// ============================================================
// test-anomaly-live.mjs
// DEMO & KIEM TRU 4 LOI CONCURRENCY TREN MYSQL THAT (2 session):
//   Pha 0: Chuan bi du lieu (SP_ChuanBi_Demo_4Anomaly 'LHP514')
//   Pha 1: Chung minh MySQL REPEATABLE READ DANG PHONG CHONG
//          Dirty Read / Unrepeatable Read / Phantom
//   Pha 2: LOST UPDATE     — thu tuc CHUA FIX (thieu FOR UPDATE)
//   Pha 3: DIRTY READ      — ha xuong READ UNCOMMITTED
//   Pha 4: UNREPEATABLE READ — ha xuong READ COMMITTED
//   Pha 5: PHANTOM READ    — ha xuong READ COMMITTED
//   Pha 6: SP_DangKyHocPhan (DA FIX) — 2 phien gianh cho cuoi,
//          chi 1 phien thang => khong Lost Update
// Chay: cd backend && node scripts/test-anomaly-live.mjs
// ============================================================
import 'dotenv/config';
import mysql from 'mysql2/promise';

const cfg = {
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  charset: 'utf8mb4_unicode_ci',
  connectTimeout: 15000,
};

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const LHP = 'LHP514';

async function newConn(isolation = null) {
  const c = await mysql.createConnection(cfg);
  if (isolation) await c.query(`SET SESSION TRANSACTION ISOLATION LEVEL ${isolation}`);
  return c;
}

async function scalar(c, sql, params = []) {
  const [rows] = await c.query(sql, params);
  return Object.values(rows[0])[0];
}

async function siso(c, malhp = LHP) {
  return scalar(c, 'SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = ?', [malhp]);
}
async function sisoToiDa(c, malhp = LHP) {
  return scalar(c, 'SELECT SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP = ?', [malhp]);
}

async function chuanBi(c, malhp = LHP) {
  await c.query('CALL SP_ChuanBi_Demo_4Anomaly(?)', [malhp]);
}

// Noi dung tuong duong SP_DangKyHocPhan_ChuaFix (bung tung buoc de
// dung giua chung giao dich — giong hanh vi "thu tuc ban dau chua fix")
async function batDauGiaoTac(c) {
  await c.beginTransaction();                       // START TRANSACTION (trong SP)
}
async function docSiSoChuaFix(c) {
  // BUOC 6 CHUA FIX: doc SiSo KHONG khoa (2 phien doc cung 1 gia tri)
  return scalar(
    c,
    `SELECT lhp.SiSoHienTai AS v
     FROM LOPHOCPHAN lhp JOIN MONHOC mh ON mh.MaMonHoc = lhp.MaMonHoc
     WHERE lhp.MaLHP = ?`, [LHP]);
}
async function ghiDangKy(c, maSV, ghiChu) {
  await c.query(
    `INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
     VALUES (?, ?, NOW(), 'DA_DANG_KY', ?)`, [maSV, LHP, ghiChu]); // trigger +1
}

const KQ = [];
function ghi(ten, kyVong, thucTe, dat) {
  KQ.push({ ten, kyVong, thucTe, dat: dat ? 'PASS' : 'FAIL' });
  console.log(`   => ${dat ? '✅ PASS' : '❌ FAIL'} — ${ten}: ky vong [${kyVong}], thuc te [${thucTe}]`);
}

