import { AppDataSource } from '../../database/data-source';
import { User } from './user.entity';
import * as argon2 from 'argon2';
import { RefreshToken } from '../auth/refresh-token.entity';
import { AuditLogService } from '../audit-logs/audit-log.service';
import { z } from 'zod';

export class UserService {
  private repository = AppDataSource.getRepository(User);

  async resetPassword(id: string, actorId: string, data: { new_password: string; must_change_password: boolean }) {
    if (!z.uuid().safeParse(id).success) throw { statusCode: 400, message: 'ID người dùng không hợp lệ' };
    const hash = await argon2.hash(data.new_password);
    return AppDataSource.transaction(async manager => {
      const users = manager.getRepository(User);
      const actor = await users.findOne({ where: { id: actorId } });
      if (!actor?.is_active || actor.role !== 'ADMIN') throw { statusCode: 403, message: 'Chỉ quản trị viên được đổi mật khẩu tài khoản' };
      const user = await users.findOne({ where: { id }, lock: { mode: 'pessimistic_write' } });
      if (!user) throw { statusCode: 404, message: 'Không tìm thấy người dùng' };
      user.password_hash = hash;
      user.must_change_password = data.must_change_password;
      await users.save(user);
      await manager.getRepository(RefreshToken).update({ user_id: id }, { revoked_at: new Date() });
      await new AuditLogService().record({ user_id: actorId, action: 'USER_PASSWORD_RESET', entity_type: 'user', entity_id: id,
        details: { target_role: user.role, must_change_password: user.must_change_password, self: actorId === id } }, manager);
      return { id, must_change_password: user.must_change_password, requires_relogin: actorId === id };
    });
  }

  async findAll(query:any={}) {
    const page=Math.max(Number(query.page)||1,1),limit=Math.min(Math.max(Number(query.limit)||20,1),100);const qb=this.repository.createQueryBuilder('u').select(['u.id','u.full_name','u.email','u.phone','u.role','u.department_id','u.is_active','u.created_at']).orderBy('u.created_at','DESC').skip((page-1)*limit).take(limit);if(query.role)qb.andWhere('u.role=:role',{role:query.role});if(query.search)qb.andWhere('(u.full_name ILIKE :s OR u.email ILIKE :s)',{s:`%${query.search}%`});const[data,total]=await qb.getManyAndCount();return{data,total,page,limit,totalPages:Math.ceil(total/limit)};
    /*return this.repository.find({
      select: { id: true, full_name: true, email: true, phone: true, role: true, department_id: true, is_active: true, created_at: true },
      order: { created_at: 'DESC' },
    });*/
  }

  async findOne(id: string) {
    const user = await this.repository.createQueryBuilder('u').leftJoin('departments','d','d.id=u.department_id').select(['u.id AS id','u.full_name AS full_name','u.email AS email','u.phone AS phone','u.role AS role','u.department_id AS department_id','u.is_active AS is_active','u.must_change_password AS must_change_password','u.created_at AS created_at','d.name AS department_name']).where('u.id=:id',{id}).getRawOne();
    if (!user) throw { statusCode: 404, message: 'Không tìm thấy người dùng' };
    return user;
  }

  async create(data: any) {
    const existingUser = await this.repository.findOne({ where: { email: data.email } });
    if (existingUser) {
      throw { statusCode: 409, message: 'Email đã được sử dụng' };
    }

    const hashedPassword = await argon2.hash(data.password);
    const newUser = this.repository.create({
      full_name: data.full_name,
      email: data.email,
      phone: data.phone,
      role: data.role,
      department_id: data.department_id,
      is_active: data.is_active ?? true,
      must_change_password: data.role==='ADMIN'||data.role==='OFFICER',
      password_hash: hashedPassword,
    });

    await this.repository.save(newUser);
    const { password_hash, ...userWithoutPassword } = newUser;
    return userWithoutPassword;
  }

  async update(id: string, data: any) {
    const user = await this.repository.findOne({ where: { id } });
    if (!user) throw { statusCode: 404, message: 'Không tìm thấy người dùng' };
    Object.assign(user, data);
    const saved = await this.repository.save(user);
    const { password_hash, ...result } = saved;
    return result;
  }

  async updateProfile(id: string, data: { full_name?: string; phone?: string }) {
    const user = await this.repository.findOne({ where: { id } });
    if (!user) throw { statusCode: 404, message: 'Không tìm thấy người dùng' };
    if (data.full_name !== undefined) user.full_name = data.full_name;
    if (data.phone !== undefined) user.phone = data.phone;
    await this.repository.save(user);
    const { password_hash, ...profile } = user;
    return profile;
  }

  async delete(id: string) {
    const user = await this.repository.findOne({where:{id}});if(!user)throw{statusCode:404,message:'Không tìm thấy người dùng'};
    user.is_active=false;await this.repository.save(user);
    return { id };
  }
}
