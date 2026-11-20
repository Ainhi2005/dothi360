import { Check, CheckCircle2, Sparkles } from "lucide-react";

import type { useAssignments } from "../hooks/useAssignments";

type Props = { model: ReturnType<typeof useAssignments> };

export function AssignmentDialog({ model }: Props) {
  const { selected } = model;
  return (
    <>
      {selected && (
        <div className="modal-backdrop">
          <div className="modal assignment-modal" style={{ maxWidth: 620 }}>
            <div className="modal-title">
              <div>
                <h2>Phân công cán bộ xử lý</h2>
                <p>
                  {selected.incident_type_name} · {selected.description}
                </p>
              </div>
              <button
                className="icon close-dark"
                onClick={() => model.setSelected(undefined)}
              >
                ×
              </button>
            </div>

            {/* AI Suggestion Card nếu có */}
            {selected.ai_suggested_officer_name && (
              <div className="ai-suggest-banner">
                <div className="ai-suggest-header">
                  <div className="ai-suggest-title">
                    <Sparkles
                      style={{ width: 16, height: 16, color: "#059669" }}
                    />
                    <span>Phương án AI tối ưu</span>
                  </div>
                  <span className="ai-confidence-badge">
                    Độ tin cậy{" "}
                    {Math.round(
                      (selected.ai_suggestion_confidence ?? 0.95) * 100,
                    )}
                    %
                  </span>
                </div>
                <div className="ai-suggest-officer">
                  <div className="officer-info">
                    <strong>{selected.ai_suggested_officer_name}</strong>
                    <small>{selected.ai_suggested_department_name}</small>
                  </div>
                  <button
                    className="btn-approve-ai"
                    onClick={() => {
                      model.handleApproveAi(selected.incident_id);
                      model.setSelected(undefined);
                    }}
                  >
                    <Check style={{ width: 14, height: 14 }} />
                    Duyệt ngay đề xuất này
                  </button>
                </div>
                {selected.ai_suggestion_reason && (
                  <p className="ai-suggest-reason">
                    {selected.ai_suggestion_reason}
                  </p>
                )}
              </div>
            )}

            <div style={{ marginTop: 14 }}>
              <label
                style={{
                  display: "block",
                  fontWeight: 600,
                  fontSize: 13,
                  marginBottom: 6,
                }}
              >
                1. Chọn Đơn vị chuyên trách:
              </label>
              <select
                value={model.selectedDeptId}
                onChange={(e) => {
                  model.setSelectedDeptId(e.target.value);
                  model.setSelectedOfficerId("");
                }}
                style={{
                  width: "100%",
                  padding: "9px 12px",
                  borderRadius: 6,
                  border: "1px solid var(--border)",
                  background: "var(--surface)",
                  fontSize: 13,
                }}
              >
                <option value="">-- Tất cả đơn vị chức năng --</option>
                {model.departments.map((d) => (
                  <option key={d.id} value={d.id}>
                    {d.name} ({d.code})
                  </option>
                ))}
              </select>
            </div>

            <div style={{ marginTop: 14 }}>
              <div
                style={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  marginBottom: 6,
                }}
              >
                <label style={{ fontWeight: 600, fontSize: 13 }}>
                  2. Chọn Cán bộ phụ trách hiện trường:
                </label>
                <span style={{ fontSize: 12, color: "var(--muted)" }}>
                  {model.filteredOfficers.length} cán bộ trực ban
                </span>
              </div>

              <div className="candidates-grid">
                {model.filteredOfficers.map((o) => {
                  const isSelected = model.selectedOfficerId === o.id;
                  const isAiPick = selected.ai_suggested_officer_id === o.id;

                  return (
                    <button
                      key={o.id}
                      type="button"
                      className={`candidate-card ${isSelected ? "selected" : ""}`}
                      onClick={() => model.setSelectedOfficerId(o.id)}
                    >
                      <div className="candidate-left">
                        <div className="candidate-check">
                          {isSelected && <CheckCircle2 size={16} />}
                        </div>
                        <div>
                          <div
                            style={{
                              display: "flex",
                              alignItems: "center",
                              gap: 6,
                            }}
                          >
                            <strong style={{ fontSize: 13 }}>
                              {o.full_name}
                            </strong>
                            {isAiPick && (
                              <span
                                style={{
                                  background: "#D1FAE5",
                                  color: "#065F46",
                                  fontSize: 10,
                                  fontWeight: 700,
                                  padding: "2px 6px",
                                  borderRadius: 4,
                                }}
                              >
                                ⭐ AI đề xuất
                              </span>
                            )}
                          </div>
                          <small
                            style={{
                              color: "var(--muted)",
                              display: "block",
                              marginTop: 2,
                            }}
                          >
                            {o.department_name} · SĐT: {o.phone || "—"}
                          </small>
                        </div>
                      </div>
                      <div>
                        <span className="officer-workload-tag low">
                          Sẵn sàng nhận việc
                        </span>
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>

            <div style={{ marginTop: 14 }}>
              <label
                style={{
                  display: "block",
                  fontWeight: 600,
                  fontSize: 13,
                  marginBottom: 6,
                }}
              >
                Ghi chú điều phối:
              </label>
              <textarea
                value={model.reason}
                onChange={(e) => model.setReason(e.target.value)}
                placeholder="Nêu chỉ đạo hoặc yêu cầu cụ thể cho cán bộ tiếp nhận..."
                rows={2}
                style={{
                  width: "100%",
                  padding: "8px 12px",
                  borderRadius: 6,
                  border: "1px solid var(--border)",
                  fontSize: 13,
                }}
              />
            </div>

            <div className="modal-actions" style={{ marginTop: 16 }}>
              <button
                className="button secondary"
                onClick={() => model.setSelected(undefined)}
              >
                Hủy
              </button>
              <button
                className="button primary"
                disabled={!model.selectedDeptId}
                onClick={model.handleConfirmAssignment}
              >
                Xác nhận phân công
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
