pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

// Mọi công tắc và thanh trượt của trung tâm điều khiển.
Singleton {
    id: root

    // ── âm thanh ──
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: !!sink && !!sink.audio && sink.audio.muted
    readonly property bool micMuted: !!source && !!source.audio && source.audio.muted

    function setVolume(v) {
        if (sink && sink.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1, v));
        }
    }
    function toggleMute() { if (sink && sink.audio) sink.audio.muted = !sink.audio.muted; }
    function toggleMic() { if (source && source.audio) source.audio.muted = !source.audio.muted; }

    // ── chế độ chơi game (scripts/gamemode.sh) ──
    readonly property string gameScript: Quickshell.env("HOME") + "/.config/hypr/scripts/gamemode.sh"
    property bool gaming: false
    function toggleGaming() {
        gameSet.command = [gameScript, gaming ? "off" : "on"];
        gaming = !gaming;                 // hiện ngay, đọc lại trạng thái thật khi lệnh xong
        gameSet.running = true;
    }
    Process { id: gameSet; onExited: gameGet.running = true }
    Process {
        id: gameGet
        command: [root.gameScript, "status"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.gaming = text.trim() === "on" }
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    // ── Wi-Fi ──
    readonly property bool wifiOn: Networking.wifiEnabled
    readonly property string wifiName: {
        for (const d of Networking.devices.values) {
            if (d.type !== DeviceType.Wifi) continue;
            const n = d.networks.values.find(x => x.connected);
            if (n) return n.name;
        }
        return "";
    }
    function toggleWifi() { Networking.wifiEnabled = !Networking.wifiEnabled; }

    // ── Bluetooth ──
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btOn: !!adapter && adapter.enabled
    readonly property var btConnected: Bluetooth.devices.values.filter(d => d.connected)
    function toggleBt() { if (adapter) adapter.enabled = !adapter.enabled; }

    // ── tiết kiệm pin (cần power-profiles-daemon) ──
    readonly property bool powerSaver: PowerProfiles.profile === PowerProfile.PowerSaver
    function togglePowerSaver() {
        PowerProfiles.profile = powerSaver ? PowerProfile.Balanced : PowerProfile.PowerSaver;
    }

    // ── ánh sáng đêm (hyprsunset) ──
    property bool nightLight: false
    function toggleNightLight() { nightLight = !nightLight; }
    Process {
        running: root.nightLight
        command: ["hyprsunset", "-t", String(Config.nightLightTemp)]
    }

    // ── độ sáng màn hình (đọc /sys/class/backlight, chỉnh bằng brightnessctl) ──
    property string backlight: ""
    property int maxBrightness: 0
    property real brightness: -1        // 0..1, -1 nếu máy không có đèn nền (màn hình rời)
    readonly property bool hasBrightness: backlight !== "" && maxBrightness > 0

    function setBrightness(v) {
        const pct = Math.round(Math.max(0.01, Math.min(1, v)) * 100);
        Quickshell.execDetached(["brightnessctl", "-q", "-d", root.backlight, "set", pct + "%"]);
        brightness = pct / 100;
    }

    Process {
        running: true
        // Hỏi brightnessctl đang chỉnh đèn nền nào, để thanh trượt đọc đúng cái mà phím độ sáng chỉnh
        // (máy có hai thư mục đèn nền, ví dụ acpi_video0 và intel_backlight, không chọn nhầm).
        // Không có brightnessctl thì lấy thư mục đầu tiên.
        command: ["sh", "-c", "brightnessctl -m -c backlight info 2>/dev/null | head -n1 | cut -d, -f1 | grep . "
                  + "|| ls /sys/class/backlight 2>/dev/null | head -n1"]
        stdout: StdioCollector { onStreamFinished: root.backlight = text.trim() }
    }
    FileView {
        path: root.backlight ? "/sys/class/backlight/" + root.backlight + "/max_brightness" : ""
        onLoaded: root.maxBrightness = parseInt(text())
    }
    FileView {
        id: curBrightness
        path: root.backlight ? "/sys/class/backlight/" + root.backlight + "/brightness" : ""
        onLoaded: {
            if (root.maxBrightness <= 0) return;
            const b = parseInt(text()) / root.maxBrightness;
            if (root.brightness >= 0 && Math.abs(b - root.brightness) > 0.004) Osd.show("brightness", b, false);
            root.brightness = b;
        }
    }
    Timer {
        interval: 400
        repeat: true
        running: root.backlight !== ""
        onTriggered: curBrightness.reload()
    }
}
