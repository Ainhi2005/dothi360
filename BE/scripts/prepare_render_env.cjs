// Generate an ignored file for Render's "Add from .env" UI. Never prints secrets.
const fs = require('node:fs');
const path = require('node:path');
const { randomBytes } = require('node:crypto');
const dotenv = require('dotenv');
const root = path.resolve(__dirname, '..');
const local = dotenv.parse(fs.readFileSync(path.join(root, '.env')));
const neon = dotenv.parse(fs.readFileSync(path.join(root, '.env.neon.local')));
const firebasePath = path.join(root, 'scratch/firebase-admin.json');
if (!local.FIREBASE_SERVICE_ACCOUNT_BASE64 && fs.existsSync(firebasePath)) {
  const raw = fs.readFileSync(firebasePath, 'utf8');
  const account = JSON.parse(raw);
  if (account.type !== 'service_account' || !account.private_key || !account.client_email || !account.project_id) throw Error('Invalid Firebase service account');
  const mobile = JSON.parse(fs.readFileSync(path.join(root, '../FE/android/app/google-services.json'), 'utf8'));
  if (account.project_id !== mobile.project_info.project_id) throw Error('Firebase project does not match the mobile application');
  local.FIREBASE_SERVICE_ACCOUNT_BASE64 = Buffer.from(raw).toString('base64');
}
const target = path.join(root, '.env.render.local');
const existing = fs.existsSync(target) ? dotenv.parse(fs.readFileSync(target)) : {};
const required = ['CLOUDINARY_CLOUD_NAME', 'CLOUDINARY_API_KEY', 'CLOUDINARY_API_SECRET', 'GEMINI_API_KEY', 'FIREBASE_SERVICE_ACCOUNT_BASE64'];
const missing = required.filter(key => !local[key]);
if (missing.length || !neon.DATABASE_URL) {
  console.error('Missing configuration keys:', [...missing, ...(!neon.DATABASE_URL ? ['DATABASE_URL'] : [])].join(', '));
  process.exit(1);
}
const config = {
  NODE_VERSION: '24.14.0', NODE_ENV: 'production', SERVE_ADMIN: 'true', DB_SSL: 'true', DATABASE_URL: neon.DATABASE_URL,
  CORS_ORIGINS: '',
  JWT_ACCESS_SECRET: existing.JWT_ACCESS_SECRET || randomBytes(48).toString('base64url'),
  JWT_REFRESH_SECRET: existing.JWT_REFRESH_SECRET || randomBytes(48).toString('base64url'),
};
for (const key of [...required, 'CLOUDINARY_FOLDER', 'GEMINI_MODEL', 'GEMINI_FALLBACK_MODELS', 'AI_ALLOWED_MEDIA_HOSTS', 'GEOCODING_BASE_URL']) {
  if (local[key]) config[key] = local[key];
}
const quote = value => {
  if (/[\r\n]/.test(value)) throw Error('Use single-line environment values');
  if (!value.includes("'")) return `'${value}'`;
  if (!/["\\]/.test(value)) return `"${value}"`;
  throw Error('Unsupported environment quoting; enter this value directly in Render');
};
const contents = Object.entries(config).map(([key, value]) => `${key}=${quote(value)}`).join('\n') + '\n';
const parsed = dotenv.parse(contents);
for (const [key, value] of Object.entries(config)) if (parsed[key] !== value) throw Error('Environment round-trip failed');
fs.writeFileSync(target, contents, { mode: 0o600 });
console.log('Prepared BE/.env.render.local; local BE/.env unchanged; secret values are not displayed.');
