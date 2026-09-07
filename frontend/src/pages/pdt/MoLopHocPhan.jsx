import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Box, Stack, TextField, MenuItem, Button, Table, TableBody, TableCell, TableContainer,
  TableHead, TableRow, Dialog, DialogTitle, DialogContent, DialogActions, Chip,
  CircularProgress, Typography, Alert,
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import { toast } from 'react-toastify';
import api, { errMessage } from '../../api/client';
import { SectionCard } from '../../components/SectionCard';
import { SiSoChip, StatusChip } from '../../components/StatusBadges';
import { thuName } from '../../utils/format';

// ============================================================
// MO LOP HOC PHAN (PĐT) — SP_MoLopHocPhan: kiem tra GV/phong
// trung lich, si so, mon hoc...
// ============================================================
export default function MoLopHocPhan() {
  const [rows, setRows] = useState([]);
  const [hocky, setHocky] = useState([]);
  const [monHoc, setMonHoc] = useState([]);
  const [giangVien, setGiangVien] = useState([]);
  const [phongHoc, setPhongHoc] = useState([]);
  const [ky, setKy] = useState('');
  const [trangThai, setTrangThai] = useState('');
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [f, setF] = useState({ MaLHP: '', TenLHP: '', MaMonHoc: '', MaHocKy: '', MaGV: '', SiSoToiDa: 60, MaPhong: '', Thu: 2, TietBatDau: 1, SoTiet: 3 });

  const load = useCallback(() => {
    setLoading(true);
    api.get('/admin/lophocphan', { params: { MaHocKy: ky || undefined, TrangThaiLop: trangThai || undefined } })
      .then(({ data }) => setRows(data.lopHocPhan || []))
      .catch((e) => toast.error(errMessage(e)))
      .finally(() => setLoading(false));
  }, [ky, trangThai]);

  useEffect(() => { load(); }, [load]);
  useEffect(() => {
    Promise.all([api.get('/danhmuc/hocky'), api.get('/danhmuc/monhoc'), api.get('/danhmuc/giangvien'), api.get('/danhmuc/phonghoc')])
      .then(([h, m, g, p]) => {
        setHocky(h.data.hocKy); setMonHoc(m.data.monHoc); setGiangVien(g.data.giangVien); setPhongHoc(p.data.phongHoc);
        const mo = h.data.hocKy.find(x => x.DangMoDangKy) || h.data.hocKy[0];
        if (mo) setF((prev) => ({ ...prev, MaHocKy: mo.MaHocKy }));
      }).catch(() => {});
  }, []);

  const set = (k) => (e) => setF((p) => ({ ...p, [k]: e.target.value }));

  const submit = async () => {
    setBusy(true);
    try {
      const { data } = await api.post('/admin/molophocphan', f);
      toast.success(`✅ ${data.message} — ${f.MaLHP}`);
      setOpen(false);
      setF((p) => ({ ...p, MaLHP: '', TenLHP: '' }));
      load();
    } catch (e) {
      toast.error(errMessage(e, 'Mở lớp thất bại.'));
    } finally {
      setBusy(false);
    }
  };

  const cacKy = useMemo(() => [...new Set(rows.map(r => r.MaHocKy))], [rows]);

  return (
    <Box>
      <SectionCard title="Lớp học phần toàn hệ thống"
        action={<Button size="small" variant="contained" startIcon={<AddIcon />} onClick={() => setOpen(true)}>Mở lớp học phần mới</Button>}>
        <Stack direction="row" spacing={1.5} sx={{ mb: 2, flexWrap: 'wrap', useFlexGap: true }}>
          <TextField select size="small" label="Học kỳ" value={ky} onChange={(e) => setKy(e.target.value)} sx={{ minWidth: 180 }}>
            <MenuItem value="">Tất cả</MenuItem>
            {hocky.map(h => <MenuItem key={h.MaHocKy} value={h.MaHocKy}>{h.MaHocKy} — {h.TenHocKy}</MenuItem>)}
          </TextField>
          <TextField select size="small" label="Trạng thái" value={trangThai} onChange={(e) => setTrangThai(e.target.value)} sx={{ minWidth: 180 }}>
            <MenuItem value="">Tất cả</MenuItem>
            <MenuItem value="MO_DANG_KY">Đang mở đăng ký</MenuItem>
            <MenuItem value="DONG_DANG_KY">Đã đóng</MenuItem>
          </TextField>
          <Chip size="small" color="primary" label={`${rows.length} lớp`} />
        </Stack>

        {loading ? <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}><CircularProgress /></Box> : (
          <TableContainer>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>Mã LHP</TableCell><TableCell>Tên lớp HP</TableCell><TableCell>Môn học</TableCell>
                  <TableCell align="center">TC</TableCell><TableCell>Học kỳ</TableCell><TableCell>Giảng viên</TableCell>
                  <TableCell>Lịch học</TableCell><TableCell align="center">Sĩ số</TableCell><TableCell>Trạng thái</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {rows.map((r) => (
                  <TableRow key={r.MaLHP} hover>
                    <TableCell><code>{r.MaLHP}</code></TableCell>
                    <TableCell>{r.TenLHP}</TableCell>
                    <TableCell sx={{ fontWeight: 600 }}>{r.TenMonHoc}</TableCell>
                    <TableCell align="center">{r.SoTinChi}</TableCell>
                    <TableCell>{r.TenHocKy} {r.NamHoc}</TableCell>
                    <TableCell>{r.TenGV || '—'}</TableCell>
                    <TableCell sx={{ fontSize: 12 }}>{r.LichHoc || '—'}</TableCell>
                    <TableCell align="center"><SiSoChip hienTai={r.SiSoHienTai} toiDa={r.SiSoToiDa} /></TableCell>
                    <TableCell><StatusChip group="LOP" code={r.TrangThaiLop} /></TableCell>
                  </TableRow>
                ))}
                {!rows.length && <TableRow><TableCell colSpan={9} align="center" sx={{ py: 3, color: 'text.disabled' }}>Không có lớp nào.</TableCell></TableRow>}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </SectionCard>

      <Dialog open={open} onClose={() => setOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle sx={{ fontFamily: 'Montserrat', fontWeight: 700 }}>➕ Mở lớp học phần mới</DialogTitle>
        <DialogContent dividers>
          <Alert severity="info" sx={{ my: 1 }}>
            <b>SP_MoLopHocPhan</b> tự kiểm tra: môn học/học kỳ/GV/phòng tồn tại · sĩ số ≤ sức chứa · GV & phòng không trùng lịch.
          </Alert>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <Stack direction="row" spacing={2}>
              <TextField size="small" label="Mã LHP * (VD: HP2025-99)" value={f.MaLHP} onChange={set('MaLHP')} sx={{ flex: 1 }} />
              <TextField size="small" label="Tên lớp HP *" value={f.TenLHP} onChange={set('TenLHP')} sx={{ flex: 2 }} />
            </Stack>
            <TextField select size="small" label="Môn học *" value={f.MaMonHoc} onChange={set('MaMonHoc')}>
              {monHoc.map(m => <MenuItem key={m.MaMonHoc} value={m.MaMonHoc}>{m.MaMonHoc} — {m.TenMonHoc} ({m.SoTinChi} TC)</MenuItem>)}
            </TextField>
            <Stack direction="row" spacing={2}>
              <TextField select size="small" label="Học kỳ *" value={f.MaHocKy} onChange={set('MaHocKy')} sx={{ flex: 1 }}>
                {hocky.map(h => <MenuItem key={h.MaHocKy} value={h.MaHocKy}>{h.MaHocKy} — {h.TenHocKy}</MenuItem>)}
              </TextField>
              <TextField select size="small" label="Giảng viên *" value={f.MaGV} onChange={set('MaGV')} sx={{ flex: 1 }}>
                {giangVien.map(g => <MenuItem key={g.MaGV} value={g.MaGV}>{g.MaGV} — {g.HoTen}</MenuItem>)}
              </TextField>
            </Stack>
            <Stack direction="row" spacing={2}>
              <TextField select size="small" label="Phòng học *" value={f.MaPhong} onChange={set('MaPhong')} sx={{ flex: 1 }}>
                {phongHoc.map(p => <MenuItem key={p.MaPhong} value={p.MaPhong}>{p.TenPhong} ({p.SucChua})</MenuItem>)}
              </TextField>
              <TextField size="small" type="number" label="Sĩ số tối đa *" value={f.SiSoToiDa} onChange={set('SiSoToiDa')} sx={{ flex: 1 }} />
            </Stack>
            <Stack direction="row" spacing={2}>
              <TextField select size="small" label="Thứ *" value={f.Thu} onChange={set('Thu')} sx={{ flex: 1 }}>
                {[2, 3, 4, 5, 6, 7].map(d => <MenuItem key={d} value={d}>{thuName(d)}</MenuItem>)}
              </TextField>
              <TextField size="small" type="number" label="Tiết bắt đầu *" value={f.TietBatDau} onChange={set('TietBatDau')} sx={{ flex: 1 }} />
              <TextField size="small" type="number" label="Số tiết *" value={f.SoTiet} onChange={set('SoTiet')} sx={{ flex: 1 }} />
            </Stack>
          </Stack>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => setOpen(false)}>Hủy</Button>
          <Button variant="contained" disabled={busy} onClick={submit}>{busy ? 'Đang mở lớp...' : 'Mở lớp'}</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
