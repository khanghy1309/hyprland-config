import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray

// Menu của biểu tượng ứng dụng trên thanh trên (menu bar extras). Đây là menu thật của ứng dụng
// (DBusMenu), vẽ lại thành một viên kính lỏng như menu chuột phải trên màn hình nền.
// Mục có menu con thì bấm để đi vào, hàng trên cùng để quay ra.
PanelWindow {
    id: pop

    // ứng dụng đang mở menu và chỗ đặt menu (toạ độ màn hình: mép trái của biểu tượng)
    property var item: null
    property real ax: 0
    // menu con đang mở, từ ngoài vào trong
    property var stack: []

    // ứng dụng thoát khi menu đang mở thì đóng menu
    readonly property bool alive: item !== null && SystemTray.items.values.indexOf(item) >= 0
    readonly property bool shown: alive
    readonly property var current: stack.length ? stack[stack.length - 1] : (alive && item.hasMenu ? item.menu : null)

    function open(it, x) { stack = []; ax = x; item = it; }
    function close() { item = null; stack = []; }
    function enter(entry) { stack = stack.concat([entry]); }
    function back() { stack = stack.slice(0, -1); }
    // nhãn DBusMenu dùng "_" để đánh dấu phím tắt (Alt + chữ): bỏ đi, "__" là một dấu "_" thật
    function label(t) { return (t || "").replace(/__/g, "\u0001").replace(/_/g, "").replace(/\u0001/g, "_"); }

    visible: shown || closing.running
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "glass-tray-menu"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: Region { item: card }

    HyprlandFocusGrab {
        windows: [pop]
        active: pop.shown
        onCleared: pop.close()
    }

    Spring { id: grow; target: pop.shown ? 1 : 0; response: 0.3; damping: 0.72 }
    Timer { id: closing; interval: Theme.wait(160) }
    onShownChanged: if (!shown) closing.restart()

    QsMenuOpener { id: opener; menu: pop.current }

    GlassPill {
        id: card
        tone: "strong"
        color: Qt.rgba(0.09, 0.10, 0.12, 0.70)
        radius: 16
        width: 264
        smoothWidth: false
        readonly property real maxH: pop.height - y - 16
        height: Math.min(maxH, flick.contentHeight + 12)
        x: Math.max(8, Math.min(pop.width - width - 8, pop.ax - 10))
        y: Theme.barTop + Theme.barHeight + 8
        transformOrigin: Item.Top
        scale: 0.92 + 0.08 * Math.min(1.04, grow.value)
        opacity: pop.shown ? Math.min(1, grow.value * 1.6) : 0
        Behavior on opacity { enabled: !pop.shown; NumberAnimation { duration: Theme.ms(140) } }

        focus: pop.shown
        Keys.onEscapePressed: pop.stack.length ? pop.back() : pop.close()
        Keys.onLeftPressed: if (pop.stack.length) pop.back()

        Flickable {
            id: flick
            x: 6
            y: 6
            width: card.width - 12
            height: card.height - 12
            contentHeight: list.implicitHeight
            clip: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: list
                width: flick.width

                // tên ứng dụng, hoặc nút quay ra khi đang ở menu con
                Item {
                    width: list.width
                    height: 30
                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: pop.stack.length && headArea.containsMouse ? Theme.chip : "transparent"
                    }
                    Icon {
                        visible: pop.stack.length > 0
                        x: 8
                        anchors.verticalCenter: parent.verticalCenter
                        path: Icons.chevronLeft
                        size: 14
                        color: Theme.dim
                    }
                    Text {
                        x: pop.stack.length ? 26 : 10
                        width: parent.width - x - 10
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        text: pop.stack.length ? pop.label(pop.stack[pop.stack.length - 1].text)
                              : !pop.item ? "" : (pop.item.tooltipTitle || pop.item.title || pop.item.id)
                        font.family: Theme.font
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: Theme.dim
                    }
                    MouseArea {
                        id: headArea
                        anchors.fill: parent
                        enabled: pop.stack.length > 0
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pop.back()
                    }
                }

                Repeater {
                    model: opener.children
                    delegate: Item {
                        id: row
                        required property var modelData
                        readonly property bool sep: modelData.isSeparator
                        readonly property bool on: modelData.enabled
                        readonly property bool checkable: modelData.buttonType !== QsMenuButtonType.None
                        readonly property bool checked: modelData.checkState === Qt.Checked
                        readonly property bool hot: on && rowArea.containsMouse
                        width: list.width
                        height: sep ? 11 : 34

                        Rectangle {
                            visible: row.sep
                            anchors.centerIn: parent
                            width: parent.width - 20
                            height: 1
                            color: Theme.line
                        }
                        Rectangle {
                            visible: !row.sep
                            anchors.fill: parent
                            radius: 11
                            color: row.hot ? Theme.accent : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.fast } }

                            // dấu chọn (ô đánh dấu, nút radio)
                            Icon {
                                visible: row.checkable && row.checked
                                x: 9
                                anchors.verticalCenter: parent.verticalCenter
                                path: Icons.check
                                size: 15
                                color: row.hot ? Theme.ink : Theme.fg
                            }
                            Image {
                                id: entryIcon
                                visible: !row.checkable && status === Image.Ready
                                x: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: 16
                                height: 16
                                source: row.sep ? "" : row.modelData.icon
                                sourceSize: Qt.size(32, 32)
                                asynchronous: true
                                smooth: true
                            }
                            Text {
                                x: 34
                                width: parent.width - x - (row.modelData.hasChildren ? 30 : 12)
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                text: pop.label(row.modelData.text)
                                font.family: Theme.font
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                color: row.hot ? Theme.ink : row.on ? Theme.fg : Theme.dim
                                opacity: row.on ? 1 : 0.55
                            }
                            Icon {
                                visible: row.modelData.hasChildren
                                anchors.right: parent.right
                                anchors.rightMargin: 9
                                anchors.verticalCenter: parent.verticalCenter
                                path: Icons.chevronRight
                                size: 14
                                color: row.hot ? Theme.ink : Theme.dim
                            }
                            MouseArea {
                                id: rowArea
                                anchors.fill: parent
                                enabled: !row.sep && row.on
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (row.modelData.hasChildren) { pop.enter(row.modelData); return; }
                                    const e = row.modelData;
                                    pop.close();
                                    e.triggered();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
