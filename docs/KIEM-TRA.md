# Sổ kiểm tra

Tệp này ghi lại **những gì đã kiểm tra trong repo, kiểm tra bằng cách nào và kết quả ra sao**. Mục đích là lần sau không phải soát lại từ đầu: chỉ cần xem lại những tệp đã đổi từ lần kiểm tra trước.

Mã sha256 của từng tệp lúc kiểm tra được lưu ở `docs/kiem-tra.sha256`. Công cụ `tools/kiem-tra.sh` dựa vào tệp đó để biết tệp nào đã đổi.

## Cách dùng

```sh
tools/kiem-tra.sh                # tệp nào đã đổi / mới / đã xoá từ lần kiểm tra trước
tools/kiem-tra.sh chay           # chạy kiểm tra tự động trên những tệp đó
tools/kiem-tra.sh chay --tat-ca  # … hoặc trên cả repo
tools/kiem-tra.sh chay a.sh b.qml
tools/kiem-tra.sh ghi            # ghi mốc mới, sau khi đã xem lại xong
```

Quy trình cho mỗi lần sửa:

1. `tools/kiem-tra.sh` để xem những tệp cần xem lại.
2. `tools/kiem-tra.sh chay` và sửa cho hết lỗi.
3. Với từng tệp đã đổi, xem lại bằng mắt theo bảng "Kiểm tra bằng tay" bên dưới.
4. Thêm một mục vào "Nhật ký kiểm tra" ở cuối tệp này.
5. `tools/kiem-tra.sh ghi`, rồi commit cả `docs/KIEM-TRA.md` và `docs/kiem-tra.sha256`.

Một tệp **có trong mốc và mã khớp** nghĩa là nó đã được soát theo các bước dưới đây và không cần soát lại.

## Kiểm tra tự động (`tools/kiem-tra.sh chay`)

| Loại tệp | Công cụ | Ghi chú |
|---|---|---|
| `*.sh` và script có dòng `#!…sh` | `bash -n`, rồi `shellcheck -x -S warning` | Mức warning trở lên là phải sửa. |
| `*.lua` (cấu hình Hyprland) | `luac -p`, rồi `tools/kiem-tra-hypr.lua` | Cú pháp, rồi chạy `hyprland.lua` với một `hl` giả: mọi khoá trong `hl.config` phải có trong `tools/hyprland-0.57-options.txt` (lấy từ mã nguồn Hyprland 0.57); hướng và việc của cử chỉ cũng được kiểm. Lên bản Hyprland mới thì lấy lại danh sách. |
| `*.frag`, `*.vert` | `qsb` dịch thử | Đổi shader thì phải chạy `config/quickshell/shaders/build.sh` để dựng lại `.qsb`. `tools/kiem-tra.sh` cảnh báo khi shader đổi mà `.qsb` chưa đổi. |
| `*.qml` | `qmllint`, nếu máy có | Quickshell nạp module lúc chạy nên qmllint không biết kiểu của nó, vì vậy tắt các cảnh báo về import và kiểu. Máy dựng repo này không có qmllint, nên QML được kiểm tra bằng bản giả (xem bên dưới). |
| `*.js` | `node --check` | Bỏ các dòng `.pragma` / `.import` của QML trước khi kiểm. |
| `*.py` | `ast.parse` | |
| `*.json` | `python -m json.tool` | |
| `*.desktop` | `desktop-file-validate` | `sddm/liquid-glass/metadata.desktop` không phải Desktop Entry nên được bỏ qua. |
| css, qss, conf, svg, md… | (không có) | Xem bằng mắt. |

## Kiểm tra bằng tay

Các bước này đã làm cho mọi tệp trong mốc. Khi một tệp đổi, làm lại bước của loại tệp đó.

### QML của Quickshell (`config/quickshell/`)

- **Chạy trong bản giả.** Một bản giả của Quickshell viết bằng PySide6 (Hyprland, Pipewire, Mpris, Bluetooth, mạng, thông báo… đều là đối tượng giả) chạy trên Xvfb. Nền đồ hoạ là xcb kèm Mesa llvmpipe, nên shader chạy thật.
  - Đã chụp từng trạng thái: màn hình nền, dock, Alt+Tab, trình mở ứng dụng, tổng quan, bảng điều khiển, bảng widget, thông báo, OSD, menu nguồn, chụp màn hình, bảng phím tắt, menu chuột phải, và từng trang Cài đặt.
  - Chụp cả khi có lẫn không có cửa sổ, với hình nền sáng và hình nền tối.
  - Tiêu chí: không có lỗi hay `TypeError` trong log, và ảnh trông đúng.
- **Đọc lại mã**, tìm các lỗi sau:
  - Process vẫn chạy khi trang hoặc cửa sổ đã ẩn.
  - Lệnh `sh -c` ghép chuỗi từ dữ liệu người dùng; phải truyền dữ liệu qua `"$1"`.
  - Tham số do người dùng gõ bị hiểu thành tuỳ chọn; phải đặt `--` trước nó.
  - Dữ liệu mất khi đóng cửa sổ, chẳng hạn bộ đếm giờ lưu chưa kịp chạy.
  - Binding vòng.
  - Giá trị `NaN` trong hoạt ảnh lò xo.
  - Chụp màn hình (ScreencopyView) khi cửa sổ đã biến mất; xem `SafeShot.qml` và `CaptureGate.js`.
- **Đối chiếu API với mã nguồn Quickshell 0.3.2.** Đã đối chiếu: `QsWindow.window`, `ScreencopyView`, `HyprlandFocusGrab`, `PanelWindow` với lớp và `mask`, `Hyprland.monitors`, `lastIpcObject`, `FileView` và `JsonAdapter`, `Process`.

### Lua của Hyprland 0.57 (`config/hypr/*.lua`)

