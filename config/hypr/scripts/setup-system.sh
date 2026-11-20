#!/usr/bin/env bash
# Những thứ một máy dùng hằng ngày cần mà Arch không tự bật: máy in và máy quét, điểm khôi phục
# hệ thống trước mỗi lần cập nhật, zram (nén RAM) và tự dọn gói cài đặt cũ.
# Chạy riêng được (~/.config/hypr/scripts/setup-system.sh, hoặc nút Thiết lập trong Cài đặt →
# Sao lưu và bảo trì) hoặc qua ./install.sh (bước 8).
#
#   setup-system.sh             hỏi trước từng phần
#   setup-system.sh --dry-run   chỉ in ra sẽ làm gì, không đổi gì
#
# Mỗi tệp hệ thống đều được sao lưu (tên.bak-liquid-glass-<thời gian>) trước khi sửa.
# Chạy lại bao nhiêu lần cũng được: phần nào đã làm thì bỏ qua.
#
# Biến dùng để thử script mà không đụng tới máy (tools/kiem-tra và docs/KIEM-TRA.md):
#   LG_ETC        thư mục thay cho /etc;  LG_BIN  thay cho /usr/local/bin
#   LG_SUDO       lệnh thay cho sudo (để trống: chạy thẳng)
#   LG_SYSTEMCTL  lệnh thay cho systemctl
#   LG_ROOTFS, LG_FSROOT, LG_ROOTSRC   kiểu ổ, subvolume và thiết bị của thư mục gốc
#   LG_UUID, LG_PARENT_UUID            UUID của ổ gốc và của phân vùng mã hoá chứa nó
#   LG_BOOT       grub | systemd-boot | other
#   LG_YES=1      đồng ý hết, không hỏi

set -uo pipefail

DRY=0
[[ "${1:-}" == "--dry-run" ]] && DRY=1

ETC="${LG_ETC:-/etc}"
BIN="${LG_BIN:-/usr/local/bin}"
SUDO="${LG_SUDO-sudo}"
SYSTEMCTL="${LG_SYSTEMCTL:-systemctl}"
STAMP="$(date +%Y%m%d-%H%M%S)"

bold()  { printf '\033[1m%s\033[0m\n' "$*"; }
info()  { printf '  • %s\n' "$*"; }
warn()  { printf '\033[33m  ! %s\033[0m\n' "$*"; }
ask()   {
    if ((DRY)); then printf '  ? %s [chạy thử: coi như đồng ý]\n' "$1"; return 0; fi
    [[ "${LG_YES:-}" == 1 ]] && return 0
    local a; read -r -p "  ? $1 [y/N] " a; [[ "${a,,}" == y* ]]
}
# lệnh cần quyền quản trị (chạy thử thì chỉ in ra)
run() {
    if ((DRY)); then printf '    $ %s\n' "$*"; return 0; fi
    # shellcheck disable=SC2086  # $SUDO cố ý tách từ (có thể để trống)
    $SUDO "$@"
}
backup() { [[ -e $1 ]] || return 0; run cp -a "$1" "$1.bak-liquid-glass-$STAMP"; info "Đã sao lưu $1 → $1.bak-liquid-glass-$STAMP"; }
# ghi một tệp hệ thống (có sao lưu nếu đã có và khác)
put() {
    local file="$1" content="$2"
    if [[ -f $file ]] && [[ "$(cat "$file")" == "$content" ]]; then return 0; fi
    backup "$file"
    if ((DRY)); then printf '    $ ghi %s:\n' "$file"; sed 's/^/        /' <<< "$content"; return 0; fi
    run mkdir -p "$(dirname "$file")"
    printf '%s\n' "$content" | run tee "$file" >/dev/null
}
svc() { run "$SYSTEMCTL" "$@" || warn "Không chạy được: systemctl $*"; }

