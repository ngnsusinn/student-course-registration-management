/* ==========================================================
   Ten file : web/js/dangky.js
   Module   : Dang ky hoc phan (TV3 — Leader, Issue #71)
   Mo ta    : Logic dang ky hoc phan phia UI — goi API backend
              (SP_DangKyHocPhan / SP_HuyDangKy tren MySQL).
              Ma loi 0/100..106, 200..202 khop SP.
   ========================================================== */

const DK_ERROR_MESSAGES = {
  100: 'Rất tiếc! Hiện tại ngoài thời hạn đăng ký học phần của học kỳ này.',
  101: 'Bạn đã đăng ký lớp học phần này rồi.',
  102: 'Không thể đăng ký! Bạn chưa hoàn thành môn tiên quyết của môn học này.',
  103: 'Đăng ký thất bại! Lớp học phần bị trùng lịch học với lớp bạn đã đăng ký.',
  104: 'Không thể đăng ký! Tổng số tín chỉ vượt quá giới hạn tối đa cho phép.',
  105: 'Đăng ký thất bại! Lớp học phần đã đầy sĩ số (hết chỗ trống).',
  106: 'Lớp học phần không tồn tại hoặc không ở trạng thái mở đăng ký.',
  500: 'Lỗi hệ thống khi xử lý đăng ký.',
};

// ---------- State ----------
let STATE = {
  hocKy: null,
  lopHocPhan: [],
  danhSachDangKy: [],
  tongTinChi: 0,
  maxTinChi: 24,
};

// ---------- Tai du lieu khoi tao ----------
async function loadState() {
  const [hk, lopmo, danhsach] = await Promise.all([
    api.get('/api/dangky/hocky-hientai'),
    api.get('/api/dangky/lopmo'),
    api.get('/api/dangky/danhsach'),
  ]);
  STATE.hocKy = hk.hocKy;
  STATE.lopHocPhan = lopmo.lopHocPhan || [];
  STATE.danhSachDangKy = danhsach.danhSach || [];
  try {
    const tc = await api.get('/api/dangky/tongtinchi');
    STATE.tongTinChi = Number(tc.tongTinChi || 0);
  } catch { STATE.tongTinChi = 0; }
}

// ---------- Dang ky ----------
async function dangKy(MaLHP) {
  if (!requireAuth('SV')) return;
  try {
    const r = await api.post('/api/dangky', { MaLHP, MaxTinChi: STATE.maxTinChi });
    showToast(`✅ ${r.message} — ${MaLHP}`, 'success');
    await refresh();
  } catch (e) {
    if (e.data && e.data.ketQua && DK_ERROR_MESSAGES[e.data.ketQua]) {
      showToast(DK_ERROR_MESSAGES[e.data.ketQua], 'error');
    } else {
      showToast(e.message, 'error');
    }
  }
}

// ---------- Huy dang ky ----------
async function huyDangKy(MaLHP) {
  if (!requireAuth('SV')) return;
  if (!confirm(`Bạn có chắc muốn HỦY đăng ký lớp ${MaLHP}?`)) return;
  try {
    const r = await api.post('/api/dangky/huy', { MaLHP });
    showToast(`✅ ${r.message}`, 'success');
    await refresh();
  } catch (e) {
    showToast(e.message, 'error');
  }
}

// ---------- Refresh toan bo ----------
async function refresh() {
  await loadState();
  renderClassList();
  renderDaDangKy();
  renderDashboard();
  renderThoiKhoaBieu();
  renderDotStatus();
}

// ---------- Render: Dashboard ----------
function renderDashboard() {
  const elTinChi = document.getElementById('stat-tong-tin-chi');
  const elSoLop = document.getElementById('stat-so-lop');
  const elHan = document.getElementById('stat-han-dang-ky');
  const elTrangThai = document.getElementById('stat-trang-thai');
  if (elTinChi) elTinChi.textContent = STATE.tongTinChi + ' TC';
  if (elSoLop) {
    const n = STATE.danhSachDangKy.filter(d => d.TrangThaiDangKy === 'DA_DANG_KY').length;
    elSoLop.textContent = n + ' lớp';
  }
  if (elHan) elHan.textContent = STATE.hocKy ? STATE.hocKy.DenNgay : 'Đã đóng';
  if (elTrangThai) elTrangThai.textContent = STATE.hocKy ? 'Đang mở' : 'Đã đóng';
}

