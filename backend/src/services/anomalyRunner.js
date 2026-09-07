// ============================================================
// services/anomalyRunner.js — Chạy 4 kịch bản lỗi concurrency (2 session)
// dùng cho API demo (controllers/concurrency.controller.js → routes/concurrency.js).
// Đây là MODULE DEMO ĐẶC THÙ (SERVICE layer): phải chạy session SQL thô để
// "tắt phòng chống" — là NGOẠI LỆ có chủ đích của quy tắc "không raw query"
// (xem scripts/audit-no-raw-query.mjs).
// Mỗi pha trả về: { ten, tieuDe, moTaTat, buoc: [{phien, moTa, ketQua}], ketLuan }
// Chỉ tác động LHP514 + 4 SV thử nghiệm (SV030/SV041/SV060/SV999),
// kết thúc luôn gọi SP_ChuanBi_Demo_4Anomaly để trả về trạng thái an toàn.
// ============================================================
import { pool } from '../db.js';

export const LHP_DEMO = 'LHP514';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Các connection đang mở của PHA HIỆN TẠI — để dọn dẹp khi pha lỗi giữa chừng.
const connDangMo = new Set();

async function newConn(isolation = null) {
  const conn = await pool.getConnection();
  if (isolation) await conn.query(`SET SESSION TRANSACTION ISOLATION LEVEL ${isolation}`);
  const releaseGoc = conn.release.bind(conn);
  conn.release = () => { conn._daTra = true; releaseGoc(); };
  connDangMo.add(conn);
  return conn;
}

async function scalar(conn, sql, params = []) {
  const [rows] = await conn.query(sql, params);
  return Object.values(rows[0])[0];
}

async function siso(conn, malhp = LHP_DEMO) {
  return Number(await scalar(conn, 'SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = ?', [malhp]));
}
async function sisoToiDa(conn, malhp = LHP_DEMO) {
  return Number(await scalar(conn, 'SELECT SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP = ?', [malhp]));
}
async function demDK(conn, malhp = LHP_DEMO) {
  return Number(await scalar(conn,
    `SELECT COUNT(*) FROM DANGKYHOCPHAN WHERE MaLHP = ? AND TrangThaiDangKy = 'DA_DANG_KY'`, [malhp]));
}

async function chuanBi(conn, malhp = LHP_DEMO) {
  await conn.query('CALL SP_ChuanBi_Demo_4Anomaly(?)', [malhp]);
}

// Nội dung tương đương SP_DangKyHocPhan_ChuaFix (bung từng bước để demo)
async function batDauGiaoTac(conn) { await conn.beginTransaction(); }
async function docSiSoChuaFix(conn) {
  return Number(await scalar(conn,
    `SELECT lhp.SiSoHienTai AS v
     FROM LOPHOCPHAN lhp JOIN MONHOC mh ON mh.MaMonHoc = lhp.MaMonHoc
     WHERE lhp.MaLHP = ?`, [LHP_DEMO]));
}
async function ghiDangKy(conn, maSV, ghiChu) {
  await conn.query(
    `INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
     VALUES (?, ?, NOW(), 'DA_DANG_KY', ?)`, [maSV, LHP_DEMO, ghiChu]);
}

