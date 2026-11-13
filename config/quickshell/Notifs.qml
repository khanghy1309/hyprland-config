pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Trình nhận thông báo của hệ thống (thay cho mako/dunst).
//   list    – mọi thông báo còn giữ (hiện ở trung tâm điều khiển)
//   current – thông báo đang hiện trên đảo động
Singleton {
    id: root

    property bool dnd: false
    property bool hovering: false
    property var popups: []

    readonly property var list: server.trackedNotifications.values
    readonly property var current: popups.length > 0 ? popups[0] : null

    function next() {
        root.popups = root.popups.slice(1).filter(n => n && n.tracked);
    }

    function dismiss(n) {
        root.popups = root.popups.filter(x => x && x !== n && x.tracked);
        if (n) n.dismiss();
    }

    // bảng thông báo nghe tín hiệu này để cho từng thẻ tan thành bụi, rồi mới gọi clearAll()
    signal clearing()

    function clearAll() {
        for (const n of root.list.slice()) n.dismiss();
        root.popups = [];
    }

    function iconFor(n) {
        if (!n) return "";
        if (n.image) return n.image;
        if (n.appIcon && (n.appIcon.startsWith("/") || n.appIcon.startsWith("file:")))
            return n.appIcon.startsWith("/") ? "file://" + n.appIcon : n.appIcon;
        return n.appIcon ? Quickshell.iconPath(n.appIcon, true) : "";
    }

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true;
            if (root.dnd && n.urgency !== NotificationUrgency.Critical) return;
            root.popups = root.popups.concat([n]);
        }
    }

    onCurrentChanged: {
        if (!current) { popTimer.stop(); return; }
        if (current.urgency === NotificationUrgency.Critical) { popTimer.stop(); return; }
        popTimer.restart();
    }
    onHoveringChanged: {
        if (hovering) popTimer.stop();
        else if (current && current.urgency !== NotificationUrgency.Critical) popTimer.restart();
    }

    Timer {
        id: popTimer
        interval: root.current && root.current.expireTimeout > 0
                  ? Math.min(root.current.expireTimeout, 10000) : Config.notifTimeout
        onTriggered: root.next()
    }
}
