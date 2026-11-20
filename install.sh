#!/usr/bin/env bash
# Cài bộ giao diện Liquid Glass — đủ 5 đợt
# (nền Hyprland, thanh trên, launcher, hình nền, kitty, bộ gõ tiếng Việt,
#  đảo động, thông báo, trung tâm điều khiển, bảng widget,
#  màn hình khóa, tự khóa, menu nguồn, màn hình đăng nhập,
#  toàn cảnh workspace, bảng phím tắt, chụp/quay màn hình, đọc chữ, emoji,
#  ứng dụng Cài đặt)
#
# Chạy từ thư mục chứa file này, bằng tài khoản thường (không dùng sudo):
#   ./install.sh
#
# Script sẽ hỏi trước khi làm các việc cần quyền quản trị.
# Cấu hình cũ (nếu có) được chép sang ~/.config/liquid-glass-backup-<thời gian>/

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$CONFIG/liquid-glass-backup-$STAMP"

bold()  { printf '\033[1m%s\033[0m\n' "$*"; }
info()  { printf '  • %s\n' "$*"; }
warn()  { printf '\033[33m  ! %s\033[0m\n' "$*"; }
ask()   { local a; read -r -p "  ? $1 [y/N] " a; [[ "${a,,}" == y* ]]; }
# bước bắt buộc: Enter là đồng ý
ask_y() { local a; read -r -p "  ? $1 [Y/n] " a; [[ -z "$a" || "${a,,}" == y* ]]; }

