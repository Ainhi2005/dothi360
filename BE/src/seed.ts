import 'reflect-metadata';
import 'dotenv/config';
import { AppDataSource } from './database/data-source';
import { Department } from './modules/departments/department.entity';
import { IncidentType } from './modules/incident-types/incident-type.entity';
import { User } from './modules/users/user.entity';
import { ROLES } from './common/constants/roles';
import * as argon2 from 'argon2';

async function seed() {
  console.log('🌱 Bắt đầu kết nối Database...');
  await AppDataSource.initialize();
  console.log('✅ Database connected.');

  const depRepo = AppDataSource.getRepository(Department);
  const typeRepo = AppDataSource.getRepository(IncidentType);
  const userRepo = AppDataSource.getRepository(User);

  // 1. Seed Departments (Đơn vị Hà Nội)
  console.log('🏢 Đang seed Departments...');
  let dep1 = await depRepo.findOne({ where: { code: 'DP_CSGT_HN_01' } });
  if (!dep1) {
    dep1 = depRepo.create({
      code: 'DP_CSGT_HN_01',
      name: 'Đội CSGT Số 1 - Hoàn Kiếm (Công an TP Hà Nội)',
      address: 'Số 3 Tràng Thi, Hàng Trống, Hoàn Kiếm, Hà Nội',
      location: { type: 'Point', coordinates: [105.8485, 21.0289] }
    });
    await depRepo.save(dep1);
  }

  let dep2 = await depRepo.findOne({ where: { code: 'DP_MT_URENCO' } });
  if (!dep2) {
    dep2 = depRepo.create({
      code: 'DP_MT_URENCO',
      name: 'Công ty TNHH MTV Môi trường Đô thị Hà Nội (URENCO)',
      address: '282 Kim Mã, Phường Kim Mã, Ba Đình, Hà Nội',
      location: { type: 'Point', coordinates: [105.8195, 21.0322] }
    });
    await depRepo.save(dep2);
  }

  // 2. Seed Incident Types (Loại sự cố)
  console.log('🚨 Đang seed Incident Types...');
  const typesData = [
    { code: 'TRAFFIC_JAM', name: 'Kẹt xe nghiêm trọng', type_priority_level: 2, default_severity: 3 },
    { code: 'ROAD_DAMAGE', name: 'Đường hư hỏng/Ổ gà', type_priority_level: 3, default_severity: 2 },
    { code: 'TREE_FALLEN', name: 'Cây đổ ngang đường', type_priority_level: 4, default_severity: 4 },
    { code: 'FLOODING', name: 'Ngập lụt', type_priority_level: 3, default_severity: 3 },
    { code: 'FIRE', name: 'Hỏa hoạn', type_priority_level: 5, default_severity: 5 },
    { code: 'OTHER', name: 'Khác', type_priority_level: 1, default_severity: 1 }
  ];

  for (const t of typesData) {
    const exists = await typeRepo.findOne({ where: { code: t.code } });
    if (!exists) {
      await typeRepo.save(typeRepo.create(t));
    }
  }

  // 3. Seed Users (Tài khoản)
  console.log('👥 Đang seed Users (Admin, Officer, Citizen)...');
  const password_hash = await argon2.hash('Demo@123456');

  // Admin
  if (!(await userRepo.findOne({ where: { email: 'admin@urban.com' } }))) {
    await userRepo.save(userRepo.create({
      full_name: 'Quản trị viên hệ thống',
      email: 'admin@urban.com',
      password_hash,
      phone: '0999999999',
      role: ROLES.ADMIN
    }));
  }

  // Officer 1 (Thuộc CSGT Q1)
  if (!(await userRepo.findOne({ where: { email: 'officer.gt@urban.com' } }))) {
    await userRepo.save(userRepo.create({
      full_name: 'Cán bộ CSGT Nguyễn Văn B',
      email: 'officer.gt@urban.com',
      password_hash,
      phone: '0888888881',
      role: ROLES.OFFICER,
      department_id: dep1.id
    }));
  }

  // Officer 2 (Thuộc MTĐT Q1)
  if (!(await userRepo.findOne({ where: { email: 'officer.mt@urban.com' } }))) {
    await userRepo.save(userRepo.create({
      full_name: 'Cán bộ Môi trường Trần Thị C',
      email: 'officer.mt@urban.com',
      password_hash,
      phone: '0888888882',
      role: ROLES.OFFICER,
      department_id: dep2.id
    }));
  }

  // Citizen (Người dân test)
  if (!(await userRepo.findOne({ where: { email: 'citizen@gmail.com' } }))) {
    await userRepo.save(userRepo.create({
      full_name: 'Người dân Test',
      email: 'citizen@gmail.com',
      password_hash,
      phone: '0777777777',
      role: ROLES.CITIZEN
    }));
  }

  console.log('🗺️ Đang seed năng lực và địa bàn mẫu...');
  const allTypes = await typeRepo.find();
  const trafficCodes = new Set(['TRAFFIC_JAM', 'ROAD_DAMAGE', 'TREE_FALLEN']);
  const environmentCodes = new Set(['FLOODING', 'FIRE', 'TREE_FALLEN', 'OTHER']);
  for (const type of allTypes) {
    const departmentIds = [
      ...(trafficCodes.has(type.code) ? [dep1.id] : []),
      ...(environmentCodes.has(type.code) ? [dep2.id] : []),
    ];
    for (const departmentId of departmentIds) {
      await AppDataSource.query(`INSERT INTO department_incident_types(department_id,incident_type_id,is_active) VALUES($1,$2,TRUE) ON CONFLICT(department_id,incident_type_id) DO UPDATE SET is_active=TRUE,updated_at=NOW()`, [departmentId, type.id]);
    }
  }
  await AppDataSource.query(`INSERT INTO areas(department_id,name,geom) VALUES($1,'Khu trung tâm Quận 1',ST_GeomFromText('POLYGON((106.690 10.755,106.710 10.755,106.710 10.785,106.690 10.785,106.690 10.755))',4326)) ON CONFLICT(department_id,name) DO UPDATE SET is_active=TRUE`, [dep1.id]);
  await AppDataSource.query(`INSERT INTO areas(department_id,name,geom) VALUES($1,'Khu Đông Quận 1',ST_GeomFromText('POLYGON((106.710 10.755,106.725 10.755,106.725 10.790,106.710 10.790,106.710 10.755))',4326)) ON CONFLICT(department_id,name) DO UPDATE SET is_active=TRUE`, [dep2.id]);

  console.log('🎉 Đã seed dữ liệu demo thành công. Mật khẩu dùng chung: Demo@123456');
  process.exit(0);
}

seed().catch(error => {
  console.error('❌ Lỗi seed data:', error);
  process.exit(1);
});
