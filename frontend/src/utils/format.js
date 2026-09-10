// ============================================================
// Hàm format dùng chung (tiền VND, thứ, tỉ lệ sĩ số...)
// ============================================================
export const fmtMoney = (n) =>
  new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND', maximumFractionDigits: 0 }).format(Number(n || 0));

export const thuName = (t) =>
  ({ 2: 'Thứ Hai', 3: 'Thứ Ba', 4: 'Thứ Tư', 5: 'Thứ Năm', 6: 'Thứ Sáu', 7: 'Thứ Bảy', 8: 'Chủ nhật' }[t] || 'Thứ ' + t);

export const fmtNgay = (d) => {
  if (!d) return '—';
  const s = String(d);
  return s.includes('T') ? s.slice(0, 10).split('-').reverse().join('/') : s;
};

export const tenVietTat = (hoTen) => {
  const parts = String(hoTen || 'NSD').trim().split(/\s+/);
  return ((parts[0]?.[0] || '') + (parts[parts.length - 1]?.[0] || '')).toUpperCase();
};

// Trạng thái đăng ký / lớp / học phí → màu + nhãn Chip
export const STATUS = {
  DK: {
    DA_DANG_KY: ['success', 'Đã đăng ký'],
    DA_HUY: ['error', 'Đã hủy'],
    CHO_XAC_NHAN: ['warning', 'Chờ xác nhận'],
  },
  LOP: {
    MO_DANG_KY: ['success', 'Mở đăng ký'],
    DONG_DANG_KY: ['warning', 'Đóng đăng ký'],
    DA_KET_THUC: ['default', 'Đã kết thúc'],
  },
  HOCPHI: {
    DA_THANH_TOAN: ['success', 'Đã thanh toán'],
    DANG_XU_LY: ['warning', 'Đang xử lý'],
    CHUA_THANH_TOAN: ['error', 'Chưa thanh toán'],
    QUA_HAN: ['error', 'Quá hạn'],
  },
};

export const statusOf = (group, code) => (STATUS[group] || {})[code] || ['default', code || '—'];

// Mã lỗi nghiệp vụ SP (giống hệt thông báo portal thật)
export const DK_ERRORS = {
  100: 'Rất tiếc! Hiện tại ngoài thời hạn đăng ký học phần của học kỳ này.',
  101: 'Bạn đã đăng ký lớp học phần này rồi.',
  102: 'Không thể đăng ký! Bạn chưa hoàn thành môn tiên quyết của môn học này.',
  103: 'Đăng ký thất bại! Lớp học phần bị trùng lịch học với lớp bạn đã đăng ký.',
  104: 'Không thể đăng ký! Tổng số tín chỉ vượt quá giới hạn tối đa cho phép.',
  105: 'Đăng ký thất bại! Lớp học phần đã đầy sĩ số (hết chỗ trống).',
  106: 'Lớp học phần không tồn tại hoặc không ở trạng thái mở đăng ký.',
  500: 'Lỗi hệ thống khi xử lý đăng ký.',
};

// Lỗi KHÓA của HQTCSDL (Chương 5 — deadlock) trả về từ SP_DangKyNhieuHocPhan.
export const KHOA_ERRORS = {
  1213: 'Xung đột khóa (DEADLOCK 1213): hệ quản trị CSDL đã hủy giao dịch của bạn để giải phóng deadlock. Vui lòng bấm đăng ký lại.',
  1205: 'Chờ khóa quá lâu (TIMEOUT 1205): một giao dịch khác đang giữ khóa. Vui lòng thử lại.',
};
export const HUY_ERRORS = {
  200: 'Rất tiếc! Hiện tại ngoài thời hạn hủy đăng ký học phần.',
  201: 'Không tìm thấy bản ghi đăng ký học phần.',
  202: 'Bản ghi đăng ký không ở trạng thái ĐÃ ĐĂNG KÝ (không thể hủy).',
  500: 'Lỗi hệ thống khi xử lý hủy đăng ký.',
};
