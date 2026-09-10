-- ==========================================================
-- Ten file : mysql/transactions/demo_deadlock_chuafix.sql
-- Muc dich : ⚠️ BAN TRIEN KHAI **CO LOI** cua SP_DangKyNhieuHocPhan
--            (dung de DEMO DEADLOCK 1213 BANG THAO TAC THAT TREN WEB)
--
-- ★ LOI: con tro khoa cac dong si so theo DUNG THU TU SINH VIEN TICK CHON
--   (KhoaThuTu = 'B' + so thu tu), thay vi sap xep MaLHP tang dan.
--   => 2 sinh vien tick 2 lop NGUOC THU TU roi bam "Dang ky" cung luc
--      se tao chu trinh cho => InnoDB tra loi 1213 va rollback 1 giao dich.
--
-- CACH DEMO (goc do NGUOI DUNG — khong co man hinh demo nao):
--   1) Ap file nay len DB:
--        cd backend && node scripts/apply-sql.js ../mysql/transactions/demo_deadlock_chuafix.sql
--   2) Mo 2 trinh duyet: sv030/matkhau@123 va sv041/matkhau@123 -> trang "Dang ky lop hoc phan".
--      Ca hai tick DUNG 2 lop nhu nhau nhung theo thu tu NGUOC NHAU, roi bam
--      "Dang ky N lop da chon" gan nhu cung luc.
--      => 1 sinh vien nhan thong bao "Xung dot khoa (deadlock 1213) ...".
--   3) Khoi phuc BAN DA FIX:
--        cd backend && node scripts/apply-sql.js ../mysql/procedures/SP_DangKyNhieuHocPhan.sql
--      Lam lai thao tac tren => KHONG con deadlock.
--
-- ⚠️ Sau khi demo PHAI chay buoc 3 de dua he thong ve ban dung.
-- ==========================================================

DROP PROCEDURE IF EXISTS SP_DangKyNhieuHocPhan;

