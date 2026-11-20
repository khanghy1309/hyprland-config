#!/usr/bin/env bash
# Chẩn đoán khi máy hiện màn hình đen sau khi cài Liquid Glass.
# Chạy từ màn hình chữ (TTY): bấm Ctrl + Alt + F3, đăng nhập bằng tên và mật khẩu của bạn, rồi:
#     bash ~/hyprland-config/tools/chan-doan.sh
# Chỉ đọc, không sửa gì. In một bản tóm tắt vừa một màn hình (chụp ảnh màn hình bằng điện thoại
# gửi lại là đủ); bản đầy đủ lưu ở ~/lg-chan-doan.txt.

set -uo pipefail
export LC_ALL=C.UTF-8
OUT="$HOME/lg-chan-doan.txt"
RUN="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
: > "$OUT"

sum() { printf '%s\n' "$*"; printf '%s\n' "$*" >> "$OUT"; }
full() { printf '\n===== %s =====\n' "$1" >> "$OUT"; shift; "$@" >> "$OUT" 2>&1 || true; }
ver() { pacman -Q "$1" 2>/dev/null | awk '{print $2}' || true; }

sum "── Liquid Glass: chẩn đoán màn hình đen ($(date '+%d/%m %H:%M')) ──"

# 1. card đồ hoạ
gpu=$(lspci -nnk 2>/dev/null | grep -EA3 'VGA|3D|Display' | grep -E 'VGA|3D|Display|driver in use' | sed 's/^\s*//' | tr '\n' ' ')
sum "Card: ${gpu:-không đọc được (thiếu pciutils?)}"
nv=""
if lspci 2>/dev/null | grep -qi nvidia; then
    nv=1
    modeset=$(cat /sys/module/nvidia_drm/parameters/modeset 2>/dev/null || echo "chưa nạp")
    sum "NVIDIA: nvidia_drm.modeset=$modeset  gói: $(pacman -Qq 2>/dev/null | grep -E '^nvidia' | tr '\n' ' ')"
fi
full "lspci" lspci -nnk

# 2. phiên bản
sum "Gói: hyprland $(ver hyprland) · quickshell $(ver quickshell) · sddm $(ver sddm) · kitty $(ver kitty)"
for c in Hyprland qs sddm kitty fish; do command -v "$c" >/dev/null 2>&1 || sum "THIẾU lệnh: $c"; done

# 3. trình đăng nhập
dm=""
[[ -L /etc/systemd/system/display-manager.service ]] && dm=$(basename "$(readlink -f /etc/systemd/system/display-manager.service)")
sum "Trình đăng nhập: ${dm:-chưa bật cái nào} · sddm: $(systemctl is-active sddm 2>/dev/null)"
sddmerr=$(journalctl -b -u sddm --no-pager -o cat 2>/dev/null | grep -iE 'error|fail|could not|cannot|segfault|qml' | tail -n 6)
[[ -n $sddmerr ]] && { sum "Lỗi của SDDM:"; sum "$sddmerr"; }
full "journal sddm" journalctl -b -u sddm --no-pager -o short-monotonic
full "sddm.conf.d" sh -c 'cat /etc/sddm.conf /etc/sddm.conf.d/*.conf 2>/dev/null'

# 4. Hyprland: nhật ký của lần chạy mới nhất
hlog=$(ls -t "$RUN"/hypr/*/hyprland.log "$HOME"/.local/share/hyprland/hyprland.log 2>/dev/null | head -n 1)
if [[ -n $hlog ]]; then
    sum "Nhật ký Hyprland: $hlog"
    herr=$(grep -aiE '\[ERR\]|\[CRITICAL\]|error|lua:|stack traceback|failed' "$hlog" | grep -viE 'xdg-desktop-portal|no such file.*\.face' | tail -n 10)
    [[ -n $herr ]] && { sum "Lỗi của Hyprland:"; sum "$herr"; } || sum "Hyprland: không thấy dòng lỗi"
    full "hyprland.log (300 dòng cuối)" tail -n 300 "$hlog"
else
    sum "Chưa thấy nhật ký Hyprland: có thể Hyprland chưa từng chạy (kẹt trước khi đăng nhập)"
fi
crash=$(ls -t "$HOME"/.cache/hyprland/hyprlandCrashReport*.txt 2>/dev/null | head -n 1)
[[ -n $crash ]] && { sum "CÓ báo cáo Hyprland bị sập: $crash"; full "crash report" head -n 60 "$crash"; }

# 5. Quickshell (thanh trên, dock, hình nền kính)
qerr=$(timeout 5 qs log 2>/dev/null | grep -aiE 'error|warn.*(qml|shader)|failed|cannot' | tail -n 8)
[[ -n $qerr ]] && { sum "Lỗi của Quickshell:"; sum "$qerr"; }
full "qs log" timeout 5 qs log

# 6. cấu hình
for f in hypr/hyprland.lua hypr/lg_look.lua quickshell/shell.qml kitty/kitty.conf; do
    [[ -f $HOME/.config/$f ]] || sum "THIẾU tệp: ~/.config/$f"
done
wp=$(cat "${XDG_STATE_HOME:-$HOME/.local/state}/liquid-glass/wallpaper" 2>/dev/null | head -n 1)
sum "Hình nền đã lưu: ${wp:-chưa có}"
[[ -n $wp && ! -e $wp ]] && sum "  → tệp hình nền không còn: $wp"
full "thư mục hypr" ls -la "$HOME/.config/hypr"

# 7. Plymouth / khởi động
sum "Dòng lệnh nhân: $(tr ' ' '\n' < /proc/cmdline | grep -E 'quiet|splash|nvidia|modeset' | tr '\n' ' ')"
full "journal lỗi lần khởi động này" journalctl -b -p err --no-pager -o short-monotonic

sum "── Bản đầy đủ: $OUT ──"
if [[ -n $nv && ${modeset:-} != Y ]]; then
    sum "Gợi ý: NVIDIA chưa bật modeset. Chạy: bash ~/hyprland-config/nvidia/setup-nvidia.sh rồi khởi động lại."
fi
