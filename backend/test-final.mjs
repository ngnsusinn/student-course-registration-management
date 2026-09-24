import { apFileSql } from './src/prepare/sqlRunner.js';
import http from 'http';
import mysql from 'mysql2/promise';
import { DB_CONFIG } from './src/config.js';

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

  // Apply new buggy SP (NO SLEEP)
  await apFileSql('lost_update_chua_fix');
  console.log('✅ Đã apply (NO SLEEP)');

  // Verify
  const conn = await mysql.createConnection({ ...DB_CONFIG, multipleStatements: true });
  await conn.query("SET time_zone = '+07:00'");
  const [def] = await conn.query("SELECT ROUTINE_DEFINITION LIKE '%FOR UPDATE%' AS CoFU, ROUTINE_DEFINITION LIKE '%DO SLEEP%' AS CoSleep FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_NAME='SP_DangKyHocPhan'");
  console.log(`SP: FOR_UPDATE=${def[0].CoFU}, DO_SLEEP=${def[0].CoSleep}`);
  await conn.end();

  // Reset data
  const conn2 = await mysql.createConnection({ ...DB_CONFIG, multipleStatements: true });
  await conn2.query("SET time_zone = '+07:00'");
  await conn2.query("CALL SP_Prepare_Demo('LOST_UPDATE')");
  await conn2.end();

  // Test single
  const single = await postJSON('/api/dangky', { MaLHP: 'LHP506', MaxTinChi: 24 }, token);
  console.log(`\nSingle: ketQua=${single.data.ketQua}`);

  // Reset
  const conn3 = await mysql.createConnection({ ...DB_CONFIG, multipleStatements: true });
  await conn3.query("SET time_zone = '+07:00'");
  await conn3.query("CALL SP_Prepare_Demo('LOST_UPDATE')");
  await conn3.end();

  // Test concurrent
  console.log('=== 2 concurrent ===');
  const t1 = Date.now();
  const req1 = postJSON('/api/dangky', { MaLHP: 'LHP506', MaxTinChi: 24 }, token);
  await new Promise(r => setTimeout(r, 100));
  const req2 = postJSON('/api/dangky', { MaLHP: 'LHP506', MaxTinChi: 24 }, token);
  const [r1, r2] = await Promise.all([req1, req2]);
  console.log(`A: HTTP ${r1.status}, ketQua=${r1.data.ketQua}`);
  console.log(`B: HTTP ${r2.status}, ketQua=${r2.data.ketQua}`);
  console.log(`Time: ${Date.now()-t1}ms`);

  // Check
  const c = await mysql.createConnection({ ...DB_CONFIG, multipleStatements: true });
  await c.query("SET time_zone = '+07:00'");
  const [lhp] = await c.query("SELECT SiSoHienTai, SiSoToiDa, (SELECT COUNT(*) FROM DANGKYHOCPHAN WHERE MaLHP='LHP506' AND TrangThaiDangKy='DA_DANG_KY') AS SoDK FROM LOPHOCPHAN WHERE MaLHP='LHP506'");
  console.log(`\nFinal: ${lhp[0].SiSoHienTai}/${lhp[0].SiSoToiDa}, COUNT=${lhp[0].SoDK}`);
  console.log(lhp[0].SoDK === 2 ? '⚠️ LỖI Lost Update!' : '✅ Không Lost Update');
  await c.end();

  // Restore
  await apFileSql('sp_dangky_that');
  console.log('\n✅ Đã FIX');
}

main().catch(e => console.log(`Fatal: ${e.message}`));
