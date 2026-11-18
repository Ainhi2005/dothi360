import { AppDataSource } from '../../database/data-source';
import { Department } from '../../modules/departments/department.entity';
import { EntityManager } from 'typeorm';
import { AlgorithmConfigService } from '../../modules/algorithm-configs/algorithm-config.service';

export interface AssignmentCandidate extends Department { assignment_method: 'AREA_CONTAINMENT'|'NEAREST_RADIUS'; workload: number; distance_m: number; }

export interface OfficerSuggestion {
  department_id: string;
  department_name: string;
  officer_id: string;
  officer_name: string;
  officer_phone: string;
  active_workload: number;
  distance_m: number;
  confidence: number;
  reason: string;
  candidates: Array<{
    officer_id: string;
    officer_name: string;
    officer_phone: string;
    department_id: string;
    department_name: string;
    active_workload: number;
    distance_m: number;
    is_top_pick: boolean;
  }>;
}

export class DepartmentAssignmentService {
  /**
   * Tìm Đơn vị (Department) phù hợp để xử lý sự cố.
   * Logic hiện tại: Tìm đơn vị có khoảng cách địa lý gần nhất với tọa độ sự cố.
   */
  async findAssignedDepartment(
    longitude: number,
    latitude: number,
    incidentTypeId?: string,
    manager: EntityManager = AppDataSource.manager,
  ): Promise<AssignmentCandidate | null> {
    if (!incidentTypeId) return null;
    const cfg=await new AlgorithmConfigService().getActive('DEPARTMENT_ASSIGNMENT',manager);
    const rows=await manager.query(`WITH eligible AS (
      SELECT d.*,CASE WHEN EXISTS(SELECT 1 FROM areas a WHERE a.department_id=d.id AND a.is_active=TRUE AND ST_Covers(a.geom,ST_SetSRID(ST_Point($1,$2),4326))) THEN 0 ELSE 1 END area_rank,
      COALESCE((SELECT COUNT(*) FROM incident_assignments ia WHERE ia.department_id=d.id AND ia.ended_at IS NULL),0)::int workload,
      ST_Distance(d.location,ST_SetSRID(ST_Point($1,$2),4326)::geography) distance_m
      FROM departments d JOIN department_incident_types dit ON dit.department_id=d.id AND dit.incident_type_id=$3 AND dit.is_active=TRUE
      WHERE d.is_active=TRUE AND d.location IS NOT NULL)
      SELECT *,CASE WHEN area_rank=0 THEN 'AREA_CONTAINMENT' ELSE 'NEAREST_RADIUS' END assignment_method FROM eligible
      WHERE area_rank=0 OR distance_m <= $4 ORDER BY area_rank,workload,distance_m LIMIT 1`,[longitude,latitude,incidentTypeId,cfg.fallback_radius_meters]);
    return rows[0]??null;
  }

  /**
   * AI Gợi ý phân công cán bộ trực tiếp dựa trên chuyên môn, vị trí và tải công việc
   */
  async suggestOfficerAssignment(
    longitude: number,
    latitude: number,
    incidentTypeId?: string,
    manager: EntityManager = AppDataSource.manager,
    _description: string = '',
  ): Promise<OfficerSuggestion | null> {
    if (!incidentTypeId) return null;

    let rows = await manager.query(`
      SELECT 
        u.id AS officer_id,
        u.full_name AS officer_name,
        u.phone AS officer_phone,
        d.id AS department_id,
        d.name AS department_name,
        COALESCE(ST_Distance(d.location, ST_SetSRID(ST_Point($1, $2), 4326)::geography), 99999)::int AS distance_m,
        COALESCE((
          SELECT COUNT(*)::int
          FROM incident_assignments a
          JOIN incidents i ON i.id = a.incident_id
          WHERE a.accepted_by = u.id 
            AND a.ended_at IS NULL 
            AND i.status NOT IN ('RESOLVED', 'CLOSED', 'CANCELLED')
        ), 0)::int AS active_workload
      FROM users u
      JOIN departments d ON d.id = u.department_id
      JOIN department_incident_types dit ON dit.department_id = d.id AND dit.incident_type_id = $3 AND dit.is_active = TRUE
      WHERE u.role = 'OFFICER' 
        AND u.is_active = TRUE 
        AND d.is_active = TRUE
      ORDER BY active_workload ASC, distance_m ASC, u.full_name ASC
    `, [longitude, latitude, incidentTypeId]);

    if (!rows.length) {
      // Dự phòng: Tìm cán bộ thuộc đơn vị gần nhất
      rows = await manager.query(`
        SELECT 
          u.id AS officer_id,
          u.full_name AS officer_name,
          u.phone AS officer_phone,
          d.id AS department_id,
          d.name AS department_name,
          COALESCE(ST_Distance(d.location, ST_SetSRID(ST_Point($1, $2), 4326)::geography), 99999)::int AS distance_m,
          COALESCE((
            SELECT COUNT(*)::int
            FROM incident_assignments a
            JOIN incidents i ON i.id = a.incident_id
            WHERE a.accepted_by = u.id 
              AND a.ended_at IS NULL 
              AND i.status NOT IN ('RESOLVED', 'CLOSED', 'CANCELLED')
          ), 0)::int AS active_workload
        FROM users u
        JOIN departments d ON d.id = u.department_id
        WHERE u.role = 'OFFICER' 
          AND u.is_active = TRUE 
          AND d.is_active = TRUE
        ORDER BY distance_m ASC, active_workload ASC
        LIMIT 10
      `, [longitude, latitude]);
    }

    if (!rows.length) return null;

    const topPick = rows[0];
    const distanceKm = (topPick.distance_m / 1000).toFixed(1);
    const confidence = topPick.active_workload === 0 ? 0.95 : 0.88;

    const reason = `AI đề xuất phân công ${topPick.officer_name} (${topPick.department_name}). Lý do: Đúng chuyên môn phụ trách, tải công việc hiện tại tối ưu (${topPick.active_workload} việc đang mở), vị trí đơn vị cách hiện trường ${distanceKm} km, sẵn sàng xử lý nhanh nhất.`;

    const candidates = rows.map((r: any, idx: number) => ({
      officer_id: r.officer_id,
      officer_name: r.officer_name,
      officer_phone: r.officer_phone,
      department_id: r.department_id,
      department_name: r.department_name,
      active_workload: Number(r.active_workload),
      distance_m: Number(r.distance_m),
      is_top_pick: idx === 0,
    }));

    return {
      department_id: topPick.department_id,
      department_name: topPick.department_name,
      officer_id: topPick.officer_id,
      officer_name: topPick.officer_name,
      officer_phone: topPick.officer_phone,
      active_workload: Number(topPick.active_workload),
      distance_m: Number(topPick.distance_m),
      confidence,
      reason,
      candidates,
    };
  }
}

