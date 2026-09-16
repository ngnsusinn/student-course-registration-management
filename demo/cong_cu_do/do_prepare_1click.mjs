// ============================================================================
// demo/cong_cu_do/do_prepare_1click.mjs
// KIỂM CHỨNG 2 NÚT 1-CLICK của trang “Chuẩn bị Demo” (/chuan-bi-demo)
//   POST /api/prepare/chuan-bi { kichBan }   → triển khai bản có lỗi + dọn dữ liệu
//   POST /api/prepare/fix                    → khôi phục bản thật + dọn dữ liệu
//   GET  /api/prepare/trang-thai             → đang ở bản nào
//
//   Chạy:  node demo/cong_cu_do/do_prepare_1click.mjs
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
const c = await mysql.createConnection({
  host: process.env.DB_HOST, port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER, password: process.env.DB_PASSWORD, database: process.env.DB_NAME,
  charset: 'utf8mb4', connectTimeout: 30000,
});
const q = async (s) => (await c.query(s))[0];

const goi = async (duong, opt) => {
  const r = await fetch(API + duong, opt);
  return { status: r.status, ok: r.ok, body: await r.json().catch(() => ({})) };
};
const token = (await goi('/api/auth/login', {
  method: 'POST', headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ TenDangNhap: 'admin', MatKhau: 'admin@123' }),
})).body.token;
const H = { 'Content-Type': 'application/json', Authorization: 'Bearer ' + token };

const tt = async () => (await goi('/api/prepare/trang-thai', { headers: H })).body;
const inTT = (nhan, t) => {
  const d = t.danhGia || {};
  console.log(`\n── ${nhan} ──────────────────────────────────────────`);
  console.log(`   SP_DangKyHocPhan       : ${d.lostUpdate?.cheDo}  — ${d.lostUpdate?.nhan}`);
  console.log(`   SP_DangKyNhieuHocPhan  : ${d.nhieuHocPhan?.cheDo}  — ${d.nhieuHocPhan?.nhan}`);
  console.log(`   Lớp demo: ` + (t.lopDemo || []).map((l) => `${l.MaLHP}=${l.SiSoHienTai}/${l.SiSoToiDa}`).join(' · '));
};

console.log('='.repeat(78));
console.log('KIỂM CHỨNG 2 NÚT 1-CLICK — trang /chuan-bi-demo');
console.log('='.repeat(78));

// 0) Trạng thái ban đầu
inTT('0. TRẠNG THÁI BAN ĐẦU', await tt());

// 1) CLICK “CHUẨN BỊ DEMO” (kịch bản DEMO)
console.log('\n\n▶ CLICK 1: [⚙ CHUẨN BỊ DEMO] — kịch bản DEMO');
const cb = await goi('/api/prepare/chuan-bi', { method: 'POST', headers: H, body: JSON.stringify({ kichBan: 'DEMO' }) });
console.log(`   HTTP ${cb.status} · ${cb.body.thongDiep || cb.body.error}`);
(cb.body.nhat_ky || []).forEach((b) => console.log(`     ${b.ok ? '✔' : '✖'} ${b.buoc}`));
inTT('SAU KHI CHUẨN BỊ', cb.body);

// 1b) Kiểm tra thật: SP đã thành bản có lỗi chưa?
const [r1] = await q(`SELECT ROUTINE_NAME,
  ROUTINE_DEFINITION LIKE '%FOR UPDATE%' AS CoForUpdate FROM information_schema.ROUTINES
  WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_NAME='SP_DangKyHocPhan'`);
const [r2] = await q(`SELECT ROUTINE_NAME,
  ROUTINE_DEFINITION LIKE '%vSiSo1%' AS DocHaiLan,
  ROUTINE_DEFINITION LIKE '%LPAD(vThuTu%' AS KhoaTheoThuTuChon FROM information_schema.ROUTINES
  WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_NAME='SP_DangKyNhieuHocPhan'`);
console.log(`\n   KIỂM TRA DB: SP_DangKyHocPhan FOR UPDATE = ${r1.CoForUpdate} (mong đợi 0 = bản lỗi)`);
console.log(`               SP_DangKyNhieuHocPhan đọc-2-lần = ${r2.DocHaiLan} (mong đợi 1) · khóa-theo-thứ-tự-tick = ${r2.KhoaTheoThuTuChon} (mong đợi 0)`);

