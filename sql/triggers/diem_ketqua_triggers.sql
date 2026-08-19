-- ==========================================================
-- Tên file : sql/triggers/diem_ketqua_triggers.sql
-- Module   : Module 4 — Điểm số & Kết quả học tập (TV4 — Wiett)
-- Issue    : #63 Trigger tự động tính điểm tổng kết & điểm chữ
-- Mô tả    : AFTER INSERT, UPDATE Trigger trên bảng KETQUAHOCTAP.
--            Tự động tính toán DiemTongKet, tra cứu quy đổi DiemChu,
--            DiemHe4 ngay khi Giảng viên nhập hoặc sửa bất kỳ điểm
--            thành phần nào (Chuyên cần, Giữa kỳ, Cuối kỳ).
-- ==========================================================

USE [StudentCourseRegistration];
GO

IF OBJECT_ID(N'TRG_KETQUAHOCTAP_TinhDiem', N'TR') IS NOT NULL DROP TRIGGER TRG_KETQUAHOCTAP_TinhDiem;
GO

CREATE TRIGGER TRG_KETQUAHOCTAP_TinhDiem
ON KETQUAHOCTAP
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Tránh vòng lặp kích hoạt Trigger vô tận (Recursion check)
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    -- Chỉ thực hiện tính toán nếu có sự thay đổi các cột điểm thành phần
    IF NOT (UPDATE(DiemChuyenCan) OR UPDATE(DiemGiuaKy) OR UPDATE(DiemCuoiKy))
        RETURN;

    -- Cập nhật tự động DiemTongKet, DiemChu, DiemHe4 cho các bản ghi vừa chèn/sửa
    UPDATE kq
    SET 
        -- 1. Tính điểm tổng kết hệ 10: 10% CC + 30% GK + 60% CK
        DiemTongKet = CASE 
            WHEN i.DiemChuyenCan IS NOT NULL AND i.DiemGiuaKy IS NOT NULL AND i.DiemCuoiKy IS NOT NULL 
            THEN ROUND((i.DiemChuyenCan * 0.10) + (i.DiemGiuaKy * 0.30) + (i.DiemCuoiKy * 0.60), 1)
            ELSE NULL 
        END,

        -- 2. Quy đổi Điểm chữ (Nếu điểm cuối kỳ < 3.0 -> Điểm liệt F)
        DiemChu = CASE 
            WHEN i.DiemChuyenCan IS NULL OR i.DiemGiuaKy IS NULL OR i.DiemCuoiKy IS NULL THEN NULL
            WHEN i.DiemCuoiKy < 3.0 THEN 'F'
            ELSE (
                SELECT TOP 1 t.DiemChu
                FROM THANGDIEMCHU t
                WHERE ROUND((i.DiemChuyenCan * 0.10) + (i.DiemGiuaKy * 0.30) + (i.DiemCuoiKy * 0.60), 1) >= t.TuDiemHe10 
                  AND ROUND((i.DiemChuyenCan * 0.10) + (i.DiemGiuaKy * 0.30) + (i.DiemCuoiKy * 0.60), 1) <= t.DenDiemHe10
                ORDER BY t.TuDiemHe10 DESC
            )
        END,

        -- 3. Quy đổi Điểm hệ 4
        DiemHe4 = CASE 
            WHEN i.DiemChuyenCan IS NULL OR i.DiemGiuaKy IS NULL OR i.DiemCuoiKy IS NULL THEN NULL
            WHEN i.DiemCuoiKy < 3.0 THEN 0.0
            ELSE (
                SELECT TOP 1 t.DiemHe4
                FROM THANGDIEMCHU t
                WHERE ROUND((i.DiemChuyenCan * 0.10) + (i.DiemGiuaKy * 0.30) + (i.DiemCuoiKy * 0.60), 1) >= t.TuDiemHe10 
                  AND ROUND((i.DiemChuyenCan * 0.10) + (i.DiemGiuaKy * 0.30) + (i.DiemCuoiKy * 0.60), 1) <= t.DenDiemHe10
                ORDER BY t.TuDiemHe10 DESC
            )
        END
    FROM KETQUAHOCTAP kq
    JOIN inserted i ON kq.MaSV = i.MaSV AND kq.MaLHP = i.MaLHP;
END;
GO

PRINT N'[OK] Issue #63 — Đã khởi tạo Trigger TRG_KETQUAHOCTAP_TinhDiem tự động tính điểm.';
GO
