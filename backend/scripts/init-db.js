import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import mysql from 'mysql2/promise';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const MYSQL_DIR = path.resolve(__dirname, '..', '..', 'mysql');

const FILES = [
  'ddl/00_danh_muc_hoso_sv_ddl.sql',
  'ddl/00_hocphan_giangvien_ddl.sql',
  'ddl/10_dangky_hocphan_ddl.sql',
  'ddl/00_diem_ketqua_ddl.sql',
  'ddl/00_hocphi_taikhoan_ddl.sql',
  'data/00_danh_muc_hoso_sv_data.sql',
  'data/00_hocphan_giangvien_data.sql',
  'data/dangky_hocphan_data.sql',
  'data/00_diem_ketqua_data.sql',
  'data/00_hocphi_taikhoan_data.sql',
  'functions/FN_KiemTra_DangKy.sql',
  'procedures/SP_DangKyHocPhan.sql',
  'procedures/SP_HuyDangKy.sql',
  'procedures/hocphi_taikhoan_procedures.sql',
  'procedures/sp_gpa.sql',
  'procedures/hocphan_giangvien_procedures.sql',
  'procedures/ThemSV_Chuyen_Lop.sql',
  'triggers/TRG_DANGKYHOCPHAN_SiSo.sql',
  'triggers/TRG_KETQUAHOCTAP_TinhDiem.sql',
  'triggers/TRG_LICHHOC_KiemTraTrungLich.sql',
  'triggers/TRG_LogDoiMatKhau.sql',
  'triggers/Xoa_Nganh_Trigger.sql',
  'views/dangky_hocphan_views.sql',
  'views/diem_ketqua_views.sql',
  'views/hocphi_views.sql',
  'views/danh_muc_hoso_sv_views.sql',
  'indexes/all_indexes.sql',
];

// Tach cac cau lenh SQL co hon tro trong chuoi, comment va DELIMITER
function splitStatements(sql) {
  const statements = [];
  let delimiter = ';';
  let buf = '';
  let i = 0;
  const n = sql.length;

  while (i < n) {
    const ch = sql[i];

    if (ch === '-' && sql[i + 1] === '-') {
      while (i < n && sql[i] !== '\n') i++;
      continue;
    }
    if (ch === '#') {
      while (i < n && sql[i] !== '\n') i++;
      continue;
    }
    if (ch === '/' && sql[i + 1] === '*') {
      i += 2;
      while (i < n && !(sql[i] === '*' && sql[i + 1] === '/')) i++;
      i += 2;
      continue;
    }
    if (ch === "'" || ch === '"' || ch === '`') {
      const quote = ch;
      buf += ch;
      i++;
      while (i < n) {
        buf += sql[i];
        if (sql[i] === '\\') {
          i++;
          if (i < n) { buf += sql[i]; i++; }
          continue;
        }
        if (sql[i] === quote) {
          if (sql[i + 1] === quote) { buf += sql[i + 1]; i += 2; continue; }
          i++;
          break;
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
        buf = '';
        delimiter = m[1];
        i += 9 + m[0].length;
        while (i < n && (sql[i] === '\n' || sql[i] === '\r')) i++;
        continue;
      }
    }

    if (sql.slice(i, i + delimiter.length) === delimiter) {
      const stmt = buf.trim();
      if (stmt) statements.push(stmt);
      buf = '';
      i += delimiter.length;
      continue;
    }

    buf += ch;
    i++;
  }

  const tail = buf.trim();
  if (tail) statements.push(tail);
  return statements;
}

async function main() {
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST || 'free02.123host.vn',
    user: process.env.DB_USER || 'roacqgfa_dbms',
    password: process.env.DB_PASSWORD || 'roacqgfa_dbms1',
    database: process.env.DB_NAME || 'roacqgfa_dbms',
    charset: 'utf8mb4_unicode_ci',
    multipleStatements: false,
    connectTimeout: 30000,
  });

  await conn.query("SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci");
  console.log('[init-db] Ket noi MySQL thanh cong.');

  for (const rel of FILES) {
    const full = path.join(MYSQL_DIR, rel);
    const sql = fs.readFileSync(full, 'utf8');
    const stmts = splitStatements(sql);
    let count = 0;
    for (const stmt of stmts) {
      try {
        await conn.query(stmt);
        count++;
      } catch (err) {
        console.error(`[init-db] LOI trong ${rel}:`);
        console.error('  ', err.message);
        console.error('  Statement:', stmt.slice(0, 300).replace(/\s+/g, ' '));
        await conn.end();
        process.exit(1);
      }
    }
    console.log(`[init-db] OK ${rel} (${count} cau lenh)`);
  }

  const [[{ SoBang }]] = await conn.query(
    "SELECT COUNT(*) AS SoBang FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = DATABASE()"
  );
  const [[dk]] = await conn.query('SELECT COUNT(*) AS n FROM DANGKYHOCPHAN');
  const [[sv]] = await conn.query('SELECT COUNT(DISTINCT MaSV) AS n FROM DANGKYHOCPHAN');
  console.log(`[init-db] HOAN TAT: ${SoBang} bang, ${dk.n} ban ghi dang ky, ${sv.n} sinh vien da dang ky.`);
  await conn.end();
}

main().catch((e) => {
  console.error('[init-db] LOI:', e.message);
  process.exit(1);
});
