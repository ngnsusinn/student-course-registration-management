-- 1. STORED PROCEDURE THÊM SINH VIÊN (KIỂM TRA LỚP TỒN TẠI)
-- -----------------------------------------------------------------
IF OBJECT_ID('sp_ThemSinhVien', 'P') IS NOT NULL
    DROP PROCEDURE sp_ThemSinhVien;
GO

CREATE PROCEDURE sp_ThemSinhVien
    @MaSV VARCHAR(12),
    @HoTen NVARCHAR(50),
    @NgaySinh DATE,
    @GioiTinh BIT,
    @Email VARCHAR(100),
    @SoDienThoai VARCHAR(15),
    @MaLop VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra mã sinh viên trùng lặp
    IF EXISTS (SELECT 1 FROM SINH_VIEN WHERE MaSV = @MaSV)
    BEGIN
        RAISERROR(N'Lỗi: Mã sinh viên %s đã tồn tại trong hệ thống!', 16, 1, @MaSV);
        RETURN;
    END

    -- Kiểm tra lớp học có tồn tại trong hệ thống không
    IF NOT EXISTS (SELECT 1 FROM LOP WHERE MaLop = @MaLop)
    BEGIN
        RAISERROR(N'Lỗi: Mã lớp %s không tồn tại! Vui lòng kiểm tra lại.', 16, 1, @MaLop);
        RETURN;
    END

    -- Thêm mới sinh viên sử dụng Transaction
    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO SINH_VIEN (MaSV, HoTen, NgaySinh, GioiTinh, Email, SoDienThoai, MaLop, TrangThaiHoc)
        VALUES (@MaSV, @HoTen, @NgaySinh, @GioiTinh, @Email, @SoDienThoai, @MaLop, 1);

        COMMIT TRANSACTION;
        PRINT N'Thêm sinh viên ' + @MaSV + N' thành công!';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- -----------------------------------------------------------------
-- 2. CHUYỂN LỚP / NGÀNH CHO SINH VIÊN
-- -----------------------------------------------------------------
IF OBJECT_ID('sp_ChuyenLopNganh', 'P') IS NOT NULL
    DROP PROCEDURE sp_ChuyenLopNganh;
GO

CREATE PROCEDURE sp_ChuyenLopNganh
    @MaSV VARCHAR(12),
    @MaLopMoi VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra sinh viên có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM SINH_VIEN WHERE MaSV = @MaSV)
    BEGIN
        RAISERROR(N'Lỗi: Sinh viên có mã %s không tồn tại!', 16, 1, @MaSV);
        RETURN;
    END

    -- Kiểm tra lớp mới có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM LOP WHERE MaLop = @MaLopMoi)
    BEGIN
        RAISERROR(N'Lỗi: Lớp mới có mã %s không tồn tại!', 16, 1, @MaLopMoi);
        RETURN;
    END

    -- Kiểm tra nếu sinh viên đã thuộc lớp này từ trước
    IF EXISTS (SELECT 1 FROM SINH_VIEN WHERE MaSV = @MaSV AND MaLop = @MaLopMoi)
    BEGIN
        PRINT N'Sinh viên hiện đã ở trong lớp này, không cần chuyển.';
        RETURN;
    END

    -- Cập nhật chuyển lớp
    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE SINH_VIEN
        SET MaLop = @MaLopMoi
        WHERE MaSV = @MaSV;

        COMMIT TRANSACTION;
        PRINT N'Chuyển lớp thành công cho sinh viên ' + @MaSV + N' sang lớp ' + @MaLopMoi;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH
END;
GO

-- -----------------------------------------------------------------
-- 3.ĐẾM SĨ SỐ LỚP (SCALAR FUNCTION)
-- -----------------------------------------------------------------
IF OBJECT_ID('fn_DemSiSoLop', 'FN') IS NOT NULL
    DROP FUNCTION fn_DemSiSoLop;
GO

CREATE FUNCTION fn_DemSiSoLop (@MaLop VARCHAR(10))
RETURNS INT
AS
BEGIN
    DECLARE @SiSo INT;

    SELECT @SiSo = COUNT(*)
    FROM SINH_VIEN
    WHERE MaLop = @MaLop;

    RETURN ISNULL(@SiSo, 0);
END;
GO