import 'dotenv/config';
import mysql from 'mysql2/promise';
import { DB_CONFIG } from '../src/config.js';

// ============================================================
// scripts/fix-timezone-utc7.js
// Chuyển toàn bộ dữ liệu DATETIME trong DB từ UTC → UTC+7
// Chạy: cd backend && node scripts/fix-timezone-utc7.js
// ============================================================

const conn = await mysql.createConnection({
  ...DB_CONFIG,
  timezone: '+07:00',
});

console.log('=== CHUYỂN MÙA GIỜ UTC → UTC+7 ===\n');

const tables = [
  { table: 'DANGKYHOCPHAN',    column: 'NgayDangKy',       nullable: false },
  { table: 'NHATKY_DOIMATKHAU', column: 'ThoiGianThayDoi',  nullable: false },
  { table: 'YEUCAU_DATLAI_MATKHAU', column: 'NgayGui',     nullable: false },
  { table: 'YEUCAU_DATLAI_MATKHAU', column: 'NgayXuLy',    nullable: true  },
];

for (const { table, column, nullable } of tables) {
  const before = (await conn.query(
    `SELECT COUNT(*) AS total, MIN(${column}) AS minVal, MAX(${column}) AS maxVal FROM ${table}`
  ))[0][0];

  await conn.query(
    `UPDATE ${table} SET ${column} = ${column} + INTERVAL 7 HOUR${nullable ? '' : ' WHERE ' + column + ' IS NOT NULL'}`
  );

  const after = (await conn.query(
    `SELECT COUNT(*) AS total, MIN(${column}) AS minVal, MAX(${column}) AS maxVal FROM ${table}`
  ))[0][0];

  console.log(`${table}.${column}:`);
  console.log(`  Trước: ${before.minVal} → ${before.maxVal} (${before.total} dòng)`);
  console.log(`  Sau:   ${after.minVal} → ${after.maxVal} (${after.total} dòng)`);
  console.log();
}

console.log('✅ Hoàn tất! Thêm 7 giờ vào tất cả cột DATETIME.');
await conn.end();
