#!/usr/bin/env bash
# Cài màn hình khởi động Plymouth "Liquid Glass": chữ hello tự viết rồi chuyển thành chữ ký.
# Chạy riêng được (./plymouth/install-plymouth.sh) hoặc qua ./install.sh.
#
# Script sẽ hỏi trước mỗi bước động tới khởi động máy, và sao lưu file trước khi sửa:
#   1. cài gói plymouth, chép theme vào /usr/share/plymouth/themes/liquid-glass
#   2. thêm hook "plymouth" vào /etc/mkinitcpio.conf (để màn hình hiện từ rất sớm)
#   3. thêm "quiet splash" vào dòng lệnh kernel (GRUB, systemd-boot hoặc /etc/kernel/cmdline)
#   4. đặt theme và tạo lại initramfs
# Gỡ: sudo plymouth-set-default-theme -R bgrt  (hoặc bỏ "splash" khỏi dòng lệnh kernel)

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME=liquid-glass
DEST=/usr/share/plymouth/themes/$THEME
STAMP="$(date +%Y%m%d-%H%M%S)"

bold()  { printf '\033[1m%s\033[0m\n' "$*"; }
info()  { printf '  • %s\n' "$*"; }
warn()  { printf '\033[33m  ! %s\033[0m\n' "$*"; }
ask()   { local a; read -r -p "  ? $1 [y/N] " a; [[ "${a,,}" == y* ]]; }
backup() { sudo cp -a "$1" "$1.bak-liquid-glass-$STAMP"; info "Đã sao lưu $1 → $1.bak-liquid-glass-$STAMP"; }

# thêm các tham số còn thiếu vào một chuỗi tham số kernel
add_params() {
    local line="$1" p
    for p in quiet splash loglevel=3 rd.udev.log_level=3 vt.global_cursor_default=0; do
        case " $line " in *" ${p%%=*}"[=\ ]*) ;; *) line="$line $p" ;; esac
    done
    printf '%s' "${line# }"
}

