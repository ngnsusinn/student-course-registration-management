import { Routes, Route, Navigate } from 'react-router-dom';
import { useSelector } from 'react-redux';
import PortalLayout from './components/PortalLayout';
import ProtectedRoute from './components/ProtectedRoute';
import { selectUser } from './store/authSlice';

import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
// — Sinh viên —
import ThongTinCaNhan from './pages/sv/ThongTinCaNhan';
import DangKyHocPhan from './pages/sv/DangKyHocPhan';
import ThoiKhoaBieu from './pages/sv/ThoiKhoaBieu';
import DanhSachDangKy from './pages/sv/DanhSachDangKy';
import HuyDangKy from './pages/sv/HuyDangKy';
import BangDiem from './pages/sv/BangDiem';
import HocPhiCuaToi from './pages/sv/HocPhiCuaToi';
// — Giảng viên —
import LopCuaToi from './pages/gv/LopCuaToi';
import NhapDiem from './pages/gv/NhapDiem';
import ThoiKhoaBieuGV from './pages/gv/ThoiKhoaBieuGV';
// — Phòng Đào tạo —
import QuanLySinhVien from './pages/pdt/QuanLySinhVien';
import KhoaNganhLop from './pages/pdt/KhoaNganhLop';
import MonHocGiangVien from './pages/pdt/MonHocGiangVien';
import MoLopHocPhan from './pages/pdt/MoLopHocPhan';
import DiemCanhBao from './pages/pdt/DiemCanhBao';
import QuanLyHocPhi from './pages/pdt/QuanLyHocPhi';
import TaiKhoan from './pages/pdt/TaiKhoan';

const SV = ['SV'];
const GV = ['GV'];
const PDT = ['PĐT'];

function Home() {
  const user = useSelector(selectUser);
  return <Dashboard role={user?.MaVaiTro || 'SV'} />;
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/" element={<ProtectedRoute><PortalLayout><Home /></PortalLayout></ProtectedRoute>} />
      <Route path="/thong-tin-ca-nhan" element={<ProtectedRoute roles={SV}><PortalLayout><ThongTinCaNhan /></PortalLayout></ProtectedRoute>} />
      <Route path="/dang-ky" element={<ProtectedRoute roles={SV}><PortalLayout><DangKyHocPhan /></PortalLayout></ProtectedRoute>} />
      <Route path="/thoi-khoa-bieu" element={<ProtectedRoute roles={SV}><PortalLayout><ThoiKhoaBieu /></PortalLayout></ProtectedRoute>} />
      <Route path="/dang-ky-cua-toi" element={<ProtectedRoute roles={SV}><PortalLayout><DanhSachDangKy /></PortalLayout></ProtectedRoute>} />
      <Route path="/huy-dang-ky" element={<ProtectedRoute roles={SV}><PortalLayout><HuyDangKy /></PortalLayout></ProtectedRoute>} />
      <Route path="/bang-diem" element={<ProtectedRoute roles={SV}><PortalLayout><BangDiem /></PortalLayout></ProtectedRoute>} />
      <Route path="/hoc-phi" element={<ProtectedRoute roles={SV}><PortalLayout><HocPhiCuaToi /></PortalLayout></ProtectedRoute>} />
      <Route path="/lop-cua-toi" element={<ProtectedRoute roles={GV}><PortalLayout><LopCuaToi /></PortalLayout></ProtectedRoute>} />
      <Route path="/nhap-diem" element={<ProtectedRoute roles={GV}><PortalLayout><NhapDiem /></PortalLayout></ProtectedRoute>} />
      <Route path="/thoi-khoa-bieu-gv" element={<ProtectedRoute roles={GV}><PortalLayout><ThoiKhoaBieuGV /></PortalLayout></ProtectedRoute>} />
      <Route path="/quan-ly/sinh-vien" element={<ProtectedRoute roles={PDT}><PortalLayout><QuanLySinhVien /></PortalLayout></ProtectedRoute>} />
      <Route path="/quan-ly/khoa-nganh-lop" element={<ProtectedRoute roles={PDT}><PortalLayout><KhoaNganhLop /></PortalLayout></ProtectedRoute>} />
      <Route path="/quan-ly/mon-hoc" element={<ProtectedRoute roles={PDT}><PortalLayout><MonHocGiangVien /></PortalLayout></ProtectedRoute>} />
      <Route path="/quan-ly/mo-lhp" element={<ProtectedRoute roles={PDT}><PortalLayout><MoLopHocPhan /></PortalLayout></ProtectedRoute>} />
      <Route path="/quan-ly/diem-canh-bao" element={<ProtectedRoute roles={PDT}><PortalLayout><DiemCanhBao /></PortalLayout></ProtectedRoute>} />
      <Route path="/quan-ly/hoc-phi" element={<ProtectedRoute roles={PDT}><PortalLayout><QuanLyHocPhi /></PortalLayout></ProtectedRoute>} />
      <Route path="/quan-ly/tai-khoan" element={<ProtectedRoute roles={PDT}><PortalLayout><TaiKhoan /></PortalLayout></ProtectedRoute>} />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
