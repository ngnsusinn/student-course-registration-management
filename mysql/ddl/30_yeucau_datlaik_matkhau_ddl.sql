-- ==========================================================
-- Ten file : mysql/ddl/30_yeucau_datlaik_matkhau_ddl.sql
-- Module   : Tai khoan & Phan quyen (TV5)
-- Mo ta    : Bang YEUCAU_DATLAI_MATKHAU — ho tro chuc nang
--            "Quen mat khau?" o man hinh dang nhap.
--
--   Luong nghiep vu:
--     1. Nguoi dung bam "Quen mat khau?" -> nhap TenDangNhap + Email
--        -> SP_TaoYeuCauDatLaiMatKhau ghi 1 dong TrangThai = 'CHO_XU_LY'
--        (khong tiet lo tai khoan co ton tai hay khong).
--     2. PĐT vao man "Tai khoan & Phan quyen" -> muc "Yeu cau dat lai
--        mat khau" -> SP_XuLyYeuCauDatLaiMatKhau (dat lai ve mat khau
--        mac dinh) hoac SP_TuChoiYeuCauDatLaiMatKhau.
--     3. Moi lan doi MatKhau cua TAIKHOAN deu duoc trigger
--        TRG_LogDoiMatKhau ghi vao NHATKY_DOIMATKHAU.
--
-- TrangThai: 'CHO_XU_LY' | 'DA_XU_LY' | 'TU_CHOI'
-- ==========================================================

DROP TABLE IF EXISTS YEUCAU_DATLAI_MATKHAU;

CREATE TABLE YEUCAU_DATLAI_MATKHAU (
    MaYeuCau     INT             NOT NULL AUTO_INCREMENT,
    TenDangNhap  VARCHAR(50)     NOT NULL,
    Email        VARCHAR(100)    NULL,
    LyDo         VARCHAR(255)    NULL,
    TrangThai    VARCHAR(20)     NOT NULL DEFAULT 'CHO_XU_LY',
    NgayGui      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    NgayXuLy     DATETIME        NULL,
    NguoiXuLy    VARCHAR(15)     NULL,
    GhiChu       VARCHAR(255)    NULL,

    CONSTRAINT PK_YEUCAU_DATLAI_MATKHAU PRIMARY KEY (MaYeuCau),
    CONSTRAINT CK_YCDLMK_TrangThai
        CHECK (TrangThai IN ('CHO_XU_LY', 'DA_XU_LY', 'TU_CHOI')),
    CONSTRAINT FK_YCDLMK_TAIKHOAN FOREIGN KEY (TenDangNhap)
        REFERENCES TAIKHOAN(TenDangNhap)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX IX_YCDLMK_TrangThai_NgayGui ON YEUCAU_DATLAI_MATKHAU (TrangThai, NgayGui);
CREATE INDEX IX_YCDLMK_TenDangNhap       ON YEUCAU_DATLAI_MATKHAU (TenDangNhap);
