import { useCallback, useEffect, useRef, useState } from 'react';
import {
  Alert, AlertTitle, Box, Button, Chip, CircularProgress, Divider, MenuItem,
  Stack, Table, TableBody, TableCell, TableHead, TableRow, TextField, Typography,
} from '@mui/material';
import BuildCircleIcon from '@mui/icons-material/BuildCircle';
import HealingIcon from '@mui/icons-material/Healing';
import RefreshIcon from '@mui/icons-material/Refresh';
import { toast } from 'react-toastify';
import api, { errMessage } from '../../api/client';
import { SectionCard } from '../../components/SectionCard';
import { TEAL } from '../../theme';

// ============================================================
// CHUẨN BỊ DEMO — công cụ 1-CLICK cho buổi demo/lab
//   [⚙ CHUẨN BỊ DEMO] : triển khai các thủ tục CỐ Ý CÓ LỖI + dọn dữ liệu
//   [✔ FIX]            : khôi phục 2 thủ tục THẬT + dọn dữ liệu
//
//   ⚠️ Đây là công cụ demo, KHÔNG phải nghiệp vụ. Muốn bỏ: xoá route
//      /chuan-bi-demo trong App.jsx + mục menu + backend routes/prepare.js
// ============================================================

const KICH_BAN = [
  { value: 'DEMO', label: 'Demo chính — Lost Update + Non-repeatable Read + Phantom Read' },
  { value: 'DEADLOCK', label: 'Deadlock — 2 SV tick lớp ngược thứ tự' },
];

function TheTrangThai({ tieuDe, cheDo, nhan }) {
  const mau = cheDo === 'CHUA_FIX' || cheDo === 'LAB_NRR_PHANTOM' || cheDo === 'LAB_DEADLOCK'
    ? { bg: '#fff8e1', border: '#f0d79a', chip: 'warning', chipLabel: 'SẴN SÀNG DEMO' }
    : { bg: '#eaf5eb', border: '#b3d9b6', chip: 'success', chipLabel: 'BẢN CHÍNH THỨC' };
  return (
    <Box sx={{ border: `1px solid ${mau.border}`, bgcolor: mau.bg, borderRadius: 1.5, p: 1.5, flex: 1, minWidth: 260 }}>
      <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 0.5 }}>
        <Typography variant="subtitle2" sx={{ fontWeight: 800 }}>{tieuDe}</Typography>
        <Chip size="small" color={mau.chip} label={mau.chipLabel} sx={{ fontWeight: 700 }} />
      </Stack>
      <Typography variant="body2">{nhan}</Typography>
    </Box>
  );
}

