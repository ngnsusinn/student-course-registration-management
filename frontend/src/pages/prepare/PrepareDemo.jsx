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
import { fmtNgay } from '../../utils/format';
import { TEAL } from '../../theme';

// ============================================================
// CHUẨN BỊ DEMO — công cụ 1-CLICK cho buổi demo/lab
//   [⚙ CHUẨN BỊ DEMO] : ♻ DỰNG LẠI toàn bộ dữ liệu đăng ký của học kỳ hiện tại
//                       về trạng thái xuất phát + triển khai các thủ tục CỐ Ý CÓ LỖI
//   [✔ FIX]            : khôi phục 2 thủ tục THẬT + ♻ dựng lại dữ liệu
//
//   ⇒ Bấm 1 nút là dữ liệu sạch & sẵn sàng dùng ngay (không cần dọn tay).
//
//   ⚠️ Đây là công cụ demo, KHÔNG phải nghiệp vụ. Muốn bỏ: xoá route
//      /chuan-bi-demo trong App.jsx + mục menu + backend routes/prepare.js
// ============================================================

// ============================================================
// MỖI DEMO LÀ 1 LỰA CHỌN RIÊNG — không gộp.
//   ⚠️ Lost Update cần SP_DangKyHocPhan bản CHƯA FIX, mà bản đó có
//      DO SLEEP(8) sau INSERT ⇒ giao dịch của trình duyệt B commit MUỘN
//      hơn "lần đọc 2" của A ⇒ kịch bản NRR/Phantom KHÔNG tái hiện được.
//      Vì vậy mỗi kịch bản phải được chuẩn bị riêng.
// ============================================================
const KICH_BAN = [
  { value: 'LOST_UPDATE', label: '① Lost Update — 2 SV giành suất cuối cùng (LHP506)' },
  { value: 'NRR', label: '② Non-repeatable Read — 2 SV, cùng lớp LHP507' },
  { value: 'PHANTOM', label: '③ Phantom Read — 1 SV, 2 cửa sổ, lớp khác (LHP505)' },
  { value: 'DIRTY_READ', label: '④ Dirty Read — đọc dữ liệu CHƯA COMMIT (LHP507)' },
  { value: 'DEADLOCK', label: '⑤ Deadlock — 2 SV tick 2 lớp theo thứ tự ngược nhau' },
];

// Hướng dẫn thao tác tay cho từng kịch bản (hiển thị ngay trên trang)
const HUONG_DAN = {
  LOST_UPDATE: {
    taiLieu: 'demo/01_LOST_UPDATE.md (PHẦN C)',
    buoc: [
      'Tài khoản: sv030 (cửa sổ thường) + sv041 (cửa sổ ẩn danh) → trang “Đăng ký lớp học phần”.',
      'Cả hai tìm dòng LHP506 (0/1 — còn đúng 1 chỗ), bấm “Đăng ký” cách nhau ~1–2 giây.',
      'KẾT QUẢ: CẢ HAI đều toast XANH thành công → lớp nhận 2 SV trong 1 chỗ ⇒ LOST UPDATE.',
      'Đối chứng: bấm FIX rồi làm lại → phiên thứ hai nhận toast ĐỎ mã 105 (lớp đã đầy sĩ số).',
    ],
  },
  NRR: {
    taiLieu: 'demo/06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md (KỊCH BẢN 1)',
    buoc: [
      'Tài khoản: sv003 (cửa sổ thường) + sv004 (cửa sổ ẩn danh).',
      'A (sv003): tick ☑ LHP507 + ☑ LHP508 → bấm “Đăng ký 2 lớp đã chọn” (nút chuyển “Đang đăng ký…”).',
      'B (sv004): trong vòng ~8 giây, bấm “Đăng ký” ở dòng LHP507 → toast XANH.',
      'KẾT QUẢ: sau ~8 giây A nhận dải ĐỎ + dòng “HỦY OAN — … sĩ số 0→1 …” ⇒ NON-REPEATABLE READ.',
    ],
  },
  PHANTOM: {
    taiLieu: 'demo/06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md (KỊCH BẢN 2)',
    buoc: [
      'Tài khoản: sv001 ở CẢ HAI cửa sổ (1 thường + 1 ẩn danh).',
      'A: tick ☑ LHP507 + ☑ LHP508 → bấm “Đăng ký 2 lớp đã chọn”.',
      'B (cùng sv001): trong vòng ~8 giây, bấm “Đăng ký” ở dòng LHP505 → toast XANH.',
      'KẾT QUẢ: A nhận dải ĐỎ + dòng “HỦY OAN — … sĩ số 0→0 · số lớp 3→4” ⇒ PHANTOM READ.',
    ],
  },
  DIRTY_READ: {
    taiLieu: 'demo/08_DIRTY_READ.md',
    buoc: [
      'Tài khoản: sv003 (cửa sổ thường) + sv004 (cửa sổ ẩn danh).',
      'A (sv003): tick ☑ LHP507 → bấm “Đăng ký 1 lớp đã chọn” (đây là PHIÊN ĐỌC, sẽ đọc 2 lần cách nhau 8 giây).',
      'B (sv004): trong vòng ~8 giây, bấm “Đăng ký” ở dòng LHP507 → toast XANH (đây là PHIÊN GHI nhưng CHƯA commit).',
      'KẾT QUẢ: A nhận dải ĐỎ + dòng “ĐỌC BẨN — … sĩ số 0→1 · số dòng 0→1 …” ⇒ đã đọc dữ liệu CHƯA COMMIT.',
      'Bấm “Đọc lại trạng thái”/F5 để thấy: LHP507 quay về 0/40 và KHÔNG có dòng đăng ký nào — con số A đọc là RÁC (phiên ghi đã ROLLBACK).',
    ],
  },
  DEADLOCK: {
    taiLieu: 'demo/04_DEADLOCK.md (PHẦN B)',
    buoc: [
      'Tài khoản: sv030 (cửa sổ thường) + sv041 (cửa sổ ẩn danh).',
      'A: tick LHP514 TRƯỚC rồi LHP506. B: tick LHP506 TRƯỚC rồi LHP514 (cố ý NGƯỢC thứ tự).',
      'Hô “3–2–1” rồi cả hai bấm “Đăng ký 2 lớp đã chọn” cách nhau ~0,3 giây.',
      'KẾT QUẢ: một phiên nhận toast ĐỎ mã 1213 (deadlock) — HQTCSDL tự hủy 1 giao dịch, dữ liệu vẫn đúng.',
    ],
  },
};

