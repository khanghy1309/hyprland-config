import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Hiệu ứng khi thu nhỏ cửa sổ (Super + H, nút thu nhỏ, menu dock) và khi hiện lại từ dock:
//   "genie"  cửa sổ bị hút vào biểu tượng trên dock như macOS (mặc định)
//   "scale"  cửa sổ thu nhỏ và mờ dần về phía dock
//   "off"    không hiệu ứng
// Chọn trong Cài đặt → Dock.
//
// Cách làm: một lớp phủ trong suốt, không nhận chuột, nằm trên mọi cửa sổ, giữ một ảnh chụp tĩnh của
// cửa sổ và chạy hiệu ứng trên ảnh đó. Cửa sổ thật được cất đi (hoặc đưa về) đúng lúc ảnh đã có,
// nên mắt không thấy chỗ chuyển. Không có ảnh trong 0,9 giây thì làm luôn, không hiệu ứng.
// Ý tưởng từ MinimizeFx của MacShell (github.com/0-ss/MacShell, giấy phép MIT).
Scope {
    id: fx

    readonly property string effect: Settings.dock.minimizeFx
    readonly property int duration: effect === "scale" ? 320 : 520

    // việc đang chạy: { tl, screen, win: {x,y,width,height}, target: {...}, reverse, before(), after() }
    property var job: null
    property real progress: 0
    property bool captured: false
    property real handover: 1

    Component.onCompleted: WinOps.fx = fx

    // Super + H gọi:  qs ipc call window minimize
    IpcHandler {
        target: "window"
        function minimize(): void {
            const w = Hyprland.activeToplevel;
            if (w && WinOps.usable(w)) WinOps.minimize(w);
        }
    }

    // ── gọi từ WinOps ──
    function play(j) {
        // còn việc cũ (đang chờ ảnh, đang chạy, hoặc đang bàn giao): làm cho xong ngay rồi mới nhận việc mới
        handoverAnim.stop();
        if (job) {
            anim.stop();
            captureWait.stop();
            const old = job;
            job = null;
            settle(old);
        }
        if (effect === "off" || !j.tl || !j.screen) { run(j.before); run(j.after); return; }
        progress = j.reverse ? 1 : 0;
        captured = false;
        handover = 1;
        job = j;
        captureWait.restart();
    }
    function run(f) { if (f) f(); }
    // chạy nốt phần việc thật của một việc, mỗi phần đúng một lần
    function settle(j) {
        const b = j.before, a = j.after;
        j.before = null;
        j.after = null;
        run(b);
        run(a);
    }

    function start() {
        if (!job) return;
        run(job.before);
        job.before = null;
        anim.from = job.reverse ? 1 : 0;
        anim.to = job.reverse ? 0 : 1;
        anim.duration = duration;
        anim.restart();
    }
    function finish() {
        anim.stop();
        captureWait.stop();
        const j = job;
        if (!j) return;
        settle(j);
        if (j.reverse) { handoverAnim.restart(); return; }   // cửa sổ thật đã về: ảnh chụp mờ đi trên nó
        job = null;
    }
    function giveUp() {
        console.log("[thu nhỏ] không chụp được cửa sổ kịp, làm luôn không hiệu ứng");
        const j = job;
        job = null;
        if (j) settle(j);
    }

    Timer { id: captureWait; interval: 900; onTriggered: if (!fx.captured) fx.giveUp() }
    NumberAnimation {
        id: anim
        target: fx
        property: "progress"
        // rời đi ngay rồi lướt êm vào chỗ
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.22, 0.8, 0.28, 1.0, 1.0, 1.0]
        onFinished: fx.finish()
    }
    NumberAnimation {
        id: handoverAnim
        target: fx; property: "handover"; from: 1; to: 0; duration: 180; easing.type: Easing.OutCubic
        onFinished: { fx.job = null; fx.handover = 1; }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: ow
            required property var modelData
            screen: modelData
            readonly property bool mine: fx.job !== null && fx.job.screen === modelData.name

            visible: mine
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: Region {}                       // không nhận chuột: bấm xuyên qua
            WlrLayershell.namespace: "lg-minimize"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            // toạ độ chung của Hyprland → toạ độ của màn hình này
            readonly property var mon: Hyprland.monitorFor(modelData)
            readonly property real ox: mon ? mon.x : 0
            readonly property real oy: mon ? mon.y : 0
            readonly property var w: fx.job ? fx.job.win : ({ x: 0, y: 0, width: 1, height: 1 })
            readonly property var t: fx.job ? fx.job.target : ({ x: 0, y: 0, width: 1, height: 1 })

            SafeShot {
                id: cap
                width: Math.max(1, ow.w.width)
                height: Math.max(1, ow.w.height)
                want: ow.mine ? fx.job.tl : null
                // không đặt visible: false (ảnh sẽ rỗng); hideSource của capTex đã giấu nó khỏi màn hình
                onHasContentChanged: ow.tryStart()
            }
            // ảnh đã có sẵn từ lần trước (thu nhỏ rồi hiện lại ngay): không có tín hiệu mới, phải tự kiểm tra
            Connections {
                target: fx
                function onJobChanged() { ow.tryStart(); }
            }
            function tryStart() {
                if (!mine || !fx.job || fx.captured) return;
                if (!cap.hasContent || cap.held !== fx.job.tl) return;
                fx.captured = true;
                captureWait.stop();
                fx.start();
            }
            ShaderEffectSource { id: capTex; sourceItem: cap; hideSource: true; visible: false; live: true; smooth: true }

            Item {
                anchors.fill: parent
                opacity: fx.handover

                // genie
                ShaderEffect {
                    anchors.fill: parent
                    visible: ow.mine && fx.captured && fx.effect === "genie"
                    mesh: GridMesh { resolution: Qt.size(8, 64) }
                    vertexShader: Qt.resolvedUrl("shaders/genie.vert.qsb")
                    fragmentShader: Qt.resolvedUrl("shaders/genie.frag.qsb")
                    property variant source: capTex
                    property real progress: fx.progress
                    property vector4d win: Qt.vector4d(ow.w.x - ow.ox, ow.w.y - ow.oy, ow.w.width, ow.w.height)
                    property vector4d target: Qt.vector4d(ow.t.x - ow.ox, ow.t.y - ow.oy, ow.t.width, ow.t.height)
                    property real radius: Settings.look.rounding
                    onStatusChanged: if (status === ShaderEffect.Error) console.warn("[thu nhỏ] shader genie:", log)
                }

                // thu nhỏ và mờ dần
                Item {
                    visible: ow.mine && fx.captured && fx.effect === "scale"
                    readonly property real p: fx.progress
                    x: ow.w.x - ow.ox + (ow.t.x + ow.t.width / 2 - ow.w.x - ow.w.width / 2) * p * 0.6
                    y: ow.w.y - ow.oy + (ow.t.y - ow.w.y) * p * 0.6
                    width: ow.w.width
                    height: ow.w.height
                    scale: 1 - 0.55 * p
                    opacity: 1 - p
                    ShaderEffectSource { anchors.fill: parent; sourceItem: cap; live: true }
                }
            }
        }
    }
}
