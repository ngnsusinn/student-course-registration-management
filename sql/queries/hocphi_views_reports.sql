/*
==========================================================
File: sql/queries/hocphi_views_reports.sql
Module: Học phí, Tài khoản & Báo cáo Thống kê Vận hành
Issue : #55

Mô tả:
- Tạo các VIEW phục vụ báo cáo học phí
- Thống kê tổng thu theo học kỳ, ngành
- Phục vụ truy vấn và báo cáo vận hành

Tác giả: Nhóm TV5
==========================================================
*/

PRINT N'========== TẠO CÁC VIEW HỌC PHÍ =========='
GO

/*=========================================================
VIEW 1: Sinh viên còn nợ học phí
=========================================================*/

IF OBJECT_ID('VW_SinhVienNoHocPhi','V') IS NOT NULL
    DROP VIEW VW_SinhVienNoHocPhi;
GO

CREATE VIEW VW_SinhVienNoHocPhi
AS
SELECT
    hp.MaHocPhi,
    sv.MaSV,
    sv.HoTen,
    hp.MaHocKy,
    hp.SoTinChi,
    hp.DonGiaTinChi,
    hp.TongTien,
    hp.DaNop,
    (hp.TongTien - hp.DaNop) AS SoTienConNo,
    hp.TrangThai
FROM HOCPHI hp
INNER JOIN SINHVIEN sv
    ON hp.MaSV = sv.MaSV
WHERE hp.DaNop < hp.TongTien;
GO


/*=========================================================
VIEW 2: Sinh viên đã thanh toán học phí
=========================================================*/

IF OBJECT_ID('VW_SinhVienDaThanhToan','V') IS NOT NULL
    DROP VIEW VW_SinhVienDaThanhToan;
GO

CREATE VIEW VW_SinhVienDaThanhToan
AS
SELECT
    hp.MaHocPhi,
    sv.MaSV,
    sv.HoTen,
    hp.MaHocKy,
    hp.SoTinChi,
    hp.DonGiaTinChi,
    hp.TongTien,
    hp.DaNop,
    hp.TrangThai
FROM HOCPHI hp
INNER JOIN SINHVIEN sv
    ON hp.MaSV = sv.MaSV
WHERE hp.TrangThai = N'DA_THANH_TOAN';
GO


/*=========================================================
VIEW 3: Tổng thu học phí theo học kỳ
=========================================================*/

IF OBJECT_ID('VW_TongThuTheoHocKy','V') IS NOT NULL
    DROP VIEW VW_TongThuTheoHocKy;
GO

CREATE VIEW VW_TongThuTheoHocKy
AS
SELECT

    hp.MaHocKy,

    COUNT(DISTINCT hp.MaSV) AS SoLuongSinhVien,

    SUM(hp.SoTinChi) AS TongTinChi,

    SUM(hp.TongTien) AS TongHocPhi,

    SUM(hp.DaNop) AS TongDaThu,

    SUM(hp.TongTien - hp.DaNop) AS TongConNo

FROM HOCPHI hp

GROUP BY hp.MaHocKy;
GO


/*=========================================================
VIEW 4: Tổng thu học phí theo ngành
=========================================================*/

IF OBJECT_ID('VW_TongThuTheoNganh','V') IS NOT NULL
    DROP VIEW VW_TongThuTheoNganh;
GO

CREATE VIEW VW_TongThuTheoNganh
AS
SELECT

    n.MaNganh,

    n.TenNganh,

    COUNT(DISTINCT sv.MaSV) AS SoLuongSinhVien,

    SUM(hp.SoTinChi) AS TongTinChi,

    SUM(hp.TongTien) AS TongHocPhi,

    SUM(hp.DaNop) AS TongDaThu,

    SUM(hp.TongTien-hp.DaNop) AS TongConNo

FROM HOCPHI hp

INNER JOIN SINHVIEN sv
    ON hp.MaSV = sv.MaSV

INNER JOIN LOP_SINHHOAT l
    ON sv.MaLopSH = l.MaLopSH

INNER JOIN NGANH n
    ON l.MaNganh = n.MaNganh

GROUP BY

    n.MaNganh,

    n.TenNganh;
GO


/*=========================================================
VIEW 5: Báo cáo tổng hợp học phí
=========================================================*/

IF OBJECT_ID('VW_BaoCaoHocPhi','V') IS NOT NULL
    DROP VIEW VW_BaoCaoHocPhi;
GO

CREATE VIEW VW_BaoCaoHocPhi
AS
SELECT

    hp.MaHocPhi,

    sv.MaSV,

    sv.HoTen,

    l.MaLopSH,

    l.TenLopSH,

    n.MaNganh,

    n.TenNganh,

    hp.MaHocKy,

    hp.SoTinChi,

    hp.DonGiaTinChi,

    hp.TongTien,

    hp.DaNop,

    (hp.TongTien-hp.DaNop) AS SoTienConNo,

    hp.TrangThai

