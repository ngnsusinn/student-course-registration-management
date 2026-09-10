// ============================================================
// controllers/dangky.controller.js — Đăng ký học phần (Module trung tâm)
// Tầng CONTROLLER (MVC): nhận HTTP request, gọi MODEL, ánh xạ mã lỗi SP → JSON.
// ============================================================
import * as dangkyModel from '../models/dangky.model.js';

export const DK_ERROR_MESSAGES = {
  0: 'Đăng ký học phần thành công.',
  100: 'Rất tiếc! Hiện tại ngoài thời hạn đăng ký học phần của học kỳ này.',
  101: 'Bạn đã đăng ký lớp học phần này rồi.',
  102: 'Không thể đăng ký! Bạn chưa hoàn thành môn tiên quyết của môn học này.',
  103: 'Đăng ký thất bại! Lớp học phần bị trùng lịch học với lớp bạn đã đăng ký.',
  104: 'Không thể đăng ký! Tổng số tín chỉ vượt quá giới hạn tối đa cho phép.',
  105: 'Đăng ký thất bại! Lớp học phần đã đầy sĩ số (hết chỗ trống).',
  106: 'Lớp học phần không tồn tại hoặc không ở trạng thái mở đăng ký.',
  500: 'Lỗi hệ thống khi xử lý đăng ký.',
};

export const HUY_ERROR_MESSAGES = {
  0: 'Hủy đăng ký thành công.',
  200: 'Rất tiếc! Hiện tại ngoài thời hạn hủy đăng ký học phần.',
  201: 'Không tìm thấy bản ghi đăng ký học phần.',
  202: 'Bản ghi đăng ký không ở trạng thái ĐÃ ĐĂNG KÝ (không thể hủy).',
  500: 'Lỗi hệ thống khi xử lý hủy đăng ký.',
};

// Thông báo cho đăng ký NHIỀU học phần (SP_DangKyNhieuHocPhan).
// 1213/1205 là lỗi KHÓA do HQTCSDL trả về — giao diện hiển thị thông báo để người dùng thử lại.
export const DK_NHIEU_MESSAGES = {
  ...DK_ERROR_MESSAGES,
  1213: 'Xung đột khóa (deadlock 1213): giao dịch đăng ký của bạn bị hệ quản trị CSDL hủy để giải phóng deadlock. Vui lòng bấm đăng ký lại.',
  1205: 'Chờ khóa quá lâu (timeout 1205): hệ thống đang bận vì một giao dịch khác giữ khóa. Vui lòng thử lại.',
};

// GET /api/dangky/hocky-hientai
export async function hocKyHienTai(req, res) {
  const hk = await dangkyModel.hocKyHienTai();
  res.json({ hocKy: hk });
}

// GET /api/dangky/lopmo — danh sách LHP đang mở cho SV đăng ký
export async function dsLopMo(req, res) {
  const maSV = req.user.MaSV;
  const hk = await dangkyModel.hocKyHienTai();
  if (!hk) return res.json({ hocKy: null, lopHocPhan: [] });
  const rows = await dangkyModel.dsLopMo(maSV, hk.MaHocKy);
  res.json({ hocKy: hk, lopHocPhan: rows });
}

// POST /api/dangky — { MaLHP, GhiChu } → SP_DangKyHocPhan
export async function dangKy(req, res) {
  const maSV = req.user.MaSV;
  const { MaLHP, GhiChu = null, MaxTinChi = 24 } = req.body || {};
  if (!MaLHP) return res.status(400).json({ error: 'Thiếu mã lớp học phần.' });

  // SP tự quản lý transaction (START TRANSACTION/COMMIT/ROLLBACK bên trong)
  let ketQua = 500;
  try {
    ketQua = await dangkyModel.dangKy(maSV, MaLHP, MaxTinChi, GhiChu);
  } catch {
    ketQua = 500;
  }

  if (ketQua !== 0) {
    return res.status(400).json({ ketQua, error: DK_ERROR_MESSAGES[ketQua] || 'Đăng ký thất bại.' });
  }

  const lhp = await dangkyModel.layLHP(MaLHP);
  res.json({ ketQua: 0, message: DK_ERROR_MESSAGES[0], lopHocPhan: lhp });
}