async function main() {
  const admin = await newConn();
  console.log('='.repeat(70));
  console.log('DEMO 4 LOI CONCURRENCY — MySQL', await scalar(admin, 'SELECT VERSION()'));
  console.log('Isolation mac dinh:', await scalar(admin, 'SELECT @@session.transaction_isolation'));
  console.log('='.repeat(70));

  // ---------- PHA 0: CHUAN BI ----------
  console.log('\n► PHA 0 — Chuan bi: LHP514 con dung 1 cho');
  await chuanBi(admin);
  const BASE = Number(await siso(admin));
  const MAX = Number(await sisoToiDa(admin));
  console.log(`   LHP514 = ${BASE}/${MAX} (con dung 1 cho)`);

  // ---------- PHA 1: MYSQL RR DANG PHONG CHONG ----------
  console.log('\n► PHA 1 — Chung minh MySQL (REPEATABLE READ) DANG PHONG CHONG 3/4 loi');
  {
    // 1a. Dirty read bi chan
    const B = await newConn();           // phien "ghi" giu chua commit
    await B.beginTransaction();
    await B.query('UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP = ?', [LHP]); // BASE -> BASE+1 chua commit
    const A = await newConn('REPEATABLE READ');
    const dirty = await scalar(A, 'SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = ?', [LHP]);
    console.log(`   [1a] B UPDATE siso ${BASE}->${BASE + 1} (chua commit); A (RR) doc = ${dirty}`);
    ghi(`RR chan Dirty Read (A phai thay gia tri CU ${BASE}, khong doc duoc ${BASE + 1} chua commit)`,
      String(BASE), String(dirty), Number(dirty) === BASE);
    await B.rollback(); await A.end(); await B.end();

    // 1b. Unrepeatable read bi chan
    const A2 = await newConn('REPEATABLE READ');
    const B2 = await newConn();
    await A2.beginTransaction();
    const v1 = await scalar(A2, 'SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = ?', [LHP]);
    await B2.query('UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP = ?', [LHP]);
    const v2 = await scalar(A2, 'SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = ?', [LHP]);
    console.log(`   [1b] A (RR) doc lan 1 = ${v1}; B UPDATE+COMMIT; A doc lan 2 = ${v2}`);
    ghi('RR chan Unrepeatable Read (hai lan doc phai bang nhau)', `${v1} = ${v1}`, `${v1} != ${v2}`, Number(v1) === Number(v2));
    await A2.rollback(); await A2.end(); await B2.end();
    await admin.query('UPDATE LOPHOCPHAN SET SiSoHienTai = (SELECT COUNT(*) FROM DANGKYHOCPHAN d WHERE d.MaLHP = LOPHOCPHAN.MaLHP AND d.TrangThaiDangKy = \'DA_DANG_KY\') WHERE MaLHP = ?', [LHP]);

    // 1c. Phantom bi chan (snapshot)
    const A3 = await newConn('REPEATABLE READ');
    const B3 = await newConn();
    await A3.beginTransaction();
    const c1 = await scalar(A3, `SELECT COUNT(*) FROM DANGKYHOCPHAN WHERE MaLHP = ? AND TrangThaiDangKy = 'DA_DANG_KY'`, [LHP]);
    await B3.query(`INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu) VALUES ('SV999', ?, NOW(), 'DA_DANG_KY', 'phantom test')`, [LHP]);
    const c2 = await scalar(A3, `SELECT COUNT(*) FROM DANGKYHOCPHAN WHERE MaLHP = ? AND TrangThaiDangKy = 'DA_DANG_KY'`, [LHP]);
    console.log(`   [1c] A (RR) COUNT lan 1 = ${c1}; B INSERT SV999 + COMMIT; A COUNT lan 2 = ${c2}`);
    ghi('RR chan Phantom (COUNT phai khong doi)', `${c1} = ${c1}`, `${c1} != ${c2}`, Number(c1) === Number(c2));
    await A3.rollback(); await A3.end(); await B3.end();
    await chuanBi(admin);
  }

  // ---------- PHA 2: LOST UPDATE (CHUA FIX) ----------
  console.log('\n► PHA 2 — LOST UPDATE: 2 phien chay noi dung SP_DangKyHocPhan_ChuaFix (doc SiSo KHONG khoa)');
  {
    const A = await newConn();
    const B = await newConn();

    await batDauGiaoTac(A);                       // A: START TRANSACTION
    const sA = await docSiSoChuaFix(A);           // A: doc SiSo (KHONG khoa) -> thay con 1 cho
    await batDauGiaoTac(B);                       // B: START TRANSACTION
    const sB = await docSiSoChuaFix(B);           // B: doc SiSo (KHONG khoa) -> cung thay con 1 cho
    console.log(`   Ca 2 phien cung doc SiSo = ${sA}/${sB} (deu thay con 1 cho) -> deu dat dieu kien cho phep`);

    await ghiDangKy(A, 'SV030', 'Phien A - chua fix');   // A: INSERT (trigger +1), giu khoa, CHUA commit

    // B ghi dang ky — se BI CHAN boi khoa cua A (dung nhu ky vong).
    // Chung minh bang thoi gian: B khong the xong truoc khi A commit.
    let bKetQua = '';
    const t0 = Date.now();
    const pB = ghiDangKy(B, 'SV041', 'Phien B - chua fix')
      .then(() => { bKetQua = 'INSERT thanh cong (sau khi A commit)'; })
      .catch((e) => { bKetQua = 'LOI: ' + e.code; })
      .finally(() => { bKetQua += ` — thoi gian cho ${((Date.now() - t0) / 1000).toFixed(1)}s`; });

    await sleep(4000);   // trong luc A chua commit — B phai dang cho khoa
    await A.commit();                             // A chot: siso 15 -> 16 (VAN CON HOP LE)
    await pB;                                     // B duoc cho di qua: trigger +1 nua
    await B.commit();                             // B chot: siso 16 -> 17 (VUOT gioi han!)
    console.log(`   B goi INSERT trong khi A chua commit... ${bKetQua}`);
    const bCho = (Date.now() - t0) / 1000;
    ghi(`Phien B bi chan cho khoa cua A (cho >= 4s — A giu khoa 4s moi commit)`, '>= 4s', `${bCho.toFixed(1)}s`, bCho >= 3.8);
    const cuoi = await siso(admin);
    const dem = await scalar(admin, `SELECT COUNT(*) FROM DANGKYHOCPHAN WHERE MaLHP = ? AND TrangThaiDangKy = 'DA_DANG_KY'`, [LHP]);
    console.log(`   Sau khi ca 2 COMMIT: so DK THUC TE = ${dem}, SiSoHienTai = ${cuoi}, SiSoToiDa = ${MAX}`);
    console.log(`   -> Lop chi du ${MAX} cho nhung co ${dem} SV dang ky thanh cong (Trigger co LEAST clamp nen bo dem "noi doi")`);
    ghi(`Lost Update xay ra (${dem} DK > toi da ${MAX} cho — 2 phien deu dat chuoc khi chi con 1 cho)`,
      `${BASE + 2} DK > ${MAX}`, `${dem} DK > ${MAX}`, Number(dem) === BASE + 2 && Number(dem) > Number(MAX));
    await A.end(); await B.end();
    await chuanBi(admin);
  }

  // ---------- PHA 3: DIRTY READ ----------
  console.log('\n► PHA 3 — DIRTY READ: ha A xuong READ UNCOMMITTED');
  {
    const A = await newConn('READ UNCOMMITTED');
    const B = await newConn();
    await B.beginTransaction();
    await B.query('UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP = ?', [LHP]); // BASE->BASE+1, CHUA COMMIT
    await A.beginTransaction();
    const docBan = await scalar(A, 'SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = ?', [LHP]);
    console.log(`   B UPDATE siso ${BASE}->${BASE + 1} (CHUA commit); A (READ UNCOMMITTED) doc = ${docBan}`);
    ghi(`Dirty Read xay ra (A doc duoc ${BASE + 1} ma B chua commit)`, `${BASE + 1} (chua commit)`, docBan, Number(docBan) === BASE + 1);
    await B.rollback();   // B quay nguoc: du lieu "bien mat"
    const docSau = await scalar(A, 'SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = ?', [LHP]);
    console.log(`   B ROLLBACK — quyet dinh A dua tren gia tri ${docBan} nay SAI, gia tri that = ${docSau}`);
    ghi(`Du lieu ban "bien mat" sau rollback`, `${docBan} -> ${docSau}`, `${docBan} -> ${docSau}`, Number(docSau) === BASE);
    await A.rollback(); await A.end(); await B.end();
    await chuanBi(admin);
  }

  // ---------- PHA 4: UNREPEATABLE READ ----------
  console.log('\n► PHA 4 — UNREPEATABLE READ: ha A xuong READ COMMITTED');
  {
    const A = await newConn('READ COMMITTED');
    const B = await newConn();
    await A.beginTransaction();
    const v1 = await scalar(A, 'SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = ?', [LHP]);
    await B.query('UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP = ?', [LHP]);
    await B.commit();
    const v2 = await scalar(A, 'SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = ?', [LHP]);
    console.log(`   A (RC) doc lan 1 = ${v1}; B UPDATE+COMMIT; A doc lai lan 2 = ${v2}`);
    ghi('Unrepeatable Read xay ra (cung 1 giao tac, 2 ket qua khac nhau)', `${v1} roi ${v1 + 1}`, `${v1} roi ${v2}`, Number(v2) === Number(v1) + 1);
    await A.rollback(); await A.end(); await B.end();
    await chuanBi(admin);
  }

  // ---------- PHA 5: PHANTOM READ ----------
  console.log('\n► PHA 5 — PHANTOM READ: ha A xuong READ COMMITTED');
  {
    const A = await newConn('READ COMMITTED');
    const B = await newConn();
    await A.beginTransaction();
    const c1 = await scalar(A, `SELECT COUNT(*) FROM DANGKYHOCPHAN WHERE MaLHP = ? AND TrangThaiDangKy = 'DA_DANG_KY'`, [LHP]);
    console.log(`   A (RC) dem so DK = ${c1} (chua thay SV999)`);
    await B.query(`INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu) VALUES ('SV999', ?, NOW(), 'DA_DANG_KY', 'Phien B moi vao — bong ma')`, [LHP]);
    await B.commit();
    const c2 = await scalar(A, `SELECT COUNT(*) FROM DANGKYHOCPHAN WHERE MaLHP = ? AND TrangThaiDangKy = 'DA_DANG_KY'`, [LHP]);
    const thayMoi = await scalar(A, `SELECT COUNT(*) FROM DANGKYHOCPHAN WHERE MaLHP = ? AND MaSV = 'SV999'`, [LHP]);
    console.log(`   B INSERT SV999 + COMMIT; A dem lai = ${c2} (xuat them ${thayMoi} dong "bong ma")`);
    ghi('Phantom Read xay ra (COUNT tang ma A khong ghi gi)', `${c1} -> ${c1 + 1}`, `${c1} -> ${c2}`, Number(c2) === Number(c1) + 1);
    await A.rollback(); await A.end(); await B.end();
    await chuanBi(admin);
  }

  // ---------- PHA 6: SP DA FIX — KHONG CON LOST UPDATE ----------
  // Chon 1 LHP KHONG co mon tien quyet (2 SV deu qua het cac buoc kiem tra,
  // chi tranh nhau o buoc si so), roi dua no ve trang thai "con dung 1 cho".
  console.log('\n► PHA 6 — SP_DangKyHocPhan (DA FIX, FOR UPDATE): 2 phien gianh cho cuoi cung');
  {
    const RACE_LHP = await scalar(admin, `
      SELECT lhp.MaLHP FROM LOPHOCPHAN lhp
      LEFT JOIN MONHOC_TIENQUYET mtq ON mtq.MaMonHoc = lhp.MaMonHoc
      WHERE lhp.MaHocKy = 'HK1-2025' AND lhp.TrangThaiLop = 'MO_DANG_KY'
        AND mtq.MaMonHoc IS NULL AND lhp.MaLHP <> ?
      ORDER BY lhp.MaLHP LIMIT 1`, [LHP]);
    console.log(`   LHP thi dau: ${RACE_LHP} (khong co mon tien quyet — 2 SV chi tranh o buoc si so)`);
    await chuanBi(admin, RACE_LHP);
    const max6 = Number(await sisoToiDa(admin, RACE_LHP));
    const base6 = Number(await siso(admin, RACE_LHP));
    console.log(`   Trang thai: ${base6}/${max6} (con dung 1 cho)`);

    const A = await newConn();
    const B = await newConn();
    const [ra, rb] = await Promise.all([
      A.query('CALL SP_DangKyHocPhan(?, ?, ?, ?, @kq)', ['SV030', RACE_LHP, 24, 'Phien A - da fix']).then(() => scalar(A, 'SELECT @kq')),
      B.query('CALL SP_DangKyHocPhan(?, ?, ?, ?, @kq)', ['SV041', RACE_LHP, 24, 'Phien B - da fix']).then(() => scalar(B, 'SELECT @kq')),
    ]);
    const cuoi = await siso(admin, RACE_LHP);
    const dem = await scalar(admin, `SELECT COUNT(*) FROM DANGKYHOCPHAN WHERE MaLHP = ? AND TrangThaiDangKy = 'DA_DANG_KY'`, [RACE_LHP]);
    console.log(`   Ket qua: Phien A = ${ra} (0=OK, 105=lop day), Phien B = ${rb}`);
    console.log(`   Si so cuoi = ${cuoi}/${max6}, so DK thuc te = ${dem}`);
    const hopLe = (Number(ra) === 0 && Number(rb) === 105) || (Number(rb) === 0 && Number(ra) === 105);
    ghi('SP da fix: chi 1 phien thang, si so khong vuot', `1 x (rc=0) + 1 x (rc=105), siso <= ${max6}`,
      `A=${ra}, B=${rb}, siso=${cuoi}`, hopLe && Number(cuoi) <= Number(max6));
    await A.end(); await B.end();
    await chuanBi(admin, RACE_LHP);   // don dep LHP thi dau
  }

  // ---------- TONG KET ----------
  console.log('\n' + '='.repeat(70));
  console.log('TONG KET KIEM TRU');
  console.log('='.repeat(70));
  console.table(KQ);
  const fail = KQ.filter((k) => k.dat === 'FAIL');
  console.log(fail.length === 0 ? '[OK] Tat ca cac phan demo dien ra dung nhu ky vong.' : `[!] ${fail.length} phan FAIL — xem bang tren.`);
  await chuanBi(admin);   // tra LHP514 ve trang thai "con dung 1 cho"
  await admin.end();
}

main().catch((e) => { console.error('[LOI]', e); process.exit(1); });
