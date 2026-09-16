// ==========================================================
// Ten file : backend/scripts/demo-lost-update.js
// Muc dich : Chay THAT kich ban "Loi mat du lieu cap nhat (Lost Update)"
//            tren MySQL remote bang 2 KET NOI THAT (gia lap 2 cua so SQL),
//            in ra man hinh 1 ban ghi ro rang de CHUP ANH minh chung
//            (Hinh 3 — Chuong 4, muc 4.1 cua bao cao).
//
//   PANEL 1 — BAN CHUA FIX  : 2 phien cung doc "con 1 cho" (LHP514 15/16)
//                             roi cung INSERT  -> 17 luot DK > 16 cho
//   PANEL 2 — BAN DA FIX    : 2 phien cung gianh cho cuoi qua
//                             SP_DangKyHocPhan (co SELECT ... FOR UPDATE)
//                             -> 1 phien 0 (thang), 1 phien 105 (lop da day)
//
// Cach chay:
//   cd backend
//   node scripts/demo-lost-update.js          # sleep 10s nhu trong bao cao
//   node scripts/demo-lost-update.js 5        # sleep 5s cho nhanh
//
// Luu y: script TU DON DEP bang SP_ChuanBi_Demo_4Anomaly o cuoi -> du lieu
//        tro ve dung trang thai ban dau (LHP514 = 15/16, LHP506 = 1/2).
// ==========================================================
import mysql from 'mysql2/promise';
import { DB_CONFIG } from '../src/config.js';

const SLEEP_GIAY = Number(process.argv[2] ?? 10);

const CFG = {
  host: DB_CONFIG.host,
  port: DB_CONFIG.port,
  user: DB_CONFIG.user,
  password: DB_CONFIG.password,
  database: DB_CONFIG.database,
  charset: DB_CONFIG.charset,
  dateStrings: true,
  connectTimeout: 30000,
};

const LINE = '='.repeat(96);
const THIN = '-'.repeat(96);

const t0 = Date.now();
const ts = () => '+' + ((Date.now() - t0) / 1000).toFixed(2).padStart(6, ' ') + 's';
const log = (who, sql, ketQua) =>
  console.log(`${ts()}  ${who.padEnd(16)}| ${sql}${ketQua ? '\n' + ' '.repeat(27) + '-> ' + ketQua : ''}`);

const A = await mysql.createConnection(CFG);
const B = await mysql.createConnection(CFG);
const q = async (c, s) => (await c.query(s))[0];
const ngu = (ms) => new Promise((r) => setTimeout(r, ms));

async function trangThai(c, maLHP, nhan) {
  const r = (await q(c, `SELECT lhp.SiSoHienTai, lhp.SiSoToiDa,
      (SELECT COUNT(*) FROM DANGKYHOCPHAN d
        WHERE d.MaLHP = lhp.MaLHP AND d.TrangThaiDangKy = 'DA_DANG_KY') AS SoDK_ThucTe
    FROM LOPHOCPHAN lhp WHERE lhp.MaLHP = '${maLHP}'`))[0];
  console.log(`        ${nhan.padEnd(22)} ${maLHP}: SiSoHienTai = ${r.SiSoHienTai}/${r.SiSoToiDa}` +
              `   |   COUNT(*) dang ky that = ${r.SoDK_ThucTe}`);
  return r;
}

const env = (await q(A, `SELECT VERSION() AS v, @@transaction_isolation AS iso,
  @@innodb_deadlock_detect AS dd, @@innodb_lock_wait_timeout AS lwt`))[0];

console.log('\n' + LINE);
console.log(' MINH CHUNG DEMO — LỖI MẤT DỮ LIỆU CẬP NHẬT (LOST UPDATE) — Chương 4, mục 4.1');
console.log(` HQTCSDL: ${env.v} (InnoDB) · isolation = ${env.iso} · deadlock_detect = ${env.dd} · lock_wait_timeout = ${env.lwt}s`);
console.log(` Hai kết nối thật (connection id ${A.threadId} = CỬA SỔ 1, ${B.threadId} = CỬA SỔ 2)`);
console.log(LINE);

