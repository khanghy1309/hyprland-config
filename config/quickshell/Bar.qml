import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray

// Thanh trên: ba viên kính nổi.
//   trái  – workspace + tên cửa sổ đang dùng
//   giữa  – chừa chỗ cho đảo động (Island.qml)
//   phải  – biểu tượng ứng dụng chạy nền (khay), rồi CPU, RAM, âm lượng, pin; bấm để mở trung tâm điều khiển
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barTop + Theme.barHeight
    exclusiveZone: implicitHeight
    color: "transparent"

    WlrLayershell.namespace: "glass-bar"
    WlrLayershell.layer: WlrLayer.Top

    // ── chữ luôn đọc được: đo độ sáng của dải hình nền nằm sau thanh trên ──
    // Hình nền sáng (trời trắng, tuyết...) thì kính của thanh chuyển sang tông tối để chữ trắng vẫn rõ.
    // Đo một lần mỗi khi đổi hình nền, trên ảnh tĩnh (video thì một khung hình), không chụp màn hình.
    readonly property bool bright: Glass.topBright
    readonly property string pillTone: "light"
    // nền sáng: chữ tối, nút đang chọn tối chữ sáng (như macOS 26 tự đổi màu chữ theo nền)
    readonly property color fg: bright ? Theme.ink : Theme.fg
    readonly property color dim: bright ? Theme.inkDim : Theme.dim
    readonly property color selBg: bright ? Theme.ink : Theme.accent
    readonly property color selFg: bright ? Theme.accent : Theme.ink
    Canvas {
        id: probe
        width: 64
        height: 4
        // phải "hiện" thì Canvas mới vẽ: đặt ra ngoài cửa sổ cho khỏi thấy
        x: -1000
        renderStrategy: Canvas.Immediate
        readonly property string src: Glass.fileUrl(Glass.still)
        onSrcChanged: if (src) loadImage(src)
        Component.onCompleted: if (src) loadImage(src)
        onImageLoaded: requestPaint()
        onPaint: {
            if (!src || !isImageLoaded(src)) return;
            const ctx = getContext("2d");
            const img = ctx.createImageData(src);          // chỉ để lấy cỡ ảnh
            const iw = img.width, ih = img.height;
            if (!iw || !ih) return;
            // phần ảnh nằm sau dải trên cùng của màn hình (ảnh được cắt vừa màn hình)
            const sw = (bar.screen && bar.screen.width) || 1920, sh = (bar.screen && bar.screen.height) || 1080;
            const k = Math.max(sw / iw, sh / ih);
            const cw = sw / k, chh = (Theme.barTop + Theme.barHeight + 8) / k;
            ctx.clearRect(0, 0, width, height);
            ctx.drawImage(src, (iw - cw) / 2, (ih - sh / k) / 2, cw, chh, 0, 0, width, height);
            const d = ctx.getImageData(0, 0, width, height).data;
            let sum = 0;
            for (let i = 0; i < d.length; i += 4) sum += 0.2126 * d[i] + 0.7152 * d[i + 1] + 0.0722 * d[i + 2];
            Glass.topBright = sum / (d.length / 4) / 255 > 0.62;
        }
    }

    readonly property var hmon: Hyprland.monitorFor(bar.screen)
    readonly property int activeId: hmon && hmon.activeWorkspace ? hmon.activeWorkspace.id : 1

    // Luôn hiện workspace 1–4, cộng thêm workspace khác đang tồn tại trên màn hình này
    readonly property var wsIds: {
        const ids = [1, 2, 3, 4];
        for (const w of Hyprland.workspaces.values) {
            if (w.id > 0 && (!w.monitor || w.monitor === bar.hmon) && ids.indexOf(w.id) < 0)
                ids.push(w.id);
        }
        return ids.sort((a, b) => a - b);
    }

    function occupied(id) {
        const w = Hyprland.workspaces.values.find(x => x.id === id);
        return !!w && w.toplevels.values.length > 0;
    }

    function goTo(id) {
        if (Hyprland.usingLua)
            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
        else
            Hyprland.dispatch(`workspace ${id}`);
    }

    // ───────────────── trái: workspace ─────────────────
    GlassPill {
        id: wsPill
        tone: bar.pillTone
        x: Theme.edge
        y: Theme.barTop
        height: Theme.barHeight
        width: wsRow.width + 16 + (titleText.text.length > 0 ? titleText.width + 22 : 0)

        Row {
            id: wsRow
            x: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Repeater {
                model: bar.wsIds

                delegate: Rectangle {
                    id: wsBtn
                    required property int modelData
                    readonly property bool isActive: modelData === bar.activeId

                    width: isActive ? 38 : 30
                    height: 28
                    radius: 14
                    color: isActive ? bar.selBg : wsMouse.containsMouse ? Theme.chip : "transparent"

                    Behavior on width { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: Theme.fast } }

                    Text {
                        anchors.centerIn: parent
                        text: wsBtn.modelData
                        font.family: Theme.mono
                        font.pixelSize: 13
                        font.weight: wsBtn.isActive ? Font.Bold : Font.Medium
                        color: wsBtn.isActive ? bar.selFg
                             : bar.occupied(wsBtn.modelData) ? bar.fg : bar.dim
                    }

                    MouseArea {
                        id: wsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bar.goTo(wsBtn.modelData)
                    }
                }
            }
        }

        Text {
            id: titleText
            anchors.left: wsRow.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 420)
            elide: Text.ElideRight
            text: Hyprland.activeToplevel && Hyprland.activeToplevel.workspace
                  && Hyprland.activeToplevel.workspace.id === bar.activeId
                  ? Hyprland.activeToplevel.title : ""
            font.family: Theme.font
            font.pixelSize: 14
            font.weight: Font.Medium
            color: bar.fg
        }

        // cuộn chuột trên viên workspace để đổi workspace
        WheelHandler {
            onWheel: event => bar.goTo(Math.max(1, bar.activeId + (event.angleDelta.y < 0 ? 1 : -1)))
        }
    }

    // giữa: đảo động nằm trong Island.qml (một lớp riêng, có thể giãn ra)

    // ───────────────── phải: trạng thái ─────────────────
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var battery: UPower.displayDevice

    GlassPill {
        id: statusPill
        tone: bar.pillTone
        anchors.right: parent.right
        anchors.rightMargin: Theme.edge
        y: Theme.barTop
        height: Theme.barHeight
        width: statusRow.implicitWidth + 40

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: PanelState.toggle("control")
        }

        Row {
            id: statusRow
            anchors.centerIn: parent
            spacing: 18

            StatText { text: "CPU " + Math.round(SysStats.cpu * 100) + "%" }
            StatText { text: "RAM " + SysStats.memUsedGiB.toFixed(1).replace(".", ",") + "G" }

            StatText {
                readonly property var audio: bar.sink ? bar.sink.audio : null
                text: !audio ? "VOL –"
                      : audio.muted ? "VOL tắt"
                      : "VOL " + Math.round(audio.volume * 100) + "%"

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (parent.audio) parent.audio.muted = !parent.audio.muted
                    onWheel: wheel => {
                        if (!parent.audio) return;
                        const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                        parent.audio.volume = Math.max(0, Math.min(1, parent.audio.volume + step));
                    }
                }
            }

            StatText {
                visible: bar.battery && bar.battery.isLaptopBattery
                readonly property real pct: !bar.battery ? 0
                    : bar.battery.percentage > 1 ? bar.battery.percentage : bar.battery.percentage * 100
                readonly property bool charging: bar.battery && bar.battery.state === UPowerDeviceState.Charging
                text: "BAT " + Math.round(pct) + "%" + (charging ? " ↑" : "")
            }
        }
    }

    // ───────────────── biểu tượng ứng dụng (menu bar extras) ─────────────────
    // Ứng dụng chạy nền (Discord, Steam, Telegram, trình quản lý mạng...) đặt biểu tượng ở đây.
    //   bấm: mở ứng dụng (ứng dụng chỉ có menu thì mở menu) · chuột phải: menu · chuột giữa: việc phụ
    //   cuộn: tuỳ ứng dụng (ví dụ chỉnh âm lượng)
    readonly property var trayItems: SystemTray.items.values

    TrayMenu { id: trayMenu; screen: bar.screen }

    GlassPill {
        id: trayPill
        tone: bar.pillTone
        visible: bar.trayItems.length > 0
        anchors.right: statusPill.left
        anchors.rightMargin: 10
        y: Theme.barTop
        height: Theme.barHeight
        width: trayRow.implicitWidth + 24

        Row {
            id: trayRow
            anchors.centerIn: parent
            spacing: 6

            Repeater {
                model: bar.trayItems
                delegate: Item {
                    id: tray
                    required property var modelData
                    width: 28
                    height: 28

                    Rectangle {
                        anchors.fill: parent
                        radius: 9
                        color: trayMenu.item === tray.modelData ? bar.selBg
                             : trayArea.containsMouse ? Theme.chip : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.fast } }
                    }
                    Image {
                        id: trayIcon
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        source: tray.modelData.icon
                        sourceSize: Qt.size(36, 36)
                        asynchronous: true
                        smooth: true
                        visible: status === Image.Ready
                    }
                    // ứng dụng không gửi được biểu tượng: hiện chữ cái đầu
                    Text {
                        anchors.centerIn: parent
                        visible: trayIcon.status !== Image.Ready
                        text: (tray.modelData.title || tray.modelData.id || "?").charAt(0).toUpperCase()
                        font.family: Theme.font
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: trayMenu.item === tray.modelData ? bar.selFg : bar.fg
                    }
                    // ứng dụng cần chú ý (tin nhắn mới, pin yếu...)
                    Rectangle {
                        visible: tray.modelData.status === Status.NeedsAttention
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 2
                        width: 7
                        height: 7
                        radius: 3.5
                        color: "#ff9f0a"
                    }

                    MouseArea {
                        id: trayArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        function showMenu() {
                            if (trayMenu.item === tray.modelData) { trayMenu.close(); return; }
                            trayMenu.open(tray.modelData, tray.mapToItem(null, 0, 0).x);
                        }
                        onClicked: mouse => {
                            const it = tray.modelData;
                            if (mouse.button === Qt.MiddleButton) it.secondaryActivate();
                            else if (mouse.button === Qt.RightButton || it.onlyMenu) { if (it.hasMenu) showMenu(); }
                            else { trayMenu.close(); it.activate(); }
                        }
                        onWheel: wheel => tray.modelData.scroll(wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x,
                                                                wheel.angleDelta.y === 0)
                    }
                }
            }
        }
    }

    component StatText: Text {
        font.family: Theme.mono
        font.pixelSize: 12
        font.weight: Font.Medium
        font.letterSpacing: 0.5
        color: bar.fg
    }
}
