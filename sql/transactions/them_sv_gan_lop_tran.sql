-- =================================================================
-- ISSUE #68: STORED PROCEDURE CHỨA TRANSACTION (KHÔNG FIX CỨNG DỮ LIỆU)
-- =================================================================

CREATE OR ALTER PROCEDURE sp_ThemSinhVienVaGanLop
    @MaSV VARCHAR(12),
    @HoTen NVARCHAR(50),
    @MaLop VARCHAR(10),
    @NgaySinh DATE = NULL,
    @GioiTinh BIT = 1,
    @Email VARCHAR(100) = NULL,
    @SoDienThoai VARCHAR(15) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Bắt đầu Giao dịch (Transaction)
    BEGIN TRANSACTION;

    BEGIN TRY
        -- 1. Kiểm tra sự tồn tại của lớp sinh hoạt
        IF NOT EXISTS (SELECT 1 FROM LOP WHERE MaLop = @MaLop)
        BEGIN
            RAISERROR(N'Lỗi Atomicity: Lớp sinh hoạt %s không tồn tại!', 16, 1, @MaLop);
        END

        -- 2. Kiểm tra trùng mã SV
        IF EXISTS (SELECT 1 FROM SINH_VIEN WHERE MaSV = @MaSV)
        BEGIN
            RAISERROR(N'Lỗi Atomicity: Mã sinh viên %s đã tồn tại!', 16, 1, @MaSV);
        END

        -- 3. Thêm mới sinh viên và gán lớp
        INSERT INTO SINH_VIEN (MaSV, HoTen, NgaySinh, GioiTinh, Email, SoDienThoai, MaLop, TrangThaiHoc)
        VALUES (@MaSV, @HoTen, @NgaySinh, @GioiTinh, @Email, @SoDienThoai, @MaLop, 1);

        -- Xác nhận giao dịch
        COMMIT TRANSACTION;
        PRINT N'Thêm sinh viên và gán lớp sinh hoạt thành công!';
    END TRY
    BEGIN CATCH
        -- Hoàn tác nếu phát sinh lỗi
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO