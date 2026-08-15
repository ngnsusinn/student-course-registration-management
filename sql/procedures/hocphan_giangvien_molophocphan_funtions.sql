-- ==========================================================
-- Tên file : sql/procedures/hocphan_giangvien_functions.sql
-- Module   : Module 2 — Học phần, Giảng viên & Mở lớp học phần (TV2)
-- Issue    : Function kiểm tra phòng trống theo khung giờ
-- Mô tả    : User-Defined Function (UDF):
--            1. FN_KiemTraPhongTrong:
--               Kiểm tra phòng học có trống tại một thứ và tiết
--               bắt đầu cụ thể hay không.
--            Kết quả:
--               1 = Phòng trống
--               0 = Phòng đã có lịch
-- ==========================================================
USE [dangkyhocphan];

/*==========================================================
    1. STORED PROCEDURE MỞ LỚP HỌC PHẦN
       - Kiểm tra GV không trùng lịch
       - Kiểm tra phòng không trùng lịch
==========================================================*/

CREATE PROCEDURE SP_MoLopHocPhan
    @MaLHP VARCHAR(10),
    @TenLHP NVARCHAR(100),
    @MaMonHoc VARCHAR(10),
    @MaHocKy VARCHAR(10),
    @MaGV VARCHAR(10),
    @SiSoToiDa INT,
    @MaPhong VARCHAR(10),
    @Thu TINYINT,
    @TietBatDau TINYINT,
    @SoTiet TINYINT
