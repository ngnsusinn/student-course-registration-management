import { useCallback, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box, Grid, Card, CardContent, Typography, Stack, Chip, Button, Table, TableBody,
  TableCell, TableContainer, TableHead, TableRow, Alert, Skeleton, Avatar,
} from '@mui/material';
import { alpha } from '@mui/material/styles';
import CelebrationIcon from '@mui/icons-material/Celebration';
import RateReviewIcon from '@mui/icons-material/RateReview';
import EventNoteIcon from '@mui/icons-material/EventNote';
import SchoolIcon from '@mui/icons-material/School';
import PaymentsIcon from '@mui/icons-material/Payments';
import GroupsIcon from '@mui/icons-material/Groups';
import AddBoxIcon from '@mui/icons-material/AddBox';
import KeyIcon from '@mui/icons-material/Key';
import DashboardIcon from '@mui/icons-material/Dashboard';
import { toast } from 'react-toastify';
import api, { errMessage } from '../api/client';
import { SiSoChip } from '../components/StatusBadges';
import { thuName, DK_ERRORS } from '../utils/format';
import { TEAL, TEAL_DARKER } from '../theme';

// ============================================================
// Dashboard — noi dung theo vai tro (SV/GV/PDT), bo cuc kieu
// portal: Thong tin SV | Lich hoc trong tuan | KQHT | Thong bao
// ============================================================
const SectionCard = ({ title, action, children }) => (
  <Card sx={{ mb: 2.5 }}>
    <CardContent>
      <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 1.5, flexWrap: 'wrap', gap: 1 }}>
        <Typography variant="h6" sx={{ display: 'flex', alignItems: 'center', gap: 1, '&::before': {
          content: '""', width: 4, height: 18, bgcolor: TEAL, borderRadius: 1, display: 'inline-block',
        } }}>
          {title}
        </Typography>
        {action}
      </Stack>
      {children}
    </CardContent>
  </Card>
);

const StatBox = ({ value, label }) => (
  <Box sx={{ border: '1px solid #e5e7eb', borderLeft: `4px solid ${TEAL}`, borderRadius: 1.5, p: 1.75, bgcolor: '#fff' }}>
    <Typography sx={{ fontFamily: 'Montserrat', fontWeight: 800, fontSize: 24, color: TEAL_DARKER }}>{value}</Typography>
    <Typography variant="body2" color="text.secondary">{label}</Typography>
  </Box>
);

const QuickTile = ({ to, icon: Icon, label, navigate }) => (
  <Card
    onClick={() => navigate(to)}
    sx={{ cursor: 'pointer', textAlign: 'center', py: 2, px: 1, transition: 'all .2s',
      '&:hover': { borderColor: TEAL, transform: 'translateY(-2px)', boxShadow: `0 6px 18px ${alpha(TEAL, .18)}` } }}
  >
    <Icon sx={{ fontSize: 28, color: TEAL, mb: 0.5 }} />
    <Typography sx={{ fontFamily: 'Montserrat', fontWeight: 600, fontSize: 13, color: TEAL_DARKER }}>{label}</Typography>
  </Card>
);

export default function Dashboard({ role }) {
  const navigate = useNavigate();
  if (role === 'GV') return <DashboardGV navigate={navigate} />;
  if (role === 'PĐT') return <DashboardPDT navigate={navigate} />;
  return <DashboardSV navigate={navigate} />;
}

