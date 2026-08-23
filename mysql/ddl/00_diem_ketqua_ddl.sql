-- ==========================================================
-- Ten file : mysql/ddl/00_diem_ketqua_ddl.sql
-- Module   : Diem so & Ket qua hoc tap (TV4)
-- Mo ta    : THANGDIEMCHU + KETQUAHOCTAP. KETQUAHOCTAP co
--            Composite FK toi DANGKYHOCPHAN(MaSV,MaLHP).
-- ==========================================================

DROP TABLE IF EXISTS KETQUAHOCTAP;
DROP TABLE IF EXISTS THANGDIEMCHU;

-- ==========================================================
-- 1. THANGDIEMCHU (bang tra cuu quy doi diem chu)
-- ==========================================================
CREATE TABLE THANGDIEMCHU (
    DiemChu         VARCHAR(2)       NOT NULL,
    TuDiemHe10      DOUBLE           NOT NULL,
    DenDiemHe10     DOUBLE           NOT NULL,
    DiemHe4         DOUBLE           NOT NULL,
    XepLoai         VARCHAR(20)      NOT NULL,

    CONSTRAINT PK_THANGDIEMCHU PRIMARY KEY (DiemChu),
    CONSTRAINT CK_TDC_TuDiemHe10 CHECK (TuDiemHe10 >= 0.0 AND TuDiemHe10 <= 10.0),
    CONSTRAINT CK_TDC_DenDiemHe10 CHECK (DenDiemHe10 >= 0.0 AND DenDiemHe10 <= 10.0),
    CONSTRAINT CK_TDC_KhoangHople CHECK (TuDiemHe10 < DenDiemHe10),
    CONSTRAINT CK_TDC_DiemHe4 CHECK (DiemHe4 >= 0.0 AND DiemHe4 <= 4.0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================================
-- 2. KETQUAHOCTAP (diem so theo SV - LHP da dang ky)
-- ==========================================================
CREATE TABLE KETQUAHOCTAP (
    MaSV            VARCHAR(12)     NOT NULL,
    MaLHP           VARCHAR(15)     NOT NULL,
    DiemChuyenCan   DOUBLE          NULL,
    DiemGiuaKy      DOUBLE          NULL,
    DiemCuoiKy      DOUBLE          NULL,
    DiemTongKet     DOUBLE          NULL,
    DiemHe4         DOUBLE          NULL,
    DiemChu         VARCHAR(2)      NULL,

    CONSTRAINT PK_KETQUAHOCTAP PRIMARY KEY (MaSV, MaLHP),
    CONSTRAINT FK_KQHT_DANGKY FOREIGN KEY (MaSV, MaLHP)
        REFERENCES DANGKYHOCPHAN(MaSV, MaLHP)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT FK_KQHT_THANGDIEMCHU FOREIGN KEY (DiemChu)
        REFERENCES THANGDIEMCHU(DiemChu)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT CK_KQHT_DiemChuyenCan CHECK (DiemChuyenCan IS NULL OR (DiemChuyenCan >= 0.0 AND DiemChuyenCan <= 10.0)),
    CONSTRAINT CK_KQHT_DiemGiuaKy CHECK (DiemGiuaKy IS NULL OR (DiemGiuaKy >= 0.0 AND DiemGiuaKy <= 10.0)),
    CONSTRAINT CK_KQHT_DiemCuoiKy CHECK (DiemCuoiKy IS NULL OR (DiemCuoiKy >= 0.0 AND DiemCuoiKy <= 10.0)),
    CONSTRAINT CK_KQHT_DiemTongKet CHECK (DiemTongKet IS NULL OR (DiemTongKet >= 0.0 AND DiemTongKet <= 10.0)),
    CONSTRAINT CK_KQHT_DiemHe4 CHECK (DiemHe4 IS NULL OR (DiemHe4 >= 0.0 AND DiemHe4 <= 4.0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