- Tên tuỳ chọn được đối chiếu với `ConfigManager::luaConfigValueName` của Hyprland: `:` đổi thành `.`, còn `-` đổi thành `_`. Vì vậy `tap_to_click` là tên đúng.
- Lệnh `hl.dsp.*` dùng trong phím tắt và trong `hyprctl dispatch` đã đối chiếu với mã nguồn Hyprland.
- Cấu hình được chạy với một `hl` giả để chắc rằng mọi `require` đều nạp được.

### Script (`install.sh`, `config/hypr/scripts/`, `nvidia/`, `plymouth/`)

- **`nvidia/setup-nvidia.sh`**
  - Chạy với `--dry-run` cùng các biến giả `LG_LSPCI`, `LG_KERNELS`, `LG_MULTILIB`, `LG_INSTALLED`, `LG_MKINITCPIO`.
  - Đã thử các trường hợp: card Turing trở lên, Maxwell/Pascal/Volta, Kepler, máy lai Intel + NVIDIA, máy chỉ có NVIDIA, và kernel lts, zen hoặc nhiều kernel cùng lúc.
- **`theme-apps.sh`**: chạy trong một HOME tạm, kiểm tra tệp nó sinh ra.
  - Các lệnh đã thử: `all`, `gtk`, `qt`, `flatpak`, `folders <màu>`, `bookmarks`.
  - Đã thử cả khi thiếu `xdg-user-dir` và khi tên thư mục có dấu hoặc dấu cách.
- **`wallpaper.sh`, `capture.sh`, `gamemode.sh`**: đọc lại các chỗ dễ xảy ra tranh chấp hoặc đồng thời (khoá `flock`, dừng mpvpaper), kích thước chẵn cho ffmpeg, và cắt chuỗi UTF-8.
- **`plymouth/install-plymouth.sh`**: thử sửa dòng lệnh kernel trên bản sao của `/etc/default/grub` (nháy đơn và nháy kép) và của các mục systemd-boot.
- Mọi script sửa tệp hệ thống đều sao lưu trước khi sửa.

### Shader (`config/quickshell/shaders/`)

- Dịch bằng `qsb`, rồi chạy thật trong bản giả: kính lỏng, tan thành bụi. (Hiệu ứng thần đèn đã xoá ngày 2026-11-20.)
- Biến uniform không được trùng tên hàm có sẵn của GLSL. Lỗi `refract` đã gặp và đã sửa thành `refractAmt`.

### Giao diện ứng dụng (`theme/`)

- **GTK 4 / libadwaita**: mở Nautilus và hộp chọn tệp GTK 4 trên X11 với picom, chụp ảnh để so.
- **GTK 3**: xem trước giao diện `gtk3.css` trên Adwaita tối. Chưa xem được với adw-gtk3 (xem phần giới hạn).
- **Qt**: mở thử ứng dụng Qt 6 với qt6ct, bảng màu `qt-colors.conf` và `qt-liquid-glass.qss`.
  - qt6ct bỏ mọi thứ sau `//`, nên QSS không được chứa `//`.
  - Viền ngoài của menu phải vuông vì Qt không có nền trong suốt.

### SDDM (`sddm/liquid-glass/`)

- `Main.qml` được nạp với các đối tượng giả `sddm`, `userModel`, `sessionModel`, `keyboard` và `config`, có tên, vai trò và tín hiệu giống SDDM 0.21.
- Đã thử các tình huống: đăng nhập, sai mật khẩu, Caps Lock, đổi bàn phím, và các nút nguồn.
- Lỗi `TypeError … of null` chỉ hiện lúc thoát bản giả, do Python huỷ đối tượng giả trước cửa sổ. Lỗi này không có thật trong SDDM.

## Giới hạn đã biết (đã cân nhắc, chấp nhận, không cần báo lại)

- **Mật khẩu Wi-Fi** được truyền cho `nmcli` qua tham số dòng lệnh, nên người dùng khác trên cùng máy có thể thấy nó qua `ps` trong lúc nối. Với máy một người dùng thì chấp nhận được. Cách tránh là dùng tệp tạm cho `nmcli --ask`, nhưng cách này phức tạp hơn.
- **Bật/tắt chế độ chơi game** bấm liên tục có thể lệch trạng thái trong chốc lát, rồi tự đúng lại sau lần đọc `gamemode.sh status` kế tiếp.
- **Trang Ngày giờ**: bấm đổi khi lệnh trước chưa xong thì lệnh sau bị bỏ. Người dùng thấy giá trị không đổi và bấm lại.
- **Menu của ứng dụng Qt** đục và có góc ngoài vuông, vì Qt Widgets trên Wayland không có nền trong suốt cho menu.
- **Popover của GTK 3** đục, vì GTK 3 vẽ popover ngay trong cửa sổ nên Hyprland không làm mờ được.
- **Độ trong của kính** (blur, khúc xạ trên Wayland thật) chỉ xem được trên Hyprland thật. Bản giả chỉ ghép blur gần đúng.
- **Giao diện GTK 3 với adw-gtk3** chưa xem bằng mắt, vì không dựng được adw-gtk3 trong máy kiểm tra.
- **Kéo chạm mép** chưa có khung xem trước như macOS, vì Hyprland không báo vị trí con trỏ trong lúc kéo (không có sự kiện chuột cho Lua). Thả tay ra là cửa sổ vào chỗ.
- **Góc nóng** là một lớp 2 × 2 px ở góc: bấm đúng điểm ảnh ở góc màn hình sẽ trúng lớp đó thay vì cửa sổ. Lớp tự tắt khi có cửa sổ toàn màn hình, nên không vướng.
- **Chưa thử trên phần cứng thật**: cài driver NVIDIA, Plymouth lúc khởi động thật, SDDM thật, đèn bàn phím và đèn màn hình qua `brightnessctl` trên nhiều loại máy.

