-- ==========================================================
-- Ten file : mysql/data/00_danh_muc_hoso_sv_data.sql
-- Module   : Danh muc he thong & Ho so sinh vien (TV1)
-- Mo ta    : 3 Khoa, 6 Nganh, 10 Lop, 60 Sinh vien.
-- ==========================================================

-- 1. KHOA
INSERT INTO KHOA (MaKhoa, TenKhoa, DienThoaiKhoa, EmailKhoa) VALUES
('CNTT', 'Công nghệ thông tin', '02435581234', 'cntt@univ.edu.vn'),
('KTT',  'Kinh tế - Tài chính',  '02435585678', 'ktt@univ.edu.vn'),
('XD',   'Xây dựng',             '02435589876', 'xd@univ.edu.vn');

-- 2. NGANH
INSERT INTO NGANH (MaNganh, TenNganh, ThoiGianDaoTao, MaKhoa) VALUES
('CN', 'Công nghệ thông tin', 4.0, 'CNTT'),
('KTMT', 'Kỹ thuật máy tính', 4.0, 'CNTT'),
('QTKD', 'Quản trị kinh doanh', 4.0, 'KTT'),
('TCNH', 'Tài chính ngân hàng', 4.0, 'KTT'),
('XDDS', 'Xây dựng dân dụng', 4.5, 'XD'),
('XDDD', 'Xây dựng đô thị', 4.5, 'XD');

-- 3. LOP_SINHHOAT
INSERT INTO LOP_SINHHOAT (MaLopSH, TenLopSH, NienKhoa, MaNganh) VALUES
('CNTT01', 'CNTT01 - Khóa 2022', 2022, 'CN'),
('CNTT02', 'CNTT02 - Khóa 2022', 2022, 'CN'),
('CNTT03', 'CNTT03 - Khóa 2022', 2022, 'CN'),
('KTMT01', 'KTMT01 - Khóa 2022', 2022, 'KTMT'),
('QTKD01', 'QTKD01 - Khóa 2022', 2022, 'QTKD'),
('QTKD02', 'QTKD02 - Khóa 2022', 2022, 'QTKD'),
('TCNH01', 'TCNH01 - Khóa 2022', 2022, 'TCNH'),
('XDDS01', 'XDDS01 - Khóa 2022', 2022, 'XDDS'),
('XDDD01', 'XDDD01 - Khóa 2022', 2022, 'XDDD'),
('XDDD02', 'XDDD02 - Khóa 2022', 2022, 'XDDD');

