import QtQuick

// Thanh trượt bo tròn: kéo hoặc bấm để đặt giá trị, cuộn chuột để chỉnh từng bước.
Item {
    id: slider

    property real value: 0          // 0..1
    property string iconPath: ""
    signal moved(real value)

    implicitHeight: 30

    function setFrom(x) {
        const v = Math.max(0, Math.min(1, x / width));
        slider.moved(v);
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.chip
    }

    Rectangle {
        width: Math.max(height, parent.width * slider.value)
        height: parent.height
        radius: height / 2
        color: Theme.accent
        Behavior on width { enabled: !area.pressed; NumberAnimation { duration: Theme.fast } }
    }

    Icon {
        visible: slider.iconPath !== ""
        x: 8
        anchors.verticalCenter: parent.verticalCenter
        path: slider.iconPath
        size: 15
        color: Theme.ink
    }

    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => slider.setFrom(mouse.x)
        onPositionChanged: mouse => { if (pressed) slider.setFrom(mouse.x); }
        onWheel: wheel => slider.moved(Math.max(0, Math.min(1, slider.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
