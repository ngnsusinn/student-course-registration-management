import { useCallback, useEffect, useState } from 'react';
import {
  Box, Grid, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Chip,
  CircularProgress, Alert, Button, Stack, Typography, Card, CardContent, LinearProgress,
} from '@mui/material';
import PlayArrowIcon from '@mui/icons-material/PlayArrow';
import RefreshIcon from '@mui/icons-material/Refresh';
import ScienceIcon from '@mui/icons-material/Science';
import { toast } from 'react-toastify';
import api, { errMessage } from '../../api/client';
import { SectionCard, StatBox } from '../../components/SectionCard';

// ============================================================
// CONCURRENCY LAB (PĐT) — Demo 4 lỗi concurrency trên MySQL thật
//   Lost Update · Dirty Read · Unrepeatable Read · Phantom Read
//   + chứng minh MySQL REPEATABLE READ đang phòng chống gì
//   + SP đã fix (FOR UPDATE) không bao giờ vượt sĩ số.
// API: /api/concurrency/trangthai · /chuanbi · /demo/:ten
// Chi tiết cơ chế: docs/concurrency/concurrency_anomaly_demo.md
// ============================================================

const PHAS = [
  {
    ten: 'rr-chan',
    tieuDe: '① MySQL mặc định đang phòng chống gì?',
    moTa: 'REPEATABLE-READ + MVCC: chặn sẵn Dirty Read, Unrepeatable Read, Phantom Read. Muốn demo 3 lỗi còn lại phải "tắt" bằng cách hạ isolation level.',
    mau: 'success.main',
  },
  {
    ten: 'lost-update',
    tieuDe: '② Lost Update (Cập nhật mất)',
    moTa: '2 phiên chạy thủ tục ban đầu CHƯA FIX (SP thiếu SELECT ... FOR UPDATE) → cùng thấy "còn 1 chỗ" → cùng được ghi → số đăng ký vượt sĩ số tối đa.',
    mau: 'error.main',
  },
  {
    ten: 'dirty-read',
    tieuDe: '③ Dirty Read (Đọc bẩn)',
    moTa: 'Tắt phòng chống: SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED → phiên đọc "nhìn thấu" dữ liệu chưa commit, dữ liệu biến mất sau rollback.',
    mau: 'error.main',
  },
  {
    ten: 'unrepeatable-read',
    tieuDe: '④ Unrepeatable Read (Đọc không lặp lại)',
    moTa: 'Tắt phòng chống: READ COMMITTED → giữa 2 lần SELECT trong cùng 1 giao dịch, phiên khác kịp sửa + commit → 2 kết quả khác nhau.',
    mau: 'error.main',
  },
  {
    ten: 'phantom-read',
    tieuDe: '⑤ Phantom Read (Đọc bóng ma)',
    moTa: 'Tắt phòng chống: READ COMMITTED → giữa 2 lần đếm, phiên khác chèn dòng mới → xuất hiện "bóng ma" trong tập kết quả.',
    mau: 'error.main',
  },
  {
    ten: 'sp-fix',
    tieuDe: '⑥ Phòng chống lại — SP đã FIX (FOR UPDATE)',
    moTa: '2 phiên gọi SP_DangKyHocPhan giành chỗ cuối: phiên sau chờ khóa dòng sĩ số, kiểm tra lại sau khi phiên trước commit → nhận mã 105. Không bao giờ vượt sĩ số.',
    mau: 'success.main',
  },
];