// ---------- PHA 1: MySQL REPEATABLE READ ĐANG PHÒNG CHỐNG ----------
async function phaRRChan() {
  const buoc = [];
  let datTong = true;

  // 1a Dirty read bị chặn
  const B = await newConn();
  await B.beginTransaction();
  await B.query(`UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP = ?`, [LHP_DEMO]);
  const baseA = await siso(B) - 1;
  const A = await newConn('REPEATABLE READ');
  const doc1a = await scalar(A, 'SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = ?', [LHP_DEMO]);
  buoc.push({ phien: 'B', moTa: `UPDATE sĩ số ${baseA} → ${baseA + 1} (CHƯA commit)`, ketQua: 'đang giữ khóa, chưa chốt sổ' });
  buoc.push({ phien: 'A', moTa: 'SELECT sĩ số (REPEATABLE READ)', ketQua: `thấy ${doc1a} (giá trị đã commit)` });
  const dat1a = Number(doc1a) === baseA;
  buoc.push({ phien: 'Kết luận', moTa: 'Dirty Read bị chặn (không thấy dữ liệu chưa commit)', ketQua: dat1a ? 'PASS ✅' : 'FAIL ❌' });
  datTong = datTong && dat1a;
  await B.rollback(); await A.rollback();
  A.release(); B.release();

  // 1b Unrepeatable read bị chặn
  const A2 = await newConn('REPEATABLE READ');
  const B2 = await newConn();
  await A2.beginTransaction();
  const v1 = await siso(A2);
  await B2.query(`UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP = ?`, [LHP_DEMO]);
  const v2 = await siso(A2);
  buoc.push({ phien: 'B', moTa: 'UPDATE + COMMIT (sửa dữ liệu giữa 2 lần đọc)', ketQua: 'đã chốt' });
  buoc.push({ phien: 'A', moTa: 'đọc lại trong CÙNG giao dịch (REPEATABLE READ)', ketQua: `vẫn là ${v2} (bằng lần đọc đầu ${v1})` });
  const dat1b = v1 === v2;
  buoc.push({ phien: 'Kết luận', moTa: 'Unrepeatable Read bị chặn (snapshot không đổi)', ketQua: dat1b ? 'PASS ✅' : 'FAIL ❌' });
  datTong = datTong && dat1b;
  await A2.rollback(); A2.release(); B2.release();

  // 1c Phantom bị chặn
  const A3 = await newConn('REPEATABLE READ');
  const B3 = await newConn();
  await A3.beginTransaction();
  const c1 = await demDK(A3);
  await B3.query(`INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
                  VALUES ('SV999', ?, NOW(), 'DA_DANG_KY', 'web demo phantom')`, [LHP_DEMO]);
  const c2 = await demDK(A3);
  buoc.push({ phien: 'B', moTa: 'INSERT SV999 + COMMIT (dòng mới chèn vào)', ketQua: 'đã chốt' });
  buoc.push({ phien: 'A', moTa: 'đếm lại trong CÙNG giao dịch (REPEATABLE READ)', ketQua: `vẫn là ${c2} (không thấy "bóng ma")` });
  const dat1c = c1 === c2;
  buoc.push({ phien: 'Kết luận', moTa: 'Phantom Read bị chặn (với SELECT thường)', ketQua: dat1c ? 'PASS ✅' : 'FAIL ❌' });
  datTong = datTong && dat1c;
  await A3.rollback(); A3.release(); B3.release();

  const admin = await newConn();
  await chuanBi(admin); admin.release();

  return {
    ten: 'rr-chan',
    tieuDe: 'MySQL mặc định (REPEATABLE READ) đang phòng chống 3/4 lỗi',
    moTaTat: 'Chứng minh MySQL REPEATABLE-READ + MVCC chặn sẵn Dirty Read, Unrepeatable Read, Phantom Read.',
    buoc,
    ketLuan: { dat: datTong, noiDung: datTong
      ? 'MySQL mặc định đã chặn 3/4 lỗi → muốn demo phải "tắt" bằng cách hạ isolation level.'
      : 'Có pha không đúng kỳ vọng — xem chi tiết từng bước.' },
  };
}

// ---------- PHA 2: LOST UPDATE (thủ tục chưa fix) ----------
async function phaLostUpdate() {
  const buoc = [];
  const admin = await newConn();
  await chuanBi(admin);
  const MAX = await sisoToiDa(admin);
  admin.release();

  const A = await newConn();
  const B = await newConn();

  await batDauGiaoTac(A);
  const sA = await docSiSoChuaFix(A);
  await batDauGiaoTac(B);
  const sB = await docSiSoChuaFix(B);
  buoc.push({ phien: 'A', moTa: 'START TRANSACTION → đọc sĩ số KHÔNG khóa (SP_ChuaFix bước 6)', ketQua: `thấy ${sA} (còn 1 chỗ)` });
  buoc.push({ phien: 'B', moTa: 'START TRANSACTION → đọc sĩ số KHÔNG khóa', ketQua: `cũng thấy ${sB} (còn 1 chỗ!)` });

  await ghiDangKy(A, 'SV030', 'Web demo - Phien A chua fix');
  let thoiGianCho = 0;
  const t0 = Date.now();
  const pB = ghiDangKy(B, 'SV041', 'Web demo - Phien B chua fix')
    .finally(() => { thoiGianCho = ((Date.now() - t0) / 1000).toFixed(1); });
  buoc.push({ phien: 'A', moTa: 'INSERT SV030 (trigger +1) — chưa commit, giữ khóa', ketQua: 'đã ghi trong giao dịch' });
  buoc.push({ phien: 'B', moTa: 'INSERT SV041 → chờ khóa của A…', ketQua: 'BỊ CHẶN (chờ phiên A COMMIT)' });

  await A.commit();
  await pB;
  await B.commit();
  buoc.push({ phien: 'A', moTa: 'COMMIT', ketQua: 'số chỗ cạn — hợp lệ' });
  buoc.push({ phien: 'B', moTa: `được đi qua sau ${thoiGianCho}s chờ → COMMIT`, ketQua: 'cũng "thành công"' });

  const admin2 = await newConn();
  const dem = await demDK(admin2);
  const cuoi = await siso(admin2);
  admin2.release();
  buoc.push({ phien: 'Kiểm tra', moTa: 'đếm số đăng ký thực tế của LHP514', ketQua: `${dem} SV đã ĐK trong khi lớp chỉ đủ ${MAX} chỗ` });

  const dat = dem === MAX + 1 && dem > MAX;
  A.release(); B.release();
  const admin3 = await newConn();
  await chuanBi(admin3); admin3.release();

  return {
    ten: 'lost-update',
    tieuDe: 'Lost Update — thủ tục ban đầu CHƯA FIX (thiếu FOR UPDATE)',
    moTaTat: '2 phiên cùng đọc "còn 1 chỗ" (không khóa) → cùng được ghi → số đăng ký vượt sĩ số tối đa.',
    buoc,
    ketLuan: { dat, noiDung: dat
      ? `LOST UPDATE xảy ra: ${dem} đăng ký > ${MAX} chỗ (bộ đếm sĩ số kẹt ở ${cuoi} vì trigger LEAST — dữ liệu hỏng âm thầm).`
      : `Kết quả không như kỳ vọng (dem=${dem}, max=${MAX}).` },
  };
}

