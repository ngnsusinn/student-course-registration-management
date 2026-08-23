-- ==========================================================
-- Ten file : mysql/triggers/Xoa_Nganh_Trigger.sql
-- Module   : Danh muc he thong & Ho so sinh vien (TV1)
-- Issue    : #57 Trigger chan xoa nganh dao tao khi con sinh vien
-- Mo ta    : Ban dich T-SQL -> MySQL.
--            T-SQL dung INSTEAD OF DELETE; MySQL chi ho tro
--            BEFORE/AFTER DELETE => dung BEFORE DELETE + SIGNAL
--            de CHAN xoa (nen trong MySQL viec chan xoa nen dung
--            FOREIGN KEY ON DELETE RESTRICT la chinh, trigger nay
--            giu de minh hoa + dam bao yeu cau do an).
-- ==========================================================

DROP TRIGGER IF EXISTS TRG_XoaNganh_ChanKhiConSinhVien;

DELIMITER $$

CREATE TRIGGER TRG_XoaNganh_ChanKhiConSinhVien
BEFORE DELETE ON NGANH
FOR EACH ROW
BEGIN
    DECLARE vSoSV INT DEFAULT 0;

    -- Kiem tra: ngành sap xoa con lop sinh hoat nao khong?
    SELECT COUNT(*) INTO vSoSV
    FROM LOP_SINHHOAT l
    JOIN SINHVIEN sv ON sv.MaLopSH = l.MaLopSH
    WHERE l.MaNganh = OLD.MaNganh;

    IF vSoSV > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lỗi: Không thể xóa Ngành đào tạo này vì vẫn còn Sinh viên thuộc ngành!';
    END IF;
END$$

DELIMITER ;
