import assert from 'node:assert/strict';
import test from 'node:test';
import { databaseConnection } from './database-connection';

test('local DB_* keeps the original non-SSL connection', () => {
  assert.deepEqual(databaseConnection({ DB_HOST: 'localhost', DB_PORT: 5432,
    DB_USER: 'demo', DB_PASSWORD: 'local-password', DB_NAME: 'demo' }), {
    host: 'localhost', port: 5432, username: 'demo', password: 'local-password', database: 'demo', ssl: false,
  });
});

test('Neon URL overrides local fields and enforces certificate verification', () => {
  const result = databaseConnection({ DATABASE_URL: 'postgresql://demo:p%40ss@db.example/demo?sslmode=require&sslrootcert=unused&channel_binding=require',
    DB_HOST: 'localhost', DB_NAME: 'local', DB_SSL: 'true' });
  assert.deepEqual(result.ssl, { rejectUnauthorized: true });
  assert.equal(result.host, undefined);
  const url = new URL(result.url!);
  assert.equal(url.hostname, 'db.example');
  assert.equal(url.password, 'p%40ss');
  assert.equal(url.searchParams.has('sslmode'), false);
  assert.equal(url.searchParams.has('sslrootcert'), false);
  assert.equal(url.searchParams.get('channel_binding'), 'require');
});

test('URL connections default to verified SSL; local URL can explicitly opt out', () => {
  const DATABASE_URL = 'postgres://demo:password@localhost:5432/demo';
  assert.deepEqual(databaseConnection({ DATABASE_URL }).ssl, { rejectUnauthorized: true });
  assert.equal(databaseConnection({ DATABASE_URL, DB_SSL: 'false' }).ssl, false);
  assert.throws(() => databaseConnection({ DATABASE_URL: 'https://db.example/demo' }));
});
