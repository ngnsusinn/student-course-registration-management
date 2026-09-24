// ============================================================================
// demo/cong_cu_do/do_thuc_te.mjs
// CÔNG CỤ ĐO THỰC TẾ 4 LỖI ĐIỀU KHIỂN CẠNH TRANH (tùy chọn — chỉ để tự kiểm chứng)
//
//   Chạy từ thư mục gốc repo:   node demo/cong_cu_do/do_thuc_te.mjs
//   hoặc:                       cd backend && node ../demo/cong_cu_do/do_thuc_te.mjs
//
// Công cụ này KHÔNG phải kịch bản demo — kịch bản thao tác tay nằm ở các file
// 01_LOST_UPDATE.md · 02_NON_REPEATABLE_READ.md · 03_PHANTOM_READ.md · 04_DEADLOCK.md
// Nó dùng 2 kết nối thật để mô phỏng đúng thao tác tay và IN RA số liệu đo được.
//
// Đọc cấu hình từ backend/.env (không phụ thuộc thư mục đang đứng).
// ============================================================================
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import fs from 'node:fs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..', '..');
const BACKEND = path.join(ROOT, 'backend');

const require = createRequire(path.join(BACKEND, 'package.json'));
const mysql = require('mysql2/promise');
require('dotenv').config({ path: path.join(BACKEND, '.env'), quiet: true });

const CFG = {
  host: process.env.DB_HOST || 'free02.123host.vn',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'roacqgfa_dbms',
  password: process.env.DB_PASSWORD || 'roacqgfa_dbms1',
  database: process.env.DB_NAME || 'roacqgfa_dbms',
  charset: 'utf8mb4',
  dateStrings: true,
  connectTimeout: 30000,
};

const KQ = [];                                   // gom ket qua do duoc
const ghi = (muc, noiDung, soLieu) => {
  console.log(`\n──── ${muc} ────\n${noiDung}`);
  KQ.push({ muc, noiDung, soLieu });
};

const mk = async () => {
  const conn = await mysql.createConnection({ ...CFG, multipleStatements: false });
  await conn.query("SET time_zone = '+07:00'");
  return conn;
};
const q = async (c, s) => (await c.query(s))[0];
const ngu = (ms) => new Promise((r) => setTimeout(r, ms));
const giay = (ms) => (ms / 1000).toFixed(2) + 's';

const A = await mk();
const B = await mk();

const tt = async (c, maLHP) => (await q(c, `SELECT lhp.SiSoHienTai, lhp.SiSoToiDa,
  (SELECT COUNT(*) FROM DANGKYHOCPHAN d WHERE d.MaLHP=lhp.MaLHP AND d.TrangThaiDangKy='DA_DANG_KY') AS SoDK
  FROM LOPHOCPHAN lhp WHERE lhp.MaLHP='${maLHP}'`))[0];

const env = (await q(A, `SELECT VERSION() AS v, @@tx_isolation AS iso,
  @@innodb_deadlock_detect AS dd, @@innodb_lock_wait_timeout AS lwt`))[0];
console.log('='.repeat(78));
console.log('ĐO THỰC TẾ 4 LỖI ĐIỀU KHIỂN CẠNH TRANH');
console.log(`HQTCSDL: ${env.v} · isolation mặc định = ${env.iso} · deadlock_detect = ${env.dd} · lock_wait_timeout = ${env.lwt}s`);
console.log(`Kết nối: ${CFG.host}:${CFG.port} / ${CFG.database}   (conn ${A.threadId} = PHIÊN A, conn ${B.threadId} = PHIÊN B)`);
console.log('='.repeat(78));

// ===========================================================================
// M1 — LOST UPDATE
// ===========================================================================
console.log('\n\n██████ M1 — LỖI MẤT DỮ LIỆU CẬP NHẬT (LOST UPDATE) ██████');

