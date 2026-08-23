import { Router } from 'express';
import { query, getConnection } from '../db.js';
import { authenticate, requireRole, asyncHandler } from '../middleware/auth.js';

const router = Router();
router.use(authenticate, requireRole('PĐT'));

// GET /api/admin/lophocphan — danh sách tất cả LHP (PĐT quản lý)
router.get('/lophocphan', asyncHandler(async (req, res) => {
  const { MaHocKy, TrangThaiLop } = req.query;
  let sql = `SELECT lhp.*, mh.TenMonHoc, mh.SoTinChi, hk.TenHocKy, hk.NamHoc,
                    gv.HoTen AS TenGV,
                    (SELECT GROUP_CONCAT(CONCAT(lh.Thu, ':', lh.TietBatDau, '-', lh.TietBatDau + lh.SoTiet - 1, '@', ph.TenPhong) SEPARATOR '; ')
                       FROM LICHHOC lh JOIN PHONGHOC ph ON ph.MaPhong = lh.MaPhong
                      WHERE lh.MaLHP = lhp.MaLHP) AS LichHoc
             FROM LOPHOCPHAN lhp
             JOIN MONHOC mh ON mh.MaMonHoc = lhp.MaMonHoc
             JOIN HOCKY hk ON hk.MaHocKy = lhp.MaHocKy
             LEFT JOIN GIANGVIEN gv ON gv.MaGV = lhp.MaGV
             WHERE 1=1`;
  const params = [];
  if (MaHocKy) { sql += ' AND lhp.MaHocKy = ?'; params.push(MaHocKy); }
  if (TrangThaiLop) { sql += ' AND lhp.TrangThaiLop = ?'; params.push(TrangThaiLop); }
  sql += ' ORDER BY lhp.MaHocKy DESC, lhp.MaLHP LIMIT 500';
  res.json({ lopHocPhan: await query(sql, params) });
}));

// GET /api/admin/thongke — dashboard tong hop
router.get('/thongke', asyncHandler(async (req, res) => {
  const [tongHop] = await query(
    `SELECT
       (SELECT COUNT(*) FROM SINHVIEN) AS TongSinhVien,
       (SELECT COUNT(*) FROM SINHVIEN WHERE TrangThaiHoc = 1) AS SvDangHoc,
       (SELECT COUNT(*) FROM GIANGVIEN) AS TongGiangVien,
       (SELECT COUNT(*) FROM MONHOC) AS TongMonHoc,
       (SELECT COUNT(*) FROM LOPHOCPHAN) AS TongLopHocPhan,
       (SELECT COUNT(*) FROM LOPHOCPHAN WHERE TrangThaiLop = 'MO_DANG_KY') AS LopDangMo,
       (SELECT COUNT(*) FROM DANGKYHOCPHAN WHERE TrangThaiDangKy = 'DA_DANG_KY') AS TongDangKyHieuLuc,
       (SELECT COUNT(*) FROM TAIKHOAN) AS TongTaiKhoan`
  );
  const dangKyTheoKy = await query(
    `SELECT lhp.MaHocKy,
            COUNT(DISTINCT dk.MaSV) AS SoSVDangKy,
            COUNT(DISTINCT dk.MaLHP) AS SoLHP,
            COUNT(*) AS TongBanGhi,
            SUM(CASE WHEN dk.TrangThaiDangKy = 'DA_HUY' THEN 1 ELSE 0 END) AS DaHuy
     FROM DANGKYHOCPHAN dk JOIN LOPHOCPHAN lhp ON lhp.MaLHP = dk.MaLHP
     GROUP BY lhp.MaHocKy ORDER BY lhp.MaHocKy`
  );
  res.json({ tongHop, dangKyTheoKy });
}));

// POST /api/admin/taikhoan/sinhvien { MaSV }
router.post('/taikhoan/sinhvien', asyncHandler(async (req, res) => {
  const { MaSV } = req.body || {};
  if (!MaSV) return res.status(400).json({ error: 'Thiếu MaSV.' });
  const conn = await getConnection();
  try {
    await conn.query('CALL SP_TaoTaiKhoanSinhVien(?)', [MaSV]);
    res.json({ message: 'Tạo tài khoản sinh viên thành công.' });
  } catch (e) {
    res.status(400).json({ error: e.sqlMessage || e.message });
  } finally {
    conn.release();
  }
}));

