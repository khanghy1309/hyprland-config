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
| `*.lua` (cấu hình Hyprland) | `luac -p` | Chỉ kiểm cú pháp. Tên tuỳ chọn thì xem phần kiểm tra bằng tay. |
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
  - Đã chụp từng trạng thái: màn hình nền, dock, Alt+Tab, trình mở ứng dụng, tổng quan, bảng điều khiển, bảng widget, thông báo, OSD, menu nguồn, chụp màn hình, bảng phím tắt, menu chuột phải, hiệu ứng thần đèn, và từng trang Cài đặt.
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

- Dịch bằng `qsb`, rồi chạy thật trong bản giả: kính lỏng, thần đèn, tan thành bụi.
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
