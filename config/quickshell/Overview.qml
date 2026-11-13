import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets

// Toàn cảnh workspace (Super + Tab, vuốt 3 ngón lên).
// Mỗi workspace là một ô thu nhỏ, bên trong là ảnh chụp các cửa sổ đúng vị trí.
//   bấm vào cửa sổ        → sang cửa sổ đó
//   bấm vào chỗ trống ô   → sang workspace đó
//   kéo cửa sổ sang ô khác → chuyển cửa sổ sang workspace đó
//   ← →  chọn ô, Enter sang, 1 … 9 sang thẳng, Esc đóng
// Ảnh chụp cửa sổ cần Hyprland hỗ trợ "hyprland-toplevel-export" (có sẵn);
// cửa sổ nào chưa chụp được thì hiện biểu tượng ứng dụng.
// Mở từ ngoài:  qs ipc call overview toggle
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

    WlrLayershell.namespace: "glass-overview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property int activeId: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : 1

    // workspace thường (id > 0) của màn hình này, thêm một ô trống ở cuối để kéo cửa sổ sang
    readonly property var wsIds: {
        const ids = Hyprland.workspaces.values
            .filter(w => w.id > 0 && (!w.monitor || !monitor || w.monitor.name === monitor.name))
            .map(w => w.id);
        if (ids.indexOf(activeId) < 0) ids.push(activeId);
        ids.sort((a, b) => a - b);
        const next = (ids.length ? ids[ids.length - 1] : 0) + 1;
        if (next <= 10) ids.push(next);
        return ids;
    }

    property int selected: 0

    // kích thước ô: giữ tỉ lệ màn hình, vừa tối đa 5 ô một hàng
    readonly property real monW: monitor ? monitor.width / monitor.scale : width
    readonly property real monH: monitor ? monitor.height / monitor.scale : height
    readonly property int perRow: Math.min(5, wsIds.length)
    readonly property real cardW: Math.min(360, (width - 120 - (perRow - 1) * 28) / Math.max(1, perRow))
    readonly property real cardH: cardW * monH / monW
    readonly property real k: cardW / monW

    function lua(expr, legacy) { Hyprland.dispatch(Hyprland.usingLua ? expr : legacy); }
    function goTo(id) {
        lua(`hl.dsp.focus({ workspace = ${id} })`, `workspace ${id}`);
        close();
    }
    function focusWindow(addr) {
        lua(`hl.dsp.focus({ window = "address:0x${addr}" })`, `focuswindow address:0x${addr}`);
        close();
    }
    function moveWindow(addr, id) {
        lua(`hl.dsp.window.move({ workspace = ${id}, follow = false, window = "address:0x${addr}" })`,
            `movetoworkspacesilent ${id},address:0x${addr}`);
        refreshTimer.restart();
    }
    function closeWindow(addr) {
        lua(`hl.dsp.window.close({ window = "address:0x${addr}" })`, `closewindow address:0x${addr}`);
        refreshTimer.restart();
    }

    function open() {
        Hyprland.refreshToplevels();
        Hyprland.refreshWorkspaces();
        selected = Math.max(0, wsIds.indexOf(activeId));
        visible = true;
        keys.forceActiveFocus();
    }
    function close() { visible = false; }
    function toggle() { visible ? close() : open(); }

    // vị trí cửa sổ không tự cập nhật qua sự kiện, hỏi lại sau khi kéo/đóng
    Timer { id: refreshTimer; interval: 120; onTriggered: Hyprland.refreshToplevels() }

    IpcHandler {
        target: "overview"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function close(): void { root.close(); }
    }

    // hình nền đang dùng (chỉ ảnh tĩnh; video thì dùng nền tối)
    FileView {
        id: wallState
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/liquid-glass/wallpaper"
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property string wallpaper: {
        const p = wallState.text().trim();
        return /\.(png|jpe?g|webp)$/i.test(p) ? "file://" + p : "";
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(6 / 255, 12 / 255, 16 / 255, 0.55)
        opacity: root.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.normal } }
        MouseArea { anchors.fill: parent; onClicked: root.close() }
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: event => {
            const k = event.key, n = root.wsIds.length;
            if (k === Qt.Key_Escape || (k === Qt.Key_Tab && (event.modifiers & Qt.MetaModifier))) root.close();
            else if (k === Qt.Key_Right || k === Qt.Key_Tab) root.selected = (root.selected + 1) % n;
            else if (k === Qt.Key_Left || k === Qt.Key_Backtab) root.selected = (root.selected + n - 1) % n;
            else if (k === Qt.Key_Down) root.selected = Math.min(n - 1, root.selected + root.perRow);
            else if (k === Qt.Key_Up) root.selected = Math.max(0, root.selected - root.perRow);
            else if (k === Qt.Key_Return || k === Qt.Key_Enter) root.goTo(root.wsIds[root.selected]);
            else if (k >= Qt.Key_1 && k <= Qt.Key_9) root.goTo(k - Qt.Key_0);
            else return;
            event.accepted = true;
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 26
        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 1.04
        Behavior on opacity { NumberAnimation { duration: Theme.normal } }
        Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

        Flow {
            id: grid
            width: root.perRow * root.cardW + (root.perRow - 1) * spacing
            spacing: 28

            Repeater {
                model: root.wsIds

                delegate: Item {
                    id: card
                    required property int modelData
                    required property int index
                    readonly property int wsId: modelData
                    readonly property bool isActive: wsId === root.activeId
                    readonly property bool isSel: index === root.selected
                    readonly property var wins: Hyprland.toplevels.values.filter(t =>
                        t.workspace && t.workspace.id === card.wsId && t.lastIpcObject && t.lastIpcObject.at)
                    readonly property bool isNew: wins.length === 0 && !isActive
                        && index === root.wsIds.length - 1

                    width: root.cardW
                    height: root.cardH + 30

                    DropArea {
                        id: drop
                        anchors.fill: frame
                        keys: ["lg-window"]
                        onDropped: d => {
                            if (d.source && d.source.wsId !== card.wsId) root.moveWindow(d.source.addr, card.wsId);
                        }
                    }

                    ClippingRectangle {
                        id: frame
                        width: root.cardW
                        height: root.cardH
                        radius: 16
                        color: Qt.rgba(1, 1, 1, 0.06)
                        border.width: card.isSel || drop.containsDrag ? 2 : 1
                        border.color: card.isSel || drop.containsDrag ? Theme.accent : Theme.rim

                        Image {
                            anchors.fill: parent
                            visible: !card.isNew
                            source: root.wallpaper
                            sourceSize: Qt.size(root.cardW * 2, root.cardH * 2)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            opacity: 0.9
                        }

                        // ô trống cuối: dấu cộng
                        Text {
                            visible: card.isNew
                            anchors.centerIn: parent
                            text: "+"
                            font.family: Theme.font
                            font.pixelSize: 40
                            font.weight: Font.Light
                            color: Theme.dim
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.selected = card.index
                            onClicked: root.goTo(card.wsId)
                        }

                        Repeater {
                            model: card.wins

                            delegate: Item {
                                id: win
                                required property var modelData
                                readonly property var ipc: modelData.lastIpcObject
                                readonly property string addr: modelData.address
                                readonly property int wsId: card.wsId
                                readonly property bool focused: Hyprland.activeToplevel === modelData

                                // tọa độ cửa sổ tính từ góc màn hình, thu nhỏ theo tỉ lệ ô
                                readonly property real homeX: ((ipc.at[0] - (root.monitor ? root.monitor.x : 0)) * root.k)
                                readonly property real homeY: ((ipc.at[1] - (root.monitor ? root.monitor.y : 0)) * root.k)
                                x: homeX
                                y: homeY
                                width: Math.max(24, ipc.size[0] * root.k)
                                height: Math.max(18, ipc.size[1] * root.k)
                                z: wm.drag.active ? 100 : (ipc.floating ? 2 : 1)

                                Drag.active: wm.drag.active
                                Drag.keys: ["lg-window"]
                                Drag.source: win
                                Drag.hotSpot.x: width / 2
                                Drag.hotSpot.y: height / 2

                                // khi kéo, nhấc cửa sổ lên lớp trên cùng để kéo được ra khỏi ô của nó
                                states: State {
                                    when: wm.drag.active
                                    ParentChange { target: win; parent: dragLayer }
                                }

                                ClippingRectangle {
                                    anchors.fill: parent
                                    radius: 6
                                    color: Theme.panelStrong
                                    border.width: win.focused ? 2 : 1
                                    border.color: win.focused ? Theme.accent : Qt.rgba(1, 1, 1, 0.22)

                                    ScreencopyView {
                                        id: shot
                                        anchors.fill: parent
                                        // chụp một lần mỗi khi mở toàn cảnh, không quay liên tục cho nhẹ máy
                                        captureSource: root.visible ? win.modelData.wayland : null
                                        live: false
                                    }

                                    // chưa có ảnh: biểu tượng ứng dụng
                                    Image {
                                        visible: !shot.hasContent
                                        anchors.centerIn: parent
                                        width: Math.min(40, parent.height * 0.5)
                                        height: width
                                        sourceSize: Qt.size(80, 80)
                                        source: Quickshell.iconPath((win.ipc.class || "").toLowerCase(), "application-x-executable")
                                    }
                                }

                                // nút đóng khi rê chuột
                                Rectangle {
                                    visible: wm.containsMouse && !wm.drag.active
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: -6
                                    width: 22
                                    height: 22
                                    radius: 11
                                    color: Theme.accent
                                    Icon { anchors.centerIn: parent; path: Icons.close; size: 12; stroke: 2.4; color: Theme.ink }
                                    z: 3
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.closeWindow(win.addr)
                                    }
                                }

                                MouseArea {
                                    id: wm
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                    drag.target: win
                                    drag.threshold: 6
                                    onEntered: root.selected = card.index
                                    onClicked: root.focusWindow(win.addr)
                                    onReleased: {
                                        if (!drag.active) return;
                                        win.Drag.drop();
                                        // về chỗ cũ; nếu đã chuyển workspace thì ô kia sẽ vẽ lại cửa sổ
                                        Qt.callLater(() => {
                                            win.x = Qt.binding(() => win.homeX);
                                            win.y = Qt.binding(() => win.homeY);
                                        });
                                    }
                                }
                            }
                        }
                    }

                    // số và tên cửa sổ chính
                    Row {
                        anchors.top: frame.bottom
                        anchors.topMargin: 9
                        anchors.horizontalCenter: frame.horizontalCenter
                        spacing: 8
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                            height: 20
                            radius: 10
                            color: card.isActive ? Theme.accent : Theme.chip
                            Text {
                                anchors.centerIn: parent
                                text: card.wsId
                                font.family: Theme.mono
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                color: card.isActive ? Theme.ink : Theme.fg
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, root.cardW - 40)
                            elide: Text.ElideRight
                            text: card.isNew ? "Workspace mới"
                                : card.wins.length === 0 ? "Trống"
                                : card.wins.length === 1 ? ((card.wins[0].lastIpcObject.class || "").split(".").pop() || card.wins[0].title)
                                : card.wins.length + " cửa sổ"
                            font.family: Theme.font
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Theme.fg
                        }
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Kéo cửa sổ sang ô khác để chuyển workspace  ·  Esc để đóng"
            font.family: Theme.font
            font.pixelSize: 13
            color: Theme.dim
        }
    }

    // lớp chứa cửa sổ đang được kéo
    Item {
        id: dragLayer
        anchors.fill: parent
    }
}
