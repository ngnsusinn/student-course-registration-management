-- ==========================================================
-- Tên file : sql/ddl/10_dangky_hocphan_ddl.sql
-- Module   : Đăng ký học phần (TV3 — Leader)
-- Issue    : #18 Viết DDL Đăng ký học phần
-- Mô tả    : CREATE TABLE bảng trung tâm DANGKYHOCPHAN:
--              - PK ghép (MaSV, MaLHP)
--              - 2 FK tới SINHVIEN và LOPHOCPHAN
--              - CHECK TrangThaiDangKy
--              - Non-clustered Index riêng MaSV, MaLHP
--              - Thiết kế sẵn cho Transaction tuần 5
--              (trigger +1/-1 SiSoHienTai nằm ở sql/triggers/)
-- Chạy sau  : 00_danh_muc_hoso_sv_ddl.sql, 00_hocphan_giangvien_ddl.sql
-- ==========================================================

IF OBJECT_ID(N'DANGKYHOCPHAN', N'U') IS NOT NULL DROP TABLE DANGKYHOCPHAN;
GO

-- ==========================================================
-- BẢNG TRUNG TÂM DANGKYHOCPHAN
-- ==========================================================
CREATE TABLE DANGKYHOCPHAN (
    MaSV                VARCHAR(12)     NOT NULL,
    MaLHP               VARCHAR(15)     NOT NULL,
    NgayDangKy          DATETIME        NOT NULL DEFAULT GETDATE(),
    TrangThaiDangKy     NVARCHAR(20)    NOT NULL DEFAULT N'DA_DANG_KY',
    GhiChu              NVARCHAR(255)   NULL,

    -- 1. Khóa chính ghép (MaSV, MaLHP)
    CONSTRAINT PK_DANGKYHOCPHAN PRIMARY KEY (MaSV, MaLHP),

    -- 2. FK 1: MaSV -> SINHVIEN
    CONSTRAINT FK_DKHP_SINHVIEN FOREIGN KEY (MaSV)
        REFERENCES SINHVIEN(MaSV)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,

    -- 3. FK 2: MaLHP -> LOPHOCPHAN
    CONSTRAINT FK_DKHP_LOPHOCPHAN FOREIGN KEY (MaLHP)
        REFERENCES LOPHOCPHAN(MaLHP)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,

    -- 4. CHECK trạng thái đăng ký
    CONSTRAINT CK_DKHP_TrangThaiDangKy CHECK (
        TrangThaiDangKy IN (N'DA_DANG_KY', N'DA_HUY', N'CHO_XAC_NHAN')
    )
);
GO

-- ==========================================================
-- CHÚ THÍCH THIẾT KẾ
-- ----------------------------------------------------------
-- 1. PK ghép (MaSV, MaLHP): đảm bảo 1 SV không thể đăng ký
--    trùng 1 LHP (thay thế UNIQUE(MaSV,MaLHP) ghi trong backlog
--    vì PK ghép đã hàm chứa tính duy nhất).
-- 2. TrangThaiDangKy: DA_DANG_KY | DA_HUY | CHO_XAC_NHAN.
-- 3. Hai Non-clustered Index riêng MaSV & MaLHP phục vụ 2 chiều
--    tra cứu (Issue #62) được tạo ở sql/indexes/dangky_hocphan_indexes.sql
--    (bàn giao riêng theo đúng backlog — không tạo trùng tại đây).
-- 4. Ràng buộc "cùng học kỳ" giữa (MaSV, MaLHP) không thể hiện
--    bằng FK đơn thuần (LOPHOCPHAN không chứa MaSV) nên sẽ được
--    kiểm tra trong SP_DangKyHocPhan (Ràng buộc 1 — Hạn đăng ký),
--    đúng tinh thần phân tích 5 ràng buộc ở docs/analysis_dangky_hocphan.md.
-- ==========================================================

PRINT N'[OK] Module 3 — Đã tạo bảng trung tâm DANGKYHOCPHAN (Index tạo ở sql/indexes/).';
GO
