import { MigrationInterface, QueryRunner } from 'typeorm';

export class AlignRefreshTokens1700000001000 implements MigrationInterface {
  name = 'AlignRefreshTokens1700000001000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE refresh_tokens ADD COLUMN IF NOT EXISTS revoked_at TIMESTAMPTZ;
      ALTER TABLE refresh_tokens ADD COLUMN IF NOT EXISTS replaced_by_id UUID;
      ALTER TABLE refresh_tokens ADD COLUMN IF NOT EXISTS user_agent TEXT;
      ALTER TABLE refresh_tokens ADD COLUMN IF NOT EXISTS ip_address INET;

      DO $$
      BEGIN
        IF EXISTS (
          SELECT 1 FROM information_schema.columns
          WHERE table_schema = 'public'
            AND table_name = 'refresh_tokens'
            AND column_name = 'is_revoked'
        ) THEN
          UPDATE refresh_tokens
          SET revoked_at = COALESCE(revoked_at, CURRENT_TIMESTAMP)
          WHERE is_revoked = TRUE;
          ALTER TABLE refresh_tokens DROP COLUMN is_revoked;
        END IF;
      END $$;

      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_constraint WHERE conname = 'fk_refresh_tokens_replacement'
        ) THEN
          ALTER TABLE refresh_tokens
          ADD CONSTRAINT fk_refresh_tokens_replacement
          FOREIGN KEY (replaced_by_id) REFERENCES refresh_tokens(id)
          ON UPDATE CASCADE ON DELETE SET NULL;
        END IF;
      END $$;

      CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_active
      ON refresh_tokens (user_id, expires_at) WHERE revoked_at IS NULL;
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE refresh_tokens ADD COLUMN IF NOT EXISTS is_revoked BOOLEAN NOT NULL DEFAULT FALSE;
      UPDATE refresh_tokens SET is_revoked = TRUE WHERE revoked_at IS NOT NULL;
      DROP INDEX IF EXISTS idx_refresh_tokens_user_active;
      ALTER TABLE refresh_tokens DROP CONSTRAINT IF EXISTS fk_refresh_tokens_replacement;
      ALTER TABLE refresh_tokens DROP COLUMN IF EXISTS ip_address;
      ALTER TABLE refresh_tokens DROP COLUMN IF EXISTS user_agent;
      ALTER TABLE refresh_tokens DROP COLUMN IF EXISTS replaced_by_id;
      ALTER TABLE refresh_tokens DROP COLUMN IF EXISTS revoked_at;
    `);
  }
}
