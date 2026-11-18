import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('audit_logs')
export class AuditLog {
  @PrimaryGeneratedColumn({ type: 'bigint' }) id!: string;
  @Column({ type: 'uuid', nullable: true }) user_id!: string | null;
  @Column({ type: 'varchar', length: 100 }) action!: string;
  @Column({ type: 'varchar', length: 50, nullable: true }) entity_type!: string | null;
  @Column({ type: 'uuid', nullable: true }) entity_id!: string | null;
  @Column({ type: 'jsonb', default: {} }) details!: Record<string, unknown>;
  @CreateDateColumn({ type: 'timestamptz' }) created_at!: Date;
}
