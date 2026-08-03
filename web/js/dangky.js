/* ==========================================================
   Tên file : web/js/dangky.js
   Module   : Đăng ký học phần (TV3 — Leader, Issue #71)
   Mô tả    : Logic đăng ký học phần phía UI.
              Mô phỏng 5 ràng buộc + mã lỗi giống SP_DangKyHocPhan.
              Khi có backend, thay các hàm local bằng fetch API.
========================================================== */

// ---------- Tiện ích ----------
function getRegisteredLHP() {
    return MOCK.registrations.filter(r => r.trangThai === 'DA_DANG_KY').map(r => r.MaLHP);
}
function getClass(MaLHP) {
    return MOCK.classes.find(c => c.MaLHP === MaLHP);
}

// ---------- Tổng tín chỉ đã đăng ký ----------
function getTongTinChiDaDangKy() {
    return getRegisteredLHP().reduce((sum, lhp) => sum + (getClass(lhp)?.soTinChi || 0), 0);
}

// ---------- Kiểm tra 5 ràng buộc (mã lỗi giống SP) ----------
// Trả về { ok: true } hoặc { ok: false, maLoi, message }
function kiemTraDangKy(MaLHP) {
    // Bước 1: Hạn đăng ký (mã 100)
    const dot = getDotHienTai();
    if (!dot) {
        return { ok: false, maLoi: 100, message: 'Rất tiếc! Hiện tại ngoài thời hạn đăng ký học phần của học kỳ này.' };
    }

    // Bước 2: Đăng ký trùng LHP (mã 101)
    if (getRegisteredLHP().includes(MaLHP)) {
        return { ok: false, maLoi: 101, message: `Bạn đã đăng ký lớp học phần ${MaLHP} rồi.` };
    }

    const cls = getClass(MaLHP);
    if (!cls) {
        return { ok: false, maLoi: 106, message: `Không tồn tại lớp học phần: ${MaLHP}` };
    }

    // Bước 3: Môn tiên quyết (mã 102) — mock theo cấu hình
    const PREREQ = {
        'LHP501': ['MH004'], 'LHP502': ['MH006'], 'LHP503': ['MH004'],
        'LHP504': ['MH003'], 'LHP505': ['MH009'], 'LHP507': ['MH012'],
        'LHP508': ['MH007'], 'LHP514': ['MH033'], 'LHP516': ['MH035'],
    };
    const require = PREREQ[MaLHP] || [];
    const thieu = require.filter(m => !MOCK.passedSubjects.includes(m));
    if (thieu.length > 0) {
        return { ok: false, maLoi: 102, message: 'Không thể đăng ký! Bạn chưa hoàn thành môn học tiên quyết: ' + thieu.join(', ') + '.' };
    }

    // Bước 4: Trùng lịch học (mã 103)
    for (const lhpDaDK of getRegisteredLHP()) {
        const c = getClass(lhpDaDK);
        if (!c) continue;
        // Cùng Thứ + khung tiết giao nhau
        if (c.thu === cls.thu &&
            c.tietBatDau <= cls.tietBatDau + cls.soTiet - 1 &&
            c.tietBatDau + c.soTiet - 1 >= cls.tietBatDau) {
            return { ok: false, maLoi: 103, message: `Đăng ký thất bại! Lớp học phần ${MaLHP} bị trùng lịch học với lớp ${lhpDaDK} (Thứ ${c.thu}, tiết ${c.tietBatDau}-${c.tietBatDau + c.soTiet - 1}).` };
        }
    }

    // Bước 5: Giới hạn tín chỉ (mã 104)
    const tongMoi = getTongTinChiDaDangKy() + cls.soTinChi;
    if (tongMoi > MOCK.currentStudent.maxTinChi) {
        return { ok: false, maLoi: 104, message: `Không thể đăng ký! Tổng số tín chỉ sau khi thêm (${tongMoi} TC) vượt quá giới hạn tối đa cho phép (${MOCK.currentStudent.maxTinChi} TC) trong học kỳ này.` };
    }

    // Bước 6: Sĩ số (mã 105)
    if (cls.siSoHienTai >= cls.siSoToiDa) {
        return { ok: false, maLoi: 105, message: `Đăng ký thất bại! Lớp học phần ${MaLHP} đã đầy sĩ số (Hết chỗ trống).` };
    }

    return { ok: true };
}

