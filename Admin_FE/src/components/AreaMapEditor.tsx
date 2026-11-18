import { useEffect, useState } from 'react';
import { MapContainer, Polygon, Polyline, TileLayer, useMapEvents } from 'react-leaflet';

type Geometry={type:'Polygon';coordinates:number[][][]};
type Props={value?:Geometry;areas?:{id:string;geometry:Geometry}[];onChange:(geometry:Geometry|undefined)=>void};
type Point=[number,number];

function ClickCollector({onAdd}:{onAdd:(point:Point)=>void}){useMapEvents({click:event=>onAdd([event.latlng.lat,event.latlng.lng])});return null}

export function AreaMapEditor({value,areas=[],onChange}:Props){
  const initial=value?.coordinates[0].slice(0,-1).map(([lng,lat])=>[lat,lng] as Point)??[];
  const[points,setPoints]=useState<Point[]>(initial);
  useEffect(()=>{if(points.length<3){onChange(undefined);return}const ring=points.map(([lat,lng])=>[lng,lat]);onChange({type:'Polygon',coordinates:[[...ring,ring[0]]]})},[points,onChange]);
  return <div className="area-map-editor"><div className="map-toolbar"><span>{points.length} điểm đã chọn</span><button type="button" className="text-button" disabled={!points.length} onClick={()=>setPoints(current=>current.slice(0,-1))}>Hoàn tác</button><button type="button" className="text-button danger-text" disabled={!points.length} onClick={()=>setPoints([])}>Vẽ lại</button></div><MapContainer center={points[0]??[10.776,106.700]} zoom={12} scrollWheelZoom className="area-map"><TileLayer attribution='&copy; OpenStreetMap contributors' url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"/><ClickCollector onAdd={point=>setPoints(current=>[...current,point])}/>{areas.map(area=><Polygon key={area.id} positions={area.geometry.coordinates[0].map(([lng,lat])=>[lat,lng] as Point)} pathOptions={{color:'#87968f',weight:1,fillOpacity:.08}}/>)}{points.length>1&&<Polyline positions={points} pathOptions={{color:'#087A56',weight:3}}/>}{points.length>=3&&<Polygon positions={points} pathOptions={{color:'#087A56',fillOpacity:.18}}/>}</MapContainer><small>Nhấn lần lượt lên bản đồ để tạo ranh giới. Có thể hoàn tác từng điểm hoặc vẽ lại toàn bộ.</small></div>;
}
