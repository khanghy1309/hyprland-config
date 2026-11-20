import QtQuick
import Quickshell

// Một viên kính bo tròn. Phần mờ phía sau do Hyprland làm (lớp "glass-..."); viên kính vẽ thêm
// chất liệu bằng shaders/glass.frag:
//   - vệt sáng mảnh ở mép phía nguồn sáng (trên trái), bóng nhẹ ở mép dưới phía trong
//   - khi phía sau chỉ có hình nền (dock, thanh trên, đảo động thu gọn): hình nền bị bẻ cong ở mép
//     như nhìn qua kính lồi thật, tách màu nhẹ ở viền
// Kiểu kính chọn trong Cài đặt → Giao diện (xem Glass.qml). Kiểu "phẳng" hoặc máy không chạy được
// shader thì quay về viên kính cũ: nền trong mờ, viền mảnh, vệt sáng ở mép trên.
Item {
    id: pill

    // "light" = kính sáng, "dark" = kính tối, "strong" = kính tối đậm hơn
    property string tone: "light"
    property real radius: Math.min(height / 2, 30)
    property color color: tone === "dark" ? Theme.panel : tone === "strong" ? Theme.panelStrong : Theme.glass
    // cho phép khúc xạ hình nền (tắt cho kính nằm trên nền khác, ví dụ ô trong một bảng)
    property bool refractable: true
    // viền sáng lên ở chỗ gần con trỏ: glow 0 … 1, glowPos theo toạ độ của viên kính
    property real glow: 0
    property point glowPos: Qt.point(width / 2, 0)
    property bool smoothWidth: true

    Behavior on width { enabled: pill.smoothWidth; NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
    Behavior on glow { NumberAnimation { duration: Theme.normal } }

    readonly property bool useShader: Glass.shader && fx.status !== ShaderEffect.Error

    // ── kính phẳng (dự phòng) ──
    Rectangle {
        anchors.fill: parent
        visible: !pill.useShader
        radius: pill.radius
        color: pill.color
        border.width: 1
        border.color: Theme.rim
        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.max(0, parent.width - parent.radius * 1.6)
            height: 1
            color: Theme.highlight
            opacity: 0.6
        }
    }

    // ── vị trí trên màn hình (để biết lấy phần nào của hình nền, và có cửa sổ nào phía sau không) ──
    readonly property var _win: QsWindow.window
    property point _sp: Qt.point(0, 0)
    property bool _placed: false
    function _locate() {
        const w = _win;
        if (!w || !w.screen || !w.anchors || !w.contentItem) { _placed = false; return; }
        const a = w.anchors, m = w.margins, sw = w.screen.width, sh = w.screen.height;
        const ox = a.left ? m.left : a.right ? sw - w.width - m.right : (sw - w.width) / 2;
        const oy = a.top ? m.top : a.bottom ? sh - w.height - m.bottom : (sh - w.height) / 2;
        const p = w.contentItem.mapFromItem(pill, 0, 0);
        const np = Qt.point(Math.round(ox + p.x), Math.round(oy + p.y));
        if (np.x !== _sp.x || np.y !== _sp.y) _sp = np;
        _placed = true;
    }
    onXChanged: _locate()
    onYChanged: _locate()
    onWidthChanged: _locate()
    onHeightChanged: _locate()
    Component.onCompleted: _locate()
    // cha hoặc ông của viên kính có thể di chuyển mà không báo: hỏi lại định kỳ (rẻ, không vẽ lại nếu không đổi)
    Timer { interval: 200; repeat: true; running: pill.visible && pill._wantRefract; onTriggered: pill._locate() }

    readonly property bool _wantRefract: useShader && refractable && Glass.canRefract && _placed
    readonly property bool _clear: {
        Glass.epoch;
        if (!_wantRefract || !_win || !_win.screen) return false;
        return !Glass.blocked(_win.screen, { x: _sp.x, y: _sp.y, w: width, h: height });
    }
    property real refractAmt: _clear ? 1 : 0
    Behavior on refractAmt { NumberAnimation { duration: Theme.ms(260); easing.type: Easing.InOutQuad } }

    // ảnh hình nền: chỉ nạp khi cần khúc xạ
    Image {
        id: wallTex
        visible: false
        source: pill._wantRefract ? Glass.fileUrl(Glass.still) : ""
        sourceSize.width: 1600
        asynchronous: true
        mipmap: true
        smooth: true
    }

    ShaderEffect {
        id: fx
        anchors.fill: parent
        visible: pill.useShader
        fragmentShader: Qt.resolvedUrl("shaders/glass.frag.qsb")

        property variant wall: wallTex
        property size size: Qt.size(width, height)
        property real radius: pill.radius
        property real refractAmt: wallTex.status === Image.Ready ? pill.refractAmt : 0
        property vector4d screenRect: Qt.vector4d(pill._sp.x, pill._sp.y,
                                                  pill._win && pill._win.screen ? pill._win.screen.width : 1920,
                                                  pill._win && pill._win.screen ? pill._win.screen.height : 1080)
        // hình nền được cắt vừa màn hình (awww và mpvpaper đều làm vậy)
        readonly property real ia: wallTex.implicitWidth / Math.max(1, wallTex.implicitHeight)
        readonly property real sa: screenRect.z / Math.max(1, screenRect.w)
        property vector4d fit: ia > sa ? Qt.vector4d(sa / ia, 1, (1 - sa / ia) / 2, 0)
                                       : Qt.vector4d(1, ia / sa, 0, (1 - ia / sa) / 2)
        property vector4d tint: Qt.vector4d(pill.color.r, pill.color.g, pill.color.b, pill.color.a)
        property real bezel: Math.min(18, Math.min(width, height) * 0.32)
        property real thickness: Math.min(16, Math.min(width, height) * 0.3)
        property real dispersion: 0.25
        property real blurLod: 4.2
        property real rim: 1
        property point glowPos: pill.glowPos
        property real glowAmt: pill.glow

        onStatusChanged: if (status === ShaderEffect.Error) console.warn("[glass] shader:", log)
    }
}
