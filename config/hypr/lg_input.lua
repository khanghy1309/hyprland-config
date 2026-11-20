-- Bàn phím, chuột, touchpad và cử chỉ

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_options = "",

        follow_mouse = 1,
        sensitivity  = LG_opt("input", "sensitivity", 0),   -- -1.0 đến 1.0; 0 là giữ nguyên
        repeat_rate  = LG_opt("input", "repeatRate", 25),   -- số ký tự mỗi giây khi giữ phím
        repeat_delay = LG_opt("input", "repeatDelay", 600), -- ms trước khi bắt đầu lặp

        touchpad = {
            natural_scroll       = LG_opt("input", "naturalScroll", true),   -- cuộn tự nhiên như macOS
            tap_to_click         = LG_opt("input", "tapToClick", true),      -- chạm để bấm
            disable_while_typing = LG_opt("input", "disableWhileTyping", true),
            clickfinger_behavior = true,   -- bấm 2 ngón = chuột phải
            scroll_factor        = LG_opt("input", "scrollFactor", 0.6),
        },
    },

    gestures = {
        workspace_swipe_distance     = 700,
        workspace_swipe_cancel_ratio = 0.3,
        workspace_swipe_create_new   = true,
    },
})

-- Cử chỉ; bật/tắt từng cái trong Cài đặt → Touchpad
-- Vuốt 3 ngón trái/phải: đổi workspace. Ở bố cục cuộn ngang thì là lướt qua dải cửa sổ
-- (đổi workspace lúc đó: bấm số trên thanh trên, hoặc Toàn cảnh)
if LG_opt("gestures", "workspace", true) then
    if LG_opt("windows", "layout", "dwindle") == "scrolling" then
        hl.gesture({ fingers = 3, direction = "horizontal", action = "scroll_move" })
    else
        hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
    end
end

-- Chụm / mở 3 ngón: kính lúp, phóng to quanh con trỏ theo tay (như Zoom trợ năng của macOS)
if LG_opt("gestures", "zoom", true) then
    hl.gesture({ fingers = 3, direction = "pinch", action = "cursor_zoom", zoom_level = "1", mode = "live" })
end

-- Vuốt 3 ngón lên: toàn cảnh workspace
if LG_opt("gestures", "overview", true) then
    hl.gesture({ fingers = 3, direction = "up", action = function() hl.exec_cmd("qs ipc call overview toggle") end })
end

-- Vuốt 3 ngón xuống: mở/ẩn terminal thả xuống
if LG_opt("gestures", "dropdown", true) then
    hl.gesture({ fingers = 3, direction = "down", action = "special", workspace_name = "dropdown" })
end

-- Vuốt 4 ngón: bảng widget (sang phải) và trung tâm điều khiển (sang trái)
if LG_opt("gestures", "panels", true) then
    hl.gesture({ fingers = 4, direction = "right", action = function() hl.exec_cmd("qs ipc call panels widgets") end })
    hl.gesture({ fingers = 4, direction = "left",  action = function() hl.exec_cmd("qs ipc call panels control") end })
end
