import { IncidentAssignmentPanel } from "../features/incidents/components/IncidentAssignmentPanel";
import { IncidentVerificationPanel } from "../features/incidents/components/IncidentVerificationPanel";
import { IncidentAnalysisPanel } from "../features/incidents/components/IncidentAnalysisPanel";
import { IncidentTimeline } from "../features/incidents/components/IncidentTimeline";
import { IncidentAssignmentDialog } from "../features/incidents/components/IncidentAssignmentDialog";

import { ArrowLeft, CalendarDays } from "lucide-react";
import { Link } from "react-router-dom";
import { PageState } from "../components/PageState";
import { StatusBadge } from "../components/StatusBadge";
import { Toast } from "../components/Toast";

import { useIncidentDetail } from "../features/incidents/hooks/useIncidentDetail";

export default function IncidentDetail() {
  const model = useIncidentDetail();
  const { data, error, toast, setToast, load } = model;
  if (!data || error)
    return <PageState loading={!error} error={error} onRetry={load} />;

  return (
    <section>
      <Link className="back-link" to="/incidents">
        <ArrowLeft /> Quay lại danh sách
      </Link>
      <div className="page-heading">
        <div>
          <span className="eyebrow">
            HỒ SƠ SỰ CỐ · {data.id.slice(0, 8).toUpperCase()}
          </span>
          <h2>{data.incident_type?.name ?? "Sự cố đô thị"}</h2>
          <p>{data.description}</p>
        </div>
        <StatusBadge status={data.status} />
      </div>
      <div className="detail-grid">
        <div className="detail-main">
          <IncidentVerificationPanel model={model} />
          {/* Hình ảnh hiện trường */}
          <article className="panel detail-section">
            <h3>Hình ảnh hiện trường</h3>
            <div className="media-grid">
              {data.media?.length ? (
                data.media.map((m) => (
                  <img key={m.id} src={m.file_url} alt="Minh chứng sự cố" />
                ))
              ) : (
                <div className="empty-media">Chưa có hình ảnh</div>
              )}
            </div>
          </article>

          {/* Khối AI Phân tích & Biện pháp xử lý đề xuất */}
          <IncidentAnalysisPanel model={model} />

          {/* Lịch sử xử lý */}
          <IncidentTimeline model={model} />
        </div>

        <aside className="detail-side">
          <article className="panel detail-section">
            <h3>Thông tin nghiệp vụ</h3>
            <dl>
              <div>
                <dt>Trạng thái</dt>
                <dd>
                  <StatusBadge status={data.status} />
                </dd>
              </div>
              <div>
                <dt>Mức nghiêm trọng</dt>
                <dd>{data.severity_level}/5</dd>
              </div>
              <div>
                <dt>Điểm ưu tiên</dt>
                <dd>
                  {data.priority_score ?? "—"} · {data.priority_level ?? "—"}
                </dd>
              </div>
              <div>
                <dt>Lượt phản ánh</dt>
                <dd>{data.report_count}</dd>
              </div>
              <div>
                <dt>Ngày tạo</dt>
                <dd>
                  <CalendarDays />{" "}
                  {new Date(data.created_at).toLocaleString("vi-VN")}
                </dd>
              </div>
            </dl>
          </article>

          <IncidentAssignmentPanel model={model} />
        </aside>
      </div>

      <IncidentAssignmentDialog model={model} />

      {toast && <Toast message={toast} onClose={() => setToast("")} />}
    </section>
  );
}
