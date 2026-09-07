// ============================================================
// controllers/giangvien.controller.js — chức năng Giảng viên
// Tầng CONTROLLER (MVC): nhận HTTP request, gọi MODEL, trả JSON.
// ============================================================
import * as giangvienModel from '../models/giangvien.model.js';

export const LOP_ERROR_MESSAGES = {
  0: 'Không tìm thấy lớp học phần.',
  2: 'Bạn không phụ trách lớp học phần này.',
};

// GET /api/giangvien/lopcuatoi?MaHocKy= (GV xem lớp mình dạy)
export async function lopCuaToi(req, res) {
  const lop = await giangvienModel.lopCuaToi(req.user.MaGV, req.query.MaHocKy || null);
  res.json({ lop });
}

// GET /api/giangvien/sinhvien/:MaLHP (GV xem danh sách SV + điểm của lớp)
export async function sinhVienCuaLop(req, res) {
  const maGV = req.user.MaGV;
  const { MaLHP } = req.params;

  const kq = await giangvienModel.kiemTraLop(maGV, MaLHP);
  if (kq === 0) return res.status(404).json({ error: LOP_ERROR_MESSAGES[0] });
  if (kq === 2) return res.status(403).json({ error: LOP_ERROR_MESSAGES[2] });

  const sinhVien = await giangvienModel.dsSinhVienTrongLop(MaLHP);
  res.json({ sinhVien });
}

// POST /api/giangvien/nhapdiem { MaSV, MaLHP, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy }
export async function nhapDiem(req, res) {
  const maGV = req.user.MaGV;
  const { MaSV, MaLHP, DiemChuyenCan = null, DiemGiuaKy = null, DiemCuoiKy = null } = req.body || {};
  if (!MaSV || !MaLHP) return res.status(400).json({ error: 'Thiếu MaSV hoặc MaLHP.' });

  try {
    await giangvienModel.nhapDiem(maGV, MaSV, MaLHP, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy);
    res.json({ message: 'Nhập điểm thành công.' });
  } catch (e) {
    res.status(400).json({ error: e.sqlMessage || e.message });
  }
}

// POST /api/giangvien/nhapdiem-hangloat { MaLHP, DanhSachDiem: [...] }
export async function nhapDiemHangLoat(req, res) {
  const maGV = req.user.MaGV;
  const { MaLHP, DanhSachDiem = [] } = req.body || {};
  if (!MaLHP || !Array.isArray(DanhSachDiem) || !DanhSachDiem.length) {
    return res.status(400).json({ error: 'Thiếu MaLHP hoặc danh sách điểm.' });
  }

  // Kiểm tra GV phụ trách lớp (SP_GV_KiemTraLop)
  const kq = await giangvienModel.kiemTraLop(maGV, MaLHP);
  if (kq === 0) return res.status(404).json({ error: LOP_ERROR_MESSAGES[0] });
  if (kq === 2) return res.status(403).json({ error: LOP_ERROR_MESSAGES[2] });

  try {
    await giangvienModel.nhapDiemHangLoat(maGV, MaLHP, DanhSachDiem);
    res.json({ message: `Nhập điểm hàng loạt thành công (${DanhSachDiem.length} SV).` });
  } catch (e) {
    res.status(400).json({ error: e.sqlMessage || e.message });
  }
}
