// ============================================================
// models/ketqua.model.js — Điểm số & Kết quả học tập (Module 4)
// Tầng MODEL (MVC): chỉ giao tiếp DB qua PROCEDURE.
// ============================================================
import { sp } from '../db.js';

// Bảng điểm cá nhân theo học kỳ.
export async function bangDiem(maSV, maHocKy) {
  return sp('CALL SP_DSBangDiem(?, ?)', [maSV, maHocKy]);
}

// GPA học kỳ (SP_TinhGPA_HocKy).
export async function gpaHocKy(maSV, maHocKy) {
  return sp('CALL SP_TinhGPA_HocKy(?, ?)', [maSV, maHocKy]);
}

// CPA tích lũy + cảnh báo học vụ (SP_TinhCPA_TichLuy).
export async function cpaTichLuy(maSV) {
  return sp('CALL SP_TinhCPA_TichLuy(?)', [maSV]);
}

// Bảng thang điểm chữ.
export async function dsThangDiemChu() {
  return sp('CALL SP_DSThangDiemChu()');
}

// Thống kê kết quả môn học (GV/PĐT).
export async function thongKeMonHoc(maLHP) {
  return sp('CALL SP_DSThongKeMonHoc(?)', [maLHP]);
}

// Danh sách SV cảnh báo học vụ (PĐT).
export async function dsCanhBaoHocVu() {
  return sp('CALL SP_DSCanhBaoHocVu()');
}

// GPA từng SV trong lớp (GV/PĐT).
export async function gpaTheoLop(maLHP) {
  return sp('CALL SP_DSGpaTheoLop(?)', [maLHP]);
}
