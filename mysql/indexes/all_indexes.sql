-- ==========================================================
-- Ten file : mysql/indexes/all_indexes.sql
-- Module   : Tong hop (TV1/TV2/TV3/TV4/TV5)
-- Mo ta    : Ban dich T-SQL -> MySQL. Non-clustered Index +
--            INCLUDE cot -> gop vao composite index (MySQL khong
--            co menh de INCLUDE). Index UNIQUE TenDangNhap da
--            co trong DDL (UQ_TAIKHOAN_TenDangNhap) nen bo qua.
-- ==========================================================

-- Dang ky hoc phan (tra cuu 2 chieu)
CREATE INDEX IX_DKHP_MaSV  ON DANGKYHOCPHAN (MaSV, TrangThaiDangKy, MaLHP);
CREATE INDEX IX_DKHP_MaLHP ON DANGKYHOCPHAN (MaLHP, TrangThaiDangKy);

-- Ho so sinh vien
CREATE INDEX IX_SINHVIEN_HoTen         ON SINHVIEN (HoTen);
CREATE INDEX IX_SINHVIEN_HoTen_MaLopSH ON SINHVIEN (HoTen, MaLopSH);

-- Hoc phi
CREATE INDEX IX_HOCPHI_MaSV ON HOCPHI (MaSV);

-- Lich hoc / Lop hoc phan
CREATE INDEX IX_LichHoc_MaPhong_Thu_Tiet ON LICHHOC (MaPhong, Thu, TietBatDau);
CREATE INDEX IX_LopHocPhan_MaGV_HocKy    ON LOPHOCPHAN (MaGV, MaHocKy);

-- Ket qua hoc tap
CREATE INDEX IX_KETQUAHOCTAP_MaSV    ON KETQUAHOCTAP (MaSV, DiemChu, DiemHe4);
CREATE INDEX IX_KETQUAHOCTAP_MaLHP   ON KETQUAHOCTAP (MaLHP, DiemTongKet);
CREATE INDEX IX_KETQUAHOCTAP_DiemChu ON KETQUAHOCTAP (DiemChu);
