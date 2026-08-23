-- ==========================================================
-- Ten file : mysql/procedures/sp_gpa.sql
-- Module   : Diem so & Ket qua hoc tap (TV4)
-- Mo ta    : Ban dich T-SQL -> MySQL:
--            SP_TinhGPA_HocKy, SP_TinhCPA_TichLuy.
--            CTE -> derived table (MySQL 5.7).
-- ==========================================================

DROP PROCEDURE IF EXISTS SP_TinhGPA_HocKy;
DROP PROCEDURE IF EXISTS SP_TinhCPA_TichLuy;

DELIMITER $$

-- ==========================================================
-- 1. GPA HOC KY (he 4)
-- ==========================================================
CREATE PROCEDURE SP_TinhGPA_HocKy (
    IN pMaSV     VARCHAR(12),
    IN pMaHocKy  VARCHAR(15)
)
BEGIN
    DECLARE vTongTinChi        INT DEFAULT 0;
    DECLARE vTongDiemTrongSo   DOUBLE DEFAULT 0.0;
    DECLARE vGPA               DOUBLE DEFAULT 0.0;
    DECLARE vXepLoai           VARCHAR(20) DEFAULT 'Chưa xếp loại';
    DECLARE vTenSV             VARCHAR(100);

    IF NOT EXISTS (SELECT 1 FROM SINHVIEN WHERE MaSV = pMaSV) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Loi: Ma sinh vien khong ton tai trong he thong!';
    END IF;

    SELECT HoTen INTO vTenSV FROM SINHVIEN WHERE MaSV = pMaSV;

    SELECT IFNULL(SUM(mh.SoTinChi), 0),
           IFNULL(SUM(kq.DiemHe4 * mh.SoTinChi), 0.0)
    INTO vTongTinChi, vTongDiemTrongSo
    FROM KETQUAHOCTAP kq
    JOIN LOPHOCPHAN lhp ON kq.MaLHP = lhp.MaLHP
    JOIN MONHOC mh ON lhp.MaMonHoc = mh.MaMonHoc
    WHERE kq.MaSV = pMaSV
      AND lhp.MaHocKy = pMaHocKy
      AND kq.DiemHe4 IS NOT NULL;

    IF vTongTinChi = 0 THEN
        SELECT pMaSV AS MaSV, vTenSV AS TenSinhVien, pMaHocKy AS MaHocKy,
               0 AS TongTinChiHocKy, 0.0 AS GPA_HocKy, 'Chưa có điểm' AS XepLoaiHocKy;
    ELSE
        SET vGPA = ROUND(vTongDiemTrongSo / vTongTinChi, 2);

        IF vGPA >= 3.60 THEN SET vXepLoai = 'Xuất sắc';
        ELSEIF vGPA >= 3.20 THEN SET vXepLoai = 'Giỏi';
        ELSEIF vGPA >= 2.50 THEN SET vXepLoai = 'Khá';
        ELSEIF vGPA >= 2.00 THEN SET vXepLoai = 'Trung bình';
        ELSEIF vGPA >= 1.00 THEN SET vXepLoai = 'Yếu';
        ELSE SET vXepLoai = 'Kém';
        END IF;

        SELECT pMaSV AS MaSV, vTenSV AS TenSinhVien, pMaHocKy AS MaHocKy,
               vTongTinChi AS TongTinChiHocKy, vGPA AS GPA_HocKy, vXepLoai AS XepLoaiHocKy;
    END IF;
END$$

-- ==========================================================
-- 2. CPA TICH LUY TOAN KHOA (mon hoc lai chi tinh diem cao nhat)
-- ==========================================================
CREATE PROCEDURE SP_TinhCPA_TichLuy (
    IN pMaSV VARCHAR(12)
)
BEGIN
    DECLARE vTongTinChi    INT DEFAULT 0;
    DECLARE vTinChiDat     INT DEFAULT 0;
    DECLARE vCPA           DOUBLE DEFAULT 0.0;
    DECLARE vXepLoai       VARCHAR(20);
    DECLARE vCanhBao       VARCHAR(100);
    DECLARE vTenSV         VARCHAR(100);
    DECLARE vMaLopSH       VARCHAR(15);

    IF NOT EXISTS (SELECT 1 FROM SINHVIEN WHERE MaSV = pMaSV) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Loi: Ma sinh vien khong ton tai!';
    END IF;

    SELECT HoTen, MaLopSH INTO vTenSV, vMaLopSH
    FROM SINHVIEN WHERE MaSV = pMaSV;

    SELECT IFNULL(SUM(bg.SoTinChi), 0),
           IFNULL(SUM(CASE WHEN bg.MaxDiemHe4 >= 1.0 THEN bg.SoTinChi ELSE 0 END), 0),
           IFNULL(ROUND(SUM(bg.MaxDiemHe4 * bg.SoTinChi) / NULLIF(SUM(bg.SoTinChi), 0), 2), 0.0)
    INTO vTongTinChi, vTinChiDat, vCPA
    FROM (
        SELECT mh.MaMonHoc, mh.SoTinChi, MAX(kq.DiemHe4) AS MaxDiemHe4
        FROM KETQUAHOCTAP kq
        JOIN LOPHOCPHAN lhp ON kq.MaLHP = lhp.MaLHP
        JOIN MONHOC mh ON lhp.MaMonHoc = mh.MaMonHoc
        WHERE kq.MaSV = pMaSV AND kq.DiemHe4 IS NOT NULL
        GROUP BY mh.MaMonHoc, mh.SoTinChi
    ) bg;

    IF vCPA >= 3.60 THEN SET vXepLoai = 'Xuất sắc';
    ELSEIF vCPA >= 3.20 THEN SET vXepLoai = 'Giỏi';
    ELSEIF vCPA >= 2.50 THEN SET vXepLoai = 'Khá';
    ELSEIF vCPA >= 2.00 THEN SET vXepLoai = 'Trung bình';
    ELSEIF vCPA >= 1.00 THEN SET vXepLoai = 'Yếu';
    ELSE SET vXepLoai = 'Kém';
    END IF;

    IF vCPA < 1.20 THEN SET vCanhBao = 'Cảnh báo học vụ Cấp 2 (Nguy cơ buộc thôi học)';
    ELSEIF vCPA < 1.60 THEN SET vCanhBao = 'Cảnh báo học vụ Cấp 1';
    ELSE SET vCanhBao = 'Bình thường';
    END IF;

    SELECT pMaSV AS MaSV, vTenSV AS TenSinhVien, vMaLopSH AS LopSinhHoat,
           vTongTinChi AS TongTinChiTichLuy, vTinChiDat AS TinChiDatPassed,
           vCPA AS CPA_TichLuy, vXepLoai AS XepLoaiTichLuy,
           vCanhBao AS TrangThaiCanhBaoHocVu;
END$$

DELIMITER ;
