import { Router } from 'express';
import { query, getConnection } from '../db.js';
import { authenticate, requireRole, asyncHandler } from '../middleware/auth.js';

const router = Router();

// GET /api/ketqua/bangdiem?MaHocKy=  (SV xem bang diem cua minh)
router.get('/bangdiem', authenticate, requireRole('SV'), asyncHandler(async (req, res) => {
  const maSV = req.user.MaSV;
  const { MaHocKy } = req.query;
  let sql = 'SELECT * FROM V_BANGDIEM_SINHVIEN WHERE MaSV = ?';
  const params = [maSV];
  if (MaHocKy) { sql += ' AND MaHocKy = ?'; params.push(MaHocKy); }
  sql += ' ORDER BY MaHocKy, TenMonHoc';
  res.json({ bangDiem: await query(sql, params) });
}));

// GET /api/ketqua/gpa?MaHocKy=  (SV)
router.get('/gpa', authenticate, requireRole('SV'), asyncHandler(async (req, res) => {
  const maSV = req.user.MaSV;
  const { MaHocKy } = req.query;
  if (!MaHocKy) return res.status(400).json({ error: 'Thiếu mã học kỳ.' });
  const conn = await getConnection();
  try {
    const [rs] = await conn.query('CALL SP_TinhGPA_HocKy(?, ?)', [maSV, MaHocKy]);
    res.json({ gpa: rs[0]?.[0] || null });
  } finally {
    conn.release();
  }
}));

// GET /api/ketqua/cpa  (SV)
router.get('/cpa', authenticate, requireRole('SV'), asyncHandler(async (req, res) => {
  const maSV = req.user.MaSV;
  const conn = await getConnection();
  try {
    const [rs] = await conn.query('CALL SP_TinhCPA_TichLuy(?)', [maSV]);
    res.json({ cpa: rs[0]?.[0] || null });
  } finally {
    conn.release();
  }
}));

// GET /api/ketqua/thangdiemchu
router.get('/thangdiemchu', authenticate, asyncHandler(async (req, res) => {
  res.json({ thangDiem: await query('SELECT * FROM THANGDIEMCHU ORDER BY TuDiemHe10 DESC') });
}));

// GET /api/ketqua/thongke-monhoc  (GV / PĐT)
router.get('/thongke-monhoc', authenticate, requireRole('GV', 'PĐT'), asyncHandler(async (req, res) => {
  const { MaLHP } = req.query;
  let sql = 'SELECT * FROM V_THONGKE_KETQUA_MONHOC';
  const params = [];
  if (MaLHP) { sql += ' WHERE MaLHP = ?'; params.push(MaLHP); }
  sql += ' ORDER BY MaLHP';
  res.json({ thongKe: await query(sql, params) });
}));

// GET /api/ketqua/canhbao-hocvu  (PĐT) — danh sách SV cảnh báo học vụ
router.get('/canhbao-hocvu', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  const conn = await getConnection();
  try {
    const [svs] = await conn.query('SELECT MaSV, HoTen, MaLopSH FROM SINHVIEN WHERE TrangThaiHoc = 1 ORDER BY MaSV');
    const canhBao = [];
    for (const sv of svs) {
      try {
        const [rs] = await conn.query('CALL SP_TinhCPA_TichLuy(?)', [sv.MaSV]);
        const cpa = rs[0]?.[0];
        if (cpa && cpa.TrangThaiCanhBaoHocVu && cpa.TrangThaiCanhBaoHocVu !== 'Bình thường') {
          canhBao.push({ ...cpa });
        }
      } catch { /* bỏ qua SV không có điểm */ }
    }
    res.json({ canhBao });
  } finally {
    conn.release();
  }
}));

// GET /api/ketqua/gpa-theo-lop/:MaLHP  (GV xem GPA từng SV trong lớp)
router.get('/gpa-theo-lop/:MaLHP', authenticate, requireRole('GV', 'PĐT'), asyncHandler(async (req, res) => {
  const { MaLHP } = req.params;
  const rows = await query(
    `SELECT sv.MaSV, sv.HoTen, kq.DiemTongKet, kq.DiemChu, kq.DiemHe4,
            mh.SoTinChi, lhp.MaHocKy
     FROM DANGKYHOCPHAN dk
     JOIN SINHVIEN sv ON sv.MaSV = dk.MaSV
     JOIN LOPHOCPHAN lhp ON lhp.MaLHP = dk.MaLHP
     JOIN MONHOC mh ON mh.MaMonHoc = lhp.MaMonHoc
     LEFT JOIN KETQUAHOCTAP kq ON kq.MaSV = dk.MaSV AND kq.MaLHP = dk.MaLHP
     WHERE dk.MaLHP = ? AND dk.TrangThaiDangKy = 'DA_DANG_KY'
     ORDER BY sv.MaSV`,
    [MaLHP]
  );
  res.json({ gpaLop: rows });
}));

export default router;
