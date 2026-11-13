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

    // Mục đang chọn: kính trắng đục, chữ tối
    readonly property color accent: "#f4f6f7"
    readonly property color ink: "#14181b"
    readonly property color inkDim: "#4a5157"

    readonly property color scrim: Qt.rgba(6 / 255, 12 / 255, 16 / 255, 0.40)

    // Phông
    // phông chữ chọn trong Cài đặt → Giao diện (mặc định Geist / Geist Mono)
    readonly property string font: Settings.look.font
    readonly property string mono: Settings.look.monoFont

    // Kích thước thanh trên
    readonly property int barTop: 18
    readonly property int barHeight: 42
    readonly property int edge: 24

    // Thời gian chuyển động (ms)
    readonly property int fast: 140
    readonly property int normal: 240
}
