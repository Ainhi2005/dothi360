# Thông báo tác nghiệp

Thông báo được lưu cùng transaction với yêu cầu; job push chỉ nhìn thấy dữ liệu đã commit. Admin đang hoạt động nhận các loại:

| Loại | Thời điểm | Mở đến |
|---|---|---|
| INCIDENT_PENDING_VERIFICATION | Cán bộ gửi kết quả chờ nghiệm thu | Hồ sơ nghiệm thu |
| REPORT_PENDING_REVIEW | Phản ánh yêu cầu kiểm duyệt thủ công | Danh sách kiểm duyệt |
| INCIDENT_PENDING_ASSIGNMENT | Hồ sơ mới hoặc duyệt xong chưa có đơn vị phù hợp | Hồ sơ phân công |
| ASSIGNMENT_REJECTED | Cán bộ từ chối nhiệm vụ | Hồ sơ để phân công lại |
| INCIDENT_BLOCKED | Cán bộ ghi khó khăn mới | Hồ sơ và tiến độ |
| FEEDBACK_PENDING_REVIEW | Công dân gửi góp ý | Góp ý tương ứng |
| INCIDENT_SLA_OVERDUE | Nhiệm vụ đang xử lý đã quá SLA | Hồ sơ và tiến độ |

Người gửi góp ý nhận FEEDBACK_RESPONDED khi Admin phản hồi. Mobile mở danh sách góp ý từ thông báo này. Thông báo phân công, trạng thái và kết quả nghiệm thu hiện có vẫn được giữ.

Admin kiểm tra thông báo mỗi 15 giây và khi quay lại cửa sổ; cập nhật số chưa đọc và hiển thị cảnh báo có nút mở yêu cầu. Đây là thông báo trong trang web. Push thiết bị tiếp tục qua job FCM hiện có và phụ thuộc cấu hình Firebase/token thiết bị.

Chống trùng theo cặp user_id và data.event_key bằng unique partial index. Mỗi lần gửi nghiệm thu có update_id riêng, nên sau yêu cầu làm lại, lần gửi mới vẫn tạo thông báo mới. Cảnh báo SLA Admin giới hạn một lần mỗi ngày UTC cho mỗi assignment. Khó khăn chỉ tạo cảnh báo khi nội dung khác bản cập nhật trước.

Migration: NotificationEventKeys1700000020000. Sau khi build, có thể chạy `node scripts/backfill_pending_notifications.cjs` để tạo thông báo cho các hồ sơ chờ nghiệm thu, phản ánh chờ kiểm duyệt và góp ý đang chờ. Chạy lại không tạo trùng.

Kiểm thử: `npm test`, `npm run test:integration`. Kiểm thử tích hợp rollback dữ liệu và thông báo, không gửi FCM. Cần kiểm tra nhận push thực tế trên thiết bị khi nghiệm thu triển khai.
