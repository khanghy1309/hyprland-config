#!/usr/bin/env bash
# Card đồ hoạ NVIDIA cho Liquid Glass: tự nhận card, chọn đúng driver, chỉnh những chỗ cần chỉnh.
# Chạy riêng được (./nvidia/setup-nvidia.sh) hoặc qua ./install.sh. Không có card NVIDIA thì không làm gì.
#
#   ./nvidia/setup-nvidia.sh             hỏi trước từng bước động tới hệ thống
#   ./nvidia/setup-nvidia.sh --dry-run   chỉ in ra sẽ làm gì, không đổi gì
#
# Chọn driver theo đời card (theo thông báo của Arch ngày 20/12/2025, driver 590 trở đi):
#   RTX 20 / GTX 16 trở lên (Turing, Ampere, Ada, Blackwell)  → nvidia-open (kho chính thức)
#   GTX 750 – GTX 10, Titan V (Maxwell, Pascal, Volta)        → nvidia-580xx-dkms (AUR)
#   cũ hơn nữa (GTX 600/700 đời Kepler trở về trước)          → giữ driver mở nouveau; driver NVIDIA
#                                                               cho các card này không chạy được Hyprland
# Những gì gói driver hiện nay đã tự lo, script không đụng tới: bật modeset (cần cho Wayland),
# chặn nouveau, giữ bộ nhớ card khi ngủ/ngủ đông.
# Những gì script làm thêm (hỏi trước, sao lưu trước khi sửa):
#   - cài gói driver hợp với kernel đang dùng (kernel lạ thì dùng bản dkms và header của kernel đó)
#   - nạp driver ngay từ initramfs (để màn hình khởi động Plymouth và màn hình đăng nhập không bị đen)
#   - máy chỉ có card NVIDIA: đặt biến môi trường cho giải mã video bằng card (~/.config/hypr/lg_gpu.lua)
#   - laptop có cả card tích hợp: cài nvidia-prime để chạy game bằng card rời (prime-run <lệnh>)

set -euo pipefail

DRY=0
[[ "${1:-}" == "--dry-run" ]] && DRY=1

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
STAMP="$(date +%Y%m%d-%H%M%S)"

bold()  { printf '\033[1m%s\033[0m\n' "$*"; }
info()  { printf '  • %s\n' "$*"; }
warn()  { printf '\033[33m  ! %s\033[0m\n' "$*"; }
ask()   { if ((DRY)); then printf '  ? %s [chạy thử: coi như đồng ý]\n' "$1"; return 0; fi
          local a; read -r -p "  ? $1 [y/N] " a; [[ "${a,,}" == y* ]]; }
# chạy một lệnh động tới hệ thống (chạy thử thì chỉ in ra)
run()   { if ((DRY)); then printf '    $ %s\n' "$*"; else "$@"; fi; }
backup() { run sudo cp -a "$1" "$1.bak-liquid-glass-$STAMP"; info "Đã sao lưu $1 → $1.bak-liquid-glass-$STAMP"; }

# ── 1. tìm card ──
# Có thể đưa sẵn kết quả lspci qua LG_LSPCI (để thử script trên máy không có card).
if [[ -n "${LG_LSPCI:-}" ]]; then
    LSPCI="$LG_LSPCI"
else
    if ! command -v lspci >/dev/null 2>&1; then
        info "Cài pciutils để đọc danh sách card đồ hoạ…"
        run sudo pacman -S --needed --noconfirm pciutils >/dev/null || true
    fi
    LSPCI="$(lspci -nn 2>/dev/null || true)"
fi
# chỉ lấy bộ điều khiển hình ảnh: VGA [0300], 3D [0302], Display [0380]
GPUS="$(grep -E '\[03(00|02|80)\]' <<< "$LSPCI" || true)"
NV="$(grep -E '\[10de:[0-9a-f]{4}\]' <<< "$GPUS" || true)"
if [[ -z "$NV" ]]; then
    info "Không có card NVIDIA, bỏ qua."
    exit 0
fi
OTHER="$(grep -vE '\[10de:[0-9a-f]{4}\]' <<< "$GPUS" || true)"
HYBRID=0
[[ -n "$OTHER" ]] && HYBRID=1