// --- M1.1 chua fix: doc khong khoa roi cung ghi ---
{
  await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP514')`);
  const t0 = await tt(A, 'LHP514');
  await q(A, 'START TRANSACTION');
  const a1 = (await q(A, `SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP='LHP514'`))[0];
  await q(A, `INSERT INTO DANGKYHOCPHAN (MaSV,MaLHP,NgayDangKy,TrangThaiDangKy,GhiChu)
    VALUES ('SV030','LHP514',NOW(),'DA_DANG_KY','do luong chua fix')`);
  await q(B, 'START TRANSACTION');
  const b1 = (await q(B, `SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP='LHP514'`))[0];
  const tb = Date.now();
  const pB = q(B, `INSERT INTO DANGKYHOCPHAN (MaSV,MaLHP,NgayDangKy,TrangThaiDangKy,GhiChu)
    VALUES ('SV041','LHP514',NOW(),'DA_DANG_KY','do luong chua fix')`);
  await ngu(2000);
  await q(A, 'COMMIT');
  await pB;
  const choKhoa = Date.now() - tb;
  await q(B, 'COMMIT');
  const after = await tt(A, 'LHP514');
  ghi('M1.1 · CHƯA FIX — 2 phiên cùng đọc "còn 1 chỗ" rồi cùng ghi (LHP514)',
    `   Xuất phát: LHP514 = ${t0.SiSoHienTai}/${t0.SiSoToiDa} (COUNT=${t0.SoDK})\n` +
    `   PHIÊN A đọc  : ${a1.SiSoHienTai}/${a1.SiSoToiDa}  →  INSERT SV030 (giữ khóa)\n` +
    `   PHIÊN B đọc  : ${b1.SiSoHienTai}/${b1.SiSoToiDa}  ← VẪN thấy "còn 1 chỗ" (snapshot cũ)\n` +
    `   PHIÊN B INSERT: CHỜ KHÓA ${giay(choKhoa)} rồi mới chạy được\n` +
    `   KẾT QUẢ: sĩ số đếm thật = ${after.SoDK}/${after.SiSoToiDa} · bộ đếm SiSoHienTai = ${after.SiSoHienTai}\n` +
    `   ⇒ ${after.SoDK > after.SiSoToiDa ? 'VƯỢT SĨ SỐ — TÁI HIỆN ĐƯỢC LỖI LOST UPDATE' : 'không vượt (sai)'}`,
    { maLHP: 'LHP514', soDK: after.SoDK, siSoToiDa: after.SiSoToiDa, boDem: after.SiSoHienTai, choKhoaMs: choKhoa });
  await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP514')`);
}

// --- M1.2 da fix: FOR UPDATE ---
{
  await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP514')`);
  await q(A, 'START TRANSACTION');
  const a1 = (await q(A, `SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP='LHP514' FOR UPDATE`))[0];
  await q(A, `INSERT INTO DANGKYHOCPHAN (MaSV,MaLHP,NgayDangKy,TrangThaiDangKy,GhiChu)
    VALUES ('SV030','LHP514',NOW(),'DA_DANG_KY','do luong da fix')`);
  await q(B, 'START TRANSACTION');
  const tb = Date.now();
  const pB = q(B, `SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP='LHP514' FOR UPDATE`);
  await ngu(2000);
  await q(A, 'COMMIT');
  const b2 = (await pB)[0];
  const choKhoa = Date.now() - tb;
  await q(B, 'ROLLBACK');
  const after = await tt(A, 'LHP514');
  ghi('M1.2 · ĐÃ FIX — khoá dòng sĩ số bằng SELECT … FOR UPDATE (cùng LHP514)',
    `   PHIÊN A: SELECT … FOR UPDATE → ${a1.SiSoHienTai}/${a1.SiSoToiDa}  (giữ X-lock) rồi INSERT SV030\n` +
    `   PHIÊN B: SELECT … FOR UPDATE → CHỜ KHÓA ${giay(choKhoa)} → sau khi A commit đọc được ${b2.SiSoHienTai}/${b2.SiSoToiDa}\n` +
    `   ⇒ điều kiện IF ${b2.SiSoHienTai} >= ${b2.SiSoToiDa} đúng ⇒ SP trả mã 105 "Lớp đã đầy sĩ số"\n` +
    `   KẾT QUẢ: ${after.SoDK}/${after.SiSoToiDa} — KHÔNG vượt sĩ số`,
    { choKhoaMs: choKhoa, docDuoc: `${b2.SiSoHienTai}/${b2.SiSoToiDa}`, soDK: after.SoDK, siSoToiDa: after.SiSoToiDa });
  await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP514')`);
}

