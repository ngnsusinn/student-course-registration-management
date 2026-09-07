// ============================================================
// routes/danhmuc.js — ánh xạ URL → CONTROLLER (lớp ROUTE, MVC)
// Các endpoint đọc danh mục mở cho mọi vai trò đã xác thực;
// thao tác ghi (CRUD) yêu cầu vai trò PĐT.
// ============================================================
import { Router } from 'express';
import { authenticate, requireRole, asyncHandler } from '../middleware/auth.js';
import * as danhmucController from '../controllers/danhmuc.controller.js';

const router = Router();

// ==================== Đọc danh mục (mọi vai trò đã đăng nhập) ====================

router.get('/hocky', authenticate, asyncHandler(danhmucController.dsHocKy));
router.get('/khoa', authenticate, asyncHandler(danhmucController.dsKhoa));
router.get('/nganh', authenticate, asyncHandler(danhmucController.dsNganh));
router.get('/lop', authenticate, asyncHandler(danhmucController.dsLop));
router.get('/monhoc', authenticate, asyncHandler(danhmucController.dsMonHoc));
router.get('/giangvien', authenticate, asyncHandler(danhmucController.dsGiangVien));
router.get('/phonghoc', authenticate, asyncHandler(danhmucController.dsPhongHoc));
router.get('/tienquyet', authenticate, asyncHandler(danhmucController.dsTienQuyet));

// Chương trình đào tạo (PĐT)
router.get('/ctdt', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.dsCTDT));
router.post('/ctdt', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.themCTDT));
router.delete('/ctdt/:MaNganh/:MaMonHoc', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.xoaCTDT));

// Danh sách sinh viên (PĐT)
router.get('/sinhvien', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.dsSinhVien));

// ==================== CRUD Quản lý danh mục (PĐT) ====================

// ---------- KHOA ----------
router.post('/khoa', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.themKhoa));
router.put('/khoa/:MaKhoa', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.suaKhoa));
router.delete('/khoa/:MaKhoa', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.xoaKhoa));

// ---------- NGANH ----------
router.post('/nganh', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.themNganh));
router.put('/nganh/:MaNganh', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.suaNganh));
router.delete('/nganh/:MaNganh', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.xoaNganh));

// ---------- LOP_SINHHOAT ----------
router.post('/lop', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.themLop));
router.put('/lop/:MaLopSH', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.suaLop));
router.delete('/lop/:MaLopSH', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.xoaLop));

// ---------- MONHOC ----------
router.post('/monhoc', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.themMonHoc));
router.put('/monhoc/:MaMonHoc', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.suaMonHoc));
router.delete('/monhoc/:MaMonHoc', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.xoaMonHoc));

// ---------- GIANGVIEN ----------
router.post('/giangvien', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.themGiangVien));
router.put('/giangvien/:MaGV', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.suaGiangVien));
router.delete('/giangvien/:MaGV', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.xoaGiangVien));

// ---------- PHONGHOC ----------
router.post('/phonghoc', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.themPhong));
router.put('/phonghoc/:MaPhong', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.suaPhong));
router.delete('/phonghoc/:MaPhong', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.xoaPhong));

// ---------- HOCKY ----------
router.post('/hocky', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.themHocKy));
router.put('/hocky/:MaHocKy', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.suaHocKy));

// ---------- SINHVIEN: chuyển lớp & cập nhật hồ sơ ----------
router.post('/sinhvien/chuyenlop', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.chuyenLop));
router.put('/sinhvien/:MaSV', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.capNhatHoSoSV));
router.delete('/sinhvien/:MaSV', authenticate, requireRole('PĐT'), asyncHandler(danhmucController.xoaSinhVien));

export default router;
