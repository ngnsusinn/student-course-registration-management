-- ==========================================================
-- Ten file : mysql/transactions/demo_deadlock.sql
-- Module   : Dang ky hoc phan (TV3 — Leader)
-- Chuong   : 5 — Dieu khien canh tranh (DEADLOCK & CACH PHONG CHONG)
-- Muc dich : Bo thu tuc phuc vu DEMO DEADLOCK o CA HAI GOC DO:
--              (A) TRUC TIEP TREN HQTCSDL  -> SP_Demo_KhoaTheoThuTu,
--                  SP_Demo_PhienGiaoDich  (2 cua so mysql client)
--              (B) GOC DO NGUOI DUNG (web) -> dung SP THAT
--                  SP_DangKyNhieuHocPhan (mysql/procedures/) va ban CO LOI
--                  (mysql/transactions/demo_deadlock_chuafix.sql).
--                  KHONG co man hinh demo nao — demo bang thao tac that
--                  tren trang "Dang ky lop hoc phan" cua sinh vien.
--
-- ★ DIEM NHAN SU PHAM: moi thu tuc duoi day deu dung CON TRO (CURSOR)
--   de duyet danh sach MaLHP va KHOA LAN LUOT tung dong LOPHOCPHAN
--   bang SELECT ... FOR UPDATE. Thu tu duyet cua con tro chinh la
--   "thu tu khoa" (lock ordering) — dung nguyen nhan gay deadlock
--   va cung chinh la cach phong chong deadlock.
--
-- ★ HAI CHE DO KHOA (tham so pKieuKhoa cua SP_Demo_KhoaTheoThuTu):
--     'THEO_YEU_CAU' : khoa theo DUNG thu tu nguoi dung gui len
--                      -> 2 phien gui nguoc nhau => DEADLOCK  (ban CHUA FIX)
--     'SAP_XEP'      : khoa theo MaLHP TANG DAN (consistent ordering)
--                      -> moi phien cung thu tu => KHONG deadlock (ban DA FIX)
--
-- Ma loi tra ve (pKetQua):
--     0    = thanh cong
--     1213 = ER_LOCK_DEADLOCK      (InnoDB tu chon nan nhan & rollback)
--     1205 = ER_LOCK_WAIT_TIMEOUT  (cho khoa qua lau)
--     100..106 = ma nghiep vu (xem SP_DangKyHocPhan)
--     500  = loi he thong khac
--
-- Cach ap dung:
--     cd backend && node scripts/apply-sql.js ../mysql/transactions/demo_deadlock.sql
-- ==========================================================

-- ==========================================================
-- 1) SP_Demo_KhoaTheoThuTu — CON TRO khoa lan luot cac dong LOPHOCPHAN
--    (CHI KHOA, KHONG GHI DU LIEU -> an toan tuyet doi de chay di chay lai)
--
--    Dung cho: demo deadlock truc tiep tren HQTCSDL (2 cua so).
--
--    Goi:
--      CALL SP_Demo_KhoaTheoThuTu('SV030','LHP514,LHP506','THEO_YEU_CAU',3,@kq);
--      CALL SP_Demo_KhoaTheoThuTu('SV030','LHP514,LHP506','SAP_XEP',3,@kq);
--    Trong do 3 = so giay TRE giua moi lan khoa (mo rong cua so deadlock
--    de nhin thay ro tren man hinh).
-- ==========================================================
DROP PROCEDURE IF EXISTS SP_Demo_KhoaTheoThuTu;

