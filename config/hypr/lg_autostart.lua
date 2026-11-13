-- Chạy một lần khi Hyprland khởi động

hl.on("hyprland.start", function()
    -- Hình nền: khôi phục hình nền dùng lần trước (ảnh, GIF hoặc video)
    hl.exec_cmd(LG.wallpaper .. " restore")

    -- Thanh trên, launcher và (từ đợt 2) đảo động, bảng trượt
    hl.exec_cmd("qs")

    -- Tự làm tối, khóa, tắt màn hình khi không dùng máy (cấu hình: hypridle.conf)
    hl.exec_cmd("hypridle")

    -- Bộ gõ tiếng Việt
    hl.exec_cmd("fcitx5 -d")

    -- Hộp thoại xin quyền quản trị (khi ứng dụng cần mật khẩu)
    hl.exec_cmd("systemctl --user start hyprpolkitagent")

    -- Lưu lịch sử bộ nhớ tạm (dùng cho launcher ở đợt 4)
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Mở sẵn terminal thả xuống (ẩn), để Super + ` hiện ngay
    hl.exec_cmd(LG.terminal .. " --class dropdown")
end)
