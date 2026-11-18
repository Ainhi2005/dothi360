import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

@Entity('emergency_contacts')
export class EmergencyContact {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 160 })
  name!: string;

  @Column({ type: 'varchar', length: 50 })
  phone_number!: string;

  @Column({ type: 'varchar', length: 60, default: 'NATIONAL' })
  category!: string;

  @Column({ type: 'varchar', length: 300 })
  description!: string;

  @Column({ type: 'varchar', length: 40, default: 'phone' })
  icon!: string;

  @Column({ type: 'varchar', length: 20, default: 'primary' })
  accent!: string;

  @Column({ type: 'boolean', default: false })
  is_hotline!: boolean;

  @Column({ type: 'integer', default: 0 })
  sort_order!: number;

  @Column({ type: 'boolean', default: true })
  is_active!: boolean;

  @Column({ type: 'varchar', length: 60, default: '24/7' })
  operating_hours!: string;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updated_at!: Date;
}
