// ============================================================
// models/auth.model.js — đăng nhập / hồ sơ / đổi mật khẩu
// Tầng MODEL (MVC): chỉ giao tiếp DB qua PROCEDURE.
// ============================================================
import { sp, spOut } from '../db.js';

// SP_DangNhap nhận { TenDangNhap, MatKhau_da_bam } — trả về bản ghi tài khoản
// (null nếu sai tên đăng nhập/mật khẩu).
export async function dangNhap(tenDangNhap, matKhauSha256) {
  return (await sp('CALL SP_DangNhap(?, ?)', [tenDangNhap, matKhauSha256]))[0] ?? null;
}

// SP_LayHoSo — hồ sơ cá nhân phục vụ dashboard (SV truyền MaSV, GV truyền MaGV).
export async function layHoSo(vaiTro, maSV, maGV) {
  return (await sp('CALL SP_LayHoSo(?, ?, ?)', [vaiTro, maSV, maGV]))[0] ?? null;
}

// SP_DoiMatKhau — ghi log qua TRG_LogDoiMatKhau (tham số OUT @KetQua).
export async function doiMatKhau(maTaiKhoan, clientIP, matKhauCuSha256, matKhauMoiSha256) {
  return spOut('SET @ClientIP = ?; CALL SP_DoiMatKhau(?, ?, ?, @KetQua)', [
    clientIP, maTaiKhoan, matKhauCuSha256, matKhauMoiSha256,
  ]);
}
