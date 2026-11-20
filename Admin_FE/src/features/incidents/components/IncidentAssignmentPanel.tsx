import {
  MapPin,
  ShieldCheck,
  Sparkles,
  UserCheck,
  CheckCircle2,
  ArrowRightLeft,
} from "lucide-react";
import { Link } from "react-router-dom";

import type { useIncidentDetail } from "../hooks/useIncidentDetail";
type Props = { model: ReturnType<typeof useIncidentDetail> };
export function IncidentAssignmentPanel({ model }: Props) {
  const { data } = model;
  if (!data) return null;
  return (
    <article className="panel detail-section">
      <div
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          marginBottom: 12,
        }}
      >
        <h3 style={{ margin: 0 }}>Điều phối & Cán bộ</h3>
        {data.assignment?.accepted_by ? (
          <span
            className="dot-label active"
            style={{
              fontSize: 11,
              background: "#ECFDF5",
              color: "#065F46",
              padding: "2px 8px",
              borderRadius: 4,
            }}
          >
            ✓ Đã tiếp nhận
          </span>
        ) : data.assignment?.assigned_officer_id ? (
          <span
            className="dot-label pending"
            style={{
              fontSize: 11,
              background: "#FEF3C7",
              color: "#92400E",
              padding: "2px 8px",
              borderRadius: 4,
            }}
          >
            Chờ cán bộ xác nhận
          </span>
        ) : (
          <span
            className="dot-label pending"
            style={{
              fontSize: 11,
              background: "#FEF3C7",
              color: "#92400E",
              padding: "2px 8px",
              borderRadius: 4,
            }}
          >
            Chờ duyệt / phân công
          </span>
        )}
      </div>

      {/* Nếu có AI Suggestion và chưa có cán bộ nhận chính thức */}
      {!data.assignment?.accepted_by &&
        !data.assignment?.assigned_officer_id &&
        data.ai_suggestion && (
          <div
            className="ai-assignment-banner"
            style={{
              margin: "0 0 16px 0",
              border: "1px solid #A7F3D0",
              background: "linear-gradient(135deg, #F0FDF4 0%, #ECFDF5 100%)",
              borderRadius: 8,
              padding: 12,
            }}
          >
            <div
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                marginBottom: 8,
              }}
            >
              <span className="ai-suggestion-badge">
                <Sparkles size={13} /> AI Đề xuất cán bộ
              </span>
              <span className="ai-confidence-pill">
                Độ tin cậy{" "}
                {Math.round((data.ai_suggestion.confidence ?? 0.95) * 100)}%
              </span>
            </div>

            <div
              style={{
                background: "#FFF",
                borderRadius: 6,
                padding: "10px 12px",
                border: "1px solid #D1FAE5",
                marginBottom: 10,
              }}
            >
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                }}
              >
                <strong style={{ fontSize: 14, color: "#065F46" }}>
                  {data.ai_suggestion.officer_name}
                </strong>
                <span
                  className={`officer-workload-tag ${data.ai_suggestion.active_workload === 0 ? "low" : data.ai_suggestion.active_workload <= 2 ? "medium" : "high"}`}
                >
                  {data.ai_suggestion.active_workload === 0
                    ? "🟢 0 việc đang xử lý"
                    : `${data.ai_suggestion.active_workload} việc đang xử lý`}
                </span>
              </div>
              <div
                style={{
                  fontSize: 12,
                  color: "var(--muted)",
                  marginTop: 4,
                  display: "flex",
                  alignItems: "center",
                  gap: 6,
                }}
              >
                <span>{data.ai_suggestion.department_name}</span>
                {data.ai_suggestion.officer_phone && (
                  <>
                    <span>·</span>
                    <span>📞 {data.ai_suggestion.officer_phone}</span>
                  </>
                )}
              </div>
            </div>

            {data.ai_suggestion.reason && (
              <div
                style={{
                  fontSize: 11.5,
                  color: "#047857",
                  background: "rgba(255,255,255,0.7)",
                  padding: "6px 8px",
                  borderRadius: 4,
                  marginBottom: 12,
                  lineHeight: 1.4,
                }}
              >
                💡 {data.ai_suggestion.reason}
              </div>
            )}

            <div style={{ display: "flex", gap: 8, flexDirection: "column" }}>
              <button
                type="button"
                className="btn-approve-ai"
                disabled={model.approvingAi}
                onClick={model.handleApproveAi}
                style={{
                  width: "100%",
                  justifyContent: "center",
                  padding: "8px 12px",
                  fontSize: 13,
                }}
              >
                <CheckCircle2 size={16} />
                {model.approvingAi
                  ? "Đang duyệt..."
                  : "✓ Duyệt đề xuất AI ngay"}
              </button>
              <button
                type="button"
                className="button secondary"
                onClick={model.openAssignModal}
                style={{
                  width: "100%",
                  justifyContent: "center",
                  fontSize: 12,
                  padding: "6px 12px",
                }}
              >
                <ArrowRightLeft size={14} /> Thay đổi cán bộ khác
              </button>
            </div>
          </div>
        )}

      {/* Nếu đã được phân công */}
      {data.assignment?.accepted_by ? (
        <div>
          <dl>
            <div>
              <dt>Cán bộ phụ trách</dt>
              <dd>
                <strong>
                  <UserCheck
                    size={14}
                    style={{
                      display: "inline",
                      verticalAlign: -2,
                      marginRight: 4,
                    }}
                  />
                  {data.assignment.officer_name || "Đã phân công"}
                </strong>
              </dd>
            </div>
            {data.assignment.officer_phone && (
              <div>
                <dt>Điện thoại</dt>
                <dd>
                  <a
                    href={`tel:${data.assignment.officer_phone}`}
                    style={{
                      color: "var(--primary)",
                      textDecoration: "none",
                    }}
                  >
                    📞 {data.assignment.officer_phone}
                  </a>
                </dd>
              </div>
            )}
            <div>
              <dt>Đơn vị</dt>
              <dd>
                <ShieldCheck
                  size={14}
                  style={{
                    display: "inline",
                    verticalAlign: -2,
                    marginRight: 4,
                  }}
                />
                {data.assignment.department_name ?? "—"}
              </dd>
            </div>
            <div>
              <dt>Phương thức</dt>
              <dd>{data.assignment.assignment_method ?? "—"}</dd>
            </div>
            <div>
              <dt>Thời gian giao</dt>
              <dd>
                {data.assignment.assigned_at
                  ? new Date(data.assignment.assigned_at).toLocaleString(
                      "vi-VN",
                    )
                  : "—"}
              </dd>
            </div>
            {data.assignment.reason && (
              <div>
                <dt>Chỉ đạo / Lý do</dt>
                <dd style={{ fontSize: 12 }}>{data.assignment.reason}</dd>
              </div>
            )}
          </dl>
          <button
            type="button"
            className="button secondary full-button"
            onClick={model.openAssignModal}
            style={{ marginTop: 12 }}
          >
            <ArrowRightLeft size={14} /> Điều chuyển / Đổi cán bộ
          </button>
        </div>
      ) : data.assignment?.assigned_officer_id ? (
        <div>
          <dl>
            <div>
              <dt>Cán bộ được chỉ định</dt>
              <dd>
                <strong>
                  <UserCheck
                    size={14}
                    style={{
                      display: "inline",
                      verticalAlign: -2,
                      marginRight: 4,
                    }}
                  />
                  {data.assignment.assigned_officer_name ?? "—"}
                </strong>
              </dd>
            </div>
            <div>
              <dt>Trạng thái tiếp nhận</dt>
              <dd style={{ color: "#92400e" }}>Đang chờ phản hồi</dd>
            </div>
            <div>
              <dt>Đơn vị</dt>
              <dd>{data.assignment.department_name ?? "—"}</dd>
            </div>
            <div>
              <dt>Thời gian giao</dt>
              <dd>
                {data.assignment.assigned_at
                  ? new Date(data.assignment.assigned_at).toLocaleString(
                      "vi-VN",
                    )
                  : "—"}
              </dd>
            </div>
          </dl>
          <button
            type="button"
            className="button secondary full-button"
            onClick={model.openAssignModal}
            style={{ marginTop: 12 }}
          >
            <ArrowRightLeft size={14} /> Điều chuyển / Đổi cán bộ
          </button>
        </div>
      ) : !data.ai_suggestion ? (
        <div>
          <p className="muted" style={{ fontSize: 13, marginBottom: 12 }}>
            Sự cố chưa được phân công cán bộ xử lý hiện trường.
          </p>
          <button
            type="button"
            className="button primary full-button"
            onClick={model.openAssignModal}
          >
            <UserCheck size={14} /> Phân công cán bộ ngay
          </button>
        </div>
      ) : null}

      <div
        style={{
          marginTop: 12,
          paddingTop: 10,
          borderTop: "1px solid var(--border)",
          textAlign: "right",
        }}
      >
        <Link
          to="/assignments"
          style={{
            fontSize: 12,
            color: "var(--muted)",
            display: "inline-flex",
            alignItems: "center",
            gap: 4,
          }}
        >
          <MapPin size={12} /> Bảng điều phối tổng thể
        </Link>
      </div>
    </article>
  );
}
