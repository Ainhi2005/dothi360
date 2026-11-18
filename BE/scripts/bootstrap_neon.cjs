// One-time bootstrap: explicit Neon credentials; never reads the local application's DB config.
const fs = require('node:fs');
const path = require('node:path');
const { randomBytes } = require('node:crypto');
const { Client } = require('pg');
const dotenv = require('dotenv');
const argon2 = require('argon2');
const root = path.resolve(__dirname, '..');

async function main() {
  const config = dotenv.parse(fs.readFileSync(path.join(root, '.env.neon.local')));
  const url = new URL(config.DATABASE_URL);
  if (!['postgres:', 'postgresql:'].includes(url.protocol) || !url.hostname.endsWith('.neon.tech')) throw Error('Expected a Neon PostgreSQL URL');
  if (url.hostname.includes('-pooler.')) throw Error('Disable Connection pooling in Neon and save the direct connection URL');
  for (const key of ['sslmode', 'sslcert', 'sslkey', 'sslrootcert', 'uselibpqcompat']) url.searchParams.delete(key);
  const client = new Client({ connectionString: url.toString(), ssl: { rejectUnauthorized: true }, connectionTimeoutMillis: 20000 });
  let transaction = false;
  try {
    await client.connect();
    const info = (await client.query(`SELECT current_database() AS database, current_setting('server_version') AS version,
      (SELECT count(*)::int FROM pg_tables WHERE schemaname='public' AND tablename<>'spatial_ref_sys') AS public_tables`)).rows[0];
    console.log(JSON.stringify({ connected: true, tls_verified: true, ...info }));
    if (!process.argv.includes('--initialize')) return;
    await client.query('BEGIN'); transaction = true;
    await client.query("SELECT pg_advisory_xact_lock(hashtext('dothi360-neon-bootstrap'))");
    const tables = (await client.query("SELECT tablename FROM pg_tables WHERE schemaname='public' AND tablename<>'spatial_ref_sys'")).rows;
    if (tables.length) throw Error('Target database is not empty; no data has been changed');
    let schema = fs.readFileSync(path.join(root, 'src/database/schema.current.sql'), 'utf8');
    schema = schema.replace(/^\\(?:un)?restrict[^\r\n]*$/gm, '')
      .replace(/^COMMENT ON EXTENSION [^;]+;\s*$/gm, '');
    if (/^\\/m.test(schema)) throw Error('Unsupported psql command in snapshot');
    await client.query(schema);
    await client.query('SET search_path TO public');
    const baseline = JSON.parse(fs.readFileSync(path.join(__dirname, 'snapshot-baseline.json'), 'utf8'));
    await client.query('CREATE TABLE public.migrations (id SERIAL PRIMARY KEY, timestamp BIGINT NOT NULL, name VARCHAR NOT NULL)');
    for (const name of baseline) await client.query('INSERT INTO public.migrations(timestamp,name) VALUES($1,$2)', [name.slice(-13), name]);
    const credentialsPath = path.join(root, '.env.demo.local');
    if (process.argv.includes('--demo')) {
      if (fs.existsSync(credentialsPath)) throw Error('Demo credentials file already exists; preserve it and check target before retrying');
      const demoPath = path.join(root, 'scratch/demo-export/DuLieuDemo.sql');
      let demo = fs.readFileSync(demoPath, 'utf8');
      if ((demo.match(/^BEGIN;\s*$/gm) || []).length !== 1 || (demo.match(/^COMMIT;\s*$/gm) || []).length !== 1) throw Error('Unexpected demo transaction structure');
      demo = demo.replace(/^BEGIN;\s*$/gm, '').replace(/^COMMIT;\s*$/gm, '');
      await client.query(demo);
      const password = randomBytes(24).toString('base64url');
      const hash = await argon2.hash(password);
      await client.query('UPDATE public.users SET password_hash=$1, must_change_password=TRUE', [hash]);
      // Save BEFORE commit so a successful commit always has recoverable credentials.
      fs.writeFileSync(credentialsPath, `DEMO_INITIAL_PASSWORD=${password}\nADMIN_EMAIL=admin@dothi360.example\nOFFICER_EMAIL=officer@dothi360.example\nCITIZEN_EMAIL=citizen@dothi360.example\n`, { flag: 'wx', mode: 0o600 });
    }
    const counts = (await client.query(`SELECT
      (SELECT count(*)::int FROM pg_tables WHERE schemaname='public' AND tablename NOT IN ('spatial_ref_sys','migrations')) AS application_tables,
      (SELECT count(*)::int FROM users) AS users,
      (SELECT count(*)::int FROM incidents) AS incidents,
      (SELECT count(*)::int FROM migrations) AS baseline_migrations`)).rows[0];
    if (counts.application_tables !== 23 || counts.baseline_migrations !== baseline.length) throw Error('Unexpected schema counts');
    await client.query('COMMIT'); transaction = false;
    console.log(JSON.stringify({ initialized: true, ...counts, demo_credentials: process.argv.includes('--demo') ? 'BE/.env.demo.local (not committed)' : undefined }));
  } catch (error) {
    if (transaction) await client.query('ROLLBACK').catch(() => {});
    // Never print URLs, SQL bodies or credentials.
    if (['ECONNREFUSED','ENETUNREACH','EACCES','EPERM','ENOTFOUND','ETIMEDOUT'].includes(error.code)) console.error(`Connection error: ${error.code}`);
    else console.error(error.code ? `Database error: ${error.code}` : error.message.replace(/postgres(?:ql)?:\/\/\S+/g, '[redacted]'));
    process.exitCode = 1;
  } finally { await client.end(); }
}
main().catch(() => { console.error('Cannot read Neon configuration; check BE/.env.neon.local'); process.exitCode = 1; });
