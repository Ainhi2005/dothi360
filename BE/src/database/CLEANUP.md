# Cấu trúc database sau dọn dẹp — 11/11/2026

Migration: `1700000019000-RemoveRetiredFeaturesAndUnusedColumns.ts`.

Đã áp dụng trên database được cấu hình trong backend. Trước khi chạy đã tạo bản sao lưu pg_dump dạng custom trong `BE/scratch/db-cleanup/`; thư mục này bị loại khỏi Git vì chứa dữ liệu thật. `before.json`/`after.json` ghi cấu trúc, khóa ngoại và số bản ghi để đối chiếu. Bản dump đã được kiểm tra đọc danh mục bằng pg_restore.

## Đã bỏ

- `ratings`: chức năng đánh giá kết quả đã gỡ khỏi ứng dụng, gồm 13 bản ghi lịch sử tại thời điểm sao lưu.
- `coordination_requests`: chức năng phối hợp đã gỡ, bảng rỗng tại thời điểm sao lưu.
- Khóa ngoại, index và trigger thuộc hai bảng trên được PostgreSQL tự gỡ cùng bảng. Không sử dụng `CASCADE` để tránh ảnh hưởng quan hệ ngoài dự kiến.
- `users.last_login_at`.
- `refresh_tokens.user_agent`, `refresh_tokens.ip_address`.
- `audit_logs.request_id`, `audit_logs.ip_address`, `audit_logs.user_agent`.
- Cấu hình `algorithm_configs.config_key = 'DUPLICATE_DETECTION'`: thuật toán hiện dùng hằng trong code và không đọc bản cấu hình này.

Sáu cột bị bỏ đều không có giá trị và không có code ghi/đọc nghiệp vụ tại thời điểm rà soát. Migration sẽ dừng nếu gặp dữ liệu không rỗng trong các cột này khi áp dụng ở môi trường khác. Request ID dùng trong middleware/response lỗi vẫn giữ nguyên; nó độc lập với cột audit log cũ.

## Được giữ

23 bảng phục vụ tính năng hiện hành:

1. users
2. refresh_tokens
3. device_tokens
4. departments
5. areas
6. incident_types
7. department_incident_types
8. incidents
9. incident_reports
10. incident_assignments
11. incident_updates
12. incident_media
13. incident_type_checklist_items
14. incident_checklist_results
15. notifications
16. user_interested_areas
17. ai_feedbacks
18. algorithm_configs
19. audit_logs
20. citizen_feedbacks
21. citizen_feedback_upvotes
22. emergency_guides
23. emergency_contacts

Ngoài ra có `migrations` do TypeORM sử dụng và `spatial_ref_sys` thuộc PostGIS: đây là hai bảng kỹ thuật cần giữ. Không xóa lịch sử phân công, cập nhật, checklist hoặc audit chỉ vì một hàng hiện không active.

QR từng dùng ID sự cố/phân công sẵn có, không có bảng/cột QR riêng để xóa.

## File schema và lịch sử migration

- `schema.current.sql`: snapshot DDL xuất từ database sau khi dọn, dùng tra cứu bảng/cột/quan hệ hiện hành; không chứa dữ liệu hoặc bảng lịch sử migrations.
- `schema.sql`: baseline lịch sử cho InitialSchema. Một số bảng/cột cũ vẫn xuất hiện ở baseline để các migration cũ hoạt động theo chuỗi; chúng bị gỡ bởi migration cleanup mới. Không sửa hoặc xóa lịch sử migration đã áp dụng chỉ để làm kết quả tìm kiếm biến mất.
- Không chạy snapshot hiện hành rồi chạy lại nguyên chuỗi migration lịch sử trên cùng database. Quy trình khởi tạo toàn bộ từ baseline là luồng khác và cần được kiểm chứng riêng.
- Script `wipe_data.js` đã bỏ truy vấn tới các bảng bị gỡ; script này xóa dữ liệu khi chạy và không phải bước dọn schema.

## Khôi phục

Migration không thể tái tạo 13 đánh giá đã xóa bằng cách tạo lại bảng rỗng. Khi cần phục hồi dữ liệu, dùng bản dump trước cleanup để khôi phục vào database riêng rồi xác nhận trước khi thay môi trường hiện tại. `migration:revert` của migration cleanup cố ý báo lỗi để không tạo cảm giác đã phục hồi dữ liệu.

## Kiểm tra

`npm test`: kiểm tra quy tắc ứng dụng.

`npm run test:integration`: kiểm tra bảng/cột đã bỏ, ràng buộc report/assignment, token, ORM và truy vấn danh sách/dashboard sau cleanup.

`node scripts/audit_database.cjs --after --export-schema`: đối chiếu cấu trúc và cập nhật snapshot DDL từ database được cấu hình; không in dữ liệu hàng hoặc thông tin đăng nhập.