# ───────────────────────── 1. máy in và máy quét ─────────────────────────
bold "Máy in và máy quét"
info "Máy in mạng và máy in USB đời mới tự hiện, không cần driver (IPP Everywhere, AirPrint)."
info "Máy in HP dùng hplip, máy in cũ khác dùng gutenprint. Máy quét đời mới cũng tự nhận (sane-airscan)."
if ask "Bật dịch vụ in (CUPS) và dò máy in trong mạng (Avahi)?"; then
    svc enable --now cups.socket
    svc enable --now avahi-daemon.service
    # systemd-resolved cũng dò mDNS và giành cổng với Avahi: tắt phần đó của resolved (Arch wiki: Avahi)
    if [[ -n "${LG_RESOLVED:-}" ]] || "$SYSTEMCTL" is-active --quiet systemd-resolved 2>/dev/null; then
        put "$ETC/systemd/resolved.conf.d/10-liquid-glass-mdns.conf" "# Avahi lo việc dò máy in trong mạng (Liquid Glass, scripts/setup-system.sh)
[Resolve]
MulticastDNS=no"
        svc restart systemd-resolved.service
    fi
    # cho máy tìm được tên máy in dạng ten-may-in.local (nss-mdns)
    NSS="$ETC/nsswitch.conf"
    if [[ -f $NSS ]] && ! grep -qE '^hosts:.*mdns' "$NSS"; then
        if grep -qE '^hosts:.*\bresolve\b' "$NSS"; then
            new=$(sed -E '/^hosts:/ s/(\s)resolve\b/\1mdns_minimal [NOTFOUND=return] resolve/' "$NSS")
        else
            new=$(sed -E '/^hosts:/ s/(\s)dns\b/\1mdns_minimal [NOTFOUND=return] dns/' "$NSS")
        fi
        if [[ "$new" != "$(cat "$NSS")" ]]; then
            put "$NSS" "$new"
            info "Đã thêm mdns_minimal vào dòng hosts: của $NSS"
        else
            warn "Không thấy chỗ thêm mdns_minimal trong $NSS; máy in theo tên .local có thể không tìm được."
        fi
    fi
    info "Thêm máy in: Cài đặt → Máy in và máy quét → Thêm máy in."
fi
echo

# ───────────────────────── 2. điểm khôi phục (Timeshift) ─────────────────────────
bold "Điểm khôi phục hệ thống (Timeshift)"
ROOTFS="${LG_ROOTFS:-$(findmnt -no FSTYPE / 2>/dev/null)}"
FSROOT="${LG_FSROOT:-$(findmnt -no FSROOT / 2>/dev/null)}"
ROOTSRC="${LG_ROOTSRC:-$(findmnt -no SOURCE / 2>/dev/null | sed 's/\[.*\]$//')}"
UUID="${LG_UUID:-$(findmnt -no UUID / 2>/dev/null)}"
# ổ gốc nằm trong phân vùng mã hoá (LUKS): Timeshift cần cả UUID của phân vùng ngoài
PARENT_UUID="${LG_PARENT_UUID-}"
if [[ -z ${LG_PARENT_UUID+x} && -n $ROOTSRC ]]; then
    pk=$(lsblk -ndo PKNAME "$ROOTSRC" 2>/dev/null | head -n1)
    if [[ -n $pk && "$(lsblk -ndo TYPE "$ROOTSRC" 2>/dev/null)" == crypt ]]; then
        PARENT_UUID=$(lsblk -ndo UUID "/dev/$pk" 2>/dev/null)
    fi
fi
if [[ -z ${LG_BOOT:-} ]]; then
    if [[ -f /boot/grub/grub.cfg ]]; then LG_BOOT=grub
    elif command -v bootctl >/dev/null 2>&1 && bootctl is-installed >/dev/null 2>&1; then LG_BOOT=systemd-boot
    else LG_BOOT=other; fi
fi

MODE=rsync
if [[ $ROOTFS == btrfs && $FSROOT == "/@" ]]; then
    MODE=btrfs
    info "Ổ gốc là Btrfs, subvolume @: điểm khôi phục chụp tức thì, gần như không tốn chỗ."
