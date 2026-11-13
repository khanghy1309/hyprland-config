pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Theo dõi việc quay màn hình. Script capture.sh báo vào đây khi bắt đầu và kết thúc:
//   qs ipc call recorder started | stopped
// Đảo động hiện chấm đỏ và thời gian quay; bấm vào để dừng.
Singleton {
    id: root

    property bool active: false
    property real startedAt: 0
    property int seconds: 0

    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/capture.sh"

    function stop() { Quickshell.execDetached([root.script, "stop"]); }

    function started() {
        root.startedAt = Date.now();
        root.seconds = 0;
        root.active = true;
    }

    readonly property string elapsed: {
        const m = Math.floor(seconds / 60), s = seconds % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    Timer {
        running: root.active
        repeat: true
        interval: 1000
        onTriggered: root.seconds = Math.round((Date.now() - root.startedAt) / 1000)
    }

    IpcHandler {
        target: "recorder"
        function started(): void { root.started(); }
        function stopped(): void { root.active = false; }
    }

    // Quickshell khởi động lại giữa lúc đang quay: hỏi lại xem còn quay không
    Process {
        running: true
        command: ["pgrep", "-x", "wf-recorder"]
        onExited: code => { if (code === 0) root.started(); }
    }
}
