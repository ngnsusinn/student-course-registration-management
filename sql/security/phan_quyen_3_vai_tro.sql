-- ==========================================================
-- Tên file : sql/security/roles_permissions.sql
-- Module   : Phân quyền & Bảo mật hệ thống
-- Issue    : #67
--
-- Mô tả:
-- Thiết lập quyền cho 3 vai trò:
--
--   1. ROLE_SINHVIEN
--      - Chỉ SELECT điểm của chính mình thông qua View.
--
--   2. ROLE_GIANGVIEN
--      - Nhập / cập nhật điểm thông qua Stored Procedure.
--      - Chỉ được thao tác trên lớp học phần do mình phụ trách.
--
--   3. ROLE_PDT
--      - Toàn quyền trên database.
--
-- Nguyên tắc:
--   - Không cấp trực tiếp SELECT bảng điểm cho Sinh viên.
--   - Không cấp trực tiếp INSERT/UPDATE bảng điểm cho Giảng viên.
--   - Kiểm soát dữ liệu thông qua VIEW / PROCEDURE.
--
-- Chạy sau:
--   - Các bảng nghiệp vụ đã được tạo.
--   - Bảng điểm phải tồn tại.
--   - LOPHOCPHAN, GIANGVIEN, SINHVIEN phải tồn tại.
-- ==========================================================


USE [StudentCourseRegistration];
GO


-- ==========================================================
-- PHẦN 1. TẠO DATABASE ROLE
-- ==========================================================

--------------------------------------------------------------
-- ROLE SINH VIÊN
--------------------------------------------------------------

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_principals
    WHERE name = N'ROLE_SINHVIEN'
      AND type = 'R'
)
BEGIN
    CREATE ROLE ROLE_SINHVIEN;
END;
GO


--------------------------------------------------------------
-- ROLE GIẢNG VIÊN
--------------------------------------------------------------

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_principals
    WHERE name = N'ROLE_GIANGVIEN'
      AND type = 'R'
)
BEGIN
    CREATE ROLE ROLE_GIANGVIEN;
END;
GO


--------------------------------------------------------------
-- ROLE PHÒNG ĐÀO TẠO
--------------------------------------------------------------

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_principals
    WHERE name = N'ROLE_PDT'
      AND type = 'R'
)
BEGIN
    CREATE ROLE ROLE_PDT;
END;
GO


PRINT N'[OK] Đã tạo 3 Database Role.';
GO


-- ==========================================================
-- PHẦN 2. VIEW ĐIỂM CỦA SINH VIÊN
-- ==========================================================
--
-- LƯU Ý:
-- Không dùng:
--
--     WHERE MaSV = CURRENT_USER
--
-- vì MaSV là mã sinh viên, còn CURRENT_USER là database user.
--
-- Cách triển khai ở đây sử dụng SESSION_CONTEXT:
--
--     EXEC sys.sp_set_session_context
--          @key = N'MaSV',
--          @value = N'SV001';
--
-- Sau đó View chỉ trả về điểm của MaSV đang được xác thực.
--
-- Ứng dụng đăng nhập phải SET SESSION_CONTEXT sau khi xác thực.
-- ==========================================================


IF OBJECT_ID(N'dbo.VW_DIEM_CUA_TOI', N'V') IS NOT NULL
    DROP VIEW dbo.VW_DIEM_CUA_TOI;
GO


CREATE VIEW dbo.VW_DIEM_CUA_TOI
AS
SELECT
    d.MaSV,
    sv.HoTen,
    d.MaLHP,
    lhp.TenLHP,
    mh.MaMonHoc,
    mh.TenMonHoc,
    d.DiemQuaTrinh,
    d.DiemThi,
    d.DiemTongKet
FROM dbo.BANGDIEM AS d

INNER JOIN dbo.SINHVIEN AS sv
    ON d.MaSV = sv.MaSV

INNER JOIN dbo.LOPHOCPHAN AS lhp
    ON d.MaLHP = lhp.MaLHP

INNER JOIN dbo.MONHOC AS mh
    ON lhp.MaMonHoc = mh.MaMonHoc

WHERE d.MaSV =
      CONVERT(VARCHAR(12),
              SESSION_CONTEXT(N'MaSV'));
