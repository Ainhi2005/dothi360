import { StatusBadge } from "../../../components/StatusBadge";

import type { useIncidentDetail } from "../hooks/useIncidentDetail";

type Props = { model: ReturnType<typeof useIncidentDetail> };

export function IncidentTimeline({ model }: Props) {
  const { data } = model;
  if (!data) return null;
  return (
    <>
      <article className="panel detail-section">
        <h3>Lịch sử xử lý</h3>
        <div className="timeline">
          {data.updates?.length ? (
            data.updates.map((u) => (
              <div className="timeline-item" key={u.id}>
                <i />
                <div>
                  <strong>
                    {u.new_status ? (
                      <StatusBadge status={u.new_status} />
                    ) : (
                      "Cập nhật"
                    )}
                  </strong>
                  <p>{u.note || "Không có ghi chú"}</p>
                  {u.progress_percent != null && (
                    <div className="progress-meta">
                      <strong>{u.progress_percent}% hoàn thành</strong>
                      {u.estimated_completion_at && (
                        <span>
                          Dự kiến:{" "}
                          {new Date(
                            u.estimated_completion_at,
                          ).toLocaleDateString("vi-VN")}
                        </span>
                      )}
                      <span>
                        {u.visibility === "INTERNAL" ? "Nội bộ" : "Công khai"}
                      </span>
                    </div>
                  )}
                  {u.blocker && (
                    <p className="warning-text">Khó khăn: {u.blocker}</p>
                  )}
                  <small>
                    {new Date(u.created_at).toLocaleString("vi-VN")}
                  </small>
                  {u.media_urls && u.media_urls.length > 0 && (
                    <div
                      style={{
                        display: "flex",
                        gap: 8,
                        marginTop: 8,
                        flexWrap: "wrap",
                      }}
                    >
                      {u.media_urls.map((url, i) => (
                        <a
                          key={i}
                          href={url}
                          target="_blank"
                          rel="noreferrer"
                          title="Xem ảnh cập nhật kích thước lớn"
                        >
                          <img
                            src={url}
                            alt="Ảnh cập nhật của cán bộ"
                            style={{
                              width: 72,
                              height: 72,
                              objectFit: "cover",
                              borderRadius: 6,
                              border: "1px solid var(--border)",
                              cursor: "pointer",
                            }}
                          />
                        </a>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            ))
          ) : (
            <p className="muted">Chưa có cập nhật xử lý.</p>
          )}
        </div>
      </article>
    </>
  );
}