## Báo động nhầm (đừng "sửa")

- `tap_to_click` trong Lua là tên đúng (xem phần Lua ở trên). Đừng đổi thành `tap-to-click`.
- Thuộc tính kiểu `list<string>` trong QML không khớp các regex tìm thuộc tính đơn giản. Thuộc tính vẫn đúng.
- `Osd.qml`: cảnh báo "onConnectedChanged … no signal" chỉ có trong bản giả, vì ở đó Bluetooth là đối tượng JS đơn giản. `BluetoothDevice` thật của Quickshell có tín hiệu `connectedChanged`.
- `shellcheck` báo SC2016 với các lệnh `sh -c '… "$1" …'`. Đó là chủ ý: dữ liệu được truyền qua `$1` để tránh chèn lệnh. Mức `-S warning` không báo lỗi này.
- Trong bản giả, ô biểu tượng ứng dụng không sáng lên khi menu đang mở, vì Repeater chép đối tượng JS nên phép so `===` sai. Trên máy thật mỗi ứng dụng là một QObject nên phép so đúng.
- Lệnh `>` trong trình mở ứng dụng chạy thẳng `sh -c` với nội dung người dùng gõ. Đây là tính năng, không phải lỗ hổng.

## Nhật ký kiểm tra

### 2026-11-20 (tối, muộn): soát toàn bộ hiệu ứng chuyển động

- **Hyprland (`lg_look.lua`), đối chiếu mã nguồn 0.57.0:**
  - Mọi tên hoạt ảnh có trong `AnimationTree.cpp`. Mọi kiểu (`popin 90%`, `slide`, `slidevert`, `fade` cho layers) qua `styleValidInConfigVar` của `AnimationManager.cpp`.
  - `speed` ≤ 100. Lò xo có `stiffness`, `damping`, `mass` > 0,5 như `hl.curve` đòi.
  - Đã thử bằng Hyprland giả theo đúng các luật đó với tốc độ 0,7 / 1 / 1,4, khi tắt hiệu ứng và khi giá trị hỏng (0, chữ): không lỗi.
- **Lỗi tìm thấy và đã sửa:**
  - **Lò xo không theo tốc độ.** Đọc hyprutils (`AnimatedVariable.cpp`) thì thấy hoạt ảnh lò xo chạy theo thời gian thật, không dùng `speed`. Cửa sổ mở, đóng, di chuyển (lò xo "easy") vì vậy không đổi theo Nhanh / Chậm.
    - Sửa: chậm đi `s` lần thì `stiffness / s²` và `damping / s`, giữ nguyên độ nảy.
    - Mô phỏng: tới 99% mất ≈ 372 / 508 / 674 ms ở 0,7 / 1 / 1,4.
  - **Tắt Hiệu ứng chuyển động vẫn còn chuyển động.** Cửa sổ dẻo, mờ khi chuyển động và dải màu trôi của kính Cực quang (`aurora:speed`) vẫn chạy. Giờ tắt theo.
  - **Hiệu ứng của Quickshell không theo Cài đặt.** `Theme.fast` / `Theme.normal` là hằng số, nên tắt hiệu ứng hay đổi tốc độ thì các hiệu ứng `Behavior` vẫn chạy như cũ (khoảng 40 chỗ) và 12 chỗ ghi thẳng số ms.
    - Sửa: `Theme.motion`, `Theme.ms()`, `Theme.wait()` theo `animations` × `animScale`.
  - **Hẹn giờ đóng ngắn hơn hiệu ứng khi chạy chậm.** Ở tốc độ Chậm, các hẹn giờ chờ hiệu ứng (đóng bảng điều khiển 420 ms, đóng menu 160 ms, dock nảy 1400 ms) xong trước hiệu ứng, cắt ngang giữa chừng. Giờ nhân theo tốc độ.
    - Hẹn giờ chụp màn hình / menu nguồn chờ lớp mờ đi theo `layersOut` × tốc độ.
  - **Vòng lặp vô tận khi tắt hiệu ứng.** Chấm đỏ đang quay (vòng lặp vô tận) và dock nảy (3 vòng) sẽ thành vòng lặp 0 ms. Giờ không chạy khi tắt hiệu ứng; dock nảy dừng thì về 0.
  - Bụi tan của thông báo (900 ms) giờ cũng theo tốc độ.
- **Quay trong bản giả:** chạy chậm 6 lần rồi ghép lại đúng thời gian thật (khoảng 30–50 ms một khung), cả mở lẫn đóng. Đã quay 12 cảnh, thêm 1 cảnh ở tốc độ Chậm và 2 cảnh khi tắt hiệu ứng:
  - trung tâm điều khiển, bảng widget, launcher, menu nguồn, toàn cảnh;
  - menu chuột phải, menu khay, menu hệ thống;
  - thông báo, âm lượng ở đảo động, Alt + Tab, dock phóng to khi rê chuột.

  Không lỗi QML. Ở tốc độ Chậm, bảng trượt ra hết rồi mới ẩn; tắt hiệu ứng thì mở và đóng tức thì.
- **Giới hạn:** bản giả không có lớp làm mờ dần của Hyprland (layersIn/Out) và hiệu ứng cửa sổ. Launcher, menu nguồn trong bản giả biến mất ngay khi đóng; trên máy thật Hyprland làm mờ dần thêm khoảng 150 ms. Trong bản giả, Alt + Tab không đóng theo lệnh của bản giả (trên máy thật đóng khi nhả Alt).

### 2026-11-20 (tối): tường lửa ufw

