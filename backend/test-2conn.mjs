import mysql from 'mysql2/promise';
import { DB_CONFIG } from './src/config.js';
import { apFileSql } from './src/prepare/sqlRunner.js';

async function main() {
  await apFileSql('lost_update_chua_fix');
  console.log('✅ Đã apply buggy SP (2s sleep)');

  // Reset
  const conn0 = await mysql.createConnection({ ...DB_CONFIG, multipleStatements: true });
  await conn0.query("SET time_zone = '+07:00'");
  await conn0.query("CALL SP_Prepare_Demo('LOST_UPDATE')");
  await conn0.end();

  // Verify SP has DO SLEEP
  const check = await mysql.createConnection({ ...DB_CONFIG, multipleStatements: true });
  await check.query("SET time_zone = '+07:00'");
  const [def] = await check.query("SELECT ROUTINE_DEFINITION LIKE '%DO SLEEP%' AS CoSleep, ROUTINE_DEFINITION LIKE '%FOR UPDATE%' AS CoFU FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_NAME='SP_DangKyHocPhan'");
  console.log(`SP: DO_SLEEP=${def[0].CoSleep}, FOR_UPDATE=${def[0].CoFU}`);
  await check.end();

  // Create 2 separate connections
  const connA = await mysql.createConnection({ ...DB_CONFIG, multipleStatements: true });
  await connA.query("SET time_zone = '+07:00'");
  const connB = await mysql.createConnection({ ...DB_CONFIG, multipleStatements: true });
  await connB.query("SET time_zone = '+07:00'");

  // Call A
  console.log('\n=== Call A (connA) ===');
  const startA = Date.now();
  try {
    await connA.query("CALL SP_DangKyHocPhan('SV030', 'LHP506', 24, 'Phien A', @kqA)");
    const [rA] = await connA.query("SELECT @kqA AS kq");
    console.log(`A: @kqA = ${rA[0].kq} (${Date.now()-startA}ms)`);
  } catch(e) { console.log(`A ERROR: ${e.message}`); }

  // Call B immediately
  console.log('\n=== Call B (connB) ===');
  const startB = Date.now();
  try {
    await connB.query("CALL SP_DangKyHocPhan('SV041', 'LHP506', 24, 'Phien B', @kqB)");
    const [rB] = await connB.query("SELECT @kqB AS kq");
    console.log(`B: @kqB = ${rB[0].kq} (${Date.now()-startB}ms)`);
  } catch(e) { console.log(`B ERROR: ${e.message}`); console.log(`B code: ${e.code}, errno: ${e.errno}`); }

  // Check final state
  const c = await mysql.createConnection({ ...DB_CONFIG, multipleStatements: true });
  await c.query("SET time_zone = '+07:00'");
  const [lhp] = await c.query("SELECT SiSoHienTai, SiSoToiDa, (SELECT COUNT(*) FROM DANGKYHOCPHAN WHERE MaLHP='LHP506' AND TrangThaiDangKy='DA_DANG_KY') AS SoDK FROM LOPHOCPHAN WHERE MaLHP='LHP506'");
  console.log(`\nFinal: ${lhp[0].SiSoHienTai}/${lhp[0].SiSoToiDa}, COUNT=${lhp[0].SoDK}`);
  console.log(lhp[0].SoDK === 2 ? '⚠️ LỖI Lost Update!' : '✅ Không Lost Update');

  await connA.end();
  await connB.end();
  await c.end();

  // Restore
  await apFileSql('sp_dangky_that');
  console.log('\n✅ Đã FIX');
}

main();
