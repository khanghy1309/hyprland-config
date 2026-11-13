pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Thông tin chung cho chất liệu kính (GlassPill + shaders/glass.frag):
//   - hình nền đang dùng, và một ảnh tĩnh của nó (video thì lấy một khung hình)
//   - có cửa sổ nào nằm sau một vùng kính không (có thì không khúc xạ được, xem glass.frag)
// Kiểu kính chọn trong Cài đặt → Giao diện → Chất liệu kính:
//   "liquid"  khúc xạ hình nền khi phía sau trống, vệt sáng ở mép (mặc định)
//   "rim"     chỉ vệt sáng ở mép, phần mờ do Hyprland làm (nhẹ máy hơn)
//   "flat"    kính phẳng kiểu cũ, không dùng shader
Singleton {
    id: root

    // lúc chơi game: kính nhẹ nhất có thể (chỉ vệt sáng ở mép, không khúc xạ)
    readonly property string mode: Controls.gaming && Settings.look.material === "liquid" ? "rim" : Settings.look.material
    readonly property bool shader: mode !== "flat"

    readonly property string stateFile: (Quickshell.env("XDG_STATE_HOME") || Settings.home + "/.local/state") + "/liquid-glass/wallpaper"
    property string wall: ""
    readonly property bool isVideo: /\.(mp4|webm|mkv|mov|m4v)$/i.test(wall)
    property string still: ""
    // dải hình nền sau thanh trên có sáng không (Bar.qml đo); sáng thì kính ở đó tối hơn cho chữ dễ đọc
    property bool topBright: false

    // video: ảnh tĩnh chỉ khớp lúc video đứng yên, nên mặc định không khúc xạ trên hình nền động
    readonly property bool canRefract: mode === "liquid" && still !== "" && (!isVideo || Settings.look.refractVideo)

    FileView {
        path: root.stateFile
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.wall = text().trim()
        onLoadFailed: root.wall = ""
    }
    onWallChanged: {
        if (!wall) { still = ""; return; }
        if (!isVideo) { still = wall; return; }
        thumb.command = [Settings.wallScript, "thumb", wall, "1920"];
        thumb.running = true;
    }
    Process {
        id: thumb
        stdout: StdioCollector { onStreamFinished: root.still = text.trim() }
    }

    // ── cửa sổ nằm sau kính ──
    // rect: { x, y, w, h } theo toạ độ của màn hình `screen`
    function blocked(screen, rect) {
        const mon = Hyprland.monitorFor(screen);
        if (!mon || !mon.activeWorkspace) return false;
        const ws = mon.activeWorkspace.id;
        const so = mon.lastIpcObject ? mon.lastIpcObject.specialWorkspace : null;
        const sp = so && so.id ? so.id : 0;      // workspace đặc biệt đang mở (terminal thả xuống...)
        for (const t of Hyprland.toplevels.values) {
            if (!t.workspace || (t.workspace.id !== ws && (sp === 0 || t.workspace.id !== sp))) continue;
            const o = t.lastIpcObject;
            if (!o || !o.at || !o.size) continue;
            if (o.fullscreen) return true;
            const x = o.at[0] - mon.x, y = o.at[1] - mon.y;
            if (x < rect.x + rect.w && x + o.size[0] > rect.x && y < rect.y + rect.h && y + o.size[1] > rect.y) return true;
        }
        return false;
    }
    // vị trí cửa sổ không có sự kiện riêng: hỏi lại Hyprland sau mỗi sự kiện (gom lại 150 ms)
    property int epoch: 0
    Connections {
        target: Hyprland
        function onRawEvent(event) { refresh.restart(); }
    }
    Timer { id: refresh; interval: 150; onTriggered: { Hyprland.refreshToplevels(); Hyprland.refreshMonitors(); settle.restart(); } }
    // dữ liệu mới về không báo riêng: chờ thêm một nhịp rồi cho các viên kính tính lại
    Timer { id: settle; interval: 120; onTriggered: root.epoch++ }
}
