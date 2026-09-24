// ============================================================
// scripts/verify-timezone.js — Kiểm tra múi giờ hiện tại của DB
//   cd backend && node scripts/verify-timezone.js
// ============================================================
import mysql from 'mysql2/promise';
import { DB_CONFIG } from '../src/config.js';

const conn = await mysql.createConnection(DB_CONFIG);
await conn.query("SET time_zone = '+07:00'");   // ← như db.js
const q = async (s) => (await conn.query(s))[0];

console.log('=== MÚA GIỜ ===');
console.table(await q(`
  SELECT
    @@session.time_zone AS SessionTimeZone,
    NOW() AS NowUTC7,
    CONVERT_TZ(NOW(), '+00:00', '+07:00') AS ExpectedUTC7
`));

console.log('\n=== DỮ LIỆU ĐÃ CHỈNH ===');
console.log('-- DANGKYHOCPHAN (5 bản mới nhất) --');
console.table(await q(`
  SELECT MaSV, MaLHP, NgayDangKy FROM DANGKYHOCPHAN
  ORDER BY NgayDangKy DESC LIMIT 5
`));

console.log('-- NHATKY_DOIMATKHAU --');
console.table(await q(`
  SELECT MaTaiKhoan, TenDangNhap, ThoiGianThayDoi FROM NHATKY_DOIMATKHAU
  ORDER BY ThoiGianThayDoi DESC LIMIT 5
`));

console.log('-- YEUCAU_DATLAI_MATKHAU --');
console.table(await q(`
  SELECT * FROM YEUCAU_DATLAI_MATKHAU LIMIT 10
`));

await conn.end();