// ====================== SINH VIEN ======================
function DashboardSV({ navigate }) {
  const [hoSo, setHoSo] = useState(null);
  const [lopMo, setLopMo] = useState([]);
  const [dangKySet, setDangKySet] = useState(new Set());
  const [tkb, setTkb] = useState([]);
  const [cpa, setCpa] = useState(null);
  const [hocKy, setHocKy] = useState(null);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [hs, hk, lm, ds, tk, cp] = await Promise.all([
        api.get('/auth/hoso'),
        api.get('/dangky/hocky-hientai'),
        api.get('/dangky/lopmo'),
        api.get('/dangky/danhsach'),
        api.get('/dangky/thoikhoabieu'),
        api.get('/ketqua/cpa').catch(() => null),
      ]);
      setHoSo(hs.data.hoSo);
      setHocKy(hk.data.hocKy);
      setLopMo(lm.data.lopHocPhan || []);
      setDangKySet(new Set((ds.data.danhSach || []).filter(x => x.TrangThaiDangKy === 'DA_DANG_KY').map(x => x.MaLHP)));
      setTkb(tk.data.thoiKhoaBieu || []);
      if (cp) setCpa(cp.data.cpa);
    } catch (e) {
      toast.error(errMessage(e, 'Không tải được dữ liệu.'));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  const dangKy = async (MaLHP) => {
    try {
      const { data } = await api.post('/dangky', { MaLHP });
      toast.success(`✅ ${data.message} — ${MaLHP}`);
      load();
    } catch (e) {
      const code = e.response?.data?.ketQua;
      toast.error(DK_ERRORS[code] || errMessage(e));
    }
  };

  const isBirthday = (() => {
    if (!hoSo?.NgaySinh) return false;
    const ns = new Date(hoSo.NgaySinh), now = new Date();
    return ns.getDate() === now.getDate() && ns.getMonth() === now.getMonth();
  })();

  const infoRows = hoSo ? [
    ['Họ tên:', hoSo.HoTen], ['MSSV:', hoSo.MaSV],
    ['Ngày sinh:', hoSo.NgaySinh], ['Giới tính:', Number(hoSo.GioiTinh) === 1 ? 'Nam' : 'Nữ'],
    ['Lớp SH:', `${hoSo.TenLopSH}`], ['Ngành:', hoSo.TenNganh],
    ['Khoa:', hoSo.TenKhoa], ['Khóa học:', hoSo.NienKhoa],
    ['Email:', hoSo.Email], ['Điện thoại:', hoSo.SoDienThoai || '—'],
    ['Nơi sinh:', hoSo.QueQuan || 'Chưa cập nhật'],
    ['Trạng thái:', Number(hoSo.TrangThaiHoc) === 1 ? 'Đang học' : 'Nghỉ học'],
  ] : [];

  const days = [2, 3, 4, 5, 6, 7, 8];
  const byDay = {};
  for (const c of tkb) (byDay[c.Thu] = byDay[c.Thu] || []).push(c);

  const notices = [];
  if (hocKy) {
    notices.push({ t: `Đợt đăng ký ${hocKy.TenHocKy} ${hocKy.NamHoc} đang mở`, s: `Thời gian: ${hocKy.TuNgay} → ${hocKy.DenNgay}. Sinh viên chủ động đăng ký đúng hạn.` });
    notices.push({ t: 'Hủy đăng ký chỉ thực hiện được trong thời gian quy định', s: 'Ngoài hạn, mọi điều chỉnh phải qua Phòng Đào tạo.' });
  } else {
    notices.push({ t: 'Đợt đăng ký học phần đã đóng', s: 'Theo dõi thông báo đợt kế tiếp trên cổng thông tin.' });
  }
  notices.push({ t: 'Học phí học kỳ', s: 'Xem chi tiết và tình trạng nộp tại mục Học phí. Nợ học phí sẽ bị tạm ĐK kỳ sau.' });

  return (
    <Box>
      {isBirthday && (
        <Alert severity="info" icon={false} sx={{
          mb: 2.5, borderRadius: 2.5, fontWeight: 600, color: '#b02a63',
          background: 'linear-gradient(90deg,#ffe3ef,#fff0f6)', border: '1px solid #ffc6dd',
        }}>
          <CelebrationIcon sx={{ verticalAlign: 'middle', mr: 1 }} />
          Chúc mừng sinh nhật <b>{hoSo?.HoTen}</b>! Nhà trường chúc bạn một ngày thật vui vẻ! 🎈
        </Alert>
      )}

      <Grid container spacing={2.5}>
        <Grid item xs={12} md={7}>
          <SectionCard title="Thông tin sinh viên" action={<Chip label={`MSSV: ${hoSo?.MaSV || '—'}`} color="primary" size="small" />}>
            {loading ? <Skeleton height={180} /> : (
              <Grid container>
                {infoRows.map(([k, v]) => (
                  <Grid item xs={12} sm={6} key={k}>
                    <Stack direction="row" spacing={1} sx={{ py: 0.5, borderBottom: '1px dashed #eef2f2', fontSize: 14 }}>
                      <Typography color="text.secondary" sx={{ minWidth: 100 }}>{k}</Typography>
                      <Typography sx={{ fontWeight: 500 }}>{v ?? '—'}</Typography>
                    </Stack>
                  </Grid>
                ))}
              </Grid>
            )}
            <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
              ⚠️ Sinh viên vui lòng cập nhật thông tin cá nhân (Nơi sinh, CCCD, SĐT...) khi có thay đổi — liên hệ Phòng Đào tạo.
            </Typography>
          </SectionCard>

          <SectionCard title="Lịch học trong tuần" action={<Button size="small" variant="outlined" onClick={() => navigate('/thoi-khoa-bieu')}>Xem cả học kỳ →</Button>}>
            <Grid container spacing={1}>
              {days.map((d) => (
                <Grid item xs={6} sm={3} md={12 / 7} key={d} sx={{ minWidth: 110 }}>
                  <Box sx={{ border: '1px solid #e5e7eb', borderRadius: 1.5, overflow: 'hidden', minHeight: 120, bgcolor: '#fff' }}>
                    <Typography sx={{ bgcolor: '#e0f2f2', color: TEAL_DARKER, fontFamily: 'Montserrat', fontWeight: 700, fontSize: 11.5, textAlign: 'center', py: 0.5, textTransform: 'uppercase' }}>
                      {thuName(d).replace('Thứ ', 'T.')}
                    </Typography>
                    {(byDay[d] || []).sort((a, b) => a.TietBatDau - b.TietBatDau).map((c, i) => (
                      <Box key={i} sx={{ p: 0.75, borderBottom: '1px dashed #f0f0f0', fontSize: 11 }}>
                        <Typography sx={{ fontWeight: 700, fontSize: 11.5, color: TEAL_DARKER }}>{c.TenMonHoc}</Typography>
                        <Typography variant="caption" color="text.secondary" display="block">
                          Tiết {c.TietBatDau}–{Number(c.TietBatDau) + Number(c.SoTiet) - 1} · {c.TenPhong}
                        </Typography>
                        <Typography variant="caption" color="text.secondary" display="block">{c.HoTenGV}</Typography>
                      </Box>
                    ))}
                    {!(byDay[d] || []).length && (
                      <Typography variant="caption" color="text.disabled" sx={{ display: 'block', textAlign: 'center', py: 2 }}>[Rỗng]</Typography>
                    )}
                  </Box>
                </Grid>
              ))}
            </Grid>
          </SectionCard>

          <SectionCard
            title="Học phần đang mở đăng ký"
            action={<Chip size="small" color={hocKy ? 'success' : 'error'} label={hocKy ? `Đợt ${hocKy.MaHocKy} đang mở — hạn ${hocKy.DenNgay}` : 'Đợt đã đóng'} />}
          >
            <TableContainer>
              <Table size="small">
                <TableHead>
                  <TableRow><TableCell>Mã LHP</TableCell><TableCell>Môn học</TableCell><TableCell>TC</TableCell><TableCell>Sĩ số</TableCell><TableCell>Giảng viên</TableCell><TableCell align="right">Thao tác</TableCell></TableRow>
                </TableHead>
                <TableBody>
                  {lopMo.map((c) => {
                    const daDk = dangKySet.has(c.MaLHP);
                    const hetCho = Number(c.SiSoHienTai) >= Number(c.SiSoToiDa);
                    return (
                      <TableRow key={c.MaLHP} hover>
                        <TableCell><code>{c.MaLHP}</code></TableCell>
                        <TableCell>{c.TenMonHoc}</TableCell>
                        <TableCell>{c.SoTinChi}</TableCell>
                        <TableCell><SiSoChip hienTai={c.SiSoHienTai} toiDa={c.SiSoToiDa} /></TableCell>
                        <TableCell>{c.TenGV || '—'}</TableCell>
                        <TableCell align="right">
                          {daDk ? <Chip size="small" color="success" label="Đã đăng ký" />
                            : <Button size="small" variant="contained" color={hetCho ? 'info' : 'success'} disabled={hetCho} onClick={() => dangKy(c.MaLHP)}>
                                {hetCho ? 'Hết chỗ' : 'Đăng ký'}
                              </Button>}
                        </TableCell>
                      </TableRow>
                    );
                  })}
                  {!loading && !lopMo.length && (
                    <TableRow><TableCell colSpan={6} align="center" sx={{ color: 'text.disabled', py: 3 }}>Không có học phần đang mở</TableCell></TableRow>
                  )}
                </TableBody>
              </Table>
            </TableContainer>
          </SectionCard>
        </Grid>

        <Grid item xs={12} md={5}>
          <SectionCard title="Kết quả học tập">
            <Grid container spacing={1.5}>
              <Grid item xs={6}><StatBox value={cpa ? Number(cpa.CPA_TichLuy || 0).toFixed(2) : '—'} label="CPA tích lũy (hệ 4)" /></Grid>
              <Grid item xs={6}><StatBox value={cpa?.TongTinChiTichLuy ?? '—'} label="Tín chỉ tích lũy" /></Grid>
            </Grid>
            {cpa && (
              <Stack spacing={1} sx={{ mt: 1.5 }}>
                <div>Xếp loại tích lũy: <Chip size="small" label={cpa.XepLoaiTichLuy || '—'} /></div>
                {cpa.TrangThaiCanhBaoHocVu && cpa.TrangThaiCanhBaoHocVu !== 'Bình thường' && (
                  <Alert severity="warning" sx={{ py: 0.5 }}>⚠️ Cảnh báo học vụ: {cpa.TrangThaiCanhBaoHocVu}</Alert>
                )}
                <Button size="small" onClick={() => navigate('/bang-diem')}>Xem bảng điểm học tập →</Button>
              </Stack>
            )}
          </SectionCard>

          <SectionCard title="Thông báo / sự kiện">
            {notices.map((n, i) => (
              <Stack key={i} direction="row" spacing={1.25} sx={{ py: 1, borderBottom: i < notices.length - 1 ? '1px dashed #eef2f2' : 0 }}>
                <Avatar sx={{ width: 9, height: 9, bgcolor: TEAL, mt: 0.75, flex: 'none' }} />
                <Box>
                  <Typography sx={{ fontWeight: 600, fontSize: 14 }}>{n.t}</Typography>
                  <Typography variant="caption" color="text.secondary">{n.s}</Typography>
                </Box>
              </Stack>
            ))}
          </SectionCard>

          <SectionCard title="Tiện ích nhanh">
            <Grid container spacing={1.5}>
              <Grid item xs={6}><QuickTile navigate={navigate} to="/dang-ky" icon={RateReviewIcon} label="Đăng ký học phần" /></Grid>
              <Grid item xs={6}><QuickTile navigate={navigate} to="/thoi-khoa-bieu" icon={EventNoteIcon} label="Thời khóa biểu" /></Grid>
              <Grid item xs={6}><QuickTile navigate={navigate} to="/bang-diem" icon={SchoolIcon} label="Kết quả học tập" /></Grid>
              <Grid item xs={6}><QuickTile navigate={navigate} to="/hoc-phi" icon={PaymentsIcon} label="Học phí" /></Grid>
            </Grid>
          </SectionCard>
        </Grid>
      </Grid>
    </Box>
  );
}

