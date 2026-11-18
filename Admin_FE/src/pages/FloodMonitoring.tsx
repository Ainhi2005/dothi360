import { useCallback, useEffect, useState } from 'react';
import { Droplets, RefreshCw, Wind, SunMedium, AlertOctagon, CheckCircle2, ExternalLink } from 'lucide-react';
import { Link } from 'react-router-dom';
import { PageHeader } from '../components/PageHeader';
import { PageState } from '../components/PageState';
import { EmptyState } from '../components/EmptyState';
import { api, errorMessage } from '../lib/api';

interface FloodPoint {
  id: string;
  title: string;
  coordinates: [number, number];
  severity_level: number;
  estimated_depth_cm: number;
  depth_description: string;
  status: 'ACTIVE' | 'DRAINING' | 'RESOLVED';
  status_label: string;
  report_count: number;
  cover_url: string | null;
  created_at: string;
  resolved_at: string | null;
}

interface WeatherAqiData {
  weather: {
    temperature: number;
    humidity: number;
    wind_speed_kmh: number;
    description: string;
    precipitation_mm: number;
  };
  air_quality: {
    aqi: number;
    status: string;
    color: string;
    pm2_5: number;
    description: string;
    health_advice: string;
  };
  flood_risk: {
    level: string;
    note: string;
  };
}