GO


PRINT N'[OK] Đã tạo View VW_DIEM_CUA_TOI.';
GO


-- ==========================================================
-- PHẦN 3. STORED PROCEDURE CHO GIẢNG VIÊN NHẬP ĐIỂM
-- ==========================================================
--
-- Procedure này:
--
--   1. Nhận MaGV đang đăng nhập.
--   2. Nhận MaSV.
--   3. Nhận MaLHP.
--   4. Kiểm tra lớp có thuộc giảng viên hay không.
--   5. Nếu đúng -> INSERT / UPDATE điểm.
--   6. Nếu sai -> từ chối.
--
-- Vì vậy không cấp:
--
--     GRANT INSERT ON BANGDIEM
--     GRANT UPDATE ON BANGDIEM
--
-- trực tiếp cho ROLE_GIANGVIEN.
-- ==========================================================


IF OBJECT_ID(N'dbo.SP_GV_NHAP_DIEM', N'P') IS NOT NULL
    DROP PROCEDURE dbo.SP_GV_NHAP_DIEM;
GO


CREATE PROCEDURE dbo.SP_GV_NHAP_DIEM
(
    @MaGV          VARCHAR(10),
    @MaSV          VARCHAR(12),
    @MaLHP         VARCHAR(15),
    @DiemQuaTrinh  DECIMAL(4,2),
    @DiemThi       DECIMAL(4,2)
)
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY

        BEGIN TRANSACTION;


        -- ==================================================
        -- 1. Kiểm tra điểm hợp lệ
        -- ==================================================

        IF @DiemQuaTrinh < 0 OR @DiemQuaTrinh > 10
        BEGIN
            RAISERROR
            (
                N'Điểm quá trình phải nằm trong khoảng từ 0 đến 10.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;
        END;


        IF @DiemThi < 0 OR @DiemThi > 10
        BEGIN
            RAISERROR
            (
                N'Điểm thi phải nằm trong khoảng từ 0 đến 10.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;
        END;


        -- ==================================================
        -- 2. Kiểm tra giảng viên có tồn tại
        -- ==================================================

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.GIANGVIEN
            WHERE MaGV = @MaGV
        )
        BEGIN
            RAISERROR
            (
                N'Giảng viên không tồn tại.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;
        END;


        -- ==================================================
        -- 3. KIỂM TRA GIẢNG VIÊN PHỤ TRÁCH LỚP
        -- ==================================================

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.LOPHOCPHAN
            WHERE MaLHP = @MaLHP
              AND MaGV = @MaGV
        )
        BEGIN
            RAISERROR
            (
                N'Giảng viên không phụ trách lớp học phần này.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;
        END;


        -- ==================================================
        -- 4. Kiểm tra sinh viên có đăng ký lớp
        -- ==================================================

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.DANGKYHOCPHAN
            WHERE MaSV = @MaSV
              AND MaLHP = @MaLHP
              AND TrangThaiDangKy = N'DA_DANG_KY'
        )
        BEGIN
            RAISERROR
            (
                N'Sinh viên chưa đăng ký lớp học phần này.',
                16,
                1
            );

            ROLLBACK TRANSACTION;
            RETURN;
        END;


        -- ==================================================
        -- 5. INSERT / UPDATE điểm
        -- ==================================================

        IF EXISTS
        (
            SELECT 1
            FROM dbo.BANGDIEM
            WHERE MaSV = @MaSV
              AND MaLHP = @MaLHP
        )
        BEGIN

            UPDATE dbo.BANGDIEM

            SET
                DiemQuaTrinh = @DiemQuaTrinh,
                DiemThi = @DiemThi,
                DiemTongKet =
                    ROUND
                    (
                        @DiemQuaTrinh * 0.4
                        +
                        @DiemThi * 0.6,
                        2
                    )

            WHERE MaSV = @MaSV
              AND MaLHP = @MaLHP;

        END
        ELSE
        BEGIN

            INSERT INTO dbo.BANGDIEM
            (
                MaSV,
                MaLHP,
                DiemQuaTrinh,
                DiemThi,
                DiemTongKet
            )
            VALUES
            (
                @MaSV,
                @MaLHP,
                @DiemQuaTrinh,
                @DiemThi,
                ROUND
                (
                    @DiemQuaTrinh * 0.4
                    +
                    @DiemThi * 0.6,
                    2
                )
            );

        END;


        COMMIT TRANSACTION;

        PRINT N'[OK] Nhập/cập nhật điểm thành công.';

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH

END;
GO


PRINT N'[OK] Đã tạo SP_GV_NHAP_DIEM.';
GO


-- ==========================================================
-- PHẦN 4. REVOKE QUYỀN NGUY HIỂM
-- ==========================================================
--
-- Sinh viên:
-- Không được truy cập trực tiếp bảng BANGDIEM.
--
-- Giảng viên:
-- Không được INSERT / UPDATE / DELETE trực tiếp BANGDIEM.
-- Chỉ được thực hiện thông qua Stored Procedure.
-- ==========================================================


REVOKE SELECT
ON dbo.BANGDIEM
FROM ROLE_SINHVIEN;
GO


REVOKE INSERT
ON dbo.BANGDIEM
FROM ROLE_GIANGVIEN;
GO


REVOKE UPDATE
ON dbo.BANGDIEM
FROM ROLE_GIANGVIEN;
GO


REVOKE DELETE
ON dbo.BANGDIEM
FROM ROLE_GIANGVIEN;
GO


PRINT N'[OK] Đã REVOKE quyền truy cập trực tiếp BANGDIEM.';
GO


-- ==========================================================
-- PHẦN 5. GRANT QUYỀN CHO SINH VIÊN
-- ==========================================================
--
-- Sinh viên chỉ được SELECT View.
-- Không được SELECT trực tiếp BANGDIEM.
-- ==========================================================


GRANT SELECT
ON dbo.VW_DIEM_CUA_TOI
TO ROLE_SINHVIEN;
GO


PRINT N'[OK] ROLE_SINHVIEN chỉ được SELECT VW_DIEM_CUA_TOI.';
GO


-- ==========================================================
-- PHẦN 6. GRANT QUYỀN CHO GIẢNG VIÊN
-- ==========================================================
--
-- Không cấp INSERT/UPDATE trực tiếp bảng BANGDIEM.
-- Chỉ cấp EXECUTE Stored Procedure.
-- ==========================================================


GRANT EXECUTE
ON dbo.SP_GV_NHAP_DIEM
TO ROLE_GIANGVIEN;
GO


PRINT N'[OK] ROLE_GIANGVIEN được EXECUTE SP_GV_NHAP_DIEM.';
GO


-- ==========================================================
-- PHẦN 7. PĐT TOÀN QUYỀN
-- ==========================================================
--
-- PĐT được toàn quyền trên database.
--
-- db_owner là Database Role mặc định của SQL Server.
-- Thành viên db_owner có toàn quyền trong database.
-- ==========================================================


IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_role_members drm

    INNER JOIN sys.database_principals r
        ON drm.role_principal_id = r.principal_id

    INNER JOIN sys.database_principals u
        ON drm.member_principal_id = u.principal_id

    WHERE r.name = N'db_owner'
      AND u.name = N'ROLE_PDT'
)
BEGIN

    ALTER ROLE db_owner
    ADD MEMBER ROLE_PDT;

END;
GO


PRINT N'[OK] ROLE_PDT đã được cấp toàn quyền database.';
GO


-- ==========================================================
-- PHẦN 8. KIỂM TRA PHÂN QUYỀN
-- ==========================================================


SELECT
    r.name AS RoleName,
    p.permission_name,
    p.state_desc,
    p.class_desc
FROM sys.database_principals AS r

LEFT JOIN sys.database_permissions AS p
    ON r.principal_id = p.grantee_principal_id

WHERE r.name IN
(
    N'ROLE_SINHVIEN',
    N'ROLE_GIANGVIEN',
    N'ROLE_PDT'
)

ORDER BY
    r.name,
    p.permission_name;
GO


PRINT N'==================================================';
PRINT N'[OK] HOÀN THÀNH ISSUE #67 - PHÂN QUYỀN HỆ THỐNG';
PRINT N'==================================================';
GO