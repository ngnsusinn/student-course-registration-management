-- ==========================================================
-- Ten file : mysql/procedures/hocphi_taikhoan_procedures.sql
-- Module   : Hoc phi, Tai khoan & Van hanh he thong (TV5)
-- Mo ta    : Ban dich T-SQL -> MySQL:
--            SP_TinhHocPhi, SP_TaoTaiKhoanSinhVien,
--            SP_TaoTaiKhoanGiangVien, SP_ThuHocPhi.
--            Sua loi goc: MaVaiTro 'STUDENT'/'LECTURER' -> 'SV'/'GV'
--            (khop du lieu VAITRO); mat khau bam SHA2-256.
-- ==========================================================

DROP PROCEDURE IF EXISTS SP_TinhHocPhi;
DROP PROCEDURE IF EXISTS SP_TaoTaiKhoanSinhVien;
DROP PROCEDURE IF EXISTS SP_TaoTaiKhoanGiangVien;
DROP PROCEDURE IF EXISTS SP_ThuHocPhi;

DELIMITER $$

-- ==========================================================
-- SP 1: TINH HOC PHI CHO SINH VIEN
-- ==========================================================
CREATE PROCEDURE SP_TinhHocPhi (
    IN pMaSV         VARCHAR(12),
    IN pMaHocKy      VARCHAR(10),
    IN pDonGiaTinChi DECIMAL(12,0)
)
BEGIN
    DECLARE vTongTinChi INT DEFAULT 0;
    DECLARE vTongTien   DECIMAL(15,0);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM SINHVIEN WHERE MaSV = pMaSV) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sinh viên không tồn tại.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM HOCKY WHERE MaHocKy = pMaHocKy) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Học kỳ không tồn tại.';
    END IF;

    SELECT IFNULL(SUM(mh.SoTinChi), 0) INTO vTongTinChi
    FROM DANGKYHOCPHAN dk
    INNER JOIN LOPHOCPHAN lhp ON dk.MaLHP = lhp.MaLHP
    INNER JOIN MONHOC mh ON lhp.MaMonHoc = mh.MaMonHoc
    WHERE dk.MaSV = pMaSV
      AND lhp.MaHocKy = pMaHocKy
      AND dk.TrangThaiDangKy = 'DA_DANG_KY';

    IF vTongTinChi = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sinh viên chưa đăng ký học phần.';
    END IF;

    SET vTongTien = vTongTinChi * pDonGiaTinChi;

    IF EXISTS (SELECT 1 FROM HOCPHI WHERE MaSV = pMaSV AND MaHocKy = pMaHocKy) THEN
        UPDATE HOCPHI
        SET SoTinChi     = vTongTinChi,
            DonGiaTinChi = pDonGiaTinChi,
            TongTien     = vTongTien,
            TrangThai    = CASE
                               WHEN DaNop >= vTongTien THEN 'DA_THANH_TOAN'
                               WHEN DaNop = 0 THEN 'CHUA_THANH_TOAN'
                               ELSE 'DANG_XU_LY'
                           END
        WHERE MaSV = pMaSV AND MaHocKy = pMaHocKy;
    ELSE
        INSERT INTO HOCPHI (MaHocPhi, MaSV, MaHocKy, SoTinChi, DonGiaTinChi, TongTien, DaNop, TrangThai)
        VALUES (CONCAT('HP_', pMaSV, '_', pMaHocKy), pMaSV, pMaHocKy, vTongTinChi, pDonGiaTinChi, vTongTien, 0, 'CHUA_THANH_TOAN');
    END IF;

    COMMIT;
END$$

