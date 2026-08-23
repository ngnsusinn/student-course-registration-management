import { Router } from 'express';
import { query, getConnection } from '../db.js';
import { authenticate, requireRole, asyncHandler } from '../middleware/auth.js';

const router = Router();

// GET /api/danhmuc/hocky
router.get('/hocky', authenticate, asyncHandler(async (req, res) => {
  const rows = await query(
    `SELECT hk.*,
            CASE WHEN hk.TrangThaiDot = 'MO' AND NOW() BETWEEN hk.TuNgay AND hk.DenNgay
                 THEN 1 ELSE 0 END AS DangMoDangKy
     FROM HOCKY hk ORDER BY hk.TuNgay DESC`
  );
  res.json({ hocKy: rows });
}));

// GET /api/danhmuc/khoa
router.get('/khoa', authenticate, asyncHandler(async (req, res) => {
  res.json({ khoa: await query('SELECT * FROM KHOA ORDER BY MaKhoa') });
}));

// GET /api/danhmuc/nganh
router.get('/nganh', authenticate, asyncHandler(async (req, res) => {
  res.json({ nganh: await query('SELECT n.*, k.TenKhoa FROM NGANH n JOIN KHOA k ON k.MaKhoa = n.MaKhoa ORDER BY n.MaNganh') });
}));

// GET /api/danhmuc/lop
router.get('/lop', authenticate, asyncHandler(async (req, res) => {
  res.json({ lop: await query('SELECT l.*, n.TenNganh, (SELECT COUNT(*) FROM SINHVIEN sv WHERE sv.MaLopSH = l.MaLopSH) AS SiSo FROM LOP_SINHHOAT l JOIN NGANH n ON n.MaNganh = l.MaNganh ORDER BY l.MaLopSH') });
}));

// GET /api/danhmuc/monhoc?MaKhoa=
router.get('/monhoc', authenticate, asyncHandler(async (req, res) => {
  const { MaKhoa } = req.query;
  let sql = 'SELECT mh.*, k.TenKhoa FROM MONHOC mh JOIN KHOA k ON k.MaKhoa = mh.MaKhoa';
  const params = [];
  if (MaKhoa) { sql += ' WHERE mh.MaKhoa = ?'; params.push(MaKhoa); }
  sql += ' ORDER BY mh.MaMonHoc';
  res.json({ monHoc: await query(sql, params) });
}));

// GET /api/danhmuc/giangvien
router.get('/giangvien', authenticate, asyncHandler(async (req, res) => {
  res.json({ giangVien: await query('SELECT gv.*, k.TenKhoa FROM GIANGVIEN gv JOIN KHOA k ON k.MaKhoa = gv.MaKhoa ORDER BY gv.MaGV') });
}));

// GET /api/danhmuc/phonghoc
router.get('/phonghoc', authenticate, asyncHandler(async (req, res) => {
  res.json({ phongHoc: await query('SELECT * FROM PHONGHOC ORDER BY MaPhong') });
}));

// GET /api/danhmuc/tienquyet — quan he tien quyet giua cac mon
router.get('/tienquyet', authenticate, asyncHandler(async (req, res) => {
  res.json({
    tienQuyet: await query(
      `SELECT mtq.MaMonHoc, mh1.TenMonHoc, mtq.MaMonTienQuyet, mh2.TenMonHoc AS TenMonTienQuyet
       FROM MONHOC_TIENQUYET mtq
       JOIN MONHOC mh1 ON mh1.MaMonHoc = mtq.MaMonHoc
       JOIN MONHOC mh2 ON mh2.MaMonHoc = mtq.MaMonTienQuyet
       ORDER BY mtq.MaMonHoc`
    ),
  });
}));

