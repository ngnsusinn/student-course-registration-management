-- ==========================================================
-- Tên file : sql/procedures/diem_ketqua_functions.sql
-- Module   : Module 4 — Điểm số & Kết quả học tập (TV4 — Wiett)
-- Issue    : #53 Function tính điểm tổng kết & quy đổi thang điểm
-- Mô tả    : Các hàm tự định nghĩa (User-Defined Functions - UDF):
--            1. FN_TinhDiemTongKet: Tính 10% CC + 30% GK + 60% CK
--            2. FN_QuyDoiDiemChu: Tra bảng THANGDIEMCHU (xử lý điểm liệt < 3.0)
--            3. FN_QuyDoiDiemHe4: Quy đổi điểm chữ sang hệ 4 (0.0 -> 4.0)
-- ==========================================================

USE [StudentCourseRegistration];
GO

-- ==========================================================
-- 1. FUNCTION TÍNH ĐIỂM TỔNG KẾT HỆ 10 (FN_TinhDiemTongKet)
-- Trọng số: 10% Chuyên cần, 30% Giữa kỳ, 60% Cuối kỳ.
-- Điều kiện: Nếu thiếu bất kỳ điểm thành phần nào -> Trả về NULL.
-- ==========================================================
IF OBJECT_ID(N'FN_TinhDiemTongKet', N'FN') IS NOT NULL DROP FUNCTION FN_TinhDiemTongKet;
GO

CREATE FUNCTION FN_TinhDiemTongKet (
    @DiemCC FLOAT,
    @DiemGK FLOAT,
    @DiemCK FLOAT
)
RETURNS FLOAT
AS
BEGIN
    IF @DiemCC IS NULL OR @DiemGK IS NULL OR @DiemCK IS NULL
        RETURN NULL;

    -- Kiểm tra miền giá trị [0, 10]
    IF @DiemCC < 0.0 OR @DiemCC > 10.0 OR
       @DiemGK < 0.0 OR @DiemGK > 10.0 OR
       @DiemCK < 0.0 OR @DiemCK > 10.0
        RETURN NULL;

    DECLARE @DiemTK FLOAT;
    SET @DiemTK = (@DiemCC * 0.10) + (@DiemGK * 0.30) + (@DiemCK * 0.60);
    
    -- Làm tròn đến 1 chữ số thập phân
    RETURN ROUND(@DiemTK, 1);
END;
GO

-- ==========================================================
-- 2. FUNCTION QUY ĐỔI ĐIỂM TỔNG KẾT SANG ĐIỂM CHỮ (FN_QuyDoiDiemChu)
-- Quy tắc: Tra bảng THANGDIEMCHU. Nếu DiemCuoiKy < 3.0 (điểm liệt) -> Trả về 'F'.
-- ==========================================================
IF OBJECT_ID(N'FN_QuyDoiDiemChu', N'FN') IS NOT NULL DROP FUNCTION FN_QuyDoiDiemChu;
GO

CREATE FUNCTION FN_QuyDoiDiemChu (
    @DiemTongKet FLOAT,
    @DiemCuoiKy FLOAT
)
RETURNS VARCHAR(2)
AS
BEGIN
    IF @DiemTongKet IS NULL
        RETURN NULL;

    -- Quy định điểm liệt: nếu thi cuối kỳ < 3.0 -> Nhận điểm F
    IF @DiemCuoiKy IS NOT NULL AND @DiemCuoiKy < 3.0
        RETURN 'F';

    DECLARE @DiemChu VARCHAR(2);

    SELECT TOP 1 @DiemChu = DiemChu
    FROM THANGDIEMCHU
    WHERE @DiemTongKet >= TuDiemHe10 AND @DiemTongKet <= DenDiemHe10
    ORDER BY TuDiemHe10 DESC;

    -- Mặc định nếu nằm ngoài dải tra cứu (ví dụ < 4.0) -> 'F'
    IF @DiemChu IS NULL
        SET @DiemChu = 'F';

    RETURN @DiemChu;
END;
GO

-- ==========================================================
-- 3. FUNCTION QUY ĐỔI ĐIỂM CHỮ SANG HỆ 4 (FN_QuyDoiDiemHe4)
-- Tra cứu điểm chữ (A, B+, B, C+, C, D+, D, F) -> Điểm hệ 4 (4.0 -> 0.0)
-- ==========================================================
IF OBJECT_ID(N'FN_QuyDoiDiemHe4', N'FN') IS NOT NULL DROP FUNCTION FN_QuyDoiDiemHe4;
GO

CREATE FUNCTION FN_QuyDoiDiemHe4 (
    @DiemChu VARCHAR(2)
)
RETURNS FLOAT
AS
BEGIN
    IF @DiemChu IS NULL
        RETURN NULL;

    DECLARE @DiemHe4 FLOAT;

    SELECT TOP 1 @DiemHe4 = DiemHe4
    FROM THANGDIEMCHU
    WHERE DiemChu = @DiemChu;

    IF @DiemHe4 IS NULL
        SET @DiemHe4 = 0.0;

    RETURN @DiemHe4;
END;
GO

-- ==========================================================
-- 4. DEMO / MINH HỌA SỬ DỤNG CÁC FUNCTION
-- ==========================================================
SELECT 
    'Demo Test 1 (8.5, 7.5, 9.0)' AS CaseTest,
    dbo.FN_TinhDiemTongKet(8.5, 7.5, 9.0) AS DiemTongKet,
    dbo.FN_QuyDoiDiemChu(dbo.FN_TinhDiemTongKet(8.5, 7.5, 9.0), 9.0) AS DiemChu,
    dbo.FN_QuyDoiDiemHe4(dbo.FN_QuyDoiDiemChu(dbo.FN_TinhDiemTongKet(8.5, 7.5, 9.0), 9.0)) AS DiemHe4;

SELECT 
    'Demo Test 2 (Điểm liệt cuối kỳ 2.5)' AS CaseTest,
    dbo.FN_TinhDiemTongKet(9.0, 8.0, 2.5) AS DiemTongKet,
    dbo.FN_QuyDoiDiemChu(dbo.FN_TinhDiemTongKet(9.0, 8.0, 2.5), 2.5) AS DiemChu,
    dbo.FN_QuyDoiDiemHe4(dbo.FN_QuyDoiDiemChu(dbo.FN_TinhDiemTongKet(9.0, 8.0, 2.5), 2.5)) AS DiemHe4;
GO

PRINT N'[OK] Issue #53 — Đã khởi tạo thành công 3 User-Defined Functions cho Module 4.';
GO
