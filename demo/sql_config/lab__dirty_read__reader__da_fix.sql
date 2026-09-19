-- ==========================================================
-- Ten file : demo/sql_config/lab__dirty_read__reader__da_fix.sql
-- Module   : Dang ky hoc phan (TV3) — Chuong 4, muc 4.2 DIRTY READ
--
-- ✅ BẢN ĐÃ FIX — GIỐNG HỆT file `lab__dirty_read__reader__chua_fix.sql`,
--    CHỈ KHÁC ĐÚNG 1 DÒNG mức cô lập:
--
--        ❌ chua_fix : SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
--        ✅ da_fix   : SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ
--
--    ⇒ REPEATABLE READ giữ ảnh chụp (snapshot) cố định từ lần đọc đầu ⇒
--      KHÔNG BAO GIỜ thấy dữ liệu chưa commit  ⇒ hai lần đọc luôn giống nhau.
--
--    Khác biệt thứ hai (chỉ ở phần kết luận): bản này trả `pKetQua = 0`
--    (dải XANH) với dòng "KHÔNG ĐỌC BẨN — …" để đối chứng trực quan với
--    dải ĐỎ của bản chưa fix.
--
--   Cach ap dung:
--     cd backend
--     node scripts/apply-sql.js ../demo/sql_config/lab__dirty_read__reader__da_fix.sql
--
--   ★ KHÔI PHỤC BẢN THẬT (BẮT BUỘC sau khi demo):
--     node scripts/apply-sql.js ../mysql/procedures/SP_DangKyNhieuHocPhan.sql
-- ==========================================================

DROP PROCEDURE IF EXISTS SP_DangKyNhieuHocPhan;

DELIMITER $$

CREATE PROCEDURE SP_DangKyNhieuHocPhan (
    IN  pMaSV        VARCHAR(12),
    IN  pDanhSachLHP VARCHAR(255),   -- CSV: 'LHP507,LHP508' — lab chỉ đọc lớp ĐẦU TIÊN
    IN  pMaxTinChi   INT,
    IN  pGhiChu      VARCHAR(255),
    OUT pKetQua      INT
)
proc_dirty_read_rr: BEGIN
    DECLARE vMaLHP1    VARCHAR(15);
    DECLARE vSiSo1     INT DEFAULT 0;
    DECLARE vSiSo2     INT DEFAULT 0;
    DECLARE vDem1      INT DEFAULT 0;
    DECLARE vDem2      INT DEFAULT 0;
    DECLARE vDoTreGiay INT DEFAULT 8;   -- ⏸ giây giữa 2 lần đọc
    DECLARE vDoiChung  VARCHAR(255) DEFAULT '';

    SET pKetQua = 500;

    SET vMaLHP1 = TRIM(SUBSTRING_INDEX(IFNULL(pDanhSachLHP, ''), ',', 1));

    IF vMaLHP1 IS NULL OR vMaLHP1 = '' THEN
        SET pKetQua = 106;
        SELECT pMaSV AS MaSV, 0 AS SoDangKyThanhCong,
               'Thiếu danh sách lớp — hãy tick ít nhất 1 lớp rồi bấm lại.' AS ChiTiet,
               'ROLLBACK' AS KetThuc;
        LEAVE proc_dirty_read_rr;
    END IF;

    -- ============================================================
    -- ✅ ĐIỂM KHÁC BIỆT DUY NHẤT SO VỚI BẢN CHƯA FIX:
    --    REPEATABLE READ  (bản chưa fix dùng READ UNCOMMITTED)
    -- ============================================================
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

    START TRANSACTION;

    -- ===== ĐỌC LẦN 1 =====
    SELECT SiSoHienTai INTO vSiSo1 FROM LOPHOCPHAN WHERE MaLHP = vMaLHP1;

    SELECT COUNT(*) INTO vDem1
    FROM DANGKYHOCPHAN
    WHERE MaLHP = vMaLHP1 AND TrangThaiDangKy = 'DA_DANG_KY';

    -- ⏸ Cùng cửa sổ 8 giây như bản chưa fix — so sánh hoàn toàn công bằng
    DO SLEEP(vDoTreGiay);

    -- ===== ĐỌC LẦN 2 (snapshot cố định ⇒ vẫn thấy số CŨ) =====
    SELECT SiSoHienTai INTO vSiSo2 FROM LOPHOCPHAN WHERE MaLHP = vMaLHP1;

    SELECT COUNT(*) INTO vDem2
    FROM DANGKYHOCPHAN
    WHERE MaLHP = vMaLHP1 AND TrangThaiDangKy = 'DA_DANG_KY';

    SET vDoiChung = CONCAT('Đối chứng cô lập [', vMaLHP1, '] · sĩ số ', vSiSo1, '→', vSiSo2,
                           ' · số dòng DANGKYHOCPHAN ', vDem1, '→', vDem2);

    COMMIT;   -- lab chỉ đọc ⇒ giao dịch rỗng, không thay đổi dữ liệu

    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

    SET pKetQua = 0;
    SELECT pMaSV AS MaSV, 0 AS SoDangKyThanhCong,
           CONCAT('KHÔNG ĐỌC BẨN — ', vDoiChung,
                  ' ⇒ REPEATABLE READ đã CHẶN dữ liệu chưa commit') AS ChiTiet,
           'COMMIT' AS KetThuc;
END$$

DELIMITER ;

SELECT '[OK] Da ghi de SP_DangKyNhieuHocPhan bang BAN LAB DIRTY READ DA FIX (doc 2 lan @ REPEATABLE READ). Khoi phuc: node scripts/apply-sql.js ../mysql/procedures/SP_DangKyNhieuHocPhan.sql' AS KetLuan;
