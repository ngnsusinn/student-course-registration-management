1. INSERT BẢNG KHOA (3 Khoa)
INSERT INTO KHOA (MaKhoa, TenKhoa, DienThoaiKhoa, EmailKhoa) VALUES
('FIT', N'Công nghệ Thông tin', '0281234561', 'fit@university.edu.vn'),
('FEE', N'Điện - Điện tử', '0281234562', 'fee@university.edu.vn'),
('FBA', N'Quản trị Kinh doanh', '0281234563', 'fba@university.edu.vn');

2. INSERT BẢNG NGANH (6 Ngành - Ngành thứ 2 là Công nghệ Ô tô)
INSERT INTO NGANH (MaNganh, TenNganh, ThoiGianDaoTao, MaKhoa) VALUES
('SE', N'Kỹ thuật Phần mềm', 4.0, 'FIT'),
('AUT', N'Công nghệ Ô tô', 4.5, 'FEE'), 
('IS', N'Hệ thống Thông tin', 4.0, 'FIT'),
('ECE', N'Kỹ thuật Điện tử - Truyền thông', 4.5, 'FEE'),
('BA', N'Quản trị Kinh doanh', 4.0, 'FBA'),
('MKT', N'Marketing', 4.0, 'FBA');

3. INSERT BẢNG LOP (10 Lớp)
INSERT INTO LOP (MaLop, TenLop, NienKhoa, MaNganh) VALUES
('SE1701', N'Kỹ thuật Phần mềm 1 - K17', 2023, 'SE'),
('SE1702', N'Kỹ thuật Phần mềm 2 - K17', 2023, 'SE'),
('AUT1701', N'Công nghệ Ô tô 1 - K17', 2023, 'AUT'),
('AUT1702', N'Công nghệ Ô tô 2 - K17', 2023, 'AUT'),
('IS1701', N'Hệ thống Thông tin 1 - K17', 2023, 'IS'),
('ECE1701', N'Điện tử Truyền thông 1 - K17', 2023, 'ECE'),
('BA1701', N'Quản trị Kinh doanh 1 - K17', 2023, 'BA'),
('BA1702', N'Quản trị Kinh doanh 2 - K17', 2023, 'BA'),
('MKT1701', N'Marketing 1 - K17', 2023, 'MKT'),
('MKT1702', N'Marketing 2 - K17', 2023, 'MKT');

4. INSERT DANH MỤC HỌC KỲ (8 Học kỳ)
INSERT INTO HOC_KY (MaHocKy, TenHocKy) VALUES
('HK1', N'Học kỳ 1'),
('HK2', N'Học kỳ 2'),
('HK3', N'Học kỳ 3'),
('HK4', N'Học kỳ 4'),
('HK5', N'Học kỳ 5'),
('HK6', N'Học kỳ 6'),
('HK7', N'Học kỳ 7'),
('HK8', N'Học kỳ 8');

5. INSERT DANH MỤC MÔN HỌC (Thay TSQL thành Lập trình Hướng đối tượng & Bổ sung môn Ô tô)
INSERT INTO MON_HOC (MaMH, TenMon, SoTinChi) VALUES
('NMLT', N'Nhập môn Lập trình', 3),
('CTDLGT', N'Cấu trúc Dữ liệu và Giải thuật', 4),
('CSDL', N'Cơ sở Dữ liệu', 3),
('LTHDT', N'Lập trình Hướng đối tượng', 3), 
('KTPM', N'Kiến trúc Phần mềm', 3),
('KTOTO', N'Kỹ thuật Ô tô Cơ bản', 3),
('DCDT', N'Động cơ Đốt trong', 3),
('KNS', N'Kỹ năng mềm', 2);

6. INSERT CHƯƠNG TRÌNH ĐÀO TẠO (Bổ sung CTĐT cho Ngành thứ 2: Công nghệ Ô tô)
INSERT INTO CHUONGTRINHDAOTAO (MaCTDT, TenCTDT, NamApDung, TongSoTinChi, MaNganh) VALUES
('CTDT_SE2023', N'Chương trình Đào tạo Kỹ thuật Phần mềm Khóa 2023', 2023, 130, 'SE'),
('CTDT_AUT2023', N'Chương trình Đào tạo Công nghệ Ô tô Khóa 2023', 2023, 140, 'AUT');

