# HƯỚNG DẪN CÀI ĐẶT VÀ SỬ DỤNG ĐÔ THỊ 360

**Đề tài:** Hệ thống phản ánh sự cố đô thị tích hợp AI.  
**Sinh viên:** Ngô Thị Ái Nhi — Mã SV: 0020868 — Lớp: 68CNPM.  
**Ngày cập nhật:** 18/11/2026.  
**Phiên bản Android:** 1.0.1, mã bản dựng 2.

## 1. Thông tin sản phẩm

| Thành phần | Địa chỉ hoặc tệp bàn giao |
|---|---|
| APK Android | UngDung/DoThi360.apk |
| Trang Admin | https://dothi360.onrender.com/login |
| API | https://dothi360.onrender.com/api/v1 |
| Kiểm tra dịch vụ | https://dothi360.onrender.com/api/v1/health |
| Mã nguồn | https://github.com/Ainhi2005/dothi360 |
| Máy chủ API và Admin | Render, cùng tên miền HTTPS |
| Database trực tuyến | Neon PostgreSQL/PostGIS |
| Dữ liệu cài đặt riêng | Database/schema.sql và Database/DuLieuDemo.sql |

APK khoảng 57,84 MiB, tương đương 60,65 MB thập phân, hỗ trợ ARM32, ARM64 và x86_64. Dung lượng sau cài đặt còn phụ thuộc thiết bị và cache.

Người dùng trực tuyến chỉ cần APK hoặc trình duyệt, không cần cài Flutter, Node.js hay PostgreSQL. Máy tác giả không cần bật để phục vụ bản trực tuyến.

## 2. Điều kiện sử dụng

- Điện thoại Android 7.0/API 24 trở lên, kiến trúc tương thích, đủ dung lượng trống và có Internet.
- Không cần cùng Wi-Fi với tác giả khi dùng APK trực tuyến.
- Trang Admin dùng trình duyệt tương thích; nên thao tác trên máy tính.
- Người dân tự đăng ký; tài khoản cán bộ và Admin được cấp hoặc bàn giao riêng.
- Push cần quyền thông báo, token thiết bị hợp lệ và Google Play Services phù hợp.

APK không cài trực tiếp trên iPhone/iPad. Bản iOS chưa được đóng gói trong bộ sản phẩm. Trình duyệt iPhone có thể mở trang Admin với tài khoản phù hợp.

## 3. Cài đặt APK trên Android

### 3.1. Cài mới từ Zalo hoặc tệp bàn giao

1. Tải hết tệp DoThi360.apk về điện thoại.
2. Nhấn vào tệp; nếu Zalo không mở được, vào Tệp/Files/Tệp của tôi, chọn Tải xuống/Downloads rồi mở APK.
3. Nếu Android yêu cầu quyền cài từ nguồn này, mở Cài đặt theo thông báo, cho phép Zalo hoặc trình quản lý tệp đang mở APK, rồi quay lại.
4. Nhấn Cài đặt, chờ hoàn tất và chọn Mở. Tên mục có thể khác giữa các hãng.
5. Đăng ký tài khoản người dân hoặc đăng nhập bằng tài khoản được cấp.
6. Cho phép vị trí, camera/ảnh và thông báo khi chức năng tương ứng yêu cầu.

Chỉ cài tệp do tác giả bàn giao. Quyền cài APK khác với quyền thông báo, vị trí và ảnh của ứng dụng. Thiết bị có chính sách quản lý riêng cần thực hiện theo chính sách của thiết bị.

### 3.2. Cập nhật bản cũ

Tải APK mới, mở tệp và chọn Cập nhật/Cài đặt. Bản bàn giao hiện tại là 1.0.1, mã bản dựng 2. Nếu Android báo xung đột chữ ký hoặc không thể cập nhật, liên hệ người bàn giao để kiểm tra phiên bản trước khi cân nhắc gỡ bản cũ.

Gửi xong các phản ánh và lưu thông tin bản nháp cần giữ trước khi gỡ ứng dụng. Dữ liệu đã gửi thành công lên server vẫn nằm trong tài khoản; dữ liệu chỉ lưu trên điện thoại có thể mất khi gỡ. Phản ánh từng gửi vào backend local không tự xuất hiện trên Neon.

## 4. Đăng ký và đăng nhập

