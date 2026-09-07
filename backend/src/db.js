import mysql from 'mysql2/promise';
import { DB_CONFIG } from './config.js';

export const pool = mysql.createPool(DB_CONFIG);

export async function getConnection() {
  return pool.getConnection();
}

// ============================================================
// Helper tầng WEB — CHỈ gọi qua VIEW / PROCEDURE / FUNCTION.
// Helper query() tổng quát ĐÃ BỊ GỠ: routes không còn cách nào
// chạy SQL tùy ý — mọi truy vấn dữ liệu đi qua 3 hàm dưới,
// và mỗi route file bị audit bắt buộc chỉ được chứa CALL/SET @.
// ============================================================

// Gọi SP trả về MỘT result set -> mảng dòng.
// CALL x() với mysql2: rows = [rs1, rs2, OkPacket...]; rs1 = mảng dòng.
export async function sp(sql, params = []) {
  const conn = await pool.getConnection();
  try {
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
    const stmts = sqlOut.split(';').map((s) => s.trim()).filter(Boolean)
      .filter((s) => !/^select\s+@KetQua/i.test(s));
    const remaining = [...params];
    for (const stmt of stmts) {
      const n = (stmt.match(/\?/g) || []).length;
      await conn.query(stmt, remaining.splice(0, n));
    }
    const [sel] = await conn.query('SELECT @KetQua AS KetQua');
    return sel && sel.length ? Number(sel[0].KetQua) : undefined;
  } finally {
    conn.release();
  }
}
