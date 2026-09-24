import mysql from 'mysql2/promise';
import { DB_CONFIG } from './src/config.js';

async function main() {
  const conn = await mysql.createConnection({ ...DB_CONFIG, multipleStatements: true });
  await conn.query("SET time_zone = '+07:00'");

  const [triggers] = await conn.query("SELECT TRIGGER_NAME, ACTION_STATEMENT FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA=DATABASE()");
  console.log(`Tổng triggers: ${triggers.length}`);
  triggers.forEach(t => { console.log(`  ${t.TRIGGER_NAME}: ${t.ACTION_STATEMENT?.slice(0, 200)}`); });

  const [dangkyTriggers] = await conn.query("SELECT TRIGGER_NAME, ACTION_STATEMENT FROM information_schema.TRIGGERS WHERE EVENT_OBJECT_TABLE='DANGKYHOCPHAN'");
  console.log('\nTriggers on DANGKYHOCPHAN:');
  dangkyTriggers.forEach(t => { console.log(`  ${t.TRIGGER_NAME}: ${t.ACTION_STATEMENT?.slice(0, 200)}`); });

  const [lhpTriggers] = await conn.query("SELECT TRIGGER_NAME, ACTION_STATEMENT FROM information_schema.TRIGGERS WHERE EVENT_OBJECT_TABLE='LOPHOCPHAN'");
  console.log('\nTriggers on LOPHOCPHAN:');
  lhpTriggers.forEach(t => { console.log(`  ${t.TRIGGER_NAME}: ${t.ACTION_STATEMENT?.slice(0, 200)}`); });

  // Check TRG_DANGKYHOCPHAN_SiSo specifically
  const [siSo] = await conn.query("SELECT ACTION_STATEMENT FROM information_schema.TRIGGERS WHERE TRIGGER_NAME='TRG_DANGKYHOCPHAN_SiSo'");
  if (siSo.length) console.log('\nTRG_DANGKYHOCPHAN_SiSo full:', siSo[0].ACTION_STATEMENT);

  await conn.end();
}
main().catch(e => console.log('Fatal:', e.message));
