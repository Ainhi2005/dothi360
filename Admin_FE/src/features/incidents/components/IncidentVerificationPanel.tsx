import { RotateCw, CheckCircle2 } from "lucide-react";

import { StatusBadge } from "../../../components/StatusBadge";

import type { useIncidentDetail } from "../hooks/useIncidentDetail";

type Props = { model: ReturnType<typeof useIncidentDetail> };

export function IncidentVerificationPanel({ model }: Props) {
  const { data } = model;
  if (!data) return null;
  return (
    <>
      {data.status === "PENDING_VERIFICATION" && (
        <article className="panel detail-section verification-panel">
          <div className="section-head-with-action">
            <div>
              <h3>Nghiệm thu kết quả xử lý</h3>
              <p className="muted">
                Kiểm tra minh chứng hiện trường của cán bộ và đối soát trước khi
                đóng sự cố.
              </p>
            </div>
            <StatusBadge status={data.status} />
          </div>

          <div className="before-after-grid">
            <div>
              <strong>📸 Ảnh người dân gửi (Hiện trạng ban đầu)</strong>
              <div className="media-grid">
                {data.report_media?.length ? (
                  data.report_media
                    .slice(0, 3)
                    .map((media) => (
                      <img
                        key={media.id}
                        src={media.file_url}
                        alt="Hiện trạng ban đầu"
                      />
                    ))
                ) : (
                  <div className="empty-media">Chưa có ảnh ban đầu</div>
                )}
              </div>
            </div>
            <div>
              <strong>🛠️ Ảnh cán bộ cập nhật (Hiện trường hoàn tất)</strong>
              <div className="media-grid">
                {data.officer_media?.length ? (
                  data.officer_media
                    .slice(-3)
                    .map((media) => (
                      <img
                        key={media.id}
                        src={media.file_url}
                        alt="Kết quả xử lý"
                      />
                    ))
                ) : (
                  <div className="empty-media">Cán bộ chưa gửi ảnh</div>
                )}
              </div>
            </div>
          </div>

          <div className="verification-form-field">
            <label htmlFor="verification-note">
              Ý kiến nghiệm thu / Kết luận xử lý:
            </label>
            <textarea
              id="verification-note"
              value={model.verificationNote}
              onChange={(event) =>
                model.setVerificationNote(event.target.value)
              }
              placeholder="Nhập kết luận nghiệm thu hoặc nội dung yêu cầu cán bộ xử lý bổ sung (tối thiểu 3 ký tự)..."
              rows={3}
            />
            {model.verificationNote.trim().length > 0 &&
              model.verificationNote.trim().length < 3 && (
                <small
                  style={{
                    color: "var(--warning)",
                    marginTop: 4,
                    display: "block",
                  }}
                >
                  Vui lòng nhập tối thiểu 3 ký tự ý kiến nghiệm thu.
                </small>
              )}
          </div>

          <div className="verification-panel-actions">
            <button
              type="button"
              className="button secondary danger-text"
              disabled={
                model.verifying || model.verificationNote.trim().length < 3
              }
              onClick={() => model.verify("REWORK")}
              style={{ display: "inline-flex", alignItems: "center", gap: 6 }}
            >
              <RotateCw size={15} />
              {model.verifying ? "Đang gửi..." : "Yêu cầu xử lý lại"}
            </button>
            <button
              type="button"
              className="button primary"
              disabled={
                model.verifying || model.verificationNote.trim().length < 3
              }
              onClick={() => model.verify("APPROVE")}
              style={{ display: "inline-flex", alignItems: "center", gap: 6 }}
            >
              <CheckCircle2 size={15} />
              {model.verifying ? "Đang duyệt..." : "Duyệt hoàn thành sự cố"}
            </button>
          </div>
        </article>
      )}
    </>
  );
}
