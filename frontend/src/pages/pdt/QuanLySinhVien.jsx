import { useCallback, useEffect, useState } from 'react';
import {
  Box, Stack, TextField, MenuItem, Button, Table, TableBody, TableCell, TableContainer,
  TableHead, TableRow, Chip, Dialog, DialogTitle, DialogContent, DialogActions,
  CircularProgress, Typography, InputAdornment,
} from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';
import AddIcon from '@mui/icons-material/Add';
import FileDownloadIcon from '@mui/icons-material/FileDownload';
import { toast } from 'react-toastify';
import api, { errMessage } from '../../api/client';
import { SectionCard } from '../../components/SectionCard';
import ConfirmDialog from '../../components/ConfirmDialog';
import { fmtNgay } from '../../utils/format';
import { xuatExcel } from '../../utils/export';

// ============================================================
// QUAN LY SINH VIEN (PĐT) — tim/loc + them/sua/xoa/chuyen lop
// ============================================================
const TT_HOC = { 1: ['success', 'Đang học'], 2: ['warning', 'Bảo lưu'], 3: ['error', 'Thôi học'] };
const EMPTY = { MaSV: '', HoTen: '', NgaySinh: '', GioiTinh: 1, Email: '', SoDienThoai: '', MaLopSH: '', QueQuan: '' };

