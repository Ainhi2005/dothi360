import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';
import { Point } from '../departments/department.entity';

@Entity('user_interested_areas')
export class InterestedArea {
  @PrimaryGeneratedColumn('uuid') id!: string;
  @Column('uuid') user_id!: string;
  @Column({ type: 'varchar', length: 80 }) name!: string;
  @Column({ type: 'geography', spatialFeatureType: 'Point', srid: 4326 }) center!: Point;
  @Column({ type: 'integer', default: 1000 }) radius_m!: number;
  @Column({ type: 'boolean', default: true }) notifications_enabled!: boolean;
  @Column({ type: 'boolean', default: true }) is_active!: boolean;
  @CreateDateColumn({ type: 'timestamptz' }) created_at!: Date;
  @UpdateDateColumn({ type: 'timestamptz' }) updated_at!: Date;
}
