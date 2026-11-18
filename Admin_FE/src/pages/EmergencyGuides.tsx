import { FormEvent, useEffect, useState } from 'react';
import { EyeOff, Pencil, Plus, ShieldAlert } from 'lucide-react';
import { api, errorMessage } from '../lib/api';
import { PageState } from '../components/PageState';
import type { EmergencyGuide } from '../types';

const empty: Omit<EmergencyGuide, 'id'> = {
  code: '', title: '', summary: '', icon: 'warning', accent: 'danger',
  do_now: [], avoid: [], phone_numbers: [], sort_order: 0, is_active: true,
};
const lines = (value: FormDataEntryValue | null) => String(value ?? '').split('\n').map(x => x.trim()).filter(Boolean);

export default function EmergencyGuides() {
  const [data, setData] = useState<EmergencyGuide[]>([]);
  const [editing, setEditing] = useState<EmergencyGuide | null | 'new'>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const load = () => {
    setLoading(true);
    api.get('/emergency-guides/admin').then(r => { setData(r.data.data); setError(''); }).catch(e => setError(errorMessage(e))).finally(() => setLoading(false));
  };
  useEffect(load, []);

  const save = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    const labels = lines(form.get('phone_labels'));
    const numbers = lines(form.get('phone_numbers'));
    const payload = {
      code: String(form.get('code')).trim().toUpperCase(), title: String(form.get('title')).trim(), summary: String(form.get('summary')).trim(),
      icon: String(form.get('icon')), accent: String(form.get('accent')), do_now: lines(form.get('do_now')), avoid: lines(form.get('avoid')),
      phone_numbers: numbers.map((number, index) => ({ label: labels[index] || 'Liên hệ khẩn cấp', number })),
      sort_order: Number(form.get('sort_order')), is_active: form.get('is_active') === 'on',
    };
    try {
      if (editing === 'new') await api.post('/emergency-guides', payload);
      else await api.put(`/emergency-guides/${editing?.id}`, payload);
      setEditing(null); load();
    } catch (err) { setError(errorMessage(err)); }
  };
  const deactivate = async (item: EmergencyGuide) => {
    if (!confirm(`Tạm ẩn hướng dẫn “${item.title}”?`)) return;
    try { await api.delete(`/emergency-guides/${item.id}`); load(); } catch (err) { setError(errorMessage(err)); }
  };
  const current = editing === 'new' ? empty : editing;

  return <section>
    <div className="page-heading"><div><h2>Hướng dẫn khẩn cấp</h2><p>Cấu hình nội dung an toàn hiển thị trên ứng dụng người dân.</p></div><button className="button primary" onClick={() => setEditing('new')}><Plus/> Thêm tình huống</button></div>
    {error && <div className="alert">{error}</div>}
    <article className="panel">
      <PageState loading={loading} error="" empty={!loading && !data.length} onRetry={load}/>
      {!loading && <div className="table-wrap"><table><thead><tr><th>Thứ tự</th><th>Tình huống</th><th>Nội dung</th><th>Liên hệ</th><th>Trạng thái</th><th>Thao tác</th></tr></thead><tbody>{data.map(item => <tr key={item.id}>
        <td>{item.sort_order}</td><td><strong>{item.title}</strong><small>{item.code}</small></td><td><span>{item.do_now.length} việc cần làm · {item.avoid.length} điều cần tránh</span><small>{item.summary}</small></td><td>{item.phone_numbers.map(phone => phone.number).join(', ')}</td><td><span className={`dot-label ${item.is_active ? 'active' : 'inactive'}`}>{item.is_active ? 'Đang hiển thị' : 'Đã ẩn'}</span></td>
        <td><div className="row-actions"><button className="text-button" onClick={() => setEditing(item)}><Pencil/> Sửa</button>{item.is_active && <button className="text-button danger-text" onClick={() => deactivate(item)}><EyeOff/> Ẩn</button>}</div></td>
      </tr>)}</tbody></table></div>}
    </article>
    {current && <div className="modal-backdrop"><form className="modal emergency-guide-modal" onSubmit={save}>
      <div className="modal-title"><div><h2>{editing === 'new' ? 'Thêm tình huống' : 'Chỉnh sửa hướng dẫn'}</h2><p>Mỗi dòng nhập theo định dạng "Tiêu đề: Mô tả chi tiết" để hiển thị rõ ràng trên ứng dụng di động.</p></div><ShieldAlert/></div>
      <div className="form-grid">
        <label>Mã tình huống<input name="code" required defaultValue={current.code} placeholder="FIRE"/></label>
        <label>Thứ tự<input name="sort_order" type="number" min="0" required defaultValue={current.sort_order}/></label>
        <label className="full">Tên tình huống<input name="title" required defaultValue={current.title}/></label>
        <label className="full">Mô tả ngắn<textarea name="summary" required defaultValue={current.summary}/></label>
        <label>Biểu tượng<select name="icon" defaultValue={current.icon}><option value="local_fire_department">Cháy</option><option value="medical_services">Y tế</option><option value="flood">Ngập nước</option><option value="electric_bolt">Điện</option><option value="park">Cây xanh</option><option value="science">Hóa chất</option><option value="car_crash">Giao thông</option><option value="elevator">Thang máy</option><option value="warning">Cảnh báo</option></select></label>
        <label>Màu nhấn<select name="accent" defaultValue={current.accent}><option value="danger">Đỏ – nguy hiểm</option><option value="warning">Cam – cảnh báo</option><option value="info">Xanh – thông tin</option><option value="success">Lục – an toàn</option></select></label>
        <label className="full">Việc cần làm ngay<textarea name="do_now" required rows={5} placeholder="Tiêu đề bước: Mô tả hướng dẫn chi tiết..." defaultValue={current.do_now.join('\n')}/></label>
        <label className="full">Điều không nên làm<textarea name="avoid" required rows={5} placeholder="Tiêu đề cảnh báo: Giải thích lý do vì sao không nên làm..." defaultValue={current.avoid.join('\n')}/></label>
        <label>Tên cơ quan (mỗi dòng)<textarea name="phone_labels" required rows={4} defaultValue={current.phone_numbers.map(x => x.label).join('\n')}/></label>
        <label>Số điện thoại (mỗi dòng)<textarea name="phone_numbers" required rows={4} defaultValue={current.phone_numbers.map(x => x.number).join('\n')}/></label>
        <label className="check-row full"><input name="is_active" type="checkbox" defaultChecked={current.is_active}/> Hiển thị trên ứng dụng</label>
      </div>
      <div className="modal-actions"><button type="button" className="button secondary" onClick={() => setEditing(null)}>Hủy</button><button className="button primary">Lưu hướng dẫn</button></div>
    </form></div>}
  </section>;
}
