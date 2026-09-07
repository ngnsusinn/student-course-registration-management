// ============================================================
// controllers/danhmuc.controller.js — Danh mục & Hồ sơ sinh viên
// Tầng CONTROLLER (MVC): nhận HTTP request, gọi MODEL, trả JSON.
// Toàn bộ dữ liệu chỉ đến từ MODEL (CALL SP/View qua db.js).
// ============================================================
import * as danhmucModel from '../models/danhmuc.model.js';

export const CHUYEN_LOP_ERROR_MESSAGES = {
  403: 'Sinh viên không tồn tại.',
  404: 'Lớp mới không tồn tại.',
  405: 'Sinh viên đã ở lớp này rồi.',
  500: 'Lỗi hệ thống.',
};

// ==================== Đọc danh mục (mọi vai trò) ====================

export async function dsHocKy(req, res) {
  res.json({ hocKy: await danhmucModel.dsHocKy() });
}
export async function dsKhoa(req, res) {
  res.json({ khoa: await danhmucModel.dsKhoa() });
}
export async function dsNganh(req, res) {
  res.json({ nganh: await danhmucModel.dsNganh() });
}
export async function dsLop(req, res) {
  res.json({ lop: await danhmucModel.dsLop() });
}
export async function dsMonHoc(req, res) {
  res.json({ monHoc: await danhmucModel.dsMonHoc(req.query.MaKhoa || null) });
}
export async function dsGiangVien(req, res) {
  res.json({ giangVien: await danhmucModel.dsGiangVien() });
}
export async function dsPhongHoc(req, res) {
  res.json({ phongHoc: await danhmucModel.dsPhongHoc() });
}
export async function dsTienQuyet(req, res) {
  res.json({ tienQuyet: await danhmucModel.dsTienQuyet() });
}
export async function dsCTDT(req, res) {
  res.json({ ctdt: await danhmucModel.dsCTDT(req.query.MaNganh || null) });
}
export async function dsSinhVien(req, res) {
  const { MaLopSH = null, tim = null } = req.query;
  res.json({ sinhVien: await danhmucModel.dsSinhVien(tim, MaLopSH) });
}

// ==================== CTDT ====================

export async function themCTDT(req, res) {
  const { MaNganh, MaMonHoc, HocKyDuKien, BatBuoc = 1 } = req.body || {};
  if (!MaNganh || !MaMonHoc || !HocKyDuKien) return res.status(400).json({ error: 'Thiếu dữ liệu CTĐT.' });
  await danhmucModel.themCTDT({ MaNganh, MaMonHoc, HocKyDuKien, BatBuoc });
  res.json({ message: 'Thêm môn vào chương trình đào tạo thành công.' });
}

export async function xoaCTDT(req, res) {
  await danhmucModel.xoaCTDT(req.params.MaNganh, req.params.MaMonHoc);
  res.json({ message: 'Xóa môn khỏi chương trình đào tạo thành công.' });
}

// ==================== KHOA ====================

export async function themKhoa(req, res) {
  const { MaKhoa, TenKhoa, DienThoaiKhoa = null, EmailKhoa } = req.body || {};
  if (!MaKhoa || !TenKhoa || !EmailKhoa) return res.status(400).json({ error: 'Thiếu MaKhoa, TenKhoa hoặc EmailKhoa.' });
  await danhmucModel.themKhoa({ MaKhoa, TenKhoa, DienThoaiKhoa, EmailKhoa });
  res.json({ message: 'Thêm khoa thành công.' });
}

export async function suaKhoa(req, res) {
  const { TenKhoa, DienThoaiKhoa, EmailKhoa } = req.body || {};
  if (!TenKhoa || !EmailKhoa) return res.status(400).json({ error: 'Thiếu TenKhoa hoặc EmailKhoa.' });
  await danhmucModel.suaKhoa(req.params.MaKhoa, { TenKhoa, DienThoaiKhoa, EmailKhoa });
  res.json({ message: 'Cập nhật khoa thành công.' });
}

export async function xoaKhoa(req, res) {
  try {
    await danhmucModel.xoaKhoa(req.params.MaKhoa);
    res.json({ message: 'Xóa khoa thành công.' });
  } catch {
    res.status(400).json({ error: 'Không thể xóa khoa vì còn dữ liệu tham chiếu (ngành/môn học).' });
  }
}

// ==================== NGANH ====================

export async function themNganh(req, res) {
  const { MaNganh, TenNganh, ThoiGianDaoTao, MaKhoa } = req.body || {};
  if (!MaNganh || !TenNganh || !ThoiGianDaoTao || !MaKhoa) return res.status(400).json({ error: 'Thiếu dữ liệu ngành.' });
  await danhmucModel.themNganh({ MaNganh, TenNganh, ThoiGianDaoTao, MaKhoa });
  res.json({ message: 'Thêm ngành thành công.' });
}

