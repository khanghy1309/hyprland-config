-- Giao diện: kính trung tính, bo góc lớn, bóng mềm.
-- Tham khảo: https://wiki.hypr.land/configuring/core/config-options/
-- Các giá trị LG_opt(...) chỉnh được trong ứng dụng Cài đặt (Super + ,).

local glass    = LG_opt("look", "glass", "acrylic")      -- kiểu kính: xem VARIANTS dưới, hoặc "off"
-- Kiểu kính của cửa sổ (biến thể blur của Hyprland 0.57). Kiểu có chuyển động (cực quang) tốn máy hơn.
local VARIANTS = {
    blur    = 0,   -- mờ thường (kawase)
    frost   = 1,   -- kính mờ đá: hạt li ti như kính nhám
    prism   = 6,   -- lăng kính: tách màu cầu vồng ở mép
    acrylic = 8,   -- acrylic: mép cong khúc xạ, gần "liquid glass" nhất (mặc định)
    aurora  = 9,   -- cực quang: dải màu chuyển động chậm phía sau kính
    haze    = 10,  -- sương óng ánh
}
local layout   = LG_opt("windows", "layout", "dwindle")  -- "dwindle" (xếp ô) | "scrolling" (cuộn ngang)
local borders  = LG_opt("look", "borders", true)
local animMul  = LG_opt("look", "animScale", 1)          -- >1 chậm hơn, <1 nhanh hơn
local function sp(x) return x * animMul end

