import QtQuick

// Thẻ menu kính lỏng dùng chung: menu hệ thống ở góc trái thanh trên, menu cửa sổ trong Toàn cảnh.
// Mỗi mục là một object:
//   { label, icon?, run?, sub?, checked?, enabled?, danger? }   hoặc   { sep: true }
//   sub: danh sách mục con, hoặc hàm trả về danh sách (để tính lúc mở, ví dụ danh sách workspace)
// Mục có menu con thì bấm để đi vào; hàng trên cùng để quay ra. Bấm một mục thường thì gọi run()
// rồi báo done() để nơi chứa đóng menu lại.
GlassPill {
    id: card

    property var entries: []
    property string title: ""
    signal done()

    property var stack: []      // [{ title, entries }] của các menu con đang mở
    readonly property var current: stack.length ? stack[stack.length - 1].entries : entries
    readonly property string heading: stack.length ? stack[stack.length - 1].title : title

    function reset() { stack = []; }
    function back() { stack = stack.slice(0, -1); }
    function activate(e) {
        if (!e || e.sep || e.enabled === false) return;
        if (e.sub) {
            const list = typeof e.sub === "function" ? e.sub() : e.sub;
            stack = stack.concat([{ title: e.label, entries: list }]);
            return;
        }
        done();
        if (e.run) e.run();
    }

    tone: "strong"
    // đậm hơn kính thường một chút: menu hay mở trên vùng sáng, chữ vẫn phải rõ
    color: Qt.rgba(0.09, 0.10, 0.12, 0.70)
    radius: 16
    width: 256
    smoothWidth: false
    height: list.implicitHeight + 12

    // Esc: ra khỏi menu con, hoặc đóng menu
    Keys.onEscapePressed: stack.length ? back() : done()
    Keys.onLeftPressed: if (stack.length) back()

    Column {
        id: list
        x: 6
        y: 6
        width: card.width - 12

        // tên menu, hoặc nút quay ra khi đang ở menu con
        Item {
            visible: card.heading !== ""
            width: list.width
            height: visible ? 30 : 0
            Rectangle {
                anchors.fill: parent
                radius: 10
                color: card.stack.length && headArea.containsMouse ? Theme.chip : "transparent"
            }
            Icon {
                visible: card.stack.length > 0
                x: 8
                anchors.verticalCenter: parent.verticalCenter
                path: Icons.chevronLeft
                size: 14
                color: Theme.dim
            }
            Text {
                x: card.stack.length ? 26 : 10
                width: parent.width - x - 10
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: card.heading
                font.family: Theme.font
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Theme.dim
            }
            MouseArea {
                id: headArea
                anchors.fill: parent
                enabled: card.stack.length > 0
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: card.back()
            }
        }

        Repeater {
            model: card.current
            delegate: Item {
                id: row
                required property var modelData
                readonly property bool sep: modelData.sep === true
                readonly property bool usable: !sep && modelData.enabled !== false
                readonly property bool hot: usable && rowArea.containsMouse
                width: list.width
                height: sep ? 11 : 34

                Rectangle {
                    visible: row.sep
                    anchors.centerIn: parent
                    width: parent.width - 20
                    height: 1
                    color: Theme.line
                }
                Rectangle {
                    visible: !row.sep
                    anchors.fill: parent
                    radius: 11
                    color: row.hot ? (row.modelData.danger ? "#ff8a80" : Theme.accent) : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.fast } }

                    Icon {
                        visible: !!row.modelData.icon || row.modelData.checked === true
                        x: 11
                        anchors.verticalCenter: parent.verticalCenter
                        path: row.modelData.checked === true ? Icons.check : (row.modelData.icon || "")
                        size: 16
                        color: row.hot ? Theme.ink : Theme.fg
                        opacity: row.usable ? 1 : 0.45
                    }
                    Text {
                        x: 38
                        width: parent.width - x - (row.modelData.sub ? 30 : 12)
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        text: row.modelData.label || ""
                        font.family: Theme.font
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: row.hot ? Theme.ink : Theme.fg
                        opacity: row.usable ? 1 : 0.45
                    }
                    Icon {
                        visible: !!row.modelData.sub
                        anchors.right: parent.right
                        anchors.rightMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        path: Icons.chevronRight
                        size: 14
                        color: row.hot ? Theme.ink : Theme.dim
                    }
                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        enabled: row.usable
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.activate(row.modelData)
                    }
                }
            }
        }
    }
}
