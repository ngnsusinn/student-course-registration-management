import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Box, Stack, ToggleButton, ToggleButtonGroup, TextField, InputAdornment, MenuItem,
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Button, Chip,
  Typography, CircularProgress,
} from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';
import FileDownloadIcon from '@mui/icons-material/FileDownload';
import { toast } from 'react-toastify';
import api, { errMessage } from '../../api/client';
import { SectionCard } from '../../components/SectionCard';
import { SiSoChip, StatusChip } from '../../components/StatusBadges';
import ConfirmDialog from '../../components/ConfirmDialog';
import { DK_ERRORS, HUY_ERRORS, thuName } from '../../utils/format';
import { xuatExcel } from '../../utils/export';

// ============================================================
// DANG KY HOC PHAN — "Hoc phan dang cho dang ky" +
// "Hoc phan da dang ky trong hoc ky nay" (mau portal)
// ============================================================
const LOAI_LABEL = { HOC_MOI: 'Đăng ký mới', HOC_LAI: 'Học lại', CAI_THIEN: 'Cải thiện' };

function renderLich(str) {
  if (!str) return '—';
  return String(str).split('; ').map((p, i) => {
    const m = p.match(/^(\d+):(\d+)-(\d+)@?(.*)$/);
    if (!m) return p;
    return `${thuName(Number(m[1]))} tiết ${m[2]}–${m[3]}${m[4] ? ' · ' + m[4] : ''}`;
  }).join('; ');
}

