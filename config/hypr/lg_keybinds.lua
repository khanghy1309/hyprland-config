-- Phím tắt. "SUPER" là phím Windows / Command.
-- Bấm Super + / để xem bảng phím tắt. Đổi phím ở đây thì sửa cả
-- ~/.config/quickshell/Cheatsheet.qml cho bảng khớp.

local S   = "SUPER"
local sh  = function(cmd) return hl.dsp.exec_cmd(cmd) end

-------------------------------------------------------------------
-- Ứng dụng
-------------------------------------------------------------------
hl.bind(S .. " + Return", sh(LG.terminal))
hl.bind(S .. " + Space",  sh(LG.launcher))
hl.bind(S .. " + E",      sh(LG.fileManager))
hl.bind(S .. " + B",      sh(LG.browser))

-- Bảng widget và trung tâm điều khiển (Quickshell)
hl.bind(S .. " + W",      sh("qs ipc call panels widgets"))
hl.bind(S .. " + N",      sh("qs ipc call panels control"))
hl.bind(S .. " + Tab",    sh("qs ipc call overview toggle"))
-- Alt + Tab như Windows: giữ Alt, bấm Tab để chọn, thả Alt để chuyển
hl.bind("ALT + Tab",         sh("qs ipc call switcher next"))
hl.bind("ALT + SHIFT + Tab", sh("qs ipc call switcher prev"))
hl.bind("ALT + Alt_L",       sh("qs ipc call switcher commit"), { release = true, transparent = true })
-- trình quản lý tác vụ
hl.bind("CTRL + SHIFT + Escape", sh(LG.taskManager))
hl.bind(S .. " + slash",  sh("qs ipc call cheatsheet toggle"))
hl.bind(S .. " + comma",  sh("qs ipc call settings toggle"))
hl.bind(S .. " + D",      sh("qs ipc call dock toggle"))
hl.bind(S .. " + SHIFT + V", sh("qs ipc call launcher clipboard"))

-------------------------------------------------------------------
-- Cửa sổ
-------------------------------------------------------------------
hl.bind(S .. " + Q", hl.dsp.window.close())
hl.bind("ALT + F4", hl.dsp.window.close())                       -- như Windows
-- thu nhỏ: cất cửa sổ vào workspace ẩn; bấm biểu tượng trên dock
-- hoặc Alt + Tab để hiện lại. Quickshell chưa chạy thì vẫn thu nhỏ được.
hl.bind(S .. " + H", sh([[qs ipc call window minimize || hyprctl dispatch 'hl.dsp.window.move({ workspace = "special:minimized", follow = false })']]))
hl.bind(S .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(S .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(S .. " + J", hl.dsp.layout("togglesplit"))

-- Ghim cửa sổ: chỉ cửa sổ nổi mới ghim được, nên chuyển sang nổi trước rồi bật/tắt ghim.
-- Cửa sổ đã ghim hiện trên mọi workspace.
hl.bind(S .. " + P", function()
    local w = hl.get_active_window()
    if not w then return end
    if not w.floating then
        hl.dispatch(hl.dsp.window.float({ action = "set" }))
    end
    hl.dispatch(hl.dsp.window.pin())
end)

-- Chuyển focus bằng phím mũi tên
hl.bind(S .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(S .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(S .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(S .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Kéo / đổi cỡ cửa sổ bằng Super + chuột trái / chuột phải
hl.bind(S .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(S .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-------------------------------------------------------------------
-- Workspace
-------------------------------------------------------------------
for i = 1, 9 do
    hl.bind(S .. " + " .. i,           hl.dsp.focus({ workspace = i }))
    hl.bind(S .. " + SHIFT + " .. i,   hl.dsp.window.move({ workspace = i }))
end
hl.bind(S .. " + CTRL + left",  hl.dsp.focus({ workspace = "e-1" }))
hl.bind(S .. " + CTRL + right", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(S .. " + mouse_down",   hl.dsp.focus({ workspace = "e+1" }))
hl.bind(S .. " + mouse_up",     hl.dsp.focus({ workspace = "e-1" }))

-- Terminal thả xuống (Super + `). Nếu terminal đó đã bị đóng thì mở lại.
local function toggleDropdown()
    for _, w in ipairs(hl.get_windows()) do
        if w.class == "dropdown" then
            hl.dispatch(hl.dsp.workspace.toggle_special("dropdown"))
            return
        end
    end
    hl.exec_cmd(LG.terminal .. " --class dropdown")
    hl.dispatch(hl.dsp.workspace.toggle_special("dropdown"))
end
hl.bind(S .. " + grave", toggleDropdown)

-------------------------------------------------------------------
-- Chụp và quay màn hình (~/.config/hypr/scripts/capture.sh)
-------------------------------------------------------------------
local cap = "~/.config/hypr/scripts/capture.sh"
hl.bind("Print",             sh(cap .. " shot screen"))         -- chụp cả màn hình
hl.bind(S .. " + SHIFT + S", sh("qs ipc call capture toggle"))   -- bảng chụp và quay
hl.bind(S .. " + SHIFT + T", sh(cap .. " ocr"))                 -- đọc chữ trong vùng chọn
hl.bind(S .. " + SHIFT + R", sh(cap .. " stop"))                -- dừng quay
hl.bind(S .. " + SHIFT + C", sh("hyprpicker -a"))

-------------------------------------------------------------------
-- Hình nền
-------------------------------------------------------------------
-- Super + Shift + W: chọn ngẫu nhiên một hình nền trong ~/Pictures/Wallpapers
hl.bind(S .. " + SHIFT + W", sh(LG.wallpaper .. " random"))

-------------------------------------------------------------------
-- Phím âm lượng, độ sáng, nhạc (phím Fn trên laptop)
-------------------------------------------------------------------
hl.bind("XF86AudioRaiseVolume", sh("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", sh("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        sh("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",     sh("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
hl.bind("XF86MonBrightnessUp",  sh("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",sh("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })
hl.bind("XF86AudioNext",  sh("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  sh("playerctl previous"),   { locked = true })
hl.bind("XF86AudioPlay",  sh("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", sh("playerctl play-pause"), { locked = true })

-------------------------------------------------------------------
-- Khóa màn hình, menu nguồn
-------------------------------------------------------------------
hl.bind(S .. " + L",      sh("pidof hyprlock || hyprlock"))
hl.bind(S .. " + Escape", sh("qs ipc call power toggle"))
-- Thoát Hyprland ngay, không hỏi (dự phòng khi Quickshell bị lỗi)
hl.bind(S .. " + SHIFT + Escape", hl.dsp.exit())
