#!/usr/bin/env bash
# Đặt hình nền: ảnh tĩnh, ảnh GIF (awww) hoặc video (mpvpaper).
#
#   wallpaper.sh <tệp>     đặt hình nền từ một tệp ảnh, GIF hoặc video
#   wallpaper.sh random    chọn ngẫu nhiên trong ~/Pictures/Wallpapers
#   wallpaper.sh restore   dùng lại hình nền lần trước (chạy khi đăng nhập)
#   wallpaper.sh power battery|ac
#                          gọi khi rút/cắm sạc: lúc dùng pin, video được thay bằng
#                          một khung hình tĩnh (nếu bật trong Cài đặt)
#   wallpaper.sh thumb <video>
#                          in đường dẫn ảnh thu nhỏ của video (tạo nếu chưa có)
#
# Video tự tạm dừng khi bị che (mức độ chọn trong Cài đặt → Hình nền) để đỡ tốn CPU/GPU.

set -u

WALL_DIR="${WALL_DIR:-$HOME/Pictures/Wallpapers}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/liquid-glass"
STATE_FILE="$STATE_DIR/wallpaper"
DEFAULT="$WALL_DIR/ridge.png"
SETTINGS="${XDG_CONFIG_HOME:-$HOME/.config}/liquid-glass/settings.json"
THUMBS="${XDG_CACHE_HOME:-$HOME/.cache}/liquid-glass/thumbs"

# đọc một lựa chọn trong settings.json (do ứng dụng Cài đặt ghi), không có thì dùng mặc định
opt() {
    local v=""
    if [ -f "$SETTINGS" ] && command -v jq >/dev/null 2>&1; then
        v="$(jq -r "$1 // empty" "$SETTINGS" 2>/dev/null)"
    fi
    printf '%s' "${v:-$2}"
}

mkdir -p "$STATE_DIR"

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Hình nền" "$1" "${2:-}"
    fi
    echo "$1 ${2:-}" >&2
}

is_video() {
    case "${1,,}" in
        *.mp4|*.webm|*.mkv|*.mov|*.m4v) return 0 ;;
        *) return 1 ;;
    esac
}

start_awww() {
    if ! pgrep -x awww-daemon >/dev/null; then
        awww-daemon --quiet >/dev/null 2>&1 &
        disown
        # chờ daemon sẵn sàng (tối đa ~3 giây)
        for _ in $(seq 1 30); do
            awww query >/dev/null 2>&1 && break
            sleep 0.1
        done
    fi
}

set_image() {
    pkill -x mpvpaper 2>/dev/null
    start_awww
    local kind
    kind="$(opt .wallpaper.transition fade)"    # fade | grow | wipe | none
    case "$kind" in fade|grow|wipe|none) ;; *) kind=fade ;; esac
    awww img "$1" \
        --transition-type "$kind" \
        --transition-duration 1.2 \
        --transition-fps 60
}

set_video() {
    if ! command -v mpvpaper >/dev/null 2>&1; then
        notify "Chưa cài mpvpaper" "Cài bằng: yay -S mpvpaper (hoặc paru -S mpvpaper)"
        return 1
    fi
    # awww và mpvpaper cùng vẽ ở lớp nền: tắt awww để video không bị che
    pkill -x awww-daemon 2>/dev/null
    pkill -x mpvpaper 2>/dev/null
    # -p: tạm dừng khi hình nền bị che hẳn. Thêm -a để tạm dừng sớm hơn:
    #   full   khi có cửa sổ toàn màn hình
    #   max    khi có cửa sổ toàn màn hình hoặc phóng to
    #   active khi đang dùng bất kỳ cửa sổ nào (chỉ chạy lúc nhìn màn hình trống)
    local mode args=()
    mode="$(opt .wallpaper.pauseMode full)"
    case "$mode" in
        full)   args=(-p -a FULL) ;;
        max)    args=(-p -a MAX) ;;
        active) args=(-p -a ACTIVE) ;;
        hidden) args=(-p) ;;
        never)  args=() ;;
        *)      args=(-p -a FULL) ;;
    esac
    mpvpaper -f "${args[@]}" \
        -o "no-audio loop hwdec=auto panscan=1.0" \
        ALL "$1"
}

# ảnh thu nhỏ của video (dùng cho Cài đặt và cho chế độ dùng pin)
thumb() {
    local src="$1" size="${2:-480}" out
    mkdir -p "$THUMBS"
    out="$THUMBS/$(printf '%s' "$src" | md5sum | cut -c1-16)-$size.jpg"
    if [ ! -s "$out" ] || [ "$src" -nt "$out" ]; then
        ffmpeg -loglevel error -y -ss 1 -i "$src" -frames:v 1 \
            -vf "scale=$size:-2" -q:v 3 "$out" </dev/null || return 1
    fi
    printf '%s\n' "$out"
}

apply() {
    local file="$1"
    if [ ! -f "$file" ]; then
        notify "Không tìm thấy tệp" "$file"
        return 1
    fi
    if is_video "$file"; then
        set_video "$file" || return 1
    else
        set_image "$file" || return 1
    fi
    printf '%s\n' "$file" > "$STATE_FILE"
}

case "${1:-}" in
    power)
        current="$(cat "$STATE_FILE" 2>/dev/null || true)"
        [ -f "$current" ] && is_video "$current" || exit 0
        if [ "${2:-}" = "battery" ] && [ "$(opt .wallpaper.stillOnBattery true)" = "true" ]; then
            # thay video bằng một khung hình (không ghi vào trạng thái, cắm sạc là có lại video)
            if frame="$(thumb "$current" 3840)"; then
                set_image "$frame"
            fi
        elif [ "${2:-}" = "ac" ] && ! pgrep -x mpvpaper >/dev/null; then
            set_video "$current"
        fi
        ;;
    thumb)
        thumb "${2:?thiếu tên tệp}" "${3:-480}"
        ;;
    restore)
        if [ -f "$STATE_FILE" ] && [ -f "$(cat "$STATE_FILE")" ]; then
            apply "$(cat "$STATE_FILE")"
        else
            apply "$DEFAULT"
        fi
        ;;
    random)
        current="$(cat "$STATE_FILE" 2>/dev/null || true)"
        mapfile -t files < <(find "$WALL_DIR" -maxdepth 1 -type f \
            \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \
               -o -iname '*.gif' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' \) \
            ! -path "$current")
        if [ "${#files[@]}" -eq 0 ]; then
            notify "Chưa có hình nền nào khác" "Thêm ảnh hoặc video vào $WALL_DIR"
            exit 1
        fi
        apply "${files[RANDOM % ${#files[@]}]}"
        ;;
    ""|-h|--help)
        sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
        ;;
    *)
        apply "$1"
        ;;
esac
