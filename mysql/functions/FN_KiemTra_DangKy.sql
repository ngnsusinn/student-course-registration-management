-- ==========================================================
-- Ten file : mysql/functions/FN_KiemTra_DangKy.sql
-- Module   : Dang ky hoc phan (TV3) + Diem (TV4) + Lich (TV2)
-- Mo ta    : Ban dich T-SQL -> MySQL. Bo 8 FUNCTION ho tro:
--   Dang ky  : FN_KiemTraTienQuyet, FN_KiemTraTrungLichHoc,
--              FN_TinhTongTinChi, FN_KiemTraDotDangKy
--   Diem     : FN_TinhDiemTongKet, FN_QuyDoiDiemChu, FN_QuyDoiDiemHe4
--   Lich     : FN_KiemTraPhongTrong
-- ==========================================================

DROP FUNCTION IF EXISTS FN_KiemTraTienQuyet;
DROP FUNCTION IF EXISTS FN_KiemTraTrungLichHoc;
DROP FUNCTION IF EXISTS FN_TinhTongTinChi;
DROP FUNCTION IF EXISTS FN_KiemTraDotDangKy;
DROP FUNCTION IF EXISTS FN_TinhDiemTongKet;
DROP FUNCTION IF EXISTS FN_QuyDoiDiemChu;
DROP FUNCTION IF EXISTS FN_QuyDoiDiemHe4;
DROP FUNCTION IF EXISTS FN_KiemTraPhongTrong;

DELIMITER $$

-- 1. Kiem tra SV da DAT tat ca mon tien quyet cua mon muon dang ky
CREATE FUNCTION FN_KiemTraTienQuyet (
    pMaSV      VARCHAR(12),
    pMaMonHoc  VARCHAR(10)
)
RETURNS TINYINT(1)
READS SQL DATA
BEGIN
    -- Neu mon khong co tien quyet -> luon hop le
    IF NOT EXISTS (SELECT 1 FROM MONHOC_TIENQUYET WHERE MaMonHoc = pMaMonHoc) THEN
        RETURN 1;
    END IF;

    -- Ton tai it nhat 1 mon tien quyet ma SV CHUA DAT -> tra 0
    IF EXISTS (
        SELECT 1
        FROM MONHOC_TIENQUYET mtq
        WHERE mtq.MaMonHoc = pMaMonHoc
          AND NOT EXISTS (
                SELECT 1
                FROM KETQUAHOCTAP kq
                JOIN LOPHOCPHAN kqL ON kqL.MaLHP = kq.MaLHP
                WHERE kq.MaSV = pMaSV
                  AND kqL.MaMonHoc = mtq.MaMonTienQuyet
                  AND kq.DiemChu <> 'F'
          )
    ) THEN
        RETURN 0;
    END IF;

    RETURN 1;
END$$

-- 2. Kiem tra LHP moi co TRUNG LICH voi cac LHP da DK trong cung hoc ky
CREATE FUNCTION FN_KiemTraTrungLichHoc (
    pMaSV   VARCHAR(12),
    pMaLHP  VARCHAR(15)
)
RETURNS TINYINT(1)
READS SQL DATA
BEGIN
    IF EXISTS (
        SELECT 1
        FROM LICHHOC lhMoi
        JOIN LOPHOCPHAN lhpMoi ON lhpMoi.MaLHP = lhMoi.MaLHP
        WHERE lhMoi.MaLHP = pMaLHP
          AND EXISTS (
                SELECT 1
                FROM DANGKYHOCPHAN dkCu
                JOIN LOPHOCPHAN lhpCu ON lhpCu.MaLHP = dkCu.MaLHP
                JOIN LICHHOC lhCu    ON lhCu.MaLHP = lhpCu.MaLHP
                WHERE dkCu.MaSV = pMaSV
                  AND dkCu.TrangThaiDangKy = 'DA_DANG_KY'
                  AND lhpCu.MaHocKy = lhpMoi.MaHocKy
                  AND lhCu.Thu = lhMoi.Thu
                  AND lhCu.TietBatDau <= lhMoi.TietBatDau + lhMoi.SoTiet - 1
                  AND lhCu.TietBatDau + lhCu.SoTiet - 1 >= lhMoi.TietBatDau
          )
    ) THEN
        RETURN 1;
    END IF;

    RETURN 0;
END$$