Người dân chọn Tạo tài khoản mới, nhập họ tên, email, số điện thoại, mật khẩu và xác nhận theo yêu cầu giao diện. Tự đăng ký tạo tài khoản người dân, không tự cấp quyền cán bộ hoặc Admin.

Cán bộ và Admin dùng tài khoản được cấp. Các email demo trực tuyến gồm admin@dothi360.example, officer@dothi360.example và citizen@dothi360.example; mật khẩu được bàn giao riêng. Mật khẩu trong bộ SQL demo không đại diện cho mật khẩu trực tuyến.

Nếu được yêu cầu đổi mật khẩu lần đầu, hoàn thành trước khi thao tác nghiệp vụ. Chức năng đổi mật khẩu yêu cầu mật khẩu mới tối thiểu 10 ký tự. Đăng xuất khi kết thúc trên máy dùng chung; không chia sẻ tài khoản Admin cho người chỉ cần thử chức năng người dân.

## 5. Hướng dẫn cho người dân

### 5.1. Gửi phản ánh

1. Mở chức năng tạo phản ánh, nhập mô tả hiện trạng, dấu hiệu nhận biết và ảnh hưởng.
2. Chụp hoặc chọn ảnh hiện trường, tối đa 5 ảnh; kiểm tra ảnh trước khi tiếp tục.
3. Chọn vị trí bằng định vị hoặc bản đồ/tìm kiếm; đối chiếu địa chỉ và tọa độ.
4. Phân tích ảnh, xem gợi ý AI và điều chỉnh loại, mức độ hoặc tóm tắt khi cần.
5. Xác nhận thông tin và gửi. Khi thay đổi thông tin liên quan, xác nhận lại theo yêu cầu của ứng dụng.
6. Đọc biên nhận để biết hồ sơ được tạo mới, gộp vào sự cố đang xử lý hoặc đã được chính người dùng phản ánh trước đó.

AI cung cấp gợi ý để người dùng kiểm tra. Khi nhà cung cấp lỗi hoặc nội dung cần kiểm duyệt, thực hiện theo thông báo và lựa chọn mà giao diện cung cấp.

### 5.2. Theo dõi và tiện ích

Mở Lịch sử, tìm phản ánh và xem mã hồ sơ, trạng thái, tiến độ, timeline cùng ảnh được phép hiển thị. Sau khi Admin chấp thuận nghiệm thu, hồ sơ chuyển sang đã giải quyết.

Sử dụng phần Thông báo để đối chiếu cập nhật. Push còn phụ thuộc thiết bị và dịch vụ; không nhận push không đồng nghĩa hồ sơ không có cập nhật.

Các mục bổ trợ gồm bản đồ sự cố, vùng quan tâm, góp ý, thông tin đô thị, hướng dẫn khẩn cấp và liên hệ khẩn cấp theo giao diện hiện có.

## 6. Hướng dẫn cho cán bộ

1. Đăng nhập APK bằng tài khoản cán bộ, mở danh sách nhiệm vụ được giao.
2. Đọc chi tiết và tiếp nhận; nếu không thể tiếp nhận, từ chối kèm lý do theo quy trình.
3. Bắt đầu xử lý, cập nhật tiến độ, ghi chú và minh chứng.
4. Hoàn thành các mục checklist bắt buộc trong workspace và lưu checklist.
5. Khi hoàn tất, gửi nghiệm thu kèm kết quả và ảnh minh chứng được upload cho lần gửi này.
6. Theo dõi quyết định Admin. Chờ nghiệm thu chưa đồng nghĩa đã giải quyết.
7. Nếu được yêu cầu làm lại, bổ sung xử lý/minh chứng và gửi lại; nếu được chấp thuận, hồ sơ được hoàn tất.

Khi không gửi được nghiệm thu, kiểm tra người tiếp nhận, trạng thái, checklist đã lưu, ghi chú và ảnh.

## 7. Hướng dẫn cho quản trị viên

Mở https://dothi360.onrender.com/login, đăng nhập tài khoản ADMIN và đổi mật khẩu nếu được yêu cầu.

### 7.1. Tiếp nhận và phân công

1. Kiểm tra danh sách hồ sơ, hàng chờ kiểm duyệt và thông báo.
2. Đối chiếu mô tả, ảnh, vị trí, loại và mức độ; xử lý các phản ánh cần kiểm duyệt.
3. Với hồ sơ chờ phân công, xem gợi ý hoặc chọn đơn vị/cán bộ phù hợp rồi xác nhận.
4. Theo dõi tiếp nhận, xử lý từ chối hoặc điều phối lại khi phát sinh.

