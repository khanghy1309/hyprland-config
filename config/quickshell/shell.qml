// Điểm vào của Quickshell (chạy bằng lệnh `qs`).
// Sửa bất kỳ file .qml nào trong thư mục này, Quickshell tự tải lại.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    // Khởi động sẵn các dịch vụ chạy nền (nhận thông báo, theo dõi âm lượng, nhạc...)
    readonly property var services: [Settings, Glass, Notifs, Osd, Media, Controls, Weather, Recorder, Updates]

    // Mỗi màn hình một thanh trên
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    // Dock ở cạnh dưới, tự ẩn khi có cửa sổ che
    Dock {}

    // Đảo động, ở màn hình đang dùng
    Island {}

    // Bảng widget và trung tâm điều khiển
    Panels {}

    // Trình chạy nhanh, mở bằng Super + Space
    Launcher {}

    // Menu nguồn, mở bằng Super + Esc
    PowerMenu {}

    // Alt + Tab
    Switcher {}

    // Toàn cảnh workspace (Super + Tab, vuốt 3 ngón lên)
    Overview {}

    // Bảng chụp và quay màn hình (Super + Shift + S)
    Capture {}

    // Bảng phím tắt (Super + /)
    Cheatsheet {}

    // Super + H:  qs ipc call window minimize  → cất cửa sổ đang dùng xuống dock
    IpcHandler {
        target: "window"
        function minimize(): void {
            const w = Hyprland.activeToplevel;
            if (w && WinOps.usable(w)) WinOps.minimize(w);
        }
    }

    // Menu chuột phải trên màn hình nền
    DesktopMenu {}

    // Góc nóng: đưa chuột vào góc màn hình (chọn việc trong Cài đặt → Màn hình nền và Dock)
    HotCorners {}

    // Ứng dụng Cài đặt (Super + ,)
    SettingsApp {}
}
