import { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { ThumbsUp, CheckCircle, XCircle, RefreshCw, Send, MapPin } from 'lucide-react';
import { api, errorMessage } from '../lib/api';
import { PageHeader } from '../components/PageHeader';
import { PageState } from '../components/PageState';

interface FeedbackItem {
  id: string;
  user_id: string;
  user_name: string;
  title: string;
  content: string;
  category: string;
  location_name: string | null;
  upvotes: number;
  status: 'PENDING' | 'ACCEPTED' | 'REJECTED';
  admin_response: string | null;
  responder_name: string | null;
  responded_at: string | null;
  created_at: string;
}

const CATEGORY_MAP: Record<string, { label: string; color: string }> = {
  TRAFFIC: { label: 'Giao thông', color: '#2563eb' },
  GREENERY: { label: 'Cây xanh', color: '#16a34a' },
  LIGHTING: { label: 'Chiếu sáng', color: '#eab308' },
  DRAINAGE: { label: 'Thoát nước', color: '#06b6d4' },
  ENVIRONMENT: { label: 'Môi trường', color: '#10b981' },
  GENERAL: { label: 'Chung', color: '#6b7280' },
};

export default function CitizenFeedbacks() {
  const [searchParams, setSearchParams] = useSearchParams();
  const feedbackId = searchParams.get('feedbackId');
  const [feedbacks, setFeedbacks] = useState<FeedbackItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [filterCategory, setFilterCategory] = useState('ALL');
  const [filterStatus, setFilterStatus] = useState('ALL');

  // Modal phản hồi
  const [selectedFeedback, setSelectedFeedback] = useState<FeedbackItem | null>(null);
  const [responseAction, setResponseAction] = useState<'ACCEPTED' | 'REJECTED'>('ACCEPTED');
  const [responseNote, setResponseNote] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const loadFeedbacks = async () => {
    setLoading(true);
    try {
      if (feedbackId) {
        const result = await api.get(`/feedbacks/${encodeURIComponent(feedbackId)}`);
        setFeedbacks([result.data.data]);
        setError('');
        return;
      }
      const res = await api.get('/feedbacks', {
        params: {
          category: filterCategory,
          status: filterStatus,
          limit: 100,
        },
      });
      setFeedbacks(res.data.data || []);
      setError('');
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadFeedbacks();
  }, [filterCategory, filterStatus, feedbackId]);

  const openRespondModal = (item: FeedbackItem, action: 'ACCEPTED' | 'REJECTED') => {
    setSelectedFeedback(item);
    setResponseAction(action);
    setResponseNote(
      action === 'ACCEPTED'
        ? 'Cảm ơn sáng kiến của bạn. Đơn vị chuyên trách đã khảo sát và đưa đề xuất vào kế hoạch triển khai.'
        : 'Cảm ơn ý kiến của bạn. Sau khi rà soát, đề xuất chưa phù hợp với quy hoạch hiện hành.'
    );
  };

  const submitResponse = async () => {
    if (!selectedFeedback || responseNote.trim().length < 5) return;
    setSubmitting(true);
    try {
      await api.patch(`/feedbacks/${selectedFeedback.id}/respond`, {
        status: responseAction,
        response_note: responseNote.trim(),
      });
      setSelectedFeedback(null);
      await loadFeedbacks();
    } catch (e) {
      alert(errorMessage(e));
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <section>
      {feedbackId && <button className="text-button" onClick={() => setSearchParams({})}>Xem tất cả góp ý</button>}
      <PageHeader
        title="Hiến kế & Góp ý đô thị"
        parent="Tiện ích công dân"
        description="Lắng nghe sáng kiến, đề xuất nâng cấp hạ tầng và giải pháp xây dựng đô thị từ nhân dân."
        actions={
          <button className="refresh-button" onClick={loadFeedbacks}>
            <RefreshCw size={16} /> Làm mới
          </button>
        }
      />

      {/* Thanh bộ lọc */}
      <div className="filter-bar" style={{ display: 'flex', gap: '12px', margin: '16px 0', flexWrap: 'wrap' }}>
        <select
          value={filterCategory}
          onChange={(e) => setFilterCategory(e.target.value)}
          style={{ padding: '8px 12px', borderRadius: '8px', border: '1px solid #e5e7eb' }}
        >
          <option value="ALL">Tất cả lĩnh vực</option>
          <option value="TRAFFIC">Giao thông - Đi lại</option>
          <option value="GREENERY">Cây xanh - Công viên</option>
          <option value="LIGHTING">Chiếu sáng - Điện</option>
          <option value="DRAINAGE">Thoát nước - Ngập</option>
          <option value="ENVIRONMENT">Môi trường - Rác</option>
          <option value="GENERAL">Góp ý chung</option>
        </select>

        <select
          value={filterStatus}
          onChange={(e) => setFilterStatus(e.target.value)}
          style={{ padding: '8px 12px', borderRadius: '8px', border: '1px solid #e5e7eb' }}
        >
          <option value="ALL">Tất cả trạng thái</option>
          <option value="PENDING">Chờ xử lý</option>
          <option value="ACCEPTED">Đã tiếp thu / Duyệt</option>
          <option value="REJECTED">Chưa phù hợp</option>
        </select>
      </div>

      <PageState loading={loading} error={error} onRetry={loadFeedbacks} />

      {!loading && !error && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(360px, 1fr))', gap: '16px' }}>
          {feedbacks.length === 0 ? (
            <p style={{ gridColumn: '1 / -1', textAlign: 'center', color: '#6b7280', padding: '32px' }}>
              Chưa có góp ý nào trong danh mục này.
            </p>
          ) : (
            feedbacks.map((item) => {
              const cat = CATEGORY_MAP[item.category] || CATEGORY_MAP.GENERAL;
              return (
                <article
                  key={item.id}
                  className="panel"
                  style={{
                    display: 'flex',
                    flexDirection: 'column',
                    justifyContent: 'space-between',
                    borderRadius: '12px',
                    padding: '16px',
                    backgroundColor: '#fff',
                    boxShadow: '0 1px 3px rgba(0,0,0,0.05)',
                  }}
                >
                  <div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                      <span
                        style={{
                          backgroundColor: `${cat.color}15`,
                          color: cat.color,
                          fontWeight: 600,
                          fontSize: '12px',
                          padding: '4px 8px',
                          borderRadius: '6px',
                        }}
                      >
                        {cat.label}
                      </span>

                      <div style={{ display: 'flex', alignItems: 'center', gap: '4px', color: '#d97706', fontWeight: 600, fontSize: '13px' }}>
                        <ThumbsUp size={14} />
                        <span>{item.upvotes} đồng tình</span>
                      </div>
                    </div>

                    <h3 style={{ fontSize: '15px', fontWeight: 700, margin: '8px 0', color: '#111827' }}>
                      {item.title}
                    </h3>

                    <p style={{ fontSize: '13px', color: '#4b5563', lineHeight: '1.5', margin: '0 0 10px 0' }}>
                      {item.content}
                    </p>

                    {item.location_name && (
                      <p style={{ fontSize: '12px', color: '#6b7280', display: 'flex', alignItems: 'center', gap: '4px', margin: '0 0 10px 0' }}>
                        <MapPin size={13} /> {item.location_name}
                      </p>
                    )}

                    {item.admin_response && (
                      <div
                        style={{
                          backgroundColor: item.status === 'ACCEPTED' ? '#f0fdf4' : '#fef2f2',
                          borderLeft: `3px solid ${item.status === 'ACCEPTED' ? '#22c55e' : '#ef4444'}`,
                          padding: '8px 12px',
                          borderRadius: '4px',
                          marginBottom: '10px',
                        }}
                      >
                        <p style={{ margin: 0, fontSize: '12px', fontWeight: 600, color: item.status === 'ACCEPTED' ? '#15803d' : '#b91c1c' }}>
                          Phản hồi của cơ quan chức năng ({item.responder_name || 'Quản trị viên'}):
                        </p>
                        <p style={{ margin: '4px 0 0 0', fontSize: '12px', color: '#374151' }}>
                          {item.admin_response}
                        </p>
                      </div>
                    )}
                  </div>

                  <div style={{ borderTop: '1px solid #f3f4f6', paddingTop: '10px', marginTop: '10px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <span style={{ fontSize: '11px', color: '#9ca3af' }}>
                        {item.user_name} · {new Date(item.created_at).toLocaleDateString('vi-VN')}
                      </span>

                      <div>
                        {item.status === 'PENDING' ? (
                          <div style={{ display: 'flex', gap: '6px' }}>
                            <button
                              className="text-button"
                              style={{ color: '#16a34a', fontWeight: 600, fontSize: '12px' }}
                              onClick={() => openRespondModal(item, 'ACCEPTED')}
                            >
                              <CheckCircle size={14} style={{ verticalAlign: 'middle', marginRight: 2 }} /> Tiếp thu
                            </button>
                            <button
                              className="text-button danger-text"
                              style={{ color: '#dc2626', fontWeight: 600, fontSize: '12px' }}
                              onClick={() => openRespondModal(item, 'REJECTED')}
                            >
                              <XCircle size={14} style={{ verticalAlign: 'middle', marginRight: 2 }} /> Từ chối
                            </button>
                          </div>
                        ) : (
                          <span
                            style={{
                              fontSize: '11px',
                              fontWeight: 600,
                              color: item.status === 'ACCEPTED' ? '#15803d' : '#991b1b',
                            }}
                          >
                            {item.status === 'ACCEPTED' ? '✓ Đã tiếp thu' : '✗ Chưa phù hợp'}
                          </span>
                        )}
                      </div>
                    </div>
                  </div>
                </article>
              );
            })
          )}
        </div>
      )}

      {/* Modal phản hồi từ cơ quan chức năng */}
      {selectedFeedback && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            backgroundColor: 'rgba(0,0,0,0.5)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 1000,
          }}
        >
          <div
            style={{
              backgroundColor: '#fff',
              borderRadius: '12px',
              padding: '24px',
              maxWidth: '500px',
              width: '90%',
              boxShadow: '0 20px 25px -5px rgba(0,0,0,0.1)',
            }}
          >
            <h3 style={{ margin: '0 0 12px 0', fontSize: '16px' }}>
              Phản hồi sáng kiến: {selectedFeedback.title}
            </h3>

            <div style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, marginBottom: '6px' }}>
                Hành động:
              </label>
              <div style={{ display: 'flex', gap: '16px' }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px' }}>
                  <input
                    type="radio"
                    name="action"
                    checked={responseAction === 'ACCEPTED'}
                    onChange={() => setResponseAction('ACCEPTED')}
                  />
                  Tiếp thu & Ghi nhận
                </label>
                <label style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px' }}>
                  <input
                    type="radio"
                    name="action"
                    checked={responseAction === 'REJECTED'}
                    onChange={() => setResponseAction('REJECTED')}
                  />
                  Chưa phù hợp quy hoạch
                </label>
              </div>
            </div>

            <div style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, marginBottom: '6px' }}>
                Ý kiến phản hồi gửi cho công dân:
              </label>
              <textarea
                rows={4}
                value={responseNote}
                onChange={(e) => setResponseNote(e.target.value)}
                style={{ width: '100%', padding: '8px', borderRadius: '6px', border: '1px solid #d1d5db', fontSize: '13px' }}
                placeholder="Nhập nội dung phản hồi, kế hoạch triển khai..."
              />
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px' }}>
              <button
                className="button secondary"
                onClick={() => setSelectedFeedback(null)}
                disabled={submitting}
              >
                Hủy
              </button>
              <button
                className="button primary"
                onClick={submitResponse}
                disabled={submitting || responseNote.trim().length < 5}
              >
                <Send size={14} style={{ marginRight: 4 }} />
                {submitting ? 'Đang gửi...' : 'Gửi phản hồi'}
              </button>
            </div>
          </div>
        </div>
      )}
    </section>
  );
}
