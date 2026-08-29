import { useCallback, useEffect, useState } from 'react';
import {
  Box, Tabs, Tab, Table, TableBody, TableCell, TableContainer, TableHead, TableRow,
  Button, Dialog, DialogTitle, DialogContent, DialogActions, TextField, MenuItem,
  Stack, CircularProgress, Chip, Autocomplete,
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import { toast } from 'react-toastify';
import api, { errMessage } from '../../api/client';
import { SectionCard } from '../../components/SectionCard';
import ConfirmDialog from '../../components/ConfirmDialog';
import { fmtNgay } from '../../utils/format';

// ============================================================
// MON HOC · TIEN QUYET · GIANG VIEN · PHONG · HOC KY (PĐT)
// ============================================================
export default function MonHocGiangVien() {
  const [tab, setTab] = useState(0);
  const [monHoc, setMonHoc] = useState([]);
  const [khoa, setKhoa] = useState([]);
  const [giangVien, setGiangVien] = useState([]);
  const [phongHoc, setPhongHoc] = useState([]);
  const [hocKy, setHocKy] = useState([]);
  const [tienQuyet, setTienQuyet] = useState([]);
  const [loading, setLoading] = useState(true);
  const [form, setForm] = useState(null);
  const [xoa, setXoa] = useState(null);
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [m, k, g, p, h, t] = await Promise.all([
        api.get('/danhmuc/monhoc'), api.get('/danhmuc/khoa'), api.get('/danhmuc/giangvien'),
        api.get('/danhmuc/phonghoc'), api.get('/danhmuc/hocky'), api.get('/danhmuc/tienquyet'),
      ]);
      setMonHoc(m.data.monHoc); setKhoa(k.data.khoa); setGiangVien(g.data.giangVien);
      setPhongHoc(p.data.phongHoc); setHocKy(h.data.hocKy); setTienQuyet(t.data.tienQuyet);
    } catch (e) { toast.error(errMessage(e)); }
    finally { setLoading(false); }
  }, []);
  useEffect(() => { load(); }, [load]);

  const luu = async () => {
    setBusy(true);
    try {
      const { url, editUrl, editKey, data } = form;
      const res = editUrl
        ? await api.put(editUrl, data)
        : await api.post(url, data);
      toast.success(`✅ ${res.data.message}`);
      setForm(null); load();
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

  const set = (k) => (e) => setForm((p) => ({ ...p, data: { ...p.data, [k]: e.target.value } }));
  const F = (k, label, extra = {}) => (
    <TextField size="small" label={label} value={form?.data?.[k] ?? ''} onChange={set(k)} sx={{ flex: 1, minWidth: 150 }} {...extra} />
  );
  const ActionCell = ({ edit, del }) => (
    <TableCell align="right" sx={{ whiteSpace: 'nowrap' }}>
      {edit && <Button size="small" onClick={edit}>Sửa</Button>}
      {del && <Button size="small" color="error" onClick={del}>Xóa</Button>}
    </TableCell>
  );

  if (loading) return <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}><CircularProgress /></Box>;

  return (
    <Box>
      <SectionCard title="Danh mục học vụ">
        <Tabs value={tab} onChange={(e, v) => setTab(v)} sx={{ mb: 2 }} variant="scrollable" allowScrollButtonsMobile>
          <Tab label={`Môn học (${monHoc.length})`} />
          <Tab label={`Tiên quyết (${tienQuyet.length})`} />
          <Tab label={`Giảng viên (${giangVien.length})`} />
          <Tab label={`Phòng học (${phongHoc.length})`} />
          <Tab label={`Học kỳ (${hocKy.length})`} />
        </Tabs>

        {tab === 0 && (<>
          <Button size="small" variant="contained" startIcon={<AddIcon />} sx={{ mb: 1.5 }}
            onClick={() => setForm({ url: '/danhmuc/monhoc', title: 'Thêm môn học', data: { MaMonHoc: '', TenMonHoc: '', SoTinChi: 2, SoTietLyThuyet: 15, SoTietThucHanh: 15, MaKhoa: '', TienQuyet: [] } })}>Thêm môn học</Button>
          <TableContainer><Table size="small">
            <TableHead><TableRow><TableCell>Mã</TableCell><TableCell>Tên môn học</TableCell><TableCell align="center">TC</TableCell><TableCell align="center">Lý thuyết</TableCell><TableCell align="center">Thực hành</TableCell><TableCell>Khoa</TableCell><TableCell align="center">Môn TQ</TableCell><TableCell align="right"></TableCell></TableRow></TableHead>
            <TableBody>
              {monHoc.map(m => (
                <TableRow key={m.MaMonHoc} hover>
                  <TableCell><code>{m.MaMonHoc}</code></TableCell><TableCell sx={{ fontWeight: 600 }}>{m.TenMonHoc}</TableCell>
                  <TableCell align="center">{m.SoTinChi}</TableCell><TableCell align="center">{m.SoTietLyThuyet}</TableCell><TableCell align="center">{m.SoTietThucHanh}</TableCell>
                  <TableCell>{m.TenKhoa}</TableCell>
                  <TableCell align="center">{tienQuyet.filter(t => t.MaMonHoc === m.MaMonHoc).map(t => <Chip key={t.MaMonTienQuyet} size="small" sx={{ m: 0.25 }} label={t.MaMonTienQuyet} />)}</TableCell>
                  <ActionCell edit={() => setForm({ editUrl: `/danhmuc/monhoc/${m.MaMonHoc}`, title: `Sửa môn ${m.MaMonHoc}`, data: { ...m } })}
                    del={() => setXoa({ url: `/danhmuc/monhoc/${m.MaMonHoc}`, label: `xóa môn ${m.TenMonHoc}` })} />
                </TableRow>
              ))}
            </TableBody>
          </Table></TableContainer>
        </>)}

        {tab === 1 && (<>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 1.5 }}>
            💡 Quan hệ tiên quyết được khai báo khi <b>thêm môn học</b> (tab Môn học). Sinh viên phải đạt ≥ D môn tiên quyết mới được đăng ký.
          </Typography>
          <TableContainer><Table size="small">
            <TableHead><TableRow><TableCell>Môn học</TableCell><TableCell></TableCell><TableCell>Môn tiên quyết</TableCell></TableRow></TableHead>
            <TableBody>
              {tienQuyet.map((t, i) => (
                <TableRow key={i} hover>
                  <TableCell><code>{t.MaMonHoc}</code> — {t.TenMonHoc}</TableCell>
                  <TableCell align="center" sx={{ color: 'primary.main', fontWeight: 700 }}>← bắt buộc học trước ←</TableCell>
                  <TableCell><code>{t.MaMonTienQuyet}</code> — {t.TenMonTienQuyet}</TableCell>
                </TableRow>
              ))}
              {!tienQuyet.length && <TableRow><TableCell colSpan={3} align="center" sx={{ py: 3, color: 'text.disabled' }}>Chưa có môn tiên quyết.</TableCell></TableRow>}
            </TableBody>
          </Table></TableContainer>
        </>)}

        {tab === 2 && (<>
          <Button size="small" variant="contained" startIcon={<AddIcon />} sx={{ mb: 1.5 }}
            onClick={() => setForm({ url: '/danhmuc/giangvien', title: 'Thêm giảng viên (kèm tài khoản)', data: { MaGV: '', HoTen: '', Email: '', MaKhoa: '' } })}>Thêm giảng viên</Button>
          <TableContainer><Table size="small">
            <TableHead><TableRow><TableCell>Mã GV</TableCell><TableCell>Họ tên</TableCell><TableCell>Email</TableCell><TableCell>Khoa</TableCell><TableCell align="right"></TableCell></TableRow></TableHead>
            <TableBody>
              {giangVien.map(g => (
                <TableRow key={g.MaGV} hover>
                  <TableCell><code>{g.MaGV}</code></TableCell><TableCell sx={{ fontWeight: 600 }}>{g.HoTen}</TableCell>
                  <TableCell>{g.Email}</TableCell><TableCell>{g.TenKhoa}</TableCell>
                  <ActionCell edit={() => setForm({ editUrl: `/danhmuc/giangvien/${g.MaGV}`, title: `Sửa GV ${g.MaGV}`, data: { ...g } })}
                    del={() => setXoa({ url: `/danhmuc/giangvien/${g.MaGV}`, label: `xóa giảng viên ${g.HoTen}` })} />
                </TableRow>
              ))}
            </TableBody>
          </Table></TableContainer>
        </>)}

        {tab === 3 && (<>
          <Button size="small" variant="contained" startIcon={<AddIcon />} sx={{ mb: 1.5 }}
            onClick={() => setForm({ url: '/danhmuc/phonghoc', title: 'Thêm phòng học', data: { MaPhong: '', TenPhong: '', SucChua: 50 } })}>Thêm phòng</Button>
          <TableContainer><Table size="small">
            <TableHead><TableRow><TableCell>Mã phòng</TableCell><TableCell>Tên phòng</TableCell><TableCell align="center">Sức chứa</TableCell><TableCell align="right"></TableCell></TableRow></TableHead>
            <TableBody>
              {phongHoc.map(p => (
                <TableRow key={p.MaPhong} hover>
                  <TableCell><code>{p.MaPhong}</code></TableCell><TableCell sx={{ fontWeight: 600 }}>{p.TenPhong}</TableCell>
                  <TableCell align="center">{p.SucChua}</TableCell>
                  <ActionCell edit={() => setForm({ editUrl: `/danhmuc/phonghoc/${p.MaPhong}`, title: `Sửa phòng ${p.MaPhong}`, data: { ...p } })}
                    del={() => setXoa({ url: `/danhmuc/phonghoc/${p.MaPhong}`, label: `xóa phòng ${p.TenPhong}` })} />
                </TableRow>
              ))}
            </TableBody>
          </Table></TableContainer>
        </>)}

        {tab === 4 && (
          <TableContainer><Table size="small">
            <TableHead><TableRow><TableCell>Mã HK</TableCell><TableCell>Tên học kỳ</TableCell><TableCell>Năm học</TableCell>
            <TableCell>Từ ngày</TableCell><TableCell>Đến ngày</TableCell><TableCell align="center">Đợt ĐK</TableCell><TableCell align="right"></TableCell></TableRow></TableHead>
            <TableBody>
              {hocKy.map(h => (
                <TableRow key={h.MaHocKy} hover>
                  <TableCell><code>{h.MaHocKy}</code></TableCell><TableCell sx={{ fontWeight: 600 }}>{h.TenHocKy}</TableCell>
                  <TableCell>{h.NamHoc}</TableCell><TableCell>{fmtNgay(h.TuNgay)}</TableCell><TableCell>{fmtNgay(h.DenNgay)}</TableCell>
                  <TableCell align="center">
                    <Chip size="small" color={h.TrangThaiDot === 'MO' ? 'success' : 'default'} label={h.TrangThaiDot === 'MO' ? 'Đang mở' : 'Đã đóng'} />
                    {!!h.DangMoDangKy && <Chip size="small" color="primary" sx={{ ml: 0.5 }} label="trong hạn" />}
                  </TableCell>
                  <ActionCell edit={() => setForm({ editUrl: `/danhmuc/hocky/${h.MaHocKy}`, title: `Cập nhật học kỳ ${h.MaHocKy}`, data: { ...h, TuNgay: fmtNgay(h.TuNgay), DenNgay: fmtNgay(h.DenNgay) } })} />
                </TableRow>
              ))}
            </TableBody>
          </Table></TableContainer>
        )}
      </SectionCard>

      <Dialog open={!!form} onClose={() => setForm(null)} maxWidth="xs" fullWidth>
        <DialogTitle sx={{ fontFamily: 'Montserrat', fontWeight: 700 }}>{form?.title}</DialogTitle>
        <DialogContent dividers>
          <Stack spacing={2} sx={{ mt: 0.5 }}>
            {tab === 0 && !form?.addTQ && (<>{F('MaMonHoc', 'Mã môn học *', { disabled: !!form?.editUrl })}{F('TenMonHoc', 'Tên môn học *')}
              {F('SoTinChi', 'Số tín chỉ *', { type: 'number' })}
              <Stack direction="row" spacing={2}>{F('SoTietLyThuyet', 'Số tiết LT', { type: 'number' })}{F('SoTietThucHanh', 'Số tiết TH', { type: 'number' })}</Stack>
              <TextField select size="small" label="Khoa phụ trách *" value={form?.data?.MaKhoa ?? ''} onChange={set('MaKhoa')}>
                {khoa.map(k => <MenuItem key={k.MaKhoa} value={k.MaKhoa}>{k.TenKhoa}</MenuItem>)}
              </TextField>
              {!form?.editUrl && (
                <Autocomplete size="small" multiple options={monHoc.map(m => m.MaMonHoc)} value={form?.data?.TienQuyet || []}
                  onChange={(e, v) => setForm((p) => ({ ...p, data: { ...p.data, TienQuyet: v } }))}
                  getOptionLabel={(v) => `${v} — ${monHoc.find(m => m.MaMonHoc === v)?.TenMonHoc || ''}`}
                  renderInput={(params) => <TextField {...params} label="Môn tiên quyết (nếu có)" />} />
              )}</>)}
            {tab === 2 && (<>{F('MaGV', 'Mã GV *', { disabled: !!form?.editUrl })}{F('HoTen', 'Họ tên *')}{F('Email', 'Email *')}
              <TextField select size="small" label="Khoa *" value={form?.data?.MaKhoa ?? ''} onChange={set('MaKhoa')}>
                {khoa.map(k => <MenuItem key={k.MaKhoa} value={k.MaKhoa}>{k.TenKhoa}</MenuItem>)}
              </TextField></>)}
            {tab === 3 && (<>{F('MaPhong', 'Mã phòng *', { disabled: !!form?.editUrl })}{F('TenPhong', 'Tên phòng *')}{F('SucChua', 'Sức chứa *', { type: 'number' })}</>)}
            {tab === 4 && (<>{F('TenHocKy', 'Tên học kỳ *')}{F('NamHoc', 'Năm học *')}{F('TuNgay', 'Từ ngày', { type: 'date', InputLabelProps: { shrink: true } })}{F('DenNgay', 'Đến ngày', { type: 'date', InputLabelProps: { shrink: true } })}
              <TextField select size="small" label="Trạng thái đợt đăng ký" value={form?.data?.TrangThaiDot ?? 'MO'} onChange={set('TrangThaiDot')}>
                <MenuItem value="MO">MỞ — cho phép đăng ký</MenuItem><MenuItem value="DONG">ĐÓNG</MenuItem>
              </TextField></>)}
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