// GET /api/danhmuc/ctdt?MaNganh= — chương trình đào tạo (PĐT)
router.get('/ctdt', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  const { MaNganh } = req.query;
  let sql = `SELECT ctdt.MaNganh, n.TenNganh, ctdt.MaMonHoc, mh.TenMonHoc, mh.SoTinChi,
                    ctdt.HocKyDuKien, ctdt.BatBuoc
             FROM CHUONGTRINHDAOTAO ctdt
             JOIN NGANH n ON n.MaNganh = ctdt.MaNganh
             JOIN MONHOC mh ON mh.MaMonHoc = ctdt.MaMonHoc WHERE 1=1`;
  const params = [];
  if (MaNganh) { sql += ' AND ctdt.MaNganh = ?'; params.push(MaNganh); }
  sql += ' ORDER BY ctdt.MaNganh, ctdt.HocKyDuKien, ctdt.MaMonHoc';
  res.json({ ctdt: await query(sql, params) });
}));

// POST /api/danhmuc/ctdt { MaNganh, MaMonHoc, HocKyDuKien, BatBuoc }
router.post('/ctdt', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  const { MaNganh, MaMonHoc, HocKyDuKien, BatBuoc = 1 } = req.body || {};
  if (!MaNganh || !MaMonHoc || !HocKyDuKien) return res.status(400).json({ error: 'Thiếu dữ liệu CTĐT.' });
  await query('INSERT INTO CHUONGTRINHDAOTAO (MaNganh, MaMonHoc, HocKyDuKien, BatBuoc) VALUES (?, ?, ?, ?)',
    [MaNganh, MaMonHoc, Number(HocKyDuKien), Number(BatBuoc)]);
  res.json({ message: 'Thêm môn vào chương trình đào tạo thành công.' });
}));

// DELETE /api/danhmuc/ctdt/:MaNganh/:MaMonHoc
router.delete('/ctdt/:MaNganh/:MaMonHoc', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  await query('DELETE FROM CHUONGTRINHDAOTAO WHERE MaNganh = ? AND MaMonHoc = ?',
    [req.params.MaNganh, req.params.MaMonHoc]);
  res.json({ message: 'Xóa môn khỏi chương trình đào tạo thành công.' });
}));

// GET /api/danhmuc/sinhvien?MaLopSH=&tim= (PĐT)
router.get('/sinhvien', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  const { MaLopSH, tim } = req.query;
  let sql = `SELECT sv.*, l.TenLopSH, n.TenNganh
             FROM SINHVIEN sv
             JOIN LOP_SINHHOAT l ON l.MaLopSH = sv.MaLopSH
             JOIN NGANH n ON n.MaNganh = l.MaNganh WHERE 1=1`;
  const params = [];
  if (MaLopSH) { sql += ' AND sv.MaLopSH = ?'; params.push(MaLopSH); }
  if (tim) { sql += ' AND (sv.HoTen LIKE ? OR sv.MaSV LIKE ?)'; params.push(`%${tim}%`, `%${tim}%`); }
  sql += ' ORDER BY sv.MaSV LIMIT 500';
  res.json({ sinhVien: await query(sql, params) });
}));

// ================= CRUD Quản lý danh mục (PĐT) =================

// ---------- KHOA ----------
// POST /api/danhmuc/khoa
router.post('/khoa', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  const { MaKhoa, TenKhoa, DienThoaiKhoa = null, EmailKhoa } = req.body || {};
  if (!MaKhoa || !TenKhoa || !EmailKhoa) return res.status(400).json({ error: 'Thiếu MaKhoa, TenKhoa hoặc EmailKhoa.' });
  await query('INSERT INTO KHOA (MaKhoa, TenKhoa, DienThoaiKhoa, EmailKhoa) VALUES (?, ?, ?, ?)',
    [MaKhoa, TenKhoa, DienThoaiKhoa, EmailKhoa]);
  res.json({ message: 'Thêm khoa thành công.' });
}));

