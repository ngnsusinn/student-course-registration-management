-- ==========================================================
-- Tên file : sql/ddl/00_danh_muc_hoso_sv_ddl.sql
-- Module   : Danh mục hệ thống & Hồ sơ sinh viên (TV1)
-- Mô tả    : Bảng NỀN được DANGKYHOCPHAN (TV3) tham chiếu.
--            Giữ đúng thiết kế docs/Ho_So_Sinh_Vien.md +
--            docs/erd_dangky_hocphan.md (đổi LOP->LOP_SINHHOAT,
--            SINH_VIEN->SINHVIEN, MaLop->MaLopSH để thống nhất
--            khóa liên module với ERD trung tâm TV3).
-- Chạy trước : (rỗng) — bảng nền đầu tiên
-- ==========================================================

IF OBJECT_ID(N'CHUONGTRINHDAOTAO', N'U') IS NOT NULL DROP TABLE CHUONGTRINHDAOTAO;
GO
IF OBJECT_ID(N'SINHVIEN', N'U') IS NOT NULL DROP TABLE SINHVIEN;
GO
IF OBJECT_ID(N'LOP_SINHHOAT', N'U') IS NOT NULL DROP TABLE LOP_SINHHOAT;
GO
IF OBJECT_ID(N'NGANH', N'U') IS NOT NULL DROP TABLE NGANH;
GO
IF OBJECT_ID(N'KHOA', N'U') IS NOT NULL DROP TABLE KHOA;
GO

-- ==========================================================
-- 1. KHOA
-- ==========================================================
CREATE TABLE KHOA (
    MaKhoa          VARCHAR(10)     NOT NULL,
    TenKhoa         NVARCHAR(100)   NOT NULL,
    DienThoaiKhoa   VARCHAR(15)     NULL,
    EmailKhoa       VARCHAR(100)    NOT NULL,

    CONSTRAINT PK_KHOA PRIMARY KEY (MaKhoa),
    CONSTRAINT UQ_KHOA_TenKhoa UNIQUE (TenKhoa),
    CONSTRAINT UQ_KHOA_EmailKhoa UNIQUE (EmailKhoa)
);
GO

-- ==========================================================
-- 2. NGANH
-- ==========================================================
CREATE TABLE NGANH (
    MaNganh         VARCHAR(10)     NOT NULL,
    TenNganh        NVARCHAR(100)   NOT NULL,
    ThoiGianDaoTao  DECIMAL(3,1)    NOT NULL,
    MaKhoa          VARCHAR(10)     NOT NULL,

    CONSTRAINT PK_NGANH PRIMARY KEY (MaNganh),
    CONSTRAINT UQ_NGANH_TenNganh UNIQUE (TenNganh),
    CONSTRAINT CK_NGANH_ThoiGianDaoTao CHECK (ThoiGianDaoTao > 0),
    CONSTRAINT FK_NGANH_KHOA FOREIGN KEY (MaKhoa)
        REFERENCES KHOA(MaKhoa)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO

-- ==========================================================
-- 3. LOP_SINHHOAT
-- ==========================================================
CREATE TABLE LOP_SINHHOAT (
    MaLopSH         VARCHAR(15)     NOT NULL,
    TenLopSH        NVARCHAR(100)   NOT NULL,
    NienKhoa        INT             NOT NULL,
    MaNganh         VARCHAR(10)     NOT NULL,

    CONSTRAINT PK_LOP_SINHHOAT PRIMARY KEY (MaLopSH),
    CONSTRAINT CK_LOP_NienKhoa CHECK (NienKhoa BETWEEN 2000 AND 2030),
    CONSTRAINT FK_LOP_SINHHOAT_NGANH FOREIGN KEY (MaNganh)
        REFERENCES NGANH(MaNganh)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO

-- ==========================================================
-- 4. SINHVIEN
-- ==========================================================
CREATE TABLE SINHVIEN (
    MaSV            VARCHAR(12)     NOT NULL,
    HoTen           NVARCHAR(100)   NOT NULL,
    NgaySinh        DATE            NOT NULL,
    GioiTinh        TINYINT         NOT NULL DEFAULT 1,  -- 1: Nam, 0: Nữ
    Email           VARCHAR(100)    NOT NULL,
    SoDienThoai     VARCHAR(15)     NOT NULL,
    QueQuan         NVARCHAR(100)   NULL,
    TrangThaiHoc    TINYINT         NOT NULL DEFAULT 1,  -- 1: Đang học, 2: Bảo lưu, 3: Thôi học
    MaLopSH         VARCHAR(15)     NOT NULL,

    CONSTRAINT PK_SINHVIEN PRIMARY KEY (MaSV),
    CONSTRAINT UQ_SINHVIEN_Email UNIQUE (Email),
    CONSTRAINT CK_SINHVIEN_GioiTinh CHECK (GioiTinh IN (0, 1)),
    CONSTRAINT CK_SINHVIEN_TrangThaiHoc CHECK (TrangThaiHoc IN (1, 2, 3)),
    CONSTRAINT FK_SINHVIEN_LOP_SINHHOAT FOREIGN KEY (MaLopSH)
        REFERENCES LOP_SINHHOAT(MaLopSH)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO

-- ==========================================================
-- 5. CHUONGTRINHDAOTAO (bảng trung gian Ngành - Môn học - Học kỳ)
--    PK ghép (MaNganh, MaMonHoc). MaMonHoc sẽ được tạo ở
--    module Học phần (TV2) — file 00_hocphan_giangvien_ddl.sql.
-- ==========================================================
CREATE TABLE CHUONGTRINHDAOTAO (
    MaNganh         VARCHAR(10)     NOT NULL,
    MaMonHoc        VARCHAR(10)     NOT NULL,
    HocKyDuKien     INT             NOT NULL,
    BatBuoc         BIT             NOT NULL DEFAULT 1,

    CONSTRAINT PK_CHUONGTRINHDAOTAO PRIMARY KEY (MaNganh, MaMonHoc),
    CONSTRAINT CK_CTDT_HocKyDuKien CHECK (HocKyDuKien > 0),
    CONSTRAINT FK_CTDT_NGANH FOREIGN KEY (MaNganh)
        REFERENCES NGANH(MaNganh)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO

PRINT N'[OK] Module 1 — Danh mục & Hồ sơ sinh viên đã tạo xong (KHOA, NGANH, LOP_SINHHOAT, SINHVIEN, CHUONGTRINHDAOTAO).';
GO
