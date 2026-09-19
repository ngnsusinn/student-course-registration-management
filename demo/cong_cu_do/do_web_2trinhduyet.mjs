// ============================================================================
// demo/cong_cu_do/do_web_2trinhduyet.mjs
// MÔ PHỎNG ĐÚNG THAO TÁC TAY CỦA NGƯỜI DÙNG TRÊN WEB (2 trình duyệt)
//   Chỉ gọi những API mà giao diện thật gọi:
//     POST /api/auth/login          (đăng nhập)
//     POST /api/dangky/nhieu        (nút “Đăng ký N lớp đã chọn”)
//     POST /api/dangky              (nút “Đăng ký” ở cột Thao tác)
//
//   Chạy:  node demo/cong_cu_do/do_web_2trinhduyet.mjs nrr
//          node demo/cong_cu_do/do_web_2trinhduyet.mjs phantom
//   (backend phải đang chạy ở http://localhost:3000)
// ============================================================================
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const BACKEND = path.resolve(__dirname, '..', '..', 'backend');
const require = createRequire(path.join(BACKEND, 'package.json'));
const mysql = require('mysql2/promise');
require('dotenv').config({ path: path.join(BACKEND, '.env'), quiet: true });

const API = 'http://localhost:3000';
const che = (process.argv[2] || 'nrr').toLowerCase();

const c = await mysql.createConnection({
  host: process.env.DB_HOST, port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER, password: process.env.DB_PASSWORD, database: process.env.DB_NAME,
  charset: 'utf8mb4', connectTimeout: 30000,
});
await c.query("SET time_zone = '+07:00'");
const q = async (s) => (await c.query(s))[0];

const goi = async (duong, opt) => {
  const r = await fetch(API + duong, opt);
  return { status: r.status, ok: r.ok, body: await r.json().catch(() => ({})) };
};
const token = async (u) => (await goi('/api/auth/login', {
  method: 'POST', headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ TenDangNhap: u, MatKhau: 'matkhau@123' }),
})).body.token;
const header = (t) => ({ 'Content-Type': 'application/json', Authorization: 'Bearer ' + t });
const dangKyNhieu = (t, ds) => goi('/api/dangky/nhieu', { method: 'POST', headers: header(t),
  body: JSON.stringify({ DanhSachLHP: ds, MaxTinChi: 24, GhiChu: 'Đăng ký mới' }) });
const dangKyMot = (t, lhp) => goi('/api/dangky', { method: 'POST', headers: header(t),
  body: JSON.stringify({ MaLHP: lhp, MaxTinChi: 24, GhiChu: 'Đăng ký mới' }) });

const SP = async () => ((await q(`SELECT ROUTINE_DEFINITION AS d FROM information_schema.ROUTINES
  WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_NAME='SP_DangKyNhieuHocPhan'`))[0] || {}).d || '';
const d = await SP();
const coDocHaiLan = /vSiSo1/.test(d);
const mucCoLap = /ISOLATION LEVEL READ COMMITTED/.test(d) ? 'READ COMMITTED (❌ đã TẮT phòng chống)'
               : 'REPEATABLE READ (✅ giữ mặc định)';

console.log('='.repeat(78));
console.log(`MÔ PHỎNG 2 TRÌNH DUYỆT — kịch bản: ${che.toUpperCase()}`);
console.log(`SP_DangKyNhieuHocPhan: ${coDocHaiLan ? 'BẢN LAB (đọc 2 lần)' : 'BẢN THẬT (không đọc 2 lần)'} · ${mucCoLap}`);
console.log('='.repeat(78));

// Dọn dẹp: xóa đăng ký thử của các SV demo trên lớp demo
const LOP_DEMO = ['LHP505', 'LHP507', 'LHP508'];
for (const lhp of LOP_DEMO) {
  await q(`DELETE FROM DANGKYHOCPHAN WHERE MaLHP='${lhp}' AND MaSV IN ('SV001','SV003','SV004')`);
  await q(`UPDATE LOPHOCPHAN lhp SET lhp.SiSoHienTai =
    (SELECT COUNT(*) FROM DANGKYHOCPHAN d WHERE d.MaLHP=lhp.MaLHP AND d.TrangThaiDangKy='DA_DANG_KY')
    WHERE lhp.MaLHP='${lhp}'`);
}
console.table(await q(`SELECT MaLHP, SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP IN ('LHP505','LHP507','LHP508')`));

