import { useEffect, useMemo, useState } from 'react';
import {
  Box, Grid, Card, CardContent, Typography, Table, TableBody, TableCell,
  TableContainer, TableHead, TableRow, CircularProgress, Chip,
} from '@mui/material';
import { toast } from 'react-toastify';
import api, { errMessage } from '../../api/client';
import { thuName } from '../../utils/format';
import { TEAL, TEAL_DARKER } from '../../theme';

// ============================================================
// TKB GIANG VIEN — luoi 7 cot tu chuoi LichHoc "2:1-3; 5:7-9"
// ============================================================
export default function ThoiKhoaBieuGV() {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get('/giangvien/lopcuatoi')
      .then(({ data }) => setRows(data.lop || []))
      .catch((e) => toast.error(errMessage(e)))
      .finally(() => setLoading(false));
  }, []);

  const slots = useMemo(() => {
    const out = [];
    for (const r of rows) {
      for (const p of String(r.LichHoc || '').split('; ')) {
        const m = p.match(/^(\d+):(\d+)-(\d+)/);
        if (m) out.push({ thu: Number(m[1]), batDau: Number(m[2]), ketThuc: Number(m[3]), lop: r });
      }
    }
    return out;
  }, [rows]);

  const byDay = {};
  for (const s of slots) (byDay[s.thu] = byDay[s.thu] || []).push(s);

  if (loading) return <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}><CircularProgress /></Box>;

  return (
    <Box>
      <Card sx={{ mb: 2.5 }}>
        <CardContent>
          <Typography variant="h6" sx={{ mb: 1 }}>📅 Thời khóa biểu giảng viên</Typography>
          <Chip size="small" color="primary" label={`${rows.length} lớp học phần · ${slots.length} ca dạy`} />
        </CardContent>
      </Card>

      <Grid container spacing={1} sx={{ mb: 2.5 }}>
        {[2, 3, 4, 5, 6, 7, 8].map((d) => (
          <Grid item xs={6} sm={4} md={12 / 7} key={d} sx={{ minWidth: 115 }}>
            <Box sx={{ border: '1px solid #e5e7eb', borderRadius: 1.5, overflow: 'hidden', minHeight: 140, bgcolor: '#fff' }}>
              <Typography sx={{ bgcolor: TEAL, color: '#fff', fontFamily: 'Montserrat', fontWeight: 700, fontSize: 12.5, textAlign: 'center', py: 0.75, textTransform: 'uppercase' }}>
                {thuName(d)}
              </Typography>
              {(byDay[d] || []).sort((a, b) => a.batDau - b.batDau).map((s, i) => (
                <Box key={i} sx={{ p: 0.75, borderBottom: '1px dashed #f0f0f0' }}>
                  <Typography sx={{ fontWeight: 700, fontSize: 11.5, color: TEAL_DARKER }}>{s.lop.TenMonHoc}</Typography>
                  <Typography variant="caption" color="text.secondary" display="block">Tiết {s.batDau}–{s.ketThuc}</Typography>
                  <Typography variant="caption" sx={{ color: 'text.disabled' }}>{s.lop.MaLHP}</Typography>
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
          <Typography variant="h6" sx={{ mb: 1.5 }}>Chi tiết ca dạy</Typography>
          <TableContainer>
            <Table size="small">
              <TableHead>
                <TableRow><TableCell>Mã LHP</TableCell><TableCell>Môn học</TableCell><TableCell>Học kỳ</TableCell>
                <TableCell align="center">Thứ</TableCell><TableCell align="center">Tiết</TableCell><TableCell align="center">Sĩ số</TableCell></TableRow>
              </TableHead>
              <TableBody>
                {slots.sort((a, b) => a.thu - b.thu || a.batDau - b.batDau).map((s, i) => (
                  <TableRow key={i} hover>
                    <TableCell><code>{s.lop.MaLHP}</code></TableCell>
                    <TableCell>{s.lop.TenMonHoc}</TableCell>
                    <TableCell>{s.lop.TenHocKy} {s.lop.NamHoc}</TableCell>
                    <TableCell align="center">{thuName(s.thu)}</TableCell>
                    <TableCell align="center">{s.batDau}–{s.ketThuc}</TableCell>
                    <TableCell align="center">{s.lop.SiSoHienTai}/{s.lop.SiSoToiDa}</TableCell>
                  </TableRow>
                ))}
                {!slots.length && <TableRow><TableCell colSpan={6} align="center" sx={{ py: 3, color: 'text.disabled' }}>Chưa có lịch dạy.</TableCell></TableRow>}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>
    </Box>
  );
}