// --- M1.3 qua thu tuc that (nghiep vu 0 / 105) ---
{
  await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP506')`);
  const t0 = await tt(A, 'LHP506');
  const pA = q(A, `CALL SP_DangKyHocPhan('SV030','LHP506',24,'do luong da fix',@kqA)`).then(() => q(A, 'SELECT @kqA AS k'));
  await ngu(200);
  const pB = q(B, `CALL SP_DangKyHocPhan('SV041','LHP506',24,'do luong da fix',@kqB)`).then(() => q(B, 'SELECT @kqB AS k'));
  const [rA, rB] = await Promise.all([pA, pB]);
  const after = await tt(A, 'LHP506');
  ghi('M1.3 · ĐÃ FIX — qua thủ tục thật SP_DangKyHocPhan (LHP506 còn 1 chỗ)',
    `   Xuất phát: LHP506 = ${t0.SiSoHienTai}/${t0.SiSoToiDa}\n` +
    `   @kqA (SV030) = ${rA[0].k}  → ${rA[0].k === 0 ? 'lấy được suất cuối' : '??'}\n` +
    `   @kqB (SV041) = ${rB[0].k}  → ${rB[0].k === 105 ? 'LỚP ĐÃ ĐẦY SĨ SỐ (bị từ chối đúng)' : '??'}\n` +
    `   KẾT QUẢ: ${after.SoDK}/${after.SiSoToiDa} — một suất chỉ cấp cho đúng một sinh viên`,
    { kqA: rA[0].k, kqB: rB[0].k, soDK: after.SoDK, siSoToiDa: after.SiSoToiDa });
  await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP506')`);
}

// ===========================================================================
// M2 — NON-REPEATABLE READ
// ===========================================================================
console.log('\n\n██████ M2 — LỖI KHÔNG ĐỌC LẠI ĐƯỢC DỮ LIỆU (NON-REPEATABLE READ) ██████');

const tangSiSo = async (c) => q(c, `UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP='LHP514'`);

// --- M2.1 chua fix: READ COMMITTED ---
{
  await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP514')`);
  await q(A, `SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED`);
  await q(A, 'START TRANSACTION');
  const l1 = (await q(A, `SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514'`))[0];
  await q(B, 'START TRANSACTION');
  await tangSiSo(B);
  await q(B, 'COMMIT');
  const l2 = (await q(A, `SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514'`))[0];
  await q(A, 'ROLLBACK');
  await q(A, `SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ`);
  ghi('M2.1 · CHƯA FIX — PHIÊN A hạ mức cô lập xuống READ COMMITTED',
    `   PHIÊN A: SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;  ★ TẮT phòng chống\n` +
    `   PHIÊN A đọc lần 1 → ${l1.SiSoHienTai}\n` +
    `   PHIÊN B    : UPDATE SiSoHienTai + 1; COMMIT;   (15 → 16)\n` +
    `   PHIÊN A đọc lần 2 → ${l2.SiSoHienTai}   ← ${l1.SiSoHienTai !== l2.SiSoHienTai ? 'KHÁC lần 1 ⇒ TÁI HIỆN ĐƯỢC LỖI' : 'giống lần 1 (sai)'}\n` +
    `   ⇒ cùng MỘT giao tác mà cùng một ô dữ liệu cho 2 giá trị khác nhau`,
    { lan1: l1.SiSoHienTai, lan2: l2.SiSoHienTai, chenhLech: l2.SiSoHienTai - l1.SiSoHienTai });
  await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP514')`);
}

// --- M2.2 da fix: REPEATABLE READ ---
{
  await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP514')`);
  await q(A, `SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ`);
  await q(A, 'START TRANSACTION');
  const l1 = (await q(A, `SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514'`))[0];
  await q(B, 'START TRANSACTION');
  await tangSiSo(B);
  await q(B, 'COMMIT');
  const l2 = (await q(A, `SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514'`))[0];
  await q(A, 'ROLLBACK');
  ghi('M2.2 · ĐÃ FIX — giữ mức mặc định REPEATABLE READ (MVCC snapshot)',
    `   PHIÊN A: SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;  ★ giữ mặc định\n` +
    `   PHIÊN A đọc lần 1 → ${l1.SiSoHienTai}\n` +
    `   PHIÊN B    : UPDATE SiSoHienTai + 1; COMMIT;   (15 → 16 — đã commit thật)\n` +
    `   PHIÊN A đọc lần 2 → ${l2.SiSoHienTai}   ← ${l1.SiSoHienTai === l2.SiSoHienTai ? 'GIỐNG lần 1 ⇒ ĐÃ CHẶN ĐƯỢC LỖI' : 'khác (sai)'}\n` +
    `   ⇒ snapshot được cố định từ lần đọc ĐẦU TIÊN của giao tác`,
    { lan1: l1.SiSoHienTai, lan2: l2.SiSoHienTai, giongNhau: l1.SiSoHienTai === l2.SiSoHienTai });
  await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP514')`);
}

