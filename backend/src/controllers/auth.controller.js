// ============================================================
// controllers/auth.controller.js — xử lý request/response Auth
// Tầng CONTROLLER (MVC): nhận HTTP request, gọi MODEL, trả JSON.
// ============================================================
import crypto from 'node:crypto';
import { signToken } from '../middleware/auth.js';
import * as authModel from '../models/auth.model.js';

export const LOGIN_ERROR = {
  401: 'Sai tên đăng nhập hoặc mật khẩu.',
  403: 'Tài khoản đã bị khóa. Liên hệ phòng đào tạo.',
};

function sha256(text) {
  return crypto.createHash('sha256').update(text, 'utf8').digest('hex');
}

// POST /api/auth/login — đăng nhập (SP_DangNhap tự so hash trong DB)
export async function login(req, res) {
  const { TenDangNhap, MatKhau } = req.body || {};
  if (!TenDangNhap || !MatKhau) {
    return res.status(400).json({ error: 'Vui lòng nhập tên đăng nhập và mật khẩu.' });
  }

  const acc = await authModel.dangNhap(TenDangNhap, sha256(MatKhau));
  if (!acc) return res.status(401).json({ error: LOGIN_ERROR[401] });
  if (acc.TrangThai === 'LOCKED') return res.status(403).json({ error: LOGIN_ERROR[403] });

  const user = {
    MaTaiKhoan: acc.MaTaiKhoan, TenDangNhap: acc.TenDangNhap, MaVaiTro: acc.MaVaiTro,
    TenVaiTro: acc.TenVaiTro, MaSV: acc.MaSV, MaGV: acc.MaGV, HoTen: acc.HoTen,
  };
  const token = signToken(user);
  res.json({ token, user });
}

// GET /api/auth/hoso — hồ sơ cá nhân (SV/GV) phục vụ dashboard kiểu portal
export async function hoso(req, res) {
  const u = req.user;
  if (u.MaVaiTro === 'SV' && u.MaSV) {
    const hoSo = await authModel.layHoSo(u.MaVaiTro, u.MaSV, null);
    return res.json({ vaiTro: 'SV', hoSo });
  }
  if (u.MaVaiTro === 'GV' && u.MaGV) {
    const hoSo = await authModel.layHoSo(u.MaVaiTro, null, u.MaGV);
    return res.json({ vaiTro: 'GV', hoSo });
  }
  res.json({ vaiTro: 'PĐT', hoSo: { HoTen: u.HoTen, TenDangNhap: u.TenDangNhap } });
}

// GET /api/auth/me
export function me(req, res) {
  res.json({ user: req.user });
}

// POST /api/auth/doimatkhau (SP_DoiMatKhau; log qua TRG_LogDoiMatKhau)
export async function doiMatKhau(req, res) {
  const { MatKhauCu, MatKhauMoi } = req.body || {};
  if (!MatKhauCu || !MatKhauMoi) {
    return res.status(400).json({ error: 'Thiếu mật khẩu cũ hoặc mật khẩu mới.' });
  }
  if (String(MatKhauMoi).length < 6) {
    return res.status(400).json({ error: 'Mật khẩu mới phải có ít nhất 6 ký tự.' });
  }

  const ip = (req.headers['x-forwarded-for'] || req.socket.remoteAddress || '').toString().slice(0, 50);
  const ketQua = await authModel.doiMatKhau(
    req.user.MaTaiKhoan, ip, sha256(MatKhauCu), sha256(MatKhauMoi),
  );
  if (ketQua === 404) return res.status(404).json({ error: 'Không tìm thấy tài khoản.' });
  if (ketQua !== 0) return res.status(400).json({ error: 'Mật khẩu cũ không đúng.' });

  res.json({ message: 'Đổi mật khẩu thành công.' });
}
