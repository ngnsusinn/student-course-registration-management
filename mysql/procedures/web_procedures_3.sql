-- ==========================================================
-- Ten file : mysql/procedures/web_procedures_3.sql
-- Muc dich : BO SUNG 2 THU TUC GIAO TAC (TRANSACTION NAM TRONG DB)
--
-- ★ NGUYEN TAC CUA HE THONG:
--   MOI GIAO TAC (START TRANSACTION / COMMIT / ROLLBACK) DEU NAM TRONG
--   STORED PROCEDURE. Tang web (Node.js) CHI GOI `CALL SP_...` —
--   KHONG tu mo giao tac, KHONG chay raw query.
--
--   Truoc day 2 nghiep vu duoi day bi lap trinh o tang Node
--   (conn.beginTransaction() + nhieu CALL) — vua vi pham nguyen tac,
--   vua SAI ve nghiep vu vi SP_GV_NHAP_DIEM da tu COMMIT ben trong.
--   Nay dua han vao DB:
--     1. SP_ThemMonHocVaTienQuyet  — them mon + cac mon tien quyet (1 giao tac)
--     2. SP_GV_NhapDiemHangLoat    — nhap diem ca lop (1 giao tac, loi 1 dong
--                                    => ROLLBACK toan bo)
-- ==========================================================

-- ==========================================================
-- 1. SP_ThemMonHocVaTienQuyet
--    Them 1 mon hoc moi + danh sach mon tien quyet trong CUNG 1 GIAO TAC.
--    pDanhSachTienQuyet: chuoi CSV, vi du 'MH001,MH002' (rong = khong co).
--    Loi bat ky (trung ma mon, ma khoa sai, trung tien quyet...) => ROLLBACK.
-- ==========================================================
DROP PROCEDURE IF EXISTS SP_ThemMonHocVaTienQuyet;

DELIMITER $$
CREATE PROCEDURE SP_ThemMonHocVaTienQuyet (
    IN pMaMonHoc       VARCHAR(10),
    IN pTenMonHoc      VARCHAR(100),
    IN pSoTinChi       TINYINT,
    IN pSoTietLyThuyet SMALLINT,
    IN pSoTietThucHanh SMALLINT,
    IN pMaKhoa         VARCHAR(10),
    IN pDanhSachTienQuyet VARCHAR(255)
)
proc_them_mon: BEGIN
    DECLARE vConLai VARCHAR(255);
    DECLARE vItem   VARCHAR(10);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;          -- tra nguyen thong bao loi cho tang goi
    END;

    START TRANSACTION;

    INSERT INTO MONHOC (MaMonHoc, TenMonHoc, SoTinChi, SoTietLyThuyet, SoTietThucHanh, MaKhoa)
    VALUES (pMaMonHoc, pTenMonHoc, pSoTinChi, IFNULL(pSoTietLyThuyet, 0),
            IFNULL(pSoTietThucHanh, 0), pMaKhoa);

    SET vConLai = TRIM(IFNULL(pDanhSachTienQuyet, ''));
    WHILE vConLai <> '' DO
        IF LOCATE(',', vConLai) > 0 THEN
            SET vItem   = TRIM(SUBSTRING_INDEX(vConLai, ',', 1));
            SET vConLai = TRIM(SUBSTRING(vConLai, LOCATE(',', vConLai) + 1));
        ELSE
            SET vItem   = TRIM(vConLai);
            SET vConLai = '';
        END IF;

        IF vItem <> '' THEN
            INSERT INTO MONHOC_TIENQUYET (MaMonHoc, MaMonTienQuyet)
            VALUES (pMaMonHoc, vItem);
        END IF;
    END WHILE;

    COMMIT;

    SELECT pMaMonHoc AS MaMonHoc, 'COMMIT' AS KetThuc;
END$$

DELIMITER ;

-- ==========================================================
-- 2. SP_GV_NhapDiemHangLoat
--    Nhap diem cho CA LOP trong MOT GIAO TAC (dung CON TRO de duyet).
--    pDanhSachDiem: chuoi ma hoa 'MaSV:CC:GK:CK;MaSV:CC:GK:CK;...'
--      - luon du 4 truong; truong diem de TRONG = diem NULL.
--      - vi du: 'SV001:8.5:7:9;SV002:::6.5'
--    Kiem tra tung dong giong SP_GV_NHAP_DIEM; BAT KY dong nao loi
--    => SIGNAL + ROLLBACK => ca lo KHONG duoc ghi (nguyen tu that su).
--    Trigger TRG_KETQUAHOCTAP_TinhDiem tu tinh DiemTongKet/Chu/He4.
-- ==========================================================
DROP PROCEDURE IF EXISTS SP_GV_NhapDiemHangLoat;

