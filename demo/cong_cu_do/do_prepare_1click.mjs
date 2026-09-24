// ============================================================================
// demo/cong_cu_do/do_prepare_1click.mjs
// KIỂM CHỨNG TRANG “CHUẨN BỊ DEMO” (/chuan-bi-demo) — 2 nút 1-CLICK
//   GET  /api/prepare/trang-thai             → đang ở bản nào / dữ liệu đã sạch chưa
//   POST /api/prepare/chuan-bi { kichBan }   → triển khai bản có lỗi + dựng lại dữ liệu
//   POST /api/prepare/fix                    → khôi phục bản thật + dựng lại dữ liệu
//
//   Chạy cả 5 kịch bản: LOST_UPDATE · NRR · PHANTOM · DIRTY_READ · DEADLOCK
//   rồi bấm FIX để trả hệ thống về bản chính thức.
//
//   Chạy:  node demo/cong_cu_do/do_prepare_1click.mjs
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
const token = (await goi('/api/auth/login', {
  method: 'POST', headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ TenDangNhap: 'admin', MatKhau: 'admin@123' }),
})).body.token;
const H = { 'Content-Type': 'application/json', Authorization: 'Bearer ' + token };

const tt = async () => (await goi('/api/prepare/trang-thai', { headers: H })).body;

// ── Kỳ vọng của từng kịch bản ───────────────────────────────────────────────
//   donKy  : FOR UPDATE / DO SLEEP / proc_dirty_writer  (SP_DangKyHocPhan)
//   nhieu  : vSiSo1 (đọc 2 lần) / LPAD (khóa theo thứ tự tick) / _ru / _rr
const KY_VONG = {
  LOST_UPDATE: { donKy: { FU: 0, Sleep: 1, Writer: 0 }, nhieu: { Doc2Lan: 0, Tick: 0 }, chip: 'LOST_UPDATE',   soDK: 231, lech: 0, sot: 0 },
  NRR:         { donKy: { FU: 1, Sleep: 0, Writer: 0 }, nhieu: { Doc2Lan: 1, Tick: 0 }, chip: 'NRR_PHANTOM',  soDK: 231, lech: 0, sot: 0 },
  PHANTOM:     { donKy: { FU: 1, Sleep: 0, Writer: 0 }, nhieu: { Doc2Lan: 1, Tick: 0 }, chip: 'NRR_PHANTOM',  soDK: 231, lech: 0, sot: 0 },
  DIRTY_READ:  { donKy: { FU: 0, Sleep: 1, Writer: 1 }, nhieu: { Doc2Lan: 1, Tick: 0 }, chip: 'DIRTY_READ',   soDK: 231, lech: 0, sot: 0 },
  DEADLOCK:    { donKy: { FU: 1, Sleep: 0, Writer: 0 }, nhieu: { Doc2Lan: 0, Tick: 1 }, chip: 'DEADLOCK',     soDK: 232, lech: 0, sot: 0 },
};
const KY_VONG_FIX = { donKy: { FU: 1, Sleep: 0, Writer: 0 }, nhieu: { Doc2Lan: 0, Tick: 0 }, soDK: 231, lech: 0, sot: 0 };

let soLoi = 0;
const kt = (dat, moTa, thucTe) => {
  if (!dat) soLoi++;
  console.log(`     ${dat ? '✔' : '✖'} ${moTa}${thucTe !== undefined ? ` — thực tế: ${thucTe}` : ''}`);
};

const docSP = async () => {
  const [dk] = await q(`SELECT ROUTINE_DEFINITION LIKE '%FOR UPDATE%'          AS FU,
      ROUTINE_DEFINITION LIKE '%DO SLEEP%'           AS Sleep,
      ROUTINE_DEFINITION LIKE '%proc_dirty_writer%'  AS Writer
    FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_NAME='SP_DangKyHocPhan'`);
  const [nh] = await q(`SELECT ROUTINE_DEFINITION LIKE '%vSiSo1%'             AS Doc2Lan,
      ROUTINE_DEFINITION LIKE '%LPAD(vThuTu%'       AS Tick,
      ROUTINE_DEFINITION LIKE '%proc_dirty_read_ru%' AS RU,
      ROUTINE_DEFINITION LIKE '%proc_dirty_read_rr%' AS RR
    FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_NAME='SP_DangKyNhieuHocPhan'`);
  return {
    donKy: { FU: Number(dk.FU), Sleep: Number(dk.Sleep), Writer: Number(dk.Writer) },
    nhieu: { Doc2Lan: Number(nh.Doc2Lan), Tick: Number(nh.Tick), RU: Number(nh.RU), RR: Number(nh.RR) },
  };
};

