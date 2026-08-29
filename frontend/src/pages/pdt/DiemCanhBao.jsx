import { useCallback, useEffect, useState } from 'react';
import {
  Box, Grid, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Chip,
  CircularProgress, Alert, Button, Stack, Typography,
} from '@mui/material';
import RefreshIcon from '@mui/icons-material/Refresh';
import { toast } from 'react-toastify';
import api, { errMessage } from '../../api/client';
import { SectionCard, StatBox } from '../../components/SectionCard';

// ============================================================
// DIEM & CANH BAO HOC VU (PĐT) — SP_TinhCPA_TichLuy + thong ke
// ============================================================
const d = (v) => (v === null || v === undefined ? '—' : Number(v).toFixed(2));

export default function DiemCanhBao() {
  const [canhBao, setCanhBao] = useState([]);
  const [thongKe, setThongKe] = useState([]);
  const [loading, setLoading] = useState(true);

  const load = useCallback(() => {
    setLoading(true);
    Promise.all([
      api.get('/ketqua/canhbao-hocvu'),
      api.get('/ketqua/thongke-monhoc'),
    ])
      .then(([cb, tk]) => { setCanhBao(cb.data.canhBao || []); setThongKe(tk.data.thongKe || []); })
      .catch((e) => toast.error(errMessage(e)))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => { load(); }, [load]);

  const cap1 = canhBao.filter(c => c.TrangThaiCanhBaoHocVu.includes('Cấp 1')).length;
  const cap2 = canhBao.length - cap1;

  if (loading) return <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}><CircularProgress /></Box>;

  return (
    <Box>
      <SectionCard title="Cảnh báo học vụ (CPA < 1.60)"
        action={<Stack direction="row" spacing={1}><Chip color="error" size="small" label={`${canhBao.length} SV cảnh báo`} /><Button size="small" startIcon={<RefreshIcon />} onClick={load}>Tính lại</Button></Stack>}>
        <Alert severity="warning" sx={{ mb: 2 }}>
          Quy chế: CPA tích lũy &lt; 1.60 → <b>Cảnh báo Cấp 1</b>; &lt; 1.20 → <b>Cấp 2 (nguy cơ buộc thôi học)</b>.
          Hiện: {cap1} SV Cấp 1 · {cap2} SV Cấp 2.
        </Alert>
        <TableContainer>
          <Table size="small">
            <TableHead>
              <TableRow><TableCell>Mã SV</TableCell><TableCell>Họ tên</TableCell><TableCell>Lớp SH</TableCell>
              <TableCell align="center">TC tích lũy</TableCell><TableCell align="center">TC đạt</TableCell>
              <TableCell align="center">CPA (hệ 4)</TableCell><TableCell>Xếp loại</TableCell><TableCell>Cảnh báo</TableCell></TableRow>
            </TableHead>
            <TableBody>
              {canhBao.map((c) => (
                <TableRow key={c.MaSV} hover>
                  <TableCell><code>{c.MaSV}</code></TableCell>
                  <TableCell sx={{ fontWeight: 600 }}>{c.TenSinhVien}</TableCell>
                  <TableCell>{c.LopSinhHoat}</TableCell>
                  <TableCell align="center">{c.TongTinChiTichLuy}</TableCell>
                  <TableCell align="center">{c.TinChiDatPassed}</TableCell>
                  <TableCell align="center"><b style={{ color: '#c62828' }}>{d(c.CPA_TichLuy)}</b></TableCell>
                  <TableCell>{c.XepLoaiTichLuy}</TableCell>
                  <TableCell><Chip size="small" color={c.TrangThaiCanhBaoHocVu.includes('Cấp 2') ? 'error' : 'warning'} label={c.TrangThaiCanhBaoHocVu} /></TableCell>
                </TableRow>
              ))}
              {!canhBao.length && <TableRow><TableCell colSpan={8} align="center" sx={{ py: 3, color: 'success.main' }}>🎉 Không có sinh viên nào bị cảnh báo học vụ.</TableCell></TableRow>}
            </TableBody>
          </Table>
        </TableContainer>
      </SectionCard>

      <SectionCard title="Thống kê kết quả theo môn học (V_THONGKE_KETQUA_MONHOC)">
        <TableContainer>
          <Table size="small">
            <TableHead>
              <TableRow><TableCell>Mã LHP</TableCell><TableCell>Môn học</TableCell><TableCell>Học kỳ</TableCell>
              <TableCell align="center">Tổng SV</TableCell><TableCell align="center">Đạt</TableCell>
              <TableCell align="center">Không đạt (F)</TableCell><TableCell align="center">Chưa có điểm</TableCell>
              <TableCell align="center">Tỷ lệ đạt</TableCell></TableRow>
            </TableHead>
            <TableBody>
              {thongKe.map((t, i) => (
                <TableRow key={i} hover>
                  <TableCell><code>{t.MaLHP}</code></TableCell>
                  <TableCell>{t.TenMonHoc}</TableCell>
                  <TableCell>{t.TenHocKy}</TableCell>
                  <TableCell align="center">{t.TongSoSinhVien}</TableCell>
                  <TableCell align="center" sx={{ color: 'success.main', fontWeight: 600 }}>{t.SoSV_Dat}</TableCell>
                  <TableCell align="center" sx={{ color: Number(t.SoSV_KiemTraF) > 0 ? 'error.main' : undefined }}>{t.SoSV_KiemTraF}</TableCell>
                  <TableCell align="center">{t.SoSV_ChuaCoDiem}</TableCell>
                  <TableCell align="center">
                    <Chip size="small" color={Number(t.TyLeDat_Percent) >= 80 ? 'success' : Number(t.TyLeDat_Percent) >= 50 ? 'warning' : 'error'}
                      label={`${d(t.TyLeDat_Percent)}%`} />
                  </TableCell>
                </TableRow>
              ))}
              {!thongKe.length && <TableRow><TableCell colSpan={8} align="center" sx={{ py: 3, color: 'text.disabled' }}>Chưa có dữ liệu điểm.</TableCell></TableRow>}
            </TableBody>
          </Table>
        </TableContainer>
      </SectionCard>
    </Box>
  );
}