7. INSERT CHI TIẾT CTDT (Sử dụng LTHDT thay TSQL cho SE và thêm môn cho AUT)
INSERT INTO CHI_TIET_CTDT (MaCTDT, MaMH, MaHocKy) VALUES
('CTDT_SE2023', 'NMLT', 'HK1'),
('CTDT_SE2023', 'KNS', 'HK1'),
('CTDT_SE2023', 'CTDLGT', 'HK2'),
('CTDT_SE2023', 'CSDL', 'HK3'),
('CTDT_SE2023', 'LTHDT', 'HK4'), 
('CTDT_SE2023', 'KTPM', 'HK5'),

Chi tiết CTĐT Công nghệ Ô tô
('CTDT_AUT2023', 'NMLT', 'HK1'),
('CTDT_AUT2023', 'KNS', 'HK1'),
('CTDT_AUT2023', 'LTHDT', 'HK2'), 
('CTDT_AUT2023', 'KTOTO', 'HK3'),
('CTDT_AUT2023', 'DCDT', 'HK4');

-- 8. INSERT BẢNG SINH_VIEN (60 Sinh viên phân bổ 10 Lớp)
INSERT INTO SINH_VIEN (MaSV, HoTen, NgaySinh, GioiTinh, TrangThaiHoc, Email, SoDienThoai, QueQuan, MaLop) VALUES
-- Lớp SE1701 (6 SV)
('SV230001', N'Nguyễn Văn An', '2005-01-15', 1, 1, 'an.nv230001@st.university.edu.vn', '0901000001', N'Hà Nội', 'SE1701'),
('SV230002', N'Trần Thị Bình', '2005-02-20', 0, 1, 'binh.tt230002@st.university.edu.vn', '0901000002', N'TP. Hồ Chí Minh', 'SE1701'),
('SV230003', N'Lê Hoàng Cường', '2005-03-10', 1, 1, 'cuong.lh230003@st.university.edu.vn', '0901000003', N'Đà Nẵng', 'SE1701'),
('SV230004', N'Phạm Thu Dung', '2005-04-12', 0, 1, 'dung.pt230004@st.university.edu.vn', '0901000004', N'Cần Thơ', 'SE1701'),
('SV230005', N'Vũ Minh Đức', '2005-05-25', 1, 2, 'duc.vm230005@st.university.edu.vn', '0901000005', N'Hải Phòng', 'SE1701'),
('SV230006', N'Đỗ Khánh Giang', '2005-06-18', 0, 1, 'giang.dk230006@st.university.edu.vn', '0901000006', N'Quảng Ninh', 'SE1701'),

-- Lớp SE1702 (6 SV)
('SV230007', N'Hoàng Văn Hùng', '2005-07-08', 1, 1, 'hung.hv230007@st.university.edu.vn', '0901000007', N'Nghệ An', 'SE1702'),
('SV230008', N'Ngô Mai Hương', '2005-08-14', 0, 1, 'huong.nm230008@st.university.edu.vn', '0901000008', N'Thanh Hóa', 'SE1702'),
('SV230009', N'Bùi Quốc Khánh', '2005-09-02', 1, 1, 'khanh.bq230009@st.university.edu.vn', '0901000009', N'Thừa Thiên Huế', 'SE1702'),
('SV230010', N'Đặng Phương Linh', '2005-10-30', 0, 1, 'linh.dp230010@st.university.edu.vn', '0901000010', N'Bình Định', 'SE1702'),
('SV230011', N'Trịnh Văn Nam', '2005-11-05', 1, 3, 'nam.tv230011@st.university.edu.vn', '0901000011', N'Bình Dương', 'SE1702'),
('SV230012', N'Lương Yến Nhi', '2005-12-12', 0, 1, 'nhi.ly230012@st.university.edu.vn', '0901000012', N'Đồng Nai', 'SE1702'),

-- Lớp AUT1701 (6 SV - Ngành Công nghệ Ô tô)
('SV230013', N'Nguyễn Tấn Phát', '2005-01-22', 1, 1, 'phat.nt230013@st.university.edu.vn', '0901000013', N'An Giang', 'AUT1701'),
('SV230014', N'Trần Như Quỳnh', '2005-02-14', 0, 1, 'quynh.tn230014@st.university.edu.vn', '0901000014', N'Kiên Giang', 'AUT1701'),
('SV230015', N'Lê Minh Sơn', '2005-03-19', 1, 1, 'son.lm230015@st.university.edu.vn', '0901000015', N'Lâm Đồng', 'AUT1701'),
('SV230016', N'Phạm Phương Tâm', '2005-04-21', 0, 1, 'tam.pp230016@st.university.edu.vn', '0901000016', N'Khánh Hòa', 'AUT1701'),
('SV230017', N'Vũ Anh Thắng', '2005-05-11', 1, 1, 'thang.va230017@st.university.edu.vn', '0901000017', N'Gia Lai', 'AUT1701'),
('SV230018', N'Đỗ Minh Uyên', '2005-06-27', 0, 1, 'uyen.dm230018@st.university.edu.vn', '0901000018', N'Đắc Lắk', 'AUT1701'),

