import { AppDataSource } from '../../database/data-source';
import { env } from '../../config/env';

export class InterestedAreaService {
  async searchPlaces(query:string, latitude?:number, longitude?:number) {
    const value=query.trim();
    if(value.length<2) return [];
    const providers = [
      () => this.searchPhoton(value, latitude, longitude),
      () => this.searchNominatim(value, latitude, longitude),
    ];
    for (const provider of providers) {
      try {
        const places = await provider();
        if (places.length) return places;
      } catch (error) {
        console.warn(JSON.stringify({
          level: 'warn',
          event: 'geocoding_provider_failed',
          message: error instanceof Error ? error.message : String(error),
        }));
      }
    }
    throw {
      statusCode: 503,
      message: 'Không thể kết nối dịch vụ tìm địa điểm. Bạn vẫn có thể chọn trực tiếp trên bản đồ.',
    };
  }

  private async searchPhoton(query: string, latitude?: number, longitude?: number) {
    const url=new URL('/api',env.GEOCODING_BASE_URL);
    url.searchParams.set('q',query);url.searchParams.set('limit','6');
    if(Number.isFinite(latitude)&&Number.isFinite(longitude)){url.searchParams.set('lat',String(latitude));url.searchParams.set('lon',String(longitude));}
    const response=await fetch(url,{headers:{'User-Agent':'DoThi360/1.0 (urban incident graduation project)','Accept':'application/json'},signal:AbortSignal.timeout(6000)});
    if(!response.ok) throw new Error(`Photon HTTP ${response.status}`);
    const payload:any=await response.json();
    return (payload.features??[]).map((feature:any)=>{const p=feature.properties??{},c=feature.geometry?.coordinates??[];return{id:String(p.osm_id??`${c[0]}-${c[1]}`),name:p.name??p.street??p.city??'Địa điểm',address:[p.housenumber,p.street,p.district,p.city,p.state,p.country].filter(Boolean).join(', '),latitude:Number(c[1]),longitude:Number(c[0]),type:p.osm_value??p.type??null};}).filter((item:any)=>Number.isFinite(item.latitude)&&Number.isFinite(item.longitude));
  }

  private async searchNominatim(query: string, latitude?: number, longitude?: number) {
    const url = new URL('https://nominatim.openstreetmap.org/search');
    url.searchParams.set('q', query);
    url.searchParams.set('format', 'jsonv2');
    url.searchParams.set('addressdetails', '1');
    url.searchParams.set('limit', '6');
    url.searchParams.set('countrycodes', 'vn');
    if (Number.isFinite(latitude) && Number.isFinite(longitude)) {
      const lat = Number(latitude), lng = Number(longitude);
      url.searchParams.set('viewbox', `${lng - 1},${lat + 1},${lng + 1},${lat - 1}`);
    }
    const response = await fetch(url, {
      headers: {
        'User-Agent': 'DoThi360/1.0 (urban incident graduation project)',
        'Accept-Language': 'vi,en',
        Accept: 'application/json',
      },
      signal: AbortSignal.timeout(6000),
    });
    if (!response.ok) throw new Error(`Nominatim HTTP ${response.status}`);
    const payload:any[] = await response.json();
    return payload.map(item => ({
      id: String(item.place_id),
      name: item.name || item.display_name?.split(',')[0] || 'Địa điểm',
      address: item.display_name || '',
      latitude: Number(item.lat),
      longitude: Number(item.lon),
      type: item.type ?? null,
    })).filter(item => Number.isFinite(item.latitude) && Number.isFinite(item.longitude));
  }
  async listMine(userId: string) {
    return AppDataSource.query(`
      SELECT a.id,a.name,a.radius_m,a.notifications_enabled,a.is_active,a.created_at,a.updated_at,
        ST_Y(a.center::geometry) latitude,ST_X(a.center::geometry) longitude,
        COUNT(i.id)::int incident_count,
        COUNT(i.id) FILTER (WHERE i.created_at >= NOW()-INTERVAL '24 hours')::int new_count
      FROM user_interested_areas a
      LEFT JOIN incidents i ON a.is_active=TRUE AND ST_DWithin(i.location,a.center,a.radius_m)
        AND i.status NOT IN ('REJECTED','CANCELLED')
      WHERE a.user_id=$1 AND a.is_active=TRUE
      GROUP BY a.id ORDER BY a.is_active DESC,a.updated_at DESC`, [userId]);
  }

  async create(userId: string, data: any) {
    const [{ count }] = await AppDataSource.query(
      'SELECT COUNT(*)::int count FROM user_interested_areas WHERE user_id=$1 AND is_active=TRUE', [userId]);
    if (Number(count) >= 5) throw { statusCode: 409, message: 'Bạn chỉ có thể theo dõi tối đa 5 khu vực' };
    try {
      const [row] = await AppDataSource.query(`
        INSERT INTO user_interested_areas(user_id,name,center,radius_m,notifications_enabled)
        VALUES($1,$2,ST_SetSRID(ST_Point($3,$4),4326)::geography,$5,$6)
        RETURNING id`, [userId,data.name,data.longitude,data.latitude,data.radius_m,data.notifications_enabled ?? true]);
      return row;
    } catch (error: any) {
      if (error?.code === '23505') throw { statusCode: 409, message: 'Tên khu vực đã tồn tại' };
      throw error;
    }
  }

