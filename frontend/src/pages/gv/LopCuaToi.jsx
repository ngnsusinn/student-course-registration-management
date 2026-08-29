import { useEffect, useState } from 'react';
import {
  Box, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Button,
  Dialog, DialogTitle, DialogContent, DialogActions, Typography, Grid, Chip,
  CircularProgress, Stack,
} from '@mui/material';
import { toast } from 'react-toastify';
import api, { errMessage } from '../../api/client';
import { SectionCard, StatBox } from '../../components/SectionCard';
import { SiSoChip, StatusChip } from '../../components/StatusBadges';
import { thuName } from '../../utils/format';

// ============================================================
// LOP CUA TOI (GV) — danh sach LHP phu trach + xem SV/thong ke
// ============================================================
function renderLich(str) {
  if (!str) return '—';
  return String(str).split('; ').map((p) => {
    const m = p.match(/^(\d+):(\d+)-(\d+)/);
    return m ? `${thuName(Number(m[1]))} tiết ${m[2]}–${m[3]}` : p;
  }).join('; ');
}

const d = (v) => (v === null || v === undefined ? '—' : Number(v).toFixed(2));

export default function LopCuaToi() {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [xem, setXem] = useState(null); // {lop, sv, thongKe}
  const [busyXem, setBusyXem] = useState(false);

  useEffect(() => {
    api.get('/giangvien/lopcuatoi')
      .then(({ data }) => setRows(data.lop || []))
      .catch((e) => toast.error(errMessage(e)))
      .finally(() => setLoading(false));
  }, []);

  const moXem = async (lop) => {
    setBusyXem(true);
    setXem({ lop, sv: [], thongKe: null });
    try {
      const [sv, tk] = await Promise.all([
        api.get(`/giangvien/sinhvien/${lop.MaLHP}`),
        api.get('/ketqua/thongke-monhoc', { params: { MaLHP: lop.MaLHP } }).catch(() => null),
      ]);
      setXem({ lop, sv: sv.data.sinhVien || [], thongKe: tk?.data?.thongKe?.[0] || null });
    } catch (e) {
      toast.error(errMessage(e));
      setXem(null);
    } finally {
      setBusyXem(false);
    }
  };

  if (loading) return <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}><CircularProgress /></Box>;

  return (
    <Box>
      <SectionCard title="Lớp học phần của tôi" action={<Chip size="small" color="primary" label={`${rows.length} lớp`} />}>
        <TableContainer>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Mã LHP</TableCell><TableCell>Tên lớp HP</TableCell><TableCell>Môn học</TableCell>
                <TableCell align="center">TC</TableCell><TableCell>Học kỳ</TableCell><TableCell>Lịch học</TableCell>
                <TableCell align="center">Sĩ số</TableCell><TableCell>Trạng thái</TableCell><TableCell align="right">Thao tác</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {rows.map((r) => (
                <TableRow key={r.MaLHP} hover>
                  <TableCell><code>{r.MaLHP}</code></TableCell>
                  <TableCell>{r.TenLHP}</TableCell>
                  <TableCell>{r.TenMonHoc}</TableCell>
                  <TableCell align="center">{r.SoTinChi}</TableCell>
                  <TableCell>{r.TenHocKy} {r.NamHoc}</TableCell>
                  <TableCell sx={{ fontSize: 12.5 }}>{renderLich(r.LichHoc)}</TableCell>
                  <TableCell align="center"><SiSoChip hienTai={r.SiSoHienTai} toiDa={r.SiSoToiDa} /></TableCell>
                  <TableCell><StatusChip group="LOP" code={r.TrangThaiLop} /></TableCell>
                  <TableCell align="right">
                    <Button size="small" variant="outlined" onClick={() => moXem(r)}>Xem sinh viên</Button>
                  </TableCell>
                </TableRow>
              ))}
              {!rows.length && <TableRow><TableCell colSpan={9} align="center" sx={{ py: 3, color: 'text.disabled' }}>Bạn chưa được phân công lớp học phần nào.</TableCell></TableRow>}
            </TableBody>
          </Table>
        </TableContainer>
      </SectionCard>

      <Dialog open={!!xem} onClose={() => setXem(null)} maxWidth="lg" fullWidth>
        <DialogTitle sx={{ fontFamily: 'Montserrat', fontWeight: 700, color: 'primary.dark' }}>
          {xem ? `${xem.lop.MaLHP} — ${xem.lop.TenMonHoc}` : ''}
        </DialogTitle>
        <DialogContent dividers>
          {busyXem ? <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}><CircularProgress /></Box> : xem && (
            <>
              {xem.thongKe && (
                <Grid container spacing={1.5} sx={{ mb: 2 }}>
                  <Grid item xs={4} sm={2}><StatBox value={xem.thongKe.TongSoSinhVien} label="SV trong lớp" /></Grid>
                  <Grid item xs={4} sm={2}><StatBox value={xem.thongKe.SoSV_Dat} label="Đạt" color="#2e7d32" /></Grid>
                  <Grid item xs={4} sm={2}><StatBox value={xem.thongKe.SoSV_KiemTraF} label="Không đạt (F)" color="#c62828" /></Grid>
                  <Grid item xs={4} sm={2}><StatBox value={xem.thongKe.SoSV_ChuaCoDiem} label="Chưa có điểm" color="#ed6c02" /></Grid>
                  <Grid item xs={4} sm={2}><StatBox value={`${d(xem.thongKe.TyLeDat_Percent)}%`} label="Tỷ lệ đạt" /></Grid>
                </Grid>
              )}
              <TableContainer>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Mã SV</TableCell><TableCell>Họ tên</TableCell><TableCell>Lớp SH</TableCell>
                      <TableCell align="center">CC</TableCell><TableCell align="center">GK</TableCell><TableCell align="center">CK</TableCell>
                      <TableCell align="center"><b>TK</b></TableCell><TableCell align="center">Chữ</TableCell><TableCell align="center">Hệ 4</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {xem.sv.map((s) => (
                      <TableRow key={s.MaSV} hover>
                        <TableCell><code>{s.MaSV}</code></TableCell>
                        <TableCell>{s.HoTen}</TableCell>
                        <TableCell>{s.MaLopSH}</TableCell>
                        <TableCell align="center">{d(s.DiemChuyenCan)}</TableCell>
                        <TableCell align="center">{d(s.DiemGiuaKy)}</TableCell>
                        <TableCell align="center">{d(s.DiemCuoiKy)}</TableCell>
                        <TableCell align="center"><b>{d(s.DiemTongKet)}</b></TableCell>
                        <TableCell align="center">{s.DiemChu || '—'}</TableCell>
                        <TableCell align="center">{d(s.DiemHe4)}</TableCell>
                      </TableRow>
                    ))}
                    {!xem.sv.length && <TableRow><TableCell colSpan={9} align="center" sx={{ py: 3, color: 'text.disabled' }}>Lớp chưa có sinh viên đăng ký.</TableCell></TableRow>}
                  </TableBody>
                </Table>
              </TableContainer>
            </>
          )}
        </DialogContent>
        <DialogActions>
          <Stack direction="row" spacing={1} sx={{ mr: 'auto', px: 2 }}>
            {xem && <Chip size="small" label={`Sĩ số ${xem.lop.SiSoHienTai}/${xem.lop.SiSoToiDa}`} />}
          </Stack>
          <Button onClick={() => setXem(null)}>Đóng</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
