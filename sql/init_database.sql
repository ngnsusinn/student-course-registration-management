-- ==========================================================
-- Tên file : sql/init_database.sql
-- Module   : Khởi tạo toàn hệ thống (TV3 — Leader, Issue #23)
-- Mô tả    : CREATE DATABASE -> chạy DDL theo thứ tự dependency
--            -> INSERT dữ liệu mẫu. Chạy 1 lệnh là xong toàn bộ.
-- Cách chạy: mở bằng SQL Server Management Studio (SSMS)
--            hoặc:  sqlcmd -S .\SQLEXPRESS -i init_database.sql
-- ==========================================================

-- ==========================================================
-- 1. TẠO DATABASE
-- ==========================================================
IF DB_ID(N'DangKyHocPhan') IS NOT NULL
BEGIN
    ALTER DATABASE DangKyHocPhan SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DangKyHocPhan;
END
GO

CREATE DATABASE DangKyHocPhan;
GO

ALTER DATABASE DangKyHocPhan SET RECOVERY FULL;
GO

USE DangKyHocPhan;
GO

PRINT N'[1/5] Database DangKyHocPhan đã tạo xong.';
GO

-- ==========================================================
-- 2. CHẠY DDL THEO THỨ TỰ DEPENDENCY
--    Module 1 -> Module 2 -> Module 3 -> Module 4 -> Module 5
-- ==========================================================
:r ddl/00_danh_muc_hoso_sv_ddl.sql
GO
:r ddl/00_hocphan_giangvien_ddl.sql
GO
:r ddl/10_dangky_hocphan_ddl.sql
GO
:r ddl/00_diem_ketqua_ddl.sql
GO
:r ddl/00_hocphi_taikhoan_ddl.sql
GO

PRINT N'[2/5] Toàn bộ 18 bảng đã tạo xong (5 module).';
GO

-- ==========================================================
-- 3. CHẠY DỮ LIỆU MẪU THEO THỨ TỰ
-- ==========================================================
:r data/00_danh_muc_hoso_sv_data.sql
GO
:r data/00_hocphan_giangvien_data.sql
GO
:r data/dangky_hocphan_data.sql
GO
:r data/00_diem_ketqua_data.sql
GO
:r data/00_hocphi_taikhoan_data.sql
GO

PRINT N'[3/5] Dữ liệu mẫu đã nạp xong.';
GO

-- ==========================================================
-- 4. CHẠY INDEX & VIEW & FUNCTION & PROCEDURE & TRIGGER
--    (Không bắt buộc để chạy data, nhưng là sản phẩm bàn giao
--     của từng issue. Nếu cần demo nhanh có thể bỏ qua bước này.)
-- ==========================================================
:r queries/dangky_hocphan_queries.sql
GO
:r indexes/dangky_hocphan_indexes.sql
GO
:r procedures/FN_KiemTra_DangKy.sql
GO
:r procedures/SP_DangKyHocPhan.sql
GO
:r procedures/SP_HuyDangKy.sql
GO
:r triggers/TRG_DANGKYHOCPHAN_SiSo.sql
GO

PRINT N'[4/5] Index + SP + Trigger đã tạo xong.';
GO

-- ==========================================================
-- 5. KIỂM TRA NHANH
-- ==========================================================
SELECT N'-- Số bảng:' AS N'', COUNT(*) AS N'Tổng bảng'
FROM sys.tables;

SELECT N'-- Số SV đã đăng ký:' AS N'', COUNT(DISTINCT MaSV) AS N'SL'
FROM DANGKYHOCPHAN;

SELECT N'-- Kiểm tra SiSoHienTai vs SiSoToiDa:';
SELECT MaLHP, SiSoHienTai, SiSoToiDa
FROM LOPHOCPHAN
ORDER BY MaLHP;
GO

PRINT N'[5/5] HOÀN TẤT — Hệ thống đã khởi tạo xong toàn bộ.';
GO