// ---------- PHA 3: DIRTY READ ----------
async function phaDirtyRead() {
  const buoc = [];
  const admin = await newConn();
  await chuanBi(admin);
  const BASE = await siso(admin);
  admin.release();

  const B = await newConn();
  await B.beginTransaction();
  await B.query(`UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP = ?`, [LHP_DEMO]);
  buoc.push({ phien: 'B', moTa: `UPDATE sĩ số ${BASE} → ${BASE + 1} (CHƯA commit — "về nguyên tắc chưa chốt sổ")`, ketQua: 'đang giữ khóa ghi' });

  const A = await newConn('READ UNCOMMITTED');
  await A.beginTransaction();
  const docBan = await scalar(A, 'SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = ?', [LHP_DEMO]);
  buoc.push({ phien: 'A', moTa: 'SELECT sĩ số (SAU KHI TẮT phòng chống: READ UNCOMMITTED)', ketQua: `thấy ${docBan} — dữ liệu B CHƯA COMMIT = ĐỌC BẨN` });

  await B.rollback();
  const docSau = await scalar(A, 'SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = ?', [LHP_DEMO]);
  buoc.push({ phien: 'B', moTa: 'ROLLBACK — giao dịch ghi bị hủy', ketQua: `giá trị ${BASE + 1} chưa từng tồn tại` });
  buoc.push({ phien: 'A', moTa: 'đọc lại', ketQua: `thấy ${docSau} → quyết định dựa trên ${docBan} vừa rồi là SAI` });

  const dat = Number(docBan) === BASE + 1 && Number(docSau) === BASE;
  A.release(); B.release();
  const admin2 = await newConn();
  await chuanBi(admin2); admin2.release();

  return {
    ten: 'dirty-read',
    tieuDe: 'Dirty Read — tắt phòng chống bằng READ UNCOMMITTED',
    moTaTat: 'Phiên đọc hạ xuống READ UNCOMMITTED → nhìn thấu dữ liệu chưa commit → dữ liệu "biến mất" sau rollback.',
    buoc,
    ketLuan: { dat, noiDung: dat
      ? `DIRTY READ xảy ra: đọc được ${docBan} (chưa commit), sau rollback chỉ còn ${docSau}.`
      : `Kết quả không như kỳ vọng (docBan=${docBan}, docSau=${docSau}).` },
  };
}