export default function ConcurrencyDemo() {
  const [trangThai, setTrangThai] = useState(null);
  const [loading, setLoading] = useState(true);
  const [dangChay, setDangChay] = useState(null);
  const [ketQua, setKetQua] = useState({});

  const loadTT = useCallback(() => {
    api.get('/concurrency/trangthai')
      .then((r) => setTrangThai(r.data))
      .catch((e) => toast.error(errMessage(e)))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => { loadTT(); }, [loadTT]);

  const chuanBi = useCallback(() => {
    setLoading(true);
    api.post('/concurrency/chuanbi')
      .then((r) => { setTrangThai(r.data); toast.success('Đã đưa LHP514 về trạng thái "còn đúng 1 chỗ".'); })
      .catch((e) => toast.error(errMessage(e)))
      .finally(() => setLoading(false));
  }, []);

  const chay = useCallback((ten) => {
    setDangChay(ten);
    api.post(`/concurrency/demo/${ten}`, {}, { timeout: 120000 })
      .then((r) => {
        setKetQua((k) => ({ ...k, [ten]: r.data }));
        toast[r.data.ketLuan.dat ? 'success' : 'warning'](
          `${r.data.tieuDe} — ${r.data.ketLuan.dat ? 'đúng kịch bản' : 'khác kỳ vọng'}`);
      })
      .catch((e) => toast.error(errMessage(e)))
      .finally(() => setDangChay(null));
  }, []);

  if (loading && !trangThai) {
    return <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}><CircularProgress /></Box>;
  }

  return (
    <Box>
      <SectionCard
        title="Concurrency Lab — phòng thí nghiệm 4 lỗi điều khiển cạnh tranh"
        action={(
          <Stack direction="row" spacing={1}>
            <Button size="small" startIcon={<RefreshIcon />} onClick={chuanBi}>Chuẩn bị lại LHP514</Button>
          </Stack>
        )}
      >
        <Alert severity="info" sx={{ mb: 2 }}>
          Mỗi kịch bản chạy <b>2 phiên kết nối thật</b> trên MySQL remote, tự thao tác trên lớp demo <b>LHP514</b> và
          tự dọn dữ liệu khi kết thúc. Tài liệu cơ chế: <code>docs/concurrency/concurrency_anomaly_demo.md</code>.
        </Alert>
        <Grid container spacing={2}>
          <Grid item xs={6} sm={3}><StatBox label="MySQL" value={trangThai?.ver || '—'} /></Grid>
          <Grid item xs={6} sm={3}><StatBox label="Isolation mặc định" value={trangThai?.iso || '—'} /></Grid>
          <Grid item xs={6} sm={3}><StatBox label="LHP514 (demo)" value={`${trangThai?.SiSoHienTai ?? '—'}/${trangThai?.SiSoToiDa ?? '—'}`} /></Grid>
          <Grid item xs={6} sm={3}>
            <StatBox label="SP demo" value={Number(trangThai?.SPDemo) === 3 ? 'Sẵn sàng ✅' : `Chưa áp (${trangThai?.SPDemo ?? 0}/3)`} />
          </Grid>
        </Grid>
        {Number(trangThai?.SPDemo) !== 3 && (
          <Alert severity="warning" sx={{ mt: 2 }}>
            Chưa đủ SP demo trên DB — chạy: <code>cd backend &amp;&amp; node scripts/apply-demo-anomaly.js</code>
          </Alert>
        )}
      </SectionCard>

      {PHAS.map((p) => {
        const kq = ketQua[p.ten];
        return (
          <Card key={p.ten} sx={{ mt: 2 }}>
            <CardContent>
              <Stack direction="row" alignItems="center" justifyContent="space-between" flexWrap="wrap" gap={1}>
                <Box>
                  <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>{p.tieuDe}</Typography>
                  <Typography variant="body2" color="text.secondary" sx={{ maxWidth: 760 }}>{p.moTa}</Typography>
                </Box>
                <Button
                  variant="contained"
                  size="small"
                  startIcon={dangChay === p.ten ? <CircularProgress size={14} color="inherit" /> : <PlayArrowIcon />}
                  disabled={!!dangChay}
                  onClick={() => chay(p.ten)}
                >
                  {dangChay === p.ten ? 'Đang chạy…' : 'Chạy demo'}
                </Button>
              </Stack>

              {dangChay === p.ten && <LinearProgress sx={{ mt: 2 }} />}

              {kq && (
                <Box sx={{ mt: 2 }}>
                  <Alert severity={kq.ketLuan.dat ? 'success' : 'warning'} sx={{ mb: 1.5 }}>
                    <b>{kq.ketLuan.dat ? 'PASS —' : 'LƯU Ý —'}</b> {kq.ketLuan.noiDung}
                  </Alert>
                  <TableContainer>
                    <Table size="small">
                      <TableHead>
                        <TableRow>
                          <TableCell sx={{ width: 110 }}>Phiên</TableCell>
                          <TableCell>Hành động</TableCell>
                          <TableCell>Kết quả quan sát</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {kq.buoc.map((b, i) => (
                          <TableRow key={i} hover>
                            <TableCell>
                              {b.phien === 'A' || b.phien === 'B'
                                ? <Chip size="small" color={b.phien === 'A' ? 'primary' : 'secondary'} label={`Phiên ${b.phien}`} />
                                : <Chip size="small" variant="outlined" label={b.phien} />}
                            </TableCell>
                            <TableCell>{b.moTa}</TableCell>
                            <TableCell sx={{ fontWeight: 600 }}>{b.ketQua}</TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </TableContainer>
                </Box>
              )}
            </CardContent>
          </Card>
        );
      })}

      <Alert severity="success" icon={<ScienceIcon />} sx={{ mt: 2 }}>
        Gợi ý khi thuyết trình: chạy <b>①</b> trước để nói "MySQL đã phòng chống gì", rồi lần lượt <b>②→⑤</b>
        (mỗi lần "tắt" một cơ chế phòng chống bằng isolation level / thủ tục chưa fix), cuối cùng <b>⑥</b> để
        chứng minh hệ thống đã fix. Chạy thủ công 2 cửa sổ: <code>mysql/transactions/demo_4_anomaly_2cua_so.sql</code>.
      </Alert>
    </Box>
  );
}
