import { MigrationInterface, QueryRunner } from 'typeorm';

export class DefaultIncidentChecklists1700000012000 implements MigrationInterface {
  name = 'DefaultIncidentChecklists1700000012000';
  async up(q: QueryRunner) {
    await q.query(`
      INSERT INTO incident_type_checklist_items(incident_type_id,title,is_required,sort_order)
      SELECT t.id,v.title,TRUE,v.ord FROM incident_types t CROSS JOIN LATERAL (
        SELECT * FROM (VALUES
          (1,'Đã đặt cảnh báo và bảo đảm an toàn hiện trường'),
          (2,CASE WHEN t.name ILIKE '%ngập%' THEN 'Đã kiểm tra miệng cống và dòng chảy' ELSE 'Đã kiểm tra nguyên nhân và phạm vi ảnh hưởng' END),
          (3,CASE WHEN t.name ILIKE '%ngập%' THEN 'Đã khơi thông dòng chảy' ELSE 'Đã thực hiện biện pháp xử lý chuyên môn' END),
          (4,'Đã phối hợp đơn vị liên quan khi cần'),
          (5,'Đã chụp ảnh sau xử lý')
        ) x(ord,title)
      ) v
      WHERE t.is_active=TRUE AND NOT EXISTS(SELECT 1 FROM incident_type_checklist_items c WHERE c.incident_type_id=t.id AND c.is_active=TRUE);
    `);
  }
  async down(q: QueryRunner) {
    await q.query(`DELETE FROM incident_type_checklist_items WHERE title IN ('Đã đặt cảnh báo và bảo đảm an toàn hiện trường','Đã kiểm tra miệng cống và dòng chảy','Đã kiểm tra nguyên nhân và phạm vi ảnh hưởng','Đã khơi thông dòng chảy','Đã thực hiện biện pháp xử lý chuyên môn','Đã phối hợp đơn vị liên quan khi cần','Đã chụp ảnh sau xử lý')`);
  }
}
