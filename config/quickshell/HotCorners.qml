import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Góc nóng, như macOS: đưa chuột vào sát một góc màn hình là làm một việc (mở Toàn cảnh,
// bảng widget, khóa máy...). Chọn việc cho từng góc: Cài đặt → Màn hình nền và Dock → Góc nóng.
//
// Mỗi góc là một lớp 2 × 2 px trong suốt nằm trên cùng. Con trỏ phải dừng ở góc một chút
// (DWELL) mới tính, để lướt chuột qua không mở nhầm; chạm xong phải rời góc rồi mới chạm lại được.
// Tự tắt khi có cửa sổ toàn màn hình (xem phim, chơi game) hoặc đang bật chế độ Chơi game.
Scope {
    id: root

    readonly property int dwell: 120

    function run(a) {
        const ipc = args => Quickshell.execDetached(["qs", "ipc", "call"].concat(args));
        switch (a) {
        case "overview": ipc(["overview", "toggle"]); break;
        case "widgets":  PanelState.toggle("widgets"); break;
        case "control":  PanelState.toggle("control"); break;
        case "launcher": ipc(["launcher", "toggle"]); break;
        case "capture":  ipc(["capture", "open"]); break;
        case "lock":     Quickshell.execDetached(["loginctl", "lock-session"]); break;
        // chờ một chút để cú rê chuột vào góc không làm màn hình sáng lại ngay (lg_look.lua: rê chuột là sáng)
        case "screenOff":
            Quickshell.execDetached(["sh", "-c", "sleep 0.8; hyprctl dispatch 'hl.dsp.dpms({ action = \"off\" })'"]);
            break;
        }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: per
            required property var modelData
            readonly property var hmon: Hyprland.monitorFor(modelData)
            // có cửa sổ toàn màn hình trên workspace đang hiện của màn hình này
            readonly property bool fullscreen: {
                Glass.epoch;
                const ws = hmon && hmon.activeWorkspace ? hmon.activeWorkspace.id : -1;
                for (const t of Hyprland.toplevels.values) {
                    if (!t.workspace || t.workspace.id !== ws) continue;
                    if (t.lastIpcObject && t.lastIpcObject.fullscreen) return true;
                }
                return false;
            }
            readonly property bool off: fullscreen || Controls.gaming

            Variants {
                model: ["topLeft", "topRight", "bottomLeft", "bottomRight"]

                PanelWindow {
                    id: corner
                    required property string modelData
                    readonly property string action: Settings.hotCorners[modelData] || "none"
                    property bool armed: true

                    screen: per.modelData
                    visible: action !== "none" && !per.off
                    anchors {
                        top: corner.modelData.startsWith("top")
                        bottom: corner.modelData.startsWith("bottom")
                        left: corner.modelData.endsWith("Left")
                        right: corner.modelData.endsWith("Right")
                    }
                    implicitWidth: 2
                    implicitHeight: 2
                    exclusionMode: ExclusionMode.Ignore
                    color: "transparent"
                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.namespace: "lg-hot-corner"
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                    Timer {
                        id: hold
                        interval: root.dwell
                        onTriggered: if (corner.armed && area.containsMouse) { corner.armed = false; root.run(corner.action); }
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: hold.restart()
                        onExited: { hold.stop(); corner.armed = true; }
                    }
                }
            }
        }
    }
}
