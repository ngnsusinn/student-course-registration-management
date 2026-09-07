import { useEffect, useState } from 'react';
import { useSelector } from 'react-redux';
import {
  Box, Grid, Card, CardContent, Typography, Stack, Avatar, Chip, Button, Divider,
  TextField, Dialog, DialogTitle, DialogContent, DialogActions, Alert, Skeleton,
} from '@mui/material';
import EditIcon from '@mui/icons-material/Edit';
import FileDownloadIcon from '@mui/icons-material/FileDownload';
import { toast } from 'react-toastify';
import api, { errMessage } from '../../api/client';
import { selectUser } from '../../store/authSlice';
import { tenVietTat } from '../../utils/format';
import { xuatExcel } from '../../utils/export';
import { TEAL, TEAL_DARKER } from '../../theme';

// ============================================================
// THONG TIN CA NHAN — ho so sinh vien (portal: "Thong tin sinh
// vien" + "Cap nhat ho so"). Du lieu tu /auth/hoso.
// ============================================================
function Row({ label, value }) {
  return (
    <Stack direction="row" spacing={1} sx={{ py: 0.75, borderBottom: '1px dashed #eef2f2', fontSize: 14 }}>
      <Typography color="text.secondary" sx={{ minWidth: 150 }}>{label}</Typography>
      <Typography sx={{ fontWeight: 500 }}>{value ?? '—'}</Typography>
    </Stack>
  );
}

