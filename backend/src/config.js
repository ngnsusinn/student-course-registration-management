import 'dotenv/config';

export const DB_CONFIG = {
  host: process.env.DB_HOST || 'free02.123host.vn',
  user: process.env.DB_USER || 'roacqgfa_dbms',
  password: process.env.DB_PASSWORD || 'roacqgfa_dbms1',
  database: process.env.DB_NAME || 'roacqgfa_dbms',
  charset: 'utf8mb4_unicode_ci',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  dateStrings: true,
};

export const JWT_SECRET = process.env.JWT_SECRET || 'dangkyhocphan_secret_2026';
export const PORT = process.env.PORT || 3000;
