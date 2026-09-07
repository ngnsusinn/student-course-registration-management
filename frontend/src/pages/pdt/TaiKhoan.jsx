import { useCallback, useEffect, useState } from 'react';
import {
  Box, Tabs, Tab, Stack, Table, TableBody, TableCell, TableContainer, TableHead,
  TableRow, Button, Dialog, DialogTitle, DialogContent, DialogActions, TextField,
  CircularProgress, Chip, Typography,
} from '@mui/material';
import LockIcon from '@mui/icons-material/Lock';
import LockOpenIcon from '@mui/icons-material/LockOpen';
import AddIcon from '@mui/icons-material/Add';
import { toast } from 'react-toastify';
import api, { errMessage } from '../../api/client';
import { SectionCard } from '../../components/SectionCard';
import ConfirmDialog from '../../components/ConfirmDialog';
import { fmtNgay } from '../../utils/format';

// ============================================================
// TAI KHOAN & PHAN QUYEN (PĐT) — khoa/mo, tao TK, nhat ky DMK
// ============================================================
export default function TaiKhoan() {
  const [tab, setTab] = useState(0);
  const [rows, setRows] = useState([]);
  const [nhatKy, setNhatKy] = useState([]);
  const [loading, setLoading] = useState(true);
  const [khoaTarget, setKhoaTarget] = useState(null);
  const [tao, setTao] = useState(null); // {loai:'SV'|'GV', ma:''}
  const [busy, setBusy] = useState(false);

  const load = useCallback(() => {
    setLoading(true);
    Promise.all([api.get('/admin/taikhoan'), api.get('/admin/nhatky-doimatkhau')])
      .then(([tk, nk]) => { setRows(tk.data.taiKhoan || []); setNhatKy(nk.data.nhatKy || []); })
      .catch((e) => toast.error(errMessage(e)))
      .finally(() => setLoading(false));
  }, []);
  useEffect(() => { load(); }, [load]);

  const doiTrangThai = async () => {
    setBusy(true);
    try {
      const moi = khoaTarget.TrangThai === 'ACTIVE' ? 'LOCKED' : 'ACTIVE';
      const { data } = await api.put('/admin/taikhoan/khoa', { MaTaiKhoan: khoaTarget.MaTaiKhoan, TrangThai: moi });
      toast.success(`✅ ${data.message} (${moi === 'LOCKED' ? 'đã khóa' : 'đã mở'})`);
      setKhoaTarget(null);
      load();
    } catch (e) { toast.error(errMessage(e)); }
    finally { setBusy(false); }
  };

  const runTao = async () => {
    setBusy(true);
    try {
      const url = tao.loai === 'SV' ? '/admin/taikhoan/sinhvien' : '/admin/taikhoan/giangvien';
      const body = tao.loai === 'SV' ? { MaSV: tao.ma } : { MaGV: tao.ma };
      const { data } = await api.post(url, body);
      toast.success(`✅ ${data.message} — đăng nhập: ${tao.ma}, mật khẩu mặc định: matkhau@123`);
      setTao(null);
      load();
    } catch (e) { toast.error(errMessage(e)); }
    finally { setBusy(false); }
  };

  if (loading) return <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}><CircularProgress /></Box>;

  return (
    <Box>
      <SectionCard title="Tài khoản & Phân quyền">
        <Tabs value={tab} onChange={(e, v) => setTab(v)} sx={{ mb: 2 }}>
          <Tab label={`Tài khoản (${rows.length})`} />
          <Tab label={`Nhật ký đổi mật khẩu (${nhatKy.length})`} />
        </Tabs>

        {tab === 0 && (<>
          <Stack direction="row" spacing={1} sx={{ mb: 1.5 }}>
            <Button size="small" variant="contained" startIcon={<AddIcon />} onClick={() => setTao({ loai: 'SV', ma: '' })}>Tạo TK sinh viên</Button>
            <Button size="small" variant="outlined" startIcon={<AddIcon />} onClick={() => setTao({ loai: 'GV', ma: '' })}>Tạo TK giảng viên</Button>
          </Stack>
          <TableContainer><Table size="small">
            <TableHead><TableRow>
              <TableCell>#</TableCell><TableCell>Tên đăng nhập</TableCell><TableCell>Email</TableCell>
              <TableCell>Vai trò</TableCell><TableCell>Gắn với</TableCell><TableCell>Trạng thái</TableCell><TableCell align="right">Thao tác</TableCell>
            </TableRow></TableHead>
            <TableBody>
              {rows.map((r) => (
                <TableRow key={r.MaTaiKhoan} hover>
                  <TableCell>{r.MaTaiKhoan}</TableCell>
                  <TableCell><code>{r.TenDangNhap}</code></TableCell>
                  <TableCell>{r.Email || '—'}</TableCell>
                  <TableCell><Chip size="small" color={r.MaVaiTro === 'PĐT' ? 'secondary' : 'primary'} variant="outlined" label={r.TenVaiTro} /></TableCell>
                  <TableCell>{r.MaSV || r.MaGV || '—'}</TableCell>
                  <TableCell><Chip size="small" color={r.TrangThai === 'ACTIVE' ? 'success' : 'error'} label={r.TrangThai === 'ACTIVE' ? 'Hoạt động' : 'Đã khóa'} /></TableCell>
                  <TableCell align="right">
                    <Button size="small" color={r.TrangThai === 'ACTIVE' ? 'error' : 'success'} variant="outlined"
                      startIcon={r.TrangThai === 'ACTIVE' ? <LockIcon /> : <LockOpenIcon />}
                      onClick={() => setKhoaTarget(r)}>
                      {r.TrangThai === 'ACTIVE' ? 'Khóa' : 'Mở khóa'}
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table></TableContainer>
        </>)}

        {tab === 1 && (
          <TableContainer><Table size="small">
            <TableHead><TableRow><TableCell>#</TableCell><TableCell>Tài khoản</TableCell><TableCell>Thời gian thay đổi</TableCell><TableCell>Địa chỉ IP</TableCell><TableCell>Ghi chú</TableCell></TableRow></TableHead>
            <TableBody>
              {nhatKy.map((n) => (
                <TableRow key={n.MaNhatKy} hover>
                  <TableCell>{n.MaNhatKy}</TableCell>
                  <TableCell><code>{n.TenDangNhap}</code></TableCell>
                  <TableCell>{fmtNgay(n.ThoiGianThayDoi)} {new Date(n.ThoiGianThayDoi).toLocaleTimeString('vi-VN', { hour12: false })}</TableCell>
                  <TableCell>{n.DiaChiIP || '—'}</TableCell>
                  <TableCell sx={{ fontSize: 12.5 }}>{n.GhiChu || '—'}</TableCell>
                </TableRow>
              ))}
              {!nhatKy.length && <TableRow><TableCell colSpan={5} align="center" sx={{ py: 3, color: 'text.disabled' }}>Chưa có bản ghi nào.</TableCell></TableRow>}
            </TableBody>
          </Table></TableContainer>
        )}
        <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
          Nhật ký được ghi tự động bởi trigger TRG_LogDoiMatKhau mỗi lần người dùng đổi mật khẩu.
        </Typography>
      </SectionCard>

      <ConfirmDialog open={!!khoaTarget}
        title={khoaTarget?.TrangThai === 'ACTIVE' ? 'Khóa tài khoản' : 'Mở khóa tài khoản'}
        text={khoaTarget?.TrangThai === 'ACTIVE'
          ? `Khóa ${khoaTarget.TenDangNhap}? Người dùng sẽ không thể đăng nhập.`
          : `Mở khóa lại tài khoản ${khoaTarget?.TenDangNhap}?`}
        confirmText={khoaTarget?.TrangThai === 'ACTIVE' ? 'Khóa' : 'Mở khóa'}
        danger={khoaTarget?.TrangThai === 'ACTIVE'}
        busy={busy} onConfirm={doiTrangThai} onClose={() => setKhoaTarget(null)} />

      <Dialog open={!!tao} onClose={() => setTao(null)} maxWidth="xs" fullWidth>
        <DialogTitle sx={{ fontFamily: 'Montserrat', fontWeight: 700 }}>Tạo tài khoản {tao?.loai === 'SV' ? 'sinh viên' : 'giảng viên'}</DialogTitle>
        <DialogContent dividers>
          <Stack spacing={2} sx={{ mt: 0.5 }}>
            <TextField size="small" label={tao?.loai === 'SV' ? 'Mã sinh viên *' : 'Mã giảng viên *'} value={tao?.ma || ''}
              onChange={(e) => setTao((p) => ({ ...p, ma: e.target.value }))} placeholder={tao?.loai === 'SV' ? 'sv061' : 'gv016'} autoFocus />
            <Typography variant="caption" color="text.secondary">SP_TaoTaiKhoan{tao?.loai === 'SV' ? 'SinhVien' : 'GiangVien'} tạo đăng nhập = mã, mật khẩu mặc định matkhau@123.</Typography>
          </Stack>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => setTao(null)}>Hủy</Button>
          <Button variant="contained" disabled={busy || !tao?.ma} onClick={runTao}>{busy ? 'Đang tạo...' : 'Tạo tài khoản'}</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
