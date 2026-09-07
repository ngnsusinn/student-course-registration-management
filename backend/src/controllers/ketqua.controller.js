// ============================================================
// controllers/ketqua.controller.js — Điểm số & Kết quả học tập
// Tầng CONTROLLER (MVC): nhận HTTP request, gọi MODEL, trả JSON.
// ============================================================
import * as ketquaModel from '../models/ketqua.model.js';

// GET /api/ketqua/bangdiem?MaHocKy= (SV xem bảng điểm của mình)
export async function bangDiem(req, res) {
  const bangDiem = await ketquaModel.bangDiem(req.user.MaSV, req.query.MaHocKy || null);
  res.json({ bangDiem });
}

// GET /api/ketqua/gpa?MaHocKy= (SV)
export async function gpa(req, res) {
  const { MaHocKy } = req.query;
  if (!MaHocKy) return res.status(400).json({ error: 'Thiếu mã học kỳ.' });
  const rs = await ketquaModel.gpaHocKy(req.user.MaSV, MaHocKy);
  res.json({ gpa: rs[0] || null });
}

// GET /api/ketqua/cpa (SV)
export async function cpa(req, res) {
  const rs = await ketquaModel.cpaTichLuy(req.user.MaSV);
  res.json({ cpa: rs[0] || null });
}

// GET /api/ketqua/thangdiemchu
export async function thangDiemChu(req, res) {
  res.json({ thangDiem: await ketquaModel.dsThangDiemChu() });
}

// GET /api/ketqua/thongke-monhoc (GV / PĐT)
export async function thongKeMonHoc(req, res) {
  res.json({ thongKe: await ketquaModel.thongKeMonHoc(req.query.MaLHP || null) });
}

// GET /api/ketqua/canhbao-hocvu (PĐT) — danh sách SV cảnh báo học vụ
export async function canhBaoHocVu(req, res) {
  const svs = await ketquaModel.dsCanhBaoHocVu();
  const canhBao = [];
  for (const sv of svs) {
    try {
      const rs = await ketquaModel.cpaTichLuy(sv.MaSV);
      const cpa = rs?.[0];
      if (cpa && cpa.TrangThaiCanhBaoHocVu && cpa.TrangThaiCanhBaoHocVu !== 'Bình thường') {
        canhBao.push({ ...cpa });
      }
    } catch { /* bỏ qua SV không có điểm */ }
  }
  res.json({ canhBao });
}

// GET /api/ketqua/gpa-theo-lop/:MaLHP (GV xem GPA từng SV trong lớp)
export async function gpaTheoLop(req, res) {
  const gpaLop = await ketquaModel.gpaTheoLop(req.params.MaLHP);
  res.json({ gpaLop });
}
