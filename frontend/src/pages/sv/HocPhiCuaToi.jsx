import { useEffect, useMemo, useState } from 'react';
import {
  Box, Grid, Alert, Table, TableBody, TableCell, TableContainer, TableHead, TableRow,
  Typography, CircularProgress,
} from '@mui/material';
import { toast } from 'react-toastify';
import api, { errMessage } from '../../api/client';
import { SectionCard, StatBox } from '../../components/SectionCard';
import { StatusChip } from '../../components/StatusBadges';
import { fmtMoney } from '../../utils/format';

// ============================================================
// HOC PHI CUA TOI — danh sach phieu hoc phi theo ky
// ============================================================
export default function HocPhiCuaToi() {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get('/hocphi/cua-toi')
      .then(({ data }) => setRows(data.hocPhi || []))
      .catch((e) => toast.error(errMessage(e)))
      .finally(() => setLoading(false));
  }, []);

  const tong = useMemo(() => rows.reduce((s, r) => ({
    phi: s.phi + Number(r.TongTien || 0),
    nop: s.nop + Number(r.DaNop || 0),
    no: s.no + Number(r.ConNo || 0),
  }), { phi: 0, nop: 0, no: 0 }), [rows]);

  if (loading) return <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}><CircularProgress /></Box>;

  return (
    <Box>
      <SectionCard title="Tổng quan học phí">
        <Grid container spacing={1.5}>
          <Grid item xs={12} sm={4}><StatBox value={fmtMoney(tong.phi)} label="Tổng học phí các kỳ" /></Grid>
          <Grid item xs={12} sm={4}><StatBox value={fmtMoney(tong.nop)} label="Đã nộp" color="#2e7d32" /></Grid>
          <Grid item xs={12} sm={4}><StatBox value={fmtMoney(tong.no)} label="Còn phải nộp" color={tong.no > 0 ? '#c62828' : '#2e7d32'} /></Grid>
        </Grid>
        {tong.no > 0 && (
          <Alert severity="warning" sx={{ mt: 2 }}>
            ⚠️ Vui lòng hoàn thành nghĩa vụ học phí tại Phòng Tài chính — Cơ sở vật chất. Nợ học phí sẽ bị <b>tạm dừng đăng ký</b> học kỳ sau.
          </Alert>
        )}
      </SectionCard>

      <SectionCard title="Chi tiết học phí theo học kỳ">
        <TableContainer>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Mã phiếu</TableCell><TableCell>Học kỳ</TableCell><TableCell align="center">Số TC</TableCell>
                <TableCell align="right">Đơn giá/TC</TableCell><TableCell align="right">Tổng học phí</TableCell>
                <TableCell align="right">Đã nộp</TableCell><TableCell align="right">Còn nợ</TableCell><TableCell>Trạng thái</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {rows.map((r) => (
                <TableRow key={r.MaHocPhi} hover>
                  <TableCell><code>{r.MaHocPhi}</code></TableCell>
                  <TableCell>{r.TenHocKy} — {r.NamHoc}</TableCell>
                  <TableCell align="center">{r.SoTinChi}</TableCell>
                  <TableCell align="right">{fmtMoney(r.DonGiaTinChi)}</TableCell>
                  <TableCell align="right"><b>{fmtMoney(r.TongTien)}</b></TableCell>
                  <TableCell align="right">{fmtMoney(r.DaNop)}</TableCell>
                  <TableCell align="right" sx={{ color: Number(r.ConNo) > 0 ? 'error.main' : 'success.main', fontWeight: 600 }}>
                    {fmtMoney(r.ConNo)}
                  </TableCell>
                  <TableCell><StatusChip group="HOCPHI" code={r.TrangThai} /></TableCell>
                </TableRow>
              ))}
              {!rows.length && <TableRow><TableCell colSpan={8} align="center" sx={{ py: 3, color: 'text.disabled' }}>Chưa có phiếu học phí.</TableCell></TableRow>}
            </TableBody>
          </Table>
        </TableContainer>
        <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
          Học phí = Số tín chỉ đã đăng ký × đơn giá tín chỉ (SP_TinhHocPhi). Trạng thái chuyển DA_THANH_TOAN tự động khi nộp đủ (Trigger).
        </Typography>
      </SectionCard>
    </Box>
  );
}
