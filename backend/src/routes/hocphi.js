import { Router } from 'express';
import { query, getConnection } from '../db.js';
import { authenticate, requireRole, asyncHandler } from '../middleware/auth.js';

const router = Router();

export const THU_ERROR_MESSAGES = {
  0: 'Thu học phí thành công.',
  301: 'Không tìm thấy phiếu học phí.',
  302: 'Phiếu học phí đã thanh toán hết.',
  303: 'Số tiền nộp không hợp lệ.',
  304: 'Số tiền nộp vượt quá số tiền còn nợ.',
  500: 'Lỗi hệ thống khi thu học phí.',
};

// GET /api/hocphi/cua-toi  (SV)
router.get('/cua-toi', authenticate, requireRole('SV'), asyncHandler(async (req, res) => {
  const maSV = req.user.MaSV;
  const rows = await query(
    `SELECT hp.*, hk.TenHocKy, hk.NamHoc, (hp.TongTien - hp.DaNop) AS ConNo
     FROM HOCPHI hp JOIN HOCKY hk ON hk.MaHocKy = hp.MaHocKy
     WHERE hp.MaSV = ? ORDER BY hp.MaHocKy DESC`,
    [maSV]
  );
  res.json({ hocPhi: rows });
}));

// GET /api/hocphi/danhsach?TrangThai=&MaHocKy=  (PĐT)
router.get('/danhsach', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  const { TrangThai, MaHocKy } = req.query;
  let sql = `SELECT hp.*, sv.HoTen, l.TenLopSH, n.TenNganh, (hp.TongTien - hp.DaNop) AS ConNo
             FROM HOCPHI hp
             JOIN SINHVIEN sv ON sv.MaSV = hp.MaSV
             JOIN LOP_SINHHOAT l ON l.MaLopSH = sv.MaLopSH
             JOIN NGANH n ON n.MaNganh = l.MaNganh WHERE 1=1`;
  const params = [];
  if (TrangThai) { sql += ' AND hp.TrangThai = ?'; params.push(TrangThai); }
  if (MaHocKy) { sql += ' AND hp.MaHocKy = ?'; params.push(MaHocKy); }
  sql += ' ORDER BY hp.MaHocKy DESC, sv.MaSV LIMIT 500';
  res.json({ hocPhi: await query(sql, params) });
}));

// GET /api/hocphi/baocao  (PĐT) — tong hop tu cac view
router.get('/baocao', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  const [tongHop] = await query(
    `SELECT COUNT(*) AS TongPhieu, COUNT(DISTINCT MaSV) AS TongSinhVien,
            SUM(TongTien) AS TongHocPhi, SUM(DaNop) AS TongDaThu,
            SUM(TongTien - DaNop) AS TongConNo,
            SUM(CASE WHEN TrangThai = 'DA_THANH_TOAN' THEN 1 ELSE 0 END) AS DaThanhToan,
            SUM(CASE WHEN TrangThai <> 'DA_THANH_TOAN' THEN 1 ELSE 0 END) AS ChuaThanhToan
     FROM HOCPHI`
  );
  res.json({
    tongHop,
    theoHocKy: await query('SELECT * FROM VW_TongThuTheoHocKy ORDER BY MaHocKy'),
    theoNganh: await query('SELECT * FROM VW_TongThuTheoNganh'),
    conNo: await query('SELECT * FROM VW_SinhVienNoHocPhi ORDER BY SoTienConNo DESC LIMIT 50'),
  });
}));

// POST /api/hocphi/thu  { MaHocPhi, SoTien }  (PĐT) -> SP_ThuHocPhi
router.post('/thu', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  const { MaHocPhi, SoTien } = req.body || {};
  if (!MaHocPhi) return res.status(400).json({ error: 'Thiếu mã học phí.' });
  const soTien = Number(SoTien);
  if (!Number.isFinite(soTien) || soTien <= 0) {
    return res.status(400).json({ error: 'Số tiền nộp không hợp lệ.' });
  }

  const conn = await getConnection();
  let ketQua = 500;
  try {
    await conn.query('CALL SP_ThuHocPhi(?, ?, @KetQua)', [MaHocPhi, soTien]);
    const [[r]] = await conn.query('SELECT @KetQua AS KetQua');
    ketQua = Number(r.KetQua);
  } catch (e) {
    ketQua = 500;
  } finally {
    conn.release();
  }

  if (ketQua !== 0) {
    return res.status(400).json({ ketQua, error: THU_ERROR_MESSAGES[ketQua] || 'Thu học phí thất bại.' });
  }
  res.json({ ketQua: 0, message: THU_ERROR_MESSAGES[0] });
}));

// POST /api/hocphi/tinh  { MaSV, MaHocKy, DonGiaTinChi }  (PĐT) -> SP_TinhHocPhi
router.post('/tinh', authenticate, requireRole('PĐT'), asyncHandler(async (req, res) => {
  const { MaSV, MaHocKy, DonGiaTinChi } = req.body || {};
  if (!MaSV || !MaHocKy || !DonGiaTinChi) {
    return res.status(400).json({ error: 'Thiếu MaSV, MaHocKy hoặc DonGiaTinChi.' });
  }
  try {
    const conn = await getConnection();
    try {
      await conn.query('CALL SP_TinhHocPhi(?, ?, ?)', [MaSV, MaHocKy, Number(DonGiaTinChi)]);
    } finally {
      conn.release();
    }
    res.json({ message: 'Tính học phí thành công.' });
  } catch (e) {
    res.status(400).json({ error: e.sqlMessage || e.message });
  }
}));

export default router;
