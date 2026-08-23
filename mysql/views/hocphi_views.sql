-- ==========================================================
-- Ten file : mysql/views/hocphi_views.sql
-- Module   : Hoc phi, Tai khoan & Bao cao (TV5)
-- Mo ta    : Ban dich T-SQL -> MySQL: 5 VIEW bao cao hoc phi.
-- ==========================================================

CREATE OR REPLACE VIEW VW_SinhVienNoHocPhi AS
SELECT
    hp.MaHocPhi, sv.MaSV, sv.HoTen, hp.MaHocKy, hp.SoTinChi,
    hp.DonGiaTinChi, hp.TongTien, hp.DaNop,
    (hp.TongTien - hp.DaNop) AS SoTienConNo,
    hp.TrangThai
FROM HOCPHI hp
INNER JOIN SINHVIEN sv ON hp.MaSV = sv.MaSV
WHERE hp.DaNop < hp.TongTien;

CREATE OR REPLACE VIEW VW_SinhVienDaThanhToan AS
SELECT
    hp.MaHocPhi, sv.MaSV, sv.HoTen, hp.MaHocKy, hp.SoTinChi,
    hp.DonGiaTinChi, hp.TongTien, hp.DaNop, hp.TrangThai
FROM HOCPHI hp
INNER JOIN SINHVIEN sv ON hp.MaSV = sv.MaSV
WHERE hp.TrangThai = 'DA_THANH_TOAN';

CREATE OR REPLACE VIEW VW_TongThuTheoHocKy AS
SELECT
    hp.MaHocKy,
    COUNT(DISTINCT hp.MaSV) AS SoLuongSinhVien,
    SUM(hp.SoTinChi) AS TongTinChi,
    SUM(hp.TongTien) AS TongHocPhi,
    SUM(hp.DaNop) AS TongDaThu,
    SUM(hp.TongTien - hp.DaNop) AS TongConNo
FROM HOCPHI hp
GROUP BY hp.MaHocKy;

CREATE OR REPLACE VIEW VW_TongThuTheoNganh AS
SELECT
    n.MaNganh, n.TenNganh,
    COUNT(DISTINCT sv.MaSV) AS SoLuongSinhVien,
    SUM(hp.SoTinChi) AS TongTinChi,
    SUM(hp.TongTien) AS TongHocPhi,
    SUM(hp.DaNop) AS TongDaThu,
    SUM(hp.TongTien - hp.DaNop) AS TongConNo
FROM HOCPHI hp
INNER JOIN SINHVIEN sv ON hp.MaSV = sv.MaSV
INNER JOIN LOP_SINHHOAT l ON sv.MaLopSH = l.MaLopSH
INNER JOIN NGANH n ON l.MaNganh = n.MaNganh
GROUP BY n.MaNganh, n.TenNganh;

CREATE OR REPLACE VIEW VW_BaoCaoHocPhi AS
SELECT
    hp.MaHocPhi, sv.MaSV, sv.HoTen, l.MaLopSH, l.TenLopSH,
    n.MaNganh, n.TenNganh, hp.MaHocKy, hp.SoTinChi,
    hp.DonGiaTinChi, hp.TongTien, hp.DaNop,
    (hp.TongTien - hp.DaNop) AS SoTienConNo,
    hp.TrangThai
FROM HOCPHI hp
INNER JOIN SINHVIEN sv ON hp.MaSV = sv.MaSV
INNER JOIN LOP_SINHHOAT l ON sv.MaLopSH = l.MaLopSH
INNER JOIN NGANH n ON l.MaNganh = n.MaNganh;
