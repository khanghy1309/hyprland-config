-- Kiểm tên tuỳ chọn trong cấu hình Hyprland (config/hypr) mà không cần Hyprland:
-- chạy hyprland.lua với một "hl" giả, mọi khoá trong hl.config phải có trong danh sách của
-- Hyprland 0.57 (tools/hyprland-0.57-options.txt); hướng và việc của cử chỉ cũng được kiểm.
-- Dùng: cd config/hypr && lua ../../tools/kiem-tra-hypr.lua ../../tools/hyprland-0.57-options.txt
local keys = {}
for l in io.lines(arg[1]) do
    if not l:match("^#") then keys[(l:gsub("%.", ":"):gsub("-", "_"))] = true end
end
-- tên có trong Hyprland nhưng không nằm trong danh sách (khai báo theo kiểu khác trong mã nguồn)
for _, k in ipairs({ "input:touchpad:tap_to_click" }) do keys[k] = true end
local bad, n, gestures = {}, 0, {}
local function walk(prefix, t)
    for k, v in pairs(t) do
        local key = prefix == "" and k or (prefix .. ":" .. k)
        if type(v) == "table" and not keys[key] then walk(key, v)
        else n = n + 1; if not keys[key] then table.insert(bad, key) end end
    end
end
local function fn() return function() return setmetatable({}, {__index=function() return function() end end}) end end
local function ns() return setmetatable({}, {__index=function(t,k) local v=fn(); rawset(t,k,v); return v end}) end
hl = ns(); hl.dsp = ns(); hl.dsp.window = ns(); hl.dsp.workspace = ns(); hl.dsp.group = ns()
hl.config = function(t) walk("", t) end
local ACT = { workspace=1, resize=1, move=1, special=1, close=1, float=1, fullscreen=1, cursor_zoom=1, scroll_move=1 }
local DIR = { horizontal=1, vertical=1, left=1, right=1, up=1, down=1, pinch=1, pinchin=1, pinchout=1, swipe=1 }
hl.gesture = function(t)
    if type(t.action) == "string" and not ACT[t.action] then table.insert(bad, "gesture action " .. t.action) end
    if not DIR[t.direction] then table.insert(bad, "gesture direction " .. tostring(t.direction)) end
    table.insert(gestures, t.fingers .. " " .. t.direction .. " " .. (type(t.action) == "string" and t.action or "fn"))
end
hl.bind = function() end
hl.on = function() end
hl.animation = function() end
hl.curve = function() end
hl.window_rule = function() end
hl.layer_rule = function() end
hl.monitor = function() end
hl.exec_cmd = function() end
package.path = "./?.lua;" .. package.path
dofile("hyprland.lua")
print(n .. " khoá; sai: " .. (#bad == 0 and "không" or table.concat(bad, ", ")))
if #bad > 0 then os.exit(1) end
print("cử chỉ: " .. table.concat(gestures, " | "))
