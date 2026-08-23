-- ==========================================================
-- Ten file : mysql/transactions/hocphan_giangvien_molophocphan_transactions.sql
-- Module   : Hoc phan, Giang vien & Mo lop hoc phan (TV2)
-- Issue    : Transaction mo lop hoc phan
-- Mo ta    : Ban dich T-SQL -> MySQL.
--            Dong goi "Mo LHP + tao lich hoc" trong Transaction:
--              1. Kiem tra LHP khong trung
--              2. Kiem tra GV khong trung lich
--              3. Kiem tra phong khong trung lich
--              4. Them LHP
--              5. Them lich hoc
--              6. Loi -> ROLLBACK toan bo; thanh cong -> COMMIT.
--            SP_MoLopHocPhan (mysql/procedures/hocphan_giangvien_
--            procedures.sql) da dong goi logic nay san.
-- ==========================================================

DROP PROCEDURE IF EXISTS SP_MoLopHocPhan_Tran;

DELIMITER $$

CREATE PROCEDURE SP_MoLopHocPhan_Tran (
    IN pMaLHP      VARCHAR(15),
    IN pTenLHP     VARCHAR(100),
    IN pMaMonHoc   VARCHAR(10),
    IN pMaHocKy    VARCHAR(10),
    IN pMaGV       VARCHAR(10),
    IN pSiSoToiDa  INT,
    IN pMaPhong    VARCHAR(10),
    IN pThu        INT,
    IN pTietBatDau INT,
    IN pSoTiet     INT
)
proc_mo_lhp: BEGIN
    DECLARE vMaxLichHoc INT DEFAULT 0;
    DECLARE vMaLichHoc  VARCHAR(10);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- ======================================================
    -- 1. Kiem tra LHP da ton tai
    -- ======================================================
    IF EXISTS (SELECT 1 FROM LOPHOCPHAN WHERE MaLHP = pMaLHP) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ma lop hoc phan da ton tai.';
    END IF;

    -- ======================================================
    -- 2. Kiem tra GIANG VIEN bi trung lich
    -- ======================================================
    IF EXISTS (
        SELECT 1
        FROM LICHHOC lh
        JOIN LOPHOCPHAN lhp ON lh.MaLHP = lhp.MaLHP
        WHERE lhp.MaGV = pMaGV
          AND lhp.MaHocKy = pMaHocKy
          AND lh.Thu = pThu
          AND pTietBatDau < lh.TietBatDau + lh.SoTiet
          AND lh.TietBatDau < pTietBatDau + pSoTiet
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Giang vien da co lop bi trung lich.';
    END IF;

    -- ======================================================
    -- 3. Kiem tra PHONG bi trung lich
    -- ======================================================
    IF EXISTS (
        SELECT 1
        FROM LICHHOC lh
        JOIN LOPHOCPHAN lhp ON lh.MaLHP = lhp.MaLHP
        WHERE lh.MaPhong = pMaPhong
          AND lhp.MaHocKy = pMaHocKy
          AND lh.Thu = pThu
          AND pTietBatDau < lh.TietBatDau + lh.SoTiet
          AND lh.TietBatDau < pTietBatDau + pSoTiet
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phong hoc da co lop bi trung lich.';
    END IF;

    -- ======================================================
    -- 4. Them LOP HOC PHAN
    -- ======================================================
    INSERT INTO LOPHOCPHAN (MaLHP, TenLHP, MaMonHoc, MaHocKy, MaGV, SiSoToiDa, SiSoHienTai, TrangThaiLop)
    VALUES (pMaLHP, pTenLHP, pMaMonHoc, pMaHocKy, pMaGV, pSiSoToiDa, 0, 'MO_DANG_KY');

    -- ======================================================
    -- 5. Sinh ma lich hoc + Them LICH HOC
    -- ======================================================
    SELECT IFNULL(MAX(CAST(SUBSTRING(MaLichHoc, 3) AS UNSIGNED)), 0) INTO vMaxLichHoc
    FROM LICHHOC WHERE MaLichHoc LIKE 'LH%';

    SET vMaLichHoc = CONCAT('LH', LPAD(vMaxLichHoc + 1, 3, '0'));

    INSERT INTO LICHHOC (MaLichHoc, MaLHP, MaPhong, Thu, TietBatDau, SoTiet)
    VALUES (vMaLichHoc, pMaLHP, pMaPhong, pThu, pTietBatDau, pSoTiet);

    -- ======================================================
    -- 6. Moi thu hop le -> COMMIT
    -- ======================================================
    COMMIT;
    SELECT 'Mo LHP va xep lich thanh cong.' AS KetQua;
END$$

DELIMITER ;

-- ==========================================================
-- DEMO CONCURRENCY TRUNG PHONG HOC (2 can bo cung xep 1 phong)
-- ==========================================================
-- Cua so 1:
-- START TRANSACTION;
--   SELECT * FROM LICHHOC WHERE MaPhong = 'P001' AND Thu = 2
--     AND TietBatDau < 4 AND TietBatDau + SoTiet > 1 FOR UPDATE;
--   DO SLEEP(10);
--   INSERT INTO LICHHOC (MaLichHoc, MaLHP, MaPhong, Thu, TietBatDau, SoTiet)
--   VALUES ('LH901', 'LHP901', 'P001', 2, 1, 3);
-- COMMIT;
-- Cua so 2 (chay trong luc cua so 1 giu khoa):
--   => BI CHAN (cho lock) toi khi cua so 1 COMMIT.

SELECT '[OK] Transaction mo LHP + xep lich (Atomicity) da tao.' AS KetLuan;
