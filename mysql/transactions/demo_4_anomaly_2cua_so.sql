-- ==========================================================
-- Ten file : mysql/transactions/demo_4_anomaly_2cua_so.sql
-- Module   : Dang ky hoc phan (TV3 — Leader)
-- Muc dich : KICH BAN DEMO 4 LOI CONCURRENCY BANG 2 CUA SO
--            (Chuong 5 — Dieu khien canh tranh) — chay thu cong.
--
-- CHUAN BI:
--   1. Ap dung SP demo (chay 1 lan):
--        node backend/scripts/apply-demo-anomaly.js
--      (hoac chay file mysql/transactions/demo_4_anomaly.sql)
--   2. Mo 2 cua so ket noi rieng den DB (mysql CLI / Workbench / DBeaver).
--   3. Moi anomaly: lam dung cac buoc "CUA SO 1" va "CUA SO 2" theo thu tu,
--      sau khi den buoc DO SLEEP thi CHUYEN NGAY sang cua so kia trong
--      khoang thoi gian do (giay).
--
-- LOI CAN DEMO:
--   A. LOST UPDATE        — Cap nhat mat
--   B. DIRTY READ         — Doc ban
--   C. UNREPEATABLE READ  — Doc khong lap lai
--   D. PHANTOM READ       — Doc bong ma
--   E. PHONG CHONG        — SP_DangKyHocPhan (FOR UPDATE) + REPEATABLE READ
--
-- Script tu dong (khuyen nghi khi thuyet trinh, in tung buoc + PASS/FAIL):
--   node backend/scripts/test-anomaly-live.mjs
-- ==========================================================


-- ==========================================================
-- PHAN 0 — CHUAN BI (chay o cua so bat ky, 1 lan)
--   Dua LHP514 ve trang thai "con dung 1 cho" (vd 15/16)
-- ==========================================================
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');
-- Xem trang thai
SELECT MaLHP, SiSoHienTai, SiSoToiDa, (SiSoToiDa - SiSoHienTai) AS ConTrong
FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';

-- Xac nhan SP "chua fix" da co san
SHOW PROCEDURE STATUS WHERE Db = DATABASE() AND Name LIKE 'SP_DangKyHocPhan%';


-- ==========================================================
-- PHAN A — LOST UPDATE (CAP NHAT MAT)
-- "Thu tuc ban dau chua fix loi" = doc SiSo KHONG khoa (thieu
--  SELECT ... FOR UPDATE) -> 2 phien cung doc con 1 cho,
--  cung cho phep DK -> so SV thuc te vuot SiSoToiDa.
--
-- Cach "tat phong chong": dung SP_ChuaFix (khong FOR UPDATE).
-- Sau khi chay xong: so DANGKYHOCPHAN cua LHP514 > SiSoToiDa
-- (bo dem SiSoHienTai bi Trigger LEAST() clamp nen "noi doi").
-- ==========================================================

-- ---- CUA SO 1 (Phien A - SV030): --------------------------
START TRANSACTION;
-- Doc si so KHONG khoa (y nhu buoc 6 cua SP_ChuaFix):
SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';
-- -> thay con dung 1 cho
DO SLEEP(10);   -- co hoi 10 giay de chay CUA SO 2
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
VALUES ('SV030', 'LHP514', NOW(), 'DA_DANG_KY', 'Phien A - chua fix');
COMMIT;
-- ------------------------------------------------------------

-- ---- CUA SO 2 (Phien B - SV041): --------------------------
START TRANSACTION;
-- Chay trong luc Cua so 1 dang SLEEP. Doc si so KHONG khoa:
SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';
-- -> van thay con dung 1 cho (Cua so 1 chua COMMIT) -> cung cho phep DK!
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
VALUES ('SV041', 'LHP514', NOW(), 'DA_DANG_KY', 'Phien B - chua fix');
-- (lenh nay CHO khoa cua Cua so 1 toi khi no COMMIT, roi trigger +1)
COMMIT;
-- ------------------------------------------------------------

