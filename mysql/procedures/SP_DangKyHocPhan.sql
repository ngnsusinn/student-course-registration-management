-- ==========================================================
-- Ten file : mysql/procedures/SP_DangKyHocPhan.sql
-- Module   : Dang ky hoc phan (TV3 — Leader)
-- Mo ta    : Ban dich T-SQL -> MySQL. Gom DU 5 BUOC KIEM TRA:
--              1. Con han dang ky (dot mo)
--              2. Chua dang ky trung LHP
--              3. Da dat mon tien quyet
--              4. Khong trung lich hoc
--              5. Chua vuot gioi han tin chi + Lop con cho
--            UPDLOCK/HOLDLOCK -> SELECT ... FOR UPDATE.
-- Ma loi pKetQua:
--   0=OK, 100=Het han, 101=Trung LHP, 102=Thieu tien quyet,
--   103=Trung lich, 104=Vuot tin chi, 105=Lop day,
--   106=LHP khong ton tai/khong mo, 500=Loi he thong
-- ==========================================================

DROP PROCEDURE IF EXISTS SP_DangKyHocPhan;

DELIMITER $$

CREATE PROCEDURE SP_DangKyHocPhan (
    IN  pMaSV      VARCHAR(12),
    IN  pMaLHP     VARCHAR(15),
    IN  pMaxTinChi INT,
    IN  pGhiChu    VARCHAR(255),
    OUT pKetQua    INT
)
proc_dangky: BEGIN
    DECLARE vMaHocKy      VARCHAR(10);
    DECLARE vMaMonHoc     VARCHAR(10);
    DECLARE vSoTinChiMH   INT;
    DECLARE vTrangThaiLop VARCHAR(30);
    DECLARE vSiSoHienTai  INT;
    DECLARE vSiSoToiDa    INT;
    DECLARE vTongTinChiDa INT;
    DECLARE vNotFound     INT DEFAULT 0;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET vNotFound = 1;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET pKetQua = 500;
    END;

    IF pMaxTinChi IS NULL THEN
        SET pMaxTinChi = 24;
    END IF;

    SET pKetQua = 500;

    START TRANSACTION;

    -- ====================================================
    -- BUOC 0: XAC THUC LHP TON TAI & DANG MO DANG KY
    -- ====================================================
    SELECT
        lhp.MaHocKy, lhp.MaMonHoc, mh.SoTinChi, lhp.TrangThaiLop
    INTO
        vMaHocKy, vMaMonHoc, vSoTinChiMH, vTrangThaiLop
    FROM LOPHOCPHAN lhp
    JOIN MONHOC mh ON mh.MaMonHoc = lhp.MaMonHoc
    WHERE lhp.MaLHP = pMaLHP;

    IF vNotFound = 1 THEN
        SET pKetQua = 106;
        ROLLBACK;
        LEAVE proc_dangky;
    END IF;

    IF vTrangThaiLop <> 'MO_DANG_KY' THEN
        SET pKetQua = 106;
        ROLLBACK;
        LEAVE proc_dangky;
    END IF;

    -- ====================================================
    -- BUOC 1: KIEM TRA HAN DANG KY
    -- ====================================================
    IF FN_KiemTraDotDangKy() = 0 THEN
        SET pKetQua = 100;
        ROLLBACK;
        LEAVE proc_dangky;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM HOCKY
        WHERE MaHocKy = vMaHocKy
          AND TrangThaiDot = 'MO'
          AND NOW() BETWEEN TuNgay AND DenNgay
    ) THEN
        SET pKetQua = 100;
        ROLLBACK;
        LEAVE proc_dangky;
    END IF;

    -- ====================================================
    -- BUOC 2: KIEM TRA DANG KY TRUNG LHP
    -- ====================================================
    IF EXISTS (
        SELECT 1 FROM DANGKYHOCPHAN
        WHERE MaSV = pMaSV AND MaLHP = pMaLHP
    ) THEN
        SET pKetQua = 101;
        ROLLBACK;
        LEAVE proc_dangky;
    END IF;

    -- ====================================================
    -- BUOC 3: KIEM TRA MON TIEN QUYET
    -- ====================================================
    IF FN_KiemTraTienQuyet(pMaSV, vMaMonHoc) = 0 THEN
        SET pKetQua = 102;
        ROLLBACK;
        LEAVE proc_dangky;
    END IF;

    -- ====================================================
    -- BUOC 4: KIEM TRA TRUNG LICH HOC
    -- ====================================================
    IF FN_KiemTraTrungLichHoc(pMaSV, pMaLHP) = 1 THEN
        SET pKetQua = 103;
        ROLLBACK;
        LEAVE proc_dangky;
    END IF;

    -- ====================================================
    -- BUOC 5: KIEM TRA GIOI HAN TIN CHI
    -- ====================================================
    SET vTongTinChiDa = FN_TinhTongTinChi(pMaSV, vMaHocKy);
    IF (vTongTinChiDa + vSoTinChiMH) > pMaxTinChi THEN
        SET pKetQua = 104;
        ROLLBACK;
        LEAVE proc_dangky;
    END IF;

    -- ====================================================
    -- BUOC 6: KIEM TRA SI SO & GHI NHAN (ATOMIC, CHONG LOST UPDATE)
    --   SELECT ... FOR UPDATE giu khoa dong toi khi COMMIT.
    -- ====================================================
    SELECT SiSoHienTai, SiSoToiDa
    INTO vSiSoHienTai, vSiSoToiDa
    FROM LOPHOCPHAN
    WHERE MaLHP = pMaLHP
    FOR UPDATE;

    IF vSiSoHienTai >= vSiSoToiDa THEN
        SET pKetQua = 105;
        ROLLBACK;
        LEAVE proc_dangky;
    END IF;

    INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
    VALUES (pMaSV, pMaLHP, NOW(), 'DA_DANG_KY', pGhiChu);

    SET pKetQua = 0;

    COMMIT;
END$$

DELIMITER ;
