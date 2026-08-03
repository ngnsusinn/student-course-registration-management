-- ==========================================================
-- Tên file : sql/data/00_hocphan_giangvien_data.sql
-- Module   : Học phần, Giảng viên & Mở lớp học phần (TV2)
-- Mô tả    : 15 GV, 48 môn học + quan hệ tiên quyết, 5 học kỳ
--            (4 kỳ quá khứ ĐÓNG + 1 kỳ hiện tại MỞ), 20 phòng,
--            46 lớp học phần có lịch đầy đủ.
--            Thiết kế CHUỖI TIÊN QUYẾT nhất quán xuyên 5 học kỳ
--            để FN_KiemTraTienQuyet (Issue #51) chạy đúng:
--              HK1-2023 (nền) -> HK2-2023 -> HK1-2024 -> HK2-2024
--              -> HK1-2025 (HIỆN TẠI, MO).
-- ==========================================================

-- ==========================================================
-- 1. GIANGVIEN (15 GV)
-- ==========================================================
INSERT INTO GIANGVIEN (MaGV, HoTen, Email, MaKhoa) VALUES
(N'GV001', N'TS. Nguyễn Minh Hiếu',   N'minhhieu@univ.edu.vn',   N'CNTT'),
(N'GV002', N'TS. Trần Lan Chi',       N'lanchi@univ.edu.vn',     N'CNTT'),
(N'GV003', N'ThS. Lê Minh Đức',       N'minhduc@univ.edu.vn',    N'CNTT'),
(N'GV004', N'PGS.TS. Phạm Thị Hằng',  N'thihang@univ.edu.vn',    N'CNTT'),
(N'GV005', N'ThS. Hoàng Văn Khoa',    N'vankhoa@univ.edu.vn',    N'CNTT'),
(N'GV006', N'TS. Bùi Quang Lâm',      N'quanglam@univ.edu.vn',   N'CNTT'),
(N'GV007', N'ThS. Đỗ Thị Mơ',         N'thimo@univ.edu.vn',      N'CNTT'),
(N'GV008', N'TS. Ngô Đình Nam',       N'dinhnam@univ.edu.vn',    N'CNTT'),
(N'GV009', N'ThS. Trịnh Thu Phương',  N'thuphuong@univ.edu.vn',  N'KTT'),
(N'GV010', N'TS. Đinh Quang Thắng',   N'quangthang@univ.edu.vn', N'KTT'),
(N'GV011', N'ThS. Lương Thị Vân',     N'thivan@univ.edu.vn',     N'KTT'),
(N'GV012', N'TS. Nguyễn Khắc Tuấn',   N'khactuan@univ.edu.vn',   N'XD'),
(N'GV013', N'ThS. Phan Văn Thành',    N'vanthanh@univ.edu.vn',   N'XD'),
(N'GV014', N'TS. Võ Thị Ngọc',        N'thingoc@univ.edu.vn',    N'XD'),
(N'GV015', N'ThS. Đào Minh Quân',     N'minhquan@univ.edu.vn',   N'XD');
GO

-- ==========================================================
-- 2. HOCKY (5 học kỳ) — TrangThaiDot: MO / DONG
--    HK1-2025 là ĐỢT HIỆN TẠI đang MỞ đăng ký.
--    LƯU Ý: DenNgay HK1-2025 được nới rộng (2027-01-15) để bộ
--    kịch bản demo (SP, Transaction, concurrency) chạy được tại
--    MỌI thời điểm thực thi. Khi triển khai thật, hạn đăng ký
--    đúng theo ngày thi của học kỳ.
-- ==========================================================
INSERT INTO HOCKY (MaHocKy, TenHocKy, NamHoc, TuNgay, DenNgay, TrangThaiDot) VALUES
(N'HK1-2023', N'Học kỳ 1', N'2023-2024', '2023-08-20', '2024-01-10', N'DONG'),
(N'HK2-2023', N'Học kỳ 2', N'2023-2024', '2024-02-01', '2024-06-10', N'DONG'),
(N'HK1-2024', N'Học kỳ 1', N'2024-2025', '2024-08-20', '2025-01-10', N'DONG'),
(N'HK2-2024', N'Học kỳ 2', N'2024-2025', '2025-02-01', '2025-06-10', N'DONG'),
(N'HK1-2025', N'Học kỳ 1', N'2025-2026', '2025-08-20', '2027-01-15', N'MO');
GO

-- ==========================================================
-- 3. PHONGHOC (20 phòng)
-- ==========================================================
INSERT INTO PHONGHOC (MaPhong, TenPhong, SucChua) VALUES
(N'P101', N'Phòng 101', 40),
(N'P102', N'Phòng 102', 40),
(N'P103', N'Phòng 103', 35),
(N'P104', N'Phòng 104', 35),
(N'P201', N'Phòng 201', 40),
(N'P202', N'Phòng 202', 40),
(N'P203', N'Phòng 203', 45),
(N'P204', N'Phòng 204', 45),
(N'P301', N'Phòng 301', 40),
(N'P302', N'Phòng 302', 40),
(N'P303', N'Phòng 303', 30),
(N'P304', N'Phòng 304', 30),
(N'P401', N'Phòng 401', 50),
(N'P402', N'Phòng 402', 50),
(N'P501', N'Phòng máy 501', 30),
(N'P502', N'Phòng máy 502', 30),
(N'P503', N'Phòng máy 503', 25),
(N'P504', N'Phòng máy 504', 25),
(N'P601', N'Hội trường 601', 100),
(N'P602', N'Hội trường 602', 100);
GO

-- ==========================================================
-- 4. MONHOC (48 môn học: MH001..MH040 + MH041..MH049 tự chọn)
-- ==========================================================
INSERT INTO MONHOC (MaMonHoc, TenMonHoc, SoTinChi, SoTietLyThuyet, SoTietThucHanh, MaKhoa) VALUES
-- Khối CNTT (20 môn)
(N'MH001', N'Nhập môn lập trình',            3, 30, 15, N'CNTT'),
(N'MH002', N'Lập trình C/C++',               3, 30, 15, N'CNTT'),
(N'MH003', N'Cấu trúc dữ liệu và giải thuật',3, 30, 15, N'CNTT'),
(N'MH004', N'Cơ sở dữ liệu',                 3, 30, 15, N'CNTT'),
(N'MH005', N'Hệ quản trị CSDL',              3, 30, 15, N'CNTT'),
(N'MH006', N'Lập trình hướng đối tượng',     3, 30, 15, N'CNTT'),
(N'MH007', N'Lập trình Web',                 3, 30, 15, N'CNTT'),
(N'MH008', N'Công nghệ phần mềm',            3, 30, 15, N'CNTT'),
(N'MH009', N'Mạng máy tính',                 3, 30, 15, N'CNTT'),
(N'MH010', N'An toàn thông tin',             3, 30, 15, N'CNTT'),
(N'MH011', N'Hệ điều hành',                  3, 30, 15, N'CNTT'),
(N'MH012', N'Kiến trúc máy tính',            3, 30, 15, N'CNTT'),
(N'MH013', N'Toán rời rạc',                  3, 45, 0,  N'CNTT'),
(N'MH014', N'Xác suất thống kê',             3, 45, 0,  N'CNTT'),
(N'MH015', N'Giải tích',                     3, 45, 0,  N'CNTT'),
(N'MH016', N'Đại số tuyến tính',             3, 45, 0,  N'CNTT'),
(N'MH017', N'Tiếng Anh chuyên ngành CNTT',   2, 30, 0,  N'CNTT'),
(N'MH018', N'Phân tích và thiết kế hệ thống',3, 30, 15, N'CNTT'),
(N'MH019', N'Trí tuệ nhân tạo',              3, 30, 15, N'CNTT'),
(N'MH020', N'Học máy',                       3, 30, 15, N'CNTT'),
(N'MH041', N'Phân tích dữ liệu lớn (Big Data)',3, 30, 15, N'CNTT'),
(N'MH042', N'Lập trình ứng dụng di động',     3, 30, 15, N'CNTT'),
-- Khối Kinh tế (12 môn)
(N'MH021', N'Kinh tế vi mô',                 3, 45, 0,  N'KTT'),
(N'MH022', N'Kinh tế vĩ mô',                 3, 45, 0,  N'KTT'),
(N'MH023', N'Nguyên lý kế toán',             3, 45, 0,  N'KTT'),
(N'MH024', N'Quản trị học',                  3, 45, 0,  N'KTT'),
(N'MH025', N'Marketing căn bản',             3, 45, 0,  N'KTT'),
(N'MH026', N'Tài chính doanh nghiệp',        3, 45, 0,  N'KTT'),
(N'MH027', N'Ngân hàng thương mại',          3, 45, 0,  N'KTT'),
(N'MH028', N'Thị trường chứng khoán',        3, 45, 0,  N'KTT'),
(N'MH029', N'Quản trị nhân lực',             3, 45, 0,  N'KTT'),
(N'MH030', N'Thống kê kinh tế',              3, 45, 0,  N'KTT'),
(N'MH044', N'Kế toán quản trị',              3, 45, 0,  N'KTT'),
(N'MH047', N'Đầu tư tài chính quốc tế',      3, 45, 0,  N'KTT'),
(N'MH048', N'Phân tích báo cáo tài chính',   3, 45, 0,  N'KTT'),
-- Khối Xây dựng (13 môn)
(N'MH031', N'Cơ học kết cấu',                3, 30, 15, N'XD'),
(N'MH032', N'Sức bền vật liệu',              3, 30, 15, N'XD'),
(N'MH033', N'Kết cấu bê tông cốt thép',      3, 30, 15, N'XD'),
(N'MH034', N'Kết cấu thép',                  3, 30, 15, N'XD'),
(N'MH035', N'Nền móng công trình',           3, 30, 15, N'XD'),
(N'MH036', N'Vật liệu xây dựng',             3, 30, 15, N'XD'),
(N'MH037', N'Quy hoạch đô thị',              3, 30, 15, N'XD'),
(N'MH038', N'Thủy lực công trình',           3, 30, 15, N'XD'),
(N'MH039', N'Trắc địa công trình',           3, 30, 15, N'XD'),
(N'MH040', N'Quản lý dự án xây dựng',        3, 30, 15, N'XD'),
(N'MH045', N'Kết cấu cao tầng',              3, 30, 15, N'XD'),
(N'MH046', N'Thẩm định dự án đầu tư XD',     3, 30, 15, N'XD'),
(N'MH049', N'Công nghệ thi công',            3, 30, 15, N'XD');
GO

-- ==========================================================
-- 5. MONHOC_TIENQUYET (môn trước phải ĐẠT để học môn sau)
-- ==========================================================
INSERT INTO MONHOC_TIENQUYET (MaMonHoc, MaMonTienQuyet) VALUES
(N'MH002', N'MH001'),  -- C/C++ cần Nhập môn
(N'MH003', N'MH002'),  -- CTDL&GT cần C/C++
(N'MH004', N'MH003'),  -- CSDL cần CTDL&GT
(N'MH005', N'MH004'),  -- Hệ QTCSDL cần CSDL
(N'MH006', N'MH002'),  -- OOP cần C/C++
(N'MH007', N'MH006'),  -- Web cần OOP
(N'MH008', N'MH006'),  -- CNPM cần OOP
(N'MH009', N'MH001'),  -- Mạng cần Nhập môn
(N'MH010', N'MH009'),  -- ATTT cần Mạng
(N'MH011', N'MH012'),  -- HĐH cần Kiến trúc máy tính
(N'MH012', N'MH016'),  -- Kiến trúc máy tính cần Đại số
(N'MH013', N'MH016'),  -- Toán rời rạc cần Đại số
(N'MH018', N'MH004'),  -- PTTKHT cần CSDL
(N'MH019', N'MH003'),  -- AI cần CTDL&GT
(N'MH020', N'MH019'),  -- Học máy cần AI
(N'MH041', N'MH005'),  -- Big Data cần Hệ QTCSDL
(N'MH042', N'MH007'),  -- Mobile cần Web
-- Khối KT
(N'MH022', N'MH021'),  -- Kinh tế vĩ mô cần vi mô
(N'MH023', N'MH021'),  -- Nguyên lý kế toán cần vi mô
(N'MH026', N'MH023'),  -- Tài chính DN cần kế toán
(N'MH027', N'MH023'),  -- Ngân hàng cần kế toán
(N'MH028', N'MH026'),  -- Chứng khoán cần TC DN
(N'MH044', N'MH023'),  -- Kế toán quản trị cần kế toán
(N'MH047', N'MH026'),  -- Đầu tư TCQT cần TC DN
(N'MH048', N'MH023'),  -- Phân tích BCTC cần kế toán
-- Khối XD
(N'MH032', N'MH031'),  -- Sức bền cần Cơ học
(N'MH033', N'MH032'),  -- BTCT cần Sức bền
(N'MH034', N'MH032'),  -- Kết cấu thép cần Sức bền
(N'MH035', N'MH033'),  -- Nền móng cần BTCT
(N'MH037', N'MH036'),  -- Quy hoạch cần Vật liệu
(N'MH038', N'MH032'),  -- Thủy lực cần Sức bền
(N'MH045', N'MH033'),  -- Kết cấu cao tầng cần BTCT
(N'MH046', N'MH040'),  -- Thẩm định dự án cần QL dự án
(N'MH049', N'MH035');  -- Công nghệ thi công cần Nền móng
GO

-- ==========================================================
-- 6. CHUONGTRINHDAOTAO (mẫu cho ngành CN)
-- ==========================================================
INSERT INTO CHUONGTRINHDAOTAO (MaNganh, MaMonHoc, HocKyDuKien, BatBuoc) VALUES
(N'CN', N'MH001', 1, 1),
(N'CN', N'MH002', 2, 1),
(N'CN', N'MH003', 3, 1),
(N'CN', N'MH004', 4, 1),
(N'CN', N'MH005', 5, 1),
(N'CN', N'MH006', 3, 1),
(N'CN', N'MH007', 4, 1),
(N'CN', N'MH008', 5, 1),
(N'CN', N'MH009', 4, 1),
(N'CN', N'MH010', 5, 1),
(N'CN', N'MH011', 5, 1),
(N'CN', N'MH012', 3, 1),
(N'CN', N'MH013', 2, 1),
(N'CN', N'MH014', 2, 1),
(N'CN', N'MH015', 1, 1),
(N'CN', N'MH016', 1, 1),
(N'CN', N'MH017', 5, 0),
(N'CN', N'MH018', 5, 1),
(N'CN', N'MH019', 5, 1),
(N'CN', N'MH020', 6, 0),
(N'CN', N'MH041', 6, 0),
(N'CN', N'MH042', 5, 0);
GO

-- ==========================================================
-- 7. LOPHOCPHAN (46 lớp — có lịch học đầy đủ)
--    TrangThaiLop: MO_DANG_KY / DONG_DANG_KY / DA_KET_THUC
--    SiSoHienTai ban đầu để 0 — bước đồng bộ ở file dữ liệu
--    đăng ký sẽ tính lại cho khớp DANGKYHOCPHAN.
-- ==========================================================
INSERT INTO LOPHOCPHAN (MaLHP, TenLHP, SiSoToiDa, SiSoHienTai, TrangThaiLop, MaMonHoc, MaHocKy, MaGV) VALUES
-- ================= HK1-2023 (ĐÓNG) =================
(N'LHP101', N'Nhập môn LT K11',            40, 0, N'DA_KET_THUC', N'MH001', N'HK1-2023', N'GV004'),
(N'LHP102', N'Giải tích K11',              40, 0, N'DA_KET_THUC', N'MH015', N'HK1-2023', N'GV003'),
(N'LHP103', N'Đại số K11',                 40, 0, N'DA_KET_THUC', N'MH016', N'HK1-2023', N'GV002'),
(N'LHP104', N'Kinh tế vi mô K11',          40, 0, N'DA_KET_THUC', N'MH021', N'HK1-2023', N'GV009'),
(N'LHP105', N'Thống kê kinh tế K11',       40, 0, N'DA_KET_THUC', N'MH030', N'HK1-2023', N'GV009'),
(N'LHP106', N'Cơ học kết cấu K11',         40, 0, N'DA_KET_THUC', N'MH031', N'HK1-2023', N'GV012'),
(N'LHP107', N'Trắc địa K11',               40, 0, N'DA_KET_THUC', N'MH039', N'HK1-2023', N'GV012'),
-- ================= HK2-2023 (ĐÓNG) =================
(N'LHP201', N'Lập trình C/C++ K12',        40, 0, N'DA_KET_THUC', N'MH002', N'HK2-2023', N'GV003'),
(N'LHP202', N'Toán rời rạc K12',           40, 0, N'DA_KET_THUC', N'MH013', N'HK2-2023', N'GV005'),
(N'LHP203', N'Xác suất thống kê K12',      40, 0, N'DA_KET_THUC', N'MH014', N'HK2-2023', N'GV004'),
(N'LHP204', N'Kinh tế vĩ mô K12',          40, 0, N'DA_KET_THUC', N'MH022', N'HK2-2023', N'GV010'),
(N'LHP205', N'Quản trị học K12',           40, 0, N'DA_KET_THUC', N'MH024', N'HK2-2023', N'GV009'),
(N'LHP206', N'Marketing căn bản K12',      40, 0, N'DA_KET_THUC', N'MH025', N'HK2-2023', N'GV010'),
(N'LHP207', N'Sức bền vật liệu K12',       40, 0, N'DA_KET_THUC', N'MH032', N'HK2-2023', N'GV013'),
(N'LHP208', N'Vật liệu xây dựng K12',      40, 0, N'DA_KET_THUC', N'MH036', N'HK2-2023', N'GV013'),
(N'LHP209', N'QL dự án xây dựng K12',      40, 0, N'DA_KET_THUC', N'MH040', N'HK2-2023', N'GV013'),
-- ================= HK1-2024 (ĐÓNG) =================
(N'LHP301', N'CTDL & GT K13',              40, 0, N'DA_KET_THUC', N'MH003', N'HK1-2024', N'GV001'),
(N'LHP302', N'OOP K13',                    40, 0, N'DA_KET_THUC', N'MH006', N'HK1-2024', N'GV004'),
(N'LHP303', N'Kiến trúc máy tính K13',     40, 0, N'DA_KET_THUC', N'MH012', N'HK1-2024', N'GV008'),
(N'LHP304', N'Nguyên lý kế toán K13',      40, 0, N'DA_KET_THUC', N'MH023', N'HK1-2024', N'GV011'),
(N'LHP305', N'Quản trị nhân lực K13',      40, 0, N'DA_KET_THUC', N'MH029', N'HK1-2024', N'GV011'),
(N'LHP306', N'BTCT K13',                   40, 0, N'DA_KET_THUC', N'MH033', N'HK1-2024', N'GV014'),
(N'LHP307', N'Kết cấu thép K13',           40, 0, N'DA_KET_THUC', N'MH034', N'HK1-2024', N'GV012'),
-- ================= HK2-2024 (ĐÓNG) =================
(N'LHP401', N'Cơ sở dữ liệu K14',          40, 0, N'DA_KET_THUC', N'MH004', N'HK2-2024', N'GV001'),
(N'LHP402', N'Lập trình Web K14',          40, 0, N'DA_KET_THUC', N'MH007', N'HK2-2024', N'GV006'),
(N'LHP403', N'Mạng máy tính K14',          40, 0, N'DA_KET_THUC', N'MH009', N'HK2-2024', N'GV008'),
(N'LHP404', N'Tài chính doanh nghiệp K14', 40, 0, N'DA_KET_THUC', N'MH026', N'HK2-2024', N'GV011'),
(N'LHP405', N'Ngân hàng thương mại K14',   40, 0, N'DA_KET_THUC', N'MH027', N'HK2-2024', N'GV009'),
(N'LHP406', N'Nền móng công trình K14',    40, 0, N'DA_KET_THUC', N'MH035', N'HK2-2024', N'GV015'),
(N'LHP407', N'Thủy lực công trình K14',    40, 0, N'DA_KET_THUC', N'MH038', N'HK2-2024', N'GV015'),
-- ================= HK1-2025 (HIỆN TẠI — ĐANG MỞ) =================
-- Khối CNTT
(N'LHP501', N'HQT CSDL K15',               25, 0, N'MO_DANG_KY', N'MH005', N'HK1-2025', N'GV002'),  -- SÁT SĨ SỐ (24/25)
(N'LHP502', N'CNPM K15',                   40, 0, N'MO_DANG_KY', N'MH008', N'HK1-2025', N'GV007'),
(N'LHP503', N'PTTKHT K15',                 40, 0, N'MO_DANG_KY', N'MH018', N'HK1-2025', N'GV007'),
(N'LHP504', N'AI K15',                     40, 0, N'MO_DANG_KY', N'MH019', N'HK1-2025', N'GV006'),
(N'LHP505', N'An toàn TT K15',             40, 0, N'MO_DANG_KY', N'MH010', N'HK1-2025', N'GV008'),
(N'LHP506', N'TA chuyên ngành K15',        30, 0, N'MO_DANG_KY', N'MH017', N'HK1-2025', N'GV001'),
(N'LHP507', N'Hệ điều hành K15',           40, 0, N'MO_DANG_KY', N'MH011', N'HK1-2025', N'GV006'),
(N'LHP508', N'Mobile K15',                 35, 0, N'MO_DANG_KY', N'MH042', N'HK1-2025', N'GV004'),
-- Khối Kinh tế
(N'LHP509', N'Chứng khoán K15',            40, 0, N'MO_DANG_KY', N'MH028', N'HK1-2025', N'GV010'),
(N'LHP510', N'Kế toán quản trị K15',       40, 0, N'MO_DANG_KY', N'MH044', N'HK1-2025', N'GV011'),
(N'LHP511', N'Đầu tư TCQT K15',            40, 0, N'MO_DANG_KY', N'MH047', N'HK1-2025', N'GV010'),
(N'LHP512', N'Phân tích BCTC K15',         40, 0, N'MO_DANG_KY', N'MH048', N'HK1-2025', N'GV011'),
-- Khối Xây dựng
(N'LHP513', N'Quy hoạch đô thị K15',       40, 0, N'MO_DANG_KY', N'MH037', N'HK1-2025', N'GV014'),
(N'LHP514', N'Kết cấu cao tầng K15',       40, 0, N'MO_DANG_KY', N'MH045', N'HK1-2025', N'GV014'),
(N'LHP515', N'Thẩm định dự án XD K15',     40, 0, N'MO_DANG_KY', N'MH046', N'HK1-2025', N'GV015'),
(N'LHP516', N'Công nghệ thi công K15',     40, 0, N'MO_DANG_KY', N'MH049', N'HK1-2025', N'GV013');
GO

-- ==========================================================
-- 8. LICHHOC (lịch học — 1 buổi/lớp; KHÔNG trùng phòng/khung giờ)
--    Thứ: 2 = Thứ Hai ... 8 = Chủ nhật
-- ==========================================================
INSERT INTO LICHHOC (MaLichHoc, MaLHP, MaPhong, Thu, TietBatDau, SoTiet) VALUES
-- HK1-2023
(N'LH101', N'LHP101', N'P101', 2, 1, 3),
(N'LH102', N'LHP102', N'P102', 2, 4, 3),
(N'LH103', N'LHP103', N'P103', 3, 1, 3),
(N'LH104', N'LHP104', N'P201', 2, 1, 3),
(N'LH105', N'LHP105', N'P202', 3, 1, 3),
(N'LH106', N'LHP106', N'P301', 2, 1, 3),
(N'LH107', N'LHP107', N'P302', 3, 1, 3),
-- HK2-2023
(N'LH201', N'LHP201', N'P101', 2, 1, 3),
(N'LH202', N'LHP202', N'P102', 2, 4, 3),
(N'LH203', N'LHP203', N'P103', 3, 1, 3),
(N'LH204', N'LHP204', N'P201', 2, 1, 3),
(N'LH205', N'LHP205', N'P202', 3, 1, 3),
(N'LH206', N'LHP206', N'P203', 4, 1, 3),
(N'LH207', N'LHP207', N'P301', 2, 1, 3),
(N'LH208', N'LHP208', N'P302', 3, 1, 3),
(N'LH209', N'LHP209', N'P303', 4, 1, 3),
-- HK1-2024
(N'LH301', N'LHP301', N'P101', 2, 1, 3),
(N'LH302', N'LHP302', N'P102', 3, 1, 3),
(N'LH303', N'LHP303', N'P103', 4, 1, 3),
(N'LH304', N'LHP304', N'P201', 2, 1, 3),
(N'LH305', N'LHP305', N'P202', 3, 1, 3),
(N'LH306', N'LHP306', N'P301', 2, 1, 3),
(N'LH307', N'LHP307', N'P302', 3, 1, 3),
-- HK2-2024
(N'LH401', N'LHP401', N'P101', 2, 1, 3),
(N'LH402', N'LHP402', N'P102', 3, 1, 3),
(N'LH403', N'LHP403', N'P103', 4, 1, 3),
(N'LH404', N'LHP404', N'P201', 2, 1, 3),
(N'LH405', N'LHP405', N'P202', 3, 1, 3),
(N'LH406', N'LHP406', N'P301', 2, 1, 3),
(N'LH407', N'LHP407', N'P302', 3, 1, 3),
-- HK1-2025 (hiện tại)
(N'LH501', N'LHP501', N'P101', 2, 1, 3),
(N'LH502', N'LHP502', N'P102', 3, 1, 3),
(N'LH503', N'LHP503', N'P103', 4, 1, 3),
(N'LH504', N'LHP504', N'P104', 5, 1, 3),
(N'LH505', N'LHP505', N'P201', 6, 1, 3),
(N'LH506', N'LHP506', N'P202', 2, 4, 2),
(N'LH507', N'LHP507', N'P203', 3, 4, 3),
(N'LH508', N'LHP508', N'P204', 4, 4, 3),
(N'LH509', N'LHP509', N'P301', 2, 1, 3),
(N'LH510', N'LHP510', N'P302', 3, 1, 3),
(N'LH511', N'LHP511', N'P303', 4, 1, 3),
(N'LH512', N'LHP512', N'P304', 5, 1, 3),
(N'LH513', N'LHP513', N'P401', 2, 1, 3),
(N'LH514', N'LHP514', N'P402', 3, 1, 3),
(N'LH515', N'LHP515', N'P401', 4, 1, 3),
(N'LH516', N'LHP516', N'P402', 5, 1, 3);
GO

PRINT N'[OK] Module 2 — Dữ liệu mẫu: 15 GV, 48 môn, 5 học kỳ, 20 phòng, 46 LHP + lịch.';
GO
