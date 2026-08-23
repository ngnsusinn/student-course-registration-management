import { Router } from 'express';
import crypto from 'node:crypto';
import { query, getConnection } from '../db.js';
import { signToken, authenticate, asyncHandler } from '../middleware/auth.js';

const router = Router();

function sha256(text) {
  return crypto.createHash('sha256').update(text, 'utf8').digest('hex');
}

// POST /api/auth/login
router.post('/login', asyncHandler(async (req, res) => {
  const { TenDangNhap, MatKhau } = req.body || {};
  if (!TenDangNhap || !MatKhau) {
    return res.status(400).json({ error: 'Vui lòng nhập tên đăng nhập và mật khẩu.' });
  }

  const rows = await query(
    `SELECT tk.MaTaiKhoan, tk.TenDangNhap, tk.MatKhau, tk.TrangThai,
            tk.MaVaiTro, tk.MaSV, tk.MaGV, tk.Email, vt.TenVaiTro
     FROM TAIKHOAN tk
     JOIN VAITRO vt ON vt.MaVaiTro = tk.MaVaiTro
     WHERE tk.TenDangNhap = ?`,
    [TenDangNhap]
  );

  if (!rows.length) {
    return res.status(401).json({ error: 'Sai tên đăng nhập hoặc mật khẩu.' });
  }

  const acc = rows[0];
  if (acc.TrangThai === 'LOCKED') {
    return res.status(403).json({ error: 'Tài khoản đã bị khóa. Liên hệ phòng đào tạo.' });
  }
  if (acc.MatKhau.toLowerCase() !== sha256(MatKhau).toLowerCase()) {
    return res.status(401).json({ error: 'Sai tên đăng nhập hoặc mật khẩu.' });
  }

  let HoTen = null;
  if (acc.MaSV) {
    const sv = await query('SELECT HoTen FROM SINHVIEN WHERE MaSV = ?', [acc.MaSV]);
    HoTen = sv[0]?.HoTen;
  } else if (acc.MaGV) {
    const gv = await query('SELECT HoTen FROM GIANGVIEN WHERE MaGV = ?', [acc.MaGV]);
    HoTen = gv[0]?.HoTen;
  } else {
    HoTen = 'Phòng Đào Tạo';
  }

  const token = signToken({
    MaTaiKhoan: acc.MaTaiKhoan,
    TenDangNhap: acc.TenDangNhap,
    MaVaiTro: acc.MaVaiTro,
    TenVaiTro: acc.TenVaiTro,
    MaSV: acc.MaSV,
    MaGV: acc.MaGV,
    HoTen,
  });

  res.json({ token, user: { MaTaiKhoan: acc.MaTaiKhoan, TenDangNhap: acc.TenDangNhap, MaVaiTro: acc.MaVaiTro, TenVaiTro: acc.TenVaiTro, MaSV: acc.MaSV, MaGV: acc.MaGV, HoTen } });
}));

// GET /api/auth/me
router.get('/me', authenticate, (req, res) => {
  res.json({ user: req.user });
});

// POST /api/auth/doimatkhau  (log qua TRG_LogDoiMatKhau)
router.post('/doimatkhau', authenticate, asyncHandler(async (req, res) => {
  const { MatKhauCu, MatKhauMoi } = req.body || {};
  if (!MatKhauCu || !MatKhauMoi) {
    return res.status(400).json({ error: 'Thiếu mật khẩu cũ hoặc mật khẩu mới.' });
  }
  if (String(MatKhauMoi).length < 6) {
    return res.status(400).json({ error: 'Mật khẩu mới phải có ít nhất 6 ký tự.' });
  }

  const rows = await query('SELECT MatKhau FROM TAIKHOAN WHERE MaTaiKhoan = ?', [req.user.MaTaiKhoan]);
  if (!rows.length) return res.status(404).json({ error: 'Không tìm thấy tài khoản.' });
  if (rows[0].MatKhau.toLowerCase() !== sha256(MatKhauCu).toLowerCase()) {
    return res.status(400).json({ error: 'Mật khẩu cũ không đúng.' });
  }

  const conn = await getConnection();
  try {
    const ip = (req.headers['x-forwarded-for'] || req.socket.remoteAddress || '').toString().slice(0, 50);
    await conn.query('SET @ClientIP = ?', [ip]);
    await conn.query('UPDATE TAIKHOAN SET MatKhau = SHA2(?, 256) WHERE MaTaiKhoan = ?', [MatKhauMoi, req.user.MaTaiKhoan]);
    await conn.commit?.();
  } finally {
    conn.release();
  }

  res.json({ message: 'Đổi mật khẩu thành công.' });
}));

export default router;
