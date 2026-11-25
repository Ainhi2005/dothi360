import { useCallback, useEffect, useRef, useState } from 'react';
import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import {
  AlertTriangle,
  Bell,
  BrainCircuit,
  Building2,
  ClipboardList,
  Droplets,
  FolderCog,
  LayoutDashboard,
  Lightbulb,
  LogOut,
  Menu,
  PhoneCall,
  ShieldAlert,
  Users,
  X,
} from 'lucide-react';
import { api, getCurrentUser, logout as logoutSession } from '../lib/api';

import { type AdminNotification, notificationPath, notificationAction } from '../lib/notifications';

const navigation = [
  {
    label: 'Điều hành tác nghiệp',
    items: [
      ['/', 'Tổng quan', LayoutDashboard],
      ['/incidents', 'Hồ sơ sự cố', AlertTriangle],
      ['/assignments', 'Điều phối cán bộ', ClipboardList],
      ['/notification-center', 'Trung tâm thông báo', Bell],
      ['/flood-points', 'Giám sát ngập úng', Droplets],
    ],
  },
  {
    label: 'Quản trị & Thuật toán',
    items: [
      ['/departments', 'Đơn vị xử lý', Building2],
      ['/users', 'Người dùng & Cán bộ', Users],
      ['/catalog', 'Loại sự cố', FolderCog],
      ['/chat-assistant', 'Trợ lý đô thị', BrainCircuit],
    ],
  },
  {
    label: 'Tiện ích công dân',
    items: [
      ['/emergency-contacts', 'Danh bạ khẩn cấp', PhoneCall],
      ['/emergency-guides', 'Hướng dẫn khẩn cấp', ShieldAlert],
      ['/citizen-feedbacks', 'Hiến kế & Góp ý', Lightbulb],
    ],
  },
] as const;

export function AdminLayout() {
  const [open, setOpen] = useState(false);
  const [unreadNotifications, setUnreadNotifications] = useState(0);
  const navigate = useNavigate();
  const knownIds = useRef<Set<string> | null>(null);
  const [alert, setAlert] = useState<AdminNotification | null>(null);
  const user = getCurrentUser() ?? {};

  const loadUnreadNotifications = useCallback(async () => {
    try {
      const response = await api.get('/admin/notifications', {
        params: { page: 1, limit: 30 },
      });
      setUnreadNotifications(Number(response.data.data?.meta?.unread) || 0);
      const items: AdminNotification[] = response.data.data?.data ?? [];
      if (knownIds.current) {
        const fresh = items.find(item => item.id && !knownIds.current!.has(item.id) && !item.is_read);
        if (fresh) setAlert(fresh);
      } else knownIds.current = new Set();
      items.forEach(item => { if (item.id) knownIds.current!.add(item.id); });
    } catch {
      // Không làm gián đoạn giao diện điều hành nếu API nhắc việc tạm lỗi.
    }
  }, []);

  useEffect(() => {
    void loadUnreadNotifications();
    const timer = window.setInterval(loadUnreadNotifications, 15000);
    const refresh = () => void loadUnreadNotifications();
    window.addEventListener('admin-notifications-updated', refresh);
    window.addEventListener('focus', refresh);
    return () => {
      window.clearInterval(timer);
      window.removeEventListener('admin-notifications-updated', refresh);
      window.removeEventListener('focus', refresh);
    };
  }, [loadUnreadNotifications]);

  const logout = async () => {
    await logoutSession();
    navigate('/login');
  };

  return (
    <div className="shell framed-shell">
      {alert && <aside className="admin-notification-alert" role="status" aria-live="polite">
        <button className="icon" aria-label="Ẩn thông báo" onClick={() => setAlert(null)}><X size={16} /></button>
        <strong><Bell size={16} /> {alert.title}</strong>
        <p>{alert.message}</p>
        <button className="text-button" onClick={() => {
          const path = notificationPath(alert);
          if (alert.id) void api.patch(`/notifications/${alert.id}/read`).then(() => { void loadUnreadNotifications(); }).catch(() => {});
          setAlert(null);
          navigate(path ?? '/notification-center');
        }}>{notificationAction(alert)}</button>
      </aside>}
      {open && (
        <button
          className="backdrop"
          aria-label="Đóng menu"
          onClick={() => setOpen(false)}
        />
      )}
      <aside className={`sidebar ${open ? 'open' : ''}`}>
        <div className="brand">
          <span className="brand-mark" style={{ background: 'transparent', padding: 0 }}>
            <img src="/main_logo.png" alt="Đô thị 360 Logo" style={{ width: 38, height: 38, objectFit: 'contain' }} />
          </span>
          <div>
            <strong>Đô thị 360</strong>
            <small>Trung tâm điều hành</small>
          </div>
          <button
            className="icon mobile-only"
            aria-label="Đóng thanh điều hướng"
            onClick={() => setOpen(false)}
          >
            <X size={18} />
          </button>
        </div>
        <nav>
          {navigation.map((group) => (
            <div className="nav-group" key={group.label}>
              <span className="nav-group-label">{group.label}</span>
              {group.items.map(([to, label, Icon]) => (
                <NavLink
                  key={to}
                  to={to}
                  end={to === '/'}
                  onClick={() => setOpen(false)}
                >
                  <Icon size={17} />
                  <span>{label}</span>
                  {to === '/notification-center' && unreadNotifications > 0 && (
                    <span className="nav-notification-count">
                      {unreadNotifications > 99 ? '99+' : unreadNotifications}
                    </span>
                  )}
                </NavLink>
              ))}
            </div>
          ))}
        </nav>
        <div className="sidebar-user">
          <div className="avatar">{user.full_name?.[0] ?? 'A'}</div>
          <div>
            <strong>{user.full_name ?? 'Quản trị viên'}</strong>
            <small>Điều phối viên hệ thống</small>
          </div>
          <button
            className="icon"
            title="Đăng xuất"
            onClick={logout}
          >
            <LogOut size={16} />
          </button>
        </div>
      </aside>

      <div className="content-viewport">
        <header className="topbar">
          <button
            className="icon mobile-only"
            aria-label="Mở menu"
            onClick={() => setOpen(true)}
          >
            <Menu size={18} />
          </button>
          <div className="topbar-scope">
            <span>Khu vực: <strong>Toàn thành phố</strong></span>
          </div>
          <div className="topbar-spacer" />
          <button
            className="icon notification-trigger"
            type="button"
            aria-label={`${unreadNotifications} thông báo chưa đọc`}
            title="Thông báo và yêu cầu cần xử lý"
            onClick={() => navigate('/notification-center')}
          >
            <Bell size={18} />
            {unreadNotifications > 0 && (
              <span>{unreadNotifications > 99 ? '99+' : unreadNotifications}</span>
            )}
          </button>
          <div className="live">
            <i /> Hệ thống trực tuyến
          </div>
        </header>
        <main className="sheet-frame">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
