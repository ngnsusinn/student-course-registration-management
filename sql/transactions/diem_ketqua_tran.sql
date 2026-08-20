-- ==========================================================
-- Tên file : sql/transactions/diem_ketqua_tran.sql
-- Module   : Module 4 — Điểm số & Kết quả học tập (TV4 — Wiett)
-- Issue    : #75 Transaction nhập điểm hàng loạt
-- Mô tả    : Giao tác nhập điểm hàng loạt cho sinh viên thuộc Lớp HP.
--            Sử dụng TRY...CATCH, BEGIN TRANSACTION và ROLLBACK.
--            Đảm bảo tính Nguyên tử (Atomicity): Rollback toàn bộ
--            nếu có bất kỳ dòng điểm nào bị lỗi (dữ liệu sai miền
--            giá trị [0,10] hoặc lỗi hệ thống), tránh nhập dở dang.
-- ==========================================================

USE [StudentCourseRegistration];
GO

-- ==========================================================
-- STORED PROCEDURE: SP_NhapDiemHangLoat
-- Tham số nhận dạng LHP và nộp điểm an toàn trọn gói
-- ==========================================================
IF OBJECT_ID(N'SP_NhapDiemHangLoat', N'P') IS NOT NULL DROP PROCEDURE SP_NhapDiemHangLoat;
GO

CREATE PROCEDURE SP_NhapDiemHangLoat
    @MaLHP VARCHAR(15),
    @NguoiNhap VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- Tự động Rollback nếu xảy ra lỗi nghiêm trọng

    PRINT N'=== BẮT ĐẦU GIAO TÁC NHẬP ĐIỂM HÀNG LOẠT ===';
    
    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Kiểm tra Lớp học phần có tồn tại không
        IF NOT EXISTS (SELECT 1 FROM LOPHOCPHAN WHERE MaLHP = @MaLHP)
        BEGIN
            RAISERROR(N'Lỗi: Lớp học phần %s không tồn tại trong hệ thống!', 16, 1, @MaLHP);
        END

        -- 2. Kiểm tra xem có sinh viên nào có điểm không hợp lệ trong dữ liệu tạm
        -- (Ví dụ kiểm tra kiểm soát điểm ngoài khoảng [0, 10])
        IF EXISTS (
            SELECT 1 FROM KETQUAHOCTAP 
            WHERE MaLHP = @MaLHP 
              AND ((DiemChuyenCan < 0.0 OR DiemChuyenCan > 10.0)
                OR (DiemGiuaKy < 0.0 OR DiemGiuaKy > 10.0)
                OR (DiemCuoiKy < 0.0 OR DiemCuoiKy > 10.0))
        )
        BEGIN
            RAISERROR(N'Lỗi dữ liệu: Phát hiện điểm thành phần ngoài khoảng [0, 10]! Giao tác bị hủy bỏ.', 16, 1);
        END

        -- 3. Giả lập cập nhật điểm số cho toàn bộ sinh viên trong lớp học phần
        -- (Thao tác này được thực hiện trong 1 giao tác duy nhất)
        UPDATE KETQUAHOCTAP
        SET 
            DiemChuyenCan = ISNULL(DiemChuyenCan, 8.0),
            DiemGiuaKy    = ISNULL(DiemGiuaKy, 7.5),
            DiemCuoiKy    = ISNULL(DiemCuoiKy, 8.0)
        WHERE MaLHP = @MaLHP;

        -- Trigger TRG_KETQUAHOCTAP_TinhDiem sẽ tự động tính toán DiemTongKet, DiemChu, DiemHe4

        -- 4. Ghi nhận giao dịch thành công (Commit)
        COMMIT TRANSACTION;
        PRINT N'[SUCCESS] Giao tác thành công! Đã nhập điểm hàng loạt cho lớp học phần ' + @MaLHP;
    END TRY
    BEGIN CATCH
        -- Hủy bỏ toàn bộ giao dịch nếu có bất kỳ lỗi nào xảy ra
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT N'[ROLLBACK] Đã hủy bỏ toàn bộ thay đổi! Không có bản ghi nào bị nhập dở dang.';
        END

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- ==========================================================
-- KỊCH BẢN DEMO THỰC THI TRANSACTION NHẬP ĐIỂM HÀNG LOẠT
-- ==========================================================

-- Demo 1: Nhập điểm hợp lệ cho lớp học phần LHP101
EXEC SP_NhapDiemHangLoat @MaLHP = 'LHP101', @NguoiNhap = 'GV001';

-- Demo 2: Minh họa ROLLBACK khi phát hiện lỗi dữ liệu dở dang
BEGIN TRANSACTION;
BEGIN TRY
    -- Cố tình nhập điểm chuyên cần sai = 15.0 (> 10.0) cho 1 sinh viên
    UPDATE KETQUAHOCTAP 
    SET DiemChuyenCan = 15.0 
    WHERE MaLHP = 'LHP101' AND MaSV = 'SV001';

    -- Thao tác 2: Nhập điểm cho sinh viên khác
    UPDATE KETQUAHOCTAP 
    SET DiemChuyenCan = 9.0 
    WHERE MaLHP = 'LHP101' AND MaSV = 'SV002';

    -- Kiểm tra điều kiện vi phạm
    IF EXISTS (SELECT 1 FROM KETQUAHOCTAP WHERE DiemChuyenCan > 10.0)
    BEGIN
        RAISERROR(N'Phát hiện điểm chuyên cần > 10.0! Kích hoạt ROLLBACK.', 16, 1);
    END

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
    BEGIN
        ROLLBACK TRANSACTION;
        PRINT N'[TEST PASSED] Giao tác đã được ROLLBACK thành công khi phát hiện 1 dòng lỗi!';
    END
END CATCH;
GO

PRINT N'[OK] Issue #75 — Đã tạo thành công Transaction nhập điểm hàng loạt.';
GO
