-- ==========================================================
-- Ten file : mysql/transactions/dangky_hocphan_tran.sql
-- Module   : Dang ky hoc phan (TV3 — Leader)
-- Issue    : #72 Transaction dang ky hoc phan (Atomicity)
-- Mo ta    : Ban dich T-SQL -> MySQL.
--            T-SQL: BEGIN TRAN + WITH (UPDLOCK, HOLDLOCK)
--            MySQL : START TRANSACTION + SELECT ... FOR UPDATE
--            (FOR UPDATE giu khoa dong toi khi COMMIT/ROLLBACK,
--             tuong duong UPDLOCK+HOLDLOCK, ngan Lost Update).
--            SP_DangKyHocPhan (mysql/procedures/) da dong goi
--            toan bo 5 buoc kiem tra + ghi nhan trong transaction.
-- ==========================================================

-- ==========================================================
-- 0. BOI CANH: LHP501 (HQT CSDL) = 24/25, CON DUNG 1 CHO.
--    SV001, SV002 co du tien quyet, chua Dk LHP501.
-- ==========================================================

-- 0.1 RESET TRANG THAI (de chay lai duoc nhieu lan)
DELETE FROM DANGKYHOCPHAN WHERE MaSV IN ('SV001', 'SV002') AND MaLHP = 'LHP501';

UPDATE LOPHOCPHAN lhp
SET lhp.SiSoHienTai = (
    SELECT COUNT(*) FROM DANGKYHOCPHAN d
    WHERE d.MaLHP = lhp.MaLHP AND d.TrangThaiDangKy = 'DA_DANG_KY'
)
WHERE lhp.MaLHP = 'LHP501';

SELECT '--- [Issue #72] Trang thai LHP501 truoc khi test ---' AS GhiChu;
SELECT MaLHP, SiSoHienTai, SiSoToiDa, (SiSoToiDa - SiSoHienTai) AS ConTrong
FROM LOPHOCPHAN WHERE MaLHP = 'LHP501';

-- ==========================================================
-- 1. DEMO LOST UPDATE (CACH SAI — KHONG DUNG KHOA)
--    Minh hoa: 2 phien cung doc SiSoHienTai = 24 roi cung INSERT
--    => si so vuot qua SiSoToiDa (25). Giai phap: FOR UPDATE.
-- ==========================================================
SELECT '--- [Issue #72] MINH HOA LOST UPDATE (KHONG NEN DUNG) ---' AS GhiChu;
SELECT '2 phien cung SELECT SiSoHienTai (khong khoa) => ca 2 thay 24 < 25 => cung cho phep DK. Ket qua SAI: 26 SV.' AS MoTa;

-- ==========================================================
-- 2. DEMO DUNG CACH — GIAO DICH NGUYEN TU + FOR UPDATE
--    SV001 dang ky LHP501 (cho cuoi): thanh cong.
-- ==========================================================
SELECT '--- [Issue #72] SV001 dang ky LHP501 (cho cuoi) ---' AS GhiChu;
CALL SP_DangKyHocPhan('SV001', 'LHP501', 24, 'Dang ky qua Transaction test', @rc1);
SELECT @rc1 AS MaKetQua;   -- Ky vong 0 = thanh cong

SELECT '--- [Issue #72] Sau khi SV001 dang ky, LHP501 = ? ---' AS GhiChu;
SELECT MaLHP, SiSoHienTai, SiSoToiDa, (SiSoToiDa - SiSoHienTai) AS ConTrong
FROM LOPHOCPHAN WHERE MaLHP = 'LHP501';

-- ==========================================================
-- 3. DEMO CHAN DANG KY KHI HET CHO
--    SV002 thu dang ky -> bi chan (ma 105 = lop day).
-- ==========================================================
SELECT '--- [Issue #72] SV002 thu dang ky LHP501 (da day) ---' AS GhiChu;
CALL SP_DangKyHocPhan('SV002', 'LHP501', 24, NULL, @rc2);
SELECT @rc2 AS MaKetQua;   -- Ky vong 105 = lop day

SELECT '--- Kiem tra SV002 khong duoc ghi nhan ---' AS GhiChu;
SELECT COUNT(*) AS SoBanGhi_SV002_LHP501
FROM DANGKYHOCPHAN WHERE MaSV = 'SV002' AND MaLHP = 'LHP501';
SELECT MaLHP, SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP = 'LHP501';

-- ==========================================================
-- 4. DEMO ROLLBACK KHI CO LOI GIUA CHUNG
--    SV060 (F mon nen Co hoc) thu dang ky LHP514 (Kết cau cao tang)
--    -> thieu tien quyet (ma 102). Transaction bi ROLLBACK.
-- ==========================================================
SELECT '--- [Issue #72] Demo rollback: dang ky thieu tien quyet ---' AS GhiChu;
CALL SP_DangKyHocPhan('SV060', 'LHP514', 24, 'Test rollback', @rc3);
SELECT @rc3 AS MaKetQua;   -- Ky vong 102 (thieu tien quyet)

SELECT '--- Kiem tra rollback ---' AS GhiChu;
SELECT COUNT(*) AS SoBanGhi_SV060_LHP514
FROM DANGKYHOCPHAN WHERE MaSV = 'SV060' AND MaLHP = 'LHP514';
SELECT MaLHP, SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';

-- ==========================================================
-- 5. DEADLOCK DEMO & CACH PHONG TRANH (Chuong 5)
--    Phien A: khoa LHP501 roi can LHP502
--    Phien B: khoa LHP502 roi can LHP501  => deadlock.
--    MySQL tu chon 1 phien lam nan nhan (rollback, loi 1213).
--    Phong tranh: luon khoa cac LHP theo THU TU CO DINH
--    (VD: MaLHP tang dan). Script 2 session: concurrency_test.sql
-- ==========================================================
SELECT '--- [Issue #72] Deadlock: chay concurrency_test.sql de demo 2 session ---' AS GhiChu;
SELECT 'Phong tranh: luon khoa cac LHP theo THU TU CO DINH (MaLHP tang dan).' AS KhuyenNghi;

-- Reset lai trang thai cho cac lan chay sau
DELETE FROM DANGKYHOCPHAN WHERE MaSV IN ('SV001', 'SV002') AND MaLHP = 'LHP501';
UPDATE LOPHOCPHAN lhp
SET lhp.SiSoHienTai = (
    SELECT COUNT(*) FROM DANGKYHOCPHAN d
    WHERE d.MaLHP = lhp.MaLHP AND d.TrangThaiDangKy = 'DA_DANG_KY'
)
WHERE lhp.MaLHP = 'LHP501';

SELECT '[OK] Issue #72 — Transaction dang ky hoc phan nguyen tu + demo hoan tat.' AS KetLuan;
