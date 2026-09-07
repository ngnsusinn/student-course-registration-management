// ============================================================
// xuatExcel — xuat du lieu bang ra file CSV co BOM UTF-8, mo
// truc tiep bang Excel (giu nguyen tieng Viet co dau). Portal
// that co nut "Xuat Excel" o hau het bang — minh tai tao.
//
// Cols: [{ header: 'Ten cot', key: 'MaCot' },
//        { header: 'Diem', value: (row) => ... }]
// ============================================================
export function xuatExcel(filename, columns, rows) {
  const esc = (v) => {
    const s = v == null ? '' : String(v);
    return /[",;\n]/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s;
  };
  const cell = (c, r) => (typeof c.value === 'function' ? c.value(r) : r[c.key]);
  const head = columns.map((c) => esc(c.header)).join(',');
  const body = (rows || [])
    .map((r) => columns.map((c) => esc(cell(c, r))).join(','))
    .join('\r\n');
  const csv = '\uFEFF' + head + '\r\n' + body;
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = /\.csv$/i.test(filename) ? filename : `${filename}.csv`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}
