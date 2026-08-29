/* ==========================================================
   Ten file : web/js/api.js
   Mo ta    : API client — goi backend Express (JWT), luu token
              trong localStorage, tu dong dinh kem Authorization.
   Cach dung: const data = await api.get('/danhmuc/khoa');
              const r = await api.post('/dangky', { MaLHP });
   ========================================================== */

const API_BASE = (window.API_BASE || '').replace(/\/$/, '') || '';

const api = {
  // ---------- Token & user ----------
  getToken() {
    return localStorage.getItem('dk_token');
  },
  getUser() {
    try { return JSON.parse(localStorage.getItem('dk_user') || 'null'); }
    catch { return null; }
  },
  setSession(token, user) {
    localStorage.setItem('dk_token', token);
    localStorage.setItem('dk_user', JSON.stringify(user));
  },
  clearSession() {
    localStorage.removeItem('dk_token');
    localStorage.removeItem('dk_user');
  },
  isAuthed() {
    return !!this.getToken();
  },
  hasRole(...roles) {
    const u = this.getUser();
    return !!u && roles.includes(u.MaVaiTro);
  },

  // ---------- Fetch wrapper ----------
  async request(method, path, body) {
    const headers = { 'Content-Type': 'application/json' };
    const token = this.getToken();
    if (token) headers.Authorization = `Bearer ${token}`;

    let res;
    try {
      res = await fetch(API_BASE + path, {
        method,
        headers,
        body: body !== undefined ? JSON.stringify(body) : undefined,
      });
    } catch (e) {
      throw new Error('Không kết nối được máy chủ. Vui lòng kiểm tra backend đang chạy.');
    }

    let data = null;
    const text = await res.text();
    try { data = text ? JSON.parse(text) : null; } catch { data = text; }

    if (res.status === 401) {
      // Token het han -> dang xuat tu dong (duong dan tuy doi, dung o moi thu muc)
      this.clearSession();
      if (!location.pathname.endsWith('/login.html')) {
        location.href = '/login.html';
      }
    }
    if (!res.ok) {
      const err = new Error((data && (data.error || data.message)) || `Lỗi HTTP ${res.status}`);
      err.status = res.status;
      err.data = data;
      throw err;
    }
    return data;
  },

  get(path) { return this.request('GET', path); },
  post(path, body) { return this.request('POST', path, body); },
  put(path, body) { return this.request('PUT', path, body); },
  del(path) { return this.request('DELETE', path); },

  // ---------- Auth ----------
  async login(TenDangNhap, MatKhau) {
    const data = await this.request('POST', '/api/auth/login', { TenDangNhap, MatKhau });
    this.setSession(data.token, data.user);
    return data.user;
  },
  logout() {
    this.clearSession();
    location.href = '/login.html';
  },
};

// ---------- Format tien VND ----------
function fmtMoney(n) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND', maximumFractionDigits: 0 }).format(Number(n || 0));
}

// ---------- Thu trong tuan ----------
function thuName(t) {
  return { 2: 'Thứ Hai', 3: 'Thứ Ba', 4: 'Thứ Tư', 5: 'Thứ Năm', 6: 'Thứ Sáu', 7: 'Thứ Bảy', 8: 'Chủ nhật' }[t] || 'Thứ ' + t;
}
