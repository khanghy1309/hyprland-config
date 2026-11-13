import QtQuick
import QtQuick.Effects

// Một khối kính: lấy đúng phần nền đã làm mờ nằm phía sau, bo góc,
// phủ một lớp màu tối trong suốt, viền mảnh và vệt sáng mép trên.
// (Màn hình đăng nhập không có compositor để làm mờ, nên tự làm mờ ở đây.)
Item {
    id: g

    property Item blurSource: null
    property real radius: height / 2
    property color tint: Qt.rgba(24 / 255, 26 / 255, 30 / 255, 0.40)
    property color rim: Qt.rgba(1, 1, 1, 0.28)

    property rect area: Qt.rect(0, 0, width, height)
    function updateArea() {
        if (!blurSource) return;
        const p = g.mapToItem(blurSource, 0, 0);
        area = Qt.rect(p.x, p.y, width, height);
    }
    onXChanged: updateArea()
    onYChanged: updateArea()
    onWidthChanged: updateArea()
    onHeightChanged: updateArea()
    Component.onCompleted: updateArea()
    // bố cục cha có thể xếp xong sau; đo lại một lần nữa
    Timer { interval: 120; running: true; onTriggered: g.updateArea() }

    ShaderEffectSource {
        id: crop
        anchors.fill: parent
        sourceItem: g.blurSource
        sourceRect: g.area
        visible: false
    }
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: g.radius
        visible: false
        layer.enabled: true
    }
    MultiEffect {
        anchors.fill: parent
        source: crop
        maskEnabled: true
        maskSource: mask
    }

    Rectangle {
        anchors.fill: parent
        radius: g.radius
        color: g.tint
        border.width: 1
        border.color: g.rim
    }
    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: 1
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.max(0, parent.width - g.radius * 1.6)
        height: 1
        color: Qt.rgba(1, 1, 1, 0.45)
        opacity: 0.6
    }
}