export async function suaNganh(req, res) {
  const { TenNganh, ThoiGianDaoTao, MaKhoa } = req.body || {};
  await danhmucModel.suaNganh(req.params.MaNganh, { TenNganh, ThoiGianDaoTao, MaKhoa });
  res.json({ message: 'Cập nhật ngành thành công.' });
}

// DELETE /api/danhmuc/nganh/:MaNganh (bị TRG_XoaNganh chặn nếu còn SV)
export async function xoaNganh(req, res) {
  try {
    await danhmucModel.xoaNganh(req.params.MaNganh);
    res.json({ message: 'Xóa ngành thành công.' });
  } catch (e) {
    res.status(400).json({ error: e.sqlMessage || e.message });
  }
}

// ==================== LOP_SINHHOAT ====================

export async function themLop(req, res) {
  const { MaLopSH, TenLopSH, NienKhoa, MaNganh } = req.body || {};
  if (!MaLopSH || !TenLopSH || !NienKhoa || !MaNganh) return res.status(400).json({ error: 'Thiếu dữ liệu lớp.' });
  await danhmucModel.themLop({ MaLopSH, TenLopSH, NienKhoa, MaNganh });
  res.json({ message: 'Thêm lớp sinh hoạt thành công.' });
}

export async function suaLop(req, res) {
  const { TenLopSH, NienKhoa, MaNganh } = req.body || {};
  await danhmucModel.suaLop(req.params.MaLopSH, { TenLopSH, NienKhoa, MaNganh });
  res.json({ message: 'Cập nhật lớp thành công.' });
}

export async function xoaLop(req, res) {
  try {
    await danhmucModel.xoaLop(req.params.MaLopSH);
    res.json({ message: 'Xóa lớp thành công.' });
  } catch {
    res.status(400).json({ error: 'Không thể xóa lớp vì còn sinh viên trong lớp.' });
  }
}

// ==================== MONHOC ====================

// POST — thêm môn + danh sách môn tiên quyết trong 1 giao tác (tại MODEL)
export async function themMonHoc(req, res) {
  const { MaMonHoc, TenMonHoc, SoTinChi, SoTietLyThuyet = 0, SoTietThucHanh = 0, MaKhoa, TienQuyet = [] } = req.body || {};
  if (!MaMonHoc || !TenMonHoc || !SoTinChi || !MaKhoa) return res.status(400).json({ error: 'Thiếu dữ liệu môn học.' });
  try {
    await danhmucModel.themMonHocVaTienQuyet({
      MaMonHoc, TenMonHoc, SoTinChi, SoTietLyThuyet, SoTietThucHanh, MaKhoa, TienQuyet,
    });
    res.json({ message: 'Thêm môn học thành công.' });
  } catch (e) {
    res.status(400).json({ error: e.sqlMessage || e.message });
  }
}

export async function suaMonHoc(req, res) {
  const { TenMonHoc, SoTinChi, SoTietLyThuyet, SoTietThucHanh, MaKhoa } = req.body || {};
  await danhmucModel.suaMonHoc(req.params.MaMonHoc, {
    TenMonHoc, SoTinChi, SoTietLyThuyet, SoTietThucHanh, MaKhoa,
  });
  res.json({ message: 'Cập nhật môn học thành công.' });
}

export async function xoaMonHoc(req, res) {
  try {
    await danhmucModel.xoaMonHoc(req.params.MaMonHoc);
    res.json({ message: 'Xóa môn học thành công.' });
  } catch {
    res.status(400).json({ error: 'Không thể xóa môn học vì còn dữ liệu liên quan.' });
  }
}

// ==================== GIANGVIEN ====================

// SP_ThemGiangVien: thêm GV + tạo tài khoản (transaction trong SP)
export async function themGiangVien(req, res) {
  const { MaGV, HoTen, Email, MaKhoa } = req.body || {};
  if (!MaGV || !HoTen || !Email || !MaKhoa) return res.status(400).json({ error: 'Thiếu dữ liệu giảng viên.' });
  try {
    await danhmucModel.themGiangVien({ MaGV, HoTen, Email, MaKhoa });
    res.json({ message: 'Thêm giảng viên thành công (kèm tài khoản).' });
  } catch (e) {
    res.status(400).json({ error: e.sqlMessage || e.message });
  }
}

export async function suaGiangVien(req, res) {
  const { HoTen, Email, MaKhoa } = req.body || {};
  await danhmucModel.suaGiangVien(req.params.MaGV, { HoTen, Email, MaKhoa });
  res.json({ message: 'Cập nhật giảng viên thành công.' });
}

export async function xoaGiangVien(req, res) {
  try {
    await danhmucModel.xoaGiangVien(req.params.MaGV);
    res.json({ message: 'Xóa giảng viên thành công.' });
  } catch {
    res.status(400).json({ error: 'Không thể xóa giảng viên vì còn dữ liệu liên quan.' });
  }
}

