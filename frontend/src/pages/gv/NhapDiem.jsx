import { useCallback, useEffect, useState } from 'react';
import {
  Box, TextField, MenuItem, Table, TableBody, TableCell, TableContainer, TableHead,
  TableRow, Button, Alert, Typography, CircularProgress, Stack, Chip,
} from '@mui/material';
import SaveIcon from '@mui/icons-material/Save';
import FileDownloadIcon from '@mui/icons-material/FileDownload';
import { toast } from 'react-toastify';
import api, { errMessage } from '../../api/client';
import { SectionCard } from '../../components/SectionCard';
import ConfirmDialog from '../../components/ConfirmDialog';
import { xuatExcel } from '../../utils/export';

// ============================================================
// NHAP DIEM (GV) — bang cham diem; Trigger tu tinh TK/chu/he4
// ============================================================
const num = (v) => (v === null || v === undefined || v === '' ? null : Number(v));

export default function NhapDiem() {
  const [lops, setLops] = useState([]);
  const [maLHP, setMaLHP] = useState('');
  const [rows, setRows] = useState([]);
  const [draft, setDraft] = useState({}); // MaSV -> {cc, gk, ck}
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(null);
  const [confirmAll, setConfirmAll] = useState(false);

  useEffect(() => {
    api.get('/giangvien/lopcuatoi')
      .then(({ data }) => {
        const ls = data.lop || [];
        setLops(ls);
        if (ls.length) setMaLHP(ls[0].MaLHP);
      })
      .catch((e) => toast.error(errMessage(e)));
  }, []);

  const loadSv = useCallback(() => {
    if (!maLHP) return;
    setLoading(true);
    api.get(`/giangvien/sinhvien/${maLHP}`)
      .then(({ data }) => {
        const sv = data.sinhVien || [];
        setRows(sv);
        setDraft(Object.fromEntries(sv.map(s => [s.MaSV, {
          cc: s.DiemChuyenCan ?? '', gk: s.DiemGiuaKy ?? '', ck: s.DiemCuoiKy ?? '',
        }])));
      })
      .catch((e) => toast.error(errMessage(e)))
      .finally(() => setLoading(false));
  }, [maLHP]);

  useEffect(() => { loadSv(); }, [loadSv]);

  const setField = (maSV, key, val) => {
    if (val !== '' && (Number(val) < 0 || Number(val) > 10)) {
      toast.warn('Điểm phải trong khoảng 0 – 10.');
      return;
    }
    setDraft((p) => ({ ...p, [maSV]: { ...p[maSV], [key]: val } }));
  };

  const payload = (maSV) => ({
    MaSV: maSV, MaLHP: maLHP,
    DiemChuyenCan: num(draft[maSV]?.cc), DiemGiuaKy: num(draft[maSV]?.gk), DiemCuoiKy: num(draft[maSV]?.ck),
  });

  const luuMot = async (maSV) => {
    setSaving(maSV);
    try {
      const { data } = await api.post('/giangvien/nhapdiem', payload(maSV));
      toast.success(`✅ ${data.message} — ${maSV}`);
      loadSv();
    } catch (e) {
      toast.error(errMessage(e, 'Nhập điểm thất bại.'));
    } finally {
      setSaving(null);
    }
  };

  const luuTatCa = async () => {
    setConfirmAll(false);
    setSaving('ALL');
    try {
      const danhSach = rows.map(s => ({
        MaSV: s.MaSV,
        DiemChuyenCan: num(draft[s.MaSV]?.cc), DiemGiuaKy: num(draft[s.MaSV]?.gk), DiemCuoiKy: num(draft[s.MaSV]?.ck),
      }));
      const { data } = await api.post('/giangvien/nhapdiem-hangloat', { MaLHP: maLHP, DanhSachDiem: danhSach });
      toast.success(`✅ ${data.message}`);
      loadSv();
    } catch (e) {
      toast.error(errMessage(e, 'Nhập điểm hàng loạt thất bại.'));
    } finally {
      setSaving(null);
    }
  };

  const lopHienTai = lops.find(l => l.MaLHP === maLHP);

  return (
    <Box>
      <SectionCard
        title="Nhập kết quả học tập sinh viên"
        action={
          <Stack direction="row" spacing={1.5} alignItems="center">
            <TextField select size="small" label="Lớp học phần" value={maLHP} onChange={(e) => setMaLHP(e.target.value)} sx={{ minWidth: 320 }}>
              {lops.map(l => <MenuItem key={l.MaLHP} value={l.MaLHP}>{l.MaLHP} — {l.TenMonHoc} ({l.TenHocKy})</MenuItem>)}
            </TextField>
            <Button variant="outlined" startIcon={<FileDownloadIcon />} disabled={!rows.length}
              onClick={() => xuatExcel(`Bang-diem-${maLHP}`, [
                { header: 'Mã SV', key: 'MaSV' }, { header: 'Họ và tên', key: 'HoTen' }, { header: 'Lớp SH', key: 'MaLopSH' },
                { header: 'Chuyên cần', key: 'DiemChuyenCan' }, { header: 'Giữa kỳ', key: 'DiemGiuaKy' },
                { header: 'Cuối kỳ', key: 'DiemCuoiKy' }, { header: 'Tổng kết', key: 'DiemTongKet' },
                { header: 'Điểm chữ', key: 'DiemChu' }, { header: 'Hệ 4', key: 'DiemHe4' },
              ], rows)}>Xuất Excel</Button>
            <Button variant="contained" startIcon={<SaveIcon />} disabled={!rows.length || saving !== null} onClick={() => setConfirmAll(true)}>
              💾 Lưu điểm
            </Button>
          </Stack>
        }
      >
        <Alert severity="info" sx={{ mb: 2 }}>
          📈 Điểm tổng kết = 10% chuyên cần + 20% giữa kỳ + 70% cuối kỳ; điểm chữ và điểm hệ 4 do <b>Trigger tự tính</b> khi lưu.
          {lopHienTai && <> Lớp <code>{lopHienTai.MaLHP}</code> — {lopHienTai.TenMonHoc}, sĩ số {lopHienTai.SiSoHienTai}/{lopHienTai.SiSoToiDa}.</>}
        </Alert>

        {loading ? <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}><CircularProgress /></Box> : (
          <TableContainer>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>Mã SV</TableCell><TableCell>Họ và tên</TableCell><TableCell>Lớp SH</TableCell>
                  <TableCell align="center" sx={{ width: 110 }}>Chuyên cần</TableCell>
                  <TableCell align="center" sx={{ width: 110 }}>Giữa kỳ</TableCell>
                  <TableCell align="center" sx={{ width: 110 }}>Cuối kỳ</TableCell>
                  <TableCell align="center">Tổng kết</TableCell><TableCell align="center">Điểm chữ</TableCell>
                  <TableCell align="center">Hệ 4</TableCell><TableCell align="right"></TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {rows.map((s) => {
                  const dd = draft[s.MaSV] || {};
                  const dirty = String(dd.cc ?? '') !== String(s.DiemChuyenCan ?? '') ||
                    String(dd.gk ?? '') !== String(s.DiemGiuaKy ?? '') ||
                    String(dd.ck ?? '') !== String(s.DiemCuoiKy ?? '');
                  return (
                    <TableRow key={s.MaSV} hover>
                      <TableCell><code>{s.MaSV}</code></TableCell>
                      <TableCell>{s.HoTen}</TableCell>
                      <TableCell>{s.MaLopSH}</TableCell>
                      {['cc', 'gk', 'ck'].map((k) => (
                        <TableCell key={k} align="center">
                          <TextField size="small" type="number" inputProps={{ min: 0, max: 10, step: 0.25, style: { width: 64, textAlign: 'center' } }}
                            value={dd[k] ?? ''} onChange={(e) => setField(s.MaSV, k, e.target.value)} />
                        </TableCell>
                      ))}
                      <TableCell align="center"><b>{s.DiemTongKet ?? '—'}</b></TableCell>
                      <TableCell align="center"><Chip size="small" variant="outlined" label={s.DiemChu || '—'} /></TableCell>
                      <TableCell align="center">{s.DiemHe4 ?? '—'}</TableCell>
                      <TableCell align="right">
                        <Button size="small" variant={dirty ? 'contained' : 'text'} color="success" disabled={!dirty || saving !== null}
                          onClick={() => luuMot(s.MaSV)}>
                          {saving === s.MaSV ? '...' : 'Lưu'}
                        </Button>
                      </TableCell>
                    </TableRow>
                  );
                })}
                {!rows.length && !loading && <TableRow><TableCell colSpan={10} align="center" sx={{ py: 3, color: 'text.disabled' }}>Lớp chưa có sinh viên hoặc bạn không phụ trách lớp này.</TableCell></TableRow>}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </SectionCard>

      <ConfirmDialog
        open={confirmAll}
        title="Lưu toàn bộ bảng điểm"
        text={`Xác nhận lưu điểm cho ${rows.length} sinh viên của lớp ${maLHP}?\nToàn bộ được thực hiện trong một giao dịch (transaction).`}
        confirmText="Lưu tất cả"
        onConfirm={luuTatCa}
        onClose={() => setConfirmAll(false)}
      />
    </Box>
  );
}
