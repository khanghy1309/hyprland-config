# Liquid Glass cho Arch + Hyprland

Đợt 1 dựng phần nền: Hyprland với hiệu ứng kính, thanh trên, launcher, hình nền (ảnh, GIF, video), terminal kitty và bộ gõ tiếng Việt.
Đợt 2 thêm đảo động, trình nhận thông báo, trung tâm điều khiển và bảng widget.
Đợt 3 thêm màn hình khóa, tự khóa khi rời máy, menu nguồn và màn hình đăng nhập.
Đợt 4 thêm toàn cảnh workspace, bảng phím tắt, bảng chụp và quay màn hình, đọc chữ trong ảnh, lịch sử bộ nhớ tạm và emoji trong launcher.
Đợt 5 thêm ứng dụng Cài đặt: chỉnh giao diện, hình nền, touchpad, Wi-Fi và thời tiết bằng chuột, không cần sửa file.

| Đợt | Nội dung | Trạng thái |
|---|---|---|
| **1** | Nền Hyprland, thanh trên, launcher, hình nền, kitty, bộ gõ | **có** |
| **2** | Đảo động, trung tâm điều khiển, bảng widget, thông báo | **có** |
| **3** | Màn hình khóa, tự khóa khi rời máy, menu nguồn, màn hình đăng nhập | **có** |
| **4** | Toàn cảnh workspace, bảng phím tắt, bảng chụp/quay, đọc chữ, bộ nhớ tạm và emoji | **có** |
| **5** | Ứng dụng Cài đặt | **có** |
| **+** | Màn hình khởi động Plymouth (hello → chữ ký) | **có** |
| **+** | Kính khúc xạ, chuyển động lò xo, chế độ chơi game | **có** |

Viết cho **Hyprland 0.57.2** (cấu hình bằng Lua) và **Quickshell 0.3.2**, là bản đang có trong kho Arch lúc soạn (12/11/2026). Mình đã kiểm tra cú pháp của mọi file và đối chiếu tên lệnh, tên tuỳ chọn với mã nguồn của hai phần mềm này, nhưng **chưa chạy thử trên một máy Arch thật**. Lần đầu khởi động có thể còn lỗi nhỏ; xem mục "Sự cố thường gặp".

---

## Cần có trước

- Arch Linux đã cài xong, đăng nhập được, có mạng.
- Tài khoản thường có quyền `sudo`.
- Card đồ hoạ Intel, AMD hoặc NVIDIA. Với NVIDIA, script cài đặt tự nhận card và cài đúng driver (xem *Card NVIDIA* bên dưới).

## Cài đặt

```bash
cd liquid-glass
./install.sh
```

Script hỏi trước mỗi bước cần `sudo`:

1. Cài khoảng 75 gói từ kho chính thức (gói có rồi thì bỏ qua).
2. Tuỳ chọn: cài `yay` và `mpvpaper` từ AUR để dùng hình nền video.
3. Sao lưu cấu hình cũ trong `~/.config/hypr`, `quickshell`, `kitty` sang `~/.config/liquid-glass-backup-<thời gian>/`, rồi chép cấu hình mới vào.
4. Cho ứng dụng GTK, Qt và Flatpak cùng bảng màu với Liquid Glass, đặt màu thư mục, thêm lối tắt ở thanh bên trình quản lý tệp (xem *Ứng dụng và thư mục* bên dưới).
5. Bật NetworkManager, bluetooth và power-profiles-daemon (cho công tắc tiết kiệm pin).
6. Máy có card NVIDIA: tự nhận đời card và cài driver hợp (không có card NVIDIA thì bỏ qua, không hỏi gì).
7. Cài theme đăng nhập vào `/usr/share/sddm/themes/liquid-glass` và bật SDDM nếu máy chưa dùng trình đăng nhập nào khác.
8. Tuỳ chọn: màn hình khởi động Plymouth.

### Card NVIDIA

`nvidia/setup-nvidia.sh` (install.sh tự gọi; chạy riêng được) đọc tên card rồi chọn driver theo đời card, đúng như Arch đang khuyên từ driver 590:

| Card | Driver |
|---|---|
| RTX 20 / GTX 16 trở lên (RTX 30, 40, 50…) | `nvidia-open` từ kho chính thức |
| GTX 750 tới GTX 10 (GTX 1060, 1050 Ti…), Titan V | `nvidia-580xx-dkms` từ AUR (driver mới không còn hỗ trợ các card này) |
| GTX 600/700 đời cũ hơn | giữ driver mở có sẵn; driver NVIDIA cho các card này không chạy được Hyprland |

Script còn:
- chọn bản driver hợp với kernel bạn dùng (`linux`, `linux-lts`, hay kernel khác thì bản dkms kèm header);
- cài bản 32-bit nếu bạn đã bật kho multilib (cho Steam);
- nạp driver ngay từ lúc khởi động, để màn hình khởi động và đăng nhập không bị đen (sửa `/etc/mkinitcpio.conf`, có sao lưu);
- máy bàn chỉ có card NVIDIA: bật giải mã video bằng card cho trình duyệt, trình xem video và hình nền video;
- laptop có cả card tích hợp: màn hình chạy bằng card tích hợp cho mát và đỡ tốn pin; chạy game bằng card rời với `prime-run <lệnh>` (Steam: thêm `prime-run %command%` vào Launch Options của game).

Xem trước script sẽ làm gì mà không đổi gì: `./nvidia/setup-nvidia.sh --dry-run`.

Đã cài bản trước rồi? Giải nén bản này đè lên thư mục cũ và chạy lại `./install.sh`. Script chỉ cài thêm gói còn thiếu, sao lưu cấu hình hiện tại rồi chép bản mới; `user.lua` của bạn được giữ nguyên.

Sau đó đăng xuất, chọn phiên **Hyprland** ở màn hình đăng nhập. Nếu đang ở màn hình chữ (TTY), gõ `start-hyprland`.

---

## Dùng hằng ngày

### Không cần nhớ phím tắt

Mọi việc đều bấm được bằng chuột hoặc touchpad, như trên Mac; phím tắt ở bảng dưới chỉ là đường tắt cho ai quen.

