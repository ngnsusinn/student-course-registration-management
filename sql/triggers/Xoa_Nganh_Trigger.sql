-- =================================================================
-- ISSUE #57: TRIGGER CHẶN XÓA NGÀNH ĐÀO TẠO KHI CÒN SINH VIÊN
-- =================================================================

CREATE OR ALTER TRIGGER trg_ChanXoaNganhKhiConSinhVien
ON NGANH
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra xem ngành chuẩn bị xóa có chứa sinh viên (thông qua bảng LOP) hay không
    IF EXISTS (
        SELECT 1
        FROM deleted d
        JOIN LOP l ON d.MaNganh = l.MaNganh
        JOIN SINH_VIEN sv ON l.MaLop = sv.MaLop
    )
    BEGIN
        RAISERROR(N'Lỗi: Không thể xóa Ngành đào tạo này vì vẫn còn Sinh viên thuộc ngành!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Nếu không còn sinh viên thuộc ngành, cho phép xóa ngành
    DELETE FROM NGANH
    WHERE MaNganh IN (SELECT MaNganh FROM deleted);

    PRINT N'Xóa ngành đào tạo thành công.';
END;
GO