DELIMITER $$
CREATE PROCEDURE SP_GV_NhapDiemHangLoat (
    IN pMaGV        VARCHAR(10),
    IN pMaLHP       VARCHAR(15),
    IN pDanhSachDiem TEXT
)
proc_nhap_diem_loat: BEGIN
    DECLARE vConLai   TEXT;
    DECLARE vBanGhi   VARCHAR(60);
    DECLARE vMaSV     VARCHAR(12);
    DECLARE vCC       VARCHAR(10);
    DECLARE vGK       VARCHAR(10);
    DECLARE vCK       VARCHAR(10);
    DECLARE vDiemCC   DECIMAL(4,2);
    DECLARE vDiemGK   DECIMAL(4,2);
    DECLARE vDiemCK   DECIMAL(4,2);
    DECLARE vHet      INT DEFAULT 0;
    DECLARE vSoDong   INT DEFAULT 0;

    -- ★ CON TRO: duyet lan luot tung dong diem da tach vao bang tam
    DECLARE cur_diem CURSOR FOR
        SELECT MaSV, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy FROM TAM_DIEM_LO;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET vHet = 1;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        DROP TEMPORARY TABLE IF EXISTS TAM_DIEM_LO;
        RESIGNAL;
    END;

    -- ===== Kiem tra dau vao (ngoai giao tac) =====
    IF NOT EXISTS (SELECT 1 FROM GIANGVIEN WHERE MaGV = pMaGV) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Giảng viên không tồn tại.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM LOPHOCPHAN WHERE MaLHP = pMaLHP AND MaGV = pMaGV) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Giảng viên không phụ trách lớp học phần này.';
    END IF;

    -- ===== Tach chuoi 'MaSV:CC:GK:CK;...' vao bang tam =====
    DROP TEMPORARY TABLE IF EXISTS TAM_DIEM_LO;
    CREATE TEMPORARY TABLE TAM_DIEM_LO (
        MaSV          VARCHAR(12)  NOT NULL,
        DiemChuyenCan DECIMAL(4,2) NULL,
        DiemGiuaKy    DECIMAL(4,2) NULL,
        DiemCuoiKy    DECIMAL(4,2) NULL,
        PRIMARY KEY (MaSV)
    ) ENGINE=MEMORY;

    SET vConLai = TRIM(IFNULL(pDanhSachDiem, ''));
    WHILE vConLai <> '' DO
        IF LOCATE(';', vConLai) > 0 THEN
            SET vBanGhi = TRIM(SUBSTRING_INDEX(vConLai, ';', 1));
            SET vConLai = SUBSTRING(vConLai, LOCATE(';', vConLai) + 1);
        ELSE
            SET vBanGhi = TRIM(vConLai);
            SET vConLai = '';
        END IF;

        IF vBanGhi <> '' THEN
            SET vMaSV = TRIM(SUBSTRING_INDEX(vBanGhi, ':', 1));
            SET vCC   = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(vBanGhi, ':', 2), ':', -1));
            SET vGK   = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(vBanGhi, ':', 3), ':', -1));
            SET vCK   = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(vBanGhi, ':', 4), ':', -1));

            IF vMaSV <> '' THEN
                INSERT IGNORE INTO TAM_DIEM_LO (MaSV, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy)
                VALUES (vMaSV,
                        IF(vCC = '', NULL, CAST(vCC AS DECIMAL(4,2))),
                        IF(vGK = '', NULL, CAST(vGK AS DECIMAL(4,2))),
                        IF(vCK = '', NULL, CAST(vCK AS DECIMAL(4,2))));
            END IF;
        END IF;
    END WHILE;

    -- ===== Ghi trong MOT giao tac =====
    START TRANSACTION;

    OPEN cur_diem;
    nhap_loop: LOOP
        FETCH cur_diem INTO vMaSV, vDiemCC, vDiemGK, vDiemCK;
        IF vHet = 1 THEN LEAVE nhap_loop; END IF;

        IF vDiemCC IS NOT NULL AND (vDiemCC < 0 OR vDiemCC > 10) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Điểm chuyên cần phải nằm trong khoảng từ 0 đến 10.';
        END IF;
        IF vDiemGK IS NOT NULL AND (vDiemGK < 0 OR vDiemGK > 10) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Điểm giữa kỳ phải nằm trong khoảng từ 0 đến 10.';
        END IF;
        IF vDiemCK IS NOT NULL AND (vDiemCK < 0 OR vDiemCK > 10) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Điểm thi phải nằm trong khoảng từ 0 đến 10.';
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM DANGKYHOCPHAN
            WHERE MaSV = vMaSV AND MaLHP = pMaLHP AND TrangThaiDangKy = 'DA_DANG_KY'
        ) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Sinh viên chưa đăng ký lớp học phần này.';
        END IF;

        IF EXISTS (SELECT 1 FROM KETQUAHOCTAP WHERE MaSV = vMaSV AND MaLHP = pMaLHP) THEN
            UPDATE KETQUAHOCTAP
            SET DiemChuyenCan = vDiemCC, DiemGiuaKy = vDiemGK, DiemCuoiKy = vDiemCK
            WHERE MaSV = vMaSV AND MaLHP = pMaLHP;
        ELSE
            INSERT INTO KETQUAHOCTAP (MaSV, MaLHP, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy)
            VALUES (vMaSV, pMaLHP, vDiemCC, vDiemGK, vDiemCK);
        END IF;

        SET vSoDong = vSoDong + 1;
    END LOOP;
    CLOSE cur_diem;

    DROP TEMPORARY TABLE IF EXISTS TAM_DIEM_LO;

    COMMIT;

    SELECT pMaLHP AS MaLHP, vSoDong AS SoDongDaNhap, 'COMMIT' AS KetThuc;
END$$

DELIMITER ;

SELECT '[OK] Da tao 2 SP giao tac: SP_ThemMonHocVaTienQuyet, SP_GV_NhapDiemHangLoat' AS KetLuan;
