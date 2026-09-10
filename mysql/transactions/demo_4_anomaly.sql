-- ==========================================================
-- Ten file : mysql/transactions/demo_4_anomaly.sql
-- Module   : Dang ky hoc phan (TV3 — Leader)
-- Muc dich : DEMO 4 LOI CONCURRENCY (Chuong 5):
--              1. Lost Update        (Cap nhat mat)
--              2. Dirty Read         (Doc ban)
--              3. Unrepeatable Read  (Doc khong lap lai)
--              4. Phantom Read       (Doc bong ma)
--   - SP_DangKyHocPhan_ChuaFix : "THU TUC BAN DAU CHUA FIX LOI"
--       (giong het SP_DangKyHocPhan nhung THIEU SELECT...FOR UPDATE
--        -> 2 phien giành chỗ cuối cùng bị LOST UPDATE)
--   - SP_ChuanBi_Demo_4Anomaly : dua LHP514 ve trang thai con dung 1 cho
--   - SP_DangKyHocPhan_NangCao : phien ban PHONG CHONG DAY DU
--       (FOR UPDATE + SERIALIZABLE cho phan doc si so)
--
-- VI SAO PHAI "TAT" PHONG CHONG CUA MYSQL?
--   MySQL/InnoDB mac dinh chay o muc REPEATABLE READ:
--     - Chan san Dirty Read
--     - Chan san Unrepeatable Read
--     - Chan phantom voi SELECT thong thuong (snapshot)
--   -> Muon demo/cho thay 4 loi, phai ha muc co lap xuong:
--        SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  -- mo Dirty Read
--        SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;    -- mo Unrepeatable + Phantom
--      va dung thu tuc "ChuaFix" (khong FOR UPDATE) cho Lost Update.
--
-- CACH DEMO (2 cua so mysql client / Workbench ket noi rieng):
--   Phan 0: chay file nay 1 lan de tao 3 SP (ca 2 cua so deu dung duoc).
--   Phan A.1..A.5: script SQL day du (copy-paste) tai
--       docs/concurrency/script_demo_sql.md   (PHAN A)
-- ==========================================================

-- ==========================================================
-- 1) THU TUC BAN DAU CHUA FIX LOI (khong co FOR UPDATE)
--    Y het SP_DangKyHocPhan, chi khac buoc 6: doc SiSo khong khoa.
-- ==========================================================
DROP PROCEDURE IF EXISTS SP_DangKyHocPhan_ChuaFix;

DELIMITER $$
CREATE PROCEDURE SP_DangKyHocPhan_ChuaFix (
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

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET vNotFound = 1;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET pKetQua = 500;
    END;

    IF pMaxTinChi IS NULL THEN SET pMaxTinChi = 24; END IF;
    SET pKetQua = 500;

    START TRANSACTION;

    SELECT lhp.MaHocKy, lhp.MaMonHoc, mh.SoTinChi, lhp.TrangThaiLop
    INTO vMaHocKy, vMaMonHoc, vSoTinChiMH, vTrangThaiLop
    FROM LOPHOCPHAN lhp JOIN MONHOC mh ON mh.MaMonHoc = lhp.MaMonHoc
    WHERE lhp.MaLHP = pMaLHP;

    IF vNotFound = 1 THEN SET pKetQua = 106; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;
    IF vTrangThaiLop <> 'MO_DANG_KY' THEN SET pKetQua = 106; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;

    IF FN_KiemTraDotDangKy() = 0 THEN SET pKetQua = 100; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;

    IF NOT EXISTS (SELECT 1 FROM HOCKY
                   WHERE MaHocKy = vMaHocKy AND TrangThaiDot = 'MO'
                     AND NOW() BETWEEN TuNgay AND DenNgay)
    THEN SET pKetQua = 100; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;

    IF EXISTS (SELECT 1 FROM DANGKYHOCPHAN WHERE MaSV = pMaSV AND MaLHP = pMaLHP)
    THEN SET pKetQua = 101; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;

    IF FN_KiemTraTienQuyet(pMaSV, vMaMonHoc) = 0 THEN SET pKetQua = 102; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;

    IF FN_KiemTraTrungLichHoc(pMaSV, pMaLHP) = 1 THEN SET pKetQua = 103; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;

    SET vTongTinChiDa = FN_TinhTongTinChi(pMaSV, vMaHocKy);
    IF (vTongTinChiDa + vSoTinChiMH) > pMaxTinChi THEN SET pKetQua = 104; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;

    -- ===== DIEM KHAC BIET VOI BAN "DA FIX": KHONG FOR UPDATE =====
    SELECT SiSoHienTai, SiSoToiDa
    INTO vSiSoHienTai, vSiSoToiDa
    FROM LOPHOCPHAN
    WHERE MaLHP = pMaLHP;      -- doc thuong: khong khoa, hai phien doc cung 1 gia tri

    IF vSiSoHienTai >= vSiSoToiDa THEN SET pKetQua = 105; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;

    INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
    VALUES (pMaSV, pMaLHP, NOW(), 'DA_DANG_KY', pGhiChu);

    SET pKetQua = 0;
    COMMIT;
END$$
DELIMITER ;

-- ==========================================================
-- 2) THU TUC CHUAN BI: dua 1 LHP ve "con dung 1 cho" de demo
--    Cach dung: CALL SP_ChuanBi_Demo_4Anomaly('LHP514');
-- ==========================================================
DROP PROCEDURE IF EXISTS SP_ChuanBi_Demo_4Anomaly;

