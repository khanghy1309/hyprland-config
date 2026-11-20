#!/usr/bin/env bash
# Gỡ Liquid Glass: trả máy về như trước khi chạy install.sh.
#     bash ~/hyprland-config/tools/go-cai-dat.sh
# Chạy được cả từ màn hình chữ (Ctrl + Alt + F3). Không xoá thẳng tệp nào của bạn: cấu hình của
# Liquid Glass được dời vào ~/liquid-glass-da-go-<thời gian>/, muốn lấy lại thì chép ngược ra.
# Không gỡ gói phần mềm (Hyprland, Edge, LibreOffice… vẫn dùng bình thường) và không đụng driver NVIDIA.
#
# Sau khi gỡ: Hyprland không còn tệp cấu hình nên tự tạo cấu hình mặc định lần đăng nhập tới
# (hình nền mặc định của Hyprland; Super + Q mở terminal, Super + M thoát Hyprland).

set -uo pipefail
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="${LG_OUT:-$HOME/liquid-glass-da-go-$STAMP}"
ETC="${LG_ETC:-/etc}"
SUDO="${LG_SUDO-sudo}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
info() { printf '  • %s\n' "$*"; }
warn() { printf '\033[33m  ! %s\033[0m\n' "$*"; }
ask()  { local a; read -r -p "  ? $1 [y/N] " a; [[ "${a,,}" == y* ]]; }
ask_y() { local a; read -r -p "  ? $1 [Y/n] " a; [[ -z "$a" || "${a,,}" == y* ]]; }

# dời một tệp / thư mục vào $OUT, giữ đường dẫn tương đối với $HOME
park() {
    local p="$1" rel
    [[ -e $p || -L $p ]] || return 0
    rel="${p#"$HOME"/}"
    mkdir -p "$OUT/$(dirname "$rel")"
    mv "$p" "$OUT/$rel" && info "Đã dời ~/$rel"
}
# chỉ dời khi tệp giống hệt bản của Liquid Glass (không đụng tệp bạn đã tự sửa hay tự có)
park_if_ours() {
    local p="$1" ours="$2"
    [[ -f $p ]] || return 0
    if cmp -s "$p" "$ours"; then park "$p"; else info "Giữ ~/${p#"$HOME"/} (không phải bản của Liquid Glass hoặc bạn đã sửa)"; fi
}

if [[ $EUID -eq 0 && -z ${LG_ALLOW_ROOT:-} ]]; then
    echo "Chạy bằng tài khoản thường, không dùng sudo:  bash tools/go-cai-dat.sh"
    exit 1
fi

bold "Gỡ Liquid Glass"
info "Cấu hình sẽ được dời vào: $OUT"
info "Không gỡ gói phần mềm, không đụng driver NVIDIA, không xoá ảnh trong ~/Pictures."
ask_y "Tiếp tục?" || exit 0
echo

