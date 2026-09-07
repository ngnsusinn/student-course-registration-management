// ============================================================
// models/giangvien.model.js — chức năng Giảng viên
// Tầng MODEL (MVC): chỉ giao tiếp DB qua PROCEDURE.
// ============================================================
import { sp, getConnection } from '../db.js';

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

// Nhập điểm hàng loạt: từng SV bằng SP trong 1 giao tác (rollback nếu 1 dòng lỗi).
export async function nhapDiemHangLoat(maGV, maLHP, danhSachDiem) {
  const conn = await getConnection();
  try {
    await conn.beginTransaction();
    for (const d of danhSachDiem) {
      if (!d.MaSV) continue;
      await conn.query('CALL SP_GV_NHAP_DIEM(?, ?, ?, ?, ?, ?)', [
        maGV, d.MaSV, maLHP,
        d.DiemChuyenCan ?? null, d.DiemGiuaKy ?? null, d.DiemCuoiKy ?? null,
      ]);
    }
    await conn.commit();
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
}
