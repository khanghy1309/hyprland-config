import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Trung tâm điều khiển (trượt ra từ mép phải). Bảng widget nay nằm trong đảo động (Island.qml).
// Mở: Super + N, vuốt 4 ngón sang trái, bấm vào viên trạng thái.
// Đóng: Esc hoặc bấm ra ngoài.
PanelWindow {
    id: win

    readonly property bool shown: PanelState.open === "control"
    // giữ cửa sổ thêm một chút khi đóng để kịp chạy hiệu ứng trượt ra
    property bool alive: false
    onShownChanged: {
        if (shown) { hideTimer.stop(); alive = true; }
        else hideTimer.restart();
    }
    Timer { id: hideTimer; interval: 420; onTriggered: win.alive = false }

    visible: alive
    screen: Quickshell.screens.find(s => Hyprland.focusedMonitor && s.name === Hyprland.focusedMonitor.name)
            ?? Quickshell.screens[0]

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.namespace: "glass-panels"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // bấm ra ngoài để đóng
    MouseArea {
        anchors.fill: parent
        onClicked: PanelState.close()
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: PanelState.close()
    }

    ControlPane {
        id: control
        readonly property bool open: PanelState.open === "control"
        // bắt đầu dưới thanh trên, không đè lên nó
        y: Theme.barTop + Theme.barHeight + 10
        height: parent.height - y - 16
        x: slide.value
        opacity: open ? 1 : 0
        Spring { id: slide; target: control.open ? win.width - control.width - 16 : win.width + 40; response: 0.38; damping: 0.92 }
        Behavior on opacity { NumberAnimation { duration: Theme.normal } }
        MouseArea { anchors.fill: parent; z: -1 }
    }
}
