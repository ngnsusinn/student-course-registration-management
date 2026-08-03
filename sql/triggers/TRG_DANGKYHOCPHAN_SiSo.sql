-- ==========================================================
-- Tên file : sql/triggers/TRG_DANGKYHOCPHAN_SiSo.sql
-- Module   : Đăng ký học phần (TV3 — Leader)
-- Issue    : #61 Trigger tự động cập nhật sĩ số LHP
-- Mô tả    : Bộ 3 TRIGGER trên bảng DANGKYHOCPHAN tự động
--            +1 / -1 SiSoHienTai của LOPHOCPHAN:
--              - AFTER INSERT   : +1 cho từng LHP được đăng ký
--              - AFTER DELETE   : -1 cho từng LHP bị xóa bản ghi
--              - AFTER UPDATE   : xử lý khi chuyển trạng thái
--                (DA_DANG_KY <-> DA_HUY): cộng/trừ theo đúng
--                hướng chuyển trạng thái.
--    Edge case được xử lý:
--      - UPDATE TrangThaiDangKy: nếu DA_DANG_KY -> DA_HUY thì -1;
--        nếu DA_HUY -> DA_DANG_KY (mở lại) thì +1.
--      - Tránh tăng vọt khi multi-row INSERT/DELETE: cập nhật theo
--        nhóm MaLHP (set-based), không lặp từng dòng.
-- ==========================================================

-- ==========================================================
-- TRIGGER 1: AFTER INSERT — TĂNG SĨ SỐ
-- ==========================================================
IF OBJECT_ID(N'dbo.TRG_DANGKYHOCPHAN_AFTER_INSERT', N'TR') IS NOT NULL
    DROP TRIGGER dbo.TRG_DANGKYHOCPHAN_AFTER_INSERT;
GO
CREATE TRIGGER dbo.TRG_DANGKYHOCPHAN_AFTER_INSERT
ON dbo.DANGKYHOCPHAN
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Chỉ tăng sĩ số cho bản ghi mới ở trạng thái DA_DANG_KY
    UPDATE LHP
    SET SiSoHienTai = LHP.SiSoHienTai + i.SoLuong
    FROM LOPHOCPHAN LHP
    JOIN (
        SELECT MaLHP, COUNT(*) AS SoLuong
        FROM inserted
        WHERE TrangThaiDangKy = N'DA_DANG_KY'
        GROUP BY MaLHP
    ) i ON i.MaLHP = LHP.MaLHP;

    -- Chống tràn sĩ số về mặt dữ liệu (an toàn nếu SP chưa kiểm tra)
    UPDATE LHP
    SET SiSoHienTai = LHP.SiSoToiDa
    FROM LOPHOCPHAN LHP
    WHERE LHP.SiSoHienTai > LHP.SiSoToiDa;
END;
GO

-- ==========================================================
-- TRIGGER 2: AFTER DELETE — GIẢM SĨ SỐ
-- ==========================================================
IF OBJECT_ID(N'dbo.TRG_DANGKYHOCPHAN_AFTER_DELETE', N'TR') IS NOT NULL
    DROP TRIGGER dbo.TRG_DANGKYHOCPHAN_AFTER_DELETE;
GO
CREATE TRIGGER dbo.TRG_DANGKYHOCPHAN_AFTER_DELETE
ON dbo.DANGKYHOCPHAN
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Chỉ giảm sĩ số nếu bản ghi bị xóa đang ở trạng thái hiệu lực
    UPDATE LHP
    SET SiSoHienTai = CASE WHEN LHP.SiSoHienTai >= d.SoLuong
                           THEN LHP.SiSoHienTai - d.SoLuong
                           ELSE 0 END
    FROM LOPHOCPHAN LHP
    JOIN (
        SELECT MaLHP, COUNT(*) AS SoLuong
        FROM deleted
        WHERE TrangThaiDangKy = N'DA_DANG_KY'
        GROUP BY MaLHP
    ) d ON d.MaLHP = LHP.MaLHP;
END;
GO

-- ==========================================================
-- TRIGGER 3: AFTER UPDATE — XỬ LÝ CHUYỂN TRẠNG THÁI
--    Edge case: UPDATE TrangThaiDangKy.
--    - DA_DANG_KY -> DA_HUY  : giảm 1 (sinh viên hủy)
--    - DA_HUY -> DA_DANG_KY  : tăng 1 (mở lại đăng ký)
--    - Đổi GhiChu / NgayDangKy : không ảnh hưởng sĩ số.
-- ==========================================================
IF OBJECT_ID(N'dbo.TRG_DANGKYHOCPHAN_AFTER_UPDATE', N'TR') IS NOT NULL
    DROP TRIGGER dbo.TRG_DANGKYHOCPHAN_AFTER_UPDATE;
GO
CREATE TRIGGER dbo.TRG_DANGKYHOCPHAN_AFTER_UPDATE
ON dbo.DANGKYHOCPHAN
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Những bản ghi chuyển DA_DANG_KY -> khác (giảm sĩ số)
    UPDATE LHP
    SET SiSoHienTai = CASE WHEN LHP.SiSoHienTai >= t.SoLuong
                           THEN LHP.SiSoHienTai - t.SoLuong
                           ELSE 0 END
    FROM LOPHOCPHAN LHP
    JOIN (
        SELECT d.MaLHP, COUNT(*) AS SoLuong
        FROM deleted d
        JOIN inserted i ON i.MaSV = d.MaSV AND i.MaLHP = d.MaLHP
        WHERE d.TrangThaiDangKy = N'DA_DANG_KY'
          AND i.TrangThaiDangKy <> N'DA_DANG_KY'
        GROUP BY d.MaLHP
    ) t ON t.MaLHP = LHP.MaLHP;

    -- Những bản ghi chuyển khác -> DA_DANG_KY (tăng sĩ số)
    UPDATE LHP
    SET SiSoHienTai = LHP.SiSoHienTai + t.SoLuong
    FROM LOPHOCPHAN LHP
    JOIN (
        SELECT i.MaLHP, COUNT(*) AS SoLuong
        FROM inserted i
        JOIN deleted d ON d.MaSV = i.MaSV AND d.MaLHP = i.MaLHP
        WHERE i.TrangThaiDangKy = N'DA_DANG_KY'
          AND d.TrangThaiDangKy <> N'DA_DANG_KY'
        GROUP BY i.MaLHP
    ) t ON t.MaLHP = LHP.MaLHP;
END;
GO

PRINT N'[OK] Issue #61 — Đã tạo 3 Trigger tự động cập nhật SiSoHienTai.';
GO