| Muốn | Bấm vào |
|---|---|
| Cài đặt, cập nhật, ngủ, khởi động lại, tắt máy, khóa, đăng xuất, buộc thoát ứng dụng | Nút giọt nước ở góc trái thanh trên (menu hệ thống, như menu quả táo). Khởi động lại, tắt máy, đăng xuất hỏi lại một bước trước khi làm |
| Mở ứng dụng | Biểu tượng trên dock, hoặc nút **Ứng dụng** (ô lưới) ở cuối dock, cạnh thùng rác |
| Tìm tệp, xem lịch sử bộ nhớ tạm, emoji, máy tính | Mở launcher (nút Ứng dụng trên dock) rồi bấm hàng nút *Ứng dụng · Tệp · Bộ nhớ tạm · Emoji · Máy tính · Lệnh* ở dưới. Mục bộ nhớ tạm có nút × để xoá khi rê chuột |
| Thu nhỏ, toàn màn hình, đặt cửa sổ sang trái / phải / lấp đầy, cho nổi, ghim, chuyển workspace, đóng | Chuột phải vào cửa sổ trong **Toàn cảnh**, hoặc chuột phải vào ứng dụng trên dock → *Tuỳ chọn cửa sổ* |
| Đặt cửa sổ nửa màn hình / lấp đầy | Kéo cửa sổ chạm mép màn hình (xem *Đặt cửa sổ nhanh*) |
| Toàn cảnh (mọi workspace) | Đưa chuột vào góc trên trái (góc nóng), vuốt 3 ngón lên, menu hệ thống, hoặc chuột phải trên màn hình nền |
| Chuyển workspace, chuyển cửa sổ sang workspace khác | Bấm số trên thanh trên; trong Toàn cảnh kéo cửa sổ sang ô khác |
| Wi-Fi, Bluetooth, âm lượng, độ sáng, chụp màn hình, chơi game | Bấm viên trạng thái bên phải thanh trên (trung tâm điều khiển) |
| Lịch, thời tiết, ghi chú | Bấm đồng hồ ở giữa thanh trên |
| Đổi hình nền, giao diện, xem bảng phím tắt, mở terminal | Chuột phải vào chỗ trống trên màn hình nền |
| Dừng quay màn hình | Bấm đảo động ở giữa thanh trên khi đang quay |

### Phím tắt

`Super` là phím Windows (hoặc Command).