-- Lớp AUT1702 (6 SV - Ngành Công nghệ Ô tô)
('SV230019', N'Hoàng Quốc Việt', '2005-07-16', 1, 1, 'viet.hq230019@st.university.edu.vn', '0901000019', N'Quảng Nam', 'AUT1702'),
('SV230020', N'Ngô Bảo Yến', '2005-08-09', 0, 1, 'yen.nb230020@st.university.edu.vn', '0901000020', N'Quảng Ngãi', 'AUT1702'),
('SV230021', N'Bùi Đức Anh', '2005-09-17', 1, 1, 'anh.bd230021@st.university.edu.vn', '0901000021', N'Vũng Tàu', 'AUT1702'),
('SV230022', N'Đặng Kim Ngân', '2005-10-04', 0, 2, 'ngan.dk230022@st.university.edu.vn', '0901000022', N'Tây Ninh', 'AUT1702'),
('SV230023', N'Trịnh Tuấn Kiệt', '2005-11-18', 1, 1, 'kiet.tt230023@st.university.edu.vn', '0901000023', N'Long An', 'AUT1702'),
('SV230024', N'Lương Thảo Nguyên', '2005-12-01', 0, 1, 'nguyen.lt230024@st.university.edu.vn', '0901000024', N'Tiền Giang', 'AUT1702'),

-- Lớp IS1701 (6 SV)
('SV230025', N'Nguyễn Hữu Bảo', '2005-01-08', 1, 1, 'bao.nh230025@st.university.edu.vn', '0901000025', N'Bến Tre', 'IS1701'),
('SV230026', N'Trần Ngọc Trinh', '2005-02-17', 0, 1, 'trinh.tn230026@st.university.edu.vn', '0901000026', N'Vĩnh Long', 'IS1701'),
('SV230027', N'Lê Tiến Đạt', '2005-03-29', 1, 1, 'dat.lt230027@st.university.edu.vn', '0901000027', N'Đồng Tháp', 'IS1701'),
('SV230028', N'Phạm Mỹ Hạnh', '2005-04-03', 0, 1, 'hanh.pm230028@st.university.edu.vn', '0901000028', N'Hậu Giang', 'IS1701'),
('SV230029', N'Vũ Thành Long', '2005-05-22', 1, 1, 'long.vt230029@st.university.edu.vn', '0901000029', N'Sóc Trăng', 'IS1701'),
('SV230030', N'Đỗ Cẩm Tú', '2005-06-14', 0, 1, 'tu.dc230030@st.university.edu.vn', '0901000030', N'Bạc Liêu', 'IS1701'),

-- Lớp ECE1701 (6 SV)
('SV230031', N'Hoàng Đình Trọng', '2005-07-24', 1, 1, 'trong.hd230031@st.university.edu.vn', '0901000031', N'Cà Mau', 'ECE1701'),
('SV230032', N'Ngô Thị Thúy', '2005-08-31', 0, 1, 'thuy.nt230032@st.university.edu.vn', '0901000032', N'Bắc Ninh', 'ECE1701'),
('SV230033', N'Bùi Xuân Lộc', '2005-09-08', 1, 1, 'loc.bx230033@st.university.edu.vn', '0901000033', N'Hải Dương', 'ECE1701'),
('SV230034', N'Đặng Thanh Hằng', '2005-10-15', 0, 1, 'hang.dt230034@st.university.edu.vn', '0901000034', N'Hưng Yên', 'ECE1701'),
('SV230035', N'Trịnh Xuân Bách', '2005-11-23', 1, 1, 'bach.tx230035@st.university.edu.vn', '0901000035', N'Nam Định', 'ECE1701'),
('SV230036', N'Lương Kiều Trang', '2005-12-09', 0, 1, 'trang.lk230036@st.university.edu.vn', '0901000036', N'Thái Bình', 'ECE1701'),

