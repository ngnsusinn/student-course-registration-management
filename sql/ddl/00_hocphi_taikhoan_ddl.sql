-- ==========================================================
-- Tên file : sql/ddl/00_hocphi_taikhoan_ddl.sql
-- Module   : Học phí, Tài khoản & Vận hành hệ thống (TV5)
-- Mô tả    : VAITRO + TAIKHOAN + HOCPHI theo docs/erd_hocphi_taikhoan.md.
--            HOCPHI.MaSV tham chiếu SINHVIEN (TV1);
--            TAIKHOAN.MaSV/MaGV tham chiếu SINHVIEN/GIANGVIEN (TV1/TV2).
-- Chạy sau  : 00_danh_muc_hoso_sv_ddl.sql, 00_hocphan_giangvien_ddl.sql
-- ==========================================================

IF OBJECT_ID(N'HOCPHI', N'U') IS NOT NULL DROP TABLE HOCPHI;
GO
IF OBJECT_ID(N'TAIKHOAN', N'U') IS NOT NULL DROP TABLE TAIKHOAN;
GO
IF OBJECT_ID(N'VAITRO', N'U') IS NOT NULL DROP TABLE VAITRO;
GO

-- ==========================================================
-- 1. VAITRO
-- ==========================================================
CREATE TABLE VAITRO (
    MaVaiTro        VARCHAR(10)     NOT NULL,
    TenVaiTro       VARCHAR(30)     NOT NULL,
    MoTa            NVARCHAR(255)   NULL,

    CONSTRAINT PK_VAITRO PRIMARY KEY (MaVaiTro),
    CONSTRAINT UQ_VAITRO_TenVaiTro UNIQUE (TenVaiTro)
);
GO

-- ==========================================================
-- 2. TAIKHOAN
-- ==========================================================
CREATE TABLE TAIKHOAN (
    MaTaiKhoan      VARCHAR(15)     NOT NULL,
    TenDangNhap     VARCHAR(30)     NOT NULL,
    MatKhau         VARCHAR(255)    NOT NULL,   -- lưu mật khẩu đã băm (hash)
    Email           VARCHAR(100)    NULL,
    TrangThai       VARCHAR(10)     NOT NULL DEFAULT N'ACTIVE',
    MaVaiTro        VARCHAR(10)     NOT NULL,
    MaSV            VARCHAR(12)     NULL,
    MaGV            VARCHAR(10)     NULL,

    CONSTRAINT PK_TAIKHOAN PRIMARY KEY (MaTaiKhoan),
    CONSTRAINT UQ_TAIKHOAN_TenDangNhap UNIQUE (TenDangNhap),
    CONSTRAINT CK_TAIKHOAN_TrangThai CHECK (TrangThai IN (N'ACTIVE', N'LOCKED')),
    CONSTRAINT FK_TAIKHOAN_VAITRO FOREIGN KEY (MaVaiTro)
        REFERENCES VAITRO(MaVaiTro)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT FK_TAIKHOAN_SINHVIEN FOREIGN KEY (MaSV)
        REFERENCES SINHVIEN(MaSV)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT FK_TAIKHOAN_GIANGVIEN FOREIGN KEY (MaGV)
        REFERENCES GIANGVIEN(MaGV)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    -- Một tài khoản thuộc về: SV, GV, hoặc tài khoản hệ thống (PĐT)
    -- (PĐT không gắn MaSV cũng không gắn MaGV — ví dụ tài khoản admin)
    CONSTRAINT CK_TAIKHOAN_MotTrongHai CHECK (
        (MaSV IS NOT NULL AND MaGV IS NULL)      -- tài khoản sinh viên
        OR (MaGV IS NOT NULL AND MaSV IS NULL)   -- tài khoản giảng viên
        OR (MaSV IS NULL AND MaGV IS NULL)       -- tài khoản hệ thống / PĐT
    )
);
GO

-- ==========================================================
-- 3. HOCPHI
-- ==========================================================
CREATE TABLE HOCPHI (
    MaHocPhi        VARCHAR(15)     NOT NULL,
    MaSV            VARCHAR(12)     NOT NULL,
    MaHocKy         VARCHAR(10)     NOT NULL,
    SoTinChi        INT             NOT NULL,
    DonGiaTinChi    DECIMAL(12,0)   NOT NULL,
    TongTien        DECIMAL(15,0)   NOT NULL,
    DaNop           DECIMAL(15,0)   NOT NULL DEFAULT 0,
    TrangThai       NVARCHAR(30)    NOT NULL DEFAULT N'CHUA_THANH_TOAN',

    CONSTRAINT PK_HOCPHI PRIMARY KEY (MaHocPhi),
    CONSTRAINT CK_HOCPHI_SoTinChi CHECK (SoTinChi > 0),
    CONSTRAINT CK_HOCPHI_DonGia CHECK (DonGiaTinChi > 0),
    CONSTRAINT CK_HOCPHI_TongTien CHECK (TongTien >= 0),
    CONSTRAINT CK_HOCPHI_DaNop CHECK (DaNop >= 0 AND DaNop <= TongTien),
    CONSTRAINT CK_HOCPHI_TrangThai CHECK (TrangThai IN (N'CHUA_THANH_TOAN', N'DANG_XU_LY', N'DA_THANH_TOAN', N'QUA_HAN')),
    CONSTRAINT FK_HOCPHI_SINHVIEN FOREIGN KEY (MaSV)
        REFERENCES SINHVIEN(MaSV)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT FK_HOCPHI_HOCKY FOREIGN KEY (MaHocKy)
        REFERENCES HOCKY(MaHocKy)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO

PRINT N'[OK] Module 5 — Đã tạo VAITRO + TAIKHOAN + HOCPHI.';
GO
