import { AppDataSource } from '../../database/data-source';
import { Incident } from '../incidents/incident.entity';
import { IncidentMedia } from '../media/media.entity';
import { Department } from '../departments/department.entity';

interface WeatherCacheEntry {
  timestamp: number;
  data: any;
}

const weatherCache = new Map<string, WeatherCacheEntry>();
const CACHE_TTL_MS = 10 * 60 * 1000; // 10 phút

export class UtilitiesService {
  private incidentRepo = AppDataSource.getRepository(Incident);
  private mediaRepo = AppDataSource.getRepository(IncidentMedia);
  private departmentRepo = AppDataSource.getRepository(Department);

  /**
   * Lấy danh sách các điểm ngập úng đô thị
   */
  async getFloodPoints(query: { status?: string }) {
    const qb = this.incidentRepo.createQueryBuilder('incident')
      .leftJoinAndSelect('incident.incident_type', 'type')
      .where('(type.code = :code OR type.name ILIKE :nameFilter OR incident.description ILIKE :descFilter)', {
        code: 'FLOODING',
        nameFilter: '%ngập%',
        descFilter: '%ngập%',
      })
      .orderBy('incident.created_at', 'DESC');

    if (query.status === 'ACTIVE') {
      qb.andWhere('incident.status NOT IN (:...done)', { done: ['RESOLVED', 'REJECTED', 'CANCELLED'] });
    } else if (query.status === 'RESOLVED') {
      qb.andWhere('incident.status = :res', { res: 'RESOLVED' });
    }

    const incidents = await qb.getMany();
    const ids = incidents.map(i => i.id);

    // Lấy ảnh đính kèm
    const covers = new Map<string, string>();
    if (ids.length > 0) {
      const mediaList = await this.mediaRepo.createQueryBuilder('media')
        .where('media.incident_id IN (:...ids) AND media.media_type = :type', { ids, type: 'IMAGE' })
        .orderBy('media.created_at', 'ASC')
        .getMany();
      for (const m of mediaList) {
        if (!covers.has(m.incident_id)) {
          covers.set(m.incident_id, m.file_url);
        }
      }
    }

    return incidents.map(i => {
      const severity = i.severity_level || 3;
      // Ước tính độ ngập theo mức độ nghiêm trọng
      let estimatedDepthCm = 25;
      let depthDescription = 'Ngập 20 - 30cm (nửa bánh xe)';
      if (severity === 1) {
        estimatedDepthCm = 15;
        depthDescription = 'Ngập 10 - 15cm (mép vỉa hè)';
      } else if (severity === 2) {
        estimatedDepthCm = 25;
        depthDescription = 'Ngập 20 - 30cm (xe máy đi chậm)';
      } else if (severity === 3) {
        estimatedDepthCm = 40;
        depthDescription = 'Ngập 35 - 50cm (nguy cơ chết máy)';
      } else if (severity === 4) {
        estimatedDepthCm = 65;
        depthDescription = 'Ngập 50 - 70cm (xe cộ tê liệt)';
      } else if (severity >= 5) {
        estimatedDepthCm = 90;
        depthDescription = 'Ngập trên 80cm (nguy hiểm cực độ)';
      }

      let floodStatus = 'ACTIVE';
      let floodStatusLabel = 'Đang ngập úng';
      if (i.status === 'RESOLVED') {
        floodStatus = 'RESOLVED';
        floodStatusLabel = 'Đã rút nước / Đã tiêu thoát';
      } else if (i.status === 'IN_PROGRESS') {
        floodStatus = 'DRAINING';
        floodStatusLabel = 'Nước đang rút / Đang xử lý bơm';
      }

      return {
        id: i.id,
        title: i.description || 'Điểm ngập úng đô thị',
        location: i.location,
        coordinates: i.location?.coordinates || [105.8542, 21.0285],
        severity_level: severity,
        estimated_depth_cm: estimatedDepthCm,
        depth_description: depthDescription,
        status: floodStatus,
        status_label: floodStatusLabel,
        incident_status: i.status,
        report_count: i.report_count || 1,
        cover_url: covers.get(i.id) || null,
        created_at: i.created_at,
        resolved_at: i.resolved_at,
      };
    });
  }

