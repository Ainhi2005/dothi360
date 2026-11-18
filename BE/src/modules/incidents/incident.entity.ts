import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';
import { Point } from '../departments/department.entity';
import { ManyToOne, JoinColumn } from 'typeorm';
import { IncidentType } from '../incident-types/incident-type.entity';

@Entity('incidents')
export class Incident {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  incident_type_id!: string;

  @ManyToOne(() => IncidentType)
  @JoinColumn({ name: 'incident_type_id' })
  incident_type!: IncidentType;
  @Column({ type: 'text' })
  description!: string;

  @Column({
    type: 'geography',
    spatialFeatureType: 'Point',
    srid: 4326,
  })
  location!: Point;

  @Column({ type: 'smallint' })
  severity_level!: number;

  @Column({ type: 'varchar', length: 30, default: 'PENDING_ASSIGNMENT' })
  status!: string;

  @Column({ type: 'numeric', precision: 5, scale: 2, nullable: true })
  priority_score!: number | null;

  @Column({ type: 'varchar', length: 20, nullable: true })
  priority_level!: string | null;

  @Column({ type: 'integer', default: 1 })
  report_count!: number;

  @Column({ type: 'uuid', nullable: true })
  ai_suggested_department_id!: string | null;

  @Column({ type: 'uuid', nullable: true })
  ai_suggested_officer_id!: string | null;

  @Column({ type: 'text', nullable: true })
  ai_suggestion_reason!: string | null;

  @Column({ type: 'numeric', precision: 4, scale: 2, nullable: true })
  ai_suggestion_confidence!: number | null;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updated_at!: Date;

  @Column({ type: 'timestamptz', nullable: true })
  resolved_at!: Date | null;
}
