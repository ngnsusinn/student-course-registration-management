// ============================================================
// models/danhmuc.model.js — Danh mục & Hồ sơ sinh viên (Module 1)
// Tầng MODEL (MVC): chỉ giao tiếp DB qua PROCEDURE.
// ============================================================
import { sp, spOut } from '../db.js';

// ==================== Đọc danh mục ====================

export async function dsHocKy() {
  return sp('CALL SP_DM_HocKy()');
}
export async function dsKhoa() {
  return sp('CALL SP_DM_Khoa()');
}
export async function dsNganh() {
  return sp('CALL SP_DM_Nganh()');
}
export async function dsLop() {
  return sp('CALL SP_DM_Lop()');
}
export async function dsMonHoc(maKhoa) {
  return sp('CALL SP_DM_MonHoc(?)', [maKhoa]);
}
export async function dsGiangVien() {
  return sp('CALL SP_DM_GiangVien()');
}
export async function dsPhongHoc() {
  return sp('CALL SP_DM_PhongHoc()');
}
export async function dsTienQuyet() {
  return sp('CALL SP_DM_TienQuyet()');
}
export async function dsCTDT(maNganh) {
  return sp('CALL SP_DM_CTDiet(?)', [maNganh]);
}
export async function dsSinhVien(tim, maLopSH) {
  return sp('CALL SP_DSSinhVien(?, ?)', [tim, maLopSH]);
}

// ==================== KHOA ====================

export async function themKhoa({ MaKhoa, TenKhoa, DienThoaiKhoa, EmailKhoa }) {
  await sp('CALL SP_ThemKhoa(?, ?, ?, ?)', [MaKhoa, TenKhoa, DienThoaiKhoa, EmailKhoa]);
}
export async function suaKhoa(maKhoa, { TenKhoa, DienThoaiKhoa, EmailKhoa }) {
  await sp('CALL SP_SuaKhoa(?, ?, ?, ?)', [maKhoa, TenKhoa, DienThoaiKhoa, EmailKhoa]);
}
export async function xoaKhoa(maKhoa) {
  await sp('CALL SP_XoaKhoa(?)', [maKhoa]);
}

// ==================== NGANH ====================

export async function themNganh({ MaNganh, TenNganh, ThoiGianDaoTao, MaKhoa }) {
  await sp('CALL SP_ThemNganh(?, ?, ?, ?)', [MaNganh, TenNganh, ThoiGianDaoTao, MaKhoa]);
}
export async function suaNganh(maNganh, { TenNganh, ThoiGianDaoTao, MaKhoa }) {
  await sp('CALL SP_SuaNganh(?, ?, ?, ?)', [maNganh, TenNganh, ThoiGianDaoTao, MaKhoa]);
}
export async function xoaNganh(maNganh) {
  await sp('CALL SP_XoaNganh(?)', [maNganh]);
}

// ==================== LOP_SINHHOAT ====================

export async function themLop({ MaLopSH, TenLopSH, NienKhoa, MaNganh }) {
  await sp('CALL SP_ThemLop(?, ?, ?, ?)', [MaLopSH, TenLopSH, NienKhoa, MaNganh]);
}
export async function suaLop(maLopSH, { TenLopSH, NienKhoa, MaNganh }) {
  await sp('CALL SP_SuaLop(?, ?, ?, ?)', [maLopSH, TenLopSH, NienKhoa, MaNganh]);
}
export async function xoaLop(maLopSH) {
  await sp('CALL SP_XoaLop(?)', [maLopSH]);
}

// ==================== MONHOC ====================

// Thêm môn học + danh sách môn tiên quyết trong 1 giao tác.
// ★ Giao tác nằm HOÀN TOÀN trong DB (SP_ThemMonHocVaTienQuyet) — tầng web
//   chỉ gọi 1 lệnh CALL, không tự mở transaction.
export async function themMonHocVaTienQuyet({
  MaMonHoc, TenMonHoc, SoTinChi, SoTietLyThuyet, SoTietThucHanh, MaKhoa, TienQuyet = [],
}) {
  const dsTienQuyet = (Array.isArray(TienQuyet) ? TienQuyet : [])
    .map((x) => String(x || '').trim()).filter(Boolean).join(',');

  return sp('CALL SP_ThemMonHocVaTienQuyet(?, ?, ?, ?, ?, ?, ?)', [
    MaMonHoc, TenMonHoc, Number(SoTinChi), Number(SoTietLyThuyet),
    Number(SoTietThucHanh), MaKhoa, dsTienQuyet,
  ]);
}

