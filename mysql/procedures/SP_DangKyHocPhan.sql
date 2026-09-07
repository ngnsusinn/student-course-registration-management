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
--
-- NANG CAP CHONG DEADLOCK (Chuong 5):
--   Khi 2 phien dang ky DONG THOI vao cung 1 lop, phien den sau co the
--   bi InnoDB chon lam "nan nhan" deadlock (loi 1213) — giao dich bi
--   rollback an toan (si so van dung, khong Lost Update).Theo pattern
--   chuan, SP TU RETRY toi da 3 lan: phien thua se kiem tra lai si so
--   sau khi phien kia commit va tra ve ma 105 (lop day) RANG RO,
--   thay vi 500 mo hinh.
--
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
    DECLARE vErrno        INT DEFAULT 0;
    DECLARE vRetry        INT DEFAULT 0;
    DECLARE vXong         INT DEFAULT 0;
    DECLARE vCoDongDaHuy  INT DEFAULT 0;

    -- ===== VONG RETRY KHI DEADLOCK (1213) =====
    retry_loop: REPEAT
      BEGIN
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET vNotFound = 1;

        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            GET DIAGNOSTICS CONDITION 1 vErrno = MYSQL_ERRNO;
            ROLLBACK;
            -- 1213 = Deadlock victim: InnoDB da tu dong rollback — an toan.
            -- Gan errno de vong REPEAT quyet dinh retry hay ket luan loi.
            SET pKetQua = vErrno;
        END;

        IF pMaxTinChi IS NULL THEN
            SET pMaxTinChi = 24;
        END IF;

        SET pKetQua = 500;
        SET vNotFound = 0;

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
        ELSE
        BEGIN
            IF vTrangThaiLop <> 'MO_DANG_KY' THEN
                SET pKetQua = 106;
                ROLLBACK;
            ELSE
            BEGIN
                -- ====================================================
                -- BUOC 1: KIEM TRA HAN DANG KY
                -- ====================================================
                IF FN_KiemTraDotDangKy() = 0 THEN
                    SET pKetQua = 100;
                    ROLLBACK;
                ELSE
                BEGIN
                    IF NOT EXISTS (
                        SELECT 1 FROM HOCKY
                        WHERE MaHocKy = vMaHocKy
                          AND TrangThaiDot = 'MO'
                          AND NOW() BETWEEN TuNgay AND DenNgay
                    ) THEN
                        SET pKetQua = 100;
                        ROLLBACK;
                    ELSE
                    BEGIN
                        -- ====================================================
                        -- BUOC 2: KIEM TRA DANG KY TRUNG LHP
                        -- (chi chan khi dang ky HIEU LUC / cho duyet —
                        --  da huy thi cho phep dang ky lai binh thuong)
                        -- ====================================================
                        IF EXISTS (
                            SELECT 1 FROM DANGKYHOCPHAN
                            WHERE MaSV = pMaSV AND MaLHP = pMaLHP
                              AND TrangThaiDangKy IN ('DA_DANG_KY', 'CHO_DUYET')
                        ) THEN
                            SET pKetQua = 101;
                            ROLLBACK;
                        ELSE
                        BEGIN
                            -- Co dong DA_HUY cu (PK MaSV+MaLHP) -> se TAI SU DUNG
                            -- bang UPDATE o BUOC 6 thay vi INSERT moi (tranh 1062)
                            SELECT COUNT(*) INTO vCoDongDaHuy
                            FROM DANGKYHOCPHAN
                            WHERE MaSV = pMaSV AND MaLHP = pMaLHP
                              AND TrangThaiDangKy = 'DA_HUY';

                            -- ====================================================
                            -- BUOC 3: KIEM TRA MON TIEN QUYET
                            -- ====================================================
                            IF FN_KiemTraTienQuyet(pMaSV, vMaMonHoc) = 0 THEN
                                SET pKetQua = 102;
                                ROLLBACK;
                            ELSE
                            BEGIN
                                -- ====================================================
                                -- BUOC 4: KIEM TRA TRUNG LICH HOC
                                -- ====================================================
                                IF FN_KiemTraTrungLichHoc(pMaSV, pMaLHP) = 1 THEN
                                    SET pKetQua = 103;
                                    ROLLBACK;
                                ELSE
                                BEGIN
                                    -- ====================================================
                                    -- BUOC 5: KIEM TRA GIOI HAN TIN CHI
                                    -- ====================================================
                                    SET vTongTinChiDa = FN_TinhTongTinChi(pMaSV, vMaHocKy);
                                    IF (vTongTinChiDa + vSoTinChiMH) > pMaxTinChi THEN
                                        SET pKetQua = 104;
                                        ROLLBACK;
                                    ELSE
                                    BEGIN
                                        -- ====================================================
                                        -- BUOC 6: KIEM TRA SI SO & GHI NHAN (ATOMIC,
                                        --   CHONG LOST UPDATE). FOR UPDATE giu khoa
                                        --   dong toi khi COMMIT.
                                        -- ====================================================
                                        SELECT SiSoHienTai, SiSoToiDa
                                        INTO vSiSoHienTai, vSiSoToiDa
                                        FROM LOPHOCPHAN
                                        WHERE MaLHP = pMaLHP
                                        FOR UPDATE;

                                        IF vSiSoHienTai >= vSiSoToiDa THEN
                                            SET pKetQua = 105;
                                            ROLLBACK;
                                        ELSE
                                        BEGIN
                                            IF vCoDongDaHuy > 0 THEN
                                                -- Tai su dung dong DA_HUY: trigger
                                                -- AFTER UPDATE tu +1 si so (DA_HUY->DA_DANG_KY)
                                                UPDATE DANGKYHOCPHAN
                                                SET TrangThaiDangKy = 'DA_DANG_KY',
                                                    NgayDangKy = NOW(),
                                                    GhiChu = pGhiChu
                                                WHERE MaSV = pMaSV AND MaLHP = pMaLHP;
                                            ELSE
                                                INSERT INTO DANGKYHOCPHAN
                                                    (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
                                                VALUES
                                                    (pMaSV, pMaLHP, NOW(), 'DA_DANG_KY', pGhiChu);
                                            END IF;

                                            SET pKetQua = 0;
                                            COMMIT;
                                        END;
                                        END IF;
                                    END;
                                    END IF;
                                END;
                                END IF;
                            END;
                            END IF;
                        END;
                        END IF;
                    END;
                    END IF;
                END;
                END IF;
            END;
            END IF;
        END;
        END IF;
    END;

    -- Danh gia: ma thuong mai (0,100..106) = XONG; 1213 = retry;
    -- con lai (errno khac) = loi he thong, khong retry.
    SET vXong = IF(pKetQua BETWEEN 0 AND 106, 1, 0);
    IF vXong = 0 AND pKetQua = 1213 AND vRetry < 2 THEN
        SET vRetry = vRetry + 1;   -- Deadlock victim -> thu lai
        SET vXong = 0;
    ELSEIF vXong = 0 THEN
        SET pKetQua = IF(pKetQua = 1213, 500, pKetQua);  -- errno khac -> 500
        SET vXong = 1;
    END IF;
UNTIL vXong = 1 END REPEAT;
END$$

DELIMITER ;
