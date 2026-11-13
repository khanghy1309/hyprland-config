pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Lựa chọn của ứng dụng Cài đặt (Super + ,), lưu ở ~/.config/liquid-glass/settings.json.
// Mỗi khi đổi:
//   - ghi lại settings.json (wallpaper.sh đọc phần hình nền từ đây)
//   - ghi ~/.config/hypr/lg_settings.lua; Hyprland thấy file đổi thì tự tải lại cấu hình
//   - phần của Quickshell (độ đậm kính, thời tiết...) đổi ngay
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || home + "/.config") + "/liquid-glass"
    readonly property string luaPath: (Quickshell.env("XDG_CONFIG_HOME") || home + "/.config") + "/hypr/lg_settings.lua"
    readonly property string wallScript: home + "/.config/hypr/scripts/wallpaper.sh"

    property alias look: adapter.look
    property alias input: adapter.input
    property alias gestures: adapter.gestures
    property alias wallpaper: adapter.wallpaper
    property alias weather: adapter.weather
    property alias misc: adapter.misc
    property alias dock: adapter.dock
    property alias display: adapter.display
    property alias power: adapter.power

    property bool ready: false

    FileView {
        id: file
        path: root.dir + "/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { root.ready = true; root.writeLua(); root.writeIdle(); }
        onLoadFailed: {
            // chưa có file: tạo với giá trị mặc định
            mkdir.running = true;
            root.ready = true;
        }
        onAdapterUpdated: if (root.ready) saveTimer.restart()

        JsonAdapter {
            id: adapter

            property JsonObject look: JsonObject {
                property int rounding: 22
                property int gapsIn: 7
                property int gapsOut: 14
                property string glass: "acrylic"     // acrylic | blur | off
                property int blurSize: 8
                property real panelAlpha: 0.5        // độ đậm của kính Quickshell (0,25 … 0,75)
                property bool shadow: true
                property bool borders: true
                property bool animations: true
                property real animScale: 1           // 0,7 nhanh · 1 vừa · 1,4 chậm
                property string font: "Geist"         // Geist | Inter | Be Vietnam Pro | Onest
                property string monoFont: "Geist Mono" // Geist Mono | JetBrains Mono
                property string material: "liquid"   // liquid | rim | flat  (xem Glass.qml)
                property bool refractVideo: false    // khúc xạ cả khi hình nền là video (dùng một khung hình tĩnh)
            }
            property JsonObject input: JsonObject {
                property bool naturalScroll: true
                property bool tapToClick: true
                property bool disableWhileTyping: true
                property real scrollFactor: 0.6
                property real sensitivity: 0
                property int repeatRate: 25
                property int repeatDelay: 600
            }
            property JsonObject gestures: JsonObject {
                property bool workspace: true
                property bool overview: true
                property bool dropdown: true
                property bool panels: true
            }
            property JsonObject wallpaper: JsonObject {
                property string pauseMode: "full"    // full | max | active | hidden | never
                property bool stillOnBattery: true
                property string transition: "fade"   // fade | grow | wipe | none
            }
            property JsonObject weather: JsonObject {
                property string city: ""             // để trống = chưa đặt vị trí
                property real lat: 0
                property real lon: 0
            }
            property JsonObject misc: JsonObject {
                property int nightLightTemp: 4500
                property int notifTimeout: 5000
                property bool clock24: true
            }
            property JsonObject display: JsonObject {
                // { "eDP-1": { mode: "1920x1080@60", scale: 1.25, position: "0x0", disabled: false }, ... }
                property var monitors: ({})
            }
            property JsonObject power: JsonObject {
                // giây không dùng máy; 0 = không bao giờ
                property int dimAfter: 150
                property int lockAfter: 300
                property int screenOffAfter: 330
                property int sleepAfter: 1800
            }
            property JsonObject dock: JsonObject {
                property bool enabled: true
                property bool autoHide: true          // ẩn khi có cửa sổ che chỗ của dock
                property int iconSize: 48
                property bool magnify: true           // phóng to biểu tượng khi rê chuột
                property string minimizeFx: "genie"   // genie | scale | off  (xem MinimizeFx.qml)
                // id của tệp .desktop, theo thứ tự trên dock
                property list<string> pinned: ["org.gnome.Nautilus", "firefox", "kitty", "liquid-glass-settings"]
            }
        }
    }

    Process {
        id: mkdir
        command: ["mkdir", "-p", root.dir]
        onExited: { file.writeAdapter(); root.writeLua(); root.writeIdle(); }
    }

    // gom các thay đổi liên tiếp (kéo thanh trượt) thành một lần ghi
    Timer {
        id: saveTimer
        interval: 350
        onTriggered: { file.writeAdapter(); root.writeLua(); root.writeIdle(); }
    }

    // ── Lua cho Hyprland ──
    function lua(v, depth) {
        const d = depth || 1;
        if (typeof v === "boolean") return v ? "true" : "false";
        if (typeof v === "number") return isFinite(v) ? String(Math.round(v * 1000) / 1000) : "nil";
        if (typeof v === "string") return JSON.stringify(v);
        if (v === null || v === undefined) return "nil";
        const pad = "    ".repeat(d + 1), end = "    ".repeat(d);
        // tên như "eDP-1" không phải tên biến Lua hợp lệ: viết dạng ["eDP-1"]
        const key = k => /^[A-Za-z_][A-Za-z0-9_]*$/.test(k) ? k : "[" + JSON.stringify(k) + "]";
        const keys = Object.keys(v);
        if (keys.length === 0) return "{}";
        return "{\n" + keys.map(k => pad + key(k) + " = " + lua(v[k], d + 1) + ",").join("\n") + "\n" + end + "}";
    }
    readonly property string luaText: {
        const L = look, I = input, G = gestures;
        const data = {
            look: { rounding: L.rounding, gapsIn: L.gapsIn, gapsOut: L.gapsOut, glass: L.glass,
                    blurSize: L.blurSize, shadow: L.shadow, borders: L.borders,
                    animations: L.animations, animScale: L.animScale },
            input: { naturalScroll: I.naturalScroll, tapToClick: I.tapToClick,
                     disableWhileTyping: I.disableWhileTyping, scrollFactor: I.scrollFactor,
                     sensitivity: I.sensitivity, repeatRate: I.repeatRate, repeatDelay: I.repeatDelay },
            gestures: { workspace: G.workspace, overview: G.overview, dropdown: G.dropdown, panels: G.panels },
            // từng màn hình: { mode, scale, position, disabled }; xem lg_monitors.lua
            monitors: display.monitors || {}
        };
        return "-- Do ứng dụng Cài đặt (Super + ,) tự ghi. Sửa tay sẽ bị ghi đè;\n"
             + "-- chỉnh riêng thì dùng user.lua.\nreturn {\n"
             + Object.keys(data).map(k => "    " + k + " = " + lua(data[k]) + ",").join("\n") + "\n}\n";
    }
    FileView { id: luaFile; path: root.luaPath; printErrors: false }
    function writeLua() {
        const old = luaFile.text();
        if (old === luaText) return;
        luaFile.setText(luaText);
        // Hyprland tự tải lại khi file nó đã nạp thay đổi; file mới tạo thì nó chưa theo dõi,
        // nên nhắc nó tải lại một lần
        if (old.trim() === "" || old.trim() === "return {}") reloadTimer.restart();
    }
    Timer {
        id: reloadTimer
        interval: 300
        onTriggered: Quickshell.execDetached(["hyprctl", "reload"])
    }

    // ── tự khóa / tắt màn hình / ngủ (Cài đặt → Nguồn điện) → ~/.config/hypr/hypridle.conf ──
    readonly property string idlePath: (Quickshell.env("XDG_CONFIG_HOME") || home + "/.config") + "/hypr/hypridle.conf"
    readonly property string idleText: {
        const P = power;
        const dpmsOff = "hyprctl dispatch 'hl.dsp.dpms({action = \"off\"})'";
        const dpmsOn = "hyprctl dispatch 'hl.dsp.dpms({action = \"on\"})'";
        const firstOff = [P.lockAfter, P.screenOffAfter].filter(x => x > 0);
        const dim = firstOff.length ? Math.max(20, Math.min(...firstOff) - 30) : 0;
        const L = ["# Do ứng dụng Cài đặt (Super + ,) → Nguồn điện tự ghi. Sửa tay sẽ bị ghi đè.",
                   "# hypridle 0.1 vẫn dùng cú pháp hyprlang.", "",
                   "general {",
                   "    lock_cmd = pidof hyprlock || hyprlock",
                   "    before_sleep_cmd = loginctl lock-session",
                   "    after_sleep_cmd = " + dpmsOn,
                   "    ignore_dbus_inhibit = false",
                   "}", ""];
        const add = (t, on, off, note) => {
            if (t <= 0) return;
            L.push("# " + note, "listener {", "    timeout = " + t, "    on-timeout = " + on);
            if (off) L.push("    on-resume = " + off);
            L.push("}", "");
        };
        add(dim, "brightnessctl -s set 10", "brightnessctl -r", "làm tối màn hình trước khi tắt/khóa");
        add(P.lockAfter, "loginctl lock-session", "", "khóa màn hình");
        add(P.screenOffAfter, dpmsOff, dpmsOn, "tắt màn hình");
        add(P.sleepAfter, "systemctl suspend", "", "cho máy ngủ");
        return L.join("\n");
    }
    FileView { id: idleFile; path: root.idlePath; printErrors: false }
    function writeIdle() {
        if (idleFile.text() === idleText) return;
        idleFile.setText(idleText);
        // hypridle không tự đọc lại file: khởi động lại nó
        Quickshell.execDetached(["sh", "-c", "pkill -x hypridle; sleep 0.3; setsid -f hypridle >/dev/null 2>&1"]);
    }

    // ── phông chữ cho ứng dụng GTK (Tệp, Firefox...) đổi theo ──
    readonly property string uiFont: look.font
    onUiFontChanged: if (ready) Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "font-name", uiFont + " 11"])

    // ── hình nền khi rút / cắm sạc ──
    readonly property bool onBattery: UPower.onBattery
    onOnBatteryChanged: powerTimer.restart()
    Timer {
        id: powerTimer
        interval: 1500     // chờ hình nền khởi động xong lúc mới đăng nhập
        running: true
        onTriggered: Quickshell.execDetached([root.wallScript, "power", root.onBattery ? "battery" : "ac"])
    }
}
