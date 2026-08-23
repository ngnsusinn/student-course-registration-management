-- ==========================================================
-- Ten file : mysql/transactions/diem_ketqua_tran.sql
-- Module   : Diem so & Ket qua hoc tap (TV4)
-- Issue    : #75 Transaction nhap diem hang loat
-- Mo ta    : Ban dich T-SQL -> MySQL.
--            SP_NhapDiemHangLoat: giao tac nhap diem hang loat
--            cho sinh vien thuoc LHP. Dam bao Atomicity:
--            ROLLBACK toan bo neu 1 dong loi (diem ngoai [0,10]).
--            Trigger TRG_KETQUAHOCTAP tu dong tinh DiemTongKet.
-- ==========================================================

DROP PROCEDURE IF EXISTS SP_NhapDiemHangLoat;

DELIMITER $$

CREATE PROCEDURE SP_NhapDiemHangLoat (
    IN pMaLHP VARCHAR(15)
)
proc_nhap_diem: BEGIN
    DECLARE vSoLoi INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT '=== BAT DAU GIAO TAC NHAP DIEM HANG LOAT ===' AS GhiChu;

    START TRANSACTION;

    -- 1. Kiem tra Lop hoc phan co ton tai khong
    IF NOT EXISTS (SELECT 1 FROM LOPHOCPHAN WHERE MaLHP = pMaLHP) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = CONCAT('Loi: Lop hoc phan ', pMaLHP, ' khong ton tai!');
    END IF;

    -- 2. Kiem tra co sinh vien nao co diem khong hop le (ngoai [0,10])
    SELECT COUNT(*) INTO vSoLoi
    FROM KETQUAHOCTAP
    WHERE MaLHP = pMaLHP
      AND (DiemChuyenCan < 0.0 OR DiemChuyenCan > 10.0
        OR DiemGiuaKy    < 0.0 OR DiemGiuaKy    > 10.0
        OR DiemCuoiKy    < 0.0 OR DiemCuoiKy    > 10.0);

    IF vSoLoi > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Loi du lieu: Phat hien diem thanh phan ngoai khoang [0, 10]! Giao tac bi huy bo.';
    END IF;

    -- 3. Cap nhat diem cho toan bo sinh vien trong lop (trong 1 giao tac)
    UPDATE KETQUAHOCTAP
    SET DiemChuyenCan = IFNULL(DiemChuyenCan, 8.0),
        DiemGiuaKy    = IFNULL(DiemGiuaKy, 7.5),
        DiemCuoiKy    = IFNULL(DiemCuoiKy, 8.0)
    WHERE MaLHP = pMaLHP;

    -- Trigger TRG_KETQUAHOCTAP_TinhDiem tu dong tinh DiemTongKet, DiemChu, DiemHe4

    COMMIT;
    SELECT CONCAT('[SUCCESS] Giao tac thanh cong! Da nhap diem hang loat cho lop ', pMaLHP) AS KetQua;
END$$

DELIMITER ;

-- ==========================================================
-- DEMO THUC THI (mo phong kich ban trong file T-SQL goc)
-- ==========================================================

-- Demo 1: Nhap diem hop le cho lop hoc phan LHP101
-- CALL SP_NhapDiemHangLoat('LHP101');

-- Demo 2: Minh hoa ROLLBACK khi phat hien loi du lieu dang dang
START TRANSACTION;
    -- Co tinh nhap diem chuyen can sai = 15.0 (> 10.0) cho 1 sinh vien
    UPDATE KETQUAHOCTAP SET DiemChuyenCan = 15.0 WHERE MaLHP = 'LHP101' AND MaSV = 'SV001';

    -- Thao tac 2: Nhap diem cho sinh vien khac
    UPDATE KETQUAHOCTAP SET DiemChuyenCan = 9.0 WHERE MaLHP = 'LHP101' AND MaSV = 'SV002';

    -- Kiem tra dieu kien vi pham
    IF EXISTS (SELECT 1 FROM KETQUAHOCTAP WHERE DiemChuyenCan > 10.0) THEN
        SELECT '[TEST PASSED] Phat hien diem chuyen can > 10.0! Kich hoat ROLLBACK.' AS ThongBao;
        ROLLBACK;
    ELSE
        COMMIT;
    END IF;

SELECT '[OK] Issue #75 — Transaction nhap diem hang loat da tao.' AS KetLuan;
