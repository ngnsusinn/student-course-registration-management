import { useEffect, useRef, useState } from 'react';
import { useDispatch } from 'react-redux';
import {
  Box, Container, Paper, Typography, TextField, Button, Stack, Alert,
  IconButton, InputAdornment, Link, Collapse, Table, TableBody, TableCell, TableRow,
} from '@mui/material';
import VisibilityIcon from '@mui/icons-material/Visibility';
import VisibilityOffIcon from '@mui/icons-material/VisibilityOff';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import { toast } from 'react-toastify';
import api, { errMessage } from '../api/client';
import { loggedIn } from '../store/authSlice';
import { SCHOOL } from '../components/PortalLayout';

// ============================================================
// Login 2 buoc theo portal that: Tai khoan+MK -> OTP 6 so
// (Portal gui OTP qua email truong + reCAPTCHA; ban demo hien
//  ma OTP ngay tren UI — backend /auth/otp/*)
// ============================================================
export default function Login() {
  const dispatch = useDispatch();
  const [step, setStep] = useState(1); // 1 = credentials, 2 = OTP
  const [tk, setTk] = useState(localStorage.getItem('dk_remember_tk') || '');
  const [mk, setMk] = useState('');
  const [showPw, setShowPw] = useState(false);
  const [remember, setRemember] = useState(true);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState('');
  const [otp, setOtp] = useState(['', '', '', '', '', '']);
  const [otpDemo, setOtpDemo] = useState('');
  const [otpEmail, setOtpEmail] = useState('');
  const [secondsLeft, setSecondsLeft] = useState(0);
  const inputsRef = useRef([]);

  useEffect(() => {
    if (secondsLeft <= 0) return;
    const t = setTimeout(() => setSecondsLeft((s) => s - 1), 1000);
    return () => clearTimeout(t);
  }, [secondsLeft]);

  const guiOtp = async () => {
    setErr('');
    if (!tk || !mk) { setErr('Vui lòng nhập tên đăng nhập và mật khẩu.'); return; }
    setBusy(true);
    try {
      const { data } = await api.post('/auth/otp/gui', { TenDangNhap: tk.trim(), MatKhau: mk });
      setOtpDemo(data.otpDemo || '');
      setOtpEmail(data.emailMasked || '');
      setSecondsLeft(data.expiresInSeconds || 120);
      setOtp(['', '', '', '', '', '']);
      setStep(2);
      toast.success(data.message);
      setTimeout(() => inputsRef.current[0]?.focus(), 100);
    } catch (e) {
      setErr(errMessage(e, 'Đăng nhập thất bại.'));
    } finally {
      setBusy(false);
    }
  };

  const xacThucOtp = async (codeArg) => {
    const code = (codeArg || otp.join(''));
    setErr('');
    if (code.length !== 6) { setErr('OTP gồm 6 chữ số.'); return; }
    setBusy(true);
    try {
      const { data } = await api.post('/auth/otp/xacthuc', { TenDangNhap: tk.trim(), Otp: code });
      if (remember) localStorage.setItem('dk_remember_tk', tk.trim());
      else localStorage.removeItem('dk_remember_tk');
      dispatch(loggedIn({ token: data.token, user: data.user }));
      toast.success(`Chào mừng ${data.user.HoTen}!`);
      setTimeout(() => { window.location.href = '/'; }, 400);
    } catch (e) {
      setErr(errMessage(e, 'Xác thực OTP thất bại.'));
      setOtp(['', '', '', '', '', '']);
      inputsRef.current[0]?.focus();
    } finally {
      setBusy(false);
    }
  };

  const onOtpChange = (i, val) => {
    const d = val.replace(/\D/g, '').slice(-1);
    const next = [...otp];
    next[i] = d;
    setOtp(next);
    if (d && i < 5) inputsRef.current[i + 1]?.focus();
    if (d && i === 5 && next.every(Boolean)) xacThucOtp(next.join(''));
  };

  const onOtpPaste = (e) => {
    e.preventDefault();
    const digits = (e.clipboardData.getData('text') || '').replace(/\D/g, '').slice(0, 6).split('');
    if (digits.length) {
      const next = ['', '', '', '', '', ''];
      digits.forEach((x, k) => { next[k] = x; });
      setOtp(next);
      if (digits.length === 6) xacThucOtp(digits.join(''));
    }
  };

  const mmss = `${String(Math.floor(secondsLeft / 60)).padStart(2, '0')}:${String(secondsLeft % 60).padStart(2, '0')}`;

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
          {step === 1 ? (
            <form onSubmit={(e) => { e.preventDefault(); guiOtp(); }} noValidate>
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
              <TextField fullWidth size="small" label="Mật khẩu" type={showPw ? 'text' : 'password'} value={mk}
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
                {busy ? 'Đang gửi mã OTP...' : 'TIẾP TỤC — GỬI MÃ OTP'}
              </Button>

              <Collapse in={!!otpDemo} />
            </form>
          ) : (
            <Box>
              <Typography variant="h5" align="center" sx={{ textTransform: 'uppercase' }}>Xác thực OTP</Typography>
              <Typography variant="body2" align="center" color="text.secondary" sx={{ mb: 2 }}>
                Mã OTP 6 chữ số đã được gửi tới email trường{otpEmail ? ` (${otpEmail})` : ''}
              </Typography>
              {err && <Alert severity="error" sx={{ mb: 2 }}>{err}</Alert>}
              {otpDemo && (
                <Alert severity="warning" sx={{ mb: 2, textAlign: 'center' }}>
                  🧪 Bản demo (không có email trường) — mã OTP: <b style={{ fontSize: 16, letterSpacing: 4 }}>{otpDemo}</b>
                </Alert>
              )}
              <Stack direction="row" spacing={1} justifyContent="center" sx={{ mb: 1.5 }} onPaste={onOtpPaste}>
                {otp.map((d, i) => (
                  <input
                    key={i}
                    ref={(el) => (inputsRef.current[i] = el)}
                    value={d}
                    onChange={(e) => onOtpChange(i, e.target.value)}
                    onKeyDown={(e) => { if (e.key === 'Backspace' && !otp[i] && i > 0) inputsRef.current[i - 1]?.focus(); }}
                    inputMode="numeric" maxLength={1}
                    style={{
                      width: 46, height: 54, textAlign: 'center', fontSize: 22, fontWeight: 700,
                      border: '1.5px solid #bdbdbd', borderRadius: 10, color: '#006266',
                      fontFamily: 'Montserrat', outline: 'none',
                    }}
                  />
                ))}
              </Stack>
              <Typography variant="body2" align="center" sx={{ mb: 2 }}>
                OTP hết hạn sau <b style={{ color: '#c62828' }}>{mmss}</b>{' · '}
                <Link component="button" type="button" variant="body2" onClick={guiOtp} disabled={busy}>Gửi lại mã</Link>
              </Typography>
              <Button fullWidth variant="contained" size="large" disabled={busy || secondsLeft === 0} onClick={() => xacThucOtp()}>
                {busy ? 'Đang xác thực...' : 'XÁC NHẬN & ĐĂNG NHẬP'}
              </Button>
              <Button fullWidth size="small" startIcon={<ArrowBackIcon />} sx={{ mt: 1.5 }}
                onClick={() => { setStep(1); setErr(''); }}>
                Quay lại đăng nhập
              </Button>
            </Box>
          )}

          <Collapse in={step === 1}>
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
