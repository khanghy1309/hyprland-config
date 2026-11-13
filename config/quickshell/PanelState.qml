pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Bảng nào đang mở: "" (không), "widgets" (đảo động mở rộng) hoặc "control" (trung tâm điều khiển).
// Mở từ ngoài:  qs ipc call panels widgets | control | close
Singleton {
    id: root

    property string open: ""

    function toggle(which) { root.open = root.open === which ? "" : which; }
    function close() { root.open = ""; }

    IpcHandler {
        target: "panels"
        function widgets(): void { root.toggle("widgets"); }
        function control(): void { root.toggle("control"); }
        function close(): void { root.close(); }
    }
}