let A, B, nhan;

if (che === 'nrr') {
  // ── Non-repeatable Read: hai SINH VIÊN KHÁC NHAU ở hai trình duyệt ──
  nhan = 'Non-repeatable Read — đọc MỘT DÒNG (sĩ số lớp LHP507)';
  const tA = await token('sv003');   // Trình duyệt A
  const tB = await token('sv004');   // Trình duyệt B
  console.log('\n[Trình duyệt A] sv003: tick LHP507 + LHP508 rồi bấm “Đăng ký 2 lớp đã chọn” ...');
  const pA = dangKyNhieu(tA, ['LHP507', 'LHP508']);
  await new Promise((r) => setTimeout(r, 2000));
  console.log('[Trình duyệt B] sv004: bấm “Đăng ký” ở dòng LHP507 ...');
  const rB = await dangKyMot(tB, 'LHP507');
  A = await pA; B = rB;
} else {
  // ── Phantom Read: CÙNG một sinh viên ở 2 cửa sổ (1 thường + 1 ẩn danh) ──
  nhan = 'Phantom Read — đếm MỘT TẬP BẢN GHI (số lớp của SV trong học kỳ)';
  const tA = await token('sv001');   // Trình duyệt A  (cửa sổ thường)
  const tB = await token('sv001');   // Trình duyệt B  (cửa sổ ẩn danh — CÙNG tài khoản)
  console.log('\n[Trình duyệt A] sv001: tick LHP507 + LHP508 rồi bấm “Đăng ký 2 lớp đã chọn” ...');
  const pA = dangKyNhieu(tA, ['LHP507', 'LHP508']);
  await new Promise((r) => setTimeout(r, 2000));
  console.log('[Trình duyệt B] sv001 (cửa sổ ẩn danh): bấm “Đăng ký” ở dòng LHP505 (lớp KHÁC) ...');
  const rB = await dangKyMot(tB, 'LHP505');
  A = await pA; B = rB;
}

console.log('\n─── KẾT QUẢ TRÊN GIAO DIỆN ───');
console.log(`   [A] HTTP ${A.status} · ketQua = ${A.body.ketQua}`);
console.log(`       ${A.ok ? 'toast XANH: ' + A.body.message : 'toast ĐỎ: ' + (A.body.error || '')}`);
if (A.body.chiTiet?.ChiTiet) console.log(`       “Kết quả từng lớp”: ${A.body.chiTiet.ChiTiet}`);
console.log(`   [B] HTTP ${B.status} · ketQua = ${B.body.ketQua} ${B.ok ? '(ĐĂNG KÝ THÀNH CÔNG)' : '· ' + (B.body.error || '')}`);

const khac = A.body.chiTiet?.ChiTiet && /HỦY OAN|→/.test(A.body.chiTiet.ChiTiet);
console.log(`\n   ⇒ ${A.body.ketQua === 104
  ? '⚠️  SINH VIÊN A BỊ HỦY OAN — hai lần đọc trong cùng giao tác cho hai kết quả khác nhau (tái hiện lỗi)'
  : A.ok ? '✅  SINH VIÊN A ĐĂNG KÝ THÀNH CÔNG — hai lần đọc giống nhau (đã chặn lỗi)'
         : '⚠️  kết quả khác — xem chi tiết ở trên'}`);

console.table(await q(`SELECT dk.MaSV, dk.MaLHP, dk.TrangThaiDangKy, dk.GhiChu
  FROM DANGKYHOCPHAN dk WHERE dk.MaLHP IN ('LHP505','LHP507','LHP508') AND dk.MaSV IN ('SV001','SV003','SV004')
  ORDER BY dk.MaSV, dk.MaLHP`));

// Dọn dẹp
for (const lhp of LOP_DEMO) {
  await q(`DELETE FROM DANGKYHOCPHAN WHERE MaLHP='${lhp}' AND MaSV IN ('SV001','SV003','SV004')`);
  await q(`UPDATE LOPHOCPHAN lhp SET lhp.SiSoHienTai =
    (SELECT COUNT(*) FROM DANGKYHOCPHAN d WHERE d.MaLHP=lhp.MaLHP AND d.TrangThaiDangKy='DA_DANG_KY')
    WHERE lhp.MaLHP='${lhp}'`);
}
console.log('\nĐã dọn dẹp đăng ký thử của SV001/SV003/SV004 trên LHP505/507/508.');
await c.end();