-- ==========================================================
-- SP 2: TAO TAI KHOAN CHO SINH VIEN
-- ==========================================================
CREATE PROCEDURE SP_TaoTaiKhoanSinhVien (
    IN pMaSV VARCHAR(12)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM SINHVIEN WHERE MaSV = pMaSV) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sinh viên không tồn tại.';
    END IF;

    IF EXISTS (SELECT 1 FROM TAIKHOAN WHERE MaSV = pMaSV) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sinh viên đã có tài khoản.';
    END IF;

    INSERT INTO TAIKHOAN (MaTaiKhoan, TenDangNhap, MatKhau, Email, TrangThai, MaVaiTro, MaSV, MaGV)
    SELECT
        CONCAT('TK_', MaSV),
        LOWER(MaSV),
        SHA2('matkhau@123', 256),
        Email,
        'ACTIVE',
        'SV',
        MaSV,
        NULL
    FROM SINHVIEN
    WHERE MaSV = pMaSV;

    COMMIT;
END$$

-- ==========================================================
-- SP 3: TAO TAI KHOAN CHO GIANG VIEN
-- ==========================================================
CREATE PROCEDURE SP_TaoTaiKhoanGiangVien (
    IN pMaGV VARCHAR(10)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM GIANGVIEN WHERE MaGV = pMaGV) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Giảng viên không tồn tại.';
    END IF;

    IF EXISTS (SELECT 1 FROM TAIKHOAN WHERE MaGV = pMaGV) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Giảng viên đã có tài khoản.';
    END IF;

    INSERT INTO TAIKHOAN (MaTaiKhoan, TenDangNhap, MatKhau, Email, TrangThai, MaVaiTro, MaSV, MaGV)
    SELECT
        CONCAT('TK_', MaGV),
        LOWER(MaGV),
        SHA2('matkhau@123', 256),
        Email,
        'ACTIVE',
        'GV',
        NULL,
        MaGV
    FROM GIANGVIEN
    WHERE MaGV = pMaGV;

    COMMIT;
END$$

-- ==========================================================
-- SP 4: THU HOC PHI (transaction an toan, chong nop vuot)
-- ==========================================================
CREATE PROCEDURE SP_ThuHocPhi (
    IN  pMaHocPhi    VARCHAR(15),
    IN  pSoTienNop   DECIMAL(15,0),
    OUT pKetQua      INT
)
proc_thu: BEGIN
    DECLARE vTongTien  DECIMAL(15,0);
    DECLARE vDaNop     DECIMAL(15,0);
    DECLARE vTrangThai VARCHAR(30);
    DECLARE vNotFound  INT DEFAULT 0;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET vNotFound = 1;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET pKetQua = 500;
    END;

    SET pKetQua = 500;

    START TRANSACTION;

    SELECT TongTien, DaNop, TrangThai
    INTO vTongTien, vDaNop, vTrangThai
    FROM HOCPHI
    WHERE MaHocPhi = pMaHocPhi
    FOR UPDATE;

    IF vNotFound = 1 THEN
        SET pKetQua = 301;           -- khong tim thay phieu hoc phi
        ROLLBACK;
        LEAVE proc_thu;
    END IF;

    IF vTrangThai = 'DA_THANH_TOAN' THEN
        SET pKetQua = 302;           -- da thanh toan het
        ROLLBACK;
        LEAVE proc_thu;
    END IF;

    IF pSoTienNop <= 0 THEN
        SET pKetQua = 303;           -- so tien nop khong hop le
        ROLLBACK;
        LEAVE proc_thu;
    END IF;

    IF vDaNop + pSoTienNop > vTongTien THEN
        SET pKetQua = 304;           -- nop vuot so tien con no
        ROLLBACK;
        LEAVE proc_thu;
    END IF;

    -- Luu y: MySQL danh gia SET tu trai sang phai, nen trong CASE
    -- cot DaNop da mang GIA TRI MOI (sau khi + pSoTienNop).
    UPDATE HOCPHI
    SET DaNop = DaNop + pSoTienNop,
        TrangThai = CASE
                        WHEN DaNop >= TongTien THEN 'DA_THANH_TOAN'
                        ELSE 'DANG_XU_LY'
                    END
    WHERE MaHocPhi = pMaHocPhi;

    SET pKetQua = 0;

    COMMIT;
END$$

DELIMITER ;
