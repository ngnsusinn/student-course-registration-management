import { useCallback, useEffect, useState } from 'react';
import {
  Box, Alert, Table, TableBody, TableCell, TableContainer, TableHead, TableRow,
  Button, Typography, Chip, CircularProgress, Stack,
} from '@mui/material';
import { toast } from 'react-toastify';
import api, { errMessage } from '../../api/client';
import { SectionCard } from '../../components/SectionCard';
import ConfirmDialog from '../../components/ConfirmDialog';
import { HUY_ERRORS } from '../../utils/format';

// ============================================================
// HUY DANG KY — chi trong thoi gian quy dinh (SP_KiemTraHuyDangKy)
// ============================================================
export default function HuyDangKy() {
  const [hocKy, setHocKy] = useState(null);
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [target, setTarget] = useState(null);
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [hk, ds] = await Promise.all([api.get('/dangky/hocky-hientai'), api.get('/dangky/danhsach')]);
      setHocKy(hk.data.hocKy);
      setRows((ds.data.danhSach || []).filter(r => r.TrangThaiDangKy === 'DA_DANG_KY' && hk.data.hocKy && r.MaHocKy === hk.data.hocKy.MaHocKy));
    } catch (e) {
      toast.error(errMessage(e));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  const submit = async () => {
    if (!target) return;
    setBusy(true);
    try {
      const { data } = await api.post('/dangky/huy', { MaLHP: target.MaLHP });
      toast.success(`✅ ${data.message}`);
      setTarget(null);
      load();
    } catch (e) {
      const code = e.response?.data?.ketQua;
      toast.error(HUY_ERRORS[code] || errMessage(e));
    } finally {
      setBusy(false);
    }
  };

  if (loading) return <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}><CircularProgress /></Box>;

  return (
    <Box>
      {hocKy ? (
        <Alert severity="info" sx={{ mb: 2.5 }}>
          Đợt <b>{hocKy.TenHocKy} — {hocKy.NamHoc}</b> đang mở đến hết ngày <b>{hocKy.DenNgay}</b>.
          Việc hủy đăng ký chỉ được thực hiện trong thời gian quy định của học kỳ.
        </Alert>
      ) : (
        <Alert severity="warning" sx={{ mb: 2.5 }}>
          Hiện không có đợt đăng ký nào đang mở — hệ thống sẽ <b>chặn hủy đăng ký (mã lỗi 200)</b>.
          Vui lòng liên hệ Phòng Đào tạo nếu cần điều chỉnh ngoài đợt.
        </Alert>
      )}

      <SectionCard title="Học phần có thể hủy (đã đăng ký — học kỳ hiện tại)"
        action={<Chip size="small" color="primary" label={`${rows.length} lớp`} />}>
        <TableContainer>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Mã LHP</TableCell><TableCell>Môn học</TableCell><TableCell align="center">Số TC</TableCell>
                <TableCell>Giảng viên</TableCell><TableCell>Ngày đăng ký</TableCell><TableCell align="right">Thao tác</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {rows.map((r) => (
                <TableRow key={r.MaLHP} hover>
                  <TableCell><code>{r.MaLHP}</code></TableCell>
                  <TableCell>{r.TenMonHoc}</TableCell>
                  <TableCell align="center">{r.SoTinChi}</TableCell>
                  <TableCell>{r.HoTenGV || '—'}</TableCell>
                  <TableCell>{r.NgayDangKy}</TableCell>
                  <TableCell align="right">
                    <Button size="small" color="error" variant="outlined" onClick={() => setTarget(r)}>Hủy đăng ký</Button>
                  </TableCell>
                </TableRow>
              ))}
              {!rows.length && <TableRow><TableCell colSpan={6} align="center" sx={{ py: 3, color: 'text.disabled' }}>Không có học phần nào để hủy.</TableCell></TableRow>}
            </TableBody>
          </Table>
        </TableContainer>
      </SectionCard>

      <SectionCard title="Mã lỗi khi hủy đăng ký (SP_HuyDangKy)">
        <TableContainer>
          <Table size="small">
            <TableHead><TableRow><TableCell sx={{ width: 90 }}>Mã</TableCell><TableCell>Ý nghĩa</TableCell></TableRow></TableHead>
            <TableBody>
              {Object.entries(HUY_ERRORS).map(([k, v]) => (
                <TableRow key={k}><TableCell><Chip size="small" label={k} color={k === '0' ? 'success' : 'error'} /></TableCell><TableCell>{v}</TableCell></TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
        <Stack direction="row" spacing={1} sx={{ mt: 1.5 }}>
          <Typography variant="caption" color="text.secondary">
            💡 Sau khi hủy, sĩ số lớp được giảm tự động (Trigger) và tín chỉ học kỳ của bạn được hoàn lại.
          </Typography>
        </Stack>
      </SectionCard>

      <ConfirmDialog
        open={!!target}
        title="Xác nhận hủy đăng ký"
        text={target ? `Bạn có chắc muốn HỦY đăng ký lớp ${target.MaLHP} — ${target.TenMonHoc} (${target.SoTinChi} TC)?\nHành động này không thể hoàn tác.` : ''}
        confirmText="Hủy đăng ký"
        danger
        busy={busy}
        onConfirm={submit}
        onClose={() => setTarget(null)}
      />
    </Box>
  );
}