// ============================================================================
console.log('\n■ BƯỚC 0 — CHUẨN BỊ: đưa LHP514 về trạng thái "còn đúng 1 chỗ"');
console.log('  CALL SP_ChuanBi_Demo_4Anomaly(\'LHP514\');');
await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP514')`);
await trangThai(A, 'LHP514', 'Trạng thái ban đầu:');

// ============================================================================
console.log('\n' + LINE);
console.log(' PANEL 1 — BẢN CHƯA FIX: hai phiên cùng đọc "còn 1 chỗ" rồi cùng ghi');
console.log('           (thiếu SELECT ... FOR UPDATE ở bước kiểm tra sĩ số)');
console.log(LINE);

await q(A, 'START TRANSACTION');
log('CỬA SỔ 1 (SV030)', 'START TRANSACTION;');
const r1 = (await q(A, `SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP='LHP514'`))[0];
log('CỬA SỔ 1 (SV030)', `SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP='LHP514';`,
    `${r1.SiSoHienTai}, ${r1.SiSoToiDa}   (đọc KHÔNG khóa → thấy còn 1 chỗ)`);

const phienB = (async () => {
  await ngu(1200);
  await q(B, 'START TRANSACTION');
  log('CỬA SỔ 2 (SV041)', 'START TRANSACTION;');
  const r2 = (await q(B, `SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP='LHP514'`))[0];
  log('CỬA SỔ 2 (SV041)', `SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP='LHP514';`,
      `${r2.SiSoHienTai}, ${r2.SiSoToiDa}   (CŨNG thấy còn 1 chỗ → tưởng mình là người cuối cùng)`);
  const dangChay = B.query(`INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
      VALUES ('SV041','LHP514',NOW(),'DA_DANG_KY','Phien B - chua fix')`);
  log('CỬA SỔ 2 (SV041)', `INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, ...) VALUES ('SV041','LHP514', ...);`,
      '... ĐANG CHỜ KHÓA của CỬA SỔ 1');
  await dangChay;
  await q(B, 'COMMIT');
  log('CỬA SỔ 2 (SV041)', 'COMMIT;', 'được đi tiếp → trigger +1 sĩ số');
})();

log('CỬA SỔ 1 (SV030)', `DO SLEEP(${SLEEP_GIAY});`, `⏸ giữ phiên ${SLEEP_GIAY} giây cho cửa sổ 2 chạy xen vào`);
await ngu(SLEEP_GIAY * 1000);
await q(A, `INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
    VALUES ('SV030','LHP514',NOW(),'DA_DANG_KY','Phien A - chua fix')`);
log('CỬA SỔ 1 (SV030)', `INSERT INTO DANGKYHOCPHAN (...) VALUES ('SV030','LHP514', ...);`,
    'OK (chưa COMMIT — đang giữ khóa)');
await q(A, 'COMMIT');
log('CỬA SỔ 1 (SV030)', 'COMMIT;', 'sĩ số 15 → 16');
await phienB;

console.log('\n  ▸ CÂU KIỂM TRA (cửa sổ bất kỳ):');
console.log('    SELECT COUNT(*) AS SoDK_ThucTe, (SELECT SiSoHienTai FROM LOPHOCPHAN');
console.log("      WHERE MaLHP='LHP514') AS BoDem_SiSo, (SELECT SiSoToiDa FROM LOPHOCPHAN");
console.log("      WHERE MaLHP='LHP514') AS SiSoToiDa FROM DANGKYHOCPHAN");
console.log("      WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';");
const sai = await trangThai(A, 'LHP514', 'KẾT QUẢ SAI:');
console.log(`\n  ✗ ${sai.SoDK_ThucTe} lượt đăng ký thật > ${sai.SiSoToiDa} chỗ  →  VƯỢT SĨ SỐ (Lost Update)`);
console.log(`  ✗ Bộ đếm SiSoHienTai kẹt ở ${sai.SiSoHienTai} vì trigger dùng LEAST(SiSoToiDa, SiSo+1)`);
console.log('     → lỗi hỏng ÂM THẦM: nhìn cột sĩ số vẫn "hợp lệ", chỉ COUNT(*) mới lộ ra.');

