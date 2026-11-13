pragma Singleton

import QtQuick
import Quickshell

// Thời tiết từ open-meteo.com, cập nhật mỗi 30 phút. Vị trí đặt trong Cài đặt → Thời tiết.
Singleton {
    id: root

    readonly property bool configured: isFinite(Config.weatherLat) && isFinite(Config.weatherLon)
    // đổi vị trí trong Cài đặt: lấy lại ngay
    readonly property string whereKey: Config.weatherLat + "," + Config.weatherLon
    onWhereKeyChanged: refresh()
    property bool loading: false
    property string error: ""
    property real temp: NaN
    property real feels: NaN
    property real tMax: NaN
    property real tMin: NaN
    property int code: -1
    readonly property string desc: describe(code)

    function describe(c) {
        if (c < 0) return "";
        if (c === 0) return "Trời quang";
        if (c <= 2) return "Ít mây";
        if (c === 3) return "Nhiều mây";
        if (c <= 48) return "Sương mù";
        if (c <= 57) return "Mưa phùn";
        if (c <= 67) return "Mưa";
        if (c <= 77) return "Tuyết";
        if (c <= 82) return "Mưa rào";
        if (c <= 86) return "Mưa tuyết";
        return "Dông";
    }

    function refresh() {
        if (!configured) return;
        loading = true;
        const url = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + Config.weatherLat + "&longitude=" + Config.weatherLon
            + "&current=temperature_2m,apparent_temperature,weather_code"
            + "&daily=temperature_2m_max,temperature_2m_min&forecast_days=1&timezone=auto";
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            root.loading = false;
            if (xhr.status !== 200) { root.error = "Không lấy được dữ liệu"; return; }
            try {
                const d = JSON.parse(xhr.responseText);
                root.temp = d.current.temperature_2m;
                root.feels = d.current.apparent_temperature;
                root.code = d.current.weather_code;
                root.tMax = d.daily.temperature_2m_max[0];
                root.tMin = d.daily.temperature_2m_min[0];
                root.error = "";
            } catch (e) {
                root.error = "Dữ liệu không đọc được";
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    Timer {
        interval: 30 * 60 * 1000
        repeat: true
        running: root.configured
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
