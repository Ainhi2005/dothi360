import { Sparkles, RotateCw, Lightbulb } from "lucide-react";

import type { useIncidentDetail } from "../hooks/useIncidentDetail";

type Props = { model: ReturnType<typeof useIncidentDetail> };

export function IncidentAnalysisPanel({ model }: Props) {
  const { data } = model;
  if (!data) return null;
  return (
    <>
      <article className="panel detail-section ai-highlight-panel">
        <div className="section-head-with-action">
          <div className="ai-title-wrap">
            <Sparkles className="ai-icon" />
            <div>
              <h3>Kết quả AI & Biện pháp đề xuất</h3>
              <p className="ai-subtitle">
                Dữ liệu phân tích hiện trường đã được người dân xác nhận khi gửi
                phản ánh
              </p>
            </div>
          </div>
          {data.ai_analysis && (
            <span className="dot-label active" style={{ fontSize: 12 }}>
              Đã lưu từ phản ánh người dân
            </span>
          )}
        </div>

        {model.analyzeMsg && (
          <p className="ai-status-msg">{model.analyzeMsg}</p>
        )}

        {data.ai_analysis ? (
          <div className="ai-content-body">
            {/* Quick Metrics Strip */}
            <div className="ai-decision-grid">
              <div className="ai-metric-box">
                <small>Độ tin cậy AI</small>
                <strong style={{ color: "var(--primary)" }}>
                  {Math.round((data.ai_analysis.confidence ?? 0.85) * 100)}%
                </strong>
              </div>
              <div className="ai-metric-box">
                <small>Mức độ rủi ro</small>
                <span
                  className={`risk-tag risk-${(data.ai_analysis.risk_level ?? "medium").toLowerCase()}`}
                >
                  {data.ai_analysis.risk_level ?? "TRUNG BÌNH"}
                </span>
              </div>
              <div className="ai-metric-box">
                <small>SLA kiến nghị</small>
                <strong>
                  {data.ai_analysis.suggested_sla_hours ?? "—"} giờ
                </strong>
              </div>
              <div className="ai-metric-box">
                <small>Loại đề xuất</small>
                <strong>
                  {data.ai_analysis.suggested_incident_type ??
                    data.incident_type?.name ??
                    "—"}
                </strong>
              </div>
              <div className="ai-metric-box">
                <small>Mức nghiêm trọng</small>
                <strong>
                  {data.ai_analysis.suggested_severity
                    ? `${data.ai_analysis.suggested_severity}/5`
                    : "—"}
                </strong>
              </div>
            </div>

            {/* HIGHLIGHTED RECOMMENDED ACTIONS */}
            {data.ai_analysis.recommended_action && (
              <div className="ai-action-highlight">
                <div className="ai-action-badge">
                  <Lightbulb />
                  <strong>Biện pháp chỉ đạo / xử lý đề xuất:</strong>
                </div>
                <p className="ai-action-text">
                  {data.ai_analysis.recommended_action}
                </p>
              </div>
            )}

            {/* DETAILED REASON */}
            {data.ai_analysis.reason && (
              <div className="ai-reason-box">
                <strong>
                  {data.ai_analysis.user_edited_reason
                    ? "Nội dung người dân đã chỉnh:"
                    : "Chi tiết nhận định của AI:"}
                </strong>
                <p>{data.ai_analysis.reason}</p>
                {data.ai_analysis.user_edited_reason &&
                  data.ai_analysis.original_reason && (
                    <small
                      style={{
                        display: "block",
                        marginTop: 8,
                        color: "var(--muted)",
                      }}
                    >
                      Bản AI ban đầu: {data.ai_analysis.original_reason}
                    </small>
                  )}
              </div>
            )}

            {/* DETECTED SIGNALS */}
            {data.ai_analysis.detected_signals &&
              data.ai_analysis.detected_signals.length > 0 && (
                <div className="ai-signals-wrap">
                  <small>Dấu hiệu nhận diện từ ảnh hiện trường:</small>
                  <div className="ai-signals">
                    {data.ai_analysis.detected_signals.map((s) => (
                      <span key={s} className="ai-signal-chip">
                        👁️ {s}
                      </span>
                    ))}
                  </div>
                </div>
              )}

            {data.duplicate_evidence && (
              <p className="duplicate-evidence">
                Khả năng trùng{" "}
                {Math.round((data.duplicate_evidence.score ?? 0) * 100)}% · cách{" "}
                {Math.round(data.duplicate_evidence.distance_m ?? 0)} m · nội
                dung{" "}
                {Math.round((data.duplicate_evidence.text_score ?? 0) * 100)}% ·
                dấu hiệu ảnh{" "}
                {Math.round(
                  (data.duplicate_evidence.visual_signal_score ?? 0) * 100,
                )}
                %
              </p>
            )}

            {data.media && data.media.length > 0 && (
              <div
                style={{
                  marginTop: 12,
                  paddingTop: 10,
                  borderTop: "1px solid var(--border)",
                  display: "flex",
                  justifyContent: "flex-end",
                }}
              >
                <button
                  type="button"
                  className="text-button"
                  onClick={model.handleAiAnalyze}
                  disabled={model.analyzing}
                  style={{
                    fontSize: 12,
                    display: "inline-flex",
                    alignItems: "center",
                    gap: 6,
                  }}
                >
                  <RotateCw
                    className={model.analyzing ? "spin" : ""}
                    style={{ width: 13, height: 13 }}
                  />
                  {model.analyzing
                    ? "Đang chạy lại phân tích..."
                    : "Phân tích lại ảnh bằng AI"}
                </button>
              </div>
            )}
          </div>
        ) : (
          <div className="ai-empty-prompt">
            <p>Sự cố này chưa có dữ liệu phân tích tự động từ AI.</p>
            {data.media && data.media.length > 0 ? (
              <button
                type="button"
                className="button primary"
                onClick={model.handleAiAnalyze}
                disabled={model.analyzing}
              >
                <Sparkles style={{ width: 16, height: 16 }} />
                {model.analyzing
                  ? "Đang phân tích..."
                  : "Kích hoạt AI phân tích hình ảnh ngay"}
              </button>
            ) : (
              <small className="muted">
                Cần có ảnh hiện trường để kích hoạt phân tích tự động.
              </small>
            )}
          </div>
        )}
      </article>
    </>
  );
}
