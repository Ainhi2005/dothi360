import { useState } from 'react';
import type { FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { api, errorMessage, setSession } from '../lib/api';

export default function Login() {
  const [email, setEmail] = useState('admin@urban.com');
  const [password, setPassword] = useState('123456');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const submit = async (event: FormEvent) => {
    event.preventDefault(); setLoading(true); setError('');
    try {
      const { data } = await api.post('/auth/login', { email, password });
      if (data.data.user.role !== 'ADMIN') throw new Error('Tài khoản không có quyền quản trị');
      setSession(data.data.access_token,data.data.user);
      navigate(data.data.user.must_change_password?'/change-password':'/');
    } catch (err) {
      setError(err instanceof Error && !('response' in err) ? err.message : errorMessage(err));
    } finally { setLoading(false); }
  };
  return <main className="login-page">
    <section className="login-intro">
      <div className="login-brand"><span className="brand-mark" style={{ background: 'transparent', padding: 0 }}><img src="/main_logo.png" alt="Đô thị 360" style={{ width: 44, height: 44, objectFit: 'contain' }} /></span><strong>Đô thị 360</strong></div>
      <p>Hệ thống quản lý và điều phối phản ánh sự cố đô thị.</p>
    </section>
    <section className="login-panel">
      <form className="login-card" onSubmit={submit}>
        <h1>Đăng nhập</h1>
        {error && <div className="alert">{error}</div>}
        <label>Email quản trị<input value={email} onChange={e => setEmail(e.target.value)} type="email" required/></label>
        <label>Mật khẩu<input value={password} onChange={e => setPassword(e.target.value)} type="password" required/></label>
        <button className="button primary" disabled={loading}>{loading ? 'Đang xác thực…' : 'Đăng nhập'}</button>
      </form>
    </section>
  </main>;
}
