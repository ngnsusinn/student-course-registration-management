// ============================================================
// routes/admin.js — ánh xạ URL → CONTROLLER (lớp ROUTE, MVC)
// Toàn bộ route dưới đây yêu cầu vai trò PĐT (xác thực ở router.use).
// ============================================================
import { Router } from 'express';
import { authenticate, requireRole, asyncHandler } from '../middleware/auth.js';
import * as adminController from '../controllers/admin.controller.js';

const router = Router();
router.use(authenticate, requireRole('PĐT'));

// GET /api/admin/lophocphan — danh sách tất cả LHP (PĐT quản lý)
router.get('/lophocphan', asyncHandler(adminController.lophocphan));

// GET /api/admin/thongke — dashboard tổng hợp
router.get('/thongke', asyncHandler(adminController.thongKe));

// POST /api/admin/taikhoan/sinhvien { MaSV }
router.post('/taikhoan/sinhvien', asyncHandler(adminController.taoTaiKhoanSinhVien));

// POST /api/admin/taikhoan/giangvien { MaGV }
router.post('/taikhoan/giangvien', asyncHandler(adminController.taoTaiKhoanGiangVien));

// GET /api/admin/taikhoan — danh sách tài khoản
router.get('/taikhoan', asyncHandler(adminController.taiKhoan));

// PUT /api/admin/taikhoan/khoa { MaTaiKhoan, TrangThai }
router.put('/taikhoan/khoa', asyncHandler(adminController.khoaTaiKhoan));

// GET /api/admin/nhatky-doimatkhau
router.get('/nhatky-doimatkhau', asyncHandler(adminController.nhatKyDoiMatKhau));

// POST /api/admin/molophocphan — mở lớp học phần (SP_MoLopHocPhan)
router.post('/molophocphan', asyncHandler(adminController.moLopHocPhan));

// POST /api/admin/themsinhvien — thêm SV + tự tạo tài khoản (SP_ThemSinhVien_Moi)
router.post('/themsinhvien', asyncHandler(adminController.themSinhVien));

export default router;
