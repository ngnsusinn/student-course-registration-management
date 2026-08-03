-- ==========================================================
-- Tên file : sql/ddl/00_diem_ketqua_ddl.sql
-- Module   : Điểm số & Kết quả học tập (TV4)
-- Mô tả    : THANGDIEMCHU + KETQUAHOCTAP theo docs/erd_diem_ketqua.md.
--            KETQUAHOCTAP có Composite FK tới DANGKYHOCPHAN(MaSV,MaLHP)
--            (bảng trung tâm TV3) — nên chạy sau 10_dangky_hocphan_ddl.sql.
-- Chạy sau  : 10_dangky_hocphan_ddl.sql
-- ==========================================================

IF OBJECT_ID(N'KETQUAHOCTAP', N'U') IS NOT NULL DROP TABLE KETQUAHOCTAP;
GO
IF OBJECT_ID(N'THANGDIEMCHU', N'U') IS NOT NULL DROP TABLE THANGDIEMCHU;
GO

-- ==========================================================
-- 1. THANGDIEMCHU (bảng tra cứu quy đổi điểm chữ)
-- ==========================================================
CREATE TABLE THANGDIEMCHU (
    DiemChu         VARCHAR(2)       NOT NULL,
    TuDiemHe10      FLOAT            NOT NULL,
    DenDiemHe10     FLOAT            NOT NULL,
    DiemHe4         FLOAT            NOT NULL,
    XepLoai         NVARCHAR(20)     NOT NULL,

    CONSTRAINT PK_THANGDIEMCHU PRIMARY KEY (DiemChu),
    CONSTRAINT CK_TDC_TuDiemHe10 CHECK (TuDiemHe10 >= 0.0 AND TuDiemHe10 <= 10.0),
    CONSTRAINT CK_TDC_DenDiemHe10 CHECK (DenDiemHe10 >= 0.0 AND DenDiemHe10 <= 10.0),
    CONSTRAINT CK_TDC_KhoangHople CHECK (TuDiemHe10 < DenDiemHe10),
    CONSTRAINT CK_TDC_DiemHe4 CHECK (DiemHe4 >= 0.0 AND DiemHe4 <= 4.0)
);
GO

-- ==========================================================
-- 2. KETQUAHOCTAP (điểm số theo SV - LHP đã đăng ký)
-- ==========================================================
CREATE TABLE KETQUAHOCTAP (
    MaSV            VARCHAR(12)     NOT NULL,
    MaLHP           VARCHAR(15)     NOT NULL,
    DiemChuyenCan   FLOAT           NULL,
    DiemGiuaKy      FLOAT           NULL,
    DiemCuoiKy      FLOAT           NULL,
    DiemTongKet     FLOAT           NULL,
    DiemHe4         FLOAT           NULL,
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
);
GO

PRINT N'[OK] Module 4 — Đã tạo THANGDIEMCHU + KETQUAHOCTAP.';
GO