// ---------- PHA 4: UNREPEATABLE READ ----------
async function phaUnrepeatableRead() {
  const buoc = [];
  const admin = await newConn();
  await chuanBi(admin);
  admin.release();

  const A = await newConn('READ COMMITTED');
  const B = await newConn();
  await A.beginTransaction();
  const v1 = await scalar(A, 'SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = ?', [LHP_DEMO]);
  buoc.push({ phien: 'A', moTa: 'SELECT lần 1 (READ COMMITTED — khóa đọc chỉ tồn tại lúc SELECT)', ketQua: `thấy ${v1}` });

  await B.query(`UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP = ?`, [LHP_DEMO]);
  await B.commit();
  buoc.push({ phien: 'B', moTa: 'UPDATE + COMMIT (sửa dữ liệu ngay giữa 2 lần đọc)', ketQua: 'đã chốt' });

  const v2 = await scalar(A, 'SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = ?', [LHP_DEMO]);
  buoc.push({ phien: 'A', moTa: 'SELECT lần 2 — trong CÙNG giao dịch', ketQua: `thấy ${v2} (khác lần 1!)` });

  const dat = Number(v2) === Number(v1) + 1;
  A.release(); B.release();
  const admin2 = await newConn();
  await chuanBi(admin2); admin2.release();

  return {
    ten: 'unrepeatable-read',
    tieuDe: 'Unrepeatable Read — tắt phòng chống bằng READ COMMITTED',
    moTaTat: 'READ COMMITTED tạo snapshot mới sau mỗi SELECT → giữa 2 lần đọc, dữ liệu đổi khiến kết quả không lặp lại được.',
    buoc,
    ketLuan: { dat, noiDung: dat
      ? `UNREPEATABLE READ xảy ra: cùng 1 giao tác đọc ${v1} rồi ${v2}.`
      : `Kết quả không như kỳ vọng (v1=${v1}, v2=${v2}).` },
  };
}

// ---------- PHA 5: PHANTOM READ ----------
async function phaPhantomRead() {
  const buoc = [];
  const admin = await newConn();
  await chuanBi(admin);
  admin.release();

  const A = await newConn('READ COMMITTED');
  const B = await newConn();
  await A.beginTransaction();
  const c1 = await demDK(A);
  buoc.push({ phien: 'A', moTa: 'đếm số đăng ký LHP514 lần 1 (READ COMMITTED)', ketQua: `${c1} dòng` });

  await B.query(`INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
                 VALUES ('SV999', ?, NOW(), 'DA_DANG_KY', 'Web demo - bong ma')`, [LHP_DEMO]);
  await B.commit();
  buoc.push({ phien: 'B', moTa: 'INSERT SV999 + COMMIT (dòng mới vừa chèn)', ketQua: 'đã chốt' });

  const c2 = await demDK(A);
  buoc.push({ phien: 'A', moTa: 'đếm lại trong CÙNG giao dịch', ketQua: `${c2} dòng — xuất hiện ${c2 - c1} "bóng ma" A không hề chèn` });

  const dat = c2 === c1 + 1;
  A.release(); B.release();
  const admin2 = await newConn();
  await chuanBi(admin2); admin2.release();

  return {
    ten: 'phantom-read',
    tieuDe: 'Phantom Read — tắt phòng chống bằng READ COMMITTED',
    moTaTat: 'Tập kết quả thêm dòng giữa 2 lần đọc trong 1 giao dịch — dòng "bóng ma" xuất hiện.',
    buoc,
    ketLuan: { dat, noiDung: dat
      ? `PHANTOM READ xảy ra: COUNT ${c1} → ${c2} do dòng SV999 xuất hiện.`
      : `Kết quả không như kỳ vọng (c1=${c1}, c2=${c2}).` },
  };
}

