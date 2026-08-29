// Final smoke test: verify all pages reference only existing JS/CSS assets
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const WEB = path.resolve(__dirname, '..', '..', 'web');

const htmlFiles = [];
function walk(dir) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) walk(full);
    else if (e.name.endsWith('.html')) htmlFiles.push(full);
  }
}
walk(WEB);

let issues = 0;
for (const f of htmlFiles) {
  const content = fs.readFileSync(f, 'utf8');
  // Check referenced local assets exist
  const refs = [...content.matchAll(/(?:src|href)="([^"]+)"/g)].map(m => m[1]);
  for (const ref of refs) {
    if (/^(https?:|#|javascript:|mailto:)/.test(ref)) continue;
    if (ref.includes('favicon')) continue;
    const clean = ref.split('?')[0].split('#')[0];
    // Duong dan tuy doi (/js/...) -> tinh goc la thu muc web/
    const target = clean.startsWith('/')
      ? path.join(WEB, clean)
      : path.resolve(path.dirname(f), clean);
    if (!fs.existsSync(target)) {
      console.log(`❌ ${path.relative(WEB, f)} -> missing asset: ${ref}`);
      issues++;
    }
  }
  // Check for leftover mock references
  if (content.includes('mock-data') || content.includes('MOCK.')) {
    console.log(`⚠️ ${path.relative(WEB, f)} still references mock data`);
  }
}
console.log(`\nChecked ${htmlFiles.length} HTML files, ${issues} missing assets.`);
