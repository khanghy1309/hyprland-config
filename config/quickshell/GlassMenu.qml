import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Cửa sổ chứa một GlassMenuCard, mở ngay dưới thanh trên (menu hệ thống).
// open(entries, x, title): x là mép trái của nút đã bấm, toạ độ màn hình.
PanelWindow {
    id: pop

    property var owner: null          // nút đang mở menu, để bấm lại thì đóng
    property real ax: 0
    readonly property bool shown: owner !== null

    function open(who, entries, x, title) {
        menu.reset();
        menu.entries = entries;
        menu.title = title || "";
        ax = x;
        owner = who;
    }
    function close() { owner = null; }
    function toggle(who, entries, x, title) { owner === who ? close() : open(who, entries, x, title); }

    visible: shown || closing.running
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "glass-bar-menu"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: Region { item: menu }

    HyprlandFocusGrab {
        windows: [pop]
        active: pop.shown
        onCleared: pop.close()
    }

    Spring { id: grow; target: pop.shown ? 1 : 0; response: 0.3; damping: 0.72 }
    Timer { id: closing; interval: Theme.wait(160) }
    onShownChanged: if (!shown) closing.restart()

    GlassMenuCard {
        id: menu
        x: Math.max(8, Math.min(pop.width - width - 8, pop.ax))
        y: Theme.barTop + Theme.barHeight + 8
        transformOrigin: Item.TopLeft
        scale: 0.92 + 0.08 * Math.min(1.04, grow.value)
        opacity: pop.shown ? Math.min(1, grow.value * 1.6) : 0
        Behavior on opacity { enabled: !pop.shown; NumberAnimation { duration: Theme.ms(140) } }
        focus: pop.shown
        onDone: pop.close()
    }
}
