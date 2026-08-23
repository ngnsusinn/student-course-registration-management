-- ==========================================================
-- Ten file : mysql/ddl/00_danh_muc_hoso_sv_ddl.sql
-- Module   : Danh muc he thong & Ho so sinh vien (TV1)
-- Mo ta    : Ban dich T-SQL -> MySQL (5.7+).
--            Bang NEN duoc DANGKYHOCPHAN (TV3) tham chieu.
-- Luu y    : NVARCHAR -> VARCHAR (charset utf8mb4 cua database);
--            CHECK duoc giu lam tai lieu (MySQL 5.7 chi parse,
--            khong enforce; MySQL 8.0.16+ se enforce).
-- ==========================================================

DROP TABLE IF EXISTS CHUONGTRINHDAOTAO;
DROP TABLE IF EXISTS SINHVIEN;
DROP TABLE IF EXISTS LOP_SINHHOAT;
DROP TABLE IF EXISTS NGANH;
DROP TABLE IF EXISTS KHOA;

-- ==========================================================
-- 1. KHOA
-- ==========================================================
CREATE TABLE KHOA (
    MaKhoa          VARCHAR(10)     NOT NULL,
    TenKhoa         VARCHAR(100)    NOT NULL,
    DienThoaiKhoa   VARCHAR(15)     NULL,
    EmailKhoa       VARCHAR(100)    NOT NULL,

    CONSTRAINT PK_KHOA PRIMARY KEY (MaKhoa),
    CONSTRAINT UQ_KHOA_TenKhoa UNIQUE (TenKhoa),
    CONSTRAINT UQ_KHOA_EmailKhoa UNIQUE (EmailKhoa)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================================
-- 2. NGANH
-- ==========================================================
CREATE TABLE NGANH (
    MaNganh         VARCHAR(10)     NOT NULL,
    TenNganh        VARCHAR(100)    NOT NULL,
    ThoiGianDaoTao  DECIMAL(3,1)    NOT NULL,
    MaKhoa          VARCHAR(10)     NOT NULL,

    CONSTRAINT PK_NGANH PRIMARY KEY (MaNganh),
    CONSTRAINT UQ_NGANH_TenNganh UNIQUE (TenNganh),
    CONSTRAINT CK_NGANH_ThoiGianDaoTao CHECK (ThoiGianDaoTao > 0),
    CONSTRAINT FK_NGANH_KHOA FOREIGN KEY (MaKhoa)
        REFERENCES KHOA(MaKhoa)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================================
-- 3. LOP_SINHHOAT
-- ==========================================================
CREATE TABLE LOP_SINHHOAT (
    MaLopSH         VARCHAR(15)     NOT NULL,
    TenLopSH        VARCHAR(100)    NOT NULL,
    NienKhoa        INT             NOT NULL,
    MaNganh         VARCHAR(10)     NOT NULL,

    CONSTRAINT PK_LOP_SINHHOAT PRIMARY KEY (MaLopSH),
    CONSTRAINT CK_LOP_NienKhoa CHECK (NienKhoa BETWEEN 2000 AND 2030),
    CONSTRAINT FK_LOP_SINHHOAT_NGANH FOREIGN KEY (MaNganh)
        REFERENCES NGANH(MaNganh)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================================
-- 4. SINHVIEN
-- ==========================================================
CREATE TABLE SINHVIEN (
    MaSV            VARCHAR(12)     NOT NULL,
    HoTen           VARCHAR(100)    NOT NULL,
    NgaySinh        DATE            NOT NULL,
    GioiTinh        TINYINT         NOT NULL DEFAULT 1,  -- 1: Nam, 0: Nu
    Email           VARCHAR(100)    NOT NULL,
    SoDienThoai     VARCHAR(15)     NOT NULL,
    QueQuan         VARCHAR(100)    NULL,
    TrangThaiHoc    TINYINT         NOT NULL DEFAULT 1,  -- 1: Dang hoc, 2: Bao luu, 3: Thoi hoc
    MaLopSH         VARCHAR(15)     NOT NULL,

    CONSTRAINT PK_SINHVIEN PRIMARY KEY (MaSV),
    CONSTRAINT UQ_SINHVIEN_Email UNIQUE (Email),
    CONSTRAINT CK_SINHVIEN_GioiTinh CHECK (GioiTinh IN (0, 1)),
    CONSTRAINT CK_SINHVIEN_TrangThaiHoc CHECK (TrangThaiHoc IN (1, 2, 3)),
    CONSTRAINT FK_SINHVIEN_LOP_SINHHOAT FOREIGN KEY (MaLopSH)
        REFERENCES LOP_SINHHOAT(MaLopSH)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================================
-- 5. CHUONGTRINHDAOTAO (bang trung gian Nganh - Mon hoc - Hoc ky)
--    PK ghep (MaNganh, MaMonHoc). FK toi MONHOC duoc tao o
--    file 00_hocphan_giangvien_ddl.sql (vi MONHOC tao sau).
-- ==========================================================
CREATE TABLE CHUONGTRINHDAOTAO (
    MaNganh         VARCHAR(10)     NOT NULL,
    MaMonHoc        VARCHAR(10)     NOT NULL,
    HocKyDuKien     INT             NOT NULL,
    BatBuoc         TINYINT(1)      NOT NULL DEFAULT 1,

    CONSTRAINT PK_CHUONGTRINHDAOTAO PRIMARY KEY (MaNganh, MaMonHoc),
    CONSTRAINT CK_CTDT_HocKyDuKien CHECK (HocKyDuKien > 0),
    CONSTRAINT FK_CTDT_NGANH FOREIGN KEY (MaNganh)
        REFERENCES NGANH(MaNganh)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
