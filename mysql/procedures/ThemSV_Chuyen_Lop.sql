-- ==========================================================
-- Ten file : mysql/procedures/ThemSV_Chuyen_Lop.sql
-- Module   : Danh muc he thong & Ho so sinh vien (TV1)
-- Issue    : #46 Stored Procedure & Function: them SV, chuyen
--            lop/nganh, dem si so lop.
-- Mo ta    : Ban dich T-SQL -> MySQL (Schema MySQL:
--            SINHVIEN, LOP_SINHHOAT, NGANH).
--            - SP_ThemSinhVien_Moi : them SV (kiem tra lop ton tai,
--              trung ma) + tu dong tao tai khoan dang nhap.
--            - SP_ChuyenLop_Nganh  : chuyen lop/nganh cho SV
--              (kiem tra lop moi ton tai, cap nhat dong bo).
--            - FN_DemSiSoLop       : dem so luong SV cua lop.
-- ==========================================================

DROP PROCEDURE IF EXISTS SP_ThemSinhVien_Moi;
DROP PROCEDURE IF EXISTS SP_ChuyenLop_Nganh;
DROP FUNCTION  IF EXISTS FN_DemSiSoLop;

DELIMITER $$

-- ==========================================================
-- 1. THEM SINH VIEN MOI (kiem tra lop ton tai + trung ma SV)
--    Transaction dam bao Atomicity: neu loi -> ROLLBACK.
-- ==========================================================
CREATE PROCEDURE SP_ThemSinhVien_Moi (
    IN pMaSV        VARCHAR(12),
    IN pHoTen       VARCHAR(100),
    IN pNgaySinh    DATE,
    IN pGioiTinh    TINYINT,
    IN pEmail       VARCHAR(100),
    IN pSoDienThoai VARCHAR(15),
    IN pMaLopSH     VARCHAR(15),
    IN pQueQuan     VARCHAR(100),
    OUT pKetQua     INT
)
proc_them_sv: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET pKetQua = 500;
    END;

    SET pKetQua = 500;
    START TRANSACTION;

    -- 1. Kiem tra ma SV trung lap
    IF EXISTS (SELECT 1 FROM SINHVIEN WHERE MaSV = pMaSV) THEN
        SET pKetQua = 401;
        ROLLBACK;
        LEAVE proc_them_sv;
    END IF;

    -- 2. Kiem tra lop sinh hoat ton tai
    IF NOT EXISTS (SELECT 1 FROM LOP_SINHHOAT WHERE MaLopSH = pMaLopSH) THEN
        SET pKetQua = 402;
        ROLLBACK;
        LEAVE proc_them_sv;
    END IF;

    -- 3. Them sinh vien
    INSERT INTO SINHVIEN (MaSV, HoTen, NgaySinh, GioiTinh, Email, SoDienThoai, QueQuan, TrangThaiHoc, MaLopSH)
    VALUES (pMaSV, pHoTen, pNgaySinh, pGioiTinh, pEmail, pSoDienThoai, pQueQuan, 1, pMaLopSH);

    -- 4. Tu dong tao tai khoan dang nhap cho SV (mac dinh: MatKhau = 123456@a)
    IF NOT EXISTS (SELECT 1 FROM TAIKHOAN WHERE MaSV = pMaSV) THEN
        INSERT INTO TAIKHOAN (MaTaiKhoan, TenDangNhap, MatKhau, Email, TrangThai, MaVaiTro, MaSV, MaGV)
        VALUES (CONCAT('TK', pMaSV), LOWER(pMaSV), SHA2('123456@a', 256), pEmail, 'ACTIVE', 'SV', pMaSV, NULL);
    END IF;

    SET pKetQua = 0;
    COMMIT;
END$$

-- ==========================================================
-- 2. CHUYEN LOP / NGANH CHO SINH VIEN
--    Kiem tra SV ton tai, lop moi ton tai, SV chua o lop moi.
-- ==========================================================
CREATE PROCEDURE SP_ChuyenLop_Nganh (
    IN pMaSV      VARCHAR(12),
    IN pMaLopMoi  VARCHAR(15),
    OUT pKetQua   INT
)
proc_chuyen_lop: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET pKetQua = 500;
    END;

    SET pKetQua = 500;
    START TRANSACTION;

    -- 1. Kiem tra SV ton tai
    IF NOT EXISTS (SELECT 1 FROM SINHVIEN WHERE MaSV = pMaSV) THEN
        SET pKetQua = 403;
        ROLLBACK;
        LEAVE proc_chuyen_lop;
    END IF;

    -- 2. Kiem tra lop moi ton tai
    IF NOT EXISTS (SELECT 1 FROM LOP_SINHHOAT WHERE MaLopSH = pMaLopMoi) THEN
        SET pKetQua = 404;
        ROLLBACK;
        LEAVE proc_chuyen_lop;
    END IF;

    -- 3. SV da o lop moi roi
    IF EXISTS (SELECT 1 FROM SINHVIEN WHERE MaSV = pMaSV AND MaLopSH = pMaLopMoi) THEN
        SET pKetQua = 405;
        ROLLBACK;
        LEAVE proc_chuyen_lop;
    END IF;

    -- 4. Cap nhat chuyen lop
    UPDATE SINHVIEN SET MaLopSH = pMaLopMoi WHERE MaSV = pMaSV;

    SET pKetQua = 0;
    COMMIT;
END$$

-- ==========================================================
-- 3. DEM SI SO LOP SINH HOAT (SCALAR FUNCTION)
-- ==========================================================
CREATE FUNCTION FN_DemSiSoLop (pMaLopSH VARCHAR(15))
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE vSiSo INT;
    SELECT COUNT(*) INTO vSiSo
    FROM SINHVIEN
    WHERE MaLopSH = pMaLopSH AND TrangThaiHoc = 1;
    RETURN IFNULL(vSiSo, 0);
END$$

DELIMITER ;