DELIMITER $$
CREATE PROCEDURE SP_Demo_KhoaTheoThuTu (
    IN  pMaSV         VARCHAR(12),
    IN  pDanhSachLHP  VARCHAR(255),   -- CSV: 'LHP514,LHP506'
    IN  pKieuKhoa     VARCHAR(20),    -- 'THEO_YEU_CAU' | 'SAP_XEP'
    IN  pDoTreGiay    INT,            -- sleep giua cac lan khoa
    OUT pKetQua       INT
)
proc_demo_khoa: BEGIN
    DECLARE vConLai   VARCHAR(255);
    DECLARE vItem     VARCHAR(15);
    DECLARE vMaLHP    VARCHAR(15);
    DECLARE vThuTu    INT DEFAULT 0;
    DECLARE vSiSo     INT;
    DECLARE vToiDa    INT;
    DECLARE vKhongThay INT DEFAULT 0;
    DECLARE vErrno    INT DEFAULT 0;
    DECLARE vHet      INT DEFAULT 0;
    DECLARE vNhatKy   VARCHAR(255) DEFAULT '';

    -- ★ CON TRO: duyet danh sach LHP theo KHOA SAP XEP da tinh san
    DECLARE cur_khoa CURSOR FOR
        SELECT MaLHP FROM TAM_DEMO_LHP ORDER BY KhoaThuTu;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET vHet = 1;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 vErrno = MYSQL_ERRNO;
        ROLLBACK;
        DROP TEMPORARY TABLE IF EXISTS TAM_DEMO_LHP;
        SET pKetQua = vErrno;   -- 1213 = deadlock victim, 1205 = het thoi gian cho
    END;

    SET pKetQua = 500;
    SET pDoTreGiay = IFNULL(pDoTreGiay, 0);

    -- ---------- Tach CSV -> bang tam (co san KHOA sap xep) ----------
    DROP TEMPORARY TABLE IF EXISTS TAM_DEMO_LHP;
    CREATE TEMPORARY TABLE TAM_DEMO_LHP (
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
            -- SAP_XEP  -> khoa sap xep theo MaLHP (moi phien cung thu tu)
            -- THEO_YEU_CAU -> khoa sap xep theo vi tri nguoi dung gui len
            INSERT IGNORE INTO TAM_DEMO_LHP (ThuTu, MaLHP, KhoaThuTu)
            VALUES (vThuTu, vItem,
                    IF(pKieuKhoa = 'SAP_XEP', CONCAT('A', vItem),
                                             CONCAT('B', LPAD(vThuTu, 6, '0'))));
        END IF;
    END WHILE;

    -- ---------- Vong khoa (giu khoa toi COMMIT) ----------
    START TRANSACTION;
    OPEN cur_khoa;
    khoa_loop: LOOP
        FETCH cur_khoa INTO vMaLHP;
        IF vHet = 1 THEN LEAVE khoa_loop; END IF;

        -- Khoa doc cap nhat (X-lock) dung 1 dong LOPHOCPHAN.
        -- Khoa nay GIU DEN KHI COMMIT/ROLLBACK -> phien khac muon khoa phai cho.
        BEGIN
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET vKhongThay = 1;
            SET vKhongThay = 0;
            SELECT SiSoHienTai, SiSoToiDa INTO vSiSo, vToiDa
            FROM LOPHOCPHAN WHERE MaLHP = vMaLHP
            FOR UPDATE;
        END;

        SET vNhatKy = CONCAT(vNhatKy,
            IF(vNhatKy = '', '', ' -> '), vMaLHP,
            IF(vKhongThay = 1, '(khong ton tai)', ''));

        IF pDoTreGiay > 0 THEN
            DO SLEEP(pDoTreGiay);   -- giu khoa lau hon => de quan sat tren man hinh
        END IF;
    END LOOP;
    CLOSE cur_khoa;

    COMMIT;   -- nha toan bo khoa
    SET pKetQua = 0;

    SELECT pMaSV AS MaSV, pKieuKhoa AS KieuKhoa,
           vNhatKy AS ThuTuKhoa, 'COMMIT — da nha khoa' AS KetThuc;
END$$

DELIMITER ;

-- ==========================================================
-- 2) SP_Demo_PhienGiaoDich — TAI HIEN LOI THAT CUA HE THONG:
--    DAO THU TU KHOA GIUA "DANG KY" VA "HUY DANG KY" (lock-order inversion)
--
--    Trong SP_DangKyHocPhan  : khoa LOPHOCPHAN (buoc 6)  -> roi ghi DANGKYHOCPHAN
--    Trong SP_HuyDangKy (cu) : khoa DANGKYHOCPHAN (JOIN FOR UPDATE) -> trigger
--                              moi cap nhat LOPHOCPHAN
--    => HAI THU TU NGUOC NHAU. Neu 2 phien cung luc:
--         Phien A giu LOPHOCPHAN, cho DANGKYHOCPHAN
--         Phien B giu DANGKYHOCPHAN, cho LOPHOCPHAN
--       => DEADLOCK (da do thuc te: InnoDB tra loi 1213 sau ~0,5s)
--
--    pVaiTro:
--      'DANG_KY_CHUA_FIX' : LOPHOCPHAN -> DANGKYHOCPHAN   (ban loi)
--      'HUY_CHUA_FIX'     : DANGKYHOCPHAN -> LOPHOCPHAN   (ban loi)
--      'DANG_KY_DA_FIX'   : LOPHOCPHAN -> DANGKYHOCPHAN   (ban da fix, giu nguyen)
--      'HUY_DA_FIX'       : LOPHOCPHAN -> DANGKYHOCPHAN   (ban da fix — DAO LAI thu tu)
--
--    pDoTreGiay: sleep giua buoc khoa thu 1 va buoc khoa thu 2 (mo rong cua so).
-- ==========================================================
DROP PROCEDURE IF EXISTS SP_Demo_PhienGiaoDich;