// --- M2.3 da fix bang khoa doc (khi can doc gia tri MOI NHAT) ---
{
  await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP514')`);
  await q(A, 'START TRANSACTION');
  const l1 = (await q(A, `SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP='LHP514' FOR UPDATE`))[0];
  const tb = Date.now();
  const pB = (async () => {
    await q(B, 'START TRANSACTION');
    return tangSiSo(B).then(() => q(B, 'COMMIT'));
  })();
  await ngu(1500);
  await q(A, 'COMMIT');
  await pB;
  const choKhoa = Date.now() - tb;
  const l2 = await tt(A, 'LHP514');
  ghi('M2.3 · ĐÃ FIX (bổ sung) — khoá đọc bằng FOR UPDATE khi BẮT BUỘC cần giá trị mới nhất',
    `   PHIÊN A: SELECT SiSoHienTai, SiSoToiDa … FOR UPDATE → ${l1.SiSoHienTai}/${l1.SiSoToiDa} (giữ X-lock)\n` +
    `   PHIÊN B: UPDATE SiSoHienTai + 1 → BỊ CHẶN ${giay(choKhoa)} cho tới khi A COMMIT rồi mới chạy\n` +
    `   ⇒ ghi của B không thể chen vào giữa 2 lần đọc của A`,
    { choKhoaMs: choKhoa, sauCung: `${l2.SiSoHienTai}/${l2.SiSoToiDa}` });
  await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP514')`);
}

// ===========================================================================
// M3 — PHANTOM READ
// ===========================================================================
console.log('\n\n██████ M3 — LỖI ĐỌC BÓNG MA (PHANTOM READ) ██████');

const demDK = async (c) => (await q(c, `SELECT COUNT(*) AS n FROM DANGKYHOCPHAN
  WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY'`))[0].n;
const themBongMa = async (c) => q(c, `INSERT INTO DANGKYHOCPHAN (MaSV,MaLHP,NgayDangKy,TrangThaiDangKy,GhiChu)
  VALUES ('SV999','LHP514',NOW(),'DA_DANG_KY','dong bong ma')`);

// --- M3.1 chua fix: READ COMMITTED ---
{
  await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP514')`);
  await q(A, `SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED`);
  await q(A, 'START TRANSACTION');
  const n1 = await demDK(A);
  await q(B, 'START TRANSACTION');
  await themBongMa(B);
  await q(B, 'COMMIT');
  const n2 = await demDK(A);
  await q(A, 'ROLLBACK');
  await q(A, `SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ`);
  ghi('M3.1 · CHƯA FIX — PHIÊN A hạ mức cô lập xuống READ COMMITTED',
    `   PHIÊN A: SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;  ★ TẮT phòng chống\n` +
    `   PHIÊN A đếm lần 1: COUNT(*) = ${n1}\n` +
    `   PHIÊN B: INSERT SV999 vào LHP514; COMMIT;   (dòng "bóng ma")\n` +
    `   PHIÊN A đếm lần 2: COUNT(*) = ${n2}   ← ${n2 !== n1 ? 'XUẤT HIỆN THÊM DÒNG ⇒ TÁI HIỆN ĐƯỢC LỖI' : 'không đổi (sai)'}\n` +
    `   ⇒ dòng A KHÔNG hề chèn lại xuất hiện trong tập kết quả của A`,
    { lan1: n1, lan2: n2, themDong: n2 - n1 });
  await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP514')`);
}

