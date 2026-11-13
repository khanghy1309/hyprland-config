.pragma library

// Âm lịch Việt Nam (múi giờ +7), theo thuật toán của Hồ Ngọc Đức
// (https://www.informatik.uni-leipzig.de/~duc/amlich/). Tính tại chỗ, không cần mạng.

const TZ = 7;
const PI = Math.PI;
const INT = Math.floor;

function jdFromDate(dd, mm, yy) {
    const a = INT((14 - mm) / 12), y = yy + 4800 - a, m = mm + 12 * a - 3;
    let jd = dd + INT((153 * m + 2) / 5) + 365 * y + INT(y / 4) - INT(y / 100) + INT(y / 400) - 32045;
    if (jd < 2299161) jd = dd + INT((153 * m + 2) / 5) + 365 * y + INT(y / 4) - 32083;
    return jd;
}

function newMoonDay(k) {
    const T = k / 1236.85, T2 = T * T, T3 = T2 * T, dr = PI / 180;
    let Jd1 = 2415020.75933 + 29.53058868 * k + 0.0001178 * T2 - 0.000000155 * T3;
    Jd1 += 0.00033 * Math.sin((166.56 + 132.87 * T - 0.009173 * T2) * dr);
    const M = 359.2242 + 29.10535608 * k - 0.0000333 * T2 - 0.00000347 * T3;
    const Mpr = 306.0253 + 385.81691806 * k + 0.0107306 * T2 + 0.00001236 * T3;
    const F = 21.2964 + 390.67050646 * k - 0.0016528 * T2 - 0.00000239 * T3;
    let C1 = (0.1734 - 0.000393 * T) * Math.sin(M * dr) + 0.0021 * Math.sin(2 * dr * M);
    C1 = C1 - 0.4068 * Math.sin(Mpr * dr) + 0.0161 * Math.sin(dr * 2 * Mpr);
    C1 = C1 - 0.0004 * Math.sin(dr * 3 * Mpr);
    C1 = C1 + 0.0104 * Math.sin(dr * 2 * F) - 0.0051 * Math.sin(dr * (M + Mpr));
    C1 = C1 - 0.0074 * Math.sin(dr * (M - Mpr)) + 0.0004 * Math.sin(dr * (2 * F + M));
    C1 = C1 - 0.0004 * Math.sin(dr * (2 * F - M)) - 0.0006 * Math.sin(dr * (2 * F + Mpr));
    C1 = C1 + 0.0010 * Math.sin(dr * (2 * F - Mpr)) + 0.0005 * Math.sin(dr * (2 * Mpr + M));
    const deltat = T < -11
        ? 0.001 + 0.000839 * T + 0.0002261 * T2 - 0.00000845 * T3 - 0.000000081 * T * T3
        : -0.000278 + 0.000265 * T + 0.000262 * T2;
    return INT(Jd1 + C1 - deltat + 0.5 + TZ / 24);
}

function sunLongitude(jdn) {
    const T = (jdn - 2451545.5 - TZ / 24) / 36525, T2 = T * T, dr = PI / 180;
    const M = 357.52910 + 35999.05030 * T - 0.0001559 * T2 - 0.00000048 * T * T2;
    const L0 = 280.46645 + 36000.76983 * T + 0.0003032 * T2;
    let DL = (1.914600 - 0.004817 * T - 0.000014 * T2) * Math.sin(dr * M);
    DL = DL + (0.019993 - 0.000101 * T) * Math.sin(dr * 2 * M) + 0.000290 * Math.sin(dr * 3 * M);
    let L = (L0 + DL) * dr;
    L = L - PI * 2 * INT(L / (PI * 2));
    return INT(L / PI * 6);
}

function lunarMonth11(yy) {
    const off = jdFromDate(31, 12, yy) - 2415021;
    const k = INT(off / 29.530588853);
    let nm = newMoonDay(k);
    if (sunLongitude(nm) >= 9) nm = newMoonDay(k - 1);
    return nm;
}

