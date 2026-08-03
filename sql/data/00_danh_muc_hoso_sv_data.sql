-- ==========================================================
-- Tên file : sql/data/00_danh_muc_hoso_sv_data.sql
-- Module   : Danh mục hệ thống & Hồ sơ sinh viên (TV1)
-- Mô tả    : 3 Khoa, 6 Ngành, 10 Lớp, 60 Sinh viên + CTĐT mẫu.
--            Nạp TRƯỚC dữ liệu các bảng nền để TV3 sử dụng.
-- ==========================================================

-- ==========================================================
-- 1. KHOA (3 khoa)
-- ==========================================================
INSERT INTO KHOA (MaKhoa, TenKhoa, DienThoaiKhoa, EmailKhoa) VALUES
(N'CNTT', N'Công nghệ thông tin', N'02435581234', N'cntt@univ.edu.vn'),
(N'KTT',  N'Kinh tế - Tài chính',  N'02435585678', N'ktt@univ.edu.vn'),
(N'XD',   N'Xây dựng',             N'02435589876', N'xd@univ.edu.vn');
GO

-- ==========================================================
-- 2. NGANH (6 ngành)
-- ==========================================================
INSERT INTO NGANH (MaNganh, TenNganh, ThoiGianDaoTao, MaKhoa) VALUES
(N'CN', N'Công nghệ thông tin', 4.0, N'CNTT'),
(N'KTMT', N'Kỹ thuật máy tính', 4.0, N'CNTT'),
(N'QTKD', N'Quản trị kinh doanh', 4.0, N'KTT'),
(N'TCNH', N'Tài chính ngân hàng', 4.0, N'KTT'),
(N'XDDS', N'Xây dựng dân dụng', 4.5, N'XD'),
(N'XDDD', N'Xây dựng đô thị', 4.5, N'XD');
GO

-- ==========================================================
-- 3. LOP_SINHHOAT (10 lớp — THỐNG NHẤT khóa 2022 để lịch sử
--    học tập xuyên 5 học kỳ HK1-2023..HK1-2025 nhất quán)
-- ==========================================================
INSERT INTO LOP_SINHHOAT (MaLopSH, TenLopSH, NienKhoa, MaNganh) VALUES
(N'CNTT01', N'CNTT01 - Khóa 2022', 2022, N'CN'),
(N'CNTT02', N'CNTT02 - Khóa 2022', 2022, N'CN'),
(N'CNTT03', N'CNTT03 - Khóa 2022', 2022, N'CN'),
(N'KTMT01', N'KTMT01 - Khóa 2022', 2022, N'KTMT'),
(N'QTKD01', N'QTKD01 - Khóa 2022', 2022, N'QTKD'),
(N'QTKD02', N'QTKD02 - Khóa 2022', 2022, N'QTKD'),
(N'TCNH01', N'TCNH01 - Khóa 2022', 2022, N'TCNH'),
(N'XDDS01', N'XDDS01 - Khóa 2022', 2022, N'XDDS'),
(N'XDDD01', N'XDDD01 - Khóa 2022', 2022, N'XDDD'),
(N'XDDD02', N'XDDD02 - Khóa 2022', 2022, N'XDDD');
GO

