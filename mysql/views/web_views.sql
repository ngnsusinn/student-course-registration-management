-- ==========================================================
-- Ten file : mysql/views/web_views.sql
-- Mo ta    : cac view phuc vu tang WEB (backend chi giao tiep
--            voi DB qua VIEW / PROCEDURE / FUNCTION — khong raw query).
-- ==========================================================

-- Tai khoan + ten vai tro (khong kem mat khau — mat khau chi dung trong SP_DangNhap)
CREATE OR REPLACE VIEW VW_TaiKhoanVaiTro AS
SELECT tk.MaTaiKhoan, tk.TenDangNhap, tk.Email, tk.TrangThai,
       tk.MaVaiTro, vt.TenVaiTro, tk.MaSV, tk.MaGV
FROM TAIKHOAN tk
JOIN VAITRO vt ON vt.MaVaiTro = tk.MaVaiTro;

-- Ho so giang vien (auth/hoso)
CREATE OR REPLACE VIEW VW_HoSoGiangVien AS
SELECT gv.MaGV, gv.HoTen, gv.Email, k.TenKhoa
FROM GIANGVIEN gv
LEFT JOIN KHOA k ON k.MaKhoa = gv.MaKhoa;

SELECT '[OK] web_views.sql — da tao 2 view phuc vu tang web.' AS KetLuan;
