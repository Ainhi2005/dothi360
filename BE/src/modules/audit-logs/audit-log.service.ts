import { EntityManager } from 'typeorm';
import { AppDataSource } from '../../database/data-source';
import { AuditLog } from './audit-log.entity';

export class AuditLogService {
  async record(input: Partial<AuditLog>, manager: EntityManager = AppDataSource.manager) {
    const repo = manager.getRepository(AuditLog);
    return repo.save(repo.create({ ...input, details: input.details ?? {} }));
  }

  async list(page = 1, limit = 50) {
    const [data, total] = await AppDataSource.getRepository(AuditLog).findAndCount({
      order: { created_at: 'DESC' }, skip: (page - 1) * limit, take: Math.min(limit, 100),
    });
    return { data, total, page, limit };
  }
}
