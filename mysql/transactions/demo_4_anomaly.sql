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

-- ==========================================================
-- 4) SP_Demo_DocHaiLan — ĐỌC HAI LẦN TRONG MỘT GIAO TÁC
--    (dùng cho kịch bản Non-repeatable Read / Phantom Read / Dirty Read
--     khi demo bằng SQL, ĐẶC BIỆT là trên **phpMyAdmin**)
--
--  ★ VÌ SAO CẦN THỦ TỤC NÀY?
--    phpMyAdmin KHÔNG giữ kết nối MySQL giữa 2 lần gửi câu lệnh: mỗi lần bấm
--    "Go" là một request HTTP mới ⇒ kết nối mới ⇒ `START TRANSACTION` ở lần
--    gửi trước ĐÃ BỊ MẤT. Vì vậy cách "gõ từng câu rồi chuyển tab" (đúng với
--    Workbench/DBeaver/mysql CLI) KHÔNG chạy được trên phpMyAdmin.
--    ⇒ Gói TRỌN 2 lần đọc + khoảng chờ vào MỘT câu `CALL` duy nhất: cả giao
--      tác nằm trong 1 request, còn phiên GHI thì mở ở TRÌNH DUYỆT KHÁC
--      (tab cùng trình duyệt dùng chung PHP session ⇒ bị khoá session).
--
--  Cach dung (2 cửa sổ ở 2 TRÌNH DUYỆT khác nhau):
--    [CỬA SỔ 1]  CALL SP_Demo_DocHaiLan('LHP514', 'READ COMMITTED', 8);
--    [CỬA SỔ 2]  (chạy trong 8 giây đó)
--                UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP='LHP514';
--                COMMIT;
--    ⇒ CỬA SỔ 1 trả về: Lan1 = 15, Lan2 = 16  ⇒ TÁI HIỆN ĐƯỢC Non-repeatable Read
--      Đổi tham số 2 thành 'REPEATABLE READ' ⇒ Lan1 = 15, Lan2 = 15 ⇒ ĐÃ CHẶN
--      Đổi thành 'READ UNCOMMITTED' (phiên 2 chỉ UPDATE, KHÔNG COMMIT) ⇒ ĐỌC BẨN
--
--   pMucCoLap: 'READ UNCOMMITTED' | 'READ COMMITTED' | 'REPEATABLE READ' | 'SERIALIZABLE'
--   pDoTreGiay: số giây giữa 2 lần đọc (0 = đọc liền, không cần cửa sổ)
-- ==========================================================
DROP PROCEDURE IF EXISTS SP_Demo_DocHaiLan;

DELIMITER $$
CREATE PROCEDURE SP_Demo_DocHaiLan (
    IN pMaLHP     VARCHAR(15),
    IN pMucCoLap  VARCHAR(20),
    IN pDoTreGiay INT
)
BEGIN
    DECLARE vMuc   VARCHAR(20);
    DECLARE vSiSo1 INT DEFAULT 0;
    DECLARE vSiSo2 INT DEFAULT 0;
    DECLARE vDem1  INT DEFAULT 0;
    DECLARE vDem2  INT DEFAULT 0;

    SET vMuc = UPPER(TRIM(IFNULL(pMucCoLap, 'READ COMMITTED')));
    IF vMuc NOT IN ('READ UNCOMMITTED', 'READ COMMITTED', 'REPEATABLE READ', 'SERIALIZABLE') THEN
        SET vMuc = 'READ COMMITTED';
    END IF;
    IF pDoTreGiay IS NULL OR pDoTreGiay < 0 THEN SET pDoTreGiay = 8; END IF;

    IF NOT EXISTS (SELECT 1 FROM LOPHOCPHAN WHERE MaLHP = pMaLHP) THEN
        SELECT pMaLHP AS MaLHP, vMuc AS MucCoLap,
               'Không tìm thấy lớp học phần này.' AS KetLuan;
    ELSE
        -- (Dùng IF + câu lệnh cố định: KHÔNG cần dynamic SQL)
        IF vMuc = 'READ UNCOMMITTED' THEN
            SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
        ELSEIF vMuc = 'REPEATABLE READ' THEN
            SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
        ELSEIF vMuc = 'SERIALIZABLE' THEN
            SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;
        ELSE
            SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
        END IF;

        START TRANSACTION;

        SELECT SiSoHienTai INTO vSiSo1 FROM LOPHOCPHAN WHERE MaLHP = pMaLHP;
        SELECT COUNT(*)     INTO vDem1
        FROM DANGKYHOCPHAN WHERE MaLHP = pMaLHP AND TrangThaiDangKy = 'DA_DANG_KY';

        -- ⏸ cửa sổ để phiên thứ hai ghi (và commit / hoặc chưa commit)
        DO SLEEP(pDoTreGiay);

        SELECT SiSoHienTai INTO vSiSo2 FROM LOPHOCPHAN WHERE MaLHP = pMaLHP;
        SELECT COUNT(*)     INTO vDem2
        FROM DANGKYHOCPHAN WHERE MaLHP = pMaLHP AND TrangThaiDangKy = 'DA_DANG_KY';

        ROLLBACK;   -- demo chỉ ĐỌC, không ghi gì

        -- ★ Trả mức cô lập về mặc định (quan trọng khi dùng connection pool)
        SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

        SELECT pMaLHP AS MaLHP, vMuc AS MucCoLap, pDoTreGiay AS DoTreGiay,
               vSiSo1 AS SiSo_Lan1, vSiSo2 AS SiSo_Lan2,
               vDem1  AS SoDong_Lan1, vDem2 AS SoDong_Lan2,
               IF(vSiSo2 <> vSiSo1 OR vDem2 <> vDem1,
                  'ĐỔI giữa 2 lần đọc ⇒ TÁI HIỆN ĐƯỢC lỗi đọc',
                  'KHÔNG đổi ⇒ mức cô lập đã CHẶN') AS KetLuan;
    END IF;
END$$
DELIMITER ;

SELECT '[OK] Da tao 4 SP demo: SP_DangKyHocPhan_ChuaFix, SP_ChuanBi_Demo_4Anomaly, SP_DangKyHocPhan_NangCao, SP_Demo_DocHaiLan' AS KetLuan;
