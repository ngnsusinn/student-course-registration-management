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

const sp = (await q(`SELECT
  (SELECT ROUTINE_DEFINITION LIKE '%proc_dirty_writer%'    FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_NAME='SP_DangKyHocPhan')      AS DonKy_Writer,
  (SELECT ROUTINE_DEFINITION LIKE '%FOR UPDATE%'           FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_NAME='SP_DangKyHocPhan')      AS DonKy_FU,
  (SELECT ROUTINE_DEFINITION LIKE '%DO SLEEP%'             FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_NAME='SP_DangKyHocPhan')      AS DonKy_Sleep,
  (SELECT ROUTINE_DEFINITION LIKE '%vSiSo1%'               FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_NAME='SP_DangKyNhieuHocPhan') AS Nhieu_Doc2Lan,
  (SELECT ROUTINE_DEFINITION LIKE '%LPAD(vThuTu%'          FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_NAME='SP_DangKyNhieuHocPhan') AS Nhieu_Tick,
  (SELECT ROUTINE_DEFINITION LIKE '%proc_dirty_read_ru%'   FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_NAME='SP_DangKyNhieuHocPhan') AS Nhieu_RU,
  (SELECT ROUTINE_DEFINITION LIKE '%proc_dirty_read_rr%'   FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_NAME='SP_DangKyNhieuHocPhan') AS Nhieu_RR`))[0];

// Suy ra kịch bản demo đang được chuẩn bị (khớp với trang “Chuẩn bị Demo”)
const kichBan = sp.Nhieu_RU || sp.Nhieu_RR || sp.DonKy_Writer
  ? '④ DIRTY READ — sẵn sàng (phiên ĐỌC BẨN @ READ UNCOMMITTED + phiên GHI không commit)'
  : !sp.DonKy_FU
    ? '① LOST UPDATE — sẵn sàng (SP_DangKyHocPhan thiếu FOR UPDATE)'
    : sp.Nhieu_Doc2Lan
      ? '②/③ NRR · PHANTOM — sẵn sàng (SP_DangKyNhieuHocPhan đọc 2 lần @ READ COMMITTED)'
      : sp.Nhieu_Tick
        ? '⑤ DEADLOCK — sẵn sàng (SP_DangKyNhieuHocPhan khóa theo thứ tự tick chọn)'
        : '— không có: cả 2 thủ tục đang là BẢN CHÍNH THỨC';

console.log('\n=== TRẠNG THÁI DEMO ===');
console.log(`  SP_DangKyHocPhan      : ${sp.DonKy_Writer ? '🟡 LAB DIRTY READ (INSERT → SLEEP → ROLLBACK)'
  : sp.DonKy_FU ? '🟢 BẢN THẬT (có FOR UPDATE)' : `🟡 BẢN CHƯA FIX (không FOR UPDATE)${sp.DonKy_Sleep ? ' + DO SLEEP 8s' : ''}`}`);
console.log(`  SP_DangKyNhieuHocPhan : ${sp.Nhieu_RU ? '🟡 LAB ĐỌC BẨN (@ READ UNCOMMITTED)'
  : sp.Nhieu_RR ? '🟢 LAB ĐỐI CHỨNG (@ REPEATABLE READ)'
  : sp.Nhieu_Doc2Lan ? '🟡 LAB NRR/PHANTOM (đọc 2 lần @ READ COMMITTED)'
  : sp.Nhieu_Tick ? '🟡 LAB DEADLOCK (khóa theo thứ tự tick)'
  : '🟢 BẢN THẬT (khóa theo MaLHP tăng dần)'}`);
console.log(`  ⇒ KỊCH BẢN ĐANG SẴN SÀNG: ${kichBan}`);
if (!sp.DonKy_FU && !sp.DonKy_Writer) console.log('     → Khôi phục bản thật: node scripts/apply-sql.js ../mysql/procedures/SP_DangKyHocPhan.sql');

console.table(await q(`SELECT lhp.MaLHP, mh.TenMonHoc, lhp.SiSoHienTai, lhp.SiSoToiDa,
    (lhp.SiSoToiDa - lhp.SiSoHienTai) AS ConTrong,
    (SELECT COUNT(*) FROM DANGKYHOCPHAN d WHERE d.MaLHP=lhp.MaLHP AND d.TrangThaiDangKy='DA_DANG_KY') AS SoDK_ThucTe
  FROM LOPHOCPHAN lhp JOIN MONHOC mh ON mh.MaMonHoc = lhp.MaMonHoc
  WHERE lhp.MaLHP IN ('LHP514','LHP506')`));

console.log('  (LHP514 dùng cho kịch bản trình biên soạn DB · LHP506 dùng cho kịch bản web)');
await c.end();