-- ==========================================================
-- 4. SINHVIEN (60 SV) — mã SV theo mẫu SV001...SV060
--    TrangThaiHoc: 1 Đang học, 2 Bảo lưu, 3 Thôi học
-- ==========================================================
INSERT INTO SINHVIEN (MaSV, HoTen, NgaySinh, GioiTinh, Email, SoDienThoai, QueQuan, TrangThaiHoc, MaLopSH) VALUES
(N'SV001', N'Nguyễn Văn An',    '2004-01-15', 1, N'sv001@univ.edu.vn', N'0912345001', N'Hà Nội',      1, N'CNTT01'),
(N'SV002', N'Trần Thị Bích',    '2004-02-20', 0, N'sv002@univ.edu.vn', N'0912345002', N'Hải Phòng',   1, N'CNTT01'),
(N'SV003', N'Lê Minh Cường',    '2004-03-10', 1, N'sv003@univ.edu.vn', N'0912345003', N'Bắc Ninh',    1, N'CNTT01'),
(N'SV004', N'Phạm Thị Dung',    '2004-04-05', 0, N'sv004@univ.edu.vn', N'0912345004', N'Nghệ An',     1, N'CNTT01'),
(N'SV005', N'Hoàng Văn Đạt',    '2004-05-12', 1, N'sv005@univ.edu.vn', N'0912345005', N'Thái Nguyên', 1, N'CNTT01'),
(N'SV006', N'Vũ Thị Hoa',       '2004-06-18', 0, N'sv006@univ.edu.vn', N'0912345006', N'Nam Định',    1, N'CNTT02'),
(N'SV007', N'Đặng Quang Huy',   '2004-07-25', 1, N'sv007@univ.edu.vn', N'0912345007', N'Hà Tĩnh',     1, N'CNTT02'),
(N'SV008', N'Bùi Thị Lan',      '2004-08-30', 0, N'sv008@univ.edu.vn', N'0912345008', N'Quảng Ninh',  1, N'CNTT02'),
(N'SV009', N'Ngô Văn Long',     '2004-09-14', 1, N'sv009@univ.edu.vn', N'0912345009', N'Hà Nam',      1, N'CNTT02'),
(N'SV010', N'Đỗ Thị Mai',       '2004-10-01', 0, N'sv010@univ.edu.vn', N'0912345010', N'Vĩnh Phúc',   1, N'CNTT02'),
(N'SV011', N'Trịnh Văn Nam',    '2003-11-11', 1, N'sv011@univ.edu.vn', N'0912345011', N'Bắc Giang',   1, N'CNTT03'),
(N'SV012', N'Đinh Thị Ngọc',    '2003-12-21', 0, N'sv012@univ.edu.vn', N'0912345012', N'Thanh Hóa',   1, N'CNTT03'),
(N'SV013', N'Lương Văn Phúc',   '2004-01-03', 1, N'sv013@univ.edu.vn', N'0912345013', N'Hưng Yên',    1, N'CNTT03'),
(N'SV014', N'Nguyễn Thị Quỳnh', '2004-02-07', 0, N'sv014@univ.edu.vn', N'0912345014', N'Thái Bình',   1, N'CNTT03'),
(N'SV015', N'Phan Văn Sơn',     '2004-03-17', 1, N'sv015@univ.edu.vn', N'0912345015', N'Hà Giang',    1, N'CNTT03'),
(N'SV016', N'Võ Thị Thảo',      '2004-04-22', 0, N'sv016@univ.edu.vn', N'0912345016', N'Đà Nẵng',     1, N'KTMT01'),
(N'SV017', N'Nguyễn Minh Tú',   '2004-05-09', 1, N'sv017@univ.edu.vn', N'0912345017', N'Cần Thơ',     1, N'KTMT01'),
(N'SV018', N'Đào Thị Uyên',     '2004-06-26', 0, N'sv018@univ.edu.vn', N'0912345018', N'Huế',         1, N'KTMT01'),
(N'SV019', N'Nguyễn Văn Vinh',  '2004-07-08', 1, N'sv019@univ.edu.vn', N'0912345019', N'Lạng Sơn',    1, N'KTMT01'),
(N'SV020', N'Trần Thị Yến',     '2004-08-19', 0, N'sv020@univ.edu.vn', N'0912345020', N'Phú Thọ',     1, N'KTMT01'),
(N'SV021', N'Lê Văn Khải',      '2004-01-28', 1, N'sv021@univ.edu.vn', N'0912345021', N'Quảng Trị',   1, N'QTKD01'),
(N'SV022', N'Phạm Thị Ngân',    '2004-02-13', 0, N'sv022@univ.edu.vn', N'0912345022', N'Quảng Bình',  1, N'QTKD01'),
(N'SV023', N'Hoàng Văn Phong',  '2004-03-06', 1, N'sv023@univ.edu.vn', N'0912345023', N'Điện Biên',   1, N'QTKD01'),
(N'SV024', N'Bùi Thị Quyên',    '2004-04-16', 0, N'sv024@univ.edu.vn', N'0912345024', N'Lào Cai',     1, N'QTKD01'),
(N'SV025', N'Đỗ Văn Tuấn',      '2004-05-27', 1, N'sv025@univ.edu.vn', N'0912345025', N'Sơn La',      1, N'QTKD01'),
(N'SV026', N'Ngô Thị Hồng',     '2004-06-09', 0, N'sv026@univ.edu.vn', N'0912345026', N'Hòa Bình',    1, N'QTKD02'),
(N'SV027', N'Trịnh Văn Khoa',   '2004-07-21', 1, N'sv027@univ.edu.vn', N'0912345027', N'Tuyên Quang', 1, N'QTKD02'),
(N'SV028', N'Đinh Thị Linh',    '2004-08-04', 0, N'sv028@univ.edu.vn', N'0912345028', N'Yên Bái',     1, N'QTKD02'),
(N'SV029', N'Lương Văn Minh',   '2004-09-18', 1, N'sv029@univ.edu.vn', N'0912345029', N'Bắc Kạn',     1, N'QTKD02'),
(N'SV030', N'Nguyễn Thị Hà',    '2004-10-29', 0, N'sv030@univ.edu.vn', N'0912345030', N'Cao Bằng',    1, N'QTKD02'),
(N'SV031', N'Phan Văn Bảo',     '2004-01-09', 1, N'sv031@univ.edu.vn', N'0912345031', N'Bình Định',   1, N'TCNH01'),
(N'SV032', N'Võ Thị Chi',       '2004-02-18', 0, N'sv032@univ.edu.vn', N'0912345032', N'Khánh Hòa',   1, N'TCNH01'),
(N'SV033', N'Nguyễn Minh Duy',  '2004-03-23', 1, N'sv033@univ.edu.vn', N'0912345033', N'Đăk Lăk',     1, N'TCNH01'),
(N'SV034', N'Đào Thị Giang',    '2004-04-30', 0, N'sv034@univ.edu.vn', N'0912345034', N'Gia Lai',     1, N'TCNH01'),
(N'SV035', N'Nguyễn Văn Hải',   '2004-05-16', 1, N'sv035@univ.edu.vn', N'0912345035', N'Kon Tum',     1, N'TCNH01'),
(N'SV036', N'Trần Thị Hương',   '2004-06-11', 0, N'sv036@univ.edu.vn', N'0912345036', N'Lâm Đồng',    1, N'XDDS01'),
(N'SV037', N'Lê Văn Kiên',      '2004-07-07', 1, N'sv037@univ.edu.vn', N'0912345037', N'Bà Rịa-VT',   1, N'XDDS01'),
(N'SV038', N'Phạm Thị Mơ',      '2004-08-14', 0, N'sv038@univ.edu.vn', N'0912345038', N'Tây Ninh',    1, N'XDDS01'),
(N'SV039', N'Hoàng Văn Nghĩa',  '2004-09-05', 1, N'sv039@univ.edu.vn', N'0912345039', N'Bình Thuận',  1, N'XDDS01'),
(N'SV040', N'Bùi Thị Phương',   '2004-10-12', 0, N'sv040@univ.edu.vn', N'0912345040', N'Kiên Giang',  1, N'XDDS01'),
(N'SV041', N'Đỗ Văn Quân',      '2004-11-23', 1, N'sv041@univ.edu.vn', N'0912345041', N'Cà Mau',      1, N'XDDD01'),
(N'SV042', N'Ngô Thị Thu',      '2004-12-01', 0, N'sv042@univ.edu.vn', N'0912345042', N'An Giang',    1, N'XDDD01'),
(N'SV043', N'Trịnh Văn Thắng',  '2004-01-25', 1, N'sv043@univ.edu.vn', N'0912345043', N'Đồng Tháp',   1, N'XDDD01'),
(N'SV044', N'Đinh Thị Vân',     '2004-02-09', 0, N'sv044@univ.edu.vn', N'0912345044', N'Vĩnh Long',   1, N'XDDD01'),
(N'SV045', N'Lương Văn Anh',    '2004-03-28', 1, N'sv045@univ.edu.vn', N'0912345045', N'Bến Tre',     1, N'XDDD01'),
(N'SV046', N'Nguyễn Thị Bình',  '2004-04-12', 0, N'sv046@univ.edu.vn', N'0912345046', N'Trà Vinh',    1, N'XDDD02'),
(N'SV047', N'Phan Văn Công',    '2004-05-30', 1, N'sv047@univ.edu.vn', N'0912345047', N'Sóc Trăng',   1, N'XDDD02'),
(N'SV048', N'Võ Thị Diễm',      '2004-06-14', 0, N'sv048@univ.edu.vn', N'0912345048', N'Bạc Liêu',    1, N'XDDD02'),
(N'SV049', N'Nguyễn Minh Đức',  '2004-07-02', 1, N'sv049@univ.edu.vn', N'0912345049', N'Hậu Giang',   1, N'XDDD02'),
(N'SV050', N'Đào Thị Hạnh',     '2004-08-22', 0, N'sv050@univ.edu.vn', N'0912345050', N'Ninh Thuận',  1, N'XDDD02'),
(N'SV051', N'Nguyễn Văn Hòa',   '2004-09-08', 1, N'sv051@univ.edu.vn', N'0912345051', N'Bắc Ninh',    1, N'CNTT01'),
(N'SV052', N'Trần Thị Khuê',    '2004-10-03', 0, N'sv052@univ.edu.vn', N'0912345052', N'Hà Nội',      1, N'CNTT01'),
(N'SV053', N'Lê Văn Lợi',       '2004-11-14', 1, N'sv053@univ.edu.vn', N'0912345053', N'Hải Dương',   1, N'CNTT02'),
(N'SV054', N'Phạm Thị Mỹ',      '2004-12-19', 0, N'sv054@univ.edu.vn', N'0912345054', N'Nam Định',    1, N'CNTT02'),
(N'SV055', N'Hoàng Văn Nhân',   '2004-01-31', 1, N'sv055@univ.edu.vn', N'0912345055', N'Hà Tĩnh',     1, N'CNTT03'),
(N'SV056', N'Bùi Thị Oanh',     '2004-02-25', 0, N'sv056@univ.edu.vn', N'0912345056', N'Quảng Ngãi',  1, N'KTMT01'),
(N'SV057', N'Đỗ Văn Phát',      '2004-03-14', 1, N'sv057@univ.edu.vn', N'0912345057', N'Đà Nẵng',     1, N'QTKD01'),
(N'SV058', N'Ngô Thị Quế',      '2004-04-27', 0, N'sv058@univ.edu.vn', N'0912345058', N'Huế',         1, N'TCNH01'),
(N'SV059', N'Trịnh Văn Sang',   '2004-05-19', 1, N'sv059@univ.edu.vn', N'0912345059', N'Cần Thơ',     1, N'XDDS01'),
(N'SV060', N'Đinh Thị Thúy',    '2004-06-30', 0, N'sv060@univ.edu.vn', N'0912345060', N'Hà Nội',      2, N'XDDD01');
GO

-- ==========================================================
-- 5. CHUONGTRINHDAOTAO (mẫu cho ngành CN)
--    (MaMonHoc sẽ được nạp cùng dữ liệu Module 2 — xem file
--    00_hocphan_giangvien_data.sql; FK CHUONGTRINHDAOTAO.MaMonHoc
--    tham chiếu MONHOC nên cần môn học tồn tại trước.)
-- ==========================================================

PRINT N'[OK] Module 1 — Dữ liệu mẫu nạp xong: 3 Khoa, 6 Ngành, 10 Lớp, 60 SV.';
GO
