import QtQuick
import Quickshell
import Quickshell.Widgets

// Thẻ trình phát nhạc: ảnh bìa, tên bài, sóng âm, thanh tiến trình, nút điều khiển.
// Dùng ở đảo động (khi mở rộng) và trung tâm điều khiển.
Item {
    id: card

    property var player: Media.player
    property bool showBars: true

    implicitHeight: col.implicitHeight

    Column {
        id: col
        width: parent.width
        spacing: 12

        Row {
            width: parent.width
            spacing: 14

            ClippingRectangle {
                width: 64
                height: 64
                radius: 14
                color: Theme.chip

                Icon {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    path: Icons.music
                    size: 26
                    color: Theme.dim
                }
                Image {
                    id: art
                    anchors.fill: parent
                    source: card.player ? (card.player.trackArtUrl || "") : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(128, 128)
                }
            }

            Column {
                width: parent.width - 64 - 14 - (bars.visible ? bars.width + 14 : 0)
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: card.player && card.player.trackTitle ? card.player.trackTitle : "Không có bài nào"
                    font.family: Theme.font
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    color: Theme.fg
                }
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: !card.player ? "" : [card.player.trackArtist, card.player.identity].filter(s => s).join(" · ")
                    font.family: Theme.font
                    font.pixelSize: 13
                    color: Theme.dim
                }
            }

            Row {
                id: bars
                visible: card.showBars
                anchors.verticalCenter: parent.verticalCenter
                height: 36
                spacing: 3
                Repeater {
                    model: Media.bars
                    delegate: Rectangle {
                        required property var modelData
                        anchors.bottom: parent.bottom
                        width: 4
                        height: Math.max(3, 36 * Math.min(1, modelData))
                        radius: 2
                        color: Theme.accent
                        Behavior on height { NumberAnimation { duration: 60 } }
                    }
                }
            }
        }

        // thanh tiến trình
        Row {
            width: parent.width
            spacing: 12
            visible: !!card.player && card.player.lengthSupported && card.player.length > 0

            Text {
                width: 44
                horizontalAlignment: Text.AlignRight
                text: card.player ? Media.fmt(card.player.position) : ""
                font.family: Theme.mono
                font.pixelSize: 12
                color: Theme.dim
                anchors.verticalCenter: parent.verticalCenter
            }
            Item {
                width: parent.width - 2 * 44 - 24
                height: 14
                anchors.verticalCenter: parent.verticalCenter
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 5
                    radius: 3
                    color: Theme.chip
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: card.player && card.player.length > 0
                           ? parent.width * Math.min(1, card.player.position / card.player.length) : 0
                    height: 5
                    radius: 3
                    color: Theme.accent
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: !!card.player && card.player.canSeek
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => card.player.position = card.player.length * (mouse.x / width)
                }
            }
            Text {
                width: 44
                text: card.player ? Media.fmt(card.player.length) : ""
                font.family: Theme.mono
                font.pixelSize: 12
                color: Theme.dim
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // nút điều khiển
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            RoundButton {
                iconPath: Icons.prev
                enabled: !!card.player && card.player.canGoPrevious
                onClicked: card.player.previous()
            }
            RoundButton {
                size: 48
                primary: true
                iconPath: card.player && card.player.isPlaying ? Icons.pause : Icons.play
                enabled: !!card.player && card.player.canTogglePlaying
                onClicked: card.player.togglePlaying()
            }
            RoundButton {
                iconPath: Icons.next
                enabled: !!card.player && card.player.canGoNext
                onClicked: card.player.next()
            }
        }
    }

    component RoundButton: Rectangle {
        id: btn
        property string iconPath: ""
        property bool primary: false
        property real size: 40
        signal clicked()

        width: size
        height: size
        radius: size / 2
        opacity: enabled ? 1 : 0.4
        color: primary ? Theme.accent : btnMouse.containsMouse ? Theme.chip : "transparent"

        Icon {
            anchors.centerIn: parent
            path: btn.iconPath
            size: btn.primary ? 18 : 18
            filled: true
            color: btn.primary ? Theme.ink : Theme.fg
        }
        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: btn.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}
