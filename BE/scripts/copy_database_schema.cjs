const fs = require('node:fs');
fs.mkdirSync('dist/database', { recursive: true });
let copied = false;
for (const filename of ['schema.sql', 'schema.current.sql']) {
  if (fs.existsSync(`src/database/${filename}`)) {
    fs.copyFileSync(`src/database/${filename}`, `dist/database/${filename}`);
    copied = true;
  }
}
if (!copied) throw new Error('No database schema file found');
