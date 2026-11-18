import { MigrationInterface, QueryRunner } from 'typeorm';
export class InterestedAreas1700000008000 implements MigrationInterface {
  name='InterestedAreas1700000008000';
  async up(q:QueryRunner){await q.query(`CREATE TABLE user_interested_areas(
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),user_id UUID NOT NULL,name VARCHAR(80) NOT NULL,
    center GEOGRAPHY(Point,4326) NOT NULL,radius_m INTEGER NOT NULL DEFAULT 1000,
    notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_interested_area_radius CHECK(radius_m BETWEEN 200 AND 10000),
    CONSTRAINT fk_interested_area_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE);
    CREATE UNIQUE INDEX uq_interested_area_user_name_active ON user_interested_areas(user_id,LOWER(name)) WHERE is_active=TRUE;
    CREATE INDEX idx_interested_area_center_gist ON user_interested_areas USING GIST(center);
    CREATE INDEX idx_interested_area_user_active ON user_interested_areas(user_id,is_active);`)}
  async down(q:QueryRunner){await q.query('DROP TABLE IF EXISTS user_interested_areas')}
}
