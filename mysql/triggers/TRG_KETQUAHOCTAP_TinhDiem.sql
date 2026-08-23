-- ==========================================================
-- Ten file : mysql/triggers/TRG_KETQUAHOCTAP_TinhDiem.sql
-- Module   : Diem so & Ket qua hoc tap (TV4)
-- Mo ta    : Ban dich T-SQL -> MySQL. Trigger tu dong tinh
--            DiemTongKet, DiemChu, DiemHe4 khi nhap/sua diem.
--            T-SQL dung AFTER UPDATE cap nhat lai bang -> MySQL
--            khong cho trigger sua bang chua no, nen chuyen thanh
--            BEFORE INSERT / BEFORE UPDATE (gan gia tri NEW.*).
-- ==========================================================

DROP TRIGGER IF EXISTS TRG_KETQUAHOCTAP_BEFORE_INSERT;
DROP TRIGGER IF EXISTS TRG_KETQUAHOCTAP_BEFORE_UPDATE;

DELIMITER $$

CREATE TRIGGER TRG_KETQUAHOCTAP_BEFORE_INSERT
BEFORE INSERT ON KETQUAHOCTAP
FOR EACH ROW
BEGIN
    DECLARE vTongKet DOUBLE;

    IF NEW.DiemChuyenCan IS NOT NULL AND NEW.DiemGiuaKy IS NOT NULL AND NEW.DiemCuoiKy IS NOT NULL THEN
        SET vTongKet = ROUND((NEW.DiemChuyenCan * 0.10) + (NEW.DiemGiuaKy * 0.30) + (NEW.DiemCuoiKy * 0.60), 1);
        SET NEW.DiemTongKet = vTongKet;

        IF NEW.DiemCuoiKy < 3.0 THEN
            SET NEW.DiemChu = 'F';
            SET NEW.DiemHe4 = 0.0;
        ELSE
            SET NEW.DiemChu = (
                SELECT t.DiemChu FROM THANGDIEMCHU t
                WHERE vTongKet >= t.TuDiemHe10 AND vTongKet <= t.DenDiemHe10
                ORDER BY t.TuDiemHe10 DESC LIMIT 1
            );
            SET NEW.DiemHe4 = (
                SELECT t.DiemHe4 FROM THANGDIEMCHU t
                WHERE vTongKet >= t.TuDiemHe10 AND vTongKet <= t.DenDiemHe10
                ORDER BY t.TuDiemHe10 DESC LIMIT 1
            );
        END IF;
    ELSE
        SET NEW.DiemTongKet = NULL;
        SET NEW.DiemChu = NULL;
        SET NEW.DiemHe4 = NULL;
    END IF;
END$$

CREATE TRIGGER TRG_KETQUAHOCTAP_BEFORE_UPDATE
BEFORE UPDATE ON KETQUAHOCTAP
FOR EACH ROW
BEGIN
    DECLARE vTongKet DOUBLE;

    IF NEW.DiemChuyenCan IS NOT NULL AND NEW.DiemGiuaKy IS NOT NULL AND NEW.DiemCuoiKy IS NOT NULL THEN
        SET vTongKet = ROUND((NEW.DiemChuyenCan * 0.10) + (NEW.DiemGiuaKy * 0.30) + (NEW.DiemCuoiKy * 0.60), 1);
        SET NEW.DiemTongKet = vTongKet;

        IF NEW.DiemCuoiKy < 3.0 THEN
            SET NEW.DiemChu = 'F';
            SET NEW.DiemHe4 = 0.0;
        ELSE
            SET NEW.DiemChu = (
                SELECT t.DiemChu FROM THANGDIEMCHU t
                WHERE vTongKet >= t.TuDiemHe10 AND vTongKet <= t.DenDiemHe10
                ORDER BY t.TuDiemHe10 DESC LIMIT 1
            );
            SET NEW.DiemHe4 = (
                SELECT t.DiemHe4 FROM THANGDIEMCHU t
                WHERE vTongKet >= t.TuDiemHe10 AND vTongKet <= t.DenDiemHe10
                ORDER BY t.TuDiemHe10 DESC LIMIT 1
            );
        END IF;
    END IF;
END$$

DELIMITER ;
