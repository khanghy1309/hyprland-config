import QtQuick
import QtQuick.Effects

// Màn hình đăng nhập Liquid Glass cho SDDM (Qt 6).
// Thử mà không cần đăng xuất:
//   sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/liquid-glass
Rectangle {
    id: root

    width: 1920
    height: 1080
    color: "#0e2836"

    // ── màu và phông ──
    readonly property color fg: "#f3f6f6"
    readonly property color dim: "#c5d0d2"
    readonly property color accent: "#f4f6f7"
    readonly property color ink: "#14181b"
    readonly property color danger: "#f28b82"
    readonly property string font: config.font ? config.font : "Inter"

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
        if (busy) return;
        busy = true;
        message = "";
        sddm.login(user.name, password.text, sessionIndex);
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false;
            password.text = "";
            root.message = "Sai mật khẩu, thử lại";
            shake.restart();
            password.forceActiveFocus();
        }
        function onLoginSucceeded() { root.message = ""; }
    }

    // ── giờ ──
    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }
    readonly property string greeting: {
        const h = now.getHours();
        return h < 11 ? "Chào buổi sáng" : h < 13 ? "Chào buổi trưa" : h < 18 ? "Chào buổi chiều" : "Chào buổi tối";
    }
    readonly property string clockText: {
        const days = ["CN", "Th 2", "Th 3", "Th 4", "Th 5", "Th 6", "Th 7"];
        const pad = n => (n < 10 ? "0" : "") + n;
        let h = now.getHours();
        let suffix = "";
        if (config.clock === "12h") { suffix = h < 12 ? " SA" : " CH"; h = h % 12 || 12; }
        return days[now.getDay()] + ", " + pad(now.getDate()) + "/" + pad(now.getMonth() + 1)
               + "  ·  " + pad(h) + ":" + pad(now.getMinutes()) + suffix;
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

    // ── góc trên phải: giờ ──
    GlassBox {
        blurSource: bgBlur
        anchors.right: parent.right
        anchors.rightMargin: 24
        y: 18
        width: clockLabel.implicitWidth + 40
        height: 42
        tint: Qt.rgba(1, 1, 1, 0.14)
        Text {
            id: clockLabel
            anchors.centerIn: parent
            text: root.clockText
            font.family: root.font
            font.pixelSize: 14
            font.weight: Font.DemiBold
            color: root.fg
        }
    }

    // ── biểu mẫu đăng nhập ──
    Column {
        id: form
        x: Math.max(48, parent.width * 0.078)
        y: parent.height * 0.185
        width: 460
        spacing: 18

        SequentialAnimation {
            id: shake
            NumberAnimation { target: form; property: "x"; to: form.x - 14; duration: 50 }
            NumberAnimation { target: form; property: "x"; to: form.x + 14; duration: 80 }
            NumberAnimation { target: form; property: "x"; to: form.x - 8; duration: 70 }
            NumberAnimation { target: form; property: "x"; to: Math.max(48, root.width * 0.078); duration: 60 }
        }

        // ảnh đại diện
        Item {
            width: 92
            height: 92
            GlassBox {
                anchors.fill: parent
                blurSource: bgBlur
                radius: 46
            }
            Text {
                anchors.centerIn: parent
                visible: avatar.status !== Image.Ready
                text: (root.user.realName || root.user.name || "?").charAt(0).toUpperCase()
                font.family: root.font
                font.pixelSize: 34
                font.weight: Font.DemiBold
                color: root.fg
            }
            Image {
                id: avatar
                anchors.fill: parent
                anchors.margins: 2
                // SDDM đưa sẵn đường dẫn dạng file://; bỏ qua ảnh mặc định (hình người xám) để hiện chữ cái đầu
                source: root.user.icon && root.user.icon.indexOf("/faces/.face.icon") < 0 ? root.user.icon : ""
                visible: false
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(184, 184)
            }
            Rectangle {
                id: avatarMask
                anchors.fill: avatar
                radius: width / 2
                visible: false
                layer.enabled: true
            }
            MultiEffect {
                anchors.fill: avatar
                visible: avatar.status === Image.Ready
                source: avatar
                maskEnabled: true
                maskSource: avatarMask
            }
        }

        Text {
            width: parent.width
            wrapMode: Text.Wrap
            text: root.greeting + ",\n" + (root.user.realName || root.user.name || "")
            font.family: root.font
            font.pixelSize: 54
            font.weight: Font.DemiBold
            font.letterSpacing: -1
            lineHeight: 1.1
            color: root.fg
        }

        // ô mật khẩu
        GlassBox {
            width: parent.width
            height: 56
            blurSource: bgBlur
            tint: Qt.rgba(24 / 255, 26 / 255, 30 / 255, 0.45)

            TextInput {
                id: password
                x: 22
                width: parent.width - 22 - 60
                anchors.verticalCenter: parent.verticalCenter
                echoMode: TextInput.Password
                passwordCharacter: "•"
                font.family: root.font
                font.pixelSize: 17
                color: root.fg
                selectionColor: root.accent
                selectedTextColor: root.ink
                clip: true
                focus: true
                enabled: !root.busy
                Keys.onReturnPressed: root.login()
                Keys.onEnterPressed: root.login()
                onTextChanged: if (text.length > 0) root.message = ""

                Text {
                    visible: password.text.length === 0
                    text: "Mật khẩu"
                    font: password.font
                    color: root.dim
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                height: 44
                radius: 22
                color: root.accent
                opacity: root.busy ? 0.5 : 1
                Icon {
                    anchors.centerIn: parent
                    path: "M5 12h14M13 6l6 6-6 6"
                    size: 18
                    stroke: 2.4
                    color: root.ink
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.login()
                }
            }
        }

        // thông báo lỗi / caps lock
        Text {
            visible: text !== ""
            leftPadding: 6
            text: root.message !== "" ? root.message
                  : keyboard.capsLock ? "Caps Lock đang bật" : ""
            font.family: root.font
            font.pixelSize: 14
            font.weight: Font.Medium
            color: root.message !== "" ? root.danger : root.dim
        }

        // người dùng, phiên, bàn phím
        Flow {
            width: parent.width
            spacing: 10

            Chooser {
                visible: root.users.length > 1
                label: "Người dùng"
                value: root.user.realName || root.user.name
                onClicked: { root.userIndex = (root.userIndex + 1) % root.users.length; password.text = ""; }
            }
            Chooser {
                visible: root.sessions.length > 0
                label: "Phiên"
                value: root.sessions[root.sessionIndex] || ""
                onClicked: root.sessionIndex = (root.sessionIndex + 1) % root.sessions.length
            }
            Chooser {
                visible: keyboard.enabled && keyboard.layouts.length > 1
                label: "Bàn phím"
                value: keyboard.layouts.length > keyboard.currentLayout && keyboard.currentLayout >= 0
                       ? keyboard.layouts[keyboard.currentLayout].longName : ""
                onClicked: keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
            }
        }
    }

    // ── góc dưới trái: tên máy ──
    Text {
        x: 36
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 34
        text: sddm.hostName
        font.family: "JetBrains Mono"
        font.pixelSize: 13
        color: root.fg
    }

    // ── góc dưới phải: nguồn ──
    GlassBox {
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        width: powerRow.implicitWidth + 18
        height: 62
        blurSource: bgBlur
        tint: Qt.rgba(1, 1, 1, 0.14)

        Row {
            id: powerRow
            anchors.centerIn: parent
            spacing: 8
            PowerButton {
                visible: sddm.canSuspend
                iconPath: "M20 14A8 8 0 1 1 10 4a6 6 0 0 0 10 10z"
                tip: "Ngủ"
                onClicked: sddm.suspend()
            }
            PowerButton {
                visible: sddm.canReboot
                iconPath: "M20 12a8 8 0 1 1-2.3-5.6M20 4v5h-5"
                tip: "Khởi động lại"
                onClicked: sddm.reboot()
            }
            PowerButton {
                visible: sddm.canPowerOff
                iconPath: "M12 3v9M6.4 6.4a8 8 0 1 0 11.2 0"
                tip: "Tắt máy"
                onClicked: sddm.powerOff()
            }
        }
    }

    Component.onCompleted: password.forceActiveFocus()

    // ── thành phần nhỏ ──
    component Chooser: GlassBox {
        id: ch
        property string label: ""
        property string value: ""
        signal clicked()
        blurSource: bgBlur
        width: chRow.implicitWidth + 32
        height: 46
        tint: Qt.rgba(24 / 255, 26 / 255, 30 / 255, chMouse.containsMouse ? 0.52 : 0.40)
        Row {
            id: chRow
            anchors.centerIn: parent
            spacing: 8
            Text {
                text: ch.label
                font.family: root.font
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: root.dim
            }
            Text {
                text: ch.value
                font.family: root.font
                font.pixelSize: 14
                font.weight: Font.Medium
                color: root.fg
            }
        }
        MouseArea {
            id: chMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ch.clicked()
        }
    }

    component PowerButton: Rectangle {
        id: pb
        property string iconPath: ""
        property string tip: ""
        signal clicked()
        width: 44
        height: 44
        radius: 22
        color: pbMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.24) : Qt.rgba(1, 1, 1, 0.12)
        Accessible.name: tip
        Icon {
            anchors.centerIn: parent
            path: pb.iconPath
            size: 19
            color: root.fg
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
