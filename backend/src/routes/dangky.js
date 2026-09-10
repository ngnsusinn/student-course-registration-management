// ============================================================
// routes/dangky.js — ánh xạ URL → CONTROLLER (lớp ROUTE, MVC)
// ============================================================
import { Router } from 'express';
import { authenticate, requireRole, asyncHandler } from '../middleware/auth.js';
import * as dangkyController from '../controllers/dangky.controller.js';

const router = Router();

// GET /api/dangky/hocky-hientai
router.get('/hocky-hientai', asyncHandler(dangkyController.hocKyHienTai));

// GET /api/dangky/lopmo — danh sách LHP đang mở cho SV đăng ký
router.get('/lopmo', authenticate, requireRole('SV'), asyncHandler(dangkyController.dsLopMo));

// POST /api/dangky — { MaLHP, GhiChu } → SP_DangKyHocPhan
router.post('/', authenticate, requireRole('SV'), asyncHandler(dangkyController.dangKy));

// POST /api/dangky/nhieu — { DanhSachLHP: [...] } → SP_DangKyNhieuHocPhan
// (đăng ký nhiều lớp trong 1 giao dịch — tính năng thật trên trang Đăng ký lớp học phần)
router.post('/nhieu', authenticate, requireRole('SV'), asyncHandler(dangkyController.dangKyNhieu));

// POST /api/dangky/huy — { MaLHP } → SP_HuyDangKy
router.post('/huy', authenticate, requireRole('SV'), asyncHandler(dangkyController.huyDangKy));

// GET /api/dangky/danhsach?MaHocKy= — danh sách đăng ký của SV
router.get('/danhsach', authenticate, requireRole('SV'), asyncHandler(dangkyController.danhSach));

// GET /api/dangky/thoikhoabieu?MaHocKy=
router.get('/thoikhoabieu', authenticate, requireRole('SV'), asyncHandler(dangkyController.thoiKhoaBieu));

// GET /api/dangky/tongtinchi?MaHocKy=
router.get('/tongtinchi', authenticate, requireRole('SV'), asyncHandler(dangkyController.tongTinChi));

export default router;