- **Gói:** `ufw` 0.36.2 có trong `extra.db`. Đọc gói tải từ mirror:
  - `/etc/ufw/ufw.conf` (`ENABLED=no` lúc mới cài), `user.rules` và `/etc/default/ufw` đều quyền 644. Vì vậy Cài đặt đọc được tình trạng mà không cần `sudo ufw status`.
  - `ufw.service` chạy `ufw-init start` lúc khởi động.
  - `before.rules` sẵn có cho qua DHCP, mDNS (224.0.0.251:5353) và UPnP (239.255.255.250:1900); `before6.rules` cho qua mDNS IPv6 (ff02::fb, lấy từ mã nguồn ufw trên git.launchpad.net). Nhờ vậy vẫn dò thấy máy in trong mạng sau khi bật.
- **Mã nguồn ufw:**
  - Mỗi luật trong `user.rules` có dòng `### tuple ### <hành động> …` (`backend_iptables.py`); hành động là `allow`, `limit`, có thể kèm `_log`, nên đếm số cổng mở theo mẫu `(allow|limit)`.
  - `ufw enable` chỉ hỏi lại khi chạy qua SSH (`under_ssh`). Script và nút trong Cài đặt vẫn dùng `--force` cho chắc.
- **`setup-system.sh` phần 5:** chạy thử với `/etc` giả, ufw và systemctl giả, các trường hợp:
  - Bật: gọi đúng thứ tự `default deny incoming`, `default allow outgoing`, `--force enable`, rồi `systemctl enable --now ufw.service`.
  - Chạy lần hai: báo "đã bật", không gọi lại.
  - sshd đang bật: hỏi rồi `ufw allow ssh` trước khi bật tường lửa.
  - `--dry-run`: chỉ in lệnh, không gọi ufw.
  - firewalld đang chạy: giữ nguyên, không cài chồng.
- **`system-status.sh maint`:** in `fw=on|off|firewalld`, `ufwapp`, `fwrules`. Đã thử với `ufw.conf` và `user.rules` giả có một luật: ra `fw=on`, `fwrules=1`.
- **Cài đặt:** trang đổi tên thành *Bảo mật và sao lưu*, thêm nhóm *Tường lửa* (nút Bật / Tắt qua pkexec, một lần hỏi mật khẩu). Bản giả đúng cả lúc bật lẫn lúc tắt. Chuỗi "bật · chặn kết nối từ ngoài vào" bị cắt vì dài quá, nên rút còn "bật · chặn mọi kết nối vào" / "bật · mở N cổng".
- **Chưa thử trên máy thật:** bật ufw thật (cần iptables-nft trong kernel), truyền hình (cast) từ Edge lên TV khi tường lửa bật. Câu trả lời dò thiết bị qua SSDP có thể là gói unicast tới cổng ngẫu nhiên, không chắc qua được.

### 2026-11-20 (chiều): terminal, Claude Code, Microsoft Edge thay Firefox

- **Tên gói:** đối chiếu với `core.db` / `extra.db` tải từ mirror chính thức hôm nay: cả 123 gói trong `PKGS` đều có. Mới thêm: fish 4.9.3, starship 1.27.0, fastfetch 2.71.0, eza, bat, zoxide, fzf 0.75 (có `fzf --fish`), ripgrep, btop, tealdeer, man-db, man-pages, git, nano, ttf-cascadia-code. Đã bỏ `firefox`.
- **Microsoft Edge:** gói AUR `microsoft-edge-stable-bin` (lấy bằng `git clone` từ AUR, đọc PKGBUILD).
  - Tệp `.desktop` là `microsoft-edge.desktop`; lệnh `microsoft-edge-stable`.
  - Lệnh này đọc `~/.config/microsoft-edge-stable-flags.conf` bằng `$(cat …)` không có ngoặc kép, nên tệp cờ không được có dòng chú thích: script ghi đúng ba dòng cờ, không chú thích.
  - Bản Flathub (`com.microsoft.Edge`) chỉ dùng khi AUR không được; dock coi hai tên tệp này là một (Dock.qml `entryOf`).
  - Dock của bản cũ ghim `firefox`: Settings.qml đổi thành `microsoft-edge` khi đọc settings.json.
  - Chưa tìm được tuỳ chọn chính thức để Edge trên Linux bỏ ba nút tự vẽ của nó; README nói thẳng là nút thu nhỏ của Edge không có tác dụng.
- **Claude Code:** lệnh cài, chỗ cài (`~/.local/bin/claude`), yêu cầu tài khoản trả phí lấy từ tài liệu chính thức (code.claude.com). Không đăng nhập hộ. `~/.local/bin` vào PATH của fish (`fish_add_path`, cả khi không tương tác) và bash (`~/.bashrc`, chỉ thêm một lần).
  - Lối tắt `claude-code.desktop`: `desktop-file-validate` qua. Đọc `parseExecString` của Quickshell thì thấy nó coi cả `'` lẫn `"` là dấu mở/đóng chuỗi, nên dòng Exec không lồng ngoặc: gọi hàm fish `lg_claude`.
  - Đã thử `lg_claude` với fish thật (3.7), có và không có lệnh `claude` giả: chuyển về thư mục nhà, chạy claude; thiếu thì in lệnh cài.
- **kitty:** mọi tên tuỳ chọn trong `kitty.conf`, `glass-theme.conf` có trong `kitty/options/definition.py` của gói kitty 0.51.0 (tải từ mirror, chỉ đọc mã, không chạy). Giá trị đối chiếu với định nghĩa: `cursor_trail` tính bằng mili giây (đặt 200 để không vẽ vệt khi ứng dụng như Claude Code vẽ lại màn hình liên tục), `tab_bar_margin_height` hai số, `tab_bar_style separator`, `strip_trailing_spaces smart`. Có hàm `copy_or_interrupt` và `paste_from_clipboard`.
  - `tools/kiem-tra.sh` giờ soát tên tuỳ chọn kitty theo `tools/kitty-0.51-options.txt` (đã thử: thêm `cursor_trial` thì báo lỗi), cú pháp `.fish` bằng `fish --no-execute`, `.toml`, `.jsonc`.