// PUT /api/danhmuc/khoa/:MaKhoa
router.put('/khoa/:MaKhoa', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  const { TenKhoa, DienThoaiKhoa, EmailKhoa } = req.body || {};
  if (!TenKhoa || !EmailKhoa) return res.status(400).json({ error: 'Thiếu TenKhoa hoặc EmailKhoa.' });
  await query('UPDATE KHOA SET TenKhoa = ?, DienThoaiKhoa = ?, EmailKhoa = ? WHERE MaKhoa = ?',
    [TenKhoa, DienThoaiKhoa, EmailKhoa, req.params.MaKhoa]);
  res.json({ message: 'Cập nhật khoa thành công.' });
}));

// DELETE /api/danhmuc/khoa/:MaKhoa
router.delete('/khoa/:MaKhoa', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  try {
    await query('DELETE FROM KHOA WHERE MaKhoa = ?', [req.params.MaKhoa]);
    res.json({ message: 'Xóa khoa thành công.' });
  } catch (e) {
    res.status(400).json({ error: 'Không thể xóa khoa vì còn dữ liệu tham chiếu (ngành/môn học).' });
  }
}));

// ---------- NGANH ----------
// POST /api/danhmuc/nganh
router.post('/nganh', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  const { MaNganh, TenNganh, ThoiGianDaoTao, MaKhoa } = req.body || {};
  if (!MaNganh || !TenNganh || !ThoiGianDaoTao || !MaKhoa) return res.status(400).json({ error: 'Thiếu dữ liệu ngành.' });
  await query('INSERT INTO NGANH (MaNganh, TenNganh, ThoiGianDaoTao, MaKhoa) VALUES (?, ?, ?, ?)',
    [MaNganh, TenNganh, ThoiGianDaoTao, MaKhoa]);
  res.json({ message: 'Thêm ngành thành công.' });
}));

// PUT /api/danhmuc/nganh/:MaNganh
router.put('/nganh/:MaNganh', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  const { TenNganh, ThoiGianDaoTao, MaKhoa } = req.body || {};
  await query('UPDATE NGANH SET TenNganh = ?, ThoiGianDaoTao = ?, MaKhoa = ? WHERE MaNganh = ?',
    [TenNganh, ThoiGianDaoTao, MaKhoa, req.params.MaNganh]);
  res.json({ message: 'Cập nhật ngành thành công.' });
}));

// DELETE /api/danhmuc/nganh/:MaNganh (bị trigger TRG_XoaNganh_ChanKhiConSinhVien chặn nếu còn SV)
router.delete('/nganh/:MaNganh', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  try {
    await query('DELETE FROM NGANH WHERE MaNganh = ?', [req.params.MaNganh]);
    res.json({ message: 'Xóa ngành thành công.' });
  } catch (e) {
    res.status(400).json({ error: e.sqlMessage || e.message });
  }
}));

// ---------- LOP_SINHHOAT ----------
// POST /api/danhmuc/lop
router.post('/lop', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  const { MaLopSH, TenLopSH, NienKhoa, MaNganh } = req.body || {};
  if (!MaLopSH || !TenLopSH || !NienKhoa || !MaNganh) return res.status(400).json({ error: 'Thiếu dữ liệu lớp.' });
  await query('INSERT INTO LOP_SINHHOAT (MaLopSH, TenLopSH, NienKhoa, MaNganh) VALUES (?, ?, ?, ?)',
    [MaLopSH, TenLopSH, NienKhoa, MaNganh]);
  res.json({ message: 'Thêm lớp sinh hoạt thành công.' });
}));

// PUT /api/danhmuc/lop/:MaLopSH
router.put('/lop/:MaLopSH', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  const { TenLopSH, NienKhoa, MaNganh } = req.body || {};
  await query('UPDATE LOP_SINHHOAT SET TenLopSH = ?, NienKhoa = ?, MaNganh = ? WHERE MaLopSH = ?',
    [TenLopSH, NienKhoa, MaNganh, req.params.MaLopSH]);
  res.json({ message: 'Cập nhật lớp thành công.' });
}));

