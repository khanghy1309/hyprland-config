# Liquid Glass — cấu hình fish đi kèm bộ cài (cài lại sẽ ghi đè file này).
# Chỉnh riêng thì viết vào ~/.config/fish/config.fish: file đó chạy sau và không bị ghi đè.

# lệnh cài cho riêng tài khoản của bạn (claude, các công cụ cài bằng pip/npm...)
fish_add_path -g ~/.local/bin

set -q EDITOR; or set -gx EDITOR nano

# mở Claude Code ở thư mục nhà (lối tắt "Claude Code" trong launcher gọi hàm này);
# thoát Claude Code (gõ /exit hoặc Ctrl + D) thì cửa sổ ở lại thành terminal thường
function lg_claude
    cd ~
    if type -q claude
        claude
    else
        echo "Chưa cài Claude Code. Cài bằng lệnh: curl -fsSL https://claude.ai/install.sh | bash"
    end
end

status is-interactive; or return

# kitty mở fish qua sh (xem kitty.conf) nên tự gắn shell integration của kitty
# (nhảy giữa các lệnh, Ctrl + Shift + G xem kết quả lệnh vừa chạy…); cách làm theo tài liệu của kitty
# (LG_KSI do kitty.conf đặt: chỉ khi fish được mở qua sh, kitty mở fish trực tiếp thì kitty tự gắn)
if set -q LG_KSI; and set -q KITTY_INSTALLATION_DIR
    set -e LG_KSI
    set --global KITTY_SHELL_INTEGRATION enabled
    source "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_conf.d/kitty-shell-integration.fish"
    set --prepend fish_complete_path "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_completions.d"
end

# ── màu khi gõ lệnh, cùng bảng màu kính với kitty ──
set -g fish_color_normal f3f6f6
set -g fish_color_command 9bd3c7
set -g fish_color_keyword c4b5fd
set -g fish_color_param f3f6f6
set -g fish_color_option c5d0d2
set -g fish_color_quote f4dcb6
set -g fish_color_redirection 8ec9ff
set -g fish_color_end 8ec9ff
set -g fish_color_operator c4b5fd
set -g fish_color_escape 7fd1d9
set -g fish_color_error f28b82
set -g fish_color_comment 7f888e
set -g fish_color_autosuggestion 6b747a
set -g fish_color_valid_path --underline
set -g fish_color_selection --background=2a2e33
set -g fish_color_search_match --background=2a2e33
set -g fish_pager_color_prefix 9bd3c7 --bold
set -g fish_pager_color_completion f3f6f6
set -g fish_pager_color_description 7f888e
set -g fish_pager_color_progress 7f888e
set -g fish_pager_color_selected_background --background=2a2e33

# ── lệnh quen thuộc, kết quả dễ nhìn hơn ──
if type -q eza
    alias ls 'eza --icons=auto --group-directories-first'
    alias ll 'eza -l --icons=auto --group-directories-first --git --time-style=+%d/%m/%Y\ %H:%M'
    alias la 'eza -la --icons=auto --group-directories-first --git --time-style=+%d/%m/%Y\ %H:%M'
    alias tree 'eza --tree --icons=auto --group-directories-first'
end
if type -q bat
    set -gx BAT_THEME ansi
    # cat vẫn in thẳng ra như cũ, chỉ thêm tô màu theo loại tệp
    alias cat 'bat --paging=never --style=plain'
    # trang hướng dẫn (man) có màu
    set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
    set -gx MANROFFOPT -c
end
# cd nhớ các thư mục bạn hay vào: "cd tai" nhảy tới ~/Downloads/tai-lieu nếu đã từng vào; cdi để chọn trong danh sách
if type -q zoxide
    zoxide init fish --cmd cd | source
end
# Ctrl + R: tìm lại lệnh cũ · Ctrl + T: chèn đường dẫn tệp · Alt + C: chuyển thư mục
if type -q fzf
    set -gx FZF_DEFAULT_OPTS '--layout=reverse --height=50% --border=rounded --info=inline-right' \
        '--color=bg+:#2a2e33,fg:#c5d0d2,fg+:#f3f6f6,hl:#9bd3c7,hl+:#9bd3c7,pointer:#9bd3c7,marker:#9bd3c7' \
        '--color=prompt:#c4b5fd,info:#7f888e,border:#5c646b,spinner:#9bd3c7,header:#7f888e'
    if type -q fd
        set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --exclude .git'
        set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    end
    fzf --fish | source
end
if type -q starship
    starship init fish | source
end

# ── lời chào: chỉ terminal đầu tiên sau khi đăng nhập hiện thông tin máy và vài mẹo ──
function fish_greeting
    set -l mark "$XDG_RUNTIME_DIR/lg-fish-greeted"
    if test -z "$XDG_RUNTIME_DIR"; or test -e "$mark"
        return
    end
    touch "$mark"
    type -q fastfetch; and fastfetch
    set_color 7f888e
    echo "  Mẹo: tldr <lệnh> xem ví dụ dùng lệnh · Ctrl + R tìm lại lệnh cũ · → nhận gợi ý màu xám"
    echo "       Ctrl + C chép chữ đang chọn, Ctrl + V dán · gõ claude để mở Claude Code"
    set_color normal
end
