pragma Singleton

import QtQuick
import Quickshell

// Màu, phông chữ và kích thước dùng chung cho mọi phần của Quickshell.
// Đổi ở đây là cả thanh trên, launcher (và các đợt sau) đổi theo.
Singleton {
    // Chữ
    readonly property color fg: "#f3f6f6"
    readonly property color dim: "#c5d0d2"

    // Kính
    readonly property color glass: Qt.rgba(1, 1, 1, 0.14)          // viên kính sáng (workspace, trạng thái)
    // độ đậm chỉnh trong Cài đặt → Giao diện (mặc định 0,5)
    readonly property real glassAlpha: Settings.look.panelAlpha
    readonly property color panel: Qt.rgba(24 / 255, 26 / 255, 30 / 255, glassAlpha - 0.10)   // kính tối (đảo động)
    readonly property color panelStrong: Qt.rgba(24 / 255, 26 / 255, 30 / 255, glassAlpha)    // launcher, bảng trượt
    readonly property color chip: Qt.rgba(1, 1, 1, 0.12)
    readonly property color line: Qt.rgba(1, 1, 1, 0.14)
    readonly property color rim: Qt.rgba(1, 1, 1, 0.26)            // viền mép kính
    readonly property color highlight: Qt.rgba(1, 1, 1, 0.45)      // vệt sáng mép trên

    // Trắng đục, chữ tối: dùng cho công tắc đang bật, thanh trượt, tiến trình…
    readonly property color accent: "#f4f6f7"
    readonly property color ink: "#14181b"
    readonly property color inkDim: "#4a5157"

    // Mục đang chọn / đang rê chuột (menu, launcher, Cài đặt…). Chọn ở Cài đặt → Giao diện → Mục đang chọn:
    //   "glass"  viên kính trong có vệt sáng ở mép (GlassHighlight.qml), chữ vẫn sáng
    //   "white"  viên trắng đục chữ tối như trước
    readonly property bool glassSel: Settings.look.selStyle !== "white"
    readonly property color selFill: glassSel ? Qt.rgba(1, 1, 1, 0.20) : accent
    readonly property color selDanger: glassSel ? Qt.rgba(1, 0.42, 0.38, 0.34) : "#ff8a80"
    readonly property color selRim: Qt.rgba(1, 1, 1, 0.42)
    readonly property color selFg: glassSel ? fg : ink
    readonly property color selDim: glassSel ? dim : inkDim
    // Công tắc / ô đang bật, nút chính (Chụp, Cập nhật, Phát nhạc): kính sáng hơn mục đang chọn một chút
    readonly property color onFill: glassSel ? Qt.rgba(1, 1, 1, 0.28) : accent
    readonly property color onFg: glassSel ? fg : ink
    readonly property color onDim: glassSel ? dim : inkDim
    // vạch nhỏ, thanh tiến trình, chấm báo, viền đánh dấu: kính sáng (vẫn thấy rõ trên nền tối)
    readonly property color mark: glassSel ? Qt.rgba(1, 1, 1, 0.62) : accent

    // Nền của menu chuột phải, menu khay, menu dock…: trong hơn bảng kính một chút (Hyprland làm mờ
    // phía sau nên chữ vẫn đọc được), đậm theo thanh "Độ đậm của các bảng kính" trong Cài đặt
    readonly property real menuAlpha: Math.max(0.22, Math.min(0.8, Settings.look.panelAlpha - 0.14))
    readonly property color menuBg: Qt.rgba(0.09, 0.10, 0.12, menuAlpha)

    readonly property color scrim: Qt.rgba(6 / 255, 12 / 255, 16 / 255, 0.40)

    // Phông
    // phông chữ chọn trong Cài đặt → Giao diện (mặc định Geist / Geist Mono)
    readonly property string font: Settings.look.font
    readonly property string mono: Settings.look.monoFont

    // Kích thước thanh trên
    readonly property int barTop: 18
    readonly property int barHeight: 42
    readonly property int edge: 24

    // Thời gian chuyển động (ms), theo Cài đặt → Giao diện → Chuyển động: tốc độ Nhanh / Vừa / Chậm nhân
    // thời gian với 0,7 / 1 / 1,4 (cùng hệ số với Hyprland, lg_look.lua); tắt hiệu ứng thì bằng 0 (đổi ngay).
    readonly property real motion: Settings.look.animations ? Settings.look.animScale : 0
    readonly property int fast: Math.round(140 * motion)
    readonly property int normal: Math.round(240 * motion)
    function ms(x) { return Math.round(x * motion); }
    // hẹn giờ chờ một hiệu ứng chạy xong: không bao giờ 0 (Timer 0 ms chạy ngay trong lúc đang đổi trạng thái)
    function wait(x) { return Math.max(1, ms(x)); }
}