// ==================== PHONGHOC ====================

export async function themPhong(req, res) {
  const { MaPhong, TenPhong, SucChua } = req.body || {};
  if (!MaPhong || !TenPhong || !SucChua) return res.status(400).json({ error: 'Thiếu dữ liệu phòng.' });
  await danhmucModel.themPhong({ MaPhong, TenPhong, SucChua });
  res.json({ message: 'Thêm phòng học thành công.' });
}

export async function suaPhong(req, res) {
  const { TenPhong, SucChua } = req.body || {};
  await danhmucModel.suaPhong(req.params.MaPhong, { TenPhong, SucChua });
  res.json({ message: 'Cập nhật phòng học thành công.' });
}

export async function xoaPhong(req, res) {
  try {
    await danhmucModel.xoaPhong(req.params.MaPhong);
    res.json({ message: 'Xóa phòng học thành công.' });
  } catch {
    res.status(400).json({ error: 'Không thể xóa phòng vì còn lịch học tham chiếu.' });
  }
}

// ==================== HOCKY ====================

export async function themHocKy(req, res) {
  const { MaHocKy, TenHocKy, NamHoc, TuNgay, DenNgay, TrangThaiDot = 'MO' } = req.body || {};
  if (!MaHocKy || !TenHocKy || !NamHoc || !TuNgay || !DenNgay) return res.status(400).json({ error: 'Thiếu dữ liệu học kỳ.' });
  await danhmucModel.themHocKy({ MaHocKy, TenHocKy, NamHoc, TuNgay, DenNgay, TrangThaiDot });
  res.json({ message: 'Thêm học kỳ thành công.' });
}

// PUT — mở/đóng đợt đăng ký
export async function suaHocKy(req, res) {
  const { TenHocKy, NamHoc, TuNgay, DenNgay, TrangThaiDot } = req.body || {};
  await danhmucModel.suaHocKy(req.params.MaHocKy, { TenHocKy, NamHoc, TuNgay, DenNgay, TrangThaiDot });
  res.json({ message: 'Cập nhật học kỳ thành công.' });
}

// ==================== SINHVIEN: chuyển lớp & cập nhật hồ sơ ====================

// POST /api/danhmuc/sinhvien/chuyenlop { MaSV, MaLopSH }
export async function chuyenLop(req, res) {
  const { MaSV, MaLopSH } = req.body || {};
  if (!MaSV || !MaLopSH) return res.status(400).json({ error: 'Thiếu MaSV hoặc MaLopSH.' });
  const kq = await danhmucModel.chuyenLop(MaSV, MaLopSH);
  if (Number(kq) !== 0) {
    return res.status(400).json({ error: CHUYEN_LOP_ERROR_MESSAGES[kq] || 'Chuyển lớp thất bại.' });
  }
  res.json({ message: 'Chuyển lớp thành công.' });
}

// PUT /api/danhmuc/sinhvien/:MaSV — cập nhật hồ sơ SV qua SP_CapNhatHoSoSV
export async function capNhatHoSoSV(req, res) {
  const b = req.body || {};
  const { HoTen, NgaySinh, GioiTinh, Email, SoDienThoai, QueQuan, MaLopSH, TrangThaiHoc } = b;
  const maSV = req.params.MaSV;

  if (MaLopSH !== undefined && MaLopSH !== null && MaLopSH !== '') {
    // Chuyển lớp qua SP riêng (giữ nguyên tính năng)
    const kq = await danhmucModel.chuyenLop(maSV, MaLopSH);
    if (Number(kq) !== 0) {
      return res.status(400).json({ error: CHUYEN_LOP_ERROR_MESSAGES[kq] || 'Chuyển lớp thất bại.' });
    }
  }

  if (HoTen === undefined && NgaySinh === undefined && GioiTinh === undefined &&
      Email === undefined && SoDienThoai === undefined && QueQuan === undefined &&
      TrangThaiHoc === undefined) {
    if (MaLopSH === undefined || MaLopSH === null || MaLopSH === '') {
      return res.status(400).json({ error: 'Không có trường nào để cập nhật.' });
    }
    return res.json({ message: 'Cập nhật hồ sơ sinh viên thành công.' });
  }

  await danhmucModel.capNhatHoSoSV(maSV, b);
  res.json({ message: 'Cập nhật hồ sơ sinh viên thành công.' });
}

// DELETE /api/danhmuc/sinhvien/:MaSV
export async function xoaSinhVien(req, res) {
  try {
    const kq = await danhmucModel.xoaSinhVien(req.params.MaSV);
    if (!kq) return res.status(400).json({ error: 'Không tìm thấy sinh viên để xóa.' });
    res.json({ message: 'Xóa sinh viên thành công.' });
  } catch {
    res.status(400).json({ error: 'Không thể xóa sinh viên vì còn dữ liệu liên quan (đăng ký/điểm/học phí).' });
  }
}