export default function QuanLySinhVien() {
  const [rows, setRows] = useState([]);
  const [lops, setLops] = useState([]);
  const [tim, setTim] = useState('');
  const [lop, setLop] = useState('');
  const [loading, setLoading] = useState(true);
  const [form, setForm] = useState(null); // null | {...} (them/sua)
  const [mode, setMode] = useState('add');
  const [xoa, setXoa] = useState(null);
  const [busy, setBusy] = useState(false);

  const load = useCallback(() => {
    setLoading(true);
    api.get('/danhmuc/sinhvien', { params: { tim: tim || undefined, MaLopSH: lop || undefined } })
      .then(({ data }) => setRows(data.sinhVien || []))
      .catch((e) => toast.error(errMessage(e)))
      .finally(() => setLoading(false));
  }, [tim, lop]);

  useEffect(() => { load(); }, [load]);
  useEffect(() => { api.get('/danhmuc/lop').then(({ data }) => setLops(data.lop || [])).catch(() => {}); }, []);

  const submit = async () => {
    setBusy(true);
    try {
      if (mode === 'add') {
        const { data } = await api.post('/admin/themsinhvien', form);
        toast.success(`✅ ${data.message}`);
      } else {
        const { data } = await api.put(`/danhmuc/sinhvien/${form.MaSV}`, form);
        toast.success(`✅ ${data.message}`);
      }
      setForm(null);
      load();
    } catch (e) {
      toast.error(errMessage(e, 'Thao tác thất bại.'));
    } finally {
      setBusy(false);
    }
  };

  const submitXoa = async () => {
    setBusy(true);
    try {
      const { data } = await api.delete(`/danhmuc/sinhvien/${xoa.MaSV}`);
      toast.success(`✅ ${data.message}`);
      setXoa(null);
      load();
    } catch (e) {
      toast.error(errMessage(e));
    } finally {
      setBusy(false);
    }
  };

  const set = (k) => (e) => setForm((p) => ({ ...p, [k]: e.target.value }));

  return (
    <Box>
      <SectionCard title="Quản lý sinh viên"
        action={
          <Stack direction="row" spacing={1}>
            <Button size="small" variant="outlined" startIcon={<FileDownloadIcon />}
              onClick={() => xuatExcel('Danh-sach-sinh-vien', [
                { header: 'Mã SV', key: 'MaSV' }, { header: 'Họ và tên', key: 'HoTen' },
                { header: 'Ngày sinh', value: (r) => fmtNgay(r.NgaySinh) },
                { header: 'Giới tính', value: (r) => (Number(r.GioiTinh) === 1 ? 'Nam' : 'Nữ') },
                { header: 'Email', key: 'Email' }, { header: 'Số điện thoại', key: 'SoDienThoai' },
                { header: 'Lớp SH', key: 'MaLopSH' }, { header: 'Trạng thái', key: 'TrangThaiHoc' },
              ], rows)}>Xuất Excel</Button>
            <Button size="small" variant="contained" startIcon={<AddIcon />} onClick={() => { setMode('add'); setForm({ ...EMPTY }); }}>Thêm sinh viên</Button>
          </Stack>
        }>
        <Stack direction="row" spacing={1.5} sx={{ mb: 2, flexWrap: 'wrap', useFlexGap: true }}>
          <TextField size="small" placeholder="🔍 Tìm theo tên / mã SV..." value={tim} onChange={(e) => setTim(e.target.value)}
            sx={{ minWidth: 260 }} InputProps={{ startAdornment: <InputAdornment position="start"><SearchIcon fontSize="small" /></InputAdornment> }} />
          <TextField select size="small" label="Lọc lớp SH" value={lop} onChange={(e) => setLop(e.target.value)} sx={{ minWidth: 220 }}>
            <MenuItem value="">Tất cả</MenuItem>
            {lops.map(l => <MenuItem key={l.MaLopSH} value={l.MaLopSH}>{l.MaLopSH} — {l.TenLopSH}</MenuItem>)}
          </TextField>
        </Stack>

        {loading ? <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}><CircularProgress /></Box> : (
          <TableContainer>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>Mã SV</TableCell><TableCell>Họ và tên</TableCell><TableCell>Ngày sinh</TableCell>
                  <TableCell>Giới tính</TableCell><TableCell>Email</TableCell><TableCell>Số điện thoại</TableCell>
                  <TableCell>Lớp SH</TableCell><TableCell>Trạng thái</TableCell><TableCell align="right">Thao tác</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {rows.map((r) => {
                  const [c, l] = TT_HOC[r.TrangThaiHoc] || ['default', r.TrangThaiHoc];
                  return (
                    <TableRow key={r.MaSV} hover>
                      <TableCell><code>{r.MaSV}</code></TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>{r.HoTen}</TableCell>
                      <TableCell>{fmtNgay(r.NgaySinh)}</TableCell>
                      <TableCell>{Number(r.GioiTinh) === 1 ? 'Nam' : 'Nữ'}</TableCell>
                      <TableCell sx={{ fontSize: 12.5 }}>{r.Email}</TableCell>
                      <TableCell>{r.SoDienThoai || '—'}</TableCell>
                      <TableCell>{r.MaLopSH}</TableCell>
                      <TableCell><Chip size="small" color={c} label={l} /></TableCell>
                      <TableCell align="right" sx={{ whiteSpace: 'nowrap' }}>
                        <Button size="small" onClick={() => { setMode('edit'); setForm({ ...r, NgaySinh: fmtNgay(r.NgaySinh) }); }}>Sửa</Button>
                        <Button size="small" color="error" onClick={() => setXoa(r)}>Xóa</Button>
                      </TableCell>
                    </TableRow>
                  );
                })}
                {!rows.length && <TableRow><TableCell colSpan={9} align="center" sx={{ py: 3, color: 'text.disabled' }}>Không tìm thấy sinh viên nào.</TableCell></TableRow>}
              </TableBody>
            </Table>
          </TableContainer>
        )}
        <Typography variant="caption" color="text.secondary">Thêm SV qua <b>SP_ThemSinhVien_Moi</b> — tự tạo tài khoản đăng nhập (mật khẩu mặc định) bằng trigger.</Typography>
      </SectionCard>

      <Dialog open={!!form} onClose={() => setForm(null)} maxWidth="sm" fullWidth>
        <DialogTitle sx={{ fontFamily: 'Montserrat', fontWeight: 700 }}>
          {mode === 'add' ? '➕ Thêm sinh viên' : `✏️ Cập nhật hồ sơ — ${form?.MaSV}`}
        </DialogTitle>
        <DialogContent dividers>
          <Stack spacing={2} sx={{ mt: 0.5 }}>
            <Stack direction="row" spacing={2}>
              <TextField size="small" label="Mã SV" value={form?.MaSV || ''} onChange={set('MaSV')} disabled={mode === 'edit'} sx={{ flex: 1 }} />
              <TextField size="small" label="Họ tên *" value={form?.HoTen || ''} onChange={set('HoTen')} sx={{ flex: 2 }} />
            </Stack>
            <Stack direction="row" spacing={2}>
              <TextField size="small" type="date" label="Ngày sinh *" InputLabelProps={{ shrink: true }} value={form?.NgaySinh || ''} onChange={set('NgaySinh')} sx={{ flex: 1 }} />
              <TextField select size="small" label="Giới tính" value={form?.GioiTinh ?? 1} onChange={set('GioiTinh')} sx={{ flex: 1 }}>
                <MenuItem value={1}>Nam</MenuItem><MenuItem value={0}>Nữ</MenuItem>
              </TextField>
            </Stack>
            <Stack direction="row" spacing={2}>
              <TextField size="small" label="Email *" value={form?.Email || ''} onChange={set('Email')} sx={{ flex: 1 }} />
              <TextField size="small" label="Số điện thoại *" value={form?.SoDienThoai || ''} onChange={set('SoDienThoai')} sx={{ flex: 1 }} />
            </Stack>
            <TextField select size="small" label="Lớp sinh hoạt *" value={form?.MaLopSH || ''} onChange={set('MaLopSH')}>
              {lops.map(l => <MenuItem key={l.MaLopSH} value={l.MaLopSH}>{l.MaLopSH} — {l.TenLopSH}</MenuItem>)}
            </TextField>
            {mode === 'edit' && (
              <TextField select size="small" label="Trạng thái học" value={form?.TrangThaiHoc ?? 1} onChange={set('TrangThaiHoc')}>
                <MenuItem value={1}>Đang học</MenuItem><MenuItem value={2}>Bảo lưu</MenuItem><MenuItem value={3}>Thôi học</MenuItem>
              </TextField>
            )}
            <TextField size="small" label="Nơi sinh" value={form?.QueQuan || ''} onChange={set('QueQuan')} multiline minRows={1} />
          </Stack>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => setForm(null)}>Hủy</Button>
          <Button variant="contained" disabled={busy} onClick={submit}>{busy ? 'Đang lưu...' : 'Lưu'}</Button>
        </DialogActions>
      </Dialog>

      <ConfirmDialog open={!!xoa} title="Xóa sinh viên"
        text={`Xóa sinh viên ${xoa?.HoTen} (${xoa?.MaSV})?\nHệ thống sẽ chặn nếu còn dữ liệu đăng ký/điểm/học phí liên quan.`}
        confirmText="Xóa" danger busy={busy} onConfirm={submitXoa} onClose={() => setXoa(null)} />
    </Box>
  );
}
