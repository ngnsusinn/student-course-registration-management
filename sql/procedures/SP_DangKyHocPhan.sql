-- ==========================================================
-- Tên file : sql/procedures/SP_DangKyHocPhan.sql
-- Module   : Đăng ký học phần (TV3 — Leader)
-- Issue    : #50 SP DangKyHocPhan
-- Mô tả    : Stored Procedure gộp ĐỦ 5 BƯỚC KIỂM TRA trước khi
--            ghi nhận 1 đăng ký học phần:
--              1. Còn hạn đăng ký (đợt mở)
--              2. Chưa đăng ký trùng LHP
--              3. Đã đạt môn tiên quyết
--              4. Không trùng lịch học
--              5. Chưa vượt giới hạn tín chỉ + Lớp còn chỗ
--            Thiết kế SẴN CHO TRANSACTION (Issue #72): phần thân
--            giao dịch được tách thành SP nội bộ hoặc dùng
--            TRY/CATCH với BEGIN TRAN bên trong.
-- ==========================================================

-- ==========================================================
-- SP_DangKyHocPhan (phiên bản ĐÓNG GÓI TRANSACTION hoàn chỉnh)
-- Tham số:
--   @MaSV           Mã sinh viên
--   @MaLHP          Mã lớp học phần
--   @MaxTinChi      Giới hạn tín chỉ tối đa của SV (mặc định 24)
--   @GhiChu         Ghi chú đăng ký (tùy chọn)
-- Trả về qua @KetQua:
--   0   = Thành công
--   100 = Hết hạn đăng ký (đợt đã đóng)
--   101 = Đã đăng ký lớp này rồi
--   102 = Thiếu môn tiên quyết
--   103 = Trùng lịch học
--   104 = Vượt quá giới hạn tín chỉ
--   105 = Lớp đã đầy sĩ số (Lost Update được chặn)
--   106 = LHP không tồn tại / không ở trạng thái mở đăng ký
--   500 = Lỗi hệ thống (rollback)
-- ==========================================================
IF OBJECT_ID(N'dbo.SP_DangKyHocPhan', N'P') IS NOT NULL DROP PROCEDURE dbo.SP_DangKyHocPhan;
GO
CREATE PROCEDURE dbo.SP_DangKyHocPhan (
    @MaSV      VARCHAR(12),
    @MaLHP     VARCHAR(15),
    @MaxTinChi INT           = 24,
    @GhiChu    NVARCHAR(255) = NULL,
    @KetQua    INT           = 0 OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MaHocKy      VARCHAR(10),
            @MaMonHoc     VARCHAR(10),
            @SoTinChiMH   INT,
            @TongTinChiDa INT,
            @TrangThaiLop NVARCHAR(30),
            @ErrMsg       NVARCHAR(500);

    -- Mặc định là lỗi, chỉ set 0 khi thành công
    SET @KetQua = 500;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- ====================================================
        -- BƯỚC 0: XÁC THỰC LHP TỒN TẠI & ĐANG MỞ ĐĂNG KÝ
        -- ====================================================
        SELECT
            @MaHocKy      = lhp.MaHocKy,
            @MaMonHoc     = lhp.MaMonHoc,
            @SoTinChiMH   = mh.SoTinChi,
            @TrangThaiLop = lhp.TrangThaiLop
        FROM LOPHOCPHAN lhp
        JOIN MONHOC mh ON mh.MaMonHoc = lhp.MaMonHoc
        WHERE lhp.MaLHP = @MaLHP;

        IF @MaHocKy IS NULL
        BEGIN
            SET @KetQua = 106;
            SET @ErrMsg = N'Không tồn tại lớp học phần: ' + ISNULL(@MaLHP, N'');
            RAISERROR(@ErrMsg, 16, 1);
        END

        IF @TrangThaiLop <> N'MO_DANG_KY'
        BEGIN
            SET @KetQua = 106;
            SET @ErrMsg = N'Lớp học phần ' + @MaLHP + N' không ở trạng thái mở đăng ký.';
            RAISERROR(@ErrMsg, 16, 1);
        END

        -- ====================================================
        -- BƯỚC 1: KIỂM TRA HẠN ĐĂNG KÝ
        --   Điều kiện: GETDATE() trong [TuNgay, DenNgay]
        --   AND TrangThaiDot = 'MO'
        -- ====================================================
        IF dbo.FN_KiemTraDotDangKy() = 0
        BEGIN
            SET @KetQua = 100;
            SET @ErrMsg = N'Rất tiếc! Hiện tại ngoài thời hạn đăng ký học phần của học kỳ này.';
            RAISERROR(@ErrMsg, 16, 1);
        END

        -- Kiểm tra LHP thuộc học kỳ đang mở (đồng nhất kỳ đăng ký)
        IF NOT EXISTS (
            SELECT 1 FROM HOCKY
            WHERE MaHocKy = @MaHocKy
              AND TrangThaiDot = N'MO'
              AND GETDATE() BETWEEN TuNgay AND DenNgay
        )
        BEGIN
            SET @KetQua = 100;
            SET @ErrMsg = N'Lớp học phần ' + @MaLHP + N' thuộc học kỳ không đang mở đăng ký.';
            RAISERROR(@ErrMsg, 16, 1);
        END

        -- ====================================================
        -- BƯỚC 2: KIỂM TRA ĐĂNG KÝ TRÙNG LHP
        --   PK ghép (MaSV, MaLHP) đã chặn vật lý, nhưng cần kiểm
        --   tra rõ để trả thông báo thân thiện.
        -- ====================================================
        IF EXISTS (
            SELECT 1 FROM DANGKYHOCPHAN
            WHERE MaSV = @MaSV AND MaLHP = @MaLHP
        )
        BEGIN
            SET @KetQua = 101;
            SET @ErrMsg = N'Bạn đã đăng ký lớp học phần ' + @MaLHP + N' rồi.';
            RAISERROR(@ErrMsg, 16, 1);
        END

        -- ====================================================
        -- BƯỚC 3: KIỂM TRA MÔN TIÊN QUYẾT
        --   Gọi FN_KiemTraTienQuyet(MaSV, MaMonHoc)
        -- ====================================================
        IF dbo.FN_KiemTraTienQuyet(@MaSV, @MaMonHoc) = 0
        BEGIN
            SET @KetQua = 102;
            SET @ErrMsg = N'Không thể đăng ký! Bạn chưa hoàn thành môn tiên quyết của môn học này.';
            RAISERROR(@ErrMsg, 16, 1);
        END

        -- ====================================================
        -- BƯỚC 4: KIỂM TRA TRÙNG LỊCH HỌC
        --   Gọi FN_KiemTraTrungLichHoc(MaSV, MaLHP)
        -- ====================================================
        IF dbo.FN_KiemTraTrungLichHoc(@MaSV, @MaLHP) = 1
        BEGIN
            SET @KetQua = 103;
            SET @ErrMsg = N'Đăng ký thất bại! Lớp học phần ' + @MaLHP +
                          N' bị trùng lịch học với lớp bạn đã đăng ký.';
            RAISERROR(@ErrMsg, 16, 1);
        END

        -- ====================================================
        -- BƯỚC 5: KIỂM TRA GIỚI HẠN TÍN CHỈ
        --   TongTinChiMoi = TongDaDangKy + SoTinChi(mon moi)
        -- ====================================================
        SET @TongTinChiDa = dbo.FN_TinhTongTinChi(@MaSV, @MaHocKy);
        IF (@TongTinChiDa + @SoTinChiMH) > @MaxTinChi
        BEGIN
            SET @KetQua = 104;
            SET @ErrMsg = N'Không thể đăng ký! Tổng số tín chỉ sau khi thêm (' +
                          CAST(@TongTinChiDa + @SoTinChiMH AS VARCHAR(3)) +
                          N' TC) vượt quá giới hạn tối đa cho phép (' +
                          CAST(@MaxTinChi AS VARCHAR(3)) + N' TC).';
            RAISERROR(@ErrMsg, 16, 1);
        END

        -- ====================================================
        -- BƯỚC 6: KIỂM TRA SĨ SỐ & GHI NHẬN (ATOMIC, CHỐNG LOST UPDATE)
        --   Cập nhật sĩ số TRƯỚC bằng UPDATE có điều kiện nguyên tử:
        --     UPDATE ... SET SiSoHienTai = SiSoHienTai + 1
        --     WHERE MaLHP = @MaLHP AND SiSoHienTai < SiSoToiDa;
        --   Nếu @@ROWCOUNT = 0 -> lớp đầy (2 SV cùng tranh chỗ cuối,
        --   chỉ 1 người thắng).
        --   PHƯƠNG ÁN 2 (dùng UPDLOCK + HOLDLOCK trong Transaction):
        --     SELECT ... FROM LOPHOCPHAN WITH (UPDLOCK, HOLDLOCK)
        --     WHERE MaLHP = @MaLHP
        --   -> khóa đọc cập nhật giữ tới hết giao dịch, ngăn 2 phiên
        --      cùng đọc SiSoHienTai = 39.
        -- ====================================================
        DECLARE @SiSoHienTai INT, @SiSoToiDa INT;

        -- KHÓA DÒNG ĐỘC QUYỀN: chặn phiên khác đọc/ghi dòng này
        -- tới khi COMMIT (chống Lost Update — xem docs/isolation_level_analysis.md)
        SELECT
            @SiSoHienTai = SiSoHienTai,
            @SiSoToiDa   = SiSoToiDa
        FROM LOPHOCPHAN WITH (UPDLOCK, HOLDLOCK)
        WHERE MaLHP = @MaLHP;

        IF @SiSoHienTai >= @SiSoToiDa
        BEGIN
            SET @KetQua = 105;
            SET @ErrMsg = N'Đăng ký thất bại! Lớp học phần ' + @MaLHP +
                          N' đã đầy sĩ số (Hết chỗ trống).';
            RAISERROR(@ErrMsg, 16, 1);
        END

        -- Ghi nhận đăng ký.
        -- TRIGGER AFTER INSERT (Issue #61) sẽ tự +1 SiSoHienTai.
        -- Dòng LOPHOCPHAN đang bị khóa UPDLOCK từ bước 6 nên không
        -- lo Lost Update; trigger chạy trong cùng Transaction.
        INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
        VALUES (@MaSV, @MaLHP, GETDATE(), N'DA_DANG_KY', @GhiChu);

        SET @KetQua = 0;

        COMMIT TRANSACTION;
        PRINT N'✅ Đăng ký học phần THÀNH CÔNG: ' + @MaSV + N' -> ' + @MaLHP;
    END TRY
    BEGIN CATCH
        -- Rollback toàn bộ nếu có lỗi bất kỳ
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Nếu chưa có thông báo cụ thể, lấy từ lỗi hệ thống
        IF @ErrMsg IS NULL
            SET @ErrMsg = ERROR_MESSAGE();

        PRINT N'❌ Đăng ký thất bại (mã ' + CAST(@KetQua AS VARCHAR(10)) + N'): ' + @ErrMsg;
    END CATCH
END;
GO

PRINT N'[OK] Issue #50 — Đã tạo SP_DangKyHocPhan (5 bước kiểm tra + Transaction).';
GO
