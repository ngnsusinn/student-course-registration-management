// ============================================================
// routes/giangvien.js — ánh xạ URL → CONTROLLER (lớp ROUTE, MVC)
// ============================================================
import { Router } from 'express';
import { authenticate, requireRole, asyncHandler } from '../middleware/auth.js';
import * as giangvienController from '../controllers/giangvien.controller.js';

const router = Router();

// GET /api/giangvien/lopcuatoi?MaHocKy= (GV xem lớp mình dạy)
router.get('/lopcuatoi', authenticate, requireRole('GV'), asyncHandler(giangvienController.lopCuaToi));

// GET /api/giangvien/sinhvien/:MaLHP (GV xem danh sách SV + điểm của lớp)
router.get('/sinhvien/:MaLHP', authenticate, requireRole('GV'), asyncHandler(giangvienController.sinhVienCuaLop));

// POST /api/giangvien/nhapdiem
router.post('/nhapdiem', authenticate, requireRole('GV'), asyncHandler(giangvienController.nhapDiem));

// POST /api/giangvien/nhapdiem-hangloat
router.post('/nhapdiem-hangloat', authenticate, requireRole('GV'), asyncHandler(giangvienController.nhapDiemHangLoat));

export default router;
