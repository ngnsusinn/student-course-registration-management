-- ==========================================================
-- Tên file : sql/indexes/dangky_hocphan_indexes.sql
-- Module   : Đăng ký học phần (TV3 — Leader)
-- Issue    : #62 Non-clustered Index Đăng ký học phần & Đo hiệu năng
-- Mô tả    : Tạo Non-clustered Index phục vụ 2 chiều tra cứu:
--              - IX_DKHP_MaSV  : "SV đã đăng ký những gì?"
--              - IX_DKHP_MaLHP : "LHP này có những ai?"
--            Kèm câu lệnh đo hiệu năng (SET STATISTICS TIME/IO)
--            và script so sánh TRƯỚC/SAU khi có index.
-- ==========================================================

-- ==========================================================
-- 1. DROP CÁC INDEX CŨ (nếu có — để chạy lại được)
-- ==========================================================
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_DKHP_MaSV' AND object_id = OBJECT_ID(N'DANGKYHOCPHAN'))
    DROP INDEX IX_DKHP_MaSV ON DANGKYHOCPHAN;
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_DKHP_MaLHP' AND object_id = OBJECT_ID(N'DANGKYHOCPHAN'))
    DROP INDEX IX_DKHP_MaLHP ON DANGKYHOCPHAN;
GO

-- ==========================================================
-- 2. ĐO HIỆU NĂNG TRƯỚC KHI CÓ INDEX (baseline)
--    Chạy 2 truy vấn tiêu biểu với STATISTICS rồi quan sát
--    Logical reads & CPU time.
-- ==========================================================
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

-- Baseline Q1: SV001 đã đăng ký những lớp nào (theo MaSV)
PRINT N'--- TRƯỚC INDEX: Q1 (lọc theo MaSV) ---';
SELECT MaSV, MaLHP, NgayDangKy, TrangThaiDangKy
FROM DANGKYHOCPHAN
WHERE MaSV = N'SV001';
GO

-- Baseline Q2: LHP501 có những ai (theo MaLHP)
PRINT N'--- TRƯỚC INDEX: Q2 (lọc theo MaLHP) ---';
SELECT MaSV, MaLHP, NgayDangKy, TrangThaiDangKy
FROM DANGKYHOCPHAN
WHERE MaLHP = N'LHP501';
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- ==========================================================
-- 3. TẠO NON-CLUSTERED INDEX (phục vụ 2 chiều tra cứu)
-- ==========================================================
-- Chỉ mục chiều "SV -> các lớp đã đăng ký"
CREATE NONCLUSTERED INDEX IX_DKHP_MaSV
    ON DANGKYHOCPHAN(MaSV)
    INCLUDE (MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu);
GO

-- Chỉ mục chiều "LHP -> danh sách SV"
CREATE NONCLUSTERED INDEX IX_DKHP_MaLHP
    ON DANGKYHOCPHAN(MaLHP)
    INCLUDE (MaSV, NgayDangKy, TrangThaiDangKy, GhiChu);
GO

PRINT N'[OK] Issue #62 — Đã tạo 2 Non-clustered Index.';
GO

-- ==========================================================
-- 4. ĐO HIỆU NĂNG SAU KHI CÓ INDEX (so sánh)
--    Logical reads giảm rõ rệt (từ scan toàn bảng sang index seek).
-- ==========================================================
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

-- Sau index Q1
PRINT N'--- SAU INDEX: Q1 (lọc theo MaSV) ---';
SELECT MaSV, MaLHP, NgayDangKy, TrangThaiDangKy
FROM DANGKYHOCPHAN WITH (INDEX(IX_DKHP_MaSV))
WHERE MaSV = N'SV001';
GO

-- Sau index Q2
PRINT N'--- SAU INDEX: Q2 (lọc theo MaLHP) ---';
SELECT MaSV, MaLHP, NgayDangKy, TrangThaiDangKy
FROM DANGKYHOCPHAN WITH (INDEX(IX_DKHP_MaLHP))
WHERE MaLHP = N'LHP501';
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- ==========================================================
-- 5. KẾ HOẠCH THỰC THI (Execution Plan) — xem chi tiết
--    Uncomment để xem plan: Ctrl+M trong SSMS trước khi chạy
-- ==========================================================
-- SET SHOWPLAN_TEXT ON;
-- SELECT * FROM DANGKYHOCPHAN WHERE MaSV = N'SV001';
-- SET SHOWPLAN_TEXT OFF;
-- GO
