// ============================================================
// controllers/prepare.controller.js — ⚠️ CÔNG CỤ DEMO (1-click)
//
//   GET  /api/prepare/trang-thai          → đang ở bản nào + dữ liệu đã sẵn sàng chưa
//   POST /api/prepare/chuan-bi {kichBan}  → 1 CLICK: ♻ refresh TOÀN BỘ dữ liệu học kỳ
//                                            hiện tại + triển khai bản có lỗi
//   POST /api/prepare/fix                 → 1 CLICK: khôi phục bản thật + ♻ refresh dữ liệu
//
//   kichBan: 'DEMO' (mặc định — Lost Update + NRR/Phantom) | 'DEADLOCK'
//
//   ★ Cả 2 nút đều gọi SP_Prepare_Demo → SP này DỰNG LẠI toàn bộ dữ liệu đăng ký
//     của học kỳ hiện tại (xoá mọi dấu vết của lần demo trước) rồi bày dữ liệu
//     đúng cho kịch bản. Nhờ vậy bấm nút là dùng được ngay, không cần dọn tay.
//
//   ⚠️ Chỉ dùng cho lab/demo. Muốn bỏ: xoá route trong routes/index.js.
// ============================================================
import * as prepareModel from '../models/prepare.model.js';

// ============================================================
// KỊCH BẢN CHUẨN BỊ — MỖI DEMO LÀ 1 LỰA CHỌN RIÊNG (không gộp)
//
//   ⚠️ VÌ SAO KHÔNG ĐƯỢC GỘP LOST UPDATE CHUNG VỚI NRR/PHANTOM?
//     • Lost Update cần `SP_DangKyHocPhan` bản CHƯA FIX, và bản đó có
//       `DO SLEEP(8)` SAU `INSERT`, TRƯỚC `COMMIT` để mở rộng cửa sổ cho
//       người thao tác tay.
//     • Nhưng chính `DO SLEEP(8)` đó làm giao dịch của trình duyệt B
//       **COMMIT muộn (~8s)** — muộn hơn "lần đọc 2" của trình duyệt A
//       trong `SP_DangKyNhieuHocPhan` bản lab ⇒ A đọc 2 lần GIỐNG NHAU
//       ⇒ KHÔNG hủy oan ⇒ kịch bản NRR/Phantom **không tái hiện được**.
//     • Vì vậy NRR/Phantom phải nạp `SP_DangKyHocPhan` **BẢN THẬT**
//       (không `DO SLEEP`) để B commit trong vài chục ms, kịp cho A đọc thấy.
//
//   Đo thực tế trên máy đang chạy web (A = SV003 tick LHP507+LHP508,
//   B = SV004 bấm "Đăng ký" LHP507 sau 1,5s):
//     • Chuẩn bị GỘP  : SP_DangKyHocPhan có SLEEP → A kq = 0   (KHÔNG hủy oan)
//     • Chuẩn bị RIÊNG: SP_DangKyHocPhan bản thật → A kq = 104 (HỦY OAN, sĩ số 0→1)
// ============================================================
const KICH_BAN = {
  LOST_UPDATE: {
    nhan: 'Lost Update — 2 SV giành suất cuối cùng (LHP506)',
    taiLieu: 'demo/01_LOST_UPDATE.md',
    duLieu: 'DEMO',                       // hồ sơ dữ liệu cho SP_Prepare_Demo
    thuTuc: [
      ['lost_update_chua_fix', 'SP_DangKyHocPhan — bản CHƯA FIX (thiếu FOR UPDATE + DO SLEEP 8s)'],
      ['sp_dangky_nhieu_that', 'SP_DangKyNhieuHocPhan — bản THẬT (không dùng ở kịch bản này)'],
    ],
    thongDiep: '✅ ĐÃ CHUẨN BỊ cho kịch bản LOST UPDATE — xem demo/01_LOST_UPDATE.md (PHẦN C)',
  },
  NRR: {
    nhan: 'Non-repeatable Read — 2 SV, cùng lớp LHP507',
    taiLieu: 'demo/06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md',
    duLieu: 'DEMO',
    thuTuc: [
      ['sp_dangky_that', 'SP_DangKyHocPhan — BẢN THẬT (không SLEEP ⇒ B commit kịp trong cửa sổ 8s)'],
      ['lab_nrr_phantom_chua_fix', 'SP_DangKyNhieuHocPhan — bản lab (đọc 2 lần @ READ COMMITTED)'],
    ],
    thongDiep: '✅ ĐÃ CHUẨN BỊ cho kịch bản NON-REPEATABLE READ — xem demo/06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md (KỊCH BẢN 1)',
  },
  PHANTOM: {
    nhan: 'Phantom Read — 1 SV, 2 cửa sổ, lớp khác (LHP505)',
    taiLieu: 'demo/06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md',
    duLieu: 'DEMO',
    thuTuc: [
      ['sp_dangky_that', 'SP_DangKyHocPhan — BẢN THẬT (không SLEEP ⇒ B commit kịp trong cửa sổ 8s)'],
      ['lab_nrr_phantom_chua_fix', 'SP_DangKyNhieuHocPhan — bản lab (đọc 2 lần @ READ COMMITTED)'],
    ],
    thongDiep: '✅ ĐÃ CHUẨN BỊ cho kịch bản PHANTOM READ — xem demo/06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md (KỊCH BẢN 2)',
  },
  DIRTY_READ: {
    nhan: 'Dirty Read — đọc dữ liệu CHƯA COMMIT rồi bị rollback (LHP507)',
    taiLieu: 'demo/08_DIRTY_READ.md',
    duLieu: 'DEMO',
    thuTuc: [
      ['lab_dirty_writer_chua_fix', 'SP_DangKyHocPhan — bản lab GHI mà KHÔNG commit (INSERT → DO SLEEP 8s → ROLLBACK)'],
      ['lab_dirty_reader_chua_fix', 'SP_DangKyNhieuHocPhan — bản lab ĐỌC BẨN (@ READ UNCOMMITTED, đọc 2 lần)'],
    ],
    thongDiep: '✅ ĐÃ CHUẨN BỊ cho kịch bản DIRTY READ — xem demo/08_DIRTY_READ.md',
  },
  DEADLOCK: {
    nhan: 'Deadlock — 2 SV tick 2 lớp theo thứ tự ngược nhau',
    taiLieu: 'demo/04_DEADLOCK.md',
    duLieu: 'DEADLOCK',
    thuTuc: [
      ['sp_dangky_that', 'SP_DangKyHocPhan — BẢN THẬT (không dùng ở kịch bản này)'],
      ['deadlock_chua_fix', 'SP_DangKyNhieuHocPhan — bản khóa theo THỨ TỰ TICK CHỌN (gây deadlock 1213)'],
    ],
    thongDiep: '✅ ĐÃ CHUẨN BỊ cho kịch bản DEADLOCK — xem demo/04_DEADLOCK.md (PHẦN B)',
  },
};
const MA_KICH_BAN = Object.keys(KICH_BAN);

