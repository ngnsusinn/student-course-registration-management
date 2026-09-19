-- ==========================================================
-- Ten file : demo/sql_config/lab__dirty_read__reader__chua_fix.sql
-- Module   : Dang ky hoc phan (TV3) — Chuong 4, muc 4.2 DIRTY READ
--
-- ⚠️⚠️ ĐÂY LÀ BẢN CỐ Ý CÓ LỖI — CHỈ DÙNG ĐỂ DEMO/LAB ⚠️⚠️
--
--   VAI "PHIÊN ĐỌC": ghi đè thủ tục THẬT `SP_DangKyNhieuHocPhan`
--   (nút "Đăng ký N lớp đã chọn") bằng bản lab CHỈ ĐỌC để chứng minh:
--
--       ① SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
--            ❌ hạ mức cô lập ⇒ cho phép đọc dữ liệu CHƯA COMMIT
--       ② START TRANSACTION
--       ③ ĐỌC LẦN 1:  sĩ số + COUNT(*) dòng đăng ký của lớp đầu tiên
--       ④ DO SLEEP(8)  ← ⏸ cửa sổ để phiên GHI kịp INSERT (chưa commit)
--       ⑤ ĐỌC LẦN 2:  nếu thấy số lớn hơn ⇒ đã đọc dữ liệu CHƯA COMMIT
--       ⑥ ROLLBACK  (lab chỉ đọc, không ghi gì)
--
--   ★ Cặp file tương ứng:
--       • Phiên GHI  : lab__dirty_read__writer__chua_fix.sql
--                      (INSERT → SLEEP 8s → ROLLBACK: dữ liệu "bẩn" biến mất)
--       • Phiên ĐỌC  : file này (@ READ UNCOMMITTED  ⇒ ĐỌC BẨN)
--       • Bản ĐÃ FIX : lab__dirty_read__reader__da_fix.sql
--                      (y hệt, chỉ khác đúng 1 dòng: REPEATABLE READ)
--
--   ★ Mã kết quả: 104 = "dải đỏ báo kết quả đo của phòng lab" (giống bản lab
--     NRR/Phantom dùng 104 để báo HỦY OAN) — nội dung thật nằm ở cột ChiTiet:
--        "ĐỌC BẨN — Đối chứng cô lập [LHP507] · sĩ số 0→1 · số dòng … 0→1"
--
--   Cach ap dung:
--     cd backend
--     node scripts/apply-sql.js ../demo/sql_config/lab__dirty_read__reader__chua_fix.sql
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
proc_dirty_read_ru: BEGIN
    DECLARE vMaLHP1    VARCHAR(15);
    DECLARE vSiSo1     INT DEFAULT 0;
    DECLARE vSiSo2     INT DEFAULT 0;
    DECLARE vDem1      INT DEFAULT 0;
    DECLARE vDem2      INT DEFAULT 0;
    DECLARE vDoTreGiay INT DEFAULT 8;   -- ⏸ giây giữa 2 lần đọc
    DECLARE vDoiChung  VARCHAR(255) DEFAULT '';

    SET pKetQua = 500;

    -- Lớp đầu tiên trong phiếu đăng ký (lab chỉ cần 1 lớp để chứng minh)
    SET vMaLHP1 = TRIM(SUBSTRING_INDEX(IFNULL(pDanhSachLHP, ''), ',', 1));

    IF vMaLHP1 IS NULL OR vMaLHP1 = '' THEN
        SET pKetQua = 106;
        SELECT pMaSV AS MaSV, 0 AS SoDangKyThanhCong,
               'Thiếu danh sách lớp — hãy tick ít nhất 1 lớp rồi bấm lại.' AS ChiTiet,
               'ROLLBACK' AS KetThuc;
        LEAVE proc_dirty_read_ru;
    END IF;

    -- ============================================================
    -- ❌ ĐIỂM KHÁC BIỆT DUY NHẤT SO VỚI BẢN ĐÃ FIX:
    --    READ UNCOMMITTED  (bản đã fix dùng REPEATABLE READ)
    -- ============================================================
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    START TRANSACTION;

    -- ===== ĐỌC LẦN 1 (trước khi phiên GHI kịp INSERT) =====
    SELECT SiSoHienTai INTO vSiSo1 FROM LOPHOCPHAN WHERE MaLHP = vMaLHP1;

    SELECT COUNT(*) INTO vDem1
    FROM DANGKYHOCPHAN
    WHERE MaLHP = vMaLHP1 AND TrangThaiDangKy = 'DA_DANG_KY';

    -- ⏸ Mở rộng cửa sổ để phiên GHI kịp INSERT (và CHƯA commit)
    DO SLEEP(vDoTreGiay);

    -- ===== ĐỌC LẦN 2 (sau khi phiên GHI đã INSERT nhưng CHƯA commit) =====
    SELECT SiSoHienTai INTO vSiSo2 FROM LOPHOCPHAN WHERE MaLHP = vMaLHP1;

    SELECT COUNT(*) INTO vDem2
    FROM DANGKYHOCPHAN
    WHERE MaLHP = vMaLHP1 AND TrangThaiDangKy = 'DA_DANG_KY';

    SET vDoiChung = CONCAT('Đối chứng cô lập [', vMaLHP1, '] · sĩ số ', vSiSo1, '→', vSiSo2,
                           ' · số dòng DANGKYHOCPHAN ', vDem1, '→', vDem2);

    -- Lab chỉ ĐỌC để chứng minh ⇒ huỷ giao dịch, không ghi gì
    ROLLBACK;

    -- ★ Trả mức cô lập về mặc định cho connection pool
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

    -- ============================================================
    -- KẾT LUẬN: hai lần đọc lệch nhau ⇒ đã đọc dữ liệu CHƯA COMMIT
    -- ============================================================
    IF vSiSo2 > vSiSo1 OR vDem2 > vDem1 THEN
        SET pKetQua = 104;
        SELECT pMaSV AS MaSV, 0 AS SoDangKyThanhCong,
               CONCAT('ĐỌC BẨN — ', vDoiChung,
                      ' ⇒ ĐÃ đọc dữ liệu CHƯA COMMIT của phiên khác (phiên đó ROLLBACK ⇒ con số này là RÁC)') AS ChiTiet,
               'ROLLBACK' AS KetThuc;
    ELSE
        SET pKetQua = 104;
        SELECT pMaSV AS MaSV, 0 AS SoDangKyThanhCong,
               CONCAT('KHÔNG ĐỌC BẨN — ', vDoiChung,
                      ' ⇒ mức cô lập đã CHẶN dữ liệu chưa commit') AS ChiTiet,
               'ROLLBACK' AS KetThuc;
    END IF;
END$$

DELIMITER ;

SELECT '[CANH BAO] Da ghi de SP_DangKyNhieuHocPhan bang BAN LAB DIRTY READ (doc 2 lan @ READ UNCOMMITTED). Khoi phuc: node scripts/apply-sql.js ../mysql/procedures/SP_DangKyNhieuHocPhan.sql' AS KetLuan;
