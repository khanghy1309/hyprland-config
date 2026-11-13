-- Biến môi trường

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Bộ gõ tiếng Việt (fcitx5 + Unikey/Bamboo).
-- Trên Wayland, ứng dụng GTK dùng giao thức text-input nên không cần GTK_IM_MODULE.
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("SDL_IM_MODULE", "fcitx")

-- Ứng dụng Qt dùng chế độ tối, không tự vẽ khung cửa sổ
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
