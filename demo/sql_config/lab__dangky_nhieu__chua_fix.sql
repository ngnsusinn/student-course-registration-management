-- ==========================================================
-- Ten file : demo/sql_config/lab__dangky_nhieu__chua_fix.sql
-- Module   : Dang ky hoc phan (TV3) — Chuong 4, muc 4.3 & 4.4
--
-- ⚠️⚠️ ĐÂY LÀ BẢN CỐ Ý CÓ LỖI — CHỈ DÙNG ĐỂ DEMO/LAB ⚠️⚠️
--
--   Ghi đè thủ tục THẬT `SP_DangKyNhieuHocPhan` — thủ tục mà nút
--   **“Đăng ký N lớp đã chọn”** trên trang *Đăng ký lớp học phần* gọi tới.
--
--   ★ KHÁC BẢN THẬT ĐÚNG 3 CHỖ (mọi thứ còn lại giữ nguyên):
--     1. Hạ mức cô lập:  SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
--        (❌ TẮT cơ chế phòng chống của HQTCSDL)
--     2. ĐỌC HAI LẦN trong CÙNG một giao tác, cách nhau DO SLEEP(8):
--          • MỘT DÒNG : LOPHOCPHAN.SiSoHienTai của lớp đầu tiên  → Non-repeatable Read
--          • MỘT TẬP  : COUNT(*) số lớp SV đã ĐK trong học kỳ    → Phantom Read
--        (đọc lần 2 TRƯỚC khi giao tác ghi bất cứ thứ gì, nên chênh lệch
--         chỉ có thể đến từ GIAO TÁC KHÁC — không phải do chính nó ghi)
--     3. “KIỂM TRA LẠI” (bug): nếu hai lần đọc KHÁC NHAU thì HỦY TOÀN BỘ
--        giao tác và trả mã 104 ⇒ sinh viên bị **HỦY OAN** dù mọi điều
--        kiện đều hợp lệ. Với REPEATABLE READ, hai lần đọc luôn giống nhau
--        nên không bao giờ hủy oan.
--
--   ★ Cả hai con số của 2 lần đọc được trả về trong cột `ChiTiet` của
--     result set ⇒ trang web hiển thị ngay trong dải thông báo
--     “Kết quả từng lớp: …” (không cần sửa gì ở giao diện).
--
--   Cach ap dung:
--     cd backend
--     node scripts/apply-sql.js ../demo/sql_config/lab__dangky_nhieu__chua_fix.sql
--
--   ★ KHÔI PHỤC BẢN ĐÃ FIX (BẮT BUỘC sau khi demo):
--     node scripts/apply-sql.js ../mysql/procedures/SP_DangKyNhieuHocPhan.sql
--
--   Ma loi pKetQua: 0 = thanh cong · 100..106 = nghiep vu (nhu SP_DangKyHocPhan)
--                   104 = "vuot tin chi" (o day dung de bao HỦY OAN)
-- ==========================================================

DROP PROCEDURE IF EXISTS SP_DangKyNhieuHocPhan;