-- Lớp BA1701 (6 SV)
('SV230037', N'Nguyễn Huy Hoàng', '2005-01-19', 1, 1, 'hoang.nh230037@st.university.edu.vn', '0901000037', N'Ninh Bình', 'BA1701'),
('SV230038', N'Trần Ánh Tuyết', '2005-02-28', 0, 1, 'tuyet.ta230038@st.university.edu.vn', '0901000038', N'Thái Nguyên', 'BA1701'),
('SV230039', N'Lê Văn Hiếu', '2005-03-07', 1, 1, 'hieu.lv230039@st.university.edu.vn', '0901000039', N'Lạng Sơn', 'BA1701'),
('SV230040', N'Phạm Bích Ngọc', '2005-04-18', 0, 1, 'ngoc.pb230040@st.university.edu.vn', '0901000040', N'Cao Bằng', 'BA1701'),
('SV230041', N'Vũ Trung Kiên', '2005-05-30', 1, 2, 'kien.vt230041@st.university.edu.vn', '0901000041', N'Bắc Giang', 'BA1701'),
('SV230042', N'Đỗ Ánh Nguyệt', '2005-06-05', 0, 1, 'nguyet.da230042@st.university.edu.vn', '0901000042', N'Phú Thọ', 'BA1701'),

-- Lớp BA1702 (6 SV)
('SV230043', N'Hoàng Văn Thịnh', '2005-07-12', 1, 1, 'thinh.hv230043@st.university.edu.vn', '0901000043', N'Vĩnh Phúc', 'BA1702'),
('SV230044', N'Ngô Khánh Linh', '2005-08-23', 0, 1, 'linh.nk230044@st.university.edu.vn', '0901000044', N'Hòa Bình', 'BA1702'),
('SV230045', N'Bùi Thanh Tùng', '2005-09-29', 1, 1, 'tung.bt230045@st.university.edu.vn', '0901000045', N'Sơn La', 'BA1702'),
('SV230046', N'Đặng Thanh Trúc', '2005-10-11', 0, 1, 'truc.dt230046@st.university.edu.vn', '0901000046', N'Yên Bái', 'BA1702'),
('SV230047', N'Trịnh Quang Khải', '2005-11-02', 1, 1, 'khai.tq230047@st.university.edu.vn', '0901000047', N'Tuyên Quang', 'BA1702'),
('SV230048', N'Lương Diệu Anh', '2005-12-25', 0, 1, 'anh.ld230048@st.university.edu.vn', '0901000048', N'Hà Giang', 'BA1702'),

-- Lớp MKT1701 (6 SV)
('SV230049', N'Nguyễn Trọng Nhân', '2005-01-31', 1, 1, 'nhan.nt230049@st.university.edu.vn', '0901000049', N'Quảng Bình', 'MKT1701'),
('SV230050', N'Trần Thị Cẩm', '2005-02-11', 0, 1, 'cam.tt230050@st.university.edu.vn', '0901000050', N'Quảng Trị', 'MKT1701'),
('SV230051', N'Lê Minh Triết', '2005-03-15', 1, 1, 'triet.lm230051@st.university.edu.vn', '0901000051', N'Phú Yên', 'MKT1701'),
('SV230052', N'Phạm Châu Anh', '2005-04-26', 0, 1, 'anh.pc230052@st.university.edu.vn', '0901000052', N'Ninh Thuận', 'MKT1701'),
('SV230053', N'Vũ Nhật Minh', '2005-05-08', 1, 1, 'minh.vn230053@st.university.edu.vn', '0901000053', N'Bình Thuận', 'MKT1701'),
('SV230054', N'Đỗ Hà Phương', '2005-06-21', 0, 1, 'phuong.dh230054@st.university.edu.vn', '0901000054', N'Bình Phước', 'MKT1701'),

-- Lớp MKT1702 (6 SV)
('SV230055', N'Hoàng Tiến Dũng', '2005-07-04', 1, 1, 'dung.ht230055@st.university.edu.vn', '0901000055', N'Đắc Nông', 'MKT1702'),
('SV230056', N'Ngô Cẩm Vân', '2005-08-19', 0, 1, 'van.nc230056@st.university.edu.vn', '0901000056', N'Kon Tum', 'MKT1702'),
('SV230057', N'Bùi Đăng Khoa', '2005-09-12', 1, 1, 'khoa.bd230057@st.university.edu.vn', '0901000057', N'Trà Vinh', 'MKT1702'),
('SV230058', N'Đặng Bảo Châu', '2005-10-27', 0, 1, 'chau.db230058@st.university.edu.vn', '0901000058', N'Hải Phòng', 'MKT1702'),
('SV230059', N'Trịnh Công Vinh', '2005-11-14', 1, 1, 'vinh.tc230059@st.university.edu.vn', '0901000059', N'Đà Nẵng', 'MKT1702'),
('SV230060', N'Lương Yến Linh', '2005-12-30', 0, 1, 'linh.ly230060@st.university.edu.vn', '0901000060', N'Cần Thơ', 'MKT1702');