elif [[ $ROOTFS == btrfs ]]; then
    info "Ổ gốc là Btrfs nhưng không theo kiểu @ (đang là ${FSROOT:-?}): dùng kiểu sao chép (rsync)."
else
    info "Ổ gốc là ${ROOTFS:-?}: dùng kiểu sao chép (rsync). Lần đầu mất vài phút, các lần sau chỉ chép phần đổi."
fi
info "Điểm khôi phục chỉ gồm hệ thống, không gồm thư mục nhà (tài liệu, ảnh của bạn không bị quay về)."

TSCONF="$ETC/timeshift/timeshift.json"
if [[ -z $UUID ]]; then
    warn "Không đọc được UUID của ổ gốc; bỏ qua phần điểm khôi phục."
elif [[ -f $TSCONF ]] && ! grep -q '"do_first_run" : "true"' "$TSCONF"; then
    info "Timeshift đã được cấu hình từ trước, giữ nguyên ($TSCONF)."
    HAVE_TS=1
elif ask "Bật điểm khôi phục: tự chụp trước mỗi lần cập nhật và mỗi ngày một lần (giữ 5 bản)?"; then
    put "$TSCONF" "{
  \"backup_device_uuid\" : \"$UUID\",
  \"parent_device_uuid\" : \"$PARENT_UUID\",
  \"do_first_run\" : \"false\",
  \"btrfs_mode\" : \"$([[ $MODE == btrfs ]] && echo true || echo false)\",
  \"include_btrfs_home_for_backup\" : \"false\",
  \"include_btrfs_home_for_restore\" : \"false\",
  \"stop_cron_emails\" : \"true\",
  \"schedule_monthly\" : \"false\",
  \"schedule_weekly\" : \"false\",
  \"schedule_daily\" : \"true\",
  \"schedule_hourly\" : \"false\",
  \"schedule_boot\" : \"false\",
  \"count_monthly\" : \"2\",
  \"count_weekly\" : \"3\",
  \"count_daily\" : \"5\",
  \"count_hourly\" : \"6\",
  \"count_boot\" : \"5\",
  \"exclude\" : [
    \"/root/**\",
    \"/home/*/**\"
  ],
  \"exclude-apps\" : []
}"
    # lịch chụp hằng ngày chạy bằng cron; Timeshift tự ghi /etc/cron.d/timeshift-hourly khi chạy
    svc enable --now cronie.service
    run timeshift --list >/dev/null 2>&1 || true
    HAVE_TS=1
fi

if [[ ${HAVE_TS:-0} == 1 ]]; then
    # chụp trước mỗi lần cài / gỡ / cập nhật gói (cùng thẻ D để Timeshift tự xoá bản cũ, giữ 5 bản)
    put "$ETC/pacman.d/hooks/05-liquid-glass-timeshift.hook" "# Tự chụp điểm khôi phục trước khi pacman đổi gói (Liquid Glass, scripts/setup-system.sh)
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
Description = Đang chụp điểm khôi phục (Timeshift)...
When = PreTransaction
Depends = timeshift
Exec = /usr/local/bin/lg-snapshot-before-update"
    put "$BIN/lg-snapshot-before-update" "#!/bin/sh
