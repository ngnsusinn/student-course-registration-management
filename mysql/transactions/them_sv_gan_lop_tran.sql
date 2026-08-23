-- ==========================================================
-- Ten file : mysql/transactions/them_sv_gan_lop_tran.sql
-- Module   : Danh muc he thong & Ho so sinh vien (TV1)
-- Issue    : #68 Transaction them sinh vien moi & gan lop sinh hoat
-- Mo ta    : Ban dich T-SQL -> MySQL.
--            SP_ThemSinhVienVaGanLop: giao dich "Them SV + gan lop"
--            dam bao Atomicity (ROLLBACK neu lop khong ton tai).
--            MySQL: START TRANSACTION + SIGNAL thay RAISERROR.
-- ==========================================================

DROP PROCEDURE IF EXISTS SP_ThemSinhVienVaGanLop;

DELIMITER $$

CREATE PROCEDURE SP_ThemSinhVienVaGanLop (
    IN pMaSV         VARCHAR(12),
    IN pHoTen        VARCHAR(100),
    IN pMaLopSH      VARCHAR(15),
    IN pNgaySinh     DATE,
    IN pGioiTinh     TINYINT,
    IN pEmail        VARCHAR(100),
    IN pSoDienThoai  VARCHAR(15),
    IN pQueQuan      VARCHAR(100)
)
proc_them_sv_lop: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Bat dau Giao dich (Transaction)
    START TRANSACTION;

    -- 1. Kiem tra su ton tai cua lop sinh hoat
    IF NOT EXISTS (SELECT 1 FROM LOP_SINHHOAT WHERE MaLopSH = pMaLopSH) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = CONCAT('Loi Atomicity: Lop sinh hoat ', pMaLopSH, ' khong ton tai!');
    END IF;

    -- 2. Kiem tra trung ma SV
    IF EXISTS (SELECT 1 FROM SINHVIEN WHERE MaSV = pMaSV) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = CONCAT('Loi Atomicity: Ma sinh vien ', pMaSV, ' da ton tai!');
    END IF;

    -- 3. Them moi sinh vien va gan lop
    INSERT INTO SINHVIEN (MaSV, HoTen, NgaySinh, GioiTinh, Email, SoDienThoai, QueQuan, TrangThaiHoc, MaLopSH)
    VALUES (pMaSV, pHoTen, pNgaySinh, pGioiTinh, pEmail, pSoDienThoai, pQueQuan, 1, pMaLopSH);

    -- 4. Tu dong tao tai khoan dang nhap (nhanh van hanh)
    IF NOT EXISTS (SELECT 1 FROM TAIKHOAN WHERE MaSV = pMaSV) THEN
        INSERT INTO TAIKHOAN (MaTaiKhoan, TenDangNhap, MatKhau, Email, TrangThai, MaVaiTro, MaSV, MaGV)
        VALUES (CONCAT('TK', pMaSV), LOWER(pMaSV), SHA2('123456@a', 256), pEmail, 'ACTIVE', 'SV', pMaSV, NULL);
    END IF;

    -- Xac nhan giao dich
    COMMIT;
END$$

DELIMITER ;

-- ==========================================================
-- DEMO THUC THI
-- ==========================================================
-- Demo 1: Them SV hop le (lop CNTT01 ton tai) -> thanh cong
-- CALL SP_ThemSinhVienVaGanLop('SV999', 'Nguyen Van Test', 'CNTT01', '2005-01-01', 1, 'test@edu.vn', '0900000000', 'Hà Nội');

-- Demo 2: Them SV vao lop KHONG TON TAI -> ROLLBACK (Atomicity)
-- CALL SP_ThemSinhVienVaGanLop('SV998', 'Nguyen Van Loi', 'LOP_KHONG_CO', '2005-01-01', 1, 'loi@edu.vn', '0900000001', NULL);
-- => MySQL bao loi 'Loi Atomicity: Lop sinh hoat LOP_KHONG_CO khong ton tai!'
--    va khong co ban ghi nao duoc ghi (ROLLBACK).

SELECT '[OK] Issue #68 — Transaction them SV + gan lop (Atomicity) da tao.' AS KetLuan;
