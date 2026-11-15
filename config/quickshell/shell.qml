// Điểm vào của Quickshell (chạy bằng lệnh `qs`).
// Sửa bất kỳ file .qml nào trong thư mục này, Quickshell tự tải lại.

import QtQuick
import Quickshell

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

    // Hiệu ứng thu nhỏ cửa sổ vào dock (genie)
    MinimizeFx {}

    // Menu chuột phải trên màn hình nền
    DesktopMenu {}

    // Ứng dụng Cài đặt (Super + ,)
    SettingsApp {}
}
