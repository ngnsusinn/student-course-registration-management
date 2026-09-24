// ============================================================================
// demo/cong_cu_do/do_thuc_te_web.mjs
// ĐO THỰC TẾ 2 LỖI QUA ĐÚNG API MÀ WEB ĐANG GỌI (mô phỏng 2 trình duyệt bấm nút)
//
//   Chạy:   node demo/cong_cu_do/do_thuc_te_web.mjs lost-update
//           node demo/cong_cu_do/do_thuc_te_web.mjs deadlock
//
// ⚠️ Công cụ này CHỈ ĐO. Việc triển khai bản SP có lỗi / khôi phục bản đã fix
//    do người demo tự làm bằng apply-sql.js (xem 01_LOST_UPDATE.md · 04_DEADLOCK.md).
//    Backend phải đang chạy ở http://localhost:3000.
// ============================================================================
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..', '..');
const BACKEND = path.join(ROOT, 'backend');
const require = createRequire(path.join(BACKEND, 'package.json'));
const mysql = require('mysql2/promise');
require('dotenv').config({ path: path.join(BACKEND, '.env'), quiet: true });

const CFG = {
  host: process.env.DB_HOST, port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER, password: process.env.DB_PASSWORD, database: process.env.DB_NAME,
  charset: 'utf8mb4', timezone: '+07:00', dateStrings: true, connectTimeout: 30000,
};
const API = 'http://localhost:3000/api';
const che = (process.argv[2] || 'lost-update').toLowerCase();

const c = await mysql.createConnection({ ...CFG, multipleStatements: false });
await c.query("SET time_zone = '+07:00'");
const q = async (s) => (await c.query(s))[0];
const ngu = (ms) => new Promise((r) => setTimeout(r, ms));

const dinhNghiaSP = async (ten) =>
  ((await q(`SELECT ROUTINE_DEFINITION AS d FROM information_schema.ROUTINES
    WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_NAME='${ten}'`))[0] || {}).d || '';

const login = async (u, p) => {
  const r = await fetch(`${API}/auth/login`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ TenDangNhap: u, MatKhau: p }),
  });
  const j = await r.json();
  if (!j.token) throw new Error('Đăng nhập thất bại: ' + JSON.stringify(j));
  return j.token;
};
const post = async (duong, token, body) => {
  const t0 = Date.now();
  const r = await fetch(`${API}${duong}`, {
    method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
    body: JSON.stringify(body),
  });
  return { status: r.status, ms: Date.now() - t0, body: await r.json() };
};
const dem = async (maLHP) => (await q(`SELECT lhp.SiSoHienTai, lhp.SiSoToiDa,
  (SELECT COUNT(*) FROM DANGKYHOCPHAN d WHERE d.MaLHP=lhp.MaLHP AND d.TrangThaiDangKy='DA_DANG_KY') AS SoDK
  FROM LOPHOCPHAN lhp WHERE lhp.MaLHP='${maLHP}'`))[0];

console.log('='.repeat(78));
console.log(`ĐO THỰC TẾ QUA API WEB — chế độ: ${che}`);
console.log(`API: ${API}  ·  DB: ${CFG.host}:${CFG.port}/${CFG.database}`);
console.log('='.repeat(78));

if (che === 'lost-update') {
  const d = await dinhNghiaSP('SP_DangKyHocPhan');
  const coForUpdate = /FOR UPDATE/i.test(d);
  const coSleep = /DO SLEEP/i.test(d);
  console.log(`\nSP_DangKyHocPhan hiện tại: ${coForUpdate ? '✅ ĐÃ FIX (có FOR UPDATE)' : '⚠️ BẢN CHƯA FIX (thiếu FOR UPDATE)'}${coSleep ? ' + có DO SLEEP (bản demo web)' : ' (bản thật, không SLEEP)'}`);

  await q(`CALL SP_ChuanBi_Demo_4Anomaly('LHP506')`);
  const t0 = await dem('LHP506');
  console.log(`Chuẩn bị: LHP506 = ${t0.SiSoHienTai}/${t0.SiSoToiDa} (COUNT=${t0.SoDK})  — "TA chuyên ngành K15", còn 1 chỗ`);

  const tA = await login('sv030', 'matkhau@123');
  const tB = await login('sv041', 'matkhau@123');
  console.log('\n[Trình duyệt A] sv030 bấm "Đăng ký" ...');
  const bd = Date.now();
  const pA = post('/dangky', tA, { MaLHP: 'LHP506', MaxTinChi: 24, GhiChu: 'Đăng ký mới' })
    .then((r) => { console.log(`   [A] sau ${((Date.now() - bd) / 1000).toFixed(1)}s → HTTP ${r.status} · ${JSON.stringify(r.body)}`); return r; });
  await ngu(2000);
  console.log('[Trình duyệt B] sv041 bấm "Đăng ký" (chậm hơn A ~2 giây, KHÔNG refresh trang) ...');
  const pB = post('/dangky', tB, { MaLHP: 'LHP506', MaxTinChi: 24, GhiChu: 'Đăng ký mới' })
    .then((r) => { console.log(`   [B] sau ${((Date.now() - bd) / 1000).toFixed(1)}s → HTTP ${r.status} · ${JSON.stringify(r.body)}`); return r; });
  const [rA, rB] = await Promise.all([pA, pB]);

  const sau = await dem('LHP506');
  console.log('\n─── KẾT QUẢ ───');
  console.log(`   A: ketQua = ${rA.body.ketQua ?? rA.status}   ${rA.body.ketQua === 0 ? '(toast XANH "Đăng ký học phần thành công")' : '(toast ĐỎ)'}`);
  console.log(`   B: ketQua = ${rB.body.ketQua ?? rB.status}   ${rB.body.ketQua === 0 ? '(toast XANH "Đăng ký học phần thành công")' : rB.body.ketQua === 105 ? '(toast ĐỎ "Lớp đã đầy sĩ số")' : '(toast ĐỎ)'}`);
  console.log(`   LHP506 sau cùng: SiSo = ${sau.SiSoHienTai}/${sau.SiSoToiDa} · COUNT(*) hiệu lực = ${sau.SoDK}`);
  console.log(`   ⇒ ${sau.SoDK > sau.SiSoToiDa ? 'VƯỢT SĨ SỐ — TÁI HIỆN ĐƯỢC LỖI LOST UPDATE TRÊN WEB'
    : rA.body.ketQua === 0 && rB.body.ketQua === 105 ? 'ĐÃ FIX — 1 phiên thắng, 1 phiên nhận mã 105'
      : 'khác (xem kết quả ở trên)'}`);
  await q(`CALL SP_ChuanBi_Demo_4Anomaly('LHP506')`);
}