// 2) CLICK “FIX”
console.log('\n\n▶ CLICK 2: [✔ FIX] — khôi phục bản thật');
const fx = await goi('/api/prepare/fix', { method: 'POST', headers: H, body: '{}' });
console.log(`   HTTP ${fx.status} · ${fx.body.thongDiep || fx.body.error}`);
(fx.body.nhat_ky || []).forEach((b) => console.log(`     ${b.ok ? '✔' : '✖'} ${b.buoc}`));
inTT('SAU KHI FIX', fx.body);

const [r3] = await q(`SELECT ROUTINE_NAME,
  ROUTINE_DEFINITION LIKE '%FOR UPDATE%' AS CoForUpdate,
  ROUTINE_DEFINITION LIKE '%DO SLEEP%' AS CoSleep FROM information_schema.ROUTINES
  WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_NAME='SP_DangKyHocPhan'`);
const [r4] = await q(`SELECT ROUTINE_NAME,
  ROUTINE_DEFINITION LIKE '%vSiSo1%' AS DocHaiLan,
  ROUTINE_DEFINITION LIKE '%LPAD(vThuTu%' AS KhoaTheoThuTuChon FROM information_schema.ROUTINES
  WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_NAME='SP_DangKyNhieuHocPhan'`);
console.log(`\n   KIỂM TRA DB: SP_DangKyHocPhan FOR UPDATE = ${r3.CoForUpdate} (mong đợi 1) · DO SLEEP = ${r3.CoSleep} (mong đợi 0)`);
console.log(`               SP_DangKyNhieuHocPhan đọc-2-lần = ${r4.DocHaiLan} (mong đợi 0) · khóa-theo-thứ-tự-tick = ${r4.KhoaTheoThuTuChon} (mong đợi 0)`);

// 3) Kịch bản DEADLOCK
console.log('\n\n▶ CLICK 3: [⚙ CHUẨN BỊ DEMO] — kịch bản DEADLOCK');
const dl = await goi('/api/prepare/chuan-bi', { method: 'POST', headers: H, body: JSON.stringify({ kichBan: 'DEADLOCK' }) });
console.log(`   HTTP ${dl.status} · ${dl.body.thongDiep || dl.body.error}`);
inTT('SAU KHI CHUẨN BỊ DEADLOCK', dl.body);
const [r5] = await q(`SELECT ROUTINE_DEFINITION LIKE '%LPAD(vThuTu%' AS KhoaTheoThuTuChon,
  ROUTINE_DEFINITION LIKE '%vSiSo1%' AS DocHaiLan FROM information_schema.ROUTINES
  WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_NAME='SP_DangKyNhieuHocPhan'`);
console.log(`\n   KIỂM TRA DB: khóa-theo-thứ-tự-tick = ${r5.KhoaTheoThuTuChon} (mong đợi 1) · đọc-2-lần = ${r5.DocHaiLan} (mong đợi 0)`);
const [sv030] = await q(`SELECT TrangThaiDangKy FROM DANGKYHOCPHAN WHERE MaSV='SV030' AND MaLHP='LHP514'`);
console.log(`   Dòng DA_HUY của SV030 ở LHP514: ${sv030 ? sv030.TrangThaiDangKy : '(không có)'} (mong đợi DA_HUY)`);

// 4) FIX lần cuối để trả hệ thống về bản thật
console.log('\n\n▶ CLICK CUỐI: [✔ FIX]');
const fx2 = await goi('/api/prepare/fix', { method: 'POST', headers: H, body: '{}' });
console.log(`   HTTP ${fx2.status} · ${fx2.body.thongDiep || fx2.body.error}`);
inTT('TRẠNG THÁI CUỐI', fx2.body);

console.log('\n' + '='.repeat(78));
console.log('KẾT LUẬN');
console.log('='.repeat(78));
console.log(`   Nút CHUẨN BỊ (DEMO)    : ${cb.body.thanhCong ? '✔ OK' : '✖ LỖI'} — 3 bước (2 SP + dữ liệu)`);
console.log(`   Nút CHUẨN BỊ (DEADLOCK): ${dl.body.thanhCong ? '✔ OK' : '✖ LỖI'}`);
console.log(`   Nút FIX                : ${fx.body.thanhCong && fx2.body.thanhCong ? '✔ OK (2 lần)' : '✖ LỖI'}`);
await c.end();
