// ============================================================
// controllers/admin.controller.js — quản trị Phòng Đào Tạo (PĐT)
// Tầng CONTROLLER (MVC): nhận HTTP request, gọi MODEL, trả JSON.
// ============================================================
import * as adminModel from '../models/admin.model.js';

export const THEM_SV_ERROR_MESSAGES = {
  401: 'Mã sinh viên đã tồn tại.',
  402: 'Lớp sinh hoạt không tồn tại.',
  500: 'Lỗi hệ thống.',
};

// GET /api/admin/lophocphan — danh sách tất cả LHP (PĐT quản lý)
export async function lophocphan(req, res) {
  const rows = await adminModel.dsLopHocPhan(req.query.MaHocKy || null, req.query.TrangThaiLop || null);
  res.json({ lopHocPhan: rows });
}

// GET /api/admin/thongke — dashboard tổng hợp
export async function thongKe(req, res) {
  const tongHop = await adminModel.thongKeTongHop();
  const dangKyTheoKy = await adminModel.tkDangKyTheoKy();
  res.json({ tongHop, dangKyTheoKy });
}

// POST /api/admin/taikhoan/sinhvien { MaSV }
export async function taoTaiKhoanSinhVien(req, res) {
  const { MaSV } = req.body || {};
  if (!MaSV) return res.status(400).json({ error: 'Thiếu MaSV.' });
  try {
    await adminModel.taoTaiKhoanSinhVien(MaSV);
    res.json({ message: 'Tạo tài khoản sinh viên thành công.' });
  } catch (e) {
    res.status(400).json({ error: e.sqlMessage || e.message });
  }
}

// POST /api/admin/taikhoan/giangvien { MaGV }
export async function taoTaiKhoanGiangVien(req, res) {
  const { MaGV } = req.body || {};
  if (!MaGV) return res.status(400).json({ error: 'Thiếu MaGV.' });
  try {
    await adminModel.taoTaiKhoanGiangVien(MaGV);
    res.json({ message: 'Tạo tài khoản giảng viên thành công.' });
  } catch (e) {
    res.status(400).json({ error: e.sqlMessage || e.message });
  }
}

// GET /api/admin/taikhoan — danh sách tài khoản
export async function taiKhoan(req, res) {
  res.json({ taiKhoan: await adminModel.dsTaiKhoan() });
}

// PUT /api/admin/taikhoan/khoa { MaTaiKhoan, TrangThai }
export async function khoaTaiKhoan(req, res) {
  const { MaTaiKhoan, TrangThai } = req.body || {};
  if (!MaTaiKhoan || !['ACTIVE', 'LOCKED'].includes(TrangThai)) {
    return res.status(400).json({ error: 'Dữ liệu không hợp lệ.' });
  }
  await adminModel.ganTrangThaiTaiKhoan(MaTaiKhoan, TrangThai);
  res.json({ message: 'Cập nhật trạng thái tài khoản thành công.' });
}

// GET /api/admin/nhatky-doimatkhau
export async function nhatKyDoiMatKhau(req, res) {
  res.json({ nhatKy: await adminModel.dsNhatKyDoiMatKhau() });
}

// POST /api/admin/molophocphan — mở lớp học phần (SP_MoLopHocPhan)
export async function moLopHocPhan(req, res) {
  const b = req.body || {};
  const required = ['MaLHP', 'TenLHP', 'MaMonHoc', 'MaHocKy', 'MaGV', 'SiSoToiDa', 'MaPhong', 'Thu', 'TietBatDau', 'SoTiet'];
  for (const f of required) {
    if (b[f] === undefined || b[f] === null || b[f] === '') {
      return res.status(400).json({ error: `Thiếu trường ${f}.` });
    }
  }
  try {
    await adminModel.moLopHocPhan(b);
    res.json({ message: 'Mở lớp học phần thành công.' });
  } catch (e) {
    res.status(400).json({ error: e.sqlMessage || e.message });
  }
}

// POST /api/admin/themsinhvien — thêm sinh viên + tự tạo tài khoản (SP_ThemSinhVien_Moi)
export async function themSinhVien(req, res) {
  const b = req.body || {};
  const required = ['MaSV', 'HoTen', 'NgaySinh', 'Email', 'SoDienThoai', 'MaLopSH'];
  for (const f of required) {
    if (!b[f]) return res.status(400).json({ error: `Thiếu trường ${f}.` });
  }
  try {
    const kq = await adminModel.themSinhVien(b);
    if (Number(kq) !== 0) {
      return res.status(400).json({ error: THEM_SV_ERROR_MESSAGES[kq] || 'Thêm sinh viên thất bại.' });
    }
    res.json({ message: 'Thêm sinh viên thành công (kèm tài khoản đăng nhập).' });
  } catch (e) {
    res.status(400).json({ error: e.sqlMessage || e.message });
  }
}
