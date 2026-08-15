-- ==========================================================
-- Tên file : sql/transactions/phan_tich_concurrency_hoc_phi.sql
-- Module   : Transaction & Concurrency - Học phí
-- Issue    : #78
--
-- Mô tả:
--   Phân tích và xử lý trường hợp 2 tiến trình đồng thời
--   cập nhật trạng thái thanh toán học phí.
--
-- Mục tiêu:
--   1. Phát hiện xung đột khi 2 transaction cùng cập nhật
--      một bản ghi HOCPHI.
--   2. Minh họa hiện tượng Lost Update.
--   3. Sử dụng UPDLOCK + HOLDLOCK để tuần tự hóa việc
--      cập nhật cùng một phiếu học phí.
--   4. Đảm bảo trạng thái thanh toán không bị cập nhật
--      sai do dữ liệu cũ.
--
-- Bảng sử dụng:
--   HOCPHI
--
-- Trạng thái hợp lệ của HOCPHI:
--   CHUA_THANH_TOAN
--   DANG_XU_LY
--   DA_THANH_TOAN
--   QUA_HAN
--
-- ==========================================================


-- ==========================================================
-- PHẦN A. TRANSACTION AN TOÀN KHI ĐÓNG HỌC PHÍ
-- ==========================================================

IF OBJECT_ID(N'dbo.SP_DongHocPhi_AnToan', N'P') IS NOT NULL
    DROP PROCEDURE dbo.SP_DongHocPhi_AnToan;
GO


CREATE PROCEDURE dbo.SP_DongHocPhi_AnToan
(
    @MaHocPhi VARCHAR(15)
)
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;


    BEGIN TRY

        -- ==================================================
        -- 1. BẮT ĐẦU TRANSACTION
        -- ==================================================

        BEGIN TRANSACTION;


        -- ==================================================
        -- 2. ĐỌC BẢN GHI VỚI KHÓA CẬP NHẬT
        --
        -- UPDLOCK:
        --   Đặt Update Lock trên bản ghi được đọc.
        --
        -- HOLDLOCK:
        --   Giữ khóa đến khi transaction kết thúc.
        --
        -- Nếu một transaction khác muốn cập nhật cùng
        -- bản ghi, transaction đó phải chờ.
        -- ==================================================

        DECLARE
            @TongTien DECIMAL(15,0),
            @DaNop DECIMAL(15,0),
            @TrangThai NVARCHAR(30);


        SELECT
            @TongTien = TongTien,
            @DaNop = DaNop,
            @TrangThai = TrangThai

        FROM dbo.HOCPHI WITH (UPDLOCK, HOLDLOCK)

        WHERE MaHocPhi = @MaHocPhi;


        -- ==================================================
        -- 3. KIỂM TRA PHIẾU HỌC PHÍ
        -- ==================================================

        IF @TongTien IS NULL
        BEGIN

            RAISERROR
            (
                N'Không tìm thấy phiếu học phí.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;

        END;


        -- ==================================================
        -- 4. KIỂM TRA ĐÃ THANH TOÁN ĐỦ CHƯA
        -- ==================================================

        IF @DaNop <> @TongTien
        BEGIN

            RAISERROR
            (
                N'Không thể đóng học phí vì sinh viên chưa thanh toán đủ.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;

        END;


        -- ==================================================
        -- 5. KIỂM TRA TRẠNG THÁI HIỆN TẠI
        -- ==================================================

        IF @TrangThai = N'DA_THANH_TOAN'
        BEGIN

            RAISERROR
            (
                N'Học phí đã được đóng trước đó.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;

        END;


        -- ==================================================
        -- 6. CẬP NHẬT TRẠNG THÁI
        -- ==================================================

        UPDATE dbo.HOCPHI

        SET TrangThai = N'DA_THANH_TOAN'

        WHERE MaHocPhi = @MaHocPhi;


        -- ==================================================
        -- 7. KIỂM TRA UPDATE
        -- ==================================================

        IF @@ROWCOUNT <> 1
        BEGIN

            RAISERROR
            (
                N'Cập nhật trạng thái học phí thất bại.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;

        END;


        -- ==================================================
        -- 8. COMMIT
        -- ==================================================

        COMMIT TRANSACTION;


        -- ==================================================
        -- 9. TRẢ KẾT QUẢ
        -- ==================================================

        SELECT
            MaHocPhi,
            MaSV,
            MaHocKy,
            TongTien,
            DaNop,
            TongTien - DaNop AS SoTienConNo,
            TrangThai

        FROM dbo.HOCPHI

        WHERE MaHocPhi = @MaHocPhi;


        PRINT N'[OK] Đóng học phí thành công.';


    END TRY


    BEGIN CATCH

        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;

    END CATCH

END;
GO


PRINT N'[OK] Đã tạo SP_DongHocPhi_AnToan.';
GO