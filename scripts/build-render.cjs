const path = require('node:path');
const fs = require('node:fs');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '..');
const npm = process.platform === 'win32' ? 'npm.cmd' : 'npm';
function run(directory, args, extraEnv = {}) {
  const result = spawnSync(npm, args, { cwd: path.join(root, directory), env: { ...process.env, ...extraEnv },
    stdio: 'inherit', shell: process.platform === 'win32' });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
}
for (const directory of ['BE', 'Admin_FE']) {
  if (!process.argv.includes('--skip-install')) run(directory, ['ci', '--include=dev']);
  run(directory, ['run', 'build'], directory === 'Admin_FE' ? { VITE_API_URL: '/api/v1' } : {});
}
const backend = path.join(root, 'BE');
const destination = path.resolve(backend, 'admin-public');
if (path.relative(backend, destination) !== 'admin-public') throw new Error('Invalid generated Admin directory');
if (fs.existsSync(destination)) fs.rmSync(destination, { recursive: true });
fs.cpSync(path.join(root, 'Admin_FE', 'dist'), destination, { recursive: true });
console.log('Build deploy thành công: API + Admin cùng origin.');