// Đếm "dấu vết" còn sót trong DB (kiểm chứng độc lập với API)
const demRac = async () => {
  const [r] = await q(`SELECT
    (SELECT COUNT(*) FROM DANGKYHOCPHAN d JOIN LOPHOCPHAN l ON l.MaLHP=d.MaLHP
      WHERE l.MaHocKy='HK1-2025') AS SoDangKy,
    (SELECT COUNT(*) FROM LOPHOCPHAN l WHERE l.SiSoHienTai <> (SELECT COUNT(*) FROM DANGKYHOCPHAN d
      WHERE d.MaLHP=l.MaLHP AND d.TrangThaiDangKy='DA_DANG_KY')) AS SoLopLech,
    (SELECT COUNT(*) FROM DANGKYHOCPHAN d JOIN LOPHOCPHAN l ON l.MaLHP=d.MaLHP
      WHERE l.MaHocKy='HK1-2025' AND d.TrangThaiDangKy='DA_DANG_KY'
        AND d.MaSV IN ('SV001','SV003','SV004','SV030','SV041','SV060','SV999')
        AND d.MaLHP IN ('LHP505','LHP506','LHP507','LHP508','LHP514')) AS SoDauVetDemo,
    (SELECT COUNT(*) FROM DANGKYHOCPHAN d JOIN LOPHOCPHAN l ON l.MaLHP=d.MaLHP
      WHERE l.MaHocKy='HK1-2025' AND d.TrangThaiDangKy<>'DA_DANG_KY') AS SoDongKhongHieuLuc`);
  return r;
};

const inTT = (nhan, t) => {
  const d = t.danhGia || {};
  const hk = t.hocKy || {};
  console.log(`\n── ${nhan} ──────────────────────────────────────────`);
  console.log(`   SP_DangKyHocPhan       : ${d.lostUpdate?.cheDo}  — ${d.lostUpdate?.nhan}`);
  console.log(`   SP_DangKyNhieuHocPhan  : ${d.nhieuHocPhan?.cheDo}  — ${d.nhieuHocPhan?.nhan}`);
  console.log(`   Chip “Kịch bản sẵn sàng”: ${d.kichBanSanSang ? d.kichBanSanSang.ma : '(không có — cả 2 SP là bản thật)'}`);
  console.log(`   Lớp demo: ` + (t.lopDemo || []).map((l) => `${l.MaLHP}=${l.SiSoHienTai}/${l.SiSoToiDa}`).join(' · '));
  console.log(`   Dữ liệu ${hk.MaHocKy || '?'}       : ${hk.SoDangKy} đăng ký · lệch sĩ số ${hk.SoLopLechSiSo} lớp · `
    + `dấu vết demo ${hk.SoDauVetDemo} · dòng không hiệu lực ${hk.SoDongKhongHieuLuc}`);
  console.log(`   Đợt đăng ký            : ${hk.TrangThaiDot}${hk.DangMoDangKy ? ' (còn hạn)' : ' (HẾT HẠN/ĐÃ ĐÓNG)'}`
    + `  ⇒  ${hk.SanSang ? '✔ SẴN SÀNG SỬ DỤNG' : '✖ CHƯA SẴN SÀNG'}`);
};

console.log('='.repeat(80));
console.log('KIỂM CHỨNG TRANG “CHUẨN BỊ DEMO” — 5 kịch bản + nút FIX');
console.log('='.repeat(80));

inTT('0. TRẠNG THÁI BAN ĐẦU', await tt());

