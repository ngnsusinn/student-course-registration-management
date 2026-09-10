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
--
-- ★ FIX DEADLOCK (Chuong 5) — KHOA THEO THU TU NHAT QUAN:
--   Ban CU doc DANGKYHOCPHAN truoc (JOIN ... FOR UPDATE), roi trigger moi
--   cap nhat LOPHOCPHAN  =>  thu tu khoa: DANGKYHOCPHAN -> LOPHOCPHAN.
--   SP_DangKyHocPhan (buoc 6) lai khoa LOPHOCPHAN truoc roi moi ghi
--   DANGKYHOCPHAN        =>  thu tu khoa: LOPHOCPHAN -> DANGKYHOCPHAN.
--   Hai thu tu NGUOC NHAU: khi 1 SV duoc DANG KY LAI (tai su dung dong
--   DA_HUY) o phien A, dong thoi bi HUY o phien B, InnoDB bao
--   ER_LOCK_DEADLOCK (1213). Da kiem chung thuc te tren MySQL 5.7.41
--   (xem docs/concurrency/script_demo_sql.md — PHAN B.4).
--   => Ban MOI chu dong khoa LOPHOCPHAN TRUOC, dua CA HAI thu tuc ve cung
--      mot thu tu khoa => triet tieu deadlock.
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
    DECLARE vSiSoHienTai       INT;
    DECLARE vSiSoToiDa         INT;
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
    -- BUOC 2: KHOA THEO THU TU NHAT QUAN (chong deadlock)
    --   (2a) Khoa LOPHOCPHAN TRUOC  — cung thu tu voi SP_DangKyHocPhan
    --   (2b) Roi moi doc/khoa DANGKYHOCPHAN
    --   => Khong con chu trinh cho doi voi nghiep vu dang ky.
    -- ====================================================
    SELECT SiSoHienTai, SiSoToiDa INTO vSiSoHienTai, vSiSoToiDa
    FROM LOPHOCPHAN
    WHERE MaLHP = pMaLHP
    FOR UPDATE;

    -- (Neu LHP khong ton tai: vNotFound = 1 va buoc duoi tra 201.)

    SELECT dk.TrangThaiDangKy INTO vTrangThaiHienTai
    FROM DANGKYHOCPHAN dk
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
