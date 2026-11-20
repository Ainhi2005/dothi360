import assert from "node:assert/strict";
import test, { before, after } from "node:test";
import { randomUUID } from "node:crypto";
import { AppDataSource } from "../../database/data-source";
import { IncidentService } from "./incident.service";
import { Incident } from "./incident.entity";
import { AssignmentService } from "../assignments/assignment.service";

before(async () => {
  AppDataSource.setOptions({ logging: false });
  await AppDataSource.initialize();
});
after(async () => {
  if (AppDataSource.isInitialized) await AppDataSource.destroy();
});

for (const decision of ["APPROVE", "REWORK"] as const) {
  test(`luồng tiếp nhận → xử lý → nghiệm thu ${decision} giữ trạng thái, audit, thông báo`, async () => {
    const q = AppDataSource.createQueryRunner();
    await q.connect();
    await q.startTransaction();
    const original = AppDataSource.transaction;
    try {
      const token = randomUUID();
      const [type] = await q.query(
        "INSERT INTO incident_types(code,name) VALUES($1,$1) RETURNING id",
        [token],
      );
      const [dept] = await q.query(
        "INSERT INTO departments(code,name) VALUES($1,$1) RETURNING id",
        [token],
      );
      const [officer] = await q.query(
        `INSERT INTO users(full_name,email,password_hash,role,department_id) VALUES('Test',$1,'test-only','OFFICER',$2) RETURNING id`,
        [`${token}@test.invalid`, dept.id],
      );
      const [admin] = await q.query(
        `INSERT INTO users(full_name,email,password_hash,role) VALUES('Admin test',$1,'test-only','ADMIN') RETURNING id`,
        [`admin-${token}@test.invalid`],
      );
      const [incident] = await q.query(
        `INSERT INTO incidents(incident_type_id,description,location,severity_level,status) VALUES($1,'Test',ST_SetSRID(ST_MakePoint(105.8,21.0),4326)::geography,3,'ASSIGNED') RETURNING id`,
        [type.id],
      );
      const [offer] = await q.query(
        `INSERT INTO incident_assignments(incident_id,department_id,assigned_officer_id,assignment_method) VALUES($1,$2,$3,'MANUAL') RETURNING id`,
        [incident.id, dept.id, officer.id],
      );
      AppDataSource.transaction = (async (fn: any) => fn(q.manager)) as any;
      const service = new IncidentService();
      service.findOne = (async () =>
        q.manager
          .getRepository(Incident)
          .findOneByOrFail({ id: incident.id })) as any;
      const assignments = new AssignmentService();
      await assert.rejects(
        assignments.acceptAssignment(offer.id, officer.id, randomUUID()),
        (e: any) => e.statusCode === 403,
      );
      await assignments.acceptAssignment(offer.id, officer.id, dept.id);
      await assert.rejects(
        assignments.acceptAssignment(offer.id, officer.id, dept.id),
        (e: any) => e.statusCode === 409,
      );
      await service.updateStatus(incident.id, officer.id, "OFFICER", dept.id, {
        status: "IN_PROGRESS",
        note: "Bắt đầu xử lý",
      });
      await service.updateStatus(incident.id, officer.id, "OFFICER", dept.id, {
        status: "PENDING_VERIFICATION",
        note: "Đã hoàn thành xử lý",
      });
      await service.verifyIncident(incident.id, admin.id, {
        decision,
        note: "Đã kiểm tra kết quả",
      });
      const [saved] = await q.query(
        "SELECT status,resolved_at FROM incidents WHERE id=$1",
        [incident.id],
      );
      const [assignment] = await q.query(
        "SELECT accepted_by,ended_at FROM incident_assignments WHERE id=$1",
        [offer.id],
      );
      assert.equal(
        saved.status,
        decision === "APPROVE" ? "RESOLVED" : "IN_PROGRESS",
      );
      assert.equal(Boolean(saved.resolved_at), decision === "APPROVE");
      assert.equal(Boolean(assignment.ended_at), decision === "APPROVE");
      assert.equal(assignment.accepted_by, officer.id);
      const [audit] = await q.query(
        "SELECT action FROM audit_logs WHERE entity_id=$1 ORDER BY created_at DESC LIMIT 1",
        [incident.id],
      );
      assert.equal(
        audit.action,
        decision === "APPROVE"
          ? "INCIDENT_VERIFIED"
          : "INCIDENT_REWORK_REQUESTED",
      );
      const rows = await q.query(
        "SELECT type FROM notifications WHERE incident_id=$1 AND user_id=$2",
        [incident.id, officer.id],
      );
      assert.ok(
        rows.some(
          (r: any) =>
            r.type ===
            (decision === "APPROVE" ? "WORK_VERIFIED" : "WORK_REWORK_REQUIRED"),
        ),
      );
      await assert.rejects(
        service.verifyIncident(incident.id, admin.id, {
          decision,
          note: "Gửi lại",
        }),
        (e: any) => e.statusCode === 409,
      );
    } finally {
      AppDataSource.transaction = original;
      await q.rollbackTransaction();
      await q.release();
    }
  });
}
