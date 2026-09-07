// ============================================================
// controllers/concurrency.controller.js — API demo 4 lỗi concurrency
// Tầng CONTROLLER (MVC): chỉ điều phối module demo (services/anomalyRunner).
// ============================================================
import { trangThai, chuanBiDemo, chayPha } from '../services/anomalyRunner.js';

// GET /api/concurrency/trangthai — trạng thái DB + SP demo đã có chưa
export async function layTrangThai(req, res) {
  res.json(await trangThai());
}

// POST /api/concurrency/chuanbi — đưa LHP demo về "còn đúng 1 chỗ"
export async function chuanBi(req, res) {
  res.json(await chuanBiDemo());
}

// POST /api/concurrency/demo/:ten — chạy 1 pha demo (2 session thật)
export async function chayDemo(req, res) {
  const kq = await chayPha(req.params.ten);
  if (!kq) return res.status(404).json({ error: 'Không có pha demo tên này.' });
  res.json(kq);
}
