-- ==========================================================
-- Ten file : mysql/data/00_hocphi_taikhoan_data.sql
-- Module   : Hoc phi, Tai khoan & Van hanh he thong (TV5)
-- Mo ta    : VAITRO + TAIKHOAN (SHA2-256) + HOCPHI.
--            Ban dich T-SQL: HASHBYTES -> SHA2, ROW_NUMBER() ->
--            bien phien @rownum (MySQL 5.7 khong co window func).
-- ==========================================================

-- 1. VAITRO
INSERT INTO VAITRO (MaVaiTro, TenVaiTro, MoTa) VALUES
('SV',  'Student',       'Sinh viên — xem/đăng ký/hủy học phần'),
('GV',  'Lecturer',      'Giảng viên — nhập điểm, xem lớp phân công'),
('PĐT', 'AcademicOffice','Phòng đào tạo — quản trị toàn hệ thống');

-- 2. TAIKHOAN (mat khau dang hash SHA-256)
INSERT INTO TAIKHOAN (MaTaiKhoan, TenDangNhap, MatKhau, Email, TrangThai, MaVaiTro, MaSV, MaGV) VALUES
('TK0001', 'sv001', SHA2('matkhau@123', 256), 'sv001@univ.edu.vn', 'ACTIVE', 'SV', 'SV001', NULL),
('TK0002', 'sv002', SHA2('matkhau@123', 256), 'sv002@univ.edu.vn', 'ACTIVE', 'SV', 'SV002', NULL),
('TK0003', 'sv003', SHA2('matkhau@123', 256), 'sv003@univ.edu.vn', 'ACTIVE', 'SV', 'SV003', NULL),
('TK0004', 'sv004', SHA2('matkhau@123', 256), 'sv004@univ.edu.vn', 'ACTIVE', 'SV', 'SV004', NULL),
('TK0005', 'sv005', SHA2('matkhau@123', 256), 'sv005@univ.edu.vn', 'ACTIVE', 'SV', 'SV005', NULL),
('TK0006', 'sv006', SHA2('matkhau@123', 256), 'sv006@univ.edu.vn', 'ACTIVE', 'SV', 'SV006', NULL),
('TK0007', 'sv007', SHA2('matkhau@123', 256), 'sv007@univ.edu.vn', 'ACTIVE', 'SV', 'SV007', NULL),
('TK0008', 'sv008', SHA2('matkhau@123', 256), 'sv008@univ.edu.vn', 'ACTIVE', 'SV', 'SV008', NULL),
('TK0009', 'sv009', SHA2('matkhau@123', 256), 'sv009@univ.edu.vn', 'ACTIVE', 'SV', 'SV009', NULL),
('TK0010', 'sv010', SHA2('matkhau@123', 256), 'sv010@univ.edu.vn', 'ACTIVE', 'SV', 'SV010', NULL),
('TK0011', 'sv011', SHA2('matkhau@123', 256), 'sv011@univ.edu.vn', 'ACTIVE', 'SV', 'SV011', NULL),
('TK0012', 'sv012', SHA2('matkhau@123', 256), 'sv012@univ.edu.vn', 'ACTIVE', 'SV', 'SV012', NULL),
('TK0013', 'sv013', SHA2('matkhau@123', 256), 'sv013@univ.edu.vn', 'ACTIVE', 'SV', 'SV013', NULL),
('TK0014', 'sv014', SHA2('matkhau@123', 256), 'sv014@univ.edu.vn', 'ACTIVE', 'SV', 'SV014', NULL),
('TK0015', 'sv015', SHA2('matkhau@123', 256), 'sv015@univ.edu.vn', 'ACTIVE', 'SV', 'SV015', NULL),
('TK0016', 'sv016', SHA2('matkhau@123', 256), 'sv016@univ.edu.vn', 'ACTIVE', 'SV', 'SV016', NULL),
('TK0017', 'sv017', SHA2('matkhau@123', 256), 'sv017@univ.edu.vn', 'ACTIVE', 'SV', 'SV017', NULL),
('TK0018', 'sv018', SHA2('matkhau@123', 256), 'sv018@univ.edu.vn', 'ACTIVE', 'SV', 'SV018', NULL),
('TK0019', 'sv019', SHA2('matkhau@123', 256), 'sv019@univ.edu.vn', 'ACTIVE', 'SV', 'SV019', NULL),
('TK0020', 'sv020', SHA2('matkhau@123', 256), 'sv020@univ.edu.vn', 'ACTIVE', 'SV', 'SV020', NULL),
('TK0021', 'sv021', SHA2('matkhau@123', 256), 'sv021@univ.edu.vn', 'ACTIVE', 'SV', 'SV021', NULL),
('TK0022', 'sv022', SHA2('matkhau@123', 256), 'sv022@univ.edu.vn', 'ACTIVE', 'SV', 'SV022', NULL),
('TK0023', 'sv023', SHA2('matkhau@123', 256), 'sv023@univ.edu.vn', 'ACTIVE', 'SV', 'SV023', NULL),
('TK0024', 'sv024', SHA2('matkhau@123', 256), 'sv024@univ.edu.vn', 'ACTIVE', 'SV', 'SV024', NULL),
('TK0025', 'sv025', SHA2('matkhau@123', 256), 'sv025@univ.edu.vn', 'ACTIVE', 'SV', 'SV025', NULL),
('TK0026', 'sv026', SHA2('matkhau@123', 256), 'sv026@univ.edu.vn', 'ACTIVE', 'SV', 'SV026', NULL),
('TK0027', 'sv027', SHA2('matkhau@123', 256), 'sv027@univ.edu.vn', 'ACTIVE', 'SV', 'SV027', NULL),
('TK0028', 'sv028', SHA2('matkhau@123', 256), 'sv028@univ.edu.vn', 'ACTIVE', 'SV', 'SV028', NULL),
('TK0029', 'sv029', SHA2('matkhau@123', 256), 'sv029@univ.edu.vn', 'ACTIVE', 'SV', 'SV029', NULL),
('TK0030', 'sv030', SHA2('matkhau@123', 256), 'sv030@univ.edu.vn', 'ACTIVE', 'SV', 'SV030', NULL),
('TK0031', 'sv031', SHA2('matkhau@123', 256), 'sv031@univ.edu.vn', 'ACTIVE', 'SV', 'SV031', NULL),
('TK0032', 'sv032', SHA2('matkhau@123', 256), 'sv032@univ.edu.vn', 'ACTIVE', 'SV', 'SV032', NULL),
('TK0033', 'sv033', SHA2('matkhau@123', 256), 'sv033@univ.edu.vn', 'ACTIVE', 'SV', 'SV033', NULL),
('TK0034', 'sv034', SHA2('matkhau@123', 256), 'sv034@univ.edu.vn', 'ACTIVE', 'SV', 'SV034', NULL),
('TK0035', 'sv035', SHA2('matkhau@123', 256), 'sv035@univ.edu.vn', 'ACTIVE', 'SV', 'SV035', NULL),
('TK0036', 'sv036', SHA2('matkhau@123', 256), 'sv036@univ.edu.vn', 'ACTIVE', 'SV', 'SV036', NULL),
('TK0037', 'sv037', SHA2('matkhau@123', 256), 'sv037@univ.edu.vn', 'ACTIVE', 'SV', 'SV037', NULL),
('TK0038', 'sv038', SHA2('matkhau@123', 256), 'sv038@univ.edu.vn', 'ACTIVE', 'SV', 'SV038', NULL),
('TK0039', 'sv039', SHA2('matkhau@123', 256), 'sv039@univ.edu.vn', 'ACTIVE', 'SV', 'SV039', NULL),
('TK0040', 'sv040', SHA2('matkhau@123', 256), 'sv040@univ.edu.vn', 'ACTIVE', 'SV', 'SV040', NULL),
('TK0041', 'sv041', SHA2('matkhau@123', 256), 'sv041@univ.edu.vn', 'ACTIVE', 'SV', 'SV041', NULL),
('TK0042', 'sv042', SHA2('matkhau@123', 256), 'sv042@univ.edu.vn', 'ACTIVE', 'SV', 'SV042', NULL),
('TK0043', 'sv043', SHA2('matkhau@123', 256), 'sv043@univ.edu.vn', 'ACTIVE', 'SV', 'SV043', NULL),
('TK0044', 'sv044', SHA2('matkhau@123', 256), 'sv044@univ.edu.vn', 'ACTIVE', 'SV', 'SV044', NULL),
('TK0045', 'sv045', SHA2('matkhau@123', 256), 'sv045@univ.edu.vn', 'ACTIVE', 'SV', 'SV045', NULL),
('TK0046', 'sv046', SHA2('matkhau@123', 256), 'sv046@univ.edu.vn', 'ACTIVE', 'SV', 'SV046', NULL),
('TK0047', 'sv047', SHA2('matkhau@123', 256), 'sv047@univ.edu.vn', 'ACTIVE', 'SV', 'SV047', NULL),
('TK0048', 'sv048', SHA2('matkhau@123', 256), 'sv048@univ.edu.vn', 'ACTIVE', 'SV', 'SV048', NULL),
('TK0049', 'sv049', SHA2('matkhau@123', 256), 'sv049@univ.edu.vn', 'ACTIVE', 'SV', 'SV049', NULL),
('TK0050', 'sv050', SHA2('matkhau@123', 256), 'sv050@univ.edu.vn', 'ACTIVE', 'SV', 'SV050', NULL),
('TK0051', 'sv051', SHA2('matkhau@123', 256), 'sv051@univ.edu.vn', 'ACTIVE', 'SV', 'SV051', NULL),
('TK0052', 'sv052', SHA2('matkhau@123', 256), 'sv052@univ.edu.vn', 'ACTIVE', 'SV', 'SV052', NULL),
('TK0053', 'sv053', SHA2('matkhau@123', 256), 'sv053@univ.edu.vn', 'ACTIVE', 'SV', 'SV053', NULL),
('TK0054', 'sv054', SHA2('matkhau@123', 256), 'sv054@univ.edu.vn', 'ACTIVE', 'SV', 'SV054', NULL),
('TK0055', 'sv055', SHA2('matkhau@123', 256), 'sv055@univ.edu.vn', 'ACTIVE', 'SV', 'SV055', NULL),
('TK0056', 'sv056', SHA2('matkhau@123', 256), 'sv056@univ.edu.vn', 'ACTIVE', 'SV', 'SV056', NULL),
('TK0057', 'sv057', SHA2('matkhau@123', 256), 'sv057@univ.edu.vn', 'ACTIVE', 'SV', 'SV057', NULL),
('TK0058', 'sv058', SHA2('matkhau@123', 256), 'sv058@univ.edu.vn', 'ACTIVE', 'SV', 'SV058', NULL),
('TK0059', 'sv059', SHA2('matkhau@123', 256), 'sv059@univ.edu.vn', 'ACTIVE', 'SV', 'SV059', NULL),
('TK0060', 'sv060', SHA2('matkhau@123', 256), 'sv060@univ.edu.vn', 'LOCKED', 'SV', 'SV060', NULL),
('TK1001', 'gv001', SHA2('matkhau@123', 256), 'minhhieu@univ.edu.vn',   'ACTIVE', 'GV', NULL, 'GV001'),
('TK1002', 'gv002', SHA2('matkhau@123', 256), 'lanchi@univ.edu.vn',     'ACTIVE', 'GV', NULL, 'GV002'),
('TK1003', 'gv003', SHA2('matkhau@123', 256), 'minhduc@univ.edu.vn',    'ACTIVE', 'GV', NULL, 'GV003'),
('TK1004', 'gv004', SHA2('matkhau@123', 256), 'thihang@univ.edu.vn',    'ACTIVE', 'GV', NULL, 'GV004'),
('TK1005', 'gv005', SHA2('matkhau@123', 256), 'vankhoa@univ.edu.vn',    'ACTIVE', 'GV', NULL, 'GV005'),
('TK1006', 'gv006', SHA2('matkhau@123', 256), 'quanglam@univ.edu.vn',   'ACTIVE', 'GV', NULL, 'GV006'),
('TK1007', 'gv007', SHA2('matkhau@123', 256), 'thimo@univ.edu.vn',      'ACTIVE', 'GV', NULL, 'GV007'),
('TK1008', 'gv008', SHA2('matkhau@123', 256), 'dinhnam@univ.edu.vn',    'ACTIVE', 'GV', NULL, 'GV008'),
('TK1009', 'gv009', SHA2('matkhau@123', 256), 'thuphuong@univ.edu.vn',  'ACTIVE', 'GV', NULL, 'GV009'),
('TK1010', 'gv010', SHA2('matkhau@123', 256), 'quangthang@univ.edu.vn', 'ACTIVE', 'GV', NULL, 'GV010'),
('TK1011', 'gv011', SHA2('matkhau@123', 256), 'thivan@univ.edu.vn',     'ACTIVE', 'GV', NULL, 'GV011'),
('TK1012', 'gv012', SHA2('matkhau@123', 256), 'khactuan@univ.edu.vn',   'ACTIVE', 'GV', NULL, 'GV012'),
('TK1013', 'gv013', SHA2('matkhau@123', 256), 'vanthanh@univ.edu.vn',   'ACTIVE', 'GV', NULL, 'GV013'),
('TK1014', 'gv014', SHA2('matkhau@123', 256), 'thingoc@univ.edu.vn',    'ACTIVE', 'GV', NULL, 'GV014'),
('TK1015', 'gv015', SHA2('matkhau@123', 256), 'minhquan@univ.edu.vn',   'ACTIVE', 'GV', NULL, 'GV015'),
('TK2000', 'admin', SHA2('admin@123', 256),   'pdt@univ.edu.vn',        'ACTIVE', 'PĐT', NULL, NULL);