# Thiếu những lệnh này thì sau khi đăng nhập chỉ thấy màn hình tối và con trỏ chuột
check_need() {
    local NEED=(Hyprland:hyprland qs:quickshell awww:awww kitty:kitty fish:fish hypridle:hypridle hyprlock:hyprlock
                fcitx5:fcitx5 jq:jq wl-paste:wl-clipboard cliphist:cliphist)
    local LACK=() n
    for n in "${NEED[@]}"; do command -v "${n%%:*}" >/dev/null 2>&1 || LACK+=("${n#*:}"); done
    if ((${#LACK[@]} > 0)); then
        printf '\n\033[1;31m  ✗ CHƯA CÀI ĐỦ: %s\033[0m\n' "${LACK[*]}"
        warn "Thiếu các gói này thì đăng nhập vào sẽ chỉ thấy màn hình tối. Cài rồi đăng nhập lại:"
        warn "  sudo pacman -Syu --needed ${LACK[*]}"
        echo
        return 1
    fi
    printf '\n\033[1;32m  ✓ Đã đủ các gói chính.\033[0m\n\n'
}

# ./install.sh --goi : chỉ cài gói (bước 1) rồi kiểm tra, không hỏi gì khác
ONLY_PKGS=0
[[ ${1:-} == --goi ]] && ONLY_PKGS=1

# ───────────────────────── kiểm tra ─────────────────────────
if [[ $EUID -eq 0 ]]; then
    echo "Đừng chạy script này bằng sudo/root. Chạy bằng tài khoản thường: ./install.sh"
    exit 1
fi
if ! command -v pacman >/dev/null 2>&1; then
    echo "Không thấy pacman. Script này dành cho Arch Linux."
    exit 1
fi

bold "Liquid Glass — đủ 5 đợt"
echo

# ───────────────────────── gói phần mềm ─────────────────────────
PKGS=(
    # nền
    hyprland xdg-desktop-portal-hyprland hyprpolkitagent quickshell qt6-5compat qt6-shadertools
    # hộp chọn tệp cho ứng dụng (nút Tải lên / Mở tệp trong ứng dụng Flatpak và vài ứng dụng khác)
    xdg-desktop-portal-gtk
    # kho mật khẩu: trình duyệt, VS Code, Git, Wi-Fi lưu được mật khẩu; tự mở khoá khi đăng nhập qua SDDM
    gnome-keyring
    # hình nền
    awww
    # terminal, tệp (trình duyệt Microsoft Edge cài từ AUR ở bước 2)
    kitty nautilus
    # bộ đồ nghề cho terminal: fish (gợi ý lệnh theo lịch sử, tô màu khi gõ), dòng nhắc starship,
    # thông tin máy fastfetch, ls / cat / cd dễ nhìn và thông minh hơn (eza, bat, zoxide),
    # tìm nhanh (fzf, ripgrep), xem tài nguyên máy (btop), ví dụ dùng lệnh ngắn gọn (tealdeer: lệnh tldr),
    # trang hướng dẫn (man-db), git, trình soạn thảo nano
    fish starship fastfetch eza bat zoxide fzf ripgrep btop tealdeer man-db man-pages git nano
    # phông của Windows Terminal (Cascadia Mono), chọn trong Cài đặt → Giao diện → Terminal
    ttf-cascadia-code
    # âm thanh, mạng, bluetooth, pin
    pipewire pipewire-pulse wireplumber networkmanager bluez bluez-utils upower
    pavucontrol nm-connection-editor
    # chụp màn hình, bộ nhớ tạm, lấy màu
    grim slurp wl-clipboard cliphist hyprpicker
    # giữ nội dung vừa chép khi đóng ứng dụng đã chép nó (Wayland vốn làm mất)
    wl-clip-persist
    # cắm USB là tự gắn ổ và báo thông báo
    udisks2 udiskie
    # tắt máy / khởi động lại / đăng xuất êm: đóng từng ứng dụng cho chúng kịp lưu rồi mới thoát
    hyprshutdown
    # bộ văn phòng (mở được Word, Excel, PowerPoint), giao diện tiếng Việt, chính tả tiếng Anh
    # (kho Arch chưa có từ điển chính tả tiếng Việt)
    libreoffice-fresh libreoffice-fresh-vi hunspell hunspell-en_us
    # in và quét: CUPS, dò máy in trong mạng, driver HP và máy in cũ, quét không cần driver
    cups cups-pdf cups-pk-helper system-config-printer avahi nss-mdns ipp-usb hplip gutenprint
    sane sane-airscan simple-scan
    # USB, thẻ nhớ, ổ của Windows: đọc ghi exFAT / NTFS / FAT32, ứng dụng Ổ đĩa để định dạng
    exfatprogs ntfs-3g dosfstools gnome-disk-utility
    # điểm khôi phục hệ thống (config/hypr/scripts/setup-system.sh), nén RAM
    timeshift cronie zram-generator
    # tường lửa: chặn kết nối từ ngoài vào (bật ở bước 8, setup-system.sh)
    ufw
    # phím Fn và nhạc
    brightnessctl playerctl
    # đảo động và trung tâm điều khiển: sóng âm, ánh sáng đêm, tiết kiệm pin
    cava hyprsunset power-profiles-daemon
    # khóa màn hình, tự khóa, màn hình đăng nhập
    hyprlock hypridle sddm
    # sửa ảnh chụp, quay màn hình, đọc chữ trong ảnh (tiếng Việt và tiếng Anh)
    satty wf-recorder libpulse tesseract tesseract-data-vie tesseract-data-eng
    # ảnh thu nhỏ của hình nền video (Cài đặt → Hình nền)
    ffmpeg
    # ứng dụng cơ bản: xem ảnh, xem video, đọc PDF, soạn văn bản, máy tính, giải nén, quản lý tác vụ
    loupe celluloid papers gnome-text-editor gnome-calculator file-roller 7zip unrar unzip mission-center
    # xem nhanh tệp bằng phím Space trong trình quản lý tệp (như Quick Look); gst-plugins-good và
    # gst-libav để xem được video mp4/mkv, webkitgtk-6.0 để xem trang HTML
    sushi gst-plugins-good gst-libav webkitgtk-6.0
    # cắm USB, điện thoại, máy ảnh là hiện trong Tệp
    gvfs gvfs-mtp gvfs-gphoto2 udisks2
    # phông tương thích Arial / Times New Roman cho tài liệu từ Windows
    ttf-liberation
    # kiểm tra cập nhật, kho ứng dụng (Flathub)
    pacman-contrib gnome-software flatpak
    # tiện ích (pciutils: nhận card đồ hoạ)
    fd jq libnotify xdg-utils xdg-user-dirs pciutils
    # bộ gõ tiếng Việt
    fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-unikey
    # phông chữ và biểu tượng
    inter-font ttf-jetbrains-mono noto-fonts noto-fonts-cjk noto-fonts-emoji papirus-icon-theme
    # giao diện tối cho ứng dụng GTK và Qt
    adw-gtk-theme qt6ct
)

bold "1. Cài gói từ kho chính thức"
info "${#PKGS[@]} gói, gói nào có rồi sẽ được bỏ qua. Bước này bắt buộc: thiếu gói là màn hình đen."
if ask_y "Cập nhật máy và cài bằng sudo pacman?"; then
    # Arch không hỗ trợ cập nhật một phần: cài gói mới lên hệ thống chưa cập nhật dễ vỡ phụ thuộc
    # (pacman từ chối cả loạt). Nên cập nhật cả máy trước, rồi mới lọc và cài.
    # khoá ký gói trước: máy cài từ ISO cũ hay báo "invalid or corrupted package (PGP signature)"
    sudo pacman -Sy --needed --noconfirm archlinux-keyring || warn "Chưa cập nhật được archlinux-keyring."
    sudo pacman -Su || warn "Cập nhật máy chưa xong; vẫn thử cài các gói."
    # Một tên gói không còn trong kho (bị đổi tên, bị gỡ) sẽ làm pacman từ chối cài TẤT CẢ.
    # Lọc trước: gói nào kho không có thì báo ra và bỏ qua, phần còn lại vẫn cài.
    mapfile -t AVAILABLE < <(pacman -Slq 2>/dev/null | sort -u)
    WANT=("${PKGS[@]}") MISSING=()
    if ((${#AVAILABLE[@]} > 0)); then
        WANT=()
        for p in "${PKGS[@]}"; do
            if printf '%s\n' "${AVAILABLE[@]}" | grep -qxF -- "$p"; then WANT+=("$p"); else MISSING+=("$p"); fi
        done
        if ((${#MISSING[@]} > 0)); then
            warn "Kho không có các gói này (có thể đã đổi tên), bỏ qua: ${MISSING[*]}"
            warn "Phần dùng tới chúng sẽ không chạy cho tới khi bạn cài gói thay thế."
        fi
    fi
    if ! sudo pacman -S --needed "${WANT[@]}"; then
        # cả loạt bị từ chối (xung đột gói, bấm nhầm n…): cài từng gói để biết đúng gói nào lỗi
        warn "pacman chưa cài được cả loạt. Cài từng gói để tìm gói gây lỗi…"
        FAILED=()
        for p in "${WANT[@]}"; do
            pacman -Q "$p" >/dev/null 2>&1 && continue
            if ! err="$(sudo pacman -S --needed --noconfirm "$p" 2>&1 >/dev/null)"; then
                FAILED+=("$p")
                warn "  $p: $(grep -m1 -iE 'error|lỗi|conflict|xung đột' <<< "$err" || tail -n 1 <<< "$err")"
            fi
        done
        if ((${#FAILED[@]} > 0)); then
            warn "Chưa cài được: ${FAILED[*]}"
            warn "Thường là xung đột với một gói đang có. Cài tay để xem pacman hỏi gì:  sudo pacman -S ${FAILED[*]}"
        else
            info "Đã cài xong từng gói."
        fi
    fi
else
    warn "Bỏ qua. Các phần cần gói còn thiếu sẽ không chạy (thanh trên, hình nền… sẽ không hiện)."
fi
echo
if ((ONLY_PKGS)); then
    check_need && info "Khởi động lại máy (gõ reboot) rồi đăng nhập." || true
    exit 0
fi

# ───────────────────────── AUR (tuỳ chọn) ─────────────────────────
bold "2. Gói AUR: trình duyệt Microsoft Edge; tuỳ chọn: hình nền video (mpvpaper), thông tin máy (hyprsysteminfo)"
AUR=""
command -v paru >/dev/null 2>&1 && AUR=paru
command -v yay  >/dev/null 2>&1 && AUR=yay
if [[ -z "$AUR" ]]; then
    info "Chưa có trình cài gói AUR (yay hoặc paru)."
    info "Microsoft Edge (trình duyệt của bộ này) có trên AUR; không có yay thì sẽ cài bản Flathub."
    if ask "Cài yay để dùng được gói AUR?"; then
        sudo pacman -S --needed git base-devel
        tmp="$(mktemp -d)"
        if git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin" && (cd "$tmp/yay-bin" && makepkg -si); then
            AUR=yay
        else
            warn "Không cài được yay (kiểm tra mạng). Bỏ qua phần AUR."
        fi
        rm -rf "$tmp"
    fi
fi
# Microsoft Edge: trình duyệt duy nhất của bộ này. Gói AUR đóng gói lại bản .deb chính thức của
# Microsoft (tự cập nhật cùng hệ thống); không được thì dùng bản Flathub.
EDGE_DESKTOP=""
if pacman -Qq microsoft-edge-stable-bin >/dev/null 2>&1; then
    EDGE_DESKTOP=microsoft-edge.desktop
    info "Đã có Microsoft Edge"
elif [[ -n "$AUR" ]]; then
    info "Cài Microsoft Edge (microsoft-edge-stable-bin) bằng $AUR"
    if "$AUR" -S --needed microsoft-edge-stable-bin; then
        EDGE_DESKTOP=microsoft-edge.desktop
    else
        warn "Không cài được Edge từ AUR."
    fi
fi
if [[ -z "$EDGE_DESKTOP" ]] && command -v flatpak >/dev/null 2>&1; then
    info "Cài Microsoft Edge từ Flathub (com.microsoft.Edge, cho riêng tài khoản của bạn)"
    if flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null \
        && flatpak install --user -y --noninteractive flathub com.microsoft.Edge; then
        EDGE_DESKTOP=com.microsoft.Edge.desktop
    fi
fi
if [[ -n "$EDGE_DESKTOP" ]]; then
    # Edge chạy thẳng trên Wayland (chữ nét khi phóng to màn hình) và gõ tiếng Việt bằng fcitx5.
    # Lệnh mở Edge đọc file này, mỗi dòng một cờ; không được có dòng chú thích.
    EDGE_FLAGS="$CONFIG/microsoft-edge-stable-flags.conf"
    if [[ ! -f "$EDGE_FLAGS" ]]; then
        printf '%s\n' --ozone-platform-hint=auto --enable-wayland-ime --wayland-text-input-version=3 > "$EDGE_FLAGS"
    fi
    # bản cũ của bộ này cài Firefox; chỉ giữ một trình duyệt
    OTHER_BROWSERS=()
    for b in firefox firefox-developer-edition chromium epiphany falkon vivaldi; do
        pacman -Qq "$b" >/dev/null 2>&1 && OTHER_BROWSERS+=("$b")
    done
    if ((${#OTHER_BROWSERS[@]} > 0)) && ask "Gỡ trình duyệt khác (${OTHER_BROWSERS[*]}) để chỉ dùng Edge? Dấu trang, mật khẩu vẫn còn trong thư mục cá nhân"; then
        sudo pacman -Rns "${OTHER_BROWSERS[@]}" || warn "Chưa gỡ được ${OTHER_BROWSERS[*]}"
    fi
else
    warn "Chưa cài được Microsoft Edge (kiểm tra mạng rồi chạy lại script). Super + B sẽ chưa mở được trình duyệt."
fi

if [[ -n "$AUR" ]] && ask "Cài mpvpaper bằng $AUR?"; then
    "$AUR" -S --needed mpvpaper || warn "Không cài được mpvpaper; hình nền video sẽ chưa dùng được."
else
    info "Bỏ qua. Ảnh tĩnh và ảnh GIF vẫn dùng được; video cần mpvpaper."
fi
# cửa sổ thông tin máy của nhóm Hyprland: menu hệ thống → Giới thiệu máy này
if [[ -n "$AUR" ]] && ask "Cài hyprsysteminfo (cửa sổ thông tin máy) bằng $AUR?"; then
    "$AUR" -S --needed hyprsysteminfo || warn "Không cài được hyprsysteminfo; Giới thiệu máy này sẽ mở trang Giới thiệu trong Cài đặt."
fi
echo

# ───────────────────────── chép cấu hình ─────────────────────────
bold "3. Chép cấu hình vào $CONFIG"

backup_if_exists() {
    local path="$1"
    if [[ -e "$path" ]]; then
        mkdir -p "$BACKUP"
        cp -a "$path" "$BACKUP/"
        info "Đã sao lưu $(basename "$path") → $BACKUP/"
    fi
}

for dir in hypr quickshell kitty; do
    backup_if_exists "$CONFIG/$dir"
done

# hypr: giữ lại user.lua của bạn nếu đã có
mkdir -p "$CONFIG/hypr"
user_lua=""
[[ -f "$CONFIG/hypr/user.lua" ]] && user_lua="$(cat "$CONFIG/hypr/user.lua")"
# Hyprland 0.57 không còn đọc hyprland.conf; bỏ file cũ (đã sao lưu ở trên) để khỏi nhầm
rm -f "$CONFIG/hypr/hyprland.conf"
cp -a "$HERE/config/hypr/." "$CONFIG/hypr/"
if [[ -n "$user_lua" ]]; then
    printf '%s\n' "$user_lua" > "$CONFIG/hypr/user.lua"
elif [[ ! -f "$CONFIG/hypr/user.lua" ]]; then
    printf -- '-- Chỉnh sửa riêng của bạn. Script cài đặt không ghi đè file này.\n' > "$CONFIG/hypr/user.lua"
fi
chmod +x "$CONFIG/hypr/scripts/"*.sh

mkdir -p "$CONFIG/quickshell" "$CONFIG/kitty"
cp -a "$HERE/config/quickshell/." "$CONFIG/quickshell/"
# shader của kính và hiệu ứng thu nhỏ: dựng lại bằng qsb của máy (khớp đúng bản Qt đang cài)
bash "$CONFIG/quickshell/shaders/build.sh" || warn "Không dựng lại được shader, dùng bản có sẵn"
cp -a "$HERE/config/kitty/." "$CONFIG/kitty/"
info "Đã chép hypr, quickshell, kitty"

# terminal: fish (chỉ thêm một file trong conf.d, config.fish của bạn giữ nguyên), starship, fastfetch, btop
mkdir -p "$CONFIG/fish/conf.d" "$CONFIG/fastfetch"
cp "$HERE/config/fish/conf.d/liquid-glass.fish" "$CONFIG/fish/conf.d/"
# starship và fastfetch: file cũ của bạn (nếu khác) được sao lưu trước khi thay
copy_conf() {
    local src="$HERE/config/$1" dst="$CONFIG/$2"
    [[ -f "$dst" ]] && ! cmp -s "$src" "$dst" && backup_if_exists "$dst"
    cp "$src" "$dst"
}
copy_conf starship/starship.toml starship.toml
copy_conf fastfetch/config.jsonc fastfetch/config.jsonc
# btop: nền trong để thấy kính phía sau (btop tự điền phần còn lại khi mở lần đầu)
if [[ ! -f "$CONFIG/btop/btop.conf" ]]; then
    mkdir -p "$CONFIG/btop"
    printf '%s\n' 'color_theme = "Default"' 'theme_background = false' 'truecolor = true' 'rounded_corners = true' > "$CONFIG/btop/btop.conf"
fi
# Shell đăng nhập vẫn là bash (script, tài liệu trên mạng đều viết cho bash); kitty tự mở fish.
# Lệnh cài cho riêng tài khoản (claude...) nằm ở ~/.local/bin: thêm vào PATH của bash.
if [[ -f "$HOME/.bashrc" ]] && ! grep -q '\.local/bin' "$HOME/.bashrc"; then
    printf '\n# Liquid Glass: lệnh cài cho riêng tài khoản (claude...)\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$HOME/.bashrc"
fi
# ví dụ dùng lệnh cho tldr (tải một lần, cần mạng)
command -v tldr >/dev/null 2>&1 && { tldr --update >/dev/null 2>&1 || true; }
info "Terminal: fish, starship, fastfetch (cấu hình ở ~/.config/fish/conf.d/liquid-glass.fish)"

# Claude Code: trợ lý lập trình AI của Anthropic, chạy trong terminal (gõ claude, hoặc mở "Claude Code"
# trong launcher). Cài bằng bộ cài chính thức vào ~/.local/bin cho riêng tài khoản (không cần sudo),
# tự cập nhật về sau. Lần đầu mở sẽ hỏi đăng nhập trong trình duyệt: cần tài khoản Claude Pro, Max,
# Team, Enterprise hoặc Claude Console. Script này không đăng nhập hộ.
if [[ -x "$HOME/.local/bin/claude" ]] || command -v claude >/dev/null 2>&1; then
    info "Đã có Claude Code (tự cập nhật; kiểm tra bằng: claude doctor)"
else
    info "Cài Claude Code bằng bộ cài chính thức (curl -fsSL https://claude.ai/install.sh | bash)"
    if curl -fsSL https://claude.ai/install.sh | bash; then
        info "Đã cài Claude Code. Mở terminal mới rồi gõ: claude"
    else
        warn "Chưa cài được Claude Code (kiểm tra mạng). Cài lại sau bằng: curl -fsSL https://claude.ai/install.sh | bash"
    fi
fi

# ứng dụng Cài đặt: thêm vào launcher (tìm "Cài đặt")
mkdir -p "$HOME/.local/share/applications"
cp "$HERE/config/applications/"*.desktop "$HOME/.local/share/applications/"
# file lựa chọn do ứng dụng Cài đặt ghi; tạo sẵn bản rỗng để Hyprland theo dõi nó ngay từ đầu
[[ -f "$CONFIG/hypr/lg_settings.lua" ]] || printf 'return {}\n' > "$CONFIG/hypr/lg_settings.lua"

# hình nền mặc định
mkdir -p "$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots"
# chỉ chép tệp (bỏ thư mục src/ chứa mã dựng hình nền), không ghi đè tệp bạn đã có
find "$HERE/wallpapers" -maxdepth 1 -type f -exec cp -n -t "$HOME/Pictures/Wallpapers/" {} + 2>/dev/null || true
info "Hình nền: ~/Pictures/Wallpapers"

# bộ gõ: thêm Unikey nếu chưa có cấu hình fcitx5
FCITX="$CONFIG/fcitx5/profile"
if [[ ! -f "$FCITX" ]]; then
    mkdir -p "$(dirname "$FCITX")"
    cat > "$FCITX" <<'EOF'
[Groups/0]
Name=Default
Default Layout=us
DefaultIM=unikey

[Groups/0/Items/0]
Name=keyboard-us
Layout=

[Groups/0/Items/1]
Name=unikey
Layout=

[GroupOrder]
0=Default
EOF
    info "Bộ gõ: thêm Unikey (đổi Anh/Việt bằng Ctrl + Space)"
fi
echo

# ───────────────────────── phông chữ ─────────────────────────
# Geist, Geist Mono, Open Sans, Be Vietnam Pro, Onest (giấy phép SIL OFL, đủ dấu tiếng Việt).
# Cài cho cả máy để màn hình đăng nhập (chạy bằng tài khoản sddm) cũng dùng được.
FONT_DIR=/usr/local/share/fonts/liquid-glass
if sudo mkdir -p "$FONT_DIR" && sudo cp -r "$HERE/fonts/." "$FONT_DIR/"; then
    fc-cache -f >/dev/null 2>&1 || true
    info "Đã cài phông Geist, Open Sans, Be Vietnam Pro, Onest (đổi trong Cài đặt → Giao diện)"
else
    warn "Chưa cài được phông chữ (cần sudo). Giao diện sẽ dùng phông dự phòng; chạy lại script để cài."
fi
echo

# ───────────────────────── ứng dụng mặc định ─────────────────────────
# Mở ảnh, video, PDF... bằng ứng dụng nào. Đổi lại trong Cài đặt → Ứng dụng mặc định.
if command -v xdg-mime >/dev/null 2>&1; then
    setdef() { local app="$1"; shift; xdg-mime default "$app" "$@" 2>/dev/null || true; }
    [[ -n "${EDGE_DESKTOP:-}" ]] && setdef "$EDGE_DESKTOP" text/html application/xhtml+xml x-scheme-handler/http x-scheme-handler/https
    setdef org.gnome.Nautilus.desktop inode/directory
    setdef org.gnome.Loupe.desktop image/png image/jpeg image/webp image/gif image/bmp image/tiff image/avif image/heic image/svg+xml
    # tài liệu văn phòng (Word, Excel, PowerPoint, OpenDocument): LibreOffice
    setdef libreoffice-writer.desktop application/vnd.openxmlformats-officedocument.wordprocessingml.document application/msword application/vnd.oasis.opendocument.text application/rtf
    setdef libreoffice-calc.desktop application/vnd.openxmlformats-officedocument.spreadsheetml.sheet application/vnd.ms-excel application/vnd.oasis.opendocument.spreadsheet text/csv
    setdef libreoffice-impress.desktop application/vnd.openxmlformats-officedocument.presentationml.presentation application/vnd.ms-powerpoint application/vnd.oasis.opendocument.presentation
    setdef io.github.celluloid_player.Celluloid.desktop video/mp4 video/x-matroska video/webm video/quicktime video/x-msvideo video/mpeg \
        audio/mpeg audio/flac audio/ogg audio/x-wav audio/mp4 audio/aac
    setdef org.gnome.Papers.desktop application/pdf
    setdef org.gnome.TextEditor.desktop text/plain text/markdown
    setdef org.gnome.FileRoller.desktop application/zip application/x-7z-compressed application/vnd.rar \
        application/x-tar application/gzip application/x-compressed-tar application/x-xz-compressed-tar
    info "Đã chọn ứng dụng mặc định cho ảnh, video, PDF, văn bản, tệp nén"
fi

# Kho ứng dụng: GNOME Software lấy ứng dụng từ Flathub (cài cho riêng bạn, không cần sudo)
if command -v flatpak >/dev/null 2>&1; then
    if flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null; then
        info "Đã thêm Flathub cho kho ứng dụng (mở \"Phần mềm\" trong launcher)"
    else
        warn "Chưa thêm được Flathub (kiểm tra mạng), chạy lại script sau."
    fi
fi
echo

# ───────────────────────── giao diện tối cho ứng dụng ─────────────────────────
bold "4. Giao diện cho ứng dụng (GTK, Qt, Flatpak) và thư mục"
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface font-name 'Geist 11' || true
    gsettings set org.gnome.desktop.interface monospace-font-name 'Geist Mono 11' || true
fi
# Qt: phông chữ (qt6ct.conf chỉ tạo khi chưa có; bảng màu và biểu tượng do theme-apps.sh đặt)
QT6CT="$CONFIG/qt6ct/qt6ct.conf"
if [[ ! -f "$QT6CT" ]]; then
    mkdir -p "$(dirname "$QT6CT")"
    cat > "$QT6CT" <<'QTEOF'
[Appearance]
standard_dialogs=xdgdesktopportal

[Fonts]
general="Geist,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
fixed="Geist Mono,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
QTEOF
fi
# màu GTK/Qt, Flatpak đọc được theme, màu thư mục (đổi trong Cài đặt → Giao diện), lối tắt thanh bên
bash "$CONFIG/hypr/scripts/theme-apps.sh" all || warn "Chưa xong phần giao diện ứng dụng; chạy lại: ~/.config/hypr/scripts/theme-apps.sh all"
echo

# ───────────────────────── dịch vụ ─────────────────────────
bold "5. Bật mạng, bluetooth và chế độ tiết kiệm pin khi khởi động"
if ask "Bật NetworkManager, bluetooth, power-profiles-daemon (sudo systemctl enable)?"; then
    sudo systemctl enable --now NetworkManager.service || warn "Không bật được NetworkManager"
    sudo systemctl enable --now bluetooth.service || warn "Không bật được bluetooth"
    sudo systemctl enable --now power-profiles-daemon.service || warn "Không bật được power-profiles-daemon"
fi

# Quickshell tự nhận thông báo. Trình thông báo khác đang chạy sẽ giành mất.
for d in mako dunst swaync; do
    if pacman -Qq "$d" >/dev/null 2>&1; then
        warn "Đang cài $d. Gỡ nó (sudo pacman -R $d) để thông báo hiện trên đảo động."
    fi
done
echo

# ───────────────────────── card NVIDIA ─────────────────────────
# Không có card NVIDIA thì script tự bỏ qua, không hỏi gì.
bold "6. Card đồ hoạ"
bash "$HERE/nvidia/setup-nvidia.sh" || warn "Phần NVIDIA chưa xong; chạy lại: ./nvidia/setup-nvidia.sh"
echo

# ───────────────────────── màn hình đăng nhập ─────────────────────────
bold "7. Màn hình đăng nhập (SDDM)"
THEME_DIR=/usr/share/sddm/themes/liquid-glass
if ask "Cài theme đăng nhập Liquid Glass vào $THEME_DIR (cần sudo)?"; then
    sudo mkdir -p "$THEME_DIR"
    sudo cp -a "$HERE/sddm/liquid-glass/." "$THEME_DIR/"
    sudo mkdir -p /etc/sddm.conf.d
    printf '[Theme]\nCurrent=liquid-glass\n' | sudo tee /etc/sddm.conf.d/10-liquid-glass.conf >/dev/null
    info "Đã cài theme. Thử mà không cần đăng xuất:"
    info "  sddm-greeter-qt6 --test-mode --theme $THEME_DIR"

    # ảnh đại diện: SDDM không đọc được thư mục nhà, nên chép ~/.face sang chỗ SDDM đọc được
    if [[ -f "$HOME/.face" ]]; then
        sudo mkdir -p /usr/share/sddm/faces
        sudo cp "$HOME/.face" "/usr/share/sddm/faces/$USER.face.icon"
        info "Đã dùng ~/.face làm ảnh đại diện"
    else
        info "Muốn có ảnh đại diện: lưu một ảnh vuông thành ~/.face rồi chạy lại script."
    fi

    # bật SDDM nếu máy chưa dùng trình đăng nhập nào khác
    current_dm="$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null || true)"
    if [[ -z "$current_dm" ]]; then
        if ask "Bật SDDM khi khởi động máy?"; then
            sudo systemctl enable sddm.service
        fi
    elif [[ "$current_dm" != *sddm.service ]]; then
        warn "Máy đang dùng trình đăng nhập khác: $(basename "$current_dm")"
        info "Muốn đổi sang SDDM:  sudo systemctl disable $(basename "$current_dm") && sudo systemctl enable sddm.service"
    else
        info "SDDM đã được bật."
    fi
fi
echo

# ───────────────────────── máy in, điểm khôi phục, zram, dọn gói, tường lửa ─────────────────────────
bold "8. Máy in, điểm khôi phục hệ thống, nén RAM, dọn gói cũ, tường lửa"
bash "$HERE/config/hypr/scripts/setup-system.sh" || warn "Phần này chưa xong; chạy lại: ~/.config/hypr/scripts/setup-system.sh"
echo

# ───────────────────────── màn hình khởi động ─────────────────────────
bold "9. Màn hình khởi động (Plymouth)"
info "Chữ hello tự viết rồi chuyển thành chữ ký, hiện lúc bật máy, nhập mật khẩu ổ đĩa và tắt máy."
if ask "Cài màn hình khởi động? (sẽ hỏi trước khi sửa mkinitcpio và dòng lệnh kernel)"; then
    bash "$HERE/plymouth/install-plymouth.sh" || warn "Phần màn hình khởi động chưa xong; chạy lại: ./plymouth/install-plymouth.sh"
fi
echo

check_need || true

bold "Xong cả 5 đợt."
cat <<'EOF'

  Bước tiếp theo:
    • Đăng xuất, rồi chọn phiên "Hyprland" ở màn hình đăng nhập.
      Nếu đang ở màn hình chữ (TTY), gõ:  start-hyprland
    • Super + Enter   mở terminal
    • Super + Space   mở launcher
    • Super + Q       đóng cửa sổ
    • Super + W / N   bảng widget / trung tâm điều khiển
    • Super + L       khóa màn hình
    • Super + Esc     menu nguồn
    • Super + Tab     toàn cảnh workspace
    • Super + /       bảng phím tắt (xem hết các phím ở đây)
    • Super + ,       Cài đặt (giao diện, hình nền, touchpad, Wi-Fi, thời tiết)
    • Super + Shift + S   chụp và quay màn hình
    • Super + Shift + Esc   thoát Hyprland ngay (dự phòng)

  Có lỗi cấu hình thì Hyprland hiện thông báo đỏ ở góc màn hình.
  Xem README.md để biết cách sửa.
EOF
