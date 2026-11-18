import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';

@Entity('algorithm_configs')
export class AlgorithmConfig {
  @PrimaryGeneratedColumn('uuid') id!: string;
  @Column({ type: 'varchar', length: 100 }) config_key!: string;
  @Column('jsonb') config_value!: Record<string, number>;
  @Column({ type: 'integer', default: 1 }) version!: number;
  @Column({ type: 'text', nullable: true }) description!: string | null;
  @Column({ type: 'boolean', default: false }) is_active!: boolean;
  @Column({ type: 'uuid', nullable: true }) updated_by!: string | null;
  @CreateDateColumn({ type: 'timestamptz' }) created_at!: Date;
  @UpdateDateColumn({ type: 'timestamptz' }) updated_at!: Date;
}
