import QtQuick

// Thanh trượt bo tròn: kéo hoặc bấm để đặt giá trị, cuộn chuột để chỉnh từng bước.
// Lúc đang giữ, thanh phồng nhẹ lên như một khối chất lỏng và đầu phần sáng thành một viên kính nhỏ;
// thả ra thì co lại với một nhịp nảy (lò xo, xem Spring.qml).
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

    Spring { id: swell; target: area.pressed ? 1 : 0; response: 0.3; damping: 0.62 }
    // kéo thì phần sáng theo tay ngay; bấm một chỗ hoặc cuộn thì trượt tới bằng lò xo
    Spring { id: fill; target: slider.value; response: area.pressed ? 0.08 : 0.28 }

    Item {
        id: body
        anchors.centerIn: parent
        width: parent.width + 6 * swell.value
        height: parent.height + 4 * swell.value

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Theme.chip
        }
        Rectangle {
            id: bar
            width: Math.max(height, body.width * Math.max(0, Math.min(1, fill.value)))
            height: parent.height
            radius: height / 2
            color: Theme.glassSel ? Qt.rgba(1, 1, 1, 0.34) : Theme.accent
            border.width: Theme.glassSel ? 1 : 0
            border.color: Theme.selRim
        }
        // viên kính ở đầu phần sáng, chỉ hiện khi đang giữ
        Rectangle {
            readonly property real k: Math.max(0, Math.min(1, swell.value))
            width: (body.height + 10) * k
            height: (body.height + 2) * k
            radius: height / 2
            x: bar.width - width / 2 - body.height * 0.25
            anchors.verticalCenter: parent.verticalCenter
            visible: k > 0.02
            color: Qt.rgba(1, 1, 1, 0.18)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.7)
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.5) }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.08) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.22) }
            }
        }
    }

    Icon {
        visible: slider.iconPath !== ""
        x: 8
        anchors.verticalCenter: parent.verticalCenter
        path: slider.iconPath
        size: 15
        color: Theme.onFg
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
