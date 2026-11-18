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

Các công cụ triển khai tại máy:

- `node BE/scripts/bootstrap_neon.cjs`: chỉ kiểm tra kết nối từ `BE/.env.neon.local`.
- Thêm `--initialize` để khởi tạo snapshot và baseline 22 migration trong database Neon trống; thêm `--demo` để nhập bản demo đã ẩn danh từ `BE/scratch/demo-export/DuLieuDemo.sql`. Công cụ từ chối database đã có bảng. Mật khẩu demo ngẫu nhiên được lưu trong `BE/.env.demo.local` và yêu cầu đổi khi đăng nhập.
- `node BE/scripts/prepare_render_env.cjs`: tạo `BE/.env.render.local` để nhập vào Render, dùng cấu hình dịch vụ từ `.env`, kết nối Neon riêng và khóa Firebase tại `BE/scratch/firebase-admin.json` nếu cần. Không thay `.env` hiện tại.
- `node BE/scripts/verify_neon.cjs`: kiểm tra ORM và luồng đăng nhập Admin qua Express tại máy với database Neon; cần backend/Admin đã build và tệp tài khoản demo do bootstrap tạo. Đây chưa phải kiểm thử địa chỉ Render trực tuyến.

Tất cả tệp `.env.*.local` và `scratch/` bị Git bỏ qua. Không dùng lệnh revert để quay ngược các migration baseline của snapshot.

Sau triển khai, kiểm tra `/api/v1/health`, đăng nhập Admin và các luồng nghiệp vụ. Chỉ build APK cuối khi đã có địa chỉ HTTPS hoạt động, truyền địa chỉ API bằng `--dart-define=API_BASE_URL=https://TEN-MIEN/api/v1` theo cấu hình ứng dụng.

## Kiểm thử backend

```sh
cd BE
npm test
npm run test:integration
```

Kiểm thử tích hợp cần database thử nghiệm đã chuẩn bị đúng schema. Tệp `.env`, khóa ký, thư mục build và dữ liệu làm việc không được đưa vào repository.
