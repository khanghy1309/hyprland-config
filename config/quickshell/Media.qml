pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

// Trình phát nhạc đang dùng (Spotify, trình duyệt, mpv...) và sóng âm từ cava.
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    // Trình phát có bài thật (có tên bài). Trình duyệt hay đăng ký trình phát rỗng cho mọi tab
    // từng có âm thanh; những cái đó bị bỏ qua để đảo động không hiện khi không có nhạc.
    readonly property var withTrack: players.filter(p => (p.trackTitle || "") !== "")
    readonly property var player: withTrack.find(p => p.isPlaying) ?? (withTrack.length > 0 ? withTrack[0] : null)
    readonly property bool playing: !!player && player.isPlaying
    readonly property bool hasTrack: !!player

    // độ cao các cột sóng âm, 0..1
    property var bars: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    function fmt(sec) {
        if (!isFinite(sec) || sec < 0) return "0:00";
        const s = Math.floor(sec % 60);
        return Math.floor(sec / 60) + ":" + (s < 10 ? "0" : "") + s;
    }

    // cava chỉ chạy khi đang phát nhạc
    Process {
        running: root.playing
        command: ["cava", "-p", Quickshell.shellPath("cava.conf")]
        stdout: SplitParser {
            onRead: data => {
                const v = data.split(";").filter(x => x !== "").map(x => Number(x) / 40);
                if (v.length > 0) root.bars = v;
            }
        }
        onRunningChanged: if (!running) root.bars = root.bars.map(() => 0)
    }

    // vị trí phát không tự cập nhật; báo cập nhật mỗi giây khi đang phát
    Timer {
        interval: 1000
        repeat: true
        running: root.playing
        onTriggered: if (root.player) root.player.positionChanged()
    }
}
