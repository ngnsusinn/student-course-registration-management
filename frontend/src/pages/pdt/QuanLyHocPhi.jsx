import { useCallback, useEffect, useState } from 'react';
import {
  Box, Tabs, Tab, Grid, Stack, TextField, MenuItem, Button, Table, TableBody, TableCell,
  TableContainer, TableHead, TableRow, Dialog, DialogTitle, DialogContent, DialogActions,
  CircularProgress, Typography, Chip,
} from '@mui/material';
import PaymentsIcon from '@mui/icons-material/Payments';
import CalculateIcon from '@mui/icons-material/Calculate';
import { toast } from 'react-toastify';
import api, { errMessage } from '../../api/client';
import { SectionCard, StatBox } from '../../components/SectionCard';
import { StatusChip } from '../../components/StatusBadges';
import { fmtMoney } from '../../utils/format';

// ============================================================
// QUAN LY HOC PHI (PĐT) — danh sach + thu (SP_ThuHocPhi)
// + tinh (SP_TinhHocPhi) + bao cao tu view
// ============================================================
export default function QuanLyHocPhi() {
  const [tab, setTab] = useState(0);
  const [hocky, setHocky] = useState([]);
  const [rows, setRows] = useState([]);
  const [ky, setKy] = useState('');
  const [tt, setTt] = useState('');
  const [loading, setLoading] = useState(true);
  const [thuTarget, setThuTarget] = useState(null);
  const [soTien, setSoTien] = useState('');
  const [busy, setBusy] = useState(false);
  const [tinh, setTinh] = useState({ MaSV: '', MaHocKy: '', DonGiaTinChi: 580000 });
  const [baoCao, setBaoCao] = useState(null);

  useEffect(() => { api.get('/danhmuc/hocky').then(({ data }) => setHocky(data.hocKy || [])).catch(() => {}); }, []);

  const loadDs = useCallback(() => {
    setLoading(true);
    api.get('/hocphi/danhsach', { params: { MaHocKy: ky || undefined, TrangThai: tt || undefined } })
      .then(({ data }) => setRows(data.hocPhi || []))
      .catch((e) => toast.error(errMessage(e)))
      .finally(() => setLoading(false));
  }, [ky, tt]);

  useEffect(() => { if (tab === 0) loadDs(); }, [tab, loadDs]);
  useEffect(() => {
    if (tab === 2 && !baoCao) {
      setLoading(true);
      api.get('/hocphi/baocao').then(({ data }) => setBaoCao(data)).catch((e) => toast.error(errMessage(e))).finally(() => setLoading(false));
    }
  }, [tab]); // eslint-disable-line

  const runThu = async () => {
    setBusy(true);
    try {
      const { data } = await api.post('/hocphi/thu', { MaHocPhi: thuTarget.MaHocPhi, SoTien: Number(soTien) });
      toast.success(`✅ ${data.message}`);
      setThuTarget(null); setSoTien('');
      loadDs();
    } catch (e) {
      const code = e.response?.data?.ketQua;
      const MSG = { 301: 'Không tìm thấy phiếu học phí.', 302: 'Phiếu đã thanh toán hết.', 303: 'Số tiền nộp không hợp lệ.', 304: 'Số tiền nộp vượt quá số tiền còn nợ.' };
      toast.error(MSG[code] || errMessage(e));
    } finally { setBusy(false); }
  };

  const runTinh = async () => {
    setBusy(true);
    try {
      const { data } = await api.post('/hocphi/tinh', { ...tinh, DonGiaTinChi: Number(tinh.DonGiaTinChi) });
      toast.success(`✅ ${data.message} — ${tinh.MaSV} (kỳ ${tinh.MaHocKy})`);
    } catch (e) { toast.error(errMessage(e)); }
    finally { setBusy(false); }
  };

  const tongDs = rows.reduce((s, r) => ({ phi: s.phi + Number(r.TongTien || 0), nop: s.nop + Number(r.DaNop || 0), no: s.no + Number(r.ConNo || 0) }), { phi: 0, nop: 0, no: 0 });

  return (
    <Box>
      <SectionCard title="Tài chính — Học phí">
        <Tabs value={tab} onChange={(e, v) => setTab(v)} sx={{ mb: 2 }}>
          <Tab label="Danh sách học phí" />
          <Tab label="Tính học phí" />
          <Tab label="Báo cáo thu" />
        </Tabs>

        {tab === 0 && (<>
          <Stack direction="row" spacing={1.5} sx={{ mb: 2, flexWrap: 'wrap', useFlexGap: true }} alignItems="center">
            <TextField select size="small" label="Học kỳ" value={ky} onChange={(e) => setKy(e.target.value)} sx={{ minWidth: 200 }}>
              <MenuItem value="">Tất cả</MenuItem>
              {hocky.map(h => <MenuItem key={h.MaHocKy} value={h.MaHocKy}>{h.MaHocKy} — {h.TenHocKy}</MenuItem>)}
            </TextField>
            <TextField select size="small" label="Trạng thái" value={tt} onChange={(e) => setTt(e.target.value)} sx={{ minWidth: 180 }}>
              <MenuItem value="">Tất cả</MenuItem>
              <MenuItem value="CHUA_THANH_TOAN">Chưa thanh toán</MenuItem>
              <MenuItem value="DANG_XU_LY">Đang xử lý</MenuItem>
              <MenuItem value="DA_THANH_TOAN">Đã thanh toán</MenuItem>
              <MenuItem value="QUA_HAN">Quá hạn</MenuItem>
            </TextField>
            <Chip size="small" color="primary" label={`${rows.length} phiếu`} />
          </Stack>
          <Grid container spacing={1.5} sx={{ mb: 2 }}>
            <Grid item xs={4}><StatBox value={fmtMoney(tongDs.phi)} label="Tổng học phí (kết quả lọc)" /></Grid>
            <Grid item xs={4}><StatBox value={fmtMoney(tongDs.nop)} label="Đã thu" color="#2e7d32" /></Grid>
            <Grid item xs={4}><StatBox value={fmtMoney(tongDs.no)} label="Còn nợ" color="#c62828" /></Grid>
          </Grid>
          {loading ? <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}><CircularProgress /></Box> : (
            <TableContainer>
              <Table size="small">
                <TableHead><TableRow>
                  <TableCell>Mã phiếu</TableCell><TableCell>Mã SV</TableCell><TableCell>Họ tên</TableCell><TableCell>Lớp</TableCell>
                  <TableCell>Học kỳ</TableCell><TableCell align="center">TC</TableCell><TableCell align="right">Tổng tiền</TableCell>
                  <TableCell align="right">Đã nộp</TableCell><TableCell align="right">Còn nợ</TableCell><TableCell>Trạng thái</TableCell><TableCell align="right"></TableCell>
                </TableRow></TableHead>
                <TableBody>
                  {rows.map((r) => (
                    <TableRow key={r.MaHocPhi} hover>
                      <TableCell><code>{r.MaHocPhi}</code></TableCell>
                      <TableCell><code>{r.MaSV}</code></TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>{r.HoTen}</TableCell>
                      <TableCell>{r.MaLopSH}</TableCell>
                      <TableCell>{r.MaHocKy}</TableCell>
                      <TableCell align="center">{r.SoTinChi}</TableCell>
                      <TableCell align="right">{fmtMoney(r.TongTien)}</TableCell>
                      <TableCell align="right">{fmtMoney(r.DaNop)}</TableCell>
                      <TableCell align="right" sx={{ fontWeight: 600, color: Number(r.ConNo) > 0 ? 'error.main' : 'success.main' }}>{fmtMoney(r.ConNo)}</TableCell>
                      <TableCell><StatusChip group="HOCPHI" code={r.TrangThai} /></TableCell>
                      <TableCell align="right">
                        {Number(r.ConNo) > 0 && (
                          <Button size="small" variant="contained" startIcon={<PaymentsIcon />} onClick={() => { setThuTarget(r); setSoTien(String(r.ConNo)); }}>Thu</Button>
                        )}
                      </TableCell>
                    </TableRow>
                  ))}
                  {!rows.length && <TableRow><TableCell colSpan={11} align="center" sx={{ py: 3, color: 'text.disabled' }}>Không có phiếu nào.</TableCell></TableRow>}
                </TableBody>
              </Table>
            </TableContainer>
          )}
        </>)}

        {tab === 1 && (
          <Box sx={{ maxWidth: 460 }}>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
              <b>SP_TinhHocPhi</b>: học phí = Σ tín chỉ đã đăng ký trong kỳ × đơn giá. Phiếu tồn tại → cập nhật; chưa có → tạo mới.
            </Typography>
            <Stack spacing={2}>
              <TextField size="small" label="Mã sinh viên *" value={tinh.MaSV} onChange={(e) => setTinh({ ...tinh, MaSV: e.target.value })} placeholder="VD: sv001" />
              <TextField select size="small" label="Học kỳ *" value={tinh.MaHocKy} onChange={(e) => setTinh({ ...tinh, MaHocKy: e.target.value })}>
                {hocky.map(h => <MenuItem key={h.MaHocKy} value={h.MaHocKy}>{h.MaHocKy} — {h.TenHocKy}</MenuItem>)}
              </TextField>
              <TextField size="small" type="number" label="Đơn giá / tín chỉ (VNĐ) *" value={tinh.DonGiaTinChi} onChange={(e) => setTinh({ ...tinh, DonGiaTinChi: e.target.value })} />
              <Button variant="contained" startIcon={<CalculateIcon />} disabled={busy || !tinh.MaSV || !tinh.MaHocKy} onClick={runTinh}>
                {busy ? 'Đang tính...' : 'Tính học phí'}
              </Button>
            </Stack>
          </Box>
        )}

        {tab === 2 && (baoCao ? (
          <Grid container spacing={2.5}>
            <Grid item xs={12}>
              <Grid container spacing={1.5}>
                <Grid item xs={6} sm={3}><StatBox value={fmtMoney(baoCao.tongHop.TongHocPhi)} label="Tổng học phí" /></Grid>
                <Grid item xs={6} sm={3}><StatBox value={fmtMoney(baoCao.tongHop.TongDaThu)} label="Đã thu" color="#2e7d32" /></Grid>
                <Grid item xs={6} sm={3}><StatBox value={fmtMoney(baoCao.tongHop.TongConNo)} label="Còn nợ" color="#c62828" /></Grid>
                <Grid item xs={6} sm={3}><StatBox value={`${baoCao.tongHop.DaThanhToan}/${baoCao.tongHop.TongPhieu}`} label="Phiếu đã thanh toán" /></Grid>
              </Grid>
            </Grid>
            <Grid item xs={12} md={6}>
              <Typography variant="subtitle2" sx={{ fontFamily: 'Montserrat', mb: 1 }}>Theo học kỳ (VW_TongThuTheoHocKy)</Typography>
              <TableContainer><Table size="small">
                <TableHead><TableRow><TableCell>Kỳ</TableCell><TableCell align="center">SV</TableCell><TableCell align="right">Học phí</TableCell><TableCell align="right">Đã thu</TableCell><TableCell align="right">Còn nợ</TableCell></TableRow></TableHead>
                <TableBody>{baoCao.theoHocKy.map(r => (
                  <TableRow key={r.MaHocKy}><TableCell><code>{r.MaHocKy}</code></TableCell><TableCell align="center">{r.SoLuongSinhVien}</TableCell>
                  <TableCell align="right">{fmtMoney(r.TongHocPhi)}</TableCell><TableCell align="right">{fmtMoney(r.TongDaThu)}</TableCell><TableCell align="right">{fmtMoney(r.TongConNo)}</TableCell></TableRow>
                ))}</TableBody>
              </Table></TableContainer>
            </Grid>
            <Grid item xs={12} md={6}>
              <Typography variant="subtitle2" sx={{ fontFamily: 'Montserrat', mb: 1 }}>Theo ngành (VW_TongThuTheoNganh)</Typography>
              <TableContainer><Table size="small">
                <TableHead><TableRow><TableCell>Ngành</TableCell><TableCell align="center">SV</TableCell><TableCell align="right">Học phí</TableCell><TableCell align="right">Đã thu</TableCell><TableCell align="right">Còn nợ</TableCell></TableRow></TableHead>
                <TableBody>{baoCao.theoNganh.map(r => (
                  <TableRow key={r.MaNganh}><TableCell>{r.TenNganh}</TableCell><TableCell align="center">{r.SoLuongSinhVien}</TableCell>
                  <TableCell align="right">{fmtMoney(r.TongHocPhi)}</TableCell><TableCell align="right">{fmtMoney(r.TongDaThu)}</TableCell><TableCell align="right">{fmtMoney(r.TongConNo)}</TableCell></TableRow>
                ))}</TableBody>
              </Table></TableContainer>
            </Grid>
            <Grid item xs={12}>
              <Typography variant="subtitle2" sx={{ fontFamily: 'Montserrat', mb: 1 }}>Top sinh viên nợ học phí (VW_SinhVienNoHocPhi)</Typography>
              <TableContainer><Table size="small">
                <TableHead><TableRow><TableCell>Mã SV</TableCell><TableCell>Họ tên</TableCell><TableCell>Kỳ</TableCell><TableCell align="center">TC</TableCell><TableCell align="right">Tổng tiền</TableCell><TableCell align="right">Đã nộp</TableCell><TableCell align="right">Còn nợ</TableCell></TableRow></TableHead>
                <TableBody>{baoCao.conNo.slice(0, 20).map(r => (
                  <TableRow key={r.MaHocPhi} hover><TableCell><code>{r.MaSV}</code></TableCell><TableCell>{r.HoTen}</TableCell><TableCell>{r.MaHocKy}</TableCell>
                  <TableCell align="center">{r.SoTinChi}</TableCell><TableCell align="right">{fmtMoney(r.TongTien)}</TableCell><TableCell align="right">{fmtMoney(r.DaNop)}</TableCell>
                  <TableCell align="right" sx={{ color: 'error.main', fontWeight: 700 }}>{fmtMoney(r.SoTienConNo)}</TableCell></TableRow>
                ))}</TableBody>
              </Table></TableContainer>
            </Grid>
          </Grid>
        ) : <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}><CircularProgress /></Box>)}
      </SectionCard>

      <Dialog open={!!thuTarget} onClose={() => setThuTarget(null)} maxWidth="xs" fullWidth>
        <DialogTitle sx={{ fontFamily: 'Montserrat', fontWeight: 700 }}>💰 Thu học phí — {thuTarget?.HoTen}</DialogTitle>
        <DialogContent dividers>
          <Typography variant="body2" sx={{ mb: 1.5 }}>
            Phiếu <code>{thuTarget?.MaHocPhi}</code> · Kỳ {thuTarget?.MaHocKy} · Tổng {fmtMoney(thuTarget?.TongTien)} ·
            Đã nộp {fmtMoney(thuTarget?.DaNop)} · <b>Còn nợ {fmtMoney(thuTarget?.ConNo)}</b>
          </Typography>
          <TextField fullWidth size="small" type="number" label="Số tiền thu (VNĐ) *" value={soTien} onChange={(e) => setSoTien(e.target.value)} />
          <Typography variant="caption" color="text.secondary">SP_ThuHocPhi chạy trong transaction — cộng DaNop, tự chuyển DA_THANH_TOAN khi nộp đủ.</Typography>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => setThuTarget(null)}>Hủy</Button>
          <Button variant="contained" disabled={busy || !Number(soTien)} onClick={runThu}>{busy ? 'Đang thu...' : 'Xác nhận thu'}</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
