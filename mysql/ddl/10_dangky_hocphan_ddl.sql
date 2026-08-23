-- ==========================================================
-- Ten file : mysql/ddl/10_dangky_hocphan_ddl.sql
-- Module   : Dang ky hoc phan (TV3 — Leader)
-- Mo ta    : Bang trung tam DANGKYHOCPHAN (ban dich MySQL):
--              - PK ghep (MaSV, MaLHP)
--              - 2 FK toi SINHVIEN va LOPHOCPHAN
--              - CHECK TrangThaiDangKy
--              - Trigger +1/-1 SiSoHienTai nam o mysql/triggers/
-- ==========================================================

DROP TABLE IF EXISTS DANGKYHOCPHAN;

CREATE TABLE DANGKYHOCPHAN (
    MaSV                VARCHAR(12)     NOT NULL,
    MaLHP               VARCHAR(15)     NOT NULL,
    NgayDangKy          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    TrangThaiDangKy     VARCHAR(20)     NOT NULL DEFAULT 'DA_DANG_KY',
    GhiChu              VARCHAR(255)    NULL,

    CONSTRAINT PK_DANGKYHOCPHAN PRIMARY KEY (MaSV, MaLHP),

    CONSTRAINT FK_DKHP_SINHVIEN FOREIGN KEY (MaSV)
        REFERENCES SINHVIEN(MaSV)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,

    CONSTRAINT FK_DKHP_LOPHOCPHAN FOREIGN KEY (MaLHP)
        REFERENCES LOPHOCPHAN(MaLHP)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,

    CONSTRAINT CK_DKHP_TrangThaiDangKy CHECK (
        TrangThaiDangKy IN ('DA_DANG_KY', 'DA_HUY', 'CHO_XAC_NHAN')
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