export async function suaMonHoc(maMonHoc, { TenMonHoc, SoTinChi, SoTietLyThuyet, SoTietThucHanh, MaKhoa }) {
  await sp('CALL SP_SuaMonHoc(?, ?, ?, ?, ?, ?)',
    [maMonHoc, TenMonHoc, Number(SoTinChi), Number(SoTietLyThuyet), Number(SoTietThucHanh), MaKhoa]);
}
export async function xoaMonHoc(maMonHoc) {
  await sp('CALL SP_XoaMonHoc(?)', [maMonHoc]);
}

// ==================== GIANGVIEN ====================

// SP_ThemGiangVien: thêm GV + tạo tài khoản (transaction trong SP).
export async function themGiangVien({ MaGV, HoTen, Email, MaKhoa }) {
  await sp('CALL SP_ThemGiangVien(?, ?, ?, ?)', [MaGV, HoTen, Email, MaKhoa]);
}
export async function suaGiangVien(maGV, { HoTen, Email, MaKhoa }) {
  await sp('CALL SP_SuaGiangVien(?, ?, ?, ?)', [maGV, HoTen, Email, MaKhoa]);
}
export async function xoaGiangVien(maGV) {
  await sp('CALL SP_XoaGiangVien(?)', [maGV]);
}

// ==================== PHONGHOC ====================

export async function themPhong({ MaPhong, TenPhong, SucChua }) {
  await sp('CALL SP_ThemPhong(?, ?, ?)', [MaPhong, TenPhong, Number(SucChua)]);
}
export async function suaPhong(maPhong, { TenPhong, SucChua }) {
  await sp('CALL SP_SuaPhong(?, ?, ?)', [maPhong, TenPhong, Number(SucChua)]);
}
export async function xoaPhong(maPhong) {
  await sp('CALL SP_XoaPhong(?)', [maPhong]);
}

// ==================== HOCKY ====================

export async function themHocKy({ MaHocKy, TenHocKy, NamHoc, TuNgay, DenNgay, TrangThaiDot }) {
  await sp('CALL SP_ThemHocKy(?, ?, ?, ?, ?, ?)', [MaHocKy, TenHocKy, NamHoc, TuNgay, DenNgay, TrangThaiDot]);
}
export async function suaHocKy(maHocKy, { TenHocKy, NamHoc, TuNgay, DenNgay, TrangThaiDot }) {
  await sp('CALL SP_SuaHocKy(?, ?, ?, ?, ?, ?)',
    [maHocKy, TenHocKy, NamHoc, TuNgay, DenNgay, TrangThaiDot]);
}

// ==================== CTDT ====================

export async function themCTDT({ MaNganh, MaMonHoc, HocKyDuKien, BatBuoc }) {
  await sp('CALL SP_ThemCTDT(?, ?, ?, ?)', [MaNganh, MaMonHoc, Number(HocKyDuKien), Number(BatBuoc)]);
}
export async function xoaCTDT(maNganh, maMonHoc) {
  await sp('CALL SP_XoaCTDT(?, ?)', [maNganh, maMonHoc]);
}

// ==================== SINHVIEN ====================

// SP_ChuyenLop_Nganh — trả mã qua OUT @KetQua (0 = OK, 403–405 = lỗi).
export async function chuyenLop(maSV, maLopSH) {
  return spOut('CALL SP_ChuyenLop_Nganh(?, ?, @KetQua)', [maSV, maLopSH]);
}

// SP_CapNhatHoSoSV — cập nhật hồ sơ SV.
export async function capNhatHoSoSV(maSV, { HoTen, NgaySinh, GioiTinh, Email, SoDienThoai, QueQuan, MaLopSH, TrangThaiHoc }) {
  await sp('CALL SP_CapNhatHoSoSV(?, ?, ?, ?, ?, ?, ?, ?, ?)', [
    maSV,
    HoTen ?? null,
    NgaySinh ?? null,
    GioiTinh === undefined || GioiTinh === '' ? null : Number(GioiTinh),
    Email ?? null,
    SoDienThoai ?? null,
    QueQuan ?? null,
    (MaLopSH !== undefined && MaLopSH !== null && MaLopSH !== '') ? MaLopSH : null,
    TrangThaiHoc === undefined || TrangThaiHoc === '' ? null : Number(TrangThaiHoc),
  ]);
}

// SP_XoaSinhVien — trả mã qua OUT @KetQua.
export async function xoaSinhVien(maSV) {
  return spOut('CALL SP_XoaSinhVien(?, @KetQua)', [maSV]);
}
