-- ==========================================================
-- Tên file : sql/procedures/sp_gpa.sql
-- Module   : Module 4 — Điểm số & Kết quả học tập (TV4 — Wiett)
-- Issue    : #54 SP tính GPA học kỳ & tích lũy
-- Mô tả    : Stored Procedures:
--            1. SP_TinhGPA_HocKy: Tính điểm trung bình GPA hệ 4 theo học kỳ
--            2. SP_TinhCPA_TichLuy: Tính điểm trung bình tích lũy CPA toàn khóa,
--               xử lý case môn học lại (chỉ tính điểm lần cao nhất/mới nhất).
-- ==========================================================

USE [StudentCourseRegistration];
GO

-- ==========================================================
-- 1. STORED PROCEDURE TÍNH GPA HỌC KỲ (SP_TinhGPA_HocKy)
-- ==========================================================
IF OBJECT_ID(N'SP_TinhGPA_HocKy', N'P') IS NOT NULL DROP PROCEDURE SP_TinhGPA_HocKy;
GO

CREATE PROCEDURE SP_TinhGPA_HocKy
    @MaSV VARCHAR(12),
    @MaHocKy VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra sinh viên có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM SINHVIEN WHERE MaSV = @MaSV)
    BEGIN
        RAISERROR(N'Lỗi: Mã sinh viên %s không tồn tại trong hệ thống!', 16, 1, @MaSV);
        RETURN;
    END

    -- Bảng tạm tính toán cho các môn đã có điểm trong học kỳ
    DECLARE @TongTinChi INT = 0;
    DECLARE @TongDiemTrongSo FLOAT = 0.0;
    DECLARE @GPA_HocKy FLOAT = 0.0;
    DECLARE @XepLoaiHocKy NVARCHAR(20) = N'Chưa xếp loại';

    SELECT 
        @TongTinChi = SUM(mh.SoTinChi),
        @TongDiemTrongSo = SUM(kq.DiemHe4 * mh.SoTinChi)
    FROM KETQUAHOCTAP kq
    JOIN LOPHOCPHAN lhp ON kq.MaLHP = lhp.MaLHP
    JOIN MONHOC mh ON lhp.MaMonHoc = mh.MaMonHoc
    WHERE kq.MaSV = @MaSV 
      AND lhp.MaHocKy = @MaHocKy
      AND kq.DiemHe4 IS NOT NULL;

    IF @TongTinChi IS NULL OR @TongTinChi = 0
    BEGIN
        SELECT 
            @MaSV AS MaSV,
            @MaHocKy AS MaHocKy,
            0 AS TongTinChiHocKy,
            0.0 AS GPA_HocKy,
            N'Chưa có điểm' AS XepLoaiHocKy;
        RETURN;
    END

    SET @GPA_HocKy = ROUND(@TongDiemTrongSo / @TongTinChi, 2);

    -- Xếp loại học lực học kỳ
    IF @GPA_HocKy >= 3.60 SET @XepLoaiHocKy = N'Xuất sắc';
    ELSE IF @GPA_HocKy >= 3.20 SET @XepLoaiHocKy = N'Giỏi';
    ELSE IF @GPA_HocKy >= 2.50 SET @XepLoaiHocKy = N'Khá';
    ELSE IF @GPA_HocKy >= 2.00 SET @XepLoaiHocKy = N'Trung bình';
    ELSE IF @GPA_HocKy >= 1.00 SET @XepLoaiHocKy = N'Yếu';
    ELSE SET @XepLoaiHocKy = N'Kém';

    -- Trả về kết quả
    SELECT 
        @MaSV AS MaSV,
        (SELECT HoTen FROM SINHVIEN WHERE MaSV = @MaSV) AS TenSinhVien,
        @MaHocKy AS MaHocKy,
        @TongTinChi AS TongTinChiHocKy,
        @GPA_HocKy AS GPA_HocKy,
        @XepLoaiHocKy AS XepLoaiHocKy;
END;
GO

-- ==========================================================
-- 2. STORED PROCEDURE TÍNH CPA TÍCH LŨY TOÀN KHÓA (SP_TinhCPA_TichLuy)
-- Xử lý bài toán Môn học lại: Mỗi môn học (MaMonHoc) chỉ lấy điểm cao nhất (MAX DiemHe4).
-- ==========================================================
IF OBJECT_ID(N'SP_TinhCPA_TichLuy', N'P') IS NOT NULL DROP PROCEDURE SP_TinhCPA_TichLuy;
GO

