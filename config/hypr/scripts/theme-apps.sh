#!/usr/bin/env bash
# Cho ứng dụng (GTK, Qt, Flatpak) và thư mục cùng một giao diện với Liquid Glass.
#
#   theme-apps.sh all              làm hết các phần dưới (install.sh gọi lệnh này)
#   theme-apps.sh gtk              bảng màu cho ứng dụng GTK 3 / GTK 4, thanh bên Nautilus kính mờ
#   theme-apps.sh qt               bảng màu tối cho ứng dụng Qt 6 (qt6ct)
#   theme-apps.sh flatpak          cho ứng dụng Flatpak đọc theme, cài theme adw-gtk3 bản Flatpak
#   theme-apps.sh folders <màu>    màu thư mục: blue (mặc định của Papirus), violet, grey, bluegrey,
#                                  nordic, pink, teal, indigo, green, yellow, orange, red, black
#   theme-apps.sh bookmarks        lối tắt ở thanh bên trình quản lý tệp (chỉ tạo khi chưa có)
#
# Không cần sudo. Mọi thứ nằm trong thư mục nhà; tệp của bạn có sẵn thì được giữ (chỉ thêm một dòng
# @import vào gtk.css, có sao lưu). Chạy lại bao nhiêu lần cũng được.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_SRC="$HERE/../theme"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
SETTINGS="$CONFIG/quickshell/settings.json"
STAMP="$(date +%Y%m%d-%H%M%S)"

info() { printf '  • %s\n' "$*"; }
warn() { printf '\033[33m  ! %s\033[0m\n' "$*" >&2; }

# ── GTK ──
# thêm  @import url("liquid-glass.css");  vào đầu gtk.css (tạo gtk.css nếu chưa có)
link_css() {
    local dir="$1" src="$2" css="$1/gtk.css" line='@import url("liquid-glass.css");'
    mkdir -p "$dir"
    cp "$src" "$dir/liquid-glass.css"
    if [[ -L $css ]]; then
        # gtk.css là liên kết (một số công cụ theme tạo vậy): không đụng vào, chỉ báo
        grep -qF "$line" "$css" 2>/dev/null || warn "$css là liên kết tới tệp khác; tự thêm dòng: $line"
        return
    fi
    if [[ ! -f $css ]]; then
        printf '%s\n\n/* CSS riêng của bạn đặt dưới dòng này */\n' "$line" > "$css"
    elif ! grep -qF "$line" "$css"; then
        cp -a "$css" "$css.bak-liquid-glass-$STAMP"
        { printf '%s\n' "$line"; cat "$css.bak-liquid-glass-$STAMP"; } > "$css"
    fi
}
do_gtk() {
    link_css "$CONFIG/gtk-4.0" "$THEME_SRC/gtk4.css"
    link_css "$CONFIG/gtk-3.0" "$THEME_SRC/gtk3.css"
    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null
        # màu nhấn gần nhất trong danh sách của GNOME, cho ứng dụng không đọc được CSS ở trên
        gsettings set org.gnome.desktop.interface accent-color 'slate' 2>/dev/null
    fi
    info "GTK: bảng màu Liquid Glass, thanh bên Nautilus kính mờ (mở lại ứng dụng để thấy)"
}

