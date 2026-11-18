import { AppDataSource } from '../../database/data-source';
import { NotificationService } from '../notifications/notification.service';
import { AuditLogService } from '../audit-logs/audit-log.service';

export class FeedbackService {
  private audit = new AuditLogService();

  async list(options: {
    page?: number;
    limit?: number;
    category?: string;
    status?: string;
    sort?: 'newest' | 'upvotes';
    userId?: string;
  }) {
    const page = Math.max(Number(options.page) || 1, 1);
    const limit = Math.min(Math.max(Number(options.limit) || 20, 1), 100);
    const offset = (page - 1) * limit;

    const conditions: string[] = ['1=1'];
    const params: any[] = [];
    let idx = 1;

    if (options.category && options.category !== 'ALL') {
      conditions.push(`f.category = $${idx++}`);
      params.push(options.category);
    }

    if (options.status && options.status !== 'ALL') {
      conditions.push(`f.status = $${idx++}`);
      params.push(options.status);
    }

    const currentUserId = options.userId || null;
    params.push(currentUserId);
    const userIdx = idx++;

    const orderBy =
      options.sort === 'upvotes'
        ? 'f.upvotes DESC, f.created_at DESC'
        : 'f.created_at DESC';

    params.push(limit);
    const limitIdx = idx++;
    params.push(offset);
    const offsetIdx = idx++;

    const query = `
      SELECT 
        f.id,
        f.user_id,
        f.title,
        f.content,
        f.category,
        f.location_name,
        f.upvotes,
        f.status,
        f.admin_response,
        f.responded_at,
        f.created_at,
        f.updated_at,
        u.full_name AS user_name,
        r.full_name AS responder_name,
        CASE WHEN $${userIdx}::uuid IS NOT NULL AND EXISTS(
          SELECT 1 FROM citizen_feedback_upvotes v 
          WHERE v.feedback_id = f.id AND v.user_id = $${userIdx}::uuid
        ) THEN TRUE ELSE FALSE END AS is_upvoted
      FROM citizen_feedbacks f
      JOIN users u ON u.id = f.user_id
      LEFT JOIN users r ON r.id = f.responded_by
      WHERE ${conditions.join(' AND ')}
      ORDER BY ${orderBy}
      LIMIT $${limitIdx} OFFSET $${offsetIdx}
    `;

    const countQuery = `
      SELECT COUNT(*)::int AS total
      FROM citizen_feedbacks f
      WHERE ${conditions.join(' AND ')}
    `;

    const [rows, countResult] = await Promise.all([
      AppDataSource.query(query, params),
      AppDataSource.query(countQuery, params.slice(0, userIdx - 1)),
    ]);

    const total = Number(countResult[0]?.total || 0);

    return {
      data: rows,
      meta: {
        page,
        limit,
        total,
        total_pages: Math.ceil(total / limit),
      },
    };
  }