// ============================================================================
console.log('\n' + LINE);
console.log(' PANEL 2 — BẢN ĐÃ FIX: SP_DangKyHocPhan có SELECT ... FOR UPDATE');
console.log('           (khoá đúng dòng sĩ số tới khi COMMIT → không thể Lost Update)');
console.log(LINE);

await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP514')`);
await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP506')`);
console.log('\n  Hai sinh viên SV030 và SV041 cùng giành SUẤT CUỐI của lớp LHP506:');
await trangThai(A, 'LHP506', 'Trạng thái ban đầu:');

console.log('');
log('CỬA SỔ 1 (SV030)', `CALL SP_DangKyHocPhan('SV030','LHP506',24,'Phien A - da fix', @kqA);`);
const pA = q(A, `CALL SP_DangKyHocPhan('SV030','LHP506',24,'Phien A - da fix', @kqA)`)
  .then(() => q(A, 'SELECT @kqA AS k'));
const pB = (async () => {
  await ngu(120);
  log('CỬA SỔ 2 (SV041)', `CALL SP_DangKyHocPhan('SV041','LHP506',24,'Phien B - da fix', @kqB);`,
      '... ĐANG CHỜ KHÓA dòng sĩ số của CỬA SỔ 1');
  return q(B, `CALL SP_DangKyHocPhan('SV041','LHP506',24,'Phien B - da fix', @kqB)`)
    .then(() => q(B, 'SELECT @kqB AS k'));
})();
const [kqA, kqB] = await Promise.all([pA, pB]);
log('CỬA SỔ 1 (SV030)', 'SELECT @kqA;', `${kqA[0].k}   → 0 = ĐĂNG KÝ THÀNH CÔNG (lấy được suất cuối)`);
log('CỬA SỔ 2 (SV041)', 'SELECT @kqB;', `${kqB[0].k}   → 105 = LỚP ĐÃ ĐẦY SĨ SỐ (bị từ chối đúng)`);
const dung = await trangThai(A, 'LHP506', 'KẾT QUẢ ĐÚNG:');
console.log(`\n  ✓ Chỉ 1 phiên thắng · sĩ số cuối ${dung.SiSoHienTai}/${dung.SiSoToiDa} · COUNT(*) = ${dung.SoDK_ThucTe} → KHÔNG vượt sĩ số`);

// ============================================================================
console.log('\n' + LINE);
console.log(' KẾT LUẬN');
console.log(LINE);
console.log(`  Bản CHƯA FIX : LHP514 nhận ${sai.SoDK_ThucTe}/${sai.SiSoToiDa} lượt đăng ký  → điều kiện sĩ số của phiên A mất hiệu lực`);
console.log(`  Bản ĐÃ FIX   : LHP506 → @kqA = ${kqA[0].k}, @kqB = ${kqB[0].k}              → một suất chỉ cấp cho đúng một sinh viên`);
console.log('  Cơ chế chặn : SELECT SiSoHienTai, SiSoToiDa ... FOR UPDATE (giữ X-lock tới COMMIT)');
console.log(LINE);

console.log('\n■ DỌN DẸP — trả dữ liệu về trạng thái ban đầu');
await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP514')`);
await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP506')`);
await trangThai(A, 'LHP514', 'Sau dọn dẹp:');
await trangThai(A, 'LHP506', 'Sau dọn dẹp:');

await A.end();
await B.end();