# ── Qt ──
# đặt khoá=giá trị trong một mục [section] của tệp ini (tạo nếu chưa có)
ini_set() {
    local file="$1" section="$2" key="$3" value="$4" tmp
    mkdir -p "$(dirname "$file")"
    touch "$file"
    tmp="$(mktemp)"
    awk -v s="[$section]" -v k="$key" -v v="$value" '
        BEGIN { insec = 0; done = 0; seen = 0 }
        /^\[.*\]$/ {
            if (insec && !done) { print k "=" v; done = 1 }
            insec = ($0 == s); if (insec) seen = 1
            print; next
        }
        insec && index($0, k "=") == 1 { if (!done) { print k "=" v; done = 1 } ; next }
        { print }
        END {
            if (!seen) { print ""; print s; print k "=" v }
            else if (insec && !done) print k "=" v
        }' "$file" > "$tmp" && cat "$tmp" > "$file"
    rm -f "$tmp"
}
do_qt() {
    local conf="$CONFIG/qt6ct/qt6ct.conf" colors="$CONFIG/qt6ct/colors/liquid-glass.conf"
    mkdir -p "$(dirname "$colors")"
    cp "$THEME_SRC/qt-colors.conf" "$colors"
    ini_set "$conf" Appearance custom_palette true
    ini_set "$conf" Appearance color_scheme_path "$colors"
    ini_set "$conf" Appearance style Fusion
    # hộp Lưu / Mở tệp: dùng hộp chung của hệ thống (kính mờ, giống ứng dụng GTK) thay vì hộp riêng của Qt
    ini_set "$conf" Appearance standard_dialogs xdgdesktopportal
    # tệp kiểu: bo tròn nút, ô nhập, danh sách, thanh trượt... (đường dẫn ảnh phải tuyệt đối)
    local qdir="$CONFIG/qt6ct/qss" img="$CONFIG/qt6ct/qss/liquid-glass"
    mkdir -p "$img"
    cp "$THEME_SRC"/qt/*.svg "$img/"
    sed "s|@DIR@|$img|g" "$THEME_SRC/qt-liquid-glass.qss" > "$qdir/liquid-glass.qss"
    ini_set "$conf" Interface stylesheets "$qdir/liquid-glass.qss"
    info "Qt: bảng màu tối và bo góc Liquid Glass (qt6ct)"
}

# ── Flatpak ──
do_flatpak() {
    if ! command -v flatpak >/dev/null 2>&1; then
        info "Flatpak chưa cài, bỏ qua."
        return
    fi
    # Ứng dụng Flatpak đã tự thấy phông chữ và bộ biểu tượng của máy (Flatpak tự cho đọc
    # /usr/share/icons, ~/.local/share/icons và các thư mục phông). Còn thiếu: CSS màu ở trên.
    # Đặt cho mọi ứng dụng (kể cả ứng dụng cài sau này), chỉ đọc.
    flatpak override --user \
        --filesystem=xdg-config/gtk-3.0:ro \
        --filesystem=xdg-config/gtk-4.0:ro \
        2>/dev/null || warn "Không đặt được quyền đọc theme cho Flatpak."
    # Ứng dụng GTK 3 trong Flatpak không dùng được theme của máy, phải có bản theme riêng trên Flathub.
    if flatpak remotes --user 2>/dev/null | grep -q '^flathub' || flatpak remotes 2>/dev/null | grep -q '^flathub'; then
        local scope=--user
        flatpak remotes --user 2>/dev/null | grep -q '^flathub' || scope=--system
        flatpak install "$scope" -y --noninteractive flathub \
            org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark >/dev/null 2>&1 \
            || warn "Chưa cài được theme adw-gtk3 cho Flatpak (cần mạng). Chạy lại: theme-apps.sh flatpak"
    else
        warn "Chưa có kho Flathub nên chưa cài theme adw-gtk3 bản Flatpak."
    fi
    info "Flatpak: ứng dụng đọc được màu Liquid Glass; ứng dụng GTK 3 dùng adw-gtk3 tối"
}

# ── màu thư mục ──
# Tạo bộ biểu tượng "Papirus-Dark-LG" trong ~/.local/share/icons: thừa hưởng Papirus-Dark,
# chỉ thay các biểu tượng thư mục bằng màu đã chọn. Chép tệp (không dùng liên kết) để ứng dụng
# Flatpak cũng thấy. Cập nhật Papirus không làm mất màu.
do_folders() {
    local color="${1:-}" src="" theme="Papirus-Dark"
    [[ -z $color ]] && color="$(jq -r '.look.folderColor // "violet"' "$SETTINGS" 2>/dev/null || echo violet)"
    for d in /usr/share/icons/Papirus "$DATA/icons/Papirus" "$HOME/.icons/Papirus"; do
        [[ -d $d ]] && { src="$d"; break; }
    done
    local dest="$DATA/icons/Papirus-Dark-LG"
    if [[ -z $src ]]; then
        warn "Chưa có bộ biểu tượng Papirus (gói papirus-icon-theme)."
        return
    fi
    if [[ $color != blue ]]; then
        if [[ ! -e "$src/48x48/places/folder-$color.svg" ]]; then
            warn "Papirus không có màu thư mục \"$color\"."
            return
        fi
        rm -rf "$dest"
        mkdir -p "$dest"
        local dirs=() size n=0
        for sub in "$src"/*/places; do
            size="$(basename "$(dirname "$sub")")"
            # biểu tượng mặc định là liên kết tới bản màu xanh (folder.svg → folder-blue.svg):
            # mỗi liên kết như vậy được thay bằng bản cùng tên của màu đã chọn
            while IFS= read -r -d '' link; do
                local target base
                target="$(readlink "$link")"
                base="$(basename "$link")"
                [[ $target == *-blue* ]] || continue
                [[ $base == *-blue* ]] && continue      # tên riêng của bản xanh (folder-blue-...): giữ nguyên
                local colored="$sub/${target//-blue/-$color}"
                [[ -e $colored ]] || continue
                mkdir -p "$dest/$size/places"
                cp -L "$colored" "$dest/$size/places/$base"
                n=$((n + 1))
            done < <(find "$sub" -maxdepth 1 -type l -print0)
            [[ -d "$dest/$size/places" ]] && dirs+=("$size/places")
        done
        {
            echo "[Icon Theme]"
            echo "Name=Papirus-Dark-LG"
            echo "Comment=Papirus-Dark với thư mục màu $color (Liquid Glass tạo)"
            echo "Inherits=Papirus-Dark,breeze-dark,hicolor"
            echo "Example=folder"
            echo "Directories=$(IFS=,; echo "${dirs[*]}")"
            for d in "${dirs[@]}"; do
                local s="${d%%/*}" scale=1
                [[ $s == *@2x ]] && { scale=2; s="${s%@2x}"; }
                echo
                echo "[$d]"
                echo "Context=Places"
                echo "Size=${s%%x*}"
                echo "Scale=$scale"
                echo "Type=Fixed"
            done
        } > "$dest/index.theme"
        gtk-update-icon-cache -q -f "$dest" 2>/dev/null || true
        theme="Papirus-Dark-LG"
        info "Thư mục màu $color ($n biểu tượng)"
    else
        rm -rf "$dest"
        info "Thư mục màu xanh mặc định của Papirus"
    fi
    command -v gsettings >/dev/null 2>&1 && gsettings set org.gnome.desktop.interface icon-theme "$theme" 2>/dev/null
    ini_set "$CONFIG/qt6ct/qt6ct.conf" Appearance icon_theme "$theme"
}