# chuỗi dùng làm phần thay thế trong sed: thoát các ký tự sed hiểu theo nghĩa riêng
sed_escape() { printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'; }

bold "Màn hình khởi động (Plymouth)"

# ── 1. gói và theme ──
if ! pacman -Q plymouth >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm plymouth
fi
sudo mkdir -p "$DEST"
sudo cp -a "$HERE/$THEME/." "$DEST/"
info "Đã chép theme vào $DEST"

# ── 2. hook trong mkinitcpio ──
MK=/etc/mkinitcpio.conf
rebuild=0
if [[ -f $MK ]]; then
    hooks="$(grep -E '^HOOKS=' "$MK" || true)"
    if [[ $hooks == *plymouth* ]]; then
        info "mkinitcpio đã có hook plymouth"
    elif [[ -n $hooks ]] && ask "Thêm hook plymouth vào $MK? (cần để hiện ngay từ đầu, và để nhập mật khẩu ổ đĩa mã hoá)"; then
        backup "$MK"
        # đặt ngay sau systemd hoặc udev (trước encrypt/sd-encrypt theo hướng dẫn của Arch Wiki)
        if [[ $hooks =~ [\(\ ]systemd[\ \)] ]]; then
            sudo sed -i -E '/^HOOKS=/ s/([( ])systemd([ )])/\1systemd plymouth\2/' "$MK"
        else
            sudo sed -i -E '/^HOOKS=/ s/([( ])udev([ )])/\1udev plymouth\2/' "$MK"
        fi
        grep -E '^HOOKS=' "$MK" | sed 's/^/    /'
        if grep -E '^HOOKS=' "$MK" | grep -q plymouth; then
            rebuild=1
        else
            warn "Không thấy hook udev hay systemd trong HOOKS nên chưa thêm được. Tự thêm \"plymouth\" vào HOOKS trong $MK (sau udev/systemd)."
        fi
    fi
else
    warn "Không thấy $MK (máy không dùng mkinitcpio?). Tự thêm plymouth vào initramfs theo công cụ của bạn."
fi

# ── 3. dòng lệnh kernel ──
cmdline_done=0
if [[ -f /etc/default/grub ]] && command -v grub-mkconfig >/dev/null 2>&1; then
    # dòng có thể dùng nháy kép hoặc nháy đơn
    if grep -qE "^GRUB_CMDLINE_LINUX_DEFAULT=[\"'].*[\"']" /etc/default/grub; then
        cur="$(sed -nE "s/^GRUB_CMDLINE_LINUX_DEFAULT=[\"'](.*)[\"'].*/\1/p" /etc/default/grub | head -n1)"
        new="$(add_params "$cur")"
        if [[ $cur == "$new" ]]; then
            info "GRUB đã có quiet splash"; cmdline_done=1
        elif ask "Sửa dòng lệnh kernel của GRUB thành: \"$new\"?"; then
            backup /etc/default/grub
            sudo sed -i -E "s|^GRUB_CMDLINE_LINUX_DEFAULT=[\"'].*[\"'].*|GRUB_CMDLINE_LINUX_DEFAULT=\"$(sed_escape "$new")\"|" /etc/default/grub
            sudo grub-mkconfig -o /boot/grub/grub.cfg
            cmdline_done=1
        fi
    elif ask "Trong /etc/default/grub chưa có dòng GRUB_CMDLINE_LINUX_DEFAULT. Thêm dòng đó với quiet splash?"; then
        backup /etc/default/grub
        printf 'GRUB_CMDLINE_LINUX_DEFAULT="%s"\n' "$(add_params "")" | sudo tee -a /etc/default/grub >/dev/null
        sudo grub-mkconfig -o /boot/grub/grub.cfg
        cmdline_done=1
    fi
fi
# /boot thường chỉ root đọc được, nên liệt kê và đọc bằng sudo
mapfile -t ENTRIES < <(sudo sh -c 'ls /boot/loader/entries/*.conf 2>/dev/null' || true)
if [[ $cmdline_done -eq 0 && ${#ENTRIES[@]} -gt 0 ]]; then
    if ask "Máy dùng systemd-boot. Thêm quiet splash vào các mục khởi động trong /boot/loader/entries?"; then
        for f in "${ENTRIES[@]}"; do
            cur="$(sudo sed -nE 's/^options[[:space:]]+(.*)/\1/p' "$f" | head -n1)"
            [[ -z $cur ]] && continue
            new="$(add_params "$cur")"
            [[ $cur == "$new" ]] && continue
            backup "$f"
            # chỉ sửa dòng options đầu tiên (một mục có thể có nhiều dòng options, chúng được nối lại)
            sudo sed -i -E "0,/^options[[:space:]]+.*/ s|^options[[:space:]]+.*|options $(sed_escape "$new")|" "$f"
            info "$(basename "$f"): options $new"
        done
        cmdline_done=1
    fi
fi
if [[ $cmdline_done -eq 0 && -f /etc/kernel/cmdline ]]; then
    cur="$(cat /etc/kernel/cmdline)"
    new="$(add_params "$cur")"
    if [[ $cur != "$new" ]] && ask "Sửa /etc/kernel/cmdline (kernel dạng UKI) thành: \"$new\"?"; then
        backup /etc/kernel/cmdline
        printf '%s\n' "$new" | sudo tee /etc/kernel/cmdline >/dev/null
        rebuild=1
        cmdline_done=1
    fi
fi
if [[ $cmdline_done -eq 0 ]]; then
    warn "Chưa thêm được \"quiet splash\" vào dòng lệnh kernel. Thêm tay theo trình khởi động của bạn,"
    warn "nếu không Plymouth sẽ không hiện: https://wiki.archlinux.org/title/Plymouth"
fi

# ── 4. đặt theme, tạo lại initramfs ──
if [[ $rebuild -eq 1 ]] || ask "Đặt theme $THEME và tạo lại initramfs ngay? (mất khoảng nửa phút)"; then
    sudo plymouth-set-default-theme -R "$THEME"
    info "Xong. Khởi động lại máy để xem."
else
    sudo plymouth-set-default-theme "$THEME"
    info "Đã đặt theme. Lần sau tạo lại initramfs (sudo mkinitcpio -P) là có hiệu lực."
fi
info "Xem thử không cần khởi động lại:  sudo plymouthd; sudo plymouth --show-splash; sleep 8; sudo plymouth --quit"