DELIMITER $$
CREATE PROCEDURE SP_DangKyNhieuHocPhan (
    IN  pMaSV        VARCHAR(12),
    IN  pDanhSachLHP VARCHAR(255),
    IN  pMaxTinChi   INT,
    IN  pGhiChu      VARCHAR(255),
    OUT pKetQua      INT
)
proc_dk_nhieu_chuafix: BEGIN
    DECLARE vConLai     VARCHAR(255);
    DECLARE vItem       VARCHAR(15);
    DECLARE vMaLHP      VARCHAR(15);
    DECLARE vThuTu      INT DEFAULT 0;
    DECLARE vMaHocKy    VARCHAR(10);
    DECLARE vMaMonHoc   VARCHAR(10);
    DECLARE vTrangThai  VARCHAR(30);
    DECLARE vSoTinChi   INT;
    DECLARE vSiSo       INT;
    DECLARE vSiSoToiDa  INT;
    DECLARE vTongTC     INT DEFAULT 0;
    DECLARE vLanDau     INT DEFAULT 1;
    DECLARE vCoDaHuy    INT DEFAULT 0;
    DECLARE vKhongThay  INT DEFAULT 0;
    DECLARE vHet        INT DEFAULT 0;
    DECLARE vErrno      INT DEFAULT 0;
    DECLARE vSoOK       INT DEFAULT 0;
    DECLARE vLoiCuoi    INT DEFAULT 0;
    DECLARE vChiTiet    VARCHAR(500) DEFAULT '';

    -- ❌ LOI: khoa theo dung thu tu nguoi dung tick chon
    DECLARE cur_dk CURSOR FOR
        SELECT MaLHP FROM TAM_DK_NHIEU ORDER BY KhoaThuTu;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET vHet = 1;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 vErrno = MYSQL_ERRNO;
        ROLLBACK;
        DROP TEMPORARY TABLE IF EXISTS TAM_DK_NHIEU;
        SET pKetQua = vErrno;
        SELECT pMaSV AS MaSV, vErrno AS MaLoi,
               'ROLLBACK — giao dich bi huy (deadlock/timeout)' AS KetThuc;
    END;

    IF pMaxTinChi IS NULL THEN SET pMaxTinChi = 24; END IF;
    SET pKetQua = 500;

    DROP TEMPORARY TABLE IF EXISTS TAM_DK_NHIEU;
    CREATE TEMPORARY TABLE TAM_DK_NHIEU (
        ThuTu     INT          NOT NULL,
        MaLHP     VARCHAR(15)  NOT NULL,
        KhoaThuTu VARCHAR(20)  NOT NULL,
        PRIMARY KEY (MaLHP)
    ) ENGINE=MEMORY;

    SET vConLai = TRIM(IFNULL(pDanhSachLHP, ''));
    WHILE vConLai <> '' DO
        SET vThuTu = vThuTu + 1;
        IF LOCATE(',', vConLai) > 0 THEN
            SET vItem   = TRIM(SUBSTRING_INDEX(vConLai, ',', 1));
            SET vConLai = TRIM(SUBSTRING(vConLai, LOCATE(',', vConLai) + 1));
        ELSE
            SET vItem   = TRIM(vConLai);
            SET vConLai = '';
        END IF;
        IF vItem <> '' THEN
            INSERT IGNORE INTO TAM_DK_NHIEU (ThuTu, MaLHP, KhoaThuTu)
            VALUES (vThuTu, vItem, CONCAT('B', LPAD(vThuTu, 6, '0')));   -- ❌ theo thu tu chon
        END IF;
    END WHILE;

    START TRANSACTION;

    OPEN cur_dk;
    dk_loop: LOOP
        FETCH cur_dk INTO vMaLHP;
        IF vHet = 1 THEN LEAVE dk_loop; END IF;

        SET vLoiCuoi = 0;

        BEGIN
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET vKhongThay = 1;
            SET vKhongThay = 0;
            SELECT lhp.SiSoHienTai, lhp.SiSoToiDa, lhp.MaHocKy, lhp.MaMonHoc,
                   lhp.TrangThaiLop, mh.SoTinChi
            INTO   vSiSo, vSiSoToiDa, vMaHocKy, vMaMonHoc, vTrangThai, vSoTinChi
            FROM LOPHOCPHAN lhp
            JOIN MONHOC mh ON mh.MaMonHoc = lhp.MaMonHoc
            WHERE lhp.MaLHP = vMaLHP
            FOR UPDATE;
        END;

        IF vKhongThay = 1 OR vTrangThai IS NULL OR vTrangThai <> 'MO_DANG_KY' THEN
            SET vLoiCuoi = 106;
        ELSEIF EXISTS (SELECT 1 FROM DANGKYHOCPHAN
                       WHERE MaSV = pMaSV AND MaLHP = vMaLHP
                         AND TrangThaiDangKy IN ('DA_DANG_KY','CHO_DUYET')) THEN
            SET vLoiCuoi = 101;
        ELSEIF FN_KiemTraTienQuyet(pMaSV, vMaMonHoc) = 0 THEN
            SET vLoiCuoi = 102;
        ELSEIF FN_KiemTraTrungLichHoc(pMaSV, vMaLHP) = 1 THEN
            SET vLoiCuoi = 103;
        ELSE
            BEGIN
                IF vLanDau = 1 THEN
                    SET vTongTC = FN_TinhTongTinChi(pMaSV, vMaHocKy);
                    SET vLanDau = 0;
                END IF;
                IF (vTongTC + vSoTinChi) > pMaxTinChi THEN
                    SET vLoiCuoi = 104;
                ELSEIF vSiSo >= vSiSoToiDa THEN
                    SET vLoiCuoi = 105;
                ELSE
                    SELECT COUNT(*) INTO vCoDaHuy FROM DANGKYHOCPHAN
                    WHERE MaSV = pMaSV AND MaLHP = vMaLHP AND TrangThaiDangKy = 'DA_HUY';

                    IF vCoDaHuy > 0 THEN
                        UPDATE DANGKYHOCPHAN
                        SET TrangThaiDangKy = 'DA_DANG_KY',
                            NgayDangKy = NOW(), GhiChu = pGhiChu
                        WHERE MaSV = pMaSV AND MaLHP = vMaLHP;
                    ELSE
                        INSERT INTO DANGKYHOCPHAN
                            (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
                        VALUES (pMaSV, vMaLHP, NOW(), 'DA_DANG_KY', pGhiChu);
                    END IF;

                    SET vTongTC = vTongTC + vSoTinChi;
                    SET vSoOK   = vSoOK + 1;
                END IF;
            END;
        END IF;

        SET vChiTiet = CONCAT(vChiTiet, IF(vChiTiet='','','; '), vMaLHP, ':',
                              IF(vLoiCuoi = 0, 'OK', CAST(vLoiCuoi AS CHAR)));
    END LOOP;
    CLOSE cur_dk;

    IF vSoOK = 0 THEN
        ROLLBACK;
        SET pKetQua = IF(vLoiCuoi = 0, 106, vLoiCuoi);
    ELSE
        COMMIT;
        SET pKetQua = 0;
    END IF;

    DROP TEMPORARY TABLE IF EXISTS TAM_DK_NHIEU;

    SELECT pMaSV AS MaSV, vSoOK AS SoDangKyThanhCong,
           vChiTiet AS ChiTiet, IF(pKetQua = 0, 'COMMIT', 'ROLLBACK') AS KetThuc;
END$$

DELIMITER ;

SELECT '[!] DA TRIEN KHAI BAN CO LOI (khoa theo thu tu tick chon) — nho chay lai mysql/procedures/SP_DangKyNhieuHocPhan.sql sau khi demo xong' AS CanhBao;
