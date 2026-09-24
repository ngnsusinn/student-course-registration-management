DROP PROCEDURE IF EXISTS SP_DangKyHocPhan;

DELIMITER $$

CREATE PROCEDURE SP_DangKyHocPhan (
    IN  pMaSV      VARCHAR(12),
    IN  pMaLHP     VARCHAR(15),
    IN  pMaxTinChi INT,
    IN  pGhiChu    VARCHAR(255),
    OUT pKetQua    INT
)
proc_dangky_chuafix: BEGIN
    DECLARE vMaHocKy      VARCHAR(10);
    DECLARE vMaMonHoc     VARCHAR(10);
    DECLARE vSoTinChiMH   INT;
    DECLARE vTrangThaiLop VARCHAR(30);
    DECLARE vSiSoHienTai  INT;
    DECLARE vSiSoToiDa    INT;
    DECLARE vTongTinChiDa INT;
    DECLARE vNotFound     INT DEFAULT 0;
    DECLARE vDoTreGiay    INT DEFAULT 8;

    IF pMaxTinChi IS NULL THEN SET pMaxTinChi = 24; END IF;
    SET pKetQua = 500;

    START TRANSACTION;

    -- STEP 1
    SELECT lhp.MaHocKy, lhp.MaMonHoc, mh.SoTinChi, lhp.TrangThaiLop
    INTO vMaHocKy, vMaMonHoc, vSoTinChiMH, vTrangThaiLop
    FROM LOPHOCPHAN lhp JOIN MONHOC mh ON mh.MaMonHoc = lhp.MaMonHoc
    WHERE lhp.MaLHP = pMaLHP;

    IF vTrangThaiLop <> 'MO_DANG_KY' THEN SET pKetQua = 106; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;
    IF FN_KiemTraDotDangKy() = 0 THEN SET pKetQua = 100; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;
    IF NOT EXISTS (SELECT 1 FROM HOCKY WHERE MaHocKy = vMaHocKy AND TrangThaiDot = 'MO' AND NOW() BETWEEN TuNgay AND DenNgay)
    THEN SET pKetQua = 100; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;

    -- STEP 2: Duplicate check
    IF EXISTS (SELECT 1 FROM DANGKYHOCPHAN WHERE MaSV = pMaSV AND MaLHP = pMaLHP AND TrangThaiDangKy IN ('DA_DANG_KY','CHO_DUYET'))
    THEN SET pKetQua = 101; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;

    IF FN_KiemTraTienQuyet(pMaSV, vMaMonHoc) = 0 THEN SET pKetQua = 102; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;
    IF FN_KiemTraTrungLichHoc(pMaSV, pMaLHP) = 1 THEN SET pKetQua = 103; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;

    SET vTongTinChiDa = FN_TinhTongTinChi(pMaSV, vMaHocKy);
    IF (vTongTinChiDa + vSoTinChiMH) > pMaxTinChi THEN SET pKetQua = 104; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;

    -- STEP 3: Read SiSo WITHOUT FOR UPDATE
    SELECT SiSoHienTai, SiSoToiDa INTO vSiSoHienTai, vSiSoToiDa FROM LOPHOCPHAN WHERE MaLHP = pMaLHP;

    IF vSiSoHienTai >= vSiSoToiDa THEN SET pKetQua = 105; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;

    -- STEP 4: INSERT
    INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu) VALUES (pMaSV, pMaLHP, NOW(), 'DA_DANG_KY', pGhiChu);

    -- STEP 5: SLEEP
    DO SLEEP(vDoTreGiay);

    SET pKetQua = 0;
    COMMIT;
END$$
DELIMITER ;