// POST /api/dangky/nhieu — { DanhSachLHP: [] } → SP_DangKyNhieuHocPhan
// Đăng ký NHIỀU học phần trong 1 giao dịch (CON TRO khóa lần lượt từng dòng sĩ số).
// Đây là tính năng THẬT trên trang "Đăng ký lớp học phần": sinh viên tick chọn nhiều
// lớp rồi bấm "Đăng ký N lớp đã chọn" — hệ thống gửi 1 yêu cầu duy nhất.
// Thủ tục luôn khóa theo MaLHP tăng dần (thứ tự nhất quán) nên không thể deadlock;
// nếu gặp sự cố khóa của HQTCSDL vẫn trả mã 1213/1205 để giao diện thông báo.
export async function dangKyNhieu(req, res) {
  const maSV = req.user.MaSV;
  const { DanhSachLHP, MaxTinChi = 24, GhiChu = null } = req.body || {};

  const ds = (Array.isArray(DanhSachLHP) ? DanhSachLHP : String(DanhSachLHP || '').split(','))
    .map((x) => String(x || '').trim()).filter(Boolean);
  if (!ds.length) return res.status(400).json({ error: 'Thiếu danh sách lớp học phần.' });
  if (ds.length > 6) return res.status(400).json({ error: 'Mỗi lần đăng ký tối đa 6 lớp.' });

  let ketQua = 500; let dong = null;
  try {
    ({ ketQua, dong } = await dangkyModel.dangKyNhieu(maSV, ds.join(','), MaxTinChi, GhiChu));
  } catch {
    ketQua = 500;
  }

  if (ketQua !== 0) {
    return res.status(409).json({
      ketQua,
      error: DK_NHIEU_MESSAGES[ketQua] || 'Đăng ký nhiều học phần thất bại.',
      chiTiet: dong,
    });
  }
  res.json({ ketQua: 0, message: DK_NHIEU_MESSAGES[0], chiTiet: dong });
}

// POST /api/dangky/huy — { MaLHP } → SP_HuyDangKy
export async function huyDangKy(req, res) {
  const maSV = req.user.MaSV;
  const { MaLHP } = req.body || {};
  if (!MaLHP) return res.status(400).json({ error: 'Thiếu mã lớp học phần.' });

  let ketQua = 500;
  try {
    ketQua = await dangkyModel.huyDangKy(maSV, MaLHP);
  } catch {
    ketQua = 500;
  }

  if (ketQua !== 0) {
    return res.status(400).json({ ketQua, error: HUY_ERROR_MESSAGES[ketQua] || 'Hủy đăng ký thất bại.' });
  }
  res.json({ ketQua: 0, message: HUY_ERROR_MESSAGES[0] });
}

// GET /api/dangky/danhsach?MaHocKy= — danh sách đăng ký của SV
export async function danhSach(req, res) {
  const { MaHocKy = null } = req.query;
  res.json({ danhSach: await dangkyModel.danhSachDangKy(req.user.MaSV, MaHocKy) });
}

// GET /api/dangky/thoikhoabieu?MaHocKy=
export async function thoiKhoaBieu(req, res) {
  const { MaHocKy = null } = req.query;
  res.json({ thoiKhoaBieu: await dangkyModel.thoiKhoaBieu(req.user.MaSV, MaHocKy) });
}

// GET /api/dangky/tongtinchi?MaHocKy=
export async function tongTinChi(req, res) {
  let { MaHocKy } = req.query;
  if (!MaHocKy) MaHocKy = (await dangkyModel.hocKyHienTai())?.MaHocKy || null;
  if (!MaHocKy) return res.json({ tongTinChi: 0 });
  const r = await dangkyModel.layTongTinChi(req.user.MaSV, MaHocKy);
  res.json({ maHocKy: MaHocKy, tongTinChi: Number(r.TongTinChi) });
}
