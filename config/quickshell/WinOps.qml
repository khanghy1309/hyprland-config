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

    // đưa cửa sổ đã thu nhỏ về workspace đang xem rồi chuyển tới nó
    function restore(w) {
        const ws = activeWsId();
        lua(`hl.dsp.window.move({ workspace = ${ws}, follow = true, window = "address:0x${w.address}" })`,
            `movetoworkspace ${ws},address:0x${w.address}`);
        lua(`hl.dsp.focus({ window = "address:0x${w.address}" })`, `focuswindow address:0x${w.address}`);
    }

    function minimize(w) {
        lua(`hl.dsp.window.move({ workspace = "${minimizedWs}", follow = false, window = "address:0x${w.address}" })`,
            `movetoworkspacesilent ${minimizedWs},address:0x${w.address}`);
    }

    function close(w) {
        lua(`hl.dsp.window.close({ window = "address:0x${w.address}" })`, `closewindow address:0x${w.address}`);
    }
}
