-- ==========================================================
-- Ten file : mysql/ddl/00_hocphan_giangvien_ddl.sql
-- Module   : Hoc phan, Giang vien & Mo lop hoc phan (TV2)
-- Mo ta    : Ban dich T-SQL -> MySQL. 7 bang: MONHOC,
--            MONHOC_TIENQUYET, GIANGVIEN, HOCKY, PHONGHOC,
--            LOPHOCPHAN, LICHHOC.
-- ==========================================================

DROP TABLE IF EXISTS LICHHOC;
DROP TABLE IF EXISTS LOPHOCPHAN;
DROP TABLE IF EXISTS PHONGHOC;
DROP TABLE IF EXISTS HOCKY;
DROP TABLE IF EXISTS GIANGVIEN;
DROP TABLE IF EXISTS MONHOC_TIENQUYET;
DROP TABLE IF EXISTS MONHOC;

-- ==========================================================
-- 1. MONHOC
-- ==========================================================
CREATE TABLE MONHOC (
    MaMonHoc            VARCHAR(10)     NOT NULL,
    TenMonHoc           VARCHAR(100)    NOT NULL,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================================
-- 2. MONHOC_TIENQUYET (quan he nhieu - nhieu tu tham chieu)
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
    CONSTRAINT CK_MTQ_KhongTuThamChieu CHECK (MaMonHoc <> MaMonTienQuyet)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================================
-- 3. GIANGVIEN
-- ==========================================================
CREATE TABLE GIANGVIEN (
    MaGV                VARCHAR(10)     NOT NULL,
    HoTen               VARCHAR(100)    NOT NULL,
    Email               VARCHAR(100)    NOT NULL,
    MaKhoa              VARCHAR(10)     NOT NULL,

    CONSTRAINT PK_GIANGVIEN PRIMARY KEY (MaGV),
    CONSTRAINT UQ_GIANGVIEN_Email UNIQUE (Email),
    CONSTRAINT FK_GIANGVIEN_KHOA FOREIGN KEY (MaKhoa)
        REFERENCES KHOA(MaKhoa)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================================
-- 4. HOCKY
-- ==========================================================
CREATE TABLE HOCKY (
    MaHocKy             VARCHAR(10)     NOT NULL,
    TenHocKy            VARCHAR(30)     NOT NULL,
    NamHoc              VARCHAR(20)     NOT NULL,
    TuNgay              DATE            NOT NULL,
    DenNgay             DATE            NOT NULL,
    TrangThaiDot        VARCHAR(30)     NOT NULL DEFAULT 'MO',

    CONSTRAINT PK_HOCKY PRIMARY KEY (MaHocKy),
    CONSTRAINT CK_HOCKY_Ngay CHECK (TuNgay < DenNgay),
    CONSTRAINT CK_HOCKY_TrangThaiDot CHECK (TrangThaiDot IN ('MO', 'DONG'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================================
-- 5. PHONGHOC
-- ==========================================================
CREATE TABLE PHONGHOC (
    MaPhong             VARCHAR(10)     NOT NULL,
    TenPhong            VARCHAR(30)     NOT NULL,
    SucChua             INT             NOT NULL,

    CONSTRAINT PK_PHONGHOC PRIMARY KEY (MaPhong),
    CONSTRAINT CK_PHONGHOC_SucChua CHECK (SucChua > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================================
-- 6. LOPHOCPHAN
-- ==========================================================
CREATE TABLE LOPHOCPHAN (
    MaLHP               VARCHAR(15)     NOT NULL,
    TenLHP              VARCHAR(100)    NOT NULL,
    SiSoToiDa           INT             NOT NULL,
    SiSoHienTai         INT             NOT NULL DEFAULT 0,
    TrangThaiLop        VARCHAR(30)     NOT NULL DEFAULT 'MO_DANG_KY',
    MaMonHoc            VARCHAR(10)     NOT NULL,
    MaHocKy             VARCHAR(10)     NOT NULL,
    MaGV                VARCHAR(10)     NULL,

    CONSTRAINT PK_LOPHOCPHAN PRIMARY KEY (MaLHP),
    CONSTRAINT CK_LOPHOCPHAN_SiSoToiDa CHECK (SiSoToiDa > 0),
    CONSTRAINT CK_LOPHOCPHAN_SiSoHienTai CHECK (SiSoHienTai >= 0),
    CONSTRAINT CK_LOPHOCPHAN_SiSo CHECK (SiSoHienTai <= SiSoToiDa),
    CONSTRAINT CK_LOPHOCPHAN_TrangThaiLop CHECK (TrangThaiLop IN ('MO_DANG_KY', 'DONG_DANG_KY', 'DA_KET_THUC')),
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================================
-- 8. KHOI PHUC FK CHUONGTRINHDAOTAO -> MONHOC
-- ==========================================================
ALTER TABLE CHUONGTRINHDAOTAO
    ADD CONSTRAINT FK_CTDT_MONHOC FOREIGN KEY (MaMonHoc)
    REFERENCES MONHOC(MaMonHoc)
    ON DELETE NO ACTION
    ON UPDATE CASCADE;
