import QtQuick
import Quickshell
import Quickshell.Widgets

// Một thông báo: biểu tượng ứng dụng, tiêu đề, nội dung, nút hành động, nút đóng.
Rectangle {
    id: card

    required property var notif
    property bool compact: false     // trên đảo động: nội dung tối đa 2 dòng
    property color fill: Theme.chip
    // true: bấm nút đóng chỉ phát closeClicked() (để chỗ chứa cho tan thành bụi rồi mới xoá)
    property bool customClose: false
    signal closeClicked()

    implicitHeight: Math.max(64, body.implicitHeight + 28)
    radius: 22
    color: fill

    readonly property string iconSrc: Notifs.iconFor(notif)

    ClippingRectangle {
        id: iconBox
        x: 14
        y: 14
        width: 38
        height: 38
        radius: 19
        color: Theme.chip

        Image {
            anchors.fill: parent
            source: card.iconSrc
            visible: status === Image.Ready
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(76, 76)
            asynchronous: true
        }
        Icon {
            anchors.centerIn: parent
            visible: card.iconSrc === ""
            path: Icons.bell
            size: 18
        }
    }

    Column {
        id: body
        anchors.left: iconBox.right
        anchors.leftMargin: 12
        anchors.right: closeBtn.left
        anchors.rightMargin: 8
        y: 14
        spacing: 3

        Row {
            width: parent.width
            spacing: 8
            Text {
                width: Math.min(implicitWidth, parent.width - timeText.width - 8)
                elide: Text.ElideRight
                text: card.notif ? (card.notif.summary || card.notif.appName) : ""
                font.family: Theme.font
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: Theme.fg
            }
            Text {
                id: timeText
                text: card.notif && card.notif.appName && card.notif.summary ? card.notif.appName : ""
                font.family: Theme.font
                font.pixelSize: 12
                color: Theme.dim
                topPadding: 2
            }
        }

        Text {
            width: parent.width
            visible: text !== ""
            text: card.notif ? card.notif.body : ""
            wrapMode: Text.Wrap
            maximumLineCount: card.compact ? 2 : 5
            elide: Text.ElideRight
            textFormat: Text.PlainText
            font.family: Theme.font
            font.pixelSize: 13
            lineHeight: 1.15
            color: Theme.dim
        }

        Row {
            visible: !!card.notif && card.notif.actions.length > 0
            spacing: 6
            topPadding: 4
            Repeater {
                model: card.notif ? card.notif.actions.slice(0, 3) : []
                delegate: Rectangle {
                    required property var modelData
                    width: actText.implicitWidth + 24
                    height: 30
                    radius: 15
                    color: actMouse.containsMouse && !Theme.glassSel ? Theme.accent : Theme.chip
                    GlassHighlight { anchors.fill: parent; on: actMouse.containsMouse && Theme.glassSel; radius: 15 }
                    Text {
                        id: actText
                        anchors.centerIn: parent
                        text: parent.modelData.text
                        font.family: Theme.font
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: actMouse.containsMouse ? Theme.selFg : Theme.fg
                    }
                    MouseArea {
                        id: actMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.modelData.invoke()
                    }
                }
            }
        }
    }

    Rectangle {
        id: closeBtn
        anchors.right: parent.right
        anchors.rightMargin: 12
        y: 14
        width: 28
        height: 28
        radius: 14
        color: closeMouse.containsMouse ? Theme.chip : "transparent"
        Icon {
            anchors.centerIn: parent
            path: Icons.close
            size: 13
            stroke: 2.2
            color: Theme.dim
        }
        MouseArea {
            id: closeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: card.customClose ? card.closeClicked() : Notifs.dismiss(card.notif)
        }
    }
}
