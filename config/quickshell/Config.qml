pragma Singleton

import QtQuick
import Quickshell

// Các giá trị dùng chung cho bảng widget, ánh sáng đêm, thông báo.
// Từ đợt 5, chỉnh trong ứng dụng Cài đặt (Super + ,); file này chỉ đọc lại từ đó.
// Riêng đường dẫn ghi chú vẫn sửa ở đây.
Singleton {
    // ── Thời tiết (Cài đặt → Thời tiết) ──
    readonly property string weatherCity: Settings.weather.city
    readonly property real weatherLat: Settings.weather.city ? Settings.weather.lat : NaN
    readonly property real weatherLon: Settings.weather.city ? Settings.weather.lon : NaN

    // ── Ghi chú nhanh ──
    readonly property string notesFile: Quickshell.env("HOME") + "/notes/quick.md"

    // ── Ánh sáng đêm (độ K, càng thấp càng vàng; Cài đặt → Giao diện) ──
    readonly property int nightLightTemp: Settings.misc.nightLightTemp

    // ── Thông báo (ms hiện trên đảo động; Cài đặt → Giao diện) ──
    readonly property int notifTimeout: Settings.misc.notifTimeout
}
