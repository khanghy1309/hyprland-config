-- Đặt cửa sổ nhanh, như macOS (Sequoia trở đi) và ứng dụng Rectangle:
--   - kéo cửa sổ chạm mép trái / phải màn hình: chiếm nửa màn hình bên đó
--   - kéo chạm mép trên: lấp đầy màn hình; kéo vào một góc: chiếm 1/4 màn hình ở góc đó
--   - kéo cửa sổ đã đặt ra khỏi chỗ: cửa sổ trở lại cỡ cũ
--   - phím tắt Super + Alt + …: xem bảng ở dưới (cũng có trong bảng phím tắt Super + /)
-- Cửa sổ được đặt sẽ chuyển sang nổi. Super + Alt + Backspace trả cửa sổ về như trước khi đặt
-- (về lại lưới nếu trước đó nó đang xếp lưới).
-- Tắt kéo chạm mép: Cài đặt → Màn hình nền và Dock → Kéo cửa sổ chạm mép màn hình để đặt.
--
-- Mọi thứ chạy ngay trong Hyprland (Lua), không chạy thêm chương trình nào.

local S = "SUPER + ALT"

-- vùng (tính theo phần màn hình dùng được): x, y, rộng, cao, từ 0 đến 1
local AREAS = {
    left         = { 0, 0, 1 / 2, 1 },
    right        = { 1 / 2, 0, 1 / 2, 1 },
    top          = { 0, 0, 1, 1 / 2 },
    bottom       = { 0, 1 / 2, 1, 1 / 2 },
    top_left     = { 0, 0, 1 / 2, 1 / 2 },
    top_right    = { 1 / 2, 0, 1 / 2, 1 / 2 },
    bottom_left  = { 0, 1 / 2, 1 / 2, 1 / 2 },
    bottom_right = { 1 / 2, 1 / 2, 1 / 2, 1 / 2 },
    first_third  = { 0, 0, 1 / 3, 1 },
    center_third = { 1 / 3, 0, 1 / 3, 1 },
    last_third   = { 2 / 3, 0, 1 / 3, 1 },
    first_two    = { 0, 0, 2 / 3, 1 },
    last_two     = { 1 / 3, 0, 2 / 3, 1 },
    fill         = { 0, 0, 1, 1 },
}

-- cỡ và chỗ của cửa sổ trước khi được đặt, để trả lại: địa chỉ cửa sổ → { floating, x, y, w, h }
local saved = {}

local function num(v, d) return type(v) == "number" and v or d end

-- khoảng cách (gaps_in / gaps_out) có thể là một số hoặc bốn cạnh
local function gaps(name, d)
    local ok, v = pcall(hl.get_config, name)
    if not ok or v == nil then v = d end
    if type(v) == "number" then return { top = v, right = v, bottom = v, left = v } end
    return { top = num(v.top, d), right = num(v.right, d), bottom = num(v.bottom, d), left = num(v.left, d) }
end

-- cỡ logic của màn hình (đã tính tỉ lệ và xoay dọc)
local function logical(mon)
    local s = num(mon.scale, 1)
    if s <= 0 then s = 1 end
    local w, h = num(mon.width, 1920) / s, num(mon.height, 1080) / s
    if num(mon.transform, 0) % 2 == 1 then w, h = h, w end
    return w, h
end

-- phần màn hình dùng được: trừ thanh trên (vùng dành riêng) và khoảng cách ngoài, như cửa sổ xếp lưới
local function usable(mon)
    local w, h = logical(mon)
    local r = mon.reserved or {}
    local go = gaps("general:gaps_out", 14)
    local rl, rt, rr, rb = num(r.left, 0), num(r.top, 0), num(r.right, 0), num(r.bottom, 0)
    return {
        x = mon.x + rl + go.left,
        y = mon.y + rt + go.top,
        w = w - rl - rr - go.left - go.right,
        h = h - rt - rb - go.top - go.bottom,
    }
end

