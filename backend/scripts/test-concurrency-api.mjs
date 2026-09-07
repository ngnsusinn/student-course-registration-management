// Test E2E API demo concurrency: login admin -> trangthai -> chuanbi -> chay 6 pha
const BASE = 'http://localhost:3000/api';

const login = await fetch(`${BASE}/auth/login`, {
  method: 'POST', headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ TenDangNhap: 'admin', MatKhau: 'admin@123' }),
});
const loginBody = await login.json();
if (!login.ok) { console.error('[LOGIN FAIL]', login.status, loginBody); process.exit(1); }
const token = loginBody.token || loginBody.Token || loginBody.data?.token;
console.log('[1] Login OK, token length =', token?.length);

const h = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

const tt = await fetch(`${BASE}/concurrency/trangthai`, { headers: h });
console.log('[2] trangthai:', tt.status, JSON.stringify(await tt.json()));

const cb = await fetch(`${BASE}/concurrency/chuanbi`, { method: 'POST', headers: h });
console.log('[3] chuanbi:', cb.status, JSON.stringify(await cb.json()));

const PHAS = ['rr-chan', 'lost-update', 'dirty-read', 'unrepeatable-read', 'phantom-read', 'sp-fix'];
let pass = 0, fail = 0;
for (const p of PHAS) {
  const r = await fetch(`${BASE}/concurrency/demo/${p}`, { method: 'POST', headers: h });
  const body = await r.json();
  if (!r.ok) { console.log(`[4] ${p}: HTTP ${r.status}`, body); fail++; continue; }
  const dat = body.ketLuan?.dat;
  dat ? pass++ : fail++;
  console.log(`[4] ${p}: ${dat ? 'PASS ✅' : 'FAIL/NOTE ❌'} — ${body.ketLuan?.noiDung}`);
  for (const b of body.buoc || []) console.log(`      [${b.phien}] ${b.moTa} => ${b.ketQua}`);
}
console.log(`\n=== API E2E: ${pass} PASS / ${fail} FAIL ===`);
