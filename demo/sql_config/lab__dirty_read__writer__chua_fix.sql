-- ==========================================================
-- Ten file : demo/sql_config/lab__dirty_read__writer__chua_fix.sql
-- Module   : Dang ky hoc phan (TV3) — Chuong 4, muc 4.2 DIRTY READ
--
-- ⚠️⚠️ ĐÂY LÀ BẢN CỐ Ý CÓ LỖI — CHỈ DÙNG ĐỂ DEMO/LAB ⚠️⚠️
--
--   VAI "PHIÊN GHI": ghi đè thủ tục THẬT `SP_DangKyHocPhan` (nút "Đăng ký"
--   của 1 lớp) bằng bản mô phỏng một giao dịch **CHƯA COMMIT**:
--
--       INSERT  →  DO SLEEP(8)  →  ❌ ROLLBACK
--         ↑ ghi dữ liệu          ↑ giữ nguyên 8 giây   ↑ dữ liệu "bẩn" BIẾN MẤT
--           nhưng KHÔNG commit     ở trạng thái chưa commit
--
--   ★ VÌ SAO PHẢI ROLLBACK?  Đó là điều biến phép đọc của phiên kia thành
--     ĐỌC BẨN đúng nghĩa: phiên A đọc được con số `SiSoHienTai` (và dòng
--     DANGKYHOCPHAN) mà **chưa từng tồn tại** — sau khi phiên này ROLLBACK,
--     sĩ số trở lại như cũ. Nếu COMMIT thì cùng lắm chỉ là "đọc sớm".
--
--   ⚠️ Thủ tục vẫn trả `pKetQua = 0` (giao diện báo thành công) — đúng như
--      một giao dịch đang chờ commit. Sau khi ROLLBACK, dữ liệu đó KHÔNG còn.
--
--   Cach ap dung:
--     cd backend
--     node scripts/apply-sql.js ../demo/sql_config/lab__dirty_read__writer__chua_fix.sql
--
--   ★ KHÔI PHỤC BẢN THẬT (BẮT BUỘC sau khi demo):
--     node scripts/apply-sql.js ../mysql/procedures/SP_DangKyHocPhan.sql
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
proc_dirty_writer: BEGIN
    DECLARE vDoTreGiay INT DEFAULT 8;   -- ⏸ 8 giây giữ dữ liệu ở trạng thái CHƯA COMMIT

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET pKetQua = 500;
    END;

    SET pKetQua = 500;

    START TRANSACTION;

    -- Dọn dòng cũ (nếu có) để chắc chắn INSERT được — PK là (MaSV, MaLHP)
    IF EXISTS (SELECT 1 FROM DANGKYHOCPHAN WHERE MaSV = pMaSV AND MaLHP = pMaLHP) THEN
        DELETE FROM DANGKYHOCPHAN WHERE MaSV = pMaSV AND MaLHP = pMaLHP;
    END IF;

    -- ★ GHI nhưng CỐ Ý KHÔNG COMMIT (trigger +1 SiSoHienTai cũng chưa commit)
    INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
    VALUES (pMaSV, pMaLHP, NOW(), 'DA_DANG_KY', pGhiChu);

    -- ⏸ Giữ dữ liệu "bẩn" trong 8 giây để phiên ĐỌC kịp đọc nó
    DO SLEEP(vDoTreGiay);

    -- ❌ ROLLBACK: dữ liệu mà phiên đọc vừa thấy KHÔNG BAO GIỜ TỒN TẠI
    ROLLBACK;

    -- Vẫn báo thành công cho giao diện (giống một giao dịch "đang chờ commit")
    SET pKetQua = 0;
END$$

DELIMITER ;

SELECT '[CANH BAO] Da ghi de SP_DangKyHocPhan bang BAN LAB DIRTY READ (INSERT -> SLEEP 8s -> ROLLBACK). Khoi phuc: node scripts/apply-sql.js ../mysql/procedures/SP_DangKyHocPhan.sql' AS KetLuan;
