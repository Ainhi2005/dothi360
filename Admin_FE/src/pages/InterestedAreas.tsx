import { useCallback, useEffect, useState } from 'react';
import { BellRing, MapPin, Radar, Search } from 'lucide-react';
import { api, errorMessage } from '../lib/api';
import { PageHeader } from '../components/PageHeader';
import { PageState } from '../components/PageState';
import type { InterestedArea } from '../types';

type Summary={total:number;active:number;users:number;notifications_enabled:number};
export default function InterestedAreas(){
 const[data,setData]=useState<InterestedArea[]>([]),[summary,setSummary]=useState<Summary>({total:0,active:0,users:0,notifications_enabled:0});
 const[loading,setLoading]=useState(true),[error,setError]=useState(''),[query,setQuery]=useState('');
 const load=useCallback(async()=>{setLoading(true);try{const[list,stats]=await Promise.all([api.get('/interested-areas/admin',{params:{q:query,limit:100}}),api.get('/interested-areas/admin/summary')]);setData(list.data.data);setSummary(stats.data.data);setError('')}catch(e){setError(errorMessage(e))}finally{setLoading(false)}},[query]);
 useEffect(()=>{const timer=setTimeout(()=>void load(),250);return()=>clearTimeout(timer)},[load]);
 const toggle=async(item:InterestedArea)=>{const action=item.is_active?'vô hiệu hóa':'kích hoạt';if(!confirm(`Bạn muốn ${action} vùng “${item.name}”?`))return;try{await api.patch(`/interested-areas/admin/${item.id}/status`,{is_active:!item.is_active});await load()}catch(e){setError(errorMessage(e))}};
 return <section><PageHeader title="Vùng quan tâm của người dân" parent="Tổ chức" description="Giám sát các vùng cá nhân được đăng ký nhận cảnh báo sự cố."/>
  <div className="stats-strip compact"><div className="stat-item"><strong>{summary.total}</strong><span>Tổng vùng</span></div><div className="stat-item"><strong>{summary.active}</strong><span>Đang theo dõi</span></div><div className="stat-item"><strong>{summary.users}</strong><span>Người sử dụng</span></div><div className="stat-item"><strong>{summary.notifications_enabled}</strong><span>Đã bật cảnh báo</span></div></div>
  <div className="filter-panel" style={{margin:'16px 0'}}><div className="search" style={{maxWidth:420}}><Search/><input value={query} onChange={e=>setQuery(e.target.value)} placeholder="Tìm tên vùng, người dùng hoặc email..."/></div></div>
  {error&&<div className="alert">{error}</div>}<article className="panel"><PageState loading={loading} error="" empty={!loading&&!data.length} onRetry={()=>void load()}/>{!loading&&data.length>0&&<div className="table-wrap"><table><thead><tr><th>Khu vực</th><th>Người theo dõi</th><th>Phạm vi</th><th>Sự cố</th><th>Cảnh báo</th><th>Trạng thái</th><th/></tr></thead><tbody>{data.map(item=><tr key={item.id}><td><strong>{item.name}</strong><small style={{display:'block',color:'var(--muted)'}}><MapPin size={12}/> {Number(item.latitude).toFixed(5)}, {Number(item.longitude).toFixed(5)}</small></td><td><strong>{item.full_name}</strong><small style={{display:'block',color:'var(--muted)'}}>{item.email}</small></td><td><span className="status-text"><Radar size={15}/> {(item.radius_m/1000).toFixed(1)} km</span></td><td>{item.incident_count}</td><td>{item.notifications_enabled?<span className="status-text"><BellRing size={15}/> Đã bật</span>:<span style={{color:'var(--muted)'}}>Đã tắt</span>}</td><td><span className={`dot-label ${item.is_active?'active':'inactive'}`}>{item.is_active?'Hoạt động':'Vô hiệu'}</span></td><td><button className={`text-button ${item.is_active?'danger-text':''}`} onClick={()=>void toggle(item)}>{item.is_active?'Vô hiệu hóa':'Kích hoạt'}</button></td></tr>)}</tbody></table></div>}</article>
  </section>;
}
