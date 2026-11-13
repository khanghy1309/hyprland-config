import QtQuick
import Quickshell
import Quickshell.Wayland
import "CaptureGate.js" as Gate

// Ảnh chụp một cửa sổ, an toàn với Hyprland.
//
// Vì sao cần: mỗi lần chụp, Hyprland trả lời bằng một "khung hình". Nếu shell bỏ nguồn chụp
// đúng lúc khung hình đó còn đang trên đường về (ví dụ đóng Alt + Tab ngay khi vừa mở, hoặc
// cửa sổ đóng lại giữa chừng), câu trả lời rơi vào một đối tượng đã mất và cả kết nối Wayland
// bị ngắt: shell sập ("wl_display#1: error 0: invalid object"). MacShell ghi lại đúng lỗi này.
//
// Cách dùng: gán `want` (cửa sổ cần chụp, hoặc null) thay vì captureSource.
//   - want = cửa sổ: nguồn được gắn sau một nhịp ngắn (xếp hàng chung, xem CaptureGate.js)
//   - want = null:   nguồn được giữ thêm graceMs rồi mới bỏ, cho khung hình đang về kịp tới
//   - không có ảnh sau 1,2 giây (cửa sổ đang đổi cỡ...): gỡ ra gắn lại, tối đa 2 lần
// `live` mặc định tắt: chỉ chụp một ảnh, đỡ tốn máy.
ScreencopyView {
    id: sc

    property var want: null
    property int graceMs: 300
    property var held: null
    property int tries: 0

    captureSource: held
    live: false

    onWantChanged: {
        tries = 0;
        if (want) {
            release.stop();
            if (held !== want) attach();
        } else {
            attachT.stop();
            retry.stop();
            if (held) release.restart();
        }
    }
    Component.onCompleted: if (want) attach()

    function attach() {
        attachT.interval = Math.max(1, Gate.slotDelay());
        attachT.restart();
    }
    Timer { id: attachT; onTriggered: if (sc.want) { sc.held = sc.want; watchdog.restart(); } }
    Timer { id: release; interval: sc.graceMs; onTriggered: if (!sc.want) sc.held = null }

    // không có ảnh: tháo nguồn, chờ cho chắc không còn khung hình nào đang về, rồi gắn lại
    Timer {
        id: watchdog
        interval: 1200
        onTriggered: {
            if (!sc.want || sc.hasContent || sc.tries >= 2) return;
            sc.tries++;
            sc.held = null;
            retry.restart();
        }
    }
    Timer { id: retry; interval: 400; onTriggered: if (sc.want) sc.attach() }
    onHasContentChanged: if (hasContent) watchdog.stop()
}
