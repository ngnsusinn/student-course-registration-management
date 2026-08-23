// End-to-end API test: full user flows for SV / GV / PĐT
const BASE = 'http://localhost:3000/api';
let pass = 0, fail = 0;

async function j(method, path, body, token) {
  const res = await fetch(BASE + path, {
    method,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let data; try { data = JSON.parse(text); } catch { data = text; }
  return { status: res.status, data };
}

function ok(name, cond, extra) {
  if (cond) { pass++; console.log(`✅ ${name}`); }
  else { fail++; console.log(`❌ ${name} ${extra ? '| ' + extra : ''}`); }
}

// ===== SV flow =====
const sv = await j('POST', '/auth/login', { TenDangNhap: 'sv001', MatKhau: 'matkhau@123' });
ok('SV login', sv.status === 200 && sv.data.token, JSON.stringify(sv.data).slice(0, 100));
const st = sv.data.token;

const hk = await j('GET', '/dangky/hocky-hientai', null, st);
ok('SV hocky-hientai', hk.status === 200 && hk.data.hocKy);

const lopmo = await j('GET', '/dangky/lopmo', null, st);
ok('SV lopmo', lopmo.status === 200 && lopmo.data.lopHocPhan?.length >= 10, 'lop=' + lopmo.data.lopHocPhan?.length);

const ds = await j('GET', '/dangky/danhsach?MaHocKy=HK1-2025', null, st);
ok('SV danhsach', ds.status === 200 && ds.data.danhSach?.length >= 3, 'rows=' + ds.data.danhSach?.length);

const tkb = await j('GET', '/dangky/thoikhoabieu?MaHocKy=HK1-2025', null, st);
ok('SV thoikhoabieu', tkb.status === 200 && tkb.data.thoiKhoaBieu?.length >= 3);

const tc = await j('GET', '/dangky/tongtinchi?MaHocKy=HK1-2025', null, st);
ok('SV tongtinchi', tc.status === 200 && tc.data.tongTinChi >= 9, 'tc=' + tc.data.tongTinChi);

const bd = await j('GET', '/ketqua/bangdiem', null, st);
ok('SV bangdiem', bd.status === 200 && bd.data.bangDiem?.length >= 5);

const gpa = await j('GET', '/ketqua/gpa?MaHocKy=HK1-2023', null, st);
ok('SV gpa', gpa.status === 200 && gpa.data.gpa?.GPA_HocKy !== undefined);

const cpa = await j('GET', '/ketqua/cpa', null, st);
ok('SV cpa', cpa.status === 200 && cpa.data.cpa?.CPA_TichLuy !== undefined);

const hp = await j('GET', '/hocphi/cua-toi', null, st);
ok('SV hocphi', hp.status === 200 && hp.data.hocPhi?.length >= 1);

// ===== GV flow =====
const gv = await j('POST', '/auth/login', { TenDangNhap: 'gv001', MatKhau: 'matkhau@123' });
ok('GV login', gv.status === 200 && gv.data.token);
const gt = gv.data.token;

const lopGV = await j('GET', '/giangvien/lopcuatoi', null, gt);
ok('GV lopcuatoi', lopGV.status === 200 && lopGV.data.lop?.length >= 2, 'lop=' + lopGV.data.lop?.length);

const maLHP = lopGV.data.lop?.[0]?.MaLHP;
const svLop = await j('GET', '/giangvien/sinhvien/' + maLHP, null, gt);
ok('GV sinhvien LHP', svLop.status === 200 && svLop.data.sinhVien?.length >= 10, maLHP + ' sv=' + svLop.data.sinhVien?.length);

const tkMon = await j('GET', '/ketqua/thongke-monhoc?MaLHP=' + maLHP, null, gt);
ok('GV thongke-monhoc', tkMon.status === 200);

const gpaLop = await j('GET', '/ketqua/gpa-theo-lop/' + maLHP, null, gt);
ok('GV gpa-theo-lop', gpaLop.status === 200 && gpaLop.data.gpaLop?.length >= 10);

// ===== PĐT flow =====
const pdt = await j('POST', '/auth/login', { TenDangNhap: 'admin', MatKhau: 'admin@123' });
ok('PĐT login', pdt.status === 200 && pdt.data.token);
const pt = pdt.data.token;

const stt = await j('GET', '/admin/thongke', null, pt);
ok('PĐT thongke', stt.status === 200 && stt.data.tongHop.TongSinhVien >= 50);

const lhp = await j('GET', '/admin/lophocphan', null, pt);
ok('PĐT lophocphan', lhp.status === 200 && lhp.data.lopHocPhan?.length >= 40, 'lhp=' + lhp.data.lopHocPhan?.length);

const svList = await j('GET', '/danhmuc/sinhvien', null, pt);
ok('PĐT sinhvien list', svList.status === 200 && svList.data.sinhVien?.length >= 50);

const cb = await j('GET', '/ketqua/canhbao-hocvu', null, pt);
ok('PĐT canhbao-hocvu', cb.status === 200 && Array.isArray(cb.data.canhBao));

const bc = await j('GET', '/hocphi/baocao', null, pt);
ok('PĐT hocphi baocao', bc.status === 200 && bc.data.tongHop?.TongHocPhi > 0);

const hpDs = await j('GET', '/hocphi/danhsach', null, pt);
ok('PĐT hocphi danhsach', hpDs.status === 200 && hpDs.data.hocPhi?.length >= 40);

const tkList = await j('GET', '/admin/taikhoan', null, pt);
ok('PĐT taikhoan', tkList.status === 200 && tkList.data.taiKhoan?.length >= 70);

const ctdt = await j('GET', '/danhmuc/ctdt?MaNganh=CN', null, pt);
ok('PĐT ctdt', ctdt.status === 200 && ctdt.data.ctdt?.length >= 15);

const khoa = await j('GET', '/danhmuc/khoa', null, pt);
const nganh = await j('GET', '/danhmuc/nganh', null, pt);
const lop = await j('GET', '/danhmuc/lop', null, pt);
const mh = await j('GET', '/danhmuc/monhoc', null, pt);
const gvAll = await j('GET', '/danhmuc/giangvien', null, pt);
const ph = await j('GET', '/danhmuc/phonghoc', null, pt);
ok('PĐT danhmuc khoa/nganh/lop/monhoc/gv/phong', khoa.status === 200 && nganh.status === 200 && lop.status === 200 && mh.status === 200 && gvAll.status === 200 && ph.status === 200,
  `khoa=${khoa.data.khoa?.length} nganh=${nganh.data.nganh?.length} lop=${lop.data.lop?.length} mh=${mh.data.monHoc?.length} gv=${gvAll.data.giangVien?.length} ph=${ph.data.phongHoc?.length}`);

console.log(`\n===== KẾT QUẢ: ${pass} PASS / ${fail} FAIL =====`);
process.exit(fail ? 1 : 0);
