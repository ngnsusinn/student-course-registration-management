import { Router } from 'express';
import crypto from 'node:crypto';
import { query, getConnection } from '../db.js';
import { signToken, authenticate, asyncHandler } from '../middleware/auth.js';

const router = Router();

function sha256(text) {
  return crypto.createHash('sha256').update(text, 'utf8').digest('hex');
}

// ============================================================
// DU LUNG OTP (mo phong portal that gui OTP qua email truong)
// key = TenDangNhap -> { otp, expiresAt }
// ============================================================
const otpStore = new Map();
const OTP_TTL_SECONDS = 120;

function genOtp() {
  return String(crypto.randomInt(100000, 999999));
}

// Kim tra tai khoan + mat khau, tra ve user payload (null neu sai)
async function verifyCredentials(TenDangNhap, MatKhau) {
  const rows = await query(
    `SELECT tk.MaTaiKhoan, tk.TenDangNhap, tk.MatKhau, tk.TrangThai,
            tk.MaVaiTro, tk.MaSV, tk.MaGV, tk.Email, vt.TenVaiTro
     FROM TAIKHOAN tk
     JOIN VAITRO vt ON vt.MaVaiTro = tk.MaVaiTro
     WHERE tk.TenDangNhap = ?`,
    [TenDangNhap]
  );
  if (!rows.length) return { error: 'Sai tên đăng nhập hoặc mật khẩu.', status: 401 };
  const acc = rows[0];
  if (acc.TrangThai === 'LOCKED') return { error: 'Tài khoản đã bị khóa. Liên hệ phòng đào tạo.', status: 403 };
  if (acc.MatKhau.toLowerCase() !== sha256(MatKhau).toLowerCase()) {
    return { error: 'Sai tên đăng nhập hoặc mật khẩu.', status: 401 };
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
  return {
    user: {
      MaTaiKhoan: acc.MaTaiKhoan, TenDangNhap: acc.TenDangNhap, MaVaiTro: acc.MaVaiTro,
      TenVaiTro: acc.TenVaiTro, MaSV: acc.MaSV, MaGV: acc.MaGV, HoTen,
    },
    email: acc.Email,
  };
}

// POST /api/auth/otp/gui — BUOC 1 dang nhap portal: kiem tra MK -> "gui OTP"
// (Portal that gui ve email truong + co reCAPTCHA; o day sinh OTP demo tra ve UI)
router.post('/otp/gui', asyncHandler(async (req, res) => {
  const { TenDangNhap, MatKhau } = req.body || {};
  if (!TenDangNhap || !MatKhau) {
    return res.status(400).json({ error: 'Vui lòng nhập tên đăng nhập và mật khẩu.' });
  }
  const v = await verifyCredentials(TenDangNhap, MatKhau);
  if (v.error) return res.status(v.status).json({ error: v.error });

  const otp = genOtp();
  otpStore.set(TenDangNhap.toLowerCase(), { otp, expiresAt: Date.now() + OTP_TTL_SECONDS * 1000 });
  res.json({
    message: 'Mã OTP đã được gửi thành công!',
    otpDemo: otp,                       // chi co trong ban demo — portal that gui email
    expiresInSeconds: OTP_TTL_SECONDS,
    emailMasked: String(v.email || '').replace(/^(.{2}).*(@.*)$/, '$1***$2'),
  });
}));

// POST /api/auth/otp/xacthuc — BUOC 2: nhap OTP -> cap JWT
router.post('/otp/xacthuc', asyncHandler(async (req, res) => {
  const { TenDangNhap, Otp } = req.body || {};
  if (!TenDangNhap || !Otp) return res.status(400).json({ error: 'Thiếu tên đăng nhập hoặc mã OTP.' });
  const rec = otpStore.get(String(TenDangNhap).toLowerCase());
  if (!rec) return res.status(400).json({ error: 'OTP đã hết hạn. Vui lòng gửi lại mã OTP!' });
  if (Date.now() > rec.expiresAt) {
    otpStore.delete(String(TenDangNhap).toLowerCase());
    return res.status(400).json({ error: 'OTP đã hết hạn. Vui lòng gửi lại mã OTP!' });
  }
  if (rec.otp !== String(Otp).trim()) return res.status(400).json({ error: 'OTP không hợp lệ!' });
  otpStore.delete(String(TenDangNhap).toLowerCase());

  // Da xac thuc mat khau o buoc 1 — lay tai khoan + cap token
  const rows = await query(
    `SELECT tk.MaTaiKhoan, tk.TenDangNhap, tk.MaVaiTro, tk.MaSV, tk.MaGV, vt.TenVaiTro
     FROM TAIKHOAN tk JOIN VAITRO vt ON vt.MaVaiTro = tk.MaVaiTro
     WHERE tk.TenDangNhap = ? AND tk.TrangThai <> 'LOCKED'`,
    [TenDangNhap]
  );
  if (!rows.length) return res.status(401).json({ error: 'Tài khoản không hợp lệ.' });
  const acc = rows[0];
  let HoTen = 'Phòng Đào Tạo';
  if (acc.MaSV) HoTen = (await query('SELECT HoTen FROM SINHVIEN WHERE MaSV = ?', [acc.MaSV]))[0]?.HoTen;
  else if (acc.MaGV) HoTen = (await query('SELECT HoTen FROM GIANGVIEN WHERE MaGV = ?', [acc.MaGV]))[0]?.HoTen;
  const user = { ...acc, HoTen };
  const token = signToken(user);
  res.json({ token, user, message: 'Đăng nhập thành công!' });
}));

// GET /api/auth/hoso — ho so ca nhan (SV/GV) phuc vu dashboard kieu portal
router.get('/hoso', authenticate, asyncHandler(async (req, res) => {
  const u = req.user;
  if (u.MaVaiTro === 'SV' && u.MaSV) {
    const [sv] = await query(
      `SELECT sv.MaSV, sv.HoTen, sv.NgaySinh, sv.GioiTinh, sv.Email, sv.SoDienThoai, sv.QueQuan,
              sv.TrangThaiHoc, l.MaLopSH, l.TenLopSH, l.NienKhoa,
              n.TenNganh, k.TenKhoa
       FROM SINHVIEN sv
       JOIN LOP_SINHHOAT l ON l.MaLopSH = sv.MaLopSH
       JOIN NGANH n ON n.MaNganh = l.MaNganh
       JOIN KHOA k ON k.MaKhoa = n.MaKhoa
       WHERE sv.MaSV = ?`,
      [u.MaSV]
    );
    return res.json({ vaiTro: 'SV', hoSo: sv || null });
  }
  if (u.MaVaiTro === 'GV' && u.MaGV) {
    const [gv] = await query(
      `SELECT gv.MaGV, gv.HoTen, gv.Email, k.TenKhoa
       FROM GIANGVIEN gv LEFT JOIN KHOA k ON k.MaKhoa = gv.MaKhoa
       WHERE gv.MaGV = ?`,
      [u.MaGV]
    );
    return res.json({ vaiTro: 'GV', hoSo: gv || null });
  }
  res.json({ vaiTro: 'PĐT', hoSo: { HoTen: u.HoTen, TenDangNhap: u.TenDangNhap } });
}));

// POST /api/auth/login — dang nhap truc tiep (giu cho test E2E/tai khoan noi bo)
router.post('/login', asyncHandler(async (req, res) => {
  const { TenDangNhap, MatKhau } = req.body || {};
  if (!TenDangNhap || !MatKhau) {
    return res.status(400).json({ error: 'Vui lòng nhập tên đăng nhập và mật khẩu.' });
  }
  const v = await verifyCredentials(TenDangNhap, MatKhau);
  if (v.error) return res.status(v.status).json({ error: v.error });
  const token = signToken(v.user);
  res.json({ token, user: v.user });
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