export default function DangKyHocPhan() {
  const [loai, setLoai] = useState('HOC_MOI');
  const [hocKy, setHocKy] = useState(null);
  const [lopMo, setLopMo] = useState([]);
  const [dangKy, setDangKy] = useState([]);
  const [tongTC, setTongTC] = useState(0);
  const [tim, setTim] = useState('');
  const [loading, setLoading] = useState(true);
  const [busyCode, setBusyCode] = useState(null);
  const [huyTarget, setHuyTarget] = useState(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [hk, lm, ds, tc] = await Promise.all([
        api.get('/dangky/hocky-hientai'),
        api.get('/dangky/lopmo'),
        api.get('/dangky/danhsach'),
        api.get('/dangky/tongtinchi'),
      ]);
      setHocKy(hk.data.hocKy);
      setLopMo(lm.data.lopHocPhan || []);
      setDangKy((ds.data.danhSach || []).filter(x => hk.data.hocKy && x.MaHocKy === hk.data.hocKy.MaHocKy));
      setTongTC(Number(tc.data.tongTinChi || 0));
    } catch (e) {
      toast.error(errMessage(e, 'Không tải được danh sách học phần.'));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  const filtered = useMemo(() => lopMo.filter(c =>
    !tim || c.MaLHP.toLowerCase().includes(tim.toLowerCase()) || (c.TenMonHoc || '').toLowerCase().includes(tim.toLowerCase())
  ), [lopMo, tim]);

  const daDangKySet = useMemo(() => new Set(dangKy.filter(d => d.TrangThaiDangKy === 'DA_DANG_KY').map(d => d.MaLHP)), [dangKy]);

  const submit = async (MaLHP) => {
    setBusyCode(MaLHP);
    try {
      const { data } = await api.post('/dangky', { MaLHP, MaxTinChi: 24, GhiChu: LOAI_LABEL[loai] });
      toast.success(`✅ ${data.message} — ${MaLHP} (${LOAI_LABEL[loai]})`);
      await load();
    } catch (e) {
      const code = e.response?.data?.ketQua;
      toast.error(DK_ERRORS[code] || errMessage(e));
    } finally {
      setBusyCode(null);
    }
  };

  const huy = async () => {
    if (!huyTarget) return;
    setBusyCode(huyTarget.MaLHP);
    try {
      const { data } = await api.post('/dangky/huy', { MaLHP: huyTarget.MaLHP });
      toast.success(`✅ ${data.message}`);
      setHuyTarget(null);
      await load();
    } catch (e) {
      const code = e.response?.data?.ketQua;
      toast.error(HUY_ERRORS[code] || errMessage(e));
    } finally {
      setBusyCode(null);
    }
  };

  return (
    <Box>
      <SectionCard
        title="Học phần đang chờ đăng ký"
        action={
          <Stack direction="row" spacing={1} alignItems="center">
            <Chip size="small" color={hocKy ? 'success' : 'error'}
              label={hocKy ? `Đợt ${hocKy.MaHocKy} đang mở — hạn ${hocKy.DenNgay}` : 'Đợt đã đóng'} />
            <Chip size="small" color="primary" label={`${tongTC}/24 TC`} />
            <Button size="small" variant="outlined" startIcon={<FileDownloadIcon />}
              onClick={() => xuatExcel('Dang-ky-lop-hoc-phan', [
                { header: 'Mã LHP', key: 'MaLHP' }, { header: 'Tên môn học', key: 'TenMonHoc' },
                { header: 'Số tín chỉ', key: 'SoTinChi' }, { header: 'Lịch học', value: (r) => renderLich(r.LichHoc) },
                { header: 'SS hiện tại', key: 'SiSoHienTai' }, { header: 'SS tối đa', key: 'SiSoToiDa' },
                { header: 'GV dự kiến', key: 'TenGV' },
              ], filtered)}>Xuất Excel</Button>
          </Stack>
        }
      >
        <Stack direction="row" spacing={2} alignItems="center" sx={{ mb: 2, flexWrap: 'wrap', gap: 1.5 }}>
          <ToggleButtonGroup size="small" exclusive value={loai} onChange={(e, v) => v && setLoai(v)}>
            {Object.entries(LOAI_LABEL).map(([k, v]) => <ToggleButton key={k} value={k}>{v}</ToggleButton>)}
          </ToggleButtonGroup>
          <TextField size="small" placeholder="🔍 Tìm theo mã lớp / môn học..." value={tim}
            onChange={(e) => setTim(e.target.value)} sx={{ minWidth: 280 }}
            InputProps={{ startAdornment: <InputAdornment position="start"><SearchIcon fontSize="small" /></InputAdornment> }} />
        </Stack>

        {loading ? <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}><CircularProgress /></Box> : (
          <TableContainer>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>Mã LHP</TableCell><TableCell>Tên môn học</TableCell><TableCell align="center">Tín chỉ</TableCell>
                  <TableCell>Lịch học</TableCell><TableCell align="center">SS tối đa</TableCell><TableCell>GV dự kiến</TableCell>
                  <TableCell align="right">Thao tác</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {filtered.map((c) => {
                  const dk = daDangKySet.has(c.MaLHP);
                  const hetCho = Number(c.SiSoHienTai) >= Number(c.SiSoToiDa);
                  return (
                    <TableRow key={c.MaLHP} hover>
                      <TableCell><code>{c.MaLHP}</code></TableCell>
                      <TableCell>{c.TenMonHoc}</TableCell>
                      <TableCell align="center">{c.SoTinChi}</TableCell>
                      <TableCell sx={{ fontSize: 12.5 }}>{renderLich(c.LichHoc)}</TableCell>
                      <TableCell align="center"><SiSoChip hienTai={c.SiSoHienTai} toiDa={c.SiSoToiDa} /></TableCell>
                      <TableCell>{c.TenGV || '—'}</TableCell>
                      <TableCell align="right">
                        {dk ? <Chip size="small" color="success" label="Đã đăng ký" /> : (
                          <Button size="small" variant="contained" color="success" disabled={hetCho || busyCode === c.MaLHP}
                            onClick={() => submit(c.MaLHP)}>
                            {busyCode === c.MaLHP ? '...' : hetCho ? 'Hết chỗ' : 'Đăng ký'}
                          </Button>
                        )}
                      </TableCell>
                    </TableRow>
                  );
                })}
                {!filtered.length && (
                  <TableRow><TableCell colSpan={7} align="center" sx={{ color: 'text.disabled', py: 3 }}>Không có dữ liệu</TableCell></TableRow>
                )}
              </TableBody>
            </Table>
          </TableContainer>
        )}
        <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
          Hệ thống kiểm tra 5 ràng buộc: hạn đăng ký · môn tiên quyết · trùng lịch · min–max tín chỉ · sĩ số (Stored Procedure).
        </Typography>
      </SectionCard>

      <SectionCard title="Học phần đã đăng ký trong học kỳ này"
        action={<Chip size="small" color="primary" label={`${dangKy.filter(d => d.TrangThaiDangKy === 'DA_DANG_KY').length} lớp`} />}>
        <TableContainer>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Mã LHP</TableCell><TableCell>Tên môn học</TableCell><TableCell align="center">Tín chỉ</TableCell>
                <TableCell>Ngày đăng ký</TableCell><TableCell>Trạng thái ĐK</TableCell><TableCell align="right">Thao tác</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {dangKy.map((d) => (
                <TableRow key={d.MaLHP}>
                  <TableCell><code>{d.MaLHP}</code></TableCell>
                  <TableCell>{d.TenMonHoc}</TableCell>
                  <TableCell align="center">{d.SoTinChi}</TableCell>
                  <TableCell>{d.NgayDangKy}</TableCell>
                  <TableCell><StatusChip group="DK" code={d.TrangThaiDangKy} /></TableCell>
                  <TableCell align="right">
                    {d.TrangThaiDangKy === 'DA_DANG_KY' && (
                      <Button size="small" color="error" variant="outlined" onClick={() => setHuyTarget(d)}>Hủy</Button>
                    )}
                  </TableCell>
                </TableRow>
              ))}
              {!loading && !dangKy.length && (
                <TableRow><TableCell colSpan={6} align="center" sx={{ color: 'text.disabled', py: 3 }}>Bạn chưa đăng ký lớp nào.</TableCell></TableRow>
              )}
            </TableBody>
          </Table>
        </TableContainer>
      </SectionCard>

      <ConfirmDialog
        open={!!huyTarget}
        title="Xác nhận hủy đăng ký"
        text={huyTarget ? `Bạn có chắc muốn HỦY đăng ký lớp ${huyTarget.MaLHP} — ${huyTarget.TenMonHoc}?` : ''}
        confirmText="Hủy đăng ký"
        danger
        busy={busyCode === huyTarget?.MaLHP}
        onConfirm={huy}
        onClose={() => setHuyTarget(null)}
      />
    </Box>
  );
}