// ---------- PHA 6: SP ĐÃ FIX (FOR UPDATE) ----------
async function phaSPFix() {
  const buoc = [];
  const admin = await newConn();
  // Chọn LHP không có môn tiên quyết để 2 SV chỉ tranh ở bước sĩ số
  const RACE_LHP = await scalar(admin, `
    SELECT lhp.MaLHP FROM LOPHOCPHAN lhp
    LEFT JOIN MONHOC_TIENQUYET mtq ON mtq.MaMonHoc = lhp.MaMonHoc
    WHERE lhp.MaHocKy = 'HK1-2025' AND lhp.TrangThaiLop = 'MO_DANG_KY'
      AND mtq.MaMonHoc IS NULL AND lhp.MaLHP <> ?
    ORDER BY lhp.MaLHP LIMIT 1`, [LHP_DEMO]);
  await chuanBi(admin, RACE_LHP);
  const MAX = await sisoToiDa(admin, RACE_LHP);
  const BASE = await siso(admin, RACE_LHP);
  admin.release();
  buoc.push({ phien: 'Chuẩn bị', moTa: `LHP ${RACE_LHP} về trạng thái ${BASE}/${MAX} (còn đúng 1 chỗ)`, ketQua: 'sẵn sàng' });

  const A = await newConn();
  const B = await newConn();
  const call = (conn, sv, phien) => conn
    .query('CALL SP_DangKyHocPhan(?, ?, ?, ?, @kq)', [sv, RACE_LHP, 24, `Web demo - Phien ${phien} da fix`])
    .then(() => scalar(conn, 'SELECT @kq'));

  const [ra, rb] = await Promise.all([call(A, 'SV030', 'A'), call(B, 'SV041', 'B')]);
  buoc.push({ phien: 'A', moTa: 'CALL SP_DangKyHocPhan (có SELECT ... FOR UPDATE bước 6)', ketQua: `mã kết quả = ${ra}` });
  buoc.push({ phien: 'B', moTa: 'CALL SP_DangKyHocPhan — bị chờ khóa dòng sĩ số, sau khi A commit kiểm tra lại', ketQua: `mã kết quả = ${rb}` });

  const admin2 = await newConn();
  const dem = await demDK(admin2, RACE_LHP);
  const cuoi = await siso(admin2, RACE_LHP);
  admin2.release();
  buoc.push({ phien: 'Kiểm tra', moTa: `số đăng ký thực tế của ${RACE_LHP}`, ketQua: `${dem} SV — sĩ số cuối ${cuoi}/${MAX}` });

  const dat = ((ra === 0 && rb === 105) || (rb === 0 && ra === 105)) && dem <= MAX;
  A.release(); B.release();
  const admin3 = await newConn();
  await chuanBi(admin3, RACE_LHP); admin3.release();

  return {
    ten: 'sp-fix',
    tieuDe: 'SP đã FIX (FOR UPDATE) — chỉ 1 phiên thắng, không Lost Update',
    moTaTat: '2 phiên chạy SP_DangKyHocPhan cùng lúc giành chỗ cuối: phiên sau chờ khóa, kiểm tra lại sĩ số → 105 (lớp đầy).',
    buoc,
    ketLuan: { dat, noiDung: dat
      ? `PHÒNG CHỐNG THÀNH CÔNG: 1 phiên thắng (rc=0), phiên kia bị từ chối (rc=105), sĩ số đúng ${dem}/${MAX}.`
      : `Kết quả không như kỳ vọng (A=${ra}, B=${rb}, dem=${dem}, max=${MAX}).` },
  };
}

export const PHAS = {
  'rr-chan': phaRRChan,
  'lost-update': phaLostUpdate,
  'dirty-read': phaDirtyRead,
  'unrepeatable-read': phaUnrepeatableRead,
  'phantom-read': phaPhantomRead,
  'sp-fix': phaSPFix,
};

// Các pha LUÔN chạy TUẦN TỰ (hàng đợi): bấm 2 nút cùng lúc cũng tự xếp hàng,
// tránh 2 kịch bản phá trạng thái LHP demo của nhau / tránh PK SV030.
// Mỗi pha chạy xong (hoặc LỖI giữa chừng) connection đều được reset isolation
// về REPEATABLE READ (mặc định của DB) rồi trả pool — an toàn cho lần chạy sau.
let hangDoi = Promise.resolve();
export function chayPha(ten) {
  const ketQua = hangDoi.then(async () => {
    const fn = PHAS[ten];
    if (!fn) return null;
    const truocKhiChay = new Set(connDangMo);
    try {
      return await fn();
    } finally {
      for (const c of connDangMo) {
        if (truocKhiChay.has(c) || c._daTra) continue;
        try { await c.query('SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ'); } catch { /* bỏ qua */ }
        try { await c.rollback(); } catch { /* không trong transaction — an toàn */ }
        try { c.release(); } catch { /* bỏ qua */ }
      }
    }
  });
  hangDoi = ketQua.catch(() => {});
  return ketQua;
}

export async function trangThai() {
  const conn = await newConn();
  const [r] = await conn.query(
    `SELECT VERSION() AS ver, @@session.transaction_isolation AS iso,
            (SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = ?) AS SiSoHienTai,
            (SELECT SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP = ?) AS SiSoToiDa,
            (SELECT COUNT(*) FROM DANGKYHOCPHAN WHERE MaLHP = ? AND TrangThaiDangKy='DA_DANG_KY') AS SoDK,
            (SELECT COUNT(*) FROM information_schema.ROUTINES
              WHERE ROUTINE_SCHEMA = DATABASE() AND ROUTINE_NAME IN
                ('SP_DangKyHocPhan_ChuaFix','SP_ChuanBi_Demo_4Anomaly','SP_DangKyHocPhan_NangCao')) AS SPDemo
     `, [LHP_DEMO, LHP_DEMO, LHP_DEMO]);
  conn.release();
  return r[0];
}

export async function chuanBiDemo() {
  const conn = await newConn();
  await chuanBi(conn);
  const st = await trangThai();
  conn.release();
  return st;
}
