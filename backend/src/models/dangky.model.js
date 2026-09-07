// ============================================================
// models/dangky.model.js — Đăng ký học phần (Module trung tâm)
// Tầng MODEL (MVC): chỉ giao tiếp DB qua PROCEDURE.
// ============================================================
import { sp, spOut } from '../db.js';

// Đợt đăng ký đang mở (SP_HocKyHienTai) — null nếu không có.
export async function hocKyHienTai() {
  return (await sp('CALL SP_HocKyHienTai()'))[0] ?? null;
}

// Danh sách lớp học phần đang mở cho SV (kèm trạng thái đã ĐK chưa).
export async function dsLopMo(maSV, maHocKy) {
  return sp('CALL SP_LopMo(?, ?)', [maSV, maHocKy]);
}

// Gọi SP_DangKyHocPhan — 5 bước kiểm tra + ghi nhận (Transaction + FOR UPDATE).
// Trả về mã kết quả qua tham số OUT @KetQua (0 = thành công, 100–106 = lỗi).
export async function dangKy(maSV, maLHP, maxTinChi, ghiChu) {
  return spOut('CALL SP_DangKyHocPhan(?, ?, ?, ?, @KetQua)', [maSV, maLHP, maxTinChi, ghiChu]);
}

// Lấy thông tin 1 lớp học phần sau khi đăng ký thành công.
export async function layLHP(maLHP) {
  return (await sp('CALL SP_LayLHP(?)', [maLHP]))[0];
}

// Gọi SP_HuyDangKy — hủy trong hạn (0 = thành công, 200–202 = lỗi).
export async function huyDangKy(maSV, maLHP) {
  return spOut('CALL SP_HuyDangKy(?, ?, @KetQua)', [maSV, maLHP]);
}

// Danh sách đăng ký của SV theo học kỳ (View chi tiết).
export async function danhSachDangKy(maSV, maHocKy) {
  return sp('CALL SP_DSDangKyChiTiet(?, ?)', [maSV, maHocKy]);
}

// Thời khóa biểu cá nhân của SV.
export async function thoiKhoaBieu(maSV, maHocKy) {
  return sp('CALL SP_DSThoiKhoaBieu(?, ?)', [maSV, maHocKy]);
}

// Tổng tín chỉ SV đã đăng ký trong học kỳ (dòng đầu tiên của SP_LayTongTinChi).
export async function layTongTinChi(maSV, maHocKy) {
  return (await sp('CALL SP_LayTongTinChi(?, ?)', [maSV, maHocKy]))[0];
}
