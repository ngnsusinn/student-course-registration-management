// ============================================================
// models/system.model.js — truy xuất dữ liệu hệ thống
// Tầng MODEL (MVC): chỉ giao tiếp DB qua PROCEDURE/VIEW.
// ============================================================
import { pool } from '../db.js';

// Gọi SP_HealthCheck để kiểm tra kết nối DB.
export async function healthCheck() {
  const [rows] = await pool.query('CALL SP_HealthCheck()');
  return rows[0]?.[0]?.ok === 1;
}
