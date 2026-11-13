.pragma library
// Sổ chung cho mọi lần chụp cửa sổ trong shell (một bản duy nhất nhờ .pragma library).
//
// Mỗi lần chụp, Hyprland tạo một "ngữ cảnh chụp". Tạo hàng chục cái cùng một lúc
// (mở toàn cảnh khi có nhiều cửa sổ) dễ làm Hyprland trả lời lẫn lộn, nên ở đây xếp hàng:
// mỗi ngữ cảnh mới cách cái trước ít nhất SLOT_MS.
// Ý tưởng từ MacShell (github.com/0-ss/MacShell, giấy phép MIT).

var SLOT_MS = 12;
var next = 0;

// phải chờ bao lâu (ms) trước khi được tạo ngữ cảnh chụp mới
function slotDelay() {
    var now = Date.now();
    var at = Math.max(now, next);
    next = at + SLOT_MS;
    return at - now;
}
