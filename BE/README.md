# Backend sự cố đô thị

Backend modular monolith sử dụng Express, TypeScript và PostgreSQL/PostGIS.

Luồng xử lý: `app.ts` → `routes/index.ts` → route/middleware của module → controller → service → TypeORM/SQL → PostgreSQL.

## Tổ chức nghiệp vụ

- `modules/`: module theo chức năng; route khai báo endpoint, controller nhận request/trả response, validation kiểm tra dữ liệu đầu vào.
- `modules/incidents/incident.service.ts`: facade giữ điểm gọi ổn định cho controller. Các service trong `services/` lần lượt xử lý tra cứu, phân tích AI, tạo/gộp, kiểm duyệt, tiến độ và nghiệm thu.
- `modules/assignments/assignment.service.ts`: facade phân công. Các service trong `services/` xử lý tra cứu, giao việc, tiếp nhận/từ chối và tổng quan cán bộ.
- `*-dependencies.ts`: repository và dịch vụ dùng chung được tạo một lần cho mỗi facade. Service con nhận dependency qua constructor.
- `algorithms/`: phát hiện trùng lặp, chấm ưu tiên và gợi ý phân công.
- `common/`: middleware, lỗi, hằng số và dịch vụ dùng chung.
- `database/`: datasource, migrations và snapshot schema.
- `jobs/`: tác vụ nền ưu tiên, thông báo push và nhắc SLA.

Service nghiệp vụ giữ phạm vi transaction. Khi cần ghi dữ liệu liên quan, tiếp tục truyền cùng `EntityManager` cho các dịch vụ được gọi; không tự mở transaction riêng trong từng bước.

## Kiểm tra trước khi bàn giao

```text
npm run typecheck
npm test
npm run test:integration
```

Bộ tích hợp cần PostgreSQL/PostGIS và môi trường local đã cấu hình; có tạo dữ liệu kiểm thử rồi dọn lại hoặc rollback. Không trỏ bộ kiểm thử vào database production.

Snapshot hiện tại là `src/database/schema.current.sql`. Migration initial cũ còn tìm `schema.sql`; không dùng riêng migration này để dựng database trống mà chưa đối chiếu quy trình bootstrap trong `scripts/`.
