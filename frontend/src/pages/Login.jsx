import { useState } from 'react';
import { useDispatch } from 'react-redux';
import {
  Box, Container, Paper, Typography, TextField, Button, Stack, Alert,
  IconButton, InputAdornment, Link, Collapse, Table, TableBody, TableCell, TableRow,
} from '@mui/material';
import VisibilityIcon from '@mui/icons-material/Visibility';
import VisibilityOffIcon from '@mui/icons-material/VisibilityOff';
import { toast } from 'react-toastify';
import api, { errMessage } from '../api/client';
import { loggedIn } from '../store/authSlice';
import { SCHOOL } from '../components/PortalLayout';

// ============================================================
// Login 1 buoc: Tai khoan + Mat khau -> JWT (POST /auth/login)
// (OTP 2 buoc chi can cho GV/PDT trong thuc te — tam bo o day)
// ============================================================
export default function Login() {
  const dispatch = useDispatch();
  const [tk, setTk] = useState(localStorage.getItem('dk_remember_tk') || '');
  const [mk, setMk] = useState('');
  const [showPw, setShowPw] = useState(false);
  const [remember, setRemember] = useState(true);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState('');

  const submit = async (e) => {
    e.preventDefault();
    setErr('');
    if (!tk || !mk) { setErr('Vui lòng nhập tên đăng nhập và mật khẩu.'); return; }
    setBusy(true);
    try {
      const { data } = await api.post('/auth/login', { TenDangNhap: tk.trim(), MatKhau: mk });
      if (remember) localStorage.setItem('dk_remember_tk', tk.trim());
      else localStorage.removeItem('dk_remember_tk');
      dispatch(loggedIn({ token: data.token, user: data.user }));
      toast.success(`Chào mừng ${data.user.HoTen}!`);
      setTimeout(() => { window.location.href = '/'; }, 400);
    } catch (ex) {
      setErr(errMessage(ex, 'Đăng nhập thất bại.'));
    } finally {
      setBusy(false);
    }
  };

  const type = showPw ? 'text' : 'password';

  return (
    <Box sx={{
      minHeight: '100vh', display: 'flex', flexDirection: 'column', position: 'relative',
      background: `linear-gradient(rgba(0,40,44,.55),rgba(0,40,44,.55)), url('/images/bg_login.jpg') center/cover fixed`,
    }}>
      {/* Header logo */}
      <Container maxWidth="lg" sx={{ py: 2.5, display: 'flex', alignItems: 'center', gap: 2, color: '#fff' }}>
        <Box component="img" src={SCHOOL.logo} alt="Logo UTH" sx={{ height: 60, bgcolor: '#fff', borderRadius: 1.5, p: 0.5 }} />
        <Box>
          <Typography sx={{ fontFamily: 'Montserrat', fontWeight: 800, fontSize: 16, textTransform: 'uppercase' }}>
            Trường Đại học Giao thông vận tải TP. Hồ Chí Minh
          </Typography>
          <Typography variant="body2" sx={{ opacity: 0.9 }}>{SCHOOL.system}</Typography>
        </Box>
      </Container>

      <Container sx={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', pb: 4 }} maxWidth="xs">
        <Paper elevation={12} sx={{ width: '100%', p: 4, borderRadius: 3 }}>
          <form onSubmit={submit} noValidate>
            <Typography variant="h5" align="center" sx={{ textTransform: 'uppercase', letterSpacing: '.02em' }}>
              Đăng nhập hệ thống
            </Typography>
            <Typography variant="body2" align="center" color="text.secondary" sx={{ mb: 3 }}>
              Dành cho Sinh viên · Giảng viên · Phòng Đào tạo
            </Typography>
            {err && <Alert severity="error" sx={{ mb: 2 }}>{err}</Alert>}
            <TextField fullWidth size="small" label="Mã sinh viên / Tài khoản" value={tk}
              onChange={(e) => setTk(e.target.value)} sx={{ mb: 2 }} autoFocus
              placeholder="VD: sv001, gv001, admin" />
            <TextField fullWidth size="small" label="Mật khẩu" type={type} value={mk}
              onChange={(e) => setMk(e.target.value)} sx={{ mb: 1.5 }}
              InputProps={{ endAdornment: (
                <InputAdornment position="end">
                  <IconButton size="small" onClick={() => setShowPw(!showPw)}>
                    {showPw ? <VisibilityOffIcon fontSize="small" /> : <VisibilityIcon fontSize="small" />}
                  </IconButton>
                </InputAdornment>
              )}} />
            <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 2.5 }}>
              <Link component="button" type="button" variant="body2" underline="hover"
                onClick={() => setRemember(!remember)} sx={{ color: 'text.secondary' }}>
                {remember ? '☑' : '☐'} Ghi nhớ tài khoản
              </Link>
              <Link variant="body2" underline="hover" href="#" sx={{ color: 'primary.dark' }}
                onClick={(e) => { e.preventDefault(); toast.info('Vui lòng liên hệ Phòng Đào tạo để được cấp lại mật khẩu.'); }}>
                Quên mật khẩu?
              </Link>
            </Stack>
            <Button fullWidth variant="contained" size="large" disabled={busy} type="submit">
              {busy ? 'Đang đăng nhập...' : 'ĐĂNG NHẬP'}
            </Button>
          </form>

          <Collapse in>
            <details style={{ marginTop: 18, borderTop: '1px dashed #dde8e8', paddingTop: 10, fontSize: 12 }}>
              <summary style={{ cursor: 'pointer', fontWeight: 600, color: '#006266' }}>
                Tài khoản demo (dành cho người thử nghiệm)
              </summary>
              <Table size="small" sx={{ mt: 1 }}>
                <TableBody>
                  <TableRow><TableCell>Sinh viên</TableCell><TableCell><code>sv001</code></TableCell><TableCell><code>matkhau@123</code></TableCell></TableRow>
                  <TableRow><TableCell>Giảng viên</TableCell><TableCell><code>gv001</code></TableCell><TableCell><code>matkhau@123</code></TableCell></TableRow>
                  <TableRow><TableCell>Phòng Đào Tạo</TableCell><TableCell><code>admin</code></TableCell><TableCell><code>admin@123</code></TableCell></TableRow>
                </TableBody>
              </Table>
            </details>
          </Collapse>
        </Paper>
      </Container>

      <Box sx={{ textAlign: 'center', color: '#cfe7e7', fontSize: 12, py: 1.5 }}>
        © 2026 {SCHOOL.short} — {SCHOOL.system} (bản demo đồ án)
      </Box>
    </Box>
  );
}
