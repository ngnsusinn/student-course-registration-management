// ============================================================
// routes/hocphi.js — ánh xạ URL → CONTROLLER (lớp ROUTE, MVC)
// ============================================================
import { Router } from 'express';
import { authenticate, requireRole, asyncHandler } from '../middleware/auth.js';
import * as hocphiController from '../controllers/hocphi.controller.js';

const router = Router();

// GET /api/hocphi/cua-toi (SV)
router.get('/cua-toi', authenticate, requireRole('SV'), asyncHandler(hocphiController.cuaToi));

// GET /api/hocphi/danhsach?TrangThai=&MaHocKy= (PĐT)
router.get('/danhsach', authenticate, requireRole('PĐT'), asyncHandler(hocphiController.danhSach));

// GET /api/hocphi/baocao (PĐT) — tổng hợp từ các view
router.get('/baocao', authenticate, requireRole('PĐT'), asyncHandler(hocphiController.baoCao));

// POST /api/hocphi/thu { MaHocPhi, SoTien } (PĐT) → SP_ThuHocPhi
router.post('/thu', authenticate, requireRole('PĐT'), asyncHandler(hocphiController.thu));

// POST /api/hocphi/tinh { MaSV, MaHocKy, DonGiaTinChi } (PĐT) → SP_TinhHocPhi
router.post('/tinh', authenticate, requireRole('PĐT'), asyncHandler(hocphiController.tinh));

export default router;
