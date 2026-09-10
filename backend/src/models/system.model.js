// ============================================================
// models/system.model.js — truy xuất dữ liệu hệ thống
// Tầng MODEL (MVC): chỉ giao tiếp DB qua PROCEDURE/VIEW.
// ============================================================
import { sp } from '../db.js';

// Gọi SP_HealthCheck để kiểm tra kết nối DB (chỉ CALL, không raw query).
export async function healthCheck() {
  const rows = await sp('CALL SP_HealthCheck()');
  return rows[0]?.ok === 1;
}