// Gói các result set thành object dễ dùng ở giao diện
const goiTrangThai = (rs) => ({
  thuTuc: (rs[0] || [])[0] || {},
  lopDemo: rs[1] || [],
  taiKhoanDemo: rs[2] || [],
  hocKy: (rs[3] || [])[0] || {},
});

// Kịch bản nào đang được chuẩn bị? (suy ra từ trạng thái 2 thủ tục)
function kichBanDangSanSang(t) {
  // Dirty Read: nhận diện bằng NHÃN thủ tục của bộ lab (đáng tin hơn đoán theo cờ,
  // vì bản "phiên ghi" cũng thiếu FOR UPDATE giống bản Lost Update).
  if (t.Nhieu_LaDocBan || t.Nhieu_LaDocBanDaFix || t.DonKy_LaWriterLab) {
    return { ma: 'DIRTY_READ', nhan: 'Dirty Read (phiên ĐỌC BẨN @ READ UNCOMMITTED + phiên GHI không commit)' };
  }
  if (!t.DonKy_CoForUpdate) {
    return { ma: 'LOST_UPDATE', nhan: 'Lost Update (SP_DangKyHocPhan đang là bản chưa fix)' };
  }
  if (t.Nhieu_DocHaiLan) {
    return { ma: 'NRR_PHANTOM', nhan: 'Non-repeatable Read / Phantom Read (SP_DangKyNhieuHocPhan đang là bản lab)' };
  }
  if (t.Nhieu_KhoaTheoThuTuChon) {
    return { ma: 'DEADLOCK', nhan: 'Deadlock (SP_DangKyNhieuHocPhan khóa theo thứ tự tick chọn)' };
  }
  return null;   // cả 2 thủ tục đều là bản chính thức
}

