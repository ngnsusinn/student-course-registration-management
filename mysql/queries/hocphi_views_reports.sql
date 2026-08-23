-- ==========================================================
-- Ten file : mysql/queries/hocphi_views_reports.sql
-- Module   : Hoc phi, Tai khoan & Bao cao thong ke van hanh (TV5)
-- Mo ta    : Ban dich T-SQL -> MySQL.
--            Cac VIEW hoc phi + bao cao: SV no hoc phi, da thanh
--            toan, tong thu theo HK/nganh, bao cao tong hop.
--            (Cac view nay da tao o mysql/views/hocphi_views.sql)
-- ==========================================================

-- ==========================================================
-- Q1. SINH VIEN CON NO HOC PHI (View VW_SinhVienNoHocPhi)
-- ==========================================================
SELECT MaHocPhi, MaSV, HoTen, MaHocKy, SoTinChi, DonGiaTinChi,
       TongTien, DaNop, SoTienConNo, TrangThai
FROM VW_SinhVienNoHocPhi
ORDER BY SoTienConNo DESC;

-- ==========================================================
-- Q2. SINH VIEN DA THANH TOAN HOC PHI (View VW_SinhVienDaThanhToan)
-- ==========================================================
SELECT * FROM VW_SinhVienDaThanhToan ORDER BY MaSV;

-- ==========================================================
-- Q3. TONG THU HOC PHI THEO HOC KY (View VW_TongThuTheoHocKy)
-- ==========================================================
SELECT * FROM VW_TongThuTheoHocKy ORDER BY MaHocKy;

-- ==========================================================
-- Q4. TONG THU HOC PHI THEO NGANH (View VW_TongThuTheoNganh)
-- ==========================================================
SELECT * FROM VW_TongThuTheoNganh;

-- ==========================================================
-- Q5. BAO CAO TONG HOP (View VW_BaoCaoHocPhi + thong ke he thong)
-- ==========================================================
SELECT * FROM VW_BaoCaoHocPhi;

-- Thong ke tong hop toan he thong (dashboard)
SELECT
    (SELECT COUNT(*) FROM SINHVIEN) AS TongSinhVien,
    (SELECT COUNT(*) FROM SINHVIEN WHERE TrangThaiHoc = 1) AS SvDangHoc,
    (SELECT COUNT(*) FROM GIANGVIEN) AS TongGiangVien,
    (SELECT COUNT(*) FROM MONHOC) AS TongMonHoc,
    (SELECT COUNT(*) FROM LOPHOCPHAN) AS TongLopHocPhan,
    (SELECT COUNT(*) FROM LOPHOCPHAN WHERE TrangThaiLop = 'MO_DANG_KY') AS LopDangMo,
    (SELECT COUNT(*) FROM DANGKYHOCPHAN WHERE TrangThaiDangKy = 'DA_DANG_KY') AS TongDangKyHieuLuc,
    (SELECT COUNT(*) FROM HOCPHI) AS TongPhieuHocPhi,
    (SELECT SUM(TongTien) FROM HOCPHI) AS TongHocPhi,
    (SELECT SUM(DaNop) FROM HOCPHI) AS TongDaThu,
    (SELECT SUM(TongTien - DaNop) FROM HOCPHI) AS TongConNo,
    (SELECT COUNT(*) FROM TAIKHOAN) AS TongTaiKhoan;

-- ==========================================================
-- Q6. THONG KE HOAT DONG TAI KHOAN (dang nhap / doi mat khau)
-- ==========================================================
SELECT tk.MaTaiKhoan, tk.TenDangNhap, tk.Email, tk.TrangThai,
       vt.TenVaiTro, tk.MaSV, tk.MaGV,
       (SELECT COUNT(*) FROM NHATKY_DOIMATKHAU nd WHERE nd.MaTaiKhoan = tk.MaTaiKhoan) AS SoLanDoiMatKhau
FROM TAIKHOAN tk
JOIN VAITRO vt ON vt.MaVaiTro = tk.MaVaiTro
ORDER BY tk.MaTaiKhoan;