bold "Card đồ hoạ NVIDIA"
while IFS= read -r l; do info "$(sed -E 's/^[0-9a-f:.]+ //; s/ \(rev [0-9a-f]+\)//' <<< "$l")"; done <<< "$NV"
((HYBRID)) && info "Máy có thêm card tích hợp: màn hình chạy bằng card tích hợp, card NVIDIA dùng khi cần (game, dựng hình)."

# Đời card lấy từ mã chip trong tên (TU106, GA102, AD107, GB203, GP104, GM204, GK104...).
# Card nào có mã thì lấy theo card mới nhất (máy có hai card NVIDIA hiếm, nhưng cứ tính).
family=""
for code in $(grep -oE '\b(G[A-Z]{1,2}[0-9]{2,3}[A-Z]?)\b' <<< "$NV" | sort -u); do
    case "$code" in
        TU*|GA*|AD*|GB*|GH*) family=open ;;
        GV*|GP*|GM*)         [[ $family == open ]] || family=legacy ;;
        GK*|GF*|GT*|G[0-9]*) [[ -n $family ]] || family=old ;;
    esac
done
# mã chip không có trong tên (card mới hơn danh sách tên trên máy): đoán theo mã thiết bị.
# NVIDIA đánh số tăng dần theo đời: từ 0x1e00 là Turing trở lên, 0x1340–0x1dff là Maxwell/Pascal/Volta.
if [[ -z "$family" ]]; then
    for id in $(grep -oE '\[10de:[0-9a-f]{4}\]' <<< "$NV" | sed -E 's/\[10de:([0-9a-f]{4})\]/\1/'); do
        n=$((16#$id))
        if ((n >= 0x1e00)); then family=open
        elif ((n >= 0x1340)); then [[ $family == open ]] || family=legacy
        else [[ -n $family ]] || family=old
        fi
    done
fi
# vẫn chưa ra: đoán theo tên thương mại
if [[ -z "$family" ]]; then
    if grep -qiE 'RTX|GTX 16[0-9]{2}|MX(4|5)[0-9]{2}|\bA[0-9]{3,4}\b|\b[HLB][0-9]{2,3}\b' <<< "$NV"; then family=open
    elif grep -qiE 'GTX (9[0-9]{2}|10[0-9]{2})|GTX 750|MX(1|2|3)[0-9]{2}|Quadro P|Titan (X|V)' <<< "$NV"; then family=legacy
    elif grep -qiE 'GTX [4-7][0-9]{2}|GT [0-9]{3}' <<< "$NV"; then family=old
    fi
fi

case "$family" in
    open)   info "Đời Turing trở lên (RTX 20 / GTX 16 hoặc mới hơn): dùng driver nvidia-open." ;;
    legacy) info "Đời Maxwell / Pascal / Volta (GTX 750 – GTX 10): driver mới không còn hỗ trợ, dùng nhánh 580 (nvidia-580xx-dkms, từ AUR)." ;;
    old)
        warn "Card này quá cũ: driver NVIDIA cho nó không chạy được Hyprland (thiếu hỗ trợ GBM)."
        warn "Giữ driver mở nouveau có sẵn. Màn hình vẫn chạy nhưng chậm hơn; nên tắt hiệu ứng kính lỏng"
        warn "(Cài đặt → Giao diện → Kính của thanh trên, dock, bảng → Phẳng)."
        exit 0 ;;
    *)
        warn "Không nhận ra đời card. Xem bảng ở https://wiki.archlinux.org/title/NVIDIA rồi cài driver tay."
        exit 0 ;;
esac

# ── 2. kernel và gói ──
# kernel đã cài (gói chính thức), để chọn bản driver dựng sẵn hay bản dkms
KERNELS=()
for k in linux linux-lts linux-zen linux-hardened linux-rt linux-rt-lts; do
    pacman -Q "$k" >/dev/null 2>&1 && KERNELS+=("$k")