- **Cài đặt → Giao diện → Terminal:** ghi `~/.config/kitty/lg-settings.conf` (phông, cỡ, độ đậm) rồi gửi SIGUSR1 cho kitty để kitty đọc lại cấu hình. `background_opacity` đổi được khi đọc lại vì `dynamic_background_opacity yes`. Bản giả: nhóm Terminal hiện đúng, không lỗi QML mới.
  - Geist Mono và Cascadia Mono: đọc bảng mã của tệp phông bằng fontTools, có đủ 104 chữ riêng của tiếng Việt (ă â đ ê ô ơ ư và các chữ có dấu nằm ngoài Latin-1, hoa và thường).
- **fish:** `fish -n` qua; chạy thật với lệnh giả: alias `ll` giữ `--time-style=+%d/%m/%Y %H:%M` là một đối số, lời chào chỉ hiện ở lần đầu, PATH có `~/.local/bin`.
- **starship.toml:** qua `config-schema.json` của starship v1.27.0 (đã thử khoá sai thì schema bắt được).
- **fastfetch:** qua `json_schema.json` của fastfetch 2.71.0; logo `arch_small`, các chỗ `{user-name}`, `{host-name}`, `{pretty-name}`, `{version}` có trong mã nguồn.
- **Chưa thử trên máy thật:** kitty, fish, Edge (gõ tiếng Việt trong Edge qua text-input-v3), bộ cài Claude Code trên Arch (tài liệu chính thức chỉ liệt kê Ubuntu, Debian, Alpine), Edge bản Flathub.

### 2026-11-20 (trưa, muộn): văn phòng, in ấn, USB, điểm khôi phục, zram, dọn gói

- **Tên gói:** đối chiếu với cơ sở dữ liệu gói `core.db` / `extra.db` tải từ mirror chính thức của Arch hôm nay.
  - Có đủ: libreoffice-fresh(-vi), cups, cups-pdf, cups-pk-helper, system-config-printer, avahi, nss-mdns, ipp-usb, hplip, gutenprint, sane, sane-airscan, simple-scan, exfatprogs, ntfs-3g, dosfstools, gnome-disk-utility, timeshift, cronie, grub-btrfs, inotify-tools, zram-generator.
  - Không có `hunspell-vi`, nên chưa có chính tả tiếng Việt.
- **Tên tệp:** đối chiếu với `extra.files`.
  - Tệp `.desktop`: `libreoffice-writer/calc/impress.desktop` (dùng cho ứng dụng mặc định), `system-config-printer.desktop`, `org.gnome.SimpleScan.desktop`, `org.gnome.DiskUtility.desktop`.
  - Lệnh: `timeshift-launcher`, `gnome-disks`.
- **Timeshift:** đối chiếu với mã nguồn (linuxmint/timeshift).
  - Các khoá của `timeshift.json` là những khoá `save_app_config` ghi.
  - Phần loại trừ dùng đúng mẫu mặc định cho thư mục nhà: `/root/**`, `/home/*/**`.
  - Kiểu Btrfs cần subvolume `@`.
  - Chạy `timeshift` một lần (bất kỳ lệnh nào) là nó tự ghi lịch cron vào `/etc/cron.d`.
  - Thẻ D để Timeshift tự xoá bản cũ.
  - Hộp chọn của polkit chỉ cho `timeshift-gtk` giữ DISPLAY, nên Timeshift chạy qua XWayland.
- **nsswitch:** sau khi sửa, dòng hosts khớp đúng mẫu của Arch wiki: `mymachines mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns`.
- **`setup-system.sh`:** chạy thử trong thư mục /etc giả (biến LG_*, lệnh giả), các trường hợp:
  - Btrfs `@` + GRUB + systemd-resolved đang bật;
  - ext4 trên LUKS + systemd-boot: điền đủ `parent_device_uuid`;
  - chạy lại lần hai: không sửa lại, không sao lưu thêm;
  - `--dry-run`: không ghi tệp nào.

  Kết quả: `timeshift.json` hợp lệ, script trong pacman hook qua `sh -n`.
- **`system-status.sh printers`:** thử với `lpstat` giả có máy đang in, máy sẵn sàng (mặc định) và máy đang tắt. Cả ba đều đọc đúng; script đặt `LC_ALL=C` để không vướng lpstat tiếng Việt.
- **Lệnh cần quyền quản trị trong Cài đặt** (pkexec rồi báo thông báo): đã thử với pkexec giả, cả khi thành công lẫn khi lỗi.
- **Bản giả:** trang Máy in và máy quét, Sao lưu và bảo trì, Giới thiệu không lỗi.
  - Trong bản giả, trang Máy in hiện "Chưa có máy in nào" thay vì "Dịch vụ in đang tắt". Lý do: `HOME` của bản giả khác, script không chạy, nên giữ giá trị mặc định. Đây là giới hạn của bản giả.
- **Chưa thử trên máy thật:**
  - máy in, máy quét thật;
  - Timeshift chụp và khôi phục thật;
  - grub-btrfs;
  - cửa sổ Timeshift (chạy bằng quyền root qua XWayland) có mở được trên Hyprland không. Nếu không mở được: `sudo -E timeshift-gtk` trong terminal.

### 2026-11-20 (trưa): phông chữ giống Windows

