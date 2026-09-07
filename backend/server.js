// ============================================================
// server.js — Entry point (MVC: ROUTE/CONTROLLER/MODEL nằm trong src/)
// Chỉ làm 3 việc: dựng Express app, mount /api (routes/index.js),
// phục vụ bản build frontend (VIEW) với SPA fallback.
// ============================================================
import express from 'express';
import cors from 'cors';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { PORT } from './src/config.js';
import apiRoutes from './src/routes/index.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const app = express();

app.use(cors());
app.use(express.json());

// Toàn bộ REST API (auth · danhmuc · dangky · ketqua · hocphi ·
// giangvien · admin · concurrency · health) — xem src/routes/index.js
app.use('/api', apiRoutes);

// Phục vụ frontend (View):
//  - Ưu tiên React SPA build (frontend/dist — stack mới giống portal.ut.edu.vn)
//  - Fallback: static multi-page cũ (web/) nếu chưa build
const distDir = path.resolve(__dirname, '..', 'frontend', 'dist');
const legacyDir = path.resolve(__dirname, '..', 'web');
const servingDist = fs.existsSync(path.join(distDir, 'index.html'));
const feDir = servingDist ? distDir : legacyDir;
app.use(express.static(feDir));

app.use('/api', (req, res) => res.status(404).json({ error: 'Không tìm thấy API.' }));

// SPA fallback (React history router): GET không phải /api -> index.html
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
