import { Router } from 'express';
import { query, getConnection } from '../db.js';
import { authenticate, requireRole, asyncHandler } from '../middleware/auth.js';

const router = Router();

export const DK_ERROR_MESSAGES = {
  0: 'Đăng ký học phần thành công.',
  100: 'Rất tiếc! Hiện tại ngoài thời hạn đăng ký học phần của học kỳ này.',
  101: 'Bạn đã đăng ký lớp học phần này rồi.',
  102: 'Không thể đăng ký! Bạn chưa hoàn thành môn tiên quyết của môn học này.',
  103: 'Đăng ký thất bại! Lớp học phần bị trùng lịch học với lớp bạn đã đăng ký.',
  104: 'Không thể đăng ký! Tổng số tín chỉ vượt quá giới hạn tối đa cho phép.',
  105: 'Đăng ký thất bại! Lớp học phần đã đầy sĩ số (hết chỗ trống).',
  106: 'Lớp học phần không tồn tại hoặc không ở trạng thái mở đăng ký.',
  500: 'Lỗi hệ thống khi xử lý đăng ký.',
};

export const HUY_ERROR_MESSAGES = {
  0: 'Hủy đăng ký thành công.',
  200: 'Rất tiếc! Hiện tại ngoài thời hạn hủy đăng ký học phần.',
  201: 'Không tìm thấy bản ghi đăng ký học phần.',
  202: 'Bản ghi đăng ký không ở trạng thái ĐÃ ĐĂNG KÝ (không thể hủy).',
  500: 'Lỗi hệ thống khi xử lý hủy đăng ký.',
};

async function hocKyHienTai() {
  const rows = await query(
    "SELECT * FROM HOCKY WHERE TrangThaiDot = 'MO' AND NOW() BETWEEN TuNgay AND DenNgay ORDER BY DenNgay DESC LIMIT 1"
  );
  return rows[0] || null;
}

// GET /api/dangky/hocky-hientai
router.get('/hocky-hientai', asyncHandler(async (req, res) => {
  const hk = await hocKyHienTai();
  res.json({ hocKy: hk });
}));

// GET /api/dangky/lopmo — danh sach LHP dang mo cho SV dang ky
router.get('/lopmo', authenticate, requireRole('SV'), asyncHandler(async (req, res) => {
  const maSV = req.user.MaSV;
  const hk = await hocKyHienTai();
  if (!hk) return res.json({ hocKy: null, lopHocPhan: [] });

  const rows = await query(
    `SELECT lhp.MaLHP, lhp.TenLHP, lhp.SiSoToiDa, lhp.SiSoHienTai,
            (lhp.SiSoToiDa - lhp.SiSoHienTai) AS SoChoTrong,
            lhp.TrangThaiLop, mh.MaMonHoc, mh.TenMonHoc, mh.SoTinChi,
            gv.MaGV, gv.HoTen AS TenGV,
            lhp.MaHocKy,
            (SELECT COUNT(*) FROM DANGKYHOCPHAN dk
              WHERE dk.MaLHP = lhp.MaLHP AND dk.MaSV = ? AND dk.TrangThaiDangKy = 'DA_DANG_KY') AS DaDangKy,
            (SELECT GROUP_CONCAT(CONCAT(lh.Thu, ':', lh.TietBatDau, '-', lh.TietBatDau + lh.SoTiet - 1, '@', ph.TenPhong) SEPARATOR '; ')
               FROM LICHHOC lh JOIN PHONGHOC ph ON ph.MaPhong = lh.MaPhong
              WHERE lh.MaLHP = lhp.MaLHP) AS LichHoc,
            (SELECT mtq.MaMonTienQuyet FROM MONHOC_TIENQUYET mtq WHERE mtq.MaMonHoc = mh.MaMonHoc LIMIT 1) AS MaMonTienQuyet
     FROM LOPHOCPHAN lhp
     JOIN MONHOC mh ON mh.MaMonHoc = lhp.MaMonHoc
     LEFT JOIN GIANGVIEN gv ON gv.MaGV = lhp.MaGV
     WHERE lhp.MaHocKy = ?
       AND lhp.TrangThaiLop = 'MO_DANG_KY'
     ORDER BY mh.TenMonHoc, lhp.MaLHP`,
    [maSV, hk.MaHocKy]
  );

  res.json({ hocKy: hk, lopHocPhan: rows });
}));

// POST /api/dangky — { MaLHP, GhiChu } -> SP_DangKyHocPhan
router.post('/', authenticate, requireRole('SV'), asyncHandler(async (req, res) => {
  const maSV = req.user.MaSV;
  const { MaLHP, GhiChu = null, MaxTinChi = 24 } = req.body || {};
  if (!MaLHP) return res.status(400).json({ error: 'Thiếu mã lớp học phần.' });

  // SP tu quan ly transaction (START TRANSACTION/COMMIT/ROLLBACK ben trong)
  const conn = await getConnection();
  let ketQua = 500;
  try {
    await conn.query('CALL SP_DangKyHocPhan(?, ?, ?, ?, @KetQua)', [maSV, MaLHP, MaxTinChi, GhiChu]);
    const [[r]] = await conn.query('SELECT @KetQua AS KetQua');
    ketQua = Number(r.KetQua);
  } catch (e) {
    ketQua = 500;
  } finally {
    conn.release();
  }

  if (ketQua !== 0) {
    return res.status(400).json({ ketQua, error: DK_ERROR_MESSAGES[ketQua] || 'Đăng ký thất bại.' });
  }

  const [lhp] = await query('SELECT MaLHP, TenLHP, SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP = ?', [MaLHP]);
  res.json({ ketQua: 0, message: DK_ERROR_MESSAGES[0], lopHocPhan: lhp });
}));

// POST /api/dangky/huy — { MaLHP } -> SP_HuyDangKy
router.post('/huy', authenticate, requireRole('SV'), asyncHandler(async (req, res) => {
  const maSV = req.user.MaSV;
  const { MaLHP } = req.body || {};
  if (!MaLHP) return res.status(400).json({ error: 'Thiếu mã lớp học phần.' });

  const conn = await getConnection();
  let ketQua = 500;
  try {
    await conn.query('CALL SP_HuyDangKy(?, ?, @KetQua)', [maSV, MaLHP]);
    const [[r]] = await conn.query('SELECT @KetQua AS KetQua');
    ketQua = Number(r.KetQua);
  } catch (e) {
    ketQua = 500;
  } finally {
    conn.release();
  }

  if (ketQua !== 0) {
    return res.status(400).json({ ketQua, error: HUY_ERROR_MESSAGES[ketQua] || 'Hủy đăng ký thất bại.' });
  }
  res.json({ ketQua: 0, message: HUY_ERROR_MESSAGES[0] });
}));

// GET /api/dangky/danhsach?MaHocKy= — danh sach dang ky cua SV
router.get('/danhsach', authenticate, requireRole('SV'), asyncHandler(async (req, res) => {
  const maSV = req.user.MaSV;
  const { MaHocKy } = req.query;
  let sql = 'SELECT * FROM VW_SinhVienDangKyChiTiet WHERE MaSV = ?';
  const params = [maSV];
  if (MaHocKy) { sql += ' AND MaHocKy = ?'; params.push(MaHocKy); }
  sql += ' ORDER BY MaHocKy DESC, MaLHP';
  res.json({ danhSach: await query(sql, params) });
}));

// GET /api/dangky/thoikhoabieu?MaHocKy=
router.get('/thoikhoabieu', authenticate, requireRole('SV'), asyncHandler(async (req, res) => {
  const maSV = req.user.MaSV;
  const { MaHocKy } = req.query;
  let sql = 'SELECT * FROM VW_ThoiKhoaBieuCaNhan WHERE MaSV = ?';
  const params = [maSV];
  if (MaHocKy) { sql += ' AND MaHocKy = ?'; params.push(MaHocKy); }
  sql += ' ORDER BY Thu, TietBatDau';
  res.json({ thoiKhoaBieu: await query(sql, params) });
}));

// GET /api/dangky/tongtinchi?MaHocKy=
router.get('/tongtinchi', authenticate, requireRole('SV'), asyncHandler(async (req, res) => {
  const maSV = req.user.MaSV;
  const hk = req.query.MaHocKy ? { MaHocKy: req.query.MaHocKy } : await hocKyHienTai();
  if (!hk) return res.json({ tongTinChi: 0 });
  const [r] = await query('SELECT FN_TinhTongTinChi(?, ?) AS TongTinChi', [maSV, hk.MaHocKy]);
  res.json({ maHocKy: hk.MaHocKy, tongTinChi: Number(r.TongTinChi) });
}));

export default router;
