-- ==========================================================
-- Tên file : sql/transactions/hocphan_giangvien_lophocphan_tran.sql
-- Module   : Học phần, Giảng viên & Mở lớp học phần (TV2)
-- Issue    : Transaction mở lớp học phần
-- Mô tả    : Đóng gói việc mở LHP + tạo lịch học trong Transaction
--            để đảm bảo dữ liệu được thêm đồng bộ:
--              1. Kiểm tra LHP không trùng
--              2. Kiểm tra GV không trùng lịch
--              3. Kiểm tra phòng không trùng lịch
--              4. Thêm LHP
--              5. Thêm lịch học
--              6. Nếu lỗi → ROLLBACK toàn bộ
--              7. Nếu thành công → COMMIT
-- ==========================================================

USE [DangKyHocPhan];
GO

DECLARE @MaLHP VARCHAR(10) = 'LH081';
DECLARE @TenLHP NVARCHAR(100) = N'Lập trình SQL - Nhóm 01';
DECLARE @MaMonHoc VARCHAR(10) = 'MH001';
DECLARE @MaHocKy VARCHAR(10) = 'HK02';
DECLARE @MaGV VARCHAR(10) = 'GV001';
DECLARE @SiSoToiDa INT = 50;

DECLARE @MaPhong VARCHAR(10) = 'P001';
DECLARE @Thu TINYINT = 2;
DECLARE @TietBatDau TINYINT = 1;
DECLARE @SoTiet TINYINT = 3;

BEGIN TRY

    BEGIN TRANSACTION;


    /*======================================================
        1. Kiểm tra LHP đã tồn tại
    ======================================================*/

    IF EXISTS
    (
        SELECT 1
        FROM LopHocPhan
        WHERE MaLHP = @MaLHP
    )
    BEGIN
        THROW 50001, N'Mã lớp học phần đã tồn tại.', 1;
    END;


    /*======================================================
        2. Kiểm tra GIẢNG VIÊN bị trùng lịch
    ======================================================*/

    IF EXISTS
    (
        SELECT 1
        FROM LichHoc LH
        JOIN LopHocPhan LHP
            ON LH.MaLHP = LHP.MaLHP
        WHERE LHP.MaGV = @MaGV
          AND LHP.MaHocKy = @MaHocKy
          AND LH.Thu = @Thu
          AND @TietBatDau < LH.TietBatDau + LH.SoTiet
          AND LH.TietBatDau < @TietBatDau + @SoTiet
    )
    BEGIN
        THROW 50002, N'Giảng viên đã có lớp bị trùng lịch.', 1;
    END;


    /*======================================================
        3. Kiểm tra PHÒNG bị trùng lịch
    ======================================================*/

    IF EXISTS
    (
        SELECT 1
        FROM LichHoc LH
        JOIN LopHocPhan LHP
            ON LH.MaLHP = LHP.MaLHP
        WHERE LH.MaPhong = @MaPhong
          AND LHP.MaHocKy = @MaHocKy
          AND LH.Thu = @Thu
          AND @TietBatDau < LH.TietBatDau + LH.SoTiet
          AND LH.TietBatDau < @TietBatDau + @SoTiet
    )
    BEGIN
        THROW 50003, N'Phòng học đã có lớp bị trùng lịch.', 1;
    END;


    /*======================================================
        4. Thêm LỚP HỌC PHẦN
    ======================================================*/

    INSERT INTO LopHocPhan
    (
        MaLHP,
        TenLHP,
        MaMonHoc,
        MaHocKy,
        MaGV,
        SiSoToiDa,
        SiSoHienTai,
        TrangThaiLop
    )
    VALUES
    (
        @MaLHP,
        @TenLHP,
        @MaMonHoc,
        @MaHocKy,
        @MaGV,
        @SiSoToiDa,
        0,
        N'Mở'
    );


    /*======================================================
        5. Thêm LỊCH HỌC
    ======================================================*/

    INSERT INTO LichHoc
    (
        MaLichHoc,
        MaLHP,
        MaPhong,
        Thu,
        TietBatDau,
        SoTiet
    )
    VALUES
    (
        'LH' + RIGHT(
            '000' + CAST(
                ISNULL(
                    (
                        SELECT MAX(
                            CAST(SUBSTRING(MaLichHoc, 3, 3) AS INT)
                        )
                        FROM LichHoc
                        WHERE MaLichHoc LIKE 'LH%'
                    ),
                    0
                ) + 1
                AS VARCHAR(3)
            ),
            3
        ),
        @MaLHP,
        @MaPhong,
        @Thu,
        @TietBatDau,
        @SoTiet
    );


    /*======================================================
        6. MỌI THỨ HỢP LỆ → COMMIT
    ======================================================*/

    COMMIT TRANSACTION;

    PRINT N'Mở LHP và xếp lịch thành công.';

END TRY

BEGIN CATCH

    /*======================================================
        7. CÓ LỖI → ROLLBACK
    ======================================================*/

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT N'Mở LHP thất bại. Đã ROLLBACK Transaction.';

    THROW;

END CATCH;

BEGIN TRANSACTION;

-- Khóa các lịch đang có của phòng P001
SELECT *
FROM LichHoc WITH (UPDLOCK, HOLDLOCK)
WHERE MaPhong = 'P001'
  AND Thu = 2
  AND TietBatDau < 4
  AND TietBatDau + SoTiet > 1;

-- Giả lập cán bộ A đang xếp lịch
WAITFOR DELAY '00:00:10';

-- Thêm lịch cho lớp A
INSERT INTO LichHoc
(
    MaLichHoc,
    MaLHP,
    MaPhong,
    Thu,
    TietBatDau,
    SoTiet
)
VALUES
(
    'LH901',
    'LH081',
    'P001',
    2,
    1,
    3
);

COMMIT TRANSACTION;

