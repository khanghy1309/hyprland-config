pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Đọc CPU và RAM từ /proc mỗi 2 giây.
Singleton {
    id: root

    property real cpu: 0          // 0..1
    property real memUsedGiB: 0
    property real memTotalGiB: 0

    property var _lastTotal: 0
    property var _lastIdle: 0

    function parseCpu(text) {
        const line = text.split("\n")[0];               // "cpu  user nice system idle iowait irq softirq steal ..."
        const v = line.trim().split(/\s+/).slice(1).map(Number);
        if (v.length < 5) return;
        const idle = v[3] + (v[4] || 0);
        const total = v.reduce((a, b) => a + b, 0);
        const dt = total - root._lastTotal;
        const di = idle - root._lastIdle;
        if (root._lastTotal > 0 && dt > 0)
            root.cpu = Math.max(0, Math.min(1, 1 - di / dt));
        root._lastTotal = total;
        root._lastIdle = idle;
    }

    function parseMem(text) {
        let total = 0, avail = 0;
        for (const l of text.split("\n")) {
            if (l.startsWith("MemTotal:")) total = parseInt(l.split(/\s+/)[1]);
            else if (l.startsWith("MemAvailable:")) avail = parseInt(l.split(/\s+/)[1]);
        }
        if (total > 0) {
            root.memTotalGiB = total / 1048576;
            root.memUsedGiB = (total - avail) / 1048576;
        }
    }

    FileView {
        id: statFile
        path: "/proc/stat"
        onLoaded: root.parseCpu(text())
    }

    FileView {
        id: memFile
        path: "/proc/meminfo"
        onLoaded: root.parseMem(text())
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            memFile.reload();
        }
    }
}