| Phím | Việc |
|---|---|
| `Super + Enter` | Mở terminal |
| `Super + Space` | Mở launcher |
| `Super + E` / `Super + B` | Tệp / trình duyệt |
| `Super + W` | Bảng widget (lịch, thời tiết, ghi chú, tài nguyên) |
| `Super + N` | Trung tâm điều khiển và thông báo |
| `Super + Q` hoặc `Alt + F4` | Đóng cửa sổ |
| `Alt + Tab` | Chuyển cửa sổ (giữ Alt, bấm Tab để chọn, thả Alt để chuyển) |
| `Super + H` | Thu nhỏ cửa sổ xuống dock |
| `Ctrl + Shift + Esc` | Trình quản lý tác vụ |
| `Super + V` | Bật/tắt cửa sổ nổi |
| `Super + F` | Toàn màn hình |
| `Super + P` | Ghim cửa sổ (chuyển sang nổi rồi hiện trên mọi workspace) |
| `Super + ←↑↓→` | Chuyển giữa các cửa sổ |
| `Super + 1…9` | Đến workspace |
| `Super + Shift + 1…9` | Chuyển cửa sổ sang workspace |
| `Super + Ctrl + ←/→` | Workspace kế bên |
| `` Super + ` `` | Terminal thả xuống |
| `Super + kéo chuột trái / phải` | Di chuyển / đổi cỡ cửa sổ |
| `Super + Tab` | Toàn cảnh workspace |
| `Super + /` | Bảng phím tắt (gõ để lọc) |
| `Super + ,` | Cài đặt |
| `Super + D` | Hiện / ẩn dock |
| `Print` | Chụp toàn màn hình (lưu và chép vào bộ nhớ tạm) |
| `Super + Shift + S` | Bảng chụp và quay màn hình |
| `Super + Shift + T` | Đọc chữ trong một vùng, chép vào bộ nhớ tạm |
| `Super + Shift + R` | Dừng quay |
| `Super + Shift + V` | Lịch sử bộ nhớ tạm |
| `Super + Shift + C` | Lấy màu trên màn hình |
| `Super + Shift + W` | Đổi hình nền ngẫu nhiên |
| `Super + L` | Khóa màn hình |
| `Super + Esc` | Menu nguồn |
| `Super + Shift + Esc` | Thoát Hyprland ngay, không hỏi (dự phòng khi thanh trên bị lỗi) |
| `Ctrl + Space` | Đổi gõ Anh / Việt |

**Touchpad:** vuốt 3 ngón trái/phải để đổi workspace, vuốt 3 ngón xuống để mở terminal thả xuống, vuốt 4 ngón sang phải để mở bảng widget, sang trái để mở trung tâm điều khiển, vuốt 3 ngón lên để mở toàn cảnh.

**Launcher** (`Super + Space`):

| Gõ | Kết quả |
|---|---|
| tên ứng dụng | Tìm và mở ứng dụng |
| `=12*(3+4)` | Tính toán, Enter để chép kết quả |
| `>lệnh` | Chạy một lệnh |
| `/tên tệp` | Tìm tệp trong thư mục nhà, Enter để mở |
| `;chữ` | Lịch sử bộ nhớ tạm, Enter để chép lại, `Shift + Delete` để xoá một mục |
| `:tên` | Emoji, gõ tiếng Anh hoặc tiếng Việt không dấu (`:cuoi`, `:tim`, `:fire`), Enter để chép |

Dùng `↑ ↓` hoặc `Tab` để chọn, `Esc` để đóng.

**Thanh trên:** nút giọt nước ở góc trái mở menu hệ thống. Bấm số workspace để chuyển, cuộn chuột trên viên bên trái để đổi workspace. Bấm `VOL` để tắt/bật tiếng, cuộn chuột trên đó để chỉnh âm lượng. Bấm chỗ khác trên viên bên phải để mở trung tâm điều khiển.

**Biểu tượng ứng dụng trên thanh trên** (như menu bar extras của macOS): ứng dụng chạy nền (Discord, Steam, Telegram, trình quản lý mạng…) đặt biểu tượng trong một viên kính nằm bên trái viên trạng thái. Bấm để mở ứng dụng (ứng dụng chỉ có menu thì mở menu), chuột phải để mở menu của ứng dụng, chuột giữa cho việc phụ, cuộn chuột tuỳ ứng dụng. Menu là menu thật của ứng dụng, vẽ lại thành viên kính lỏng; mục có menu con thì bấm để đi vào, bấm hàng trên cùng để quay ra. Chấm cam ở góc biểu tượng nghĩa là ứng dụng cần bạn chú ý. Không có ứng dụng nào chạy nền thì viên này tự ẩn.

**Đảo động** (viên ở giữa thanh trên) tự đổi theo việc đang diễn ra, ưu tiên theo thứ tự:

1. Đổi âm lượng hoặc độ sáng: hiện thanh mức trong khoảng 1,5 giây.
2. Thông báo mới: hiện khoảng 5 giây; rê chuột vào thì giữ lại, bấm để mở trung tâm điều khiển, bấm × để xoá.
3. Tai nghe Bluetooth vừa kết nối: tên thiết bị và % pin (nếu tai nghe có báo pin).
4. Đang phát nhạc: ảnh bìa, tên bài, sóng âm. Bấm vào để mở rộng thành trình phát; rời chuột thì tự thu lại.
5. Đang quay màn hình: chấm đỏ và thời gian quay. Bấm vào để dừng.
6. Bình thường: ngày giờ. Bấm để đảo mở rộng thành bảng widget. Có chấm trắng nhỏ khi còn thông báo chưa xoá.

**Trung tâm điều khiển** (`Super + N`): công tắc Wi-Fi, Bluetooth, Không làm phiền, Tiết kiệm pin, Ánh sáng đêm, Micro, Chơi game, nút Chụp màn hình; thanh âm lượng và độ sáng (độ sáng chỉ hiện trên laptop); trình phát nhạc; danh sách thông báo. Khi bật Không làm phiền, thông báo vẫn được lưu nhưng không hiện lên đảo (trừ thông báo khẩn). Xoá một thông báo (hoặc *Xóa hết*) thì thẻ tan thành bụi bay lên.

**Chơi game** (trong trung tâm điều khiển): tắt làm mờ, bóng đổ và chuyển động của Hyprland, dừng hẳn hình nền video, chuyển máy sang chạy hết công suất. Bấm lần nữa là mọi thứ về như cũ. Lệnh tay: `~/.config/hypr/scripts/gamemode.sh on|off`.

**Bảng widget** (bấm vào đồng hồ trên đảo động, `Super + W`, hoặc vuốt 4 ngón sang phải): đảo động giãn ra thành một bảng kính ngay giữa phía trên, gồm giờ lớn và ngày, thời tiết (bấm vào để đặt vị trí), lịch tháng (mũi tên để xem tháng khác), trình phát nếu đang có nhạc, ghi chú nhanh tự lưu vào `~/notes/quick.md`, CPU/RAM/ổ đĩa. Bấm ra ngoài hoặc `Esc` để thu lại.

Đóng hai bảng bằng `Esc` hoặc bấm ra ngoài.

**Toàn cảnh** (`Super + Tab` hoặc vuốt 3 ngón lên): mỗi workspace là một ô thu nhỏ có ảnh các cửa sổ đúng vị trí. Bấm cửa sổ để sang cửa sổ đó, bấm chỗ trống để sang workspace, kéo cửa sổ sang ô khác để chuyển nó đi, rê chuột lên cửa sổ rồi bấm × để đóng. Ô cuối có dấu + là workspace mới, kéo cửa sổ vào đó để mở workspace mới cho nó. Bàn phím: `← →` chọn ô, `Enter` sang, `1…9` sang thẳng, `Esc` đóng.

**Chụp và quay** (`Super + Shift + S`): một thanh kính hiện ở cạnh dưới màn hình.
- Chọn việc: *Chụp ảnh*, *Quay video* hoặc *Đọc chữ*.
- Chọn vùng: *Vùng* (tự kéo khung), *Cửa sổ* (bấm vào một cửa sổ), *Cả màn hình*. Phím tắt `1 2 3`.
- Chụp ảnh có hẹn giờ 3 hoặc 10 giây, và tuỳ chọn mở ngay trình sửa ảnh Satty (vẽ, mũi tên, che thông tin) sau khi chụp. Không mở Satty thì thông báo hiện ra có nút *Sửa* nếu bạn đổi ý.
- Quay video có tuỳ chọn thu âm thanh máy hoặc micro. Lúc đang quay, đảo động hiện chấm đỏ; bấm vào đảo hoặc `Super + Shift + R` để dừng.
- `Enter` để bắt đầu, `Esc` để đóng.

Ảnh lưu ở `~/Pictures/Screenshots`, video ở `~/Videos/Screencasts`. Ảnh cũng được chép sẵn vào bộ nhớ tạm để dán ngay.

**Đọc chữ** (`Super + Shift + T`): kéo khung quanh chữ trên màn hình (ảnh, video, PDF dạng ảnh...), chữ đọc được nằm sẵn trong bộ nhớ tạm. Đọc được tiếng Việt có dấu và tiếng Anh; chữ càng to rõ càng chính xác.

**Dock** (cạnh dưới màn hình): ứng dụng ghim, rồi các ứng dụng đang chạy khác, rồi thùng rác. Chấm nhỏ dưới biểu tượng nghĩa là ứng dụng đang có cửa sổ.
- Bấm: mở ứng dụng, hoặc chuyển tới cửa sổ của nó. Bấm tiếp để chuyển vòng qua các cửa sổ của cùng ứng dụng.
- Bấm chuột giữa: mở thêm một cửa sổ mới.
- Chuột phải: danh sách cửa sổ, *Mở cửa sổ mới*, *Ghim vào Dock* / *Bỏ ghim*, *Đóng*. Chuột phải vào thùng rác để dọn sạch.
- Giữ và kéo một biểu tượng đã ghim sang trái/phải để đổi chỗ.
- **Ghim ứng dụng chưa mở:** trong launcher, chọn ứng dụng rồi bấm `Ctrl + P` (hoặc chuột phải vào nó); bấm lại để bỏ ghim. Hoặc vào Cài đặt → Màn hình nền và Dock, gõ tên ứng dụng ở ô *Thêm ứng dụng*. Trang đó cũng có nút ↑ ↓ để đổi thứ tự và *Bỏ ghim*.
- **Tự ẩn** (mặc định): dock lùi xuống khi có cửa sổ che chỗ của nó, nên cửa sổ vẫn dùng hết màn hình. Đưa chuột sát mép dưới màn hình (khoảng giữa) hoặc bấm `Super + D` để hiện lại. Workspace trống thì dock luôn hiện.
- **Thu nhỏ** (`Super + H`, hoặc chuột phải → *Tuỳ chọn cửa sổ* → *Thu nhỏ xuống dock*): cửa sổ biến khỏi màn hình ngay, không có hiệu ứng; bấm biểu tượng trên dock để mở lại.
- Đổi kích thước, tắt phóng to, tắt tự ẩn: Cài đặt → Màn hình nền và Dock.

**Đặt cửa sổ nhanh** (như macOS Sequoia/Tahoe và ứng dụng Rectangle): kéo cửa sổ (bằng thanh tiêu đề, hoặc `Super` + kéo chuột trái) cho con trỏ chạm mép màn hình rồi thả.
- Chạm mép trái hoặc phải: cửa sổ chiếm nửa màn hình bên đó. Chạm mép trên: lấp đầy màn hình. Kéo vào một góc: chiếm một phần tư màn hình ở góc đó. Mép dưới là chỗ của dock nên không làm gì.
- Kéo cửa sổ đã đặt ra chỗ khác: cửa sổ trở lại cỡ cũ.
- Phím tắt, giữ `Super + Alt` rồi bấm: `← → ↑ ↓` nửa màn hình, `U I J K` bốn góc, `D F G` một phần ba (trái, giữa, phải), `E T` hai phần ba, `Enter` lấp đầy, `C` ra giữa, `Backspace` trả cửa sổ về như trước khi đặt (về lại lưới nếu trước đó nó đang xếp lưới).
- Cửa sổ được đặt sẽ chuyển sang nổi; khoảng cách giữa hai cửa sổ cạnh nhau bằng khoảng cách khi xếp lưới. Khác macOS: lúc kéo chưa có khung xem trước, vì Hyprland không báo vị trí con trỏ trong lúc kéo; thả tay ra là cửa sổ vào chỗ.
- Tắt kéo chạm mép: Cài đặt → Màn hình nền và Dock → *Kéo cửa sổ chạm mép màn hình để đặt*.

**Góc nóng** (như Hot Corners của macOS): đưa chuột vào sát một góc màn hình là làm việc đã chọn cho góc đó: Toàn cảnh, Bảng widget, Trung tâm điều khiển, Launcher, Chụp màn hình, Khóa màn hình, Tắt màn hình. Mặc định chỉ góc trên trái mở Toàn cảnh. Chọn việc cho từng góc ở Cài đặt → Màn hình nền và Dock → *Góc nóng*. Con trỏ phải dừng ở góc khoảng 0,1 giây mới tính, nên lướt chuột qua không mở nhầm. Góc nóng tự tắt khi có cửa sổ toàn màn hình (xem phim, chơi game) hoặc khi bật Chơi game.

**Tính năng riêng của Hyprland** (Hyprland 0.57 có sẵn, chỉ cần bật):
- **Kiểu kính của cửa sổ** (Cài đặt → Giao diện → *Kính của cửa sổ*): Acrylic (mặc định, mép cong khúc xạ), Lăng kính (tách màu cầu vồng ở mép), Kính nhám (hạt li ti), Cực quang (dải màu chuyển động chậm phía sau, tốn máy hơn), Sương óng ánh, Mờ thường, Tắt.
- **Cửa sổ dẻo** (Cài đặt → Giao diện): kéo hoặc đổi cỡ cửa sổ thì nó rung rinh như thạch rồi đứng lại.
- **Mờ khi chuyển động** (Cài đặt → Giao diện): cửa sổ đang di chuyển có vệt mờ theo sau.
- **Bố cục cuộn ngang** (Cài đặt → Màn hình nền và Dock → *Bố cục cửa sổ*, hoặc ô *Cuộn ngang* trong trung tâm điều khiển): mỗi cửa sổ là một cột rộng nửa màn hình, xếp thành dải dài như niri. Vuốt 3 ngón ngang để lướt qua dải; lúc đó đổi workspace bằng thanh trên hoặc Toàn cảnh. Chỉ một cửa sổ thì nó chiếm cả màn hình.
- **Kính lúp**: phóng to quanh con trỏ, như Zoom trợ năng của macOS. Mở 3 ngón trên touchpad để phóng theo tay, chụm lại để thu về; hoặc bấm ô *Kính lúp* trong trung tâm điều khiển để đi qua các mức 1,5× → 2× → 3× → tắt.
- **Terminal nhường chỗ** (Cài đặt → Màn hình nền và Dock): mở một ứng dụng có cửa sổ từ terminal (ví dụ `loupe ảnh.png`) thì terminal tạm ẩn, ứng dụng hiện đúng chỗ đó; đóng ứng dụng thì terminal hiện lại.
- **Nhóm tab**: nhiều cửa sổ chung một khung, có thanh tab kính ở trên (bấm tab để chuyển, bấm chuột giữa để đóng). Tạo nhóm: chuột phải vào cửa sổ trong Toàn cảnh hoặc trên dock → *Tuỳ chọn cửa sổ* → *Gộp tab với cửa sổ cạnh*; hoặc *Gộp thành nhóm tab* rồi kéo cửa sổ khác thả vào thanh tab. Cùng menu đó có *Tab kế tiếp*, *Tách khỏi nhóm tab*, *Bỏ nhóm tab*.
- **Chia sẻ một workspace khi họp online**: lúc chia sẻ màn hình trên Meet, Zoom, Discord…, hộp chọn của Hyprland có thêm lựa chọn chỉ chia sẻ một workspace (thay vì cả màn hình hay một cửa sổ). Không cần bật gì.

**Cài đặt** (`Super + ,`, hoặc gõ "cài đặt" trong launcher): một cửa sổ kính, đổi gì là áp dụng ngay, không có nút Lưu.
- *Màn hình nền và Dock:* hiện / tự ẩn dock, phóng to biểu tượng, kích thước biểu tượng, bố cục cửa sổ (xếp ô / cuộn ngang), terminal nhường chỗ, đặt cửa sổ khi kéo chạm mép, góc nóng (một màn hình thu nhỏ, mỗi góc một nút chọn việc), ứng dụng ghim.
- *Giao diện:* kiểu kính của cửa sổ, cửa sổ dẻo, mờ khi chuyển động, nút trên thanh tiêu đề ứng dụng, phông chữ (Geist mặc định, Inter, Be Vietnam Pro, Onest; đều đủ dấu tiếng Việt), kính của cửa sổ (acrylic / mờ thường / tắt), kính của thanh trên, dock và các bảng (xem *Kính lỏng* bên dưới), độ mờ, độ đậm của các bảng kính, màu thư mục, bo góc, khoảng cách giữa cửa sổ, viền sáng, bóng đổ, tốc độ chuyển động, nhiệt độ ánh sáng đêm, thời gian hiện thông báo.
- *Hình nền:* bấm vào ảnh để đổi. Video và GIF có nhãn ở góc. Chọn lúc nào video tạm dừng (khi có cửa sổ toàn màn hình, khi có bất kỳ cửa sổ nào, hoặc không bao giờ), có dùng ảnh tĩnh khi chạy pin không, và hiệu ứng khi đổi ảnh.
- *Touchpad và bàn phím:* cuộn tự nhiên, chạm để bấm, tắt touchpad khi gõ, tốc độ cuộn và con trỏ, bật/tắt từng cử chỉ, tốc độ lặp phím (có ô gõ thử).
- *Wi-Fi:* bật/tắt, danh sách mạng xung quanh, bấm để kết nối (mạng có khoá thì hiện ô mật khẩu ngay bên dưới), quên mạng, ngắt kết nối.
- *Bluetooth:* bật/tắt, thiết bị đã ghép (kết nối, ngắt, quên, % pin), tìm và ghép thiết bị mới; ghép xong tự kết nối.
- *Âm thanh:* chọn loa / tai nghe / HDMI, chọn micro, âm lượng và tắt tiếng từng cái, âm lượng riêng của từng ứng dụng đang phát.
- *Màn hình:* độ phân giải, tần số quét, tỉ lệ 100–200%, bật/tắt và vị trí màn hình phụ (trái/phải/trên/dưới). Bấm *Áp dụng* xong, nếu không bấm *Giữ thay đổi* trong 15 giây thì tự quay lại như cũ (phòng khi màn hình đen).
- *Nguồn điện:* tiết kiệm pin / cân bằng / hiệu năng; sau bao lâu thì tắt màn hình, khóa, cho máy ngủ.
- *Ngày giờ:* tự đặt giờ qua mạng, kiểu 24 giờ hay 12 giờ, đổi múi giờ (tìm theo tên thành phố).
- *Ứng dụng mặc định:* mở web, thư mục, ảnh, video, nhạc, PDF, văn bản, tệp nén bằng ứng dụng nào.
- *Thời tiết:* gõ tên thành phố rồi chọn trong danh sách. Không cần tự tìm toạ độ nữa.
- *Giới thiệu:* tên máy, phiên bản Hyprland, Quickshell, kernel; kiểm tra cập nhật, mở kho ứng dụng.

Lựa chọn lưu ở `~/.config/liquid-glass/settings.json`. Phần của Hyprland được ghi ra `~/.config/hypr/lg_settings.lua` (đừng sửa tay file này, nó sẽ bị ghi đè; muốn chỉnh thêm thì dùng `user.lua`).

**Kính lỏng.** Thanh trên, dock, đảo động và các bảng không chỉ làm mờ phía sau: khi phía sau chỉ có hình nền, mép kính bẻ cong hình nền như nhìn qua tấm kính lồi thật, có tách màu nhẹ ở viền và vệt sáng ở mép trên. Khi có cửa sổ nằm sau, kính tự chuyển sang chỉ làm mờ cộng vệt sáng (shell chỉ có ảnh hình nền, không có ảnh của cửa sổ, nên không giả vờ khúc xạ cửa sổ). Hình nền sáng thì chữ trên thanh trên tự chuyển sang màu tối và đảo động đậm lại để chữ vẫn rõ. Hình nền video: mặc định chỉ có vệt sáng, vì kính chỉ có một khung hình tĩnh của video; bật *Khúc xạ cả hình nền video* nếu vẫn muốn. Máy yếu: chọn *Viền sáng* hoặc *Phẳng* trong Cài đặt → Giao diện.

**Chuyển động.** Đảo động, dock và trung tâm điều khiển chạy bằng lò xo: đổi ý giữa chừng (ví dụ thông báo tới khi đảo đang mở) thì đảo rẽ mượt sang cỡ mới thay vì giật. Giờ và tên bài hát đổi bằng hiệu ứng nhoè. Công tắc trong Cài đặt phồng thành viên kính khi gạt; thanh trượt phồng nhẹ khi kéo. Tắt hết: Cài đặt → Giao diện → Hiệu ứng chuyển động.

**Bảng phím tắt** (`Super + /`): toàn bộ phím tắt và cử chỉ, gõ để lọc (gõ không dấu cũng được). Nếu bạn đổi phím trong `lg_keybinds.lua`, sửa thêm `Cheatsheet.qml` cho bảng khớp.

---

## Ứng dụng và thư mục

Ứng dụng mở trong cửa sổ cũng dùng chung bảng màu với thanh trên và dock: nền kính tối, mục được chọn trắng đục chữ tối.

- **Ứng dụng GTK 4 / libadwaita** (Tệp, Lịch, hộp chọn tệp…): đổi màu theo Liquid Glass. Hình dáng nút giữ nguyên vì libadwaita không cho thay.
- **Xem nhanh bằng phím Space** (như Quick Look của macOS): trong trình quản lý tệp, chọn một tệp rồi bấm `Space` để xem ngay ảnh, PDF, video, nhạc, văn bản, mã nguồn, trang HTML; bấm `Space` lần nữa để đóng. Cửa sổ xem nhanh nổi giữa màn hình, cùng màu Liquid Glass. Video và ảnh: bấm đúp để phóng to. Do gói `sushi` (GNOME) làm.
- **Trình quản lý tệp (Nautilus):** thanh bên kính mờ, nhìn xuyên thấy hình nền như Finder; phần danh sách tệp vẫn nền đặc. Thanh bên có sẵn lối tắt Tài liệu, Tải về, Ảnh, Ảnh chụp màn hình, Hình nền, Dự án (chỉ thư mục nào có thật; đã có lối tắt riêng thì giữ nguyên).
- **Ứng dụng GTK 3** (GIMP, Inkscape…): theme adw-gtk3 tối cùng màu.
- **Ứng dụng Qt** (VLC, OBS, qBittorrent…): bảng màu tối Liquid Glass và bo tròn theo cùng kiểu (nút, ô nhập, danh sách, thẻ, thanh trượt, thanh tiến trình, thanh cuộn) qua qt6ct. Menu và danh sách xổ xuống giữ khung ngoài vuông, chỉ bo tròn từng mục, vì Qt không cho các cửa sổ nổi này trong suốt (bo góc ngoài sẽ lộ góc đen). Ứng dụng có theme riêng (như OBS) vẫn dùng theme của nó.
- **Ứng dụng Flatpak:** đọc được màu Liquid Glass (chỉ đọc), ứng dụng GTK 3 trong Flatpak có theme adw-gtk3 tối; áp cho cả ứng dụng cài sau này.
- **Nút trên thanh tiêu đề:** trên Hyprland, nút thu nhỏ và phóng to của ứng dụng bấm không có tác dụng (Hyprland bỏ qua hai yêu cầu đó), nên mặc định ứng dụng chỉ còn nút đóng. Chọn ở Cài đặt → Giao diện → *Nút trên thanh tiêu đề ứng dụng*: *Đóng bên phải*, *Đóng bên trái* (như macOS) hoặc *Ẩn hết*; mở lại ứng dụng để thấy. Áp cho ứng dụng GTK 3, GTK 4 / libadwaita, Firefox, Chromium và ứng dụng Flatpak. Thu nhỏ, toàn màn hình: chuột phải vào ứng dụng trên dock hoặc trong Toàn cảnh. Ứng dụng Qt không có thanh tiêu đề riêng trên Hyprland. Ứng dụng Electron tự vẽ nút (VS Code, Discord, Obsidian…): đổi trong cài đặt của từng ứng dụng, ví dụ VS Code đặt `"window.titleBarStyle": "native"`.
- **Màu thư mục:** Cài đặt → Giao diện → *Màu thư mục*, 12 màu (mặc định tím). Đổi là trình quản lý tệp đổi theo ngay.
- **Menu chuột phải kính lỏng:** menu của ứng dụng GTK (trình quản lý tệp, trình xem ảnh, GIMP…) nền hơi trong, Hyprland làm mờ phía sau, bo 14–16 px, mục được chọn là viên trắng như menu của dock. Menu của ứng dụng Qt vẫn nền đặc khung vuông (Qt không cho menu trong suốt); menu của Firefox, Chrome do trình duyệt tự vẽ.
- **Hộp Lưu / Mở tệp kính mờ:** dùng chung cho ứng dụng GTK, trình duyệt, ứng dụng Flatpak và cả ứng dụng Qt (qt6ct được đặt dùng hộp chung của hệ thống). Thanh bên trong hơn, danh sách tệp nền đặc cho dễ đọc. Các hộp thoại khác của ứng dụng GTK 3 cũng kính mờ theo.
- **Chuột phải trên màn hình nền:** menu kính lỏng hiện từ đúng chỗ con trỏ với Mở Terminal, Mở thư mục nhà, Đổi hình nền, Hình nền ngẫu nhiên, Giao diện, Chụp màn hình, Hiện/ẩn dock, Phím tắt.

CSS riêng của bạn: đặt trong `~/.config/gtk-4.0/gtk.css` (hoặc `gtk-3.0`), dưới dòng `@import`. Không thích thanh bên Nautilus trong suốt: thêm `window.view { background-color: #1b1d21; }` vào đó.

Chạy lại tay (sau khi cài thêm Papirus, Flatpak…): `~/.config/hypr/scripts/theme-apps.sh all`.

## Cho người quen Windows

- **Alt + Tab**, **Alt + F4**, **Ctrl + Shift + Esc** (Mission Center: xem CPU, RAM, ứng dụng nào đang chạy, tắt ứng dụng bị treo) dùng như trên Windows. `Super + Shift + S` cũng là chụp màn hình như Windows.
- **Thu nhỏ** (`Super + H`): cửa sổ biến khỏi màn hình nhưng vẫn chạy; biểu tượng trên dock vẫn có chấm. Bấm biểu tượng đó, hoặc chọn trong Alt + Tab, để hiện lại.
- **Ứng dụng có sẵn:** Firefox, Tệp (Nautilus), xem ảnh (Loupe), xem video và nghe nhạc (Celluloid), đọc PDF (Papers), soạn văn bản (Text Editor), máy tính bỏ túi, giải nén zip/rar/7z (File Roller), Mission Center.
- **USB, điện thoại, máy ảnh** cắm vào là hiện trong Tệp (điện thoại Android: chọn chế độ "Truyền tệp" trên điện thoại).
- **Tài liệu Word/Excel** từ máy Windows hiển thị đúng phông nhờ bộ phông Liberation (thay cho Arial, Times New Roman).
- **Cài phần mềm:** mở *Phần mềm* trong launcher (GNOME Software, lấy ứng dụng từ Flathub, như Microsoft Store).
- **Cập nhật:** máy tự kiểm tra mỗi 3 giờ. Có bản mới thì hiện thông báo và một ô trong trung tâm điều khiển; bấm *Cập nhật* để mở cửa sổ cập nhật (nhập mật khẩu khi được hỏi).
- **Lịch có âm lịch:** bảng widget hiện ngày âm dưới mỗi ngày, ngày nghỉ lễ màu đỏ, ngày lễ khác có chấm vàng. Bấm vào một ngày để xem âm lịch đầy đủ (ví dụ "mùng 5 tháng 10 năm Bính Ngọ") và tên ngày lễ. Âm lịch tính ngay trên máy, không cần mạng.

## Khóa màn hình, tự khóa, menu nguồn, đăng nhập

**Màn hình khóa** (`Super + L`) dùng hyprlock: nền là ảnh chụp màn hình lúc khóa được làm mờ, giờ lớn ở giữa, ảnh đại diện và ô mật khẩu ở dưới, pin và bố cục bàn phím ở hai góc. Gõ sai mật khẩu thì ô đổi màu và đếm số lần sai. Máy có cảm biến vân tay: bỏ dấu `#` ở phần `auth` trong `~/.config/hypr/hyprlock.conf` và cài `fprintd`.

**Tự khóa** (hypridle): mặc định làm tối màn hình lúc 4,5 phút, khóa lúc 5 phút, tắt màn hình lúc 5,5 phút, cho máy ngủ lúc 30 phút. Đổi trong Cài đặt → Nguồn điện; file `~/.config/hypr/hypridle.conf` do ứng dụng Cài đặt ghi lại.

Đang xem phim hoặc họp video thì không tự khóa (nếu ứng dụng báo cho hệ thống). Máy luôn khóa trước khi ngủ, kể cả khi gập màn hình laptop.

**Menu nguồn** (`Super + Esc`): Khóa (L), Đăng xuất (E), Ngủ (U), Ngủ đông (H), Khởi động lại (R), Tắt máy (S). Bấm chữ cái để chọn nhanh, hoặc `← →` rồi `Enter`. Mục được chọn sẵn là Khóa, để lỡ tay bấm Enter cũng không tắt máy. Ngủ đông chỉ chạy khi máy đã có phân vùng swap đủ lớn.

**Màn hình đăng nhập** (SDDM), bố cục như màn hình đăng nhập của macOS:
- Giữa phía trên: ngày ("Thứ Năm, 19 tháng 11") và giờ lớn.
- Giữa phía dưới: ảnh đại diện tròn, tên, ô mật khẩu dạng viên kính nhỏ. Gõ mật khẩu thì nút → hiện ở cuối ô; Caps Lock đang bật thì có dấu ⇪ trong ô. Gõ sai thì ô lắc ngang như trên Mac và báo "Sai mật khẩu".
- Máy có nhiều người dùng: ảnh đại diện xếp thành hàng, người đang chọn to hơn; bấm vào ảnh để đổi người.
- Dưới cùng: Ngủ, Khởi động lại, Tắt máy (nút tròn kính, nhãn bên dưới).
- Góc trên phải: phiên (khi có nhiều phiên) và bố cục bàn phím (khi có nhiều bố cục); bấm để đổi.
- Khối kính được làm mờ ngay trong theme vì lúc đăng nhập chưa có Hyprland. Chữ tự to nhỏ theo chiều cao màn hình.
- Thử theme mà không cần đăng xuất: `sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/liquid-glass`
- Ảnh đại diện: lưu một ảnh vuông thành `~/.face` rồi chạy lại `./install.sh`. Không có ảnh thì hiện chữ cái đầu của tên.
- Đổi ảnh nền hoặc phông: sửa `/usr/share/sddm/themes/liquid-glass/theme.conf` (cần `sudo`).

## Màn hình khởi động

Lúc bật máy, trên nền đen: chữ **hello** tự viết ra bằng nét sáng tím hồng, rồi từng đoạn nét trôi như chất lỏng từ trái sang phải và **biến thành chữ ký**; xong chữ ký sáng nhịp nhàng, có ba chấm chờ bên dưới. Máy có ổ đĩa mã hoá thì ô nhập mật khẩu hiện ngay dưới chữ ký. Lúc tắt máy hoặc khởi động lại: chữ ký hiện dần kèm dòng "Đang tắt máy…" / "Đang khởi động lại…".

Cài bằng `./install.sh` (bước 8) hoặc riêng: `./plymouth/install-plymouth.sh`. Script hỏi trước khi sửa `/etc/mkinitcpio.conf` và dòng lệnh kernel (GRUB, systemd-boot hoặc `/etc/kernel/cmdline`), và sao lưu từng file trước khi sửa.

- Xem thử không cần khởi động lại: `sudo plymouthd; sudo plymouth --show-splash; sleep 8; sudo plymouth --quit`
- Đổi chữ ký hoặc chữ hello: sửa danh sách điểm trong `plymouth/src/anim.html`, rồi chạy `node plymouth/src/render.js /tmp/khung` và `python3 plymouth/src/pack.py /tmp/khung plymouth/liquid-glass`, cập nhật số khung trong `liquid-glass.script` theo `layout.txt`, rồi cài lại.
- Gỡ: `sudo plymouth-set-default-theme -R bgrt`.

## Hình nền

Có sẵn ba hình nền trong `~/Pictures/Wallpapers`:
- `ridge.png`: núi lúc hoàng hôn (mặc định)
- `dem-anh-dao.jpg`: đêm trăng tím hồng, cành anh đào
- `dem-anh-dao.mp4`: bản động của `dem-anh-dao.jpg`, có hoa rơi, sao nhấp nháy, đồi lay nhẹ; video 16 giây lặp liền mạch

Đổi hình nền trong Cài đặt → Hình nền, hoặc chạy `~/.config/hypr/scripts/wallpaper.sh ~/Pictures/Wallpapers/dem-anh-dao.mp4`. Muốn sửa màu, số cánh hoa…: mở `wallpapers/src/dem-anh-dao.html`, rồi vẽ lại bằng `node wallpapers/src/render.js 3840 2160 out.png` và `node wallpapers/src/video.js 2560 1440 30 out.mp4` (cần Node, Playwright và ffmpeg).

Bỏ ảnh (`.png`, `.jpg`, `.webp`), ảnh động (`.gif`) hoặc video (`.mp4`, `.webm`, `.mkv`) vào `~/Pictures/Wallpapers`, rồi:

```bash
~/.config/hypr/scripts/wallpaper.sh ~/Pictures/Wallpapers/tên-tệp.mp4
```

hoặc bấm `Super + Shift + W` để chọn ngẫu nhiên. Hình nền được nhớ lại cho lần đăng nhập sau.

- Ảnh và GIF dùng `awww`, chuyển ảnh bằng hiệu ứng mờ dần.
- Video dùng `mpvpaper` (cài ở bước 2). Video không có tiếng, tự lặp, **tự tạm dừng khi bị che hoặc khi có cửa sổ toàn màn hình**. Hình nền video vẫn tốn pin hơn ảnh tĩnh vì lớp kính phải làm mờ lại liên tục, nên khi dùng pin bạn nên chuyển về ảnh tĩnh.

---

## Tuỳ chỉnh

- **Chỉnh riêng cho mình:** viết vào `~/.config/hypr/user.lua`. File này nạp sau cùng và không bị script cài đặt ghi đè. Ví dụ đổi bố cục bàn phím:
  ```lua
  hl.config({ input = { kb_layout = "us,vn" } })
  ```
- **Phần lớn lựa chọn hằng ngày** (kính, bo góc, touchpad, hình nền, thời tiết...): dùng ứng dụng Cài đặt (`Super + ,`).
- **Kính của cửa sổ, chi tiết hơn:** `~/.config/hypr/lg_look.lua`, phần `blur` và `acrylic` (độ khúc xạ, tách màu ở mép...).
- **Màu, phông của thanh trên, đảo động, các bảng:** `~/.config/quickshell/Theme.qml`.
- **Nơi lưu ghi chú nhanh:** `~/.config/quickshell/Config.qml`.
- **Độ trong của terminal:** `background_opacity` trong `~/.config/kitty/kitty.conf`.
- **Ứng dụng mặc định** (terminal, trình duyệt, trình quản lý tệp): `~/.config/hypr/lg_programs.lua`.

Sửa file nào thì Hyprland và Quickshell tự tải lại, không cần đăng xuất.

---

## Sự cố thường gặp

**Góc màn hình hiện thông báo lỗi đỏ.** Đó là lỗi trong cấu hình Hyprland, thông báo ghi tên file và dòng. Gửi nguyên văn thông báo cho mình để sửa. Trong lúc chờ, các phím tắt cơ bản vẫn dùng được.

**Không thấy thanh trên.** Mở terminal (`Super + Enter`) và chạy `qs`. Lỗi của Quickshell sẽ in ra ngay trong terminal.

**Thông báo không hiện lên đảo động.** Một trình thông báo khác (mako, dunst, swaync) đang giữ chỗ. Gỡ nó rồi chạy lại `qs`.

**Ứng dụng Flatpak vẫn sáng / khác màu.** Chạy `~/.config/hypr/scripts/theme-apps.sh flatpak` (cần mạng để tải theme adw-gtk3 bản Flatpak), rồi mở lại ứng dụng. Ứng dụng Qt/KDE trong Flatpak không đọc qt6ct nên giữ màu riêng của chúng.

**Máy NVIDIA: màn hình đen sau khi đăng nhập hoặc sau khi cập nhật.** Bấm `Ctrl + Alt + F3` để sang màn hình chữ, đăng nhập, rồi chạy `nvidia-smi`. Báo lỗi hoặc không thấy tên card nghĩa là driver chưa chạy: chạy lại `./nvidia/setup-nvidia.sh` rồi khởi động lại. Card GTX 10 trở về trước mà đang cài `nvidia-open` thì đó là lý do: script sẽ đổi sang nhánh 580.

**Máy NVIDIA: video trong trình duyệt giật, quạt kêu to.** Chạy `vainfo` (gói `libva-utils`); thấy dòng `NVDEC` là giải mã video bằng card đã chạy. Laptop lai thì video dùng card tích hợp, như vậy là đúng.

**Công tắc Tiết kiệm pin không bấm được.** Kiểm tra dịch vụ: `systemctl status power-profiles-daemon`.

**Không có sóng âm.** Cần gói `cava`; sóng âm chỉ chạy khi đang phát nhạc.

**Kính trông phẳng, không có vệt sáng / thu nhỏ không có hiệu ứng.** Shader chưa dựng được cho bản Qt trên máy. Cài `qt6-shadertools` rồi chạy `~/.config/quickshell/shaders/build.sh`. Chạy `qs` trong terminal sẽ thấy dòng `[glass] shader:` hoặc `[thu nhỏ]` nếu còn lỗi.

**Máy giật khi mở bảng.** Cài đặt → Giao diện → Kính của thanh trên, dock, bảng → *Viền sáng* (hoặc *Phẳng*).

**Màn hình giật khi kéo cửa sổ.** Đổi `variant = 8` thành `variant = 0` trong `lg_look.lua`, hoặc giảm `passes` từ 3 xuống 2.

**Không gõ được tiếng Việt.** Chạy `fcitx5-configtool`, kiểm tra Unikey có trong danh sách bộ gõ. Đổi Anh/Việt bằng `Ctrl + Space`.

**Ứng dụng Qt không có giao diện tối.** Chạy `qt6ct`, chọn kiểu `Fusion` và bảng màu tối.

**Màn hình khóa bị lỗi, không mở được.** Bấm `Ctrl + Alt + F2` để sang màn hình chữ, đăng nhập, rồi chạy `loginctl terminate-user $USER`. Lệnh này kết thúc phiên làm việc (việc chưa lưu sẽ mất), sau đó đăng nhập lại bình thường.

**Màn hình đăng nhập hiện theme mặc định.** Kiểm tra có file `/etc/sddm.conf.d/10-liquid-glass.conf` và lệnh `sddm-greeter-qt6` tồn tại. Nếu SDDM báo thiếu greeter Qt 6 thì nó tự quay về theme mặc định.

**Toàn cảnh chỉ hiện biểu tượng, không có ảnh cửa sổ.** Một số ứng dụng chạy qua XWayland hoặc cửa sổ vừa mở chưa chụp được; đóng rồi mở lại toàn cảnh. Nếu không cửa sổ nào có ảnh, chạy `qs` trong terminal để xem lỗi.

**Quay màn hình không được.** Xem lỗi trong `$XDG_RUNTIME_DIR/wf-recorder.log`. Nếu lỗi ở phần âm thanh, chọn *Âm thanh: Không* rồi thử lại.

**Đọc chữ ra sai nhiều.** Phóng to chữ trên màn hình rồi chụp lại; tesseract đọc chữ nhỏ hoặc chữ trên nền nhiều hoa văn kém.

**Đổi trong Cài đặt mà cửa sổ không đổi theo.** Kiểm tra `~/.config/hypr/lg_settings.lua` đã có nội dung, rồi chạy `hyprctl reload`. Nếu góc màn hình báo lỗi ở file đó, xoá file đi và mở lại Cài đặt, nó sẽ được ghi lại.

**Wi-Fi trong Cài đặt không hiện mạng nào.** Kiểm tra NetworkManager đang chạy: `systemctl status NetworkManager`. Mạng doanh nghiệp (cần tên đăng nhập) thì dùng nút *Cài đặt mạng nâng cao*.

**Video hình nền không có ảnh thu nhỏ.** Cần gói `ffmpeg`; bấm *Tải lại danh sách* sau khi cài.

**Muốn quay về cấu hình cũ.** Chép lại từ `~/.config/liquid-glass-backup-<thời gian>/` vào `~/.config/`.

---

## Cấu trúc thư mục

```
config/
  hypr/
    hyprland.lua      điểm vào, nạp các file lg_*
    lg_programs.lua   ứng dụng mặc định
    lg_monitors.lua   màn hình
    lg_env.lua        biến môi trường, bộ gõ
    lg_gpu.lua        biến riêng cho card NVIDIA (do nvidia/setup-nvidia.sh ghi, chỉ có trên máy NVIDIA)
    theme/            giao diện cho ứng dụng: gtk4.css, gtk3.css, qt-colors.conf, qt-liquid-glass.qss + qt/*.svg (theme-apps.sh chép đi)
    lg_look.lua       kính, bo góc, bóng, chuyển động
    lg_input.lua      bàn phím, touchpad, cử chỉ
    lg_rules.lua      quy tắc cửa sổ và lớp
    lg_keybinds.lua   phím tắt
    lg_snap.lua       đặt cửa sổ nhanh: kéo chạm mép, Super + Alt + …
    lg_autostart.lua  chạy khi đăng nhập
    lg_settings.lua   do ứng dụng Cài đặt tự ghi (không sửa tay)
    hyprlock.conf     màn hình khóa
    hypridle.conf     tự khóa khi không dùng máy
    scripts/wallpaper.sh, capture.sh, vndate.sh, battery.sh, gamemode.sh, theme-apps.sh
  quickshell/
    shell.qml         điểm vào
    Theme.qml         màu, phông, kích thước
    Config.qml        giá trị dùng chung (đọc từ Settings), nơi lưu ghi chú
    Settings.qml      đọc/ghi lựa chọn của ứng dụng Cài đặt
    SettingsApp.qml   ứng dụng Cài đặt
    GlassPill.qml     viên kính dùng chung (vẽ bằng shaders/glass.frag)
    Glass.qml         hình nền cho kính, cửa sổ nào nằm sau kính
    shaders/          glass.frag (kính), dust.frag (tan thành bụi), build.sh
    Spring.qml        chuyển động lò xo
    MorphText.qml     chữ đổi bằng hiệu ứng nhoè
    LiquidSwitch.qml  công tắc kính lỏng
    Dissolve.qml      thẻ tan thành bụi
    DesktopMenu.qml   menu chuột phải trên màn hình nền
    TrayMenu.qml      menu kính lỏng của biểu tượng ứng dụng trên thanh trên
    GlassMenuCard.qml thẻ menu kính lỏng dùng chung (menu hệ thống, menu cửa sổ), có menu con
    GlassMenu.qml     cửa sổ chứa thẻ menu, mở dưới thanh trên
    HotCorners.qml    góc nóng
    SafeShot.qml, CaptureGate.js   chụp cửa sổ an toàn (tránh làm sập shell)
    Icon.qml, Icons.qml   biểu tượng nét mảnh
    SysStats.qml      đọc CPU, RAM
    Bar.qml           thanh trên
    Island.qml        đảo động
    Notifs.qml        nhận thông báo
    Media.qml         trình phát nhạc, sóng âm (cava.conf)
    Osd.qml           sự kiện âm lượng, độ sáng, tai nghe
    Controls.qml      Wi-Fi, Bluetooth, âm thanh, độ sáng, ánh sáng đêm
    Panels.qml        lớp chứa hai bảng trượt
    IslandDash.qml    bảng widget trong đảo động
    ControlPane.qml   trung tâm điều khiển
    Weather.qml       thời tiết
    Tile.qml, GlassSlider.qml, MediaCard.qml, NotifCard.qml
    Launcher.qml      trình chạy nhanh
    Switcher.qml      Alt + Tab
    Updates.qml       kiểm tra cập nhật
    lunar.js          âm lịch và ngày lễ
    WinOps.qml        thu nhỏ / hiện lại cửa sổ
    Dock.qml          dock ở cạnh dưới
    PowerMenu.qml     menu nguồn
    Overview.qml      toàn cảnh workspace
    Capture.qml       bảng chụp và quay
    Recorder.qml      theo dõi lúc đang quay
    Cheatsheet.qml    bảng phím tắt
    emoji.tsv         danh sách emoji cho launcher
  applications/
    liquid-glass-settings.desktop   mục "Cài đặt" trong launcher
  kitty/
    kitty.conf, glass-theme.conf
sddm/liquid-glass/   theme màn hình đăng nhập (Main.qml, GlassBox.qml...)
nvidia/setup-nvidia.sh   nhận card NVIDIA và cài đúng driver
fonts/               Geist, Geist Mono, Be Vietnam Pro, Onest (giấy phép SIL OFL)
wallpapers/ridge.png  hình nền mặc định (4K)
tools/kiem-tra.sh    sổ kiểm tra: tệp nào đổi từ lần soát trước, kiểm tra tự động
docs/KIEM-TRA.md     đã kiểm tra những gì, bằng cách nào, giới hạn đã biết
install.sh
```

Sửa repo xong, chạy `tools/kiem-tra.sh` để biết tệp nào cần soát lại và `tools/kiem-tra.sh chay` để kiểm tra tự động; cách làm và kết quả các lần soát trước ở `docs/KIEM-TRA.md`.

## Ghi công

Kính khúc xạ, chuyển động lò xo, chữ nhoè, công tắc kính, thẻ tan thành bụi, chụp cửa sổ an toàn và chế độ chơi game học cách làm từ [MacShell](https://github.com/0-ss/MacShell) của Rickky (giấy phép MIT). Mã ở đây được viết lại cho repo này; chỗ nào học ý tưởng đều ghi trong chú thích đầu tệp.