  async getMine(userId: string, page = 1, limit = 20) {
    const offset = (Math.max(page, 1) - 1) * limit;
    const rows = await AppDataSource.query(
      `SELECT 
        f.*,
        u.full_name AS user_name,
        r.full_name AS responder_name,
        TRUE AS is_upvoted
       FROM citizen_feedbacks f
       JOIN users u ON u.id = f.user_id
       LEFT JOIN users r ON r.id = f.responded_by
       WHERE f.user_id = $1
       ORDER BY f.created_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );
    const count = await AppDataSource.query(
      'SELECT COUNT(*)::int AS total FROM citizen_feedbacks WHERE user_id = $1',
      [userId]
    );
    const total = Number(count[0]?.total || 0);
    return {
      data: rows,
      meta: { page, limit, total, total_pages: Math.ceil(total / limit) },
    };
  }

  async getDetail(id: string, currentUserId?: string) {
    const rows = await AppDataSource.query(
      `SELECT 
        f.*,
        u.full_name AS user_name,
        r.full_name AS responder_name,
        CASE WHEN $2::uuid IS NOT NULL AND EXISTS(
          SELECT 1 FROM citizen_feedback_upvotes v 
          WHERE v.feedback_id = f.id AND v.user_id = $2::uuid
        ) THEN TRUE ELSE FALSE END AS is_upvoted
       FROM citizen_feedbacks f
       JOIN users u ON u.id = f.user_id
       LEFT JOIN users r ON r.id = f.responded_by
       WHERE f.id = $1`,
      [id, currentUserId ?? null]
    );
    if (!rows.length) throw { statusCode: 404, message: 'Không tìm thấy góp ý' };
    return rows[0];
  }

  async create(userId: string, data: {
    title: string;
    content: string;
    category?: string;
    location_name?: string;
    latitude?: number;
    longitude?: number;
  }) {
    let locationSql = 'NULL';
    const params: any[] = [
      userId,
      data.title,
      data.content,
      data.category || 'GENERAL',
      data.location_name || null,
    ];

    if (data.latitude && data.longitude) {
      params.push(data.longitude, data.latitude);
      locationSql = `ST_SetSRID(ST_MakePoint($6, $7), 4326)::geography`;
    }

    return AppDataSource.transaction(async (manager) => {
    const [row] = await manager.query(
      `INSERT INTO citizen_feedbacks (user_id, title, content, category, location_name, location)
       VALUES ($1, $2, $3, $4, $5, ${locationSql})
       RETURNING *`,
      params
    );

    await this.audit.record({
      user_id: userId,
      action: 'CITIZEN_FEEDBACK_CREATED',
      entity_type: 'citizen_feedback',
      entity_id: row.id,
      details: { title: data.title, category: data.category },
    }, manager);
    await new NotificationService().notifyAdmins({
      eventKey: `feedback:${row.id}`, type: 'FEEDBACK_PENDING_REVIEW',
      title: 'Có góp ý mới cần phản hồi', message: data.title,
      actionPath: `/citizen-feedbacks?feedbackId=${row.id}`, actionLabel: 'Xem và phản hồi',
      data: { feedback_id: row.id },
    }, manager);
    return row;
    });
  }

  async toggleUpvote(feedbackId: string, userId: string) {
    return AppDataSource.transaction(async (m) => {
      const [feedback] = await m.query(
        'SELECT id, upvotes FROM citizen_feedbacks WHERE id = $1',
        [feedbackId]
      );
      if (!feedback) throw { statusCode: 404, message: 'Góp ý không tồn tại' };

      const [existing] = await m.query(
        'SELECT 1 FROM citizen_feedback_upvotes WHERE feedback_id = $1 AND user_id = $2',
        [feedbackId, userId]
      );

      let isUpvoted = false;
      let newUpvotes = feedback.upvotes;

      if (existing) {
        await m.query(
          'DELETE FROM citizen_feedback_upvotes WHERE feedback_id = $1 AND user_id = $2',
          [feedbackId, userId]
        );
        newUpvotes = Math.max(0, feedback.upvotes - 1);
        await m.query(
          'UPDATE citizen_feedbacks SET upvotes = $1, updated_at = NOW() WHERE id = $2',
          [newUpvotes, feedbackId]
        );
        isUpvoted = false;
      } else {
        await m.query(
          'INSERT INTO citizen_feedback_upvotes (feedback_id, user_id) VALUES ($1, $2)',
          [feedbackId, userId]
        );
        newUpvotes = feedback.upvotes + 1;
        await m.query(
          'UPDATE citizen_feedbacks SET upvotes = $1, updated_at = NOW() WHERE id = $2',
          [newUpvotes, feedbackId]
        );
        isUpvoted = true;
      }

      return {
        feedback_id: feedbackId,
        is_upvoted: isUpvoted,
        upvotes: newUpvotes,
      };
    });
  }

  async respond(id: string, adminId: string, data: { status: 'ACCEPTED' | 'REJECTED'; response_note: string }) {
    return AppDataSource.transaction(async (m) => {
      const result = await m.query(
        `UPDATE citizen_feedbacks 
         SET status = $2, admin_response = $3, responded_at = NOW(), responded_by = $4, updated_at = NOW()
         WHERE id = $1
         RETURNING *`,
        [id, data.status, data.response_note, adminId]
      );
      const row = Array.isArray(result[0]) ? result[0][0] : result[0];
      if (!row) throw { statusCode: 404, message: 'Không tìm thấy góp ý' };

      await this.audit.record({
        user_id: adminId,
        action: `CITIZEN_FEEDBACK_${data.status}`,
        entity_type: 'citizen_feedback',
        entity_id: id,
        details: { response_note: data.response_note, status: data.status },
      }, m);

      await new NotificationService().create({
        user_id: row.user_id, incident_id: null, type: 'FEEDBACK_RESPONDED',
        title: data.status === 'ACCEPTED' ? 'Góp ý của bạn đã được tiếp nhận' : 'Góp ý của bạn đã được phản hồi',
        message: data.response_note, data: { feedback_id: id, status: data.status },
      }, m);
      return row;
    });
  }
}

