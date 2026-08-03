-- ==========================================================
-- Tên file : sql/data/00_hocphi_taikhoan_data.sql
-- Module   : Học phí, Tài khoản & Vận hành hệ thống (TV5)
-- Mô tả    : VAITRO + TAIKHOAN + HOCPHI mẫu cho 3 nhóm vai trò.
--            Học phí tính theo tổng tín chỉ ĐK của học kỳ HK1-2025
--            với đơn giá 850.000 VNĐ/tín chỉ.
-- ==========================================================

-- ==========================================================
-- 1. VAITRO
-- ==========================================================
INSERT INTO VAITRO (MaVaiTro, TenVaiTro, MoTa) VALUES
(N'SV',  N'Student',       N'Sinh viên — xem/đăng ký/hủy học phần'),
(N'GV',  N'Lecturer',      N'Giảng viên — nhập điểm, xem lớp phân công'),
(N'PĐT', N'AcademicOffice',N'Phòng đào tạo — quản trị toàn hệ thống');
GO

-- ==========================================================
-- 2. TAIKHOAN (mật khẩu dạng hash SHA-256 minh hoạ — không bao giờ lưu plaintext)
--    SV: sv001..sv060 | GV: gv001..gv015 | PĐT: admin
-- ==========================================================
INSERT INTO TAIKHOAN (MaTaiKhoan, TenDangNhap, MatKhau, Email, TrangThai, MaVaiTro, MaSV, MaGV) VALUES
(N'TK0001', N'sv001', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv001@univ.edu.vn', N'ACTIVE', N'SV', N'SV001', NULL),
(N'TK0002', N'sv002', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv002@univ.edu.vn', N'ACTIVE', N'SV', N'SV002', NULL),
(N'TK0003', N'sv003', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv003@univ.edu.vn', N'ACTIVE', N'SV', N'SV003', NULL),
(N'TK0004', N'sv004', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv004@univ.edu.vn', N'ACTIVE', N'SV', N'SV004', NULL),
(N'TK0005', N'sv005', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv005@univ.edu.vn', N'ACTIVE', N'SV', N'SV005', NULL),
(N'TK0006', N'sv006', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv006@univ.edu.vn', N'ACTIVE', N'SV', N'SV006', NULL),
(N'TK0007', N'sv007', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv007@univ.edu.vn', N'ACTIVE', N'SV', N'SV007', NULL),
(N'TK0008', N'sv008', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv008@univ.edu.vn', N'ACTIVE', N'SV', N'SV008', NULL),
(N'TK0009', N'sv009', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv009@univ.edu.vn', N'ACTIVE', N'SV', N'SV009', NULL),
(N'TK0010', N'sv010', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv010@univ.edu.vn', N'ACTIVE', N'SV', N'SV010', NULL),
(N'TK0011', N'sv011', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv011@univ.edu.vn', N'ACTIVE', N'SV', N'SV011', NULL),
(N'TK0012', N'sv012', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv012@univ.edu.vn', N'ACTIVE', N'SV', N'SV012', NULL),
(N'TK0013', N'sv013', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv013@univ.edu.vn', N'ACTIVE', N'SV', N'SV013', NULL),
(N'TK0014', N'sv014', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv014@univ.edu.vn', N'ACTIVE', N'SV', N'SV014', NULL),
(N'TK0015', N'sv015', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv015@univ.edu.vn', N'ACTIVE', N'SV', N'SV015', NULL),
(N'TK0016', N'sv016', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv016@univ.edu.vn', N'ACTIVE', N'SV', N'SV016', NULL),
(N'TK0017', N'sv017', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv017@univ.edu.vn', N'ACTIVE', N'SV', N'SV017', NULL),
(N'TK0018', N'sv018', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv018@univ.edu.vn', N'ACTIVE', N'SV', N'SV018', NULL),
(N'TK0019', N'sv019', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv019@univ.edu.vn', N'ACTIVE', N'SV', N'SV019', NULL),
(N'TK0020', N'sv020', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv020@univ.edu.vn', N'ACTIVE', N'SV', N'SV020', NULL),
(N'TK0021', N'sv021', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv021@univ.edu.vn', N'ACTIVE', N'SV', N'SV021', NULL),
(N'TK0022', N'sv022', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv022@univ.edu.vn', N'ACTIVE', N'SV', N'SV022', NULL),
(N'TK0023', N'sv023', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv023@univ.edu.vn', N'ACTIVE', N'SV', N'SV023', NULL),
(N'TK0024', N'sv024', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv024@univ.edu.vn', N'ACTIVE', N'SV', N'SV024', NULL),
(N'TK0025', N'sv025', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv025@univ.edu.vn', N'ACTIVE', N'SV', N'SV025', NULL),
(N'TK0026', N'sv026', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv026@univ.edu.vn', N'ACTIVE', N'SV', N'SV026', NULL),
(N'TK0027', N'sv027', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv027@univ.edu.vn', N'ACTIVE', N'SV', N'SV027', NULL),
(N'TK0028', N'sv028', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv028@univ.edu.vn', N'ACTIVE', N'SV', N'SV028', NULL),
(N'TK0029', N'sv029', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv029@univ.edu.vn', N'ACTIVE', N'SV', N'SV029', NULL),
(N'TK0030', N'sv030', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv030@univ.edu.vn', N'ACTIVE', N'SV', N'SV030', NULL),
(N'TK0031', N'sv031', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv031@univ.edu.vn', N'ACTIVE', N'SV', N'SV031', NULL),
(N'TK0032', N'sv032', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv032@univ.edu.vn', N'ACTIVE', N'SV', N'SV032', NULL),
(N'TK0033', N'sv033', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv033@univ.edu.vn', N'ACTIVE', N'SV', N'SV033', NULL),
(N'TK0034', N'sv034', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv034@univ.edu.vn', N'ACTIVE', N'SV', N'SV034', NULL),
(N'TK0035', N'sv035', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv035@univ.edu.vn', N'ACTIVE', N'SV', N'SV035', NULL),
(N'TK0036', N'sv036', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv036@univ.edu.vn', N'ACTIVE', N'SV', N'SV036', NULL),
(N'TK0037', N'sv037', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv037@univ.edu.vn', N'ACTIVE', N'SV', N'SV037', NULL),
(N'TK0038', N'sv038', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv038@univ.edu.vn', N'ACTIVE', N'SV', N'SV038', NULL),
(N'TK0039', N'sv039', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv039@univ.edu.vn', N'ACTIVE', N'SV', N'SV039', NULL),
(N'TK0040', N'sv040', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv040@univ.edu.vn', N'ACTIVE', N'SV', N'SV040', NULL),
(N'TK0041', N'sv041', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv041@univ.edu.vn', N'ACTIVE', N'SV', N'SV041', NULL),
(N'TK0042', N'sv042', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv042@univ.edu.vn', N'ACTIVE', N'SV', N'SV042', NULL),
(N'TK0043', N'sv043', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv043@univ.edu.vn', N'ACTIVE', N'SV', N'SV043', NULL),
(N'TK0044', N'sv044', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv044@univ.edu.vn', N'ACTIVE', N'SV', N'SV044', NULL),
(N'TK0045', N'sv045', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv045@univ.edu.vn', N'ACTIVE', N'SV', N'SV045', NULL),
(N'TK0046', N'sv046', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv046@univ.edu.vn', N'ACTIVE', N'SV', N'SV046', NULL),
(N'TK0047', N'sv047', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv047@univ.edu.vn', N'ACTIVE', N'SV', N'SV047', NULL),
(N'TK0048', N'sv048', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv048@univ.edu.vn', N'ACTIVE', N'SV', N'SV048', NULL),
(N'TK0049', N'sv049', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv049@univ.edu.vn', N'ACTIVE', N'SV', N'SV049', NULL),
(N'TK0050', N'sv050', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv050@univ.edu.vn', N'ACTIVE', N'SV', N'SV050', NULL),
(N'TK0051', N'sv051', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv051@univ.edu.vn', N'ACTIVE', N'SV', N'SV051', NULL),
(N'TK0052', N'sv052', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv052@univ.edu.vn', N'ACTIVE', N'SV', N'SV052', NULL),
(N'TK0053', N'sv053', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv053@univ.edu.vn', N'ACTIVE', N'SV', N'SV053', NULL),
(N'TK0054', N'sv054', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv054@univ.edu.vn', N'ACTIVE', N'SV', N'SV054', NULL),
(N'TK0055', N'sv055', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv055@univ.edu.vn', N'ACTIVE', N'SV', N'SV055', NULL),
(N'TK0056', N'sv056', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv056@univ.edu.vn', N'ACTIVE', N'SV', N'SV056', NULL),
(N'TK0057', N'sv057', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv057@univ.edu.vn', N'ACTIVE', N'SV', N'SV057', NULL),
(N'TK0058', N'sv058', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv058@univ.edu.vn', N'ACTIVE', N'SV', N'SV058', NULL),
(N'TK0059', N'sv059', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv059@univ.edu.vn', N'ACTIVE', N'SV', N'SV059', NULL),
(N'TK0060', N'sv060', HASHBYTES('SHA2_256', N'matkhau@123'), N'sv060@univ.edu.vn', N'LOCKED', N'SV', N'SV060', NULL),
(N'TK1001', N'gv001', HASHBYTES('SHA2_256', N'matkhau@123'), N'minhhieu@univ.edu.vn', N'ACTIVE', N'GV', NULL, N'GV001'),
(N'TK1002', N'gv002', HASHBYTES('SHA2_256', N'matkhau@123'), N'lanchi@univ.edu.vn', N'ACTIVE', N'GV', NULL, N'GV002'),
(N'TK1003', N'gv003', HASHBYTES('SHA2_256', N'matkhau@123'), N'minhduc@univ.edu.vn', N'ACTIVE', N'GV', NULL, N'GV003'),
(N'TK1004', N'gv004', HASHBYTES('SHA2_256', N'matkhau@123'), N'thihang@univ.edu.vn', N'ACTIVE', N'GV', NULL, N'GV004'),
(N'TK1005', N'gv005', HASHBYTES('SHA2_256', N'matkhau@123'), N'vankhoa@univ.edu.vn', N'ACTIVE', N'GV', NULL, N'GV005'),
(N'TK1006', N'gv006', HASHBYTES('SHA2_256', N'matkhau@123'), N'quanglam@univ.edu.vn', N'ACTIVE', N'GV', NULL, N'GV006'),
(N'TK1007', N'gv007', HASHBYTES('SHA2_256', N'matkhau@123'), N'thimo@univ.edu.vn', N'ACTIVE', N'GV', NULL, N'GV007'),
(N'TK1008', N'gv008', HASHBYTES('SHA2_256', N'matkhau@123'), N'dinhnam@univ.edu.vn', N'ACTIVE', N'GV', NULL, N'GV008'),
(N'TK1009', N'gv009', HASHBYTES('SHA2_256', N'matkhau@123'), N'thuphuong@univ.edu.vn', N'ACTIVE', N'GV', NULL, N'GV009'),
(N'TK1010', N'gv010', HASHBYTES('SHA2_256', N'matkhau@123'), N'quangthang@univ.edu.vn', N'ACTIVE', N'GV', NULL, N'GV010'),
(N'TK1011', N'gv011', HASHBYTES('SHA2_256', N'matkhau@123'), N'thivan@univ.edu.vn', N'ACTIVE', N'GV', NULL, N'GV011'),
(N'TK1012', N'gv012', HASHBYTES('SHA2_256', N'matkhau@123'), N'khactuan@univ.edu.vn', N'ACTIVE', N'GV', NULL, N'GV012'),
(N'TK1013', N'gv013', HASHBYTES('SHA2_256', N'matkhau@123'), N'vanthanh@univ.edu.vn', N'ACTIVE', N'GV', NULL, N'GV013'),
(N'TK1014', N'gv014', HASHBYTES('SHA2_256', N'matkhau@123'), N'thingoc@univ.edu.vn', N'ACTIVE', N'GV', NULL, N'GV014'),
(N'TK1015', N'gv015', HASHBYTES('SHA2_256', N'matkhau@123'), N'minhquan@univ.edu.vn', N'ACTIVE', N'GV', NULL, N'GV015'),
(N'TK2000', N'admin', HASHBYTES('SHA2_256', N'admin@123'),   N'pdtt@univ.edu.vn', N'ACTIVE', N'PĐT', NULL, NULL);
GO

-- ==========================================================
-- 3. HOCPHI — tính cho SV đã ĐK học kỳ HK1-2025 (đơn giá 850.000đ/TC)
--    (TongTien = tổng tín chỉ × đơn giá; TrangThai đa dạng)
-- ==========================================================
INSERT INTO HOCPHI (MaHocPhi, MaSV, MaHocKy, SoTinChi, DonGiaTinChi, TongTien, DaNop, TrangThai)
SELECT
    N'HP' + RIGHT('0000' + CAST(ROW_NUMBER() OVER (ORDER BY s.MaSV) AS VARCHAR(4)), 4),
    s.MaSV,
    N'HK1-2025',
    SUM(m.SoTinChi),
    850000,
    SUM(m.SoTinChi) * 850000,
    CASE
        WHEN s.MaSV = N'SV060' THEN 0                                   -- chưa nộp
        WHEN s.MaSV IN (N'SV001', N'SV002', N'SV003') THEN SUM(m.SoTinChi) * 850000  -- đã nộp đủ
        ELSE SUM(m.SoTinChi) * 850000 / 2                               -- đã nộp 1 nửa
    END,
    CASE
        WHEN s.MaSV = N'SV060' THEN N'CHUA_THANH_TOAN'
        WHEN s.MaSV IN (N'SV001', N'SV002', N'SV003') THEN N'DA_THANH_TOAN'
        ELSE N'DANG_XU_LY'
    END
FROM SINHVIEN s
JOIN DANGKYHOCPHAN d ON d.MaSV = s.MaSV
JOIN LOPHOCPHAN l ON l.MaLHP = d.MaLHP
JOIN MONHOC m ON m.MaMonHoc = l.MaMonHoc
WHERE l.MaHocKy = N'HK1-2025'
  AND d.TrangThaiDangKy = N'DA_DANG_KY'
GROUP BY s.MaSV;
GO

-- ==========================================================
-- 4. KIỂM TRA NHANH
-- ==========================================================
PRINT N'--- [Module 5] Số tài khoản / bản ghi học phí ---';
SELECT
    (SELECT COUNT(*) FROM TAIKHOAN) AS [Số tài khoản],
    (SELECT COUNT(*) FROM HOCPHI)   AS [Số bản ghi học phí];
GO
