import { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { Link as RouterLink, NavLink, useLocation } from 'react-router-dom';
import {
  Box, Container, Typography, Avatar, Button, Chip, Breadcrumbs, Stack, Link,
} from '@mui/material';
import { alpha } from '@mui/material/styles';
import LogoutIcon from '@mui/icons-material/Logout';
import LockResetIcon from '@mui/icons-material/LockReset';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import EmailIcon from '@mui/icons-material/Email';
import NavigateNextIcon from '@mui/icons-material/NavigateNext';
import { selectUser, loggedOut } from '../store/authSlice';
import { menuFor, CRUMB_LABELS } from '../config/menu';
import { tenVietTat } from '../utils/format';
import { TEAL, TEAL_DEEP, TEAL_DARKER } from '../theme';
import ChangePasswordDialog from './ChangePasswordDialog';

// ============================================================
// PortalLayout — topbar + header trắng (logo trường) + thanh
// menu teal + breadcrumb + footer 3 cột. Nhận diện như portal.
// ============================================================
export const SCHOOL = {
  name: 'TRƯỜNG ĐẠI HỌC GIAO THÔNG VẬN TẢI TP. HỒ CHÍ MINH',
  short: 'UTH',
  system: 'Cổng thông tin Đào tạo theo hệ thống tín chỉ',
  logo: '/images/logo_full.png',
  email: 'phongdaotao@uth.edu.vn',
  hours: 'Thứ 2 – Thứ 6: 07:30 – 16:30',
};

function Clock() {
  const [now, setNow] = useState(new Date());
  useEffect(() => {
    const t = setInterval(() => setNow(new Date()), 1000);
    return () => clearInterval(t);
  }, []);
  let d = new Intl.DateTimeFormat('vi-VN', { weekday: 'long', day: '2-digit', month: '2-digit', year: 'numeric' }).format(now);
  d = d.charAt(0).toUpperCase() + d.slice(1);
  const hhmmss = now.toLocaleTimeString('vi-VN', { hour12: false });
  return <span style={{ fontVariantNumeric: 'tabular-nums' }}>🕐 {d} · {hhmmss}</span>;
}

export default function PortalLayout({ children }) {
  const user = useSelector(selectUser);
  const dispatch = useDispatch();
  const location = useLocation();
  const [openDmk, setOpenDmk] = useState(false);
  const role = user?.MaVaiTro || 'SV';
  const menu = menuFor(role);

  const logout = () => {
    dispatch(loggedOut());
    window.location.href = '/login';
  };

  const crumbs = (() => {
    const path = location.pathname;
    if (path === '/') return null;
    return (
      <Breadcrumbs separator={<NavigateNextIcon fontSize="small" />} sx={{ mb: 2 }}>
        <Link component={RouterLink} to="/" color="primary" sx={{ textDecoration: 'none', fontSize: 13 }}>
          🏠 Trang chủ
        </Link>
        <Typography variant="body2" sx={{ color: 'text.primary', fontWeight: 600 }}>
          {CRUMB_LABELS[path] || 'Trang'}
        </Typography>
      </Breadcrumbs>
    );
  })();

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', minHeight: '100vh', bgcolor: 'background.default' }}>
      {/* ===== Topbar ===== */}
      <Box sx={{ bgcolor: TEAL_DEEP, color: '#d8efef', fontSize: 12.5 }}>
        <Container maxWidth="lg" sx={{ py: 0.5, display: 'flex', justifyContent: 'space-between', gap: 2, flexWrap: 'wrap' }}>
          <Stack direction="row" spacing={1} alignItems="center" fontWeight={600}>
            <Box component="img" src={SCHOOL.logo} alt="logo" sx={{ height: 18 }} />
            <span>{SCHOOL.name} — {SCHOOL.system}</span>
          </Stack>
          <Stack direction="row" spacing={2.5} alignItems="center" sx={{ display: { xs: 'none', md: 'flex' } }}>
            <Clock />
            <span><EmailIcon sx={{ fontSize: 14, verticalAlign: 'middle', mr: 0.5 }} />{SCHOOL.email}</span>
          </Stack>
        </Container>
      </Box>

      {/* ===== Header trắng ===== */}
      <Box sx={{ bgcolor: 'background.paper', borderBottom: '1px solid #e5e7eb' }}>
        <Container maxWidth="lg" sx={{ py: 1.2, display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 2, flexWrap: 'wrap' }}>
          <Stack direction="row" spacing={1.75} alignItems="center" sx={{ minWidth: 0 }}>
            <Box component="img" src={SCHOOL.logo} alt="Logo UTH" sx={{ height: { xs: 44, md: 54 } }} />
            <Box sx={{ minWidth: 0 }}>
              <Typography sx={{ fontFamily: 'Montserrat', fontWeight: 800, fontSize: { xs: 12.5, md: 15 }, color: TEAL_DARKER, textTransform: 'uppercase', lineHeight: 1.25 }}>
                {SCHOOL.name}
              </Typography>
              <Typography sx={{ fontSize: 13, color: 'text.secondary' }}>{SCHOOL.system}</Typography>
            </Box>
          </Stack>

          {user ? (
            <Stack direction="row" spacing={1.25} alignItems="center">
              <Avatar sx={{ bgcolor: TEAL, fontFamily: 'Montserrat', fontWeight: 700, width: 40, height: 40, boxShadow: `0 0 0 3px ${alpha(TEAL, 0.15)}` }}>
                {tenVietTat(user.HoTen)}
              </Avatar>
              <Box sx={{ display: { xs: 'none', sm: 'block' }, lineHeight: 1.2 }}>
                <Typography sx={{ fontSize: 14, fontWeight: 600 }}>{user.HoTen || user.TenDangNhap}</Typography>
                <Typography sx={{ fontSize: 12, color: 'text.secondary' }}>
                  {user.TenVaiTro || user.MaVaiTro} · {user.TenDangNhap}
                </Typography>
              </Box>
              <Button size="small" variant="outlined" startIcon={<LockResetIcon />} onClick={() => setOpenDmk(true)}>
                Đổi mật khẩu
              </Button>
              <Button size="small" variant="contained" startIcon={<LogoutIcon />} onClick={logout}>
                Đăng xuất
              </Button>
            </Stack>
          ) : (
            <Button variant="contained" component={RouterLink} to="/login">Đăng nhập</Button>
          )}
        </Container>
      </Box>

      {/* ===== Thanh menu teal ===== */}
      <Box sx={{ bgcolor: TEAL, position: 'sticky', top: 0, zIndex: 1100, boxShadow: '0 2px 6px rgba(0,134,137,.35)' }}>
        <Container maxWidth="lg" sx={{ display: 'flex', overflowX: 'auto', '&::-webkit-scrollbar': { display: 'none' } }}>
          {menu.map((m) => (
            <NavLink
              key={m.to}
              to={m.to}
              end={m.to === '/'}
              style={({ isActive }) => ({
                display: 'flex', alignItems: 'center', gap: 7, padding: '11px 14px',
                fontSize: 13.5, whiteSpace: 'nowrap', textDecoration: 'none',
                color: '#fff', fontWeight: isActive ? 700 : 500,
                background: isActive ? 'rgba(0,0,0,.18)' : 'transparent',
                borderBottom: isActive ? '3px solid #ffd54f' : '3px solid transparent',
              })}
            >
              <m.icon sx={{ fontSize: 16 }} />
              {m.label}
            </NavLink>
          ))}
        </Container>
      </Box>

      {/* ===== Nội dung ===== */}
      <Container maxWidth="lg" component="main" sx={{ py: 2.5, flex: 1 }}>
        {crumbs}
        {children}
      </Container>

      {/* ===== Footer ===== */}
      <Box component="footer" sx={{ bgcolor: TEAL_DEEP, color: '#cfe7e7', fontSize: 13, mt: 'auto' }}>
        <Container maxWidth="lg" sx={{ py: 3, display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1.4fr 1fr 1fr' }, gap: 4 }}>
          <Box>
            <Stack direction="row" spacing={1.5} alignItems="center" sx={{ mb: 1 }}>
              <Box component="img" src={SCHOOL.logo} alt="logo" sx={{ height: 40, bgcolor: '#fff', borderRadius: 1.5, p: 0.4 }} />
              <Box>
                <Typography sx={{ color: '#fff', fontFamily: 'Montserrat', fontWeight: 700, fontSize: 13, textTransform: 'uppercase' }}>
                  {SCHOOL.name}
                </Typography>
                <Typography variant="caption">{SCHOOL.system}</Typography>
              </Box>
            </Stack>
            <Typography variant="body2">✉ {SCHOOL.email}</Typography>
          </Box>
          <Box>
            <Typography sx={{ color: '#fff', fontFamily: 'Montserrat', fontWeight: 700, fontSize: 13, textTransform: 'uppercase', mb: 1 }}>
              Liên kết nhanh
            </Typography>
            {menu.slice(0, 5).map((m) => (
              <Link key={m.to} component={RouterLink} to={m.to} sx={{ display: 'block', color: '#cfe7e7', textDecoration: 'none', py: 0.25, '&:hover': { color: '#fff', textDecoration: 'underline' } }}>
                {m.label}
              </Link>
            ))}
          </Box>
          <Box>
            <Typography sx={{ color: '#fff', fontFamily: 'Montserrat', fontWeight: 700, fontSize: 13, textTransform: 'uppercase', mb: 1 }}>
              Hỗ trợ người học
            </Typography>
            <Typography variant="body2">🕗 {SCHOOL.hours}</Typography>
            <Typography variant="body2">Khiếu nại học vụ: liên hệ Phòng Đào tạo</Typography>
          </Box>
        </Container>
        <Box sx={{ borderTop: '1px solid rgba(255,255,255,.15)', py: 1.5, textAlign: 'center', fontSize: 12.5, color: '#a9cccc' }}>
          © {new Date().getFullYear()} {SCHOOL.short} — {SCHOOL.system}. Bản demo đồ án môn học (dữ liệu mẫu) · Nhóm 5 — Đề tài 6 · v2.0 (React)
        </Box>
      </Box>

      <ChangePasswordDialog open={openDmk} onClose={() => setOpenDmk(false)} />
    </Box>
  );
}