# ── 1. cấu hình trong thư mục nhà ──
bold "1. Cấu hình của bạn (~/.config…)"
pgrep -x quickshell >/dev/null 2>&1 && { pkill -x quickshell; info "Đã tắt thanh trên (Quickshell)"; }
for d in hypr quickshell kitty liquid-glass; do park "$CONFIG/$d"; done
park "$CONFIG/fish/conf.d/liquid-glass.fish"
park_if_ours "$CONFIG/starship.toml" "$HERE/config/starship/starship.toml"
park_if_ours "$CONFIG/fastfetch/config.jsonc" "$HERE/config/fastfetch/config.jsonc"
park "$CONFIG/microsoft-edge-stable-flags.conf"
for f in "$HERE"/config/applications/*.desktop; do park "$HOME/.local/share/applications/$(basename "$f")"; done
park "$STATE/liquid-glass"
park "$CACHE/liquid-glass"
# GTK, Qt: theme-apps.sh chỉ thêm tệp liquid-glass.* và một dòng @import
for g in gtk-3.0 gtk-4.0; do
    park "$CONFIG/$g/liquid-glass.css"
    if [[ -f $CONFIG/$g/gtk.css ]] && grep -q 'liquid-glass.css' "$CONFIG/$g/gtk.css"; then
        mkdir -p "$OUT/.config/$g" && cp -a "$CONFIG/$g/gtk.css" "$OUT/.config/$g/gtk.css"
        sed -i '/liquid-glass\.css/d' "$CONFIG/$g/gtk.css" && info "Bỏ dòng @import liquid-glass.css trong ~/.config/$g/gtk.css"
    fi
done
park "$CONFIG/qt6ct/colors/liquid-glass.conf"
park "$CONFIG/qt6ct/qss/qt-liquid-glass.qss"
# hai dòng thêm vào ~/.bashrc (PATH cho ~/.local/bin): giữ lại, Claude Code và các lệnh cài riêng cần nó
echo

# ── 2. trả lại cấu hình cũ (từ lúc trước khi cài) ──
last="$(ls -d "$CONFIG"/liquid-glass-backup-* 2>/dev/null | sort | head -n 1)"
if [[ -n $last ]]; then
    bold "2. Cấu hình cũ trước khi cài Liquid Glass"
    info "Tìm thấy bản sao lưu đầu tiên: $last ($(ls "$last" | tr '\n' ' '))"
    [[ -f $last/hypr/hyprland.conf && ! -f $last/hypr/hyprland.lua ]] && \
        info "Lưu ý: Hyprland 0.57 chỉ đọc hyprland.lua; hyprland.conf cũ chép về cũng không có tác dụng."
    if ask "Chép các thư mục này về ~/.config (hypr, kitty… như trước khi cài)?"; then
        cp -a "$last/." "$CONFIG/" && info "Đã trả lại cấu hình cũ"
    fi
    echo
fi

# ── 3. phần cho cả máy (cần mật khẩu) ──
bold "3. Phần cài cho cả máy"
SDDMCONF="$ETC/sddm.conf.d/10-liquid-glass.conf"
if [[ -f $SDDMCONF ]] && ask "Màn hình đăng nhập: bỏ theme Liquid Glass, dùng lại theme mặc định của SDDM?"; then
    $SUDO rm -f "$SDDMCONF" && $SUDO rm -rf "${LG_SDDM_THEME:-/usr/share/sddm/themes/liquid-glass}" && info "Đã bỏ theme đăng nhập"
fi
FONTS="${LG_FONTS:-/usr/local/share/fonts/liquid-glass}"
if [[ -d $FONTS ]] && ask "Gỡ phông Geist, Open Sans, Be Vietnam Pro, Onest đi kèm?"; then
    $SUDO rm -rf "$FONTS" && { fc-cache -f >/dev/null 2>&1 || true; } && info "Đã gỡ phông"
fi
# setup-system.sh: các tệp có tên liquid-glass (máy in, điểm khôi phục, zram)
SYS=()
for f in "$ETC"/systemd/resolved.conf.d/10-liquid-glass-mdns.conf "$ETC"/pacman.d/hooks/05-liquid-glass-timeshift.hook \
         "$ETC"/systemd/system/grub-btrfsd.service.d/10-liquid-glass-timeshift.conf \
         "$ETC"/sysctl.d/99-liquid-glass-zram.conf "$ETC"/tmpfiles.d/liquid-glass-zswap.conf; do
    [[ -e $f ]] && SYS+=("$f")
done
if ((${#SYS[@]} > 0)); then
    info "Thiết lập hệ thống do Liquid Glass thêm: ${SYS[*]}"
    if ask "Bỏ các thiết lập này (tự chụp điểm khôi phục trước khi cập nhật, zram, dò máy in qua mạng)?"; then
        $SUDO rm -f "${SYS[@]}" && info "Đã bỏ. Khởi động lại để có hiệu lực hết."
    fi
fi
# Plymouth: chỉ trả lại tệp đã sao lưu nếu có
mk_bak="$(ls "$ETC"/mkinitcpio.conf.bak-liquid-glass-* 2>/dev/null | sort | head -n 1)"
grub_bak="$(ls "$ETC"/default/grub.bak-liquid-glass-* 2>/dev/null | sort | head -n 1)"
if [[ -n $mk_bak || -n $grub_bak ]]; then
    info "Có bản sao lưu từ lúc cài màn hình khởi động / driver: ${mk_bak:-} ${grub_bak:-}"
    warn "Bản sao lưu mkinitcpio có thể là trước khi cài driver NVIDIA; trả lại thì máy nạp driver muộn hơn một chút."
    if ask "Trả lại các tệp đó (bỏ màn hình khởi động Plymouth)?"; then
        [[ -n $mk_bak ]] && $SUDO cp -a "$mk_bak" "$ETC/mkinitcpio.conf" && $SUDO mkinitcpio -P
        [[ -n $grub_bak ]] && $SUDO cp -a "$grub_bak" "$ETC/default/grub" && $SUDO grub-mkconfig -o /boot/grub/grub.cfg
    fi
fi
echo

bold "Xong."
info "Cấu hình đã dời nằm ở: $OUT (xoá thư mục đó khi chắc không cần nữa)"
info "Đăng xuất / khởi động lại: Hyprland tự tạo cấu hình mặc định."
info "Cấu hình mặc định: Super + Q mở terminal (kitty), Super + M thoát Hyprland."
info "Muốn cài lại Liquid Glass sau này: cd ~/hyprland-config && ./install.sh"