CREATE PROCEDURE SP_TinhCPA_TichLuy
    @MaSV VARCHAR(12)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM SINHVIEN WHERE MaSV = @MaSV)
    BEGIN
        RAISERROR(N'Lỗi: Mã sinh viên %s không tồn tại!', 16, 1, @MaSV);
        RETURN;
    END

    -- Lấy điểm cao nhất cho từng môn học đã học
    WITH BestGradesPerCourse AS (
        SELECT 
            mh.MaMonHoc,
            mh.SoTinChi,
            MAX(kq.DiemHe4) AS MaxDiemHe4
        FROM KETQUAHOCTAP kq
        JOIN LOPHOCPHAN lhp ON kq.MaLHP = lhp.MaLHP
        JOIN MONHOC mh ON lhp.MaMonHoc = mh.MaMonHoc
        WHERE kq.MaSV = @MaSV AND kq.DiemHe4 IS NOT NULL
        GROUP BY mh.MaMonHoc, mh.SoTinChi
    )
    SELECT 
        @MaSV AS MaSV,
        sv.HoTen AS TenSinhVien,
        sv.MaLopSH AS LopSinhHoat,
        ISNULL(SUM(bg.SoTinChi), 0) AS TongTinChiTichLuy,
        ISNULL(SUM(CASE WHEN bg.MaxDiemHe4 >= 1.0 THEN bg.SoTinChi ELSE 0 END), 0) AS TinChiDatPassed,
        ISNULL(ROUND(SUM(bg.MaxDiemHe4 * bg.SoTinChi) / NULLIF(SUM(bg.SoTinChi), 0), 2), 0.0) AS CPA_TichLuy,
        CASE 
            WHEN ISNULL(ROUND(SUM(bg.MaxDiemHe4 * bg.SoTinChi) / NULLIF(SUM(bg.SoTinChi), 0), 2), 0.0) >= 3.60 THEN N'Xuất sắc'
            WHEN ISNULL(ROUND(SUM(bg.MaxDiemHe4 * bg.SoTinChi) / NULLIF(SUM(bg.SoTinChi), 0), 2), 0.0) >= 3.20 THEN N'Giỏi'
            WHEN ISNULL(ROUND(SUM(bg.MaxDiemHe4 * bg.SoTinChi) / NULLIF(SUM(bg.SoTinChi), 0), 2), 0.0) >= 2.50 THEN N'Khá'
            WHEN ISNULL(ROUND(SUM(bg.MaxDiemHe4 * bg.SoTinChi) / NULLIF(SUM(bg.SoTinChi), 0), 2), 0.0) >= 2.00 THEN N'Trung bình'
            WHEN ISNULL(ROUND(SUM(bg.MaxDiemHe4 * bg.SoTinChi) / NULLIF(SUM(bg.SoTinChi), 0), 2), 0.0) >= 1.00 THEN N'Yếu'
            ELSE N'Kém'
        END AS XepLoaiTichLuy,
        CASE 
            WHEN ISNULL(ROUND(SUM(bg.MaxDiemHe4 * bg.SoTinChi) / NULLIF(SUM(bg.SoTinChi), 0), 2), 0.0) < 1.20 THEN N'Cảnh báo học vụ Cấp 2 (Nguy cơ buộc thôi học)'
            WHEN ISNULL(ROUND(SUM(bg.MaxDiemHe4 * bg.SoTinChi) / NULLIF(SUM(bg.SoTinChi), 0), 2), 0.0) < 1.60 THEN N'Cảnh báo học vụ Cấp 1'
            ELSE N'Bình thường'
        END AS TrangThaiCanhBaoHocVu
    FROM SINHVIEN sv
    LEFT JOIN BestGradesPerCourse bg ON 1=1
    WHERE sv.MaSV = @MaSV
    GROUP BY sv.MaSV, sv.HoTen, sv.MaLopSH;
END;
GO

-- ==========================================================
-- 3. MINH HỌA THỰC THI PROCEDURE
-- ==========================================================
EXEC SP_TinhGPA_HocKy @MaSV = 'SV001', @MaHocKy = 'HK1-2023';
EXEC SP_TinhCPA_TichLuy @MaSV = 'SV001';
EXEC SP_TinhCPA_TichLuy @MaSV = 'SV030';
GO

PRINT N'[OK] Issue #54 — Đã khởi tạo Stored Procedures SP_TinhGPA_HocKy và SP_TinhCPA_TichLuy.';
GO