// --- M3.2 da fix: REPEATABLE READ ---
{
  await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP514')`);
  await q(A, `SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ`);
  await q(A, 'START TRANSACTION');
  const n1 = await demDK(A);
  await q(B, 'START TRANSACTION');
  await themBongMa(B);
  await q(B, 'COMMIT');
  const n2 = await demDK(A);
  await q(A, 'ROLLBACK');
  const tong = await demDK(A);
  ghi('M3.2 · ĐÃ FIX — giữ mức mặc định REPEATABLE READ (snapshot + next-key lock)',
    `   PHIÊN A: SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;  ★ giữ mặc định\n` +
    `   PHIÊN A đếm lần 1: COUNT(*) = ${n1}\n` +
    `   PHIÊN B: INSERT SV999 vào LHP514; COMMIT;   (đã ghi thật — kiểm tra lại thấy COUNT=${tong})\n` +
    `   PHIÊN A đếm lần 2: COUNT(*) = ${n2}   ← ${n1 === n2 ? 'KHÔNG ĐỔI ⇒ ĐÃ CHẶN ĐƯỢC LỖI' : 'đổi (sai)'}\n` +
    `   ⇒ A vẫn làm việc trên một ảnh chụp nhất quán`,
    { lan1: n1, lan2: n2, khongDoi: n1 === n2, countThatSauCung: tong });
  await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP514')`);
}

// --- M3.3 da fix bang khoa pham vi ---
{
  await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP514')`);
  await q(A, 'START TRANSACTION');
  const r = (await q(A, `SELECT COUNT(*) AS n FROM DANGKYHOCPHAN
    WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY' FOR UPDATE`))[0];
  let bElapsed = null;
  const pB = (async () => {
    await q(B, 'START TRANSACTION');
    const t = Date.now();
    await themBongMa(B);
    bElapsed = Date.now() - t;
  })();
  await ngu(2500);
  const n2 = (await q(A, `SELECT COUNT(*) AS n FROM DANGKYHOCPHAN
    WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY' FOR UPDATE`))[0].n;
  await q(A, 'COMMIT');
  await pB;
  await q(B, 'COMMIT');
  const sau = await demDK(A);
  ghi('M3.3 · ĐÃ FIX (bổ sung) — khoá PHẠM VI bằng SELECT … FOR UPDATE trên đúng tập đang đếm',
    `   PHIÊN A: SELECT COUNT(*) … FROM DANGKYHOCPHAN WHERE MaLHP='LHP514' … FOR UPDATE  → COUNT = ${r.n}\n` +
    `   PHIÊN B: INSERT SV999 → ${bElapsed > 1000 ? `BỊ CHẶN ${giay(bElapsed)} (chờ tới khi A COMMIT)` : `chạy ngay (${giay(bElapsed ?? 0)}) — KHÔNG bị chặn`}\n` +
    `   PHIÊN A đếm lại (trong cùng giao tác) → ${n2}  ← ${r.n === n2 ? 'KHÔNG ĐỔI' : 'ĐỔI'}\n` +
    `   KẾT QUẢ cuối sau khi cả hai commit: COUNT = ${sau}\n` +
    `   ⇒ phiên khác ${bElapsed > 1000 ? 'KHÔNG THỂ chèn vào phạm vi mà A đang đọc (next-key/gap lock)' : 'vẫn chèn được — cần khoá dòng sĩ số ở LOPHOCPHAN (xem M1.2)'}`,
    { countA: r.n, countA2: n2, insertChoMs: bElapsed, countCuoi: sau });
  await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP514')`);
}

// ===========================================================================
// M4 — DEADLOCK
// ===========================================================================
console.log('\n\n██████ M4 — LỖI KHÓA CHẾT (DEADLOCK) ██████');

