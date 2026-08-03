/* ==========================================================
   Tên file : web/js/mock-data.js
   Module   : Đăng ký học phần (TV3)
   Mô tả    : Dữ liệu mẫu phía trình duyệt để demo giao diện.
              Khi kết nối DB thật, thay bằng gọi API.
              Số liệu khớp với dữ liệu trong sql/data/.
========================================================== */

const MOCK = {
    // SV hiện tại đang đăng nhập (demo)
    currentStudent: {
        MaSV: 'SV001',
        HoTen: 'Nguyễn Văn An',
        MaLopSH: 'CNTT01',
        maxTinChi: 24,
    },

    // Học kỳ / đợt đăng ký
    dots: [
        { MaHocKy: 'HK1-2025', ten: 'Học kỳ 1', nam: '2025-2026', tuNgay: '2025-08-20', denNgay: '2027-01-15', trangThai: 'MO' },
    ],

    // Các lớp học phần đang mở (khớp sql/data LHP5xx)
    classes: [
        { MaLHP: 'LHP501', tenLop: 'HQT CSDL K15', mon: 'Hệ quản trị CSDL', soTinChi: 3, siSoHienTai: 24, siSoToiDa: 25, giangVien: 'TS. Trần Lan Chi', thu: 2, tietBatDau: 1, soTiet: 3 },
        { MaLHP: 'LHP502', tenLop: 'CNPM K15', mon: 'Công nghệ phần mềm', soTinChi: 3, siSoHienTai: 18, siSoToiDa: 40, giangVien: 'ThS. Đỗ Thị Mơ', thu: 3, tietBatDau: 1, soTiet: 3 },
        { MaLHP: 'LHP503', tenLop: 'PTTKHT K15', mon: 'Phân tích và thiết kế hệ thống', soTinChi: 3, siSoHienTai: 12, siSoToiDa: 40, giangVien: 'ThS. Đỗ Thị Mơ', thu: 4, tietBatDau: 1, soTiet: 3 },
        { MaLHP: 'LHP504', tenLop: 'AI K15', mon: 'Trí tuệ nhân tạo', soTinChi: 3, siSoHienTai: 9, siSoToiDa: 40, giangVien: 'TS. Bùi Quang Lâm', thu: 5, tietBatDau: 1, soTiet: 3 },
        { MaLHP: 'LHP505', tenLop: 'An toàn TT K15', mon: 'An toàn thông tin', soTinChi: 3, siSoHienTai: 7, siSoToiDa: 40, giangVien: 'TS. Ngô Đình Nam', thu: 6, tietBatDau: 1, soTiet: 3 },
        { MaLHP: 'LHP506', tenLop: 'TA chuyên ngành K15', mon: 'Tiếng Anh chuyên ngành CNTT', soTinChi: 2, siSoHienTai: 15, siSoToiDa: 30, giangVien: 'TS. Nguyễn Minh Hiếu', thu: 2, tietBatDau: 4, soTiet: 2 },
        { MaLHP: 'LHP507', tenLop: 'Hệ điều hành K15', mon: 'Hệ điều hành', soTinChi: 3, siSoHienTai: 5, siSoToiDa: 40, giangVien: 'TS. Bùi Quang Lâm', thu: 3, tietBatDau: 4, soTiet: 3 },
        { MaLHP: 'LHP508', tenLop: 'Mobile K15', mon: 'Lập trình ứng dụng di động', soTinChi: 3, siSoHienTai: 3, siSoToiDa: 35, giangVien: 'PGS.TS. Phạm Thị Hằng', thu: 4, tietBatDau: 4, soTiet: 3 },
        { MaLHP: 'LHP509', tenLop: 'Chứng khoán K15', mon: 'Thị trường chứng khoán', soTinChi: 3, siSoHienTai: 20, siSoToiDa: 40, giangVien: 'TS. Đinh Quang Thắng', thu: 2, tietBatDau: 1, soTiet: 3 },
        { MaLHP: 'LHP510', tenLop: 'Kế toán quản trị K15', mon: 'Kế toán quản trị', soTinChi: 3, siSoHienTai: 14, siSoToiDa: 40, giangVien: 'ThS. Lương Thị Vân', thu: 3, tietBatDau: 1, soTiet: 3 },
        { MaLHP: 'LHP511', tenLop: 'Đầu tư TCQT K15', mon: 'Đầu tư tài chính quốc tế', soTinChi: 3, siSoHienTai: 6, siSoToiDa: 40, giangVien: 'TS. Đinh Quang Thắng', thu: 4, tietBatDau: 1, soTiet: 3 },
        { MaLHP: 'LHP512', tenLop: 'Phân tích BCTC K15', mon: 'Phân tích báo cáo tài chính', soTinChi: 3, siSoHienTai: 11, siSoToiDa: 40, giangVien: 'ThS. Lương Thị Vân', thu: 5, tietBatDau: 1, soTiet: 3 },
        { MaLHP: 'LHP513', tenLop: 'Quy hoạch đô thị K15', mon: 'Quy hoạch đô thị', soTinChi: 3, siSoHienTai: 8, siSoToiDa: 40, giangVien: 'TS. Võ Thị Ngọc', thu: 2, tietBatDau: 1, soTiet: 3 },
        { MaLHP: 'LHP514', tenLop: 'Kết cấu cao tầng K15', mon: 'Kết cấu cao tầng', soTinChi: 3, siSoHienTai: 4, siSoToiDa: 40, giangVien: 'TS. Võ Thị Ngọc', thu: 3, tietBatDau: 1, soTiet: 3 },
        { MaLHP: 'LHP515', tenLop: 'Thẩm định dự án XD K15', mon: 'Thẩm định dự án đầu tư XD', soTinChi: 3, siSoHienTai: 2, siSoToiDa: 40, giangVien: 'ThS. Đào Minh Quân', thu: 4, tietBatDau: 1, soTiet: 3 },
        { MaLHP: 'LHP516', tenLop: 'Công nghệ thi công K15', mon: 'Công nghệ thi công', soTinChi: 3, siSoHienTai: 1, siSoToiDa: 40, giangVien: 'ThS. Phan Văn Thành', thu: 5, tietBatDau: 1, soTiet: 3 },
    ],

    // SV001 đã đăng ký (đã chuyển LHP501 -> LHP505 trong data SQL)
    registrations: [
        { MaLHP: 'LHP505', trangThai: 'DA_DANG_KY', ngayDangKy: '2025-09-05 08:00:00', ghiChu: 'SV tranh chỗ cuối LHP501' },
        { MaLHP: 'LHP502', trangThai: 'DA_DANG_KY', ngayDangKy: '2025-09-05 08:00:00', ghiChu: null },
        { MaLHP: 'LHP503', trangThai: 'DA_DANG_KY', ngayDangKy: '2025-09-05 08:00:00', ghiChu: null },
        { MaLHP: 'LHP504', trangThai: 'DA_DANG_KY', ngayDangKy: '2025-09-05 08:00:00', ghiChu: null },
    ],

    // Các môn SV đã hoàn thành (điểm qua) — để kiểm tra tiên quyết
    passedSubjects: ['MH001', 'MH002', 'MH003', 'MH004', 'MH006', 'MH007', 'MH009'],
};
