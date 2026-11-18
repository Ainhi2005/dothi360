import { useEffect, useState } from 'react';
import { AlertTriangle, ArrowRightLeft, Check, CheckCircle2, RefreshCw, Sparkles, UserCheck } from 'lucide-react';
import { PageHeader } from '../components/PageHeader';
import { PageState } from '../components/PageState';
import { StatusBadge } from '../components/StatusBadge';
import { Toast } from '../components/Toast';
import { api, errorMessage } from '../lib/api';
import type { Assignment, Department } from '../types';

interface CandidateOfficer {
  id: string;
  full_name: string;
  email: string;
  phone?: string;
  department_id: string;
  department_name: string;
  active_workload: number;
}

export default function Assignments() {
  const [data, setData] = useState<Assignment[]>([]);
  const [departments, setDepartments] = useState<Department[]>([]);
  const [officers, setOfficers] = useState<CandidateOfficer[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selected, setSelected] = useState<Assignment>();
  const [selectedDeptId, setSelectedDeptId] = useState('');
  const [selectedOfficerId, setSelectedOfficerId] = useState('');
  const [reason, setReason] = useState('');
  const [toast, setToast] = useState('');
  const [approvingId, setApprovingId] = useState<string | null>(null);
  const [filter, setFilter] = useState<'ALL' | 'PENDING' | 'OFFERED' | 'ACTIVE' | 'ENDED'>('ALL');

  const load = () => {
    setLoading(true);
    Promise.all([
      api.get('/assignments'),
      api.get('/departments'),
    ])
      .then(([a, d]) => {
        setData(a.data.data);
        setDepartments(d.data.data);
        setError('');
      })
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    void load();
  }, []);

  // Duyệt nhanh đề xuất của AI (1-Click Approve)
  const handleApproveAi = async (incidentId: string) => {
    try {
      setApprovingId(incidentId);
      await api.post('/assignments/approve-suggestion', { incident_id: incidentId });
      setToast('Đã duyệt phân công cán bộ theo đề xuất AI thành công!');
      load();
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setApprovingId(null);
    }
  };

  // Mở modal điều phối / thay đổi cán bộ
  const openReassignModal = async (assignment: Assignment) => {
    try {
      const response = await api.get('/assignments/candidates', {
        params: { incident_id: assignment.incident_id },
      });
      const candidateDepartments = response.data.data.departments ?? [];
      const candidateOfficers: CandidateOfficer[] = response.data.data.officers ?? [];
      setDepartments(candidateDepartments);
      setOfficers(candidateOfficers);
      setSelected(assignment);
      const initialDept = assignment.department_id || assignment.ai_suggested_department_id || (candidateDepartments[0]?.id ?? '');
      const suggestedOfficerId = assignment.assigned_officer_id || assignment.accepted_by || assignment.ai_suggested_officer_id || '';
      setSelectedDeptId(initialDept);
      setSelectedOfficerId(candidateOfficers.some(o => o.id === suggestedOfficerId) ? suggestedOfficerId : '');
      setReason(assignment.ai_suggestion_reason || 'Quản trị viên phân công cán bộ tiếp nhận xử lý hiện trường');
    } catch (requestError) {
      setError(errorMessage(requestError));
    }
  };

  // Xác nhận phân công thủ công / thay đổi
  const handleConfirmAssignment = async () => {
    if (!selected || !selectedDeptId) return;
    try {
      await api.post('/assignments/assign-officer', {
        incident_id: selected.incident_id,
        department_id: selectedDeptId,
        officer_id: selectedOfficerId || undefined,
        reason: reason.trim() || undefined,
      });
      setSelected(undefined);
      setToast('Đã phân công cán bộ thành công!');
      load();
    } catch (e) {
      setError(errorMessage(e));
    }
  };

  const filteredOfficers = officers.filter(
    (o) => !selectedDeptId || o.department_id === selectedDeptId
  );

  return (
    <section>
      <PageHeader
        title="Phân công cán bộ"
        parent="Điều hành"
        description="AI tự động phân tích & gợi ý cán bộ phù hợp nhất. Quản trị viên chỉ cần 1 click để duyệt hoặc điều chỉnh."
        actions={
          <button className="refresh-button" onClick={load}>
            <RefreshCw /> Làm mới
          </button>
        }
      />

      <div className="assignment-summary">
        <div
          className={filter === 'PENDING' ? 'active' : ''}
          onClick={() => setFilter(filter === 'PENDING' ? 'ALL' : 'PENDING')}
          style={{ cursor: 'pointer' }}
        >
          <strong>{data.filter((a) => !a.id && !a.ended_at).length}</strong>
          <span>Chưa phân công</span>
        </div>
        <div
          className={filter === 'OFFERED' ? 'active' : ''}
          onClick={() => setFilter(filter === 'OFFERED' ? 'ALL' : 'OFFERED')}
          style={{ cursor: 'pointer' }}
        >
          <strong>{data.filter((a) => a.id && !a.accepted_by && !a.ended_at).length}</strong>
          <span>Chờ cán bộ xác nhận</span>
        </div>
        <div
          className={filter === 'ACTIVE' ? 'active' : ''}
          onClick={() => setFilter(filter === 'ACTIVE' ? 'ALL' : 'ACTIVE')}
          style={{ cursor: 'pointer' }}
        >
          <strong>{data.filter((a) => a.accepted_by && !a.ended_at).length}</strong>
          <span>Đang thực hiện</span>
        </div>
        <div
          className={filter === 'ENDED' ? 'active' : ''}
          onClick={() => setFilter(filter === 'ENDED' ? 'ALL' : 'ENDED')}
          style={{ cursor: 'pointer' }}
        >
          <strong>{data.filter((a) => a.ended_at).length}</strong>
          <span>Đã hoàn thành / Kết thúc</span>
        </div>
      </div>

      <article className="panel">
        <PageState
          loading={loading}
          error={error}
          empty={!loading && !error && !data.length}
          onRetry={load}
        />
        {!loading && !error && (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Sự cố</th>
                  <th>Đơn vị chuyên trách</th>
                  <th>Cán bộ phụ trách / Đề xuất AI</th>
                  <th>Phương thức</th>
                  <th>Trạng thái</th>
                  <th style={{ textAlign: 'right' }}>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {data
                  .filter(
                    (a) =>
                      filter === 'ALL' ||
                      (filter === 'PENDING' && !a.id && !a.ended_at) ||
                      (filter === 'OFFERED' && Boolean(a.id) && !a.accepted_by && !a.ended_at) ||
                      (filter === 'ACTIVE' && Boolean(a.accepted_by) && !a.ended_at) ||
                      (filter === 'ENDED' && a.ended_at)
                  )
                  .map((a) => {
                    const isPending = !a.id && !a.ended_at;
                    const hasAiSuggestion = Boolean(a.ai_suggested_officer_name);

                    return (
                      <tr key={a.incident_id} className={a.ended_at ? 'opacity-50' : ''}>
                        <td style={{ maxWidth: 280 }}>
                          <strong style={{ display: 'block', fontSize: 13 }}>
                            {a.incident_type_name ?? 'Sự cố đô thị'}
                          </strong>
                          <small style={{ color: 'var(--muted)', display: 'block' }}>
                            {a.description}
                          </small>
                          {a.rejection_reason && (
                            <div style={{ marginTop: 6, color: '#b45309', display: 'flex', gap: 5, alignItems: 'flex-start' }}>
                              <AlertTriangle style={{ width: 14, height: 14, flexShrink: 0 }} />
                              <small>
                                Cán bộ {a.rejecting_officer_name ?? ''} từ chối: {a.rejection_reason}
                              </small>
                            </div>
                          )}
                        </td>

                        <td>
                          {a.department_name ? (
                            <strong>{a.department_name}</strong>
                          ) : a.ai_suggested_department_name ? (
                            <span style={{ color: '#047857', fontWeight: 600 }}>
                              {a.ai_suggested_department_name}
                            </span>
                          ) : (
                            <span className="muted">Chưa gán đơn vị</span>
                          )}
                        </td>

                        <td style={{ minWidth: 240 }}>
                          {a.officer_name ? (
                            <div>
                              <strong style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                                <UserCheck style={{ width: 15, height: 15, color: '#059669' }} />
                                {a.officer_name}
                              </strong>
                              {a.reason && (
                                <small style={{ color: 'var(--muted)', display: 'block' }}>
                                  {a.reason}
                                </small>
                              )}
                            </div>
                          ) : a.assigned_officer_name ? (
                            <div>
                              <strong style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                                <UserCheck style={{ width: 15, height: 15, color: '#d97706' }} />
                                {a.assigned_officer_name}
                              </strong>
                              <small style={{ color: '#92400e', display: 'block' }}>
                                Chờ cán bộ tiếp nhận hoặc từ chối
                              </small>
                            </div>
                          ) : hasAiSuggestion ? (
                            <div
                              style={{
                                background: '#ECFDF5',
                                border: '1px solid #A7F3D0',
                                borderRadius: 6,
                                padding: '6px 10px',
                              }}
                            >
                              <div
                                style={{
                                  display: 'flex',
                                  alignItems: 'center',
                                  gap: 6,
                                  color: '#065F46',
                                  fontWeight: 600,
                                  fontSize: 12,
                                }}
                              >
                                <Sparkles style={{ width: 13, height: 13, color: '#059669' }} />
                                AI Đề xuất: {a.ai_suggested_officer_name}
                              </div>
                              <small
                                style={{
                                  color: '#047857',
                                  fontSize: 11,
                                  display: 'block',
                                  marginTop: 2,
                                }}
                              >
                                {a.ai_suggestion_reason ?? 'Tải công việc thấp nhất & vị trí tối ưu'}
                              </small>
                            </div>
                          ) : (
                            <span className="muted">Chưa có đề xuất</span>
                          )}
                        </td>

                        <td>
                          <span style={{ fontSize: 12 }}>
                            {a.assignment_method === 'AI_SUGGESTED'
                              ? '🤖 AI Gợi ý'
                              : a.assignment_method === 'MANUAL'
                              ? '👤 Admin chỉ định'
                              : a.assignment_method || '—'}
                          </span>
                        </td>

                        <td>
                          {a.ended_at ? (
                            <span className="status-text status-cancelled">
                              <i />
                              Đã kết thúc
                            </span>
                          ) : a.id && !a.accepted_by ? (
                            <span className="status-text status-assigned"><i />Chờ xác nhận</span>
                          ) : (
                            <StatusBadge status={a.status} />
                          )}
                        </td>

                        <td style={{ textAlign: 'right', whiteSpace: 'nowrap' }}>
                          {!a.ended_at && (
                            <div style={{ display: 'inline-flex', gap: 8 }}>
                              {isPending && hasAiSuggestion && (
                                <button
                                  className="btn-approve-ai"
                                  disabled={approvingId === a.incident_id}
                                  onClick={() => handleApproveAi(a.incident_id)}
                                  title="1 click để duyệt ngay cán bộ do AI đề xuất"
                                >
                                  <Check style={{ width: 14, height: 14 }} />
                                  {approvingId === a.incident_id ? 'Đang duyệt...' : 'Duyệt gợi ý AI'}
                                </button>
                              )}
                              <button
                                className="button secondary"
                                style={{ padding: '6px 12px', fontSize: 12 }}
                                onClick={() => openReassignModal(a)}
                              >
                                <ArrowRightLeft style={{ width: 13, height: 13 }} />
                                {isPending ? 'Chọn cán bộ khác' : 'Điều phối lại'}
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

      {/* Modal Điều phối / Thay đổi cán bộ & đơn vị */}
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
              <button className="icon close-dark" onClick={() => setSelected(undefined)}>
                ×
              </button>
            </div>

            {/* AI Suggestion Card nếu có */}
            {selected.ai_suggested_officer_name && (
              <div className="ai-suggest-banner">
                <div className="ai-suggest-header">
                  <div className="ai-suggest-title">
                    <Sparkles style={{ width: 16, height: 16, color: '#059669' }} />
                    <span>Phương án AI tối ưu</span>
                  </div>
                  <span className="ai-confidence-badge">
                    Độ tin cậy {Math.round((selected.ai_suggestion_confidence ?? 0.95) * 100)}%
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
                      handleApproveAi(selected.incident_id);
                      setSelected(undefined);
                    }}
                  >
                    <Check style={{ width: 14, height: 14 }} />
                    Duyệt ngay đề xuất này
                  </button>
                </div>
                {selected.ai_suggestion_reason && (
                  <p className="ai-suggest-reason">{selected.ai_suggestion_reason}</p>
                )}
              </div>
            )}

            <div style={{ marginTop: 14 }}>
              <label style={{ display: 'block', fontWeight: 600, fontSize: 13, marginBottom: 6 }}>
                1. Chọn Đơn vị chuyên trách:
              </label>
              <select
                value={selectedDeptId}
                onChange={(e) => {
                  setSelectedDeptId(e.target.value);
                  setSelectedOfficerId('');
                }}
                style={{
                  width: '100%',
                  padding: '9px 12px',
                  borderRadius: 6,
                  border: '1px solid var(--border)',
                  background: 'var(--surface)',
                  fontSize: 13,
                }}
              >
                <option value="">-- Tất cả đơn vị chức năng --</option>
                {departments.map((d) => (
                  <option key={d.id} value={d.id}>
                    {d.name} ({d.code})
                  </option>
                ))}
              </select>
            </div>

            <div style={{ marginTop: 14 }}>
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  marginBottom: 6,
                }}
              >
                <label style={{ fontWeight: 600, fontSize: 13 }}>
                  2. Chọn Cán bộ phụ trách hiện trường:
                </label>
                <span style={{ fontSize: 12, color: 'var(--muted)' }}>
                  {filteredOfficers.length} cán bộ trực ban
                </span>
              </div>

              <div className="candidates-grid">
                {filteredOfficers.map((o) => {
                  const isSelected = selectedOfficerId === o.id;
                  const isAiPick = selected.ai_suggested_officer_id === o.id;

                  return (
                    <button
                      key={o.id}
                      type="button"
                      className={`candidate-card ${isSelected ? 'selected' : ''}`}
                      onClick={() => setSelectedOfficerId(o.id)}
                    >
                      <div className="candidate-left">
                        <div className="candidate-check">{isSelected && <CheckCircle2 size={16} />}</div>
                        <div>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                            <strong style={{ fontSize: 13 }}>{o.full_name}</strong>
                            {isAiPick && (
                              <span
                                style={{
                                  background: '#D1FAE5',
                                  color: '#065F46',
                                  fontSize: 10,
                                  fontWeight: 700,
                                  padding: '2px 6px',
                                  borderRadius: 4,
                                }}
                              >
                                ⭐ AI đề xuất
                              </span>
                            )}
                          </div>
                          <small style={{ color: 'var(--muted)', display: 'block', marginTop: 2 }}>
                            {o.department_name} · SĐT: {o.phone || '—'}
                          </small>
                        </div>
                      </div>
                      <div>
                        <span className="officer-workload-tag low">Sẵn sàng nhận việc</span>
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>

            <div style={{ marginTop: 14 }}>
              <label style={{ display: 'block', fontWeight: 600, fontSize: 13, marginBottom: 6 }}>
                Ghi chú điều phối:
              </label>
              <textarea
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                placeholder="Nêu chỉ đạo hoặc yêu cầu cụ thể cho cán bộ tiếp nhận..."
                rows={2}
                style={{
                  width: '100%',
                  padding: '8px 12px',
                  borderRadius: 6,
                  border: '1px solid var(--border)',
                  fontSize: 13,
                }}
              />
            </div>

            <div className="modal-actions" style={{ marginTop: 16 }}>
              <button className="button secondary" onClick={() => setSelected(undefined)}>
                Hủy
              </button>
              <button
                className="button primary"
                disabled={!selectedDeptId}
                onClick={handleConfirmAssignment}
              >
                Xác nhận phân công
              </button>
            </div>
          </div>
        </div>
      )}

      {toast && <Toast message={toast} onClose={() => setToast('')} />}
    </section>
  );
}
