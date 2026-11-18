import { useEffect, useMemo, useState } from 'react';
import { RefreshCw, Search } from 'lucide-react';
import { PageHeader } from '../components/PageHeader';
import { PageState } from '../components/PageState';
import { api, errorMessage } from '../lib/api';

type OfficerPerformanceRow = {
  id: string;
  full_name: string;
  email: string;
  is_active: boolean;
  department_name?: string;
  total_accepted: number;
  active_tasks: number;
  completed_tasks: number;
  avg_accept_minutes: number;
};

export default function OfficerPerformance() {
  const [data, setData] = useState<OfficerPerformanceRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [query, setQuery] = useState('');

  const load = () => {
    setLoading(true);
    api.get('/assignments/officer-performance')
      .then(response => { setData(response.data.data); setError(''); })
      .catch(value => setError(errorMessage(value)))
      .finally(() => setLoading(false));
  };

  useEffect(() => { void load(); }, []);
  const filtered = useMemo(() => {
    const value = query.trim().toLowerCase();
    return data.filter(item => !value || item.full_name.toLowerCase().includes(value)
      || item.email.toLowerCase().includes(value)
      || item.department_name?.toLowerCase().includes(value));
  }, [data, query]);
  const totals = useMemo(() => ({
    active: data.reduce((sum, item) => sum + Number(item.active_tasks), 0),
    completed: data.reduce((sum, item) => sum + Number(item.completed_tasks), 0),
    available: data.filter(item => item.is_active && Number(item.active_tasks) === 0).length,
  }), [data]);

  return <section>
    <PageHeader title="Hiệu suất cán bộ" parent="Tổ chức" description="Theo dõi tải công việc và tốc độ tiếp nhận theo từng cán bộ." actions={<button className="refresh-button" onClick={load}><RefreshCw/> Làm mới</button>}/>
    <div className="assignment-summary">
      <div><strong>{data.length}</strong><span>Tổng cán bộ</span></div>
      <div><strong>{totals.active}</strong><span>Việc đang xử lý</span></div>
      <div><strong>{totals.completed}</strong><span>Việc đã hoàn thành</span></div>
      <div><strong>{totals.available}</strong><span>Đang sẵn sàng</span></div>
    </div>
    <article className="panel">
      <div className="list-toolbar"><div className="search-control"><Search/><input value={query} onChange={event => setQuery(event.target.value)} placeholder="Tìm cán bộ hoặc đơn vị"/></div></div>
      <PageState loading={loading} error={error} empty={!loading && !error && !filtered.length} onRetry={load}/>
      {!loading && !error && filtered.length > 0 && <div className="table-wrap"><table><thead><tr><th>Cán bộ</th><th>Đơn vị</th><th>Đang xử lý</th><th>Hoàn thành</th><th>Tiếp nhận TB</th><th>Trạng thái</th></tr></thead><tbody>{filtered.map(item => <tr key={item.id}>
        <td><strong>{item.full_name}</strong><small>{item.email}</small></td>
        <td>{item.department_name ?? 'Chưa gán đơn vị'}</td>
        <td><strong>{item.active_tasks}</strong></td>
        <td>{item.completed_tasks}</td>
        <td>{Number(item.avg_accept_minutes) < 1 ? 'Dưới 1 phút' : `${item.avg_accept_minutes} phút`}</td>
        <td><span className={`status-text ${item.is_active ? 'status-resolved' : 'status-cancelled'}`}><i/>{item.is_active ? 'đang hoạt động' : 'đã khóa'}</span></td>
      </tr>)}</tbody></table></div>}
    </article>
  </section>;
}