// ====================== GIANG VIEN ======================
function DashboardGV({ navigate }) {
  const [lop, setLop] = useState([]);
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    api.get('/giangvien/lopcuatoi')
      .then(({ data }) => setLop(data.lop || []))
      .catch((e) => toast.error(errMessage(e)))
      .finally(() => setLoading(false));
  }, []);

  return (
    <Box>
      <SectionCard title="Tổng quan giảng viên">
        <Grid container spacing={1.5}>
          <Grid item xs={6} sm={3}><StatBox value={loading ? '…' : lop.length} label="Lớp học phần phụ trách" /></Grid>
          <Grid item xs={6} sm={3}><StatBox value={lop.reduce((s, x) => s + Number(x.SiSoHienTai || 0), 0)} label="Tổng SV trong lớp" /></Grid>
          <Grid item xs={6} sm={3}><StatBox value={new Set(lop.map(x => x.MaHocKy)).size} label="Học kỳ có lớp" /></Grid>
          <Grid item xs={6} sm={3}><StatBox value={lop.filter(x => x.TrangThaiLop === 'MO_DANG_KY').length} label="Lớp đang mở ĐK" /></Grid>
        </Grid>
      </SectionCard>
      <SectionCard title="Tiện ích nhanh">
        <Grid container spacing={1.5}>
          <Grid item xs={6} md={3}><QuickTile navigate={navigate} to="/lop-cua-toi" icon={GroupsIcon} label="Lớp của tôi" /></Grid>
          <Grid item xs={6} md={3}><QuickTile navigate={navigate} to="/nhap-diem" icon={RateReviewIcon} label="Nhập điểm" /></Grid>
          <Grid item xs={6} md={3}><QuickTile navigate={navigate} to="/thoi-khoa-bieu-gv" icon={EventNoteIcon} label="Thời khóa biểu" /></Grid>
        </Grid>
      </SectionCard>
    </Box>
  );
}

