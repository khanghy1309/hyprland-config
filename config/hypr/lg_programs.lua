-- Ứng dụng mặc định. Đổi ở đây là mọi phím tắt dùng theo.
-- Đặt thành biến toàn cục để các file lg_* khác dùng chung.

LG = {
    terminal    = "kitty",
    fileManager = "nautilus",
    browser     = "firefox",
    -- Launcher là một phần của Quickshell (~/.config/quickshell)
    launcher    = "qs ipc call launcher toggle",
    wallpaper   = os.getenv("HOME") .. "/.config/hypr/scripts/wallpaper.sh",
}
