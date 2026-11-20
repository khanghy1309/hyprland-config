import QtQuick

// Công tắc kiểu iOS 26 / macOS 26: bấm một cái là một chuyển động liền —
// núm phồng lên thành một viên kính trong khi rời chỗ, băng qua dưới dạng kính (hơi kéo dài theo
// hướng chạy, màu rãnh đổi theo nó), rồi đặc lại thành núm trắng khi tới nơi. Giữ chuột thì núm
// vẫn là kính. Không cần ảnh nền: phần "nhìn xuyên qua" là chính rãnh công tắc phía dưới.
// Ý tưởng từ LiquidSwitch của MacShell (github.com/0-ss/MacShell, giấy phép MIT).
Item {
    id: sw

    property bool on: false
    property bool held: false           // chuột đang giữ
    property bool interactive: true     // false: chỗ khác lo phần bấm (ví dụ cả hàng trong Cài đặt)
    signal toggled()

    implicitWidth: 50
    implicitHeight: 28

    function mix(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t); }

    // một giá trị duy nhất điều khiển mọi thứ: 0 = tắt, 1 = bật (nảy nhẹ khi tới nơi)
    Spring { id: along; target: sw.on ? 1 : 0; response: 0.42; damping: 0.7 }
    readonly property real pos: Math.max(0, Math.min(1, along.value))
    // độ "kính" của núm: nhiều nhất ở giữa đường, hoặc khi đang giữ
    Spring { id: glassS; target: sw.held ? 1 : 0; response: 0.25 }
    readonly property real glass: Math.min(1, Math.max(glassS.value, Math.pow(Math.sin(Math.PI * pos), 0.7)))
    readonly property real stretch: Math.min(10, Math.abs(along.velocity) * 4)

    // rãnh
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: sw.mix(Theme.chip, Theme.onFill, sw.pos)
        border.width: 1
        border.color: Theme.glassSel ? sw.mix(Theme.line, Theme.selRim, sw.pos) : Theme.line
    }

    // núm
    Item {
        id: knob
        readonly property real restW: sw.height - 6
        width: restW + 12 * sw.glass + sw.stretch
        height: restW + 4 * sw.glass
        x: 3 + (sw.width - 6 - restW) * sw.pos - (width - restW) / 2
        anchors.verticalCenter: parent.verticalCenter

        // bóng đổ nhạt dần khi núm thành kính
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 2
            anchors.bottomMargin: -2
            radius: height / 2
            color: Qt.rgba(0, 0, 0, 0.22 * (1 - sw.glass))
        }
        // thân núm: trắng đặc → kính trong
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            // kiểu kính: núm là viên kính sáng (đặc hơn khi bật); kiểu trắng đục: núm trắng, bật thì tối
            readonly property color rest: Theme.glassSel ? Qt.rgba(1, 1, 1, sw.on ? 0.78 : 0.55) : sw.on ? Theme.ink : Theme.fg
            color: sw.mix(rest, Qt.rgba(1, 1, 1, 0.16), sw.glass)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.25 + 0.45 * sw.glass)
            // ánh sáng: vệt sáng nửa trên, quầng mờ ở dưới như ánh sáng đi xuyên qua kính
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: height / 2
                opacity: sw.glass
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.42) }
                    GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.06) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.18) }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: sw.enabled && sw.interactive
        visible: sw.interactive
        cursorShape: Qt.PointingHandCursor
        onPressedChanged: sw.held = pressed
        onClicked: sw.toggled()
    }
}
