-- =================================================================
-- ISSUE #69: STORED PROCEDURE CẬP NHẬT HỒ SƠ CHỐNG XUNG ĐỘT (CONCURRENCY)
-- Sử dụng Tham số truyền vào + UPDLOCK để tránh Lost Update & Deadlock
-- =================================================================

CREATE OR ALTER PROCEDURE sp_CapNhatHoSoSinhVien_Concurrency
    @MaSV VARCHAR(12),
    @EmailMoi VARCHAR(100) = NULL,
    @SoDienThoaiMoi VARCHAR(15) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Bắt đầu Transaction
    BEGIN TRANSACTION;

    BEGIN TRY
        -- 1. Kiểm tra sự tồn tại và Khóa dòng dữ liệu (UPDLOCK) 
        -- Ngăn các giao dịch khác đọc/sửa sinh viên này cho đến khi kết thúc TRAN
        IF NOT EXISTS (
            SELECT 1 
            FROM SINH_VIEN WITH (UPDLOCK, ROWLOCK) 
            WHERE MaSV = @MaSV
        )
        BEGIN
            RAISERROR(N'Lỗi: Không tìm thấy sinh viên có mã %s!', 16, 1, @MaSV);
        END

        -- 2. Cập nhật Email (nếu người dùng có truyền vào)
        IF @EmailMoi IS NOT NULL
        BEGIN
            UPDATE SINH_VIEN
            SET Email = @EmailMoi
            WHERE MaSV = @MaSV;
        END

        -- 3. Cập nhật Số điện thoại (nếu người dùng có truyền vào)
        IF @SoDienThoaiMoi IS NOT NULL
        BEGIN
            UPDATE SINH_VIEN
            SET SoDienThoai = @SoDienThoaiMoi
            WHERE MaSV = @MaSV;
        END

        -- Cam kết giao dịch thành công
        COMMIT TRANSACTION;
        PRINT N'Cập nhật hồ sơ sinh viên ' + @MaSV + N' thành công!';
    END TRY
    BEGIN CATCH
        -- Hoàn tác dữ liệu nếu phát sinh lỗi
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO