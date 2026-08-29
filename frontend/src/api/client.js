import axios from 'axios';

// ============================================================
// axios client — JWT Bearer + tự đăng xuất khi 401 (như portal)
// Token/user lưu localStorage (key cũ: dk_token / dk_user)
// ============================================================
export const TOKEN_KEY = 'dk_token';
export const USER_KEY = 'dk_user';

export const getToken = () => localStorage.getItem(TOKEN_KEY);
export const getUser = () => {
  try { return JSON.parse(localStorage.getItem(USER_KEY) || 'null'); } catch { return null; }
};
export const setSession = (token, user) => {
  localStorage.setItem(TOKEN_KEY, token);
  localStorage.setItem(USER_KEY, JSON.stringify(user));
};
export const clearSession = () => {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(USER_KEY);
};

const api = axios.create({ baseURL: '/api', timeout: 30000 });

api.interceptors.request.use((config) => {
  const token = getToken();
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401 && !location.pathname.startsWith('/login')) {
      clearSession();
      location.href = '/login';
    }
    return Promise.reject(err);
  }
);

// Rút thông điệp lỗi chuẩn từ response backend
export const errMessage = (e, fallback = 'Đã có lỗi xảy ra.') =>
  e?.response?.data?.error || e?.message || fallback;

export default api;