// DELETE /api/danhmuc/lop/:MaLopSH
router.delete('/lop/:MaLopSH', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  try {
    await query('DELETE FROM LOP_SINHHOAT WHERE MaLopSH = ?', [req.params.MaLopSH]);
    res.json({ message: 'Xóa lớp thành công.' });
  } catch (e) {
    res.status(400).json({ error: 'Không thể xóa lớp vì còn sinh viên trong lớp.' });
  }
}));

// ---------- MONHOC ----------
// POST /api/danhmuc/monhoc
router.post('/monhoc', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  const { MaMonHoc, TenMonHoc, SoTinChi, SoTietLyThuyet = 0, SoTietThucHanh = 0, MaKhoa, TienQuyet = [] } = req.body || {};
  if (!MaMonHoc || !TenMonHoc || !SoTinChi || !MaKhoa) return res.status(400).json({ error: 'Thiếu dữ liệu môn học.' });
  const conn = await getConnection();
  try {
    await conn.beginTransaction();
    await conn.query(
      'INSERT INTO MONHOC (MaMonHoc, TenMonHoc, SoTinChi, SoTietLyThuyet, SoTietThucHanh, MaKhoa) VALUES (?, ?, ?, ?, ?, ?)',
      [MaMonHoc, TenMonHoc, Number(SoTinChi), Number(SoTietLyThuyet), Number(SoTietThucHanh), MaKhoa]
    );
    for (const tq of TienQuyet) {
      await conn.query('INSERT INTO MONHOC_TIENQUYET (MaMonHoc, MaMonTienQuyet) VALUES (?, ?)', [MaMonHoc, tq]);
    }
    await conn.commit();
    res.json({ message: 'Thêm môn học thành công.' });
  } catch (e) {
    await conn.rollback();
    res.status(400).json({ error: e.sqlMessage || e.message });
  } finally {
    conn.release();
  }
}));

// PUT /api/danhmuc/monhoc/:MaMonHoc
router.put('/monhoc/:MaMonHoc', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  const { TenMonHoc, SoTinChi, SoTietLyThuyet, SoTietThucHanh, MaKhoa } = req.body || {};
  await query('UPDATE MONHOC SET TenMonHoc = ?, SoTinChi = ?, SoTietLyThuyet = ?, SoTietThucHanh = ?, MaKhoa = ? WHERE MaMonHoc = ?',
    [TenMonHoc, Number(SoTinChi), Number(SoTietLyThuyet), Number(SoTietThucHanh), MaKhoa, req.params.MaMonHoc]);
  res.json({ message: 'Cập nhật môn học thành công.' });
}));

// DELETE /api/danhmuc/monhoc/:MaMonHoc
router.delete('/monhoc/:MaMonHoc', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  try {
    await query('DELETE FROM MONHOC WHERE MaMonHoc = ?', [req.params.MaMonHoc]);
    res.json({ message: 'Xóa môn học thành công.' });
  } catch (e) {
    res.status(400).json({ error: 'Không thể xóa môn học vì còn dữ liệu liên quan.' });
  }
}));

// ---------- GIANGVIEN ----------
// POST /api/danhmuc/giangvien
router.post('/giangvien', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  const { MaGV, HoTen, Email, MaKhoa } = req.body || {};
  if (!MaGV || !HoTen || !Email || !MaKhoa) return res.status(400).json({ error: 'Thiếu dữ liệu giảng viên.' });
  const conn = await getConnection();
  try {
    await conn.beginTransaction();
    await conn.query('INSERT INTO GIANGVIEN (MaGV, HoTen, Email, MaKhoa) VALUES (?, ?, ?, ?)',
      [MaGV, HoTen, Email, MaKhoa]);
    // Tự động tạo tài khoản cho giảng viên
    await conn.query('CALL SP_TaoTaiKhoanGiangVien(?)', [MaGV]);
    await conn.commit();
    res.json({ message: 'Thêm giảng viên thành công (kèm tài khoản).' });
  } catch (e) {
    await conn.rollback();
    res.status(400).json({ error: e.sqlMessage || e.message });
  } finally {
    conn.release();
  }
}));