-- 3. Tong so tin chi SV da DK thanh cong trong 1 hoc ky
CREATE FUNCTION FN_TinhTongTinChi (
    pMaSV     VARCHAR(12),
    pMaHocKy  VARCHAR(10)
)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE vTong INT DEFAULT 0;

    SELECT IFNULL(SUM(mh.SoTinChi), 0) INTO vTong
    FROM DANGKYHOCPHAN dk
    JOIN LOPHOCPHAN lhp ON lhp.MaLHP = dk.MaLHP
    JOIN MONHOC     mh  ON mh.MaMonHoc = lhp.MaMonHoc
    WHERE dk.MaSV = pMaSV
      AND dk.TrangThaiDangKy = 'DA_DANG_KY'
      AND lhp.MaHocKy = pMaHocKy;

    RETURN vTong;
END$$

-- 4. Kiem tra dot dang ky hien tai con mo hay khong
CREATE FUNCTION FN_KiemTraDotDangKy ()
RETURNS TINYINT(1)
READS SQL DATA
BEGIN
    IF EXISTS (
        SELECT 1
        FROM HOCKY
        WHERE TrangThaiDot = 'MO'
          AND NOW() BETWEEN TuNgay AND DenNgay
    ) THEN
        RETURN 1;
    END IF;

    RETURN 0;
END$$

-- 5. Tinh diem tong ket he 10: 10% CC + 30% GK + 60% CK
CREATE FUNCTION FN_TinhDiemTongKet (
    pDiemCC DOUBLE,
    pDiemGK DOUBLE,
    pDiemCK DOUBLE
)
RETURNS DOUBLE
DETERMINISTIC
BEGIN
    IF pDiemCC IS NULL OR pDiemGK IS NULL OR pDiemCK IS NULL THEN
        RETURN NULL;
    END IF;

    IF pDiemCC < 0.0 OR pDiemCC > 10.0 OR
       pDiemGK < 0.0 OR pDiemGK > 10.0 OR
       pDiemCK < 0.0 OR pDiemCK > 10.0 THEN
        RETURN NULL;
    END IF;

    RETURN ROUND((pDiemCC * 0.10) + (pDiemGK * 0.30) + (pDiemCK * 0.60), 1);
END$$

-- 6. Quy doi diem tong ket sang diem chu (diem liet CK < 3.0 -> F)
CREATE FUNCTION FN_QuyDoiDiemChu (
    pDiemTongKet DOUBLE,
    pDiemCuoiKy  DOUBLE
)
RETURNS VARCHAR(2)
READS SQL DATA
BEGIN
    DECLARE vDiemChu VARCHAR(2);

    IF pDiemTongKet IS NULL THEN
        RETURN NULL;
    END IF;

    IF pDiemCuoiKy IS NOT NULL AND pDiemCuoiKy < 3.0 THEN
        RETURN 'F';
    END IF;

    SELECT t.DiemChu INTO vDiemChu
    FROM THANGDIEMCHU t
    WHERE pDiemTongKet >= t.TuDiemHe10 AND pDiemTongKet <= t.DenDiemHe10
    ORDER BY t.TuDiemHe10 DESC
    LIMIT 1;

    IF vDiemChu IS NULL THEN
        SET vDiemChu = 'F';
    END IF;

    RETURN vDiemChu;
END$$

-- 7. Quy doi diem chu sang he 4
CREATE FUNCTION FN_QuyDoiDiemHe4 (
    pDiemChu VARCHAR(2)
)
RETURNS DOUBLE
READS SQL DATA
BEGIN
    DECLARE vDiemHe4 DOUBLE;

    IF pDiemChu IS NULL THEN
        RETURN NULL;
    END IF;

    SELECT t.DiemHe4 INTO vDiemHe4
    FROM THANGDIEMCHU t
    WHERE t.DiemChu = pDiemChu
    LIMIT 1;

    IF vDiemHe4 IS NULL THEN
        SET vDiemHe4 = 0.0;
    END IF;

    RETURN vDiemHe4;
END$$

-- 8. Kiem tra phong trong tai 1 thu + tiet
CREATE FUNCTION FN_KiemTraPhongTrong (
    pMaPhong VARCHAR(10),
    pThu     TINYINT,
    pTiet    TINYINT
)
RETURNS TINYINT(1)
READS SQL DATA
BEGIN
    IF EXISTS (
        SELECT 1
        FROM LICHHOC
        WHERE MaPhong = pMaPhong
          AND Thu = pThu
          AND pTiet >= TietBatDau
          AND pTiet < TietBatDau + SoTiet
    ) THEN
        RETURN 0;
    END IF;

    RETURN 1;
END$$

DELIMITER ;
