import QtQuick
import QtQuick.Effects

// Chữ đổi bằng hiệu ứng mờ: khi `text` đổi, chữ cũ nhoè đi, nhạt và co nhẹ, chữ mới hiện rõ dần
// từ chỗ nhoè. Độ rộng đổi cũng trượt mượt. Dùng thay cho Text ở chỗ chữ hay đổi (giờ, tên bài hát).
// Ý tưởng từ MorphText của MacShell (github.com/0-ss/MacShell, giấy phép MIT).
Item {
    id: root

    property string text: ""
    property font font: Qt.font({ family: Theme.font, pixelSize: 14 })
    property color color: Theme.fg
    property int elide: Text.ElideNone
    property int duration: 340

    implicitWidth: Math.max(a.implicitWidth, b.implicitWidth * b.opacity)
    implicitHeight: Math.max(a.implicitHeight, b.implicitHeight)

    // a: chữ đang hiện, b: chữ cũ đang tan
    property real t: 1
    onTextChanged: {
        b.text = a.text;
        a.text = root.text;
        if (!Settings.look.animations || b.text === "") { t = 1; return; }
        anim.restart();
    }
    Component.onCompleted: a.text = text
    NumberAnimation { id: anim; target: root; property: "t"; from: 0; to: 1; duration: root.duration; easing.type: Easing.OutCubic }

    Text {
        id: a
        width: root.width > 0 ? root.width : implicitWidth
        font: root.font
        color: root.color
        elide: root.elide
        opacity: root.t
        scale: 0.96 + 0.04 * root.t
        layer.enabled: root.t < 1
        layer.effect: MultiEffect { blurEnabled: true; blur: 1 - root.t; blurMax: 16 }
    }
    Text {
        id: b
        width: a.width
        font: root.font
        color: root.color
        elide: root.elide
        visible: root.t < 1
        opacity: 1 - root.t
        scale: 1 - 0.05 * root.t
        layer.enabled: visible
        layer.effect: MultiEffect { blurEnabled: true; blur: root.t; blurMax: 16 }
    }
}
