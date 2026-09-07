// ============================================================
// routes/concurrency.js — ánh xạ URL → CONTROLLER (lớp ROUTE, MVC)
// API demo 4 lỗi concurrency (plus point) — chỉ PĐT (admin) được chạy.
// Logic demo nằm ở services/anomalyRunner.js (2 session thật trên MySQL).
// ============================================================
import { Router } from 'express';
import { authenticate, requireRole, asyncHandler } from '../middleware/auth.js';
import * as concurrencyController from '../controllers/concurrency.controller.js';

const router = Router();

// GET /api/concurrency/trangthai — trạng thái DB + SP demo đã có chưa
router.get('/trangthai', authenticate, requireRole('PĐT'), asyncHandler(concurrencyController.layTrangThai));

// POST /api/concurrency/chuanbi — đưa LHP demo về "còn đúng 1 chỗ"
router.post('/chuanbi', authenticate, requireRole('PĐT'), asyncHandler(concurrencyController.chuanBi));

// POST /api/concurrency/demo/:ten — chạy 1 pha demo (2 session thật)
router.post('/demo/:ten', authenticate, requireRole('PĐT'), asyncHandler(concurrencyController.chayDemo));

export default router;
