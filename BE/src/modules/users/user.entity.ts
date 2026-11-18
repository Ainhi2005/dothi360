/** Entity ánh xạ bảng users và các quan hệ liên quan. */
import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 150 })
  full_name!: string;

  @Column({ type: 'varchar', length: 255, unique: true })
  email!: string;

  @Column({ type: 'varchar', length: 255 })
  password_hash!: string;

  @Column({ type: 'varchar', length: 20, unique: true, nullable: true })
  phone!: string;

  @Column({ type: 'varchar', length: 20 })
  role!: string;

  @Column({ type: 'uuid', nullable: true })
  department_id!: string | null;

  @Column({ type: 'boolean', default: true })
  is_active!: boolean;
  @Column({type:'boolean',default:false}) must_change_password!:boolean;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updated_at!: Date;
}
