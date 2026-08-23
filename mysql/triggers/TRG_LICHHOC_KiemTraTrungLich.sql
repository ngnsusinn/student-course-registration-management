-- ==========================================================
-- Ten file : mysql/triggers/TRG_LICHHOC_KiemTraTrungLich.sql
-- Module   : Hoc phan, Giang vien & Mo lop hoc phan (TV2)
-- Mo ta    : Ban dich T-SQL -> MySQL. Chan them/sua lich hoc
--            bi trung phong hoac trung giang vien trong cung
--            hoc ky (cung Thu + khung tiet giao nhau).
--            AFTER + ROLLBACK -> BEFORE + SIGNAL.
-- ==========================================================

DROP TRIGGER IF EXISTS TRG_LICHHOC_BEFORE_INSERT;
DROP TRIGGER IF EXISTS TRG_LICHHOC_BEFORE_UPDATE;

DELIMITER $$

CREATE TRIGGER TRG_LICHHOC_BEFORE_INSERT
BEFORE INSERT ON LICHHOC
FOR EACH ROW
BEGIN
    -- 1. Trung phong
    IF EXISTS (
        SELECT 1
        FROM LICHHOC LH
        JOIN LOPHOCPHAN LHP_I  ON NEW.MaLHP = LHP_I.MaLHP
        JOIN LOPHOCPHAN LHP_LH ON LH.MaLHP = LHP_LH.MaLHP
        WHERE LH.MaPhong = NEW.MaPhong
          AND LH.Thu = NEW.Thu
          AND NEW.TietBatDau < LH.TietBatDau + LH.SoTiet
          AND LH.TietBatDau < NEW.TietBatDau + NEW.SoTiet
          AND LHP_I.MaHocKy = LHP_LH.MaHocKy
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Không thể lưu lịch học: phòng đã bị trùng lịch.';
    END IF;

    -- 2. Trung giang vien
    IF EXISTS (
        SELECT 1
        FROM LICHHOC LH
        JOIN LOPHOCPHAN LHP_I  ON NEW.MaLHP = LHP_I.MaLHP
        JOIN LOPHOCPHAN LHP_LH ON LH.MaLHP = LHP_LH.MaLHP
        WHERE LH.Thu = NEW.Thu
          AND NEW.TietBatDau < LH.TietBatDau + LH.SoTiet
          AND LH.TietBatDau < NEW.TietBatDau + NEW.SoTiet
          AND LHP_I.MaGV = LHP_LH.MaGV
          AND LHP_I.MaHocKy = LHP_LH.MaHocKy
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Không thể lưu lịch học: giảng viên đã bị trùng lịch.';
    END IF;
END$$

CREATE TRIGGER TRG_LICHHOC_BEFORE_UPDATE
BEFORE UPDATE ON LICHHOC
FOR EACH ROW
BEGIN
    -- 1. Trung phong (loai tru chinh ban ghi dang sua)
    IF EXISTS (
        SELECT 1
        FROM LICHHOC LH
        JOIN LOPHOCPHAN LHP_I  ON NEW.MaLHP = LHP_I.MaLHP
        JOIN LOPHOCPHAN LHP_LH ON LH.MaLHP = LHP_LH.MaLHP
        WHERE LH.MaLichHoc <> NEW.MaLichHoc
          AND LH.MaPhong = NEW.MaPhong
          AND LH.Thu = NEW.Thu
          AND NEW.TietBatDau < LH.TietBatDau + LH.SoTiet
          AND LH.TietBatDau < NEW.TietBatDau + NEW.SoTiet
          AND LHP_I.MaHocKy = LHP_LH.MaHocKy
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Không thể lưu lịch học: phòng đã bị trùng lịch.';
    END IF;

    -- 2. Trung giang vien
    IF EXISTS (
        SELECT 1
        FROM LICHHOC LH
        JOIN LOPHOCPHAN LHP_I  ON NEW.MaLHP = LHP_I.MaLHP
        JOIN LOPHOCPHAN LHP_LH ON LH.MaLHP = LHP_LH.MaLHP
        WHERE LH.MaLichHoc <> NEW.MaLichHoc
          AND LH.Thu = NEW.Thu
          AND NEW.TietBatDau < LH.TietBatDau + LH.SoTiet
          AND LH.TietBatDau < NEW.TietBatDau + NEW.SoTiet
          AND LHP_I.MaGV = LHP_LH.MaGV
          AND LHP_I.MaHocKy = LHP_LH.MaHocKy
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Không thể lưu lịch học: giảng viên đã bị trùng lịch.';
    END IF;
END$$

DELIMITER ;
