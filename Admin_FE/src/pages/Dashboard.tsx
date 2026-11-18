import { useEffect, useState } from 'react';
import {
  AlertCircle,
  ArrowRight,
  Clock3,
  RefreshCw,
  CheckCircle2,
  ExternalLink,
} from 'lucide-react';
import { Link } from 'react-router-dom';
import { PageHeader } from '../components/PageHeader';
import { PageState } from '../components/PageState';
import { api, errorMessage } from '../lib/api';

type Summary = {
  total: number;
  open: number;
  unassigned: number;
  waiting: number;
  processing: number;
  pending_verification: number;
  resolved: number;
  urgent: number;
  officers: number;
  active_users: number;
  completion_rate: number;
};

type SlaIncident = {
  id: string;
  description: string;
  status: string;
  priority_level: string;
  created_at: string;
  age_hours: number;
  sla_hours: number;
};

type WorkloadDept = {
  id: string;
  name: string;
  open: number;
  completed: number;
};

type PriorityIncident = {
  id: string;
  incident_id?: string;
  incident_type_name?: string;
  description: string;
  status: string;
  priority_level?: string;
  priority_score?: number;
  department_name?: string;
  officer_name?: string;
  created_at?: string;
  assigned_at?: string;
};

const formatPriority = (level?: string) => {
  switch (level) {
    case 'EMERGENCY':
      return { label: 'KHẨN CẤP', className: 'priority-tag emergency' };
    case 'HIGH':
      return { label: 'CAO', className: 'priority-tag high' };
    case 'MEDIUM':
      return { label: 'TRUNG BÌNH', className: 'priority-tag medium' };
    case 'LOW':
      return { label: 'THẤP', className: 'priority-tag low' };
    default:
      return { label: 'THƯỜNG', className: 'priority-tag default' };
  }
};

