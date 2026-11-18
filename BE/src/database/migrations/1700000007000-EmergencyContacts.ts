import { MigrationInterface, QueryRunner } from 'typeorm';

export class EmergencyContacts1700000007000 implements MigrationInterface {
  name = 'EmergencyContacts1700000007000';

  async up(q: QueryRunner) {
    await q.query(`
      CREATE TABLE emergency_contacts (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        name VARCHAR(160) NOT NULL,
        phone_number VARCHAR(50) NOT NULL,
        category VARCHAR(60) NOT NULL DEFAULT 'NATIONAL',
        description VARCHAR(300) NOT NULL,
        icon VARCHAR(40) NOT NULL DEFAULT 'phone',
        accent VARCHAR(20) NOT NULL DEFAULT 'primary',
        is_hotline BOOLEAN NOT NULL DEFAULT FALSE,
        sort_order INTEGER NOT NULL DEFAULT 0,
        is_active BOOLEAN NOT NULL DEFAULT TRUE,
        operating_hours VARCHAR(60) NOT NULL DEFAULT '24/7',
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );

      CREATE INDEX idx_emergency_contacts_active_order ON emergency_contacts(is_active, sort_order);
      CREATE INDEX idx_emergency_contacts_category ON emergency_contacts(category);

      INSERT INTO emergency_contacts(name, phone_number, category, description, icon, accent, is_hotline, sort_order, operating_hours) VALUES
      ('Cứu hỏa', '114', 'NATIONAL', 'Tiếp nhận tin báo cháy nổ, sập đổ công trình, người mắc kẹt, đuối nước và thiên tai.', 'local_fire_department', 'danger', TRUE, 10, '24/7'),
      ('Cấp cứu', '115', 'NATIONAL', 'Tiếp nhận cấp cứu tai nạn thương tích, đột quỵ, ngộ độc, điều phối xe cứu thương khẩn cấp.', 'medical_services', 'danger', TRUE, 20, '24/7'),
      ('Cảnh sát', '113', 'NATIONAL', 'Bảo đảm an ninh trật tự, can thiệp khẩn cấp vụ việc tội phạm, cướp giật, bạo lực.', 'local_police', 'danger', TRUE, 30, '24/7'),
      ('Trẻ em', '111', 'NATIONAL', 'Đường dây nóng Quốc gia bảo vệ trẻ em bị xâm hại, bạo lực gia đình và khủng hoảng tinh thần.', 'family_restroom', 'info', TRUE, 40, '24/7'),
      ('Công ty Thoát nước Hà Nội', '02438343355', 'INFRASTRUCTURE', 'Xử lý ngập úng, nắp hố ga mất, tràn cống', 'flood', 'info', FALSE, 50, '24/7'),
      ('Công viên Cây xanh Hà Nội', '02438234551', 'INFRASTRUCTURE', 'Cây gãy đổ đè đường, cành nghiêng nguy hiểm', 'park', 'success', FALSE, 60, '24/7'),
      ('Điện lực EVN Hà Nội', '19001288', 'INFRASTRUCTURE', 'Sự cố chập điện, đứt dây cáp trên phố', 'electric_bolt', 'warning', FALSE, 70, '24/7'),
      ('Chiếu sáng công cộng Hà Nội', '02439744444', 'INFRASTRUCTURE', 'Đèn đường tắt hàng loạt, hở rò rỉ điện cột đèn', 'lightbulb', 'info', FALSE, 80, '24/7'),
      ('Phòng CSGT TP. Hà Nội', '02439424448', 'TRAFFIC', 'Ùn tắc nghiêm trọng, tai nạn giao thông', 'traffic', 'warning', FALSE, 90, '24/7'),
      ('Hỗ trợ khách xe bus & Metro', '19001296', 'TRAFFIC', 'Tìm đồ thất lạc, sự cố trên tuyến vận tải', 'directions_bus', 'info', FALSE, 100, '24/7'),
      ('Trung tâm Chống độc BV Bạch Mai', '02438693731', 'MEDICAL', 'Tư vấn cấp cứu ngộ độc hóa chất, rắn cắn', 'medical_services', 'danger', FALSE, 110, '24/7'),
      ('Trung tâm Kiểm soát Bệnh tật CDC HN', '0969082115', 'MEDICAL', 'Khai báo dịch bệnh lạ, ngộ độc tập thể', 'health_and_safety', 'danger', FALSE, 120, '24/7');
    `);
  }

  async down(q: QueryRunner) {
    await q.query('DROP TABLE IF EXISTS emergency_contacts');
  }
}
