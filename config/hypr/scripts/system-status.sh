#!/usr/bin/env bash
# Tình trạng máy in, điểm khôi phục, nén RAM, gói cũ, tường lửa cho Cài đặt (Máy in và máy quét, Bảo mật và sao lưu).
# Chỉ đọc, không cần quyền quản trị. In ra từng dòng  khoá=giá trị  (máy in: printer=tên|trạng thái|mặc định).
#
#   system-status.sh printers    dịch vụ in và danh sách máy in
#   system-status.sh maint       điểm khôi phục, zram, gói cũ, tường lửa

set -uo pipefail
export LC_ALL=C   # lpstat, swapon... in tiếng Anh để đọc được, không theo ngôn ngữ máy

ETC="${LG_ETC:-/etc}"

printers() {
    if systemctl is-active --quiet cups.socket 2>/dev/null || systemctl is-active --quiet cups.service 2>/dev/null; then
        echo "cups=on"
    else
        echo "cups=off"; return 0
    fi
    local def; def=$(lpstat -d 2>/dev/null | sed -n 's/^system default destination: //p')
    # printer HP_LaserJet is idle.  enabled since ...
    # printer Canon now printing Canon-12.  enabled since ...
    # printer Epson disabled since ...
    lpstat -p 2>/dev/null | while read -r word name rest; do
        [[ $word == printer ]] || continue
        local state=idle
        case $rest in
            *disabled*) state=off ;;
            *printing*) state=busy ;;
        esac
        printf 'printer=%s|%s|%s\n' "$name" "$state" "$([[ $name == "$def" ]] && echo 1 || echo 0)"
    done
    printf 'jobs=%s\n' "$(lpstat -o 2>/dev/null | grep -c .)"
}

maint() {
    local ts="$ETC/timeshift/timeshift.json"
    if [[ -r $ts ]] && grep -q '"do_first_run" : "false"' "$ts"; then
        echo "timeshift=on"
        grep -q '"btrfs_mode" : "true"' "$ts" && echo "tsmode=btrfs" || echo "tsmode=rsync"
    else
        echo "timeshift=off"
    fi
    [[ -f $ETC/pacman.d/hooks/05-liquid-glass-timeshift.hook ]] && echo "tshook=on" || echo "tshook=off"
    command -v timeshift >/dev/null 2>&1 && echo "tsapp=yes" || echo "tsapp=no"
    # zram: tên và cỡ (byte) của các swap zram đang bật
    local z; z=$(swapon --show=NAME,SIZE --bytes --noheadings 2>/dev/null | awk '$1 ~ /zram/ { s += $2 } END { if (s) print s }')
    echo "zram=${z:-0}"
    systemctl is-enabled --quiet paccache.timer 2>/dev/null && echo "paccache=on" || echo "paccache=off"
    echo "pkgcache=$(du -sb /var/cache/pacman/pkg 2>/dev/null | cut -f1)"
    command -v gnome-disks >/dev/null 2>&1 && echo "disks=yes" || echo "disks=no"
    # tường lửa: ufw.conf và user.rules ai cũng đọc được, không cần quyền quản trị như "ufw status"
    if systemctl is-active --quiet firewalld 2>/dev/null; then
        echo "fw=firewalld"
    elif grep -qs '^ENABLED=yes' "$ETC/ufw/ufw.conf"; then
        echo "fw=on"
    else
        echo "fw=off"
    fi
    command -v ufw >/dev/null 2>&1 && echo "ufwapp=yes" || echo "ufwapp=no"
    # số luật cho phép đi vào bạn tự thêm (ufw allow ...), đếm theo IPv4
    echo "fwrules=$(grep -cEs '^### tuple ### (allow|limit)' "$ETC/ufw/user.rules")"
}

case "${1:-}" in
    printers) printers ;;
    maint) maint ;;
    *) echo "Dùng: $0 printers|maint" >&2; exit 2 ;;
esac
