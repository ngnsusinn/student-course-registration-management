// ============================================================
// routes/ketqua.js — ánh xạ URL → CONTROLLER (lớp ROUTE, MVC)
// ============================================================
import { Router } from 'express';
import { authenticate, requireRole, asyncHandler } from '../middleware/auth.js';
import * as ketquaController from '../controllers/ketqua.controller.js';

const router = Router();

// GET /api/ketqua/bangdiem?MaHocKy= (SV xem bảng điểm của mình)
router.get('/bangdiem', authenticate, requireRole('SV'), asyncHandler(ketquaController.bangDiem));

// GET /api/ketqua/gpa?MaHocKy= (SV)
router.get('/gpa', authenticate, requireRole('SV'), asyncHandler(ketquaController.gpa));

// GET /api/ketqua/cpa (SV)
router.get('/cpa', authenticate, requireRole('SV'), asyncHandler(ketquaController.cpa));

// GET /api/ketqua/thangdiemchu
router.get('/thangdiemchu', authenticate, asyncHandler(ketquaController.thangDiemChu));

// GET /api/ketqua/thongke-monhoc (GV / PĐT)
router.get('/thongke-monhoc', authenticate, requireRole('GV', 'PĐT'), asyncHandler(ketquaController.thongKeMonHoc));

// GET /api/ketqua/canhbao-hocvu (PĐT) — danh sách SV cảnh báo học vụ
router.get('/canhbao-hocvu', authenticate, requireRole('PĐT'), asyncHandler(ketquaController.canhBaoHocVu));

// GET /api/ketqua/gpa-theo-lop/:MaLHP (GV xem GPA từng SV trong lớp)
router.get('/gpa-theo-lop/:MaLHP', authenticate, requireRole('GV', 'PĐT'), asyncHandler(ketquaController.gpaTheoLop));

export default router;
