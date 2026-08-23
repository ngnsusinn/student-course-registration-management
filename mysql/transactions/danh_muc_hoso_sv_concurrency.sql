-- ==========================================================
-- Ten file : mysql/transactions/danh_muc_hoso_sv_concurrency.sql
-- Module   : Danh muc he thong & Ho so sinh vien (TV1)
-- Issue    : #69 Stored procedure cap nhat ho so SV chong xung dot
-- Mo ta    : Ban dich T-SQL -> MySQL.
--            SP_CapNhatHoSoSinhVien_Concurrency: cap nhat Email /
--            SoDienThoai cua SV trong Transaction; SELECT ... FOR
--            UPDATE khoa dong (tuong duong UPDLOCK+ROWLOCK) ngan
--            Lost Update khi 2 nhan vien cung sua ho so 1 SV.
-- ==========================================================

DROP PROCEDURE IF EXISTS SP_CapNhatHoSoSinhVien_Concurrency;

DELIMITER $$

CREATE PROCEDURE SP_CapNhatHoSoSinhVien_Concurrency (
    IN pMaSV          VARCHAR(12),
    IN pEmailMoi      VARCHAR(100),
    IN pSoDienThoaiMoi VARCHAR(15)
)
proc_cap_nhat_hoso: BEGIN
    DECLARE vNotFound INT DEFAULT 0;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET vNotFound = 1;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- 1. Kiem tra su ton tai + Khoa dong du lieu (FOR UPDATE)
    --    Ngan cac giao dich khac doc/sua SV nay cho den khi ket thuc
    SELECT MaSV FROM SINHVIEN WHERE MaSV = pMaSV FOR UPDATE;

    IF vNotFound = 1 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = CONCAT('Loi: Khong tim thay sinh vien co ma ', pMaSV, '!');
    END IF;

    -- 2. Cap nhat Email (neu nguoi dung co truyen vao)
    IF pEmailMoi IS NOT NULL AND pEmailMoi <> '' THEN
        UPDATE SINHVIEN SET Email = pEmailMoi WHERE MaSV = pMaSV;
    END IF;

    -- 3. Cap nhat So dien thoai (neu nguoi dung co truyen vao)
    IF pSoDienThoaiMoi IS NOT NULL AND pSoDienThoaiMoi <> '' THEN
        UPDATE SINHVIEN SET SoDienThoai = pSoDienThoaiMoi WHERE MaSV = pMaSV;
    END IF;

    COMMIT;
    SELECT CONCAT('Cap nhat ho so sinh vien ', pMaSV, ' thanh cong!') AS KetQua;
END$$

DELIMITER ;

-- ==========================================================
-- DEMO CONCURRENCY (2 nhan vien cung sua ho so 1 SV)
-- ==========================================================
-- Cua so 1:
--   CALL SP_CapNhatHoSoSinhVien_Concurrency('SV001', 'sv001_moi@edu.vn', NULL);
-- Cua so 2 (dong thoi):
--   CALL SP_CapNhatHoSoSinhVien_Concurrency('SV001', NULL, '0987777666');
-- => Phien 2 cho doi den khi phien 1 COMMIT (khong Lost Update).

SELECT '[OK] Issue #69 — SP cap nhat ho so SV chong xung dot da tao.' AS KetLuan;