// ====================== PHONG DAO TAO ======================
function DashboardPDT({ navigate }) {
  const [st, setSt] = useState(null);
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    api.get('/admin/thongke')
      .then(({ data }) => setSt(data.tongHop))
      .catch((e) => toast.error(errMessage(e)))
      .finally(() => setLoading(false));
  }, []);

  const items = st ? [
    [st.SvDangHoc, 'Sinh viên đang học'], [st.TongGiangVien, 'Giảng viên'],
    [st.TongMonHoc, 'Môn học'], [st.TongLopHocPhan, 'Lớp học phần'],
    [st.LopDangMo, 'Lớp đang mở ĐK'], [st.TongDangKyHieuLuc, 'Lượt ĐK hiệu lực'],
    [st.TongTaiKhoan, 'Tài khoản'], [st.TongSinhVien, 'Tổng SV (mọi trạng thái)'],
  ] : [];

  return (
    <Box>
      <SectionCard title="Bảng điều hành — Phòng Đào tạo">
        <Grid container spacing={1.5}>
          {items.map(([v, l]) => (
            <Grid item xs={6} sm={3} key={l}><StatBox value={loading ? '…' : v} label={l} /></Grid>
          ))}
        </Grid>
      </SectionCard>
      <SectionCard title="Tiện ích nhanh">
        <Grid container spacing={1.5}>
          <Grid item xs={6} md={2.4}><QuickTile navigate={navigate} to="/quan-ly/sinh-vien" icon={GroupsIcon} label="Quản lý SV" /></Grid>
          <Grid item xs={6} md={2.4}><QuickTile navigate={navigate} to="/quan-ly/mo-lhp" icon={AddBoxIcon} label="Mở LHP" /></Grid>
          <Grid item xs={6} md={2.4}><QuickTile navigate={navigate} to="/quan-ly/diem-canh-bao" icon={DashboardIcon} label="Điểm & Cảnh báo" /></Grid>
          <Grid item xs={6} md={2.4}><QuickTile navigate={navigate} to="/quan-ly/hoc-phi" icon={PaymentsIcon} label="Học phí" /></Grid>
          <Grid item xs={6} md={2.4}><QuickTile navigate={navigate} to="/quan-ly/tai-khoan" icon={KeyIcon} label="Tài khoản" /></Grid>
        </Grid>
      </SectionCard>
    </Box>
  );
}