  async update(userId: string, id: string, data: any) {
    try {
      const rows = await AppDataSource.query(`
        UPDATE user_interested_areas SET name=$3,center=ST_SetSRID(ST_Point($4,$5),4326)::geography,
          radius_m=$6,notifications_enabled=$7,updated_at=NOW()
        WHERE id=$1 AND user_id=$2 AND is_active=TRUE RETURNING id`,
        [id,userId,data.name,data.longitude,data.latitude,data.radius_m,data.notifications_enabled ?? true]);
      if (!rows.length) throw { statusCode: 404, message: 'Không tìm thấy khu vực quan tâm' };
      return rows[0];
    } catch (error: any) {
      if (error?.code === '23505') throw { statusCode: 409, message: 'Tên khu vực đã tồn tại' };
      throw error;
    }
  }

  async remove(userId: string, id: string) {
    const rows = await AppDataSource.query(
      'UPDATE user_interested_areas SET is_active=FALSE,updated_at=NOW() WHERE id=$1 AND user_id=$2 AND is_active=TRUE RETURNING id',
      [id,userId]);
    if (!rows.length) throw { statusCode: 404, message: 'Không tìm thấy khu vực quan tâm' };
  }

  async incidents(userId: string, id: string, page = 1, limit = 20) {
    const safePage = Math.max(page,1), safeLimit = Math.min(Math.max(limit,1),50);
    const areas = await AppDataSource.query(
      'SELECT id,name,radius_m,ST_Y(center::geometry) latitude,ST_X(center::geometry) longitude FROM user_interested_areas WHERE id=$1 AND user_id=$2 AND is_active=TRUE',
      [id,userId]);
    if (!areas.length) throw { statusCode: 404, message: 'Không tìm thấy khu vực quan tâm' };
    const data = await AppDataSource.query(`
      SELECT i.id,i.description,i.status,i.priority_level,i.report_count,i.created_at,t.name incident_type_name,
        ROUND(ST_Distance(i.location,a.center))::int distance_m,
        (SELECT m.file_url FROM incident_media m WHERE m.incident_id=i.id AND m.media_type='IMAGE' ORDER BY m.created_at LIMIT 1) cover_url
      FROM user_interested_areas a JOIN incidents i ON ST_DWithin(i.location,a.center,a.radius_m)
      JOIN incident_types t ON t.id=i.incident_type_id
      WHERE a.id=$1 AND a.user_id=$2 AND i.status NOT IN ('REJECTED','CANCELLED')
      ORDER BY i.created_at DESC OFFSET $3 LIMIT $4`, [id,userId,(safePage-1)*safeLimit,safeLimit]);
    return { area: areas[0], data, page: safePage, limit: safeLimit };
  }

  async adminSummary() {
    const [summary] = await AppDataSource.query(`SELECT COUNT(*)::int total,
      COUNT(*) FILTER(WHERE is_active)::int active,COUNT(DISTINCT user_id)::int users,
      COUNT(*) FILTER(WHERE notifications_enabled AND is_active)::int notifications_enabled
      FROM user_interested_areas`);
    return summary;
  }

  async adminList(page = 1, limit = 30, q = '') {
    const safePage=Math.max(page,1),safeLimit=Math.min(Math.max(limit,1),100),term=`%${q.trim()}%`;
    const [data,count] = await Promise.all([
      AppDataSource.query(`SELECT a.id,a.name,a.radius_m,a.notifications_enabled,a.is_active,a.created_at,
        ST_Y(a.center::geometry) latitude,ST_X(a.center::geometry) longitude,u.full_name,u.email,
        (SELECT COUNT(*)::int FROM incidents i WHERE ST_DWithin(i.location,a.center,a.radius_m)) incident_count
        FROM user_interested_areas a JOIN users u ON u.id=a.user_id
        WHERE ($3='' OR a.name ILIKE $4 OR u.full_name ILIKE $4 OR u.email ILIKE $4)
        ORDER BY a.created_at DESC OFFSET $1 LIMIT $2`,[(safePage-1)*safeLimit,safeLimit,q.trim(),term]),
      AppDataSource.query(`SELECT COUNT(*)::int total FROM user_interested_areas a JOIN users u ON u.id=a.user_id
        WHERE ($1='' OR a.name ILIKE $2 OR u.full_name ILIKE $2 OR u.email ILIKE $2)`,[q.trim(),term]),
    ]);
    return { data, meta:{page:safePage,limit:safeLimit,total:count[0].total,total_pages:Math.ceil(count[0].total/safeLimit)} };
  }

  async adminSetStatus(id: string, isActive: boolean) {
    const rows=await AppDataSource.query('UPDATE user_interested_areas SET is_active=$2,updated_at=NOW() WHERE id=$1 RETURNING id',[id,isActive]);
    if(!rows.length)throw{statusCode:404,message:'Không tìm thấy khu vực quan tâm'};
    return rows[0];
  }
}
