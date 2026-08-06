/*
==========================================================
File: sql/procedures/hocphi_taikhoan_procedures.sql
Module: Học phí, Tài khoản & Vận hành hệ thống
Issue : #56

Mô tả:
- SP_TinhHocPhi
- SP_TaoTaiKhoanSinhVien
- SP_TaoTaiKhoanGiangVien
==========================================================
*/

PRINT N'========== TẠO STORED PROCEDURE =========='
GO

/*==========================================================
SP 1: TÍNH HỌC PHÍ CHO SINH VIÊN
============================================================
Chức năng:
- Kiểm tra sinh viên tồn tại
- Kiểm tra học kỳ tồn tại
- Tính tổng số tín chỉ đã đăng ký
- Tính tổng học phí
- Nếu đã có phiếu học phí -> UPDATE
- Nếu chưa có -> INSERT
==========================================================*/

IF OBJECT_ID('SP_TinhHocPhi', 'P') IS NOT NULL
    DROP PROCEDURE SP_TinhHocPhi;
GO

CREATE PROCEDURE SP_TinhHocPhi
(
    @MaSV VARCHAR(12),
    @MaHocKy VARCHAR(10),
    @DonGiaTinChi DECIMAL(12,0)
)
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY

        BEGIN TRANSACTION;

        --------------------------------------------------
        -- Kiểm tra sinh viên
        --------------------------------------------------

        IF NOT EXISTS
        (
            SELECT *
            FROM SINHVIEN
            WHERE MaSV = @MaSV
        )
        BEGIN
            RAISERROR(N'Sinh viên không tồn tại.',16,1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        --------------------------------------------------
        -- Kiểm tra học kỳ
        --------------------------------------------------

        IF NOT EXISTS
        (
            SELECT *
            FROM HOCKY
            WHERE MaHocKy=@MaHocKy
        )
        BEGIN
            RAISERROR(N'Học kỳ không tồn tại.',16,1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        --------------------------------------------------
        -- Tính tổng số tín chỉ
        --------------------------------------------------

        DECLARE @TongTinChi INT;

        SELECT

            @TongTinChi = ISNULL(SUM(mh.SoTinChi),0)

        FROM DANGKYHOCPHAN dk

        INNER JOIN LOPHOCPHAN lhp
            ON dk.MaLHP = lhp.MaLHP

        INNER JOIN MONHOC mh
            ON lhp.MaMonHoc = mh.MaMonHoc

        WHERE

            dk.MaSV = @MaSV

            AND lhp.MaHocKy = @MaHocKy

            AND dk.TrangThaiDangKy = N'DA_DANG_KY';

        --------------------------------------------------
        -- Không có học phần
        --------------------------------------------------

        IF @TongTinChi = 0
        BEGIN
            RAISERROR(N'Sinh viên chưa đăng ký học phần.',16,1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        --------------------------------------------------
        -- Tính tiền
        --------------------------------------------------

        DECLARE @TongTien DECIMAL(15,0);

        SET @TongTien = @TongTinChi * @DonGiaTinChi;

        --------------------------------------------------
        -- Nếu đã có học phí
        --------------------------------------------------

        IF EXISTS
        (
            SELECT *
            FROM HOCPHI
            WHERE MaSV=@MaSV
            AND MaHocKy=@MaHocKy
        )

        BEGIN

            UPDATE HOCPHI

            SET

                SoTinChi=@TongTinChi,

                DonGiaTinChi=@DonGiaTinChi,

                TongTien=@TongTien,

                TrangThai=
                CASE

                    WHEN DaNop>=@TongTien
                    THEN N'DA_THANH_TOAN'

                    WHEN DaNop=0
                    THEN N'CHUA_THANH_TOAN'

                    ELSE N'DANG_XU_LY'

                END

            WHERE

                MaSV=@MaSV

                AND MaHocKy=@MaHocKy;

        END

        --------------------------------------------------
        -- Chưa có học phí
        --------------------------------------------------

        ELSE

        BEGIN

            INSERT INTO HOCPHI
            (

                MaHocPhi,

                MaSV,

                MaHocKy,

                SoTinChi,

                DonGiaTinChi,

                TongTien,

                DaNop,

                TrangThai

            )

            VALUES
            (

                CONCAT('HP_',@MaSV,'_',@MaHocKy),

                @MaSV,

                @MaHocKy,

                @TongTinChi,

                @DonGiaTinChi,

                @TongTien,

                0,

                N'CHUA_THANH_TOAN'

            );

        END

        COMMIT TRANSACTION;

        PRINT N'Tính học phí thành công.';

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT N'Lỗi: ' + ERROR_MESSAGE();

    END CATCH

END
GO

PRINT N'Đã tạo SP_TinhHocPhi thành công.'
GO
/*==========================================================
SP 2: TẠO TÀI KHOẢN CHO SINH VIÊN
============================================================
Chức năng:
- Kiểm tra sinh viên tồn tại
- Không tạo trùng tài khoản
- Tự động tạo tài khoản khi thêm sinh viên
==========================================================*/

IF OBJECT_ID('SP_TaoTaiKhoanSinhVien', 'P') IS NOT NULL
    DROP PROCEDURE SP_TaoTaiKhoanSinhVien;
GO

CREATE PROCEDURE SP_TaoTaiKhoanSinhVien
(
    @MaSV VARCHAR(12)
)
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY

        BEGIN TRANSACTION;

        --------------------------------------------------
        -- Kiểm tra sinh viên
        --------------------------------------------------

        IF NOT EXISTS
        (
            SELECT *
            FROM SINHVIEN
            WHERE MaSV = @MaSV
        )
        BEGIN
            RAISERROR(N'Sinh viên không tồn tại.',16,1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        --------------------------------------------------
        -- Kiểm tra tài khoản đã tồn tại
        --------------------------------------------------

        IF EXISTS
        (
            SELECT *
            FROM TAIKHOAN
            WHERE MaSV = @MaSV
        )
        BEGIN
            RAISERROR(N'Sinh viên đã có tài khoản.',16,1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        INSERT INTO TAIKHOAN
        (
            MaTaiKhoan,
            TenDangNhap,
            MatKhau,
            Email,
            TrangThai,
            MaVaiTro,
            MaSV,
            MaGV
        )
        SELECT
            CONCAT('TK_', MaSV),
            MaSV,
            '123456',              -- Thực tế nên lưu mật khẩu đã băm (hash)
            Email,
            N'ACTIVE',
            'STUDENT',
            MaSV,
            NULL
        FROM SINHVIEN
        WHERE MaSV = @MaSV;

        COMMIT TRANSACTION;

        PRINT N'Tạo tài khoản sinh viên thành công.';

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT N'Lỗi: ' + ERROR_MESSAGE();

    END CATCH

END
GO


/*==========================================================
SP 3: TẠO TÀI KHOẢN CHO GIẢNG VIÊN
============================================================
Chức năng:
- Kiểm tra giảng viên tồn tại
- Không tạo trùng tài khoản
- Tự động tạo tài khoản khi thêm giảng viên
==========================================================*/

IF OBJECT_ID('SP_TaoTaiKhoanGiangVien', 'P') IS NOT NULL
    DROP PROCEDURE SP_TaoTaiKhoanGiangVien;
GO

CREATE PROCEDURE SP_TaoTaiKhoanGiangVien
(
    @MaGV VARCHAR(10)
)
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY

        BEGIN TRANSACTION;

        --------------------------------------------------
        -- Kiểm tra giảng viên
        --------------------------------------------------

        IF NOT EXISTS
        (
            SELECT *
            FROM GIANGVIEN
            WHERE MaGV = @MaGV
        )
        BEGIN
            RAISERROR(N'Giảng viên không tồn tại.',16,1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        --------------------------------------------------
        -- Kiểm tra tài khoản
        --------------------------------------------------

        IF EXISTS
        (
            SELECT *
            FROM TAIKHOAN
            WHERE MaGV = @MaGV
        )
        BEGIN
            RAISERROR(N'Giảng viên đã có tài khoản.',16,1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        INSERT INTO TAIKHOAN
        (
            MaTaiKhoan,
            TenDangNhap,
            MatKhau,
            Email,
            TrangThai,
            MaVaiTro,
            MaSV,
            MaGV
        )
        SELECT
            CONCAT('TK_', MaGV),
            MaGV,
            '123456',              -- Thực tế nên lưu mật khẩu đã băm (hash)
            Email,
            N'ACTIVE',
            'LECTURER',
            NULL,
            MaGV
        FROM GIANGVIEN
        WHERE MaGV = @MaGV;

        COMMIT TRANSACTION;

        PRINT N'Tạo tài khoản giảng viên thành công.';

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT N'Lỗi: ' + ERROR_MESSAGE();

    END CATCH

END
GO


PRINT N'==============================================='
PRINT N'HOÀN THÀNH ISSUE #56'
PRINT N'Đã tạo Stored Procedure tính học phí và tạo tài khoản tự động.'
PRINT N'==============================================='
GO
