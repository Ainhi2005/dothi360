import { AppDataSource } from '../../database/data-source';
import { Department } from './department.entity';

export class DepartmentService {
  private repository = AppDataSource.getRepository(Department);

  async findAll() {
    return this.repository.find({ order: { created_at: 'DESC' } });
  }

  async findOne(id: string) {
    const department = await this.repository.findOne({ where: { id } });
    if (!department) throw { statusCode: 404, message: 'Không tìm thấy đơn vị' };
    return department;
  }

  async create(data: any) {
    const existing = await this.repository.findOne({
      where: [{ code: data.code }, { name: data.name }],
    });
    if (existing) {
      throw { statusCode: 409, message: 'Mã hoặc Tên đơn vị đã tồn tại' };
    }

    let location = null;
    if (data.longitude !== undefined && data.latitude !== undefined) {
      location = {
        type: 'Point',
        coordinates: [data.longitude, data.latitude],
      };
    }

    const newDept = this.repository.create({
      ...data,
      location,
    });
    return this.repository.save(newDept);
  }

  async update(id: string, data: any) {
    const department = await this.findOne(id);
    
    if (data.longitude !== undefined && data.latitude !== undefined) {
      data.location = {
        type: 'Point',
        coordinates: [data.longitude, data.latitude],
      };
      delete data.longitude;
      delete data.latitude;
    }

    Object.assign(department, data);
    return this.repository.save(department);
  }

  async delete(id: string) {
    const department = await this.findOne(id);
    department.is_active=false;await this.repository.save(department);
    return { id };
  }
  async getCapabilities(id:string){await this.findOne(id);return AppDataSource.query(`SELECT dit.incident_type_id,it.name,dit.is_active FROM department_incident_types dit JOIN incident_types it ON it.id=dit.incident_type_id WHERE dit.department_id=$1 ORDER BY it.name`,[id]);}
  async setCapabilities(id:string,typeIds:string[]){await this.findOne(id);return AppDataSource.transaction(async m=>{await m.query('DELETE FROM department_incident_types WHERE department_id=$1',[id]);if(typeIds.length)await m.query(`INSERT INTO department_incident_types(department_id,incident_type_id) SELECT $1,unnest($2::uuid[])`,[id,typeIds]);return this.getCapabilities(id);});}
}
