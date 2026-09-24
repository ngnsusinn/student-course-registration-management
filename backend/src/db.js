import mysql from 'mysql2/promise';
import { DB_CONFIG } from './config.js';

// ============================================================
// Pool nội bộ — CỐ TÌNH KHÔNG export: tầng web không có cách nào lấy
// connection thô, do đó không thể tự mở transaction hay chạy SQL tùy ý.
//
// ★ NGUYÊN TẮC:
//   1. MỌI GIAO TÁC (START TRANSACTION / COMMIT / ROLLBACK) nằm trong
//      STORED PROCEDURE ở database — tầng web KHÔNG tự mở transaction.
//   2. Tầng web chỉ chạy `CALL <SP>` (và `SET @var` / `SELECT @var` để đọc
//      tham số OUT). Không có raw query, không có connection thô.
//   Helper query() tổng quát ĐÃ BỊ GỠ; pool/getConnection không được export.
//   Kiểm chứng tự động: `node scripts/audit-no-raw-query.mjs`.
// ============================================================

// Tất cả connection trong pool đều dùng múi giờ UTC+7 (Vietnam).
// SET time_zone phải chạy trên MỖI connection vì mysql2 không hỗ trợ
// timezone option trong createPool (chỉ ảnh hưởng đến serialization Date).
const TIMEZONE_SQL = "SET time_zone = '+07:00'";

const pool = mysql.createPool(DB_CONFIG);

// Khởi tạo: SET time_zone cho 1 connection trong pool (để kiểm tra).
// Các connection khác sẽ tự động SET khi được sử dụng qua sp/spMulti/spOut.
try {
  const conn = await pool.getConnection();
  try { await conn.query(TIMEZONE_SQL); }
  finally { conn.release(); }
} catch { /* pool chưa sẵn sàng — sẽ SET ở lần dùng đầu tiên */ }

// ============================================================
// Helper tầng WEB — CHỈ gọi qua VIEW / PROCEDURE / FUNCTION.
//
// Gọi SP trả về MỘT result set -> mảng dòng.
// CALL x() với mysql2: rows = [rs1, rs2, OkPacket...]; rs1 = mảng dòng.
export async function sp(sql, params = []) {
  const conn = await pool.getConnection();
  try {
    await conn.query(TIMEZONE_SQL);           // ← đảm bảo múi giờ UTC+7
    const [rows] = await conn.query(sql, params);
    return rows[0] ?? [];
  } finally {
    conn.release();
  }
}

// Gọi SP trả về NHIỀU result set -> mảng các mảng dòng.
export async function spMulti(sql, params = []) {
  const conn = await pool.getConnection();
  try {
    await conn.query(TIMEZONE_SQL);           // ← đảm bảo múi giờ UTC+7
    const [rows] = await conn.query(sql, params);
    return rows.filter(Array.isArray);
  } finally {
    conn.release();
  }
}

// Gọi SP dùng tham số OUT rồi đọc biến @KetQua trên CÙNG kết nối.
// Cú pháp: spOut('CALL SP_X(?, @KetQua)', [a]) — tự thêm 'SELECT @KetQua'.
// Lưu ý: KHÔNG gộp 'CALL; SELECT' trong 1 multi-statement (MySQL 5.7 báo
// ER_PARSE_ERROR), nên tách câu và chạy lần lượt trên 1 connection —
// placeholder của từng câu nhận params lần lượt theo thứ tự.
export async function spOut(sqlOut, params = []) {
  const conn = await pool.getConnection();
  try {
    await conn.query(TIMEZONE_SQL);
    const stmts = sqlOut.split(';').map((s) => s.trim()).filter(Boolean)
      .filter((s) => !/^select\s+@KetQua/i.test(s));
    const remaining = [...params];
    for (const stmt of stmts) {
      const n = (stmt.match(/\?/g) || []).length;
      try {
        await conn.query(stmt, remaining.splice(0, n));
      } catch (e) {
        console.log('[spOut] ERROR on stmt:', stmt.slice(0, 80), '→', e.message, '| code:', e.code, '| errno:', e.errno, '| sqlMessage:', e.sqlMessage?.slice(0, 100));
        throw e;
      }
    }
    const [sel] = await conn.query('SELECT @KetQua AS KetQua');
    return sel && sel.length ? Number(sel[0].KetQua) : undefined;
  } finally {
    conn.release();
  }
}

// Như spOut nhưng TRẢ VỀ CẢ dòng tổng kết mà SP SELECT ra: { ketQua, dong }.
// Dùng cho SP vừa trả mã lỗi qua OUT vừa trả 1 result set mô tả chi tiết
// (ví dụ SP_DangKyNhieuHocPhan — đăng ký nhiều học phần trong 1 giao dịch).
export async function spOutFull(sqlOut, params = []) {
  const conn = await pool.getConnection();
  try {
    await conn.query(TIMEZONE_SQL);           // ← đảm bảo múi giờ UTC+7
    const stmts = sqlOut.split(';').map((s) => s.trim()).filter(Boolean)
      .filter((s) => !/^select\s+@KetQua/i.test(s));
    const remaining = [...params];
    let rs = null;
    for (const stmt of stmts) {
      const n = (stmt.match(/\?/g) || []).length;
      const [rows] = await conn.query(stmt, remaining.splice(0, n));
      if (Array.isArray(rows)) rs = rows;
    }
    const [sel] = await conn.query('SELECT @KetQua AS KetQua');
    const dong = Array.isArray(rs) && Array.isArray(rs[0]) ? rs[0][0] : null;
    return { ketQua: sel && sel.length ? Number(sel[0].KetQua) : undefined, dong };
  } finally {
    conn.release();
  }
}