function leapMonthOffset(a11) {
    const k = INT((a11 - 2415021.076998695) / 29.530588853 + 0.5);
    let last = 0, i = 1, arc = sunLongitude(newMoonDay(k + i));
    do {
        last = arc;
        i++;
        arc = sunLongitude(newMoonDay(k + i));
    } while (arc !== last && i < 14);
    return i - 1;
}

// dương lịch → { day, month, year, leap }
function toLunar(dd, mm, yy) {
    const dayNumber = jdFromDate(dd, mm, yy);
    const k = INT((dayNumber - 2415021.076998695) / 29.530588853);
    let monthStart = newMoonDay(k + 1);
    if (monthStart > dayNumber) monthStart = newMoonDay(k);
    let a11 = lunarMonth11(yy), b11 = a11, lunarYear;
    if (a11 >= monthStart) {
        lunarYear = yy;
        a11 = lunarMonth11(yy - 1);
    } else {
        lunarYear = yy + 1;
        b11 = lunarMonth11(yy + 1);
    }
    const lunarDay = dayNumber - monthStart + 1;
    const diff = INT((monthStart - a11) / 29);
    let leap = false, lunarMonth = diff + 11;
    if (b11 - a11 > 365) {
        const leapDiff = leapMonthOffset(a11);
        if (diff >= leapDiff) {
            lunarMonth = diff + 10;
            if (diff === leapDiff) leap = true;
        }
    }
    if (lunarMonth > 12) lunarMonth -= 12;
    if (lunarMonth >= 11 && diff < 4) lunarYear -= 1;
    return { day: lunarDay, month: lunarMonth, year: lunarYear, leap: leap };
}

const CAN = ["Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý"];
const CHI = ["Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"];
function yearName(y) { return CAN[(y + 6) % 10] + " " + CHI[(y + 8) % 12]; }

// ngày lễ: off = ngày nghỉ theo luật lao động
const SOLAR = {
    "1/1": ["Tết Dương lịch", true], "14/2": ["Lễ Tình nhân", false], "8/3": ["Quốc tế Phụ nữ", false],
    "30/4": ["Ngày Thống nhất", true], "1/5": ["Quốc tế Lao động", true], "1/6": ["Quốc tế Thiếu nhi", false],
    "2/9": ["Quốc khánh", true], "20/10": ["Phụ nữ Việt Nam", false], "20/11": ["Nhà giáo Việt Nam", false],
    "24/12": ["Đêm Giáng sinh", false], "25/12": ["Giáng sinh", false]
};
const LUNAR = {
    "1/1": ["Tết Nguyên đán", true], "2/1": ["Mùng 2 Tết", true], "3/1": ["Mùng 3 Tết", true],
    "15/1": ["Rằm tháng Giêng", false], "10/3": ["Giỗ Tổ Hùng Vương", true], "15/4": ["Lễ Phật đản", false],
    "5/5": ["Tết Đoan ngọ", false], "15/7": ["Lễ Vu Lan", false], "15/8": ["Tết Trung thu", false],
    "23/12": ["Ông Công ông Táo", false]
};

// mọi thông tin của một ngày dương lịch (tháng tính từ 1)
function info(dd, mm, yy) {
    const l = toLunar(dd, mm, yy);
    let h = SOLAR[dd + "/" + mm] || (!l.leap && LUNAR[l.day + "/" + l.month]) || null;
    // giao thừa: ngày cuối tháng Chạp (hôm sau là mùng 1 Tết)
    if (!h && l.month === 12 && !l.leap) {
        const next = new Date(yy, mm - 1, dd + 1);
        const n = toLunar(next.getDate(), next.getMonth() + 1, next.getFullYear());
        if (n.day === 1 && n.month === 1) h = ["Giao thừa", true];
    }
    return {
        lunar: l,
        // chữ nhỏ dưới ngày: mùng 1 hiện cả tháng
        short: l.day === 1 ? l.day + "/" + l.month + (l.leap ? "n" : "") : String(l.day),
        text: (l.day <= 10 ? "mùng " : "") + l.day + " tháng " + (l.month === 1 ? "Giêng" : l.month === 12 ? "Chạp" : l.month)
              + (l.leap ? " (nhuận)" : "") + " năm " + yearName(l.year),
        holiday: h ? h[0] : "",
        dayOff: h ? h[1] : false
    };
}
