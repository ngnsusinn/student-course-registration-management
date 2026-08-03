/* ==========================================================
   Tên file : web/js/shared.js
   Module   : Template UI chung (TV3 — Leader, Issue #72)
   Mô tả    : Các hàm dùng chung: toast, format, render bảng.
========================================================== */

// ---------- Toast ----------
function showToast(message, type = 'info') {
    const container = document.getElementById('toast-container');
    if (!container) return;
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

// ---------- Format ----------
function formatTiSo(hienTai, toiDa) {
    const full = hienTai >= toiDa;
    const soCon = toiDa - hienTai;
    let badge = 'success';
    if (soCon <= 1) badge = 'error';
    else if (soCon <= 3) badge = 'warning';
    return `<span class="badge badge--${badge}">${hienTai}/${toiDa}</span>`;
}

// ---------- Escape HTML (chống XSS khi render dữ liệu) ----------
function esc(str) {
    return String(str ?? '').replace(/[&<>"']/g, c => ({
        '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
    }[c]));
}

// ---------- Đọc trạng thái đợt ----------
function getDotHienTai() {
    const now = new Date();
    const dot = MOCK.dots.find(d => d.trangThai === 'MO' && now >= new Date(d.tuNgay) && now <= new Date(d.denNgay));
    return dot;
}

// ---------- Đăng xuất (mock) ----------
function handleLogout() {
    showToast('Đã đăng xuất (demo).', 'info');
    // Chuyển hướng thật khi có backend:
    // window.location.href = 'login.html';
}
