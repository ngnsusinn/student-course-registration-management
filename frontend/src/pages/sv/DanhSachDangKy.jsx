import { useEffect, useMemo, useState } from 'react';
import {
  Box, Grid, Stack, Table, TableBody, TableCell, TableContainer, TableHead, TableRow,
  CircularProgress, Chip, Typography, Button,
} from '@mui/material';
import FileDownloadIcon from '@mui/icons-material/FileDownload';
import { toast } from 'react-toastify';
import api, { errMessage } from '../../api/client';
import { SectionCard, StatBox } from '../../components/SectionCard';
import { StatusChip } from '../../components/StatusBadges';
import { fmtNgay } from '../../utils/format';
import { xuatExcel } from '../../utils/export';

// ============================================================
// DANH SACH DANG KY — toan bo hoc phan da dang ky + tom tat TC
// ============================================================
export default function DanhSachDangKy() {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get('/dangky/danhsach')
      .then(({ data }) => setRows(data.danhSach || []))
      .catch((e) => toast.error(errMessage(e)))
      .finally(() => setLoading(false));
  }, []);

  const theoKy = useMemo(() => {
    const map = new Map();
    rows.forEach(r => {
      const cur = map.get(r.MaHocKy) || { ten: `${r.TenHocKy} — ${r.NamHoc}`, active: 0, huy: 0, tc: 0 };
      if (r.TrangThaiDangKy === 'DA_DANG_KY') { cur.active += 1; cur.tc += Number(r.SoTinChi); }
      else cur.huy += 1;
      map.set(r.MaHocKy, cur);
    });
    return [...map.entries()].sort((a, b) => b[0] - a[0]);
  }, [rows]);

  const tongDangKy = rows.filter(r => r.TrangThaiDangKy === 'DA_DANG_KY').length;
  const tongHuy = rows.length - tongDangKy;
  const tongTC = theoKy.reduce((s, [, v]) => s + v.tc, 0);

  if (loading) return <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}><CircularProgress /></Box>;

  return (
    <Box>
      <SectionCard title="Tóm tắt đăng ký">
        <Grid container spacing={1.5}>
          <Grid item xs={6} sm={3}><StatBox value={tongDangKy} label="Học phần đang đăng ký" /></Grid>
          <Grid item xs={6} sm={3}><StatBox value={tongHuy} label="Đã hủy" color="#c62828" /></Grid>
          <Grid item xs={6} sm={3}><StatBox value={tongTC} label="Tổng tín chỉ tích lũy ĐK" /></Grid>
          <Grid item xs={6} sm={3}><StatBox value={theoKy.length} label="Học kỳ đã đăng ký" /></Grid>
        </Grid>
      </SectionCard>

      <SectionCard title="Danh sách lớp học phần đã đăng ký"
        action={
          <Button size="small" variant="outlined" startIcon={<FileDownloadIcon />}
            onClick={() => xuatExcel('Danh-sach-dang-ky', [
              { header: 'Mã LHP', key: 'MaLHP' }, { header: 'Tên lớp HP', key: 'TenLHP' },
              { header: 'Tên môn học', key: 'TenMonHoc' }, { header: 'Tín chỉ', key: 'SoTinChi' },
              { header: 'Học kỳ', value: (r) => `${r.TenHocKy} ${r.NamHoc}` },
              { header: 'Ngày đăng ký', value: (r) => fmtNgay(r.NgayDangKy) },
              { header: 'Trạng thái ĐK', key: 'TrangThaiDangKy' }, { header: 'Ghi chú', key: 'GhiChu' },
            ], rows)}>Xuất Excel</Button>
        }>
        <TableContainer>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Mã LHP</TableCell><TableCell>Tên lớp HP</TableCell><TableCell>Tên môn học</TableCell>
                <TableCell align="center">Tín chỉ</TableCell><TableCell>Học kỳ</TableCell>
                <TableCell>Ngày đăng ký</TableCell><TableCell>Trạng thái ĐK</TableCell><TableCell>Ghi chú</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {rows.map((r, i) => (
                <TableRow key={i} hover>
                  <TableCell><code>{r.MaLHP}</code></TableCell>
                  <TableCell>{r.TenLHP}</TableCell>
                  <TableCell>{r.TenMonHoc}</TableCell>
                  <TableCell align="center">{r.SoTinChi}</TableCell>
                  <TableCell>{r.TenHocKy} {r.NamHoc}</TableCell>
                  <TableCell>{fmtNgay(r.NgayDangKy)}</TableCell>
                  <TableCell><StatusChip group="DK" code={r.TrangThaiDangKy} /></TableCell>
                  <TableCell sx={{ fontSize: 12.5 }}>{r.GhiChu || '—'}</TableCell>
                </TableRow>
              ))}
              {!rows.length && <TableRow><TableCell colSpan={8} align="center" sx={{ py: 3, color: 'text.disabled' }}>Bạn chưa đăng ký học phần nào.</TableCell></TableRow>}
            </TableBody>
          </Table>
        </TableContainer>
      </SectionCard>

      <SectionCard title="Theo học kỳ">
        {theoKy.map(([ky, v]) => (
          <Stack key={ky} direction="row" spacing={1.5} alignItems="center" sx={{ py: 0.75, flexWrap: 'wrap', useFlexGap: true }}>
            <Typography sx={{ minWidth: 220, fontWeight: 600, fontSize: 14 }}>{v.ten}</Typography>
            <Chip size="small" color="success" label={`${v.active} lớp đang học`} />
            <Chip size="small" color="primary" label={`${v.tc} TC`} />
            {v.huy > 0 && <Chip size="small" color="error" label={`${v.huy} đã hủy`} />}
          </Stack>
        ))}
        {!theoKy.length && <Typography color="text.disabled">Chưa có dữ liệu.</Typography>}
      </SectionCard>
    </Box>
  );
}
