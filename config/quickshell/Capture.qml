import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Bảng chụp và quay màn hình (Super + Shift + S), một thanh kính ở cạnh dưới màn hình.
//   Chọn việc: chụp ảnh, quay video, hoặc đọc chữ trong một vùng (OCR).
//   Chọn vùng: một vùng tự kéo, một cửa sổ, hoặc cả màn hình.
//   Phím: 1 2 3 chọn vùng, Tab đổi việc, Enter bắt đầu, Esc đóng.
// Việc thật do ~/.config/hypr/scripts/capture.sh làm.
// Mở từ ngoài:  qs ipc call capture toggle
PanelWindow {
    id: root

    visible: false
    screen: Quickshell.screens.find(s => Hyprland.focusedMonitor && s.name === Hyprland.focusedMonitor.name)
            ?? Quickshell.screens[0]

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.namespace: "glass-capture"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // lựa chọn được giữ lại cho lần mở sau
    property string task: "shot"      // shot | record | ocr
    property string area: "region"    // region | window | screen
    property int delay: 0             // giây, chỉ cho chụp ảnh
    property string audio: "none"     // none | system | mic, chỉ cho quay
    property bool edit: false         // mở Satty sau khi chụp

    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/capture.sh"

    readonly property var tasks: [
        { id: "shot",   label: "Chụp ảnh",  path: "M4 8h3l2-3h6l2 3h3v11H4zM12 10a3.5 3.5 0 1 0 0 7 3.5 3.5 0 0 0 0-7z" },
        { id: "record", label: "Quay video", path: "M12 5a7 7 0 1 0 0 14 7 7 0 0 0 0-14z" },
        { id: "ocr",    label: "Đọc chữ",    path: "M5 7V5h14v2M12 5v14M9 19h6" }
    ]
    readonly property var areas: [
        { id: "region", label: "Vùng",          path: "M4 9V4h5M15 4h5v5M20 15v5h-5M9 20H4v-5" },
        { id: "window", label: "Cửa sổ",        path: "M3 5h18v14H3zM3 9h18" },
        { id: "screen", label: "Cả màn hình",   path: "M3 4h18v12H3zM8 20h8M12 16v4" }
    ]

    function open() { visible = true; keys.forceActiveFocus(); }
    function close() { visible = false; }
    function toggle() { visible ? close() : open(); }

    function command() {
        if (task === "ocr") return [script, "ocr"];
        if (task === "record") return [script, "record", area, "--audio", audio];
        const c = [script, "shot", area, "--delay", String(delay)];
        if (edit) c.push("--edit");
        return c;
    }

    // đóng bảng trước, chờ nó biến mất hẳn rồi mới chụp, để ảnh không dính bảng
    property var pending: null
    function start() {
        pending = command();
        close();
        runTimer.restart();
    }
    Timer {
        id: runTimer
        // chờ Hyprland làm mờ xong bảng này (layersOut ~150 ms × tốc độ) để ảnh chụp không dính bảng
        interval: Settings.look.animations ? 80 + Math.round(150 * Settings.look.animScale) : 60
        onTriggered: if (root.pending) { Quickshell.execDetached(root.pending); root.pending = null; }
    }

    IpcHandler {
        target: "capture"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function close(): void { root.close(); }
        // chạy thẳng không mở bảng, ví dụ:  qs ipc call capture ocr
        function ocr(): void { Quickshell.execDetached([root.script, "ocr"]); }
    }

    // bấm ra ngoài để đóng; không làm tối màn hình để còn thấy chỗ cần chụp
    MouseArea { anchors.fill: parent; onClicked: root.close() }

    Item {
        id: keys
        focus: true
        Keys.onPressed: event => {
            const k = event.key;
            if (k === Qt.Key_Escape) root.close();
            else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) root.start();
            else if (k === Qt.Key_1) root.area = "region";
            else if (k === Qt.Key_2) root.area = "window";
            else if (k === Qt.Key_3) root.area = "screen";
            else if (k === Qt.Key_Tab || k === Qt.Key_Right) {
                const i = root.tasks.findIndex(t => t.id === root.task);
                root.task = root.tasks[(i + 1) % root.tasks.length].id;
            } else if (k === Qt.Key_Backtab || k === Qt.Key_Left) {
                const i = root.tasks.findIndex(t => t.id === root.task);
                root.task = root.tasks[(i + root.tasks.length - 1) % root.tasks.length].id;
            } else return;
            event.accepted = true;
        }
    }

    GlassPill {
        id: bar
        tone: "strong"
        radius: 26
        height: 76
        width: content.implicitWidth + 24
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.visible ? 40 : 10
        Behavior on anchors.bottomMargin { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
        opacity: root.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.fast } }

        MouseArea { anchors.fill: parent }   // chặn click xuyên ra nền

        Row {
            id: content
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Repeater {
                model: root.tasks
                delegate: Choice {
                    required property var modelData
                    label: modelData.label
                    path: modelData.path
                    on: root.task === modelData.id
                    onPicked: root.task = modelData.id
                }
            }

            Divider {}

            Repeater {
                model: root.areas
                delegate: Choice {
                    required property var modelData
                    required property int index
                    label: modelData.label
                    path: modelData.path
                    hint: String(index + 1)
                    on: root.area === modelData.id
                    enabled: root.task !== "ocr"
                    onPicked: root.area = modelData.id
                }
            }

            Divider {}

            // tuỳ chọn, đổi theo việc đang chọn
            Cycle {
                visible: root.task === "shot"
                label: "Hẹn giờ"
                value: root.delay === 0 ? "Tắt" : root.delay + " giây"
                onPicked: root.delay = root.delay === 0 ? 3 : root.delay === 3 ? 10 : 0
            }
            Cycle {
                visible: root.task === "shot"
                label: "Sau khi chụp"
                value: root.edit ? "Mở để sửa" : "Chỉ lưu"
                onPicked: root.edit = !root.edit
            }
            Cycle {
                visible: root.task === "record"
                label: "Âm thanh"
                value: ({ none: "Không", system: "Âm thanh máy", mic: "Micro" })[root.audio]
                onPicked: root.audio = root.audio === "none" ? "system" : root.audio === "system" ? "mic" : "none"
            }
            Text {
                visible: root.task === "ocr"
                anchors.verticalCenter: parent.verticalCenter
                width: 236
                wrapMode: Text.WordWrap
                text: "Kéo chọn vùng có chữ. Chữ đọc được sẽ nằm sẵn trong bộ nhớ tạm."
                font.family: Theme.font
                font.pixelSize: 12
                color: Theme.dim
                leftPadding: 8
                rightPadding: 8
            }

            Item { width: 4; height: 1 }

            // nút bắt đầu
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: goText.implicitWidth + 40
                height: 52
                radius: 18
                color: root.task === "record" ? "#ff5a5f" : Theme.accent
                Behavior on color { ColorAnimation { duration: Theme.fast } }
                Text {
                    id: goText
                    anchors.centerIn: parent
                    text: root.task === "record" ? "Bắt đầu quay" : root.task === "ocr" ? "Chọn vùng" : "Chụp"
                    font.family: Theme.font
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: root.task === "record" ? "white" : Theme.ink
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.start()
                }
            }
        }
    }

    // ── thành phần nhỏ ──

    // nút chọn có biểu tượng và nhãn
    component Choice: Rectangle {
        id: c
        property string label
        property string path
        property string hint: ""
        property bool on: false
        signal picked()

        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        width: Math.max(72, cl.implicitWidth + 20)
        height: 56
        radius: 16
        opacity: enabled ? 1 : 0.35
        color: on && !Theme.glassSel ? Theme.accent : !on && cm.containsMouse ? Theme.chip : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        GlassHighlight { anchors.fill: parent; on: c.on && Theme.glassSel; radius: 16 }

        Column {
            anchors.centerIn: parent
            spacing: 5
            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                path: c.path
                size: 20
                color: c.on ? Theme.selFg : Theme.fg
                filled: c.label === "Quay video"
            }
            Text {
                id: cl
                anchors.horizontalCenter: parent.horizontalCenter
                text: c.label
                font.family: Theme.font
                font.pixelSize: 12
                font.weight: Font.Medium
                color: c.on ? Theme.selFg : Theme.fg
            }
        }
        Text {
            visible: c.hint.length > 0 && c.enabled
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6
            text: c.hint
            font.family: Theme.mono
            font.pixelSize: 9
            color: c.on ? Theme.selDim : Theme.dim
        }
        MouseArea {
            id: cm
            anchors.fill: parent
            hoverEnabled: true
            enabled: c.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: c.picked()
        }
    }

    // tuỳ chọn bấm để đổi vòng
    component Cycle: Rectangle {
        id: y
        property string label
        property string value
        signal picked()

        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        width: Math.max(yl.implicitWidth, yv.implicitWidth) + 28
        height: 56
        radius: 16
        color: ym.containsMouse ? Theme.chip : "transparent"
        Column {
            anchors.centerIn: parent
            spacing: 3
            Text {
                id: yl
                anchors.horizontalCenter: parent.horizontalCenter
                text: y.label
                font.family: Theme.font
                font.pixelSize: 11
                color: Theme.dim
            }
            Text {
                id: yv
                anchors.horizontalCenter: parent.horizontalCenter
                text: y.value + "  ▾"
                font.family: Theme.font
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Theme.fg
            }
        }
        MouseArea {
            id: ym
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: y.picked()
        }
    }

    component Divider: Rectangle {
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        width: 1
        height: 36
        color: Theme.line
    }
}
