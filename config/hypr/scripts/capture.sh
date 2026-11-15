#!/usr/bin/env bash
# Chụp màn hình, quay màn hình và đọc chữ trong ảnh.
#
#   capture.sh shot   region|window|screen  [--edit] [--delay N]
#   capture.sh record region|window|screen  [--audio none|system|mic]
#   capture.sh stop                    dừng quay
#   capture.sh ocr                     chọn vùng, đọc chữ, chép vào bộ nhớ tạm
#
# Ảnh lưu ở ~/Pictures/Screenshots, video ở ~/Videos/Screencasts.
# Bảng chụp (Super + Shift + S) gọi script này; bạn cũng có thể gọi trực tiếp.

set -uo pipefail

shots="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/Screenshots"
casts="$(xdg-user-dir VIDEOS 2>/dev/null || echo "$HOME/Videos")/Screencasts"
stamp() { date +%F_%H-%M-%S; }

notify() { notify-send -a "Chụp màn hình" "$@"; }

# Trả về vùng dạng "x,y wxh" theo chế độ; trả lỗi nếu người dùng bấm Esc khi chọn.
geometry() {
    case "$1" in
        region)
            slurp -d
            ;;
        window)
            # các cửa sổ trên những workspace đang hiện; slurp cho bấm chọn một khung
            local ws
            ws="$(hyprctl monitors -j | jq -c '[.[].activeWorkspace.id]')"
            hyprctl clients -j \
                | jq -r --argjson ws "$ws" \
                    '.[] | select(.mapped and (.workspace.id as $w | $ws | index($w)))
                         | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' \
                | slurp -r
            ;;
        screen)
            # màn hình đang có con trỏ chuột
            hyprctl monitors -j \
                | jq -r '.[] | select(.focused) | "\(.x),\(.y) \((.width / .scale) | floor)x\((.height / .scale) | floor)"'
            ;;
        *)
            echo "chế độ không hợp lệ: $1" >&2
            return 1
            ;;
    esac
}

# Bộ mã hoá H.264 chỉ nhận khung có chiều rộng và chiều cao chẵn: bớt 1 px nếu lẻ.
even_geom() {
    local pos size w h
    read -r pos size <<< "$1"
    w="${size%x*}"; h="${size#*x}"
    if [[ "$w" =~ ^[0-9]+$ && "$h" =~ ^[0-9]+$ ]]; then
        printf '%s %dx%d\n' "$pos" $((w - w % 2)) $((h - h % 2))
    else
        printf '%s\n' "$1"
    fi
}

shot() {
    local mode="$1"; shift
    local edit=0 delay=0
    while (($#)); do
        case "$1" in
            --edit) edit=1 ;;
            --delay) delay="${2:-0}"; [[ "$delay" =~ ^[0-9]+$ ]] || delay=0; shift ;;
        esac
        shift
    done

    local geom
    geom="$(geometry "$mode")" || exit 0
    [[ -n "$geom" ]] || exit 0
    ((delay > 0)) && sleep "$delay"

    mkdir -p "$shots"
    local f
    f="$shots/$(stamp).png"
    grim -g "$geom" "$f" || { notify -u critical "Không chụp được màn hình"; exit 1; }

    if ((edit)); then
        # Satty: vẽ, chú thích, che thông tin; Enter để lưu và chép
        satty --filename "$f" --output-filename "$f" --copy-command wl-copy \
              --early-exit --actions-on-enter save-to-clipboard,save-to-file \
              --disable-notifications
        exit 0
    fi

    wl-copy --type image/png < "$f"
    # thông báo có nút; chạy nền để script trả về ngay
    (
        action="$(notify -i "$f" --action=edit="Sửa" --action=open="Mở thư mục" \
                         "Đã chụp và chép vào bộ nhớ tạm" "$(basename "$f")")"
        case "$action" in
            edit) satty --filename "$f" --output-filename "$f" --copy-command wl-copy \
                        --early-exit --actions-on-enter save-to-clipboard,save-to-file ;;
            open) xdg-open "$shots" ;;
        esac
    ) &
    disown
}

record() {
    local mode="$1"; shift
    local audio="none"
    while (($#)); do
        case "$1" in
            --audio) audio="${2:-none}"; shift ;;
        esac
        shift
    done

    if pgrep -x wf-recorder >/dev/null; then
        notify "Đang quay rồi" "Bấm vào đảo động hoặc chạy: capture.sh stop"
        exit 0
    fi

    local geom
    geom="$(geometry "$mode")" || exit 0
    [[ -n "$geom" ]] || exit 0
    geom="$(even_geom "$geom")"

    local args=()
    case "$audio" in
        system) args+=("--audio=$(pactl get-default-sink).monitor") ;;
        mic)    args+=("--audio=$(pactl get-default-source)") ;;
    esac

    mkdir -p "$casts"
    local f
    f="$casts/$(stamp).mp4"

    # H.264 preset veryfast: nhẹ máy, file vẫn gọn
    wf-recorder -g "$geom" -f "$f" -c libx264 -p preset=veryfast -p crf=23 "${args[@]}" \
        >/dev/null 2>"${XDG_RUNTIME_DIR:-/tmp}/wf-recorder.log" &
    local pid=$!
    sleep 0.4
    if ! kill -0 "$pid" 2>/dev/null; then
        notify -u critical "Không quay được" "Xem lỗi trong ${XDG_RUNTIME_DIR:-/tmp}/wf-recorder.log"
        exit 1
    fi
    printf '%s\n' "$f" > "${XDG_RUNTIME_DIR:-/tmp}/lg-recording"
    qs ipc call recorder started >/dev/null 2>&1 || true

    wait "$pid"
    qs ipc call recorder stopped >/dev/null 2>&1 || true
    rm -f "${XDG_RUNTIME_DIR:-/tmp}/lg-recording"

    if [[ -s "$f" ]]; then
        action="$(notify --action=open="Mở video" --action=folder="Mở thư mục" \
                         "Đã lưu video" "$(basename "$f")")"
        case "$action" in
            open)   xdg-open "$f" ;;
            folder) xdg-open "$casts" ;;
        esac
    fi
}

stop() {
    # SIGINT để wf-recorder ghi nốt phần cuối file rồi mới thoát
    pkill -INT -x wf-recorder || true
}

ocr() {
    local geom text
    geom="$(slurp -d)" || exit 0
    text="$(grim -g "$geom" - | tesseract stdin stdout -l vie+eng 2>/dev/null)"
    text="$(printf '%s' "$text" | sed -e 's/[[:space:]]*$//')"
    if [[ -z "$text" ]]; then
        notify "Không đọc được chữ nào" "Thử chọn vùng rộng hơn, chữ rõ hơn"
        exit 0
    fi
    printf '%s' "$text" | wl-copy
    # cắt theo ký tự (không theo byte) để không cắt đôi một chữ có dấu
    notify "Đã chép chữ vào bộ nhớ tạm" "${text:0:200}"
}

cmd="${1:-}"; shift || true
case "$cmd" in
    shot)   shot "${1:-region}" "${@:2}" ;;
    record) record "${1:-region}" "${@:2}" ;;
    stop)   stop ;;
    ocr)    ocr ;;
    *)
        sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
        exit 1
        ;;
esac
