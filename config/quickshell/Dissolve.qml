import QtQuick

// Bọc một tấm thẻ để nó có thể tan thành bụi (shaders/dust.frag): gọi dissolve(độ trễ ms, hàm gọi khi xong).
// Tắt hiệu ứng chuyển động trong Cài đặt thì thẻ chỉ mờ đi nhanh.
Item {
    id: root

    default property alias content: holder.data
    property real progress: 0
    readonly property bool busy: anim.running || delay.running
    property var done: null
    readonly property real padX: 120
    readonly property real padY: 70

    function dissolve(ms, cb) {
        if (busy) return;
        done = cb;
        delay.interval = Math.max(1, ms);
        delay.restart();
    }
    Timer { id: delay; onTriggered: anim.restart() }
    NumberAnimation {
        id: anim
        target: root; property: "progress"; from: 0; to: 1
        duration: Settings.look.animations ? Math.round(900 * Settings.look.animScale) : 160
        onFinished: { const f = root.done; root.done = null; if (f) f(); }
    }

    Item {
        id: holder
        width: root.width
        height: root.height
    }

    // ảnh của tấm thẻ kèm khoảng trống cho bụi bay
    ShaderEffectSource {
        id: src
        sourceItem: root.progress > 0 ? holder : null     // chỉ chụp khi bắt đầu tan, đỡ tốn bộ nhớ cho mỗi thẻ
        sourceRect: Qt.rect(0, -root.padY, root.width + root.padX, root.height + root.padY)
        live: false
        hideSource: fx.visible
        visible: false
    }
    ShaderEffect {
        id: fx
        x: 0
        y: -root.padY
        width: root.width + root.padX
        height: root.height + root.padY
        visible: root.progress > 0 && Settings.look.animations && status !== ShaderEffect.Error
        onVisibleChanged: if (visible) src.scheduleUpdate()
        fragmentShader: Qt.resolvedUrl("shaders/dust.frag.qsb")
        property variant source: src
        property real progress: root.progress
        property size cardSize: Qt.size(root.width, root.height)
        property size pad: Qt.size(root.padX, root.padY)
    }
    // dự phòng khi không có shader: mờ dần
    states: State {
        when: root.progress > 0 && !fx.visible
        PropertyChanges { holder.opacity: 1 - root.progress }
    }
}
