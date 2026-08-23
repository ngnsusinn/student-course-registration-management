-- ==========================================================
-- Ten file : mysql/procedures/SP_HuyDangKy.sql
-- Module   : Dang ky hoc phan (TV3 — Leader)
-- Mo ta    : Ban dich T-SQL -> MySQL. HUY DANG KY hoc phan:
--              - Chi huy duoc khi DOT VAN MO (con han huy).
--              - Chi huy ban ghi dang o trang thai DA_DANG_KY.
--              - UPDATE trang thai -> DA_HUY (giu lich su);
--                trigger tu -1 SiSoHienTai.
-- Ma loi pKetQua:
--   0=OK, 200=Dot da dong, 201=Khong tim thay ban ghi,
--   202=Khong o trang thai DA_DANG_KY, 500=Loi he thong
-- ==========================================================

DROP PROCEDURE IF EXISTS SP_HuyDangKy;

DELIMITER $$

CREATE PROCEDURE SP_HuyDangKy (
    IN  pMaSV   VARCHAR(12),
    IN  pMaLHP  VARCHAR(15),
    OUT pKetQua INT
)
proc_huy: BEGIN
    DECLARE vTrangThaiHienTai VARCHAR(20);
    DECLARE vNotFound         INT DEFAULT 0;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET vNotFound = 1;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET pKetQua = 500;
    END;

    SET pKetQua = 500;

    START TRANSACTION;

    -- ====================================================
    -- BUOC 1: KIEM TRA DOT DANG KY CON MO (con han huy)
    -- ====================================================
    IF FN_KiemTraDotDangKy() = 0 THEN
        SET pKetQua = 200;
        ROLLBACK;
        LEAVE proc_huy;
    END IF;

    -- ====================================================
    -- BUOC 2: LAY TRANG THAI HIEN TAI (khoa doc cap nhat)
    -- ====================================================
    SELECT dk.TrangThaiDangKy INTO vTrangThaiHienTai
    FROM DANGKYHOCPHAN dk
    JOIN LOPHOCPHAN lhp ON lhp.MaLHP = dk.MaLHP
    WHERE dk.MaSV = pMaSV AND dk.MaLHP = pMaLHP
    FOR UPDATE;

    IF vNotFound = 1 THEN
        SET pKetQua = 201;
        ROLLBACK;
        LEAVE proc_huy;
    END IF;

    IF vTrangThaiHienTai <> 'DA_DANG_KY' THEN
        SET pKetQua = 202;
        ROLLBACK;
        LEAVE proc_huy;
    END IF;

    -- ====================================================
    -- BUOC 3: HUY DANG KY (giu lich su, trigger tu -1 si so)
    -- ====================================================
    UPDATE DANGKYHOCPHAN
    SET TrangThaiDangKy = 'DA_HUY',
        GhiChu = CONCAT(IFNULL(GhiChu, ''), ' | Hủy ngày ', DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s'))
    WHERE MaSV = pMaSV AND MaLHP = pMaLHP;

    SET pKetQua = 0;

    COMMIT;
END$$

DELIMITER ;