if (che === 'deadlock') {
  const d = await dinhNghiaSP('SP_DangKyNhieuHocPhan');
  const theoThuTuChon = /CONCAT\(\s*'B'/i.test(d) || /KhoaThuTu\s*=\s*'B'/i.test(d);
  console.log(`\nSP_DangKyNhieuHocPhan: ${theoThuTuChon ? '⚠️ BẢN CHƯA FIX (con trỏ khoá theo ĐÚNG thứ tự tick chọn)' : '✅ ĐÃ FIX (con trỏ khoá theo MaLHP TĂNG DẦN)'}`);

  await q(`CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506')`);
  const l514 = await dem('LHP514'); const l506 = await dem('LHP506');
  console.log(`Chuẩn bị: LHP514 = ${l514.SiSoHienTai}/${l514.SiSoToiDa} · LHP506 = ${l506.SiSoHienTai}/${l506.SiSoToiDa}  (SV030 có dòng DA_HUY ở LHP514)`);

  const tA = await login('sv030', 'matkhau@123');
  const tB = await login('sv041', 'matkhau@123');
  console.log('\nTrình duyệt A (sv030): tick LHP514 rồi LHP506');
  console.log('Trình duyệt B (sv041): tick LHP506 rồi LHP514 (NGƯỢC thứ tự)');
  console.log('Cả hai bấm "Đăng ký 2 lớp đã chọn" gần như cùng lúc ...\n');
  const bd = Date.now();
  const pA = post('/dangky/nhieu', tA, { DanhSachLHP: ['LHP514', 'LHP506'], MaxTinChi: 24, GhiChu: 'Đăng ký mới' })
    .then((r) => { console.log(`   [A] sau ${((Date.now() - bd) / 1000).toFixed(1)}s → HTTP ${r.status} · ketQua=${r.body.ketQua} · ${r.body.error || r.body.message}`); return r; });
  await ngu(300);
  const pB = post('/dangky/nhieu', tB, { DanhSachLHP: ['LHP506', 'LHP514'], MaxTinChi: 24, GhiChu: 'Đăng ký mới' })
    .then((r) => { console.log(`   [B] sau ${((Date.now() - bd) / 1000).toFixed(1)}s → HTTP ${r.status} · ketQua=${r.body.ketQua} · ${r.body.error || r.body.message}`); return r; });
  const [rA, rB] = await Promise.all([pA, pB]);

  const co1213 = [rA, rB].some((r) => r.body.ketQua === 1213);
  console.log('\n─── KẾT QUẢ ───');
  console.log(`   A: ketQua = ${rA.body.ketQua} · B: ketQua = ${rB.body.ketQua}`);
  console.log(`   ⇒ ${co1213 ? 'CÓ PHIÊN NHẬN 1213 → web hiện toast đỏ "Xung đột khoá (deadlock 1213)…" — TÁI HIỆN ĐƯỢC LỖI DEADLOCK TRÊN WEB'
    : 'KHÔNG có 1213 — hai phiên nối tiếp nhau an toàn (bản đã fix)'}`);
  const sau514 = await dem('LHP514'); const sau506 = await dem('LHP506');
  console.log(`   Sĩ số sau cùng: LHP514 = ${sau514.SiSoHienTai}/${sau514.SiSoToiDa} · LHP506 = ${sau506.SiSoHienTai}/${sau506.SiSoToiDa} (deadlock không làm sai dữ liệu)`);
  await q(`CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506')`);
}

if (!['lost-update', 'deadlock'].includes(che)) {
  console.log('\nChế độ không hợp lệ. Dùng: lost-update | deadlock');
}

await c.end();
