import { AppDataSource } from '../../database/data-source';
import { AuditLogService } from '../audit-logs/audit-log.service';
import { EmergencyGuide } from './emergency-guide.entity';

export class EmergencyGuideService {
  private repo = AppDataSource.getRepository(EmergencyGuide);

  list(activeOnly = true) {
    return this.repo.find({
      where: activeOnly ? { is_active: true } : {},
      order: { sort_order: 'ASC', title: 'ASC' },
    });
  }

  async get(id: string) {
    const guide = await this.repo.findOne({ where: { id } });
    if (!guide || !guide.is_active) throw { statusCode: 404, message: 'Không tìm thấy hướng dẫn khẩn cấp' };
    return guide;
  }

  async create(data: Partial<EmergencyGuide>, actorId: string) {
    return AppDataSource.transaction(async (manager) => {
      const saved = await manager.getRepository(EmergencyGuide).save(manager.getRepository(EmergencyGuide).create(data));
      await new AuditLogService().record({ user_id: actorId, action: 'EMERGENCY_GUIDE_CREATED', entity_type: 'emergency_guide', entity_id: saved.id, details: { code: saved.code, title: saved.title } }, manager);
      return saved;
    });
  }

  async update(id: string, data: Partial<EmergencyGuide>, actorId: string) {
    return AppDataSource.transaction(async (manager) => {
      const repo = manager.getRepository(EmergencyGuide);
      const guide = await repo.findOne({ where: { id } });
      if (!guide) throw { statusCode: 404, message: 'Không tìm thấy hướng dẫn khẩn cấp' };
      const saved = await repo.save(repo.merge(guide, data));
      await new AuditLogService().record({ user_id: actorId, action: 'EMERGENCY_GUIDE_UPDATED', entity_type: 'emergency_guide', entity_id: saved.id, details: { code: saved.code, title: saved.title, is_active: saved.is_active } }, manager);
      return saved;
    });
  }

  async deactivate(id: string, actorId: string) {
    return this.update(id, { is_active: false }, actorId);
  }
}
