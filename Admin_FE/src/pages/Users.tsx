import { type FormEvent, useCallback, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Plus, Search } from 'lucide-react';
import { api, errorMessage, getCurrentUser, logout } from '../lib/api';
import type { Department, User } from '../types';
import { PageState } from '../components/PageState';
import { Toast } from '../components/Toast';
import { UserPasswordDialog } from '../components/UserPasswordDialog';

export default function Users() {
  const [data, setData] = useState<User[]>([]), [deps, setDeps] = useState<Department[]>([]);
  const [q, setQ] = useState(''), [page, setPage] = useState(1), [totalPages, setTotalPages] = useState(1);
  const [loading, setLoading] = useState(true), [error, setError] = useState('');
  const [open, setOpen] = useState(false), [passwordUser, setPasswordUser] = useState<User | null>(null);
  const [message, setMessage] = useState('');
  const navigate = useNavigate();
  const load = useCallback(() => {
    setLoading(true);
    return Promise.all([api.get('/users', { params: { page, limit: 20, search: q } }), api.get('/departments')])
      .then(([u, d]) => { setData(u.data.data); setTotalPages(Math.max(1, u.data.totalPages)); setDeps(d.data.data); setError(''); })
      .catch(e => setError(errorMessage(e))).finally(() => setLoading(false));
  }, [page, q]);
  useEffect(() => { const timeout = setTimeout(() => { void load(); }, 250); return () => clearTimeout(timeout); }, [load]);
  async function create(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget), role = String(form.get('role'));
    try {
      await api.post('/users', { full_name: form.get('full_name'), email: form.get('email'), phone: form.get('phone'), password: form.get('password'), role, department_id: role === 'OFFICER' ? form.get('department_id') : undefined });
      setOpen(false); void load();
    } catch (cause) { setError(errorMessage(cause)); }
  }
  async function toggle(user: User) {
    try { await api.put(`/users/${user.id}`, { is_active: !user.is_active }); void load(); }
    catch (cause) { setError(errorMessage(cause)); }
  }
  async function passwordSaved(self: boolean) {
    setPasswordUser(null);
    if (self) { await logout().catch(() => {}); navigate('/login', { replace: true }); return; }
    setMessage('Đã đổi mật khẩu. Các phiên đăng nhập cũ của tài khoản đã bị thu hồi.');
  }
  return <section>
    <div className="page-heading"><div><span className="eyebrow">PHÂN QUYỀN</span><h2>Người dùng hệ thống</h2><p>Quản lý tài khoản, mật khẩu và trạng thái của Người dân, Cán bộ, Admin.</p></div><button className="button primary" onClick={() => setOpen(true)}><Plus/> Thêm tài khoản</button></div>
    <div className="toolbar"><div className="search"><Search/><input value={q} onChange={e => { setQ(e.target.value); setPage(1); }} placeholder="Tìm tên hoặc email…" aria-label="Tìm tài khoản"/></div></div>
    <article className="panel"><PageState loading={loading} error={error} empty={!loading && !data.length} onRetry={load}/>
      {!loading && <div className="table-wrap"><table><thead><tr><th>Người dùng</th><th>Vai trò</th><th>Đơn vị</th><th>Ngày tạo</th><th>Trạng thái</th><th>Thao tác</th></tr></thead><tbody>{data.map(user => <tr key={user.id}>
        <td><strong>{user.full_name}</strong><small>{user.email}</small></td><td><span className="role">{user.role}</span></td><td>{deps.find(d => d.id === user.department_id)?.name ?? '—'}</td><td>{new Date(user.created_at).toLocaleDateString('vi-VN')}</td><td><span className={`dot-label ${user.is_active ? 'active' : 'inactive'}`}>{user.is_active ? 'Hoạt động' : 'Đã khóa'}</span></td>
        <td><div className="user-actions"><button className="text-button" onClick={() => setPasswordUser(user)}>Đổi mật khẩu</button><button className="text-button" onClick={() => void toggle(user)}>{user.is_active ? 'Khóa' : 'Mở khóa'}</button></div></td>
      </tr>)}</tbody></table></div>}
      <div className="modal-actions"><button className="button secondary" disabled={loading || page <= 1} onClick={() => setPage(page - 1)}>Trang trước</button><span>Trang {page}/{totalPages}</span><button className="button secondary" disabled={loading || page >= totalPages} onClick={() => setPage(page + 1)}>Trang sau</button></div>
    </article>
    {open && <div className="modal-backdrop"><form className="modal" onSubmit={create}><h3>Tạo tài khoản mới</h3><div className="form-grid"><label>Họ và tên<input name="full_name" required minLength={2}/></label><label>Email<input name="email" type="email" required/></label><label>Số điện thoại<input name="phone"/></label><label>Mật khẩu tạm<input name="password" type="password" required minLength={6}/></label><label>Vai trò<select name="role" defaultValue="OFFICER"><option value="OFFICER">Cán bộ xử lý</option><option value="ADMIN">Quản trị viên</option><option value="CITIZEN">Người dân</option></select></label><label>Đơn vị<select name="department_id"><option value="">Chọn đơn vị</option>{deps.map(d => <option key={d.id} value={d.id}>{d.name}</option>)}</select></label></div><div className="modal-actions"><button type="button" className="button secondary" onClick={() => setOpen(false)}>Hủy</button><button className="button primary">Tạo tài khoản</button></div></form></div>}
    {passwordUser && <UserPasswordDialog key={passwordUser.id} user={passwordUser} self={passwordUser.id === getCurrentUser()?.id} onClose={() => setPasswordUser(null)} onSaved={self => void passwordSaved(self)}/>}
    {message && <Toast message={message} onClose={() => setMessage('')}/>}
  </section>;
}
