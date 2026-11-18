import { AppDataSource } from '../../database/data-source';
import { IncidentType } from './incident-type.entity';

export class IncidentTypeService {
  private repo = AppDataSource.getRepository(IncidentType);

  async findAll() {
    return this.repo.find({ order: { created_at: 'DESC' } });
  }

  async findOne(id: string) {
    const type = await this.repo.findOne({ where: { id } });
    if (!type) throw { statusCode: 404, message: 'Loại sự cố không tồn tại' };
    return type;
  }

  async create(data: Partial<IncidentType>) {
    const existing = await this.repo.findOne({ where: { code: data.code } });
    if (existing) throw { statusCode: 400, message: 'Mã loại sự cố đã tồn tại' };

    const newType = this.repo.create(data);
    return this.repo.save(newType);
  }

  async update(id: string, data: Partial<IncidentType>) {
    const type = await this.findOne(id);
    Object.assign(type, data);
    return this.repo.save(type);
  }

  async remove(id: string) {
    const type = await this.findOne(id);
    type.is_active=false;await this.repo.save(type);
    return true;
  }
}
