import { useCallback, useEffect, useState } from 'react';
import {
  Box, Tabs, Tab, Table, TableBody, TableCell, TableContainer, TableHead, TableRow,
  Button, Dialog, DialogTitle, DialogContent, DialogActions, TextField, MenuItem,
  Stack, CircularProgress, Chip, Typography,
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import { toast } from 'react-toastify';
import api, { errMessage } from '../../api/client';
import { SectionCard } from '../../components/SectionCard';
import ConfirmDialog from '../../components/ConfirmDialog';

// ============================================================
// KHOA · NGANH · LOP · CTDT (PĐT) — CRUD danh muc co ban
// ============================================================
export default function KhoaNganhLop() {
  const [tab, setTab] = useState(0);
  const [khoa, setKhoa] = useState([]);
  const [nganh, setNganh] = useState([]);
  const [lop, setLop] = useState([]);
  const [monHoc, setMonHoc] = useState([]);
  const [ctdt, setCtdt] = useState([]);
  const [ctdtNganh, setCtdtNganh] = useState('');
  const [loading, setLoading] = useState(true);
  const [form, setForm] = useState(null);
  const [xoa, setXoa] = useState(null); // {url, label}
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [k, n, l, m] = await Promise.all([
        api.get('/danhmuc/khoa'), api.get('/danhmuc/nganh'),
        api.get('/danhmuc/lop'), api.get('/danhmuc/monhoc'),
      ]);
      setKhoa(k.data.khoa); setNganh(n.data.nganh); setLop(l.data.lop); setMonHoc(m.data.monHoc);
    } catch (e) { toast.error(errMessage(e)); }
    finally { setLoading(false); }
  }, []);

  useEffect(() => { load(); }, [load]);
  useEffect(() => {
    if (tab === 3) {
      api.get('/danhmuc/ctdt', { params: { MaNganh: ctdtNganh || undefined } })
        .then(({ data }) => setCtdt(data.ctdt || [])).catch((e) => toast.error(errMessage(e)));
    }
  }, [tab, ctdtNganh]);

  const luu = async () => {
    setBusy(true);
    try {
      const { url, editKey, data } = form;
      const cfg = { headers: { 'Content-Type': 'application/json' } };
      const res = editKey
        ? await api.put(`${url}/${data[editKey]}`, data, cfg)
        : await api.post(url, data, cfg);
      toast.success(`✅ ${res.data.message}`);
      setForm(null);
      load();
      if (tab === 3) setCtdtNganh(ctdtNganh);
    } catch (e) { toast.error(errMessage(e, 'Lưu thất bại.')); }
    finally { setBusy(false); }
  };

  const runXoa = async () => {
    setBusy(true);
    try {
      const { data } = await api.delete(xoa.url);
      toast.success(`✅ ${data.message}`);
      setXoa(null); load();
    } catch (e) { toast.error(errMessage(e)); }
    finally { setBusy(false); }
  };

  const ActionCell = ({ edit, del }) => (
    <TableCell align="right" sx={{ whiteSpace: 'nowrap' }}>
      {edit && <Button size="small" onClick={edit}>Sửa</Button>}
      {del && <Button size="small" color="error" onClick={del}>Xóa</Button>}
    </TableCell>
  );

  const set = (k) => (e) => setForm((p) => ({ ...p, data: { ...p.data, [k]: e.target.value } }));
  const F = (k, label, extra = {}) => (
    <TextField size="small" label={label} value={form?.data?.[k] ?? ''} onChange={set(k)} sx={{ flex: 1, minWidth: 160 }} {...extra} />
  );

  if (loading) return <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}><CircularProgress /></Box>;

  return (
    <Box>
      <SectionCard title="Hệ thống danh mục đào tạo">
        <Tabs value={tab} onChange={(e, v) => setTab(v)} sx={{ mb: 2 }} variant="scrollable" allowScrollButtonsMobile>
          <Tab label={`Khoa (${khoa.length})`} />
          <Tab label={`Ngành (${nganh.length})`} />
          <Tab label={`Lớp sinh hoạt (${lop.length})`} />
          <Tab label="Chương trình đào tạo" />
        </Tabs>

        {tab === 0 && (
          <>
            <Button size="small" variant="contained" startIcon={<AddIcon />} sx={{ mb: 1.5 }}
              onClick={() => setForm({ url: '/danhmuc/khoa', title: 'Thêm khoa', data: { MaKhoa: '', TenKhoa: '', DienThoaiKhoa: '', EmailKhoa: '' } })}>Thêm khoa</Button>
            <TableContainer><Table size="small">
              <TableHead><TableRow><TableCell>Mã</TableCell><TableCell>Tên khoa</TableCell><TableCell>Điện thoại</TableCell><TableCell>Email</TableCell><TableCell align="right">SL ngành</TableCell><TableCell align="right"></TableCell></TableRow></TableHead>
              <TableBody>
                {khoa.map(k => (
                  <TableRow key={k.MaKhoa} hover>
                    <TableCell><code>{k.MaKhoa}</code></TableCell><TableCell sx={{ fontWeight: 600 }}>{k.TenKhoa}</TableCell>
                    <TableCell>{k.DienThoaiKhoa || '—'}</TableCell><TableCell>{k.EmailKhoa}</TableCell>
                    <TableCell align="right">{nganh.filter(n => n.MaKhoa === k.MaKhoa).length}</TableCell>
                    <ActionCell edit={() => setForm({ url: '/danhmuc/khoa', editKey: 'MaKhoa', title: `Sửa khoa ${k.MaKhoa}`, data: { ...k } })}
                      del={() => setXoa({ url: `/danhmuc/khoa/${k.MaKhoa}`, label: `xóa khoa ${k.TenKhoa}` })} />
                  </TableRow>
                ))}
              </TableBody>
            </Table></TableContainer>
          </>
        )}

        {tab === 1 && (
          <>
            <Button size="small" variant="contained" startIcon={<AddIcon />} sx={{ mb: 1.5 }}
              onClick={() => setForm({ url: '/danhmuc/nganh', title: 'Thêm ngành', data: { MaNganh: '', TenNganh: '', ThoiGianDaoTao: 4, MaKhoa: '' } })}>Thêm ngành</Button>
            <TableContainer><Table size="small">
              <TableHead><TableRow><TableCell>Mã</TableCell><TableCell>Tên ngành</TableCell><TableCell align="center">Khóa học (năm)</TableCell><TableCell>Khoa</TableCell><TableCell align="right">SL lớp</TableCell><TableCell align="right"></TableCell></TableRow></TableHead>
              <TableBody>
                {nganh.map(n => (
                  <TableRow key={n.MaNganh} hover>
                    <TableCell><code>{n.MaNganh}</code></TableCell><TableCell sx={{ fontWeight: 600 }}>{n.TenNganh}</TableCell>
                    <TableCell align="center">{n.ThoiGianDaoTao}</TableCell><TableCell>{n.TenKhoa}</TableCell>
                    <TableCell align="right">{lop.filter(l => l.MaNganh === n.MaNganh).length}</TableCell>
                    <ActionCell edit={() => setForm({ url: '/danhmuc/nganh', editKey: 'MaNganh', title: `Sửa ngành ${n.MaNganh}`, data: { ...n } })}
                      del={() => setXoa({ url: `/danhmuc/nganh/${n.MaNganh}`, label: `xóa ngành ${n.TenNganh} (trigger chặn nếu còn SV)` })} />
                  </TableRow>
                ))}
              </TableBody>
            </Table></TableContainer>
          </>
        )}

        {tab === 2 && (
          <>
            <Button size="small" variant="contained" startIcon={<AddIcon />} sx={{ mb: 1.5 }}
              onClick={() => setForm({ url: '/danhmuc/lop', title: 'Thêm lớp sinh hoạt', data: { MaLopSH: '', TenLopSH: '', NienKhoa: '', MaNganh: '' } })}>Thêm lớp</Button>
            <TableContainer><Table size="small">
              <TableHead><TableRow><TableCell>Mã lớp</TableCell><TableCell>Tên lớp</TableCell><TableCell>Niên chế</TableCell><TableCell>Ngành</TableCell><TableCell align="center">Sĩ số</TableCell><TableCell align="right"></TableCell></TableRow></TableHead>
              <TableBody>
                {lop.map(l => (
                  <TableRow key={l.MaLopSH} hover>
                    <TableCell><code>{l.MaLopSH}</code></TableCell><TableCell sx={{ fontWeight: 600 }}>{l.TenLopSH}</TableCell>
                    <TableCell>{l.NienKhoa}</TableCell><TableCell>{l.TenNganh}</TableCell>
                    <TableCell align="center"><Chip size="small" label={l.SiSo} /></TableCell>
                    <ActionCell edit={() => setForm({ url: '/danhmuc/lop', editKey: 'MaLopSH', title: `Sửa lớp ${l.MaLopSH}`, data: { ...l } })}
                      del={() => setXoa({ url: `/danhmuc/lop/${l.MaLopSH}`, label: `xóa lớp ${l.MaLopSH}` })} />
                  </TableRow>
                ))}
              </TableBody>
            </Table></TableContainer>
          </>
        )}

        {tab === 3 && (
          <>
            <Stack direction="row" spacing={1.5} alignItems="center" sx={{ mb: 1.5, flexWrap: 'wrap', useFlexGap: true }}>
              <TextField select size="small" label="Lọc theo ngành" value={ctdtNganh} onChange={(e) => setCtdtNganh(e.target.value)} sx={{ minWidth: 260 }}>
                <MenuItem value="">Tất cả ngành</MenuItem>
                {nganh.map(n => <MenuItem key={n.MaNganh} value={n.MaNganh}>{n.TenNganh}</MenuItem>)}
              </TextField>
              <Button size="small" variant="contained" startIcon={<AddIcon />}
                onClick={() => setForm({ url: '/danhmuc/ctdt', title: 'Thêm môn vào CTĐT', data: { MaNganh: ctdtNganh || '', MaMonHoc: '', HocKyDuKien: 1, BatBuoc: 1 } })}>Thêm môn</Button>
            </Stack>
            <TableContainer><Table size="small">
              <TableHead><TableRow><TableCell>Ngành</TableCell><TableCell>Mã môn</TableCell><TableCell>Môn học</TableCell><TableCell align="center">TC</TableCell><TableCell align="center">HK dự kiến</TableCell><TableCell align="center">Bắt buộc</TableCell><TableCell align="right"></TableCell></TableRow></TableHead>
              <TableBody>
                {ctdt.map((c, i) => (
                  <TableRow key={i} hover>
                    <TableCell>{c.MaNganh}</TableCell><TableCell><code>{c.MaMonHoc}</code></TableCell>
                    <TableCell sx={{ fontWeight: 600 }}>{c.TenMonHoc}</TableCell><TableCell align="center">{c.SoTinChi}</TableCell>
                    <TableCell align="center">{c.HocKyDuKien}</TableCell>
                    <TableCell align="center">{Number(c.BatBuoc) ? <Chip size="small" color="primary" label="Bắt buộc" /> : <Chip size="small" label="Tự chọn" variant="outlined" />}</TableCell>
                    <ActionCell del={() => setXoa({ url: `/danhmuc/ctdt/${c.MaNganh}/${c.MaMonHoc}`, label: `xóa ${c.TenMonHoc} khỏi chương trình` })} />
                  </TableRow>
                ))}
                {!ctdt.length && <TableRow><TableCell colSpan={7} align="center" sx={{ py: 3, color: 'text.disabled' }}>Chưa có dữ liệu CTĐT.</TableCell></TableRow>}
              </TableBody>
            </Table></TableContainer>
          </>
        )}
      </SectionCard>

      <Dialog open={!!form} onClose={() => setForm(null)} maxWidth="xs" fullWidth>
        <DialogTitle sx={{ fontFamily: 'Montserrat', fontWeight: 700 }}>{form?.title}</DialogTitle>
        <DialogContent dividers>
          <Stack spacing={2} sx={{ mt: 0.5, minWidth: 240 }}>
            {tab === 0 && (<>{F('MaKhoa', 'Mã khoa *', { disabled: !!form?.editKey })}{F('TenKhoa', 'Tên khoa *')}{F('DienThoaiKhoa', 'Điện thoại')}{F('EmailKhoa', 'Email *')}</>)}
            {tab === 1 && (<>{F('MaNganh', 'Mã ngành *', { disabled: !!form?.editKey })}{F('TenNganh', 'Tên ngành *')}{F('ThoiGianDaoTao', 'Thời gian đào tạo (năm)', { type: 'number' })}
              <TextField select size="small" label="Khoa *" value={form?.data?.MaKhoa ?? ''} onChange={set('MaKhoa')} sx={{ minWidth: 160 }}>
                {khoa.map(k => <MenuItem key={k.MaKhoa} value={k.MaKhoa}>{k.TenKhoa}</MenuItem>)}
              </TextField></>)}
            {tab === 2 && (<>{F('MaLopSH', 'Mã lớp *', { disabled: !!form?.editKey })}{F('TenLopSH', 'Tên lớp *')}{F('NienKhoa', 'Niên chế (VD: 2021-2025) *')}
              <TextField select size="small" label="Ngành *" value={form?.data?.MaNganh ?? ''} onChange={set('MaNganh')} sx={{ minWidth: 160 }}>
                {nganh.map(n => <MenuItem key={n.MaNganh} value={n.MaNganh}>{n.TenNganh}</MenuItem>)}
              </TextField></>)}
            {tab === 3 && (<>
              <TextField select size="small" label="Ngành *" value={form?.data?.MaNganh ?? ''} onChange={set('MaNganh')}>
                {nganh.map(n => <MenuItem key={n.MaNganh} value={n.MaNganh}>{n.TenNganh}</MenuItem>)}
              </TextField>
              <TextField select size="small" label="Môn học *" value={form?.data?.MaMonHoc ?? ''} onChange={set('MaMonHoc')}>
                {monHoc.map(m => <MenuItem key={m.MaMonHoc} value={m.MaMonHoc}>{m.MaMonHoc} — {m.TenMonHoc}</MenuItem>)}
              </TextField>
              {F('HocKyDuKien', 'Học kỳ dự kiến *', { type: 'number' })}
              <TextField select size="small" label="Tính chất" value={form?.data?.BatBuoc ?? 1} onChange={set('BatBuoc')}>
                <MenuItem value={1}>Bắt buộc</MenuItem><MenuItem value={0}>Tự chọn</MenuItem>
              </TextField>
            </>)}
          </Stack>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => setForm(null)}>Hủy</Button>
          <Button variant="contained" disabled={busy} onClick={luu}>{busy ? 'Đang lưu...' : 'Lưu'}</Button>
        </DialogActions>
      </Dialog>

      <ConfirmDialog open={!!xoa} title="Xác nhận xóa" text={`Bạn có chắc muốn ${xoa?.label}?`} confirmText="Xóa" danger busy={busy} onConfirm={runXoa} onClose={() => setXoa(null)} />
    </Box>
  );
}
