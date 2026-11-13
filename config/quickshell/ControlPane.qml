import QtQuick
import Quickshell

// Trung tâm điều khiển (trượt ra từ mép phải): công tắc nhanh, âm lượng, độ sáng,
// trình phát nhạc và danh sách thông báo.
GlassPill {
    id: pane

    tone: "strong"
    radius: 30
    width: 400

    Column {
        id: topCol
        x: 18
        y: 18
        width: parent.width - 36
        spacing: 14

        // ── công tắc ──
        Grid {
            columns: 2
            spacing: 10
            width: parent.width
            readonly property real cellW: (width - spacing) / 2

            Tile {
                width: parent.cellW
                label: "Wi-Fi"
                iconPath: Icons.wifi
                on: Controls.wifiOn
                sub: !Controls.wifiOn ? "Tắt" : (Controls.wifiName || "Bật")
                onClicked: Controls.toggleWifi()
            }
            Tile {
                width: parent.cellW
                label: "Bluetooth"
                iconPath: Icons.bluetooth
                available: !!Controls.adapter
                on: Controls.btOn
                sub: !Controls.adapter ? "Không có" : !Controls.btOn ? "Tắt"
                     : Controls.btConnected.length > 0 ? Controls.btConnected[0].name : "Bật"
                onClicked: Controls.toggleBt()
            }
            Tile {
                width: parent.cellW
                label: "Không làm phiền"
                iconPath: Icons.moon
                on: Notifs.dnd
                sub: Notifs.dnd ? "Bật" : "Tắt"
                onClicked: Notifs.dnd = !Notifs.dnd
            }
            Tile {
                width: parent.cellW
                label: "Tiết kiệm pin"
                iconPath: Icons.battery
                on: Controls.powerSaver
                sub: Controls.powerSaver ? "Bật" : "Tắt"
                onClicked: Controls.togglePowerSaver()
            }
            Tile {
                width: parent.cellW
                label: "Ánh sáng đêm"
                iconPath: Icons.sun
                on: Controls.nightLight
                sub: Controls.nightLight ? Config.nightLightTemp + "K" : "Tắt"
                onClicked: Controls.toggleNightLight()
            }
            Tile {
                width: parent.cellW
                label: "Micro"
                iconPath: Icons.mic
                available: !!Controls.source
                on: !Controls.micMuted && !!Controls.source
                sub: !Controls.source ? "Không có" : Controls.micMuted ? "Đang tắt tiếng" : "Bật"
                onClicked: Controls.toggleMic()
            }
        }

        // ── âm lượng, độ sáng ──
        Rectangle {
            width: parent.width
            height: sliders.implicitHeight + 28
            radius: 22
            color: Theme.chip
            Column {
                id: sliders
                x: 16
                y: 14
                width: parent.width - 32
                spacing: 12
                Text {
                    text: "Âm thanh"
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: Theme.fg
                }
                GlassSlider {
                    width: parent.width
                    iconPath: Controls.muted ? Icons.volumeOff : Icons.volume
                    value: Controls.muted ? 0 : Controls.volume
                    onMoved: v => Controls.setVolume(v)
                }
                Text {
                    visible: Controls.hasBrightness
                    text: "Màn hình"
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: Theme.fg
                }
                GlassSlider {
                    visible: Controls.hasBrightness
                    width: parent.width
                    iconPath: Icons.sun
                    value: Math.max(0, Controls.brightness)
                    onMoved: v => Controls.setBrightness(v)
                }
            }
        }

        // ── nhạc ──
        Rectangle {
            visible: Media.hasTrack
            width: parent.width
            height: media.implicitHeight + 32
            radius: 22
            color: Theme.chip
            MediaCard {
                id: media
                x: 16
                y: 16
                width: parent.width - 32
                showBars: false
            }
        }

        // ── tiêu đề thông báo ──
        Row {
            width: parent.width
            height: 34
            Text {
                width: parent.width - clearBtn.width
                leftPadding: 6
                anchors.verticalCenter: parent.verticalCenter
                text: "Thông báo"
                font.family: Theme.font
                font.pixelSize: 17
                font.weight: Font.DemiBold
                color: Theme.fg
            }
            Rectangle {
                id: clearBtn
                visible: Notifs.list.length > 0
                width: clearText.implicitWidth + 24
                height: 32
                radius: 16
                color: clearMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : Theme.chip
                Text {
                    id: clearText
                    anchors.centerIn: parent
                    text: "Xóa hết"
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: Theme.fg
                }
                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.clearAll()
                }
            }
        }
    }

    // ── danh sách thông báo (cuộn được) ──
    ListView {
        id: list
        x: 18
        anchors.top: topCol.bottom
        anchors.topMargin: 8
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        width: parent.width - 36
        clip: true
        spacing: 8
        model: Notifs.list.slice().reverse()       // mới nhất ở trên
        boundsBehavior: Flickable.StopAtBounds

        delegate: NotifCard {
            required property var modelData
            width: list.width
            notif: modelData
        }

        Text {
            visible: list.count === 0
            anchors.horizontalCenter: parent.horizontalCenter
            y: 30
            text: "Không có thông báo"
            font.family: Theme.font
            font.pixelSize: 14
            color: Theme.dim
        }

        add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.normal } }
        removeDisplaced: Transition { NumberAnimation { property: "y"; duration: Theme.normal; easing.type: Easing.OutCubic } }
    }
}
