-- ==========================================================
-- Ten file : mysql/ddl/00_hocphi_taikhoan_ddl.sql
-- Module   : Hoc phi, Tai khoan & Van hanh he thong (TV5)
-- Mo ta    : VAITRO + TAIKHOAN + HOCPHI + NHATKY_DOIMATKHAU
--            (bang NHATKY_DOIMATKHAU duoc bo sung vi file DDL
--            goc trong repo T-SQL bi trong nhung trigger
--            TRG_LogDoiMatKhau can ghi log vao bang nay).
-- ==========================================================

DROP TABLE IF EXISTS NHATKY_DOIMATKHAU;
DROP TABLE IF EXISTS HOCPHI;
DROP TABLE IF EXISTS TAIKHOAN;
DROP TABLE IF EXISTS VAITRO;

-- ==========================================================
-- 1. VAITRO
-- ==========================================================
CREATE TABLE VAITRO (
    MaVaiTro        VARCHAR(10)     NOT NULL,
    TenVaiTro       VARCHAR(30)     NOT NULL,
    MoTa            VARCHAR(255)    NULL,

    CONSTRAINT PK_VAITRO PRIMARY KEY (MaVaiTro),
    CONSTRAINT UQ_VAITRO_TenVaiTro UNIQUE (TenVaiTro)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================================
-- 2. TAIKHOAN
-- ==========================================================
CREATE TABLE TAIKHOAN (
    MaTaiKhoan      VARCHAR(15)     NOT NULL,
    TenDangNhap     VARCHAR(30)     NOT NULL,
    MatKhau         VARCHAR(255)    NOT NULL,   -- luu mat khau da bam (SHA2-256)
    Email           VARCHAR(100)    NULL,
    TrangThai       VARCHAR(10)     NOT NULL DEFAULT 'ACTIVE',
    MaVaiTro        VARCHAR(10)     NOT NULL,
    MaSV            VARCHAR(12)     NULL,
    MaGV            VARCHAR(10)     NULL,

    CONSTRAINT PK_TAIKHOAN PRIMARY KEY (MaTaiKhoan),
    CONSTRAINT UQ_TAIKHOAN_TenDangNhap UNIQUE (TenDangNhap),
    CONSTRAINT CK_TAIKHOAN_TrangThai CHECK (TrangThai IN ('ACTIVE', 'LOCKED')),
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
    CONSTRAINT CK_TAIKHOAN_MotTrongHai CHECK (
        (MaSV IS NOT NULL AND MaGV IS NULL)
        OR (MaGV IS NOT NULL AND MaSV IS NULL)
        OR (MaSV IS NULL AND MaGV IS NULL)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
    TrangThai       VARCHAR(30)     NOT NULL DEFAULT 'CHUA_THANH_TOAN',

    CONSTRAINT PK_HOCPHI PRIMARY KEY (MaHocPhi),
    CONSTRAINT UQ_HOCPHI_SV_HocKy UNIQUE (MaSV, MaHocKy),
    CONSTRAINT CK_HOCPHI_SoTinChi CHECK (SoTinChi > 0),
    CONSTRAINT CK_HOCPHI_DonGia CHECK (DonGiaTinChi > 0),
    CONSTRAINT CK_HOCPHI_TongTien CHECK (TongTien >= 0),
    CONSTRAINT CK_HOCPHI_DaNop CHECK (DaNop >= 0 AND DaNop <= TongTien),
    CONSTRAINT CK_HOCPHI_TrangThai CHECK (TrangThai IN ('CHUA_THANH_TOAN', 'DANG_XU_LY', 'DA_THANH_TOAN', 'QUA_HAN')),
    CONSTRAINT FK_HOCPHI_SINHVIEN FOREIGN KEY (MaSV)
        REFERENCES SINHVIEN(MaSV)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT FK_HOCPHI_HOCKY FOREIGN KEY (MaHocKy)
        REFERENCES HOCKY(MaHocKy)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================================
-- 4. NHATKY_DOIMATKHAU (log doi mat khau — phuc vu trigger
--    TRG_LogDoiMatKhau; DDL goc trong repo T-SQL bi thieu)
-- ==========================================================
CREATE TABLE NHATKY_DOIMATKHAU (
    MaNhatKy        BIGINT          NOT NULL AUTO_INCREMENT,
    MaTaiKhoan      VARCHAR(15)     NOT NULL,
    TenDangNhap     VARCHAR(30)     NOT NULL,
    ThoiGianThayDoi DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    DiaChiIP        VARCHAR(50)     NULL,
    GhiChu          VARCHAR(255)    NULL,

    CONSTRAINT PK_NHATKY_DOIMATKHAU PRIMARY KEY (MaNhatKy),
    CONSTRAINT FK_NKDMK_TAIKHOAN FOREIGN KEY (MaTaiKhoan)
        REFERENCES TAIKHOAN(MaTaiKhoan)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
