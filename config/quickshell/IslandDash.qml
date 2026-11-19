import QtQuick
import Quickshell
import Quickshell.Io
import "lunar.js" as Lunar

// Nội dung đảo động khi mở rộng thành bảng widget (bấm vào đồng hồ, Super + W, vuốt 4 ngón sang phải).
//   hàng trên:  giờ lớn, ngày  ·  thời tiết
//   trái:       lịch tháng có âm lịch và ngày lễ; bấm vào một ngày để xem chi tiết
//   phải:       nhạc đang phát (nếu có), ghi chú nhanh, tài nguyên máy
Item {
    id: dash

    property bool active: false
    signal closeRequested()

    implicitWidth: 820
    implicitHeight: head.height + body.height + 22 * 2 + 18

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // tháng đang xem: 0 = tháng này, -1 = tháng trước...
    property int monthOffset: 0
    // ngày đang chọn (mặc định hôm nay)
    property date picked: new Date()
    onActiveChanged: if (active) { monthOffset = 0; picked = clock.date; }
    readonly property var pickedInfo: Lunar.info(picked.getDate(), picked.getMonth() + 1, picked.getFullYear())
    readonly property date shownMonth: {
        const d = clock.date;
        return new Date(d.getFullYear(), d.getMonth() + monthOffset, 1);
    }
    readonly property var days: {
        const first = shownMonth;
        const y = first.getFullYear(), m = first.getMonth();
        const count = new Date(y, m + 1, 0).getDate();
        const lead = (first.getDay() + 6) % 7;          // tuần bắt đầu từ thứ Hai
        const today = clock.date;
        const out = [];
        for (let i = 0; i < lead; i++) out.push({ n: "", today: false, weekend: false });
        for (let i = 1; i <= count; i++) {
            const dow = (lead + i - 1) % 7;
            const li = Lunar.info(i, m + 1, y);
            out.push({ n: String(i), weekend: dow === 6, date: new Date(y, m, i),
                       lunar: li.short, holiday: li.holiday, off: li.dayOff, firstLunar: li.lunar.day === 1,
                       today: y === today.getFullYear() && m === today.getMonth() && i === today.getDate() });
        }
        return out;
    }

    // ── hàng trên: giờ, ngày, thời tiết ──
    Item {
        id: head
        x: 26
        y: 22
        width: parent.width - 52
        height: 64

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 16
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(clock.date, Settings.misc.clock24 ? "HH:mm" : "h:mm AP")
                font.family: Theme.font
                font.pixelSize: 46
                font.weight: Font.Light
                color: Theme.fg
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                Text {
                    text: clock.date.toLocaleString(Qt.locale("vi_VN"), "dddd")
                    font.family: Theme.font
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    font.capitalization: Font.Capitalize
                    color: Theme.fg
                }
                Text {
                    text: clock.date.getDate() + " tháng " + (clock.date.getMonth() + 1) + ", " + clock.date.getFullYear()
                    font.family: Theme.font
                    font.pixelSize: 13
                    color: Theme.dim
                }
            }
        }

        // thời tiết: bấm để mở Cài đặt → Thời tiết
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: weatherRow.implicitWidth + 28
            height: 56
            radius: 20
            color: wm.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Theme.chip
            Row {
                id: weatherRow
                x: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    path: Weather.code === 0 ? Icons.sun : Icons.cloud
                    size: 24
                }
                Text {
                    visible: Weather.configured && isFinite(Weather.temp)
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(Weather.temp) + "°"
                    font.family: Theme.font
                    font.pixelSize: 28
                    font.weight: Font.Light
                    color: Theme.fg
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: Weather.configured ? (Config.weatherCity || "Thời tiết") : "Thời tiết"
                        font.family: Theme.font
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: Theme.fg
                    }
                    Text {
                        text: !Weather.configured ? "Bấm để đặt vị trí"
                            : Weather.error !== "" ? Weather.error
                            : !isFinite(Weather.temp) ? "Đang tải…"
                            : Weather.desc + " · " + Math.round(Weather.tMin) + "°–" + Math.round(Weather.tMax) + "°"
                        font.family: Theme.font
                        font.pixelSize: 12
                        color: Theme.dim
                    }
                }
            }
            MouseArea {
                id: wm
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    dash.closeRequested();
                    Quickshell.execDetached(["qs", "ipc", "call", "settings", "page", "weather"]);
                }
            }
        }
    }

    Row {
        id: body
        x: 22
        y: head.y + head.height + 18
        spacing: 14
        readonly property real colW: (dash.width - 44 - spacing) / 2

        // ── lịch ── (cao bằng cột bên phải cho hai cột thẳng hàng)
        Card {
            width: body.colW
            height: Math.max(calCol.implicitHeight + 28, rightCol.height)
            Column {
                id: calCol
                width: parent.width
                spacing: 4

                Row {
                    width: parent.width
                    Text {
                        width: parent.width - 68
                        leftPadding: 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Tháng " + (dash.shownMonth.getMonth() + 1) + ", " + dash.shownMonth.getFullYear()
                        font.family: Theme.font
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        color: Theme.fg
                    }
                    SmallButton { iconPath: Icons.chevronLeft; onClicked: dash.monthOffset-- }
                    SmallButton { iconPath: Icons.chevronRight; onClicked: dash.monthOffset++ }
                }

                Grid {
                    id: calGrid
                    columns: 7
                    width: parent.width
                    readonly property real cell: width / 7
                    Repeater {
                        model: ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
                        delegate: Text {
                            required property var modelData
                            width: parent.cell
                            height: 22
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: modelData
                            font.family: Theme.font
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: Theme.dim
                        }
                    }
                    Repeater {
                        model: dash.days
                        delegate: Item {
                            id: day
                            required property var modelData
                            readonly property bool isPicked: !!modelData.date && modelData.date.getTime() === new Date(dash.picked.getFullYear(), dash.picked.getMonth(), dash.picked.getDate()).getTime()
                            width: parent.cell
                            height: 40
                            // hôm nay: nền sáng; ngày đang chọn: viền
                            Rectangle {
                                anchors.centerIn: parent
                                width: 36
                                height: 38
                                radius: 12
                                visible: !!day.modelData.n && (day.modelData.today || day.isPicked)
                                color: day.modelData.today ? Theme.accent : "transparent"
                                border.width: day.isPicked && !day.modelData.today ? 1.5 : 0
                                border.color: Theme.fg
                            }
                            Column {
                                anchors.centerIn: parent
                                spacing: -1
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: day.modelData.n
                                    font.family: Theme.font
                                    font.pixelSize: 13
                                    font.weight: day.modelData.today ? Font.Bold : Font.Medium
                                    // ngày nghỉ lễ: màu đỏ nhạt
                                    color: day.modelData.today ? Theme.ink
                                         : day.modelData.off ? "#ff8a80"
                                         : day.modelData.weekend ? Theme.dim : Theme.fg
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: day.modelData.lunar || ""
                                    font.family: Theme.font
                                    font.pixelSize: 9
                                    font.weight: day.modelData.firstLunar ? Font.DemiBold : Font.Normal
                                    color: day.modelData.today ? Theme.inkDim : Theme.dim
                                    opacity: day.modelData.today ? 1 : 0.85
                                }
                            }
                            // ngày lễ không nghỉ: chấm nhỏ
                            Rectangle {
                                visible: !!day.modelData.holiday && !day.modelData.off
                                anchors.top: parent.top
                                anchors.topMargin: 3
                                anchors.right: parent.right
                                anchors.rightMargin: parent.width / 2 - 14
                                width: 4
                                height: 4
                                radius: 2
                                color: day.modelData.today ? Theme.ink : "#ffcc80"
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: !!day.modelData.date
                                cursorShape: Qt.PointingHandCursor
                                onClicked: dash.picked = day.modelData.date
                            }
                        }
                    }
                }

                // ngày đang chọn: âm lịch đầy đủ và ngày lễ
                Column {
                    width: parent.width
                    topPadding: 6
                    leftPadding: 6
                    spacing: 2
                    Text {
                        width: parent.width - 6
                        elide: Text.ElideRight
                        text: dash.picked.toLocaleString(Qt.locale("vi_VN"), "dddd, dd/MM") + " · âm lịch " + dash.pickedInfo.text
                        font.family: Theme.font
                        font.pixelSize: 12
                        color: Theme.fg
                    }
                    Text {
                        visible: dash.pickedInfo.holiday.length > 0
                        text: dash.pickedInfo.holiday + (dash.pickedInfo.dayOff ? " · ngày nghỉ" : "")
                        font.family: Theme.font
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: dash.pickedInfo.dayOff ? "#ff8a80" : "#ffcc80"
                    }
                }
            }
        }

        Column {
            id: rightCol
            width: body.colW
            spacing: 14

            // ── nhạc (chỉ khi có bài) ──
            Card {
                visible: Media.hasTrack
                width: parent.width
                MediaCard { width: parent.width }
            }

            // ── ghi chú nhanh ──
            Card {
                width: parent.width
                Column {
                    width: parent.width
                    spacing: 6
                    Text {
                        leftPadding: 4
                        text: "Ghi chú nhanh"
                        font.family: Theme.font
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        color: Theme.fg
                    }
                    Item {
                        width: parent.width
                        height: Media.hasTrack ? 52 : 96
                        clip: true
                        TextEdit {
                            id: notes
                            anchors.fill: parent
                            leftPadding: 4
                            wrapMode: TextEdit.Wrap
                            font.family: Theme.font
                            font.pixelSize: 14
                            color: Theme.fg
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.ink
                            property bool loaded: false
                            Keys.onEscapePressed: dash.closeRequested()
                            onTextChanged: if (loaded) saveTimer.restart()
                        }
                        Text {
                            visible: notes.text.length === 0
                            leftPadding: 4
                            text: "Bấm vào đây để gõ, tự lưu vào ~/notes/quick.md"
                            font: notes.font
                            color: Theme.dim
                            opacity: 0.8
                        }
                    }
                }
            }

            // ── tài nguyên máy ──
            Card {
                width: parent.width
                Column {
                    width: parent.width
                    spacing: 10
                    Meter { label: "CPU"; value: SysStats.cpu; valueText: Math.round(SysStats.cpu * 100) + "%" }
                    Meter {
                        label: "RAM"
                        value: SysStats.memTotalGiB > 0 ? SysStats.memUsedGiB / SysStats.memTotalGiB : 0
                        valueText: SysStats.memUsedGiB.toFixed(1).replace(".", ",") + "G"
                    }
                    Meter { label: "Ổ đĩa"; value: dash.diskUsed; valueText: Math.round(dash.diskUsed * 100) + "%" }
                }
            }
        }
    }

    // ── lưu / đọc ghi chú ──
    Component.onCompleted: {
        const dir = Config.notesFile.substring(0, Config.notesFile.lastIndexOf("/"));
        Quickshell.execDetached(["mkdir", "-p", dir]);
    }
    FileView {
        id: notesFile
        path: Config.notesFile
        atomicWrites: true
        onLoaded: { notes.text = text(); notes.loaded = true; }
        onLoadFailed: notes.loaded = true
    }
    Timer {
        id: saveTimer
        interval: 600
        onTriggered: notesFile.setText(notes.text)
    }
    // đảo thu lại ngay sau khi gõ (chưa tới 0,6 giây): lưu luôn, không mất mấy chữ cuối
    Component.onDestruction: if (saveTimer.running) notesFile.setText(notes.text)

    // ── dung lượng ổ đĩa ──
    property real diskUsed: 0
    Process {
        id: dfProc
        command: ["df", "-B1", "--output=used,size", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim().split("\n").pop().trim().split(/\s+/).map(Number);
                if (v.length === 2 && v[1] > 0) dash.diskUsed = v[0] / v[1];
            }
        }
    }
    Timer {
        interval: 60000
        repeat: true
        running: dash.active
        triggeredOnStart: true
        onTriggered: dfProc.running = true
    }

    component Card: Rectangle {
        default property alias content: inner.data
        height: inner.childrenRect.height + 28
        radius: 20
        color: Theme.chip
        Item {
            id: inner
            x: 14
            y: 14
            width: parent.width - 28
        }
    }

    component SmallButton: Rectangle {
        id: sb
        property string iconPath: ""
        signal clicked()
        width: 30
        height: 30
        radius: 15
        color: sbMouse.containsMouse ? Theme.chip : "transparent"
        Icon { anchors.centerIn: parent; path: sb.iconPath; size: 15 }
        MouseArea {
            id: sbMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: sb.clicked()
        }
    }

    component Meter: Row {
        id: mt
        property string label: ""
        property real value: 0
        property string valueText: ""
        width: parent.width
        spacing: 12
        Text {
            width: 48
            leftPadding: 4
            text: mt.label
            font.family: Theme.mono
            font.pixelSize: 12
            color: Theme.fg
            anchors.verticalCenter: parent.verticalCenter
        }
        Item {
            width: mt.width - 48 - 52 - 24
            height: 6
            anchors.verticalCenter: parent.verticalCenter
            Rectangle { anchors.fill: parent; radius: 3; color: Theme.chip }
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, mt.value))
                height: parent.height
                radius: 3
                color: Theme.fg
                Behavior on width { NumberAnimation { duration: Theme.normal } }
            }
        }
        Text {
            width: 52
            horizontalAlignment: Text.AlignRight
            text: mt.valueText
            font.family: Theme.mono
            font.pixelSize: 12
            color: Theme.fg
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
