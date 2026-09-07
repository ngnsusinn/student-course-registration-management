// ============================================================
// models/admin.model.js — quản trị Phòng Đào Tạo (PĐT)
// Tầng MODEL (MVC): chỉ giao tiếp DB qua PROCEDURE.
// ============================================================
import { sp, spOut } from '../db.js';

// Danh sách tất cả lớp học phần (lọc theo học kỳ / trạng thái).
export async function dsLopHocPhan(maHocKy, trangThaiLop) {
  return sp('CALL SP_DSLopHocPhan(?, ?)', [maHocKy, trangThaiLop]);
}

// Dashboard: thống kê tổng hợp (dòng đầu của SP_ThongKeTongHop).
export async function thongKeTongHop() {
  const [tongHop] = await sp('CALL SP_ThongKeTongHop()');
  return tongHop;
}

// Dashboard: số đăng ký theo từng học kỳ.
export async function tkDangKyTheoKy() {
  return sp('CALL SP_TKDangKyTheoKy()');
}

// Tạo tài khoản sinh viên tự động.
export async function taoTaiKhoanSinhVien(maSV) {
  await sp('CALL SP_TaoTaiKhoanSinhVien(?)', [maSV]);
}

// Tạo tài khoản giảng viên tự động.
export async function taoTaiKhoanGiangVien(maGV) {
  await sp('CALL SP_TaoTaiKhoanGiangVien(?)', [maGV]);
}

// Danh sách tài khoản hệ thống.
export async function dsTaiKhoan() {
  return sp('CALL SP_DSTaiKhoan()');
}

// Khóa / mở khóa tài khoản.
export async function ganTrangThaiTaiKhoan(maTaiKhoan, trangThai) {
  await sp('CALL SP_GanTrangThaiTaiKhoan(?, ?)', [maTaiKhoan, trangThai]);
}

// Nhật ký đổi mật khẩu.
export async function dsNhatKyDoiMatKhau() {
  return sp('CALL SP_DSNhatKyDoiMatKhau()');
}

// Mở lớp học phần + xếp lịch (SP_MoLopHocPhan — kiểm tra GV/phòng trùng lịch).
export async function moLopHocPhan({ MaLHP, TenLHP, MaMonHoc, MaHocKy, MaGV, SiSoToiDa, MaPhong, Thu, TietBatDau, SoTiet }) {
  await sp('CALL SP_MoLopHocPhan(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', [
    MaLHP, TenLHP, MaMonHoc, MaHocKy, MaGV,
    Number(SiSoToiDa), MaPhong, Number(Thu), Number(TietBatDau), Number(SoTiet),
  ]);
}

// Thêm sinh viên + tự tạo tài khoản (SP_ThemSinhVien_Moi) — OUT @KetQua (0 = OK, 401–402 = lỗi).
export async function themSinhVien({ MaSV, HoTen, NgaySinh, GioiTinh, Email, SoDienThoai, MaLopSH, QueQuan }) {
  return spOut('CALL SP_ThemSinhVien_Moi(?, ?, ?, ?, ?, ?, ?, ?, @KetQua)', [
    MaSV, HoTen, NgaySinh, Number(GioiTinh ?? 1),
    Email, SoDienThoai, MaLopSH, QueQuan,
  ]);
}
