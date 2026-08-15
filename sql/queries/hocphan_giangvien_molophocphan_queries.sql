-- ==========================================================
-- Tên file : sql/queries/hocphan_giangvien_lophocphan_queries.sql
-- Module   : Học phần, Giảng viên & Mở lớp học phần (TV2)
-- Issue    : Truy vấn Học phần, Giảng viên & Lớp học phần
-- Mô tả    : Các câu truy vấn phục vụ quản lý học phần,
--            giảng viên, lớp học phần và lịch học:
--              Q1. LHP theo học kỳ + sĩ số còn trống
--              Q2. Tra cứu môn học và môn tiên quyết
--              Q3. Thời khóa biểu theo giảng viên
--              Q4. Thời khóa biểu theo phòng
--              Q5. Kiểm tra phòng trống theo khung giờ
--              Q6. Danh sách LHP theo môn học
--              Q7. Thống kê số LHP theo giảng viên
-- ==========================================================

USE [DangKyHocPhan];
GO

/*==========================================================
    1. LHP THEO HỌC KỲ + SĨ SỐ CÒN TRỐNG
==========================================================*/

SELECT
    LHP.MaLHP,
    LHP.TenLHP,
    MH.TenMonHoc,
    HK.TenHocKy,
    HK.NamHoc,
    LHP.SiSoToiDa,
    LHP.SiSoHienTai,
    LHP.SiSoToiDa - LHP.SiSoHienTai AS SoChoConTrong,
    LHP.TrangThaiLop
FROM LopHocPhan LHP
JOIN MonHoc MH
    ON LHP.MaMonHoc = MH.MaMonHoc
JOIN HocKy HK
    ON LHP.MaHocKy = HK.MaHocKy
WHERE HK.MaHocKy = 'HK02'
ORDER BY LHP.MaLHP;


/*==========================================================
    2. TRA MÔN TIÊN QUYẾT - kiểm tra môn cụ thể
==========================================================*/

SELECT
    MH.MaMonHoc,
    MH.TenMonHoc,
    TQ.MaMonTienQuyet,
    MH_TQ.TenMonHoc AS TenMonTienQuyet
FROM MonHoc MH
JOIN MonHoc_TienQuyet TQ
    ON MH.MaMonHoc = TQ.MaMonHoc
JOIN MonHoc MH_TQ
    ON TQ.MaMonTienQuyet = MH_TQ.MaMonHoc
ORDER BY
    MH.MaMonHoc;
GO

SELECT
    MH.MaMonHoc,
    MH.TenMonHoc,
    TQ.MaMonTienQuyet,
    MH_TQ.TenMonHoc AS TenMonTienQuyet
FROM MonHoc MH
JOIN MonHoc_TienQuyet TQ
    ON MH.MaMonHoc = TQ.MaMonHoc
JOIN MonHoc MH_TQ
    ON TQ.MaMonTienQuyet = MH_TQ.MaMonHoc
WHERE MH.MaMonHoc = 'MH019';
GO

/*==========================================================
    3. THỜI KHÓA BIỂU THEO GIẢNG VIÊN
==========================================================*/

SELECT
    GV.MaGV,
    GV.HoTen,
    LHP.MaLHP,
    MH.TenMonHoc,
    HK.TenHocKy,
    LH.Thu,
    LH.TietBatDau,
    LH.SoTiet,
    PH.TenPhong
FROM GiangVien GV
JOIN LopHocPhan LHP
    ON GV.MaGV = LHP.MaGV
JOIN MonHoc MH
    ON LHP.MaMonHoc = MH.MaMonHoc
JOIN HocKy HK
    ON LHP.MaHocKy = HK.MaHocKy
JOIN LichHoc LH
    ON LHP.MaLHP = LH.MaLHP
JOIN PhongHoc PH
    ON LH.MaPhong = PH.MaPhong
WHERE GV.MaGV = 'GV001'
ORDER BY
    LH.Thu,
    LH.TietBatDau;
GO

/*==========================================================
    4. THỜI KHÓA BIỂU THEO PHÒNG
==========================================================*/

SELECT
    PH.MaPhong,
    PH.TenPhong,
    LH.Thu,
    LH.TietBatDau,
    LH.SoTiet,
    LHP.MaLHP,
    MH.TenMonHoc,
    GV.HoTen AS GiangVien,
    HK.TenHocKy
FROM PhongHoc PH
JOIN LichHoc LH
    ON PH.MaPhong = LH.MaPhong
JOIN LopHocPhan LHP
    ON LH.MaLHP = LHP.MaLHP
JOIN MonHoc MH
    ON LHP.MaMonHoc = MH.MaMonHoc
JOIN GiangVien GV
    ON LHP.MaGV = GV.MaGV
JOIN HocKy HK
    ON LHP.MaHocKy = HK.MaHocKy
WHERE PH.MaPhong = 'P001'
ORDER BY
    LH.Thu,
    LH.TietBatDau;
GO

/*==========================================================
    5. KIỂM TRA PHÒNG TRỐNG THEO KHUNG GIỜ
    Ví dụ: Thứ 2, tiết 1-3
==========================================================*/

DECLARE @Thu TINYINT = 2;
DECLARE @TietBatDau TINYINT = 1;
DECLARE @SoTiet TINYINT = 3;

SELECT
    PH.MaPhong,
    PH.TenPhong,
    PH.SucChua
