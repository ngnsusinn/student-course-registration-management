-- ==========================================================
-- Tên file : sql/triggers/hocphan_lophocphan_trigger.sql
-- Module   : Học phần, Giảng viên & Mở lớp học phần (TV2)
-- Issue    : Trigger kiểm tra lịch học
--
-- Mô tả:
-- Trigger kiểm tra không cho phép thêm/cập nhật lịch học
-- bị trùng phòng hoặc trùng giảng viên trong cùng học kỳ.
--
-- Ghi nhận / kiểm tra:
--      + Giảng viên không được trùng lịch
--      + Phòng học không được trùng lịch
--      + Cùng thứ và khoảng tiết
--
-- Chạy sau:
--      00_hocphan_giangvien_ddl.sql
-- ==========================================================

CREATE TRIGGER TRG_KiemTraTrungLich
ON LichHoc
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    /*======================================================
        1. KIỂM TRA TRÙNG PHÒNG
    ======================================================*/
    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        JOIN LichHoc LH
            ON I.MaPhong = LH.MaPhong
           AND I.Thu = LH.Thu
           AND I.MaLichHoc <> LH.MaLichHoc

           /* Hai khoảng tiết bị giao nhau */
           AND I.TietBatDau < LH.TietBatDau + LH.SoTiet
           AND LH.TietBatDau < I.TietBatDau + I.SoTiet

        JOIN LopHocPhan LHP_I
            ON I.MaLHP = LHP_I.MaLHP

        JOIN LopHocPhan LHP_LH
            ON LH.MaLHP = LHP_LH.MaLHP

        /* Chỉ xét cùng học kỳ */
        AND LHP_I.MaHocKy = LHP_LH.MaHocKy
    )
    BEGIN
        RAISERROR(N'Không thể lưu lịch học: phòng đã bị trùng lịch.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;


    /*======================================================
        2. KIỂM TRA TRÙNG GIẢNG VIÊN
    ======================================================*/
    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        JOIN LichHoc LH
            ON I.Thu = LH.Thu
           AND I.MaLichHoc <> LH.MaLichHoc

           /* Hai khoảng tiết bị giao nhau */
           AND I.TietBatDau < LH.TietBatDau + LH.SoTiet
           AND LH.TietBatDau < I.TietBatDau + I.SoTiet

        JOIN LopHocPhan LHP_I
            ON I.MaLHP = LHP_I.MaLHP

        JOIN LopHocPhan LHP_LH
            ON LH.MaLHP = LHP_LH.MaLHP

        /* Cùng giảng viên */
        AND LHP_I.MaGV = LHP_LH.MaGV

        /* Cùng học kỳ */
        AND LHP_I.MaHocKy = LHP_LH.MaHocKy
    )
    BEGIN
        RAISERROR(N'Không thể lưu lịch học: giảng viên đã bị trùng lịch.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
