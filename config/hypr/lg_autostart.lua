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

    -- Giữ nội dung vừa chép khi đóng ứng dụng đã chép nó (Wayland vốn làm mất, Windows và Mac thì không)
    hl.exec_cmd("wl-clip-persist --clipboard regular")

    -- Cắm USB, thẻ nhớ: tự gắn ổ và báo một thông báo (bấm vào để mở thư mục)
    hl.exec_cmd("udiskie --automount --notify --no-tray")

    -- Mở sẵn terminal thả xuống (ẩn), để Super + ` hiện ngay
    hl.exec_cmd(LG.terminal .. " --class dropdown")
end)
