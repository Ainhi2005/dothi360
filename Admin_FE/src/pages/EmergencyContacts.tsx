import { FormEvent, useEffect, useState } from 'react';
import { EyeOff, Eye, Pencil, Plus, PhoneCall, Phone, Search, ShieldCheck, Flame, Stethoscope, Car, AlertTriangle, Clock } from 'lucide-react';
import { api, errorMessage } from '../lib/api';
import { PageState } from '../components/PageState';
import type { EmergencyContact } from '../types';

const empty: Omit<EmergencyContact, 'id' | 'created_at' | 'updated_at'> = {
  name: '',
  phone_number: '',
  category: 'NATIONAL',
  description: '',
  icon: 'phone',
  accent: 'primary',
  is_hotline: false,
  sort_order: 10,
  is_active: true,
  operating_hours: '24/7',
};

const CATEGORIES: Record<string, { label: string; icon: any; color: string }> = {
  ALL: { label: 'Tất cả phân loại', icon: Phone, color: 'var(--primary)' },
  NATIONAL: { label: 'Khẩn cấp quốc gia', icon: Flame, color: '#dc2626' },
  INFRASTRUCTURE: { label: 'Hạ tầng đô thị', icon: AlertTriangle, color: '#d97706' },
  MEDICAL: { label: 'Y tế & Cấp cứu', icon: Stethoscope, color: '#e11d48' },
  SECURITY: { label: 'An ninh & Trật tự', icon: ShieldCheck, color: '#2563eb' },
  TRAFFIC: { label: 'Giao thông & Cứu hộ', icon: Car, color: '#059669' },
  RESCUE: { label: 'Tìm kiếm cứu nạn', icon: PhoneCall, color: '#7c3aed' },
};

