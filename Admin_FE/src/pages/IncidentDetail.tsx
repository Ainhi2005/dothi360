import { useCallback, useEffect, useState } from 'react';
import { ArrowLeft, CalendarDays, MapPin, ShieldCheck, Sparkles, RotateCw, Lightbulb, UserCheck, CheckCircle2, ArrowRightLeft } from 'lucide-react';
import { Link, useParams } from 'react-router-dom';
import { PageState } from '../components/PageState';
import { StatusBadge } from '../components/StatusBadge';
import { Toast } from '../components/Toast';
import { api, errorMessage } from '../lib/api';
import type { IncidentDetail as IncidentDetailType, Department } from '../types';

interface CandidateOfficer {
  id: string;
  full_name: string;
  email: string;
  phone?: string;
  department_id: string;
  department_name: string;
  active_workload: number;
}

export default function IncidentDetail() {
  const { id } = useParams();
  const [data, setData] = useState<IncidentDetailType>();
  const [error, setError] = useState('');
  const [analyzing, setAnalyzing] = useState(false);
  const [analyzeMsg, setAnalyzeMsg] = useState('');
  const [verificationNote, setVerificationNote] = useState('');
  const [verifying, setVerifying] = useState(false);
  const [departments, setDepartments] = useState<Department[]>([]);
  const [officers, setOfficers] = useState<CandidateOfficer[]>([]);
  const [modalOpen, setModalOpen] = useState(false);
  const [selectedDeptId, setSelectedDeptId] = useState('');
  const [selectedOfficerId, setSelectedOfficerId] = useState('');
  const [assignReason, setAssignReason] = useState('');
  const [assigning, setAssigning] = useState(false);
  const [assignmentError, setAssignmentError] = useState('');
  const [approvingAi, setApprovingAi] = useState(false);
  const [toast, setToast] = useState('');

  const load = useCallback(() => api.get(`/incidents/${id}`).then(r => { setData(r.data.data); setError(''); }).catch(e => setError(errorMessage(e))), [id]);
  useEffect(() => { void load(); }, [load]);

  const handleAiAnalyze = async () => {
    try {
      setAnalyzing(true);
      setAnalyzeMsg('');
      await api.post(`/incidents/${id}/ai-analyze`);
      await load();
      setAnalyzeMsg('Phân tích AI hoàn tất!');
    } catch (e) {
      setAnalyzeMsg(errorMessage(e));
    } finally {
      setAnalyzing(false);
    }
  };

  const verify = async (decision: 'APPROVE'|'REWORK') => {
    if (verificationNote.trim().length < 3) return;
    try {
      setVerifying(true);
      await api.patch(`/incidents/${id}/verification`, { decision, note: verificationNote.trim() });
      setVerificationNote('');
      await load();
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setVerifying(false);
    }
  };

  const handleApproveAi = async () => {
    if (!data) return;
    try {
      setApprovingAi(true);
      await api.post('/assignments/approve-suggestion', { incident_id: data.id });
      setToast('Đã duyệt phân công cán bộ theo đề xuất AI thành công!');
      await load();
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setApprovingAi(false);
    }
  };

  const openAssignModal = async () => {
    if (!data) return;
    let availableDepartments = departments;
    let availableOfficers = officers;
    try {
      const response = await api.get('/assignments/candidates', {
        params: { incident_id: data.id },
      });
      availableDepartments = response.data.data.departments ?? [];
      availableOfficers = response.data.data.officers ?? [];
      setDepartments(availableDepartments);
      setOfficers(availableOfficers);
    } catch (e) {
      setError(errorMessage(e));
      return;
    }
    const initDept = data.assignment?.department_id ||
      data.ai_suggestion?.department_id || availableDepartments[0]?.id || '';
    const suggestedOfficerId = data.assignment?.assigned_officer_id || data.assignment?.accepted_by ||
      data.ai_suggestion?.officer_id || '';
    const initOfficer = availableOfficers.some((officer: CandidateOfficer) => officer.id === suggestedOfficerId)
      ? suggestedOfficerId
      : '';
    setSelectedDeptId(initDept);
    setSelectedOfficerId(initOfficer);
    setAssignReason(data?.ai_suggestion?.reason || 'Quản trị viên phân công cán bộ tiếp nhận xử lý hiện trường');
    setAssignmentError('');
    setModalOpen(true);
  };

  const handleConfirmAssignment = async () => {
    if (!data || !selectedDeptId) return;
    try {
      setAssigning(true);
      setAssignmentError('');
      await api.post('/assignments/assign-officer', {
        incident_id: data.id,
        department_id: selectedDeptId,
        officer_id: selectedOfficerId || undefined,
        reason: assignReason.trim() || undefined,
      });
      setModalOpen(false);
      setToast('Đã phân công cán bộ thành công!');
      await load();
    } catch (e) {
      setAssignmentError(errorMessage(e));
    } finally {
      setAssigning(false);
    }
  };

  if (!data || error) return <PageState loading={!error} error={error} onRetry={load}/>;

  return <section>
    <Link className="back-link" to="/incidents"><ArrowLeft/> Quay lại danh sách</Link>
    <div className="page-heading">
      <div>
        <span className="eyebrow">HỒ SƠ SỰ CỐ · {data.id.slice(0,8).toUpperCase()}</span>
        <h2>{data.incident_type?.name ?? 'Sự cố đô thị'}</h2>
        <p>{data.description}</p>
      </div>
      <StatusBadge status={data.status}/>
    </div>
    <div className="detail-grid">
      <div className="detail-main">
        {data.status === 'PENDING_VERIFICATION' && (
          <article className="panel detail-section verification-panel">
            <div className="section-head-with-action">
              <div>
                <h3>Nghiệm thu kết quả xử lý</h3>
                <p className="muted">Kiểm tra minh chứng hiện trường của cán bộ và đối soát trước khi đóng sự cố.</p>
              </div>
              <StatusBadge status={data.status}/>
            </div>

            <div className="before-after-grid">
              <div>
                <strong>📸 Ảnh người dân gửi (Hiện trạng ban đầu)</strong>
                <div className="media-grid">
                  {data.report_media?.length ? (
                    data.report_media.slice(0, 3).map(media => (
                      <img key={media.id} src={media.file_url} alt="Hiện trạng ban đầu" />
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
                    data.officer_media.slice(-3).map(media => (
                      <img key={media.id} src={media.file_url} alt="Kết quả xử lý" />
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
                value={verificationNote}
                onChange={event => setVerificationNote(event.target.value)}
                placeholder="Nhập kết luận nghiệm thu hoặc nội dung yêu cầu cán bộ xử lý bổ sung (tối thiểu 3 ký tự)..."
                rows={3}
              />
              {verificationNote.trim().length > 0 && verificationNote.trim().length < 3 && (
                <small style={{ color: 'var(--warning)', marginTop: 4, display: 'block' }}>
                  Vui lòng nhập tối thiểu 3 ký tự ý kiến nghiệm thu.
                </small>
              )}
            </div>

            <div className="verification-panel-actions">
              <button
                type="button"
                className="button secondary danger-text"
                disabled={verifying || verificationNote.trim().length < 3}
                onClick={() => verify('REWORK')}
                style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}
              >
                <RotateCw size={15} />
                {verifying ? 'Đang gửi...' : 'Yêu cầu xử lý lại'}
              </button>
              <button
                type="button"
                className="button primary"
                disabled={verifying || verificationNote.trim().length < 3}
                onClick={() => verify('APPROVE')}
                style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}
              >
                <CheckCircle2 size={15} />
                {verifying ? 'Đang duyệt...' : 'Duyệt hoàn thành sự cố'}
              </button>
            </div>
          </article>
        )}
        {/* Hình ảnh hiện trường */}
        <article className="panel detail-section">
          <h3>Hình ảnh hiện trường</h3>
          <div className="media-grid">
            {data.media?.length ? data.media.map(m => <img key={m.id} src={m.file_url} alt="Minh chứng sự cố"/>) : <div className="empty-media">Chưa có hình ảnh</div>}
          </div>
        </article>

        {/* Khối AI Phân tích & Biện pháp xử lý đề xuất */}
        <article className="panel detail-section ai-highlight-panel">
          <div className="section-head-with-action">
            <div className="ai-title-wrap">
              <Sparkles className="ai-icon" />
              <div>
                <h3>Kết quả AI & Biện pháp đề xuất</h3>
                <p className="ai-subtitle">Dữ liệu phân tích hiện trường đã được người dân xác nhận khi gửi phản ánh</p>
              </div>
            </div>
            {data.ai_analysis && (
              <span className="dot-label active" style={{ fontSize: 12 }}>
                Đã lưu từ phản ánh người dân
              </span>
            )}
          </div>

          {analyzeMsg && <p className="ai-status-msg">{analyzeMsg}</p>}

          {data.ai_analysis ? (
            <div className="ai-content-body">
              {/* Quick Metrics Strip */}
              <div className="ai-decision-grid">
                <div className="ai-metric-box">
                  <small>Độ tin cậy AI</small>
                  <strong style={{ color: 'var(--primary)' }}>{Math.round((data.ai_analysis.confidence ?? 0.85) * 100)}%</strong>
                </div>
                <div className="ai-metric-box">
                  <small>Mức độ rủi ro</small>
                  <span className={`risk-tag risk-${(data.ai_analysis.risk_level ?? 'medium').toLowerCase()}`}>
                    {data.ai_analysis.risk_level ?? 'TRUNG BÌNH'}
                  </span>
                </div>
                <div className="ai-metric-box">
                  <small>SLA kiến nghị</small>
                  <strong>{data.ai_analysis.suggested_sla_hours ?? '—'} giờ</strong>
                </div>
                <div className="ai-metric-box">
                  <small>Loại đề xuất</small>
                  <strong>{data.ai_analysis.suggested_incident_type ?? data.incident_type?.name ?? '—'}</strong>
                </div>
                <div className="ai-metric-box">
                  <small>Mức nghiêm trọng</small>
                  <strong>{data.ai_analysis.suggested_severity ? `${data.ai_analysis.suggested_severity}/5` : '—'}</strong>
                </div>
              </div>

              {/* HIGHLIGHTED RECOMMENDED ACTIONS */}
              {data.ai_analysis.recommended_action && (
                <div className="ai-action-highlight">
                  <div className="ai-action-badge">
                    <Lightbulb />
                    <strong>Biện pháp chỉ đạo / xử lý đề xuất:</strong>
                  </div>
                  <p className="ai-action-text">{data.ai_analysis.recommended_action}</p>
                </div>
              )}

              {/* DETAILED REASON */}
              {data.ai_analysis.reason && (
                <div className="ai-reason-box">
                  <strong>
                    {data.ai_analysis.user_edited_reason
                      ? 'Nội dung người dân đã chỉnh:'
                      : 'Chi tiết nhận định của AI:'}
                  </strong>
                  <p>{data.ai_analysis.reason}</p>
                  {data.ai_analysis.user_edited_reason && data.ai_analysis.original_reason && (
                    <small style={{ display: 'block', marginTop: 8, color: 'var(--muted)' }}>
                      Bản AI ban đầu: {data.ai_analysis.original_reason}
                    </small>
                  )}
                </div>
              )}

              {/* DETECTED SIGNALS */}
              {data.ai_analysis.detected_signals && data.ai_analysis.detected_signals.length > 0 && (
                <div className="ai-signals-wrap">
                  <small>Dấu hiệu nhận diện từ ảnh hiện trường:</small>
                  <div className="ai-signals">
                    {data.ai_analysis.detected_signals.map(s => (
                      <span key={s} className="ai-signal-chip">👁️ {s}</span>
                    ))}
                  </div>
                </div>
              )}

              {data.duplicate_evidence && (
                <p className="duplicate-evidence">
                  Khả năng trùng {Math.round((data.duplicate_evidence.score ?? 0) * 100)}% · cách {Math.round(data.duplicate_evidence.distance_m ?? 0)} m · nội dung {Math.round((data.duplicate_evidence.text_score ?? 0) * 100)}% · dấu hiệu ảnh {Math.round((data.duplicate_evidence.visual_signal_score ?? 0) * 100)}%
                </p>
              )}

              {data.media && data.media.length > 0 && (
                <div style={{ marginTop: 12, paddingTop: 10, borderTop: '1px solid var(--border)', display: 'flex', justifyContent: 'flex-end' }}>
                  <button
                    type="button"
                    className="text-button"
                    onClick={handleAiAnalyze}
                    disabled={analyzing}
                    style={{ fontSize: 12, display: 'inline-flex', alignItems: 'center', gap: 6 }}
                  >
                    <RotateCw className={analyzing ? 'spin' : ''} style={{ width: 13, height: 13 }} />
                    {analyzing ? 'Đang chạy lại phân tích...' : 'Phân tích lại ảnh bằng AI'}
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
                  onClick={handleAiAnalyze} 
                  disabled={analyzing}
                >
                  <Sparkles style={{ width: 16, height: 16 }} />
                  {analyzing ? 'Đang phân tích...' : 'Kích hoạt AI phân tích hình ảnh ngay'}
                </button>
              ) : (
                <small className="muted">Cần có ảnh hiện trường để kích hoạt phân tích tự động.</small>
              )}
            </div>
          )}
        </article>

        {/* Lịch sử xử lý */}
        <article className="panel detail-section">
          <h3>Lịch sử xử lý</h3>
          <div className="timeline">
            {data.updates?.length ? data.updates.map(u => (
              <div className="timeline-item" key={u.id}>
                <i/>
                <div>
                  <strong>{u.new_status ? <StatusBadge status={u.new_status}/> : 'Cập nhật'}</strong>
                  <p>{u.note || 'Không có ghi chú'}</p>
                  {u.progress_percent != null && <div className="progress-meta"><strong>{u.progress_percent}% hoàn thành</strong>{u.estimated_completion_at && <span>Dự kiến: {new Date(u.estimated_completion_at).toLocaleDateString('vi-VN')}</span>}<span>{u.visibility === 'INTERNAL' ? 'Nội bộ' : 'Công khai'}</span></div>}
                  {u.blocker && <p className="warning-text">Khó khăn: {u.blocker}</p>}
                  <small>{new Date(u.created_at).toLocaleString('vi-VN')}</small>
                  {u.media_urls && u.media_urls.length > 0 && (
                    <div style={{ display: 'flex', gap: 8, marginTop: 8, flexWrap: 'wrap' }}>
                      {u.media_urls.map((url, i) => (
                        <a key={i} href={url} target="_blank" rel="noreferrer" title="Xem ảnh cập nhật kích thước lớn">
                          <img
                            src={url}
                            alt="Ảnh cập nhật của cán bộ"
                            style={{
                              width: 72,
                              height: 72,
                              objectFit: 'cover',
                              borderRadius: 6,
                              border: '1px solid var(--border)',
                              cursor: 'pointer',
                            }}
                          />
                        </a>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            )) : <p className="muted">Chưa có cập nhật xử lý.</p>}
          </div>
        </article>
      </div>

      <aside className="detail-side">
        <article className="panel detail-section">
          <h3>Thông tin nghiệp vụ</h3>
          <dl>
            <div><dt>Trạng thái</dt><dd><StatusBadge status={data.status}/></dd></div>
            <div><dt>Mức nghiêm trọng</dt><dd>{data.severity_level}/5</dd></div>
            <div><dt>Điểm ưu tiên</dt><dd>{data.priority_score ?? '—'} · {data.priority_level ?? '—'}</dd></div>
            <div><dt>Lượt phản ánh</dt><dd>{data.report_count}</dd></div>
            <div><dt>Ngày tạo</dt><dd><CalendarDays/> {new Date(data.created_at).toLocaleString('vi-VN')}</dd></div>
          </dl>
        </article>

        <article className="panel detail-section">
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
            <h3 style={{ margin: 0 }}>Điều phối & Cán bộ</h3>
            {data.assignment?.accepted_by ? (
              <span className="dot-label active" style={{ fontSize: 11, background: '#ECFDF5', color: '#065F46', padding: '2px 8px', borderRadius: 4 }}>
                ✓ Đã tiếp nhận
              </span>
            ) : data.assignment?.assigned_officer_id ? (
              <span className="dot-label pending" style={{ fontSize: 11, background: '#FEF3C7', color: '#92400E', padding: '2px 8px', borderRadius: 4 }}>
                Chờ cán bộ xác nhận
              </span>
            ) : (
              <span className="dot-label pending" style={{ fontSize: 11, background: '#FEF3C7', color: '#92400E', padding: '2px 8px', borderRadius: 4 }}>
                Chờ duyệt / phân công
              </span>
            )}
          </div>

          {/* Nếu có AI Suggestion và chưa có cán bộ nhận chính thức */}
          {!data.assignment?.accepted_by && !data.assignment?.assigned_officer_id && data.ai_suggestion && (
            <div className="ai-assignment-banner" style={{ margin: '0 0 16px 0', border: '1px solid #A7F3D0', background: 'linear-gradient(135deg, #F0FDF4 0%, #ECFDF5 100%)', borderRadius: 8, padding: 12 }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
                <span className="ai-suggestion-badge">
                  <Sparkles size={13} /> AI Đề xuất cán bộ
                </span>
                <span className="ai-confidence-pill">
                  Độ tin cậy {Math.round((data.ai_suggestion.confidence ?? 0.95) * 100)}%
                </span>
              </div>

              <div style={{ background: '#FFF', borderRadius: 6, padding: '10px 12px', border: '1px solid #D1FAE5', marginBottom: 10 }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <strong style={{ fontSize: 14, color: '#065F46' }}>
                    {data.ai_suggestion.officer_name}
                  </strong>
                  <span className={`officer-workload-tag ${data.ai_suggestion.active_workload === 0 ? 'low' : data.ai_suggestion.active_workload <= 2 ? 'medium' : 'high'}`}>
                    {data.ai_suggestion.active_workload === 0 ? '🟢 0 việc đang xử lý' : `${data.ai_suggestion.active_workload} việc đang xử lý`}
                  </span>
                </div>
                <div style={{ fontSize: 12, color: 'var(--muted)', marginTop: 4, display: 'flex', alignItems: 'center', gap: 6 }}>
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
                <div style={{ fontSize: 11.5, color: '#047857', background: 'rgba(255,255,255,0.7)', padding: '6px 8px', borderRadius: 4, marginBottom: 12, lineHeight: 1.4 }}>
                  💡 {data.ai_suggestion.reason}
                </div>
              )}

              <div style={{ display: 'flex', gap: 8, flexDirection: 'column' }}>
                <button
                  type="button"
                  className="btn-approve-ai"
                  disabled={approvingAi}
                  onClick={handleApproveAi}
                  style={{ width: '100%', justifyContent: 'center', padding: '8px 12px', fontSize: 13 }}
                >
                  <CheckCircle2 size={16} />
                  {approvingAi ? 'Đang duyệt...' : '✓ Duyệt đề xuất AI ngay'}
                </button>
                <button
                  type="button"
                  className="button secondary"
                  onClick={openAssignModal}
                  style={{ width: '100%', justifyContent: 'center', fontSize: 12, padding: '6px 12px' }}
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
                    <strong><UserCheck size={14} style={{ display: 'inline', verticalAlign: -2, marginRight: 4 }} />{data.assignment.officer_name || 'Đã phân công'}</strong>
                  </dd>
                </div>
                {data.assignment.officer_phone && (
                  <div>
                    <dt>Điện thoại</dt>
                    <dd>
                      <a href={`tel:${data.assignment.officer_phone}`} style={{ color: 'var(--primary)', textDecoration: 'none' }}>
                        📞 {data.assignment.officer_phone}
                      </a>
                    </dd>
                  </div>
                )}
                <div>
                  <dt>Đơn vị</dt>
                  <dd><ShieldCheck size={14} style={{ display: 'inline', verticalAlign: -2, marginRight: 4 }} />{data.assignment.department_name ?? '—'}</dd>
                </div>
                <div>
                  <dt>Phương thức</dt>
                  <dd>{data.assignment.assignment_method ?? '—'}</dd>
                </div>
                <div>
                  <dt>Thời gian giao</dt>
                  <dd>{data.assignment.assigned_at ? new Date(data.assignment.assigned_at).toLocaleString('vi-VN') : '—'}</dd>
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
                onClick={openAssignModal}
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
                  <dd><strong><UserCheck size={14} style={{ display: 'inline', verticalAlign: -2, marginRight: 4 }} />{data.assignment.assigned_officer_name ?? '—'}</strong></dd>
                </div>
                <div><dt>Trạng thái tiếp nhận</dt><dd style={{ color: '#92400e' }}>Đang chờ phản hồi</dd></div>
                <div><dt>Đơn vị</dt><dd>{data.assignment.department_name ?? '—'}</dd></div>
                <div><dt>Thời gian giao</dt><dd>{data.assignment.assigned_at ? new Date(data.assignment.assigned_at).toLocaleString('vi-VN') : '—'}</dd></div>
              </dl>
              <button type="button" className="button secondary full-button" onClick={openAssignModal} style={{ marginTop: 12 }}>
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
                onClick={openAssignModal}
              >
                <UserCheck size={14} /> Phân công cán bộ ngay
              </button>
            </div>
          ) : null}

          <div style={{ marginTop: 12, paddingTop: 10, borderTop: '1px solid var(--border)', textAlign: 'right' }}>
            <Link to="/assignments" style={{ fontSize: 12, color: 'var(--muted)', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
              <MapPin size={12} /> Bảng điều phối tổng thể
            </Link>
          </div>
        </article>
      </aside>
    </div>

    {modalOpen && (
      <div className="modal-backdrop" onClick={() => setModalOpen(false)}>
        <div className="modal assignment-dialog" role="dialog" aria-modal="true" aria-labelledby="assignment-dialog-title" onClick={(e) => e.stopPropagation()}>
          <div className="assignment-dialog-header">
            <div>
              <h3 id="assignment-dialog-title">Điều chuyển cán bộ</h3>
              <small>
                Sự cố: {data.incident_type?.name ?? 'Sự cố đô thị'} ({data.id.slice(0, 8).toUpperCase()})
              </small>
            </div>
            <button
              type="button"
              className="assignment-dialog-close"
              aria-label="Đóng hộp thoại"
              onClick={() => setModalOpen(false)}
            >
              &times;
            </button>
          </div>

          <div className="assignment-dialog-body">
            <label className="assignment-field">
              <span>Đơn vị chuyên trách</span>
              <select
                value={selectedDeptId}
                onChange={(e) => {
                  setSelectedDeptId(e.target.value);
                  setSelectedOfficerId('');
                }}
              >
                {departments.map((d) => (
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
                  <small>Chọn một cán bộ hoặc để trống để giao chung cho đơn vị.</small>
                </div>
                <span>
                  {officers.filter((o) => !selectedDeptId || o.department_id === selectedDeptId).length} cán bộ
                </span>
              </div>

              <div className="candidates-grid">
                {officers.filter((o) => !selectedDeptId || o.department_id === selectedDeptId).length === 0 && (
                  <div className="assignment-empty-candidates">Đơn vị này chưa có cán bộ đang hoạt động.</div>
                )}
                {officers
                  .filter((o) => !selectedDeptId || o.department_id === selectedDeptId)
                  .map((o) => {
                    const isSelected = selectedOfficerId === o.id;
                    const isAiPick = data.ai_suggestion?.officer_id === o.id;

                    return (
                      <button
                        key={o.id}
                        type="button"
                        className={`candidate-card ${isSelected ? 'selected' : ''}`}
                        onClick={() => setSelectedOfficerId(isSelected ? '' : o.id)}
                      >
                        <div className="candidate-left">
                          <div className="candidate-check">{isSelected && <CheckCircle2 size={16} />}</div>
                          <div className="candidate-identity">
                            <div>
                              <strong>{o.full_name}</strong>
                              {isAiPick && <span className="candidate-ai-label"><Sparkles size={11}/> AI đề xuất</span>}
                            </div>
                            <small>{o.phone || 'Chưa có số điện thoại'}</small>
                          </div>
                        </div>
                        <span className={`officer-workload-tag ${o.active_workload === 0 ? 'low' : o.active_workload <= 2 ? 'medium' : 'high'}`}>
                          {o.active_workload === 0 ? 'Sẵn sàng' : `${o.active_workload} việc đang xử lý`}
                        </span>
                      </button>
                    );
                  })}
              </div>
            </div>

            <label className="assignment-field">
              <span>Chỉ đạo xử lý</span>
              <textarea
                value={assignReason}
                onChange={(e) => setAssignReason(e.target.value)}
                placeholder="Nêu yêu cầu cụ thể cho cán bộ tiếp nhận..."
                rows={3}
              />
            </label>
            {assignmentError && <div className="assignment-dialog-error">{assignmentError}</div>}
          </div>

          <div className="assignment-dialog-footer">
            <button className="button secondary" disabled={assigning} onClick={() => setModalOpen(false)}>
              Hủy
            </button>
            <button
              className="button primary"
              disabled={!selectedDeptId || assigning}
              onClick={handleConfirmAssignment}
            >
              {assigning ? 'Đang phân công...' : 'Xác nhận điều chuyển'}
            </button>
          </div>
        </div>
      </div>
    )}

    {toast && <Toast message={toast} onClose={() => setToast('')} />}
  </section>;
}