-- 4. SINHVIEN (60 SV)
INSERT INTO SINHVIEN (MaSV, HoTen, NgaySinh, GioiTinh, Email, SoDienThoai, QueQuan, TrangThaiHoc, MaLopSH) VALUES
('SV001', 'Nguyễn Văn An',    '2004-01-15', 1, 'sv001@univ.edu.vn', '0912345001', 'Hà Nội',      1, 'CNTT01'),
('SV002', 'Trần Thị Bích',    '2004-02-20', 0, 'sv002@univ.edu.vn', '0912345002', 'Hải Phòng',   1, 'CNTT01'),
('SV003', 'Lê Minh Cường',    '2004-03-10', 1, 'sv003@univ.edu.vn', '0912345003', 'Bắc Ninh',    1, 'CNTT01'),
('SV004', 'Phạm Thị Dung',    '2004-04-05', 0, 'sv004@univ.edu.vn', '0912345004', 'Nghệ An',     1, 'CNTT01'),
('SV005', 'Hoàng Văn Đạt',    '2004-05-12', 1, 'sv005@univ.edu.vn', '0912345005', 'Thái Nguyên', 1, 'CNTT01'),
('SV006', 'Vũ Thị Hoa',       '2004-06-18', 0, 'sv006@univ.edu.vn', '0912345006', 'Nam Định',    1, 'CNTT02'),
('SV007', 'Đặng Quang Huy',   '2004-07-25', 1, 'sv007@univ.edu.vn', '0912345007', 'Hà Tĩnh',     1, 'CNTT02'),
('SV008', 'Bùi Thị Lan',      '2004-08-30', 0, 'sv008@univ.edu.vn', '0912345008', 'Quảng Ninh',  1, 'CNTT02'),
('SV009', 'Ngô Văn Long',     '2004-09-14', 1, 'sv009@univ.edu.vn', '0912345009', 'Hà Nam',      1, 'CNTT02'),
('SV010', 'Đỗ Thị Mai',       '2004-10-01', 0, 'sv010@univ.edu.vn', '0912345010', 'Vĩnh Phúc',   1, 'CNTT02'),
('SV011', 'Trịnh Văn Nam',    '2003-11-11', 1, 'sv011@univ.edu.vn', '0912345011', 'Bắc Giang',   1, 'CNTT03'),
('SV012', 'Đinh Thị Ngọc',    '2003-12-21', 0, 'sv012@univ.edu.vn', '0912345012', 'Thanh Hóa',   1, 'CNTT03'),
('SV013', 'Lương Văn Phúc',   '2004-01-03', 1, 'sv013@univ.edu.vn', '0912345013', 'Hưng Yên',    1, 'CNTT03'),
('SV014', 'Nguyễn Thị Quỳnh', '2004-02-07', 0, 'sv014@univ.edu.vn', '0912345014', 'Thái Bình',   1, 'CNTT03'),
('SV015', 'Phan Văn Sơn',     '2004-03-17', 1, 'sv015@univ.edu.vn', '0912345015', 'Hà Giang',    1, 'CNTT03'),
('SV016', 'Võ Thị Thảo',      '2004-04-22', 0, 'sv016@univ.edu.vn', '0912345016', 'Đà Nẵng',     1, 'KTMT01'),
('SV017', 'Nguyễn Minh Tú',   '2004-05-09', 1, 'sv017@univ.edu.vn', '0912345017', 'Cần Thơ',     1, 'KTMT01'),
('SV018', 'Đào Thị Uyên',     '2004-06-26', 0, 'sv018@univ.edu.vn', '0912345018', 'Huế',         1, 'KTMT01'),
('SV019', 'Nguyễn Văn Vinh',  '2004-07-08', 1, 'sv019@univ.edu.vn', '0912345019', 'Lạng Sơn',    1, 'KTMT01'),
('SV020', 'Trần Thị Yến',     '2004-08-19', 0, 'sv020@univ.edu.vn', '0912345020', 'Phú Thọ',     1, 'KTMT01'),
('SV021', 'Lê Văn Khải',      '2004-01-28', 1, 'sv021@univ.edu.vn', '0912345021', 'Quảng Trị',   1, 'QTKD01'),
('SV022', 'Phạm Thị Ngân',    '2004-02-13', 0, 'sv022@univ.edu.vn', '0912345022', 'Quảng Bình',  1, 'QTKD01'),
('SV023', 'Hoàng Văn Phong',  '2004-03-06', 1, 'sv023@univ.edu.vn', '0912345023', 'Điện Biên',   1, 'QTKD01'),
('SV024', 'Bùi Thị Quyên',    '2004-04-16', 0, 'sv024@univ.edu.vn', '0912345024', 'Lào Cai',     1, 'QTKD01'),
('SV025', 'Đỗ Văn Tuấn',      '2004-05-27', 1, 'sv025@univ.edu.vn', '0912345025', 'Sơn La',      1, 'QTKD01'),
('SV026', 'Ngô Thị Hồng',     '2004-06-09', 0, 'sv026@univ.edu.vn', '0912345026', 'Hòa Bình',    1, 'QTKD02'),
('SV027', 'Trịnh Văn Khoa',   '2004-07-21', 1, 'sv027@univ.edu.vn', '0912345027', 'Tuyên Quang', 1, 'QTKD02'),
('SV028', 'Đinh Thị Linh',    '2004-08-04', 0, 'sv028@univ.edu.vn', '0912345028', 'Yên Bái',     1, 'QTKD02'),
('SV029', 'Lương Văn Minh',   '2004-09-18', 1, 'sv029@univ.edu.vn', '0912345029', 'Bắc Kạn',     1, 'QTKD02'),
('SV030', 'Nguyễn Thị Hà',    '2004-10-29', 0, 'sv030@univ.edu.vn', '0912345030', 'Cao Bằng',    1, 'QTKD02'),
('SV031', 'Phan Văn Bảo',     '2004-01-09', 1, 'sv031@univ.edu.vn', '0912345031', 'Bình Định',   1, 'TCNH01'),
('SV032', 'Võ Thị Chi',       '2004-02-18', 0, 'sv032@univ.edu.vn', '0912345032', 'Khánh Hòa',   1, 'TCNH01'),
('SV033', 'Nguyễn Minh Duy',  '2004-03-23', 1, 'sv033@univ.edu.vn', '0912345033', 'Đăk Lăk',     1, 'TCNH01'),
('SV034', 'Đào Thị Giang',    '2004-04-30', 0, 'sv034@univ.edu.vn', '0912345034', 'Gia Lai',     1, 'TCNH01'),
('SV035', 'Nguyễn Văn Hải',   '2004-05-16', 1, 'sv035@univ.edu.vn', '0912345035', 'Kon Tum',     1, 'TCNH01'),
('SV036', 'Trần Thị Hương',   '2004-06-11', 0, 'sv036@univ.edu.vn', '0912345036', 'Lâm Đồng',    1, 'XDDS01'),
('SV037', 'Lê Văn Kiên',      '2004-07-07', 1, 'sv037@univ.edu.vn', '0912345037', 'Bà Rịa-VT',   1, 'XDDS01'),
('SV038', 'Phạm Thị Mơ',      '2004-08-14', 0, 'sv038@univ.edu.vn', '0912345038', 'Tây Ninh',    1, 'XDDS01'),
('SV039', 'Hoàng Văn Nghĩa',  '2004-09-05', 1, 'sv039@univ.edu.vn', '0912345039', 'Bình Thuận',  1, 'XDDS01'),
('SV040', 'Bùi Thị Phương',   '2004-10-12', 0, 'sv040@univ.edu.vn', '0912345040', 'Kiên Giang',  1, 'XDDS01'),
('SV041', 'Đỗ Văn Quân',      '2004-11-23', 1, 'sv041@univ.edu.vn', '0912345041', 'Cà Mau',      1, 'XDDD01'),
('SV042', 'Ngô Thị Thu',      '2004-12-01', 0, 'sv042@univ.edu.vn', '0912345042', 'An Giang',    1, 'XDDD01'),
('SV043', 'Trịnh Văn Thắng',  '2004-01-25', 1, 'sv043@univ.edu.vn', '0912345043', 'Đồng Tháp',   1, 'XDDD01'),
('SV044', 'Đinh Thị Vân',     '2004-02-09', 0, 'sv044@univ.edu.vn', '0912345044', 'Vĩnh Long',   1, 'XDDD01'),
('SV045', 'Lương Văn Anh',    '2004-03-28', 1, 'sv045@univ.edu.vn', '0912345045', 'Bến Tre',     1, 'XDDD01'),
('SV046', 'Nguyễn Thị Bình',  '2004-04-12', 0, 'sv046@univ.edu.vn', '0912345046', 'Trà Vinh',    1, 'XDDD02'),
('SV047', 'Phan Văn Công',    '2004-05-30', 1, 'sv047@univ.edu.vn', '0912345047', 'Sóc Trăng',   1, 'XDDD02'),
('SV048', 'Võ Thị Diễm',      '2004-06-14', 0, 'sv048@univ.edu.vn', '0912345048', 'Bạc Liêu',    1, 'XDDD02'),
('SV049', 'Nguyễn Minh Đức',  '2004-07-02', 1, 'sv049@univ.edu.vn', '0912345049', 'Hậu Giang',   1, 'XDDD02'),
('SV050', 'Đào Thị Hạnh',     '2004-08-22', 0, 'sv050@univ.edu.vn', '0912345050', 'Ninh Thuận',  1, 'XDDD02'),
('SV051', 'Nguyễn Văn Hòa',   '2004-09-08', 1, 'sv051@univ.edu.vn', '0912345051', 'Bắc Ninh',    1, 'CNTT01'),
('SV052', 'Trần Thị Khuê',    '2004-10-03', 0, 'sv052@univ.edu.vn', '0912345052', 'Hà Nội',      1, 'CNTT01'),
('SV053', 'Lê Văn Lợi',       '2004-11-14', 1, 'sv053@univ.edu.vn', '0912345053', 'Hải Dương',   1, 'CNTT02'),
('SV054', 'Phạm Thị Mỹ',      '2004-12-19', 0, 'sv054@univ.edu.vn', '0912345054', 'Nam Định',    1, 'CNTT02'),
('SV055', 'Hoàng Văn Nhân',   '2004-01-31', 1, 'sv055@univ.edu.vn', '0912345055', 'Hà Tĩnh',     1, 'CNTT03'),
('SV056', 'Bùi Thị Oanh',     '2004-02-25', 0, 'sv056@univ.edu.vn', '0912345056', 'Quảng Ngãi',  1, 'KTMT01'),
('SV057', 'Đỗ Văn Phát',      '2004-03-14', 1, 'sv057@univ.edu.vn', '0912345057', 'Đà Nẵng',     1, 'QTKD01'),
('SV058', 'Ngô Thị Quế',      '2004-04-27', 0, 'sv058@univ.edu.vn', '0912345058', 'Huế',         1, 'TCNH01'),
('SV059', 'Trịnh Văn Sang',   '2004-05-19', 1, 'sv059@univ.edu.vn', '0912345059', 'Cần Thơ',     1, 'XDDS01'),
('SV060', 'Đinh Thị Thúy',    '2004-06-30', 0, 'sv060@univ.edu.vn', '0912345060', 'Hà Nội',      2, 'XDDD01');
