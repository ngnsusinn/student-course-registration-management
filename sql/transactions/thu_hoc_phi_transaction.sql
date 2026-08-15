-- ==========================================================
-- Tên file : sql/transactions/thu_hoc_phi_transaction.sql
-- Module   : Giao dịch thu học phí
-- Issue    : #77
--
-- Mô tả:
--   - Giao dịch thu học phí sinh viên.
--   - Cập nhật số tiền đã nộp.
--   - Cập nhật trạng thái học phí.
--   - Đảm bảo tính nguyên tử của giao dịch.
--   - Xử lý trường hợp 2 tiến trình cùng cập nhật một
--     phiếu học phí.
--
-- Bảng sử dụng:
--   HOCPHI
--
-- Không tạo bảng mới vì HOCPHI đã có trường DaNop để
-- ghi nhận số tiền sinh viên đã thanh toán.
--
-- ==========================================================


-- ==========================================================
-- 1. THỦ TỤC THU HỌC PHÍ
-- ==========================================================

IF OBJECT_ID(N'dbo.SP_ThuHocPhi', N'P') IS NOT NULL
    DROP PROCEDURE dbo.SP_ThuHocPhi;
GO


CREATE PROCEDURE dbo.SP_ThuHocPhi
(
    @MaHocPhi  VARCHAR(15),
    @SoTienNop DECIMAL(15,0)
)
AS
BEGIN

    SET NOCOUNT ON;

    -- ------------------------------------------------------
    -- Xử lý lỗi tự động rollback khi transaction gặp lỗi
    -- ------------------------------------------------------

    SET XACT_ABORT ON;


    BEGIN TRY

        -- ==================================================
        -- 2. KIỂM TRA SỐ TIỀN NỘP
        -- ==================================================

        IF @SoTienNop <= 0
        BEGIN
            RAISERROR
            (
                N'Số tiền nộp phải lớn hơn 0.',
                16,
                1
            );

            RETURN;
        END;


        -- ==================================================
        -- 3. BẮT ĐẦU TRANSACTION
        -- ==================================================

        BEGIN TRANSACTION;


        -- ==================================================
        -- 4. KHÓA BẢN GHI HỌC PHÍ
        --
        -- UPDLOCK:
        --   Các transaction khác muốn cập nhật cùng dòng
        --   phải chờ transaction hiện tại hoàn thành.
        --
        -- HOLDLOCK:
        --   Giữ khóa đến khi transaction kết thúc.
        --
        -- Nhờ đó tránh tình trạng:
        --
        -- Transaction A đọc DaNop = 0
        -- Transaction B đọc DaNop = 0
        -- A cập nhật
        -- B cập nhật đè dữ liệu của A
        --
        -- Đây là cơ chế chống Lost Update.
        -- ==================================================

        DECLARE
            @DaNopHienTai DECIMAL(15,0),
            @TongTien     DECIMAL(15,0),
            @TrangThai    NVARCHAR(30);


        SELECT
            @DaNopHienTai = DaNop,
            @TongTien = TongTien,
            @TrangThai = TrangThai

        FROM dbo.HOCPHI WITH (UPDLOCK, HOLDLOCK)

        WHERE MaHocPhi = @MaHocPhi;


        -- ==================================================
        -- 5. KIỂM TRA MÃ HỌC PHÍ
        -- ==================================================

        IF @DaNopHienTai IS NULL
        BEGIN

            RAISERROR
            (
                N'Không tìm thấy mã học phí cần thanh toán.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;

        END;


        -- ==================================================
        -- 6. KIỂM TRA PHIẾU ĐÃ THANH TOÁN ĐỦ
        -- ==================================================

        IF @DaNopHienTai >= @TongTien
        BEGIN

            RAISERROR
            (
                N'Học phí đã được thanh toán đầy đủ.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;

        END;


        -- ==================================================
        -- 7. KIỂM TRA KHÔNG CHO PHÉP NỘP VƯỢT
        -- ==================================================

        IF @DaNopHienTai + @SoTienNop > @TongTien
        BEGIN

            RAISERROR
            (
                N'Số tiền nộp vượt quá số học phí còn phải thanh toán.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;

        END;


        -- ==================================================
        -- 8. TÍNH SỐ TIỀN SAU KHI THANH TOÁN
        -- ==================================================

        DECLARE @DaNopMoi DECIMAL(15,0);

        SET @DaNopMoi =
            @DaNopHienTai + @SoTienNop;


        -- ==================================================
        -- 9. XÁC ĐỊNH TRẠNG THÁI MỚI
        -- ==================================================

        DECLARE @TrangThaiMoi NVARCHAR(30);


        IF @DaNopMoi = @TongTien
        BEGIN

            SET @TrangThaiMoi = N'DA_THANH_TOAN';

        END
        ELSE
        BEGIN

            SET @TrangThaiMoi = N'DANG_XU_LY';

        END;


        -- ==================================================
        -- 10. CẬP NHẬT HỌC PHÍ
        -- ==================================================

        UPDATE dbo.HOCPHI

        SET
            DaNop = @DaNopMoi,
            TrangThai = @TrangThaiMoi

        WHERE MaHocPhi = @MaHocPhi;


        -- ==================================================
        -- 11. KIỂM TRA UPDATE
        -- ==================================================

        IF @@ROWCOUNT <> 1
        BEGIN

            RAISERROR
            (
                N'Không thể cập nhật thông tin học phí.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;

        END;


        -- ==================================================
        -- 12. COMMIT
        -- ==================================================

        COMMIT TRANSACTION;


        -- ==================================================
        -- 13. TRẢ KẾT QUẢ
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


        PRINT N'[OK] Thu học phí thành công.';


    END TRY


    BEGIN CATCH

        -- --------------------------------------------------
        -- Nếu transaction vẫn còn mở thì rollback
        -- --------------------------------------------------

        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;


        -- --------------------------------------------------
        -- Trả lại lỗi cho ứng dụng
        -- --------------------------------------------------

        THROW;

    END CATCH

END;
GO


PRINT N'[OK] Đã tạo SP_ThuHocPhi.';
GO