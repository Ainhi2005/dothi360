# Đô Thị 360

Hệ thống phản ánh sự cố đô thị tích hợp AI.

- `BE/`: API Express, TypeORM và PostgreSQL/PostGIS.
- `Admin_FE/`: giao diện quản trị React.
- `FE/`: ứng dụng Flutter.

## Chạy tại máy

1. Sao chép `BE/.env.example` thành `BE/.env`, điền cấu hình riêng và chuẩn bị PostgreSQL/PostGIS.
2. Cài dependency bằng `npm ci` trong `BE` và `Admin_FE`.
3. Chạy `npm run dev` trong từng thư mục trên.
4. Trong `FE`, chạy `flutter pub get`, rồi `flutter run` với `API_BASE_URL` phù hợp thiết bị.

Schema hiện hành: `BE/src/database/schema.current.sql`. Chỉ nhập snapshot vào database trống; không chạy lại toàn bộ migration lịch sử sau khi nhập snapshot mà chưa đối chiếu baseline.

## Triển khai Render và Neon

`render.yaml` khai báo một dịch vụ chạy API và Admin trên cùng tên miền. Render build bằng `node scripts/build-render.cjs`, sau đó chạy `cd BE && npm start`.

Tạo database Neon có PostGIS và nhập schema/dữ liệu trước khi khởi động dịch vụ. Điền `DATABASE_URL`, thông tin Cloudinary, Gemini và Firebase trong phần biến môi trường của Render; không đưa khóa riêng vào Git. Kết nối database dùng SSL và kiểm tra chứng chỉ.

Sau triển khai, kiểm tra `/api/v1/health`, đăng nhập Admin và các luồng nghiệp vụ. Chỉ build APK cuối khi đã có địa chỉ HTTPS hoạt động, truyền địa chỉ API bằng `--dart-define=API_BASE_URL=https://TEN-MIEN/api/v1` theo cấu hình ứng dụng.

## Kiểm thử backend

```sh
cd BE
npm test
npm run test:integration
```

Kiểm thử tích hợp cần database thử nghiệm đã chuẩn bị đúng schema. Tệp `.env`, khóa ký, thư mục build và dữ liệu làm việc không được đưa vào repository.
