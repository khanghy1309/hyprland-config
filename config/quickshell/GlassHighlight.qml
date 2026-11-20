import QtQuick

// Viên kính đánh dấu mục đang chọn / đang rê chuột, kiểu liquid glass: nền trong, viền sáng mảnh,
// vệt sáng ở mép trên, chữ phía trên vẫn sáng (khác viên trắng đục cũ).
// Hai cách dùng:
//   1. Đặt trong một mục:          GlassHighlight { anchors.fill: parent; on: hovered }
//   2. Một viên trượt theo mục:     GlassHighlight { follow: mụcĐangChọn }  (đặt cùng cha, dưới các mục)
//      viên kính lướt sang mục mới bằng lò xo như con trỏ của macOS, không nhảy.
// Cài đặt → Giao diện → Mục đang chọn = "Trắng đục" thì vẽ viên trắng như trước.
Item {
    id: hl
    property bool on: follow !== null
    property Item follow: null
    property real radius: 11
    property bool danger: false
    // true: kính sáng hơn (ô đang bật, nút chính)
    property bool strong: false
    // khi trượt: lề so với mục
    property real inset: 0

    // ── trượt theo mục ──
    // Toạ độ của mục trong cha của viên kính. Đọc cả vị trí của cha và ông của mục (Row, Column…) để
    // biểu thức tự tính lại khi bố cục xếp xong hoặc đổi (mapToItem một mình không báo khi đổi).
    readonly property rect _cur: {
        const f = follow;
        if (!f || !parent) return Qt.rect(0, 0, 0, 0);
        const deps = [f.x, f.y, f.width, f.height,
                      f.parent ? f.parent.x + f.parent.y + f.parent.width : 0,
                      f.parent && f.parent.parent ? f.parent.parent.x + f.parent.parent.y : 0];
        const p = f.mapToItem(parent, 0, 0);
        return Qt.rect(p.x + inset, p.y + inset, f.width - inset * 2, f.height - inset * 2);
    }
    property rect _r: Qt.rect(0, 0, 0, 0)
    on_CurChanged: {
        if (_cur.width <= 0 || _cur.height <= 0) return;
        // đang ẩn (chưa chọn gì): hiện ngay tại mục mới, không trượt từ chỗ cũ
        const first = _r.width <= 0 || fade.opacity < 0.05;
        _r = _cur;
        if (first) { sx.snap(); sy.snap(); sw.snap(); sh.snap(); }
    }
    Spring { id: sx; target: hl._r.x; response: 0.22 }
    Spring { id: sy; target: hl._r.y; response: 0.22 }
    Spring { id: sw; target: hl._r.width; response: 0.22 }
    Spring { id: sh; target: hl._r.height; response: 0.22 }
    readonly property bool _slide: _r.width > 0 && (follow !== null || fade.opacity > 0)
    Binding on x { when: hl._slide; value: sx.value }
    Binding on y { when: hl._slide; value: sy.value }
    Binding on width { when: hl._slide; value: sw.value }
    Binding on height { when: hl._slide; value: sh.value }

    Item {
        id: fade
        anchors.fill: parent
        opacity: hl.on ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.fast } }

        Rectangle {
            id: body
            anchors.fill: parent
            radius: hl.radius
            color: hl.danger ? Theme.selDanger : hl.strong ? Theme.onFill : Theme.selFill
            border.width: Theme.glassSel ? 1 : 0
            border.color: hl.danger ? Qt.rgba(1, 0.7, 0.68, 0.5) : Theme.selRim
            // ánh sáng phía trên rõ hơn phía dưới, như mặt kính cong
            gradient: Theme.glassSel ? sheen : null
            Gradient {
                id: sheen
                GradientStop { position: 0.0; color: Qt.rgba(body.color.r, body.color.g, body.color.b, Math.min(1, body.color.a * 1.55)) }
                GradientStop { position: 0.55; color: body.color }
                GradientStop { position: 1.0; color: Qt.rgba(body.color.r, body.color.g, body.color.b, body.color.a * 0.7) }
            }
        }
        // vệt sáng mảnh ở mép trên
        Rectangle {
            visible: Theme.glassSel
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.max(0, parent.width - hl.radius * 1.4)
            height: 1
            radius: 0.5
            color: Qt.rgba(1, 1, 1, 0.55)
        }
    }
}
