import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Menu chuột phải trên màn hình nền: bấm chuột phải vào chỗ trống (không có cửa sổ) để mở.
// Menu là một viên kính lỏng như dock và đảo động, hiện ra từ đúng chỗ con trỏ, nảy nhẹ khi mở.
//
// Cách bắt chuột phải: mỗi màn hình có một lớp trong suốt nằm ngay trên hình nền, dưới mọi cửa sổ
// (lớp "bottom"). Chỉ chỗ trống của màn hình nền mới tới được lớp này, nên không ảnh hưởng cửa sổ.
Scope {
    id: root

    // menu đang mở ở màn hình nào, tại đâu (toạ độ của màn hình đó)
    property string screenName: ""
    property point at: Qt.point(0, 0)
    readonly property bool shown: screenName !== ""

    function close() { screenName = ""; }
    function ipc(args) { Quickshell.execDetached(["qs", "ipc", "call"].concat(args)); }

    readonly property var items: [
        { icon: Icons.terminal, label: "Mở Terminal",          run: () => Quickshell.execDetached(["kitty", "--directory", Quickshell.env("HOME")]) },
        { icon: Icons.folder,   label: "Mở thư mục nhà",        run: () => Quickshell.execDetached(["nautilus", "--new-window", Quickshell.env("HOME")]) },
        { icon: Icons.search,   label: "Tìm ứng dụng, tệp…",    run: () => root.ipc(["launcher", "open"]) },
        { icon: Icons.clipboard, label: "Lịch sử bộ nhớ tạm",   run: () => root.ipc(["launcher", "clipboard"]) },
        { icon: Icons.grid,     label: "Toàn cảnh",             run: () => root.ipc(["overview", "open"]) },
        { sep: true },
        { icon: Icons.image,    label: "Đổi hình nền…",         run: () => root.ipc(["settings", "page", "wallpaper"]) },
        { icon: Icons.shuffle,  label: "Hình nền ngẫu nhiên",   run: () => Quickshell.execDetached([Settings.wallScript, "random"]) },
        { icon: Icons.palette,  label: "Giao diện…",            run: () => root.ipc(["settings", "page", "look"]) },
        { sep: true },
        { icon: Icons.camera,   label: "Chụp màn hình",         run: () => root.ipc(["capture", "open"]) },
        { icon: Icons.dock,     label: "Hiện hoặc ẩn dock",     run: () => root.ipc(["dock", "toggle"]), when: () => Settings.dock.enabled },
        { icon: Icons.keyboard, label: "Phím tắt",              run: () => root.ipc(["cheatsheet", "open"]) }
    ]

    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen
            required property var modelData

            // ── lớp bắt chuột phải, nằm ngay trên hình nền ──
            PanelWindow {
                screen: perScreen.modelData
                anchors { top: true; bottom: true; left: true; right: true }
                exclusionMode: ExclusionMode.Ignore
                color: "transparent"
                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.namespace: "lg-desktop"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onPressed: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            root.at = Qt.point(mouse.x, mouse.y);
                            root.screenName = perScreen.modelData.name;
                        } else {
                            root.close();
                        }
                    }
                }
            }

            // ── menu, nằm trên cửa sổ ──
            PanelWindow {
                id: pop
                screen: perScreen.modelData
                readonly property bool mine: root.screenName === perScreen.modelData.name
                visible: mine || closing.running
                anchors { top: true; bottom: true; left: true; right: true }
                exclusionMode: ExclusionMode.Ignore
                color: "transparent"
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "glass-desktop-menu"
                WlrLayershell.keyboardFocus: mine ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
                // chỉ phần menu nhận chuột; bấm ra ngoài thì HyprlandFocusGrab báo để đóng
                mask: Region { item: card }

                HyprlandFocusGrab {
                    windows: [pop]
                    active: pop.mine
                    onCleared: root.close()
                }

                // mở: nảy nhẹ từ góc gần con trỏ; đóng: mờ nhanh
                Spring { id: grow; target: pop.mine ? 1 : 0; response: 0.3; damping: 0.72 }
                Timer { id: closing; interval: Theme.wait(160) }
                onMineChanged: if (!mine) closing.restart()

                GlassPill {
                    id: card
                    tone: "strong"
                    // đậm hơn kính thường một chút: menu hay mở trên vùng hình nền sáng, chữ vẫn phải rõ
                    color: Qt.rgba(0.09, 0.10, 0.12, 0.70)
                    radius: 18
                    width: 248
                    height: list.implicitHeight + 12
                    // mở về phía còn chỗ: sát mép phải thì mở sang trái, sát mép dưới thì mở lên
                    readonly property bool flipX: root.at.x + width + 8 > pop.width
                    readonly property bool flipY: root.at.y + height + 8 > pop.height
                    x: Math.max(8, flipX ? root.at.x - width : root.at.x)
                    y: Math.max(8, flipY ? root.at.y - height : root.at.y)
                    transformOrigin: flipX ? (flipY ? Item.BottomRight : Item.TopRight)
                                           : (flipY ? Item.BottomLeft : Item.TopLeft)
                    scale: 0.9 + 0.1 * Math.min(1.04, grow.value)
                    opacity: pop.mine ? Math.min(1, grow.value * 1.6) : 0
                    Behavior on opacity { enabled: !pop.mine; NumberAnimation { duration: Theme.ms(140) } }

                    focus: pop.mine
                    Keys.onEscapePressed: root.close()

                    Column {
                        id: list
                        x: 6
                        y: 6
                        width: card.width - 12
                        Repeater {
                            model: root.items.filter(it => !it.when || it.when())
                            delegate: Item {
                                id: row
                                required property var modelData
                                width: list.width
                                height: modelData.sep ? 11 : 36

                                Rectangle {
                                    visible: row.modelData.sep === true
                                    anchors.centerIn: parent
                                    width: parent.width - 20
                                    height: 1
                                    color: Theme.line
                                }
                                Rectangle {
                                    visible: !row.modelData.sep
                                    anchors.fill: parent
                                    radius: 12
                                    color: rowArea.containsMouse ? Theme.accent : "transparent"
                                    Behavior on color { ColorAnimation { duration: Theme.fast } }

                                    Icon {
                                        x: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        path: row.modelData.icon || ""
                                        size: 17
                                        color: rowArea.containsMouse ? Theme.ink : Theme.fg
                                    }
                                    Text {
                                        x: 40
                                        width: parent.width - 52
                                        anchors.verticalCenter: parent.verticalCenter
                                        elide: Text.ElideRight
                                        text: row.modelData.label || ""
                                        font.family: Theme.font
                                        font.pixelSize: 14
                                        font.weight: Font.Medium
                                        color: rowArea.containsMouse ? Theme.ink : Theme.fg
                                    }
                                    MouseArea {
                                        id: rowArea
                                        anchors.fill: parent
                                        enabled: !row.modelData.sep
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { root.close(); row.modelData.run(); }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
