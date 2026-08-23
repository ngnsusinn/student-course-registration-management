import mysql from 'mysql2/promise';

const c = await mysql.createConnection({
  host: 'free02.123host.vn',
  user: 'roacqgfa_dbms',
  password: 'roacqgfa_dbms1',
  database: 'roacqgfa_dbms',
  charset: 'utf8mb4',
});

const q = async (s) => (await c.query(s))[0];

console.log('LHP501:', JSON.stringify(await q("SELECT MaLHP,SiSoHienTai,SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP='LHP501'")));
console.log('Diem F:', JSON.stringify(await q("SELECT MaSV,MaLHP,DiemTongKet,DiemChu FROM KETQUAHOCTAP WHERE DiemChu='F' ORDER BY MaSV")));
console.log('HOCPHI:', JSON.stringify(await q('SELECT COUNT(*) n FROM HOCPHI')));
console.log('TAIKHOAN:', JSON.stringify(await q('SELECT MaVaiTro, COUNT(*) n FROM TAIKHOAN GROUP BY MaVaiTro')));
console.log('FN:', JSON.stringify(await q("SELECT FN_KiemTraDotDangKy() AS dotMo, FN_KiemTraTienQuyet('SV001','MH005') AS sv001_tq, FN_KiemTraTienQuyet('SV030','MH022') AS sv030_tq, FN_TinhTongTinChi('SV001','HK1-2025') AS tc_sv001")));
console.log('VIEW TKB SV001:', JSON.stringify(await q("SELECT COUNT(*) n FROM VW_ThoiKhoaBieuCaNhan WHERE MaSV='SV001' AND MaHocKy='HK1-2025'")));

await c.end();
