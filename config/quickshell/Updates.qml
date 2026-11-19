pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Kiểm tra bản cập nhật: gói Arch (checkupdates, không cần sudo), gói AUR (yay, nếu có)
// và ứng dụng Flatpak. Kiểm tra 2 phút sau khi đăng nhập, rồi mỗi 3 giờ.
// Có bản mới: hiện trong trung tâm điều khiển và một thông báo.
// Bấm "Cập nhật" mở terminal chạy lệnh cập nhật (cần mật khẩu, bạn xem được từng bước).
Singleton {
    id: root

    property int pacman: 0
    property int aur: 0
    property int flatpak: 0
    readonly property int count: pacman + aur + flatpak
    property bool checking: false
    property bool updating: false
    property date lastCheck

    function check() {
        if (checking || updating) return;
        checking = true;
        proc.running = true;
    }

    Process {
        id: proc
        // ba dòng: số gói Arch, số gói AUR, số ứng dụng Flatpak
        command: ["sh", "-c",
            "a=$(checkupdates 2>/dev/null | wc -l); "
            + "b=0; command -v yay >/dev/null 2>&1 && b=$(yay -Qua 2>/dev/null | wc -l); "
            // Flatpak: đếm cả ứng dụng cài riêng cho bạn (--user) lẫn cài cho cả máy (--system, Kho ứng dụng hay cài kiểu này)
            + "c=0; command -v flatpak >/dev/null 2>&1 && c=$( { flatpak remote-ls --updates --user --columns=application; "
            + "flatpak remote-ls --updates --system --columns=application; } 2>/dev/null | sort -u | grep -c . ); "
            + "printf '%s\\n%s\\n%s\\n' \"$a\" \"$b\" \"$c\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim().split("\n").map(x => parseInt(x) || 0);
                const before = root.count;
                root.pacman = v[0] || 0;
                root.aur = v[1] || 0;
                root.flatpak = v[2] || 0;
                root.checking = false;
                root.lastCheck = new Date();
                if (root.count > before && root.count > 0) root.announce();
            }
        }
    }

    function announce() {
        notifyProc.running = false;
        notifyProc.running = true;
    }
    Process {
        id: notifyProc
        command: ["notify-send", "-a", "Cập nhật", "-i", "system-software-update",
                  "--action=update=Cập nhật ngay",
                  "Có " + root.count + " bản cập nhật", "Bấm để cập nhật, hoặc mở trung tâm điều khiển (Super + N)"]
        stdout: StdioCollector { onStreamFinished: if (text.trim() === "update") root.run() }
    }

    // cập nhật trong terminal để bạn nhập mật khẩu và thấy tiến trình
    function run() {
        if (updating) return;
        updating = true;
        updProc.running = true;
    }
    Process {
        id: updProc
        command: ["kitty", "--class", "lg-update", "--title", "Cập nhật phần mềm", "-e", "sh", "-c",
            "echo '== Gói Arch =='; sudo pacman -Syu; "
            + "if command -v yay >/dev/null 2>&1; then echo; echo '== Gói AUR =='; yay -Sua; fi; "
            + "if command -v flatpak >/dev/null 2>&1; then echo; echo '== Ứng dụng Flatpak =='; flatpak update -y; fi; "
            + "echo; echo 'Xong. Nếu có cập nhật kernel, khởi động lại máy để dùng bản mới.'; "
            + "printf 'Bấm Enter để đóng… '; read -r _"]
        onExited: { root.updating = false; root.check(); }
    }

    Timer {
        running: true
        interval: 2 * 60 * 1000
        onTriggered: root.check()
    }
    Timer {
        running: true
        repeat: true
        interval: 3 * 60 * 60 * 1000
        onTriggered: root.check()
    }

    IpcHandler {
        target: "updates"
        function check(): void { root.check(); }
        function run(): void { root.run(); }
    }
}