export default function Dashboard() {
  const [summary, setSummary] = useState<Summary>();
  const [slaList, setSlaList] = useState<SlaIncident[]>([]);
  const [workload, setWorkload] = useState<WorkloadDept[]>([]);
  const [incidents, setIncidents] = useState<PriorityIncident[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const loadData = () => {
    setLoading(true);
    Promise.all([
      api.get('/admin/dashboard/summary'),
      api.get('/admin/dashboard/sla'),
      api.get('/admin/dashboard/workload'),
      api.get('/assignments', { params: { limit: 6 } }),
    ])
      .then(([summaryRes, slaRes, workloadRes, assignmentsRes]) => {
        setSummary(summaryRes.data.data);
        setSlaList(Array.isArray(slaRes.data.data) ? slaRes.data.data : []);
        setWorkload(Array.isArray(workloadRes.data.data) ? workloadRes.data.data.slice(0, 5) : []);
        const rawAssignments = assignmentsRes.data.data?.data ?? assignmentsRes.data.data ?? [];
        setIncidents(Array.isArray(rawAssignments) ? rawAssignments.slice(0, 6) : []);
        setError('');
      })
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    void loadData();
  }, []);

  if (loading || error) {
    return <PageState loading={loading} error={error} onRetry={loadData} />;
  }

  const overdueCount = slaList.length;
  const urgentCount = summary?.urgent ?? 0;
  const unassignedCount = summary?.unassigned ?? 0;
  const pendingVerificationCount = summary?.pending_verification ?? 0;

  // Dải KPI phẳng bằng typography và vạch chia, không icon card
  const metrics = [
    {
      label: 'Chờ phân công',
      value: unassignedCount,
      alert: unassignedCount > 0,
      tone: 'warning',
    },
    {
      label: 'Khẩn cấp trong ca',
      value: urgentCount,
      alert: urgentCount > 0,
      tone: 'danger',
    },
    {
      label: 'Quá hạn SLA',
      value: overdueCount,
      alert: overdueCount > 0,
      tone: 'danger',
    },
    {
      label: 'Đang xử lý tại chỗ',
      value: summary?.processing ?? 0,
      alert: false,
      tone: 'neutral',
    },
    {
      label: 'Chờ nghiệm thu',
      value: pendingVerificationCount,
      alert: pendingVerificationCount > 0,
      tone: 'info',
    },
    {
      label: 'Tỷ lệ giải quyết',
      value: `${summary?.completion_rate ?? 0}%`,
      alert: false,
      tone: 'success',
    },
  ];

  return (
    <section className="dashboard-sheet">
      <PageHeader
        title="Trung tâm điều phối"
        parent="Điều hành đô thị"
        description="Theo dõi hàng đợi tác nghiệp, phân công nhiệm vụ và cảnh báo tiến độ thời gian thực."
        actions={
          <button
            className="refresh-button"
            onClick={loadData}
            title="Làm mới dữ liệu từ máy chủ"
          >
            <RefreshCw size={14} /> Làm mới
          </button>
        }
      />

      {/* DẢI KPI BẰNG TYPOGRAPHY VÀ VẠCH CHIA - KHÔNG ICON CARD */}
      <div className="flat-metrics-strip">
        {metrics.map((m) => (
          <div className="metric-col" key={m.label}>
            <strong className={`metric-num ${m.alert ? m.tone : ''}`}>
              {m.value}
            </strong>
            <span className="metric-label">{m.label}</span>
          </div>
        ))}
      </div>

      {/* HÀNG ĐỢI KHẨN: NỘI DUNG CHÍNH TRẢ LỜI CÂU HỎI ĐIỀU PHỐI */}
      <div className="queue-section">
        <div className="section-header-compact">
          <h2>Hàng đợi cần xử lý ngay</h2>
          <span className="section-subtext">
            Ưu tiên giải quyết theo mức độ ảnh hưởng và giới hạn SLA
          </span>
        </div>

        <div className="dispatch-queues-grid">
          {/* Hàng đợi 1: Chờ phân công */}
          <Link
            to="/assignments?status=PENDING_ASSIGNMENT"
            className={`dispatch-queue-tile ${unassignedCount > 0 ? 'active-alert' : ''}`}
          >
            <div className="queue-tile-top">
              <span className="queue-badge warning">
                <Clock3 size={13} /> Chờ phân công
              </span>
              <strong className="queue-count">{unassignedCount}</strong>
            </div>
            <p className="queue-desc">
              Sự cố phản ánh mới chưa được giao đơn vị chuyên trách xử lý.
            </p>
            <div className="queue-action-link">
              <span>Mở bảng phân công</span>
              <ArrowRight size={14} />
            </div>
          </Link>

          {/* Hàng đợi 2: Quá hạn SLA & Khẩn cấp */}
          <Link
            to="/incidents?priority=HIGH"
            className={`dispatch-queue-tile ${overdueCount > 0 || urgentCount > 0 ? 'active-danger' : ''}`}
          >
            <div className="queue-tile-top">
              <span className="queue-badge danger">
                <AlertCircle size={13} /> Khẩn cấp & Quá SLA
              </span>
              <strong className="queue-count">
                {Math.max(overdueCount, urgentCount)}
              </strong>
            </div>
            <p className="queue-desc">
              {overdueCount > 0
                ? `Có ${overdueCount} sự cố đã trễ hạn cam kết, cần can thiệp đôn đốc.`
                : 'Sự cố mức độ cao hoặc khẩn cấp cần phản ứng ngay lập tức.'}
            </p>
            <div className="queue-action-link">
              <span>Xử lý sự cố ưu tiên</span>
              <ArrowRight size={14} />
            </div>
          </Link>

          {/* Hàng đợi 3: Chờ nghiệm thu */}
          <Link
            to="/incidents?status=PENDING_VERIFICATION"
            className={`dispatch-queue-tile ${pendingVerificationCount > 0 ? 'active-info' : ''}`}
          >
            <div className="queue-tile-top">
              <span className="queue-badge info">
                <CheckCircle2 size={13} /> Chờ nghiệm thu
              </span>
              <strong className="queue-count">{pendingVerificationCount}</strong>
            </div>
            <p className="queue-desc">
              Cán bộ hiện trường đã gửi minh chứng xử lý, chờ đối soát đóng hồ sơ.
            </p>
            <div className="queue-action-link">
              <span>Kiểm định kết quả</span>
              <ArrowRight size={14} />
            </div>
          </Link>
        </div>
      </div>

      {/* BỐ CỤC 2 CỘT: BẢNG SỰ CỐ ƯU TIÊN VÀ TẢI ĐƠN VỊ */}
      <div className="workspace-main-grid">
        {/* Bảng sự cố: hiển thị Priority, SLA, Đơn vị và Hành động */}
        <div className="sheet-panel incident-table-panel">
          <div className="panel-title-bar">
            <div>
              <h3>Danh sách sự cố cần điều phối</h3>
              <p>Sắp xếp theo mức độ ưu tiên và thời hạn xử lý</p>
            </div>
            <Link to="/incidents" className="panel-more-link">
              Tất cả sự cố <ExternalLink size={13} />
            </Link>
          </div>

          <div className="table-responsive">
            <table className="dispatch-table">
              <thead>
                <tr>
                  <th>Sự cố & Vị trí</th>
                  <th>Mức ưu tiên</th>
                  <th>Thời hạn SLA</th>
                  <th>Đơn vị phụ trách</th>
                  <th style={{ textAlign: 'right' }}>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {incidents.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="empty-table-cell">
                      Hiện tại không có sự cố nào trong hàng đợi cần can thiệp.
                    </td>
                  </tr>
                ) : (
                  incidents.map((inc) => {
                    const priority = formatPriority(inc.priority_level);
                    const incidentId = inc.incident_id ?? inc.id;
                    const isOverdue = slaList.some((s) => s.id === incidentId);

                    return (
                      <tr key={inc.id}>
                        <td className="cell-incident">
                          <Link
                            to={`/incidents/${incidentId}`}
                            className="incident-title-link"
                          >
                            {inc.incident_type_name ?? 'Sự cố đô thị'}
                          </Link>
                          <span className="incident-desc-snippet">
                            {inc.description}
                          </span>
                        </td>
                        <td>
                          <span className={priority.className}>
                            {priority.label}
                          </span>
                        </td>
                        <td>
                          {isOverdue ? (
                            <span className="sla-tag overdue">
                              Đã quá hạn
                            </span>
                          ) : (
                            <span className="sla-tag in-time">
                              Trong hạn
                            </span>
                          )}
                        </td>
                        <td>
                          {inc.department_name ? (
                            <span className="dept-name">
                              {inc.department_name}
                            </span>
                          ) : (
                            <span className="dept-unassigned">
                              Chưa phân công
                            </span>
                          )}
                        </td>
                        <td style={{ textAlign: 'right' }}>
                          <Link
                            to={
                              inc.department_name
                                ? `/incidents/${incidentId}`
                                : `/assignments`
                            }
                            className="table-action-button"
                          >
                            {inc.department_name ? 'Chi tiết' : 'Phân công'}
                          </Link>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Khối tải đơn vị & Nhân lực */}
        <div className="sheet-panel workload-panel">
          <div className="panel-title-bar">
            <div>
              <h3>Tải công việc đơn vị</h3>
              <p>Khối lượng đang xử lý trực tiếp</p>
            </div>
            <Link to="/departments" className="panel-more-link">
              Quản lý <ArrowRight size={13} />
            </Link>
          </div>

          <div className="workload-rows">
            {workload.length === 0 ? (
              <div className="empty-workload">Chưa có số liệu tải công việc</div>
            ) : (
              workload.map((dept) => (
                <div className="workload-item" key={dept.id}>
                  <div className="workload-dept-info">
                    <strong className="workload-dept-name">{dept.name}</strong>
                    <span className="workload-stats-text">
                      Đã giải quyết: {dept.completed} việc
                    </span>
                  </div>
                  <div className="workload-count-badge">
                    <span>{dept.open} đang mở</span>
                  </div>
                </div>
              ))
            )}
          </div>

          <div className="panel-footer-stat">
            <span>Cán bộ trực tuyến: <strong>{summary?.officers ?? 0}</strong></span>
            <span>Tỷ lệ hoàn thành: <strong>{summary?.completion_rate ?? 0}%</strong></span>
          </div>
        </div>
      </div>
    </section>
  );
}