DELIMITER $$
CREATE PROCEDURE SP_ChuanBi_Demo_4Anomaly (IN pMaLHP VARCHAR(15))
BEGIN
    DELETE FROM DANGKYHOCPHAN WHERE MaLHP = pMaLHP AND MaSV IN ('SV030','SV041','SV060','SV999');
    UPDATE LOPHOCPHAN lhp
    SET lhp.SiSoHienTai = (
        SELECT COUNT(*) FROM DANGKYHOCPHAN d
        WHERE d.MaLHP = lhp.MaLHP AND d.TrangThaiDangKy = 'DA_DANG_KY'
    )
    WHERE lhp.MaLHP = pMaLHP;
    UPDATE LOPHOCPHAN SET SiSoToiDa = SiSoHienTai + 1 WHERE MaLHP = pMaLHP;
    SELECT MaLHP, SiSoHienTai, SiSoToiDa, (SiSoToiDa - SiSoHienTai) AS ConTrong
    FROM LOPHOCPHAN WHERE MaLHP = pMaLHP;
END$$
DELIMITER ;

-- ==========================================================
-- 3) THU TUC PHONG CHONG NANG CAO:
--    khoi dong SERIALIZABLE cho phan doc cuoi + FOR UPDATE chan hanh,
--    minh hoa "chan ca phantom" tren dong si so (khóa range).
-- ==========================================================
DROP PROCEDURE IF EXISTS SP_DangKyHocPhan_NangCao;

DELIMITER $$
CREATE PROCEDURE SP_DangKyHocPhan_NangCao (
    IN  pMaSV      VARCHAR(12),
    IN  pMaLHP     VARCHAR(15),
    IN  pMaxTinChi INT,
    IN  pGhiChu    VARCHAR(255),
    OUT pKetQua    INT
)
proc_dangky_nangcao: BEGIN
    DECLARE vSiSoHienTai INT;
    DECLARE vSiSoToiDa   INT;
    DECLARE vNotFound    INT DEFAULT 0;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET vNotFound = 1;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET pKetQua = 500;
    END;

    IF pMaxTinChi IS NULL THEN SET pMaxTinChi = 24; END IF;
    SET pKetQua = 500;

    START TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM LOPHOCPHAN WHERE MaLHP = pMaLHP AND TrangThaiLop = 'MO_DANG_KY')
    THEN SET pKetQua = 106; ROLLBACK; LEAVE proc_dangky_nangcao; END IF;

    IF EXISTS (SELECT 1 FROM DANGKYHOCPHAN WHERE MaSV = pMaSV AND MaLHP = pMaLHP)
    THEN SET pKetQua = 101; ROLLBACK; LEAVE proc_dangky_nangcao; END IF;

    -- KHOA DIEU KIEN (khoa range dong + gap): phien khac khong INSERT/DELETE
    -- vao tap hop cac dong LOPHOCPHAN dang doc cho toi khi COMMIT.
    -- MySQL 8.0 co the dung `FOR SHARE` (S-lock giu den COMMIT = doc SERIALIZABLE);
    -- MySQL 5.7 khong co FOR SHARE -> dung FOR UPDATE (X-lock), hieu qua tuong duong
    -- cho bai toan nay. Hoac: SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE
    -- truoc khi CALL (demo 2 cua so trong docs/concurrency/concurrency_anomaly_demo.md).
    SELECT SiSoHienTai, SiSoToiDa
    INTO vSiSoHienTai, vSiSoToiDa
    FROM LOPHOCPHAN
    WHERE MaLHP = pMaLHP
    FOR UPDATE;

    IF vNotFound = 1 THEN SET pKetQua = 106; ROLLBACK; LEAVE proc_dangky_nangcao; END IF;

    IF vSiSoHienTai >= vSiSoToiDa THEN SET pKetQua = 105; ROLLBACK; LEAVE proc_dangky_nangcao; END IF;

    INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
    VALUES (pMaSV, pMaLHP, NOW(), 'DA_DANG_KY', pGhiChu);

    SET pKetQua = 0;
    COMMIT;
END$$
DELIMITER ;

SELECT '[OK] Da tao 3 SP demo: SP_DangKyHocPhan_ChuaFix, SP_ChuanBi_Demo_4Anomaly, SP_DangKyHocPhan_NangCao' AS KetLuan;
