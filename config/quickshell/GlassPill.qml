import QtQuick

// Một viên kính bo tròn: nền trong mờ (Hyprland làm mờ phía sau),
// viền mảnh và một vệt sáng ở mép trên.
Rectangle {
    id: pill

    // "light" = kính sáng, "dark" = kính tối, "strong" = kính tối đậm hơn
    property string tone: "light"

    radius: Math.min(height / 2, 30)
    color: tone === "dark" ? Theme.panel : tone === "strong" ? Theme.panelStrong : Theme.glass
    border.width: 1
    border.color: Theme.rim

    Behavior on width { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: 1
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.max(0, parent.width - parent.radius * 1.6)
        height: 1
        color: Theme.highlight
        opacity: 0.6
    }
}
