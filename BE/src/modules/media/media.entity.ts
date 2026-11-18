import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('incident_media')
export class IncidentMedia {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid' })
  incident_id!: string;

  @Column({ type: 'uuid', nullable: true })
  update_id!: string | null;
  
  // Note: in SQL it is report_id. Wait! Actually `report_id`? Let's check: 
  // No, in SQL there's no report_id in `incident_media`? Wait, I saw fk_incident_media_report FOREIGN KEY (report_id) REFERENCES incident_reports(id) in the schema check!
  @Column({ type: 'uuid', nullable: true })
  report_id!: string | null;

  @Column({ type: 'uuid' })
  uploaded_by!: string;

  @Column({ type: 'varchar', length: 20 })
  media_type!: string;

  @Column({ type: 'text' })
  storage_key!: string;

  @Column({ type: 'text' })
  file_url!: string;

  @Column({ type: 'varchar', length: 100 })
  mime_type!: string;

  @Column({ type: 'bigint' })
  file_size!: number;

  @CreateDateColumn({ type: 'timestamptz' })
  created_at!: Date;
}
