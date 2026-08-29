import express from 'express';
import cors from 'cors';
import fs from 'node:fs';
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

// Phuc vu frontend:
//  - Uu tien React SPA build (frontend/dist — stack mới giống portal.ut.edu.vn)
//  - Fallback: static multi-page cu (web/) neu chua build
const __dirname2 = __dirname;
const distDir = path.resolve(__dirname2, '..', 'frontend', 'dist');
const legacyDir = path.resolve(__dirname2, '..', 'web');
const servingDist = fs.existsSync(path.join(distDir, 'index.html'));
const feDir = servingDist ? distDir : legacyDir;
app.use(express.static(feDir));

app.use('/api', (req, res) => res.status(404).json({ error: 'Không tìm thấy API.' }));

// SPA fallback (React history router): GET khong phai /api -> index.html
if (servingDist) {
  app.use((req, res, next) => {
    if (req.method === 'GET' && !req.path.startsWith('/api')) {
      return res.sendFile(path.join(distDir, 'index.html'));
    }
    next();
  });
}

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: err.sqlMessage || err.message || 'Lỗi máy chủ.' });
});

app.listen(PORT, () => {
  console.log(`Backend đang chạy tại http://localhost:${PORT}`);
});