// PUT /api/danhmuc/giangvien/:MaGV
router.put('/giangvien/:MaGV', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  const { HoTen, Email, MaKhoa } = req.body || {};
  await query('UPDATE GIANGVIEN SET HoTen = ?, Email = ?, MaKhoa = ? WHERE MaGV = ?',
    [HoTen, Email, MaKhoa, req.params.MaGV]);
  res.json({ message: 'Cập nhật giảng viên thành công.' });
}));

// DELETE /api/danhmuc/giangvien/:MaGV
router.delete('/giangvien/:MaGV', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  try {
    await query('DELETE FROM GIANGVIEN WHERE MaGV = ?', [req.params.MaGV]);
    res.json({ message: 'Xóa giảng viên thành công.' });
  } catch (e) {
    res.status(400).json({ error: 'Không thể xóa giảng viên vì còn dữ liệu liên quan.' });
  }
}));

// ---------- PHONGHOC ----------
// POST /api/danhmuc/phonghoc
router.post('/phonghoc', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  const { MaPhong, TenPhong, SucChua } = req.body || {};
  if (!MaPhong || !TenPhong || !SucChua) return res.status(400).json({ error: 'Thiếu dữ liệu phòng.' });
  await query('INSERT INTO PHONGHOC (MaPhong, TenPhong, SucChua) VALUES (?, ?, ?)',
    [MaPhong, TenPhong, Number(SucChua)]);
  res.json({ message: 'Thêm phòng học thành công.' });
}));

// PUT /api/danhmuc/phonghoc/:MaPhong
router.put('/phonghoc/:MaPhong', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  const { TenPhong, SucChua } = req.body || {};
  await query('UPDATE PHONGHOC SET TenPhong = ?, SucChua = ? WHERE MaPhong = ?',
    [TenPhong, Number(SucChua), req.params.MaPhong]);
  res.json({ message: 'Cập nhật phòng học thành công.' });
}));

// DELETE /api/danhmuc/phonghoc/:MaPhong
router.delete('/phonghoc/:MaPhong', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  try {
    await query('DELETE FROM PHONGHOC WHERE MaPhong = ?', [req.params.MaPhong]);
    res.json({ message: 'Xóa phòng học thành công.' });
  } catch (e) {
    res.status(400).json({ error: 'Không thể xóa phòng vì còn lịch học tham chiếu.' });
  }
}));

// ---------- HOCKY ----------
// POST /api/danhmuc/hocky
router.post('/hocky', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  const { MaHocKy, TenHocKy, NamHoc, TuNgay, DenNgay, TrangThaiDot = 'MO' } = req.body || {};
  if (!MaHocKy || !TenHocKy || !NamHoc || !TuNgay || !DenNgay) return res.status(400).json({ error: 'Thiếu dữ liệu học kỳ.' });
  await query('INSERT INTO HOCKY (MaHocKy, TenHocKy, NamHoc, TuNgay, DenNgay, TrangThaiDot) VALUES (?, ?, ?, ?, ?, ?)',
    [MaHocKy, TenHocKy, NamHoc, TuNgay, DenNgay, TrangThaiDot]);
  res.json({ message: 'Thêm học kỳ thành công.' });
}));

// PUT /api/danhmuc/hocky/:MaHocKy — mở/đóng đợt đăng ký
router.put('/hocky/:MaHocKy', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  const { TenHocKy, NamHoc, TuNgay, DenNgay, TrangThaiDot } = req.body || {};
  await query('UPDATE HOCKY SET TenHocKy = ?, NamHoc = ?, TuNgay = ?, DenNgay = ?, TrangThaiDot = ? WHERE MaHocKy = ?',
    [TenHocKy, NamHoc, TuNgay, DenNgay, TrangThaiDot, req.params.MaHocKy]);
  res.json({ message: 'Cập nhật học kỳ thành công.' });
}));

