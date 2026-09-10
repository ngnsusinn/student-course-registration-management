// ============================================================
// models/giangvien.model.js — chức năng Giảng viên
// Tầng MODEL (MVC): chỉ giao tiếp DB qua PROCEDURE.
// ============================================================
import { sp } from '../db.js';

// Danh sách lớp GV phụ trách theo học kỳ.
export async function lopCuaToi(maGV, maHocKy) {
  return sp('CALL SP_GV_LopCuaToi(?, ?)', [maGV, maHocKy]);
}

// SP_GV_KiemTraLop — kiểm tra GV có phụ trách lớp không.
// Trả về mã: 1 = OK, 0 = không tồn tại LHP, 2 = GV không phụ trách.
export async function kiemTraLop(maGV, maLHP) {
  const [kt] = await sp('CALL SP_GV_KiemTraLop(?, ?)', [maGV, maLHP]);
  return Number(kt?.KetQua);
}

// Danh sách SV (kèm điểm) trong lớp GV phụ trách.
export async function dsSinhVienTrongLop(maLHP) {
  return sp('CALL SP_GV_DSSinhVienLop(?)', [maLHP]);
}

// Nhập điểm 1 sinh viên (SP_GV_NHAP_DIEM — điểm TK/chữ/hệ 4 do Trigger tự tính).
export async function nhapDiem(maGV, maSV, maLHP, diemChuyenCan, diemGiuaKy, diemCuoiKy) {
  await sp('CALL SP_GV_NHAP_DIEM(?, ?, ?, ?, ?, ?)', [
    maGV, maSV, maLHP, diemChuyenCan, diemGiuaKy, diemCuoiKy,
  ]);
}

// Nhập điểm hàng loạt cho cả lớp trong MỘT GIAO TÁC.
// ★ Giao tác nằm HOÀN TOÀN trong DB (SP_GV_NhapDiemHangLoat): tầng web chỉ
//   mã hoá danh sách điểm thành chuỗi 'MaSV:CC:GK:CK;...' rồi gọi 1 lệnh CALL.
//   Bất kỳ dòng nào sai ⇒ SP ROLLBACK cả lô (nguyên tử thật sự).
export async function nhapDiemHangLoat(maGV, maLHP, danhSachDiem) {
  const diem = (v) => (v === null || v === undefined || v === '' ? '' : String(Number(v)));
  const chuoi = (Array.isArray(danhSachDiem) ? danhSachDiem : [])
    .filter((d) => d && d.MaSV)
    .map((d) => [d.MaSV, diem(d.DiemChuyenCan), diem(d.DiemGiuaKy), diem(d.DiemCuoiKy)].join(':'))
    .join(';');

  return sp('CALL SP_GV_NhapDiemHangLoat(?, ?, ?)', [maGV, maLHP, chuoi]);
}