// Diễn giải trạng thái hiện tại thành nhãn tiếng Việt
function danhGia(t) {
  return {
    lostUpdate: t.DonKy_LaWriterLab
      ? { cheDo: 'LAB_DIRTY_READ', nhan: 'Bản lab Dirty Read — GHI rồi ROLLBACK (dữ liệu không bao giờ commit)' }
      : t.DonKy_CoForUpdate
        ? { cheDo: 'DA_FIX', nhan: 'Đã fix (SP_DangKyHocPhan có FOR UPDATE)' }
        : { cheDo: 'CHUA_FIX', nhan: 'CHƯA FIX (thiếu FOR UPDATE) — sẵn sàng demo Lost Update' },
    nhieuHocPhan: t.Nhieu_LaDocBan
      ? { cheDo: 'LAB_DIRTY_READ', nhan: 'Bản lab ĐỌC BẨN — đọc 2 lần @ READ UNCOMMITTED (sẵn sàng demo Dirty Read)' }
      : t.Nhieu_LaDocBanDaFix
        ? { cheDo: 'DA_FIX_LAB', nhan: 'Bản lab ĐỐI CHỨNG — đọc 2 lần @ REPEATABLE READ (đã chặn đọc bẩn)' }
        : t.Nhieu_DocHaiLan
          ? { cheDo: 'LAB_NRR_PHANTOM', nhan: 'Bản lab đọc 2 lần — sẵn sàng demo Non-repeatable Read / Phantom Read'
              + (t.Nhieu_CoSleep ? '' : ' (thiếu DO SLEEP — không mở rộng cửa sổ)') }
          : t.Nhieu_KhoaTheoThuTuChon
            ? { cheDo: 'LAB_DEADLOCK', nhan: 'Bản khóa theo thứ tự tick — sẵn sàng demo Deadlock' }
            : { cheDo: 'DA_FIX', nhan: 'Đã fix (khóa theo MaLHP tăng dần)' },
    kichBanSanSang: kichBanDangSanSang(t),
  };
}

// Tạo bộ ghi nhật ký từng bước cho 2 nút 1-click
function taoBuocGhi(nhat_ky) {
  return async (moTa, fn) => {
    try {
      const kq = await fn();
      nhat_ky.push({ buoc: moTa, ok: true, chiTiet: kq });
      return kq;
    } catch (e) {
      nhat_ky.push({ buoc: moTa, ok: false, chiTiet: e.sqlMessage || e.message });
      throw e;
    }
  };
}

// Ghi thêm 1 dòng nhật ký TÓM TẮT tình trạng dữ liệu sau khi refresh.
// ⚠️ SP_Prepare_Demo có gọi SP con (SP_ChuanBi_Demo_4Anomaly / _Deadlock) nên
//    các result set của SP con bị chèn lên TRƯỚC dòng tổng kết — vì vậy phải
//    dò theo tên cột thay vì tin vào thứ tự result set.
function timDongTomTat(kq) {
  for (const rs of kq || []) {
    const dong = rs?.[0];
    if (dong && dong.DotDangKy_Mo !== undefined) return dong;
  }
  return null;
}

function ghiTomTatDuLieu(nhat_ky, kq) {
  const t = timDongTomTat(kq);
  if (!t) return;
  const sach = t.DotDangKy_Mo === 1 && t.SoLopLechSiSo === 0 && t.SoDauVetDemo === 0;
  nhat_ky.push({
    buoc: `↳ Học kỳ hiện tại: ${t.SoDangKy} đăng ký · lệch sĩ số ${t.SoLopLechSiSo} lớp · `
        + `dấu vết demo còn lại ${t.SoDauVetDemo} · đợt đăng ký ${t.DotDangKy_Mo ? 'ĐANG MỞ' : 'ĐÃ ĐÓNG'}`
        + (sach ? ' ⇒ SẴN SÀNG SỬ DỤNG' : ''),
    ok: sach,
    chiTiet: t,
  });
}