hl.config({
    general = {
        gaps_in  = LG_opt("look", "gapsIn", 7),
        gaps_out = LG_opt("look", "gapsOut", 14),

        -- Viền 1px trắng mờ đóng vai "mép kính". Cửa sổ đang dùng sáng hơn một chút.
        border_size = borders and 1 or 0,
        col = {
            active_border   = "rgba(ffffff55)",
            inactive_border = "rgba(ffffff1a)",
        },

        resize_on_border = true,
        allow_tearing    = false,
        layout           = (layout == "scrolling") and "scrolling" or "dwindle",
    },

    decoration = {
        rounding       = LG_opt("look", "rounding", 22),
        rounding_power = 2.5,   -- >2 cho góc "squircle" mềm hơn, gần kiểu macOS

        -- Không làm cả cửa sổ trong suốt (chữ sẽ mờ theo).
        -- Độ trong của từng ứng dụng đặt riêng, ví dụ kitty trong kitty.conf.
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = LG_opt("look", "shadow", true),
            range        = 30,
            render_power = 3,
            color        = 0x59000000,
            color_inactive = 0x33000000,
        },

        -- Cửa sổ dẻo: kéo hoặc đổi cỡ thì rung rinh như thạch (mới trong Hyprland 0.57)
        wobble = {
            enabled = LG_opt("look", "wobble", false),
        },
        -- Mờ khi chuyển động: vệt mờ theo cửa sổ đang di chuyển
        motion_blur = {
            enabled = LG_opt("look", "motionBlur", false),
        },

        -- Ánh sáng mép trong của cửa sổ, rất nhẹ
        glow = {
            enabled      = borders,
            range        = 6,
            render_power = 3,
            color        = "rgba(ffffff1f)",
            color_inactive = "rgba(ffffff0d)",
        },

        blur = {
            enabled  = glass ~= "off",
            -- Kiểu kính (bảng VARIANTS ở đầu tệp). Máy yếu hoặc thấy giật: chọn Mờ thường.
            variant  = VARIANTS[glass] or 0,
            size     = LG_opt("look", "blurSize", 8),
            passes   = 3,
            vibrancy = 0.2,
            noise    = 0.01,
            popups   = true,         -- làm mờ cả menu chuột phải
            input_methods = true,    -- làm mờ khung gợi ý của bộ gõ

            acrylic = {
                refraction = 16,     -- độ lệch ở mép kính (px)
                bulb       = 40,     -- độ rộng phần mép cong (px)
                clarity    = 0.8,    -- bao nhiêu nền phía sau xuyên qua rõ
                aberration = 0.02,   -- tách màu ở mép
                tint       = 0x14F2F4F6,
            },
        },
    },

    animations = {
        enabled = LG_opt("look", "animations", true),
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
        focus_on_activate       = true,
        -- Terminal tự ẩn khi mở ứng dụng có cửa sổ từ nó, đóng ứng dụng thì terminal hiện lại
        -- (Cài đặt → Màn hình nền và Dock → Terminal nhường chỗ)
        enable_swallow          = LG_opt("windows", "swallow", false),
        swallow_regex           = "^(kitty|org.wezfurlong.wezterm|Alacritty|foot)$",
        -- màn hình đang tắt (tự tắt, hoặc góc nóng "Tắt màn hình") thì rê chuột / bấm phím là sáng lại
        mouse_move_enables_dpms = true,
        key_press_enables_dpms  = true,
    },

    dwindle = {
        preserve_split = true,
    },

    -- Bố cục cuộn ngang (Cài đặt → Màn hình nền và Dock → Bố cục cửa sổ): cửa sổ xếp thành một
    -- dải dài, mỗi cửa sổ là một cột rộng nửa màn hình; vuốt 3 ngón ngang để lướt (lg_input.lua).
    -- Chỉ một cửa sổ thì nó chiếm cả màn hình.
    scrolling = {
        column_width             = 0.5,
        fullscreen_on_one_column = true,
        focus_fit_method         = 1,    -- cửa sổ được chọn cuộn vừa vào màn hình
        follow_focus             = 1,
    },

    -- Nhóm tab: nhiều cửa sổ chung một khung, có thanh tab kính phía trên
    -- (chuột phải vào cửa sổ trong Toàn cảnh hoặc trên dock → Tuỳ chọn cửa sổ → Gộp thành nhóm tab;
    -- kéo một cửa sổ thả vào thanh tab để thêm vào nhóm)
    group = {
        drag_into_group = 2,            -- chỉ khi thả vào thanh tab, kéo ngang qua cửa sổ không bị gộp nhầm
        col = {
            border_active   = "rgba(ffffff55)",
            border_inactive = "rgba(ffffff1a)",
        },
        groupbar = {
            enabled          = true,
            blur             = true,
            font_family      = LG_opt("look", "font", "Geist"),
            font_size        = 12,
            font_weight_active   = "semibold",
            font_weight_inactive = "normal",
            height           = 22,
            indicator_height = 0,
            gradients        = true,
            rounding         = 9,
            gradient_rounding = 9,
            gaps_in          = 4,
            gaps_out         = 4,
            keep_upper_gap   = false,
            middle_click_close = true,
            col = {
                active   = "rgba(ffffff38)",
                inactive = "rgba(ffffff10)",
            },
            text_color          = "rgba(f3f6f6ff)",
            text_color_inactive = "rgba(f3f6f6a0)",
        },
    },

    layers = {
        allow_new_top_layers_over_existing_fullscreen = true,
    },
})

-- Đường cong chuyển động (lấy từ cấu hình mẫu của Hyprland, chỉnh nhẹ)
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, damping = 24.21279333 })

hl.animation({ leaf = "global",        enabled = true, speed = sp(10),   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = sp(5.39), bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = sp(4.79), spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = sp(4.1),  spring = "easy",         style = "popin 90%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = sp(1.49), bezier = "linear",       style = "popin 90%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = sp(1.73), bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = sp(1.46), bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = sp(3.03), bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = sp(3.81), bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = sp(4),    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = sp(1.5),  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = sp(1.79), bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = sp(1.39), bezier = "almostLinear" })
-- Đổi workspace bằng kiểu trượt ngang để khớp với cử chỉ vuốt 3 ngón
hl.animation({ leaf = "workspaces",    enabled = true, speed = sp(3.5),  bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = sp(3.5), bezier = "easeOutQuint", style = "slidevert" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = sp(7),    bezier = "quick" })
