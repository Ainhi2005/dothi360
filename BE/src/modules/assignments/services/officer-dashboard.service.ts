import { AppDataSource } from "../../../database/data-source";

import { AssignmentServiceDependencies } from "./assignment-dependencies";

/** Tổng quan và hiệu suất cán bộ. */
export class OfficerDashboardService {
  constructor(private readonly deps: AssignmentServiceDependencies) {}

  async getOfficerDashboard(departmentId: string, userId: string) {
    const [summary] = await AppDataSource.query(
      `
      SELECT
        COUNT(*) FILTER (
          WHERE a.ended_at IS NULL AND a.accepted_by IS NULL
            AND (a.assigned_officer_id IS NULL OR a.assigned_officer_id = $2)
            AND i.status = 'ASSIGNED'
        )::int AS queue,
        COUNT(*) FILTER (
          WHERE a.ended_at IS NULL AND a.accepted_by = $2
            AND i.status IN ('ACCEPTED', 'IN_PROGRESS', 'PENDING_VERIFICATION')
        )::int AS mine,
        COUNT(*) FILTER (
          WHERE a.ended_at IS NULL
            AND (a.accepted_by = $2 OR (a.accepted_by IS NULL AND (a.assigned_officer_id IS NULL OR a.assigned_officer_id = $2)))
            AND i.priority_level IN ('HIGH', 'EMERGENCY')
        )::int AS urgent,
        COUNT(*) FILTER (
          WHERE a.ended_at IS NULL
            AND a.accepted_by = $2
            AND a.assigned_at < NOW() - INTERVAL '24 hours'
        )::int AS overdue,
        COUNT(*) FILTER (
          WHERE a.accepted_by = $2 AND a.ended_at IS NOT NULL
            AND i.status = 'RESOLVED' AND a.rejected_at IS NULL
        )::int AS completed
      FROM incident_assignments a
      JOIN incidents i ON i.id = a.incident_id
      WHERE a.department_id = $1
    `,
      [departmentId, userId],
    );

    const [latest] = await AppDataSource.query(
      `
      SELECT a.assigned_at, t.name AS incident_type_name, i.priority_level
      FROM incident_assignments a
      JOIN incidents i ON i.id = a.incident_id
      LEFT JOIN incident_types t ON t.id = i.incident_type_id
      WHERE a.department_id = $1 AND a.ended_at IS NULL
        AND i.status NOT IN ('RESOLVED', 'REJECTED', 'CANCELLED', 'PENDING_ASSIGNMENT')
        AND (a.accepted_by = $2 OR (a.accepted_by IS NULL AND (a.assigned_officer_id IS NULL OR a.assigned_officer_id = $2)))
      ORDER BY i.priority_score DESC NULLS LAST, a.assigned_at ASC
      LIMIT 1
    `,
      [departmentId, userId],
    );
    return { ...summary, next_priority: latest ?? null };
  }

  async getOfficerPerformance() {
    return AppDataSource.query(`
      SELECT u.id, u.full_name, u.email, u.is_active, d.name AS department_name,
        COUNT(a.id) FILTER (WHERE a.accepted_by = u.id)::int AS total_accepted,
        COUNT(a.id) FILTER (WHERE a.accepted_by = u.id AND a.ended_at IS NULL)::int AS active_tasks,
        COUNT(a.id) FILTER (WHERE a.accepted_by = u.id AND a.ended_at IS NOT NULL)::int AS completed_tasks,
        COALESCE(ROUND(AVG(EXTRACT(EPOCH FROM (a.accepted_at - a.assigned_at)) / 60)
          FILTER (WHERE a.accepted_by = u.id AND a.accepted_at IS NOT NULL)), 0)::int AS avg_accept_minutes
      FROM users u
      LEFT JOIN departments d ON d.id = u.department_id
      LEFT JOIN incident_assignments a ON a.accepted_by = u.id
      WHERE u.role = 'OFFICER'
      GROUP BY u.id, u.full_name, u.email, u.is_active, d.name
      ORDER BY active_tasks DESC, completed_tasks DESC, u.full_name ASC
    `);
  }
}
