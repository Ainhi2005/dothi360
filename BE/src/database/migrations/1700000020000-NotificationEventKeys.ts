import { MigrationInterface, QueryRunner } from 'typeorm';

export class NotificationEventKeys1700000020000 implements MigrationInterface {
  name = 'NotificationEventKeys1700000020000';
  async up(q: QueryRunner): Promise<void> {
    await q.query(`CREATE UNIQUE INDEX IF NOT EXISTS uq_notifications_user_event
      ON notifications(user_id, (data->>'event_key')) WHERE data ? 'event_key'`);
  }
  async down(q: QueryRunner): Promise<void> {
    await q.query('DROP INDEX IF EXISTS uq_notifications_user_event');
  }
}
