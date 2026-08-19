-- ==========================================================
-- Tên file : sql/indexes/diem_ketqua_indexes.sql
-- Module   : Module 4 — Điểm số & Kết quả học tập (TV4 — Wiett)
-- Issue    : #64 Non-clustered Index Tra cứu Bảng điểm Cá nhân & Theo Lớp
-- Mô tả    : Thiết kế các chỉ mục phi tuần tự (Non-clustered Indexes)
--            để tối ưu hóa tốc độ truy vấn xem bảng điểm cá nhân,
--            tra cứu điểm theo lớp cho Giảng viên và lọc điểm F.
-- ==========================================================

USE [StudentCourseRegistration];
GO

-- ==========================================================
-- 1. INDEX 1: TỐI ƯU TRA CỨU BẢNG ĐIỂM CÁ NHÂN & TÍNH GPA/CPA (MaSV)
-- Thường dùng trong: Xem bảng điểm sinh viên, SP_TinhGPA_HocKy, SP_TinhCPA_TichLuy
-- ==========================================================
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_KETQUAHOCTAP_MaSV' AND object_id = OBJECT_ID(N'KETQUAHOCTAP'))
    DROP INDEX IX_KETQUAHOCTAP_MaSV ON KETQUAHOCTAP;
GO

CREATE NONCLUSTERED INDEX IX_KETQUAHOCTAP_MaSV
ON KETQUAHOCTAP (MaSV)
INCLUDE (DiemChuyenCan, DiemGiuaKy, DiemCuoiKy, DiemTongKet, DiemChu, DiemHe4);
GO

-- ==========================================================
-- 2. INDEX 2: TỐI ƯU TRA CỨU ĐIỂM THEO LỚP HỌC PHẦN CHO GIẢNG VIÊN (MaLHP)
-- Thường dùng trong: Màn hình giảng viên nhập điểm, V_THONGKE_KETQUA_MONHOC, xếp hạng MAX/MIN
-- ==========================================================
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_KETQUAHOCTAP_MaLHP' AND object_id = OBJECT_ID(N'KETQUAHOCTAP'))
    DROP INDEX IX_KETQUAHOCTAP_MaLHP ON KETQUAHOCTAP;
GO

CREATE NONCLUSTERED INDEX IX_KETQUAHOCTAP_MaLHP
ON KETQUAHOCTAP (MaLHP)
INCLUDE (MaSV, DiemTongKet, DiemChu, DiemHe4);
GO

-- ==========================================================
-- 3. INDEX 3: TỐI ƯU TRUY VẤN LỌC SINH VIÊN BỊ ĐIỂM F (DiemChu)
-- Thường dùng trong: FN_KiemTraTienQuyet, Cảnh báo học vụ, thống kê tỷ lệ rớt môn
-- ==========================================================
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_KETQUAHOCTAP_DiemChu' AND object_id = OBJECT_ID(N'KETQUAHOCTAP'))
    DROP INDEX IX_KETQUAHOCTAP_DiemChu ON KETQUAHOCTAP;
GO

CREATE NONCLUSTERED INDEX IX_KETQUAHOCTAP_DiemChu
ON KETQUAHOCTAP (DiemChu)
INCLUDE (MaSV, MaLHP);
GO

PRINT N'[OK] Issue #64 — Đã tạo thành công các Non-clustered Indexes cho Module 4.';
GO
