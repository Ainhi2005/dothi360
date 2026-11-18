# Đô Thị 360 — Flutter

Ứng dụng dành cho người dân và cán bộ xử lý sự cố đô thị.

## Cài đặt và chạy

```sh
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

Địa chỉ trên dùng cho Android emulator kết nối backend tại máy. Điện thoại thật cần địa chỉ backend truy cập được từ thiết bị.

## Kiểm tra và build bản demo trực tuyến

```sh
flutter analyze
flutter test
flutter build apk --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://dothi360.onrender.com/api/v1
```

APK tại `build/app/outputs/flutter-apk/app-release.apk`, chứa ARM32, ARM64 và x86_64. Cấu hình ký hiện tại dùng khóa debug cho demo nội bộ.

## Tổ chức mã nguồn

- `lib/core/`: cấu hình API, routing, theme, lưu phiên, push và widget chung.
- `lib/features/`: dữ liệu, provider/controller và giao diện theo chức năng.
- `assets/HaNoi/`, `assets/images/`: tài nguyên ứng dụng đang sử dụng.
- `test/`: kiểm thử model và widget.

Luồng tạo phản ánh hiện do `CreateReportController` điều phối upload, xác nhận AI và gửi API. Các lớp repository/usecase cũ không còn được ứng dụng dùng đã được loại khỏi nguồn.

Không đóng gói khóa Firebase Admin, khóa backend hoặc tệp `.env` riêng vào ứng dụng.
