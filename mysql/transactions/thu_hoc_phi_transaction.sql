-- ==========================================================
-- Ten file : mysql/transactions/thu_hoc_phi_transaction.sql
-- Module   : Hoc phi, Tai khoan & Van hanh he thong (TV5)
-- Issue    : #77 Giao dich thu hoc phi
-- Mo ta    : Ban dich T-SQL -> MySQL.
--            SP_ThuHocPhi: cap nhat DaNop + TrangThai trong 1
--            transaction; dam bao Atomicity va khong duoc thu
--            vuot so tien con no. (Ban MySQL day du trong
--            mysql/procedures/hocphi_taikhoan_procedures.sql;
--            file nay giu kich ban phan tich + demo transaction.)
-- ==========================================================

DROP PROCEDURE IF EXISTS SP_ThuHocPhi_Tran;

DELIMITER $$

CREATE PROCEDURE SP_ThuHocPhi_Tran (
    IN pMaHocPhi VARCHAR(15),
    IN pSoTienNop DECIMAL(15,0),
    OUT pKetQua  INT
)
proc_thu_hoc_phi: BEGIN
    DECLARE vTongTien DECIMAL(15,0);
    DECLARE vDaNop    DECIMAL(15,0);
    DECLARE vTrangThai VARCHAR(30);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET pKetQua = 500;
    END;

    SET pKetQua = 500;
    START TRANSACTION;

    -- 1. Kiem tra so tien nop
    IF pSoTienNop <= 0 THEN
        SET pKetQua = 303;   -- So tien nop khong hop le
        ROLLBACK;
        LEAVE proc_thu_hoc_phi;
    END IF;

    -- 2. Doc phieu hoc phi + khoa dong (FOR UPDATE ~ UPDLOCK+HOLDLOCK)
    SELECT TongTien, DaNop, TrangThai
    INTO vTongTien, vDaNop, vTrangThai
    FROM HOCPHI
    WHERE MaHocPhi = pMaHocPhi
    FOR UPDATE;

    -- 3. Kiem tra phieu ton tai
    IF vTongTien IS NULL THEN
        SET pKetQua = 301;   -- Khong tim thay phieu
        ROLLBACK;
        LEAVE proc_thu_hoc_phi;
    END IF;

    -- 4. Kiem tra da thanh toan het
    IF vDaNop >= vTongTien THEN
        SET pKetQua = 302;   -- Da thanh toan het
        ROLLBACK;
        LEAVE proc_thu_hoc_phi;
    END IF;

    -- 5. Kiem tra so tien nop khong vuot con no
    IF (vDaNop + pSoTienNop) > vTongTien THEN
        SET pKetQua = 304;   -- Vuot qua so tien con no
        ROLLBACK;
        LEAVE proc_thu_hoc_phi;
    END IF;

    -- 6. Cap nhat DaNop + TrangThai
    UPDATE HOCPHI
    SET DaNop = DaNop + pSoTienNop,
        TrangThai = IF(DaNop + pSoTienNop >= TongTien, 'DA_THANH_TOAN', 'DANG_XU_LY')
    WHERE MaHocPhi = pMaHocPhi;

    SET pKetQua = 0;
    COMMIT;
END$$

DELIMITER ;

-- ==========================================================
-- DEMO
-- ==========================================================
-- Demo 1: Thu hoc phi hop le
-- CALL SP_ThuHocPhi_Tran('HP0002', 500000, @kq); SELECT @kq;

-- Demo 2: Thu vuot con no -> bi chan (ma 304), rollback
-- CALL SP_ThuHocPhi_Tran('HP0002', 999999999, @kq2); SELECT @kq2;

-- Demo 3: 2 tien trinh cung thu 1 phieu -> dong thoi thu duoc
--         nho FOR UPDATE (tien trinh thu 2 cho doi, sau do bi chan
--         neu vuot con no con lai).

SELECT '[OK] Issue #77 — Giao dich thu hoc phi (Atomicity) da tao.' AS KetLuan;