// --- M4.1 chua fix: khoa theo thu tu yeu cau ---
{
  await q(A, `CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506')`);
  await q(A, `SET SESSION innodb_lock_wait_timeout = 20`);
  await q(B, `SET SESSION innodb_lock_wait_timeout = 20`);
  await q(A, 'SET @kq1 = NULL'); await q(B, 'SET @kq2 = NULL');
  const t0 = Date.now();
  const pA = q(A, `CALL SP_Demo_KhoaTheoThuTu('SV030','LHP514,LHP506','THEO_YEU_CAU',3,@kq1)`).catch((e) => e);
  await ngu(500);
  const pB = q(B, `CALL SP_Demo_KhoaTheoThuTu('SV041','LHP506,LHP514','THEO_YEU_CAU',3,@kq2)`).catch((e) => e);
  await Promise.all([pA, pB]);
  const r1 = (await q(A, 'SELECT @kq1 AS k'))[0].k;
  const r2 = (await q(B, 'SELECT @kq2 AS k'))[0].k;
  const phatHien = Date.now() - t0;
  ghi('M4.1 · CHƯA FIX — 2 phiên khoá 2 lớp theo thứ tự NGƯỢC NHAU (khoá theo yêu cầu)',
    `   PHIÊN A: CALL SP_Demo_KhoaTheoThuTu('SV030','LHP514,LHP506','THEO_YEU_CAU',3,@kq1)\n` +
    `   PHIÊN B: CALL SP_Demo_KhoaTheoThuTu('SV041','LHP506,LHP514','THEO_YEU_CAU',3,@kq2)\n` +
    `   @kq1 = ${r1} · @kq2 = ${r2}\n` +
    `   ⇒ ${r1 === 1213 || r2 === 1213 ? 'MỘT PHIÊN NHẬN 1213 (ER_LOCK_DEADLOCK) — InnoDB tự chọn nạn nhân & rollback' : 'không có 1213 (sai)'}\n` +
    `   Thời điểm phát hiện: ~${giay(phatHien)} sau khi bắt đầu`,
    { kq1: r1, kq2: r2, phatHienMs: phatHien });
}

// --- M4.2 da fix: SAP_XEP ---
{
  await q(A, `CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506')`);
  await q(A, 'SET @kq1 = NULL'); await q(B, 'SET @kq2 = NULL');
  const pA = q(A, `CALL SP_Demo_KhoaTheoThuTu('SV030','LHP514,LHP506','SAP_XEP',3,@kq1)`).catch((e) => e);
  await ngu(500);
  const pB = q(B, `CALL SP_Demo_KhoaTheoThuTu('SV041','LHP506,LHP514','SAP_XEP',3,@kq2)`).catch((e) => e);
  await Promise.all([pA, pB]);
  const r1 = (await q(A, 'SELECT @kq1 AS k'))[0].k;
  const r2 = (await q(B, 'SELECT @kq2 AS k'))[0].k;
  ghi('M4.2 · ĐÃ FIX — khoá theo thứ tự NHẤT QUÁN (con trỏ sắp MaLHP TĂNG DẦN)',
    `   PHIÊN A: … 'SAP_XEP' … (A cũng khoá LHP506→LHP514 theo yêu cầu, nhưng con trỏ tự sắp lại)\n` +
    `   PHIÊN B: … 'SAP_XEP' …\n` +
    `   @kq1 = ${r1} · @kq2 = ${r2}\n` +
    `   ⇒ ${r1 === 0 && r2 === 0 ? 'CẢ HAI = 0 — KHÔNG còn deadlock (không thể hình thành chu trình chờ)' : 'có lỗi (sai)'}`,
    { kq1: r1, kq2: r2 });
}

// --- M4.3 loi THAT cua he thong: dao thu tu khoa DANG KY <-> HUY ---
{
  await q(A, `CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506')`);
  await q(A, 'SET @kq1 = NULL'); await q(B, 'SET @kq2 = NULL');
  const pA = q(A, `CALL SP_Demo_PhienGiaoDich('DANG_KY_CHUA_FIX','SV030','LHP514',3,@kq1)`).catch((e) => e);
  await ngu(500);
  const pB = q(B, `CALL SP_Demo_PhienGiaoDich('HUY_CHUA_FIX','SV030','LHP514',3,@kq2)`).catch((e) => e);
  await Promise.all([pA, pB]);
  const r1 = (await q(A, 'SELECT @kq1 AS k'))[0].k;
  const r2 = (await q(B, 'SELECT @kq2 AS k'))[0].k;
  ghi('M4.3 · LỖI THẬT CỦA HỆ THỐNG — đảo thứ tự khoá giữa ĐĂNG KÝ và HỦY ĐĂNG KÝ',
    `   PHIÊN A: SP_Demo_PhienGiaoDich('DANG_KY_CHUA_FIX','SV030','LHP514',3,@kq1)   [LOPHOCPHAN → DANGKYHOCPHAN]\n` +
    `   PHIÊN B: SP_Demo_PhienGiaoDich('HUY_CHUA_FIX','SV030','LHP514',3,@kq2)       [DANGKYHOCPHAN → LOPHOCPHAN]\n` +
    `   @kq1 = ${r1} · @kq2 = ${r2}   (1213 = deadlock, 202 = nghiệp vụ)\n` +
    `   ⇒ ${r1 === 1213 || r2 === 1213 ? 'DEADLOCK sinh ra từ CHÍNH nghiệp vụ đăng ký/hủy của hệ thống' : 'không tái hiện được ở lần chạy này'}`,
    { kq1: r1, kq2: r2 });
}

