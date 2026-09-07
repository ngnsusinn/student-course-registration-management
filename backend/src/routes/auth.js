// ============================================================
// routes/auth.js — ánh xạ URL → CONTROLLER (lớp ROUTE, MVC)
// ============================================================
import { Router } from 'express';
import { authenticate, asyncHandler } from '../middleware/auth.js';
import * as authController from '../controllers/auth.controller.js';

const router = Router();

// GET /api/auth/hoso — hồ sơ cá nhân (SV/GV) phục vụ dashboard
router.get('/hoso', authenticate, asyncHandler(authController.hoso));

// POST /api/auth/login — đăng nhập (không cần xác thực)
router.post('/login', asyncHandler(authController.login));

// GET /api/auth/me
router.get('/me', authenticate, authController.me);

// POST /api/auth/doimatkhau
router.post('/doimatkhau', authenticate, asyncHandler(authController.doiMatKhau));

export default router;