// ---------- Đăng ký ----------
function dangKy(MaLHP) {
    const kq = kiemTraDangKy(MaLHP);
    if (!kq.ok) {
        showToast(kq.message, 'error');
        return false;
    }
    const cls = getClass(MaLHP);
    cls.siSoHienTai += 1;
    MOCK.registrations.push({
        MaLHP, trangThai: 'DA_DANG_KY',
        ngayDangKy: new Date().toISOString().slice(0, 19).replace('T', ' '),
        ghiChu: null,
    });
    showToast(`✅ Đăng ký học phần THÀNH CÔNG: ${MaLHP} (${cls.mon})`, 'success');
    renderClassList();
    renderDashboard();
    return true;
}

// ---------- Hủy đăng ký ----------
function huyDangKy(MaLHP) {
    const dot = getDotHienTai();
    if (!dot) {
        showToast('Rất tiếc! Hiện tại ngoài thời hạn hủy đăng ký học phần.', 'error');
        return;
    }
    const rec = MOCK.registrations.find(r => r.MaLHP === MaLHP && r.trangThai === 'DA_DANG_KY');
    if (!rec) {
        showToast(`Không tìm thấy bản ghi đăng ký học phần ${MaLHP} đang hiệu lực.`, 'error');
        return;
    }
    rec.trangThai = 'DA_HUY';
    const cls = getClass(MaLHP);
    if (cls) cls.siSoHienTai -= 1;
    showToast(`✅ Hủy đăng ký THÀNH CÔNG: ${MaLHP}`, 'success');
    renderClassList();
    renderDashboard();
}

// ---------- Render: Dashboard ----------
function renderDashboard() {
    const elTinChi = document.getElementById('stat-tong-tin-chi');
    const elSoLop = document.getElementById('stat-so-lop');
    const elHan = document.getElementById('stat-han-dang-ky');
    const elTrangThai = document.getElementById('stat-trang-thai');

    if (elTinChi) elTinChi.textContent = getTongTinChiDaDangKy() + ' TC';
    if (elSoLop) elSoLop.textContent = getRegisteredLHP().length + ' lớp';
    if (elHan) {
        const dot = getDotHienTai();
        elHan.textContent = dot ? dot.denNgay : 'Đã đóng';
    }
    if (elTrangThai) {
        const dot = getDotHienTai();
        elTrangThai.textContent = dot ? 'Đang mở' : 'Đã đóng';
    }
}

