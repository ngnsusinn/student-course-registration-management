import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Box, Grid, Card, CardContent, Typography, Stack, MenuItem, TextField, Table,
  TableBody, TableCell, TableContainer, TableHead, TableRow, CircularProgress, Chip,
} from '@mui/material';
import { toast } from 'react-toastify';
import api, { errMessage } from '../../api/client';
import { thuName } from '../../utils/format';
import { TEAL, TEAL_DARKER } from '../../theme';

// ============================================================
// THOI KHOA BIEU — luoi 7 cot Thứ 2..CN + bang chi tiet
// ============================================================
export default function ThoiKhoaBieu() {
  const [danhSach, setDanhSach] = useState([]);
  const [tkb, setTkb] = useState([]);
  const [maHocKy, setMaHocKy] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([api.get('/dangky/danhsach'), api.get('/dangky/hocky-hientai')])
      .then(([ds, hk]) => {
        const rows = ds.data.danhSach || [];
        setDanhSach(rows);
        const ky = [...new Set(rows.map(r => r.MaHocKy))];
        setMaHocKy(hk.data.hocKy?.MaHocKy && ky.includes(hk.data.hocKy.MaHocKy) ? hk.data.hocKy.MaHocKy : ky[0] || '');
      })
      .catch((e) => toast.error(errMessage(e)))
      .finally(() => setLoading(false));
  }, []);

  const loadTkb = useCallback(() => {
    if (!maHocKy) { setTkb([]); return; }
    setLoading(true);
    api.get('/dangky/thoikhoabieu', { params: { MaHocKy: maHocKy } })
      .then(({ data }) => setTkb(data.thoiKhoaBieu || []))
      .catch((e) => toast.error(errMessage(e)))
      .finally(() => setLoading(false));
  }, [maHocKy]);

  useEffect(() => { loadTkb(); }, [loadTkb]);

  const cacKy = useMemo(() => {
    const map = new Map();
    danhSach.forEach(r => map.set(r.MaHocKy, `${r.TenHocKy} — ${r.NamHoc}`));
    return [...map.entries()];
  }, [danhSach]);

  const tongTC = useMemo(() => {
    const lop = new Map();
    danhSach.filter(r => r.MaHocKy === maHocKy && r.TrangThaiDangKy === 'DA_DANG_KY')
      .forEach(r => lop.set(r.MaLHP, r.SoTinChi));
    return [...lop.values()].reduce((s, x) => s + Number(x), 0);
  }, [danhSach, maHocKy]);

  const byDay = {};
  for (const c of tkb) (byDay[c.Thu] = byDay[c.Thu] || []).push(c);
  const days = [2, 3, 4, 5, 6, 7, 8];

  if (loading && !tkb.length) return <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}><CircularProgress /></Box>;

  return (
    <Box>
      <Card sx={{ mb: 2.5 }}>
        <CardContent>
          <Stack direction="row" spacing={2} alignItems="center" flexWrap="wrap" useFlexGap>
            <Typography variant="h6">📅 Thời khóa biểu</Typography>
            <TextField select size="small" label="Học kỳ" value={maHocKy} onChange={(e) => setMaHocKy(e.target.value)} sx={{ minWidth: 260 }}>
              {cacKy.map(([k, v]) => <MenuItem key={k} value={k}>{v}</MenuItem>)}
            </TextField>
            <Chip color="primary" label={`Tổng cộng: ${tongTC} tín chỉ`} />
          </Stack>
        </CardContent>
      </Card>

      <Grid container spacing={1} sx={{ mb: 2.5 }}>
        {days.map((d) => (
          <Grid item xs={6} sm={4} md={12 / 7} key={d} sx={{ minWidth: 115 }}>
            <Box sx={{ border: '1px solid #e5e7eb', borderRadius: 1.5, overflow: 'hidden', minHeight: 150, bgcolor: '#fff' }}>
              <Typography sx={{ bgcolor: TEAL, color: '#fff', fontFamily: 'Montserrat', fontWeight: 700, fontSize: 12.5, textAlign: 'center', py: 0.75, textTransform: 'uppercase' }}>
                {thuName(d)}
              </Typography>
              {(byDay[d] || []).sort((a, b) => a.TietBatDau - b.TietBatDau).map((c, i) => (
                <Box key={i} sx={{ p: 0.75, borderBottom: '1px dashed #f0f0f0' }}>
                  <Typography sx={{ fontWeight: 700, fontSize: 11.5, color: TEAL_DARKER }}>{c.TenMonHoc}</Typography>
                  <Typography variant="caption" color="text.secondary" display="block">
                    Tiết {c.TietBatDau}–{Number(c.TietBatDau) + Number(c.SoTiet) - 1} · {c.TenPhong}
                  </Typography>
                  <Typography variant="caption" color="text.secondary" display="block">{c.HoTenGV || '—'}</Typography>
                  <Typography variant="caption" sx={{ color: 'text.disabled' }}>{c.MaLHP}</Typography>
                </Box>
              ))}
              {!(byDay[d] || []).length && (
                <Typography variant="caption" color="text.disabled" sx={{ display: 'block', textAlign: 'center', py: 2 }}>[Rỗng]</Typography>
              )}
            </Box>
          </Grid>
        ))}
      </Grid>

      <Card>
        <CardContent>
          <Typography variant="h6" sx={{ mb: 1.5 }}>Danh sách lớp đã đăng ký</Typography>
          <TableContainer>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>Mã LHP</TableCell><TableCell>Môn học</TableCell><TableCell align="center">TC</TableCell>
                  <TableCell align="center">Thứ</TableCell><TableCell align="center">Tiết</TableCell><TableCell>Phòng</TableCell><TableCell>Giảng viên</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {tkb.map((c, i) => (
                  <TableRow key={i} hover>
                    <TableCell><code>{c.MaLHP}</code></TableCell>
                    <TableCell>{c.TenMonHoc}</TableCell>
                    <TableCell align="center">{c.SoTinChi}</TableCell>
                    <TableCell align="center">{thuName(c.Thu)}</TableCell>
                    <TableCell align="center">{c.TietBatDau}–{Number(c.TietBatDau) + Number(c.SoTiet) - 1}</TableCell>
                    <TableCell>{c.TenPhong}</TableCell>
                    <TableCell>{c.HoTenGV || '—'}</TableCell>
                  </TableRow>
                ))}
                {!tkb.length && <TableRow><TableCell colSpan={7} align="center" sx={{ py: 3, color: 'text.disabled' }}>Học kỳ này chưa có lịch học.</TableCell></TableRow>}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>
    </Box>
  );
}
