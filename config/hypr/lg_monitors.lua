-- Màn hình. Mặc định: mọi màn hình dùng độ phân giải tốt nhất, tự xếp, tự chọn tỉ lệ.
-- Chỉnh bằng chuột trong Cài đặt → Màn hình (Super + ,). Xem tên màn hình: hyprctl monitors
-- Ví dụ cố định tay (đặt trong user.lua để không bị Cài đặt ghi đè):
--   hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- Lựa chọn từ ứng dụng Cài đặt (LGS.monitors trong lg_settings.lua)
for name, m in pairs(LGS.monitors or {}) do
    if type(m) == "table" then
        if m.disabled then
            hl.monitor({ output = name, disabled = true })
        else
            hl.monitor({
                output   = name,
                mode     = m.mode or "preferred",
                position = m.position or "auto",
                scale    = m.scale and tostring(m.scale) or "auto",
            })
        end
    end
end
