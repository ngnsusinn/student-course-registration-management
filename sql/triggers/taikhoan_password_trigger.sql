-- ==========================================================
-- Tên file : sql/triggers/taikhoan_password_trigger.sql
-- Module   : Học phí, Tài khoản & Vận hành hệ thống (TV5)
-- Issue    : #65
--
-- Mô tả:
-- Trigger ghi log mỗi lần thay đổi mật khẩu tài khoản.
--
-- Ghi nhận:
--      + Mã tài khoản
--      + Tên đăng nhập
--      + Thời gian đổi mật khẩu
--      + Địa chỉ IP (nếu có)
--      + Ghi chú
--
-- Chạy sau:
--      00_hocphi_taikhoan_ddl.sql
--      01_nhatky_doimatkhau_ddl.sql
-- ==========================================================

IF OBJECT_ID(N'TRG_LogDoiMatKhau',N'TR') IS NOT NULL
    DROP TRIGGER TRG_LogDoiMatKhau;
GO

CREATE TRIGGER TRG_LogDoiMatKhau
ON TAIKHOAN
AFTER UPDATE
AS
BEGIN

    SET NOCOUNT ON;

    ----------------------------------------------------------
    -- Chỉ xử lý khi cột MatKhau được cập nhật
    ----------------------------------------------------------

    IF UPDATE(MatKhau)
    BEGIN

        INSERT INTO NHATKY_DOIMATKHAU
        (
            MaTaiKhoan,
            TenDangNhap,
            ThoiGianThayDoi,
            DiaChiIP,
            GhiChu
        )

        SELECT

            i.MaTaiKhoan,

            i.TenDangNhap,

            GETDATE(),

            CONVERT(VARCHAR(50),
                    CONNECTIONPROPERTY('client_net_address')),

            N'Thay đổi mật khẩu'

        FROM inserted i

        INNER JOIN deleted d

            ON i.MaTaiKhoan = d.MaTaiKhoan

        WHERE

            i.MatKhau <> d.MatKhau;

    END

END
GO

PRINT N'[OK] Trigger TRG_LogDoiMatKhau đã được tạo.';
GO
