-- ~/.config/hypr/hyprland.lua
-- Liquid Glass cho Hyprland 0.57+ (cấu hình Lua).
-- Mỗi phần nằm trong một file riêng cùng thư mục, nạp theo thứ tự bên dưới.
-- Sửa file nào thì Hyprland tự tải lại; nếu có lỗi, Hyprland hiện thông báo ở góc màn hình.

require("lg_programs")   -- tên các ứng dụng dùng chung (terminal, trình duyệt...)

-- Lựa chọn từ ứng dụng Cài đặt (Super + ,). File lg_settings.lua do ứng dụng tự ghi,
-- sửa tay sẽ bị ghi đè; muốn chỉnh riêng thì dùng user.lua ở cuối.
do
    local ok, s = pcall(require, "lg_settings")
    LGS = (ok and type(s) == "table") and s or {}
end
-- LG_opt("look", "rounding", 22): lấy một lựa chọn, không có thì dùng giá trị mặc định
function LG_opt(section, key, default)
    local t = LGS[section]
    if type(t) ~= "table" or t[key] == nil then return default end
    return t[key]
end

require("lg_monitors")   -- màn hình
require("lg_env")        -- biến môi trường (bộ gõ tiếng Việt, con trỏ...)
pcall(require, "lg_gpu") -- biến riêng cho card NVIDIA (nvidia/setup-nvidia.sh ghi; máy khác không có file này)
require("lg_look")       -- kính, bo góc, bóng, chuyển động
require("lg_input")      -- bàn phím, touchpad, cử chỉ
require("lg_rules")      -- quy tắc cho cửa sổ và lớp (thanh trên, launcher)
require("lg_keybinds")   -- phím tắt
require("lg_autostart")  -- chạy khi đăng nhập

-- Chỗ dành cho chỉnh sửa riêng của bạn. File này không bị script cài đặt ghi đè.
pcall(require, "user")
