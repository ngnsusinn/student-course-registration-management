import mysql from 'mysql2/promise';
import { DB_CONFIG } from './src/config.js';
import { apFileSql } from './src/prepare/sqlRunner.js';

async function main() {
  await apFileSql('lost_update_chua_fix');
  console.log('✅ Applied lost_update_chua_fix');

  const conn = await mysql.createConnection({ ...DB_CONFIG, multipleStatements: true });
  await conn.query("SET time_zone = '+07:00'");
  const [def] = await conn.query("SELECT ROUTINE_DEFINITION FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_NAME='SP_DangKyHocPhan'");
  const d = def[0].ROUTINE_DEFINITION;
  console.log('DO SLEEP at:', d.indexOf('DO SLEEP'));
  console.log('vDoTreGiay at:', d.indexOf('vDoTreGiay'));

  await conn.query("CALL SP_Prepare_Demo('LOST_UPDATE')");
  console.log('✅ Reset dữ liệu');

  // Test call
  console.log('\n=== GỌI SP_DangKyHocPhan ===');
  const start = Date.now();
  try {
    await conn.query("CALL SP_DangKyHocPhan('SV030', 'LHP506', 24, 'test', @kq)");
    const elapsed = Date.now() - start;
    const [r] = await conn.query("SELECT @kq AS KetQua");
    console.log('Thời gian:', elapsed, 'ms');
    console.log('@kq =', r[0].KetQua);
    console.log(elapsed > 7000 ? '✅ DO SLEEP hoạt động' : '❌ DO SLEEP KHÔNG hoạt động');
  } catch(e) { console.log('ERROR:', e.message); }

  await conn.end();
}
main().catch(e => console.log('Fatal:', e.message));
