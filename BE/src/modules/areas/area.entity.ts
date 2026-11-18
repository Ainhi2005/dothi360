import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

@Entity('areas')
export class Area {
  @PrimaryGeneratedColumn('uuid') id!: string;
  @Column('uuid') department_id!: string;
  @Column({ type: 'varchar', length: 200 }) name!: string;
  @Column({ type: 'geometry', spatialFeatureType: 'Polygon', srid: 4326 }) geom!: { type: 'Polygon'; coordinates: number[][][] };
  @Column({ type: 'boolean', default: true }) is_active!: boolean;
  @CreateDateColumn({ type: 'timestamptz' }) created_at!: Date;
  @UpdateDateColumn({ type: 'timestamptz' }) updated_at!: Date;
}
