import { Navigate, useLocation } from 'react-router-dom';
import { useSelector } from 'react-redux';
import { getToken, getUser } from '../api/client';

// Bảo vệ route: bắt buộc đăng nhập + đúng vai trò (như requireRole backend)
export default function ProtectedRoute({ roles, children }) {
  const location = useLocation();
  const token = useSelector((s) => s.auth.token) || getToken();
  const user = useSelector((s) => s.auth.user) || getUser();

  if (!token || !user) return <Navigate to="/login" replace state={{ from: location }} />;
  if (roles && !roles.includes(user.MaVaiTro)) return <Navigate to="/" replace />;
  return children;
}
