import { Sparkles, CheckCircle2 } from "lucide-react";

import type { useIncidentDetail } from "../hooks/useIncidentDetail";

type Props = { model: ReturnType<typeof useIncidentDetail> };

export function IncidentAssignmentDialog({ model }: Props) {
  const { data } = model;
  if (!data) return null;
  return (
    <>
      {model.modalOpen && (
        <div
          className="modal-backdrop"
          onClick={() => model.setModalOpen(false)}
        >
          <div
            className="modal assignment-dialog"
            role="dialog"
            aria-modal="true"
            aria-labelledby="assignment-dialog-title"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="assignment-dialog-header">
              <div>
                <h3 id="assignment-dialog-title">Điều chuyển cán bộ</h3>
                <small>
                  Sự cố: {data.incident_type?.name ?? "Sự cố đô thị"} (
                  {data.id.slice(0, 8).toUpperCase()})
                </small>
              </div>
              <button
                type="button"
                className="assignment-dialog-close"
                aria-label="Đóng hộp thoại"
                onClick={() => model.setModalOpen(false)}
              >
                &times;
              </button>
            </div>

            <div className="assignment-dialog-body">
              <label className="assignment-field">
                <span>Đơn vị chuyên trách</span>
                <select
                  value={model.selectedDeptId}
                  onChange={(e) => {
                    model.setSelectedDeptId(e.target.value);
                    model.setSelectedOfficerId("");
                  }}
                >
                  {model.departments.map((d) => (
                    <option key={d.id} value={d.id}>
                      {d.name} ({d.code})
                    </option>
                  ))}
                </select>
              </label>

              <div className="assignment-candidate-section">
                <div className="assignment-section-heading">
                  <div>
                    <strong>Cán bộ nhận nhiệm vụ</strong>
                    <small>
                      Chọn một cán bộ hoặc để trống để giao chung cho đơn vị.
                    </small>
                  </div>
                  <span>
                    {
                      model.officers.filter(
                        (o) =>
                          !model.selectedDeptId ||
                          o.department_id === model.selectedDeptId,
                      ).length
                    }{" "}
                    cán bộ
                  </span>
                </div>

                <div className="candidates-grid">
                  {model.officers.filter(
                    (o) =>
                      !model.selectedDeptId ||
                      o.department_id === model.selectedDeptId,
                  ).length === 0 && (
                    <div className="assignment-empty-candidates">
                      Đơn vị này chưa có cán bộ đang hoạt động.
                    </div>
                  )}
                  {model.officers
                    .filter(
                      (o) =>
                        !model.selectedDeptId ||
                        o.department_id === model.selectedDeptId,
                    )
                    .map((o) => {
                      const isSelected = model.selectedOfficerId === o.id;
                      const isAiPick = data.ai_suggestion?.officer_id === o.id;

                      return (
                        <button
                          key={o.id}
                          type="button"
                          className={`candidate-card ${isSelected ? "selected" : ""}`}
                          onClick={() =>
                            model.setSelectedOfficerId(isSelected ? "" : o.id)
                          }
                        >
                          <div className="candidate-left">
                            <div className="candidate-check">
                              {isSelected && <CheckCircle2 size={16} />}
                            </div>
                            <div className="candidate-identity">
                              <div>
                                <strong>{o.full_name}</strong>
                                {isAiPick && (
                                  <span className="candidate-ai-label">
                                    <Sparkles size={11} /> AI đề xuất
                                  </span>
                                )}
                              </div>
                              <small>
                                {o.phone || "Chưa có số điện thoại"}
                              </small>
                            </div>
                          </div>
                          <span
                            className={`officer-workload-tag ${o.active_workload === 0 ? "low" : o.active_workload <= 2 ? "medium" : "high"}`}
                          >
                            {o.active_workload === 0
                              ? "Sẵn sàng"
                              : `${o.active_workload} việc đang xử lý`}
                          </span>
                        </button>
                      );
                    })}
                </div>
              </div>

              <label className="assignment-field">
                <span>Chỉ đạo xử lý</span>
                <textarea
                  value={model.assignReason}
                  onChange={(e) => model.setAssignReason(e.target.value)}
                  placeholder="Nêu yêu cầu cụ thể cho cán bộ tiếp nhận..."
                  rows={3}
                />
              </label>
              {model.assignmentError && (
                <div className="assignment-dialog-error">
                  {model.assignmentError}
                </div>
              )}
            </div>

            <div className="assignment-dialog-footer">
              <button
                className="button secondary"
                disabled={model.assigning}
                onClick={() => model.setModalOpen(false)}
              >
                Hủy
              </button>
              <button
                className="button primary"
                disabled={!model.selectedDeptId || model.assigning}
                onClick={model.handleConfirmAssignment}
              >
                {model.assigning ? "Đang phân công..." : "Xác nhận điều chuyển"}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