DELIMITER $$
CREATE PROCEDURE SP_Demo_PhienGiaoDich (
    IN  pVaiTro     VARCHAR(20),
    IN  pMaSV       VARCHAR(12),
    IN  pMaLHP      VARCHAR(15),
    IN  pDoTreGiay  INT,
    OUT pKetQua     INT
)
proc_demo_phien: BEGIN
    DECLARE vSiSo      INT;
    DECLARE vToiDa     INT;
    DECLARE vTrangThai VARCHAR(20);
    DECLARE vKhongThay INT DEFAULT 0;
    DECLARE vErrno     INT DEFAULT 0;
    DECLARE vCoDaHuy   INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 vErrno = MYSQL_ERRNO;
        ROLLBACK;
        SET pKetQua = vErrno;
        SELECT pVaiTro AS VaiTro, pMaSV AS MaSV, pMaLHP AS MaLHP,
               vErrno AS MaLoi,
               IF(vErrno = 1213, 'DEADLOCK — InnoDB da rollback phien nay (nan nhan)',
               IF(vErrno = 1205, 'HET THOI GIAN CHO KHOA', 'LOI KHAC')) AS KetQua;
    END;

    SET pKetQua = 500;
    SET pDoTreGiay = IFNULL(pDoTreGiay, 0);

    START TRANSACTION;

    IF pVaiTro LIKE 'HUY%CHUA_FIX' THEN
        -- ===== BAN LOI: khoa DANGKYHOCPHAN TRUOC =====
        SELECT dk.TrangThaiDangKy INTO vTrangThai
        FROM DANGKYHOCPHAN dk
        JOIN LOPHOCPHAN lhp ON lhp.MaLHP = dk.MaLHP
        WHERE dk.MaSV = pMaSV AND dk.MaLHP = pMaLHP
        FOR UPDATE;                       -- giu X-lock dong DANGKYHOCPHAN

        IF pDoTreGiay > 0 THEN DO SLEEP(pDoTreGiay); END IF;

        IF vTrangThai IS NULL THEN
            SET pKetQua = 201; ROLLBACK;
        ELSEIF vTrangThai <> 'DA_DANG_KY' THEN
            SET pKetQua = 202; ROLLBACK;
        ELSE
            UPDATE DANGKYHOCPHAN SET TrangThaiDangKy = 'DA_HUY',
                   GhiChu = CONCAT(IFNULL(GhiChu,''), ' | Huy demo deadlock')
            WHERE MaSV = pMaSV AND MaLHP = pMaLHP;   -- trigger xin khoa LOPHOCPHAN
            SET pKetQua = 0; COMMIT;
        END IF;

    ELSEIF pVaiTro LIKE 'HUY%DA_FIX' THEN
        -- ===== BAN DA FIX: khoa LOPHOCPHAN TRUOC (cung thu tu voi dang ky) =====
        BEGIN
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET vKhongThay = 1;
            SELECT SiSoHienTai, SiSoToiDa INTO vSiSo, vToiDa
            FROM LOPHOCPHAN WHERE MaLHP = pMaLHP FOR UPDATE;
        END;
        IF vKhongThay = 1 THEN SET pKetQua = 201; ROLLBACK;
        ELSE
            IF pDoTreGiay > 0 THEN DO SLEEP(pDoTreGiay); END IF;
            SELECT dk.TrangThaiDangKy INTO vTrangThai
            FROM DANGKYHOCPHAN dk
            WHERE dk.MaSV = pMaSV AND dk.MaLHP = pMaLHP
            FOR UPDATE;
            IF vTrangThai IS NULL THEN SET pKetQua = 201; ROLLBACK;
            ELSEIF vTrangThai <> 'DA_DANG_KY' THEN SET pKetQua = 202; ROLLBACK;
            ELSE
                UPDATE DANGKYHOCPHAN SET TrangThaiDangKy = 'DA_HUY',
                       GhiChu = CONCAT(IFNULL(GhiChu,''), ' | Huy demo deadlock (da fix)')
                WHERE MaSV = pMaSV AND MaLHP = pMaLHP;
                SET pKetQua = 0; COMMIT;
            END IF;
        END IF;

    ELSEIF pVaiTro LIKE 'DANG_KY%DA_FIX' THEN
        -- ===== BAN DA FIX: LOPHOCPHAN -> DANGKYHOCPHAN (khoa tuong minh) =====
        BEGIN
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET vKhongThay = 1;
            SELECT SiSoHienTai, SiSoToiDa INTO vSiSo, vToiDa
            FROM LOPHOCPHAN WHERE MaLHP = pMaLHP FOR UPDATE;
        END;
        IF vKhongThay = 1 OR vSiSo >= vToiDa THEN SET pKetQua = IF(vKhongThay=1,106,105); ROLLBACK;
        ELSE
            IF pDoTreGiay > 0 THEN DO SLEEP(pDoTreGiay); END IF;
            SELECT COUNT(*) INTO vCoDaHuy FROM DANGKYHOCPHAN
            WHERE MaSV = pMaSV AND MaLHP = pMaLHP AND TrangThaiDangKy = 'DA_HUY';
            SELECT TrangThaiDangKy INTO vTrangThai FROM DANGKYHOCPHAN
            WHERE MaSV = pMaSV AND MaLHP = pMaLHP FOR UPDATE;
            IF vTrangThai IN ('DA_DANG_KY','CHO_DUYET') THEN
                SET pKetQua = 101; ROLLBACK;
            ELSEIF vCoDaHuy > 0 THEN
                UPDATE DANGKYHOCPHAN SET TrangThaiDangKy='DA_DANG_KY',
                       NgayDangKy=NOW(), GhiChu='Dang ky lai demo deadlock (da fix)'
                WHERE MaSV = pMaSV AND MaLHP = pMaLHP;
                SET pKetQua = 0; COMMIT;
            ELSE
                INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
                VALUES (pMaSV, pMaLHP, NOW(), 'DA_DANG_KY', 'Dang ky demo deadlock (da fix)');
                SET pKetQua = 0; COMMIT;
            END IF;
        END IF;

    ELSE
        -- ===== BAN LOI 'DANG_KY_CHUA_FIX': LOPHOCPHAN -> (sleep) -> DANGKYHOCPHAN =====
        BEGIN
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET vKhongThay = 1;
            SELECT SiSoHienTai, SiSoToiDa INTO vSiSo, vToiDa
            FROM LOPHOCPHAN WHERE MaLHP = pMaLHP FOR UPDATE;
        END;
        IF vKhongThay = 1 OR vSiSo >= vToiDa THEN SET pKetQua = IF(vKhongThay=1,106,105); ROLLBACK;
        ELSE
            IF pDoTreGiay > 0 THEN DO SLEEP(pDoTreGiay); END IF;
            SELECT COUNT(*) INTO vCoDaHuy FROM DANGKYHOCPHAN
            WHERE MaSV = pMaSV AND MaLHP = pMaLHP AND TrangThaiDangKy = 'DA_HUY';
            IF vCoDaHuy > 0 THEN
                UPDATE DANGKYHOCPHAN SET TrangThaiDangKy='DA_DANG_KY',
                       NgayDangKy=NOW(), GhiChu='Dang ky lai demo deadlock'
                WHERE MaSV = pMaSV AND MaLHP = pMaLHP;
            ELSE
                INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
                VALUES (pMaSV, pMaLHP, NOW(), 'DA_DANG_KY', 'Dang ky demo deadlock');
            END IF;
            SET pKetQua = 0; COMMIT;
        END IF;
    END IF;

    SELECT pVaiTro AS VaiTro, pMaSV AS MaSV, pMaLHP AS MaLHP, pKetQua AS MaLoi,
           IF(pKetQua = 0, 'THANH CONG (COMMIT)',
              IF(pKetQua = 1213, 'DEADLOCK (1213) — bi rollback',
              IF(pKetQua = 1205, 'HET THOI GIAN CHO KHOA (1205)', 'KET THUC'))) AS KetQua;