// --- M4.4 da fix: cung thu tu khoa ---
{
  await q(A, `CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506')`);
  await q(A, 'SET @kq1 = NULL'); await q(B, 'SET @kq2 = NULL');
  const pA = q(A, `CALL SP_Demo_PhienGiaoDich('DANG_KY_DA_FIX','SV030','LHP514',3,@kq1)`).catch((e) => e);
  await ngu(500);
  const pB = q(B, `CALL SP_Demo_PhienGiaoDich('HUY_DA_FIX','SV030','LHP514',3,@kq2)`).catch((e) => e);
  await Promise.all([pA, pB]);
  const r1 = (await q(A, 'SELECT @kq1 AS k'))[0].k;
  const r2 = (await q(B, 'SELECT @kq2 AS k'))[0].k;
  ghi('M4.4 · ĐÃ FIX — SP_HuyDangKy khoá LOPHOCPHAN TRƯỚC (cùng thứ tự với SP_DangKyHocPhan)',
    `   PHIÊN A: 'DANG_KY_DA_FIX' · PHIÊN B: 'HUY_DA_FIX'\n` +
    `   @kq1 = ${r1} · @kq2 = ${r2}\n` +
    `   ⇒ ${r1 !== 1213 && r2 !== 1213 ? 'KHÔNG còn 1213 — hai phiên nối tiếp nhau an toàn' : 'vẫn còn deadlock'}`,
    { kq1: r1, kq2: r2 });
}

// ===========================================================================
// KET THUC — don dep
// ===========================================================================
await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP514')`);
await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP506')`);
await q(A, `CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506')`);
await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP514')`);
await q(A, `CALL SP_ChuanBi_Demo_4Anomaly('LHP506')`);
await q(A, `SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ`);
await q(B, `SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ`).catch(() => {});
await q(A, 'SELECT RELEASE_ALL_LOCKS()').catch(() => {});

const con = (await q(A, `SELECT
  (SELECT COUNT(*) FROM DANGKYHOCPHAN WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY') AS LHP514_DK,
  (SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514') AS LHP514_SiSo,
  (SELECT SiSoToiDa   FROM LOPHOCPHAN WHERE MaLHP='LHP514') AS LHP514_ToiDa,
  (SELECT COUNT(*) FROM DANGKYHOCPHAN WHERE MaLHP='LHP506' AND TrangThaiDangKy='DA_DANG_KY') AS LHP506_DK,
  (SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP506') AS LHP506_SiSo`))[0];
console.log('\n' + '='.repeat(78));
console.log('DỌN DẸP — trạng thái cuối:', JSON.stringify(con));
console.log('='.repeat(78));

// Ghi ket qua ra file markdown de doi chieu
const outDir = path.join(ROOT, 'demo', 'cong_cu_do');
fs.writeFileSync(path.join(outDir, 'ket_qua_do_raw.md'),
  '# KẾT QUẢ ĐO THỰC TẾ (raw — do công cụ `do_thuc_te.mjs` sinh ra)\n\n' +
  `- HQTCSDL: ${env.v} · isolation mặc định = ${env.iso} · deadlock_detect = ${env.dd} · lock_wait_timeout = ${env.lwt}s\n` +
  `- Kết nối: ${CFG.host}:${CFG.port} / ${CFG.database}\n\n` +
  KQ.map((k) => `## ${k.muc}\n\n\`\`\`\n${k.noiDung}\n\`\`\`\n\n\`soLieu\`: \`${JSON.stringify(k.soLieu)}\`\n`).join('\n') +
  `\n## Dọn dẹp\n\n\`\`\`\n${JSON.stringify(con)}\n\`\`\`\n`, 'utf8');
console.log(`\nĐã ghi: demo/cong_cu_do/ket_qua_do_raw.md (${KQ.length} mục)`);

await A.end();
await B.end();
