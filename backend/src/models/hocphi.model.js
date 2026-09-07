// ============================================================
// models/hocphi.model.js — Học phí, Tài khoản & Vận hành (Module 5)
// Tầng MODEL (MVC): chỉ giao tiếp DB qua PROCEDURE/VIEW.
// ============================================================
import { sp, spOut, spMulti } from '../db.js';

// Học phí của 1 sinh viên (SV xem của mình).
export async function hocPhiCuaToi(maSV) {
  return sp('CALL SP_DSHocPhiCuaToi(?)', [maSV]);
}

// Danh sách học phí lọc theo trạng thái / học kỳ (PĐT).
export async function dsHocPhi(trangThai, maHocKy) {
  return sp('CALL SP_DSHocPhiDanhsach(?, ?)', [trangThai, maHocKy]);
}

// Báo cáo tổng hợp: SP trả 4 result set (tổng hợp / theo kỳ / theo ngành / còn nợ).
export async function thongKeHocPhi() {
  return spMulti('CALL SP_ThongKeHocPhi()');
}

// Gọi SP_ThuHocPhi — trả mã kết quả qua OUT @KetQua (0 = thành công, 301–304 = lỗi).
export async function thuHocPhi(maHocPhi, soTien) {
  return spOut('CALL SP_ThuHocPhi(?, ?, @KetQua)', [maHocPhi, soTien]);
}

// SP_TinhHocPhi: tự tính học phí = tổng TC × đơn giá.
export async function tinhHocPhi(maSV, maHocKy, donGiaTinChi) {
  return sp('CALL SP_TinhHocPhi(?, ?, ?)', [maSV, maHocKy, donGiaTinChi]);
}