export default function ThongTinCaNhan() {
  const user = useSelector(selectUser);
  const [hs, setHs] = useState(null);
  const [loading, setLoading] = useState(true);
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState({ Email: '', SoDienThoai: '', QueQuan: '' });

  useEffect(() => {
    api.get('/auth/hoso')
      .then(({ data }) => {
        const h = data.hoSo || {};
        setHs(h);
        setForm({ Email: h.Email || '', SoDienThoai: h.SoDienThoai || '', QueQuan: h.QueQuan || '' });
      })
      .catch((e) => toast.error(errMessage(e, 'Không thể tải thông tin sinh viên')))
      .finally(() => setLoading(false));
  }, []);

  const gioiTinh = Number(hs?.GioiTinh) === 1 ? 'Nam' : Number(hs?.GioiTinh) === 0 ? 'Nữ' : '—';
  const tinhTrang = Number(hs?.TrangThaiHoc) === 1 ? 'Đang học' : 'Nghỉ học';

  const xuat = () => xuatExcel('Thong-tin-ca-nhan', [
    { header: 'Trường', value: () => 'ĐH GTVT HCM' },
    { header: 'Mã số sinh viên', key: 'MaSV' }, { header: 'Họ và tên', key: 'HoTen' },
    { header: 'Ngày sinh', key: 'NgaySinh' }, { header: 'Giới tính', value: () => gioiTinh },
    { header: 'Nơi sinh', key: 'QueQuan' }, { header: 'Email', key: 'Email' },
    { header: 'Số điện thoại', key: 'SoDienThoai' }, { header: 'Lớp sinh hoạt', key: 'TenLopSH' },
    { header: 'Ngành', key: 'TenNganh' }, { header: 'Khóa học', key: 'NienKhoa' },
    { header: 'Tình trạng học', value: () => tinhTrang },
  ], [hs || {}]);

  const luu = () => {
    setOpen(false);
    toast.info('Yêu cầu cập nhật hồ sơ đã được ghi nhận (bản demo — chưa có API backend). Phòng Đào tạo sẽ xét duyệt.');
  };

  if (loading) return <Card><CardContent><Skeleton height={260} /></CardContent></Card>;

  return (
    <Box>
      <Alert severity="info" sx={{ mb: 2 }}>
        Sinh viên vui lòng cập nhật thông tin cá nhân (Nơi sinh, CCCD, số điện thoại, email...) khi có thay đổi.
        Email và số điện thoại cần còn sử dụng để Phòng Đào tạo liên hệ khi cần.
      </Alert>

      <Grid container spacing={2.5}>
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent sx={{ textAlign: 'center' }}>
              <Avatar sx={{ width: 96, height: 96, mx: 'auto', mb: 1.5, bgcolor: TEAL, fontFamily: 'Montserrat', fontWeight: 700, fontSize: 34 }}>
                {tenVietTat(hs?.HoTen || user?.HoTen)}
              </Avatar>
              <Typography sx={{ fontFamily: 'Montserrat', fontWeight: 700, fontSize: 18, color: TEAL_DARKER }}>
                {hs?.HoTen || user?.HoTen}
              </Typography>
              <Typography color="text.secondary" sx={{ mb: 1 }}>Mã số sinh viên: {hs?.MaSV}</Typography>
              <Chip size="small" color={Number(hs?.TrangThaiHoc) === 1 ? 'success' : 'default'} label={tinhTrang} />
              <Divider sx={{ my: 2 }} />
              <Stack spacing={1}>
                <Button variant="outlined" startIcon={<EditIcon />} onClick={() => setOpen(true)}>Cập nhật hồ sơ</Button>
                <Button variant="text" startIcon={<FileDownloadIcon />} onClick={xuat}>Xuất Excel</Button>
              </Stack>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={8}>
          <Card sx={{ mb: 2.5 }}>
            <CardContent>
              <Typography variant="h6" sx={{ fontFamily: 'Montserrat', fontWeight: 700, color: TEAL_DARKER, mb: 1 }}>Thông tin cá nhân</Typography>
              <Grid container columnSpacing={4}>
                <Grid item xs={12} sm={6}><Row label="Họ và tên" value={hs?.HoTen} /></Grid>
                <Grid item xs={12} sm={6}><Row label="Mã số sinh viên" value={hs?.MaSV} /></Grid>
                <Grid item xs={12} sm={6}><Row label="Ngày sinh" value={hs?.NgaySinh} /></Grid>
                <Grid item xs={12} sm={6}><Row label="Giới tính" value={gioiTinh} /></Grid>
                <Grid item xs={12} sm={6}><Row label="Nơi sinh" value={hs?.QueQuan || 'Chưa cập nhật'} /></Grid>
                <Grid item xs={12} sm={6}><Row label="Quốc tịch" value="Việt Nam" /></Grid>
                <Grid item xs={12} sm={6}><Row label="Email" value={hs?.Email} /></Grid>
                <Grid item xs={12} sm={6}><Row label="Số điện thoại" value={hs?.SoDienThoai || 'Chưa cập nhật'} /></Grid>
              </Grid>
            </CardContent>
          </Card>

          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ fontFamily: 'Montserrat', fontWeight: 700, color: TEAL_DARKER, mb: 1 }}>Thông tin đào tạo</Typography>
              <Grid container columnSpacing={4}>
                <Grid item xs={12} sm={6}><Row label="Khóa học" value={hs?.NienKhoa} /></Grid>
                <Grid item xs={12} sm={6}><Row label="Lớp sinh hoạt" value={hs?.TenLopSH} /></Grid>
                <Grid item xs={12} sm={6}><Row label="Ngành" value={hs?.TenNganh} /></Grid>
                <Grid item xs={12} sm={6}><Row label="Khoa chủ quản" value={hs?.TenKhoa} /></Grid>
                <Grid item xs={12} sm={6}><Row label="Bậc đào tạo" value="Chính quy" /></Grid>
                <Grid item xs={12} sm={6}><Row label="Loại hình đào tạo" value="Đại học — hệ tín chỉ" /></Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Dialog open={open} onClose={() => setOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle sx={{ fontFamily: 'Montserrat', fontWeight: 700 }}>Cập nhật thông tin liên hệ</DialogTitle>
        <DialogContent dividers>
          <Stack spacing={2} sx={{ mt: 0.5 }}>
            <TextField label="Email" value={form.Email} onChange={(e) => setForm({ ...form, Email: e.target.value })} fullWidth />
            <TextField label="Số điện thoại" value={form.SoDienThoai} onChange={(e) => setForm({ ...form, SoDienThoai: e.target.value })} fullWidth />
            <TextField label="Nơi sinh" value={form.QueQuan} onChange={(e) => setForm({ ...form, QueQuan: e.target.value })} fullWidth multiline minRows={2} />
            <Typography variant="caption" color="text.secondary">
              Hãy kiểm tra kỹ email, số điện thoại và ghi chú trước khi cập nhật hồ sơ.
            </Typography>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpen(false)}>Hủy</Button>
          <Button variant="contained" onClick={luu}>Gửi yêu cầu</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
