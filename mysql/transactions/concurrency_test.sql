-- ==========================================================
-- Ten file : mysql/transactions/concurrency_test.sql
-- Module   : Dang ky hoc phan (TV3 — Leader)
-- Issue    : #74 Kich ban test 2 session dong thoi
-- Mo ta    : Ban dich T-SQL -> MySQL.
--            KICH BAN 2 PHIEN DANG KY DONG THOI VAO LHP SAP HET CHO.
--            Chứng minh he thong XU LY DUNG (chi 1 SV thang,
--            si so khong vuot SiSoToiDa, khong Lost Update).
--
--  CACH CHAY (2 CUA SO mysql client / 2 ket noi):
--   1. Chay PHAN A "Chuan bi" trong cua so so 1.
--   2. Chay PHAN B "Phien 1" trong cua so so 1
--      (START TRANSACTION + SELECT ... FOR UPDATE + SLEEP(10)).
--   3. CHUYEN NGAY sang cua so so 2, chay PHAN C "Phien 2"
--      trong khi Phien 1 DANG GIU KHOA (10 giay).
--   4. Quan sat: Phien 2 BI CHAN (cho lock) toi khi Phien 1
--      COMMIT; sau do Phien 2 nhan ma loi 105 (lop day).
--   5. Chay PHAN D "Kiem tra" de xac nhan si so = 25/25.
-- ==========================================================

-- ==========================================================
-- PHAN A — CHUAN BI (chay 1 lan)
-- ==========================================================
SELECT '=== [Issue #74] PHAN A: Chuan bi trang thai test ===' AS GhiChu;

-- Dam bao SV001, SV002 chua Dk LHP501
DELETE FROM DANGKYHOCPHAN WHERE MaSV IN ('SV001', 'SV002') AND MaLHP = 'LHP501';

-- Dong bo si so LHP501 = so Dk hieu luc
UPDATE LOPHOCPHAN lhp
SET lhp.SiSoHienTai = (
    SELECT COUNT(*) FROM DANGKYHOCPHAN d
    WHERE d.MaLHP = lhp.MaLHP AND d.TrangThaiDangKy = 'DA_DANG_KY'
)
WHERE lhp.MaLHP = 'LHP501';

-- Dam bao SiSoToiDa = 25
UPDATE LOPHOCPHAN SET SiSoToiDa = 25 WHERE MaLHP = 'LHP501';

SELECT 'Trang thai LHP501 sau chuan bi:';
SELECT MaLHP, SiSoHienTai, SiSoToiDa, (SiSoToiDa - SiSoHienTai) AS ConTrong
FROM LOPHOCPHAN WHERE MaLHP = 'LHP501';

-- ==========================================================
-- PHAN B — PHIEN 1 (SESSION 1) — chay trong cua so mysql #1
--   SV001 dang ky LHP501. Mo Transaction, giu FOR UPDATE dong,
--   cho 10 giay de "phong to" cua so khoa cho Phien 2 thay.
-- ==========================================================
SELECT '=== [Issue #74] PHAN B: Phien 1 — SV001 dang ky LHP501 ===' AS GhiChu;

START TRANSACTION;

-- Khoa dong LHP501 (tuong duong UPDLOCK+HOLDLOCK)
SELECT MaLHP, SiSoHienTai, SiSoToiDa
FROM LOPHOCPHAN
WHERE MaLHP = 'LHP501'
FOR UPDATE;

SELECT 'Phien 1: Da khoa dong LHP501 (FOR UPDATE). Giu khoa 10 giay...' AS GhiChu;

-- Cho 10 giay de ban chuyen sang Phien 2
DO SLEEP(10);

-- Ghi nhan dang ky (Trigger AFTER INSERT tu +1 SiSoHienTai)
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
VALUES ('SV001', 'LHP501', NOW(), 'DA_DANG_KY', 'Phien 1 dang ky cho cuoi');

COMMIT;
SELECT 'Phien 1: COMMIT thanh cong — SV001 da lay cho cuoi.' AS GhiChu;