AS
BEGIN
    SET NOCOUNT ON;

    /*------------------------------------------------------
        1. Kiểm tra mã LHP đã tồn tại
    ------------------------------------------------------*/
    IF EXISTS
    (
        SELECT 1
        FROM LopHocPhan
        WHERE MaLHP = @MaLHP
    )
    BEGIN
        RAISERROR(N'Mã lớp học phần đã tồn tại.', 16, 1);
        RETURN;
    END;


    /*------------------------------------------------------
        2. Kiểm tra môn học
    ------------------------------------------------------*/
    IF NOT EXISTS
    (
        SELECT 1
        FROM MonHoc
        WHERE MaMonHoc = @MaMonHoc
    )
    BEGIN
        RAISERROR(N'Môn học không tồn tại.', 16, 1);
        RETURN;
    END;


    /*------------------------------------------------------
        3. Kiểm tra học kỳ
    ------------------------------------------------------*/
    IF NOT EXISTS
    (
        SELECT 1
        FROM HocKy
        WHERE MaHocKy = @MaHocKy
    )
    BEGIN
        RAISERROR(N'Học kỳ không tồn tại.', 16, 1);
        RETURN;
    END;


    /*------------------------------------------------------
        4. Kiểm tra giảng viên
    ------------------------------------------------------*/
    IF NOT EXISTS
    (
        SELECT 1
        FROM GiangVien
        WHERE MaGV = @MaGV
    )
    BEGIN
        RAISERROR(N'Giảng viên không tồn tại.', 16, 1);
        RETURN;
    END;


    /*------------------------------------------------------
        5. Kiểm tra phòng học
    ------------------------------------------------------*/
    IF NOT EXISTS
    (
        SELECT 1
        FROM PhongHoc
        WHERE MaPhong = @MaPhong
    )
    BEGIN
        RAISERROR(N'Phòng học không tồn tại.', 16, 1);
        RETURN;
    END;


    /*------------------------------------------------------
        6. Kiểm tra sĩ số
    ------------------------------------------------------*/
    IF @SiSoToiDa <= 0
    BEGIN
        RAISERROR(N'Sĩ số tối đa phải lớn hơn 0.', 16, 1);
        RETURN;
    END;


    /*------------------------------------------------------
        7. Kiểm tra thứ và tiết học
    ------------------------------------------------------*/
    IF @Thu < 2 OR @Thu > 8
    BEGIN
        RAISERROR(N'Thứ phải nằm trong khoảng từ 2 đến 8.', 16, 1);
        RETURN;
    END;

    IF @TietBatDau <= 0 OR @SoTiet <= 0
    BEGIN
        RAISERROR(N'Tiết bắt đầu và số tiết phải lớn hơn 0.', 16, 1);
        RETURN;
    END;


    /*------------------------------------------------------
        8. Kiểm tra GIẢNG VIÊN bị trùng lịch
    ------------------------------------------------------*/
    IF EXISTS
    (
        SELECT 1
        FROM LichHoc LH
        JOIN LopHocPhan LHP
            ON LH.MaLHP = LHP.MaLHP
        WHERE LHP.MaGV = @MaGV
          AND LHP.MaHocKy = @MaHocKy
          AND LH.Thu = @Thu
          AND @TietBatDau < LH.TietBatDau + LH.SoTiet
          AND LH.TietBatDau < @TietBatDau + @SoTiet
    )
    BEGIN
        RAISERROR(N'Giảng viên đã có lớp bị trùng lịch.', 16, 1);
        RETURN;
    END;


    /*------------------------------------------------------
        9. Kiểm tra PHÒNG bị trùng lịch
    ------------------------------------------------------*/
    IF EXISTS
    (
        SELECT 1
        FROM LichHoc LH
        JOIN LopHocPhan LHP
            ON LH.MaLHP = LHP.MaLHP
        WHERE LH.MaPhong = @MaPhong
          AND LHP.MaHocKy = @MaHocKy
          AND LH.Thu = @Thu
          AND @TietBatDau < LH.TietBatDau + LH.SoTiet
          AND LH.TietBatDau < @TietBatDau + @SoTiet
    )
    BEGIN
        RAISERROR(N'Phòng học đã có lớp bị trùng lịch.', 16, 1);
        RETURN;
    END;


    /*------------------------------------------------------
        10. Thêm lớp học phần
    ------------------------------------------------------*/
    INSERT INTO LopHocPhan
    (
        MaLHP,
        TenLHP,
        MaMonHoc,
        MaHocKy,
        MaGV,
        SiSoToiDa,
        SiSoHienTai,
        TrangThaiLop
    )
    VALUES
    (
        @MaLHP,
        @TenLHP,
        @MaMonHoc,
        @MaHocKy,
        @MaGV,
        @SiSoToiDa,
        0,
        N'Mở'
    );


    /*------------------------------------------------------
        11. Thêm lịch học
    ------------------------------------------------------*/
    INSERT INTO LichHoc
    (
        MaLichHoc,
        MaLHP,
        MaPhong,
        Thu,
        TietBatDau,
        SoTiet
    )
    VALUES
    (
        'LH' + RIGHT('000' + CAST(
            ISNULL(
                (
                    SELECT MAX(
                        CAST(SUBSTRING(MaLichHoc, 3, 3) AS INT)
                    )
                    FROM LichHoc
                    WHERE MaLichHoc LIKE 'LH%'
                ), 0
            ) + 1
        AS VARCHAR(3)), 3),
        @MaLHP,
        @MaPhong,
        @Thu,
        @TietBatDau,
        @SoTiet
    );


    PRINT N'Mở lớp học phần thành công.';
END;


/*==========================================================
    2. FUNCTION KIỂM TRA PHÒNG TRỐNG
    Tham số: Phòng, Thứ, Tiết
    Kết quả:
        1 = Phòng trống
        0 = Phòng đã có lịch
==========================================================*/

CREATE FUNCTION FN_KiemTraPhongTrong
(
    @MaPhong VARCHAR(10),
    @Thu TINYINT,
    @Tiet TINYINT
)
RETURNS BIT
AS
BEGIN
    DECLARE @KetQua BIT;

    IF EXISTS
    (
        SELECT 1
        FROM LichHoc
        WHERE MaPhong = @MaPhong
          AND Thu = @Thu
          AND @Tiet >= TietBatDau
          AND @Tiet < TietBatDau + SoTiet
    )
        SET @KetQua = 0;
    ELSE
        SET @KetQua = 1;

    RETURN @KetQua;
END;
