import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets

// Đảo động ở giữa thanh trên. Thứ tự ưu tiên khi nhiều việc cùng lúc:
//   bảng widget (bấm vào đồng hồ, Super + W)  >  âm lượng / độ sáng  >  thông báo  >  tai nghe vừa kết nối  >  đang quay màn hình
//   >  trình phát mở rộng (bấm vào đảo khi có nhạc)  >  nhạc thu gọn  >  đồng hồ
PanelWindow {
    id: win

    screen: Quickshell.screens.find(s => Hyprland.focusedMonitor && s.name === Hyprland.focusedMonitor.name)
            ?? Quickshell.screens[0]

    anchors.top: true
    // đủ chỗ cho bảng widget; phần trong suốt không nhận chuột (xem mask)
    implicitWidth: 900
    implicitHeight: 640
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.namespace: "glass-island"
    WlrLayershell.layer: WlrLayer.Top
    // bảng widget có ô ghi chú: cho gõ phím khi bấm vào
    WlrLayershell.keyboardFocus: mode === "dash" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // bấm ra ngoài đảo thì thu bảng widget lại
    HyprlandFocusGrab {
        windows: [win]
        active: win.mode === "dash"
        onCleared: PanelState.close()
    }

    // chỉ phần viên kính nhận chuột, phần trong suốt xung quanh cho chuột đi xuyên qua
    mask: Region { item: body }

    property bool expanded: false

    readonly property bool dash: PanelState.open === "widgets"
    readonly property string mode: dash ? "dash"
        : Osd.active ? "osd"
        : Notifs.current ? "notif"
        : Osd.deviceActive ? "device"
        : Recorder.active ? "rec"
        : (expanded && Media.hasTrack) ? "player"
        : (Media.playing && Media.hasTrack) ? "media"
        : "clock"

    onModeChanged: {
        if (mode !== "player" && mode !== "media") expanded = false;
        // chuột đang nằm trên đảo lúc thông báo tới hoặc đi: báo lại cho đúng (để thông báo không bị giữ mãi / mất sớm)
        Notifs.hovering = hover.hovered && mode === "notif";
    }

    readonly property var size: ({
        clock:  Qt.size(clockText.implicitWidth + 40, Theme.barHeight),
        media:  Qt.size(Math.min(380, mediaRow.implicitWidth + 28), Theme.barHeight),
        osd:    Qt.size(340, 48),
        device: Qt.size(Math.max(340, deviceRow.implicitWidth + 32), 58),
        rec:    Qt.size(recRow.implicitWidth + 36, Theme.barHeight),
        notif:  Qt.size(460, notifCard.implicitHeight),
        player: Qt.size(520, playerCard.implicitHeight + 36),
        dash:   Qt.size(dashView.implicitWidth, dashView.implicitHeight)
    })[mode]

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    GlassPill {
        id: body
        tone: "dark"
        // nền sau thanh trên sáng: đảo đậm gần như đen (như đảo động thật) để chữ trắng vẫn rõ
        color: Glass.topBright ? Qt.rgba(0.08, 0.09, 0.11, 0.84) : Theme.panel
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.barTop
        // co giãn bằng lò xo: đổi trạng thái giữa chừng thì rẽ mượt sang cỡ mới, nảy nhẹ như đảo động của iPhone
        width: sw.value
        height: sh.value
        smoothWidth: false
        radius: Math.min(height / 2, 28)
        clip: true

        Spring { id: sw; target: win.size.width; response: 0.42; damping: 0.78 }
        Spring { id: sh; target: win.size.height; response: 0.42; damping: 0.74 }

        HoverHandler {
            id: hover
            onHoveredChanged: {
                Notifs.hovering = hovered && win.mode === "notif";
                if (!hovered && win.expanded) collapseTimer.restart();
                else collapseTimer.stop();
            }
        }
        Timer { id: collapseTimer; interval: 1500; onTriggered: win.expanded = false }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (win.mode === "clock") PanelState.toggle("widgets");
                else if (win.mode === "media") win.expanded = true;
                else if (win.mode === "notif") PanelState.toggle("control");
                else if (win.mode === "rec") Recorder.stop();
            }
        }

        // ── bảng widget: lịch, thời tiết, ghi chú, tài nguyên ──
        Fader {
            on: win.mode === "dash"
            focus: on
            Keys.onEscapePressed: PanelState.close()
            IslandDash {
                id: dashView
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: implicitWidth
                active: win.mode === "dash"
                onCloseRequested: PanelState.close()
            }
        }

        // ── đồng hồ ──
        Fader {
            on: win.mode === "clock"
            // phút đổi thì chữ nhoè rồi hiện rõ lại (MorphText.qml)
            MorphText {
                id: clockText
                anchors.centerIn: parent
                text: clock.date.toLocaleString(Qt.locale("vi_VN"), "ddd, dd/MM") + "  ·  "
                      + Qt.formatDateTime(clock.date, Settings.misc.clock24 ? "HH:mm" : "h:mm AP")
                font: Qt.font({ family: Theme.font, pixelSize: 14, weight: Font.DemiBold })
                color: Theme.fg
            }
            // chấm nhỏ khi có thông báo chưa xem
            Rectangle {
                visible: Notifs.list.length > 0
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 6
                height: 6
                radius: 3
                color: Theme.mark
            }
        }

        // ── nhạc thu gọn ──
        Fader {
            on: win.mode === "media"
            Row {
                id: mediaRow
                x: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                ClippingRectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: Theme.chip
                    Image {
                        id: art
                        anchors.fill: parent
                        source: Media.player ? (Media.player.trackArtUrl || "") : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(56, 56)
                        asynchronous: true
                    }
                    // bài không có ảnh bìa: hiện nốt nhạc thay cho vòng tròn trống
                    Icon {
                        visible: art.status !== Image.Ready
                        anchors.centerIn: parent
                        path: Icons.music
                        size: 14
                        color: Theme.dim
                    }
                }
                MorphText {
                    width: Math.min(implicitWidth, 250)
                    elide: Text.ElideRight
                    anchors.verticalCenter: parent.verticalCenter
                    text: Media.player ? (Media.player.trackTitle || Media.player.identity) : ""
                    font: Qt.font({ family: Theme.font, pixelSize: 14, weight: Font.DemiBold })
                    color: Theme.fg
                }
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 20
                    spacing: 3
                    Repeater {
                        model: Media.bars.slice(0, 6)
                        delegate: Rectangle {
                            required property var modelData
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3
                            height: Math.max(3, 20 * Math.min(1, modelData))
                            radius: 2
                            color: Theme.mark
                        }
                    }
                }
            }
        }

        // ── trình phát mở rộng ──
        Fader {
            on: win.mode === "player"
            MediaCard {
                id: playerCard
                x: 20
                y: 18
                width: parent.width - 40
            }
        }

        // ── âm lượng / độ sáng ──
        Fader {
            on: win.mode === "osd"
            Row {
                x: 18
                anchors.verticalCenter: parent.verticalCenter
                spacing: 14
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    path: Osd.kind === "brightness" ? Icons.sun : Osd.muted ? Icons.volumeOff : Icons.volume
                    size: 20
                }
                Item {
                    width: 220
                    height: 6
                    anchors.verticalCenter: parent.verticalCenter
                    Rectangle { anchors.fill: parent; radius: 3; color: Theme.chip }
                    Rectangle {
                        width: parent.width * Math.min(1, Osd.muted ? 0 : Osd.value)
                        height: parent.height
                        radius: 3
                        color: Theme.mark
                        Behavior on width { NumberAnimation { duration: Theme.fast } }
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Osd.muted ? "tắt" : Math.round(Osd.value * 100) + "%"
                    font.family: Theme.mono
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: Theme.fg
                }
            }
        }

        // ── tai nghe vừa kết nối ──
        Fader {
            on: win.mode === "device"
            Row {
                id: deviceRow
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12
                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: Theme.chip
                    Icon { anchors.centerIn: parent; path: Icons.headphones; size: 19 }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: Osd.device ? Osd.device.name : ""
                        font.family: Theme.font
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        color: Theme.fg
                    }
                    Text {
                        text: "Đã kết nối"
                        font.family: Theme.font
                        font.pixelSize: 12
                        color: Theme.dim
                    }
                }
                Text {
                    visible: !!Osd.device && Osd.device.batteryAvailable
                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: 6
                    text: Osd.device ? "Pin " + Math.round(Osd.device.battery * 100) + "%" : ""
                    font.family: Theme.mono
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: Theme.fg
                }
            }
        }

        // ── đang quay màn hình: bấm để dừng ──
        Fader {
            on: win.mode === "rec"
            Row {
                id: recRow
                anchors.centerIn: parent
                spacing: 10
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 10
                    height: 10
                    radius: 5
                    color: "#ff5a5f"
                    // chấm đỏ nhấp nháy khi đang quay; tắt hiệu ứng thì đứng yên
                    SequentialAnimation on opacity {
                        running: win.mode === "rec" && Settings.look.animations
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Recorder.elapsed
                    font.family: Theme.mono
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: Theme.fg
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Bấm để dừng"
                    font.family: Theme.font
                    font.pixelSize: 13
                    color: Theme.dim
                }
            }
        }

        // ── thông báo ──
        Fader {
            on: win.mode === "notif"
            NotifCard {
                id: notifCard
                width: parent.width
                notif: Notifs.current
                compact: true
                fill: "transparent"
            }
        }
    }

    // nội dung của một trạng thái: mờ dần khi chuyển
    component Fader: Item {
        property bool on: false
        anchors.fill: parent
        opacity: on ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.fast } }
    }
}
