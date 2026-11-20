import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Trình chạy nhanh (Super + Space).
//   gõ tên       → tìm ứng dụng
//   = biểu thức  → tính toán, Enter để chép kết quả
//   > lệnh       → chạy lệnh shell
//   / tên tệp    → tìm tệp trong thư mục nhà (cần fd), Enter để mở
//   ; chữ        → lịch sử bộ nhớ tạm (cliphist), Enter để chép lại, Shift + Delete để xóa
//   : tên        → emoji (gõ tiếng Anh hoặc tiếng Việt), Enter để chép
// Mở/đóng từ ngoài:  qs ipc call launcher toggle
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

    WlrLayershell.namespace: "glass-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property string query: ""
    property int selected: 0
    // hàng kết quả đang chọn: viên kính chọn trượt theo nó
    property Item selRow: null
    property var fileResults: []
    property var clipEntries: []
    readonly property int maxRows: 8

    function open(prefix) {
        const p = typeof prefix === "string" ? prefix : "";
        input.text = p;
        query = p;
        selected = 0;
        visible = true;
        input.forceActiveFocus();
        input.cursorPosition = p.length;
        if (p === ";") loadClips();
    }
    function close() { visible = false; }
    function toggle() { visible ? close() : open(); }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function close(): void { root.close(); }
        // mở thẳng vào lịch sử bộ nhớ tạm / emoji (Super + Shift + V dùng cái đầu)
        function clipboard(): void { root.open(";"); }
        function emoji(): void { root.open(":"); }
    }

    // ───────────────── tìm kết quả ─────────────────
    function score(entry, q) {
        const name = (entry.name || "").toLowerCase();
        if (name.startsWith(q)) return 100 - name.length * 0.1;
        const words = name.split(/[\s\-_.]+/);
        if (words.some(w => w.startsWith(q))) return 80;
        if (name.includes(q)) return 60;
        const extra = [entry.genericName || "", entry.comment || "", (entry.keywords || []).join(" ")]
                      .join(" ").toLowerCase();
        if (extra.includes(q)) return 30;
        return -1;
    }

    function calc(expr) {
        const e = expr.replace(/,/g, ".").replace(/\^/g, "**").replace(/×/g, "*").replace(/÷/g, "/");
        if (!/^[0-9+\-*/().%\s]*$/.test(e) || e.trim() === "") return null;
        try {
            const v = Function("\"use strict\"; return (" + e + ");")();
            if (typeof v !== "number" || !isFinite(v)) return null;
            return Math.round(v * 1e10) / 1e10;
        } catch (err) {
            return null;
        }
    }

    readonly property var results: {
        const q = root.query;
        const out = [];

        if (q.startsWith("=")) {
            const v = root.calc(q.slice(1));
            out.push(v === null
                ? { label: "Nhập một phép tính, ví dụ =12*(3+4)", sub: "", icon: "accessories-calculator", run: null }
                : { label: String(v).replace(".", ","), sub: "Enter để chép", icon: "accessories-calculator",
                    run: () => { Quickshell.clipboardText = String(v); } });
            return out;
        }

        if (q.startsWith(">")) {
            const cmd = q.slice(1).trim();
            out.push({ label: cmd.length ? cmd : "Nhập một lệnh để chạy", sub: cmd.length ? "Enter để chạy" : "",
                       icon: "utilities-terminal",
                       run: cmd.length ? () => Quickshell.execDetached(["sh", "-c", cmd]) : null });
            return out;
        }

        if (q.startsWith("/")) {
            for (const f of root.fileResults.slice(0, root.maxRows))
                out.push({ label: f.split("/").pop(), sub: "~/" + f, icon: "text-x-generic",
                           run: () => Quickshell.execDetached(["xdg-open", Quickshell.env("HOME") + "/" + f]) });
            if (out.length === 0)
                out.push({ label: q.length > 2 ? "Không thấy tệp nào" : "Nhập tên tệp cần tìm", sub: "",
                           icon: "system-search", run: null });
            return out;
        }

        if (q.startsWith(";")) {
            const cq = root.plain(q.slice(1).trim());
            for (const line of root.clipEntries) {
                const tab = line.indexOf("\t");
                const preview = tab >= 0 ? line.slice(tab + 1) : line;
                if (cq && !root.plain(preview).includes(cq)) continue;
                const img = preview.match(/^\[\[ binary data .*? (\w+) (\d+x\d+) \]\]$/);
                const entry = line;
                out.push({ label: img ? "Ảnh " + img[2] : preview.replace(/\s+/g, " ").trim(),
                           sub: img ? img[1] : "", icon: img ? "image-x-generic" : "edit-paste",
                           clip: entry,
                           run: () => Quickshell.execDetached(["sh", "-c",
                                    "printf '%s' \"$1\" | cliphist decode | wl-copy", "_", entry]) });
                if (out.length >= root.maxRows) break;
            }
            if (out.length === 0)
                out.push({ label: root.clipEntries.length ? "Không có mục nào khớp" : "Bộ nhớ tạm đang trống",
                           sub: "", icon: "edit-paste", run: null });
            return out;
        }

        if (q.startsWith(":")) {
            const eq = root.plain(q.slice(1).trim());
            // chưa gõ gì: hiện các emoji hay dùng (có từ khóa tiếng Việt) trước
            // xếp: từ khóa bắt đầu bằng chữ gõ > một từ bắt đầu bằng chữ gõ > chứa chữ gõ
            const rank = e => {
                const v = root.plain(e.vi), n = e.name.toLowerCase();
                if (v.startsWith(eq) || n.startsWith(eq)) return 3 - (v === eq || n === eq ? -1 : 0);
                if ((" " + v + " " + n).includes(" " + eq)) return 2;
                return 1;
            };
            const list = eq ? root.emojis.filter(e => e.key.includes(eq)).sort((x, y) => rank(y) - rank(x))
                            : root.emojis.filter(e => e.vi.length > 0);
            for (const e of list.slice(0, root.maxRows)) {
                const g = e.glyph;
                out.push({ label: e.vi || e.name, sub: e.vi ? e.name : "",
                           glyph: g, run: () => Quickshell.execDetached(["wl-copy", g]) });
            }
            if (out.length === 0)
                out.push({ label: "Không thấy emoji nào", sub: "", icon: "system-search", run: null });
            return out;
        }

        const lq = q.trim().toLowerCase();
        const apps = DesktopEntries.applications.values.filter(a => !a.noDisplay);
        let ranked;
        if (lq.length === 0) {
            ranked = apps.slice().sort((a, b) => a.name.localeCompare(b.name));
        } else {
            ranked = apps.map(a => ({ a, s: root.score(a, lq) }))
                         .filter(x => x.s >= 0)
                         .sort((x, y) => y.s - x.s || x.a.name.localeCompare(y.a.name))
                         .map(x => x.a);
        }
        for (const a of ranked.slice(0, root.maxRows)) {
            const entry = a;
            const pinned = Settings.dock.pinned.indexOf(entry.id) >= 0;
            out.push({ label: entry.name,
                       sub: (pinned ? "Đã ghim · " : "") + (entry.genericName || entry.comment || ""),
                       icon: entry.icon, appId: entry.id,
                       run: () => entry.execute() });
        }
        if (out.length === 0)
            out.push({ label: "Không thấy ứng dụng nào", sub: "Thử > " + q + " để chạy như một lệnh",
                       icon: "system-search", run: null });
        return out;
    }

    onQueryChanged: {
        selected = 0;
        if (query.startsWith("/")) fileTimer.restart();
        if (query === ";") loadClips();
    }

    // so khớp không dấu: gõ "cuoi" vẫn ra "cười"
    function plain(s) {
        return (s || "").toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/đ/g, "d");
    }

    // ── bộ nhớ tạm: đọc danh sách từ cliphist mỗi lần gõ ";" ──
    function loadClips() {
        clipProc.running = false;
        clipProc.running = true;
    }
    Process {
        id: clipProc
        command: ["sh", "-c", "cliphist list | head -n 200"]
        stdout: StdioCollector {
            onStreamFinished: root.clipEntries = text.split("\n").filter(l => l.length > 0)
        }
    }
    function deleteClip(i) {
        const r = results[i];
        if (!r || !r.clip) return;
        Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | cliphist delete", "_", r.clip]);
        root.clipEntries = root.clipEntries.filter(l => l !== r.clip);
    }

    // ── emoji: đọc một lần từ emoji.tsv cạnh file này ──
    FileView {
        id: emojiFile
        path: Quickshell.shellPath("emoji.tsv")
    }
    readonly property var emojis: emojiFile.text().split("\n")
        .filter(l => l.length > 0 && l[0] !== "#")
        .map(l => {
            const c = l.split("\t");
            return { glyph: c[0], name: c[1] || "", vi: c[2] || "", key: root.plain((c[1] || "") + " " + (c[2] || "")) };
        })

    // Ctrl + P hoặc chuột phải vào một ứng dụng: ghim / bỏ ghim trên dock
    function togglePin(i) {
        const r = results[i];
        if (!r || !r.appId) return;
        const list = Settings.dock.pinned.slice();
        const at = list.indexOf(r.appId);
        if (at >= 0) list.splice(at, 1); else list.push(r.appId);
        Settings.dock.pinned = list;
    }

    function activate(i) {
        const r = results[i];
        if (!r || !r.run) return;
        r.run();
        close();
    }

    // tìm tệp bằng fd, chờ người dùng ngừng gõ 200 ms
    Timer {
        id: fileTimer
        interval: 200
        onTriggered: {
            const q = root.query.slice(1).trim();
            if (q.length < 2) { root.fileResults = []; return; }
            // --fixed-strings: gõ "(", "[" hay "+" vẫn tìm đúng chữ đó, không bị hiểu là biểu thức chính quy.
            // "--" trước từ khoá: gõ chữ bắt đầu bằng "-" không bị fd hiểu thành tuỳ chọn (kể cả --exec).
            fileProc.running = false;      // đang tìm dở từ khoá cũ: dừng, tìm lại với từ khoá mới
            fileProc.command = ["fd", "--type", "f", "--fixed-strings", "--max-results", "40",
                                "--base-directory", Quickshell.env("HOME"), "--", q];
            fileProc.running = true;
        }
    }
    Process {
        id: fileProc
        stdout: StdioCollector {
            onStreamFinished: root.fileResults = text.split("\n").filter(l => l.length > 0)
        }
    }

    // ───────────────── giao diện ─────────────────

    // nền mờ phía sau; bấm ra ngoài để đóng
    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    GlassPill {
        id: card
        tone: "strong"
        radius: 30
        width: 760
        height: column.implicitHeight + 28
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.17
        // viền kính sáng lên ở chỗ gần con trỏ
        glow: cardHover.hovered ? 0.8 : 0
        glowPos: cardHover.point.position
        HoverHandler { id: cardHover }

        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.97
        Behavior on opacity { NumberAnimation { duration: Theme.fast } }
        Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

        // chặn click xuyên xuống nền
        MouseArea { anchors.fill: parent }

        GlassHighlight { follow: root.selRow; radius: 16 }

        Column {
            id: column
            x: 14
            y: 14
            width: parent.width - 28
            spacing: 4

            // ô tìm kiếm
            Rectangle {
                width: parent.width
                height: 62
                radius: 20
                color: Theme.chip

                Image {
                    x: 20
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    height: 22
                    sourceSize: Qt.size(44, 44)
                    source: Quickshell.iconPath("system-search-symbolic", "system-search")
                    opacity: 0.8
                }

                TextInput {
                    id: input
                    x: 54
                    width: parent.width - 54 - 70
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.font
                    font.pixelSize: 22
                    font.weight: Font.Medium
                    color: Theme.fg
                    selectionColor: Theme.glassSel ? Qt.rgba(1, 1, 1, 0.32) : Theme.accent
                    selectedTextColor: Theme.onFg
                    clip: true
                    focus: true
                    onTextChanged: root.query = text

                    Text {
                        visible: input.text.length === 0
                        text: "Tìm ứng dụng, tệp hoặc lệnh"
                        font: input.font
                        color: Theme.dim
                        opacity: 0.8
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            root.close();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
                            root.selected = Math.min(root.results.length - 1, root.selected + 1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                            root.selected = Math.max(0, root.selected - 1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_P && (event.modifiers & Qt.ControlModifier)) {
                            root.togglePin(root.selected);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier)) {
                            root.deleteClip(root.selected);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.activate(root.selected);
                            event.accepted = true;
                        }
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: escText.implicitWidth + 18
                    height: 26
                    radius: 8
                    color: Theme.chip
                    Text {
                        id: escText
                        anchors.centerIn: parent
                        text: "Esc"
                        font.family: Theme.mono
                        font.pixelSize: 12
                        color: Theme.dim
                    }
                    // bấm để đóng, như bấm Esc
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }

            Item { width: 1; height: 4 }

            // kết quả
            Repeater {
                model: root.results

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool isSel: index === root.selected
                    onIsSelChanged: if (isSel) root.selRow = row
                    Component.onCompleted: if (isSel) root.selRow = row

                    width: column.width
                    height: 52
                    radius: 16
                    color: !isSel && rowMouse.containsMouse ? Theme.chip : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.fast } }

                    Rectangle {
                        id: iconBox
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 32
                        radius: 16
                        color: row.isSel ? Qt.rgba(0, 0, 0, 0.08) : Theme.chip

                        Image {
                            visible: !row.modelData.glyph
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            sourceSize: Qt.size(44, 44)
                            source: row.modelData.glyph ? "" : Quickshell.iconPath(row.modelData.icon || "", "application-x-executable")
                        }
                        Text {
                            visible: !!row.modelData.glyph
                            anchors.centerIn: parent
                            text: row.modelData.glyph || ""
                            font.family: "Noto Color Emoji"
                            font.pixelSize: 20
                        }
                    }

                    Text {
                        anchors.left: iconBox.right
                        anchors.leftMargin: 14
                        anchors.right: subText.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        text: row.modelData.label
                        font.family: Theme.font
                        font.pixelSize: 16
                        font.weight: Font.Medium
                        color: row.isSel ? Theme.selFg : Theme.fg
                    }

                    Text {
                        id: subText
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, 300)
                        elide: Text.ElideLeft
                        text: row.modelData.sub
                        font.family: Theme.mono
                        font.pixelSize: 12
                        color: row.isSel ? Theme.selDim : Theme.dim
                    }

                    // mục bộ nhớ tạm: nút xoá khi rê chuột (như Shift + Delete)
                    Rectangle {
                        visible: !!row.modelData.clip && (rowMouse.containsMouse || delArea.containsMouse)
                        z: 2
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        radius: 14
                        color: delArea.containsMouse ? "#ff8a80" : Theme.chip
                        Icon { anchors.centerIn: parent; path: Icons.close; size: 12; stroke: 2.2; color: delArea.containsMouse ? Theme.ink : Theme.fg }
                        MouseArea {
                            id: delArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.deleteClip(row.index)
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) root.togglePin(row.index);
                            else root.activate(row.index);
                        }
                        onEntered: root.selected = row.index
                    }
                }
            }

            // chế độ tìm: bấm để chuyển, không cần nhớ ký tự đầu (ký tự vẫn hiện nhỏ để gõ cho nhanh)
            Rectangle { width: parent.width; height: 1; color: Theme.line }

            Item {
                width: parent.width
                height: 46
                Row {
                    x: 4
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    Repeater {
                        model: [["", "Ứng dụng", Icons.apps], ["/", "Tệp", Icons.file], [";", "Bộ nhớ tạm", Icons.clipboard],
                                [":", "Emoji", Icons.smile], ["=", "Máy tính", Icons.calc], [">", "Lệnh", Icons.terminal]]
                        delegate: Rectangle {
                            id: chip
                            required property var modelData
                            readonly property string pre: modelData[0]
                            readonly property bool on: pre === "" ? !/^[\/;:=>]/.test(root.query) : root.query.startsWith(pre)
                            width: chipRow.implicitWidth + 20
                            height: 30
                            radius: 15
                            color: !on && chipArea.containsMouse ? Theme.chip : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.fast } }
                            GlassHighlight { anchors.fill: parent; on: chip.on; radius: 15 }
                            Row {
                                id: chipRow
                                anchors.centerIn: parent
                                spacing: 6
                                Icon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    path: chip.modelData[2]
                                    size: 14
                                    color: chip.on ? Theme.selFg : Theme.fg
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: chip.modelData[1]
                                    font.family: Theme.font
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    color: chip.on ? Theme.selFg : Theme.fg
                                }
                                Text {
                                    visible: chip.pre !== ""
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: chip.pre
                                    font.family: Theme.mono
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    color: chip.on ? Theme.selDim : Theme.dim
                                }
                            }
                            MouseArea {
                                id: chipArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { input.text = chip.pre; input.cursorPosition = input.text.length; input.forceActiveFocus(); }
                            }
                        }
                    }
                }
            }
        }
    }
}
