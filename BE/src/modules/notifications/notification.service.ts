import { EntityManager } from 'typeorm';
import { AppDataSource } from '../../database/data-source';
import { Notification } from './notification.entity';

export class NotificationService {
  async notifyAdmins(input: {
    eventKey: string; type: string; title: string; message: string;
    incidentId?: string | null; actionPath: string; actionLabel: string;
    data?: Record<string, unknown>;
  }, manager: EntityManager = AppDataSource.manager) {
    return manager.query(`
      INSERT INTO notifications(user_id, incident_id, type, title, message, data)
      SELECT id, $1, $2, $3, $4, $5::jsonb FROM users
      WHERE role='ADMIN' AND is_active=TRUE
      ON CONFLICT DO NOTHING RETURNING id
    `, [input.incidentId ?? null, input.type, input.title, input.message,
      JSON.stringify({ ...input.data, event_key: input.eventKey,
        incident_id: input.incidentId ?? null,
        action_path: input.actionPath, action_label: input.actionLabel })]);
  }

  async create(input: Pick<Notification,'user_id'|'incident_id'|'type'|'title'|'message'> & { data?: Record<string, unknown> }, manager: EntityManager = AppDataSource.manager) {
    const repo = manager.getRepository(Notification);
    return repo.save(repo.create({ ...input, data: input.data ?? {} }));
  }
  async notifyReporters(incidentId: string, type: string, title: string, message: string, manager: EntityManager) {
    const users: { reporter_id: string }[] = await manager.query('SELECT DISTINCT reporter_id FROM incident_reports WHERE incident_id=$1', [incidentId]);
    return Promise.all(users.map(u => this.create({ user_id: u.reporter_id, incident_id: incidentId, type, title, message, data: { incident_id: incidentId } }, manager)));
  }
  async notifyDepartment(incidentId: string, departmentId: string, manager: EntityManager, assignmentId?: string, assignedOfficerId?: string | null) {
    const users: { id: string }[] = await manager.query(
      `SELECT id FROM users
       WHERE department_id=$1 AND role='OFFICER' AND is_active=TRUE
         AND ($2::uuid IS NULL OR id=$2::uuid)`,
      [departmentId, assignedOfficerId ?? null],
    );
    const targeted = Boolean(assignedOfficerId);
    return Promise.all(users.map(u => this.create({
      user_id: u.id,
      incident_id: incidentId,
      type: 'ASSIGNMENT_CREATED',
      title: targeted ? 'Bạn có nhiệm vụ mới chờ xác nhận' : 'Đơn vị có nhiệm vụ mới',
      message: targeted
        ? 'Quản trị viên vừa chỉ định bạn xử lý một sự cố. Hãy xem hồ sơ để tiếp nhận hoặc từ chối.'
        : 'Đơn vị của bạn vừa được giao một sự cố mới. Hãy xem hồ sơ để tiếp nhận.',
      data: { incident_id: incidentId, assignment_id: assignmentId, action: 'REVIEW_ASSIGNMENT' },
    }, manager)));
  }
  async notifyAdminsPendingAssignment(
    incidentId: string,
    incidentType: string,
    description: string,
    address: string | null,
    manager: EntityManager,
  ) {
    const locationText = address?.trim() ? ` tại ${address.trim()}` : '';
    const summary = description.trim().length > 140
      ? `${description.trim().slice(0, 137)}...`
      : description.trim();
    return this.notifyAdmins({
      eventKey: `pending-assignment:${incidentId}`,
      incidentId,
      type: 'INCIDENT_PENDING_ASSIGNMENT',
      title: 'Sự cố mới chờ phân công',
      message: `${incidentType}${locationText}: ${summary}`,
      actionPath: `/incidents/${incidentId}`,
      actionLabel: 'Mở và phân công',
      data: { status: 'PENDING_ASSIGNMENT' },
    }, manager);
  }
  async notifyInterestedAreas(incidentId:string, _reporterId:string, manager:EntityManager){
    const rows:{user_id:string;area_id:string;area_name:string;incident_type:string;distance_m:number;address:string|null}[]=await manager.query(`
      SELECT DISTINCT ON(a.user_id) a.user_id,a.id area_id,a.name area_name,t.name incident_type,
        ROUND(ST_Distance(i.location,a.center))::int distance_m,
        (SELECT r.reported_address FROM incident_reports r
          WHERE r.incident_id=i.id AND NULLIF(TRIM(r.reported_address),'') IS NOT NULL
          ORDER BY r.created_at ASC LIMIT 1) address
      FROM user_interested_areas a JOIN incidents i ON i.id=$1 AND ST_DWithin(i.location,a.center,a.radius_m)
      JOIN incident_types t ON t.id=i.incident_type_id
      WHERE a.is_active=TRUE AND a.notifications_enabled=TRUE
        AND NOT EXISTS(
          SELECT 1 FROM notifications n
          WHERE n.user_id=a.user_id AND n.incident_id=i.id AND n.type='AREA_WARNING'
        )
      ORDER BY a.user_id,ST_Distance(i.location,a.center)`,[incidentId]);
    return Promise.all(rows.map(row=>this.create({
      user_id:row.user_id,
      incident_id:incidentId,
      type:'AREA_WARNING',
      title:`Sự cố mới gần ${row.area_name}`,
      message:row.address?.trim()
        ? `${row.incident_type} tại ${row.address.trim()}, cách tâm khu vực khoảng ${row.distance_m} m.`
        : `${row.incident_type} vừa được ghi nhận trong phạm vi ${row.area_name}.`,
      data:{
        incident_id:incidentId,
        area_id:row.area_id,
        area_name:row.area_name,
        distance_m:row.distance_m,
        action:'VIEW_INCIDENT',
      },
    },manager)));
  }
  async list(userId: string, page: number, limit: number) {
    const repo = AppDataSource.getRepository(Notification); const take=Math.min(Math.max(limit,1),100);
    const [data,total]=await repo.findAndCount({ where:{user_id:userId}, order:{created_at:'DESC'}, skip:(Math.max(page,1)-1)*take, take });
    return { data,total,page,limit:take,unread:await repo.count({where:{user_id:userId,is_read:false}}) };
  }
  async markRead(id: string, userId: string) { const result=await AppDataSource.getRepository(Notification).update({id,user_id:userId},{is_read:true,read_at:new Date()}); if(!result.affected) throw {statusCode:404,message:'Không tìm thấy thông báo'}; }
  markAllRead(userId:string){return AppDataSource.getRepository(Notification).createQueryBuilder().update().set({is_read:true,read_at:new Date()}).where('user_id=:userId AND is_read=FALSE',{userId}).execute();}
  registerDevice(userId:string,token:string,platform:string){return AppDataSource.query(`INSERT INTO device_tokens(user_id,token,platform) VALUES($1,$2,$3) ON CONFLICT(token) DO UPDATE SET user_id=$1,platform=$3,is_active=TRUE,last_used_at=NOW(),updated_at=NOW()`,[userId,token,platform]);}
  removeDevice(userId:string,token:string){return AppDataSource.query('UPDATE device_tokens SET is_active=FALSE,updated_at=NOW() WHERE user_id=$1 AND token=$2',[userId,token]);}
  async remove(id: string, userId: string) {
    const res = await AppDataSource.getRepository(Notification).delete({ id, user_id: userId });
    if (!res.affected) throw { statusCode: 404, message: 'Không tìm thấy thông báo cần xóa' };
  }
  async removeAll(userId: string) {
    await AppDataSource.getRepository(Notification).delete({ user_id: userId });
  }
}