// POST /api/admin/taikhoan/giangvien { MaGV }
router.post('/taikhoan/giangvien', asyncHandler(async (req, res) => {
  const { MaGV } = req.body || {};
  if (!MaGV) return res.status(400).json({ error: 'Thiếu MaGV.' });
  const conn = await getConnection();
  try {
    await conn.query('CALL SP_TaoTaiKhoanGiangVien(?)', [MaGV]);
    res.json({ message: 'Tạo tài khoản giảng viên thành công.' });
  } catch (e) {
    res.status(400).json({ error: e.sqlMessage || e.message });
  } finally {
    conn.release();
  }
}));

// GET /api/admin/taikhoan — danh sach tai khoan
router.get('/taikhoan', asyncHandler(async (req, res) => {
  res.json({
    taiKhoan: await query(
      `SELECT tk.MaTaiKhoan, tk.TenDangNhap, tk.Email, tk.TrangThai,
              tk.MaVaiTro, vt.TenVaiTro, tk.MaSV, tk.MaGV
       FROM TAIKHOAN tk JOIN VAITRO vt ON vt.MaVaiTro = tk.MaVaiTro
       ORDER BY tk.MaTaiKhoan`
    ),
  });
}));

// PUT /api/admin/taikhoan/khoa { MaTaiKhoan, TrangThai }
router.put('/taikhoan/khoa', asyncHandler(async (req, res) => {
  const { MaTaiKhoan, TrangThai } = req.body || {};
  if (!MaTaiKhoan || !['ACTIVE', 'LOCKED'].includes(TrangThai)) {
    return res.status(400).json({ error: 'Dữ liệu không hợp lệ.' });
  }
  await query('UPDATE TAIKHOAN SET TrangThai = ? WHERE MaTaiKhoan = ?', [TrangThai, MaTaiKhoan]);
  res.json({ message: 'Cập nhật trạng thái tài khoản thành công.' });
}));

// GET /api/admin/nhatky-doimatkhau
router.get('/nhatky-doimatkhau', asyncHandler(async (req, res) => {
  res.json({ nhatKy: await query('SELECT * FROM NHATKY_DOIMATKHAU ORDER BY ThoiGianThayDoi DESC LIMIT 200') });
}));

// POST /api/admin/molophocphan — mo lop hoc phan (SP_MoLopHocPhan)
router.post('/molophocphan', asyncHandler(async (req, res) => {
  const b = req.body || {};
  const required = ['MaLHP', 'TenLHP', 'MaMonHoc', 'MaHocKy', 'MaGV', 'SiSoToiDa', 'MaPhong', 'Thu', 'TietBatDau', 'SoTiet'];
  for (const f of required) {
    if (b[f] === undefined || b[f] === null || b[f] === '') {
      return res.status(400).json({ error: `Thiếu trường ${f}.` });
    }
  }
  const conn = await getConnection();
  try {
    await conn.query('CALL SP_MoLopHocPhan(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', [
      b.MaLHP, b.TenLHP, b.MaMonHoc, b.MaHocKy, b.MaGV,
      Number(b.SiSoToiDa), b.MaPhong, Number(b.Thu), Number(b.TietBatDau), Number(b.SoTiet),
    ]);
    res.json({ message: 'Mở lớp học phần thành công.' });
  } catch (e) {
    res.status(400).json({ error: e.sqlMessage || e.message });
  } finally {
    conn.release();
  }
}));

// POST /api/admin/themsinhvien — them sinh vien + tu tao tai khoan (SP_ThemSinhVien_Moi)
router.post('/themsinhvien', asyncHandler(async (req, res) => {
  const b = req.body || {};
  const required = ['MaSV', 'HoTen', 'NgaySinh', 'Email', 'SoDienThoai', 'MaLopSH'];
  for (const f of required) {
    if (!b[f]) return res.status(400).json({ error: `Thiếu trường ${f}.` });
  }
  const conn = await getConnection();
  try {
    await conn.query('CALL SP_ThemSinhVien_Moi(?, ?, ?, ?, ?, ?, ?, ?, @kq)', [
      b.MaSV, b.HoTen, b.NgaySinh, Number(b.GioiTinh ?? 1),
      b.Email, b.SoDienThoai, b.MaLopSH, b.QueQuan || null,
    ]);
    const [[r]] = await conn.query('SELECT @kq AS kq');
    if (Number(r.kq) !== 0) {
      const MSG = { 401: 'Mã sinh viên đã tồn tại.', 402: 'Lớp sinh hoạt không tồn tại.', 500: 'Lỗi hệ thống.' };
      return res.status(400).json({ error: MSG[r.kq] || 'Thêm sinh viên thất bại.' });
    }
    res.json({ message: 'Thêm sinh viên thành công (kèm tài khoản đăng nhập).' });
  } catch (e) {
    res.status(400).json({ error: e.sqlMessage || e.message });
  } finally {
    conn.release();
  }
}));

export default router;
