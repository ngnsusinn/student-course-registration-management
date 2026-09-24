// ============================================================
// prepare/sqlRunner.js — ⚠️ CÔNG CỤ DEMO (không phải nghiệp vụ)
//
//   Áp 1 file .sql lên CSDL (hỗ trợ DELIMITER) — dùng cho 2 nút
//   1-click ở trang “Chuẩn bị Demo”.
//
//   Cách làm giống hệt backend/scripts/apply-sql.js (đã dùng để triển
//   khai demo bằng dòng lệnh) — chỉ khác là chạy từ trong server.
//
//   ⚠️ CHỈ cho phép các file trong DANH SACH_CHO_PHEP (chống path traversal).
// ============================================================
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import mysql from 'mysql2/promise';
import { DB_CONFIG } from '../config.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..', '..', '..');   // thư mục gốc repo

// Whitelist: khoá = mã dùng ở API, giá trị = đường dẫn tương đối từ gốc repo
export const DANH_SACH_CHO_PHEP = {
  // — Mỗi kịch bản demo một bộ file riêng (xem prepare.controller.js → KICH_BAN) —
  'lost_update_chua_fix': 'demo/sql_config/lost_update__chua_fix.sql',
  'lab_nrr_phantom_chua_fix': 'demo/sql_config/lab__dangky_nhieu__chua_fix.sql',
  'deadlock_chua_fix': 'demo/sql_config/deadlock__chua_fix.sql',
  // Dirty Read: phiên GHI (INSERT → SLEEP → ROLLBACK) + phiên ĐỌC (2 mức cô lập)
  'lab_dirty_writer_chua_fix': 'demo/sql_config/lab__dirty_read__writer__chua_fix.sql',
  'lab_dirty_reader_chua_fix': 'demo/sql_config/lab__dirty_read__reader__chua_fix.sql',
  'lab_dirty_reader_da_fix': 'demo/sql_config/lab__dirty_read__reader__da_fix.sql',
  // — Bản chính thức của hệ thống (nút FIX + các kịch bản cần 1 thủ tục "sạch") —
  'sp_dangky_that': 'mysql/procedures/SP_DangKyHocPhan.sql',
  'sp_dangky_nhieu_that': 'mysql/procedures/SP_DangKyNhieuHocPhan.sql',
};

// Tách câu lệnh SQL có hỗ trợ DELIMITER (giống scripts/apply-sql.js)
function splitStatements(sql) {
  const statements = [];
  let delimiter = ';';
  let buf = '';
  let i = 0;
  const n = sql.length;
  while (i < n) {
    const ch = sql[i];
    if (ch === '-' && sql[i + 1] === '-') { while (i < n && sql[i] !== '\n') i++; continue; }
    if (ch === '#') { while (i < n && sql[i] !== '\n') i++; continue; }
    if (ch === '/' && sql[i + 1] === '*') { i += 2; while (i < n && !(sql[i] === '*' && sql[i + 1] === '/')) i++; i += 2; continue; }
    if (ch === "'" || ch === '"' || ch === '`') {
      const quote = ch; buf += ch; i++;
      while (i < n) {
        buf += sql[i];
        if (sql[i] === '\\') { i++; if (i < n) { buf += sql[i]; i++; } continue; }
        if (sql[i] === quote) {
          if (sql[i + 1] === quote) { buf += sql[i + 1]; i += 2; continue; }
          i++; break;
        }
        i++;
      }
      continue;
    }
    if (sql.slice(i, i + 9).toUpperCase() === 'DELIMITER') {
      const rest = sql.slice(i + 9);
      const m = rest.match(/^\s*(\S+)/);
      if (m) {
        const stmt = buf.trim();
        if (stmt) statements.push(stmt);
        buf = ''; delimiter = m[1]; i += 9 + m[0].length;
        while (i < n && (sql[i] === '\n' || sql[i] === '\r')) i++;
        continue;
      }
    }
    if (sql.slice(i, i + delimiter.length) === delimiter) {
      const stmt = buf.trim();
      if (stmt) statements.push(stmt);
      buf = ''; i += delimiter.length; continue;
    }
    buf += ch; i++;
  }
  const tail = buf.trim();
  if (tail) statements.push(tail);
  return statements;
}

// Áp 1 file trong whitelist lên CSDL. Trả về nhật ký từng câu lệnh.
export async function apFileSql(ma) {
  const rel = DANH_SACH_CHO_PHEP[ma];
  if (!rel) throw new Error(`File SQL không nằm trong danh sách cho phép: ${ma}`);

  const full = path.join(ROOT, rel);
  if (!fs.existsSync(full)) throw new Error(`Không tìm thấy file: ${rel}`);

  const sql = fs.readFileSync(full, 'utf8');
  const stmts = splitStatements(sql);
  const conn = await mysql.createConnection({
    host: DB_CONFIG.host, port: DB_CONFIG.port, user: DB_CONFIG.user,
    password: DB_CONFIG.password, database: DB_CONFIG.database,
    charset: DB_CONFIG.charset, dateStrings: true, connectTimeout: 30000,
  });
  await conn.query("SET time_zone = '+07:00'");  // ← đảm bảo múi giờ UTC+7
  const nhat_ky = [];
  try {
    for (const stmt of stmts) {
      await conn.query(stmt);
      nhat_ky.push(stmt.replace(/\s+/g, ' ').slice(0, 90));
    }
  } finally {
    await conn.end();
  }
  return { file: rel, soCauLenh: stmts.length, nhat_ky };
}
