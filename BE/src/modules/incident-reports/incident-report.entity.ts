import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, JoinColumn, ManyToOne } from 'typeorm';
import { Point } from '../departments/department.entity';
import { Incident } from '../incidents/incident.entity';

@Entity('incident_reports')
export class IncidentReport {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  incident_id!: string;

  @ManyToOne(() => Incident)
  @JoinColumn({ name: 'incident_id' })
  incident!: Incident;

  @Column({ type: 'uuid' })
  reporter_id!: string;

  @Column({ type: 'text' })
  description!: string;

  @Column({
    type: 'geography',
    spatialFeatureType: 'Point',
    srid: 4326,
  })
  reported_location!: Point;

  @Column({ type: 'text', nullable: true })
  reported_address!: string | null;

  @Column({ type: 'varchar', length: 20, default: 'GPS' })
  location_source!: 'GPS' | 'MAP' | 'SEARCH';

  @Column({ type: 'smallint', nullable: true })
  reported_severity!: number | null;

  @Column({ type: 'numeric', precision: 10, scale: 2, nullable: true })
  duplicate_distance_m!: number | null;

  @Column({ type: 'numeric', precision: 10, scale: 2, nullable: true })
  duplicate_time_minutes!: number | null;

  @Column({ type: 'numeric', precision: 5, scale: 4, nullable: true })
  duplicate_score!: number | null;

  @Column({ type: 'jsonb', nullable: true })
  duplicate_evidence!: Record<string, unknown> | null;

  @Column({ type:'jsonb', nullable:true })
  ai_analysis!: Record<string,unknown>|null;

  @Column({ type:'boolean', default:false })
  requires_manual_review!: boolean;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;
}
