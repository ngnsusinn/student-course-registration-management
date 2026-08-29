/* ==========================================================
   Ten file : web/js/shared.js
   Mo ta    : Ham dung chung: toast, format, escape, auth guard,
              layout portal (topbar + header + navbar + footer),
              menu theo vai tro (SV / GV / PĐT), doi mat khau,
              dong ho thoi gian thuc.
   Luu y    : Toan bo lien ket dung duong dan tuy doi (bat dau
              bang '/') de chay dung o moi thu muc web/app/...
   ========================================================== */

// ---------- Dinh danh don vi — theo mau Portal UTH (dinh dang lai tai day) ----------
const SCHOOL = {
  name: 'TRƯỜNG ĐẠI HỌC GIAO THÔNG VẬN TẢI TP. HỒ CHÍ MINH',
  short: 'UTH',
  system: 'Cổng thông tin Đào tạo theo hệ thống tín chỉ',
  logo: '/images/logo_full.png',
  address: 'Cơ sở chính, TP. Hồ Chí Minh',
  email: 'phongdaotao@uth.edu.vn',
  supportEmail: 'hotro.dangky@uth.edu.vn',
  hours: 'Thứ 2 – Thứ 6: 07:30 – 16:30',
};

// Logo truong (dung the <img>); giu ten ham cu de cac noi goi khong doi
function schoolCrest(size) {
  const s = size || 46;
  return `<img src="${SCHOOL.logo}" alt="Logo ${esc(SCHOOL.short)}" style="height:${s}px;width:auto">`;
}

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

// ---------- Menu theo vai tro (duong dan tuy doi) ----------
function menuVaiTro(activePath) {
  const u = api.getUser();
  const role = u ? u.MaVaiTro : 'SV';
  const items = [];

  if (role === 'SV') {
    items.push(
      { href: '/index.html', icon: '🏠', label: 'Trang chủ' },
      { href: '/app/dangky_hocphan/dang-ky.html', icon: '📝', label: 'Đăng ký học phần' },
      { href: '/app/dangky_hocphan/thoi-khoa-bieu.html', icon: '🗓️', label: 'Thời khóa biểu' },
      { href: '/app/dangky_hocphan/danh-sach-dang-ky.html', icon: '📋', label: 'Học phần đã đăng ký' },
      { href: '/app/dangky_hocphan/huy-dang-ky.html', icon: '🚫', label: 'Hủy đăng ký' },
      { href: '/app/diem/bang-diem.html', icon: '🎓', label: 'Kết quả học tập' },
      { href: '/app/hocphi/hoc-phi-cua-toi.html', icon: '💰', label: 'Học phí' },
    );
  } else if (role === 'GV') {
    items.push(
      { href: '/index.html', icon: '🏠', label: 'Trang chủ' },
      { href: '/app/giangvien/lop-cua-toi.html', icon: '👨‍🏫', label: 'Lớp học phần của tôi' },
      { href: '/app/giangvien/nhap-diem.html', icon: '✏️', label: 'Nhập điểm' },
      { href: '/app/giangvien/thoi-khoa-bieu-gv.html', icon: '🗓️', label: 'Thời khóa biểu' },
    );
  } else { // PĐT
    items.push(
      { href: '/index.html', icon: '🏠', label: 'Trang chủ' },
      { href: '/app/admin/dashboard.html', icon: '📊', label: 'Bảng điều hành' },
      { href: '/app/danhmuc/sinh-vien.html', icon: '👥', label: 'Quản lý sinh viên' },
      { href: '/app/danhmuc/khoa-nganh-lop.html', icon: '🏛️', label: 'Khoa · Ngành · Lớp' },
      { href: '/app/hocphan/mon-hoc-giang-vien.html', icon: '📚', label: 'Môn học · Giảng viên' },
      { href: '/app/hocphan/mo-lop-hoc-phan.html', icon: '➕', label: 'Mở lớp học phần' },
      { href: '/app/diem/nhap-diem-pdt.html', icon: '📈', label: 'Điểm & Cảnh báo học vụ' },
      { href: '/app/hocphi/quan-ly-hoc-phi.html', icon: '💰', label: 'Quản lý học phí' },
      { href: '/app/admin/tai-khoan.html', icon: '🔑', label: 'Tài khoản & Phân quyền' },
    );
  }
  return items.map(it => {
    const active = activePath && it.href.endsWith('/' + activePath) ? ' app-nav__link--active' : '';
    return `<a href="${it.href}" class="app-nav__link${active}"><span class="app-nav__icon">${it.icon}</span>${esc(it.label)}</a>`;
  }).join('');
}

