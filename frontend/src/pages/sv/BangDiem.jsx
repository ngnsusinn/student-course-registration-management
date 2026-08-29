import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Box, Grid, Table, TableBody, TableCell, TableContainer, TableHead, TableRow,
  TextField, MenuItem, Alert, Chip, Typography, CircularProgress,
} from '@mui/material';
import { toast } from 'react-toastify';
import api, { errMessage } from '../../api/client';
import { SectionCard, StatBox } from '../../components/SectionCard';

// ============================================================
// BANG DIEM — GPA hoc ky / CPA tich luy / bang diem / thang chu
// ============================================================
const d = (v) => (v === null || v === undefined ? '—' : Number(v).toFixed(2));

export default function BangDiem() {
  const [bangDiem, setBangDiem] = useState([]);
  const [maHocKy, setMaHocKy] = useState('');
  const [gpa, setGpa] = useState(null);
  const [cpa, setCpa] = useState(null);
  const [thang, setThang] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get('/ketqua/bangdiem')
      .then(({ data }) => {
        const rows = data.bangDiem || [];
        setBangDiem(rows);
        const ky = [...new Set(rows.map(r => r.MaHocKy))];
        setMaHocKy(ky[0] || '');
      })
      .catch((e) => toast.error(errMessage(e)))
      .finally(() => setLoading(false));
    api.get('/ketqua/thangdiemchu').then(({ data }) => setThang(data.thangDiem || [])).catch(() => {});
    api.get('/ketqua/cpa').then(({ data }) => setCpa(data.cpa)).catch(() => {});
  }, []);

  const loadGpa = useCallback(() => {
    if (!maHocKy) { setGpa(null); return; }
    api.get('/ketqua/gpa', { params: { MaHocKy: maHocKy } })
      .then(({ data }) => setGpa(data.gpa))
      .catch(() => setGpa(null));
  }, [maHocKy]);
  useEffect(() => { loadGpa(); }, [loadGpa]);

  const rowsKy = useMemo(() => bangDiem.filter(r => r.MaHocKy === maHocKy), [bangDiem, maHocKy]);
  const cacKy = useMemo(() => {
    const map = new Map();
    bangDiem.forEach(r => map.set(r.MaHocKy, r.TenHocKy));
    return [...map.entries()].sort((a, b) => b[0] - a[0]);
  }, [bangDiem]);

  if (loading) return <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}><CircularProgress /></Box>;

  return (
    <Box>
      <SectionCard title="Kết quả học tập"
        action={
          <TextField select size="small" label="Học kỳ" value={maHocKy} onChange={(e) => setMaHocKy(e.target.value)} sx={{ minWidth: 200 }}>
            {cacKy.map(([k, v]) => <MenuItem key={k} value={k}>{v}</MenuItem>)}
          </TextField>
        }>
        <Grid container spacing={1.5}>
          <Grid item xs={6} sm={3}><StatBox value={gpa ? d(gpa.GPA_HocKy) : '—'} label={`GPA học kỳ (hệ 4)${gpa?.TongTinChiHocKy ? ` · ${gpa.TongTinChiHocKy} TC` : ''}`} /></Grid>
          <Grid item xs={6} sm={3}><StatBox value={gpa?.XepLoaiHocKy || '—'} label="Xếp loại học kỳ" /></Grid>
          <Grid item xs={6} sm={3}><StatBox value={cpa ? d(cpa.CPA_TichLuy) : '—'} label={`CPA tích lũy${cpa ? ` · ${cpa.TongTinChiTichLuy} TC (${cpa.TinChiDatPassed} đạt)` : ''}`} /></Grid>
          <Grid item xs={6} sm={3}><StatBox value={cpa?.XepLoaiTichLuy || '—'} label="Xếp loại tích lũy" /></Grid>
        </Grid>
        {cpa?.TrangThaiCanhBaoHocVu && cpa.TrangThaiCanhBaoHocVu !== 'Bình thường' && (
          <Alert severity="warning" sx={{ mt: 2 }}>⚠️ {cpa.TrangThaiCanhBaoHocVu} — liên hệ cố vấn học tập để được hỗ trợ.</Alert>
        )}
      </SectionCard>

      <SectionCard title={`Bảng điểm học tập — ${cacKy.find(([k]) => k === maHocKy)?.[1] || ''}`}>
        <TableContainer>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell align="center">STT</TableCell><TableCell>Mã LHP</TableCell><TableCell>Môn học</TableCell>
                <TableCell align="center">Số TC</TableCell><TableCell align="center">Điểm CC</TableCell>
                <TableCell align="center">Điểm GK</TableCell><TableCell align="center">Điểm CK</TableCell>
                <TableCell align="center"><b>Điểm TK</b></TableCell><TableCell align="center">Chữ</TableCell>
                <TableCell align="center">Hệ 4</TableCell><TableCell>Xếp loại</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {rowsKy.map((r, i) => (
                <TableRow key={i} hover>
                  <TableCell align="center">{i + 1}</TableCell>
                  <TableCell><code>{r.MaLHP}</code></TableCell>
                  <TableCell>{r.TenMonHoc}</TableCell>
                  <TableCell align="center">{r.SoTinChi}</TableCell>
                  <TableCell align="center">{d(r.DiemChuyenCan)}</TableCell>
                  <TableCell align="center">{d(r.DiemGiuaKy)}</TableCell>
                  <TableCell align="center">{d(r.DiemCuoiKy)}</TableCell>
                  <TableCell align="center"><b>{d(r.DiemTongKet)}</b></TableCell>
                  <TableCell align="center"><Chip size="small" label={r.DiemChu || '—'} color={r.DiemChu === 'F' ? 'error' : 'success'} variant="outlined" /></TableCell>
                  <TableCell align="center">{d(r.DiemHe4)}</TableCell>
                  <TableCell>{r.XepLoaiMonHoc || '—'}</TableCell>
                </TableRow>
              ))}
              {!rowsKy.length && <TableRow><TableCell colSpan={11} align="center" sx={{ py: 3, color: 'text.disabled' }}>Học kỳ này chưa có kết quả.</TableCell></TableRow>}
            </TableBody>
          </Table>
        </TableContainer>
        <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
          Điểm tổng kết = 10% CC + 20% GK + 70% CK (Trigger tự tính, quy đổi hệ 4 theo bảng điểm chữ).
        </Typography>
      </SectionCard>

      <SectionCard title="Thang điểm chữ">
        <TableContainer>
          <Table size="small" sx={{ maxWidth: 640 }}>
            <TableHead>
              <TableRow><TableCell align="center">Điểm chữ</TableCell><TableCell align="center">Từ (hệ 10)</TableCell>
              <TableCell align="center">Đến (hệ 10)</TableCell><TableCell align="center">Điểm hệ 4</TableCell><TableCell>Xếp loại</TableCell></TableRow>
            </TableHead>
            <TableBody>
              {thang.map((t) => (
                <TableRow key={t.DiemChu}>
                  <TableCell align="center"><b>{t.DiemChu}</b></TableCell>
                  <TableCell align="center">{Number(t.TuDiemHe10).toFixed(1)}</TableCell>
                  <TableCell align="center">{Number(t.DenDiemHe10).toFixed(1)}</TableCell>
                  <TableCell align="center">{Number(t.DiemHe4).toFixed(2)}</TableCell>
                  <TableCell>{t.XepLoai}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      </SectionCard>
    </Box>
  );
}
