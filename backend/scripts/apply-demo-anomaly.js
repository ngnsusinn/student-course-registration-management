// Áp dụng mysql/transactions/demo_4_anomaly.sql lên DB (tự xử lý DELIMITER)
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import 'dotenv/config';
import mysql from 'mysql2/promise';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
// Neu truyen file cu the qua argv -> ap dung file do; nguoc lai ap dung demo_4_anomaly.sql
const SQL_FILE = process.argv[2]
  ? path.resolve(process.cwd(), process.argv[2])
  : path.resolve(__dirname, '..', '..', 'mysql', 'transactions', 'demo_4_anomaly.sql');

// Sao chép logic splitStatements từ scripts/init-db.js (hỗ trợ DELIMITER)
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

const conn = await mysql.createConnection({
  host: process.env.DB_HOST, user: process.env.DB_USER,
  password: process.env.DB_PASSWORD, database: process.env.DB_NAME,
  charset: 'utf8mb4_unicode_ci', connectTimeout: 30000,
});

const sql = fs.readFileSync(SQL_FILE, 'utf8');
const stmts = splitStatements(sql);
console.log(`[apply] ${stmts.length} câu lệnh từ ${path.basename(SQL_FILE)}`);
for (const stmt of stmts) {
  try {
    await conn.query(stmt);
    console.log('[apply] OK:', stmt.replace(/\s+/g, ' ').slice(0, 80));
  } catch (err) {
    console.error('[apply] LOI:', err.message);
    console.error('  Statement:', stmt.replace(/\s+/g, ' ').slice(0, 200));
    await conn.end();
    process.exit(1);
  }
}
await conn.end();
console.log('[apply] Hoan tat.');