for (const ma of Object.keys(KY_VONG)) {
  const kv = KY_VONG[ma];
  console.log(`\n\n▶ [⚙ CHUẨN BỊ DEMO] — kịch bản ${ma}`);
  const r = await goi('/api/prepare/chuan-bi', { method: 'POST', headers: H, body: JSON.stringify({ kichBan: ma }) });
  console.log(`   HTTP ${r.status} · ${r.body.thongDiep || r.body.error || ''}`);
  (r.body.nhat_ky || []).forEach((b) => console.log(`     ${b.ok ? '✔' : '✖'} ${b.buoc}`));
  kt(r.status === 200 && r.body.thanhCong === true, 'HTTP 200 + thanhCong');
  kt((r.body.nhat_ky || []).length === 4 && r.body.nhat_ky.every((b) => b.ok), 'đủ 4 dòng nhật ký, tất cả ✔');
  inTT(`SAU KHI CHUẨN BỊ ${ma}`, r.body);

  const sp = await docSP();
  const d = await demRac();
  console.log(`   KIỂM TRA DB:`);
  kt(JSON.stringify(sp.donKy) === JSON.stringify(kv.donKy), 'SP_DangKyHocPhan (FU/Sleep/Writer)', JSON.stringify(sp.donKy));
  kt(sp.nhieu.Doc2Lan === kv.nhieu.Doc2Lan && sp.nhieu.Tick === kv.nhieu.Tick,
    'SP_DangKyNhieuHocPhan (đọc-2-lần / khóa-theo-thứ-tự-tick)', `${sp.nhieu.Doc2Lan} / ${sp.nhieu.Tick}`);
  kt(r.body.danhGia?.kichBanSanSang?.ma === kv.chip, 'chip “Kịch bản đang sẵn sàng”', r.body.danhGia?.kichBanSanSang?.ma);
  kt(d.SoDangKy === kv.soDK && d.SoLopLech === kv.lech && d.SoDauVetDemo === kv.sot,
    `dữ liệu sạch (đăng ký/lệch/sót = ${kv.soDK}/${kv.lech}/${kv.sot})`,
    `${d.SoDangKy}/${d.SoLopLech}/${d.SoDauVetDemo}`);
  if (ma === 'DEADLOCK') {
    const [sv030] = await q(`SELECT TrangThaiDangKy FROM DANGKYHOCPHAN WHERE MaSV='SV030' AND MaLHP='LHP514'`);
    kt(sv030 && sv030.TrangThaiDangKy === 'DA_HUY', 'SV030 có dòng DA_HUY ở LHP514 (thế cờ deadlock)', sv030?.TrangThaiDangKy);
  }
  if (ma === 'LOST_UPDATE') {
    const [l] = await q(`SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP='LHP506'`);
    kt(l.SiSoHienTai === 0 && l.SiSoToiDa === 1, 'LHP506 = 0/1 (còn đúng 1 chỗ)', `${l.SiSoHienTai}/${l.SiSoToiDa}`);
  }
  if (ma === 'DIRTY_READ' || ma === 'NRR') {
    const [l] = await q(`SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP='LHP507'`);
    kt(l.SiSoHienTai === 0, 'LHP507 sĩ số = 0 (sạch)', `${l.SiSoHienTai}/${l.SiSoToiDa}`);
  }
}

console.log('\n\n▶ [✔ FIX] — khôi phục bản thật');
const fx = await goi('/api/prepare/fix', { method: 'POST', headers: H, body: '{}' });
console.log(`   HTTP ${fx.status} · ${fx.body.thongDiep || fx.body.error || ''}`);
(fx.body.nhat_ky || []).forEach((b) => console.log(`     ${b.ok ? '✔' : '✖'} ${b.buoc}`));
kt(fx.status === 200 && fx.body.thanhCong === true, 'HTTP 200 + thanhCong');
kt((fx.body.nhat_ky || []).length === 4 && fx.body.nhat_ky.every((b) => b.ok),
  'đủ 4 dòng nhật ký (2 SP + ♻ dữ liệu + tổng kết), tất cả ✔');
inTT('TRẠNG THÁI CUỐI', fx.body);
const spCuoi = await docSP();
const dCuoi = await demRac();
console.log(`   KIỂM TRA DB:`);
kt(JSON.stringify(spCuoi.donKy) === JSON.stringify(KY_VONG_FIX.donKy), 'SP_DangKyHocPhan = bản THẬT', JSON.stringify(spCuoi.donKy));
kt(JSON.stringify(spCuoi.nhieu) === JSON.stringify({ Doc2Lan: 0, Tick: 0, RU: 0, RR: 0 }),
  'SP_DangKyNhieuHocPhan = bản THẬT', JSON.stringify(spCuoi.nhieu));
kt(!fx.body.danhGia?.kichBanSanSang, 'chip “Kịch bản sẵn sàng” đã biến mất', fx.body.danhGia?.kichBanSanSang?.ma || '(không có)');
kt(dCuoi.SoDangKy === KY_VONG_FIX.soDK && dCuoi.SoLopLech === KY_VONG_FIX.lech && dCuoi.SoDauVetDemo === KY_VONG_FIX.sot,
  `dữ liệu sạch (${KY_VONG_FIX.soDK}/${KY_VONG_FIX.lech}/${KY_VONG_FIX.sot})`,
  `${dCuoi.SoDangKy}/${dCuoi.SoLopLech}/${dCuoi.SoDauVetDemo}`);

console.log('\n' + '='.repeat(80));
console.log(soLoi === 0 ? '✅ KẾT LUẬN: TẤT CẢ ✔ — trang “Chuẩn bị Demo” dùng được cho cả 5 kịch bản + nút FIX'
  : `❌ KẾT LUẬN: còn ${soLoi} mục KHÔNG đạt — xem các dòng ✖ ở trên`);
console.log('='.repeat(80));
await c.end();
process.exit(soLoi === 0 ? 0 : 1);
