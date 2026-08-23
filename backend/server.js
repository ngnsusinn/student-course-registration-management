import express from 'express';
import cors from 'cors';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { PORT } from './src/config.js';
import { pool } from './src/db.js';

import authRoutes from './src/routes/auth.js';
import danhmucRoutes from './src/routes/danhmuc.js';
import dangkyRoutes from './src/routes/dangky.js';
import ketquaRoutes from './src/routes/ketqua.js';
import hocphiRoutes from './src/routes/hocphi.js';
import giangvienRoutes from './src/routes/giangvien.js';
import adminRoutes from './src/routes/admin.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const app = express();

app.use(cors());
app.use(express.json());

app.get('/api/health', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT 1 AS ok');
    res.json({ status: 'ok', db: rows[0].ok === 1 ? 'connected' : 'error' });
  } catch (e) {
    res.status(500).json({ status: 'error', message: e.message });
  }
});

app.use('/api/auth', authRoutes);
app.use('/api/danhmuc', danhmucRoutes);
app.use('/api/dangky', dangkyRoutes);
app.use('/api/ketqua', ketquaRoutes);
app.use('/api/hocphi', hocphiRoutes);
app.use('/api/giangvien', giangvienRoutes);
app.use('/api/admin', adminRoutes);

// Phục vụ frontend (thu mục web/) — đặt TRƯỚC catch-all 404
const webDir = path.resolve(__dirname, '..', 'web');
app.use(express.static(webDir));

app.use('/api', (req, res) => res.status(404).json({ error: 'Không tìm thấy API.' }));

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: err.sqlMessage || err.message || 'Lỗi máy chủ.' });
});

app.listen(PORT, () => {
  console.log(`Backend đang chạy tại http://localhost:${PORT}`);
});
