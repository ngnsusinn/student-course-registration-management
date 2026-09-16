// ============================================================
// controllers/prepare.controller.js — ⚠️ CÔNG CỤ DEMO (1-click)
//
//   GET  /api/prepare/trang-thai          → đang ở bản nào + trạng thái lớp
//   POST /api/prepare/chuan-bi {kichBan}  → 1 CLICK: triển khai bản có lỗi + dọn dữ liệu
//   POST /api/prepare/fix                 → 1 CLICK: khôi phục bản thật + dọn dữ liệu
//
//   kichBan: 'DEMO' (mặc định — Lost Update + NRR/Phantom) | 'DEADLOCK'
//
//   ⚠️ Chỉ dùng cho lab/demo. Muốn bỏ: xoá route trong routes/index.js.
// ============================================================
import * as prepareModel from '../models/prepare.model.js';

const KICH_BAN = ['DEMO', 'DEADLOCK'];

// Gói 3 result set thành object dễ dùng ở giao diện
const goiTrangThai = (rs) => ({
  thuTuc: (rs[0] || [])[0] || {},
  lopDemo: rs[1] || [],
  taiKhoanDemo: rs[2] || [],
});

// Diễn giải trạng thái hiện tại thành nhãn tiếng Việt
function danhGia(t) {
  return {
    lostUpdate: t.DonKy_CoForUpdate
      ? { cheDo: 'DA_FIX', nhan: 'Đã fix (SP_DangKyHocPhan có FOR UPDATE)' }
      : { cheDo: 'CHUA_FIX', nhan: 'CHƯA FIX (thiếu FOR UPDATE) — sẵn sàng demo Lost Update' },
    nhieuHocPhan: t.Nhieu_DocHaiLan
      ? { cheDo: 'LAB_NRR_PHANTOM', nhan: 'Bản lab đọc 2 lần — sẵn sàng demo Non-repeatable Read / Phantom Read'
          + (t.Nhieu_CoSleep ? '' : ' (thiếu DO SLEEP — không mở rộng cửa sổ)') }
      : t.Nhieu_KhoaTheoThuTuChon
        ? { cheDo: 'LAB_DEADLOCK', nhan: 'Bản khóa theo thứ tự tick — sẵn sàng demo Deadlock' }
        : { cheDo: 'DA_FIX', nhan: 'Đã fix (khóa theo MaLHP tăng dần)' },
  };
}

// GET /api/prepare/trang-thai
export async function trangThai(req, res) {
  const rs = await prepareModel.trangThai();
  const g = goiTrangThai(rs);
  res.json({ ...g, danhGia: danhGia(g.thuTuc) });
}

// POST /api/prepare/chuan-bi  { kichBan }
export async function chuanBi(req, res) {
  const kichBan = String(req.body?.kichBan || 'DEMO').trim().toUpperCase();
  if (!KICH_BAN.includes(kichBan)) {
    return res.status(400).json({ error: `kichBan phải là ${KICH_BAN.join(' hoặc ')}.` });
  }

  const nhat_ky = [];
  const buoc = async (moTa, fn) => {
    try {
      const kq = await fn();
      nhat_ky.push({ buoc: moTa, ok: true, chiTiet: kq });
      return kq;
    } catch (e) {
      nhat_ky.push({ buoc: moTa, ok: false, chiTiet: e.sqlMessage || e.message });
      throw e;
    }
  };

  try {
    // 1) Triển khai "bản có lỗi" cho kịch bản được chọn
    await buoc('Triển khai SP_DangKyHocPhan — bản CHƯA FIX (Lost Update)',
      () => prepareModel.apSql('lost_update_chua_fix'));

    if (kichBan === 'DEADLOCK') {
      await buoc('Triển khai SP_DangKyNhieuHocPhan — bản khóa theo thứ tự tick (Deadlock)',
        () => prepareModel.apSql('deadlock_chua_fix'));
    } else {
      await buoc('Triển khai SP_DangKyNhieuHocPhan — bản lab đọc 2 lần (NRR / Phantom)',
        () => prepareModel.apSql('lab_nrr_phantom_chua_fix'));
    }

    // 2) Dọn & chuẩn bị dữ liệu
    await buoc(`Dọn & chuẩn bị dữ liệu demo (kịch bản ${kichBan})`,
      () => prepareModel.chuanBiDuLieu(kichBan));

    const rs = await prepareModel.trangThai();
    const g = goiTrangThai(rs);
    res.json({
      thanhCong: true,
      kichBan,
      thongDiep: kichBan === 'DEADLOCK'
        ? '✅ ĐÃ CHUẨN BỊ cho kịch bản DEADLOCK — xem demo/04_DEADLOCK.md PHẦN B'
        : '✅ ĐÃ CHUẨN BỊ cho kịch bản Lost Update + Non-repeatable Read + Phantom Read — xem demo/01, 06',
      nhat_ky,
      ...g,
      danhGia: danhGia(g.thuTuc),
    });
  } catch (e) {
    res.status(500).json({ thanhCong: false, kichBan, error: e.sqlMessage || e.message, nhat_ky });
  }
}

// POST /api/prepare/fix
export async function fix(req, res) {
  const nhat_ky = [];
  const buoc = async (moTa, fn) => {
    try {
      const kq = await fn();
      nhat_ky.push({ buoc: moTa, ok: true, chiTiet: kq });
      return kq;
    } catch (e) {
      nhat_ky.push({ buoc: moTa, ok: false, chiTiet: e.sqlMessage || e.message });
      throw e;
    }
  };

  try {
    // 1) Khôi phục 2 thủ tục THẬT của hệ thống
    await buoc('Khôi phục SP_DangKyHocPhan — BẢN THẬT (có FOR UPDATE + retry 1213)',
      () => prepareModel.apSql('sp_dangky_that'));
    await buoc('Khôi phục SP_DangKyNhieuHocPhan — BẢN THẬT (khóa theo MaLHP tăng dần)',
      () => prepareModel.apSql('sp_dangky_nhieu_that'));

    // 2) Dọn dữ liệu về trạng thái xuất phát
    await buoc('Dọn dữ liệu demo về trạng thái xuất phát',
      () => prepareModel.chuanBiDuLieu('DEMO'));

    const rs = await prepareModel.trangThai();
    const g = goiTrangThai(rs);
    res.json({
      thanhCong: true,
      thongDiep: '✅ ĐÃ FIX — hệ thống đã trở về bản chính thức (không còn thủ tục có lỗi)',
      nhat_ky,
      ...g,
      danhGia: danhGia(g.thuTuc),
    });
  } catch (e) {
    res.status(500).json({ thanhCong: false, error: e.sqlMessage || e.message, nhat_ky });
  }
}
