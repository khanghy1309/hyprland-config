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
    hyprland xdg-desktop-portal-hyprland hyprpolkitagent quickshell qt6-5compat
    # hình nền
    awww
    # terminal, tệp, trình duyệt
    kitty nautilus firefox
    # âm thanh, mạng, bluetooth, pin
    pipewire pipewire-pulse wireplumber networkmanager bluez bluez-utils upower
    pavucontrol nm-connection-editor
    # chụp màn hình, bộ nhớ tạm, lấy màu
    grim slurp wl-clipboard cliphist hyprpicker
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
    # cắm USB, điện thoại, máy ảnh là hiện trong Tệp
    gvfs gvfs-mtp gvfs-gphoto2 udisks2
    # phông tương thích Arial / Times New Roman cho tài liệu từ Windows
    ttf-liberation
    # kiểm tra cập nhật, kho ứng dụng (Flathub)
    pacman-contrib gnome-software flatpak
    # tiện ích
    fd jq libnotify xdg-utils xdg-user-dirs
    # bộ gõ tiếng Việt
    fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-unikey
    # phông chữ và biểu tượng
    inter-font ttf-jetbrains-mono noto-fonts noto-fonts-cjk noto-fonts-emoji papirus-icon-theme
    # giao diện tối cho ứng dụng GTK và Qt
    adw-gtk-theme qt6ct
)

bold "1. Cài gói từ kho chính thức"
info "${#PKGS[@]} gói, gói nào có rồi sẽ được bỏ qua"
if ask "Cài bằng sudo pacman?"; then
    sudo pacman -S --needed "${PKGS[@]}"
else
    warn "Bỏ qua. Các phần cần gói còn thiếu sẽ không chạy."
fi
echo

# ───────────────────────── AUR (tuỳ chọn) ─────────────────────────
bold "2. Hình nền video (mpvpaper, từ AUR) — tuỳ chọn"
AUR=""
command -v paru >/dev/null 2>&1 && AUR=paru
command -v yay  >/dev/null 2>&1 && AUR=yay
if [[ -z "$AUR" ]]; then
    info "Chưa có trình cài gói AUR (yay hoặc paru)."
    if ask "Cài yay để dùng được gói AUR?"; then
        sudo pacman -S --needed git base-devel
        tmp="$(mktemp -d)"
        git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
        (cd "$tmp/yay-bin" && makepkg -si)
        rm -rf "$tmp"
        AUR=yay
    fi
fi
if [[ -n "$AUR" ]] && ask "Cài mpvpaper bằng $AUR?"; then
    "$AUR" -S --needed mpvpaper
else
    info "Bỏ qua. Ảnh tĩnh và ảnh GIF vẫn dùng được; video cần mpvpaper."
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
cp -a "$HERE/config/kitty/." "$CONFIG/kitty/"
info "Đã chép hypr, quickshell, kitty"

# ứng dụng Cài đặt: thêm vào launcher (tìm "Cài đặt")
mkdir -p "$HOME/.local/share/applications"
cp "$HERE/config/applications/"*.desktop "$HOME/.local/share/applications/"
# file lựa chọn do ứng dụng Cài đặt ghi; tạo sẵn bản rỗng để Hyprland theo dõi nó ngay từ đầu
[[ -f "$CONFIG/hypr/lg_settings.lua" ]] || printf 'return {}\n' > "$CONFIG/hypr/lg_settings.lua"

# hình nền mặc định
mkdir -p "$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots"
cp -n "$HERE/wallpapers/"* "$HOME/Pictures/Wallpapers/" 2>/dev/null || true
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
# Geist, Geist Mono, Be Vietnam Pro, Onest (giấy phép SIL OFL, đủ dấu tiếng Việt).
# Cài cho cả máy để màn hình đăng nhập (chạy bằng tài khoản sddm) cũng dùng được.
FONT_DIR=/usr/local/share/fonts/liquid-glass
sudo mkdir -p "$FONT_DIR"
sudo cp -r "$HERE/fonts/." "$FONT_DIR/"
fc-cache -f >/dev/null 2>&1 || true
info "Đã cài phông Geist, Be Vietnam Pro, Onest (đổi trong Cài đặt → Giao diện)"
echo

# ───────────────────────── ứng dụng mặc định ─────────────────────────
# Mở ảnh, video, PDF... bằng ứng dụng nào. Đổi lại trong Cài đặt → Ứng dụng mặc định.
if command -v xdg-mime >/dev/null 2>&1; then
    setdef() { local app="$1"; shift; xdg-mime default "$app" "$@" 2>/dev/null || true; }
    setdef firefox.desktop text/html x-scheme-handler/http x-scheme-handler/https
    setdef org.gnome.Nautilus.desktop inode/directory
    setdef org.gnome.Loupe.desktop image/png image/jpeg image/webp image/gif image/bmp image/tiff image/avif image/heic image/svg+xml
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
bold "4. Giao diện tối cho ứng dụng GTK"
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' || true
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' || true
    gsettings set org.gnome.desktop.interface font-name 'Geist 11' || true
    gsettings set org.gnome.desktop.interface monospace-font-name 'Geist Mono 11' || true
    info "Đã đặt chế độ tối, biểu tượng Papirus, phông Geist"
else
    warn "Không có gsettings, bỏ qua."
fi

# Ứng dụng Qt (và launcher của Quickshell) lấy bộ biểu tượng từ qt6ct
QT6CT="$CONFIG/qt6ct/qt6ct.conf"
if [[ ! -f "$QT6CT" ]]; then
    mkdir -p "$(dirname "$QT6CT")"
    cat > "$QT6CT" <<'QTEOF'
[Appearance]
icon_theme=Papirus-Dark
style=Fusion
standard_dialogs=default

[Fonts]
general="Geist,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
fixed="Geist Mono,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
QTEOF
    info "Qt: biểu tượng Papirus-Dark, kiểu Fusion"
fi
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

# ───────────────────────── màn hình đăng nhập ─────────────────────────
bold "6. Màn hình đăng nhập (SDDM)"
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
