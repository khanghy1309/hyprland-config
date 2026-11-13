import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Dock kính ở cạnh dưới màn hình.
//   - ứng dụng ghim (sắp theo Settings.dock.pinned), rồi các ứng dụng đang chạy khác, rồi thùng rác
//   - chấm nhỏ dưới biểu tượng: ứng dụng đang có cửa sổ
//   - bấm: mở ứng dụng, hoặc chuyển tới cửa sổ của nó; bấm tiếp để chuyển vòng qua các cửa sổ
//   - bấm chuột giữa: mở thêm một cửa sổ mới
//   - chuột phải: danh sách cửa sổ, ghim / bỏ ghim, đóng
//   - giữ và kéo một biểu tượng đã ghim để đổi chỗ
// Tự ẩn (mặc định): dock lùi xuống khi có cửa sổ che chỗ của nó; đưa chuột xuống sát mép dưới
// màn hình để hiện lại. Super + D cũng hiện / ẩn dock.
// Chỉnh trong Cài đặt → Dock.   Mở từ ngoài:  qs ipc call dock toggle
PanelWindow {
    id: dock

    visible: Settings.dock.enabled
    screen: Quickshell.screens.find(s => Hyprland.focusedMonitor && s.name === Hyprland.focusedMonitor.name)
            ?? Quickshell.screens[0]

    anchors {
        bottom: true
        left: true
        right: true
    }
    // đủ chỗ cho biểu tượng phóng to, tên ứng dụng và menu chuột phải phía trên dock
    implicitHeight: Settings.dock.iconSize * 2 + 260
    color: "transparent"

    // tự ẩn: không chiếm chỗ của cửa sổ. Luôn hiện: chừa một khoảng ở dưới cho dock.
    exclusionMode: Settings.dock.autoHide ? ExclusionMode.Ignore : ExclusionMode.Normal
    exclusiveZone: Settings.dock.autoHide ? 0 : body.height + margin

    WlrLayershell.namespace: "glass-dock"
    WlrLayershell.layer: WlrLayer.Top

    // chỉ dock (hoặc dải kích hoạt ở mép dưới khi dock đang ẩn) và menu nhận chuột
    mask: Region {
        item: dock.revealed ? hitArea : trigger
        Region { item: menu.visible ? menu : null }
        Region { item: tip.visible ? tip : null }
    }

    readonly property int base: Settings.dock.iconSize
    readonly property int spacing: 8
    readonly property int pad: 10
    readonly property int margin: 10

    // ───────────────── ứng dụng ─────────────────

    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property int activeWs: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : 1

    // cửa sổ thường và cửa sổ đã thu nhỏ (bỏ qua terminal thả xuống)
    readonly property var wins: Hyprland.toplevels.values.filter(t => WinOps.usable(t))

    function idFor(t) {
        const c = t.lastIpcObject["class"];
        if (c === "org.quickshell") return t.title === "Cài đặt" ? "liquid-glass-settings" : "";
        const e = DesktopEntries.heuristicLookup(c);
        return e ? e.id : "class:" + c;
    }

    readonly property var apps: {
        const groups = {}, order = [];
        for (const w of wins) {
            const id = idFor(w);
            if (!id) continue;
            if (!groups[id]) { groups[id] = []; order.push(id); }
            groups[id].push(w);
        }
        const pinned = Settings.dock.pinned;
        const out = [];
        for (const id of pinned) {
            const e = DesktopEntries.byId(id);
            if (e) out.push({ id: id, entry: e, wins: groups[id] || [], pinned: true });
        }
        for (const id of order) {
            if (pinned.indexOf(id) >= 0) continue;
            const e = id.startsWith("class:") ? null : DesktopEntries.byId(id);
            out.push({ id: id, entry: e, wins: groups[id], pinned: false, cls: id.replace(/^class:/, "") });
        }
        return out;
    }
    readonly property int pinnedCount: apps.filter(a => a.pinned).length
    readonly property bool hasUnpinned: apps.length > pinnedCount

    function lua(expr, legacy) { Hyprland.dispatch(Hyprland.usingLua ? expr : legacy); }
    function focusWin(w) { WinOps.focus(w); }    // cửa sổ đã thu nhỏ thì hiện lại
    function closeWin(w) {
        lua(`hl.dsp.window.close({ window = "address:0x${w.address}" })`, `closewindow address:0x${w.address}`);
    }

    // cửa sổ dùng gần nhất có focusHistoryID nhỏ nhất
    function recent(list) {
        return list.slice().sort((a, b) => (a.lastIpcObject.focusHistoryID ?? 99) - (b.lastIpcObject.focusHistoryID ?? 99));
    }

    property string bouncing: ""
    function launch(app) {
        if (!app.entry) return;
        app.entry.execute();
        bouncing = app.id;
        bounceTimer.restart();
    }
    Timer { id: bounceTimer; interval: 1400; onTriggered: dock.bouncing = "" }

    function activate(app) {
        if (app.wins.length === 0) { launch(app); return; }
        // chỉ còn cửa sổ đã thu nhỏ: hiện lại cái dùng gần nhất
        const shown = app.wins.filter(w => !WinOps.isMinimized(w));
        if (shown.length === 0) { WinOps.restore(recent(app.wins)[0]); return; }
        const active = Hyprland.activeToplevel;
        const i = app.wins.indexOf(active);
        if (i >= 0) {
            // đang ở cửa sổ của ứng dụng này: chuyển sang cửa sổ kế tiếp
            if (app.wins.length > 1) focusWin(app.wins[(i + 1) % app.wins.length]);
        } else {
            focusWin(recent(app.wins)[0]);
        }
    }

    function setPinned(id, on) {
        const list = Settings.dock.pinned.slice();
        const i = list.indexOf(id);
        if (on && i < 0) list.push(id);
        if (!on && i >= 0) list.splice(i, 1);
        Settings.dock.pinned = list;
    }
    function movePinned(from, to) {
        const list = Settings.dock.pinned.slice();
        const id = dock.apps[from].id;
        const at = list.indexOf(id);
        if (at < 0) return;
        list.splice(at, 1);
        list.splice(Math.min(to, list.length), 0, id);
        Settings.dock.pinned = list;
    }

    // ───────────────── tự ẩn ─────────────────

    // dock có bị cửa sổ nào trên workspace đang xem đè lên không
    readonly property bool covered: {
        if (!monitor) return false;
        const top = monitor.height / monitor.scale - (base + pad * 2 + margin);
        const left = (width - baseRowWidth) / 2 - pad, right = left + baseRowWidth + pad * 2;
        return wins.some(w => {
            if (w.workspace.id !== activeWs) return false;
            const o = w.lastIpcObject;
            if (o.fullscreen) return true;
            if (!o.at || !o.size) return false;
            const x = o.at[0] - monitor.x, y = o.at[1] - monitor.y;
            return y + o.size[1] > top && x < right && x + o.size[0] > left;
        });
    }

    property bool peek: false
    // hiện dock một lúc khi có cửa sổ đang thu nhỏ vào nó / hiện lại từ nó
    property bool flashing: false
    Timer { id: flashTimer; interval: 1300; onTriggered: dock.flashing = false }
    readonly property bool want: !Settings.dock.autoHide || !covered || peek || flashing
        || hoverDock.hovered || menu.visible || dragFrom >= 0
    property bool revealed: true
    onWantChanged: {
        if (want) { hideTimer.stop(); revealed = true; }
        else hideTimer.restart();
    }
    Timer { id: hideTimer; interval: 450; onTriggered: dock.revealed = false }
    // lúc mới khởi động: nếu đã có cửa sổ che thì ẩn luôn
    Component.onCompleted: {
        if (!want) hideTimer.restart();
        WinOps.slotFor = w => dock.slotFor(w);
        WinOps.flashDock = () => { dock.flashing = true; flashTimer.restart(); };
    }

    // chỗ của cửa sổ trên dock (toạ độ chung của Hyprland), cho hiệu ứng thu nhỏ.
    // Tính theo bố cục chưa phóng to và theo vị trí dock lúc đang hiện, kể cả khi dock đang ẩn.
    function slotFor(w) {
        if (!visible || !monitor) return null;
        const id = idFor(w);
        const i = apps.findIndex(a => a.id === id);
        const left = (width - baseRowWidth) / 2;
        const cx = left + (i >= 0 ? centerOf(i) : baseRowWidth / 2);
        const sh = monitor.height / monitor.scale;
        const top = sh - margin - pad - base;
        return { x: monitor.x + cx - base / 2, y: monitor.y + top, width: base, height: base };
    }

    // vị trí cửa sổ không có sự kiện riêng: hỏi lại Hyprland sau mỗi sự kiện (gom lại 120 ms)
    Connections {
        target: Hyprland
        function onRawEvent(event) { refreshTimer.restart(); }
    }
    Timer { id: refreshTimer; interval: 120; onTriggered: Hyprland.refreshToplevels() }

    IpcHandler {
        target: "dock"
        function toggle(): void { dock.peek = !dock.peek; }
        function show(): void { dock.peek = true; }
        function hide(): void { dock.peek = false; }
    }

    // ───────────────── bố cục & phóng to ─────────────────

    // số ô: ứng dụng + thùng rác; vạch ngăn tính riêng
    readonly property int slots: apps.length + 1
    readonly property int dividers: 1 + (hasUnpinned ? 1 : 0)
    readonly property real baseRowWidth: slots * base + (slots - 1) * spacing + dividers * (spacing + 1)

    // vị trí chuột tính theo bố cục chưa phóng to, để kích thước không "đuổi theo" chuột
    readonly property real mouseX: hoverDock.hovered && dragFrom < 0 && !menu.visible && revealed
        ? hoverDock.point.position.x - (width - baseRowWidth) / 2 : -1e5

    // chuột có trong dock không. Đặt ở gốc cửa sổ để thấy được cả khi chuột nằm trên biểu tượng;
    // mask ở trên đã giới hạn chuột chỉ vào được dock, dải kích hoạt và menu.
    HoverHandler { id: hoverDock }
    function scaleAt(center) {
        if (!Settings.dock.magnify) return 1;
        const d = Math.abs(center - mouseX);
        const r = base * 2.4;
        return d >= r ? 1 : 1 + 0.55 * Math.cos(d / r * Math.PI / 2);
    }
    // tâm của ô thứ i trong bố cục chưa phóng to
    function centerOf(i) {
        let x = i * (base + spacing) + base / 2;
        if (i >= pinnedCount) x += hasUnpinned ? spacing + 1 : 0;
        if (i >= apps.length) x += spacing + 1;
        return x;
    }

    // dải kích hoạt: 4 px ở mép dưới, rộng bằng dock
    Item {
        id: trigger
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: dock.baseRowWidth + dock.pad * 2 + 80
        height: 4
    }

    // vùng nhận chuột khi dock hiện: dock + khoảng phía trên cho biểu tượng phóng to
    Item {
        id: hitArea
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: body.width + 40
        height: body.height + dock.margin + (Settings.dock.magnify ? dock.base * 0.6 : 0) + 6
    }

    GlassPill {
        id: body
        tone: "dark"
        radius: 24
        smoothWidth: false
        height: dock.base + dock.pad * 2
        width: row.width + dock.pad * 2
        anchors.horizontalCenter: parent.horizontalCenter
        y: slide.value
        Spring { id: slide; target: dock.revealed ? dock.height - body.height - dock.margin : dock.height + 6; response: 0.36 }
        Behavior on width { NumberAnimation { duration: 90 } }

        Row {
            id: row
            x: dock.pad
            anchors.bottom: parent.bottom
            anchors.bottomMargin: dock.pad
            spacing: dock.spacing

            Repeater {
                model: dock.apps
                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property var app: modelData
                    readonly property real s: dock.scaleAt(dock.centerOf(index))
                    readonly property bool running: app.wins.length > 0
                    readonly property string name: app.entry ? app.entry.name : app.cls

                    width: dock.base * s + (index === dock.pinnedCount && dock.hasUnpinned ? dock.spacing + 1 : 0)
                    height: dock.base
                    Behavior on width { enabled: dock.mouseX < -1e4; NumberAnimation { duration: 120 } }

                    // vạch ngăn trước nhóm ứng dụng chưa ghim
                    Rectangle {
                        visible: cell.index === dock.pinnedCount && dock.hasUnpinned
                        x: -dock.spacing / 2 - 0.5
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: dock.base * 0.7
                        color: Theme.line
                    }

                    Item {
                        id: iconBox
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        width: dock.base * cell.s
                        height: width
                        // nảy khi đang mở ứng dụng
                        transform: Translate {
                            y: dock.bouncing === cell.app.id ? -bounce.v : 0
                        }

                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            sourceSize: Qt.size(128, 128)
                            asynchronous: true
                            smooth: true
                            mipmap: true
                            source: Quickshell.iconPath(cell.app.entry ? cell.app.entry.icon : cell.app.cls.toLowerCase(),
                                                        "application-x-executable")
                            opacity: dock.dragFrom === cell.index ? 0.35 : 1
                        }
                    }

                    // chấm: đang chạy
                    Rectangle {
                        visible: cell.running
                        anchors.horizontalCenter: iconBox.horizontalCenter
                        anchors.top: parent.bottom
                        anchors.topMargin: 3
                        width: 4
                        height: 4
                        radius: 2
                        color: Theme.fg
                        opacity: 0.85
                    }

                    MouseArea {
                        id: cm
                        anchors.fill: iconBox
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        property real pressX: 0
                        property bool dragging: false
                        onEntered: dock.hoveredItem = cell
                        onExited: if (dock.hoveredItem === cell) dock.hoveredItem = null
                        onPressed: mouse => { pressX = mouse.x; dragging = false; }
                        onPositionChanged: mouse => {
                            if (!pressed || !(pressedButtons & Qt.LeftButton) || !cell.app.pinned) return;
                            if (!dragging && Math.abs(mouse.x - pressX) > 10) { dragging = true; dock.dragFrom = cell.index; menu.close(); }
                            if (dragging) {
                                const p = mapToItem(row, mouse.x, mouse.y);
                                dock.dragTo = Math.max(0, Math.min(dock.pinnedCount - 1,
                                    Math.round((p.x - dock.base / 2) / (dock.base + dock.spacing))));
                            }
                        }
                        onReleased: mouse => {
                            if (dragging) {
                                if (dock.dragTo !== dock.dragFrom) dock.movePinned(dock.dragFrom, dock.dragTo);
                                dock.dragFrom = -1;
                                dragging = false;
                            }
                        }
                        onClicked: mouse => {
                            if (dragging) return;
                            if (mouse.button === Qt.RightButton) menu.openFor(cell.app, cell);
                            else if (mouse.button === Qt.MiddleButton) dock.launch(cell.app);
                            else { menu.close(); dock.activate(cell.app); }
                        }
                    }
                }
            }

            // vạch ngăn trước thùng rác
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: dock.base * 0.7
                color: Theme.line
            }

            Item {
                id: trash
                readonly property string name: "Thùng rác"
                readonly property real s: dock.scaleAt(dock.centerOf(dock.apps.length))
                width: dock.base * s
                height: dock.base
                Image {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    width: dock.base * trash.s
                    height: width
                    sourceSize: Qt.size(128, 128)
                    mipmap: true
                    source: Quickshell.iconPath(dock.trashFull ? "user-trash-full" : "user-trash", "user-trash")
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onEntered: dock.hoveredItem = trash
                    onExited: if (dock.hoveredItem === trash) dock.hoveredItem = null
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) menu.openTrash(trash);
                        else Quickshell.execDetached(["gio", "open", "trash:///"]);
                    }
                }
            }
        }

        // vạch báo chỗ thả khi kéo đổi chỗ
        Rectangle {
            visible: dock.dragFrom >= 0 && dock.dragTo !== dock.dragFrom
            x: dock.pad + dock.dragTo * (dock.base + dock.spacing) + (dock.dragTo > dock.dragFrom ? dock.base + dock.spacing / 2 : -dock.spacing / 2) - 1
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: dock.base
            radius: 1
            color: Theme.accent
        }
    }

    property Item hoveredItem: null
    property int dragFrom: -1
    property int dragTo: -1

    // nảy lên xuống khi mở ứng dụng
    QtObject {
        id: bounce
        property real v: 0
        property SequentialAnimation anim: SequentialAnimation {
            running: dock.bouncing !== ""
            loops: 3
            NumberAnimation { target: bounce; property: "v"; to: 16; duration: 220; easing.type: Easing.OutQuad }
            NumberAnimation { target: bounce; property: "v"; to: 0; duration: 220; easing.type: Easing.InQuad }
        }
    }

    // thùng rác có gì không (kiểm tra mỗi lần dock hiện ra)
    property bool trashFull: false
    onRevealedChanged: if (revealed) trashCheck.running = true
    Process {
        id: trashCheck
        command: ["sh", "-c", "ls -A \"${XDG_DATA_HOME:-$HOME/.local/share}/Trash/files\" 2>/dev/null | head -n1"]
        stdout: StdioCollector { onStreamFinished: dock.trashFull = text.trim().length > 0 }
    }

    // ───────────────── tên ứng dụng khi rê chuột ─────────────────

    GlassPill {
        id: tip
        tone: "strong"
        radius: 10
        readonly property Item target: dock.hoveredItem
        visible: !!target && dock.revealed && !menu.visible && dock.dragFrom < 0
        width: tipText.implicitWidth + 24
        height: 30
        // giữa biểu tượng (biểu tượng nằm sát phải ô của nó); dock.mouseX để tính lại khi phóng to
        x: target ? target.mapToItem(body.parent, target.width - dock.base * target.s / 2 + 0 * dock.mouseX, 0).x - width / 2 : 0
        // ngay trên biểu tượng, kể cả khi nó đang phóng to
        y: body.y - height - (target ? dock.base * (target.s - 1) : 0) - 8
        Text {
            id: tipText
            anchors.centerIn: parent
            text: tip.target ? tip.target.name : ""
            font.family: Theme.font
            font.pixelSize: 13
            font.weight: Font.Medium
            color: Theme.fg
        }
    }

    // ───────────────── menu chuột phải ─────────────────

    GlassPill {
        id: menu
        tone: "strong"
        radius: 16
        visible: false
        width: Math.max(220, menuCol.implicitWidth + 16)
        height: menuCol.implicitHeight + 16
        y: body.y - height - 12

        property var app: null
        property bool forTrash: false
        property var items: []

        function place(anchorItem) {
            const p = anchorItem.mapToItem(body.parent, anchorItem.width - dock.base * anchorItem.s / 2, 0);
            x = Math.max(8, Math.min(dock.width - width - 8, p.x - width / 2));
        }
        function openFor(a, anchorItem) {
            app = a;
            forTrash = false;
            const list = [];
            for (const w of a.wins)
                list.push({ label: (WinOps.isMinimized(w) ? "(thu nhỏ) " : "") + (w.title || a.cls || "Cửa sổ"),
                            run: () => dock.focusWin(w), win: true });
            if (a.entry) list.push({ label: "Mở cửa sổ mới", run: () => dock.launch(a) });
            if (a.entry) list.push({ label: a.pinned ? "Bỏ ghim khỏi Dock" : "Ghim vào Dock", run: () => dock.setPinned(a.id, !a.pinned) });
            if (a.wins.length > 0)
                list.push({ label: a.wins.length > 1 ? "Đóng " + a.wins.length + " cửa sổ" : "Đóng",
                            run: () => a.wins.forEach(w => dock.closeWin(w)) });
            items = list;
            visible = true;
            place(anchorItem);
        }
        function openTrash(anchorItem) {
            forTrash = true;
            items = [{ label: "Mở thùng rác", run: () => Quickshell.execDetached(["gio", "open", "trash:///"]) },
                     { label: "Dọn sạch thùng rác", run: () => Quickshell.execDetached(["gio", "trash", "--empty"]) }];
            visible = true;
            place(anchorItem);
        }
        function close() { visible = false; }

        // rời chuột khỏi dock và menu một lúc thì tự đóng
        Timer {
            running: menu.visible && !hoverDock.hovered
            interval: 900
            onTriggered: menu.close()
        }

        Column {
            id: menuCol
            x: 8
            y: 8
            Repeater {
                model: menu.items
                delegate: Rectangle {
                    id: mi
                    required property var modelData
                    required property int index
                    readonly property bool sepAbove: index > 0 && !modelData.win && menu.items[index - 1].win
                    width: menu.width - 16
                    height: 34 + (sepAbove ? 9 : 0)
                    radius: 10
                    color: "transparent"
                    Rectangle {
                        visible: mi.sepAbove
                        x: 8
                        y: 4
                        width: parent.width - 16
                        height: 1
                        color: Theme.line
                    }
                    Rectangle {
                        y: mi.sepAbove ? 9 : 0
                        width: parent.width
                        height: 34
                        radius: 10
                        color: mim.containsMouse ? Theme.accent : "transparent"
                        Text {
                            x: 12
                            width: parent.width - 24
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            text: mi.modelData.label
                            font.family: Theme.font
                            font.pixelSize: 13
                            font.weight: mi.modelData.win ? Font.Normal : Font.Medium
                            color: mim.containsMouse ? Theme.ink : Theme.fg
                        }
                        MouseArea {
                            id: mim
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { menu.close(); mi.modelData.run(); }
                        }
                    }
                }
            }
        }
    }
}