-- ---- KIEM TRA (cua so bat ky): ----------------------------
SELECT COUNT(*) AS SoDK_ThucTe,
       (SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514') AS BoDem_SiSo,
       (SELECT SiSoToiDa  FROM LOPHOCPHAN WHERE MaLHP='LHP514') AS SiSoToiDa
FROM DANGKYHOCPHAN
WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';
-- KY VONG (loi): SoDK_ThucTe = SiSoToiDa + 1  => LOST UPDATE xay ra.
-- Don dep:
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');


-- ==========================================================
-- PHAN B — DIRTY READ (DOC BAN)
-- MySQL REPEATABLE READ CHAN dirty read mac dinh. De demo, phai
-- "TAT" phong chong o phien doc bang cach ha muc co lap:
--    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- Cau: GV/PKT vua chot tang si so nhung CHUA chot so (chua commit);
-- phien doc "nhin thay" du lieu do va ra quyet dinh — roi giao dich
-- ghi bi ROLLBACK -> quyet dinh dua tren du lieu chua ton tai.
-- ==========================================================

-- ---- CUA SO 2 (Phien GHI — giu du lieu chua commit): ------
START TRANSACTION;
UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP = 'LHP514';
-- CHUA COMMIT! Giu y, chuyen sang Cua so 1.
-- (sau khi Cua so 1 doc xong lan 1, quay lai day chay:)
ROLLBACK;
-- ------------------------------------------------------------

-- ---- CUA SO 1 (Phien DOC — da TAT phong chong): -----------
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
START TRANSACTION;
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';
-- -> DOC DUOC gia tri DA TANG (+1) ma Cua so 2 CHUA COMMIT = DIRTY READ
DO SLEEP(8);    -- trong luc nay Cua so 2 se ROLLBACK
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';
-- -> gia tri "bien mat" — quyet dinh vua roi sai tren du lieu ban
ROLLBACK;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;  -- tra ve mac dinh
-- ------------------------------------------------------------

-- Don dep:
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');


-- ==========================================================
-- PHAN C — UNREPEATABLE READ (DOC KHONG LAP LAI)
-- "Tat" phong chong o phien doc: READ COMMITTED (giu khoa doc
--  cham dut sau moi SELECT -> giua 2 lan doc, nguoi khac sua duoc).
-- ==========================================================

-- ---- CUA SO 1 (Phien DOC — READ COMMITTED): ---------------
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';   -- lan 1
DO SLEEP(8);    -- trong luc nay Cua so 2 sua + COMMIT
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';   -- lan 2
-- -> 2 lan doc KHAC NHAU trong cung 1 giao tac = Unrepeatable Read
ROLLBACK;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- ------------------------------------------------------------

-- ---- CUA SO 2 (Phien GHI): --------------------------------
UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP = 'LHP514';
COMMIT;
-- (chay khi Cua so 1 dang SLEEP)
-- ------------------------------------------------------------

-- Don dep:
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');


-- ==========================================================
-- PHAN D — PHANTOM READ (DOC BONG MA)
-- "Tat" phong chong o phien doc: READ COMMITTED. Phien doc dem
-- so luong 2 lan; giua 2 lan dem, phien khac INSERT moi -> xuat
-- hien them dong "bong ma" ma phien doc khong hieu vi sao.
-- ==========================================================

-- ---- CUA SO 1 (Phien DOC — READ COMMITTED): ---------------
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
SELECT COUNT(*) FROM DANGKYHOCPHAN
WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';       -- lan 1
DO SLEEP(8);    -- trong luc nay Cua so 2 INSERT moi + COMMIT
SELECT COUNT(*) FROM DANGKYHOCPHAN
WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';       -- lan 2
-- -> COUNT tang them 1 dong "bong ma" = Phantom Read
ROLLBACK;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- ------------------------------------------------------------

-- ---- CUA SO 2 (Phien GHI): --------------------------------
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
VALUES ('SV999', 'LHP514', NOW(), 'DA_DANG_KY', 'Phien B moi vao - bong ma');
COMMIT;
-- (chay khi Cua so 1 dang SLEEP)
-- ------------------------------------------------------------

-- Don dep:
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');


-- ==========================================================
-- PHAN E — PHONG CHONG LAI (CHUNG MINH DA FIX)
-- E1. SP_DangKyHocPhan (da fix, FOR UPDATE): 2 phien thi dau
--     cho cuoi — chi 1 phien rc=0, phien kia rc=105.
-- E2. REPEATABLE READ mac dinh: doc lai COUNT truoc/sau khi
--     phien khac INSERT — khong thay bong ma.
-- ==========================================================

-- E1 — CUA SO 1:
CALL SP_DangKyHocPhan('SV030', 'LHP514', 24, 'Phien A - da fix', @kqA);
SELECT @kqA;   -- 0 = thanh cong
-- E1 — CUA SO 2 (chay ngay lap tuc):
CALL SP_DangKyHocPhan('SV041', 'LHP514', 24, 'Phien B - da fix', @kqB);
SELECT @kqB;   -- 105 = lop day (cho khoa roi kiem tra lai sau khi A commit)
-- E1 — KIEM TRA: si so khong vuot, chi 1 DK moi:
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');

-- E2 — CUA SO 1 (de isolation mac dinh REPEATABLE READ):
START TRANSACTION;
SELECT COUNT(*) FROM DANGKYHOCPHAN
WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';       -- lan 1
DO SLEEP(8);
SELECT COUNT(*) FROM DANGKYHOCPHAN
WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';       -- lan 2 = GIONG lan 1
ROLLBACK;
-- E2 — CUA SO 2 (chay khi Cua so 1 dang SLEEP):
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
VALUES ('SV999', 'LHP514', NOW(), 'DA_DANG_KY', 'snapshot test');
COMMIT;

-- Don dep cuoi cung:
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');
