-- ==========================================================
-- Ten file : mysql/triggers/TRG_LogDoiMatKhau.sql
-- Module   : Hoc phi, Tai khoan & Van hanh he thong (TV5)
-- Mo ta    : Ban dich T-SQL -> MySQL. Ghi log moi lan thay doi
--            mat khau tai khoan vao NHATKY_DOIMATKHAU.
--            IP: ung dung dat bien phien @ClientIP truoc khi
--            UPDATE (MySQL khong co CONNECTIONPROPERTY).
-- ==========================================================

DROP TRIGGER IF EXISTS TRG_LogDoiMatKhau;

DELIMITER $$

CREATE TRIGGER TRG_LogDoiMatKhau
AFTER UPDATE ON TAIKHOAN
FOR EACH ROW
BEGIN
    IF NEW.MatKhau <> OLD.MatKhau THEN
        INSERT INTO NHATKY_DOIMATKHAU
            (MaTaiKhoan, TenDangNhap, ThoiGianThayDoi, DiaChiIP, GhiChu)
        VALUES
            (NEW.MaTaiKhoan, NEW.TenDangNhap, NOW(), @ClientIP, 'Thay đổi mật khẩu');
    END IF;
END$$

DELIMITER ;
