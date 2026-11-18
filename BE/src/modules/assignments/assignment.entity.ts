import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('incident_assignments')
export class IncidentAssignment {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  incident_id!: string;

  @Column({ type: 'uuid' })
  department_id!: string;

  @Column({ type: 'uuid', nullable: true })
  assigned_by!: string | null;

  @Column({ type: 'uuid', nullable: true })
  assigned_officer_id!: string | null;

  @Column({ type: 'uuid', nullable: true })
  accepted_by!: string | null;

  @Column({ type: 'varchar', length: 30 })
  assignment_method!: string;

  @Column({ type: 'text', nullable: true })
  reason!: string | null;

  @Column({ type: 'integer', nullable: true })
  workload_at_assignment!: number | null;

  @Column({ type: 'numeric', precision: 10, scale: 2, nullable: true })
  distance_m!: number | null;

  @CreateDateColumn({ type: 'timestamptz' })
  assigned_at!: Date;

  @Column({ type: 'timestamptz', nullable: true })
  accepted_at!: Date | null;

  @Column({ type: 'timestamptz', nullable: true })
  ended_at!: Date | null;

  @Column({ type: 'uuid', nullable: true })
  rejected_by!: string | null;

  @Column({ type: 'varchar', length: 40, nullable: true })
  rejection_code!: string | null;

  @Column({ type: 'text', nullable: true })
  rejection_reason!: string | null;

  @Column({ type: 'timestamptz', nullable: true })
  rejected_at!: Date | null;
}
