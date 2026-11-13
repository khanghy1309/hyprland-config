pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Thao tác với cửa sổ dùng chung cho dock và Alt + Tab.
// Cửa sổ "thu nhỏ" (Super + H) thật ra được cất vào workspace ẩn special:minimized.
Singleton {
    id: root

    readonly property string minimizedWs: "special:minimized"

    function lua(expr, legacy) { Hyprland.dispatch(Hyprland.usingLua ? expr : legacy); }

    // hiệu ứng thu nhỏ (MinimizeFx.qml tự gắn vào khi chạy) và chỗ của cửa sổ trên dock (Dock.qml gắn vào)
    property var fx: null
    property var slotFor: null          // function(w) → { x, y, width, height } theo toạ độ chung, hoặc null
    property var flashDock: null        // function() → hiện dock một lúc (khi dock đang tự ẩn)

    function rectOf(w) {
        const o = w && w.lastIpcObject;
        return o && o.at && o.size ? { x: o.at[0], y: o.at[1], width: o.size[0], height: o.size[1] } : null;
    }
    function screenOf(w) {
        const o = w && w.lastIpcObject;
        const m = o ? Hyprland.monitors.values.find(m => m.id === o.monitor) : null;
        return (m ?? Hyprland.focusedMonitor)?.name ?? "";
    }
    // biểu tượng của cửa sổ trên dock; không có dock thì giữa mép dưới màn hình
    function targetOf(w, r) {
        const t = slotFor ? slotFor(w) : null;
        if (t) return t;
        const m = Hyprland.focusedMonitor;
        const s = 48;
        return m ? { x: m.x + m.width / m.scale / 2 - s / 2, y: m.y + m.height / m.scale - s - 12, width: s, height: s }
                 : { x: r.x + r.width / 2 - s / 2, y: r.y + r.height, width: s, height: s };
    }
    function play(w, reverse, before, after) {
        const r = rectOf(w);
        if (!fx || !r || !w.wayland) { before(); if (after) after(); return; }
        if (flashDock) flashDock();
        fx.play({ tl: w.wayland, screen: screenOf(w), win: r, target: targetOf(w, r), reverse: reverse, before: before, after: after });
    }

    function isMinimized(w) { return !!w && !!w.workspace && w.workspace.name === minimizedWs; }

    // cửa sổ thường + cửa sổ đã thu nhỏ (bỏ qua terminal thả xuống và workspace đặc biệt khác)
    function usable(w) {
        return !!w && !!w.workspace && !!w.lastIpcObject && !!w.lastIpcObject["class"]
            && (w.workspace.id > 0 || isMinimized(w));
    }

    function activeWsId() {
        const m = Hyprland.focusedMonitor;
        return m && m.activeWorkspace ? m.activeWorkspace.id : 1;
    }

    function focus(w) {
        if (isMinimized(w)) { restore(w); return; }
        lua(`hl.dsp.focus({ window = "address:0x${w.address}" })`, `focuswindow address:0x${w.address}`);
    }

    // đưa cửa sổ đã thu nhỏ về workspace đang xem rồi chuyển tới nó (hiệu ứng chạy ngược từ dock)
    function restore(w) {
        play(w, true, () => {}, () => restoreNow(w));
    }
    function restoreNow(w) {
        const ws = activeWsId();
        lua(`hl.dsp.window.move({ workspace = ${ws}, follow = true, window = "address:0x${w.address}" })`,
            `movetoworkspace ${ws},address:0x${w.address}`);
        lua(`hl.dsp.focus({ window = "address:0x${w.address}" })`, `focuswindow address:0x${w.address}`);
    }

    function minimize(w) {
        if (!w || isMinimized(w)) return;
        play(w, false, () => minimizeNow(w), null);
    }
    function minimizeNow(w) {
        lua(`hl.dsp.window.move({ workspace = "${minimizedWs}", follow = false, window = "address:0x${w.address}" })`,
            `movetoworkspacesilent ${minimizedWs},address:0x${w.address}`);
    }

    function close(w) {
        lua(`hl.dsp.window.close({ window = "address:0x${w.address}" })`, `closewindow address:0x${w.address}`);
    }
}
