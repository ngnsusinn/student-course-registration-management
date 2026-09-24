import http from 'http';
import { apFileSql } from './src/prepare/sqlRunner.js';

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

  await apFileSql('lost_update_chua_fix');
  const mysql = await import('mysql2/promise');
  const { DB_CONFIG } = await import('./src/config.js');
  const conn = await mysql.createConnection({ ...DB_CONFIG, multipleStatements: true });
  await conn.query("SET time_zone = '+07:00'");
  await conn.query("CALL SP_Prepare_Demo('LOST_UPDATE')");
  await conn.end();

  console.log('\n=== 2 concurrent web requests ===');
  const req1 = postJSON('/api/dangky', { MaLHP: 'LHP506', MaxTinChi: 24 }, token);
  await new Promise(r => setTimeout(r, 100));
  const req2 = postJSON('/api/dangky', { MaLHP: 'LHP506', MaxTinChi: 24 }, token);
  const [r1, r2] = await Promise.all([req1, req2]);
  console.log(`A: ketQua=${r1.data.ketQua}`);
  console.log(`B: ketQua=${r2.data.ketQua}, error=${r2.data.error}`);

  await apFileSql('sp_dangky_that');
  console.log('✅ Đã FIX');
}

main().catch(e => console.log(`Fatal: ${e.message}`));
