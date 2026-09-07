// ============================================================
// controllers/system.controller.js — health check hệ thống
// Tầng CONTROLLER (MVC): nhận HTTP request, gọi MODEL, trả JSON.
// ============================================================
import { healthCheck } from '../models/system.model.js';

// GET /api/health — trạng thái server + kết nối DB
export async function health(req, res) {
  try {
    const ok = await healthCheck();
    res.json({ status: 'ok', db: ok ? 'connected' : 'error' });
  } catch (e) {
    res.status(500).json({ status: 'error', message: e.message });
  }
}
