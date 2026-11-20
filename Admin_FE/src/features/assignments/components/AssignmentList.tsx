import {
  AlertTriangle,
  ArrowRightLeft,
  Check,
  Sparkles,
  UserCheck,
} from "lucide-react";

import { PageState } from "../../../components/PageState";
import { StatusBadge } from "../../../components/StatusBadge";

import type { useAssignments } from "../hooks/useAssignments";

type Props = { model: ReturnType<typeof useAssignments> };

export function AssignmentList({ model }: Props) {
  const { data } = model;
  return (
    <>
      <article className="panel">
        <PageState
          loading={model.loading}
          error={model.error}
          empty={!model.loading && !model.error && !data.length}
          onRetry={model.load}
        />
        {!model.loading && !model.error && (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Sự cố</th>
                  <th>Đơn vị chuyên trách</th>
                  <th>Cán bộ phụ trách / Đề xuất AI</th>
                  <th>Phương thức</th>
                  <th>Trạng thái</th>
                  <th style={{ textAlign: "right" }}>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {data
                  .filter(
                    (a) =>
                      model.filter === "ALL" ||
                      (model.filter === "PENDING" && !a.id && !a.ended_at) ||
                      (model.filter === "OFFERED" &&
                        Boolean(a.id) &&
                        !a.accepted_by &&
                        !a.ended_at) ||
                      (model.filter === "ACTIVE" &&
                        Boolean(a.accepted_by) &&
                        !a.ended_at) ||
                      (model.filter === "ENDED" && a.ended_at),
                  )
                  .map((a) => {
                    const isPending = !a.id && !a.ended_at;
                    const hasAiSuggestion = Boolean(
                      a.ai_suggested_officer_name,
                    );

                    return (
                      <tr
                        key={a.incident_id}
                        className={a.ended_at ? "opacity-50" : ""}
                      >
                        <td style={{ maxWidth: 280 }}>
                          <strong style={{ display: "block", fontSize: 13 }}>
                            {a.incident_type_name ?? "Sự cố đô thị"}
                          </strong>
                          <small
                            style={{ color: "var(--muted)", display: "block" }}
                          >
                            {a.description}
                          </small>
                          {a.rejection_reason && (
                            <div
                              style={{
                                marginTop: 6,
                                color: "#b45309",
                                display: "flex",
                                gap: 5,
                                alignItems: "flex-start",
                              }}
                            >
                              <AlertTriangle
                                style={{ width: 14, height: 14, flexShrink: 0 }}
                              />
                              <small>
                                Cán bộ {a.rejecting_officer_name ?? ""} từ chối:{" "}
                                {a.rejection_reason}
                              </small>
                            </div>
                          )}
                        </td>

                        <td>
                          {a.department_name ? (
                            <strong>{a.department_name}</strong>
                          ) : a.ai_suggested_department_name ? (
                            <span style={{ color: "#047857", fontWeight: 600 }}>
                              {a.ai_suggested_department_name}
                            </span>
                          ) : (
                            <span className="muted">Chưa gán đơn vị</span>
                          )}
                        </td>

                        <td style={{ minWidth: 240 }}>
                          {a.officer_name ? (
                            <div>
                              <strong
                                style={{
                                  display: "flex",
                                  alignItems: "center",
                                  gap: 6,
                                }}
                              >
                                <UserCheck
                                  style={{
                                    width: 15,
                                    height: 15,
                                    color: "#059669",
                                  }}
                                />
                                {a.officer_name}
                              </strong>
                              {a.reason && (
                                <small
                                  style={{
                                    color: "var(--muted)",
                                    display: "block",
                                  }}
                                >
                                  {a.reason}
                                </small>
                              )}
                            </div>
                          ) : a.assigned_officer_name ? (
                            <div>
                              <strong
                                style={{
                                  display: "flex",
                                  alignItems: "center",
                                  gap: 6,
                                }}
                              >
                                <UserCheck
                                  style={{
                                    width: 15,
                                    height: 15,
                                    color: "#d97706",
                                  }}
                                />
                                {a.assigned_officer_name}
                              </strong>
                              <small
                                style={{ color: "#92400e", display: "block" }}
                              >
                                Chờ cán bộ tiếp nhận hoặc từ chối
                              </small>
                            </div>
                          ) : hasAiSuggestion ? (
                            <div
                              style={{
                                background: "#ECFDF5",
                                border: "1px solid #A7F3D0",
                                borderRadius: 6,
                                padding: "6px 10px",
                              }}
                            >
                              <div
                                style={{
                                  display: "flex",
                                  alignItems: "center",
                                  gap: 6,
                                  color: "#065F46",
                                  fontWeight: 600,
                                  fontSize: 12,
                                }}
                              >
                                <Sparkles
                                  style={{
                                    width: 13,
                                    height: 13,
                                    color: "#059669",
                                  }}
                                />
                                AI Đề xuất: {a.ai_suggested_officer_name}
                              </div>
                              <small
                                style={{
                                  color: "#047857",
                                  fontSize: 11,
                                  display: "block",
                                  marginTop: 2,
                                }}
                              >
                                {a.ai_suggestion_reason ??
                                  "Tải công việc thấp nhất & vị trí tối ưu"}
                              </small>
                            </div>
                          ) : (
                            <span className="muted">Chưa có đề xuất</span>
                          )}
                        </td>

                        <td>
                          <span style={{ fontSize: 12 }}>
                            {a.assignment_method === "AI_SUGGESTED"
                              ? "🤖 AI Gợi ý"
                              : a.assignment_method === "MANUAL"
                                ? "👤 Admin chỉ định"
                                : a.assignment_method || "—"}
                          </span>
                        </td>

                        <td>
                          {a.ended_at ? (
                            <span className="status-text status-cancelled">
                              <i />
                              Đã kết thúc
                            </span>
                          ) : a.id && !a.accepted_by ? (
                            <span className="status-text status-assigned">
                              <i />
                              Chờ xác nhận
                            </span>
                          ) : (
                            <StatusBadge status={a.status} />
                          )}
                        </td>

                        <td
                          style={{ textAlign: "right", whiteSpace: "nowrap" }}
                        >
                          {!a.ended_at && (
                            <div style={{ display: "inline-flex", gap: 8 }}>
                              {isPending && hasAiSuggestion && (
                                <button
                                  className="btn-approve-ai"
                                  disabled={model.approvingId === a.incident_id}
                                  onClick={() =>
                                    model.handleApproveAi(a.incident_id)
                                  }
                                  title="1 click để duyệt ngay cán bộ do AI đề xuất"
                                >
                                  <Check style={{ width: 14, height: 14 }} />
                                  {model.approvingId === a.incident_id
                                    ? "Đang duyệt..."
                                    : "Duyệt gợi ý AI"}
                                </button>
                              )}
                              <button
                                className="button secondary"
                                style={{ padding: "6px 12px", fontSize: 12 }}
                                onClick={() => model.openReassignModal(a)}
                              >
                                <ArrowRightLeft
                                  style={{ width: 13, height: 13 }}
                                />
                                {isPending
                                  ? "Chọn cán bộ khác"
                                  : "Điều phối lại"}
                              </button>
                            </div>
                          )}
                        </td>
                      </tr>
                    );
                  })}
              </tbody>
            </table>
          </div>
        )}
      </article>
    </>
  );
}