// ---------- Render: Trang thai dot ----------
function renderDotStatus() {
  const badge = document.getElementById('dot-status');
  const badgeWarn = document.getElementById('dot-status-warning');
  const alertEl = document.getElementById('han-huy-alert');
  if (badge) {
    badge.className = STATE.hocKy ? 'badge badge--success' : 'badge badge--error';
    badge.textContent = STATE.hocKy ? `Đợt đang mở (hạn: ${STATE.hocKy.DenNgay})` : 'Đợt đã đóng';
  }
  if (badgeWarn) {
    badgeWarn.textContent = STATE.hocKy ? `Đang mở — hạn hủy: ${STATE.hocKy.DenNgay}` : 'Đợt đã đóng';
  }
  if (alertEl) {
    if (STATE.hocKy) {
      alertEl.className = 'alert alert--success';
      alertEl.innerHTML = '✅ Đợt đăng ký đang mở — bạn có thể đăng ký / hủy các lớp dưới đây.';
    } else {
      alertEl.className = 'alert alert--error';
      alertEl.innerHTML = '❌ Đợt đăng ký đã đóng — bạn KHÔNG thể đăng ký hoặc hủy.';
    }
  }
}

// ---------- Render: Danh sach lop ----------
function renderClassList() {
  const creditCounter = document.getElementById('credit-counter');
  if (creditCounter) {
    creditCounter.textContent = `Đã ĐK: ${STATE.tongTinChi} TC / tối đa ${STATE.maxTinChi} TC`;
  }

  const search = (document.getElementById('search-input')?.value || '').toLowerCase();
  const filterKhoi = document.getElementById('filter-khoi')?.value || '';

  const filtered = STATE.lopHocPhan.filter(c => {
    const matchSearch = !search ||
      c.MaLHP.toLowerCase().includes(search) ||
      (c.TenMonHoc || '').toLowerCase().includes(search) ||
      (c.TenLHP || '').toLowerCase().includes(search);
    let khoi = 'CNTT';
    if (c.MaLHP >= 'LHP509' && c.MaLHP <= 'LHP512') khoi = 'KTT';
    if (c.MaLHP >= 'LHP513') khoi = 'XD';
    const matchKhoi = !filterKhoi || khoi === filterKhoi;
    return matchSearch && matchKhoi;
  });

  const tbody = document.getElementById('class-list-body');
  const empty = document.getElementById('class-list-empty');
  if (!tbody) return;

  const daDangKySet = new Set(
    STATE.danhSachDangKy.filter(d => d.TrangThaiDangKy === 'DA_DANG_KY').map(d => d.MaLHP)
  );

  tbody.innerHTML = filtered.map(c => {
    const daDangKy = daDangKySet.has(c.MaLHP);
    const hetCho = Number(c.SiSoHienTai) >= Number(c.SiSoToiDa);
    return `
    <tr>
        <td><code>${esc(c.MaLHP)}</code></td>
        <td>${esc(c.TenMonHoc)}<br><small class="text-muted">${esc(c.TenLHP || '')}</small></td>
        <td>${c.SoTinChi}</td>
        <td>${esc(c.LichHoc || '—')}</td>
        <td>${formatTiSo(Number(c.SiSoHienTai), Number(c.SiSoToiDa))}</td>
        <td>${esc(c.TenGV || '—')}</td>
        <td>
            ${daDangKy
              ? `<span class="badge badge--success">Đã đăng ký</span>
                 <button class="btn btn--danger btn--sm" onclick="huyDangKy('${c.MaLHP}')">Hủy</button>`
              : hetCho
                ? `<button class="btn btn--primary btn--sm" disabled>Hết chỗ</button>`
                : `<button class="btn btn--success btn--sm" onclick="dangKy('${c.MaLHP}')">Đăng ký</button>`}
        </td>
    </tr>`;
  }).join('');

  if (empty) empty.style.display = filtered.length ? 'none' : 'block';
}

