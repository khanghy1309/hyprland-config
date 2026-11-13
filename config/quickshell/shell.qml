// Điểm vào của Quickshell (chạy bằng lệnh `qs`).
// Sửa bất kỳ file .qml nào trong thư mục này, Quickshell tự tải lại.

import QtQuick
import Quickshell

ShellRoot {
    // Khởi động sẵn các dịch vụ chạy nền (nhận thông báo, theo dõi âm lượng, nhạc...)
    readonly property var services: [Settings, Notifs, Osd, Media, Controls, Weather, Recorder]

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

    // Toàn cảnh workspace (Super + Tab, vuốt 3 ngón lên)
    Overview {}

    // Bảng chụp và quay màn hình (Super + Shift + S)
    Capture {}

    // Bảng phím tắt (Super + /)
    Cheatsheet {}

    // Ứng dụng Cài đặt (Super + ,)
    SettingsApp {}
}
