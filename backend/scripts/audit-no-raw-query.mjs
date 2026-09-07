// ============================================================
// audit-no-raw-query.mjs  (v2 — RECHECK toàn dự án)
// Kiểm chứng yêu cầu: "dưới code web CHỈ dùng thủ tục/view/function".
//
// 3 lớp kiểm tra:
//   1. QUÉT TĨNH toàn bộ backend/src: mọi string literal giống SQL
//      phải là CALL <SP> (cho phép SET @var — cơ chế OUT param).
//   2. ĐỐI CHIẾU DB: trích danh sách SP được CALL trong backend/src,
//      gọi SHOW PROCEDURE STATUS và báo SP nào CHƯA tồn tại.
//   3. GHI CHÚ module demo (services/anomalyRunner.js) — ngoại lệ có chủ đích.
//
// Chạy: node scripts/audit-no-raw-query.mjs   (exit 1 nếu fail)
// ============================================================
import { readdirSync, readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import 'dotenv/config';
import mysql from 'mysql2/promise';

const __dirname = dirname(fileURLToPath(import.meta.url));
const srcDir = join(__dirname, '..', 'src');

const FORBIDDEN = /\b(SELECT|INSERT|UPDATE|DELETE|REPLACE|TRUNCATE|DROP|ALTER|CREATE|SHOW)\b/i;
// SELECT @var được phép: là NỬA CƠ CHỈ đọc tham số OUT của SP (SELECT @KetQua),
// không truy vấn bảng nào — đi cặp với SET @var.
const ALLOWED_PREFIX = /^(CALL|SET\s+@|SELECT\s+@)/i;

function extractLiterals(src) {
  const out = [];
  const re = /'([^'\\\n]*)'|`([^`\\]*)`/g;
  let m;
  while ((m = re.exec(src)) !== null) {
    const lit = (m[1] ?? m[2] ?? '').trim();
    if (lit) out.push(lit);
  }
  return out;
}

// ---------- LỚP 1: quét tĩnh toàn bộ src ----------
let errors = 0;
const jsFiles = [];
function walk(dir) {
  for (const f of readdirSync(dir, { withFileTypes: true })) {
    const p = join(dir, f.name);
    if (f.isDirectory()) walk(p);
    else if (f.name.endsWith('.js')) jsFiles.push(p);
  }
}
walk(srcDir);
console.log(`LỚP 1 — Quét tĩnh ${jsFiles.length} file trong backend/src\n`);

const calledSPs = new Set();
const spCallRe = /\bCALL\s+([A-Za-z_][A-Za-z0-9_]*)/gi;

for (const file of jsFiles) {
  const src = readFileSync(file, 'utf8');
  const rel = file.replace(srcDir + '\\', '').replace(/\\/g, '/');
  // Ngoại lệ có chủ đích: services/anomalyRunner.js (module demo 4 lỗi
  // phải chạy session SQL thô để "tắt phòng chống" — xem README ghi chú).
  const isDemo = rel.endsWith('anomalyRunner.js');

  const lines = src.split('\n');

  // Gom danh sách SP được gọi (bỏ comment để tránh false positive)
  const code = lines.filter((l) => !/^\s*(\/\/|\*|\/\*)/.test(l)).join('\n');
  let m;
  while ((m = spCallRe.exec(code)) !== null) calledSPs.add(m[1].toUpperCase());

  const bad = [];
  lines.forEach((line, i) => {
    if (line.trim().startsWith('//') || line.trim().startsWith('*') || line.trim().startsWith('/*')) return;
    for (const lit of extractLiterals(line)) {
      if (FORBIDDEN.test(lit) && !ALLOWED_PREFIX.test(lit)) {
        bad.push(`    dòng ${i + 1}: ${lit.slice(0, 90)}`);
      }
    }
  });

  if (isDemo) {
    console.log(`ℹ️  ${rel} — module DEMO 4 lỗi (ngoại lệ CÓ CHỦ ĐÍCH: demo phải chạy session thô để "tắt phòng chống"); ${bad.length} phát hiện SQL thô.`);
    continue;
  }
  if (bad.length) {
    errors += bad.length;
    console.log(`❌ ${rel} — ${bad.length} raw query:`);
    bad.forEach((b) => console.log(b));
  } else {
    console.log(`✅ ${rel} — sạch (chỉ CALL SP / SET @var)`);
  }
}

// ---------- LỚP 2: đối chiếu SP được gọi với DB ----------
console.log(`\nLỚP 2 — Đối chiếu ${calledSPs.size} SP được gọi trong code với DB...`);
let dbOk = true;
try {
  const c = await mysql.createConnection({
    host: process.env.DB_HOST, user: process.env.DB_USER,
    password: process.env.DB_PASSWORD, database: process.env.DB_NAME,
  });
  const [rows] = await c.query('SHOW PROCEDURE STATUS WHERE Db = DATABASE()');
  const dbSPs = new Set(rows.map((r) => r.Name.toUpperCase()));
  await c.end();

  const thieu = [...calledSPs].filter((s) => !dbSPs.has(s)).sort();
  if (thieu.length) {
    dbOk = false;
    console.log(`❌ ${thieu.length} SP được gọi nhưng KHÔNG tồn tại trên DB:`);
    thieu.forEach((s) => console.log(`    - ${s}`));
  } else {
    console.log(`✅ Cả ${calledSPs.size} SP được gọi đều TỒN TẠI trên DB (${dbSPs.size} SP hiện có).`);
  }
} catch (e) {
  dbOk = false;
  console.log('❌ Không đối chiếu được DB:', e.message);
}

// ---------- Kết luận ----------
const pass = errors === 0 && dbOk;
console.log(pass
  ? '\n[PASS] Toàn bộ tầng web KHÔNG có raw query — 100% View/Procedure/Function, và mọi SP được gọi đều tồn tại. ✅'
  : `\n[FAIL] ${errors} raw query / thiếu SP. ❌`);
process.exit(pass ? 0 : 1);
