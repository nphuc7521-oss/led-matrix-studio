# HƯỚNG DẪN ĐỒNG BỘ 3 BẢNG LED MA TRẬN HD-WF2 (64x32 RGB)

Dự án này cung cấp 2 giải pháp hoàn chỉnh để điều khiển đồng bộ 3 bảng LED HD-WF2 chỉ bằng **1 nút bấm**:
1. **Ứng dụng di động Flutter trên iOS** (`led_matrix_app/`)
2. **Kịch bản chạy tự động trên Windows** (`sync_3_boards.ps1`)

---

## 1. Cơ Chế Hoạt Động (Giải Mã Giao Thức Huidu HT)

- **Cổng kết nối:** TCP Port `6101` (Dữ liệu hiển thị)
- **Cấu trúc gói tin:**
  - Header: `0x48, 0x54, 0x00, 0x1F` (Magic `'HT'`)
  - Device GUID: 16 bytes định danh mạch
  - Command 30: Cài đặt thông số màn hình (`64x32 RGB`)
  - Command 19: Định nghĩa vùng hiển thị và nội dung văn bản
  - Command 2: Nạp dữ liệu font / bộ nhớ
  - Command 4: Kích hoạt hiển thị chương trình
  - Checksum: Thuật toán tổng cộng dồn 16-bit (`Sum16`)
  - Footer: `0xAA`

---

## 2. Ứng Dụng iOS (Flutter)

Thư mục: `d:\LAMVIEC\MẠCH ĐÈN LED MA TRẬN\led_matrix_app\`

### Tính Năng:
- Giao diện mô phỏng bảng LED 64x32 trực quan thời gian thực.
- Nhập văn bản tiếng Việt có dấu.
- Chọn 7 màu sắc LED chuẩn: Đỏ, Xanh Lá, Xanh Dương, Vàng, Xanh Lơ, Tím Hồng, Trắng.
- Hiệu ứng: Hiện ngay, Cuộn trái, Cuộn phải, Nhấp nháy.
- Thanh trượt điều chỉnh tốc độ chạy chữ.
- **Nút "GỬI ĐẾN CẢ 3 BẢNG":** Tự động chuyển qua lần lượt 3 WiFi của 3 mạch bằng `NEHotspotConfigurationManager` trên iOS mà không cần vào mục Cài đặt WiFi của iPhone.
- Trang cài đặt cho phép đổi SSID và Mật khẩu của từng mạch.

### Cách Chạy / Build Lên iPhone:
```bash
cd "d:\LAMVIEC\MẠCH ĐÈN LED MA TRẬN\led_matrix_app"
flutter pub get
flutter run
```

---

## 3. Chạy Nhanh Trên Laptop (PowerShell)

Để gửi nội dung tới mạch ngay trên laptop:
```powershell
powershell -ExecutionPolicy Bypass -File "d:\LAMVIEC\MẠCH ĐÈN LED MA TRẬN\sync_3_boards.ps1" -Text "HOANG PHUC" -Color "RED"
```
