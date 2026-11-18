import assert from 'node:assert/strict';
import test, { before, after } from 'node:test';
import { randomUUID } from 'node:crypto';
import { AppDataSource } from '../../database/data-source';
import { NotificationService } from './notification.service';
import { FeedbackService } from '../feedbacks/feedback.service';

before(async () => { AppDataSource.setOptions({ logging: false }); await AppDataSource.initialize(); });
after(async () => { if (AppDataSource.isInitialized) await AppDataSource.destroy(); });

test('Admin đang hoạt động nhận đúng sự kiện, chống trùng và cho phép đợt nghiệm thu mới', async () => {
  const q = AppDataSource.createQueryRunner(); await q.connect(); await q.startTransaction();
  try {
    const ids: string[] = [];
    for (const [role, active] of [['ADMIN',true],['ADMIN',false],['CITIZEN',true]] as const) {
      const [row] = await q.query(`INSERT INTO users(full_name,email,password_hash,role,is_active) VALUES('Notification test',$1,'test-only',$2,$3) RETURNING id`, [`${randomUUID()}@test.invalid`,role,active]); ids.push(row.id);
    }
    const service = new NotificationService();
    const input = { eventKey: randomUUID(), type:'INCIDENT_PENDING_VERIFICATION', title:'Chờ nghiệm thu',message:'Kết quả', actionPath:'/incidents/test',actionLabel:'Mở nghiệm thu' };
    await service.notifyAdmins(input,q.manager);
    await service.notifyAdmins(input,q.manager);
    const rows = await q.query(`SELECT user_id,data FROM notifications WHERE data->>'event_key'=$1`,[input.eventKey]);
    assert.equal(rows.filter((r: any) => r.user_id === ids[0]).length,1);
    assert.equal(rows.some((r: any) => ids.slice(1).includes(r.user_id)),false);
    assert.equal(rows[0].data.action_label,'Mở nghiệm thu');
    await service.notifyAdmins({...input,eventKey:randomUUID()},q.manager);
    const [count] = await q.query(`SELECT COUNT(*)::int count FROM notifications WHERE user_id=$1`,[ids[0]]);
    assert.equal(count.count,2);
  } finally { await q.rollbackTransaction(); await q.release(); }
});

test('Góp ý và phản hồi tạo thông báo trong cùng transaction, rollback không để lại thông báo', async () => {
  const q = AppDataSource.createQueryRunner(); await q.connect(); await q.startTransaction();
  const original = AppDataSource.transaction;
  const marker = randomUUID();
  try {
    const [citizen] = await q.query(`INSERT INTO users(full_name,email,password_hash,role) VALUES('Test',$1,'test-only','CITIZEN') RETURNING id`,[`${randomUUID()}@test.invalid`]);
    const [admin] = await q.query(`INSERT INTO users(full_name,email,password_hash,role) VALUES('Test',$1,'test-only','ADMIN') RETURNING id`,[`${randomUUID()}@test.invalid`]);
    AppDataSource.transaction = (async (fn: any) => fn(q.manager)) as any;
    const service = new FeedbackService();
    const feedback = await service.create(citizen.id,{title:marker,content:'Nội dung kiểm thử thông báo'});
    const pending = await q.query(`SELECT * FROM notifications WHERE user_id=$1 AND data->>'feedback_id'=$2`,[admin.id,feedback.id]);
    assert.equal(pending.length,1); assert.equal(pending[0].type,'FEEDBACK_PENDING_REVIEW');
    await service.respond(feedback.id,admin.id,{status:'ACCEPTED',response_note:'Đã tiếp nhận đề xuất'});
    const replies = await q.query(`SELECT * FROM notifications WHERE user_id=$1 AND data->>'feedback_id'=$2`,[citizen.id,feedback.id]);
    assert.equal(replies.length,1); assert.equal(replies[0].type,'FEEDBACK_RESPONDED');
  } finally { AppDataSource.transaction = original; await q.rollbackTransaction(); await q.release(); }
  const rows = await AppDataSource.query('SELECT id FROM citizen_feedbacks WHERE title=$1',[marker]);
  assert.equal(rows.length,0);
});

test('Cán bộ gửi nghiệm thu tạo thông báo Admin, gửi lại sai trạng thái không sinh thêm', async () => {
  const { IncidentService } = await import('../incidents/incident.service');
  const { Incident } = await import('../incidents/incident.entity');
  const q = AppDataSource.createQueryRunner(); await q.connect(); await q.startTransaction();
  const original = AppDataSource.transaction;
  try {
    const token = randomUUID();
    const [type] = await q.query(`INSERT INTO incident_types(code,name) VALUES($1,$1) RETURNING id`,[token]);
    const [dept] = await q.query(`INSERT INTO departments(code,name) VALUES($1,$1) RETURNING id`,[token]);
    const [officer] = await q.query(`INSERT INTO users(full_name,email,password_hash,role,department_id) VALUES('Test',$1,'test-only','OFFICER',$2) RETURNING id`,[`${token}@test.invalid`,dept.id]);
    const [incident] = await q.query(`INSERT INTO incidents(incident_type_id,description,location,severity_level,status) VALUES($1,'Test',ST_SetSRID(ST_MakePoint(105.8,21.0),4326)::geography,3,'IN_PROGRESS') RETURNING id`,[type.id]);
    await q.query(`INSERT INTO incident_assignments(incident_id,department_id,accepted_by,accepted_at,assignment_method) VALUES($1,$2,$3,NOW(),'MANUAL')`,[incident.id,dept.id,officer.id]);
    AppDataSource.transaction = (async (fn: any) => fn(q.manager)) as any;
    const service = new IncidentService();
    service.findOne = (async () => q.manager.getRepository(Incident).findOneByOrFail({id:incident.id})) as any;
    await service.updateStatus(incident.id,officer.id,'OFFICER',dept.id,{status:'PENDING_VERIFICATION',note:'Đã xử lý, đề nghị nghiệm thu'});
    const rows = await q.query(`SELECT * FROM notifications WHERE incident_id=$1 AND type='INCIDENT_PENDING_VERIFICATION'`,[incident.id]);
    const [admins] = await q.query(`SELECT COUNT(*)::int count FROM users WHERE role='ADMIN' AND is_active=TRUE`);
    assert.ok(admins.count > 0); assert.equal(rows.length,admins.count);
    assert.equal(rows[0].data.action_path,`/incidents/${incident.id}`);
    await assert.rejects(service.updateStatus(incident.id,officer.id,'OFFICER',dept.id,{status:'PENDING_VERIFICATION'}), (error: any) => error.statusCode === 409);
    const [count] = await q.query(`SELECT COUNT(*)::int count FROM notifications WHERE incident_id=$1 AND type='INCIDENT_PENDING_VERIFICATION'`,[incident.id]);
    assert.equal(count.count,rows.length);
  } finally { AppDataSource.transaction = original; await q.rollbackTransaction(); await q.release(); }
});
