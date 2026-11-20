import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Menu nguồn (Super + Esc): khóa, đăng xuất, ngủ, ngủ đông, khởi động lại, tắt máy.
// Bấm chữ cái trong ngoặc để chọn nhanh, ← → để di chuyển, Enter để chọn, Esc để đóng.
// Mở từ ngoài:  qs ipc call power toggle
PanelWindow {
    id: root

    visible: false
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

    WlrLayershell.namespace: "glass-power"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property int selected: 0

    readonly property var actions: [
        { label: "Khóa",          key: "L", path: "M6 11h12v10H6zM9 11V7a3 3 0 0 1 6 0v4",
          cmd: ["sh", "-c", "pidof hyprlock || hyprlock"] },
        { label: "Đăng xuất",     key: "E", path: "M10 4H5v16h5M14 8l4 4-4 4M18 12H9",
          cmd: Controls.logoutCmd },
        { label: "Ngủ",           key: "U", path: Icons.moon,
          cmd: ["systemctl", "suspend"] },
        { label: "Ngủ đông",      key: "H", path: "M12 3v18M4.2 7.5l15.6 9M19.8 7.5l-15.6 9",
          cmd: ["systemctl", "hibernate"] },
        { label: "Khởi động lại", key: "R", path: "M20 12a8 8 0 1 1-2.3-5.6M20 4v5h-5",
          cmd: Controls.rebootCmd },
        { label: "Tắt máy",       key: "S", path: "M12 3v9M6.4 6.4a8 8 0 1 0 11.2 0",
          cmd: Controls.poweroffCmd }
    ]

    function open() { selected = 0; visible = true; keyCatcher.forceActiveFocus(); }
    function close() { visible = false; }
    function toggle() { visible ? close() : open(); }

    // đóng menu trước rồi mới chạy lệnh, để ảnh chụp nền của màn hình khóa không dính menu
    property var pending: null
    function run(i) {
        pending = actions[i].cmd;
        close();
        runTimer.restart();
    }
    Timer {
        id: runTimer
        interval: Settings.look.animations ? 40 + Math.round(150 * Settings.look.animScale) : 40
        onTriggered: if (root.pending) { Quickshell.execDetached(root.pending); root.pending = null; }
    }

    IpcHandler {
        target: "power"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function close(): void { root.close(); }
    }

    // nền tối mờ; bấm ra ngoài để đóng
    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        opacity: root.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.normal } }
        MouseArea { anchors.fill: parent; onClicked: root.close() }
    }

    Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) { root.close(); }
            else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) { root.selected = (root.selected + 1) % root.actions.length; }
            else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) { root.selected = (root.selected + root.actions.length - 1) % root.actions.length; }
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) { root.run(root.selected); }
            else {
                const i = root.actions.findIndex(a => a.key === event.text.toUpperCase());
                if (i < 0) return;
                root.run(i);
            }
            event.accepted = true;
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 20
        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: Theme.normal } }
        Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

        Repeater {
            model: root.actions

            delegate: GlassPill {
                id: tile
                required property var modelData
                required property int index
                readonly property bool isSel: index === root.selected

                tone: "strong"
                width: 176
                height: 200
                radius: 40
                // ô đang chọn: kính sáng hơn, viền sáng rõ (Cài đặt chọn "Trắng đục" thì trắng như trước)
                color: isSel ? (Theme.glassSel ? Qt.rgba(1, 1, 1, 0.30) : Theme.accent) : Theme.panelStrong
                glow: isSel && Theme.glassSel ? 1 : tileHover.hovered && !isSel ? 1 : 0
                glowPos: tileHover.point.position
                HoverHandler { id: tileHover }
                Behavior on color { ColorAnimation { duration: Theme.fast } }

                Column {
                    anchors.centerIn: parent
                    spacing: 18
                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        path: tile.modelData.path
                        size: 46
                        stroke: 1.5
                        color: tile.isSel ? Theme.selFg : Theme.fg
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tile.modelData.label + " (" + tile.modelData.key + ")"
                        font.family: Theme.font
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        color: tile.isSel ? Theme.selFg : Theme.fg
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selected = tile.index
                    onClicked: root.run(tile.index)
                }
            }
        }
    }
}
