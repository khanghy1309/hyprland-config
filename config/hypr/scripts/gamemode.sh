#!/usr/bin/env bash
# Chế độ chơi game: nhường GPU/CPU cho game, tắt xong thì mọi thứ về như cũ.
#   gamemode.sh on | off | toggle | status
#
# Bật:  tắt làm mờ, bóng đổ và chuyển động của Hyprland (chỉ tạm thời, không sửa tệp cấu hình),
#       dừng hẳn hình nền video (không giải mã khung nào), chuyển hồ sơ nguồn sang "hiệu năng".
#       Quickshell tự chuyển kính sang kiểu nhẹ nhất khi thấy tệp trạng thái.
# Tắt:  tải lại cấu hình Hyprland (mọi giá trị về đúng như trong tệp), cho video chạy tiếp,
#       trả lại hồ sơ nguồn lúc trước.
# Lưu ý: đổi gì trong ứng dụng Cài đặt lúc đang bật cũng làm Hyprland tải lại cấu hình, tức là bật lại
#        làm mờ; bấm tắt rồi bật chế độ chơi game lại là được.
# Ý tưởng từ macshell-gaming.sh của MacShell (github.com/0-ss/MacShell, giấy phép MIT).

set -u
STATE="${XDG_RUNTIME_DIR:-/tmp}/liquid-glass-gamemode"

on() {
    [ -f "$STATE" ] && return 0
    printf 'profile=%s\n' "$(powerprofilesctl get 2>/dev/null)" > "$STATE"
    hyprctl eval 'hl.config({ decoration = { blur = { enabled = false }, shadow = { enabled = false } }, animations = { enabled = false } })' >/dev/null 2>&1
    pkill -STOP -x mpvpaper 2>/dev/null
    powerprofilesctl set performance 2>/dev/null || true
    notify-send -a "Chế độ chơi game" "Đã bật" "Tắt làm mờ và chuyển động, dừng hình nền video, chạy hết công suất." 2>/dev/null || true
}

off() {
    [ -f "$STATE" ] || return 0
    local profile=""
    profile="$(sed -n 's/^profile=//p' "$STATE")"
    rm -f "$STATE"
    hyprctl reload >/dev/null 2>&1
    pkill -CONT -x mpvpaper 2>/dev/null
    [ -n "$profile" ] && powerprofilesctl set "$profile" 2>/dev/null
    notify-send -a "Chế độ chơi game" "Đã tắt" "Mọi thứ đã về như cũ." 2>/dev/null || true
}

case "${1:-status}" in
    on) on ;;
    off) off ;;
    toggle) if [ -f "$STATE" ]; then off; else on; fi ;;
    status) [ -f "$STATE" ] && echo on || echo off ;;
    *) echo "Dùng: $0 on|off|toggle|status" >&2; exit 2 ;;
esac