- Đã đếm bằng fontTools đủ 67 chữ tiếng Việt có dấu, cả hoa lẫn thường:
  - Open Sans (bản biến thiên của Google Fonts, giấy phép OFL) đủ hết;
  - Noto Sans đủ hết;
  - Selawik (phông mở của Microsoft thay Segoe UI) thiếu ơ, ư, ĩ, ũ và mọi chữ có dấu nặng, hỏi, ngã, nên không dùng.
- Segoe UI là phông có bản quyền của Microsoft, nên không đi kèm. Nếu máy có Segoe UI (`fc-list -q 'Segoe UI'`), Cài đặt hiện thêm lựa chọn này.
- Bản giả: danh sách phông hiện Open Sans đúng mặt chữ. Không lỗi.

### 2026-11-20 (trưa, sau): bốn công cụ đi kèm

- **wl-clip-persist**: chạy khi đăng nhập với `--clipboard regular`, theo README của công cụ. Không dùng `both`, để không đụng vùng chọn chuột giữa.
- **udiskie**: chạy khi đăng nhập với `--automount --notify --no-tray`, theo `udiskie/cli.py`. Thông báo đi qua máy chủ thông báo của Quickshell. Cài thêm `udisks2`.
- **hyprshutdown**: Khởi động lại, Tắt máy, Đăng xuất trong `Bar.qml` và `PowerMenu.qml` đều gọi lệnh chung `Controls.rebootCmd` / `poweroffCmd` / `logoutCmd`.
  - Tuỳ chọn đối chiếu với `src/main.cpp`: `-t` cho dòng chữ, `-p` cho lệnh chạy sau cùng. Mặc định chạy nền.
  - Máy chưa có hyprshutdown thì chạy lệnh cũ. Đã thử cả hai trường hợp với lệnh giả trong PATH: tham số đúng, chữ có dấu còn nguyên.
- **hyprsysteminfo** (AUR, install.sh hỏi): cửa sổ có class `hyprsysteminfo`, theo `src/main.cpp`; đã thêm luật cho nó nổi giữa màn hình. Mục *Giới thiệu máy này* mở công cụ này, chưa cài thì mở trang Giới thiệu; trang Giới thiệu có nút, tự tắt khi chưa cài.
- Kiểm tra tự động: không lỗi. Bản giả (trang Giới thiệu, menu hệ thống, menu nguồn, trung tâm điều khiển): không lỗi.
- **Chưa thử trên máy thật:** màn hình của hyprshutdown, udiskie khi cắm USB thật, wl-clip-persist với ảnh.

### 2026-11-20 (trưa): tám tính năng riêng của Hyprland 0.57

**Thêm**
- Kiểu kính của cửa sổ (biến thể blur), cửa sổ dẻo (`decoration.wobble`), mờ khi chuyển động (`decoration.motion_blur`).
- Bố cục cuộn ngang (`general.layout = "scrolling"`): vuốt 3 ngón ngang dùng `scroll_move` thay cho đổi workspace.
- Kính lúp: chụm 3 ngón (`cursor_zoom`, kiểu `live`) và ô trong trung tâm điều khiển. Ô này đổi mức bằng `hyprctl eval 'hl.config({ cursor = { zoom_factor = … } })'` và đặt lại mức sau sự kiện `configreloaded`.
- Terminal nhường chỗ (`misc.enable_swallow` cùng `swallow_regex`).
- Nhóm tab: thanh tab kính (`group.groupbar`); menu cửa sổ dùng `hl.dsp.group.toggle` / `next` và `hl.dsp.window.move` với `out_of_group`, `into_or_create_group`.
- Chia sẻ workspace là của XDPH 0.57, không cần cấu hình.

**Đối chiếu với mã nguồn Hyprland 0.57:** tên và kiểu của mọi tuỳ chọn trên, các giá trị biến thể blur (0 kawase, 1 frost, 6 prism, 8 acrylic, 9 aurora, 10 haze), các việc và hướng của cử chỉ (`pinch`, `scroll_move`, `cursor_zoom` với `mode = "live"`), tham số của các lệnh nhóm. `hl.config` gọi lúc chạy vẫn đặt giá trị và lên lịch làm mới.

**Công cụ mới:** `tools/kiem-tra-hypr.lua` với danh sách 398 tuỳ chọn, đã gắn vào `tools/kiem-tra.sh chay`.
- Đã thử: cố ý gõ sai `enable_swalow` thì công cụ báo lỗi.
- Cấu hình hiện tại: 89 khoá, không khoá nào sai, với cả cấu hình mặc định lẫn cấu hình bật hết các tính năng mới.

**Bản giả:** trang Giao diện (hàng nút kiểu kính), Màn hình nền và Dock, Touchpad, trung tâm điều khiển (ô Kính lúp, Cuộn ngang), menu cửa sổ có mục nhóm tab. Không lỗi.

**Chưa thử trên máy thật:** cảm giác của cửa sổ dẻo và cuộn ngang, kính lúp khi chụm 3 ngón, thanh tab nhóm trông thế nào.

### 2026-11-20 (sau): nút trên thanh tiêu đề

- Đã xác nhận trong mã nguồn Hyprland 0.57: yêu cầu thu nhỏ (`xdg_toplevel.set_minimized`) không được đọc tới, và `lg_rules.lua` chặn yêu cầu phóng to. Vì vậy hai nút đó trên thanh tiêu đề ứng dụng bấm không có tác dụng.
- Thêm: `theme-apps.sh buttons close-right|close-left|none` ghi `gtk-decoration-layout` vào `gtk-3.0/settings.ini` và `gtk-4.0/settings.ini`, kèm gsettings `org.gnome.desktop.wm.preferences button-layout`. Cài đặt → Giao diện có lựa chọn này; mặc định chỉ để nút đóng.
- Đã thử trong một HOME tạm:
  - giữ nguyên các khoá khác đã có trong `settings.ini`;
  - đọc đúng lựa chọn từ `settings.json`;
  - tệp mới không có dòng trống ở đầu.
