import QtQuick
import QtQuick.Effects

// Màn hình đăng nhập Liquid Glass cho SDDM (Qt 6), bố cục như màn hình đăng nhập của macOS:
//   - giữa phía trên: ngày và giờ lớn
//   - giữa phía dưới: ảnh đại diện, tên, ô mật khẩu dạng viên kính (sai mật khẩu thì ô lắc như Mac)
//   - nhiều người dùng: ảnh đại diện xếp thành hàng, bấm để chọn
//   - dưới cùng: Ngủ, Khởi động lại, Tắt máy
//   - góc trên phải: phiên (Hyprland...) và bố cục bàn phím, bấm để đổi
// Thử mà không cần đăng xuất:
//   sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/liquid-glass
Rectangle {
    id: root

    width: 1920
    height: 1080
    color: "#0e2836"

    // ── màu và phông ──
    readonly property color fg: "#f3f6f6"
    readonly property color dim: "#d5dde0"
    readonly property color accent: "#f4f6f7"
    readonly property color ink: "#14181b"
    readonly property color danger: "#ffb4ab"
    readonly property string font: config.font ? config.font : "Geist"
    // cỡ chữ theo chiều cao màn hình (1080p là chuẩn), để màn hình 4K hay laptop nhỏ đều cân
    readonly property real k: Math.max(0.75, Math.min(2, height / 1080))

    // ── người dùng và phiên ──
    property var users: []
    property int userIndex: Math.max(0, userModel.lastIndex)
    readonly property var user: users.length > userIndex ? users[userIndex]
                                : ({ name: userModel.lastUser, realName: "", icon: "" })

    property var sessions: []
    property int sessionIndex: Math.max(0, sessionModel.lastIndex)

    property bool busy: false
    property string message: ""

    Repeater {
        model: userModel
        delegate: Item {
            required property int index
            required property string name
            required property string realName
            required property string icon
            Component.onCompleted: {
                const u = root.users.slice();
                u[index] = { name: name, realName: realName, icon: icon };
                root.users = u;
            }
        }
    }
    Repeater {
        model: sessionModel
        delegate: Item {
            required property int index
            required property string name
            Component.onCompleted: {
                const s = root.sessions.slice();
                s[index] = name;
                root.sessions = s;
            }
        }
    }

    function login() {
        if (busy || password.text.length === 0) return;
        busy = true;
        message = "";
        sddm.login(user.name, password.text, sessionIndex);
    }
    function pickUser(i) {
        if (i === userIndex || busy) return;
        userIndex = i;
        password.text = "";
        message = "";
        password.forceActiveFocus();
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false;
            password.text = "";
            root.message = "Sai mật khẩu";
            shake.restart();
            password.forceActiveFocus();
        }
        function onLoginSucceeded() { root.message = ""; }
    }

    // ── giờ ──
    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }
    readonly property string dateText: {
        const days = ["Chủ Nhật", "Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy"];
        return days[now.getDay()] + ", " + now.getDate() + " tháng " + (now.getMonth() + 1);
    }
    readonly property string timeText: {
        let h = now.getHours();
        if (config.clock === "12h") h = h % 12 || 12;
        const m = now.getMinutes();
        return h + ":" + (m < 10 ? "0" : "") + m;
    }

    // ── nền: ảnh rõ phủ lên trên, bản làm mờ ở dưới để các khối kính lấy ──
    MultiEffect {
        id: bgBlur
        anchors.fill: parent
        source: bg
        blurEnabled: true
        blur: 1.0
        blurMax: 48
        saturation: 0.15
    }
    Image {
        id: bg
        anchors.fill: parent
        source: config.background ? config.background : "background.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
    }
    // tối nhẹ ở trên và dưới để chữ trắng luôn đọc được, kể cả trên hình nền sáng
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.28) }
            GradientStop { position: 0.32; color: Qt.rgba(0, 0, 0, 0.0) }
            GradientStop { position: 0.62; color: Qt.rgba(0, 0, 0, 0.0) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.38) }
        }
    }

    // ── ngày và giờ lớn ──
    Item {
        id: clockBox
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height * 0.085
        width: Math.max(dateLabel.implicitWidth, timeLabel.implicitWidth)
        height: timeLabel.y + timeLabel.implicitHeight
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.35)
            shadowBlur: 0.6
            shadowVerticalOffset: 2
        }
        Text {
            id: dateLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.dateText
            font.family: root.font
            font.pixelSize: Math.round(24 * root.k)
            font.weight: Font.DemiBold
            color: root.fg
            opacity: 0.92
        }
        Text {
            id: timeLabel
            anchors.horizontalCenter: parent.horizontalCenter
            y: dateLabel.implicitHeight - Math.round(10 * root.k)
            text: root.timeText
            font.family: root.font
            font.pixelSize: Math.round(132 * root.k)
            font.weight: Font.Bold
            font.letterSpacing: -3 * root.k
            color: root.fg
            opacity: 0.94
        }
    }

    // ── góc trên phải: phiên và bàn phím ──
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 20
        y: 16
        spacing: 8

        Chooser {
            visible: root.sessions.length > 1
            text: root.sessions[root.sessionIndex] || ""
            onClicked: root.sessionIndex = (root.sessionIndex + 1) % root.sessions.length
        }
        Chooser {
            visible: keyboard.enabled && keyboard.layouts.length > 1
            readonly property var layout: keyboard.layouts.length > keyboard.currentLayout && keyboard.currentLayout >= 0
                                          ? keyboard.layouts[keyboard.currentLayout] : null
            text: layout ? (layout.shortName || layout.longName || "").toUpperCase() : ""
            onClicked: keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
        }
    }

    // ── người dùng và ô mật khẩu ──
    Column {
        id: who
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: powerRow.top
        anchors.bottomMargin: root.height * 0.085
        spacing: Math.round(14 * root.k)

        // ảnh đại diện; nhiều người dùng thì xếp hàng, người đang chọn to hơn
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.round(34 * root.k)
            Repeater {
                model: root.users.length > 0 ? root.users : [root.user]
                delegate: Column {
                    id: uc
                    required property var modelData
                    required property int index
                    readonly property bool chosen: index === root.userIndex || root.users.length === 0
                    // người chưa chọn nhỏ hơn: canh giữa theo chiều dọc với người đang chọn
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Math.round(10 * root.k)
                    opacity: chosen ? 1 : ucArea.containsMouse ? 0.9 : 0.65
                    Behavior on opacity { NumberAnimation { duration: 160 } }

                    Avatar {
                        anchors.horizontalCenter: parent.horizontalCenter
                        size: Math.round((uc.chosen ? 96 : 72) * root.k)
                        person: uc.modelData
                        Behavior on size { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        MouseArea {
                            id: ucArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: uc.chosen ? Qt.ArrowCursor : Qt.PointingHandCursor
                            onClicked: root.pickUser(uc.index)
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: uc.modelData.realName || uc.modelData.name || ""
                        font.family: root.font
                        font.pixelSize: Math.round((uc.chosen ? 18 : 15) * root.k)
                        font.weight: Font.DemiBold
                        color: root.fg
                        layer.enabled: true
                        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Qt.rgba(0, 0, 0, 0.4); shadowBlur: 0.5 }
                    }
                }
            }
        }

        // ô mật khẩu: viên kính nhỏ ở giữa, như macOS
        Item {
            id: fieldBox
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.round(250 * root.k)
            height: Math.round(38 * root.k)

            SequentialAnimation {
                id: shake
                // lắc ngang ba lần như ô mật khẩu của Mac khi gõ sai
                NumberAnimation { target: field; property: "x"; to: -16; duration: 45 }
                NumberAnimation { target: field; property: "x"; to: 14; duration: 80 }
                NumberAnimation { target: field; property: "x"; to: -10; duration: 70 }
                NumberAnimation { target: field; property: "x"; to: 6; duration: 60 }
                NumberAnimation { target: field; property: "x"; to: 0; duration: 50 }
            }

            GlassBox {
                id: field
                width: parent.width
                height: parent.height
                blurSource: bgBlur
                tint: Qt.rgba(1, 1, 1, password.activeFocus ? 0.22 : 0.16)
                rim: Qt.rgba(1, 1, 1, 0.34)

                TextInput {
                    id: password
                    x: Math.round(16 * root.k)
                    width: parent.width - x - (enterBtn.visible || capsIcon.visible ? parent.height + 6 : 16)
                    anchors.verticalCenter: parent.verticalCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    font.family: root.font
                    font.pixelSize: Math.round(15 * root.k)
                    font.letterSpacing: 1
                    color: root.fg
                    selectionColor: Qt.rgba(1, 1, 1, 0.32)
                    selectedTextColor: root.fg
                    clip: true
                    focus: true
                    enabled: !root.busy
                    Keys.onReturnPressed: root.login()
                    Keys.onEnterPressed: root.login()
                    Keys.onEscapePressed: text = ""
                    onTextChanged: if (text.length > 0) root.message = ""

                    Text {
                        visible: password.text.length === 0
                        text: "Nhập mật khẩu"
                        font.family: root.font
                        font.pixelSize: password.font.pixelSize
                        color: root.dim
                        opacity: 0.85
                    }
                }

                // Caps Lock đang bật: mũi tên lên ở cuối ô (như macOS)
                Icon {
                    id: capsIcon
                    visible: keyboard.capsLock && !enterBtn.visible
                    anchors.right: parent.right
                    anchors.rightMargin: Math.round(12 * root.k)
                    anchors.verticalCenter: parent.verticalCenter
                    path: "M12 4l7 8h-4v4H9v-4H5zM9 20h6"
                    size: Math.round(16 * root.k)
                    color: root.dim
                }

                // nút đăng nhập: chỉ hiện khi đã gõ
                Rectangle {
                    id: enterBtn
                    visible: password.text.length > 0 || root.busy
                    anchors.right: parent.right
                    anchors.rightMargin: 5
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.height - 10
                    height: width
                    radius: width / 2
                    // viên kính sáng có viền (cùng kiểu điểm nhấn với Quickshell)
                    color: root.busy ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.28)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.42)
                    Icon {
                        visible: !root.busy
                        anchors.centerIn: parent
                        path: "M5 12h14M13 6l6 6-6 6"
                        size: parent.width * 0.6
                        stroke: 2.4
                        color: root.fg
                    }
                    // đang kiểm tra mật khẩu: vòng xoay
                    Icon {
                        visible: root.busy
                        anchors.centerIn: parent
                        path: "M12 4a8 8 0 0 1 8 8"
                        size: parent.width * 0.7
                        stroke: 2.4
                        color: root.fg
                        RotationAnimation on rotation { running: root.busy; from: 0; to: 360; duration: 800; loops: Animation.Infinite }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.login()
                    }
                }
            }
        }

        // dòng nhắc dưới ô: lỗi, Caps Lock, hoặc cách đăng nhập
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.message !== "" ? root.message
                  : keyboard.capsLock ? "Caps Lock đang bật"
                  : root.busy ? "Đang đăng nhập…" : "Nhập mật khẩu rồi bấm Enter"
            font.family: root.font
            font.pixelSize: Math.round(13 * root.k)
            font.weight: Font.Medium
            color: root.message !== "" ? root.danger : root.dim
            opacity: root.message !== "" || keyboard.capsLock || root.busy ? 1 : 0.75
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Qt.rgba(0, 0, 0, 0.45); shadowBlur: 0.5 }
        }
    }

    // ── dưới cùng: Ngủ · Khởi động lại · Tắt máy ──
    Row {
        id: powerRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(36 * root.k)
        spacing: Math.round(40 * root.k)
        PowerButton {
            visible: sddm.canSuspend
            iconPath: "M20 14A8 8 0 1 1 10 4a6 6 0 0 0 10 10z"
            label: "Ngủ"
            onClicked: sddm.suspend()
        }
        PowerButton {
            visible: sddm.canReboot
            iconPath: "M20 12a8 8 0 1 1-2.3-5.6M20 4v5h-5"
            label: "Khởi động lại"
            onClicked: sddm.reboot()
        }
        PowerButton {
            visible: sddm.canPowerOff
            iconPath: "M12 3v9M6.4 6.4a8 8 0 1 0 11.2 0"
            label: "Tắt máy"
            onClicked: sddm.powerOff()
        }
    }

    Component.onCompleted: password.forceActiveFocus()

    // ── thành phần nhỏ ──

    // ảnh đại diện tròn; không có ảnh thì là viên kính với chữ cái đầu của tên
    component Avatar: Item {
        id: av
        property var person: ({})
        property real size: 96
        width: size
        height: size
        readonly property string src: person && person.icon && person.icon.indexOf("/faces/.face.icon") < 0 ? person.icon : ""
        GlassBox {
            anchors.fill: parent
            blurSource: bgBlur
            radius: width / 2
            tint: Qt.rgba(1, 1, 1, 0.16)
        }
        Text {
            anchors.centerIn: parent
            visible: pic.status !== Image.Ready
            text: ((av.person && (av.person.realName || av.person.name)) || "?").charAt(0).toUpperCase()
            font.family: root.font
            font.pixelSize: av.size * 0.4
            font.weight: Font.DemiBold
            color: root.fg
        }
        // SDDM đưa sẵn đường dẫn dạng file://; bỏ qua ảnh mặc định (hình người xám) để hiện chữ cái đầu
        Image {
            id: pic
            anchors.fill: parent
            anchors.margins: 2
            source: av.src
            visible: false
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(256, 256)
        }
        Rectangle {
            id: picMask
            anchors.fill: pic
            radius: width / 2
            visible: false
            layer.enabled: true
        }
        MultiEffect {
            anchors.fill: pic
            visible: pic.status === Image.Ready
            source: pic
            maskEnabled: true
            maskSource: picMask
        }
    }

    // viên kính nhỏ ở góc trên phải; bấm để đổi
    component Chooser: GlassBox {
        id: ch
        property string text: ""
        signal clicked()
        blurSource: bgBlur
        width: chText.implicitWidth + 28
        height: 32
        tint: Qt.rgba(1, 1, 1, chMouse.containsMouse ? 0.24 : 0.14)
        Text {
            id: chText
            anchors.centerIn: parent
            text: ch.text
            font.family: root.font
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: root.fg
        }
        MouseArea {
            id: chMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ch.clicked()
        }
    }

    // nút tròn kính, nhãn bên dưới (như màn hình đăng nhập của Mac)
    component PowerButton: Item {
        id: pb
        property string iconPath: ""
        property string label: ""
        signal clicked()
        width: Math.max(pbCol.implicitWidth, 60)
        height: pbCol.implicitHeight
        Accessible.name: label
        Column {
            id: pbCol
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            GlassBox {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.round(44 * root.k)
                height: width
                blurSource: bgBlur
                tint: Qt.rgba(1, 1, 1, pbMouse.containsMouse ? 0.26 : 0.14)
                Icon {
                    anchors.centerIn: parent
                    path: pb.iconPath
                    size: parent.width * 0.44
                    color: root.fg
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: pb.label
                font.family: root.font
                font.pixelSize: Math.round(12 * root.k)
                font.weight: Font.Medium
                color: root.fg
                opacity: pbMouse.containsMouse ? 1 : 0.8
                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Qt.rgba(0, 0, 0, 0.45); shadowBlur: 0.5 }
            }
        }
        MouseArea {
            id: pbMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pb.clicked()
        }
    }
}
