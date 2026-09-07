// ============================================================
// controllers/hocphi.controller.js — Học phí, Tài khoản & Vận hành
// Tầng CONTROLLER (MVC): nhận HTTP request, gọi MODEL, trả JSON.
// ============================================================
import * as hocphiModel from '../models/hocphi.model.js';

export const THU_ERROR_MESSAGES = {
  0: 'Thu học phí thành công.',
  301: 'Không tìm thấy phiếu học phí.',
  302: 'Phiếu học phí đã thanh toán hết.',
  303: 'Số tiền nộp không hợp lệ.',
  304: 'Số tiền nộp vượt quá số tiền còn nợ.',
  500: 'Lỗi hệ thống khi thu học phí.',
};

// GET /api/hocphi/cua-toi (SV)
export async function cuaToi(req, res) {
  res.json({ hocPhi: await hocphiModel.hocPhiCuaToi(req.user.MaSV) });
}

// GET /api/hocphi/danhsach?TrangThai=&MaHocKy= (PĐT)
export async function danhSach(req, res) {
  const { TrangThai, MaHocKy } = req.query;
  const hocPhi = await hocphiModel.dsHocPhi(TrangThai || null, MaHocKy || null);
  res.json({ hocPhi });
}

// GET /api/hocphi/baocao (PĐT) — tổng hợp từ các view (SP trả 4 result set)
export async function baoCao(req, res) {
  const [tongHopRows, theoHocKy, theoNganh, conNo] = await hocphiModel.thongKeHocPhi();
  res.json({
    tongHop: tongHopRows[0] || null,
    theoHocKy,
    theoNganh,
    conNo,
  });
}

// POST /api/hocphi/thu { MaHocPhi, SoTien } (PĐT) → SP_ThuHocPhi
export async function thu(req, res) {
  const { MaHocPhi, SoTien } = req.body || {};
  if (!MaHocPhi) return res.status(400).json({ error: 'Thiếu mã học phí.' });
  const soTien = Number(SoTien);
  if (!Number.isFinite(soTien) || soTien <= 0) {
    return res.status(400).json({ error: 'Số tiền nộp không hợp lệ.' });
  }

  let ketQua = 500;
  try {
    ketQua = await hocphiModel.thuHocPhi(MaHocPhi, soTien);
  } catch {
    ketQua = 500;
  }

  if (ketQua !== 0) {
    return res.status(400).json({ ketQua, error: THU_ERROR_MESSAGES[ketQua] || 'Thu học phí thất bại.' });
  }
  res.json({ ketQua: 0, message: THU_ERROR_MESSAGES[0] });
}

// POST /api/hocphi/tinh { MaSV, MaHocKy, DonGiaTinChi } (PĐT) → SP_TinhHocPhi
export async function tinh(req, res) {
  const { MaSV, MaHocKy, DonGiaTinChi } = req.body || {};
  if (!MaSV || !MaHocKy || !DonGiaTinChi) {
    return res.status(400).json({ error: 'Thiếu MaSV, MaHocKy hoặc DonGiaTinChi.' });
  }
  try {
    await hocphiModel.tinhHocPhi(MaSV, MaHocKy, Number(DonGiaTinChi));
    res.json({ message: 'Tính học phí thành công.' });
  } catch (e) {
    res.status(400).json({ error: e.sqlMessage || e.message });
  }
}
