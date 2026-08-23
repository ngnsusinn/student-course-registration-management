import { Router } from 'express';
import { query, getConnection } from '../db.js';
import { authenticate, requireRole, asyncHandler } from '../middleware/auth.js';

const router = Router();

// GET /api/giangvien/lopcuatoi?MaHocKy=  (GV xem lop minh day)
router.get('/lopcuatoi', authenticate, requireRole('GV'), asyncHandler(async (req, res) => {
  const maGV = req.user.MaGV;
  const { MaHocKy } = req.query;
  let sql = `SELECT lhp.*, mh.TenMonHoc, mh.SoTinChi, hk.TenHocKy, hk.NamHoc,
                    (SELECT GROUP_CONCAT(CONCAT(lh.Thu, ':', lh.TietBatDau, '-', lh.TietBatDau + lh.SoTiet - 1) SEPARATOR '; ')
                       FROM LICHHOC lh WHERE lh.MaLHP = lhp.MaLHP) AS LichHoc
             FROM LOPHOCPHAN lhp
             JOIN MONHOC mh ON mh.MaMonHoc = lhp.MaMonHoc
             JOIN HOCKY hk ON hk.MaHocKy = lhp.MaHocKy
             WHERE lhp.MaGV = ?`;
  const params = [maGV];
  if (MaHocKy) { sql += ' AND lhp.MaHocKy = ?'; params.push(MaHocKy); }
  sql += ' ORDER BY lhp.MaHocKy DESC, lhp.MaLHP';
  res.json({ lop: await query(sql, params) });
}));

// GET /api/giangvien/sinhvien/:MaLHP  (GV xem danh sach SV + diem cua lop)
router.get('/sinhvien/:MaLHP', authenticate, requireRole('GV'), asyncHandler(async (req, res) => {
  const maGV = req.user.MaGV;
  const { MaLHP } = req.params;

  const lop = await query('SELECT MaGV FROM LOPHOCPHAN WHERE MaLHP = ?', [MaLHP]);
  if (!lop.length) return res.status(404).json({ error: 'Không tìm thấy lớp học phần.' });
  if (lop[0].MaGV !== maGV) {
    return res.status(403).json({ error: 'Bạn không phụ trách lớp học phần này.' });
  }

  const rows = await query(
    `SELECT sv.MaSV, sv.HoTen, sv.MaLopSH, dk.NgayDangKy, dk.TrangThaiDangKy,
            kq.DiemChuyenCan, kq.DiemGiuaKy, kq.DiemCuoiKy,
            kq.DiemTongKet, kq.DiemChu, kq.DiemHe4
     FROM DANGKYHOCPHAN dk
     JOIN SINHVIEN sv ON sv.MaSV = dk.MaSV
     LEFT JOIN KETQUAHOCTAP kq ON kq.MaSV = dk.MaSV AND kq.MaLHP = dk.MaLHP
     WHERE dk.MaLHP = ? AND dk.TrangThaiDangKy = 'DA_DANG_KY'
     ORDER BY sv.MaSV`,
    [MaLHP]
  );
  res.json({ sinhVien: rows });
}));

// POST /api/giangvien/nhapdiem  { MaSV, MaLHP, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy }
router.post('/nhapdiem', authenticate, requireRole('GV'), asyncHandler(async (req, res) => {
  const maGV = req.user.MaGV;
  const { MaSV, MaLHP, DiemChuyenCan = null, DiemGiuaKy = null, DiemCuoiKy = null } = req.body || {};
  if (!MaSV || !MaLHP) return res.status(400).json({ error: 'Thiếu MaSV hoặc MaLHP.' });

  const conn = await getConnection();
  try {
    await conn.query('CALL SP_GV_NHAP_DIEM(?, ?, ?, ?, ?, ?)', [
      maGV, MaSV, MaLHP, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy,
    ]);
    res.json({ message: 'Nhập điểm thành công.' });
  } catch (e) {
    res.status(400).json({ error: e.sqlMessage || e.message });
  } finally {
    conn.release();
  }
}));

// POST /api/giangvien/nhapdiem-hangloat  { MaLHP, DanhSachDiem: [{ MaSV, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy }] }
router.post('/nhapdiem-hangloat', authenticate, requireRole('GV'), asyncHandler(async (req, res) => {
  const maGV = req.user.MaGV;
  const { MaLHP, DanhSachDiem = [] } = req.body || {};
  if (!MaLHP || !Array.isArray(DanhSachDiem) || !DanhSachDiem.length) {
    return res.status(400).json({ error: 'Thiếu MaLHP hoặc danh sách điểm.' });
  }

  // Kiểm tra GV phụ trách lớp
  const lop = await query('SELECT MaGV FROM LOPHOCPHAN WHERE MaLHP = ?', [MaLHP]);
  if (!lop.length) return res.status(404).json({ error: 'Không tìm thấy lớp học phần.' });
  if (lop[0].MaGV !== maGV) return res.status(403).json({ error: 'Bạn không phụ trách lớp học phần này.' });

  const conn = await getConnection();
  try {
    await conn.beginTransaction();
    for (const d of DanhSachDiem) {
      if (!d.MaSV) continue;
      await conn.query('CALL SP_GV_NHAP_DIEM(?, ?, ?, ?, ?, ?)', [
        maGV, d.MaSV, MaLHP,
        d.DiemChuyenCan ?? null, d.DiemGiuaKy ?? null, d.DiemCuoiKy ?? null,
      ]);
    }
    await conn.commit();
    res.json({ message: `Nhập điểm hàng loạt thành công (${DanhSachDiem.length} SV).` });
  } catch (e) {
    await conn.rollback();
    res.status(400).json({ error: e.sqlMessage || e.message });
  } finally {
    conn.release();
  }
}));

export default router;