  /**
   * Lấy dữ liệu thời tiết và chất lượng không khí (AQI)
   */
  async getWeatherAndAqi(lat: number = 21.0285, lng: number = 105.8542) {
    const cacheKey = `${lat.toFixed(2)},${lng.toFixed(2)}`;
    const now = Date.now();
    const cached = weatherCache.get(cacheKey);
    if (cached && (now - cached.timestamp < CACHE_TTL_MS)) {
      return cached.data;
    }

    try {
      // 1. Gọi API Open-Meteo Weather
      const weatherUrl = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lng}&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m&timezone=Asia%2FBangkok`;
      const aqiUrl = `https://air-quality-api.open-meteo.com/v1/air-quality?latitude=${lat}&longitude=${lng}&current=pm10,pm2_5,european_aqi&timezone=Asia%2FBangkok`;

      const [weatherRes, aqiRes] = await Promise.all([
        fetch(weatherUrl, { signal: AbortSignal.timeout(6000) }),
        fetch(aqiUrl, { signal: AbortSignal.timeout(6000) }),
      ]);

      const weatherJson: any = weatherRes.ok ? await weatherRes.json() : null;
      const aqiJson: any = aqiRes.ok ? await aqiRes.json() : null;

      const currentW = weatherJson?.current || {};
      const currentA = aqiJson?.current || {};

      const temp = currentW.temperature_2m ?? 29;
      const feelsLike = currentW.apparent_temperature ?? temp;
      const humidity = currentW.relative_humidity_2m ?? 75;
      const windSpeed = currentW.wind_speed_10m ?? 8.5;
      const precipitation = currentW.precipitation ?? 0;
      const weatherCode = currentW.weather_code ?? 1;

      const pm25 = currentA.pm2_5 ?? 22.4;
      const pm10 = currentA.pm10 ?? 38.6;
      let rawAqi = currentA.european_aqi ?? Math.round(pm25 * 2.5);
      if (rawAqi <= 0) rawAqi = 45;

      // Diễn giải thời tiết
      let weatherDesc = 'Trời quang đãng, nắng nhẹ';
      let weatherIcon = 'sunny';
      if ([1, 2, 3].includes(weatherCode)) {
        weatherDesc = 'Mây rải rác, trời dịu';
        weatherIcon = 'partly_cloudy';
      } else if ([45, 48].includes(weatherCode)) {
        weatherDesc = 'Sương mù nhẹ sáng sớm';
        weatherIcon = 'fog';
      } else if ([51, 53, 55, 61, 63].includes(weatherCode)) {
        weatherDesc = 'Mưa rào nhẹ từng đợt';
        weatherIcon = 'rain_light';
      } else if ([65, 80, 81, 82].includes(weatherCode)) {
        weatherDesc = 'Mưa to diện rộng, chú ý đường trơn';
        weatherIcon = 'rain_heavy';
      } else if ([95, 96, 99].includes(weatherCode)) {
        weatherDesc = 'Dông lốc nguy hiểm, đề phòng cây đổ';
        weatherIcon = 'thunderstorm';
      }

      // Đánh giá AQI
      let aqiStatus = 'Tốt';
      let aqiColor = '#10B981'; // Green
      let aqiDescription = 'Chất lượng không khí trong lành, an toàn cho mọi hoạt động ngoài trời.';
      let healthAdvice = 'Không khí trong sạch, bạn có thể yên tâm rèn luyện thể thao và sinh hoạt ngoài trời.';

      if (rawAqi > 150) {
        aqiStatus = 'Nguy hại';
        aqiColor = '#EF4444'; // Red
        aqiDescription = 'Chất lượng không khí ở mức báo động đỏ, ảnh hưởng xấu tới sức khỏe.';
        aqiAdvice: healthAdvice = 'Hạn chế tối đa ra ngoài. Bắt buộc đeo khẩu trang chống bụi N95/PM2.5 khi ra đường.';
      } else if (rawAqi > 100) {
        aqiStatus = 'Kém';
        aqiColor = '#F97316'; // Orange
        aqiDescription = 'Không khí ô nhiễm, người nhạy cảm và trẻ nhỏ bắt đầu chịu ảnh hưởng.';
        healthAdvice = 'Nên đeo khẩu trang chống bụi mịn. Đóng kín cửa sổ khi ở gần trục đường lớn.';
      } else if (rawAqi > 50) {
        aqiStatus = 'Trung bình';
        aqiColor = '#EAB308'; // Yellow
        aqiDescription = 'Chất lượng không khí chấp nhận được, ở mức bình thường đối với đô thị.';
        healthAdvice = 'Nhóm người quá nhạy cảm với khói bụi nên giảm vận động gắng sức ngoài trời.';
      }

      // Đánh giá nguy cơ ngập úng
      let floodRisk = 'THẤP';
      let floodRiskNote = 'Thời tiết ổn định, không có nguy cơ ngập lụt';
      if (precipitation > 15 || weatherCode >= 80) {
        floodRisk = 'CAO';
        floodRiskNote = 'Mưa lớn kéo dài, các vùng trũng thấp có nguy cơ ngập úng nghiêm trọng!';
      } else if (precipitation > 2 || [55, 63].includes(weatherCode)) {
        floodRisk = 'TRUNG BÌNH';
        floodRiskNote = 'Đang có mưa, đề phòng ứ đọng nước cục bộ tại các điểm thoát nước chậm.';
      }

      const result = {
        location: { latitude: lat, longitude: lng, name: 'Khu vực đô thị của bạn' },
        weather: {
          temperature: Math.round(temp),
          apparent_temperature: Math.round(feelsLike),
          humidity,
          wind_speed_kmh: Math.round(windSpeed),
          precipitation_mm: precipitation,
          description: weatherDesc,
          icon: weatherIcon,
          weather_code: weatherCode,
        },
        air_quality: {
          aqi: rawAqi,
          status: aqiStatus,
          color: aqiColor,
          pm2_5: Math.round(pm25 * 10) / 10,
          pm10: Math.round(pm10 * 10) / 10,
          description: aqiDescription,
          health_advice: healthAdvice,
        },
        flood_risk: {
          level: floodRisk,
          note: floodRiskNote,
        },
        updated_at: new Date().toISOString(),
      };

      weatherCache.set(cacheKey, { timestamp: now, data: result });
      return result;
    } catch (err) {
      console.warn('Weather/AQI fetch fallback:', err);
      // Fallback data khi mạng yếu hoặc offline
      return {
        location: { latitude: lat, longitude: lng, name: 'Khu vực đô thị' },
        weather: {
          temperature: 29,
          apparent_temperature: 31,
          humidity: 70,
          wind_speed_kmh: 12,
          precipitation_mm: 0,
          description: 'Nắng ráo, mây nhẹ',
          icon: 'partly_cloudy',
          weather_code: 1,
        },
        air_quality: {
          aqi: 58,
          status: 'Trung bình',
          color: '#EAB308',
          pm2_5: 24.5,
          pm10: 42.0,
          description: 'Chất lượng không khí bình thường ở các trục đường chính.',
          health_advice: 'Người có vấn đề hô hấp nên chuẩn bị khẩu trang khi tham gia giao thông giờ cao điểm.',
        },
        flood_risk: {
          level: 'THẤP',
          note: 'Không có cảnh báo mưa lớn hay ngập úng.',
        },
        updated_at: new Date().toISOString(),
      };
    }
  }

  /**
   * Lấy danh bạ các đơn vị kỹ thuật đô thị (Thoát nước, Cây xanh, Chiếu sáng, CSGT...)
   */
  async getDepartmentsDirectory(userLat?: number, userLng?: number) {
    const departments = await this.departmentRepo.find({
      where: { is_active: true },
      order: { name: 'ASC' },
    });

    const ids = departments.map(d => d.id);
    let capabilitiesMap = new Map<string, string[]>();
    if (ids.length > 0) {
      const caps = await AppDataSource.query(`
        SELECT dit.department_id, it.name as type_name
        FROM department_incident_types dit
        JOIN incident_types it ON it.id = dit.incident_type_id
        WHERE dit.department_id = ANY($1) AND dit.is_active = TRUE
      `, [ids]);
      for (const c of caps) {
        const list = capabilitiesMap.get(c.department_id) || [];
        list.push(c.type_name);
        capabilitiesMap.set(c.department_id, list);
      }
    }

    return departments.map(d => {
      let distanceKm: number | null = null;
      if (userLat !== undefined && userLng !== undefined && d.location?.coordinates) {
        // Tính khoảng cách theo công thức Haversine
        const [depLng, depLat] = d.location.coordinates;
        const R = 6371; // km
        const dLat = (depLat - userLat) * Math.PI / 180;
        const dLon = (depLng - userLng) * Math.PI / 180;
        const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
          Math.cos(userLat * Math.PI / 180) * Math.cos(depLat * Math.PI / 180) *
          Math.sin(dLon / 2) * Math.sin(dLon / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        distanceKm = Math.round(R * c * 10) / 10;
      }

      return {
        id: d.id,
        code: d.code,
        name: d.name,
        address: d.address || 'Đang cập nhật địa chỉ',
        phone: d.phone || '1022',
        email: d.email,
        location: d.location,
        distance_km: distanceKm,
        managed_incident_types: capabilitiesMap.get(d.id) || ['Xử lý sự cố hạ tầng đô thị'],
      };
    }).sort((a, b) => {
      if (a.distance_km !== null && b.distance_km !== null) {
        return a.distance_km - b.distance_km;
      }
      return a.name.localeCompare(b.name);
    });
  }

  /**
   * Thống kê tổng hợp đô thị phục vụ trang Tiện ích & Admin Dashboard
   */
  async getSummary() {
    const [floodActive, floodResolved, totalDep] = await Promise.all([
      this.incidentRepo.createQueryBuilder('i')
        .leftJoin('i.incident_type', 't')
        .where('(t.code = :code OR t.name ILIKE :ngap) AND i.status NOT IN (:...done)', {
          code: 'FLOODING',
          ngap: '%ngập%',
          done: ['RESOLVED', 'REJECTED', 'CANCELLED'],
        })
        .getCount(),
      this.incidentRepo.createQueryBuilder('i')
        .leftJoin('i.incident_type', 't')
        .where('(t.code = :code OR t.name ILIKE :ngap) AND i.status = :res', {
          code: 'FLOODING',
          ngap: '%ngập%',
          res: 'RESOLVED',
        })
        .getCount(),
      this.departmentRepo.count({ where: { is_active: true } }),
    ]);

    return {
      active_flood_points: floodActive,
      resolved_flood_points: floodResolved,
      total_departments: totalDep,
      system_status: floodActive > 3 ? 'CẢNH BÁO MƯA NGẬP' : 'HOẠT ĐỘNG BÌNH THƯỜNG',
    };
  }
}
