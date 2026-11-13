import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire

// Thanh trên: ba viên kính nổi.
//   trái  – workspace + tên cửa sổ đang dùng
//   giữa  – chừa chỗ cho đảo động (Island.qml)
//   phải  – CPU, RAM, âm lượng, pin; bấm để mở trung tâm điều khiển
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barTop + Theme.barHeight
    exclusiveZone: implicitHeight
    color: "transparent"

    WlrLayershell.namespace: "glass-bar"
    WlrLayershell.layer: WlrLayer.Top

    readonly property var hmon: Hyprland.monitorFor(bar.screen)
    readonly property int activeId: hmon && hmon.activeWorkspace ? hmon.activeWorkspace.id : 1

    // Luôn hiện workspace 1–4, cộng thêm workspace khác đang tồn tại trên màn hình này
    readonly property var wsIds: {
        const ids = [1, 2, 3, 4];
        for (const w of Hyprland.workspaces.values) {
            if (w.id > 0 && (!w.monitor || w.monitor === bar.hmon) && ids.indexOf(w.id) < 0)
                ids.push(w.id);
        }
        return ids.sort((a, b) => a - b);
    }

    function occupied(id) {
        const w = Hyprland.workspaces.values.find(x => x.id === id);
        return !!w && w.toplevels.values.length > 0;
    }

    function goTo(id) {
        if (Hyprland.usingLua)
            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
        else
            Hyprland.dispatch(`workspace ${id}`);
    }

    // ───────────────── trái: workspace ─────────────────
    GlassPill {
        id: wsPill
        x: Theme.edge
        y: Theme.barTop
        height: Theme.barHeight
        width: wsRow.width + 16 + (titleText.text.length > 0 ? titleText.width + 22 : 0)

        Row {
            id: wsRow
            x: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Repeater {
                model: bar.wsIds

                delegate: Rectangle {
                    id: wsBtn
                    required property int modelData
                    readonly property bool isActive: modelData === bar.activeId

                    width: isActive ? 38 : 30
                    height: 28
                    radius: 14
                    color: isActive ? Theme.accent : wsMouse.containsMouse ? Theme.chip : "transparent"

                    Behavior on width { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: Theme.fast } }

                    Text {
                        anchors.centerIn: parent
                        text: wsBtn.modelData
                        font.family: Theme.mono
                        font.pixelSize: 13
                        font.weight: wsBtn.isActive ? Font.Bold : Font.Medium
                        color: wsBtn.isActive ? Theme.ink
                             : bar.occupied(wsBtn.modelData) ? Theme.fg : Theme.dim
                    }

                    MouseArea {
                        id: wsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bar.goTo(wsBtn.modelData)
                    }
                }
            }
        }

        Text {
            id: titleText
            anchors.left: wsRow.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 420)
            elide: Text.ElideRight
            text: Hyprland.activeToplevel && Hyprland.activeToplevel.workspace
                  && Hyprland.activeToplevel.workspace.id === bar.activeId
                  ? Hyprland.activeToplevel.title : ""
            font.family: Theme.font
            font.pixelSize: 14
            font.weight: Font.Medium
            color: Theme.fg
        }

        // cuộn chuột trên viên workspace để đổi workspace
        WheelHandler {
            onWheel: event => bar.goTo(Math.max(1, bar.activeId + (event.angleDelta.y < 0 ? 1 : -1)))
        }
    }

    // giữa: đảo động nằm trong Island.qml (một lớp riêng, có thể giãn ra)

    // ───────────────── phải: trạng thái ─────────────────
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var battery: UPower.displayDevice

    GlassPill {
        id: statusPill
        anchors.right: parent.right
        anchors.rightMargin: Theme.edge
        y: Theme.barTop
        height: Theme.barHeight
        width: statusRow.implicitWidth + 40

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: PanelState.toggle("control")
        }

        Row {
            id: statusRow
            anchors.centerIn: parent
            spacing: 18

            StatText { text: "CPU " + Math.round(SysStats.cpu * 100) + "%" }
            StatText { text: "RAM " + SysStats.memUsedGiB.toFixed(1).replace(".", ",") + "G" }

            StatText {
                readonly property var audio: bar.sink ? bar.sink.audio : null
                text: !audio ? "VOL –"
                      : audio.muted ? "VOL tắt"
                      : "VOL " + Math.round(audio.volume * 100) + "%"

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (parent.audio) parent.audio.muted = !parent.audio.muted
                    onWheel: wheel => {
                        if (!parent.audio) return;
                        const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                        parent.audio.volume = Math.max(0, Math.min(1, parent.audio.volume + step));
                    }
                }
            }

            StatText {
                visible: bar.battery && bar.battery.isLaptopBattery
                readonly property real pct: !bar.battery ? 0
                    : bar.battery.percentage > 1 ? bar.battery.percentage : bar.battery.percentage * 100
                readonly property bool charging: bar.battery && bar.battery.state === UPowerDeviceState.Charging
                text: "BAT " + Math.round(pct) + "%" + (charging ? " ↑" : "")
            }
        }
    }

    component StatText: Text {
        font.family: Theme.mono
        font.pixelSize: 12
        font.weight: Font.Medium
        font.letterSpacing: 0.5
        color: Theme.fg
    }
}