// ---------- Render: Danh sách lớp ----------
function renderClassList() {
    // Cập nhật bộ đếm tín chỉ (trên trang đăng ký)
    const creditCounter = document.getElementById('credit-counter');
    if (creditCounter) {
        creditCounter.textContent = `Đã ĐK: ${getTongTinChiDaDangKy()} TC / tối đa ${MOCK.currentStudent.maxTinChi} TC`;
    }

    const search = (document.getElementById('search-input')?.value || '').toLowerCase();
    const filterKhoi = document.getElementById('filter-khoi')?.value || '';

    const filtered = MOCK.classes.filter(c => {
        const matchSearch = !search ||
            c.MaLHP.toLowerCase().includes(search) ||
            c.mon.toLowerCase().includes(search);
        // Map khối theo mã môn (đơn giản hoá)
        let khoi = 'CNTT';
        if (c.MaLHP >= 'LHP509' && c.MaLHP <= 'LHP512') khoi = 'KTT';
        if (c.MaLHP >= 'LHP513') khoi = 'XD';
        const matchKhoi = !filterKhoi || khoi === filterKhoi;
        return matchSearch && matchKhoi;
    });

    const tbody = document.getElementById('class-list-body');
    const empty = document.getElementById('class-list-empty');
    if (!tbody) return;

    const registered = getRegisteredLHP();

    tbody.innerHTML = filtered.map(c => {
        const daDangKy = registered.includes(c.MaLHP);
        const hetCho = c.siSoHienTai >= c.siSoToiDa;
        return `
        <tr>
            <td><code>${esc(c.MaLHP)}</code></td>
            <td>${esc(c.tenLop)}</td>
            <td>${esc(c.mon)}</td>
            <td>${c.soTinChi}</td>
            <td>${formatTiSo(c.siSoHienTai, c.siSoToiDa)}</td>
            <td>${esc(c.giangVien)}</td>
            <td>
                ${daDangKy
                    ? `<span class="badge badge--success">Đã đăng ký</span>
                       <button class="btn btn--danger btn--sm" onclick="huyDangKy('${c.MaLHP}')">Hủy</button>`
                    : hetCho
                        ? `<button class="btn btn--primary btn--sm" disabled>Hết chỗ</button>`
                        : `<button class="btn btn--success btn--sm" onclick="dangKy('${c.MaLHP}')">Đăng ký</button>`
                }
            </td>
        </tr>`;
    }).join('');

    if (empty) empty.style.display = filtered.length ? 'none' : 'block';
}

// ---------- Render: Giỏ đăng ký / đã đăng ký ----------
function renderDaDangKy() {
    const tbody = document.getElementById('registered-body');
    if (!tbody) return;

    const registered = MOCK.registrations.filter(r => r.trangThai === 'DA_DANG_KY');
    tbody.innerHTML = registered.map(r => {
        const c = getClass(r.MaLHP);
        if (!c) return '';
        return `
        <tr>
            <td><code>${esc(c.MaLHP)}</code></td>
            <td>${esc(c.mon)}</td>
            <td>${c.soTinChi}</td>
            <td>${esc(r.ngayDangKy)}</td>
            <td><span class="badge badge--success">Đã đăng ký</span></td>
            <td><button class="btn btn--danger btn--sm" onclick="huyDangKy('${c.MaLHP}')">Hủy</button></td>
        </tr>`;
    }).join('');

    // Empty state
    const empty = document.getElementById('registered-empty');
    if (empty) empty.style.display = registered.length ? 'none' : 'block';

    const total = document.getElementById('registered-total');
    if (total) total.textContent = getTongTinChiDaDangKy() + ' TC / ' + MOCK.currentStudent.maxTinChi + ' TC';
}

// ---------- Render: Thời khóa biểu ----------
function renderThoiKhoaBieu() {
    const tbody = document.getElementById('tkb-body');
    if (!tbody) return;

    const registered = getRegisteredLHP().map(getClass).filter(Boolean)
        .sort((a, b) => a.thu - b.thu || a.tietBatDau - b.tietBatDau);

    const thuNames = { 2: 'Thứ Hai', 3: 'Thứ Ba', 4: 'Thứ Tư', 5: 'Thứ Năm', 6: 'Thứ Sáu', 7: 'Thứ Bảy', 8: 'Chủ nhật' };

    tbody.innerHTML = registered.map(c => `
        <tr>
            <td>${thuNames[c.thu]}</td>
            <td>Tiết ${c.tietBatDau} - ${c.tietBatDau + c.soTiet - 1}</td>
            <td><code>${esc(c.MaLHP)}</code></td>
            <td>${esc(c.mon)}</td>
            <td>${esc(c.giangVien)}</td>
        </tr>`).join('');

    const empty = document.getElementById('tkb-empty');
    if (empty) empty.style.display = registered.length ? 'none' : 'block';
}

// ---------- Render theo trang hiện tại ----------
function initPage() {
    renderDashboard();
    if (document.getElementById('class-list-body')) renderClassList();
    if (document.getElementById('registered-body')) renderDaDangKy();
    if (document.getElementById('tkb-body')) renderThoiKhoaBieu();
}

document.addEventListener('DOMContentLoaded', initPage);