END$$

DELIMITER ;

-- ==========================================================
-- 3) SP_ChuanBi_Demo_Deadlock — DUA DU LIEU VE TRANG THAI DEMO
--    - Xoa dang ky thu nghiem cua SV030/SV041 tren cac LHP chi dinh
--    - Tinh lai SiSoHienTai cho dung
--    - Tao 1 dong DA_HUY (SV030, LHP dau tien) de kich hoat
--      nhanh "tai su dung dong DA_HUY" trong SP_DangKyHocPhan
--      (day chinh la nhanh gay deadlock that voi SP_HuyDangKy).
--    An toan: chi tac dong SV030/SV041 + cac LHP chi dinh.
-- ==========================================================
DROP PROCEDURE IF EXISTS SP_ChuanBi_Demo_Deadlock;

DELIMITER $$
CREATE PROCEDURE SP_ChuanBi_Demo_Deadlock (
    IN pDanhSachLHP VARCHAR(255)
)
BEGIN
    DECLARE vConLai VARCHAR(255);
    DECLARE vItem   VARCHAR(15);
    DECLARE vDauTien VARCHAR(15) DEFAULT NULL;

    DELETE FROM DANGKYHOCPHAN
    WHERE MaSV IN ('SV030','SV041')
      AND FIND_IN_SET(MaLHP, REPLACE(pDanhSachLHP, ' ', '')) > 0;

    -- Tinh lai si so thuc te cho tung LHP trong danh sach
    UPDATE LOPHOCPHAN lhp
    SET lhp.SiSoHienTai = (
        SELECT COUNT(*) FROM DANGKYHOCPHAN d
        WHERE d.MaLHP = lhp.MaLHP AND d.TrangThaiDangKy = 'DA_DANG_KY'
    )
    WHERE FIND_IN_SET(lhp.MaLHP, REPLACE(pDanhSachLHP, ' ', '')) > 0;

    -- LHP dau tien: tao dong DA_HUY cho SV030 (kich hoat nhanh UPDATE tai su dung)
    SET vConLai = TRIM(REPLACE(pDanhSachLHP, ' ', ''));
    IF LOCATE(',', vConLai) > 0 THEN
        SET vDauTien = TRIM(SUBSTRING_INDEX(vConLai, ',', 1));
    ELSE
        SET vDauTien = vConLai;
    END IF;

    IF vDauTien IS NOT NULL AND vDauTien <> '' THEN
        INSERT IGNORE INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
        VALUES ('SV030', vDauTien, NOW(), 'DA_HUY', 'Dong DA_HUY phuc vu demo deadlock');
    END IF;

    SELECT lhp.MaLHP, lhp.SiSoHienTai, lhp.SiSoToiDa,
           (lhp.SiSoToiDa - lhp.SiSoHienTai) AS ConTrong,
           (SELECT TrangThaiDangKy FROM DANGKYHOCPHAN d
             WHERE d.MaSV='SV030' AND d.MaLHP=lhp.MaLHP LIMIT 1) AS TrangThaiSV030
    FROM LOPHOCPHAN lhp
    WHERE FIND_IN_SET(lhp.MaLHP, REPLACE(pDanhSachLHP, ' ', '')) > 0;
END$$

DELIMITER ;

SELECT '[OK] Da tao 3 SP demo deadlock: SP_Demo_KhoaTheoThuTu, SP_Demo_PhienGiaoDich, SP_ChuanBi_Demo_Deadlock' AS KetLuan;