export default function FloodMonitoring() {
  const [floodPoints, setFloodPoints] = useState<FloodPoint[]>([]);
  const [weatherAqi, setWeatherAqi] = useState<WeatherAqiData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'ACTIVE' | 'RESOLVED'>('ALL');
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const [floodRes, weatherRes] = await Promise.all([
        api.get('/utilities/flood-points'),
        api.get('/utilities/weather-aqi'),
      ]);
      setFloodPoints(floodRes.data.data || []);
      setWeatherAqi(weatherRes.data.data || null);
      setError('');
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadData();
  }, [loadData]);

  const markResolved = async (incidentId: string) => {
    if (!confirm('Xác nhận điểm ngập này đã được tiêu thoát và rút nước hoàn toàn?')) return;
    setActionLoading(incidentId);
    try {
      await api.patch(`/incidents/${incidentId}/status`, {
        status: 'RESOLVED',
        note: 'Hệ thống thoát nước đã vận hành, nước rút hoàn toàn.',
      });
      await loadData();
    } catch (e) {
      alert(errorMessage(e));
    } finally {
      setActionLoading(null);
    }
  };

  const filteredPoints = floodPoints.filter(p => {
    if (statusFilter === 'ACTIVE') return p.status !== 'RESOLVED';
    if (statusFilter === 'RESOLVED') return p.status === 'RESOLVED';
    return true;
  });

  const activeCount = floodPoints.filter(p => p.status !== 'RESOLVED').length;

  return (
    <section>
      <PageHeader
        title="Điểm ngập úng & Môi trường"
        parent="Điều hành"
        description="Theo dõi trực quan các điểm ngập nước do mưa bão, chỉ số AQI và thời tiết đô thị."
        actions={
          <button className="refresh-button" onClick={loadData}>
            <RefreshCw /> Làm mới
          </button>
        }
      />

      {/* Overview Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '1rem', marginBottom: '1.5rem' }}>
        <article className="panel" style={{ padding: '1.25rem', borderLeft: '4px solid #0284C7' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.9rem', color: 'var(--text-muted, #64748B)' }}>Điểm ngập đang theo dõi</span>
            <Droplets size={22} color="#0284C7" />
          </div>
          <div style={{ fontSize: '1.8rem', fontWeight: 700, marginTop: '0.5rem', color: '#0284C7' }}>
            {activeCount} <small style={{ fontSize: '1rem', fontWeight: 500 }}>điểm</small>
          </div>
          <p style={{ margin: '0.25rem 0 0', fontSize: '0.85rem', color: 'var(--text-muted, #64748B)' }}>
            {floodPoints.length - activeCount} điểm đã tiêu thoát xong
          </p>
        </article>

        <article className="panel" style={{ padding: '1.25rem', borderLeft: `4px solid ${weatherAqi?.air_quality.color || '#10B981'}` }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.9rem', color: 'var(--text-muted, #64748B)' }}>Chất lượng không khí (AQI)</span>
            <Wind size={22} color={weatherAqi?.air_quality.color || '#10B981'} />
          </div>
          <div style={{ fontSize: '1.8rem', fontWeight: 700, marginTop: '0.5rem', color: weatherAqi?.air_quality.color || '#10B981' }}>
            {weatherAqi?.air_quality.aqi ?? '--'}{' '}
            <span style={{ fontSize: '0.95rem', fontWeight: 600, padding: '0.2rem 0.6rem', borderRadius: '12px', background: `${weatherAqi?.air_quality.color}22` }}>
              {weatherAqi?.air_quality.status ?? 'Bình thường'}
            </span>
          </div>
          <p style={{ margin: '0.25rem 0 0', fontSize: '0.85rem', color: 'var(--text-muted, #64748B)' }}>
            PM2.5: {weatherAqi?.air_quality.pm2_5 ?? 0} µg/m³
          </p>
        </article>

        <article className="panel" style={{ padding: '1.25rem', borderLeft: '4px solid #EAB308' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.9rem', color: 'var(--text-muted, #64748B)' }}>Thời tiết đô thị</span>
            <SunMedium size={22} color="#EAB308" />
          </div>
          <div style={{ fontSize: '1.8rem', fontWeight: 700, marginTop: '0.5rem' }}>
            {weatherAqi?.weather.temperature ?? 29}°C{' '}
            <small style={{ fontSize: '0.9rem', fontWeight: 400, color: 'var(--text-muted, #64748B)' }}>
              (ẩm {weatherAqi?.weather.humidity ?? 70}%)
            </small>
          </div>
          <p style={{ margin: '0.25rem 0 0', fontSize: '0.85rem', color: 'var(--text-muted, #64748B)' }}>
            {weatherAqi?.weather.description ?? 'Trời nắng mây rải rác'}
          </p>
        </article>

        <article className="panel" style={{ padding: '1.25rem', borderLeft: weatherAqi?.flood_risk.level === 'CAO' ? '4px solid #EF4444' : '4px solid #10B981' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.9rem', color: 'var(--text-muted, #64748B)' }}>Nguy cơ ngập úng</span>
            <AlertOctagon size={22} color={weatherAqi?.flood_risk.level === 'CAO' ? '#EF4444' : '#10B981'} />
          </div>
          <div style={{ fontSize: '1.5rem', fontWeight: 700, marginTop: '0.5rem', color: weatherAqi?.flood_risk.level === 'CAO' ? '#EF4444' : '#10B981' }}>
            CẤP {weatherAqi?.flood_risk.level ?? 'THẤP'}
          </div>
          <p style={{ margin: '0.25rem 0 0', fontSize: '0.85rem', color: 'var(--text-muted, #64748B)' }}>
            {weatherAqi?.flood_risk.note ?? 'Hạ tầng thoát nước ổn định'}
          </p>
        </article>
      </div>

      {/* Filter Tabs */}
      <div className="filter-panel" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ display: 'flex', gap: '0.5rem' }}>
          <button
            className={`button ${statusFilter === 'ALL' ? 'primary' : 'secondary'}`}
            onClick={() => setStatusFilter('ALL')}
          >
            Tất cả ({floodPoints.length})
          </button>
          <button
            className={`button ${statusFilter === 'ACTIVE' ? 'primary' : 'secondary'}`}
            onClick={() => setStatusFilter('ACTIVE')}
          >
            Đang ngập ({activeCount})
          </button>
          <button
            className={`button ${statusFilter === 'RESOLVED' ? 'primary' : 'secondary'}`}
            onClick={() => setStatusFilter('RESOLVED')}
          >
            Đã tiêu thoát ({floodPoints.length - activeCount})
          </button>
        </div>
        <div style={{ fontSize: '0.9rem', color: 'var(--text-muted, #64748B)' }}>
          Hiển thị <strong>{filteredPoints.length}</strong> điểm ngập
        </div>
      </div>

      <PageState loading={loading} error={error} onRetry={loadData} />

      {!loading && !error && filteredPoints.length === 0 && (
        <EmptyState
          title="Không có điểm ngập nào"
          description="Hiện tại không có điểm ngập úng nào phù hợp với bộ lọc đã chọn."
        />
      )}

      {/* Table */}
      {!loading && !error && filteredPoints.length > 0 && (
        <article className="panel">
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Vị trí / Mô tả ngập</th>
                  <th>Mức nước ước tính</th>
                  <th>Tọa độ GPS</th>
                  <th>Lượt phản ánh</th>
                  <th>Thời gian ghi nhận</th>
                  <th>Trạng thái</th>
                  <th style={{ textAlign: 'right' }}>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {filteredPoints.map(point => (
                  <tr key={point.id}>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                        {point.cover_url ? (
                          <img
                            src={point.cover_url}
                            alt="Hiện trường"
                            style={{ width: '48px', height: '48px', borderRadius: '6px', objectFit: 'cover' }}
                          />
                        ) : (
                          <div style={{ width: '48px', height: '48px', borderRadius: '6px', background: '#E0F2FE', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                            <Droplets size={22} color="#0284C7" />
                          </div>
                        )}
                        <div>
                          <strong>{point.title}</strong>
                          <br />
                          <small style={{ color: 'var(--text-muted, #64748B)' }}>{point.depth_description}</small>
                        </div>
                      </div>
                    </td>
                    <td>
                      <span style={{ fontWeight: 600, color: point.estimated_depth_cm >= 40 ? '#EF4444' : '#0284C7' }}>
                        ~{point.estimated_depth_cm} cm
                      </span>
                    </td>
                    <td>
                      <small style={{ fontFamily: 'monospace' }}>
                        {point.coordinates[1].toFixed(4)}, {point.coordinates[0].toFixed(4)}
                      </small>
                    </td>
                    <td>
                      <strong>{point.report_count}</strong> người báo
                    </td>
                    <td>
                      {new Date(point.created_at).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })}{' '}
                      <small>{new Date(point.created_at).toLocaleDateString('vi-VN')}</small>
                    </td>
                    <td>
                      {point.status === 'RESOLVED' ? (
                        <span style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', padding: '0.2rem 0.6rem', borderRadius: '12px', background: '#ECFDF5', color: '#10B981', fontSize: '0.85rem', fontWeight: 600 }}>
                          <CheckCircle2 size={14} /> Đã rút nước
                        </span>
                      ) : point.status === 'DRAINING' ? (
                        <span style={{ padding: '0.2rem 0.6rem', borderRadius: '12px', background: '#FEF3C7', color: '#D97706', fontSize: '0.85rem', fontWeight: 600 }}>
                          Đang bơm thoát
                        </span>
                      ) : (
                        <span style={{ padding: '0.2rem 0.6rem', borderRadius: '12px', background: '#FEE2E2', color: '#EF4444', fontSize: '0.85rem', fontWeight: 600 }}>
                          Đang ngập úng
                        </span>
                      )}
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <div style={{ display: 'inline-flex', gap: '0.5rem', alignItems: 'center' }}>
                        {point.status !== 'RESOLVED' && (
                          <button
                            className="button secondary"
                            style={{ padding: '0.3rem 0.6rem', fontSize: '0.8rem' }}
                            disabled={actionLoading === point.id}
                            onClick={() => markResolved(point.id)}
                            title="Xác nhận đã rút nước"
                          >
                            Đã rút nước
                          </button>
                        )}
                        <Link className="text-button" to={`/incidents/${point.id}`} style={{ display: 'inline-flex', alignItems: 'center', gap: '2px' }}>
                          Chi tiết <ExternalLink size={14} />
                        </Link>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </article>
      )}
    </section>
  );
}
