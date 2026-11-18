import { MigrationInterface, QueryRunner } from 'typeorm';

export class CitizenFeedbacks1700000016000 implements MigrationInterface {
  name = 'CitizenFeedbacks1700000016000';

  async up(q: QueryRunner): Promise<void> {
    await q.query(`
      CREATE TABLE IF NOT EXISTS citizen_feedbacks (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        title VARCHAR(250) NOT NULL,
        content TEXT NOT NULL,
        category VARCHAR(50) NOT NULL DEFAULT 'GENERAL',
        location_name VARCHAR(255),
        location GEOGRAPHY(Point, 4326),
        upvotes INTEGER NOT NULL DEFAULT 0,
        status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
        admin_response TEXT,
        responded_at TIMESTAMPTZ,
        responded_by UUID REFERENCES users(id) ON DELETE SET NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        CONSTRAINT ck_feedback_status CHECK (status IN ('PENDING', 'ACCEPTED', 'REJECTED')),
        CONSTRAINT ck_feedback_category CHECK (category IN ('TRAFFIC', 'GREENERY', 'LIGHTING', 'DRAINAGE', 'ENVIRONMENT', 'GENERAL'))
      );

      CREATE TABLE IF NOT EXISTS citizen_feedback_upvotes (
        feedback_id UUID NOT NULL REFERENCES citizen_feedbacks(id) ON DELETE CASCADE,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        PRIMARY KEY (feedback_id, user_id)
      );

      CREATE INDEX IF NOT EXISTS idx_feedbacks_user ON citizen_feedbacks(user_id, created_at DESC);
      CREATE INDEX IF NOT EXISTS idx_feedbacks_status_created ON citizen_feedbacks(status, created_at DESC);
      CREATE INDEX IF NOT EXISTS idx_feedbacks_upvotes ON citizen_feedbacks(upvotes DESC, created_at DESC);
    `);
  }

  async down(q: QueryRunner): Promise<void> {
    await q.query(`
      DROP TABLE IF EXISTS citizen_feedback_upvotes CASCADE;
      DROP TABLE IF EXISTS citizen_feedbacks CASCADE;
    `);
  }
}