-- hình chữ nhật của một vùng: giữa hai cửa sổ cạnh nhau có khoảng cách như khi xếp lưới
-- (mỗi bên gaps_in), cửa sổ không tính viền nên trừ thêm viền
local function rect(mon, name)
    local a, f = usable(mon), AREAS[name]
    local gi = gaps("general:gaps_in", 7)
    local okb, b = pcall(hl.get_config, "general:border_size")
    b = (okb and num(b, 1)) or 1
    local x0, y0 = a.x + f[1] * a.w, a.y + f[2] * a.h
    local x1, y1 = a.x + (f[1] + f[3]) * a.w, a.y + (f[2] + f[4]) * a.h
    if f[1] > 0 then x0 = x0 + gi.left end
    if f[1] + f[3] < 0.999 then x1 = x1 - gi.right end
    if f[2] > 0 then y0 = y0 + gi.top end
    if f[2] + f[4] < 0.999 then y1 = y1 - gi.bottom end
    x0, y0, x1, y1 = x0 + b, y0 + b, x1 - b, y1 - b
    return { x = math.floor(x0 + 0.5), y = math.floor(y0 + 0.5),
             w = math.floor(x1 - x0 + 0.5), h = math.floor(y1 - y0 + 0.5) }
end

local function sel(w) return "address:" .. w.address end

local function remember(w)
    if saved[w.address] then return end
    saved[w.address] = { floating = w.floating, x = w.at.x, y = w.at.y, w = w.size.x, h = w.size.y }
end

local function place(w, r)
    local win = sel(w)
    if num(w.fullscreen, 0) ~= 0 then
        hl.dispatch(hl.dsp.window.fullscreen({ action = "unset", window = win }))
    end
    if not w.floating then
        hl.dispatch(hl.dsp.window.float({ action = "enable", window = win }))
    end
    hl.dispatch(hl.dsp.window.resize({ x = r.w, y = r.h, window = win }))
    hl.dispatch(hl.dsp.window.move({ x = r.x, y = r.y, window = win }))
end

local function snap(w, name, mon)
    if not w or not AREAS[name] then return end
    mon = mon or w.monitor
    if not mon then return end
    remember(w)
    place(w, rect(mon, name))
end

-- trả cửa sổ về như trước khi đặt
local function restore(w)
    if not w then return end
    local s = saved[w.address]
    if not s then return end
    saved[w.address] = nil
    if not s.floating then
        hl.dispatch(hl.dsp.window.float({ action = "disable", window = sel(w) }))
        return
    end
    place(w, { x = s.x, y = s.y, w = s.w, h = s.h })
end

-- giữa màn hình, giữ nguyên cỡ (cửa sổ đang xếp lưới thì lấy 2/3 màn hình)
local function center(w)
    if not w then return end
    remember(w)
    if not w.floating then
        local mon = w.monitor
        if not mon then return end
        local a = usable(mon)
        local cw, ch = math.floor(a.w * 2 / 3), math.floor(a.h * 3 / 4)
        place(w, { x = math.floor(a.x + (a.w - cw) / 2), y = math.floor(a.y + (a.h - ch) / 2), w = cw, h = ch })
        return
    end
    hl.dispatch(hl.dsp.window.center({ window = sel(w) }))
end

local function onActive(f)
    return function() f(hl.get_active_window()) end
end
local function key(k, name)
    hl.bind(S .. " + " .. k, onActive(function(w) snap(w, name) end), { description = "Đặt cửa sổ: " .. name })
end

-------------------------------------------------------------------
-- Phím tắt (giống Rectangle trên macOS, Ctrl + Option đổi thành Super + Alt)
-------------------------------------------------------------------
key("left",  "left")          -- nửa trái
key("right", "right")         -- nửa phải
key("up",    "top")           -- nửa trên
key("down",  "bottom")        -- nửa dưới
key("U", "top_left")          -- bốn góc
key("I", "top_right")
key("J", "bottom_left")
key("K", "bottom_right")
key("D", "first_third")       -- một phần ba: trái, giữa, phải
key("F", "center_third")
key("G", "last_third")
key("E", "first_two")         -- hai phần ba: trái, phải
key("T", "last_two")
key("Return", "fill")         -- lấp đầy (vẫn chừa thanh trên và khoảng cách)
hl.bind(S .. " + C", onActive(center), { description = "Đặt cửa sổ: giữa" })
hl.bind(S .. " + BackSpace", onActive(restore), { description = "Đặt cửa sổ: trả về như cũ" })

