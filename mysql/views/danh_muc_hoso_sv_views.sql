-- ==========================================================
-- Ten file : mysql/views/danh_muc_hoso_sv_views.sql
-- Module   : Danh muc he thong & Ho so sinh vien (TV1)
-- Mo ta    : View VW_SinhVienDangHoc — danh sach sinh vien
--            dang hoc kem thong tin lop/nganh/khoa.
-- ==========================================================

CREATE OR REPLACE VIEW VW_SinhVienDangHoc AS
SELECT
    sv.MaSV, sv.HoTen, sv.NgaySinh,
    IF(sv.GioiTinh = 1, 'Nam', 'Nu') AS GioiTinh,
    sv.Email, sv.SoDienThoai, sv.QueQuan,
    l.MaLopSH, l.TenLopSH, l.NienKhoa,
    n.MaNganh, n.TenNganh,
    k.MaKhoa, k.TenKhoa
FROM SINHVIEN sv
JOIN LOP_SINHHOAT l ON sv.MaLopSH = l.MaLopSH
JOIN NGANH n ON l.MaNganh = n.MaNganh
JOIN KHOA k ON n.MaKhoa = k.MaKhoa
WHERE sv.TrangThaiHoc = 1;
