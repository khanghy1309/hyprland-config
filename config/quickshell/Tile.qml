import QtQuick

// Ô bật/tắt trong trung tâm điều khiển. Bật = kính trắng đục, chữ tối.
Rectangle {
    id: tile

    property string label: ""
    property string sub: ""
    property string iconPath: ""
    property bool on: false
    property bool available: true
    signal clicked()

    implicitHeight: 64
    radius: 22
    opacity: available ? 1 : 0.45
    color: on ? Theme.accent : mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Theme.chip
    Behavior on color { ColorAnimation { duration: Theme.fast } }

    Accessible.role: Accessible.CheckBox
    Accessible.name: label
    Accessible.checked: on

    Rectangle {
        id: iconCircle
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 34
        height: 34
        radius: 17
        color: tile.on ? Qt.rgba(0, 0, 0, 0.10) : Theme.chip
        Icon {
            anchors.centerIn: parent
            path: tile.iconPath
            size: 18
            color: tile.on ? Theme.ink : Theme.fg
        }
    }

    Column {
        anchors.left: iconCircle.right
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        Text {
            width: parent.width
            elide: Text.ElideRight
            text: tile.label
            font.family: Theme.font
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: tile.on ? Theme.ink : Theme.fg
        }
        Text {
            width: parent.width
            elide: Text.ElideRight
            visible: text !== ""
            text: tile.sub
            font.family: Theme.font
            font.pixelSize: 12
            color: tile.on ? Theme.inkDim : Theme.dim
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: tile.available
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.clicked()
    }
}
