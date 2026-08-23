-- ==========================================================
-- Ten file : mysql/transactions/phan_tich_concurrency_hoc_phi.sql
-- Module   : Hoc phi, Tai khoan & Van hanh he thong (TV5)
-- Issue    : #78 Phan tich concurrency cap nhat thanh toan hoc phi
-- Mo ta    : Ban dich T-SQL -> MySQL.
--            SP_DongHocPhi_AnToan: dong trang thai HOCPHI = 
--            DA_THANH_TOAN trong Transaction + SELECT ... FOR UPDATE
--            (tuong duong UPDLOCK+HOLDLOCK) de tuan tu hoa viec
--            cap nhat cung 1 phieu hoc phi, tranh Lost Update.
-- ==========================================================

DROP PROCEDURE IF EXISTS SP_DongHocPhi_AnToan;

DELIMITER $$

CREATE PROCEDURE SP_DongHocPhi_AnToan (
    IN pMaHocPhi VARCHAR(15)
)
proc_dong_hoc_phi: BEGIN
    DECLARE vTongTien   DECIMAL(15,0);
    DECLARE vDaNop      DECIMAL(15,0);
    DECLARE vTrangThai  VARCHAR(30);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- ==================================================
    -- 1. DOC BAN GHI VOI KHOA CAP NHAT (FOR UPDATE)
    --    = UPDLOCK + HOLDLOCK trong SQL Server:
    --    - Khoa Update tren ban ghi duoc doc.
    --    - Giu khoa den khi transaction ket thuc.
    --    - Transaction khac muon cap nhat cung ban ghi phai cho.
    -- ==================================================
    SELECT TongTien, DaNop, TrangThai
    INTO vTongTien, vDaNop, vTrangThai
    FROM HOCPHI
    WHERE MaHocPhi = pMaHocPhi
    FOR UPDATE;

    -- ==================================================
    -- 2. KIEM TRA PHIEU HOC PHI
    -- ==================================================
    IF vTongTien IS NULL THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Khong tim thay phieu hoc phi.';
    END IF;

    -- ==================================================
    -- 3. KIEM TRA DA THANH TOAN DU CHUA
    -- ==================================================
    IF vDaNop <> vTongTien THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Khong the dong hoc phi vi sinh vien chua thanh toan du.';
    END IF;

    -- ==================================================
    -- 4. KIEM TRA TRANG THAI HIEN TAI
    -- ==================================================
    IF vTrangThai = 'DA_THANH_TOAN' THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hoc phi da duoc dong truoc do.';
    END IF;

    -- ==================================================
    -- 5. CAP NHAT TRANG THAI
    -- ==================================================
    UPDATE HOCPHI
    SET TrangThai = 'DA_THANH_TOAN'
    WHERE MaHocPhi = pMaHocPhi;

    -- ==================================================
    -- 6. KIEM TRA UPDATE
    -- ==================================================
    IF ROW_COUNT() <> 1 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cap nhat trang thai hoc phi that bai.';
    END IF;

    -- ==================================================
    -- 7. COMMIT + TRA KET QUA
    -- ==================================================
    COMMIT;

    SELECT MaHocPhi, MaSV, MaHocKy, TongTien, DaNop,
           (TongTien - DaNop) AS SoTienConNo, TrangThai
    FROM HOCPHI
    WHERE MaHocPhi = pMaHocPhi;
END$$

DELIMITER ;

-- ==========================================================
-- DEMO CONCURRENCY (2 tien trinh cung cap nhat 1 phieu hoc phi)
-- ==========================================================
-- Cua so 1: CALL SP_DongHocPhi_AnToan('HP0002');
-- Cua so 2 (dong thoi): CALL SP_DongHocPhi_AnToan('HP0002');
-- => Phien 2 cho doi lock; sau do nhan loi 'Hoc phi da duoc dong truoc do.'
--    (neu phien 1 da dong xong) — khong cap nhat sai trang thai.

SELECT '[OK] Issue #78 — SP dong hoc phi an toan (concurrency) da tao.' AS KetLuan;
