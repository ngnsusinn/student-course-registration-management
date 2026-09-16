// ============================================================
// routes/index.js — gom toàn bộ router của API (MVC: lớp ROUTE)
// server.js chỉ cần mount 1 lần: app.use('/api', apiRoutes).
// ============================================================
import { Router } from 'express';
import { asyncHandler } from '../middleware/auth.js';
import * as systemController from '../controllers/system.controller.js';

import authRoutes from './auth.js';
import danhmucRoutes from './danhmuc.js';
import dangkyRoutes from './dangky.js';
import ketquaRoutes from './ketqua.js';
import hocphiRoutes from './hocphi.js';
import giangvienRoutes from './giangvien.js';
import adminRoutes from './admin.js';
import prepareRoutes from './prepare.js';   // ⚠️ CÔNG CỤ DEMO: 1-click prepare / fix

const router = Router();

// GET /api/health — health check (không cần xác thực)
router.get('/health', asyncHandler(systemController.health));

router.use('/auth', authRoutes);
router.use('/danhmuc', danhmucRoutes);
router.use('/dangky', dangkyRoutes);
router.use('/ketqua', ketquaRoutes);
router.use('/hocphi', hocphiRoutes);
router.use('/giangvien', giangvienRoutes);
router.use('/admin', adminRoutes);

// ⚠️ CÔNG CỤ DEMO — trang “Chuẩn bị Demo”: 1 click chuẩn bị (triển khai bản
//     có lỗi + dọn dữ liệu) và 1 click fix (khôi phục bản thật).
//     Bỏ dòng này nếu không cần công cụ demo.
router.use('/prepare', prepareRoutes);

export default router;