function menuItemByPath(pathname) {
  const all = {
    '/index.html': 'Trang chủ',
    '/app/dangky_hocphan/dang-ky.html': 'Đăng ký học phần',
    '/app/dangky_hocphan/thoi-khoa-bieu.html': 'Thời khóa biểu',
    '/app/dangky_hocphan/danh-sach-dang-ky.html': 'Học phần đã đăng ký',
    '/app/dangky_hocphan/huy-dang-ky.html': 'Hủy đăng ký',
    '/app/diem/bang-diem.html': 'Kết quả học tập',
    '/app/hocphi/hoc-phi-cua-toi.html': 'Học phí của tôi',
    '/app/giangvien/lop-cua-toi.html': 'Lớp học phần của tôi',
    '/app/giangvien/nhap-diem.html': 'Nhập điểm',
    '/app/giangvien/thoi-khoa-bieu-gv.html': 'Thời khóa biểu giảng viên',
    '/app/admin/dashboard.html': 'Bảng điều hành',
    '/app/admin/tai-khoan.html': 'Tài khoản & Phân quyền',
    '/app/danhmuc/sinh-vien.html': 'Quản lý sinh viên',
    '/app/danhmuc/khoa-nganh-lop.html': 'Khoa · Ngành · Lớp',
    '/app/hocphan/mon-hoc-giang-vien.html': 'Môn học · Giảng viên',
    '/app/hocphan/mo-lop-hoc-phan.html': 'Mở lớp học phần',
    '/app/diem/nhap-diem-pdt.html': 'Điểm & Cảnh báo học vụ',
    '/app/hocphi/quan-ly-hoc-phi.html': 'Quản lý học phí',
  };
  return all[pathname] || null;
}

// ---------- Avatar + ten ----------
function tenVietTat(hoTen) {
  const parts = String(hoTen || 'NSD').trim().split(/\s+/);
  const last = parts[parts.length - 1] || 'N';
  const first = parts[0] || '';
  return (first.charAt(0) + last.charAt(0)).toUpperCase();
}

// ---------- Topbar (thoi gian thuc + thong tin lien he) ----------
function renderTopbar() {
  if (document.querySelector('.app-topbar')) return;
  const header = document.querySelector('header.app-header');
  if (!header) return;
  const top = document.createElement('div');
  top.className = 'app-topbar';
  top.innerHTML = `
    <div class="app-topbar__inner">
      <span class="app-topbar__school">${schoolCrest(18)}&nbsp; ${esc(SCHOOL.name)} — ${esc(SCHOOL.system)}</span>
      <span class="app-topbar__right">
        <span id="topbar-clock" class="app-topbar__clock"></span>
        <span class="app-topbar__contact">✉ ${esc(SCHOOL.email)}</span>
      </span>
    </div>`;
  header.parentNode.insertBefore(top, header);
  startClock();
}

function startClock() {
  const el = document.getElementById('topbar-clock');
  if (!el) return;
  const fmtDate = new Intl.DateTimeFormat('vi-VN', { weekday: 'long', day: '2-digit', month: '2-digit', year: 'numeric' });
  const tick = () => {
    const d = new Date();
    let s = fmtDate.format(d);
    s = s.charAt(0).toUpperCase() + s.slice(1);
    el.textContent = `🕐 ${s} · ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}:${String(d.getSeconds()).padStart(2, '0')}`;
  };
  tick();
  setInterval(tick, 1000);
}