### 7.2. Nghiệm thu

1. Mở hồ sơ chờ nghiệm thu từ danh sách hoặc thông báo.
2. Kiểm tra tiến độ, checklist, ghi chú và ảnh minh chứng.
3. Chấp thuận hoặc yêu cầu làm lại, kèm ghi chú.
4. Chấp thuận chuyển hồ sơ sang RESOLVED; yêu cầu làm lại đưa hồ sơ về xử lý để cán bộ bổ sung.
5. Nếu trạng thái đã thay đổi, tải lại hồ sơ trước khi quyết định tiếp.

Admin còn có các trang quản lý tài khoản, đơn vị, danh mục, checklist, góp ý và thống kê theo quyền. Thông báo Admin tải lại định kỳ; có thể cần chờ một nhịp cập nhật hoặc tải lại trang.

## 8. Phân biệt dữ liệu trực tuyến và local

| Nội dung | APK và Admin trực tuyến | Chạy tại máy phát triển |
|---|---|---|
| API | https://dothi360.onrender.com/api/v1 | Theo cấu hình local, thường cổng 3000 |
| Database | Neon | PostgreSQL theo BE/.env tại máy |
| Admin | Tên miền Render | Thường http://localhost:5173 |
| Dữ liệu | Không tự đồng bộ với local | Không tự đồng bộ với Neon |

Nhập schema và dữ liệu demo tại máy không thay đổi Neon. Muốn đổi URL API trong APK phải build lại; chỉnh .env tại máy không tự đổi APK đã gửi cho người dùng.

## 9. Xử lý sự cố thường gặp

| Tình huống | Cách xử lý |
|---|---|
| Không mở được APK | Tải xong rồi mở từ Files/Tải xuống; giữ đúng phần mở rộng .apk |
| Không tương thích/cài không thành công | Kiểm tra Android, dung lượng trống, đúng bản APK và chữ ký bản cũ |
| Dữ liệu tải lâu | Kiểm tra Internet, mở health, chờ dịch vụ sẵn sàng rồi thử lại |
| Sai tài khoản/mật khẩu | Kiểm tra email, mật khẩu và đúng môi trường; dùng thông tin được cấp cho môi trường đó |
| Không gửi được phản ánh | Kiểm tra mô tả, ảnh, vị trí, xác nhận; xem lịch sử trước khi gửi lại |
| Cán bộ không thấy nhiệm vụ | Kiểm tra tài khoản, đơn vị, người được chỉ định và trạng thái |
| Không gửi được nghiệm thu | Kiểm tra quyền tiếp nhận, checklist đã lưu, ghi chú, ảnh và trạng thái |
| Không có push | Kiểm tra quyền thông báo, đăng nhập, mạng, Google Play Services và Thông báo trong app |
| Dữ liệu local khác web | Kiểm tra API và database đang dùng; hai môi trường độc lập |

Render Free có thể ngủ sau 15 phút không nhận lưu lượng; lần truy cập tiếp theo có thể cần khoảng một phút để khởi động. Vì mobile có timeout, hãy chờ dịch vụ sẵn sàng rồi thử lại nếu lần đầu thất bại. Các job trong process backend không chạy khi dịch vụ ngủ. Nguồn: https://render.com/docs/free#spinning-down-on-idle.

Health: https://dothi360.onrender.com/api/v1/health. Dịch vụ sẵn sàng khi HTTP 200 và phản hồi có database: connected.

## 10. Dành cho người cài từ mã nguồn

Người chỉ dùng bản trực tuyến không cần thực hiện phần này. Môi trường đã dùng: Node.js 24.14.0, Flutter 3.35.4/Dart 3.9.2. Cần thêm Android SDK và PostgreSQL có PostGIS. Snapshot xuất từ PostgreSQL 16.14; Neon đã kiểm tra là PostgreSQL 18.7.

### 10.1. Database riêng

Chỉ nhập vào database trống mới tạo, cấu trúc trước và dữ liệu sau. Ví dụ PowerShell, chạy từ thư mục sản phẩm có thư mục Database:

```powershell
psql -U postgres -h localhost -p 5432 -c "CREATE DATABASE dothi360_demo;"
psql -U postgres -h localhost -p 5432 -d dothi360_demo -v ON_ERROR_STOP=1 -f "Database/schema.sql"
psql -U postgres -h localhost -p 5432 -d dothi360_demo -v ON_ERROR_STOP=1 -f "Database/DuLieuDemo.sql"
```

Trong repository, snapshot nằm tại BE/src/database/schema.current.sql. Cần psql tương thích với lệnh \restrict/\unrestrict và quyền tạo extension. Không nhập đè database đang sử dụng; không nhập snapshot rồi chạy lại toàn bộ migration lịch sử. Công cụ BE/scripts/bootstrap_neon.cjs dành riêng cho bootstrap Neon trống và có đăng ký baseline; khác với nhập SQL local ở trên.

### 10.2. Backend và Admin

Sao chép BE/.env.example thành BE/.env nếu chưa có, điền database riêng, JWT, Cloudinary, Gemini và Firebase cần dùng. Không ghi đè cấu hình đang hoạt động.

```powershell
cd BE
npm ci
npm run build
npm start
```

Kiểm tra http://localhost:3000/api/v1/health; Swagger tại http://localhost:3000/api-docs. Script npm run dev hiện build rồi theo dõi dist, nên sửa src cần build lại.

Tạo Admin_FE/.env.local với VITE_API_URL=http://localhost:3000/api/v1; mở terminal khác:

```powershell
cd Admin_FE
npm ci
npm run dev -- --port 5173
```

CORS_ORIGINS của BE phải chứa origin Admin. Dùng nhất quán hostname/giao thức khi thử cookie refresh.

### 10.3. Flutter

Chạy với Android emulator và backend tại máy:

```powershell
cd FE
flutter pub get
flutter run --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

Điện thoại thật muốn dùng backend local cần URL LAN truy cập được từ thiết bị; thay IP thật của máy chạy BE. Điều kiện cùng mạng chỉ áp dụng cho cách chạy local.

Build APK trực tuyến từ thư mục FE:

```powershell
flutter build apk --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://dothi360.onrender.com/api/v1
```

Kết quả: FE/build/app/outputs/flutter-apk/app-release.apk. Firebase client và Firebase Admin phải cùng project. APK hiện ký bằng khóa debug cho demo nội bộ; phát hành lên cửa hàng cần khóa release riêng.

### 10.4. Tái triển khai Render

Repository có render.yaml và scripts/build-render.cjs. Dịch vụ dùng Node, root directory để trống, build command node scripts/build-render.cjs, start command cd BE && npm start, health check /api/v1/health. Admin dùng API tương đối /api/v1, chạy chung origin với BE.

Điền biến môi trường riêng: NODE_ENV=production, SERVE_ADMIN=true, DB_SSL=true, DATABASE_URL Neon kết nối trực tiếp, hai khóa JWT mạnh và thông tin Cloudinary/Gemini/Firebase Admin. Khởi tạo database trước. Không đưa khóa dịch vụ vào Git hoặc APK.

## 11. Chuẩn bị trình diễn

1. Dùng APK mới trong thư mục UngDung; kiểm tra Internet và quyền ứng dụng.
2. Mở Admin và health để dịch vụ sẵn sàng trước buổi trình diễn.
3. Chuẩn bị ba tài khoản được bàn giao riêng, ảnh và vị trí demo nhất quán.
4. Trình diễn tạo phản ánh, phân công, tiếp nhận, tiến độ/checklist, nghiệm thu và quyết định Admin.
5. Đối chiếu cùng mã hồ sơ trên mobile và Admin. Nếu trình diễn push, kiểm tra trước trên chính điện thoại sử dụng.

Đợt triển khai đã kiểm tra kết nối Neon, đăng nhập ba vai trò, phân quyền, Cloudinary, phân tích ảnh Gemini, tạo/chống trùng, phân công/tiếp nhận và nghiệm thu APPROVE/REWORK với thông báo Admin. Sau dọn nguồn, Flutter Analyze không có lỗi/cảnh báo, 3 kiểm thử đạt và APK đủ ba kiến trúc build thành công. Kết quả không thay thế kiểm thử mọi màn hình trên mọi thiết bị; push hiển thị thực tế cần kiểm tra trên điện thoại.

Tài liệu không chứa mật khẩu trực tuyến, chuỗi kết nối Neon hoặc khóa dịch vụ. Chủ hệ thống bàn giao thông tin truy cập riêng cho người có quyền tương ứng.