- Đã xem bằng mắt `gtk3-widget-factory` (GTK 3) với bốn cách: mặc định (thu nhỏ, phóng to, đóng), `:close`, `close:`, `:`. Kết quả đúng như chọn.
- Chưa xem được GTK 4 trong máy kiểm tra (Nautilus không hiện trên Xvfb). GTK 4 đọc cùng khoá `gtk-decoration-layout`, và trên Wayland đọc gsettings qua xdg-desktop-portal-gtk.
- Sửa lỗi cũ: `theme-apps.sh` đọc `~/.config/quickshell/settings.json`, trong khi Cài đặt ghi `~/.config/liquid-glass/settings.json`. Hậu quả: `theme-apps.sh all` (chạy lại install.sh) luôn đặt màu thư mục tím, bỏ qua màu đã chọn.

### 2026-11-20: dùng được hoàn toàn bằng chuột

Đã rà từng phím tắt trong `lg_keybinds.lua` và thêm cách bấm chuột cho những việc trước đó chỉ làm được bằng phím. Bảng đối chiếu nằm trong README, mục *Không cần nhớ phím tắt*.

**Thêm mới**
- Menu hệ thống ở góc trái thanh trên (`Bar.qml`, `GlassMenu.qml`, `GlassMenuCard.qml`). Khởi động lại, tắt máy và đăng xuất phải bấm thêm một mục con mới làm.
- Menu cửa sổ khi chuột phải trong Toàn cảnh (`Overview.qml`) và trên dock → *Tuỳ chọn cửa sổ* (`Dock.qml`). Các mục do `WinOps.menuFor` tạo.
- Nút Ứng dụng ở cuối dock.
- Hàng nút chế độ trong launcher, nút × xoá mục bộ nhớ tạm, nút Esc bấm được.
- Ba mục mới trong menu chuột phải trên màn hình nền.

**Đã kiểm tra**
- Kiểm tra tự động không báo lỗi.
- Chạy trong bản giả các trạng thái: menu hệ thống và menu con xác nhận; menu cửa sổ trong Toàn cảnh và menu con *Đặt cửa sổ*; dock → *Tuỳ chọn cửa sổ*; launcher; cùng các màn hình cũ.
- Đặt cửa sổ từ menu gọi `hyprctl eval 'LG_snap(…)'`.
  - Đối chiếu với `src/ipc/s1/Commands.cpp` của Hyprland 0.57: `eval` chạy mã Lua tuỳ ý.
  - `hl.get_window` nhận chuỗi `address:0x…`.
  - Đã thử `LG_snap` trong Hyprland giả bằng Lua.
- Nút thu nhỏ trên thanh tiêu đề (GTK) chưa dùng được, đã đối chiếu với mã nguồn:
  - Hyprland 0.57 ghi lại yêu cầu `xdg_toplevel.set_minimized` nhưng không đọc tới;
  - chỉ yêu cầu từ thanh tác vụ (foreign-toplevel) mới phát sự kiện `minimized`;
  - vì vậy không thêm nút thu nhỏ vào thanh tiêu đề ứng dụng; thu nhỏ bằng menu cửa sổ.

**Sửa nhờ chạy thử:**
- Menu cửa sổ trong Toàn cảnh nằm chung lớp với ảnh cửa sổ, nên đã đổi sang nền gần đặc.
- Dòng nhắc trong launcher chồng lên hàng nút, đã bỏ.

**Báo động nhầm của bản giả:** menu trên dock tự đóng sau 0,9 giây vì bản giả không có chuột rê trên dock. Trên máy thật menu chỉ tự đóng khi chuột rời dock.

### 2026-11-19 (chiều): thêm tính năng học từ macOS

Thêm: biểu tượng ứng dụng trên thanh trên, xem nhanh bằng Space, đặt cửa sổ nhanh, góc nóng, màn hình đăng nhập kiểu macOS.

**Biểu tượng ứng dụng** (`Bar.qml`, `TrayMenu.qml`)
- API đối chiếu với mã nguồn Quickshell 0.3.2:
  - `SystemTray.items` và `SystemTrayItem`, gồm `activate`, `secondaryActivate`, `scroll`, `menu`, `onlyMenu`, `status`;
  - `QsMenuOpener.children` và `QsMenuEntry`, gồm `isSeparator`, `enabled`, `buttonType`, `checkState`, `hasChildren`, `triggered()`.
- Chạy trong bản giả với 4 ứng dụng: một ứng dụng không có biểu tượng (hiện chữ cái đầu), một ứng dụng cần chú ý (chấm cam), và menu có ô đánh dấu, mục tắt và menu con.

**Đặt cửa sổ** (`lg_snap.lua`)
- Đối chiếu với mã nguồn Hyprland 0.57:
  - các hàm `hl.dsp.window.float`, `resize`, `move`, `center`, `fullscreen` (vị trí tuyệt đối, nhận `window = "address:…"`), `hl.get_config` và `hl.get_cursor_pos`;
  - `hl.get_monitor_at_cursor` (`width`/`height` là điểm ảnh thật nên phải chia tỉ lệ; `reserved` theo đơn vị logic).
- Bắt chuột trái được kiểm tra trong `src/keybinds/Manager.cpp`:
  - lúc thả chuột, việc kéo kết thúc (`endDragTarget`) trước khi chạy phím tắt;
  - phím tắt `release` có `ignore_mods` thì khớp theo phím giữ lúc nhấn;
  - phải có `transparent` thì phím tắt Super + chuột trái (kéo cửa sổ) không che mất nó;
  - có `non_consuming` thì cú bấm vẫn tới ứng dụng.
