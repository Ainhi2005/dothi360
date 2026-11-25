import assert from 'node:assert/strict';
import test, { before, after } from 'node:test';
import { randomUUID } from 'node:crypto';
import { AppDataSource } from '../../database/data-source';
import { Incident } from './incident.entity';
import { IncidentQueryService } from './services/incident-query.service';
import { IncidentServiceDependencies } from './services/incident-dependencies';
import app from '../../app';

before(async () => {
  const options = AppDataSource.options as { url?: string; host?: string };
  const host = options.url ? new URL(options.url).hostname : options.host;
  assert.ok(['localhost', '127.0.0.1', '::1'].includes(host ?? ''),
    'Bộ kiểm thử vị trí chỉ chạy trên PostgreSQL local');
  AppDataSource.setOptions({ logging: false });
  await AppDataSource.initialize();
});

after(async () => {
  if (AppDataSource.isInitialized) await AppDataSource.destroy();
});

test('GPS mới thay đổi kết quả, loại hồ sơ đóng, khoảng cách thật và giới hạn tám hồ sơ', async () => {
  const runner = AppDataSource.createQueryRunner();
  await runner.connect();
  await runner.startTransaction();
  try {
    const service = new IncidentQueryService({
      incidentRepo: runner.manager.getRepository(Incident),
    } as IncidentServiceDependencies);
    const [type] = await runner.query(
      'INSERT INTO incident_types(code,name) VALUES($1,$1) RETURNING id', [randomUUID()]);
    // Chọn vùng xa dữ liệu demo để kết quả không phụ thuộc hồ sơ có sẵn.
    const longitude = -30;
    const latitude = -40;
    const ids: string[] = [];
    for (let index = 0; index < 10; index++) {
      const [row] = await runner.query(`INSERT INTO incidents
        (incident_type_id,description,location,severity_level,status,created_at)
        VALUES($1,$2,ST_SetSRID(ST_MakePoint($3,$4),4326)::geography,3,'IN_PROGRESS',
          NOW() + ($5 * INTERVAL '1 second')) RETURNING id`,
      [type.id, `Kiểm thử gần ${index}`, longitude + index * 0.001, latitude, index]);
      ids.push(row.id);
    }
    await runner.query(`INSERT INTO incidents
      (incident_type_id,description,location,severity_level,status,resolved_at)
      SELECT $1, 'Hồ sơ đã đóng', ST_SetSRID(ST_MakePoint($2,$3),4326)::geography,3,
        status, CASE WHEN status='RESOLVED' THEN NOW() ELSE NULL END
      FROM unnest(ARRAY['RESOLVED','REJECTED','CANCELLED']) AS status`,
    [type.id, longitude, latitude]);
    const [reporter] = await runner.query(`INSERT INTO users(full_name,email,password_hash)
      VALUES('Người kiểm thử',$1,'test-only') RETURNING id`, [`${randomUUID()}@test.invalid`]);
    await runner.query(`INSERT INTO incident_reports
      (incident_id,reporter_id,description,reported_location,reported_address)
      VALUES($1,$2,'Phản ánh kiểm thử',ST_SetSRID(ST_MakePoint($3,$4),4326)::geography,'Địa chỉ kiểm thử')`,
    [ids[0], reporter.id, longitude, latitude]);
    await runner.query(`INSERT INTO incident_media
      (incident_id,uploaded_by,media_type,storage_key,file_url,mime_type,file_size)
      VALUES($1,$2,'IMAGE',$3,'https://example.invalid/scene.jpg','image/jpeg',100)`,
    [ids[0], reporter.id, randomUUID()]);

    const nearby = await service.findNearby(latitude, longitude);
    assert.deepEqual(nearby.map(row => row.id), ids.slice(0, 8));
    assert.equal(nearby[0].distance_m, 0);
    assert.ok(nearby[1].distance_m > 80 && nearby[1].distance_m < 90);
    assert.equal(nearby[0].address, 'Địa chỉ kiểm thử');
    assert.equal(nearby[0].cover_url, 'https://example.invalid/scene.jpg');
    const moved = await service.findNearby(latitude, longitude + 0.009);
    assert.equal(moved[0].id, ids[9]);
    const farAway = await service.findNearby(latitude + 1, longitude);
    assert.equal(farAway.length, 0);
    for (const [lat, lng, radius] of [[NaN, longitude, 10000], [91, longitude, 10000],
      [latitude, 181, 10000], [latitude, longitude, 0], [latitude, longitude, 100001]]) {
      await assert.rejects(service.findNearby(lat, lng, radius), (error: any) => error.statusCode === 400);
    }
  } finally {
    await runner.rollbackTransaction();
    await runner.release();
  }
});

test('GET /incidents/nearby nhận GPS và từ chối tọa độ thiếu/sai', async () => {
  const server = app.listen(0, '127.0.0.1');
  try {
    await new Promise<void>((resolve, reject) => {
      server.once('listening', resolve);
      server.once('error', reject);
    });
    const address = server.address();
    assert.ok(address && typeof address !== 'string');
    const base = `http://127.0.0.1:${address.port}/api/v1/incidents/nearby`;
    for (const query of ['', '?lat=&lng=105', '?lat=abc&lng=105', '?lat=91&lng=105',
      '?lat=21&lng=181', '?lat=21&lng=105&radius_m=-1', '?lat=21&lat=22&lng=105']) {
      const response = await fetch(base + query);
      assert.equal(response.status, 400, query);
    }
    const response = await fetch(base + '?lat=-40&lng=-30');
    assert.equal(response.status, 200);
    const body = await response.json() as { data: unknown[]; radius_m: number };
    assert.ok(Array.isArray(body.data));
    assert.equal(body.radius_m, 10000);
  } finally {
    await new Promise<void>((resolve, reject) => server.close(error => error ? reject(error) : resolve()));
  }
});
