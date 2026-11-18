import { ArrowUpRight, MessageSquare } from 'lucide-react';
import { Link } from 'react-router-dom';
import type { Incident } from '../types';
import { StatusBadge } from './StatusBadge';
export function IncidentCard({ incident }: { incident: Incident }) {
  return <article className="incident-card"><div className="incident-card-head"><StatusBadge status={incident.status}/><span className={`priority priority-${(incident.priority_level ?? '').toLowerCase()}`}><i/>{incident.priority_level ?? '—'}</span></div><h3>{incident.incident_type?.name ?? 'Sự cố đô thị'}</h3><p>{incident.description}</p><div className="incident-card-meta"><span><MessageSquare/> {incident.report_count} lượt báo</span><span>{new Date(incident.created_at).toLocaleDateString('vi-VN')}</span></div><Link to={`/incidents/${incident.id}`}>Mở hồ sơ <ArrowUpRight/></Link></article>;
}