-------------------------------------------------------------------
-- Kéo chạm mép
-------------------------------------------------------------------
-- Hyprland không báo lúc thả cửa sổ, nên nghe chính nút chuột trái: lúc nhấn ghi lại chỗ của các
-- cửa sổ nổi, lúc thả xem cửa sổ đang dùng có vừa bị kéo đi (đổi chỗ mà không đổi cỡ) không, và
-- con trỏ có đang chạm mép màn hình không. Cả hai lần đều để cú bấm đi tiếp tới ứng dụng như thường.
-- Kéo bằng thanh tiêu đề hay bằng Super + chuột trái đều được.
local EDGE   = 6     -- cách mép bao nhiêu px thì tính là chạm
local CORNER = 60    -- gần góc bao nhiêu px thì tính là góc

local pressAt = {}   -- địa chỉ cửa sổ → { x, y, w, h } lúc nhấn chuột

local function dragEnabled() return LG_opt("windows", "snapDrag", true) ~= false end

local function onPress()
    pressAt = {}
    if not dragEnabled() then return end
    for _, w in ipairs(hl.get_windows() or {}) do
        if w.floating and w.mapped then
            pressAt[w.address] = { x = w.at.x, y = w.at.y, w = w.size.x, h = w.size.y }
        end
    end
end

-- con trỏ chạm mép nào (nil nếu không chạm)
local function edgeAt(c, mon)
    local w, h = logical(mon)
    local L, T, R, B = mon.x, mon.y, mon.x + w, mon.y + h
    local nearL, nearR = c.x <= L + EDGE, c.x >= R - 1 - EDGE
    local nearT, nearB = c.y <= T + EDGE, c.y >= B - 1 - EDGE
    local inTop, inBottom = c.y <= T + CORNER, c.y >= B - CORNER
    local inLeft, inRight = c.x <= L + CORNER, c.x >= R - CORNER
    if (nearL and inTop) or (nearT and inLeft) then return "top_left" end
    if (nearR and inTop) or (nearT and inRight) then return "top_right" end
    if (nearL and inBottom) or (nearB and inLeft) then return "bottom_left" end
    if (nearR and inBottom) or (nearB and inRight) then return "bottom_right" end
    if nearL then return "left" end
    if nearR then return "right" end
    if nearT then return "fill" end
    -- mép dưới là chỗ của dock: không làm gì
    return nil
end

local function onRelease()
    if not dragEnabled() then return end
    local w = hl.get_active_window()
    if not w or not w.floating or num(w.fullscreen, 0) ~= 0 then return end
    local p = pressAt[w.address]
    pressAt = {}
    if not p then return end
    -- vừa bị kéo: chỗ đổi đủ xa, cỡ giữ nguyên (đổi cỡ bằng mép trái cũng làm đổi chỗ, nhưng đổi cả cỡ)
    local moved = math.abs(w.at.x - p.x) + math.abs(w.at.y - p.y) > 24
    local sameSize = math.abs(w.size.x - p.w) <= 2 and math.abs(w.size.y - p.h) <= 2
    if not moved or not sameSize then return end

    local c, mon = hl.get_cursor_pos(), hl.get_monitor_at_cursor()
    if not c or not mon then return end
    local where = edgeAt(c, mon)
    if where then
        snap(w, where, mon)
        return
    end
    -- kéo cửa sổ đã đặt ra chỗ khác: trở lại cỡ cũ, giữ con trỏ ở giữa thanh tiêu đề
    local s = saved[w.address]
    if s and s.floating then
        saved[w.address] = nil
        local nx = math.floor(c.x - s.w / 2)
        place(w, { x = nx, y = w.at.y, w = s.w, h = s.h })
    elseif s then
        -- trước đó đang xếp lưới: để cửa sổ nổi ở chỗ mới; Super + Alt + Backspace không còn gì để trả
        saved[w.address] = nil
    end
end

-- ignore_mods: có giữ phím gì cũng được (Super + kéo); non_consuming: cú bấm vẫn tới ứng dụng;
-- transparent: không bị phím tắt Super + chuột trái (kéo cửa sổ) che mất
local MOUSE = { ignore_mods = true, non_consuming = true, transparent = true }
hl.bind("mouse:272", onPress, MOUSE)
hl.bind("mouse:272", onRelease, { ignore_mods = true, non_consuming = true, transparent = true, release = true })

-- cửa sổ đóng thì bỏ chỗ đã nhớ
hl.on("window.close", function(w)
    if w and w.address then saved[w.address] = nil; pressAt[w.address] = nil end
end)
