// ============================================================
// scripts/verify-db.js — Kiểm tra nhanh CSDL mà backend đang trỏ tới
//   Dùng CHUNG cấu hình với backend (src/config.js) => tự đọc backend/.env
//   (kể cả DB_PORT khi CSDL chạy sau tunnel / cổng khác 3306).
//
//   cd backend && node scripts/verify-db.js
// ============================================================
import mysql from 'mysql2/promise';
import { DB_CONFIG } from '../src/config.js';

const c = await mysql.createConnection({ ...DB_CONFIG, multipleStatements: false });
const q = async (s) => (await c.query(s))[0];

const info = (await q(`SELECT VERSION() AS PhienBan, DATABASE() AS CSDL, CURRENT_USER() AS TaiKhoan,
  @@tx_isolation AS MucCoLap, @@innodb_deadlock_detect AS PhatHienDeadlock,
  @@innodb_lock_wait_timeout AS ChoKhoaToiDa`))[0];
console.log('=== KẾT NỐI ===');
console.log(`  ${DB_CONFIG.host}:${DB_CONFIG.port}  →  ${info.PhienBan}  (db: ${info.CSDL}, user: ${info.TaiKhoan})`);
console.log(`  isolation = ${info.MucCoLap} · deadlock_detect = ${info.PhatHienDeadlock} · lock_wait_timeout = ${info.ChoKhoaToiDa}s`);

const dem = (await q(`SELECT
  (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_TYPE='BASE TABLE') AS SoBang,
  (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_TYPE='VIEW')       AS SoView,
  (SELECT COUNT(*) FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA=DATABASE())                          AS SoSP,
  (SELECT COUNT(*) FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA=DATABASE())                          AS SoTrigger,
  (SELECT COUNT(*) FROM SINHVIEN) AS SoSV,
  (SELECT COUNT(*) FROM DANGKYHOCPHAN) AS SoLuotDK`))[0];
console.log('\n=== ĐỐI TƯỢNG ===');
console.log(`  ${dem.SoBang} bảng · ${dem.SoView} view · ${dem.SoSP} SP/Function · ${dem.SoTrigger} trigger · ${dem.SoSV} SV · ${dem.SoLuotDK} lượt đăng ký`);

const sp = (await q(`SELECT ROUTINE_DEFINITION LIKE '%FOR UPDATE%' AS CoForUpdate,
  ROUTINE_DEFINITION LIKE '%DO SLEEP%' AS CoSleep
  FROM information_schema.ROUTINES
  WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_NAME='SP_DangKyHocPhan'`))[0];
console.log('\n=== TRẠNG THÁI DEMO LOST UPDATE ===');
console.log(`  SP_DangKyHocPhan: ${sp.CoForUpdate ? '✅ ĐÃ FIX (có FOR UPDATE)' : '⚠️ BẢN CHƯA FIX (không có FOR UPDATE)'}${sp.CoSleep ? ' + có DO SLEEP (bản demo web)' : ''}`);
if (!sp.CoForUpdate) console.log('     → Khôi phục bản thật: node scripts/apply-sql.js ../mysql/procedures/SP_DangKyHocPhan.sql');

console.table(await q(`SELECT lhp.MaLHP, mh.TenMonHoc, lhp.SiSoHienTai, lhp.SiSoToiDa,
    (lhp.SiSoToiDa - lhp.SiSoHienTai) AS ConTrong,
    (SELECT COUNT(*) FROM DANGKYHOCPHAN d WHERE d.MaLHP=lhp.MaLHP AND d.TrangThaiDangKy='DA_DANG_KY') AS SoDK_ThucTe
  FROM LOPHOCPHAN lhp JOIN MONHOC mh ON mh.MaMonHoc = lhp.MaMonHoc
  WHERE lhp.MaLHP IN ('LHP514','LHP506')`));

console.log('  (LHP514 dùng cho kịch bản trình biên soạn DB · LHP506 dùng cho kịch bản web)');
await c.end();
