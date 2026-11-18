import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('incident_updates')
export class IncidentUpdate {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  incident_id!: string;

  @Column({ type: 'uuid' })
  updated_by!: string;

  @Column({ type: 'varchar', length: 30, nullable: true })
  old_status!: string | null;

  @Column({ type: 'varchar', length: 30, nullable: true })
  new_status!: string | null;

  @Column({ type: 'text', nullable: true })
  note!: string | null;

  @Column({ type: 'smallint', nullable: true })
  progress_percent!: number | null;

  @Column({ type: 'timestamptz', nullable: true })
  estimated_completion_at!: Date | null;

  @Column({ type: 'text', nullable: true })
  blocker!: string | null;

  @Column({ type: 'varchar', length: 20, default: 'PUBLIC' })
  visibility!: 'PUBLIC' | 'INTERNAL';

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;
}
