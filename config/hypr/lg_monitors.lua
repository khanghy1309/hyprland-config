-- Màn hình. Mặc định: mọi màn hình dùng độ phân giải tốt nhất, tự xếp, tự chọn tỉ lệ.
-- Xem tên màn hình bằng lệnh:  hyprctl monitors
-- Ví dụ cố định màn hình laptop 1920x1080, tỉ lệ 1:
--   hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})
