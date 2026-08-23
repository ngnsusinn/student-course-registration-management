-- =================================================================
-- ISSUE #58: NON-CLUSTERED INDEX TÌM KIẾM SINH VIÊN THEO HỌ TÊN & LỚP
-- =================================================================

-- 1. Index hỗ trợ tra cứu theo Họ tên
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_SINHVIEN_HoTen' AND object_id = OBJECT_ID('SINH_VIEN'))
    DROP INDEX IX_SINHVIEN_HoTen ON SINH_VIEN;
GO

CREATE NONCLUSTERED INDEX IX_SINHVIEN_HoTen
ON SINH_VIEN (HoTen);
GO

-- 2. Index kết hợp (Composite Index) hỗ trợ lọc đồng thời theo Họ tên và Lớp
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_SINHVIEN_HoTen_MaLop' AND object_id = OBJECT_ID('SINH_VIEN'))
    DROP INDEX IX_SINHVIEN_HoTen_MaLop ON SINH_VIEN;
GO

CREATE NONCLUSTERED INDEX IX_SINHVIEN_HoTen_MaLop
ON SINH_VIEN (HoTen, MaLop);
GO