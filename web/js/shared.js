/* ==========================================================
   Ten file : web/js/shared.js
   Mo ta    : Ham dung chung: toast, format, escape, auth guard,
              menu dieu huong theo vai tro (SV / GV / PĐT).
   ========================================================== */

// ---------- Toast ----------
function showToast(message, type = 'info') {
  let container = document.getElementById('toast-container');
  if (!container) {
    container = document.createElement('div');
    container.id = 'toast-container';
    container.className = 'toast-container';
    document.body.appendChild(container);
  }
  const toast = document.createElement('div');
  toast.className = `toast toast--${type}`;
  toast.textContent = message;
  container.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transition = 'opacity .3s';
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

// ---------- Escape HTML (chong XSS) ----------
function esc(str) {
  return String(str ?? '').replace(/[&<>"']/g, c => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  }[c]));
}

// ---------- Format so tien ----------
function fmtMoney(n) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND', maximumFractionDigits: 0 }).format(Number(n || 0));
}

// ---------- Badge trang thai ----------
function badgeTrangThaiDangKy(tt) {
  const map = {
    'DA_DANG_KY': ['success', 'Đã đăng ký'],
    'DA_HUY': ['error', 'Đã hủy'],
    'CHO_XAC_NHAN': ['warning', 'Chờ xác nhận'],
  };
  const [cls, label] = map[tt] || ['info', tt];
  return `<span class="badge badge--${cls}">${label}</span>`;
}

function badgeTrangThaiLop(tt) {
  const map = {
    'MO_DANG_KY': ['success', 'Mở đăng ký'],
    'DONG_DANG_KY': ['warning', 'Đóng đăng ký'],
    'DA_KET_THUC': ['info', 'Đã kết thúc'],
  };
  const [cls, label] = map[tt] || ['info', tt];
  return `<span class="badge badge--${cls}">${label}</span>`;
}

function badgeHocPhi(tt) {
  const map = {
    'DA_THANH_TOAN': ['success', 'Đã thanh toán'],
    'DANG_XU_LY': ['warning', 'Đang xử lý'],
    'CHUA_THANH_TOAN': ['error', 'Chưa thanh toán'],
    'QUA_HAN': ['error', 'Quá hạn'],
  };
  const [cls, label] = map[tt] || ['info', tt];
  return `<span class="badge badge--${cls}">${label}</span>`;
}

// ---------- Thu trong tuan ----------
function thuName(t) {
  return { 2: 'Thứ Hai', 3: 'Thứ Ba', 4: 'Thứ Tư', 5: 'Thứ Năm', 6: 'Thứ Sáu', 7: 'Thứ Bảy', 8: 'Chủ nhật' }[t] || 'Thứ ' + t;
}

// ---------- Badge si so ----------
function formatTiSo(hienTai, toiDa) {
  const soCon = toiDa - hienTai;
  let badge = 'success';
  if (soCon <= 0) badge = 'error';
  else if (soCon <= 3) badge = 'warning';
  return `<span class="badge badge--${badge}">${hienTai}/${toiDa}</span>`;
}

// ---------- Menu theo vai tro ----------
function menuVaiTro(activePath) {
  const u = api.getUser();
  const role = u ? u.MaVaiTro : 'SV';
  const items = [];

  if (role === 'SV') {
    items.push(
      { href: 'index.html', label: 'Trang chủ' },
      { href: 'app/dangky_hocphan/dang-ky.html', label: 'Đăng ký học phần' },
      { href: 'app/dangky_hocphan/thoi-khoa-bieu.html', label: 'Thời khóa biểu' },
      { href: 'app/dangky_hocphan/danh-sach-dang-ky.html', label: 'Danh sách đăng ký' },
      { href: 'app/dangky_hocphan/huy-dang-ky.html', label: 'Hủy đăng ký' },
      { href: 'app/diem/bang-diem.html', label: 'Bảng điểm' },
      { href: 'app/hocphi/hoc-phi-cua-toi.html', label: 'Học phí' },
    );
  } else if (role === 'GV') {
    items.push(
      { href: 'index.html', label: 'Trang chủ' },
      { href: 'app/giangvien/lop-cua-toi.html', label: 'Lớp của tôi' },
      { href: 'app/giangvien/nhap-diem.html', label: 'Nhập điểm' },
      { href: 'app/giangvien/thoi-khoa-bieu-gv.html', label: 'Thời khóa biểu' },
    );
  } else { // PĐT
    items.push(
      { href: 'index.html', label: 'Trang chủ' },
      { href: 'app/admin/dashboard.html', label: 'Dashboard' },
      { href: 'app/danhmuc/sinh-vien.html', label: 'Quản lý SV' },
      { href: 'app/danhmuc/khoa-nganh-lop.html', label: 'Khoa · Ngành · Lớp' },
      { href: 'app/hocphan/mon-hoc-giang-vien.html', label: 'Môn học · GV' },
      { href: 'app/hocphan/mo-lop-hoc-phan.html', label: 'Mở LHP' },
      { href: 'app/diem/nhap-diem-pdt.html', label: 'Điểm & Cảnh báo' },
      { href: 'app/hocphi/quan-ly-hoc-phi.html', label: 'Học phí' },
      { href: 'app/admin/tai-khoan.html', label: 'Tài khoản' },
    );
  }
  return items.map(it => {
    const active = activePath && it.href.endsWith(activePath) ? ' app-nav__link--active' : '';
    return `<a href="${it.href}" class="app-nav__link${active}">${esc(it.label)}</a>`;
  }).join('');
}

// ---------- Render header / footer chung ----------
function renderLayout(activePath) {
  const u = api.getUser();
  const header = document.querySelector('header.app-header');
  if (header) {
    const brand = header.querySelector('.app-header__brand');
    if (brand) {
      const h1 = brand.querySelector('h1');
      const title = h1 ? h1.textContent : 'Hệ thống';
      header.querySelector('.app-header__brand').innerHTML =
        `<span class="app-header__logo">🎓</span><h1 class="app-header__title">${esc(title)}</h1>`;
    }
    const nav = header.querySelector('nav.app-nav');
    if (nav) nav.innerHTML = menuVaiTro(activePath);

    const userBox = header.querySelector('.app-header__user');
    if (userBox) {
      userBox.innerHTML = u
        ? `<span>👤 ${esc(u.HoTen || u.TenDangNhap)}</span>
           <span class="badge badge--info">${esc(u.TenVaiTro || u.MaVaiTro)}</span>
           <button class="btn btn--outline btn--sm" onclick="api.logout()">Đăng xuất</button>`
        : `<a href="login.html" class="btn btn--primary btn--sm">Đăng nhập</a>`;
    }
  }
}

// ---------- Auth guard ----------
function requireAuth(roles) {
  if (!api.isAuthed()) {
    location.href = 'login.html';
    return false;
  }
  if (roles && !api.hasRole(...roles)) {
    showToast('Bạn không có quyền truy cập chức năng này.', 'error');
    location.href = 'index.html';
    return false;
  }
  return true;
}

// ---------- Handler loi API ----------
async function runApi(fn, okMsg) {
  try {
    const data = await fn();
    if (okMsg) showToast(okMsg, 'success');
    return data;
  } catch (e) {
    showToast(e.message || 'Đã có lỗi xảy ra.', 'error');
    return null;
  }
}

// ---------- Khoi tao layout khi DOM ready ----------
document.addEventListener('DOMContentLoaded', () => {
  const page = location.pathname.split('/').pop();
  renderLayout(page);
});