# Chụp điểm khôi phục trước khi cập nhật (pacman hook). Không chụp lại nếu vừa chụp trong 30 phút,
# để cài nhiều gói liền nhau không tạo cả loạt điểm khôi phục. Lỗi thì bỏ qua, không chặn pacman.
stamp=/var/lib/liquid-glass/last-snapshot
mkdir -p /var/lib/liquid-glass
if [ -f \"\$stamp\" ] && [ \$(( \$(date +%s) - \$(stat -c %Y \"\$stamp\") )) -lt 1800 ]; then
    echo 'Vừa chụp điểm khôi phục chưa tới 30 phút, bỏ qua.'
    exit 0
fi
timeshift --create --scripted --tags D --comments 'Trước khi cập nhật' && touch \"\$stamp\"
exit 0"
    run chmod 755 "$BIN/lg-snapshot-before-update"
    info "Mở, chụp tay hoặc quay về một điểm khôi phục: Cài đặt → Sao lưu (hoặc ứng dụng Timeshift)."

    # khởi động thẳng vào một điểm khôi phục từ menu GRUB (chỉ Btrfs + GRUB)
    if [[ $MODE == btrfs && $LG_BOOT == grub ]]; then
        if ask "Thêm các điểm khôi phục vào menu GRUB (máy hỏng sau cập nhật vẫn khởi động được bản cũ)?"; then
            run pacman -S --needed --noconfirm grub-btrfs inotify-tools
            put "$ETC/systemd/system/grub-btrfsd.service.d/10-liquid-glass-timeshift.conf" "# grub-btrfs theo dõi điểm khôi phục của Timeshift (Liquid Glass)
[Service]
ExecStart=
ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto"
            svc daemon-reload
            svc enable --now grub-btrfsd.service
            run grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1 || warn "grub-mkconfig chưa chạy được; chạy tay: sudo grub-mkconfig -o /boot/grub/grub.cfg"
            info "Menu GRUB có thêm mục 'Arch Linux snapshots'."
        fi
    else
        info "Quay về điểm khôi phục: Cài đặt → Sao lưu → Mở Timeshift → chọn điểm → Khôi phục."
        info "Máy hỏng tới mức không vào được: khởi động USB cài Arch, cài timeshift rồi khôi phục từ đó."
    fi
    if ask "Chụp điểm khôi phục đầu tiên ngay bây giờ?$([[ $MODE == rsync ]] && echo ' (kiểu sao chép: có thể mất vài phút)')"; then
        run timeshift --create --scripted --tags D --comments 'Điểm khôi phục đầu tiên' || warn "Chưa chụp được; mở Timeshift để xem lỗi."
    fi
fi
echo

# ───────────────────────── 3. zram ─────────────────────────
bold "Nén RAM (zram)"
info "Khi RAM sắp đầy, máy nén bớt phần ít dùng ngay trong RAM thay vì đơ; máy 8 GB mở nhiều tab mượt hơn hẳn."
ZCONF="$ETC/systemd/zram-generator.conf"
if [[ -f $ZCONF ]]; then
    info "Đã có $ZCONF, giữ nguyên."
elif ask "Bật zram (dùng tối đa nửa RAM, không quá 8 GB, nén zstd)?"; then
    put "$ZCONF" "# Nén RAM (Liquid Glass, scripts/setup-system.sh). Arch wiki: zram
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
swap-priority = 100"
    # thông số cho swap trên zram (Arch wiki: Optimizing swap on zram)
    put "$ETC/sysctl.d/99-liquid-glass-zram.conf" "# Swap trên zram rẻ hơn đọc ổ: cho dùng sớm, không đọc trước (Liquid Glass)
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0"
    # zswap nén thêm một lần nữa trước khi tới zram: tắt đi (Arch wiki khuyên khi dùng zram)
    put "$ETC/tmpfiles.d/liquid-glass-zswap.conf" "# Tắt zswap khi đã dùng zram (Liquid Glass)
w- /sys/module/zswap/parameters/enabled - - - - 0"
    svc daemon-reload
    svc start systemd-zram-setup@zram0.service
    run sysctl --system >/dev/null 2>&1 || true
    run systemd-tmpfiles --create "$ETC/tmpfiles.d/liquid-glass-zswap.conf" >/dev/null 2>&1 || true
fi
echo

# ───────────────────────── 4. dọn gói cũ ─────────────────────────
bold "Tự dọn gói cài đặt cũ"
info "Mỗi lần cập nhật, bản cũ của gói được giữ lại trong /var/cache/pacman/pkg; lâu dần chiếm nhiều GB."
if ask "Mỗi tuần tự xoá bớt, chỉ giữ 3 bản gần nhất của mỗi gói (paccache.timer)?"; then
    svc enable --now paccache.timer
fi
echo
exit 0
