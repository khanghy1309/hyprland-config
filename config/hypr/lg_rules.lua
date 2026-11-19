-- Quy tắc cho cửa sổ và lớp giao diện

-------------------------------------------------------------------
-- Lớp (layer) của Quickshell: thanh trên, launcher, bảng trượt...
-- Mọi lớp có tên bắt đầu bằng "glass-" đều được làm mờ phía sau.
-- ignore_alpha: phần hoàn toàn trong suốt (ngoài viên kính) không bị làm mờ,
-- nên chỉ đúng hình viên kính bo tròn được làm mờ.
-------------------------------------------------------------------
hl.layer_rule({
    name  = "glass-layers",
    match = { namespace = "^glass-.*$" },
    blur         = true,
    blur_popups  = true,
    ignore_alpha = 0.05,
})

-- Lớp phủ của hiệu ứng thu nhỏ (thần đèn): phải hiện ngay lập tức, đúng lúc cửa sổ thật được cất đi.
-- Nếu để Hyprland cho nó hiện dần như các lớp khác thì cửa sổ sẽ chớp một cái trước khi bay vào dock.
hl.layer_rule({
    name  = "minimize-overlay",
    match = { namespace = "^lg-minimize$" },
    no_anim = true,
})

-------------------------------------------------------------------
-- Cửa sổ
-------------------------------------------------------------------

-- Bỏ qua yêu cầu "phóng to" của ứng dụng (giữ bố cục xếp ô)
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Sửa lỗi kéo thả với XWayland (từ cấu hình mẫu)
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- Terminal thả xuống: luôn nổi, nằm trong workspace đặc biệt "dropdown"
hl.window_rule({
    name  = "dropdown-terminal",
    match = { class = "^dropdown$" },
    float     = true,
    workspace = "special:dropdown silent",
    size      = "1200 620",
    center    = true,
})

-- Video ảnh-trong-ảnh của trình duyệt: nổi, ghim, nằm góc dưới phải
hl.window_rule({
    name  = "picture-in-picture",
    match = { title = "^(Picture-in-Picture|Picture in picture|Hình trong hình)$" },
    float = true,
    pin   = true,
    size  = "480 270",
    move  = "monitor_w-504 monitor_h-294",
    keep_aspect_ratio = true,
})

-- Hộp thoại mở/lưu tệp và vài ứng dụng nhỏ: nổi, ở giữa
hl.window_rule({
    name  = "float-dialogs",
    match = { title = "^(Open File|Open Folder|Save As|Save File|Mở tệp|Lưu tệp).*$" },
    float  = true,
    center = true,
})
hl.window_rule({
    name  = "float-small-apps",
    match = { class = "^(org.pulseaudio.pavucontrol|blueman-manager|nm-connection-editor|org.fcitx.fcitx5-config-qt)$" },
    float  = true,
    size   = "900 600",
    center = true,
})

-- Satty (sửa ảnh chụp màn hình): nổi, ở giữa
hl.window_rule({
    name  = "float-satty",
    match = { class = "^com.gabm.satty$" },
    float  = true,
    size   = "1280 800",
    center = true,
})

-- Ứng dụng Cài đặt của Liquid Glass (một cửa sổ Quickshell): nổi, ở giữa
hl.window_rule({
    name  = "float-lg-settings",
    match = { class = "^org.quickshell$", title = "^Cài đặt$" },
    float  = true,
    size   = "1000 680",
    center = true,
})

-- Xem nhanh (chọn tệp trong trình quản lý tệp rồi bấm Space, như Quick Look của macOS):
-- nổi ở giữa màn hình, phóng ra từ giữa thay vì trượt vào
hl.window_rule({
    name      = "float-quick-look",
    match     = { class = "^org.gnome.NautilusPreviewer$" },
    float     = true,
    center    = true,
    animation = "popin 85%",
})

-- Máy tính bỏ túi: nổi, nhỏ gọn
hl.window_rule({
    name  = "float-calculator",
    match = { class = "^org.gnome.Calculator$" },
    float = true,
})

-- Cửa sổ cập nhật phần mềm (terminal): nổi, ở giữa
hl.window_rule({
    name  = "float-lg-update",
    match = { class = "^lg-update$" },
    float  = true,
    size   = "900 560",
    center = true,
})
