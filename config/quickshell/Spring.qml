import QtQuick

// Lò xo: `value` đuổi theo `target` như vật gắn lò xo, theo cách Apple mô tả chuyển động:
//   response  thời gian (giây) để đi gần hết quãng đường; nhỏ = nhanh, gọn
//   damping   1 = dừng êm không nảy (mặc định), < 1 = nảy nhẹ (0,8 là vừa đủ thấy)
//
// Khác Behavior + NumberAnimation: đổi target giữa chừng không bắt đầu lại từ đầu, giá trị giữ nguyên
// vị trí và vận tốc đang có rồi rẽ sang đích mới, nên không bị khựng khi đảo chiều.
// Dùng:  Spring { id: sw; target: muốnRộng }   rồi   width: sw.value
// Ý tưởng từ MacShell (github.com/0-ss/MacShell, giấy phép MIT).
Item {
    id: sp
    width: 0
    height: 0
    visible: false

    property real target: 0
    property real value: 0
    property real velocity: 0
    property real response: 0.32
    property real damping: 1.0
    property real epsilon: 0.01
    // tắt hiệu ứng (Cài đặt → Giao diện → Hiệu ứng chuyển động): nhảy thẳng tới đích
    property bool animated: Settings.look.animations
    readonly property bool running: fa.running

    Component.onCompleted: { value = target; velocity = 0; }

    // nhảy thẳng tới đích, không chuyển động (dùng khi vật đang ẩn)
    function snap() { fa.stop(); value = target; velocity = 0; }

    onTargetChanged: {
        if (!animated) { snap(); return; }
        if (Math.abs(target - value) > epsilon || Math.abs(velocity) > epsilon) fa.start();
    }

    function step(dt) {
        dt = Math.min(Math.max(dt, 0), 0.05);          // khung hình bị nghẽn không làm lò xo "nổ"
        const w = 2 * Math.PI / Math.max(response * Settings.look.animScale, 0.02);
        const k = w * w, c = 2 * damping * w;
        const n = Math.max(1, Math.ceil(dt / 0.004));  // chia nhỏ bước cho lò xo cứng vẫn ổn định
        const h = dt / n;
        let v = velocity, x = value;
        for (let i = 0; i < n; i++) {
            v += (k * (target - x) - c * v) * h;
            x += v * h;
        }
        velocity = v;
        value = x;
        if (Math.abs(target - x) < epsilon && Math.abs(v) < epsilon * 10) snap();
    }

    FrameAnimation {
        id: fa
        onTriggered: sp.step(frameTime)
    }
}
