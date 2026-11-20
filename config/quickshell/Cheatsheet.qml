import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Bảng phím tắt (Super + /). Gõ để lọc, Esc để đóng.
// Danh sách này viết tay cho khớp ~/.config/hypr/lg_keybinds.lua và lg_input.lua;
// đổi phím ở đó thì sửa cả ở đây.
// Mở từ ngoài:  qs ipc call cheatsheet toggle
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

    WlrLayershell.namespace: "glass-cheatsheet"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property var groups: [
        { title: "Ứng dụng", items: [
            [["Super", "Enter"], "Terminal"],
            [["Super", "Space"], "Trình chạy nhanh"],
            [["Super", "E"], "Trình quản lý tệp"],
            [["Super", "B"], "Trình duyệt"],
            [["Super", "`"], "Terminal thả xuống"],
            [["Super", "Shift", "V"], "Lịch sử bộ nhớ tạm"]
        ] },
        { title: "Cửa sổ", items: [
            [["Super", "Q"], "Đóng"],
            [["Alt", "F4"], "Đóng (như Windows)"],
            [["Super", "H"], "Thu nhỏ xuống dock"],
            [["Alt", "Tab"], "Chuyển cửa sổ"],
            [["Super", "V"], "Nổi / xếp ô"],
            [["Super", "F"], "Toàn màn hình"],
            [["Super", "P"], "Ghim nổi trên mọi workspace"],
            [["Super", "J"], "Đổi chiều chia đôi"],
            [["Super", "← → ↑ ↓"], "Chuyển sang cửa sổ bên cạnh"],
            [["Super", "kéo chuột trái"], "Di chuyển"],
            [["Super", "kéo chuột phải"], "Đổi kích thước"]
        ] },
        { title: "Đặt cửa sổ", items: [
            [["kéo chạm mép trái / phải"], "Nửa màn hình"],
            [["kéo chạm mép trên"], "Lấp đầy màn hình"],
            [["kéo vào góc"], "Một phần tư màn hình"],
            [["Super", "Alt", "← → ↑ ↓"], "Nửa trái / phải / trên / dưới"],
            [["Super", "Alt", "U I J K"], "Bốn góc"],
            [["Super", "Alt", "D F G"], "Một phần ba: trái / giữa / phải"],
            [["Super", "Alt", "E T"], "Hai phần ba: trái / phải"],
            [["Super", "Alt", "Enter"], "Lấp đầy"],
            [["Super", "Alt", "C"], "Ra giữa"],
            [["Super", "Alt", "Backspace"], "Trả về như cũ"],
            [["chuột vào góc màn hình"], "Góc nóng"]
        ] },
        { title: "Workspace", items: [
            [["Super", "Tab"], "Toàn cảnh"],
            [["Super", "1 … 9"], "Sang workspace"],
            [["Super", "Shift", "1 … 9"], "Chuyển cửa sổ đi"],
            [["Super", "Ctrl", "← →"], "Workspace trước / sau"],
            [["Super", "cuộn chuột"], "Workspace trước / sau"]
        ] },
        { title: "Bảng", items: [
            [["Super", "W"], "Bảng widget"],
            [["Super", "N"], "Trung tâm điều khiển"],
            [["Super", "/"], "Bảng phím tắt này"],
            [["Super", ","], "Cài đặt"],
            [["Super", "D"], "Hiện / ẩn dock"],
            [["Super", "L"], "Khóa màn hình"],
            [["Super", "Esc"], "Menu nguồn"]
        ] },
        { title: "Chụp và quay", items: [
            [["Print"], "Chụp cả màn hình"],
            [["Super", "Shift", "S"], "Bảng chụp và quay"],
            [["Super", "Shift", "T"], "Đọc chữ trong vùng chọn"],
            [["Super", "Shift", "R"], "Dừng quay"],
            [["Super", "Shift", "C"], "Lấy màu trên màn hình"]
        ] },
        { title: "Touchpad", items: [
            [["3 ngón", "← →"], "Đổi workspace"],
            [["3 ngón", "↑"], "Toàn cảnh"],
            [["3 ngón", "↓"], "Terminal thả xuống"],
            [["4 ngón", "→"], "Bảng widget"],
            [["4 ngón", "←"], "Trung tâm điều khiển"],
            [["3 ngón", "chụm / mở"], "Kính lúp"]
        ] },
        { title: "Khác", items: [
            [["Super", "Shift", "W"], "Hình nền ngẫu nhiên"],
            [["Ctrl", "Shift", "Esc"], "Trình quản lý tác vụ"],
            [["Super", "Shift", "Esc"], "Thoát Hyprland ngay"]
        ] }
    ]

    property string filter: ""

    // nhóm sau khi lọc: chỉ giữ dòng có chữ khớp (bỏ dấu để gõ "dong" vẫn ra "Đóng")
    function plain(s) {
        return s.toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/đ/g, "d");
    }
    readonly property var shown: {
        const q = plain(filter.trim());
        if (!q) return groups;
        return groups.map(g => ({ title: g.title,
                                   items: g.items.filter(it => plain(it[1] + " " + it[0].join(" ") + " " + g.title).includes(q)) }))
                     .filter(g => g.items.length > 0);
    }

    function open() { filter = ""; input.text = ""; visible = true; input.forceActiveFocus(); }
    function close() { visible = false; }
    function toggle() { visible ? close() : open(); }

    IpcHandler {
        target: "cheatsheet"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function close(): void { root.close(); }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        opacity: root.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.normal } }
        MouseArea { anchors.fill: parent; onClicked: root.close() }
    }

    GlassPill {
        id: card
        tone: "strong"
        radius: 34
        width: Math.min(parent.width - 80, 1180)
        height: Math.min(parent.height - 120, head.height + cols.implicitHeight + 64)
        anchors.centerIn: parent
        clip: true

        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.97
        Behavior on opacity { NumberAnimation { duration: Theme.fast } }
        Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }

        Item {
            id: head
            x: 32
            y: 26
            width: parent.width - 64
            height: 44

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Phím tắt"
                font.family: Theme.font
                font.pixelSize: 26
                font.weight: Font.DemiBold
                color: Theme.fg
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 300
                height: 40
                radius: 14
                color: Theme.chip

                TextInput {
                    id: input
                    x: 16
                    width: parent.width - 32
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.font
                    font.pixelSize: 15
                    color: Theme.fg
                    clip: true
                    onTextChanged: root.filter = text
                    Keys.onEscapePressed: root.close()

                    Text {
                        visible: input.text.length === 0
                        text: "Gõ để lọc, ví dụ: chụp"
                        font: input.font
                        color: Theme.dim
                    }
                }
            }
        }

        // ba cột, nhóm được chia đều theo số dòng
        Row {
            id: cols
            x: 32
            y: head.y + head.height + 22
            width: parent.width - 64
            spacing: 36

            readonly property real colWidth: (width - spacing * 2) / 3
            readonly property var split: {
                const out = [[], [], []], load = [0, 0, 0];
                for (const g of root.shown) {
                    const i = load.indexOf(Math.min(...load));
                    out[i].push(g);
                    load[i] += g.items.length + 2;
                }
                return out;
            }

            Repeater {
                model: 3
                delegate: Column {
                    required property int index
                    width: cols.colWidth
                    spacing: 22

                    Repeater {
                        model: cols.split[index]
                        delegate: Column {
                            required property var modelData
                            width: cols.colWidth
                            spacing: 6

                            Text {
                                text: modelData.title
                                font.family: Theme.font
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                font.capitalization: Font.AllUppercase
                                font.letterSpacing: 0.8
                                color: Theme.dim
                                bottomPadding: 2
                            }

                            Repeater {
                                model: modelData.items
                                delegate: Item {
                                    required property var modelData
                                    width: cols.colWidth
                                    height: 30

                                    Text {
                                        anchors.left: parent.left
                                        anchors.right: keysRow.left
                                        anchors.rightMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        elide: Text.ElideRight
                                        text: modelData[1]
                                        font.family: Theme.font
                                        font.pixelSize: 14
                                        color: Theme.fg
                                    }
                                    Row {
                                        id: keysRow
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4
                                        Repeater {
                                            model: modelData[0]
                                            delegate: Rectangle {
                                                required property var modelData
                                                width: kt.implicitWidth + 14
                                                height: 24
                                                radius: 7
                                                color: Theme.chip
                                                border.width: 1
                                                border.color: Theme.line
                                                Text {
                                                    id: kt
                                                    anchors.centerIn: parent
                                                    text: modelData
                                                    font.family: Theme.font
                                                    font.pixelSize: 12
                                                    font.weight: Font.DemiBold
                                                    color: Theme.fg
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Text {
            visible: root.shown.length === 0
            anchors.horizontalCenter: parent.horizontalCenter
            y: cols.y + 40
            text: "Không có phím tắt nào khớp"
            font.family: Theme.font
            font.pixelSize: 15
            color: Theme.dim
        }
    }
}