// ---------- SINHVIEN: chuyển lớp & cập nhật hồ sơ ----------
// POST /api/danhmuc/sinhvien/chuyenlop { MaSV, MaLopSH }
router.post('/sinhvien/chuyenlop', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  const { MaSV, MaLopSH } = req.body || {};
  if (!MaSV || !MaLopSH) return res.status(400).json({ error: 'Thiếu MaSV hoặc MaLopSH.' });
  const conn = await getConnection();
  try {
    await conn.query('CALL SP_ChuyenLop_Nganh(?, ?, @kq)', [MaSV, MaLopSH]);
    const [[r]] = await conn.query('SELECT @kq AS kq');
    if (Number(r.kq) !== 0) {
      const MSG = { 403: 'Sinh viên không tồn tại.', 404: 'Lớp mới không tồn tại.', 405: 'Sinh viên đã ở lớp này rồi.', 500: 'Lỗi hệ thống.' };
      return res.status(400).json({ error: MSG[r.kq] || 'Chuyển lớp thất bại.' });
    }
    res.json({ message: 'Chuyển lớp thành công.' });
  } catch (e) {
    res.status(400).json({ error: e.sqlMessage || e.message });
  } finally {
    conn.release();
  }
}));

// PUT /api/danhmuc/sinhvien/:MaSV — cập nhật hồ sơ SV (dùng SP chống xung đột)
router.put('/sinhvien/:MaSV', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  const b = req.body || {};
  const { HoTen, NgaySinh, GioiTinh, Email, SoDienThoai, QueQuan, MaLopSH, TrangThaiHoc } = b;
  const fields = [];
  const params = [];
  if (HoTen !== undefined) { fields.push('HoTen = ?'); params.push(HoTen); }
  if (NgaySinh !== undefined) { fields.push('NgaySinh = ?'); params.push(NgaySinh); }
  if (GioiTinh !== undefined) { fields.push('GioiTinh = ?'); params.push(Number(GioiTinh)); }
  if (Email !== undefined) { fields.push('Email = ?'); params.push(Email); }
  if (SoDienThoai !== undefined) { fields.push('SoDienThoai = ?'); params.push(SoDienThoai); }
  if (QueQuan !== undefined) { fields.push('QueQuan = ?'); params.push(QueQuan); }
  if (TrangThaiHoc !== undefined) { fields.push('TrangThaiHoc = ?'); params.push(Number(TrangThaiHoc)); }
  if (MaLopSH !== undefined) {
    // Chuyển lớp qua SP riêng (giữ nguyên tính năng)
    const conn = await getConnection();
    try {
      await conn.query('CALL SP_ChuyenLop_Nganh(?, ?, @kq)', [req.params.MaSV, MaLopSH]);
    } finally {
      conn.release();
    }
  }
  if (!fields.length) return res.status(400).json({ error: 'Không có trường nào để cập nhật.' });
  params.push(req.params.MaSV);
  await query(`UPDATE SINHVIEN SET ${fields.join(', ')} WHERE MaSV = ?`, params);
  res.json({ message: 'Cập nhật hồ sơ sinh viên thành công.' });
}));

// DELETE /api/danhmuc/sinhvien/:MaSV
router.delete('/sinhvien/:MaSV', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  try {
    await query('DELETE FROM SINHVIEN WHERE MaSV = ?', [req.params.MaSV]);
    res.json({ message: 'Xóa sinh viên thành công.' });
  } catch (e) {
    res.status(400).json({ error: 'Không thể xóa sinh viên vì còn dữ liệu liên quan (đăng ký/điểm/học phí).' });
  }
}));

export default router;