# đường dẫn → dạng URL (dấu cách, chữ có dấu... thành %xx), giữ nguyên dấu /
urlenc() {
    local LC_ALL=C s="$1" out="" c i
    for ((i = 0; i < ${#s}; i++)); do
        c="${s:i:1}"
        case "$c" in
            [a-zA-Z0-9/._~-]) out+="$c" ;;
            *) out+="$(printf '%%%02X' "'$c")" ;;
        esac
    done
    printf '%s' "$out"
}

# thư mục chuẩn (DOWNLOAD, PICTURES...) theo ngôn ngữ của máy; không có xdg-user-dir thì đọc thẳng user-dirs.dirs
userdir() {
    if command -v xdg-user-dir >/dev/null 2>&1; then
        xdg-user-dir "$1" 2>/dev/null
        return
    fi
    local line
    line="$(grep -E "^XDG_$1_DIR=" "$CONFIG/user-dirs.dirs" 2>/dev/null | head -n1)" || return 0
    line="${line#*=}"; line="${line%\"}"; line="${line#\"}"
    printf '%s' "${line/#\$HOME/$HOME}"
}

# ── lối tắt ở thanh bên ──
do_bookmarks() {
    local bm="$CONFIG/gtk-3.0/bookmarks"
    if [[ -s $bm ]]; then
        info "Đã có lối tắt riêng ($bm), giữ nguyên."
        return
    fi
    mkdir -p "$(dirname "$bm")"
    : > "$bm"
    local key label dir
    while IFS='|' read -r key label; do
        if [[ $key == "~"* ]]; then dir="${key/#\~/$HOME}"
        else
            # TÊN hoặc TÊN/thư-mục-con, TÊN là thư mục chuẩn (DOWNLOAD, PICTURES...) theo ngôn ngữ của máy
            dir="$(userdir "${key%%/*}")"
            [[ $key == */* && -n $dir ]] && dir="$dir/${key#*/}"
        fi
        [[ -n $dir && -d $dir && $dir != "$HOME" ]] || continue
        # đường dẫn dạng URL (dấu cách, chữ có dấu...)
        printf 'file://%s %s\n' "$(urlenc "$dir")" "$label" >> "$bm"
    done <<'EOF'
DOCUMENTS|Tài liệu
DOWNLOAD|Tải về
PICTURES|Ảnh
PICTURES/Screenshots|Ảnh chụp màn hình
~/Pictures/Wallpapers|Hình nền
VIDEOS|Video
MUSIC|Nhạc
~/Projects|Dự án
EOF
    info "Lối tắt ở thanh bên trình quản lý tệp: $(cut -d' ' -f2- "$bm" | paste -sd, - | sed 's/,/, /g')"
}

case "${1:-all}" in
    all) do_gtk; do_qt; do_flatpak; do_folders ""; do_bookmarks ;;
    gtk) do_gtk ;;
    qt) do_qt ;;
    flatpak) do_flatpak ;;
    folders) do_folders "${2:-}" ;;
    bookmarks) do_bookmarks ;;
    *) echo "Dùng: $0 all|gtk|qt|flatpak|folders <màu>|bookmarks" >&2; exit 2 ;;
esac
exit 0
