import { EntityManager } from 'typeorm';
import { AppDataSource } from '../../database/data-source';
import { AlgorithmConfig } from './algorithm-config.entity';
import { AuditLogService } from '../audit-logs/audit-log.service';

export const CONFIG_DEFAULTS = {
  PRIORITY_SCORING: { type_weight: .30, severity_weight: .35, duplicate_weight: .20, waiting_weight: .15, waiting_cap_hours: 48, emergency_min: 80, high_min: 60, medium_min: 40 },
  DEPARTMENT_ASSIGNMENT: { fallback_radius_meters: 5000 },
};

export class AlgorithmConfigService {
  async getActive(key: 'PRIORITY_SCORING', manager?: EntityManager): Promise<typeof CONFIG_DEFAULTS.PRIORITY_SCORING>;
  async getActive(key: 'DEPARTMENT_ASSIGNMENT', manager?: EntityManager): Promise<typeof CONFIG_DEFAULTS.DEPARTMENT_ASSIGNMENT>;
  async getActive(key: keyof typeof CONFIG_DEFAULTS, manager: EntityManager = AppDataSource.manager) {
    const row = await manager.getRepository(AlgorithmConfig).findOne({ where: { config_key: key, is_active: true } });
    return { ...CONFIG_DEFAULTS[key], ...(row?.config_value ?? {}) };
  }
  list() { return AppDataSource.getRepository(AlgorithmConfig).find({ order: { config_key: 'ASC', version: 'DESC' } }); }
  async activate(key: keyof typeof CONFIG_DEFAULTS, value: Record<string, number>, description: string | undefined, adminId: string) {
    this.validate(key, value);
    return AppDataSource.transaction(async manager => {
      const repo = manager.getRepository(AlgorithmConfig);
      const latest = await repo.findOne({ where: { config_key: key }, order: { version: 'DESC' }, lock: { mode: 'pessimistic_write' } });
      await repo.update({ config_key: key, is_active: true }, { is_active: false });
      const saved = await repo.save(repo.create({ config_key: key, config_value: value, version: (latest?.version ?? 0) + 1, description, is_active: true, updated_by: adminId }));
      await new AuditLogService().record({ user_id: adminId, action: 'ALGORITHM_CONFIG_ACTIVATED', entity_type: 'algorithm_config', entity_id: saved.id, details: { key, version: saved.version, value } }, manager);
      return saved;
    });
  }
  private validate(key: keyof typeof CONFIG_DEFAULTS, value: Record<string, number>) {
    if (key === 'DEPARTMENT_ASSIGNMENT' && (!(value.fallback_radius_meters > 0) || value.fallback_radius_meters > 100000)) throw { statusCode: 400, message: 'Bán kính fallback phải từ 1 đến 100000 mét' };
    if (key === 'PRIORITY_SCORING') {
      const weights = ['type_weight','severity_weight','duplicate_weight','waiting_weight'];
      const sum = weights.reduce((n, k) => n + Number(value[k]), 0);
      if (weights.some(k => value[k] < 0 || value[k] > 1) || Math.abs(sum - 1) > .001) throw { statusCode: 400, message: 'Các trọng số phải từ 0 đến 1 và có tổng bằng 1' };
      if (!(value.medium_min < value.high_min && value.high_min < value.emergency_min && value.emergency_min <= 100)) throw { statusCode: 400, message: 'Ngưỡng ưu tiên không hợp lệ' };
    }
  }
}
