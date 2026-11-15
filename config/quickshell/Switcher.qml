import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets

// Alt + Tab: chuyển cửa sổ như trên Windows.
//   giữ Alt, bấm Tab để đi tiếp (Shift + Tab đi lùi), thả Alt để chuyển tới cửa sổ đang chọn
//   bấm chuột vào một ô cũng được; Esc để huỷ
// Cửa sổ xếp theo lần dùng gần nhất; cửa sổ đã thu nhỏ cũng có (chuyển tới là nó hiện lại).
// Hyprland gọi vào đây (lg_keybinds.lua):  qs ipc call switcher next | prev | commit | cancel
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

    WlrLayershell.namespace: "glass-switcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // cửa sổ dùng gần nhất trước (focusHistoryID: 0 là cửa sổ đang dùng)
    readonly property var wins: Hyprland.toplevels.values.filter(w => WinOps.usable(w))
        .sort((a, b) => (a.lastIpcObject.focusHistoryID ?? 999) - (b.lastIpcObject.focusHistoryID ?? 999))

    property int index: 0

    function step(d) {
        if (!visible) {
            if (wins.length === 0) return;
            Hyprland.refreshToplevels();
            index = wins.length > 1 ? (d > 0 ? 1 : wins.length - 1) : 0;
            visible = true;
            keys.forceActiveFocus();
            return;
        }
        if (wins.length > 0) index = (index + d + wins.length) % wins.length;
    }
    function commit() {
        if (!visible) return;
        // danh sách có thể ngắn lại lúc bảng đang mở (một cửa sổ vừa đóng)
        const w = wins.length > 0 ? wins[Math.min(index, wins.length - 1)] : null;
        visible = false;
        if (w) WinOps.focus(w);
    }
    function cancel() { visible = false; }

    IpcHandler {
        target: "switcher"
        function next(): void { root.step(1); }
        function prev(): void { root.step(-1); }
        function commit(): void { root.commit(); }
        function cancel(): void { root.cancel(); }
    }

    // phòng khi lệnh "thả Alt" không tới: tự đóng nếu không ai bấm gì trong 8 giây
    Timer {
        running: root.visible
        interval: 8000
        onTriggered: root.cancel()
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) root.cancel();
            else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Right) root.step(1);
            else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Left) root.step(-1);
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.commit();
            else return;
            event.accepted = true;
        }
        // nếu bàn phím báo được việc thả Alt cho cửa sổ này thì dùng luôn
        Keys.onReleased: event => {
            if (event.key === Qt.Key_Alt || event.key === Qt.Key_Meta) { root.commit(); event.accepted = true; }
        }
    }

    MouseArea { anchors.fill: parent; onClicked: root.cancel() }

    readonly property real cardW: 236
    readonly property real thumbH: 140

    GlassPill {
        id: panel
        tone: "strong"
        radius: 30
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, list.contentWidth + 36)
        height: root.thumbH + 96
        MouseArea { anchors.fill: parent }

        ListView {
            id: list
            x: 18
            y: 18
            width: parent.width - 36
            height: parent.height - 36
            orientation: ListView.Horizontal
            spacing: 12
            clip: true
            model: root.wins
            currentIndex: root.index
            highlightMoveDuration: 120
            preferredHighlightBegin: width / 2 - root.cardW / 2
            preferredHighlightEnd: width / 2 + root.cardW / 2
            highlightRangeMode: contentWidth > width ? ListView.ApplyRange : ListView.NoHighlightRange
            interactive: false

            delegate: Rectangle {
                id: card
                required property var modelData
                required property int index
                readonly property bool sel: index === root.index
                readonly property bool mini: WinOps.isMinimized(modelData)
                width: root.cardW
                height: list.height
                radius: 20
                color: sel ? Qt.rgba(1, 1, 1, 0.16) : "transparent"
                border.width: sel ? 2 : 0
                border.color: Theme.accent

                ClippingRectangle {
                    id: thumb
                    x: 10
                    y: 10
                    width: parent.width - 20
                    height: root.thumbH - 10
                    radius: 12
                    color: Theme.chip
                    opacity: card.mini ? 0.55 : 1
                    SafeShot {
                        id: shot
                        anchors.fill: parent
                        want: root.visible ? card.modelData.wayland : null
                        live: false
                    }
                    Image {
                        visible: !shot.hasContent
                        anchors.centerIn: parent
                        width: 56
                        height: 56
                        sourceSize: Qt.size(112, 112)
                        source: Quickshell.iconPath(root.iconFor(card.modelData), "application-x-executable")
                    }
                }

                Row {
                    anchors.top: thumb.bottom
                    anchors.topMargin: 10
                    x: 12
                    width: parent.width - 24
                    spacing: 8
                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20
                        height: 20
                        sourceSize: Qt.size(40, 40)
                        source: Quickshell.iconPath(root.iconFor(card.modelData), "application-x-executable")
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 28
                        elide: Text.ElideRight
                        text: (card.mini ? "(thu nhỏ) " : "") + (card.modelData.title || card.modelData.lastIpcObject["class"])
                        font.family: Theme.font
                        font.pixelSize: 13
                        font.weight: card.sel ? Font.DemiBold : Font.Normal
                        color: Theme.fg
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.index = card.index
                    onClicked: { root.index = card.index; root.commit(); }
                }
            }
        }
    }

    function iconFor(w) {
        const c = w.lastIpcObject["class"] || "";
        const e = DesktopEntries.heuristicLookup(c);
        return e ? e.icon : c.toLowerCase();
    }
}
