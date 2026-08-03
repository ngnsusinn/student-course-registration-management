-- ==========================================================
-- Tên file : sql/ddl/00_hocphan_giangvien_ddl.sql
-- Module   : Học phần, Giảng viên & Mở lớp học phần (TV2)
-- Mô tả    : 7 bảng TV2 theo docs/ERD_hocphan_giangvien_molophocphan.md.
--            Gồm MONHOC, MONHOC_TIENQUYET, GIANGVIEN, HOCKY,
--            PHONGHOC, LOPHOCPHAN, LICHHOC — là bảng CHA của
--            DANGKYHOCPHAN (TV3). LICHHOC dùng ON DELETE CASCADE
--            khi xóa LOPHOCPHAN (theo backlog #17).
-- Chạy sau  : 00_danh_muc_hoso_sv_ddl.sql (vì MONHOC.MaKhoa,
--            GIANGVIEN.MaKhoa tham chiếu KHOA; CHUONGTRINHDAOTAO
--            tham chiếu MONHOC).
-- ==========================================================

-- ==========================================================
-- 0. XÓA RÀNG BUỘC FK_CTDT_MONHOC TRƯỚC (nếu có)
--    Vì bảng CHUONGTRINHDAOTAO (tạo ở Module 1) có FK tới MONHOC,
--    phải bỏ FK này trước khi DROP/CREATE lại MONHOC.
--    (FK sẽ được tạo LẠI ở cuối file, sau khi MONHOC tồn tại.)
-- ==========================================================
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CTDT_MONHOC')
    ALTER TABLE CHUONGTRINHDAOTAO DROP CONSTRAINT FK_CTDT_MONHOC;
GO

IF OBJECT_ID(N'LICHHOC', N'U') IS NOT NULL DROP TABLE LICHHOC;
GO
IF OBJECT_ID(N'LOPHOCPHAN', N'U') IS NOT NULL DROP TABLE LOPHOCPHAN;
GO
IF OBJECT_ID(N'PHONGHOC', N'U') IS NOT NULL DROP TABLE PHONGHOC;
GO
IF OBJECT_ID(N'HOCKY', N'U') IS NOT NULL DROP TABLE HOCKY;
GO
IF OBJECT_ID(N'GIANGVIEN', N'U') IS NOT NULL DROP TABLE GIANGVIEN;
GO
IF OBJECT_ID(N'MONHOC_TIENQUYET', N'U') IS NOT NULL DROP TABLE MONHOC_TIENQUYET;
GO
IF OBJECT_ID(N'MONHOC', N'U') IS NOT NULL DROP TABLE MONHOC;
GO

-- ==========================================================
-- 1. MONHOC
-- ==========================================================
CREATE TABLE MONHOC (
    MaMonHoc            VARCHAR(10)     NOT NULL,
    TenMonHoc           NVARCHAR(100)   NOT NULL,
    SoTinChi            INT             NOT NULL,
    SoTietLyThuyet      INT             NOT NULL DEFAULT 0,
    SoTietThucHanh      INT             NOT NULL DEFAULT 0,
    MaKhoa              VARCHAR(10)     NOT NULL,

    CONSTRAINT PK_MONHOC PRIMARY KEY (MaMonHoc),
    CONSTRAINT CK_MONHOC_SoTinChi CHECK (SoTinChi > 0),
    CONSTRAINT CK_MONHOC_SoTietLyThuyet CHECK (SoTietLyThuyet >= 0),
    CONSTRAINT CK_MONHOC_SoTietThucHanh CHECK (SoTietThucHanh >= 0),
    CONSTRAINT FK_MONHOC_KHOA FOREIGN KEY (MaKhoa)
        REFERENCES KHOA(MaKhoa)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO

-- ==========================================================
-- 2. MONHOC_TIENQUYET (quan hệ nhiều - nhiều tự tham chiếu)
-- ==========================================================
CREATE TABLE MONHOC_TIENQUYET (
    MaMonHoc            VARCHAR(10)     NOT NULL,
    MaMonTienQuyet      VARCHAR(10)     NOT NULL,

    CONSTRAINT PK_MONHOC_TIENQUYET PRIMARY KEY (MaMonHoc, MaMonTienQuyet),
    CONSTRAINT FK_MTQ_MONHOC_CHINH FOREIGN KEY (MaMonHoc)
        REFERENCES MONHOC(MaMonHoc)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT FK_MTQ_MONHOC_TQ FOREIGN KEY (MaMonTienQuyet)
        REFERENCES MONHOC(MaMonHoc)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    -- Chống tự tham chiếu: môn không thể là tiên quyết của chính nó
    CONSTRAINT CK_MTQ_KhongTuThamChieu CHECK (MaMonHoc <> MaMonTienQuyet)
);
GO

-- ==========================================================
-- 3. GIANGVIEN
-- ==========================================================
CREATE TABLE GIANGVIEN (
    MaGV                VARCHAR(10)     NOT NULL,
    HoTen               NVARCHAR(100)   NOT NULL,
    Email               VARCHAR(100)    NOT NULL,
    MaKhoa              VARCHAR(10)     NOT NULL,

    CONSTRAINT PK_GIANGVIEN PRIMARY KEY (MaGV),
    CONSTRAINT UQ_GIANGVIEN_Email UNIQUE (Email),
    CONSTRAINT FK_GIANGVIEN_KHOA FOREIGN KEY (MaKhoa)
        REFERENCES KHOA(MaKhoa)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO

-- ==========================================================
-- 4. HOCKY
-- ==========================================================
CREATE TABLE HOCKY (
    MaHocKy             VARCHAR(10)     NOT NULL,
    TenHocKy            NVARCHAR(30)    NOT NULL,
    NamHoc              VARCHAR(20)     NOT NULL,
    TuNgay              DATE            NOT NULL,
    DenNgay             DATE            NOT NULL,
    TrangThaiDot        NVARCHAR(30)    NOT NULL DEFAULT N'MO',

    CONSTRAINT PK_HOCKY PRIMARY KEY (MaHocKy),
    CONSTRAINT CK_HOCKY_Ngay CHECK (TuNgay < DenNgay),
    CONSTRAINT CK_HOCKY_TrangThaiDot CHECK (TrangThaiDot IN (N'MO', N'DONG'))
);
GO

-- ==========================================================
-- 5. PHONGHOC
-- ==========================================================
CREATE TABLE PHONGHOC (
    MaPhong             VARCHAR(10)     NOT NULL,
    TenPhong            NVARCHAR(30)    NOT NULL,
    SucChua             INT             NOT NULL,

    CONSTRAINT PK_PHONGHOC PRIMARY KEY (MaPhong),
    CONSTRAINT CK_PHONGHOC_SucChua CHECK (SucChua > 0)
);
GO

-- ==========================================================
-- 6. LOPHOCPHAN
-- ==========================================================
CREATE TABLE LOPHOCPHAN (
    MaLHP               VARCHAR(15)     NOT NULL,
    TenLHP              NVARCHAR(100)   NOT NULL,
    SiSoToiDa           INT             NOT NULL,
    SiSoHienTai         INT             NOT NULL DEFAULT 0,
    TrangThaiLop        NVARCHAR(30)    NOT NULL DEFAULT N'MO_DANG_KY',
    MaMonHoc            VARCHAR(10)     NOT NULL,
    MaHocKy             VARCHAR(10)     NOT NULL,
    MaGV                VARCHAR(10)     NULL,

    CONSTRAINT PK_LOPHOCPHAN PRIMARY KEY (MaLHP),
    CONSTRAINT CK_LOPHOCPHAN_SiSoToiDa CHECK (SiSoToiDa > 0),
    CONSTRAINT CK_LOPHOCPHAN_SiSoHienTai CHECK (SiSoHienTai >= 0),
    CONSTRAINT CK_LOPHOCPHAN_SiSo CHECK (SiSoHienTai <= SiSoToiDa),
    CONSTRAINT CK_LOPHOCPHAN_TrangThaiLop CHECK (TrangThaiLop IN (N'MO_DANG_KY', N'DONG_DANG_KY', N'DA_KET_THUC')),
    CONSTRAINT FK_LOPHOCPHAN_MONHOC FOREIGN KEY (MaMonHoc)
        REFERENCES MONHOC(MaMonHoc)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT FK_LOPHOCPHAN_HOCKY FOREIGN KEY (MaHocKy)
        REFERENCES HOCKY(MaHocKy)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT FK_LOPHOCPHAN_GIANGVIEN FOREIGN KEY (MaGV)
        REFERENCES GIANGVIEN(MaGV)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO

-- ==========================================================
-- 7. LICHHOC
-- ==========================================================
CREATE TABLE LICHHOC (
    MaLichHoc           VARCHAR(10)     NOT NULL,
    MaLHP               VARCHAR(15)     NOT NULL,
    MaPhong             VARCHAR(10)     NOT NULL,
    Thu                 INT             NOT NULL,
    TietBatDau          INT             NOT NULL,
    SoTiet              INT             NOT NULL,

    CONSTRAINT PK_LICHHOC PRIMARY KEY (MaLichHoc),
    CONSTRAINT CK_LICHHOC_Thu CHECK (Thu BETWEEN 2 AND 8),
    CONSTRAINT CK_LICHHOC_TietBatDau CHECK (TietBatDau BETWEEN 1 AND 15),
    CONSTRAINT CK_LICHHOC_SoTiet CHECK (SoTiet BETWEEN 1 AND 6),
    CONSTRAINT FK_LICHHOC_LOPHOCPHAN FOREIGN KEY (MaLHP)
        REFERENCES LOPHOCPHAN(MaLHP)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT FK_LICHHOC_PHONGHOC FOREIGN KEY (MaPhong)
        REFERENCES PHONGHOC(MaPhong)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO

-- ==========================================================
-- 8. KHÔI PHỤC FK CHUONGTRINHDAOTAO -> MONHOC (Module 1 & 2)
--    CHUONGTRINHDAOTAO(MaNganh, MaMonHoc) tham chiếu MONHOC(MaMonHoc)
--    — giờ MONHOC đã tồn tại nên có thể thêm lại FK.
-- ==========================================================
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CTDT_MONHOC')
    ALTER TABLE CHUONGTRINHDAOTAO
        ADD CONSTRAINT FK_CTDT_MONHOC FOREIGN KEY (MaMonHoc)
        REFERENCES MONHOC(MaMonHoc)
        ON DELETE NO ACTION
        ON UPDATE CASCADE;
GO

PRINT N'[OK] Module 2 — Học phần & Mở lớp đã tạo xong (MONHOC, MONHOC_TIENQUYET, GIANGVIEN, HOCKY, PHONGHOC, LOPHOCPHAN, LICHHOC).';
GO
