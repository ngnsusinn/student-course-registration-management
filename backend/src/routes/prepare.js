// ============================================================
// routes/prepare.js — ⚠️ ROUTE của CÔNG CỤ DEMO (1-click prepare/fix)
//   Yêu cầu đăng nhập (mọi vai trò) — chỉ dùng cho lab/demo.
// ============================================================
import { Router } from 'express';
import { authenticate } from '../middleware/auth.js';
import * as prepareController from '../controllers/prepare.controller.js';

const router = Router();

// GET /api/prepare/trang-thai — đang ở bản nào?
router.get('/trang-thai', authenticate, prepareController.trangThai);

// POST /api/prepare/chuan-bi — 1 CLICK: dựng lại toàn bộ dữ liệu học kỳ hiện tại
//                              + triển khai bản có lỗi
router.post('/chuan-bi', authenticate, prepareController.chuanBi);

// POST /api/prepare/fix — 1 CLICK: khôi phục bản thật + dựng lại dữ liệu học kỳ hiện tại
router.post('/fix', authenticate, prepareController.fix);

export default router;