// ---------- Render: Gio dang ky / da dang ky ----------
function renderDaDangKy() {
  const tbody = document.getElementById('registered-body');
  if (!tbody) return;

  const registered = STATE.danhSachDangKy.filter(d => d.TrangThaiDangKy === 'DA_DANG_KY');
  tbody.innerHTML = registered.map(d => `
    <tr>
        <td><code>${esc(d.MaLHP)}</code></td>
        <td>${esc(d.TenMonHoc)}</td>
        <td>${d.SoTinChi}</td>
        <td>${esc(d.NgayDangKy || '')}</td>
        <td>${badgeTrangThaiDangKy(d.TrangThaiDangKy)}</td>
        <td><button class="btn btn--danger btn--sm" onclick="huyDangKy('${d.MaLHP}')">Hủy</button></td>
    </tr>`).join('');

  const empty = document.getElementById('registered-empty');
  if (empty) empty.style.display = registered.length ? 'none' : 'block';

  const total = document.getElementById('registered-total');
  if (total) total.textContent = `${STATE.tongTinChi} TC / ${STATE.maxTinChi} TC`;

  // Màn hình danh sách đăng ký (trang danh-sach-dang-ky.html — 7 cột + tóm tắt)
  if (document.getElementById('stat-tong')) {
    const dsBody = document.getElementById('registered-body');
    const all = STATE.danhSachDangKy;
    dsBody.innerHTML = all.map(d => `
      <tr>
        <td><code>${esc(d.MaLHP)}</code></td>
        <td>${esc(d.TenMonHoc)}</td>
        <td>${esc(d.TenLHP)}</td>
        <td>${d.SoTinChi}</td>
        <td>${esc(d.MaHocKy)}</td>
        <td>${esc(d.NgayDangKy || '')}</td>
        <td>${badgeTrangThaiDangKy(d.TrangThaiDangKy)}</td>
      </tr>`).join('');
    if (empty) empty.style.display = all.length ? 'none' : 'block';

    const statTong = document.getElementById('stat-tong');
    const statMax = document.getElementById('stat-max');
    const statCon = document.getElementById('stat-con');
    if (statTong) statTong.textContent = STATE.tongTinChi + ' TC';
    if (statMax) statMax.textContent = STATE.maxTinChi + ' TC';
    if (statCon) statCon.textContent = Math.max(0, STATE.maxTinChi - STATE.tongTinChi) + ' TC';
  }
}

// ---------- Render: Thoi khoa bieu ----------
function renderThoiKhoaBieu() {
  const tbody = document.getElementById('tkb-body');
  if (!tbody) return;

  const rows = STATE.danhSachDangKy.filter(d => d.TrangThaiDangKy === 'DA_DANG_KY');
  // Lấy lịch từ lớp đã đăng ký qua API thoikhoabieu
  api.get('/api/dangky/thoikhoabieu')
    .then(r => {
      const list = (r.thoiKhoaBieu || []).sort((a, b) => a.Thu - b.Thu || a.TietBatDau - b.TietBatDau);
      tbody.innerHTML = list.map(c => `
        <tr>
            <td>${thuName(c.Thu)}</td>
            <td>Tiết ${c.TietBatDau} - ${Number(c.TietBatDau) + Number(c.SoTiet) - 1}</td>
            <td><code>${esc(c.MaLHP)}</code></td>
            <td>${esc(c.TenMonHoc)}</td>
            <td>${esc(c.TenPhong || '')}</td>
            <td>${esc(c.HoTenGV || '—')}</td>
        </tr>`).join('');
      const empty = document.getElementById('tkb-empty');
      if (empty) empty.style.display = list.length ? 'none' : 'block';
    })
    .catch(() => {
      if (tbody) tbody.innerHTML = `<tr><td colspan="6" class="text-muted">Không tải được thời khóa biểu.</td></tr>`;
    });
}

// ---------- Hien thi ten SV tren header ----------
function renderUserInfo() {
  const u = api.getUser();
  const el = document.getElementById('user-name');
  if (el && u) el.textContent = `${u.HoTen} (${u.MaSV || u.MaGV || u.TenDangNhap})`;
}

// ---------- Khoi dong trang ----------
async function initPage() {
  if (!requireAuth('SV')) return;
  try {
    await loadState();
    renderDashboard();
    renderClassList();
    renderDaDangKy();
    renderThoiKhoaBieu();
    renderDotStatus();
    renderUserInfo();
  } catch (e) {
    showToast(e.message, 'error');
  }
}

document.addEventListener('DOMContentLoaded', initPage);
