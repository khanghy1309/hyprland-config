pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Thao tác với cửa sổ dùng chung cho dock và Alt + Tab.
// Cửa sổ "thu nhỏ" (Super + H) thật ra được cất vào workspace ẩn special:minimized.
// Super + H gọi  qs ipc call window minimize  (IpcHandler ở dưới).
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

    // thu nhỏ: cửa sổ biến khỏi màn hình ngay (không có hiệu ứng), vẫn chạy, biểu tượng vẫn ở dock
    function minimize(w) {
        if (!w || isMinimized(w)) return;
        lua(`hl.dsp.window.move({ workspace = "${minimizedWs}", follow = false, window = "address:0x${w.address}" })`,
            `movetoworkspacesilent ${minimizedWs},address:0x${w.address}`);
    }

    function close(w) {
        lua(`hl.dsp.window.close({ window = "address:0x${w.address}" })`, `closewindow address:0x${w.address}`);
    }

    // ── menu cửa sổ (chuột phải trong Toàn cảnh, trên dock): làm mọi việc với cửa sổ không cần phím tắt ──
    // đặt cửa sổ vào một vùng màn hình (lg_snap.lua lo phần tính toán; chạy trong Hyprland)
    function snap(w, name) {
        if (!Hyprland.usingLua) return;
        Quickshell.execDetached(["hyprctl", "eval", `LG_snap("${name}", "address:0x${w.address}")`]);
    }
    function sel(w) { return `window = "address:0x${w.address}"`; }
    function toggleFullscreen(w) { lua(`hl.dsp.window.fullscreen({ action = "toggle", ${sel(w)} })`, `fullscreen 0`); }
    function toggleFloat(w) { lua(`hl.dsp.window.float({ action = "toggle", ${sel(w)} })`, `togglefloating address:0x${w.address}`); }
    // chỉ cửa sổ nổi mới ghim được: chuyển sang nổi trước (như Super + P)
    function togglePin(w) {
        const o = w.lastIpcObject || {};
        if (!o.floating) lua(`hl.dsp.window.float({ action = "set", ${sel(w)} })`, `setfloating address:0x${w.address}`);
        lua(`hl.dsp.window.pin({ action = "toggle", ${sel(w)} })`, `pin address:0x${w.address}`);
    }
    function moveTo(w, id) {
        lua(`hl.dsp.window.move({ workspace = ${id}, follow = false, ${sel(w)} })`, `movetoworkspacesilent ${id},address:0x${w.address}`);
    }

    // các mục của menu cửa sổ (xem GlassMenuCard.qml). before(): việc nơi mở menu cần làm trước
    // (ví dụ đóng Toàn cảnh); moved(): sau khi chuyển workspace (ví dụ vẽ lại Toàn cảnh)
    function menuFor(w, before, moved) {
        const o = w.lastIpcObject || {};
        const pre = () => { if (before) before(); };
        const area = (label, name) => ({ label: label, run: () => { pre(); focus(w); snap(w, name); } });
        const list = [];
        if (!isMinimized(w))
            list.push({ label: "Thu nhỏ xuống dock", icon: Icons.minimize, run: () => { pre(); minimize(w); } });
        list.push({ label: o.fullscreen ? "Thoát toàn màn hình" : "Toàn màn hình", icon: Icons.fullscreen,
                    run: () => { pre(); focus(w); toggleFullscreen(w); } });
        if (Hyprland.usingLua)
            list.push({ label: "Đặt cửa sổ", icon: Icons.layout, sub: [
                area("Nửa trái", "left"), area("Nửa phải", "right"), area("Lấp đầy màn hình", "fill"),
                area("Ra giữa", "center"), { sep: true },
                area("Góc trên trái", "top_left"), area("Góc trên phải", "top_right"),
                area("Góc dưới trái", "bottom_left"), area("Góc dưới phải", "bottom_right"), { sep: true },
                area("Một phần ba bên trái", "first_third"), area("Một phần ba ở giữa", "center_third"),
                area("Một phần ba bên phải", "last_third"), { sep: true },
                area("Trả về như cũ", "restore")
            ] });
        list.push({ label: o.floating ? "Xếp vào lưới" : "Cho nổi tự do", icon: Icons.floating,
                    run: () => { pre(); toggleFloat(w); } });
        list.push({ label: "Ghim trên mọi workspace", icon: Icons.pin, checked: !!o.pinned,
                    run: () => { pre(); togglePin(w); } });
        list.push({ label: "Chuyển sang workspace", icon: Icons.moveTo, sub: () => {
            const ids = Hyprland.workspaces.values.map(x => x.id).filter(id => id > 0);
            const top = Math.max(1, ...ids);
            const cur = w.workspace ? w.workspace.id : -1;
            const out = [];
            for (let id = 1; id <= top + 1; id++) {
                if (id === cur) continue;
                out.push({ label: id > top ? "Workspace mới (" + id + ")" : "Workspace " + id,
                           run: () => { moveTo(w, id); if (moved) moved(); } });
            }
            return out;
        } });
        list.push({ sep: true });
        list.push({ label: "Đóng cửa sổ", icon: Icons.close, danger: true, run: () => { close(w); if (moved) moved(); } });
        return list;
    }
}
