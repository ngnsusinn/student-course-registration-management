-- ==========================================================
-- Tên file : sql/procedures/SP_HuyDangKy.sql
-- Module   : Đăng ký học phần (TV3 — Leader)
-- Issue    : #51 SP HuyDangKy + Function kiểm tra tiên quyết
-- Mô tả    : Stored Procedure HỦY ĐĂNG KÝ học phần.
--              - Chỉ hủy được khi ĐỢT VẪN MỞ (còn hạn hủy).
--              - Chỉ hủy bản ghi đang ở trạng thái DA_DANG_KY
--                (không hủy bản ghi đã hủy / chờ xác nhận).
--              - Dùng UPDATE trạng thái -> DA_HUY (giữ lịch sử)
--                kèm cập nhật SiSoHienTai -1.
--              - Phần Transaction được đóng gói để chống lỗi giữa
--                chừng (Issue #72 cũng dùng chung kiến trúc này).
-- Trả về qua @KetQua:
--   0   = Hủy thành công
--   200 = Đợt đăng ký đã đóng (không còn hạn hủy)
--   201 = Không tìm thấy bản ghi đăng ký
--   202 = Bản ghi không ở trạng thái DA_DANG_KY (đã hủy rồi)
--   500 = Lỗi hệ thống (rollback)
-- ==========================================================
IF OBJECT_ID(N'dbo.SP_HuyDangKy', N'P') IS NOT NULL DROP PROCEDURE dbo.SP_HuyDangKy;
GO
CREATE PROCEDURE dbo.SP_HuyDangKy (
    @MaSV   VARCHAR(12),
    @MaLHP  VARCHAR(15),
    @KetQua INT = 500 OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TrangThaiHienTai NVARCHAR(20),
            @ErrMsg           NVARCHAR(500);

    SET @KetQua = 500;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- ====================================================
        -- BƯỚC 1: KIỂM TRA ĐỢT ĐĂNG KÝ CÒN MỞ (còn hạn hủy)
        -- ====================================================
        IF dbo.FN_KiemTraDotDangKy() = 0
        BEGIN
            SET @KetQua = 200;
            SET @ErrMsg = N'Rất tiếc! Hiện tại ngoài thời hạn hủy đăng ký học phần.';
            RAISERROR(@ErrMsg, 16, 1);
        END

        -- ====================================================
        -- BƯỚC 2: LẤY TRẠNG THÁI HIỆN TẠI (khóa đọc cập nhật)
        -- ====================================================
        SELECT @TrangThaiHienTai = dk.TrangThaiDangKy
        FROM DANGKYHOCPHAN dk WITH (UPDLOCK, HOLDLOCK)
        JOIN LOPHOCPHAN lhp ON lhp.MaLHP = dk.MaLHP
        WHERE dk.MaSV = @MaSV AND dk.MaLHP = @MaLHP;

        IF @TrangThaiHienTai IS NULL
        BEGIN
            SET @KetQua = 201;
            SET @ErrMsg = N'Không tìm thấy bản ghi đăng ký học phần '
                        + @MaSV + N' / ' + @MaLHP + N'.';
            RAISERROR(@ErrMsg, 16, 1);
        END

        IF @TrangThaiHienTai <> N'DA_DANG_KY'
        BEGIN
            SET @KetQua = 202;
            SET @ErrMsg = N'Bản ghi đăng ký ' + @MaLHP
                        + N' của bạn không ở trạng thái ĐÃ ĐĂNG KÝ (không thể hủy).';
            RAISERROR(@ErrMsg, 16, 1);
        END

        -- ====================================================
        -- BƯỚC 3: HỦY ĐĂNG KÝ
        --   - Cập nhật trạng thái -> DA_HUY (giữ lịch sử đăng ký)
        --   - Giảm SiSoHienTai 1 (chống tràn sĩ số)
        -- ====================================================
        UPDATE DANGKYHOCPHAN
        SET TrangThaiDangKy = N'DA_HUY',
            GhiChu = ISNULL(GhiChu, N'') + N' | Hủy ngày ' + CONVERT(VARCHAR(20), GETDATE(), 120)
        WHERE MaSV = @MaSV AND MaLHP = @MaLHP;
        -- TRIGGER AFTER UPDATE (Issue #61) tự -1 SiSoHienTai.

        SET @KetQua = 0;

        COMMIT TRANSACTION;
        PRINT N'✅ Hủy đăng ký THÀNH CÔNG: ' + @MaSV + N' bỏ lớp ' + @MaLHP;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        IF @ErrMsg IS NULL
            SET @ErrMsg = ERROR_MESSAGE();

        PRINT N'❌ Hủy đăng ký thất bại (mã ' + CAST(@KetQua AS VARCHAR(10)) + N'): ' + @ErrMsg;
    END CATCH
END;
GO

PRINT N'[OK] Issue #51 — Đã tạo SP_HuyDangKy (kiểm tra hạn hủy + Transaction).';
GO
