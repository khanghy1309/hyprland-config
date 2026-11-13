pragma Singleton

import QtQuick
import QtQml
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire

// Sự kiện ngắn hiện trên đảo động: đổi âm lượng/độ sáng, tai nghe vừa kết nối.
Singleton {
    id: root

    // âm lượng / độ sáng
    property string kind: ""        // "volume" | "brightness"
    property real value: 0
    property bool muted: false
    property bool active: false

    // thiết bị Bluetooth vừa kết nối
    property var device: null
    property bool deviceActive: false

    // bỏ qua các thay đổi lúc mới khởi động
    property bool ready: false
    Timer { interval: 2000; running: true; onTriggered: root.ready = true }

    function show(k, v, m) {
        if (!ready) return;
        kind = k;
        value = v;
        muted = !!m;
        active = true;
        hideTimer.restart();
    }
    Timer { id: hideTimer; interval: 1600; onTriggered: root.active = false }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
        function onVolumeChanged() { root.show("volume", Pipewire.defaultAudioSink.audio.volume, Pipewire.defaultAudioSink.audio.muted); }
        function onMutedChanged() { root.show("volume", Pipewire.defaultAudioSink.audio.volume, Pipewire.defaultAudioSink.audio.muted); }
    }

    Instantiator {
        model: Bluetooth.devices
        delegate: Connections {
            required property var modelData
            target: modelData
            function onConnectedChanged() {
                if (!modelData.connected || !root.ready) return;
                root.device = modelData;
                root.deviceActive = true;
                devTimer.restart();
            }
        }
    }
    Timer { id: devTimer; interval: 4000; onTriggered: root.deviceActive = false }
}