// ---------- Breadcrumb ----------
function renderBreadcrumb(pageTitle) {
  const main = document.querySelector('main.container');
  if (!main || main.querySelector('.breadcrumb')) return;
  const bc = document.createElement('nav');
  bc.className = 'breadcrumb';
  bc.innerHTML = `<a href="/index.html">🏠 Trang chủ</a><span>›</span><strong>${esc(pageTitle)}</strong>`;
  main.insertBefore(bc, main.firstChild);
}

// ---------- Footer ----------
function renderFooter() {
  const footer = document.querySelector('footer.app-footer');
  if (!footer) return;
  const u = api.getUser();
  const links = [
    { href: '/index.html', label: 'Trang chủ' },
    { href: '/app/dangky_hocphan/dang-ky.html', label: 'Đăng ký học phần' },
    { href: '/app/dangky_hocphan/thoi-khoa-bieu.html', label: 'Thời khóa biểu' },
    { href: '/app/diem/bang-diem.html', label: 'Kết quả học tập' },
    { href: '/app/hocphi/hoc-phi-cua-toi.html', label: 'Học phí' },
  ];
  footer.innerHTML = `
    <div class="app-footer__grid">
      <div class="app-footer__col">
        <div class="app-footer__brand">${schoolCrest(40)}
          <div><strong>${esc(SCHOOL.name)}</strong><br><span>${esc(SCHOOL.system)}</span></div>
        </div>
        <p>📍 ${esc(SCHOOL.address)}<br>
           ✉ ${esc(SCHOOL.email)}</p>
      </div>
      <div class="app-footer__col">
        <h4>Liên kết nhanh</h4>
        ${links.map(l => `<a href="${l.href}">${esc(l.label)}</a>`).join('')}
      </div>
      <div class="app-footer__col">
        <h4>Hỗ trợ người học</h4>
        <p>🕗 ${esc(SCHOOL.hours)}<br>
           Email hỗ trợ đăng ký: ${esc(SCHOOL.supportEmail)}<br>
           Khiếu nại học vụ: liên hệ Phòng Đào tạo</p>
      </div>
    </div>
    <div class="app-footer__bar">
      © ${new Date().getFullYear()} ${esc(SCHOOL.short)} — ${esc(SCHOOL.system)}. Bản demo đồ án môn học (dữ liệu mẫu).
      <span class="app-footer__credit">· Nhóm 5 — Đề tài 6 · v1.0</span>
    </div>`;
}

// ---------- Modal doi mat khau ----------
function openDoiMatKhau() {
  document.getElementById('dmk-mask')?.remove();
  const mask = document.createElement('div');
  mask.id = 'dmk-mask';
  mask.className = 'modal-mask';
  mask.innerHTML = `
    <div class="modal" style="max-width:440px">
      <h3>🔑 Đổi mật khẩu</h3>
      <form id="dmk-form">
        <div class="form-group">
          <label for="dmk-cu">Mật khẩu hiện tại</label>
          <input type="password" class="input" id="dmk-cu" required autocomplete="current-password">
        </div>
        <div class="form-group">
          <label for="dmk-moi">Mật khẩu mới (tối thiểu 6 ký tự)</label>
          <input type="password" class="input" id="dmk-moi" minlength="6" required autocomplete="new-password">
        </div>
        <div class="form-group">
          <label for="dmk-re">Nhập lại mật khẩu mới</label>
          <input type="password" class="input" id="dmk-re" required autocomplete="new-password">
        </div>
        <label style="font-size:13px;color:var(--color-text-muted);display:flex;gap:6px;align-items:center">
          <input type="checkbox" onchange="document.querySelectorAll('#dmk-form input[type=password]').forEach(i=>i.type=this.checked?'text':'password')"> Hiện mật khẩu
        </label>
        <p class="card__note" style="margin-top:10px">Mỗi lần đổi mật khẩu đều được ghi vào nhật ký (trigger <code>TRG_LogDoiMatKhau</code>).</p>
        <div class="modal-actions">
          <button type="button" class="btn btn--outline" onclick="document.getElementById('dmk-mask').remove()">Hủy</button>
          <button type="submit" class="btn btn--primary" id="dmk-submit">Đổi mật khẩu</button>
        </div>
      </form>
    </div>`;
  document.body.appendChild(mask);
  mask.addEventListener('click', e => { if (e.target === mask) mask.remove(); });
  document.getElementById('dmk-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const cu = document.getElementById('dmk-cu').value;
    const moi = document.getElementById('dmk-moi').value;
    const re = document.getElementById('dmk-re').value;
    if (moi.length < 6) return showToast('Mật khẩu mới phải có ít nhất 6 ký tự.', 'error');
    if (moi !== re) return showToast('Mật khẩu nhập lại không khớp.', 'error');
    if (moi === cu) return showToast('Mật khẩu mới không được trùng mật khẩu cũ.', 'error');
    const btn = document.getElementById('dmk-submit');
    btn.disabled = true; btn.textContent = 'Đang xử lý...';
    try {
      const r = await api.post('/api/auth/doimatkhau', { MatKhauCu: cu, MatKhauMoi: moi });
      showToast(`✅ ${r.message}`, 'success');
      mask.remove();
    } catch (err) {
      showToast(err.message || 'Đổi mật khẩu thất bại.', 'error');
      btn.disabled = false; btn.textContent = 'Đổi mật khẩu';
    }
  });
}

