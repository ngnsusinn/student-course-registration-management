-- ==========================================================
-- Tên file : sql/indexes/hocphi_taikhoan_indexes.sql
-- Module   : Học phí, Tài khoản & Vận hành hệ thống (TV5)
-- Issue    : #66
--
-- Mô tả:
-- Tạo các Non-clustered Index phục vụ tối ưu truy vấn.
--
-- Bao gồm:
--   1. IX_HOCPHI_MaSV
--      - Tra cứu học phí theo sinh viên.
--
--   2. IX_TAIKHOAN_TenDangNhap
--      - Đảm bảo tên đăng nhập duy nhất.
--      - Tăng tốc quá trình đăng nhập.
--
-- Chạy sau:
--   00_hocphi_taikhoan_ddl.sql
-- ==========================================================

PRINT N'========== TẠO INDEX TV5 =========='
GO

-- ==========================================================
-- INDEX 1
-- Non-clustered Index trên HOCPHI(MaSV)
-- Phục vụ:
--   - Tra cứu học phí theo sinh viên.
--   - Join với bảng SINHVIEN.
-- ==========================================================

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_HOCPHI_MaSV'
      AND object_id = OBJECT_ID(N'HOCPHI')
)
BEGIN

    CREATE NONCLUSTERED INDEX IX_HOCPHI_MaSV

    ON HOCPHI(MaSV);

    PRINT N'[OK] Đã tạo IX_HOCPHI_MaSV.';

END
ELSE
BEGIN

    PRINT N'[SKIP] IX_HOCPHI_MaSV đã tồn tại.';

END
GO


-- ==========================================================
-- INDEX 2
-- Unique Index trên TAIKHOAN(TenDangNhap)
--
-- Lưu ý:
-- Trong DDL, TAIKHOAN đã có:
--     CONSTRAINT UQ_TAIKHOAN_TenDangNhap UNIQUE(TenDangNhap)
--
-- SQL Server tự tạo một Unique Index cho ràng buộc này.
-- Trigger dưới đây chỉ tạo Unique Index nếu ràng buộc/index
-- chưa tồn tại, tránh tạo trùng.
-- ==========================================================

IF NOT EXISTS
(
    SELECT 1
    FROM sys.key_constraints
    WHERE name = N'UQ_TAIKHOAN_TenDangNhap'
)
AND NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_TAIKHOAN_TenDangNhap'
      AND object_id = OBJECT_ID(N'TAIKHOAN')
)
BEGIN

    CREATE UNIQUE NONCLUSTERED INDEX IX_TAIKHOAN_TenDangNhap

    ON TAIKHOAN(TenDangNhap);

    PRINT N'[OK] Đã tạo IX_TAIKHOAN_TenDangNhap.';

END
ELSE
BEGIN

    PRINT N'[SKIP] TenDangNhap đã được bảo vệ bởi UNIQUE Constraint/Index.';

END
GO

PRINT N'==========================================='
PRINT N'Hoàn thành Issue #66'
PRINT N'Đã tạo các Index tối ưu cho Học phí & Tài khoản.'
PRINT N'==========================================='
GO