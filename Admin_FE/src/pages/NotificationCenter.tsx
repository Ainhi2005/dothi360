import { useCallback, useEffect, useState } from 'react';
import { Bell, CheckCheck, RefreshCw } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

import { PageHeader } from '../components/PageHeader';
import { PageState } from '../components/PageState';
import { api, errorMessage } from '../lib/api';
import { notificationPath, notificationAction, notificationCategory } from '../lib/notifications';

type NotificationItem = {
  id: string;
  type: string;
  title: string;
  message: string;
  is_read: boolean;
  push_status: string;
  push_attempts: number;
  push_last_error?: string;
  created_at: string;
  incident_id?: string;
  data?: { action_path?: string; action_label?: string };
};

type NotificationMeta = { total: number; failed: number; unread: number };

export default function NotificationCenter() {
  const navigate = useNavigate();
  const [items, setItems] = useState<NotificationItem[]>([]);
  const [meta, setMeta] = useState<NotificationMeta>({ total: 0, failed: 0, unread: 0 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const load = useCallback(async (quiet = false) => {
    if (!quiet) setLoading(true);
    try {
      const response = await api.get('/admin/notifications');
      setItems(response.data.data.data);
      setMeta(response.data.data.meta);
      setError('');
    } catch (requestError) {
      setError(errorMessage(requestError));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
    const timer = window.setInterval(() => void load(true), 15000);
    const onFocus = () => void load(true);
    window.addEventListener('focus', onFocus);
    return () => { window.clearInterval(timer); window.removeEventListener('focus', onFocus); };
  }, [load]);

  const notifyBadgeChanged = () =>
    window.dispatchEvent(new Event('admin-notifications-updated'));

  const openIncident = async (item: NotificationItem) => {
    if (!item.is_read) {
      await api.patch(`/notifications/${item.id}/read`);
      notifyBadgeChanged();
    }
    const path = notificationPath(item);
    if (path) navigate(path);
    else await load(true);
  };

  const markAllRead = async () => {
    await api.patch('/notifications/read-all');
    notifyBadgeChanged();
    await load();
  };

  return (
    <section>
      <PageHeader
        title="Trung tâm thông báo"
        parent="Điều hành"
        description="Theo dõi yêu cầu nghiệm thu, kiểm duyệt, phân công, khó khăn và góp ý cần phản hồi."
        actions={
          <div className="notification-actions">
            {meta.unread > 0 && (
              <button className="refresh-button" onClick={() => void markAllRead()}>
                <CheckCheck /> Đánh dấu đã đọc
              </button>
            )}
            <button className="refresh-button" onClick={() => void load()}>
              <RefreshCw /> Làm mới
            </button>
          </div>
        }
      />

      <div className="assignment-summary">
        <div><strong>{meta.total}</strong><span>Tổng nhắc việc</span></div>
        <div><strong>{meta.unread}</strong><span>Chưa đọc</span></div>
        <div><strong>{meta.failed}</strong><span>Push cần kiểm tra</span></div>
      </div>

      <article className="panel">
        <PageState loading={loading} error={error} empty={!loading && !items.length} onRetry={load} />
        {!loading && items.length > 0 && (
          <div className="table-wrap">
            <table>
              <thead>
                <tr><th>Trạng thái</th><th>Nội dung nhắc việc</th><th>Push</th><th>Thời gian</th><th /></tr>
              </thead>
              <tbody>
                {items.map(item => (
                  <tr key={item.id} className={item.is_read ? '' : 'notification-unread-row'}>
                    <td>
                      <span className={`dot-label ${item.is_read ? 'inactive' : 'active'}`}>
                        {item.is_read ? 'Đã đọc' : 'Mới'}
                      </span>
                    </td>
                    <td>
                      <strong className="notification-title"><Bell size={15} /> {item.title}</strong>
                      <small>{notificationCategory(item.type)} · {item.message}</small>
                    </td>
                    <td>
                      <span className={`dot-label ${item.push_status === 'FAILED' ? 'inactive' : 'active'}`}>
                        {item.push_status}
                      </span>
                      {item.push_last_error && <small>{item.push_last_error}</small>}
                    </td>
                    <td>{new Date(item.created_at).toLocaleString('vi-VN')}</td>
                    <td>
                      {notificationPath(item) && (
                        <button className="text-button" onClick={() => void openIncident(item)}>
                          {notificationAction(item)}
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </article>
    </section>
  );
}