-- 3. HOCPHI — tinh cho SV da DK hoc ky HK1-2025 (don gia 850.000d/TC)
SET @rownum := 0;
INSERT INTO HOCPHI (MaHocPhi, MaSV, MaHocKy, SoTinChi, DonGiaTinChi, TongTien, DaNop, TrangThai)
SELECT
    CONCAT('HP', LPAD(num.rn, 4, '0')),
    num.MaSV,
    'HK1-2025',
    num.SoTinChi,
    850000,
    num.TongTien,
    num.DaNop,
    num.TrangThai
FROM (
    SELECT @rownum := @rownum + 1 AS rn, agg.*
    FROM (
        SELECT
            s.MaSV,
            SUM(m.SoTinChi) AS SoTinChi,
            SUM(m.SoTinChi) * 850000 AS TongTien,
            CASE
                WHEN s.MaSV = 'SV060' THEN 0
                WHEN s.MaSV IN ('SV001', 'SV002', 'SV003') THEN SUM(m.SoTinChi) * 850000
                ELSE SUM(m.SoTinChi) * 850000 / 2
            END AS DaNop,
            CASE
                WHEN s.MaSV = 'SV060' THEN 'CHUA_THANH_TOAN'
                WHEN s.MaSV IN ('SV001', 'SV002', 'SV003') THEN 'DA_THANH_TOAN'
                ELSE 'DANG_XU_LY'
            END AS TrangThai
        FROM SINHVIEN s
        JOIN DANGKYHOCPHAN d ON d.MaSV = s.MaSV
        JOIN LOPHOCPHAN l ON l.MaLHP = d.MaLHP
        JOIN MONHOC m ON m.MaMonHoc = l.MaMonHoc
        WHERE l.MaHocKy = 'HK1-2025'
          AND d.TrangThaiDangKy = 'DA_DANG_KY'
        GROUP BY s.MaSV
        ORDER BY s.MaSV
    ) agg
) num;
