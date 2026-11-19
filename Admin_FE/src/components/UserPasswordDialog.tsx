import { useEffect, useRef, useState, type FormEvent } from 'react';
import { api, errorMessage } from '../lib/api';
import type { User } from '../types';

export function UserPasswordDialog({ user, self, onClose, onSaved }: {
  user: User; self: boolean; onClose: () => void; onSaved: (self: boolean) => void;
}) {
  const dialog = useRef<HTMLDialogElement>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  useEffect(() => { dialog.current?.showModal(); }, []);
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (busy) return;
    const form = new FormData(event.currentTarget);
    if (form.get('new_password') !== form.get('confirm_password')) { setError('Mật khẩu xác nhận không khớp'); return; }
    setBusy(true); setError('');
    try {
      const response = await api.patch(`/users/${user.id}/password`, {
        new_password: form.get('new_password'), must_change_password: form.get('must_change_password') === 'on',
      });
      onSaved(response.data.data.requires_relogin === true);
    } catch (cause) { setError(errorMessage(cause)); setBusy(false); }
  }
  return <dialog ref={dialog} className="modal password-dialog" aria-labelledby="password-dialog-title"
    onCancel={event => { event.preventDefault(); if (!busy) onClose(); }}>
    <form onSubmit={submit}>
      <h3 id="password-dialog-title">Đổi mật khẩu tài khoản</h3>
      <p><strong>{user.full_name}</strong><br/>{user.email} · {user.role}</p>
      <p>Các phiên đăng nhập cũ của tài khoản này sẽ bị thu hồi.{self && ' Bạn sẽ được chuyển về trang đăng nhập sau khi lưu.'}</p>
      {error && <div className="alert" role="alert">{error}</div>}
      <fieldset disabled={busy}>
        <label>Mật khẩu mới<input name="new_password" type="password" autoComplete="new-password" minLength={6} maxLength={128} required autoFocus/></label>
        <small>Từ 6 đến 128 ký tự.</small>
        <label>Xác nhận mật khẩu mới<input name="confirm_password" type="password" autoComplete="new-password" minLength={6} maxLength={128} required/></label>
        <label className="password-option"><input name="must_change_password" type="checkbox"/>Yêu cầu đổi lại mật khẩu ở lần đăng nhập tiếp theo</label>
      </fieldset>
      <div className="modal-actions"><button type="button" className="button secondary" disabled={busy} onClick={onClose}>Hủy</button><button className="button primary" disabled={busy}>{busy ? 'Đang lưu…' : 'Lưu mật khẩu'}</button></div>
    </form>
  </dialog>;
}