-- ==========================================================
-- PHAN C — PHIEN 2 (SESSION 2) — chay trong cua so mysql #2
--   CHAY PHAN NAY TRONG KHI PHIEN 1 DANG GIU KHOA (10 giay)
--   SV002 cung co dang ky LHP501. Phien 2 se BI CHAN toi khi
--   Phien 1 commit; sau do nhan ma loi 105 (lop day).
-- ==========================================================
SELECT '=== [Issue #74] PHAN C: Phien 2 — SV002 co dang ky LHP501 ===' AS GhiChu;
SELECT '(Ban phai chay PHAN B va PHAN C o 2 cua so khac nhau)' AS GhiChu;

CALL SP_DangKyHocPhan('SV002', 'LHP501', 24, 'Phien 2 co lay cho cuoi', @rc);

SELECT @rc AS MaKetQua;
-- Neu @rc = 105: DUNG — lop da day, Lost Update duoc ngan chan.
SELECT IF(@rc = 105,
          'DUNG: Lop da day — Lost Update duoc ngan chan, SV002 bi tu choi.',
          'Khong nhu ky vong (ma khac 105), kiem tra lai trang thai du lieu.') AS DanhGia;

-- ==========================================================
-- PHAN D — KIEM TRA KET QUA (chay sau khi ca 2 phien xong)
--   Si so LHP501 phai = 25 (khong vuot SiSoToiDa).
--   SV001 co ban ghi, SV002 khong co.
-- ==========================================================
SELECT '=== [Issue #74] PHAN D: Kiem tra ket qua ===' AS GhiChu;

SELECT MaLHP, SiSoHienTai, SiSoToiDa,
       IF(SiSoHienTai <= SiSoToiDa, 'Hop le', 'Vuot si so!') AS TrangThai
FROM LOPHOCPHAN WHERE MaLHP = 'LHP501';

SELECT MaSV, MaLHP, TrangThaiDangKy, NgayDangKy
FROM DANGKYHOCPHAN
WHERE MaLHP = 'LHP501' AND MaSV IN ('SV001', 'SV002')
ORDER BY MaSV;

-- ==========================================================
-- PHAN E (TUY CHON) — DEMO LOST UPDATE NEU KHONG DUNG KHOA
--   (Khong tu chay kich ban nay o day; tham khao mo ta duoi day)
-- ==========================================================
SELECT '=== [Issue #74] PHAN E: Mo ta demo Lost Update (khong dung khoa) ===' AS GhiChu;
SELECT 'S1: SELECT SiSoHienTai -> 24; S2: SELECT -> 24; S1 INSERT+UPDATE=25; S2 INSERT+UPDATE=25 => 26 SV (HONG DU LIEU).' AS MoTa;
SELECT 'Giai phap da ap dung trong SP: SELECT ... FOR UPDATE.' AS GiaiPhap;

-- ==========================================================
-- PHAN F (TUY CHON) — DEMO DEADLOCK + PHONG TRANH
--   Mo 2 cua so, chay 2 batch sau DONG THOI:
--     Phien 1: dang ky LHP501 roi LHP502
--     Phien 2: dang ky LHP502 roi LHP501  (nguoc thu tu -> deadlock)
--   MySQL chon 1 nan nhan (loi 1213), phien kia thanh cong.
--   Xem chi tiet docs/concurrency/deadlock_analysis.md.
-- ==========================================================
SELECT '=== [Issue #74] PHAN F: Deadlock demo (tham khao deadlock_analysis.md) ===' AS GhiChu;

-- Phien 1 (cua so 1):
-- START TRANSACTION;
--   SELECT ... FROM LOPHOCPHAN WHERE MaLHP='LHP501' FOR UPDATE;
--   DO SLEEP(5);
--   SELECT ... FROM LOPHOCPHAN WHERE MaLHP='LHP502' FOR UPDATE;
-- COMMIT;
-- Phien 2 (cua so 2):
-- START TRANSACTION;
--   SELECT ... FROM LOPHOCPHAN WHERE MaLHP='LHP502' FOR UPDATE;
--   DO SLEEP(5);
--   SELECT ... FROM LOPHOCPHAN WHERE MaLHP='LHP501' FOR UPDATE;
-- COMMIT;

SELECT '[OK] Issue #74 — Kich ban test 2 session dong thoi hoan tat.' AS KetLuan;
