-- ==========================================================
-- Ten file : mysql/procedures/hocphan_giangvien_procedures.sql
-- Module   : Hoc phan, Giang vien & Mo lop hoc phan (TV2)
--            + Phan quyen nhap diem (TV5)
-- Mo ta    : Ban dich T-SQL -> MySQL:
--            SP_MoLopHocPhan, SP_GV_NHAP_DIEM.
--            Sua loi goc: TrangThaiLop 'Mở' -> 'MO_DANG_KY'
--            (ban goc vi pham CHECK); SP_GV_NHAP_DIEM ghi vao
--            KETQUAHOCTAP (bang diem thuc te cua he thong,
--            thay cho bang BANGDIEM thieu DDL trong repo goc).
-- ==========================================================

DROP PROCEDURE IF EXISTS SP_MoLopHocPhan;
DROP PROCEDURE IF EXISTS SP_GV_NHAP_DIEM;

DELIMITER $$

-- ==========================================================
-- 1. MO LOP HOC PHAN (kiem tra GV/phong trung lich)
-- ==========================================================
CREATE PROCEDURE SP_MoLopHocPhan (
    IN pMaLHP      VARCHAR(15),
    IN pTenLHP     VARCHAR(100),
    IN pMaMonHoc   VARCHAR(10),
    IN pMaHocKy    VARCHAR(10),
    IN pMaGV       VARCHAR(10),
    IN pSiSoToiDa  INT,
    IN pMaPhong    VARCHAR(10),
    IN pThu        TINYINT,
    IN pTietBatDau TINYINT,
    IN pSoTiet     TINYINT
)
BEGIN
    DECLARE vMaLichHoc VARCHAR(10);
    DECLARE vMaxLH     INT DEFAULT 0;

    IF EXISTS (SELECT 1 FROM LOPHOCPHAN WHERE MaLHP = pMaLHP) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mã lớp học phần đã tồn tại.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM MONHOC WHERE MaMonHoc = pMaMonHoc) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Môn học không tồn tại.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM HOCKY WHERE MaHocKy = pMaHocKy) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Học kỳ không tồn tại.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM GIANGVIEN WHERE MaGV = pMaGV) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Giảng viên không tồn tại.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM PHONGHOC WHERE MaPhong = pMaPhong) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phòng học không tồn tại.';
    END IF;

    IF pSiSoToiDa <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sĩ số tối đa phải lớn hơn 0.';
    END IF;

    IF pThu < 2 OR pThu > 8 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Thứ phải nằm trong khoảng từ 2 đến 8.';
    END IF;

    IF pTietBatDau <= 0 OR pSoTiet <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tiết bắt đầu và số tiết phải lớn hơn 0.';
    END IF;

    -- Kiem tra GIANG VIEN trung lich
    IF EXISTS (
        SELECT 1
        FROM LICHHOC LH
        JOIN LOPHOCPHAN LHP ON LH.MaLHP = LHP.MaLHP
        WHERE LHP.MaGV = pMaGV
          AND LHP.MaHocKy = pMaHocKy
          AND LH.Thu = pThu
          AND pTietBatDau < LH.TietBatDau + LH.SoTiet
          AND LH.TietBatDau < pTietBatDau + pSoTiet
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Giảng viên đã có lớp bị trùng lịch.';
    END IF;

    -- Kiem tra PHONG trung lich
    IF EXISTS (
        SELECT 1
        FROM LICHHOC LH
        JOIN LOPHOCPHAN LHP ON LH.MaLHP = LHP.MaLHP
        WHERE LH.MaPhong = pMaPhong
          AND LHP.MaHocKy = pMaHocKy
          AND LH.Thu = pThu
          AND pTietBatDau < LH.TietBatDau + LH.SoTiet
          AND LH.TietBatDau < pTietBatDau + pSoTiet
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phòng học đã có lớp bị trùng lịch.';
    END IF;

    INSERT INTO LOPHOCPHAN (MaLHP, TenLHP, MaMonHoc, MaHocKy, MaGV, SiSoToiDa, SiSoHienTai, TrangThaiLop)
    VALUES (pMaLHP, pTenLHP, pMaMonHoc, pMaHocKy, pMaGV, pSiSoToiDa, 0, 'MO_DANG_KY');

    SELECT IFNULL(MAX(CAST(SUBSTRING(MaLichHoc, 3) AS UNSIGNED)), 0) + 1
    INTO vMaxLH
    FROM LICHHOC
    WHERE MaLichHoc LIKE 'LH%';

    SET vMaLichHoc = CONCAT('LH', LPAD(vMaxLH, 3, '0'));

    INSERT INTO LICHHOC (MaLichHoc, MaLHP, MaPhong, Thu, TietBatDau, SoTiet)
    VALUES (vMaLichHoc, pMaLHP, pMaPhong, pThu, pTietBatDau, pSoTiet);
END$$

-- ==========================================================
-- 2. GIANG VIEN NHAP DIEM (chi lop minh phu trach)
--    Ghi vao KETQUAHOCTAP; trigger TRG_KETQUAHOCTAP_TinhDiem
--    tu dong tinh DiemTongKet/DiemChu/DiemHe4.
-- ==========================================================
CREATE PROCEDURE SP_GV_NHAP_DIEM (
    IN pMaGV          VARCHAR(10),
    IN pMaSV          VARCHAR(12),
    IN pMaLHP         VARCHAR(15),
    IN pDiemChuyenCan DECIMAL(4,2),
    IN pDiemGiuaKy    DECIMAL(4,2),
    IN pDiemCuoiKy    DECIMAL(4,2)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF pDiemChuyenCan IS NOT NULL AND (pDiemChuyenCan < 0 OR pDiemChuyenCan > 10) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Điểm chuyên cần phải nằm trong khoảng từ 0 đến 10.';
    END IF;

    IF pDiemGiuaKy IS NOT NULL AND (pDiemGiuaKy < 0 OR pDiemGiuaKy > 10) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Điểm giữa kỳ phải nằm trong khoảng từ 0 đến 10.';
    END IF;

    IF pDiemCuoiKy IS NOT NULL AND (pDiemCuoiKy < 0 OR pDiemCuoiKy > 10) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Điểm thi phải nằm trong khoảng từ 0 đến 10.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM GIANGVIEN WHERE MaGV = pMaGV) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Giảng viên không tồn tại.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM LOPHOCPHAN WHERE MaLHP = pMaLHP AND MaGV = pMaGV) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Giảng viên không phụ trách lớp học phần này.';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM DANGKYHOCPHAN
        WHERE MaSV = pMaSV AND MaLHP = pMaLHP AND TrangThaiDangKy = 'DA_DANG_KY'
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sinh viên chưa đăng ký lớp học phần này.';
    END IF;

    IF EXISTS (SELECT 1 FROM KETQUAHOCTAP WHERE MaSV = pMaSV AND MaLHP = pMaLHP) THEN
        UPDATE KETQUAHOCTAP
        SET DiemChuyenCan = pDiemChuyenCan,
            DiemGiuaKy    = pDiemGiuaKy,
            DiemCuoiKy    = pDiemCuoiKy
        WHERE MaSV = pMaSV AND MaLHP = pMaLHP;
    ELSE
        INSERT INTO KETQUAHOCTAP (MaSV, MaLHP, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy)
        VALUES (pMaSV, pMaLHP, pDiemChuyenCan, pDiemGiuaKy, pDiemCuoiKy);
    END IF;

    COMMIT;
END$$

DELIMITER ;