export default function PrepareDemo() {
  const [kichBan, setKichBan] = useState('DEMO');
  const [tt, setTt] = useState(null);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState('');
  const [log, setLog] = useState([]);
  const logRef = useRef(null);

  const themLog = (msg) => setLog((l) => [...l, `[${new Date().toLocaleTimeString('vi-VN')}] ${msg}`]);
  useEffect(() => { if (logRef.current) logRef.current.scrollTop = logRef.current.scrollHeight; }, [log]);

  const tai = useCallback(async () => {
    setLoading(true);
    try {
      const { data } = await api.get('/prepare/trang-thai');
      setTt(data);
    } catch (e) {
      toast.error(errMessage(e, 'Không đọc được trạng thái.'));
    } finally {
      setLoading(false);
    }
  }, []);
  useEffect(() => { tai(); }, [tai]);

  const chay = async (duong, body, nhan) => {
    setBusy(duong);
    themLog(`▶ ${nhan} …`);
    try {
      const { data } = await api.post(`/prepare/${duong}`, body || {}, { timeout: 120000 });
      (data.nhat_ky || []).forEach((b) => themLog(`   ${b.ok ? '✔' : '✖'} ${b.buoc}`));
      themLog(data.thongDiep || '✔ Xong');
      toast.success(data.thongDiep || '✔ Xong');
      setTt(data);
    } catch (e) {
      themLog('✖ LỖI: ' + errMessage(e));
      toast.error(errMessage(e, 'Thao tác thất bại.'));
    } finally {
      setBusy('');
    }
  };

  const dg = tt?.danhGia;

  return (
    <Box>
      <Alert severity="info" sx={{ mb: 2.5 }}>
        <AlertTitle sx={{ fontWeight: 800 }}>⚙️ Chuẩn bị Demo — 2 nút 1-CLICK</AlertTitle>
        <b>CHUẨN BỊ DEMO</b> sẽ triển khai các <b>thủ tục cố ý có lỗi</b> (bản chưa fix) và <b>dọn dữ liệu</b> về
        trạng thái xuất phát. <b>FIX</b> sẽ khôi phục <b>bản chính thức</b> của hệ thống và dọn dữ liệu.
        Sau khi bấm, chỉ cần mở web ở 2 trình duyệt và làm theo guide — <b>không cần chạy lệnh nào</b>.
      </Alert>

      {/* ============ 2 NÚT CHÍNH ============ */}
      <SectionCard title="🎛️ Điều khiển">
        <Stack spacing={2}>
          <TextField
            select size="small" label="Chuẩn bị cho kịch bản" value={kichBan}
            onChange={(e) => setKichBan(e.target.value)}
            helperText="Deadlock dùng chung SP_DangKyNhieuHocPhan với NRR/Phantom nên phải chuẩn bị riêng."
            sx={{ maxWidth: 620 }}
          >
            {KICH_BAN.map((k) => <MenuItem key={k.value} value={k.value}>{k.label}</MenuItem>)}
          </TextField>

          <Stack direction="row" spacing={1.5} flexWrap="wrap" useFlexGap>
            <Button
              variant="contained" color="warning" size="large" startIcon={<BuildCircleIcon />}
              disabled={!!busy}
              onClick={() => chay('chuan-bi', { kichBan }, `CHUẨN BỊ DEMO (kịch bản ${kichBan})`)}
            >
              {busy === 'chuan-bi' ? 'Đang chuẩn bị…' : '⚙ CHUẨN BỊ DEMO'}
            </Button>
            <Button
              variant="contained" color="success" size="large" startIcon={<HealingIcon />}
              disabled={!!busy}
              onClick={() => chay('fix', {}, 'FIX — khôi phục bản chính thức')}
            >
              {busy === 'fix' ? 'Đang fix…' : '✔ FIX — khôi phục bản thật'}
            </Button>
            <Button variant="outlined" startIcon={<RefreshIcon />} disabled={!!busy} onClick={tai}>
              Đọc lại trạng thái
            </Button>
          </Stack>

          <Alert severity="warning" icon={false}>
            ⚠️ Nhớ bấm <b>FIX</b> sau khi demo xong — nếu không, hệ thống vẫn đang chạy bằng <b>thủ tục cố ý có lỗi</b>.
          </Alert>
        </Stack>
      </SectionCard>

      {/* ============ TRẠNG THÁI ============ */}
      <SectionCard title="📊 Trạng thái hiện tại">
        {loading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}><CircularProgress /></Box>
        ) : (
          <Stack spacing={2}>
            <Stack direction={{ xs: 'column', md: 'row' }} spacing={2}>
              <TheTrangThai
                tieuDe="SP_DangKyHocPhan (nút “Đăng ký”)"
                cheDo={dg?.lostUpdate?.cheDo} nhan={dg?.lostUpdate?.nhan || '—'}
              />
              <TheTrangThai
                tieuDe="SP_DangKyNhieuHocPhan (nút “Đăng ký N lớp đã chọn”)"
                cheDo={dg?.nhieuHocPhan?.cheDo} nhan={dg?.nhieuHocPhan?.nhan || '—'}
              />
            </Stack>

            <Divider />

            <Typography variant="subtitle2" sx={{ fontWeight: 800 }}>Lớp demo</Typography>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>Lớp</TableCell><TableCell>Môn học</TableCell>
                  <TableCell align="right">Sĩ số</TableCell><TableCell align="right">Còn</TableCell>
                  <TableCell align="right">COUNT(*) hiệu lực</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {(tt?.lopDemo || []).map((l) => (
                  <TableRow key={l.MaLHP}>
                    <TableCell><b>{l.MaLHP}</b></TableCell>
                    <TableCell>{l.TenMonHoc}</TableCell>
                    <TableCell align="right"><b>{l.SiSoHienTai}/{l.SiSoToiDa}</b></TableCell>
                    <TableCell align="right">{l.ConTrong}</TableCell>
                    <TableCell align="right">{l.SoDK_ThucTe}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>

            <Typography variant="subtitle2" sx={{ fontWeight: 800 }}>Tài khoản demo (mật khẩu: <code>matkhau@123</code>)</Typography>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>Tên đăng nhập</TableCell><TableCell>Vai trò</TableCell><TableCell>Trạng thái</TableCell>
                  <TableCell>Dùng cho</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {(tt?.taiKhoanDemo || []).map((t) => (
                  <TableRow key={t.TenDangNhap}>
                    <TableCell><b>{t.TenDangNhap}</b></TableCell>
                    <TableCell>{t.MaVaiTro}</TableCell>
                    <TableCell>
                      <Chip size="small" color={t.TrangThai === 'ACTIVE' ? 'success' : 'default'} label={t.TrangThai} />
                    </TableCell>
                    <TableCell>
                      {t.TenDangNhap === 'sv003' && 'Lost Update · NRR (trình duyệt A)'}
                      {t.TenDangNhap === 'sv004' && 'NRR (trình duyệt B)'}
                      {t.TenDangNhap === 'sv001' && 'Phantom Read (2 cửa sổ)'}
                      {t.TenDangNhap === 'sv030' && 'Lost Update · Deadlock'}
                      {t.TenDangNhap === 'sv041' && 'Lost Update · Deadlock'}
                      {t.TenDangNhap === 'gv001' && 'Nhập điểm'}
                      {t.TenDangNhap === 'admin' && 'PĐT (quản trị)'}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </Stack>
        )}
      </SectionCard>

      {/* ============ NHẬT KÝ ============ */}
      <SectionCard title="📜 Nhật ký thao tác">
        <Box ref={logRef} sx={{
          fontFamily: 'Consolas, monospace', fontSize: 12, bgcolor: '#101820', color: '#d8e2ea',
          borderRadius: 1.5, p: 1.5, height: 220, overflow: 'auto', whiteSpace: 'pre-wrap',
        }}>
          {log.length ? log.join('\n') : 'Chưa có thao tác nào.'}
        </Box>
      </SectionCard>

      {/* ============ BƯỚC TIẾP THEO ============ */}
      <SectionCard title="👉 Sau khi bấm CHUẨN BỊ DEMO, làm gì tiếp?">
        <Stack spacing={1}>
          {[
            ['1. Lost Update — 2 trình duyệt', 'sv030 + sv041 → trang “Đăng ký lớp học phần” → cùng bấm “Đăng ký” lớp LHP506 → cả hai đều báo thành công (lỗi). Xem demo/01_LOST_UPDATE.md'],
            ['2. Non-repeatable Read — 2 trình duyệt', 'sv003 (tick LHP507+LHP508 → “Đăng ký 2 lớp đã chọn”) + sv004 (bấm “Đăng ký” LHP507 trong 8 giây) → A bị HỦY OAN. Xem demo/06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md'],
            ['3. Phantom Read — 1 SV, 2 cửa sổ', 'sv001 ở cả 2 cửa sổ: A tick LHP507+LHP508; B bấm “Đăng ký” LHP505 trong 8 giây → A bị HỦY OAN. Xem demo/06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md'],
            ['4. Deadlock — chuẩn bị riêng', 'Chọn kịch bản “Deadlock” ở ô trên rồi bấm CHUẨN BỊ DEMO. Xem demo/04_DEADLOCK.md PHẦN B'],
            ['5. SQL 2 tab (nếu cần)', 'Các kịch bản SQL dùng trình biên soạn DB: demo/01 → 04, PHẦN A/B'],
          ].map(([t, m]) => (
            <Box key={t} sx={{ borderLeft: `3px solid ${TEAL}`, pl: 1.5 }}>
              <Typography variant="subtitle2" sx={{ fontWeight: 700 }}>{t}</Typography>
              <Typography variant="body2" color="text.secondary">{m}</Typography>
            </Box>
          ))}
        </Stack>
      </SectionCard>
    </Box>
  );
}