DELIMITER $$
CREATE PROCEDURE SP_DangKyNhieuHocPhan (
    IN  pMaSV        VARCHAR(12),
    IN  pDanhSachLHP VARCHAR(255),   -- CSV: 'LHP507,LHP508'
    IN  pMaxTinChi   INT,
    IN  pGhiChu      VARCHAR(255),
    OUT pKetQua      INT
)
proc_dk_nhieu_lab: BEGIN
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

    -- ★ Các biến phục vụ ĐỌC HAI LẦN (phần lab)
    DECLARE vDoTreGiay  INT DEFAULT 8;      -- ⏸ giây giữa 2 lần đọc
    DECLARE vMaLHP1     VARCHAR(15);
    DECLARE vMaHocKy1   VARCHAR(10);
    DECLARE vSiSo1      INT DEFAULT 0;
    DECLARE vSiSo2      INT DEFAULT 0;
    DECLARE vDem1       INT DEFAULT 0;
    DECLARE vDem2       INT DEFAULT 0;
    DECLARE vDoiChung   VARCHAR(255) DEFAULT '';

    -- ★ Con trỏ LUÔN khoá theo MaLHP TĂNG DẦN (giữ nguyên như bản THẬT)
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
            VALUES (vThuTu, vItem, CONCAT('A', vItem));   -- ★ khoa sap xep tang dan
        END IF;
    END WHILE;

    -- ============================================================
    -- ❌ ĐIỂM KHÁC BIỆT 1: HẠ MỨC CÔ LẬP  ("TẮT" phòng chống)
    -- ============================================================
    SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

    START TRANSACTION;

    -- Lớp đầu tiên trong danh sách (theo thứ tự con trỏ) + học kỳ của lớp đó
    SELECT MaLHP INTO vMaLHP1 FROM TAM_DK_NHIEU ORDER BY KhoaThuTu LIMIT 1;
    SELECT MaHocKy INTO vMaHocKy1 FROM LOPHOCPHAN WHERE MaLHP = vMaLHP1;

    -- ============================================================
    -- ❌ ĐIỂM KHÁC BIỆT 2: ĐỌC LẦN 1  (một DÒNG + một TẬP BẢN GHI)
    -- ============================================================
    SELECT SiSoHienTai INTO vSiSo1 FROM LOPHOCPHAN WHERE MaLHP = vMaLHP1;

    SELECT COUNT(*) INTO vDem1
    FROM DANGKYHOCPHAN dk
    JOIN LOPHOCPHAN l ON l.MaLHP = dk.MaLHP
    WHERE dk.MaSV = pMaSV AND l.MaHocKy = vMaHocKy1
      AND dk.TrangThaiDangKy = 'DA_DANG_KY';

    -- ⏸ Mở rộng cửa sổ để người thao tác kịp làm thao tác THẬT ở trình duyệt khác
    DO SLEEP(vDoTreGiay);

    -- ============================================================
    -- ❌ ĐIỂM KHÁC BIỆT 2 (tt): ĐỌC LẦN 2  — vẫn TRƯỚC khi giao tác này ghi
    -- ============================================================
    SELECT SiSoHienTai INTO vSiSo2 FROM LOPHOCPHAN WHERE MaLHP = vMaLHP1;

    SELECT COUNT(*) INTO vDem2
    FROM DANGKYHOCPHAN dk
    JOIN LOPHOCPHAN l ON l.MaLHP = dk.MaLHP
    WHERE dk.MaSV = pMaSV AND l.MaHocKy = vMaHocKy1
      AND dk.TrangThaiDangKy = 'DA_DANG_KY';

    SET vDoiChung = CONCAT('Đối chứng cô lập [', vMaLHP1, '] · sĩ số ', vSiSo1, '→', vSiSo2,
                           ' · số lớp của SV trong kỳ ', vDem1, '→', vDem2);

    -- ============================================================
    -- ❌ ĐIỂM KHÁC BIỆT 3: "KIỂM TRA LẠI" — HỦY OAN khi hai lần đọc khác nhau
    --    (với REPEATABLE READ, hai lần đọc luôn giống nhau ⇒ không hủy)
    -- ============================================================
    IF vSiSo2 <> vSiSo1 OR vDem2 <> vDem1 THEN
        ROLLBACK;
        DROP TEMPORARY TABLE IF EXISTS TAM_DK_NHIEU;
        SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
        SET pKetQua = 104;
        SELECT pMaSV AS MaSV, 0 AS SoDangKyThanhCong,
               CONCAT('HỦY OAN — ', vDoiChung) AS ChiTiet,
               'ROLLBACK' AS KetThuc;
        LEAVE proc_dk_nhieu_lab;
    END IF;

    -- ============================================================
    -- PHẦN CÒN LẠI: GIỐNG HỆT BẢN THẬT (vòng lặp đăng ký từng lớp)
    -- ============================================================
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

    -- ★ Trả mức cô lập về mặc định cho connection pool
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

    SELECT pMaSV AS MaSV, vSoOK AS SoDangKyThanhCong,
           CONCAT(vChiTiet, ' · ', vDoiChung) AS ChiTiet,
           IF(pKetQua = 0, 'COMMIT', 'ROLLBACK') AS KetThuc;
END$$
DELIMITER ;

SELECT '[CANH BAO] Da ghi de SP_DangKyNhieuHocPhan bang BAN LAB (doc 2 lan + huy oan). Khoi phuc: node scripts/apply-sql.js ../mysql/procedures/SP_DangKyNhieuHocPhan.sql' AS KetLuan;