- Chạy với một Hyprland giả bằng Lua: màn hình 2560×1600 tỉ lệ 1,25, thanh trên 60 px.
  - Đã thử: nửa màn hình, góc, lấp đầy, trả về, kéo chạm mép, kéo ra, bấm ở mép mà không kéo, đổi cỡ bằng mép trái, cửa sổ lưới.
  - Hai nửa cách nhau 16 px (2 × gaps_in + 2 viền), đúng như khi xếp lưới.

**Góc nóng** (`HotCorners.qml`, trang Cài đặt)
- Chạy trong bản giả, xem cả hai hướng mở danh sách.
- Bản giả bắt được lỗi `left`/`top` trùng thuộc tính có sẵn của Item; đã đổi tên.
- `misc:mouse_move_enables_dpms` và `key_press_enables_dpms` có trong Hyprland 0.57; giờ đã bật trong `lg_look.lua`.

**Xem nhanh**
- `sushi` 51 trên Arch (GTK 4) có mã ứng dụng `org.gnome.NautilusPreviewer`, theo tệp dịch vụ D-Bus và metainfo trong gói.

**SDDM** (`Main.qml`)
- Chạy với SDDM giả, một và hai người dùng, Caps Lock, sai mật khẩu.
- Bản giả bắt được lỗi `MouseArea anchors.fill` bên trong Column; đã sửa.

**Chưa thử trên máy thật:**
- kéo chạm mép trên Hyprland thật, cả khi kéo bằng thanh tiêu đề của ứng dụng;
- biểu tượng thật của Discord, Steam;
- sushi mở từ Nautilus.

### 2026-11-19: soát toàn bộ repo (sau commit 232b610)

Đã soát mọi tệp theo các bước ở trên, và tạo `tools/kiem-tra.sh` cùng mốc `docs/kiem-tra.sha256`. Kiểm tra tự động trên cả repo: không có lỗi.

Lỗi tìm thấy và đã sửa:

1. **Trang Cài đặt vẫn chạy khi đã đóng cửa sổ** (`SettingsApp.qml`). Đóng Cài đặt lúc đang ở trang Bluetooth thì máy cứ dò thiết bị mãi; đóng ở trang Wi-Fi thì cứ 15 giây quét mạng một lần, tốn pin. Sửa: chỉ giữ trang khi cửa sổ đang mở (`active: win.visible`).
2. **Đổi độ phân giải rồi đóng Cài đặt lúc đang đếm ngược "Giữ thay đổi?"** thì độ phân giải mới bị giữ luôn (`SettingsApp.qml`). Nếu màn hình không hiện được độ phân giải đó, người dùng không thấy gì để hoàn tác. Sửa: đóng trang lúc đang đếm thì tự trả về cấu hình cũ.
3. **Tìm tệp bằng `/` trong trình mở ứng dụng** (`Launcher.qml`):
   - gõ chữ bắt đầu bằng `-` thì `fd` hiểu thành tuỳ chọn;
   - gõ `.`, `(` hay `[` thì `fd` hiểu thành biểu thức chính quy.

   Sửa: thêm `--fixed-strings` và `--`.
4. **Ứng dụng Flatpak cài cho cả hệ thống không được đếm vào số bản cập nhật** (`Updates.qml`). Sửa: đếm cả `--user` lẫn `--system`, và lệnh cập nhật cập nhật cả hai.
5. **Tự làm tối màn hình gần như tắt hẳn đèn** (`Settings.qml`, `hypridle.conf`). `brightnessctl set 10` là mức thô của phần cứng; có máy tối đa tới 96000, nên 10 gần như bằng 0. Sửa: dùng `10%`.
6. **Chỉnh độ sáng nhầm thiết bị** (`Controls.qml`). Máy có cả đèn bàn phím thì `brightnessctl` không ghi `-d` có thể chỉnh đèn bàn phím. Sửa: tìm đúng thiết bị loại `backlight` và luôn ghi `-d`.
7. **Ghi chú nhanh có thể mất** khi đóng bảng widget trong vòng 0,6 giây sau khi gõ (`IslandDash.qml`). Sửa: ghi ngay khi bảng bị đóng.

### Trước đó: commit 3df2a58 "Soát lỗi ẩn"

Đã sửa:

- **MinimizeFx**: việc mới không còn huỷ nhầm việc cũ đang bàn giao.
- **SafeShot**: đổi thẳng từ cửa sổ này sang cửa sổ khác không còn dùng lại ảnh cũ.
- **Spring**: chặn NaN khi đích chưa tính được.
- **Glass**:
  - GIF được tính là hình nền động;
  - khung hình video không còn lệch khi đổi hình nền liên tiếp;
  - tên tệp có dấu cách hoặc `#` vẫn mở được.
- **Notifs**: thông báo bị ứng dụng rút lại được gỡ ngay.
- **Weather**: mất mạng lúc đăng nhập thì thử lại mỗi phút.
- **Switcher**: không còn chọn ra ngoài danh sách khi cửa sổ vừa đóng.
- **Dissolve**: chỉ chụp thẻ khi bắt đầu tan.
- **wallpaper.sh**:
  - khoá để không có hai mpvpaper chạy cùng lúc;
  - tắt được mpvpaper đang bị đóng băng;
  - video ngắn hơn 1 giây vẫn có ảnh thu nhỏ.
- **capture.sh**:
  - quay vùng có cỡ lẻ không còn lỗi bộ mã hoá;
  - cắt chữ theo ký tự.
- **install.sh**:
  - gói không còn trong kho không làm hỏng cả lần cài;
  - lỗi ở bước tuỳ chọn không dừng script.
- **install-plymouth.sh**:
  - GRUB dùng nháy đơn;
  - systemd-boot khi `/boot` chỉ root đọc được;
  - mục có nhiều dòng `options`;
  - ký tự đặc biệt trong tham số kernel.
