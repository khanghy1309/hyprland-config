import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire

// Ứng dụng Cài đặt (Super + , hoặc tìm "Cài đặt" trong launcher).
// Là một cửa sổ thường: kéo, thu nhỏ, đóng bằng Super + Q hoặc Esc như mọi ứng dụng.
// Mọi thay đổi lưu ngay (xem Settings.qml), không cần bấm "Lưu".
// Mở từ ngoài:  qs ipc call settings open   |   qs ipc call settings page wifi
FloatingWindow {
    id: win

    visible: false
    title: "Cài đặt"
    implicitWidth: 1000
    implicitHeight: 680
    minimumSize: Qt.size(820, 560)
    color: "transparent"          // Hyprland làm mờ phía sau

    property string page: "look"

    readonly property var pages: [
        { id: "look",      label: "Giao diện",            path: "M12 3a9 9 0 1 0 0 18c1 0 1.5-.8 1.5-1.6 0-.9-.7-1.4-.7-2.2 0-.9.7-1.6 1.6-1.6H16a5 5 0 0 0 5-5c0-4.3-4-7.6-9-7.6zM7.5 12a1 1 0 1 0 0-2 1 1 0 0 0 0 2zM10.5 8a1 1 0 1 0 0-2 1 1 0 0 0 0 2zM15 8.5a1 1 0 1 0 0-2 1 1 0 0 0 0 2z" },
        { id: "dock",      label: "Dock",                 path: "M3 15h18v5H3zM6 17.5h.01M10 17.5h.01M14 17.5h.01M18 17.5h.01M8 4h8v8H8z" },
        { id: "wallpaper", label: "Hình nền",             path: "M3 5h18v14H3zM3 15l5-5 4 4 3-3 6 6M15.5 8.5h.01" },
        { id: "input",     label: "Touchpad và bàn phím", path: "M4 4h16v10H4zM12 14v6M8 20h8" },
        { id: "wifi",      label: "Wi-Fi",                path: Icons.wifi },
        { id: "bluetooth", label: "Bluetooth",            path: Icons.bluetooth },
        { id: "sound",     label: "Âm thanh",             path: Icons.volume },
        { id: "weather",   label: "Thời tiết",            path: Icons.cloud },
        { id: "about",     label: "Giới thiệu",           path: "M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18zM12 11v5M12 8h.01" }
    ]

    function open(p) {
        if (typeof p === "string" && pages.some(x => x.id === p)) page = p;
        visible = true;
    }

    IpcHandler {
        target: "settings"
        function open(): void { win.open(); }
        function toggle(): void { win.visible ? (win.visible = false) : win.open(); }
        function page(name: string): void { win.open(name); }
    }

    // nền kính của cả cửa sổ; Hyprland bo góc và vẽ viền
    Rectangle {
        anchors.fill: parent
        color: Theme.panelStrong
        focus: true
        Keys.onEscapePressed: win.visible = false
    }

    // ── cột trái: danh sách trang ──
    Rectangle {
        id: side
        width: 250
        height: parent.height
        color: Qt.rgba(1, 1, 1, 0.04)

        Column {
            x: 14
            y: 22
            width: parent.width - 28
            spacing: 4

            Text {
                x: 12
                text: "Cài đặt"
                font.family: Theme.font
                font.pixelSize: 24
                font.weight: Font.DemiBold
                color: Theme.fg
                bottomPadding: 14
            }

            Repeater {
                model: win.pages
                delegate: Rectangle {
                    id: item
                    required property var modelData
                    readonly property bool on: win.page === modelData.id
                    width: parent.width
                    height: 42
                    radius: 13
                    color: on ? Theme.accent : im.containsMouse ? Theme.chip : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                    Row {
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12
                        Icon { anchors.verticalCenter: parent.verticalCenter; path: item.modelData.path; size: 18; color: item.on ? Theme.ink : Theme.fg }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: item.modelData.label
                            font.family: Theme.font
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: item.on ? Theme.ink : Theme.fg
                        }
                    }
                    MouseArea {
                        id: im
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.page = item.modelData.id
                    }
                }
            }
        }

        Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.line }
    }

    // ── phần phải: nội dung trang, cuộn được ──
    Flickable {
        id: flick
        anchors.left: side.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        contentHeight: pageLoader.height + 60
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Loader {
            id: pageLoader
            x: 36
            y: 30
            width: flick.width - 72
            sourceComponent: ({ look: lookPage, dock: dockPage, wallpaper: wallPage, input: inputPage, wifi: wifiPage, bluetooth: btPage, sound: soundPage,
                                weather: weatherPage, about: aboutPage })[win.page]
            onLoaded: flick.contentY = 0
        }
    }

    // ═════════════════════════ các trang ═════════════════════════

    Component {
        id: lookPage
        Column {
            spacing: 26
            PageTitle { text: "Giao diện" }

            Group {
                title: "Kính"
                SegRow {
                    label: "Kiểu kính"
                    note: "Acrylic có mép cong khúc xạ như macOS. Máy yếu hoặc thấy giật thì chọn Mờ thường."
                    options: [["acrylic", "Acrylic"], ["blur", "Mờ thường"], ["off", "Tắt"]]
                    current: Settings.look.glass
                    onPicked: v => Settings.look.glass = v
                }
                SliderRow {
                    label: "Độ mờ phía sau"
                    enabled: Settings.look.glass !== "off"
                    from: 2; to: 20; step: 1
                    value: Settings.look.blurSize
                    onMoved: v => Settings.look.blurSize = v
                }
                SliderRow {
                    label: "Độ đậm của bảng kính"
                    note: "Thanh trên, đảo động, launcher, các bảng trượt"
                    from: 0.25; to: 0.75; step: 0.05
                    value: Settings.look.panelAlpha
                    format: v => Math.round(v * 100) + "%"
                    onMoved: v => Settings.look.panelAlpha = v
                    last: true
                }
            }

            Group {
                title: "Cửa sổ"
                SliderRow {
                    label: "Bo góc"
                    from: 0; to: 30; step: 1
                    value: Settings.look.rounding
                    format: v => v + " px"
                    onMoved: v => Settings.look.rounding = v
                }
                SliderRow {
                    label: "Khoảng cách giữa các cửa sổ"
                    from: 0; to: 24; step: 1
                    value: Settings.look.gapsIn
                    format: v => v + " px"
                    onMoved: v => Settings.look.gapsIn = v
                }
                SliderRow {
                    label: "Khoảng cách tới mép màn hình"
                    from: 0; to: 40; step: 1
                    value: Settings.look.gapsOut
                    format: v => v + " px"
                    onMoved: v => Settings.look.gapsOut = v
                }
                SwitchRow {
                    label: "Viền sáng mép kính"
                    on: Settings.look.borders
                    onToggled: Settings.look.borders = !Settings.look.borders
                }
                SwitchRow {
                    label: "Bóng đổ"
                    on: Settings.look.shadow
                    onToggled: Settings.look.shadow = !Settings.look.shadow
                    last: true
                }
            }

            Group {
                title: "Chuyển động"
                SwitchRow {
                    label: "Hiệu ứng chuyển động"
                    on: Settings.look.animations
                    onToggled: Settings.look.animations = !Settings.look.animations
                }
                SegRow {
                    label: "Tốc độ"
                    enabled: Settings.look.animations
                    options: [[0.7, "Nhanh"], [1, "Vừa"], [1.4, "Chậm"]]
                    current: Settings.look.animScale
                    onPicked: v => Settings.look.animScale = v
                    last: true
                }
            }

            Group {
                title: "Khác"
                SliderRow {
                    label: "Ánh sáng đêm"
                    note: "Càng thấp càng vàng. Bật/tắt trong trung tâm điều khiển."
                    from: 3000; to: 6000; step: 100
                    value: Settings.misc.nightLightTemp
                    format: v => v + " K"
                    onMoved: v => Settings.misc.nightLightTemp = v
                }
                SegRow {
                    label: "Thông báo hiện trên đảo"
                    options: [[3000, "3 giây"], [5000, "5 giây"], [8000, "8 giây"]]
                    current: Settings.misc.notifTimeout
                    onPicked: v => Settings.misc.notifTimeout = v
                    last: true
                }
            }
        }
    }

    Component {
        id: dockPage
        Column {
            spacing: 26
            PageTitle { text: "Dock" }

            Group {
                title: ""
                SwitchRow {
                    label: "Hiện dock"
                    on: Settings.dock.enabled
                    onToggled: Settings.dock.enabled = !Settings.dock.enabled
                }
                SwitchRow {
                    label: "Tự ẩn"
                    note: "Dock lùi xuống khi có cửa sổ che chỗ của nó. Đưa chuột sát mép dưới màn hình, hoặc bấm Super + D, để hiện lại. Tắt đi thì dock luôn hiện và cửa sổ chừa chỗ cho nó."
                    enabled: Settings.dock.enabled
                    on: Settings.dock.autoHide
                    onToggled: Settings.dock.autoHide = !Settings.dock.autoHide
                }
                SwitchRow {
                    label: "Phóng to biểu tượng khi rê chuột"
                    enabled: Settings.dock.enabled
                    on: Settings.dock.magnify
                    onToggled: Settings.dock.magnify = !Settings.dock.magnify
                }
                SliderRow {
                    label: "Kích thước biểu tượng"
                    enabled: Settings.dock.enabled
                    from: 32; to: 72; step: 2
                    value: Settings.dock.iconSize
                    format: v => v + " px"
                    onMoved: v => Settings.dock.iconSize = v
                    last: true
                }
            }

            Group {
                title: "Ứng dụng ghim"

                // danh sách đang ghim, theo thứ tự trên dock
                Repeater {
                    model: Settings.dock.pinned
                    delegate: Item {
                        id: pr
                        required property string modelData
                        required property int index
                        readonly property var entry: DesktopEntries.byId(modelData)
                        function move(d) {
                            const l = Settings.dock.pinned.slice();
                            const j = pr.index + d;
                            if (j < 0 || j >= l.length) return;
                            l.splice(j, 0, l.splice(pr.index, 1)[0]);
                            Settings.dock.pinned = l;
                        }
                        width: parent.width
                        height: 52
                        Image {
                            x: 18
                            anchors.verticalCenter: parent.verticalCenter
                            width: 28
                            height: 28
                            sourceSize: Qt.size(56, 56)
                            source: Quickshell.iconPath(pr.entry ? pr.entry.icon : "", "application-x-executable")
                        }
                        Text {
                            x: 58
                            anchors.verticalCenter: parent.verticalCenter
                            text: pr.entry ? pr.entry.name : pr.modelData + " (chưa cài)"
                            font.family: Theme.font
                            font.pixelSize: 14
                            color: pr.entry ? Theme.fg : Theme.dim
                        }
                        Row {
                            anchors.right: parent.right
                            anchors.rightMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            SmallButton { text: "↑"; visible: pr.index > 0; onClicked: pr.move(-1) }
                            SmallButton { text: "↓"; visible: pr.index < Settings.dock.pinned.length - 1; onClicked: pr.move(1) }
                            SmallButton {
                                text: "Bỏ ghim"
                                onClicked: Settings.dock.pinned = Settings.dock.pinned.filter(x => x !== pr.modelData)
                            }
                        }
                        Rectangle { x: 58; anchors.bottom: parent.bottom; width: parent.width - 58; height: 1; color: Theme.line }
                    }
                }

                // thêm: gõ tên ứng dụng, bấm vào kết quả để ghim
                Item {
                    id: addBox
                    width: parent.width
                    height: 60
                    property string q: ""
                    Rectangle {
                        x: 16; y: 10
                        width: parent.width - 32
                        height: 40
                        radius: 12
                        color: Theme.chip
                        TextInput {
                            id: addInput
                            x: 14
                            width: parent.width - 28
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.font
                            font.pixelSize: 14
                            color: Theme.fg
                            clip: true
                            onTextChanged: addBox.q = text.trim().toLowerCase()
                            Text { visible: addInput.text.length === 0; text: "Thêm ứng dụng: gõ tên, ví dụ code"; font: addInput.font; color: Theme.dim }
                        }
                    }
                }
                Repeater {
                    model: addBox.q.length < 1 ? [] : DesktopEntries.applications.values
                        .filter(e => !e.noDisplay && Settings.dock.pinned.indexOf(e.id) < 0
                                && (e.name.toLowerCase().includes(addBox.q) || (e.genericName || "").toLowerCase().includes(addBox.q)))
                        .slice(0, 5)
                    delegate: Item {
                        id: ar
                        required property var modelData
                        width: parent.width
                        height: 46
                        Rectangle { anchors.fill: parent; anchors.margins: 4; radius: 12; color: am.containsMouse ? Theme.chip : "transparent" }
                        Image {
                            x: 18
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24
                            height: 24
                            sourceSize: Qt.size(48, 48)
                            source: Quickshell.iconPath(ar.modelData.icon || "", "application-x-executable")
                        }
                        Text {
                            x: 58
                            anchors.verticalCenter: parent.verticalCenter
                            text: ar.modelData.name
                            font.family: Theme.font
                            font.pixelSize: 14
                            color: Theme.fg
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 18
                            anchors.verticalCenter: parent.verticalCenter
                            text: "+ Ghim"
                            font.family: Theme.font
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Theme.dim
                        }
                        MouseArea {
                            id: am
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { Settings.dock.pinned = Settings.dock.pinned.concat([ar.modelData.id]); addInput.text = ""; }
                        }
                    }
                }

                ButtonsRow {
                    buttons: [["Khôi phục mặc định", () => {
                        Settings.dock.pinned = ["org.gnome.Nautilus", "firefox", "kitty", "liquid-glass-settings"];
                    }]]
                    note: "Cũng ghim được bằng chuột phải vào biểu tượng trên dock, hoặc Ctrl + P trong launcher. Kéo biểu tượng trên dock để đổi chỗ."
                    last: true
                }
            }
        }
    }

    Component {
        id: wallPage
        Column {
            id: wp
            spacing: 26

            readonly property string wallDir: Settings.home + "/Pictures/Wallpapers"
            property var items: []        // [{ file, thumb, video }]

            function scan() { lister.running = false; lister.running = true; }
            Component.onCompleted: scan()

            Process {
                id: lister
                // mỗi dòng: tệp <TAB> ảnh thu nhỏ (video thì tạo ảnh thu nhỏ bằng ffmpeg)
                command: ["sh", "-c",
                    "find \"$1\" -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' "
                    + "-o -iname '*.webp' -o -iname '*.gif' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' "
                    + "-o -iname '*.mov' \\) | sort | while IFS= read -r f; do "
                    + "case \"$f\" in *.[mM][pP]4|*.[wW][eE][bB][mM]|*.[mM][kK][vV]|*.[mM][oO][vV]) "
                    + "t=$(\"$2\" thumb \"$f\" 480 2>/dev/null) ;; *) t=$f ;; esac; "
                    + "printf '%s\\t%s\\n' \"$f\" \"$t\"; done",
                    "_", wp.wallDir, Settings.wallScript]
                stdout: StdioCollector {
                    onStreamFinished: wp.items = text.split("\n").filter(l => l.length > 0).map(l => {
                        const c = l.split("\t");
                        return { file: c[0], thumb: c[1] || "", video: /\.(mp4|webm|mkv|mov)$/i.test(c[0]) };
                    })
                }
            }

            FileView {
                id: current
                path: (Quickshell.env("XDG_STATE_HOME") || Settings.home + "/.local/state") + "/liquid-glass/wallpaper"
                watchChanges: true
                onFileChanged: reload()
            }
            readonly property string currentFile: current.text().trim()

            function setWall(f) { Quickshell.execDetached([Settings.wallScript, f]); }

            PageTitle { text: "Hình nền" }

            Group {
                title: "Chọn hình nền"
                Item {
                    width: parent.width
                    height: grid.height + 32
                    Flow {
                        id: grid
                        x: 16
                        y: 16
                        width: parent.width - 32
                        spacing: 12
                        readonly property real cellW: (width - spacing * 2) / 3
                        Repeater {
                            model: wp.items
                            delegate: Item {
                                id: cell
                                required property var modelData
                                readonly property bool on: wp.currentFile === modelData.file
                                width: grid.cellW
                                height: grid.cellW * 9 / 16
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 12
                                    color: Theme.chip
                                    clip: true
                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 1
                                        source: cell.modelData.thumb ? "file://" + cell.modelData.thumb : ""
                                        sourceSize: Qt.size(480, 270)
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                    }
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 12
                                    color: "transparent"
                                    border.width: cell.on ? 3 : 1
                                    border.color: cell.on ? Theme.accent : Theme.line
                                }
                                Rectangle {
                                    visible: cell.modelData.video || /\.gif$/i.test(cell.modelData.file)
                                    x: 8; y: 8
                                    width: tag.implicitWidth + 12
                                    height: 20
                                    radius: 6
                                    color: Qt.rgba(0, 0, 0, 0.5)
                                    Text {
                                        id: tag
                                        anchors.centerIn: parent
                                        text: cell.modelData.video ? "VIDEO" : "GIF"
                                        font.family: Theme.mono
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        color: "white"
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: wp.setWall(cell.modelData.file)
                                }
                            }
                        }
                    }
                    Text {
                        visible: wp.items.length === 0
                        anchors.centerIn: parent
                        text: "Chưa có hình nền nào trong " + wp.wallDir
                        font.family: Theme.font
                        font.pixelSize: 13
                        color: Theme.dim
                    }
                }
                ButtonsRow {
                    buttons: [
                        ["Mở thư mục hình nền", () => Quickshell.execDetached(["sh", "-c", "mkdir -p \"$1\" && xdg-open \"$1\"", "_", wp.wallDir])],
                        ["Tải lại danh sách", () => wp.scan()],
                        ["Ngẫu nhiên", () => Quickshell.execDetached([Settings.wallScript, "random"])]
                    ]
                    note: "Thả ảnh (PNG, JPG, WebP), GIF hoặc video (MP4, WebM, MKV) vào thư mục rồi bấm Tải lại."
                    last: true
                }
            }

            Group {
                title: "Hình nền video"
                SegRow {
                    label: "Tạm dừng video khi"
                    note: "Video dừng lại để đỡ tốn pin và GPU, chạy tiếp khi màn hình trống trở lại."
                    options: [["full", "Có cửa sổ toàn màn hình"], ["active", "Có cửa sổ"], ["never", "Không"]]
                    current: Settings.wallpaper.pauseMode
                    onPicked: v => {
                        Settings.wallpaper.pauseMode = v;
                        // áp dụng ngay nếu đang dùng video
                        if (/\.(mp4|webm|mkv|mov)$/i.test(wp.currentFile)) reapply.restart();
                    }
                }
                SwitchRow {
                    label: "Dùng ảnh tĩnh khi chạy bằng pin"
                    note: "Rút sạc thì video được thay bằng một khung hình, cắm sạc lại thì chạy tiếp."
                    on: Settings.wallpaper.stillOnBattery
                    onToggled: Settings.wallpaper.stillOnBattery = !Settings.wallpaper.stillOnBattery
                    last: true
                }
            }

            Timer {
                id: reapply
                interval: 600      // chờ settings.json được ghi xong
                onTriggered: wp.setWall(wp.currentFile)
            }

            Group {
                title: "Hiệu ứng đổi ảnh"
                SegRow {
                    label: "Khi đổi hình nền"
                    options: [["fade", "Mờ dần"], ["grow", "Lan từ giữa"], ["wipe", "Quét ngang"], ["none", "Không"]]
                    current: Settings.wallpaper.transition
                    onPicked: v => Settings.wallpaper.transition = v
                    last: true
                }
            }
        }
    }

    Component {
        id: inputPage
        Column {
            spacing: 26
            PageTitle { text: "Touchpad và bàn phím" }

            Group {
                title: "Touchpad"
                SwitchRow {
                    label: "Cuộn tự nhiên"
                    note: "Vuốt lên thì trang đi lên, giống điện thoại và macOS"
                    on: Settings.input.naturalScroll
                    onToggled: Settings.input.naturalScroll = !Settings.input.naturalScroll
                }
                SwitchRow {
                    label: "Chạm để bấm"
                    on: Settings.input.tapToClick
                    onToggled: Settings.input.tapToClick = !Settings.input.tapToClick
                }
                SwitchRow {
                    label: "Tắt touchpad khi đang gõ phím"
                    on: Settings.input.disableWhileTyping
                    onToggled: Settings.input.disableWhileTyping = !Settings.input.disableWhileTyping
                }
                SliderRow {
                    label: "Tốc độ cuộn"
                    from: 0.2; to: 1.5; step: 0.1
                    value: Settings.input.scrollFactor
                    format: v => v.toFixed(1).replace(".", ",") + "×"
                    onMoved: v => Settings.input.scrollFactor = v
                }
                SliderRow {
                    label: "Tốc độ con trỏ"
                    note: "Áp dụng cho cả chuột và touchpad"
                    from: -1; to: 1; step: 0.1
                    value: Settings.input.sensitivity
                    format: v => v === 0 ? "mặc định" : (v > 0 ? "+" : "") + v.toFixed(1).replace(".", ",")
                    onMoved: v => Settings.input.sensitivity = v
                    last: true
                }
            }

            Group {
                title: "Cử chỉ"
                SwitchRow {
                    label: "3 ngón trái / phải: đổi workspace"
                    on: Settings.gestures.workspace
                    onToggled: Settings.gestures.workspace = !Settings.gestures.workspace
                }
                SwitchRow {
                    label: "3 ngón lên: toàn cảnh"
                    on: Settings.gestures.overview
                    onToggled: Settings.gestures.overview = !Settings.gestures.overview
                }
                SwitchRow {
                    label: "3 ngón xuống: terminal thả xuống"
                    on: Settings.gestures.dropdown
                    onToggled: Settings.gestures.dropdown = !Settings.gestures.dropdown
                }
                SwitchRow {
                    label: "4 ngón trái / phải: bảng widget và trung tâm điều khiển"
                    on: Settings.gestures.panels
                    onToggled: Settings.gestures.panels = !Settings.gestures.panels
                    last: true
                }
            }

            Group {
                title: "Bàn phím"
                SliderRow {
                    label: "Lặp phím: chờ trước khi lặp"
                    note: "Giữ một phím bao lâu thì bắt đầu gõ lặp"
                    from: 200; to: 1000; step: 50
                    value: Settings.input.repeatDelay
                    format: v => v + " ms"
                    onMoved: v => Settings.input.repeatDelay = v
                }
                SliderRow {
                    label: "Lặp phím: tốc độ"
                    from: 10; to: 60; step: 1
                    value: Settings.input.repeatRate
                    format: v => v + " ký tự/giây"
                    onMoved: v => Settings.input.repeatRate = v
                }
                Item {
                    width: parent.width
                    height: 64
                    Rectangle {
                        x: 16; y: 12
                        width: parent.width - 32
                        height: 40
                        radius: 12
                        color: Theme.chip
                        TextInput {
                            id: tryIt
                            x: 14
                            width: parent.width - 28
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.font
                            font.pixelSize: 14
                            color: Theme.fg
                            clip: true
                            Text {
                                visible: tryIt.text.length === 0
                                text: "Gõ thử ở đây"
                                font: tryIt.font
                                color: Theme.dim
                            }
                        }
                    }
                }
                ButtonsRow {
                    buttons: [["Mở cài đặt bộ gõ tiếng Việt", () => Quickshell.execDetached(["fcitx5-configtool"])]]
                    note: "Đổi Anh / Việt bằng Ctrl + Space"
                    last: true
                }
            }
        }
    }

    Component {
        id: wifiPage
        Column {
            id: wf
            spacing: 26

            property var networks: []      // [{ ssid, signal, secure, active, saved }]
            property var saved: []
            property bool scanning: false
            property string asking: ""     // SSID đang hỏi mật khẩu
            property string message: ""

            // nmcli -t dùng ":" ngăn cột và "\:" cho dấu hai chấm trong tên
            function fields(line) {
                const out = [];
                let cur = "";
                for (let i = 0; i < line.length; i++) {
                    const c = line[i];
                    if (c === "\\" && i + 1 < line.length) { cur += line[++i]; continue; }
                    if (c === ":") { out.push(cur); cur = ""; continue; }
                    cur += c;
                }
                out.push(cur);
                return out;
            }

            function refresh(rescan) {
                scanning = true;
                savedProc.running = false;
                savedProc.running = true;
                listProc.command = ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list",
                                    "--rescan", rescan ? "yes" : "auto"];
                listProc.running = false;
                listProc.running = true;
            }
            Component.onCompleted: refresh(false)
            Timer { interval: 15000; repeat: true; running: true; onTriggered: wf.refresh(false) }

            Process {
                id: savedProc
                command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
                stdout: StdioCollector {
                    onStreamFinished: wf.saved = text.split("\n").map(l => wf.fields(l))
                        .filter(f => f.length >= 2 && f[1] === "802-11-wireless").map(f => f[0])
                }
            }
            Process {
                id: listProc
                stdout: StdioCollector {
                    onStreamFinished: {
                        const best = {};
                        for (const l of text.split("\n")) {
                            const f = wf.fields(l);
                            if (f.length < 4 || !f[1]) continue;
                            const n = { ssid: f[1], signal: parseInt(f[2]) || 0, secure: f[3] !== "" && f[3] !== "--",
                                        active: f[0] === "*" };
                            const old = best[n.ssid];
                            if (!old || n.active || (!old.active && n.signal > old.signal)) best[n.ssid] = n;
                        }
                        wf.networks = Object.values(best).sort((a, b) => b.active - a.active || b.signal - a.signal);
                        wf.scanning = false;
                    }
                }
            }
            Process {
                id: actProc
                property string okText: ""
                stdout: StdioCollector { id: actOut }
                stderr: StdioCollector { id: actErr }
                onExited: code => {
                    wf.message = code === 0 ? okText
                        : (actErr.text.indexOf("Secrets were required") >= 0 || actErr.text.indexOf("802-1x") >= 0
                           ? "Sai mật khẩu hoặc mạng cần đăng nhập kiểu khác" : "Không kết nối được: " + actErr.text.trim().split("\n").pop());
                    wf.refresh(false);
                }
            }
            function run(cmd, okText) {
                wf.message = "Đang kết nối…";
                actProc.okText = okText;
                actProc.command = cmd;
                actProc.running = true;
            }
            function connect(n) {
                if (wf.saved.indexOf(n.ssid) >= 0) run(["nmcli", "connection", "up", "id", n.ssid], "Đã kết nối " + n.ssid);
                else if (!n.secure) run(["nmcli", "device", "wifi", "connect", n.ssid], "Đã kết nối " + n.ssid);
                else { wf.asking = n.ssid; wf.message = ""; }
            }

            PageTitle { text: "Wi-Fi" }

            Group {
                title: ""
                SwitchRow {
                    label: "Wi-Fi"
                    note: Controls.wifiOn ? (Controls.wifiName ? "Đang dùng " + Controls.wifiName : "Chưa kết nối") : "Đang tắt"
                    on: Controls.wifiOn
                    onToggled: Controls.toggleWifi()
                    last: true
                }
            }

            Group {
                visible: Controls.wifiOn
                title: wf.scanning ? "Mạng xung quanh · đang tìm…" : "Mạng xung quanh"

                Repeater {
                    model: wf.networks
                    delegate: Column {
                        id: net
                        required property var modelData
                        required property int index
                        width: parent.width

                        Item {
                            width: parent.width
                            height: 54
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 4
                                radius: 12
                                color: nm.containsMouse ? Theme.chip : "transparent"
                            }
                            // vạch sóng: 1–4
                            Row {
                                x: 18
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Repeater {
                                    model: 4
                                    delegate: Rectangle {
                                        required property int index
                                        anchors.bottom: parent.bottom
                                        width: 4
                                        height: 5 + index * 4
                                        radius: 1.5
                                        color: net.modelData.signal >= [5, 30, 55, 75][index] ? Theme.fg : Theme.line
                                    }
                                }
                            }
                            Column {
                                x: 52
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    text: net.modelData.ssid
                                    font.family: Theme.font
                                    font.pixelSize: 14
                                    font.weight: net.modelData.active ? Font.DemiBold : Font.Normal
                                    color: Theme.fg
                                }
                                Text {
                                    visible: text.length > 0
                                    text: net.modelData.active ? "Đã kết nối"
                                        : wf.saved.indexOf(net.modelData.ssid) >= 0 ? "Đã lưu" : ""
                                    font.family: Theme.font
                                    font.pixelSize: 12
                                    color: Theme.dim
                                }
                            }
                            Row {
                                anchors.right: parent.right
                                anchors.rightMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 10
                                Icon {
                                    visible: net.modelData.secure
                                    anchors.verticalCenter: parent.verticalCenter
                                    path: "M6 11h12v9H6zM9 11V8a3 3 0 0 1 6 0v3"
                                    size: 15
                                    color: Theme.dim
                                }
                                SmallButton {
                                    visible: wf.saved.indexOf(net.modelData.ssid) >= 0
                                    text: "Quên"
                                    onClicked: wf.run(["nmcli", "connection", "delete", "id", net.modelData.ssid],
                                                      "Đã quên " + net.modelData.ssid)
                                }
                                SmallButton {
                                    visible: net.modelData.active
                                    text: "Ngắt"
                                    onClicked: wf.run(["nmcli", "connection", "down", "id", net.modelData.ssid], "Đã ngắt kết nối")
                                }
                            }
                            MouseArea {
                                id: nm
                                anchors.fill: parent
                                anchors.rightMargin: 150
                                hoverEnabled: true
                                cursorShape: net.modelData.active ? Qt.ArrowCursor : Qt.PointingHandCursor
                                onClicked: if (!net.modelData.active) wf.connect(net.modelData)
                            }
                        }

                        // ô mật khẩu ngay dưới mạng vừa chọn
                        Item {
                            visible: wf.asking === net.modelData.ssid
                            width: parent.width
                            height: visible ? 60 : 0
                            Rectangle {
                                x: 52; y: 4
                                width: parent.width - 52 - 16 - 110
                                height: 40
                                radius: 12
                                color: Theme.chip
                                TextInput {
                                    id: pw
                                    x: 14
                                    width: parent.width - 28
                                    anchors.verticalCenter: parent.verticalCenter
                                    echoMode: TextInput.Password
                                    font.family: Theme.font
                                    font.pixelSize: 14
                                    color: Theme.fg
                                    clip: true
                                    onVisibleChanged: if (visible) { text = ""; forceActiveFocus(); }
                                    onAccepted: go.clicked()
                                    Text { visible: pw.text.length === 0; text: "Mật khẩu"; font: pw.font; color: Theme.dim }
                                }
                            }
                            SmallButton {
                                id: go
                                anchors.right: parent.right
                                anchors.rightMargin: 16
                                y: 8
                                text: "Kết nối"
                                strong: true
                                onClicked: {
                                    if (pw.text.length === 0) return;
                                    const s = net.modelData.ssid;
                                    wf.asking = "";
                                    wf.run(["nmcli", "device", "wifi", "connect", s, "password", pw.text], "Đã kết nối " + s);
                                }
                            }
                        }

                        Rectangle {
                            visible: net.index < wf.networks.length - 1
                            x: 52
                            width: parent.width - 52
                            height: 1
                            color: Theme.line
                        }
                    }
                }

                Text {
                    visible: wf.networks.length === 0 && !wf.scanning
                    x: 18
                    height: 50
                    verticalAlignment: Text.AlignVCenter
                    text: "Không thấy mạng nào"
                    font.family: Theme.font
                    font.pixelSize: 13
                    color: Theme.dim
                }

                ButtonsRow {
                    buttons: [["Tìm lại", () => wf.refresh(true)],
                              ["Cài đặt mạng nâng cao", () => Quickshell.execDetached(["nm-connection-editor"])]]
                    note: wf.message
                    last: true
                }
            }
        }
    }

    Component {
        id: btPage
        Column {
            id: bt
            spacing: 26
            readonly property var adapter: Bluetooth.defaultAdapter
            readonly property var devices: adapter ? adapter.devices.values : []
            readonly property var mine: devices.filter(d => d.paired).sort((a, b) => b.connected - a.connected || a.name.localeCompare(b.name))
            // thiết bị mới: chỉ hiện cái có tên (bỏ các địa chỉ trơn khó nhận ra)
            readonly property var found: devices.filter(d => !d.paired && d.deviceName && d.deviceName !== d.address.replace(/:/g, "-"))
            property string message: ""

            // vào trang thì tìm thiết bị, rời trang thì thôi tìm (tìm liên tục tốn pin)
            Component.onCompleted: if (adapter && adapter.enabled) adapter.discovering = true
            Component.onDestruction: if (adapter) adapter.discovering = false

            property var pending: null
            property int waited: 0
            function pairAndConnect(d) {
                bt.message = "Đang ghép với " + d.name + "… Nếu thiết bị hỏi mã, xác nhận trên thiết bị.";
                d.trusted = true;      // lần sau tự kết nối lại
                d.pair();
                pending = d;
                waited = 0;
            }
            // ghép xong thì kết nối luôn (đợi tối đa 30 giây)
            Timer {
                running: !!bt.pending
                repeat: true
                interval: 1000
                onTriggered: {
                    const d = bt.pending;
                    if (d.paired) {
                        d.connect();
                        bt.message = "Đã ghép " + d.name;
                        bt.pending = null;
                    } else if (++bt.waited > 30 || (!d.pairing && bt.waited > 3)) {
                        bt.message = "Không ghép được " + d.name + ". Thử lại, hoặc dùng Ghép bằng dòng lệnh.";
                        bt.pending = null;
                    }
                }
            }
            PageTitle { text: "Bluetooth" }

            Group {
                title: ""
                SwitchRow {
                    label: "Bluetooth"
                    note: !bt.adapter ? "Máy này không có Bluetooth, hoặc dịch vụ bluetooth chưa chạy"
                        : bt.adapter.enabled ? (bt.adapter.discovering ? "Đang tìm thiết bị xung quanh…" : "Bật") : "Tắt"
                    enabled: !!bt.adapter
                    on: !!bt.adapter && bt.adapter.enabled
                    onToggled: {
                        bt.adapter.enabled = !bt.adapter.enabled;
                        if (bt.adapter.enabled) discoverTimer.restart();
                    }
                    last: true
                }
            }
            Timer { id: discoverTimer; interval: 800; onTriggered: if (bt.adapter) bt.adapter.discovering = true }

            Group {
                visible: !!bt.adapter && bt.adapter.enabled
                title: "Thiết bị của bạn"
                Repeater {
                    model: bt.mine
                    delegate: DeviceRow {
                        required property var modelData
                        required property int index
                        dev: modelData
                        last: index === bt.mine.length - 1
                        status: modelData.state === BluetoothDeviceState.Connecting ? "Đang kết nối…"
                            : modelData.state === BluetoothDeviceState.Disconnecting ? "Đang ngắt…"
                            : modelData.connected ? "Đã kết nối" + (modelData.batteryAvailable ? " · pin " + Math.round(modelData.battery * 100) + "%" : "")
                            : "Chưa kết nối"
                        actions: modelData.connected
                            ? [["Ngắt", () => modelData.disconnect()], ["Quên", () => modelData.forget()]]
                            : [["Kết nối", () => modelData.connect()], ["Quên", () => modelData.forget()]]
                    }
                }
                Text {
                    visible: bt.mine.length === 0
                    x: 18
                    height: 50
                    verticalAlignment: Text.AlignVCenter
                    text: "Chưa ghép thiết bị nào"
                    font.family: Theme.font
                    font.pixelSize: 13
                    color: Theme.dim
                }
            }

            Group {
                visible: !!bt.adapter && bt.adapter.enabled
                title: bt.adapter && bt.adapter.discovering ? "Thiết bị xung quanh · đang tìm…" : "Thiết bị xung quanh"
                Repeater {
                    model: bt.found
                    delegate: DeviceRow {
                        required property var modelData
                        dev: modelData
                        status: modelData.pairing ? "Đang ghép…" : ""
                        actions: modelData.pairing ? [["Huỷ", () => modelData.cancelPair()]]
                                                   : [["Ghép", () => bt.pairAndConnect(modelData)]]
                    }
                }
                ButtonsRow {
                    buttons: [[bt.adapter && bt.adapter.discovering ? "Dừng tìm" : "Tìm lại",
                               () => { bt.adapter.discovering = !bt.adapter.discovering; }],
                              ["Ghép bằng dòng lệnh", () => Quickshell.execDetached(["kitty", "-e", "bluetoothctl"])]]
                    note: bt.message || "Để tai nghe, chuột, bàn phím ở chế độ ghép đôi (thường là giữ nút nguồn vài giây). Bàn phím cần gõ mã thì dùng nút Ghép bằng dòng lệnh."
                    last: true
                }
            }
        }
    }

    Component {
        id: soundPage
        Column {
            id: snd
            spacing: 26

            readonly property var nodes: Pipewire.nodes.values.filter(n => n.audio && !n.isStream)
            readonly property var outputs: nodes.filter(n => n.isSink)
            readonly property var inputs: nodes.filter(n => !n.isSink)
            readonly property var sink: Pipewire.defaultAudioSink
            readonly property var source: Pipewire.defaultAudioSource
            // ứng dụng đang phát ra loa/tai nghe hiện tại
            PwNodeLinkTracker { id: links; node: snd.sink }
            readonly property var apps: links.linkGroups.map(g => g.source).filter(n => n && n.audio && n.isStream)

            // phải "theo dõi" các node thì mới đọc / đổi được âm lượng
            PwObjectTracker { objects: snd.outputs.concat(snd.inputs, snd.apps) }

            function label(n) {
                return n.description || n.nickname || n.name;
            }

            PageTitle { text: "Âm thanh" }

            Group {
                title: "Đầu ra"
                Repeater {
                    model: snd.outputs
                    delegate: PickRow {
                        required property var modelData
                        label: snd.label(modelData)
                        on: snd.sink === modelData
                        onPicked: Pipewire.preferredDefaultAudioSink = modelData
                    }
                }
                SliderRow {
                    label: "Âm lượng"
                    enabled: !!snd.sink && !!snd.sink.audio
                    from: 0; to: 1; step: 0.01
                    value: snd.sink && snd.sink.audio ? Math.min(1, snd.sink.audio.volume) : 0
                    format: v => Math.round(v * 100) + "%"
                    onMoved: v => { snd.sink.audio.volume = v; snd.sink.audio.muted = false; }
                }
                SwitchRow {
                    label: "Tắt tiếng"
                    enabled: !!snd.sink && !!snd.sink.audio
                    on: !!snd.sink && !!snd.sink.audio && snd.sink.audio.muted
                    onToggled: snd.sink.audio.muted = !snd.sink.audio.muted
                    last: true
                }
            }

            Group {
                title: "Đầu vào (micro)"
                Repeater {
                    model: snd.inputs
                    delegate: PickRow {
                        required property var modelData
                        label: snd.label(modelData)
                        on: snd.source === modelData
                        onPicked: Pipewire.preferredDefaultAudioSource = modelData
                    }
                }
                Text {
                    visible: snd.inputs.length === 0
                    x: 18
                    height: 50
                    verticalAlignment: Text.AlignVCenter
                    text: "Không có micro nào"
                    font.family: Theme.font
                    font.pixelSize: 13
                    color: Theme.dim
                }
                SliderRow {
                    label: "Độ nhạy micro"
                    enabled: !!snd.source && !!snd.source.audio
                    from: 0; to: 1; step: 0.01
                    value: snd.source && snd.source.audio ? Math.min(1, snd.source.audio.volume) : 0
                    format: v => Math.round(v * 100) + "%"
                    onMoved: v => snd.source.audio.volume = v
                }
                SwitchRow {
                    label: "Tắt micro"
                    enabled: !!snd.source && !!snd.source.audio
                    on: !!snd.source && !!snd.source.audio && snd.source.audio.muted
                    onToggled: snd.source.audio.muted = !snd.source.audio.muted
                    last: true
                }
            }

            Group {
                title: "Âm lượng từng ứng dụng"
                Repeater {
                    model: snd.apps
                    delegate: SliderRow {
                        required property var modelData
                        readonly property var p: modelData.properties || {}
                        label: p["application.name"] || snd.label(modelData)
                        note: p["media.name"] || ""
                        from: 0; to: 1; step: 0.01
                        value: modelData.audio ? Math.min(1, modelData.audio.volume) : 0
                        format: v => Math.round(v * 100) + "%"
                        onMoved: v => modelData.audio.volume = v
                    }
                }
                Text {
                    visible: snd.apps.length === 0
                    x: 18
                    height: 50
                    verticalAlignment: Text.AlignVCenter
                    text: "Chưa có ứng dụng nào đang phát âm thanh"
                    font.family: Theme.font
                    font.pixelSize: 13
                    color: Theme.dim
                }
                ButtonsRow {
                    buttons: [["Cài đặt âm thanh nâng cao", () => Quickshell.execDetached(["pavucontrol"])]]
                    note: "Chọn cấu hình loa, HDMI, tai nghe Bluetooth chất lượng cao…"
                    last: true
                }
            }
        }
    }

    Component {
        id: weatherPage
        Column {
            id: wp2
            spacing: 26
            property var results: []
            property string status: ""

            function search(q) {
                if (q.trim().length < 2) return;
                status = "Đang tìm…";
                const xhr = new XMLHttpRequest();
                xhr.onreadystatechange = () => {
                    if (xhr.readyState !== XMLHttpRequest.DONE) return;
                    try {
                        const r = JSON.parse(xhr.responseText).results || [];
                        wp2.results = r;
                        wp2.status = r.length ? "" : "Không tìm thấy nơi nào tên như vậy";
                    } catch (e) {
                        wp2.results = [];
                        wp2.status = "Không tìm được (kiểm tra mạng)";
                    }
                };
                xhr.open("GET", "https://geocoding-api.open-meteo.com/v1/search?count=6&language=vi&format=json&name="
                         + encodeURIComponent(q.trim()));
                xhr.send();
            }

            PageTitle { text: "Thời tiết" }

            Group {
                title: "Vị trí"
                Item {
                    width: parent.width
                    height: 58
                    Text {
                        x: 18
                        anchors.verticalCenter: parent.verticalCenter
                        text: Settings.weather.city ? Settings.weather.city : "Chưa đặt vị trí"
                        font.family: Theme.font
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        color: Theme.fg
                    }
                    Text {
                        visible: !!Settings.weather.city && isFinite(Weather.temp)
                        anchors.right: parent.right
                        anchors.rightMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(Weather.temp) + "°  " + Weather.desc
                        font.family: Theme.font
                        font.pixelSize: 14
                        color: Theme.dim
                    }
                }
                Item {
                    width: parent.width
                    height: 60
                    Rectangle {
                        x: 16; y: 6
                        width: parent.width - 32 - 96
                        height: 42
                        radius: 12
                        color: Theme.chip
                        TextInput {
                            id: q
                            x: 14
                            width: parent.width - 28
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.font
                            font.pixelSize: 14
                            color: Theme.fg
                            clip: true
                            onAccepted: wp2.search(text)
                            Text { visible: q.text.length === 0; text: "Tên thành phố, ví dụ Đà Lạt"; font: q.font; color: Theme.dim }
                        }
                    }
                    SmallButton {
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        y: 9
                        text: "Tìm"
                        strong: true
                        onClicked: wp2.search(q.text)
                    }
                }
                Repeater {
                    model: wp2.results
                    delegate: Item {
                        id: place
                        required property var modelData
                        width: parent.width
                        height: 48
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: 12
                            color: pm.containsMouse ? Theme.chip : "transparent"
                        }
                        Text {
                            x: 18
                            anchors.verticalCenter: parent.verticalCenter
                            text: place.modelData.name + " · " + [place.modelData.admin1, place.modelData.country].filter(x => !!x).join(", ")
                            font.family: Theme.font
                            font.pixelSize: 14
                            color: Theme.fg
                        }
                        MouseArea {
                            id: pm
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Settings.weather.lat = place.modelData.latitude;
                                Settings.weather.lon = place.modelData.longitude;
                                Settings.weather.city = place.modelData.name;
                                wp2.results = [];
                                q.text = "";
                            }
                        }
                    }
                }
                ButtonsRow {
                    buttons: Settings.weather.city ? [["Bỏ vị trí", () => { Settings.weather.city = ""; }]] : []
                    note: wp2.status || "Dữ liệu từ open-meteo.com, cập nhật mỗi 30 phút. Chỉ tên thành phố được gửi đi khi tìm."
                    last: true
                }
            }
        }
    }

    Component {
        id: aboutPage
        Column {
            id: ab
            spacing: 26
            property var info: []

            Process {
                running: true
                command: ["sh", "-c",
                    "printf '%s\\n' \"$(uname -n)\" \"$(uname -r)\" "
                    + "\"$(hyprctl version -j 2>/dev/null | jq -r '.tag // .version // empty')\" "
                    + "\"$(qs --version 2>/dev/null | head -n1)\" "
                    + "\"$(. /etc/os-release 2>/dev/null; echo \"$PRETTY_NAME\")\""]
                stdout: StdioCollector { onStreamFinished: ab.info = text.split("\n") }
            }

            PageTitle { text: "Giới thiệu" }

            Group {
                title: "Máy này"
                InfoRow { label: "Tên máy"; value: ab.info[0] || "" }
                InfoRow { label: "Hệ điều hành"; value: ab.info[4] || "" }
                InfoRow { label: "Kernel"; value: ab.info[1] || "" }
                InfoRow { label: "Hyprland"; value: ab.info[2] || "" }
                InfoRow { label: "Quickshell"; value: ab.info[3] || ""; last: true }
            }

            Group {
                title: "Liquid Glass"
                InfoRow { label: "Lựa chọn của bạn"; value: "~/.config/liquid-glass/settings.json" }
                InfoRow { label: "Chỉnh riêng Hyprland"; value: "~/.config/hypr/user.lua" }
                ButtonsRow {
                    buttons: [["Mở thư mục cấu hình", () => Quickshell.execDetached(["xdg-open", Settings.home + "/.config/hypr"])],
                              ["Bảng phím tắt", () => { win.visible = false; Quickshell.execDetached(["qs", "ipc", "call", "cheatsheet", "open"]); }]]
                    last: true
                }
            }
        }
    }

    // ═════════════════════════ thành phần ═════════════════════════

    component PageTitle: Text {
        font.family: Theme.font
        font.pixelSize: 28
        font.weight: Font.DemiBold
        color: Theme.fg
    }

    // một nhóm: tiêu đề nhỏ + thẻ kính chứa các dòng
    component Group: Column {
        id: g
        property string title
        default property alias rows: card.children
        width: parent ? parent.width : 0
        spacing: 8
        Text {
            visible: g.title.length > 0
            x: 4
            text: g.title
            font.family: Theme.font
            font.pixelSize: 12
            font.weight: Font.Bold
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 0.8
            color: Theme.dim
        }
        Rectangle {
            width: parent.width
            height: card.implicitHeight
            radius: 18
            color: Qt.rgba(1, 1, 1, 0.06)
            border.width: 1
            border.color: Theme.line
            Column { id: card; width: parent.width }
        }
    }

    // nền chung của một dòng: nhãn, chú thích, đường kẻ dưới
    component RowBase: Item {
        id: rb
        property string label
        property string note: ""
        property bool last: false
        // phần bên phải dành cho nút/thanh trượt; dòng nào có nút rộng thì tăng lên
        property real reserve: width * 0.45
        readonly property real textRight: width - reserve
        width: parent ? parent.width : 0
        height: Math.max(56, labelCol.implicitHeight + 28)
        opacity: enabled ? 1 : 0.4
        Column {
            id: labelCol
            x: 18
            width: rb.textRight - 18
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: rb.label
                font.family: Theme.font
                font.pixelSize: 14
                color: Theme.fg
            }
            Text {
                visible: rb.note.length > 0
                width: parent.width
                wrapMode: Text.WordWrap
                text: rb.note
                font.family: Theme.font
                font.pixelSize: 12
                color: Theme.dim
            }
        }
        Rectangle {
            visible: !rb.last
            x: 18
            anchors.bottom: parent.bottom
            width: parent.width - 18
            height: 1
            color: Theme.line
        }
    }

    component SwitchRow: RowBase {
        id: sr
        property bool on: false
        signal toggled()
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            width: 46
            height: 28
            radius: 14
            color: sr.on ? Theme.accent : Theme.chip
            border.width: 1
            border.color: Theme.line
            Behavior on color { ColorAnimation { duration: Theme.fast } }
            Rectangle {
                x: sr.on ? parent.width - width - 3 : 3
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22
                radius: 11
                color: sr.on ? Theme.ink : Theme.fg
                Behavior on x { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
            }
        }
        MouseArea {
            anchors.fill: parent
            enabled: sr.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: sr.toggled()
        }
    }

    component SliderRow: RowBase {
        id: sl
        property real from: 0
        property real to: 1
        property real step: 1
        property real value: 0
        property var format: v => String(v)
        signal moved(real value)
        GlassSlider {
            id: gs
            anchors.right: valText.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: sl.width - sl.textRight - 12 - valText.width - 18
            height: 22
            enabled: sl.enabled
            value: (sl.value - sl.from) / (sl.to - sl.from)
            onMoved: v => {
                const raw = sl.from + v * (sl.to - sl.from);
                const snapped = Math.round(raw / sl.step) * sl.step;
                const val = Math.round(Math.min(sl.to, Math.max(sl.from, snapped)) * 1000) / 1000;
                if (val !== sl.value) sl.moved(val);
            }
        }
        Text {
            id: valText
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            width: 86
            horizontalAlignment: Text.AlignRight
            text: sl.format(sl.value)
            font.family: Theme.font
            font.pixelSize: 13
            font.weight: Font.Medium
            color: Theme.dim
        }
    }

    component SegRow: RowBase {
        id: sg
        property var options: []      // [[giá trị, nhãn], …]
        property var current
        signal picked(var value)
        reserve: Math.max(width * 0.3, segBox.width + 40)
        Rectangle {
            id: segBox
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            width: segRow.implicitWidth + 6
            height: 34
            radius: 11
            color: Theme.chip
            Row {
                id: segRow
                x: 3
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: sg.options
                    delegate: Rectangle {
                        id: seg
                        required property var modelData
                        readonly property bool on: sg.current === modelData[0]
                        width: st.implicitWidth + 22
                        height: 28
                        radius: 9
                        color: on ? Theme.accent : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.fast } }
                        Text {
                            id: st
                            anchors.centerIn: parent
                            text: seg.modelData[1]
                            font.family: Theme.font
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: seg.on ? Theme.ink : Theme.fg
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: sg.enabled
                            cursorShape: Qt.PointingHandCursor
                            onClicked: sg.picked(seg.modelData[0])
                        }
                    }
                }
            }
        }
    }

    // một thiết bị Bluetooth: biểu tượng, tên, trạng thái, các nút
    component DeviceRow: RowBase {
        id: dr
        property var dev
        property string status: ""
        property var actions: []
        label: dev ? dev.name : ""
        note: status
        reserve: btnRow.width + 40
        Row {
            id: btnRow
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Repeater {
                model: dr.actions
                delegate: SmallButton {
                    required property var modelData
                    text: modelData[0]
                    onClicked: modelData[1]()
                }
            }
        }
    }

    // một lựa chọn trong danh sách (thiết bị âm thanh): dấu chọn bên phải
    component PickRow: RowBase {
        id: pk
        property bool on: false
        signal picked()
        Icon {
            visible: pk.on
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            path: "M5 12l5 5L20 7"
            size: 18
            stroke: 2.4
            color: Theme.fg
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: pk.picked()
        }
    }

    component InfoRow: RowBase {
        id: ir
        property string value
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            width: ir.width - ir.textRight - 18
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideMiddle
            text: ir.value
            font.family: Theme.mono
            font.pixelSize: 12
            color: Theme.dim
        }
    }

    // hàng nút bấm, kèm một dòng chú thích bên trái
    component ButtonsRow: RowBase {
        id: br
        property var buttons: []       // [[nhãn, hàm], …]
        label: ""
        Text {
            x: 18
            anchors.verticalCenter: parent.verticalCenter
            width: br.width - btns.width - 54
            wrapMode: Text.WordWrap
            text: br.note
            font.family: Theme.font
            font.pixelSize: 12
            color: Theme.dim
        }
        Row {
            id: btns
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Repeater {
                model: br.buttons
                delegate: SmallButton {
                    required property var modelData
                    text: modelData[0]
                    onClicked: modelData[1]()
                }
            }
        }
        // ButtonsRow tự vẽ chú thích ở trên; ẩn cột nhãn của RowBase
        Component.onCompleted: children[0].visible = false
    }

    component SmallButton: Rectangle {
        id: sb
        property string text
        property bool strong: false
        signal clicked()
        width: sbt.implicitWidth + 26
        height: 34
        radius: 11
        color: strong ? Theme.accent : sbm.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : Theme.chip
        border.width: strong ? 0 : 1
        border.color: Theme.line
        Text {
            id: sbt
            anchors.centerIn: parent
            text: sb.text
            font.family: Theme.font
            font.pixelSize: 13
            font.weight: Font.Medium
            color: sb.strong ? Theme.ink : Theme.fg
        }
        MouseArea {
            id: sbm
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: sb.clicked()
        }
    }
}
