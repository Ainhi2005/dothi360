import { AppDataSource } from '../../database/data-source';
import { EmergencyContact } from './emergency-contact.entity';
import { ILike } from 'typeorm';

export class EmergencyContactService {
  private repo = AppDataSource.getRepository(EmergencyContact);

  async getPublicContacts(query: { category?: string; q?: string } = {}) {
    const qb = this.repo.createQueryBuilder('contact')
      .where('contact.is_active = TRUE');

    if (query.category && query.category !== 'ALL') {
      qb.andWhere('contact.category = :category', { category: query.category });
    }

    if (query.q) {
      qb.andWhere('(contact.name ILIKE :q OR contact.phone_number ILIKE :q OR contact.description ILIKE :q)', {
        q: `%${query.q.trim()}%`,
      });
    }

    return qb.orderBy('contact.is_hotline', 'DESC')
      .addOrderBy('contact.sort_order', 'ASC')
      .addOrderBy('contact.name', 'ASC')
      .getMany();
  }

  async getAdminContacts(query: { category?: string; q?: string } = {}) {
    const qb = this.repo.createQueryBuilder('contact');

    if (query.category && query.category !== 'ALL') {
      qb.andWhere('contact.category = :category', { category: query.category });
    }

    if (query.q) {
      qb.andWhere('(contact.name ILIKE :q OR contact.phone_number ILIKE :q OR contact.description ILIKE :q)', {
        q: `%${query.q.trim()}%`,
      });
    }

    return qb.orderBy('contact.sort_order', 'ASC')
      .addOrderBy('contact.name', 'ASC')
      .getMany();
  }

  async getById(id: string) {
    const contact = await this.repo.findOne({ where: { id } });
    if (!contact) throw { statusCode: 404, message: 'Không tìm thấy số liên hệ khẩn cấp' };
    return contact;
  }

  async create(data: Partial<EmergencyContact>) {
    const contact = this.repo.create(data);
    return this.repo.save(contact);
  }

  async update(id: string, data: Partial<EmergencyContact>) {
    const contact = await this.getById(id);
    Object.assign(contact, data);
    return this.repo.save(contact);
  }

  async delete(id: string) {
    const contact = await this.getById(id);
    contact.is_active = !contact.is_active;
    return this.repo.save(contact);
  }
}