function TheTrangThai({ tieuDe, cheDo, nhan }) {
  const LA_BAN_LAB = ['CHUA_FIX', 'LAB_NRR_PHANTOM', 'LAB_DEADLOCK', 'LAB_DIRTY_READ'];
  const mau = LA_BAN_LAB.includes(cheDo)
    ? { bg: '#fff8e1', border: '#f0d79a', chip: 'warning', chipLabel: 'SẴN SÀNG DEMO' }
    : cheDo === 'DA_FIX_LAB'
      ? { bg: '#eaf5eb', border: '#b3d9b6', chip: 'success', chipLabel: 'ĐỐI CHỨNG — ĐÃ FIX' }
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
  const [kichBan, setKichBan] = useState('LOST_UPDATE');
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
        <AlertTitle sx={{ fontWeight: 800 }}>⚙️ Chuẩn bị Demo — mỗi kịch bản 1 lần bấm</AlertTitle>
        <b>Chọn kịch bản</b> ở ô dưới rồi bấm <b>CHUẨN BỊ DEMO</b>: nút này <b>♻ dựng lại TOÀN BỘ dữ liệu đăng ký
        của học kỳ hiện tại</b> về trạng thái xuất phát (xoá mọi dấu vết của lần demo trước: đăng ký thừa, dòng
        đã hủy, sĩ số lệch, điểm vừa nhập, mật khẩu/tài khoản bị đổi…) rồi <b>triển khai đúng các thủ tục
        của kịch bản đó</b>. <b>FIX</b> khôi phục <b>bản chính thức</b> của hệ thống và cũng dựng lại dữ liệu.
        Sau khi bấm, chỉ cần mở web ở 2 trình duyệt và làm theo guide — <b>không cần chạy lệnh nào</b>.
        <br />
        ⚠️ <b>Mỗi lần đổi kịch bản phải bấm CHUẨN BỊ DEMO lại</b> — các kịch bản dùng chung 2 thủ tục nên
        <b> không thể</b> bật cùng lúc.
      </Alert>

      {/* ============ 2 NÚT CHÍNH ============ */}
      <SectionCard title="🎛️ Điều khiển">
        <Stack spacing={2}>
          <TextField
            select size="small" label="Chuẩn bị cho kịch bản" value={kichBan}
            onChange={(e) => setKichBan(e.target.value)}
            helperText="Mỗi kịch bản có bộ thủ tục riêng — đổi kịch bản thì phải bấm CHUẨN BỊ DEMO lại (xem hướng dẫn bên dưới)."
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
            <br />
            💡 Sau mỗi lần bấm, các <b>tab trình duyệt đang mở</b> nên <b>F5</b> để thấy dữ liệu mới (trang này tự đọc lại).
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

            <Stack direction="row" spacing={1} alignItems="center" flexWrap="wrap" useFlexGap>
              <Typography variant="subtitle2" sx={{ fontWeight: 800 }}>
                Kịch bản đang sẵn sàng:
              </Typography>
              {dg?.kichBanSanSang ? (
                <Chip color="warning" label={dg.kichBanSanSang.nhan} sx={{ fontWeight: 700 }} />
              ) : (
                <Chip color="success" label="Không có — cả 2 thủ tục đang là bản CHÍNH THỨC" sx={{ fontWeight: 700 }} />
              )}
            </Stack>

            <Divider />

            <Stack direction="row" spacing={1} alignItems="center" flexWrap="wrap" useFlexGap>
              <Typography variant="subtitle2" sx={{ fontWeight: 800 }}>
                Dữ liệu học kỳ hiện tại ({tt?.hocKy?.MaHocKy || '—'})
              </Typography>
              <Chip
                size="small"
                color={tt?.hocKy?.SanSang ? 'success' : 'error'}
                label={tt?.hocKy?.SanSang ? '✔ SẴN SÀNG SỬ DỤNG' : '✖ CHƯA SẴN SÀNG'}
                sx={{ fontWeight: 700 }}
              />
            </Stack>
            <Typography variant="body2" color="text.secondary">
              Sau khi bấm <b>CHUẨN BỊ DEMO</b>, dữ liệu học kỳ được dựng lại từ đầu — bảng dưới phải
              <b> khớp cột “Mong đợi”</b> thì mới coi là sẵn sàng trình diễn.
            </Typography>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>Hạng mục</TableCell>
                  <TableCell>Hiện tại</TableCell>
                  <TableCell>Mong đợi</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {[
                  [
                    'Đợt đăng ký',
                    `${tt?.hocKy?.TrangThaiDot || '—'}${tt?.hocKy?.DangMoDangKy ? ' · còn hạn' : ' · HẾT HẠN / ĐÃ ĐÓNG'}`
                      + (tt?.hocKy?.TuNgay ? ` (${fmtNgay(tt.hocKy.TuNgay)} → ${fmtNgay(tt.hocKy.DenNgay)})` : ''),
                    'MO · còn hạn',
                  ],
                  ['Đăng ký trong học kỳ', `${tt?.hocKy?.SoDangKy ?? '—'} bản ghi`, 'Đúng bộ dữ liệu chuẩn'],
                  ['Lớp lệch sĩ số', `${tt?.hocKy?.SoLopLechSiSo ?? '—'} lớp`, '0'],
                  ['Đăng ký demo còn sót', `${tt?.hocKy?.SoDauVetDemo ?? '—'} bản ghi`, '0'],
                  ['Dòng không hiệu lực (DA_HUY…)', `${tt?.hocKy?.SoDongKhongHieuLuc ?? '—'} bản ghi`,
                    '0 (riêng kịch bản Deadlock: 1)'],
                ].map(([hangMuc, hienTai, mongDoi]) => (
                  <TableRow key={hangMuc}>
                    <TableCell>{hangMuc}</TableCell>
                    <TableCell><b>{hienTai}</b></TableCell>
                    <TableCell sx={{ color: 'text.secondary' }}>{mongDoi}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>

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
      <SectionCard title={`👉 Kịch bản đang chọn: ${KICH_BAN.find((k) => k.value === kichBan)?.label || kichBan}`}>
        <Stack spacing={1}>
          {(HUONG_DAN[kichBan]?.buoc || []).map((m, i) => (
            <Box key={i} sx={{ borderLeft: `3px solid ${TEAL}`, pl: 1.5 }}>
              <Typography variant="body2"><b>Bước {i + 1}.</b> {m}</Typography>
            </Box>
          ))}
          <Alert severity="info" icon={false} sx={{ mt: 1 }}>
            📄 Kịch bản chi tiết: <code>{HUONG_DAN[kichBan]?.taiLieu}</code>
          </Alert>
          <Alert severity="success" icon={false}>
            💡 Muốn diễn lại từ đầu, <b>đổi kịch bản khác</b>, hay lỡ tay đăng ký linh tinh: chỉ cần chọn lại
            kịch bản rồi bấm <b>CHUẨN BỊ DEMO</b> lần nữa — nút này <b>dựng lại toàn bộ dữ liệu học kỳ hiện tại</b>
            rồi bày lại đúng trạng thái xuất phát (<b>idempotent</b>, bấm bao nhiêu lần cũng được).
          </Alert>
          <Alert severity="warning" icon={false}>
            ⚠️ <b>Mỗi lần đổi kịch bản phải bấm CHUẨN BỊ DEMO lại</b> — các kịch bản chia nhau 2 thủ tục
            <code> SP_DangKyHocPhan</code> và <code>SP_DangKyNhieuHocPhan</code> nên không thể bật cùng lúc.
            Riêng <b>NRR/Phantom</b> cần <code>SP_DangKyHocPhan</code> là <b>bản THẬT (không DO SLEEP)</b> để
            trình duyệt B commit kịp trong cửa sổ 8 giây; nếu chuẩn bị chung với Lost Update thì B commit muộn
            và <b>kịch bản sẽ không tái hiện được</b>.
          </Alert>
        </Stack>
      </SectionCard>
    </Box>
  );
}
