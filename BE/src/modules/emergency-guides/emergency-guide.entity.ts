import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

export type EmergencyPhone = { label: string; number: string };

@Entity('emergency_guides')
export class EmergencyGuide {
  @PrimaryGeneratedColumn('uuid') id!: string;
  @Column({ type: 'varchar', length: 60, unique: true }) code!: string;
  @Column({ type: 'varchar', length: 160 }) title!: string;
  @Column({ type: 'varchar', length: 300 }) summary!: string;
  @Column({ type: 'varchar', length: 40, default: 'warning' }) icon!: string;
  @Column({ type: 'varchar', length: 20, default: 'danger' }) accent!: string;
  @Column({ type: 'jsonb', default: () => "'[]'::jsonb" }) do_now!: string[];
  @Column({ type: 'jsonb', default: () => "'[]'::jsonb" }) avoid!: string[];
  @Column({ type: 'jsonb', default: () => "'[]'::jsonb" }) phone_numbers!: EmergencyPhone[];
  @Column({ type: 'integer', default: 0 }) sort_order!: number;
  @Column({ type: 'boolean', default: true }) is_active!: boolean;
  @CreateDateColumn({ type: 'timestamptz' }) created_at!: Date;
  @UpdateDateColumn({ type: 'timestamptz' }) updated_at!: Date;
}