export default function EmergencyContacts() {
  const [data, setData] = useState<EmergencyContact[]>([]);
  const [editing, setEditing] = useState<EmergencyContact | null | 'new'>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('ALL');

  const load = () => {
    setLoading(true);
    api.get('/emergency-contacts/admin')
      .then(r => { setData(r.data.data); setError(''); })
      .catch(e => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  };

  useEffect(load, []);

  const save = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const payload = {
      name: String(form.get('name')).trim(),
      phone_number: String(form.get('phone_number')).trim(),
      category: String(form.get('category')),
      description: String(form.get('description')).trim(),
      icon: String(form.get('icon')),
      accent: String(form.get('accent')),
      operating_hours: String(form.get('operating_hours')).trim() || '24/7',
      is_hotline: form.get('is_hotline') === 'on',
      sort_order: Number(form.get('sort_order')) || 0,
      is_active: form.get('is_active') === 'on',
    };

    try {
      if (editing === 'new') {
        await api.post('/emergency-contacts', payload);
      } else {
        await api.put(`/emergency-contacts/${editing?.id}`, payload);
      }
      setEditing(null);
      load();
    } catch (err) {
      setError(errorMessage(err));
    }
  };

  const toggleActive = async (item: EmergencyContact) => {
    const action = item.is_active ? 'Tạm ẩn' : 'Kích hoạt lại';
    if (!confirm(`${action} liên hệ khẩn cấp “${item.name}” (${item.phone_number})?`)) return;
    try {
      await api.delete(`/emergency-contacts/${item.id}`);
      load();
    } catch (err) {
      setError(errorMessage(err));
    }
  };

  const filtered = data.filter(item => {
    const matchCat = selectedCategory === 'ALL' || item.category === selectedCategory;
    const matchSearch = !search ||
      item.name.toLowerCase().includes(search.toLowerCase()) ||
      item.phone_number.includes(search) ||
      item.description.toLowerCase().includes(search.toLowerCase());
    return matchCat && matchSearch;
  });

  const totalHotlines = data.filter(c => c.is_hotline && c.is_active).length;
  const totalActive = data.filter(c => c.is_active).length;

  const current = editing === 'new' ? empty : editing;

  return (
    <section>
      <div className="page-heading">
        <div>
          <h2>Danh bạ khẩn cấp</h2>
          <p>Quản lý các số điện thoại hotline, cứu hộ và đầu mối khẩn cấp cho người dân.</p>
        </div>
        <button className="button primary" onClick={() => setEditing('new')}>
          <Plus /> Thêm số khẩn cấp
        </button>
      </div>

      {error && <div className="alert">{error}</div>}

      {/* Metrics Strip */}
      <div className="stats-strip compact" style={{ marginBottom: 16 }}>
        <div className="stat-item">
          <strong>{data.length}</strong>
          <span>Tổng số đầu mối</span>
        </div>
        <div className="stat-item">
          <strong style={{ color: '#dc2626' }}>{totalHotlines}</strong>
          <span>Hotline cấp thiết (Ghim đầu)</span>
        </div>
        <div className="stat-item">
          <strong style={{ color: 'var(--primary)' }}>{totalActive}</strong>
          <span>Đang hoạt động trên App</span>
        </div>
        <div className="stat-item">
          <strong>{data.filter(c => c.category === 'INFRASTRUCTURE').length}</strong>
          <span>Đầu mối hạ tầng đô thị</span>
        </div>
      </div>

      {/* Filters & Search */}
      <div className="filter-panel" style={{ display: 'flex', gap: 12, alignItems: 'center', marginBottom: 16 }}>
        <div className="search" style={{ flex: 1, maxWidth: 360 }}>
          <Search />
          <input
            placeholder="Tìm theo tên cơ quan, số điện thoại, nhiệm vụ..."
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>
        <select
          value={selectedCategory}
          onChange={e => setSelectedCategory(e.target.value)}
          style={{ padding: '9px 12px', borderRadius: 6, border: '1px solid var(--border)' }}
        >
          {Object.entries(CATEGORIES).map(([key, cat]) => (
            <option key={key} value={key}>{cat.label}</option>
          ))}
        </select>
        {search && (
          <button className="clear-filter" onClick={() => setSearch('')}>
            Xóa tìm kiếm
          </button>
        )}
      </div>

      <article className="panel">
        <PageState loading={loading} error="" empty={!loading && !filtered.length} onRetry={load} />
        {!loading && (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th style={{ width: 60 }}>Thứ tự</th>
                  <th>Số khẩn cấp / Hotline</th>
                  <th>Cơ quan tiếp nhận & Chức năng</th>
                  <th>Phân loại</th>
                  <th>Giờ phục vụ</th>
                  <th>Trạng thái</th>
                  <th style={{ textAlign: 'right' }}>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(item => (
                  <tr key={item.id}>
                    <td>
                      <span style={{ fontWeight: 600, color: 'var(--muted)' }}>#{item.sort_order}</span>
                    </td>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                        <a
                          href={`tel:${item.phone_number}`}
                          style={{
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: 6,
                            padding: '4px 10px',
                            background: item.is_hotline ? '#fee2e2' : 'var(--primary-soft)',
                            color: item.is_hotline ? '#dc2626' : 'var(--primary-dark)',
                            borderRadius: 6,
                            fontWeight: 700,
                            fontSize: 14,
                            textDecoration: 'none',
                          }}
                          title="Bấm để gọi thử"
                        >
                          <PhoneCall size={14} />
                          {item.phone_number}
                        </a>
                        {item.is_hotline && (
                          <span
                            style={{
                              fontSize: 10,
                              fontWeight: 700,
                              padding: '2px 6px',
                              borderRadius: 4,
                              background: '#ef4444',
                              color: '#fff',
                            }}
                          >
                            HOTLINE
                          </span>
                        )}
                      </div>
                    </td>
                    <td>
                      <strong>{item.name}</strong>
                      <small style={{ color: 'var(--muted)', display: 'block', maxWidth: 420 }}>
                        {item.description}
                      </small>
                    </td>
                    <td>
                      <span
                        className="badge"
                        style={{
                          background: '#f1f5f9',
                          color: CATEGORIES[item.category]?.color || 'var(--text)',
                          border: `1px solid ${CATEGORIES[item.category]?.color || 'var(--border)'}44`,
                          padding: '3px 8px',
                          borderRadius: 6,
                          fontWeight: 600,
                        }}
                      >
                        {CATEGORIES[item.category]?.label || item.category}
                      </span>
                    </td>
                    <td>
                      <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, fontSize: 12 }}>
                        <Clock size={13} color="var(--muted)" />
                        {item.operating_hours || '24/7'}
                      </span>
                    </td>
                    <td>
                      <span className={`dot-label ${item.is_active ? 'active' : 'inactive'}`}>
                        {item.is_active ? 'Hiển thị' : 'Tạm ẩn'}
                      </span>
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <div className="row-actions" style={{ justifyContent: 'flex-end' }}>
                        <button className="text-button" onClick={() => setEditing(item)}>
                          <Pencil size={15} /> Sửa
                        </button>
                        <button
                          className={`text-button ${item.is_active ? 'danger-text' : ''}`}
                          onClick={() => toggleActive(item)}
                        >
                          {item.is_active ? <EyeOff size={15} /> : <Eye size={15} />}
                          {item.is_active ? 'Ẩn' : 'Hiện'}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </article>

      {/* Modal Add / Edit */}
      {current && (
        <div className="modal-backdrop">
          <form className="modal emergency-guide-modal" onSubmit={save} style={{ maxWidth: 650 }}>
            <div className="modal-title" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <h2>{editing === 'new' ? 'Thêm số liên hệ khẩn cấp' : 'Chỉnh sửa số khẩn cấp'}</h2>
                <p>Số điện thoại sẽ xuất hiện trong "Danh bạ khẩn cấp" trên ứng dụng người dân.</p>
              </div>
              <PhoneCall size={26} color="var(--primary)" />
            </div>

            <div className="form-grid">
              <label>
                Số điện thoại (Hotline)*
                <input
                  name="phone_number"
                  required
                  defaultValue={current.phone_number}
                  placeholder="Ví dụ: 114, 115, 1022, 19006769"
                />
              </label>

              <label>
                Thứ tự sắp xếp*
                <input
                  name="sort_order"
                  type="number"
                  min="0"
                  required
                  defaultValue={current.sort_order}
                  placeholder="10, 20, 30..."
                />
              </label>

              <label className="full">
                Tên cơ quan / Lực lượng tiếp nhận*
                <input
                  name="name"
                  required
                  defaultValue={current.name}
                  placeholder="Ví dụ: Cứu hỏa & Cứu nạn cứu hộ 114"
                />
              </label>

              <label>
                Phân loại khẩn cấp*
                <select name="category" defaultValue={current.category}>
                  <option value="NATIONAL">Khẩn cấp quốc gia (113, 114, 115...)</option>
                  <option value="INFRASTRUCTURE">Hạ tầng đô thị (1022, Điện, Nước...)</option>
                  <option value="TRAFFIC">Giao thông & Cứu hộ đường bộ</option>
                  <option value="MEDICAL">Y tế & Cấp cứu</option>
                  <option value="SECURITY">An ninh & Trật tự</option>
                  <option value="RESCUE">Tìm kiếm & Cứu nạn cứu hộ</option>
                </select>
              </label>

              <label>
                Giờ hoạt động / Trực ban
                <input
                  name="operating_hours"
                  defaultValue={current.operating_hours || '24/7'}
                  placeholder="24/7 hoặc 07:30 - 17:00"
                />
              </label>

              <label className="full">
                Mô tả nhiệm vụ & Tình huống gọi*
                <textarea
                  name="description"
                  required
                  rows={3}
                  defaultValue={current.description}
                  placeholder="Mô tả khi nào người dân cần gọi số này và chức năng xử lý..."
                />
              </label>

              <label>
                Biểu tượng
                <select name="icon" defaultValue={current.icon}>
                  <option value="phone">Điện thoại chung</option>
                  <option value="local_fire_department">Cứu hỏa (114)</option>
                  <option value="medical_services">Cấp cứu y tế (115)</option>
                  <option value="local_police">Cảnh sát (113)</option>
                  <option value="support_agent">Tổng đài tiếp nhận (1022)</option>
                  <option value="electric_bolt">Điện lực EVN</option>
                  <option value="flood">Thoát nước & Ngập</option>
                  <option value="car_crash">Cứu hộ giao thông</option>
                  <option value="park">Cây xanh</option>
                  <option value="health_and_safety">Y tế CDC</option>
                  <option value="sos">SOS Khẩn cấp</option>
                </select>
              </label>

              <label>
                Màu sắc nhấn
                <select name="accent" defaultValue={current.accent}>
                  <option value="danger">Đỏ – Khẩn cấp, nguy hiểm</option>
                  <option value="primary">Xanh lá – Chính thống, hạ tầng</option>
                  <option value="warning">Cam – Cảnh báo, điện lưới</option>
                  <option value="info">Xanh dương – Thông tin, hỗ trợ</option>
                  <option value="success">Lục nhạt – Cây xanh, môi trường</option>
                </select>
              </label>

              <label className="check-row full">
                <input name="is_hotline" type="checkbox" defaultChecked={current.is_hotline} />
                <strong>Ghim làm Hotline cấp thiết hàng đầu</strong> (Hiển thị thẻ quay số to nổi bật trên đầu app)
              </label>

              <label className="check-row full">
                <input name="is_active" type="checkbox" defaultChecked={current.is_active} />
                Hiển thị trên ứng dụng người dân
              </label>
            </div>

            <div className="modal-actions" style={{ marginTop: 20 }}>
              <button type="button" className="button secondary" onClick={() => setEditing(null)}>
                Hủy
              </button>
              <button className="button primary">
                Lưu liên hệ
              </button>
            </div>
          </form>
        </div>
      )}
    </section>
  );
}