FROM HOCPHI hp

INNER JOIN SINHVIEN sv
    ON hp.MaSV = sv.MaSV

INNER JOIN LOP_SINHHOAT l
    ON sv.MaLopSH = l.MaLopSH

INNER JOIN NGANH n
    ON l.MaNganh = n.MaNganh;
GO

PRINT N'Đã tạo thành công các VIEW phục vụ báo cáo học phí.'
GO
/*
==========================================================
PHẦN II - TRUY VẤN & BÁO CÁO THỐNG KÊ HỌC PHÍ
==========================================================
*/

PRINT N'========== BÁO CÁO THỐNG KÊ HỌC PHÍ =========='
GO

/*=========================================================
1. Danh sách sinh viên còn nợ học phí
=========================================================*/

SELECT *
FROM VW_SinhVienNoHocPhi
ORDER BY SoTienConNo DESC;
GO


/*=========================================================
2. Danh sách sinh viên đã thanh toán học phí
=========================================================*/

SELECT *
FROM VW_SinhVienDaThanhToan
ORDER BY HoTen;
GO


/*=========================================================
3. Top 10 sinh viên còn nợ nhiều nhất
=========================================================*/

SELECT TOP (10)
    MaSV,
    HoTen,
    TenNganh,
    MaHocKy,
    TongTien,
    DaNop,
    SoTienConNo
FROM VW_BaoCaoHocPhi
ORDER BY SoTienConNo DESC;
GO


/*=========================================================
4. Tổng doanh thu học phí
=========================================================*/

SELECT
    SUM(TongTien) AS TongHocPhiPhaiThu,
    SUM(DaNop) AS TongHocPhiDaThu,
    SUM(TongTien - DaNop) AS TongHocPhiConNo
FROM HOCPHI;
GO


/*=========================================================
5. Tổng doanh thu theo học kỳ
=========================================================*/

SELECT *
FROM VW_TongThuTheoHocKy
ORDER BY MaHocKy;
GO


/*=========================================================
6. Tổng doanh thu theo ngành
=========================================================*/

SELECT *
FROM VW_TongThuTheoNganh
ORDER BY TenNganh;
GO


/*=========================================================
7. Thống kê trạng thái học phí
=========================================================*/

SELECT

    TrangThai,

    COUNT(*) AS SoLuongPhieu,

    SUM(TongTien) AS TongHocPhi,

    SUM(DaNop) AS TongDaThu,

    SUM(TongTien - DaNop) AS TongConNo

FROM HOCPHI

GROUP BY TrangThai

ORDER BY TrangThai;
GO


/*=========================================================
8. Sinh viên chưa thanh toán
=========================================================*/

SELECT

    MaSV,

    HoTen,

    TenNganh,

    MaHocKy,

    TongTien,

    DaNop,

    SoTienConNo

FROM VW_BaoCaoHocPhi

WHERE TrangThai = N'CHUA_THANH_TOAN'

ORDER BY SoTienConNo DESC;
GO


/*=========================================================
9. Sinh viên quá hạn học phí
=========================================================*/

SELECT

    MaSV,

    HoTen,

    TenNganh,

    MaHocKy,

    TongTien,

    DaNop,

    SoTienConNo

FROM VW_BaoCaoHocPhi

WHERE TrangThai = N'QUA_HAN'

ORDER BY SoTienConNo DESC;
GO


/*=========================================================
10. Dashboard tổng hợp
=========================================================*/

SELECT

    COUNT(*) AS TongPhieuHocPhi,

    COUNT(DISTINCT MaSV) AS TongSinhVien,

    SUM(TongTien) AS TongHocPhi,

    SUM(DaNop) AS TongDaThu,

    SUM(TongTien - DaNop) AS TongConNo,

    SUM(CASE
            WHEN TrangThai = N'DA_THANH_TOAN'
            THEN 1
            ELSE 0
        END) AS DaThanhToan,

    SUM(CASE
            WHEN TrangThai <> N'DA_THANH_TOAN'
            THEN 1
            ELSE 0
        END) AS ChuaThanhToan

FROM HOCPHI;
GO


/*=========================================================
11. Tỷ lệ thu học phí
=========================================================*/

SELECT

    CAST(SUM(DaNop) * 100.0 / NULLIF(SUM(TongTien),0) AS DECIMAL(5,2))
        AS TyLeThuHocPhi

FROM HOCPHI;
GO


/*=========================================================
12. Số sinh viên theo trạng thái học phí
=========================================================*/

SELECT

    TrangThai,

    COUNT(DISTINCT MaSV) AS SoLuongSinhVien

FROM HOCPHI

GROUP BY TrangThai

ORDER BY TrangThai;
GO


PRINT N'==============================================='
PRINT N'HOÀN THÀNH ISSUE #55'
PRINT N'Đã tạo VIEW và truy vấn thống kê học phí thành công.'
PRINT N'==============================================='
GO