done
[[ -n "${LG_KERNELS:-}" ]] && read -r -a KERNELS <<< "$LG_KERNELS"     # để thử script
((${#KERNELS[@]} > 0)) || KERNELS=(linux)
info "Kernel: ${KERNELS[*]}"

MULTILIB=0
grep -qE '^\[multilib\]' /etc/pacman.conf 2>/dev/null && MULTILIB=1
[[ -n "${LG_MULTILIB:-}" ]] && MULTILIB="$LG_MULTILIB"

REPO=() AURPKG=()
if [[ $family == open ]]; then
    # chỉ dùng kernel linux và/hoặc linux-lts: dùng bản dựng sẵn; có kernel khác: dkms (dựng theo từng kernel)
    prebuilt=1
    for k in "${KERNELS[@]}"; do [[ $k == linux || $k == linux-lts ]] || prebuilt=0; done
    if ((prebuilt)); then
        for k in "${KERNELS[@]}"; do
            [[ $k == linux ]] && REPO+=(nvidia-open)
            [[ $k == linux-lts ]] && REPO+=(nvidia-lts-open)
        done
    else
        REPO+=(nvidia-open-dkms)
        for k in "${KERNELS[@]}"; do REPO+=("$k-headers"); done
    fi
    REPO+=(nvidia-utils libva-nvidia-driver)
    ((MULTILIB)) && REPO+=(lib32-nvidia-utils)     # game 32-bit (Steam)
else
    AURPKG+=(nvidia-580xx-dkms nvidia-580xx-utils)
    ((MULTILIB)) && AURPKG+=(lib32-nvidia-580xx-utils)
    for k in "${KERNELS[@]}"; do REPO+=("$k-headers"); done
    REPO+=(dkms libva-nvidia-driver)
fi
((HYBRID)) && REPO+=(nvidia-prime)

# driver NVIDIA đang cài (nếu có)
INSTALLED="$(pacman -Qq 2>/dev/null | grep -E '^(nvidia|nvidia-open|nvidia-lts|nvidia-lts-open|nvidia-dkms|nvidia-open-dkms|nvidia-[0-9]+xx-dkms)$' || true)"
[[ -n "${LG_INSTALLED+x}" ]] && INSTALLED="$LG_INSTALLED"
if [[ -n "$INSTALLED" ]]; then
    info "Đang có driver: $(tr '\n' ' ' <<< "$INSTALLED")"
    if [[ $family == legacy ]] && grep -qE '^nvidia(-open|-lts|-lts-open|-dkms|-open-dkms)?$' <<< "$INSTALLED"; then
        warn "Driver này không còn chạy được với card của bạn (sau khi cập nhật có thể màn hình đen)."
        warn "Cần gỡ nó rồi cài nhánh 580; trình cài AUR sẽ hỏi thay thế, chọn đồng ý."
    fi
fi

echo
info "Gói cần có: ${REPO[*]}${AURPKG:+ (AUR: ${AURPKG[*]})}"
if ask "Cài driver NVIDIA?"; then
    run sudo pacman -S --needed "${REPO[@]}" || warn "pacman báo lỗi; xem thông báo phía trên."
    if ((${#AURPKG[@]} > 0)); then
        AUR=""
        command -v paru >/dev/null 2>&1 && AUR=paru
        command -v yay >/dev/null 2>&1 && AUR=yay
        if [[ -z $AUR ]] && ((DRY == 0)); then
            warn "Cần yay hoặc paru để cài gói AUR. Chạy ./install.sh (bước 2 cài yay) rồi chạy lại script này."
        else
            run "${AUR:-yay}" -S --needed "${AURPKG[@]}" || warn "Không cài được ${AURPKG[*]}."
        fi
    fi
fi

# ── 3. nạp driver ngay từ initramfs ──
# Không có bước này, lúc khởi động màn hình có thể đen vài giây (hoặc không hiện Plymouth),
# và trên vài máy nouveau giành card trước. Theo Arch Wiki: thêm 4 mô-đun vào MODULES,
# bỏ hook kms (hook đó nạp nouveau vào initramfs).
MK=/etc/mkinitcpio.conf
[[ -n "${LG_MKINITCPIO:-}" ]] && MK="$LG_MKINITCPIO"
NVMODS="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
if [[ -f $MK ]]; then
    mods="$(grep -E '^MODULES=' "$MK" || true)"
    hooks="$(grep -E '^HOOKS=' "$MK" || true)"
    need_mods=0 need_hooks=0
    for m in $NVMODS; do [[ " ${mods//[()]/ } " == *" $m "* ]] || need_mods=1; done
    [[ " ${hooks//[()]/ } " == *" kms "* ]] && need_hooks=1
    if ((need_mods || need_hooks)) && ask "Nạp driver NVIDIA ngay lúc khởi động (sửa $MK)?"; then
        backup "$MK"
        if ((need_mods)); then
            if [[ -n $mods ]]; then
                # thêm các mô-đun còn thiếu vào cuối danh sách MODULES=(...)
                cur="$(sed -E 's/^MODULES=\((.*)\).*/\1/' <<< "$mods")"
                new="$cur"
                for m in $NVMODS; do [[ " $new " == *" $m "* ]] || new="$new $m"; done
                new="$(sed -E 's/^ +//; s/ +/ /g' <<< "$new")"
                run sudo sed -i -E "s|^MODULES=\(.*\)|MODULES=($new)|" "$MK"
            else
                run sudo sh -c "printf 'MODULES=(%s)\n' '$NVMODS' >> '$MK'"
            fi
        fi
        ((need_hooks)) && run sudo sed -i -E '/^HOOKS=/ { s/\(kms /(/; s/ kms\)/)/; s/ kms / /g }' "$MK"
        ((DRY)) || grep -E '^(MODULES|HOOKS)=' "$MK" | sed 's/^/    /'
        if command -v mkinitcpio >/dev/null 2>&1 || ((DRY)); then
            run sudo mkinitcpio -P || warn "mkinitcpio báo lỗi; xem thông báo phía trên trước khi khởi động lại."
        fi
    fi
elif ((DRY == 0)); then
    warn "Không thấy $MK (máy không dùng mkinitcpio?). Tự thêm $NVMODS vào initramfs theo công cụ của bạn."
fi

# ── 4. biến môi trường cho Hyprland ──
# Máy chỉ có card NVIDIA: giải mã video bằng card (trình duyệt, mpv, hình nền video) cần
# libva-nvidia-driver và hai biến dưới. Laptop lai thì KHÔNG đặt: ứng dụng chạy bằng card tích hợp,
# đặt các biến này sẽ làm giải mã video và OpenGL tìm nhầm sang card NVIDIA.
GPUFILE="$CONFIG/hypr/lg_gpu.lua"
TMP="$(mktemp)"
{
    echo "-- Do nvidia/setup-nvidia.sh tự ghi theo card của máy. Chạy lại script đó nếu đổi card."
    if ((HYBRID)); then
        echo "-- Laptop có card tích hợp + NVIDIA: màn hình chạy bằng card tích hợp, không cần biến riêng."
        echo "-- Chạy một ứng dụng bằng card NVIDIA:  prime-run <lệnh>   (Steam: thêm  prime-run %command%)"
    else
        echo "hl.env(\"LIBVA_DRIVER_NAME\", \"nvidia\")          -- giải mã video bằng card (libva-nvidia-driver)"
        echo "hl.env(\"NVD_BACKEND\", \"direct\")                -- cách libva-nvidia-driver nói chuyện với driver"
        echo "hl.env(\"__GLX_VENDOR_LIBRARY_NAME\", \"nvidia\")  -- ứng dụng X11 (XWayland) dùng OpenGL của NVIDIA"
    fi
} > "$TMP"
if ((DRY)); then
    info "Sẽ ghi $GPUFILE:"; sed 's/^/      /' "$TMP"; rm -f "$TMP"
else
    mkdir -p "$(dirname "$GPUFILE")"
    mv "$TMP" "$GPUFILE"
    chmod 644 "$GPUFILE"
    info "Đã ghi $GPUFILE"
fi

echo
info "Xong phần NVIDIA. Khởi động lại máy để driver mới có hiệu lực."
info "Kiểm tra sau khi khởi động lại:  nvidia-smi   (thấy tên card là driver đã chạy)"
((HYBRID)) && info "Thử card rời:  prime-run glxinfo | grep 'OpenGL renderer'  (cần gói mesa-utils)"
exit 0
