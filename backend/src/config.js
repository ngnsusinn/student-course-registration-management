import 'dotenv/config';

export const DB_CONFIG = {
  host: process.env.DB_HOST || 'free02.123host.vn',
  // DB_PORT cho phép trỏ tới MySQL/MariaDB chạy cổng khác 3306
  // (ví dụ server sau tunnel ngrok: 0.tcp.ap.ngrok.io:21868).
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'roacqgfa_dbms',
  password: process.env.DB_PASSWORD || 'roacqgfa_dbms1',
  database: process.env.DB_NAME || 'roacqgfa_dbms',
  charset: 'utf8mb4_unicode_ci',
  // ★ Múi giờ UTC+7 (Vietnam) — được SET qua SQL trong db.js
  //   (mysql2 không hỗ trợ timezone option cho session timezone).
  //   Xem: db.js → SET time_zone = '+07:00' trước mỗi SP call.
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  dateStrings: true,
};

export const JWT_SECRET = process.env.JWT_SECRET || 'dangkyhocphan_secret_2026';
export const PORT = process.env.PORT || 3000;