// ---------- Render header / navbar / footer chung ----------
function renderLayout(activePath) {
  const u = api.getUser();
  const header = document.querySelector('header.app-header');
  if (!header) return;

  const isHome = location.pathname === '/' || location.pathname.endsWith('/index.html');
  const pageTitle = isHome ? 'Trang chủ'
    : (menuItemByPath(location.pathname)
      || header.querySelector('.app-header__title')?.textContent?.trim()
      || 'Trang');

  renderTopbar();

  // Header trang voi huy hieu + ten 2 dong
  header.classList.add('app-header--portal');
  const brand = header.querySelector('.app-header__brand');
  if (brand) {
    brand.innerHTML = `${schoolCrest(46)}
      <div class="app-header__names">
        <span class="app-header__school">${esc(SCHOOL.name)}</span>
        <span class="app-header__sys">${esc(SCHOOL.system)}</span>
      </div>`;
  }

  // Thanh dieu huong xanh duong ben duoi header
  const nav = header.querySelector('nav.app-nav');
  let strip = document.querySelector('.app-navbar');
  if (!strip && nav) {
    strip = document.createElement('div');
    strip.className = 'app-navbar';
    strip.innerHTML = '<div class="app-navbar__inner"></div>';
    header.insertAdjacentElement('afterend', strip);
    strip.firstElementChild.appendChild(nav);
  }
  if (nav) nav.innerHTML = menuVaiTro(activePath);

  // Khu vuc nguoi dung
  const userBox = header.querySelector('.app-header__user');
  if (userBox) {
    userBox.innerHTML = u
      ? `<div class="user-chip" title="${esc(u.HoTen || '')}">
           <span class="user-chip__avatar">${esc(tenVietTat(u.HoTen))}</span>
           <span class="user-chip__meta">
             <strong>${esc(u.HoTen || u.TenDangNhap)}</strong>
             <small>${esc(u.TenVaiTro || u.MaVaiTro)} · ${esc(u.TenDangNhap)}</small>
           </span>
         </div>
         <button class="btn btn--outline btn--sm" onclick="openDoiMatKhau()">🔑 Đổi mật khẩu</button>
         <button class="btn btn--primary btn--sm" onclick="api.logout()">Đăng xuất</button>`
      : `<a href="/login.html" class="btn btn--primary btn--sm">Đăng nhập</a>`;
  }

  if (!isHome) renderBreadcrumb(pageTitle);
  renderFooter();
}

// ---------- Auth guard ----------
function requireAuth(roles) {
  if (!api.isAuthed()) {
    location.href = '/login.html';
    return false;
  }
  if (roles && !api.hasRole(...roles)) {
    showToast('Bạn không có quyền truy cập chức năng này.', 'error');
    location.href = '/index.html';
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
  let page = location.pathname.replace(/^\//, '');
  if (page === '') page = 'index.html';
  renderLayout(page);
});
