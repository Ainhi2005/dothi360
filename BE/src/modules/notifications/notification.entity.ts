import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('notifications')
export class Notification {
  @PrimaryGeneratedColumn('uuid') id!: string;
  @Column('uuid') user_id!: string;
  @Column({ type: 'uuid', nullable: true }) incident_id!: string | null;
  @Column({ type: 'varchar', length: 50 }) type!: string;
  @Column({ type: 'varchar', length: 200 }) title!: string;
  @Column('text') message!: string;
  @Column({ type: 'jsonb', default: {} }) data!: Record<string, unknown>;
  @Column({ type: 'boolean', default: false }) is_read!: boolean;
  @Column({ type: 'timestamptz', nullable: true }) read_at!: Date | null;
  @Column({ type: 'varchar', length: 20, default: 'PENDING' }) push_status!: string;
  @Column({ type: 'smallint', default: 0 }) push_attempts!: number;
  @Column({ type: 'timestamptz', nullable: true }) push_sent_at!: Date | null;
  @Column({ type: 'text', nullable: true }) push_last_error!: string | null;
  @CreateDateColumn({ type: 'timestamptz' }) created_at!: Date;
}
