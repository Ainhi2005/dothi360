# Database migrations

Các lệnh chạy từ thư mục `BE`:

```bash
npm run migration:show
npm run migration:run
npm run migration:revert
```

- `InitialSchema` tạo toàn bộ schema cho database mới.
- Nếu database đã được tạo trước đây bằng `schema.sql`, migration initial chỉ ghi
  nhận baseline và không chạy lại `CREATE TABLE`.
- `AlignRefreshTokens` chuyển cấu trúc refresh token cũ từ `is_revoked` sang
  `revoked_at` mà vẫn giữ trạng thái token đã thu hồi.
- `EnforceConcurrencyConstraints` bảo đảm mỗi sự cố chỉ có một assignment đang
  hoạt động và mỗi người chỉ có một report trên một sự cố.

Không sửa migration đã phát hành. Mọi thay đổi schema tiếp theo phải tạo migration
mới có cả `up` và `down`.
