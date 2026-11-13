import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

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
        { id: "display",   label: "Màn hình",             path: "M3 4h18v12H3zM8 20h8M12 16v4" },
        { id: "dock",      label: "Dock",                 path: "M3 15h18v5H3zM6 17.5h.01M10 17.5h.01M14 17.5h.01M18 17.5h.01M8 4h8v8H8z" },
        { id: "wallpaper", label: "Hình nền",             path: "M3 5h18v14H3zM3 15l5-5 4 4 3-3 6 6M15.5 8.5h.01" },
        { id: "input",     label: "Touchpad và bàn phím", path: "M4 4h16v10H4zM12 14v6M8 20h8" },
        { id: "wifi",      label: "Wi-Fi",                path: Icons.wifi },
        { id: "bluetooth", label: "Bluetooth",            path: Icons.bluetooth },
        { id: "sound",     label: "Âm thanh",             path: Icons.volume },
        { id: "power",     label: "Nguồn điện",           path: "M13 3L5 14h6l-1 7 8-11h-6l1-7z" },
        { id: "datetime",  label: "Ngày giờ",             path: "M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18zM12 7v5l3 2" },
        { id: "apps",      label: "Ứng dụng mặc định",    path: "M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM13 13h7v7h-7z" },
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

        // danh sách trang cuộn được khi cửa sổ thấp
        Flickable {
            anchors.fill: parent
            contentHeight: sideCol.implicitHeight + 44
            clip: true
            boundsBehavior: Flickable.StopAtBounds
        Column {
            id: sideCol
            x: 14
            y: 22
            width: parent.width - 28
            spacing: 2

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
                    height: 38
                    radius: 12
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
            sourceComponent: ({ look: lookPage, display: displayPage, dock: dockPage, wallpaper: wallPage, input: inputPage, wifi: wifiPage, bluetooth: btPage, sound: soundPage, power: powerPage, datetime: dtPage, apps: appsPage,
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
                    label: "Kính của cửa sổ"
                    note: "Acrylic có mép cong khúc xạ như macOS. Máy yếu hoặc thấy giật thì chọn Mờ thường."
                    options: [["acrylic", "Acrylic"], ["blur", "Mờ thường"], ["off", "Tắt"]]
                    current: Settings.look.glass
                    onPicked: v => Settings.look.glass = v
                }
                SegRow {
                    label: "Kính của thanh trên, dock, bảng"
                    note: "Kính lỏng: hình nền bị bẻ cong ở mép như kính thật (khi phía sau không có cửa sổ). Viền sáng: chỉ vệt sáng ở mép, nhẹ máy hơn."
                    options: [["liquid", "Kính lỏng"], ["rim", "Viền sáng"], ["flat", "Phẳng"]]
                    current: Settings.look.material
                    onPicked: v => Settings.look.material = v
                }
                SwitchRow {
                    label: "Khúc xạ cả hình nền video"
                    note: "Kính dùng một khung hình tĩnh của video, nên chỗ mép có thể lệch với video đang chạy"
                    enabled: Settings.look.material === "liquid"
                    on: Settings.look.refractVideo
                    onToggled: Settings.look.refractVideo = !Settings.look.refractVideo
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
                title: "Phông chữ"
                Repeater {
                    // [tên phông, mô tả]; tất cả đều đủ dấu tiếng Việt và đi kèm bộ cài
                    model: [["Geist", "Gọn, hiện đại, gần với phông của macOS"],
                            ["Inter", "Rõ ở cỡ nhỏ, rất phổ biến"],
                            ["Be Vietnam Pro", "Thiết kế riêng cho tiếng Việt, dấu đặt đẹp"],
                            ["Onest", "Tròn, mềm, thân thiện"]]
                    delegate: PickRow {
                        required property var modelData
                        label: "Thứ Sáu, 13 tháng 11 · " + modelData[0]
                        labelFont: modelData[0]
                        note: modelData[1]
                        on: Settings.look.font === modelData[0]
                        onPicked: Settings.look.font = modelData[0]
                    }
                }
                SegRow {
                    label: "Phông chữ số và mã"
                    note: "Dùng cho số liệu trên thanh trên, đồng hồ đếm giờ… Terminal kitty đặt riêng trong kitty.conf."
                    options: [["Geist Mono", "Geist Mono"], ["JetBrains Mono", "JetBrains Mono"]]
                    current: Settings.look.monoFont
                    onPicked: v => Settings.look.monoFont = v
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
        id: displayPage
        Column {
            id: dp
            spacing: 26

            // thông tin thật từ Hyprland: hyprctl monitors all -j
            property var mons: []
            property bool loaded: false
            // bản nháp đang chỉnh: { tên: { mode, scale, position, disabled } }
            property var draft: ({})
            // để hoàn tác nếu người dùng không bấm "Giữ"
            property var previous: null
            property int countdown: 0
            property string openModes: ""      // màn hình đang mở danh sách độ phân giải

            function read() { monProc.running = false; monProc.running = true; }
            Component.onCompleted: read()
            Process {
                id: monProc
                command: ["hyprctl", "monitors", "all", "-j"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        try { dp.mons = JSON.parse(text); } catch (e) { dp.mons = []; }
                        dp.loaded = true;
                        if (Object.keys(dp.draft).length === 0) dp.resetDraft();
                    }
                }
            }

            function current(m) {
                const saved = (Settings.display.monitors || {})[m.name];
                if (saved) return Object.assign({}, saved);
                return { mode: m.width + "x" + m.height + "@" + Math.round(m.refreshRate),
                         scale: m.scale, position: "auto", disabled: !!m.disabled };
            }
            function resetDraft() {
                const d = {};
                for (const m of mons) d[m.name] = current(m);
                draft = d;
            }
            function setDraft(name, key, val) {
                const d = Object.assign({}, draft);
                d[name] = Object.assign({}, d[name]);
                d[name][key] = val;
                draft = d;
            }
            readonly property bool dirty: JSON.stringify(draft) !== JSON.stringify((() => {
                const d = {}; for (const m of mons) d[m.name] = current(m); return d;
            })())

            // "1920x1080@60.00Hz" → { res: "1920x1080", hz: 60 }
            function modesOf(m) {
                return (m.availableModes || []).map(s => {
                    const mm = s.match(/^(\d+)x(\d+)@([\d.]+)/);
                    return mm ? { w: +mm[1], h: +mm[2], hz: Math.round(+mm[3]) } : null;
                }).filter(x => x);
            }
            function resolutions(m) {
                const seen = {}, out = [];
                for (const x of modesOf(m)) {
                    const k = x.w + "x" + x.h;
                    if (!seen[k]) { seen[k] = true; out.push(x); }
                }
                return out.sort((a, b) => b.w * b.h - a.w * a.h);
            }
            function ratesFor(m, res) {
                const out = [];
                for (const x of modesOf(m)) if (x.w + "x" + x.h === res && out.indexOf(x.hz) < 0) out.push(x.hz);
                return out.sort((a, b) => b - a);
            }
            function resOf(mode) { return (mode || "").split("@")[0]; }
            function hzOf(mode) { return Math.round(+((mode || "").split("@")[1] || 60)); }

            // vị trí màn hình phụ so với màn hình đầu tiên
            function placeOf(name) {
                const p = (draft[name] || {}).position || "auto";
                if (p === "auto") return "right";
                const first = dp.mons[0], fd = draft[first.name] || {};
                const [x, y] = p.split("x").map(Number);
                return x < 0 ? "left" : y < 0 ? "above" : y > 0 && x === 0 ? "below" : "right";
            }
            function logicalSize(name) {
                const d = draft[name] || {}, m = dp.mons.find(x => x.name === name);
                const r = resOf(d.mode).split("x").map(Number);
                const sc = +(d.scale || 1);
                return { w: Math.round((r[0] || m.width) / sc), h: Math.round((r[1] || m.height) / sc) };
            }
            function setPlace(name, where) {
                const first = dp.mons[0].name;
                const a = logicalSize(first), b = logicalSize(name);
                const pos = { right: a.w + "x0", left: (-b.w) + "x0", above: "0x" + (-b.h), below: "0x" + a.h }[where];
                setDraft(first, "position", "0x0");
                setDraft(name, "position", pos);
            }

            function apply() {
                previous = JSON.parse(JSON.stringify(Settings.display.monitors || {}));
                Settings.display.monitors = JSON.parse(JSON.stringify(draft));
                countdown = 15;
            }
            function keep() { countdown = 0; previous = null; dp.read(); }
            function revert() {
                if (previous !== null) Settings.display.monitors = previous;
                countdown = 0;
                previous = null;
                draft = ({});
                revertRead.restart();
            }
            Timer { id: revertRead; interval: 1500; onTriggered: dp.read() }
            Timer {
                running: dp.countdown > 0
                repeat: true
                interval: 1000
                onTriggered: { dp.countdown--; if (dp.countdown === 0) dp.revert(); }
            }

            PageTitle { text: "Màn hình" }

            Text {
                visible: !dp.loaded
                text: "Đang đọc thông tin màn hình…"
                font.family: Theme.font
                font.pixelSize: 14
                color: Theme.dim
            }

            // hỏi lại sau khi áp dụng, như Windows: không bấm gì thì tự quay lại
            Group {
                visible: dp.countdown > 0
                title: ""
                ButtonsRow {
                    buttons: [["Quay lại", () => dp.revert()], ["Giữ thay đổi", () => dp.keep()]]
                    note: "Giữ cài đặt màn hình này? Tự quay lại sau " + dp.countdown + " giây."
                    last: true
                }
            }

            Repeater {
                model: dp.mons
                delegate: Group {
                    id: mg
                    required property var modelData
                    required property int index
                    readonly property var m: modelData
                    readonly property var d: dp.draft[m.name] || {}
                    title: (m.description || m.name).replace(/\s*\(.*\)$/, "") + "  ·  " + m.name

                    SwitchRow {
                        visible: dp.mons.length > 1
                        label: "Dùng màn hình này"
                        note: mg.index === 0 ? "Màn hình chính" : ""
                        on: !mg.d.disabled
                        // không cho tắt màn hình cuối cùng đang bật
                        enabled: !(!mg.d.disabled && dp.mons.filter(x => !(dp.draft[x.name] || {}).disabled).length <= 1)
                        onToggled: dp.setDraft(mg.m.name, "disabled", !mg.d.disabled)
                    }

                    // độ phân giải: bấm để mở danh sách
                    RowBase {
                        enabled: !mg.d.disabled
                        label: "Độ phân giải"
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 18
                            anchors.verticalCenter: parent.verticalCenter
                            text: dp.resOf(mg.d.mode).replace("x", " × ") + (dp.openModes === mg.m.name ? "  ▴" : "  ▾")
                            font.family: Theme.font
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: Theme.fg
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: dp.openModes = dp.openModes === mg.m.name ? "" : mg.m.name
                        }
                    }
                    Repeater {
                        model: dp.openModes === mg.m.name ? dp.resolutions(mg.m) : []
                        delegate: PickRow {
                            required property var modelData
                            required property int index
                            readonly property string res: modelData.w + "x" + modelData.h
                            // độ phân giải lớn nhất thường là độ phân giải gốc của màn hình
                            label: modelData.w + " × " + modelData.h + (index === 0 ? "  (gốc)" : "")
                            on: dp.resOf(mg.d.mode) === res
                            onPicked: {
                                const rates = dp.ratesFor(mg.m, res);
                                const hz = rates.indexOf(dp.hzOf(mg.d.mode)) >= 0 ? dp.hzOf(mg.d.mode) : rates[0];
                                dp.setDraft(mg.m.name, "mode", res + "@" + hz);
                                dp.openModes = "";
                            }
                        }
                    }

                    SegRow {
                        enabled: !mg.d.disabled
                        label: "Tần số quét"
                        note: "Càng cao chuyển động càng mượt, tốn pin hơn một chút"
                        options: dp.ratesFor(mg.m, dp.resOf(mg.d.mode)).slice(0, 5).map(r => [r, r + " Hz"])
                        current: dp.hzOf(mg.d.mode)
                        onPicked: v => dp.setDraft(mg.m.name, "mode", dp.resOf(mg.d.mode) + "@" + v)
                    }

                    SegRow {
                        enabled: !mg.d.disabled
                        label: "Tỉ lệ (chữ và biểu tượng to hơn)"
                        note: "Màn hình laptop độ phân giải cao thường hợp 125–150%"
                        options: [[1, "100%"], [1.25, "125%"], [1.5, "150%"], [1.75, "175%"], [2, "200%"]]
                        current: Math.round(+mg.d.scale * 100) / 100
                        onPicked: v => dp.setDraft(mg.m.name, "scale", v)
                        last: mg.index === 0 || dp.mons.length < 2
                    }

                    SegRow {
                        visible: mg.index > 0
                        enabled: !mg.d.disabled
                        label: "Đặt so với màn hình chính"
                        options: [["left", "Bên trái"], ["right", "Bên phải"], ["above", "Phía trên"], ["below", "Phía dưới"]]
                        current: dp.placeOf(mg.m.name)
                        onPicked: v => dp.setPlace(mg.m.name, v)
                        last: true
                    }
                }
            }

            Group {
                visible: dp.loaded
                title: ""
                ButtonsRow {
                    buttons: [["Đặt lại tự động", () => { Settings.display.monitors = ({}); dp.draft = ({}); revertRead.restart(); }],
                              ["Áp dụng", () => dp.apply()]]
                    note: dp.dirty ? "Có thay đổi chưa áp dụng." : "Cắm thêm màn hình thì mở lại trang này để chỉnh."
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
                SegRow {
                    label: "Hiệu ứng thu nhỏ cửa sổ"
                    note: "Thần đèn: cửa sổ bị hút vào biểu tượng trên dock như macOS. Bấm Super + H để thu nhỏ."
                    options: [["genie", "Thần đèn"], ["scale", "Thu nhỏ"], ["off", "Tắt"]]
                    current: Settings.dock.minimizeFx
                    onPicked: v => Settings.dock.minimizeFx = v
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
        id: powerPage
        Column {
            spacing: 26
            PageTitle { text: "Nguồn điện" }

            Group {
                title: "Chế độ"
                SegRow {
                    label: "Hiệu năng"
                    note: "Tiết kiệm pin: máy mát và lâu hết pin hơn. Hiệu năng: nhanh nhất, tốn pin."
                    options: [[PowerProfile.PowerSaver, "Tiết kiệm pin"], [PowerProfile.Balanced, "Cân bằng"], [PowerProfile.Performance, "Hiệu năng"]]
                    current: PowerProfiles.profile
                    onPicked: v => PowerProfiles.profile = v
                }
                InfoRow {
                    visible: !!UPower.displayDevice && UPower.displayDevice.isLaptopBattery
                    label: "Pin"
                    value: UPower.displayDevice ? Math.round(UPower.displayDevice.percentage * 100) + "%" + (UPower.onBattery ? " · đang dùng pin" : " · đang sạc") : ""
                    last: true
                }
            }

            Group {
                title: "Khi không dùng máy"
                SegRow {
                    label: "Tắt màn hình sau"
                    options: [[60, "1 phút"], [180, "3 phút"], [330, "5 phút"], [600, "10 phút"], [1800, "30 phút"], [0, "Không"]]
                    current: Settings.power.screenOffAfter
                    onPicked: v => Settings.power.screenOffAfter = v
                }
                SegRow {
                    label: "Khóa màn hình sau"
                    options: [[120, "2 phút"], [300, "5 phút"], [600, "10 phút"], [1800, "30 phút"], [0, "Không"]]
                    current: Settings.power.lockAfter
                    onPicked: v => Settings.power.lockAfter = v
                }
                SegRow {
                    label: "Cho máy ngủ sau"
                    note: "Máy luôn khóa trước khi ngủ, kể cả khi gập màn hình laptop. Đang xem phim hay họp video thì không tự khóa."
                    options: [[900, "15 phút"], [1800, "30 phút"], [3600, "1 giờ"], [0, "Không"]]
                    current: Settings.power.sleepAfter
                    onPicked: v => Settings.power.sleepAfter = v
                    last: true
                }
            }
        }
    }

    Component {
        id: dtPage
        Column {
            id: dt
            spacing: 26
            property string tz: ""
            property bool ntp: true
            property var zones: []
            property string q: ""

            function read() { infoProc.running = false; infoProc.running = true; }
            Component.onCompleted: { read(); zoneProc.running = true; }
            Process {
                id: infoProc
                command: ["timedatectl", "show", "-p", "Timezone", "-p", "NTP", "--value"]
                stdout: StdioCollector {
                    onStreamFinished: { const l = text.trim().split("\n"); dt.tz = l[0] || ""; dt.ntp = l[1] === "yes"; }
                }
            }
            Process {
                id: zoneProc
                command: ["timedatectl", "list-timezones"]
                stdout: StdioCollector { onStreamFinished: dt.zones = text.trim().split("\n") }
            }
            // timedatectl hỏi mật khẩu bằng hộp thoại của hệ thống (hyprpolkitagent)
            Process {
                id: setProc
                onExited: dt.read()
            }
            function run(cmd) { setProc.command = cmd; setProc.running = true; }

            SystemClock { id: dclock; precision: SystemClock.Seconds }

            PageTitle { text: "Ngày giờ" }

            Group {
                title: ""
                InfoRow {
                    label: "Bây giờ"
                    value: dclock.date.toLocaleString(Qt.locale("vi_VN"), "dddd, dd/MM/yyyy") + "  "
                           + Qt.formatDateTime(dclock.date, Settings.misc.clock24 ? "HH:mm:ss" : "h:mm:ss AP")
                }
                SwitchRow {
                    label: "Tự đặt giờ qua mạng"
                    note: "Nên bật. Đổi cài đặt này cần mật khẩu."
                    on: dt.ntp
                    onToggled: dt.run(["timedatectl", "set-ntp", dt.ntp ? "false" : "true"])
                }
                SegRow {
                    label: "Kiểu giờ"
                    options: [[true, "24 giờ"], [false, "12 giờ (SA/CH)"]]
                    current: Settings.misc.clock24
                    onPicked: v => Settings.misc.clock24 = v
                    last: true
                }
            }

            Group {
                title: "Múi giờ"
                InfoRow { label: "Đang dùng"; value: dt.tz }
                Item {
                    width: parent.width
                    height: 60
                    Rectangle {
                        x: 16; y: 10
                        width: parent.width - 32 - 150
                        height: 40
                        radius: 12
                        color: Theme.chip
                        TextInput {
                            id: zq
                            x: 14
                            width: parent.width - 28
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Theme.font
                            font.pixelSize: 14
                            color: Theme.fg
                            clip: true
                            onTextChanged: dt.q = text.trim().toLowerCase().replace(/ /g, "_")
                            Text { visible: zq.text.length === 0; text: "Tìm thành phố, ví dụ Tokyo, London"; font: zq.font; color: Theme.dim }
                        }
                    }
                    SmallButton {
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        y: 13
                        text: "Giờ Việt Nam"
                        onClicked: dt.run(["timedatectl", "set-timezone", "Asia/Ho_Chi_Minh"])
                    }
                }
                Repeater {
                    model: dt.q.length < 2 ? [] : dt.zones.filter(z => z.toLowerCase().includes(dt.q)).slice(0, 8)
                    delegate: PickRow {
                        required property string modelData
                        label: modelData.replace(/_/g, " ")
                        on: modelData === dt.tz
                        onPicked: { dt.run(["timedatectl", "set-timezone", modelData]); zq.text = ""; }
                    }
                }
            }
        }
    }

    Component {
        id: appsPage
        Column {
            id: ap
            spacing: 26
            // [nhãn, các kiểu tệp]; kiểu đầu tiên dùng để đọc ứng dụng đang chọn
            readonly property var kinds: [
                ["Trình duyệt web", ["x-scheme-handler/https", "x-scheme-handler/http", "text/html"]],
                ["Thư mục", ["inode/directory"]],
                ["Ảnh", ["image/jpeg", "image/png", "image/webp", "image/gif", "image/bmp", "image/tiff", "image/avif", "image/heic", "image/svg+xml"]],
                ["Video", ["video/mp4", "video/x-matroska", "video/webm", "video/quicktime", "video/x-msvideo", "video/mpeg"]],
                ["Nhạc", ["audio/mpeg", "audio/flac", "audio/ogg", "audio/x-wav", "audio/mp4", "audio/aac"]],
                ["PDF", ["application/pdf"]],
                ["Văn bản", ["text/plain", "text/markdown"]],
                ["Tệp nén", ["application/zip", "application/x-7z-compressed", "application/vnd.rar", "application/x-tar", "application/gzip"]]
            ]
            property var current: ({})     // nhãn → tệp .desktop đang chọn
            property var choices: ({})     // nhãn → [tệp .desktop có thể mở]
            property string open: ""

            function read() { lister.running = false; lister.running = true; }
            Component.onCompleted: read()
            Process {
                id: lister
                // mỗi loại: dòng "#nhãn", dòng mặc định, rồi các ứng dụng đăng ký (gio mime)
                command: ["sh", "-c", ap.kinds.map(k =>
                    "echo '#" + k[0] + "'; xdg-mime query default " + k[1][0] + "; echo '--'; "
                    + "LC_ALL=C gio mime " + k[1][0] + " 2>/dev/null | sed -n '/Registered applications:/,/Recommended/p' | grep -E '^\\s+' | tr -d '\\t '"
                ).join("; ")]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const cur = {}, ch = {};
                        let label = "", phase = 0;
                        for (const line of text.split("\n")) {
                            if (line.startsWith("#")) { label = line.slice(1); phase = 1; ch[label] = []; continue; }
                            if (line === "--") { phase = 2; continue; }
                            if (!line.trim()) continue;
                            if (phase === 1) cur[label] = line.trim();
                            else if (phase === 2 && ch[label].indexOf(line.trim()) < 0) ch[label].push(line.trim());
                        }
                        ap.current = cur;
                        ap.choices = ch;
                    }
                }
            }
            function entryOf(file) { return DesktopEntries.byId((file || "").replace(/\.desktop$/, "")); }
            function setDefault(kind, file) {
                Quickshell.execDetached(["xdg-mime", "default", file].concat(kind[1]));
                const c = Object.assign({}, ap.current);
                c[kind[0]] = file;
                ap.current = c;
                ap.open = "";
            }

            PageTitle { text: "Ứng dụng mặc định" }

            Group {
                title: "Mở bằng"
                Repeater {
                    model: ap.kinds
                    delegate: Column {
                        id: kd
                        required property var modelData
                        required property int index
                        width: parent.width
                        readonly property string cur: ap.current[modelData[0]] || ""
                        readonly property var e: ap.entryOf(cur)
                        RowBase {
                            label: kd.modelData[0]
                            last: kd.index === ap.kinds.length - 1 && ap.open !== kd.modelData[0]
                            Row {
                                anchors.right: parent.right
                                anchors.rightMargin: 18
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 10
                                Image {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 22
                                    height: 22
                                    sourceSize: Qt.size(44, 44)
                                    source: kd.e ? Quickshell.iconPath(kd.e.icon, "application-x-executable") : ""
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: (kd.e ? kd.e.name : kd.cur || "Chưa chọn") + (ap.open === kd.modelData[0] ? "  ▴" : "  ▾")
                                    font.family: Theme.font
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: Theme.fg
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ap.open = ap.open === kd.modelData[0] ? "" : kd.modelData[0]
                            }
                        }
                        Repeater {
                            model: ap.open === kd.modelData[0] ? (ap.choices[kd.modelData[0]] || []) : []
                            delegate: PickRow {
                                required property string modelData
                                readonly property var en: ap.entryOf(modelData)
                                label: "      " + (en ? en.name : modelData)
                                on: modelData === kd.cur
                                onPicked: ap.setDefault(kd.modelData, modelData)
                            }
                        }
                    }
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
                title: "Cập nhật phần mềm"
                InfoRow {
                    label: Updates.checking ? "Đang kiểm tra…"
                        : Updates.count > 0 ? "Có " + Updates.count + " bản cập nhật" : "Máy đang ở bản mới nhất"
                    value: Updates.lastCheck && !isNaN(Updates.lastCheck.getTime())
                           ? "kiểm tra lúc " + Qt.formatDateTime(Updates.lastCheck, "HH:mm") : ""
                }
                ButtonsRow {
                    buttons: [["Kiểm tra ngay", () => Updates.check()],
                              ["Cập nhật", () => Updates.run()],
                              ["Kho ứng dụng", () => Quickshell.execDetached(["gnome-software"])]]
                    note: "Tự kiểm tra mỗi 3 giờ. Kho ứng dụng lấy phần mềm từ Flathub."
                    last: true
                }
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
        property string labelFont: Theme.font
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
                font.family: rb.labelFont
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
        LiquidSwitch {
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            on: sr.on
            held: srArea.pressed
            interactive: false
        }
        MouseArea {
            id: srArea
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