// GET /api/prepare/trang-thai
export async function trangThai(req, res) {
  const rs = await prepareModel.trangThai();
  const g = goiTrangThai(rs);
  res.json({
    ...g,
    danhGia: danhGia(g.thuTuc),
    // Danh sách kịch bản cho giao diện (nguồn sự thật ở server)
    kichBan: MA_KICH_BAN.map((ma) => ({ ma, nhan: KICH_BAN[ma].nhan, taiLieu: KICH_BAN[ma].taiLieu })),
  });
}

// POST /api/prepare/chuan-bi  { kichBan }
// MỖI DEMO CHUẨN BỊ RIÊNG — xem bảng KICH_BAN ở đầu file để biết vì sao không gộp.
export async function chuanBi(req, res) {
  const kichBan = String(req.body?.kichBan || 'LOST_UPDATE').trim().toUpperCase();
  const cfg = KICH_BAN[kichBan];
  if (!cfg) {
    return res.status(400).json({ error: `kichBan phải là một trong: ${MA_KICH_BAN.join(', ')}.` });
  }

  const nhat_ky = [];
  const buoc = taoBuocGhi(nhat_ky);

  try {
    // 1) Triển khai ĐÚNG các thủ tục của RIÊNG kịch bản này
    for (const [maFile, moTa] of cfg.thuTuc) {
      await buoc(`Triển khai ${moTa}`, () => prepareModel.apSql(maFile));
    }

    // 2) ♻ Dựng lại TOÀN BỘ dữ liệu học kỳ hiện tại + bày dữ liệu cho kịch bản
    const kqDuLieu = await buoc(
      `♻ Dựng lại TOÀN BỘ dữ liệu học kỳ hiện tại về trạng thái xuất phát + chuẩn bị dữ liệu demo (kịch bản ${kichBan})`,
      () => prepareModel.chuanBiDuLieu(cfg.duLieu));
    ghiTomTatDuLieu(nhat_ky, kqDuLieu);

    const rs = await prepareModel.trangThai();
    const g = goiTrangThai(rs);
    res.json({
      thanhCong: true,
      kichBan,
      nhan: cfg.nhan,
      taiLieu: cfg.taiLieu,
      thongDiep: cfg.thongDiep,
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
  const buoc = taoBuocGhi(nhat_ky);

  try {
    // 1) Khôi phục 2 thủ tục THẬT của hệ thống
    await buoc('Khôi phục SP_DangKyHocPhan — BẢN THẬT (có FOR UPDATE + retry 1213)',
      () => prepareModel.apSql('sp_dangky_that'));
    await buoc('Khôi phục SP_DangKyNhieuHocPhan — BẢN THẬT (khóa theo MaLHP tăng dần)',
      () => prepareModel.apSql('sp_dangky_nhieu_that'));

    // 2) ♻ Dựng lại TOÀN BỘ dữ liệu học kỳ hiện tại về trạng thái xuất phát
    const kqDuLieu = await buoc(
      '♻ Dựng lại TOÀN BỘ dữ liệu học kỳ hiện tại về trạng thái xuất phát (xoá mọi dấu vết demo)',
      () => prepareModel.chuanBiDuLieu('DEMO'));
    ghiTomTatDuLieu(nhat_ky, kqDuLieu);

    const rs = await prepareModel.trangThai();
    const g = goiTrangThai(rs);
    res.json({
      thanhCong: true,
      thongDiep: '✅ ĐÃ FIX — hệ thống đã trở về bản chính thức và dữ liệu học kỳ hiện tại đã dựng lại',
      nhat_ky,
      ...g,
      danhGia: danhGia(g.thuTuc),
    });
  } catch (e) {
    res.status(500).json({ thanhCong: false, error: e.sqlMessage || e.message, nhat_ky });
  }
}