FROM PhongHoc PH
WHERE NOT EXISTS
(
    SELECT 1
    FROM LichHoc LH
    WHERE LH.MaPhong = PH.MaPhong
      AND LH.Thu = @Thu

      /* Kiểm tra 2 khoảng tiết có giao nhau */
      AND @TietBatDau < LH.TietBatDau + LH.SoTiet
      AND LH.TietBatDau < @TietBatDau + @SoTiet
)
ORDER BY
    PH.MaPhong;
GO

/*==========================================================
    6. DANH SÁCH LHP THEO MÔN HỌC
==========================================================*/

SELECT
    MH.MaMonHoc,
    MH.TenMonHoc,
    LHP.MaLHP,
    LHP.TenLHP,
    HK.TenHocKy,
    HK.NamHoc,
    GV.MaGV,
    GV.HoTen AS GiangVien,
    LHP.SiSoToiDa,
    LHP.SiSoHienTai,
    LHP.SiSoToiDa - LHP.SiSoHienTai AS SoChoConTrong,
    LHP.TrangThaiLop
FROM MonHoc MH
JOIN LopHocPhan LHP
    ON MH.MaMonHoc = LHP.MaMonHoc
JOIN HocKy HK
    ON LHP.MaHocKy = HK.MaHocKy
JOIN GiangVien GV
    ON LHP.MaGV = GV.MaGV
WHERE MH.MaMonHoc = 'MH019'
ORDER BY LHP.MaLHP;
GO

/*==========================================================
    7. THỐNG KÊ SỐ LHP THEO GIẢNG VIÊN
==========================================================*/

SELECT
    GV.MaGV,
    GV.HoTen,
    COUNT(LHP.MaLHP) AS SoLuongLHP
FROM GiangVien GV
LEFT JOIN LopHocPhan LHP
    ON GV.MaGV = LHP.MaGV
GROUP BY
    GV.MaGV,
    GV.HoTen
ORDER BY
    SoLuongLHP DESC;
GO

/*==========================================================
    SESSION A — CÁN BỘ A
    Mở lớp LH081 tại P001, Thứ 2, tiết 1-3
==========================================================*/

BEGIN TRANSACTION;


/*----------------------------------------------------------
    1. CHỐT PHÒNG + KHUNG GIỜ
----------------------------------------------------------*/

SELECT *
FROM LichHoc WITH (UPDLOCK, HOLDLOCK)
WHERE MaPhong = 'P001'
  AND Thu = 2
  AND TietBatDau < 4
  AND TietBatDau + SoTiet > 1;


/*----------------------------------------------------------
    2. KIỂM TRA LẠI SAU KHI ĐÃ CHỐT
----------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM LichHoc
    WHERE MaPhong = 'P001'
      AND Thu = 2
      AND TietBatDau < 4
      AND TietBatDau + SoTiet > 1
)
BEGIN
    PRINT N'Phòng P001 đã có lịch.';
    ROLLBACK TRANSACTION;
    RETURN;
END;


/*----------------------------------------------------------
    3. GIẢ LẬP CÁN BỘ A ĐANG XẾP LỊCH
    Trong thời gian này Session B sẽ phải chờ.
----------------------------------------------------------*/

WAITFOR DELAY '00:00:10';


/*----------------------------------------------------------
    4. THÊM LỊCH CHO CÁN BỘ A
----------------------------------------------------------*/

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
    'LH901',
    'LH081',
    'P001',
    2,
    1,
    3
);


/*----------------------------------------------------------
    5. COMMIT
----------------------------------------------------------*/

COMMIT TRANSACTION;

PRINT N'Cán bộ A: Xếp lịch thành công.';
GO  

USE [DangKyHocPhan];
GO


/*==========================================================
    SESSION B — CÁN BỘ B
    Cũng muốn xếp LH082 vào P001, Thứ 2, tiết 1-3
==========================================================*/

BEGIN TRANSACTION;


/*----------------------------------------------------------
    1. CHỐT PHÒNG + KHUNG GIỜ
----------------------------------------------------------*/

SELECT *
FROM LichHoc WITH (UPDLOCK, HOLDLOCK)
WHERE MaPhong = 'P001'
  AND Thu = 2
  AND TietBatDau < 4
  AND TietBatDau + SoTiet > 1;


/*
    Nếu Session A đang giữ khóa,
    Session B sẽ CHỜ tại đây.
*/


/*----------------------------------------------------------
    2. KIỂM TRA LẠI SAU KHI ĐƯỢC GIẢI PHÓNG KHÓA
----------------------------------------------------------*/

IF EXISTS
(
    SELECT 1
    FROM LichHoc
    WHERE MaPhong = 'P001'
      AND Thu = 2
      AND TietBatDau < 4
      AND TietBatDau + SoTiet > 1
)
BEGIN
    PRINT N'Cán bộ B: Phòng P001 đã bị cán bộ A xếp lịch.';
    
    ROLLBACK TRANSACTION;
    RETURN;
END;


/*----------------------------------------------------------
    3. Nếu không bị trùng thì mới INSERT
----------------------------------------------------------*/

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
    'LH902',
    'LH082',
    'P001',
    2,
    1,
    3
);

COMMIT TRANSACTION;

PRINT N'Cán bộ B: Xếp lịch thành công.';
GO