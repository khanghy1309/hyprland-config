pragma Singleton

import QtQuick
import Quickshell

// Đường SVG của các biểu tượng (khung 24×24), lấy từ bản thiết kế.
Singleton {
    readonly property string wifi: "M2 9a15 15 0 0 1 20 0M5.5 12.5a10 10 0 0 1 13 0M9 16a5 5 0 0 1 6 0M12 19.5h.01"
    readonly property string bluetooth: "M7 7l10 10-5 5V2l5 5L7 17"
    readonly property string moon: "M20 14A8 8 0 1 1 10 4a6 6 0 0 0 10 10z"
    readonly property string battery: "M3 8h15v8H3zM21 11v2M6 12h9"
    readonly property string sun: "M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8zM12 2v2M12 20v2M2 12h2M20 12h2M5 5l1.4 1.4M17.6 17.6L19 19M5 19l1.4-1.4M17.6 6.4L19 5"
    readonly property string mic: "M12 3a3 3 0 0 0-3 3v6a3 3 0 0 0 6 0V6a3 3 0 0 0-3-3zM5 11a7 7 0 0 0 14 0M12 18v3"
    readonly property string volume: "M4 9v6h4l5 4V5L8 9zM16 9a4 4 0 0 1 0 6M19 6a8 8 0 0 1 0 12"
    readonly property string volumeOff: "M4 9v6h4l5 4V5L8 9zM17 9l5 6M22 9l-5 6"
    readonly property string headphones: "M4 15v-3a8 8 0 0 1 16 0v3M3 14h5v7H5a2 2 0 0 1-2-2zM16 14h5v5a2 2 0 0 1-2 2h-3z"
    readonly property string bell: "M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9M10 21h4"
    readonly property string close: "M6 6l12 12M18 6L6 18"
    readonly property string music: "M9 18V5l11-2v13M9 18a3 3 0 1 1-6 0 3 3 0 0 1 6 0zM20 16a3 3 0 1 1-6 0 3 3 0 0 1 6 0z"
    readonly property string play: "M7 4l13 8-13 8z"
    readonly property string pause: "M6 4h4v16H6zM14 4h4v16h-4z"
    readonly property string next: "M4 5l9 7-9 7zM13 5l9 7-9 7z"
    readonly property string prev: "M20 5l-9 7 9 7zM11 5l-9 7 9 7z"
    readonly property string chevronLeft: "M15 6l-6 6 6 6"
    readonly property string chevronRight: "M9 6l6 6-6 6"
    readonly property string cloud: "M7 19h10a4 4 0 0 0 .6-8 6 6 0 0 0-11.5 1.7A3.2 3.2 0 0 0 7 19z"
    readonly property string gamepad: "M6 9h4M8 7v4M15 10h.01M18 8h.01M7 4h10a5 5 0 0 1 4.9 6l-1 5a3 3 0 0 1-5.2 1.4L14 15h-4l-1.7 1.4A3 3 0 0 1 3.1 15l-1-5A5 5 0 0 1 7 4z"
    readonly property string camera: "M4 8h3l2-3h6l2 3h3v11H4zM12 17a4 4 0 1 0 0-8 4 4 0 0 0 0 8z"
    readonly property string pin: "M12 3v4M12 15v6M9 4h6l-1 6 4 4H6l4-4z"
}
