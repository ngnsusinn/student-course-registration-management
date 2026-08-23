const BASE = 'http://localhost:3000/api';

async function j(method, path, body, token) {
  const res = await fetch(BASE + path, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let data;
  try { data = JSON.parse(text); } catch { data = text; }
  return { status: res.status, data };
}

function show(label, r) {
  console.log(`\n=== ${label} [${r.status}] ===`);
  console.log(JSON.stringify(r.data, null, 1).slice(0, 600));
}

// 1. Login SV
const login = await j('POST', '/auth/login', { TenDangNhap: 'sv001', MatKhau: 'matkhau@123' });
show('Login SV001', login);
const token = login.data.token;

// 2. Hoc ky hien tai
show('Hoc ky hien tai', await j('GET', '/dangky/hocky-hientai', null, token));

// 3. Lop mo
const lopmo = await j('GET', '/dangky/lopmo', null, token);
console.log('\n=== Lop mo [', lopmo.status, '] so lop:', lopmo.data.lopHocPhan?.length);
console.log(JSON.stringify(lopmo.data.lopHocPhan?.slice(0, 2), null, 1));

// 4. Tong tin chi
show('Tong tin chi HK1-2025', await j('GET', '/dangky/tongtinchi?MaHocKy=HK1-2025', null, token));

// 5. Danh sach dang ky
const ds = await j('GET', '/dangky/danhsach?MaHocKy=HK1-2025', null, token);
console.log('\n=== Danh sach dang ky HK1-2025 [', ds.status, '] so mon:', ds.data.danhSach?.length);

// 6. Thoi khoa bieu
const tkb = await j('GET', '/dangky/thoikhoabieu?MaHocKy=HK1-2025', null, token);
console.log('\n=== TKB [', tkb.status, '] so buoi:', tkb.data.thoiKhoaBieu?.length);

// 7. Bang diem
const bd = await j('GET', '/ketqua/bangdiem?MaHocKy=HK1-2023', null, token);
console.log('\n=== Bang diem HK1-2023 [', bd.status, '] so mon:', bd.data.bangDiem?.length);

// 8. GPA
show('GPA HK1-2023', await j('GET', '/ketqua/gpa?MaHocKy=HK1-2023', null, token));

// 9. CPA
show('CPA', await j('GET', '/ketqua/cpa', null, token));

// 10. Hoc phi
const hp = await j('GET', '/hocphi/cua-toi', null, token);
console.log('\n=== Hoc phi [', hp.status, '] so phieu:', hp.data.hocPhi?.length);
console.log(JSON.stringify(hp.data.hocPhi?.slice(0, 1), null, 1));
