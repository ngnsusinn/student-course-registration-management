import { apFileSql } from './src/prepare/sqlRunner.js';
import http from 'http';

const BASE = 'http://localhost:3000';

function postJSON(path, body, token) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const req = http.request(`${BASE}${path}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Content-Length': data.length, 'Authorization': `Bearer ${token}` },
    }, (res) => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => { try { resolve({ status: res.statusCode, data: JSON.parse(d) }); } catch(e) { resolve({ status: res.statusCode, data: d }); } });
    });
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

async function main() {
  const login = await postJSON('/api/auth/login', { TenDangNhap: 'sv030', MatKhau: 'matkhau@123' });
  const token = login.data.token;
  console.log('✅ Login OK');

  // Reset
  const s = await postJSON('/api/prepare/chuan-bi', { kichBan: 'LOST_UPDATE' }, token);
  console.log('Prepare:', s.data.thongDiep?.slice(0, 50));

  // Concurrent
  console.log('\n=== 2 concurrent web requests ===');
  const t = Date.now();
  const [r1, r2] = await Promise.all([postJSON('/api/dangky', { MaLHP: 'LHP506', MaxTinChi: 24 }, token), postJSON('/api/dangky', { MaLHP: 'LHP506', MaxTinChi: 24 }, token)]);
  console.log(`A: HTTP ${r1.status}, ketQua=${r1.data.ketQua}`);
  console.log(`B: HTTP ${r2.status}, ketQua=${r2.data.ketQua}`);
  console.log('Time:', Date.now()-t, 'ms');
}

main().catch(e => console.log('Fatal:', e.message));
