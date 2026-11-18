import { useCallback, useEffect, useState } from 'react';
import { ArrowDown, ArrowUp, ArrowUpDown, FileSpreadsheet, Grid2X2, List, RefreshCw, Search, X } from 'lucide-react';
import { Link, useSearchParams } from 'react-router-dom';
import { EmptyState } from '../components/EmptyState';
import { IncidentCard } from '../components/IncidentCard';
import { PageHeader } from '../components/PageHeader';
import { PageState } from '../components/PageState';
import { StatusBadge } from '../components/StatusBadge';
import { api, errorMessage } from '../lib/api';
import type { Incident } from '../types';

export default function Incidents() {
  const [params, setParams] = useSearchParams();
  const [data, setData] = useState<Incident[]>([]), [loading, setLoading] = useState(true), [error, setError] = useState(''), [view, setView] = useState<'table'|'grid'>('table'),[total,setTotal]=useState(0);
  const [exporting, setExporting] = useState(false);
  const query = params.get('q') ?? '', status = params.get('status') ?? '', priority = params.get('priority') ?? '';
  const sortBy = params.get('sort_by') ?? 'created_at';
  const sortOrder = params.get('sort_order') ?? 'DESC';

  const setFilter = (key: string, value: string) => { 
    const next = new URLSearchParams(params); 
    if (value) next.set(key, value); 
    else next.delete(key); 
    setParams(next); 
  };

  const toggleSort = (col: string) => {
    const next = new URLSearchParams(params);
    if (sortBy === col) {
      next.set('sort_order', sortOrder === 'ASC' ? 'DESC' : 'ASC');
    } else {
      next.set('sort_by', col);
      next.set('sort_order', 'DESC');
    }
    setParams(next);
  };

  const renderSortIcon = (col: string) => {
    if (sortBy !== col) return <ArrowUpDown size={12} style={{ opacity: 0.35, marginLeft: 4, verticalAlign: 'middle' }} />;
    return sortOrder === 'ASC'
      ? <ArrowUp size={12} style={{ color: 'var(--primary, #00875A)', marginLeft: 4, verticalAlign: 'middle' }} />
      : <ArrowDown size={12} style={{ color: 'var(--primary, #00875A)', marginLeft: 4, verticalAlign: 'middle' }} />;
  };

  const load = useCallback(() => { 
    setLoading(true); 
    api.get('/incidents', { 
      params: { 
        limit: 20, 
        q: query || undefined, 
        status: status || undefined, 
        priority: priority || undefined,
        sort_by: sortBy,
        sort_order: sortOrder,
      } 
    }).then(r => { 
      setData(r.data.data); 
      setTotal(r.data.total); 
      setError(''); 
    }).catch(e => setError(errorMessage(e))).finally(() => setLoading(false)); 
  }, [query, status, priority, sortBy, sortOrder]);

  useEffect(() => { 
    const timer = setTimeout(() => void load(), query ? 300 : 0); 
    return () => clearTimeout(timer); 
  }, [load, query]);

  const exportExcel = async () => {
    try {
      setExporting(true);
      const res = await api.get('/admin/reports/incidents.xlsx', { responseType: 'blob' });
      const blob = new Blob([res.data], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `Bao-cao-su-co-${new Date().toISOString().slice(0, 10)}.xlsx`);
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);
    } catch (e) {
      alert(errorMessage(e));
    } finally {
      setExporting(false);
    }
  };

  const items = data;
  const hasFilters = Boolean(query || status || priority || sortBy !== 'created_at' || sortOrder !== 'DESC');

  return <section>
    <PageHeader
      title="Sự cố"
      parent="Điều hành"
      description="Theo dõi, lọc và mở hồ sơ toàn bộ sự cố đô thị."
      actions={
        <div style={{ display: 'flex', gap: 8 }}>
          <button
            className="button secondary"
            onClick={exportExcel}
            disabled={exporting}
            style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}
            title="Tải tệp bảng tính Excel (.xlsx) chuẩn biểu mẫu báo cáo hành chính"
          >
            <FileSpreadsheet size={15}/> {exporting ? 'Đang xuất...' : 'Xuất Excel'}
          </button>
          <button className="refresh-button" onClick={load}>
            <RefreshCw size={15}/> Làm mới
          </button>
        </div>
      }
    />
    <div className="filter-panel">
      <div className="search">
        <Search/><input placeholder="Tìm nội dung hoặc loại sự cố" value={query} onChange={e => setFilter('q', e.target.value)}/>
      </div>
      <select value={status} onChange={e => setFilter('status', e.target.value)}>
        <option value="">Tất cả trạng thái</option>
        <option value="PENDING_ASSIGNMENT">Chờ phân công</option>
        <option value="ASSIGNED">Đã phân công</option>
        <option value="ACCEPTED">Đã tiếp nhận</option>
        <option value="IN_PROGRESS">Đang xử lý</option>
        <option value="PENDING_VERIFICATION">Chờ nghiệm thu</option>
        <option value="RESOLVED">Hoàn thành</option>
      </select>
      <select value={priority} onChange={e => setFilter('priority', e.target.value)}>
        <option value="">Mọi mức ưu tiên</option>
        <option value="HIGH">Cao</option>
        <option value="MEDIUM">Trung bình</option>
        <option value="LOW">Thấp</option>
      </select>
      <select 
        value={`${sortBy}_${sortOrder}`} 
        onChange={e => {
          const val = e.target.value;
          const next = new URLSearchParams(params);
          if (val === 'created_at_DESC') { next.set('sort_by', 'created_at'); next.set('sort_order', 'DESC'); }
          else if (val === 'created_at_ASC') { next.set('sort_by', 'created_at'); next.set('sort_order', 'ASC'); }
          else if (val === 'priority_DESC') { next.set('sort_by', 'priority'); next.set('sort_order', 'DESC'); }
          else if (val === 'priority_ASC') { next.set('sort_by', 'priority'); next.set('sort_order', 'ASC'); }
          else if (val === 'report_count_DESC') { next.set('sort_by', 'report_count'); next.set('sort_order', 'DESC'); }
          else if (val === 'status_ASC') { next.set('sort_by', 'status'); next.set('sort_order', 'ASC'); }
          setParams(next);
        }}
        title="Sắp xếp danh sách sự cố"
      >
        <option value="created_at_DESC">Mới nhất (Ngày tạo &darr;)</option>
        <option value="created_at_ASC">Cũ nhất (Ngày tạo &uarr;)</option>
        <option value="priority_DESC">Ưu tiên: Cao &rarr; Thấp</option>
        <option value="priority_ASC">Ưu tiên: Thấp &rarr; Cao</option>
        <option value="report_count_DESC">Nhiều lượt báo nhất</option>
        <option value="status_ASC">Theo trạng thái</option>
      </select>
      {hasFilters && <button className="clear-filter" onClick={() => setParams({})}><X/> Xóa lọc</button>}
      <div className="view-switch">
        <button className={view==='table'?'active':''} onClick={() => setView('table')} title="Dạng bảng"><List/></button>
        <button className={view==='grid'?'active':''} onClick={() => setView('grid')} title="Dạng thẻ"><Grid2X2/></button>
      </div>
    </div>
    <div className="result-meta"><strong>{total}</strong> sự cố phù hợp · hiển thị tối đa 20 mỗi trang</div>
    <PageState loading={loading} error={error} onRetry={load}/>
    {!loading && !error && !items.length && <EmptyState title="Không tìm thấy sự cố" description="Thử thay đổi bộ lọc hoặc xóa điều kiện tìm kiếm." action={hasFilters && <button className="button secondary" onClick={() => setParams({})}>Xóa bộ lọc</button>}/>} 
    {!loading && !error && items.length > 0 && (view === 'grid' ? <div className="incident-grid">{items.map(i => <IncidentCard incident={i} key={i.id}/>)}</div> : <article className="panel"><div className="table-wrap"><table><thead><tr>
      <th>Sự cố</th>
      <th onClick={() => toggleSort('priority')} style={{ cursor: 'pointer', userSelect: 'none' }} title="Bấm để đổi sắp xếp mức ưu tiên">
        Ưu tiên{renderSortIcon('priority')}
      </th>
      <th onClick={() => toggleSort('report_count')} style={{ cursor: 'pointer', userSelect: 'none' }} title="Bấm để đổi sắp xếp lượt báo">
        Lượt báo{renderSortIcon('report_count')}
      </th>
      <th onClick={() => toggleSort('created_at')} style={{ cursor: 'pointer', userSelect: 'none' }} title="Bấm để đổi sắp xếp ngày tạo">
        Ngày tạo{renderSortIcon('created_at')}
      </th>
      <th onClick={() => toggleSort('status')} style={{ cursor: 'pointer', userSelect: 'none' }} title="Bấm để đổi sắp xếp trạng thái">
        Trạng thái{renderSortIcon('status')}
      </th>
      <th/>
    </tr></thead><tbody>{items.map(i => <tr key={i.id}><td><strong>{i.incident_type?.name ?? 'Sự cố đô thị'}</strong><small>{i.description}</small></td><td><span className={`priority priority-${(i.priority_level ?? '').toLowerCase()}`}><i/>{i.priority_level ?? '—'}</span><small>{i.priority_score == null ? 'Chưa có điểm' : `${Math.round(i.priority_score)} điểm`}</small></td><td>{i.report_count}</td><td>{new Date(i.created_at).toLocaleDateString('vi-VN')}</td><td><StatusBadge status={i.status}/></td><td><Link className="text-button" to={`/incidents/${i.id}`}>Xem hồ sơ</Link></td></tr>)}</tbody></table></div></article>)}
  </section>;
}

