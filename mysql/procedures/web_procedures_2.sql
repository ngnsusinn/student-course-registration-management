-- ==========================================================
-- Ten file : mysql/procedures/web_procedures_2.sql
-- Mo ta    : bo SP phan 2 cho tang WEB — CRUD danh muc (KHOA,
--            NGANH, LOP, MONHOC, GIANGVIEN, PHONGHOC, HOCKY, CTDT,
--            MONHOC_TIENQUYET) + cac SP ho tro dang ky hoc phan.
-- ==========================================================

DROP PROCEDURE IF EXISTS SP_HocKyHienTai;
DROP PROCEDURE IF EXISTS SP_LopMo;
DROP PROCEDURE IF EXISTS SP_LayLHP;
DROP PROCEDURE IF EXISTS SP_DSDangKyChiTiet;
DROP PROCEDURE IF EXISTS SP_LayTongTinChi;
DROP PROCEDURE IF EXISTS SP_ThemCTDT;
DROP PROCEDURE IF EXISTS SP_XoaCTDT;
DROP PROCEDURE IF EXISTS SP_ThemKhoa;
DROP PROCEDURE IF EXISTS SP_SuaKhoa;
DROP PROCEDURE IF EXISTS SP_XoaKhoa;
DROP PROCEDURE IF EXISTS SP_ThemNganh;
DROP PROCEDURE IF EXISTS SP_SuaNganh;
DROP PROCEDURE IF EXISTS SP_XoaNganh;
DROP PROCEDURE IF EXISTS SP_ThemLop;
DROP PROCEDURE IF EXISTS SP_SuaLop;
DROP PROCEDURE IF EXISTS SP_XoaLop;
DROP PROCEDURE IF EXISTS SP_ThemMonHoc;
DROP PROCEDURE IF EXISTS SP_SuaMonHoc;
DROP PROCEDURE IF EXISTS SP_XoaMonHoc;
DROP PROCEDURE IF EXISTS SP_ThemTienQuyet;
DROP PROCEDURE IF EXISTS SP_ThemGiangVien;
DROP PROCEDURE IF EXISTS SP_SuaGiangVien;
DROP PROCEDURE IF EXISTS SP_XoaGiangVien;
DROP PROCEDURE IF EXISTS SP_ThemPhong;
DROP PROCEDURE IF EXISTS SP_SuaPhong;
DROP PROCEDURE IF EXISTS SP_XoaPhong;
DROP PROCEDURE IF EXISTS SP_ThemHocKy;
DROP PROCEDURE IF EXISTS SP_SuaHocKy;

DELIMITER $$

-- ==========================================================
-- 1. DANG KY HOC PHAN (bo tro)
-- ==========================================================

-- Hoc ky dang mo dang ky (moi nhat)
CREATE PROCEDURE SP_HocKyHienTai ()
BEGIN
    SELECT * FROM HOCKY
    WHERE TrangThaiDot = 'MO' AND NOW() BETWEEN TuNgay AND DenNgay
    ORDER BY DenNgay DESC
    LIMIT 1;
END$$

-- Danh sach LHP dang mo de SV dang ky (kem DaDangKy cua chinh SV nay)
CREATE PROCEDURE SP_LopMo (
    IN pMaSV    VARCHAR(12),
    IN pMaHocKy VARCHAR(15)
)
BEGIN
    SELECT lhp.MaLHP, lhp.TenLHP, lhp.SiSoToiDa, lhp.SiSoHienTai,
           (lhp.SiSoToiDa - lhp.SiSoHienTai) AS SoChoTrong,
           lhp.TrangThaiLop, mh.MaMonHoc, mh.TenMonHoc, mh.SoTinChi,
           gv.MaGV, gv.HoTen AS TenGV,
           lhp.MaHocKy,
           (SELECT COUNT(*) FROM DANGKYHOCPHAN dk
             WHERE dk.MaLHP = lhp.MaLHP AND dk.MaSV = pMaSV
               AND dk.TrangThaiDangKy = 'DA_DANG_KY') AS DaDangKy,
           (SELECT GROUP_CONCAT(CONCAT(lh.Thu, ':', lh.TietBatDau, '-',
                                       lh.TietBatDau + lh.SoTiet - 1, '@', ph.TenPhong)
                                SEPARATOR '; ')
              FROM LICHHOC lh JOIN PHONGHOC ph ON ph.MaPhong = lh.MaPhong
             WHERE lh.MaLHP = lhp.MaLHP) AS LichHoc,
           (SELECT mtq.MaMonTienQuyet FROM MONHOC_TIENQUYET mtq
             WHERE mtq.MaMonHoc = mh.MaMonHoc LIMIT 1) AS MaMonTienQuyet
    FROM LOPHOCPHAN lhp
    JOIN MONHOC mh ON mh.MaMonHoc = lhp.MaMonHoc
    LEFT JOIN GIANGVIEN gv ON gv.MaGV = lhp.MaGV
    WHERE lhp.MaHocKy = pMaHocKy
      AND lhp.TrangThaiLop = 'MO_DANG_KY'
    ORDER BY mh.TenMonHoc, lhp.MaLHP;
END$$

-- Thong tin 1 LHP (tra ve sau khi dang ky thanh cong)
CREATE PROCEDURE SP_LayLHP (
    IN pMaLHP VARCHAR(15)
)
BEGIN
    SELECT MaLHP, TenLHP, SiSoHienTai, SiSoToiDa
    FROM LOPHOCPHAN WHERE MaLHP = pMaLHP;
END$$

-- Danh sach dang ky chi tiet cua SV (tat ca trang thai, loc hoc ky tuy chon)
CREATE PROCEDURE SP_DSDangKyChiTiet (
    IN pMaSV    VARCHAR(12),
    IN pMaHocKy VARCHAR(15)
)
BEGIN
    SELECT * FROM VW_SinhVienDangKyChiTiet
    WHERE MaSV = pMaSV
      AND (pMaHocKy IS NULL OR MaHocKy = pMaHocKy)
    ORDER BY MaHocKy DESC, MaLHP;
END$$

-- Tong tin chi SV da dang ky hieu luc trong 1 hoc ky (dung FN co san)
CREATE PROCEDURE SP_LayTongTinChi (
    IN pMaSV    VARCHAR(12),
    IN pMaHocKy VARCHAR(15)
)
BEGIN
    SELECT FN_TinhTongTinChi(pMaSV, pMaHocKy) AS TongTinChi;
END$$

-- ==========================================================
-- 2. CHUONG TRINH DAO TAO
-- ==========================================================

CREATE PROCEDURE SP_ThemCTDT (
    IN pMaNganh VARCHAR(10), IN pMaMonHoc VARCHAR(10),
    IN pHocKyDuKien TINYINT, IN pBatBuoc TINYINT
)
BEGIN
    INSERT INTO CHUONGTRINHDAOTAO (MaNganh, MaMonHoc, HocKyDuKien, BatBuoc)
    VALUES (pMaNganh, pMaMonHoc, pHocKyDuKien, pBatBuoc);
END$$

CREATE PROCEDURE SP_XoaCTDT (
    IN pMaNganh VARCHAR(10), IN pMaMonHoc VARCHAR(10)
)
BEGIN
    DELETE FROM CHUONGTRINHDAOTAO
    WHERE MaNganh = pMaNganh AND MaMonHoc = pMaMonHoc;
END$$

-- ==========================================================
-- 3. KHOA
-- ==========================================================

CREATE PROCEDURE SP_ThemKhoa (
    IN pMaKhoa VARCHAR(10), IN pTenKhoa VARCHAR(100),
    IN pDienThoaiKhoa VARCHAR(15), IN pEmailKhoa VARCHAR(100)
)
BEGIN
    INSERT INTO KHOA (MaKhoa, TenKhoa, DienThoaiKhoa, EmailKhoa)
    VALUES (pMaKhoa, pTenKhoa, pDienThoaiKhoa, pEmailKhoa);
END$$

CREATE PROCEDURE SP_SuaKhoa (
    IN pMaKhoa VARCHAR(10), IN pTenKhoa VARCHAR(100),
    IN pDienThoaiKhoa VARCHAR(15), IN pEmailKhoa VARCHAR(100)
)
BEGIN
    UPDATE KHOA
    SET TenKhoa = pTenKhoa, DienThoaiKhoa = pDienThoaiKhoa, EmailKhoa = pEmailKhoa
    WHERE MaKhoa = pMaKhoa;
END$$

CREATE PROCEDURE SP_XoaKhoa (IN pMaKhoa VARCHAR(10))
BEGIN
    DELETE FROM KHOA WHERE MaKhoa = pMaKhoa;
END$$

-- ==========================================================
-- 4. NGANH
-- ==========================================================

CREATE PROCEDURE SP_ThemNganh (
    IN pMaNganh VARCHAR(10), IN pTenNganh VARCHAR(100),
    IN pThoiGianDaoTao VARCHAR(50), IN pMaKhoa VARCHAR(10)
)
BEGIN
    INSERT INTO NGANH (MaNganh, TenNganh, ThoiGianDaoTao, MaKhoa)
    VALUES (pMaNganh, pTenNganh, pThoiGianDaoTao, pMaKhoa);
END$$

CREATE PROCEDURE SP_SuaNganh (
    IN pMaNganh VARCHAR(10), IN pTenNganh VARCHAR(100),
    IN pThoiGianDaoTao VARCHAR(50), IN pMaKhoa VARCHAR(10)
)
BEGIN
    UPDATE NGANH
    SET TenNganh = pTenNganh, ThoiGianDaoTao = pThoiGianDaoTao, MaKhoa = pMaKhoa
    WHERE MaNganh = pMaNganh;
END$$

-- Trigger TRG_XoaNganh_ChanKhiConSinhVien tu chan neu con SV
CREATE PROCEDURE SP_XoaNganh (IN pMaNganh VARCHAR(10))
BEGIN
    DELETE FROM NGANH WHERE MaNganh = pMaNganh;
END$$

-- ==========================================================
-- 5. LOP SINH HOAT
-- ==========================================================

CREATE PROCEDURE SP_ThemLop (
    IN pMaLopSH VARCHAR(15), IN pTenLopSH VARCHAR(100),
    IN pNienKhoa VARCHAR(20), IN pMaNganh VARCHAR(10)
)
BEGIN
    INSERT INTO LOP_SINHHOAT (MaLopSH, TenLopSH, NienKhoa, MaNganh)
    VALUES (pMaLopSH, pTenLopSH, pNienKhoa, pMaNganh);
END$$

CREATE PROCEDURE SP_SuaLop (
    IN pMaLopSH VARCHAR(15), IN pTenLopSH VARCHAR(100),
    IN pNienKhoa VARCHAR(20), IN pMaNganh VARCHAR(10)
)
BEGIN
    UPDATE LOP_SINHHOAT
    SET TenLopSH = pTenLopSH, NienKhoa = pNienKhoa, MaNganh = pMaNganh
    WHERE MaLopSH = pMaLopSH;
END$$

CREATE PROCEDURE SP_XoaLop (IN pMaLopSH VARCHAR(15))
BEGIN
    DELETE FROM LOP_SINHHOAT WHERE MaLopSH = pMaLopSH;
END$$

-- ==========================================================
-- 6. MON HOC (+ tien quyet)
-- ==========================================================

CREATE PROCEDURE SP_ThemMonHoc (
    IN pMaMonHoc VARCHAR(10), IN pTenMonHoc VARCHAR(100),
    IN pSoTinChi TINYINT, IN pSoTietLyThuyet SMALLINT,
    IN pSoTietThucHanh SMALLINT, IN pMaKhoa VARCHAR(10)
)
BEGIN
    INSERT INTO MONHOC (MaMonHoc, TenMonHoc, SoTinChi, SoTietLyThuyet, SoTietThucHanh, MaKhoa)
    VALUES (pMaMonHoc, pTenMonHoc, pSoTinChi, pSoTietLyThuyet, pSoTietThucHanh, pMaKhoa);
END$$

CREATE PROCEDURE SP_SuaMonHoc (
    IN pMaMonHoc VARCHAR(10), IN pTenMonHoc VARCHAR(100),
    IN pSoTinChi TINYINT, IN pSoTietLyThuyet SMALLINT,
    IN pSoTietThucHanh SMALLINT, IN pMaKhoa VARCHAR(10)
)
BEGIN
    UPDATE MONHOC
    SET TenMonHoc = pTenMonHoc, SoTinChi = pSoTinChi,
        SoTietLyThuyet = pSoTietLyThuyet, SoTietThucHanh = pSoTietThucHanh,
        MaKhoa = pMaKhoa
    WHERE MaMonHoc = pMaMonHoc;
END$$

CREATE PROCEDURE SP_XoaMonHoc (IN pMaMonHoc VARCHAR(10))
BEGIN
    DELETE FROM MONHOC WHERE MaMonHoc = pMaMonHoc;
END$$

-- Them 1 quan he tien quyet (backend goi nhieu lan trong 1 transaction)
CREATE PROCEDURE SP_ThemTienQuyet (
    IN pMaMonHoc VARCHAR(10), IN pMaMonTienQuyet VARCHAR(10)
)
BEGIN
    INSERT INTO MONHOC_TIENQUYET (MaMonHoc, MaMonTienQuyet)
    VALUES (pMaMonHoc, pMaMonTienQuyet);
END$$

-- ==========================================================
-- 7. GIANG VIEN
-- ==========================================================

-- Them GV + tu dong tao tai khoan (transaction ben trong SP)
CREATE PROCEDURE SP_ThemGiangVien (
    IN pMaGV VARCHAR(12), IN pHoTen VARCHAR(100),
    IN pEmail VARCHAR(100), IN pMaKhoa VARCHAR(10)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    INSERT INTO GIANGVIEN (MaGV, HoTen, Email, MaKhoa)
    VALUES (pMaGV, pHoTen, pEmail, pMaKhoa);
    CALL SP_TaoTaiKhoanGiangVien(pMaGV);
    COMMIT;
END$$

CREATE PROCEDURE SP_SuaGiangVien (
    IN pMaGV VARCHAR(12), IN pHoTen VARCHAR(100),
    IN pEmail VARCHAR(100), IN pMaKhoa VARCHAR(10)
)
BEGIN
    UPDATE GIANGVIEN
    SET HoTen = pHoTen, Email = pEmail, MaKhoa = pMaKhoa
    WHERE MaGV = pMaGV;
END$$

CREATE PROCEDURE SP_XoaGiangVien (IN pMaGV VARCHAR(12))
BEGIN
    DELETE FROM GIANGVIEN WHERE MaGV = pMaGV;
END$$

-- ==========================================================
-- 8. PHONG HOC
-- ==========================================================

CREATE PROCEDURE SP_ThemPhong (
    IN pMaPhong VARCHAR(15), IN pTenPhong VARCHAR(100), IN pSucChua SMALLINT
)
BEGIN
    INSERT INTO PHONGHOC (MaPhong, TenPhong, SucChua)
    VALUES (pMaPhong, pTenPhong, pSucChua);
END$$

CREATE PROCEDURE SP_SuaPhong (
    IN pMaPhong VARCHAR(15), IN pTenPhong VARCHAR(100), IN pSucChua SMALLINT
)
BEGIN
    UPDATE PHONGHOC SET TenPhong = pTenPhong, SucChua = pSucChua
    WHERE MaPhong = pMaPhong;
END$$

CREATE PROCEDURE SP_XoaPhong (IN pMaPhong VARCHAR(15))
BEGIN
    DELETE FROM PHONGHOC WHERE MaPhong = pMaPhong;
END$$

-- ==========================================================
-- 9. HOC KY
-- ==========================================================

CREATE PROCEDURE SP_ThemHocKy (
    IN pMaHocKy VARCHAR(15), IN pTenHocKy VARCHAR(50), IN pNamHoc VARCHAR(20),
    IN pTuNgay DATE, IN pDenNgay DATE, IN pTrangThaiDot VARCHAR(20)
)
BEGIN
    INSERT INTO HOCKY (MaHocKy, TenHocKy, NamHoc, TuNgay, DenNgay, TrangThaiDot)
    VALUES (pMaHocKy, pTenHocKy, pNamHoc, pTuNgay, pDenNgay, pTrangThaiDot);
END$$

CREATE PROCEDURE SP_SuaHocKy (
    IN pMaHocKy VARCHAR(15), IN pTenHocKy VARCHAR(50), IN pNamHoc VARCHAR(20),
    IN pTuNgay DATE, IN pDenNgay DATE, IN pTrangThaiDot VARCHAR(20)
)
BEGIN
    UPDATE HOCKY
    SET TenHocKy = pTenHocKy, NamHoc = pNamHoc, TuNgay = pTuNgay,
        DenNgay = pDenNgay, TrangThaiDot = pTrangThaiDot
    WHERE MaHocKy = pMaHocKy;
END$$

DELIMITER ;

SELECT '[OK] web_procedures_2.sql — da tao 28 SP CRUD dang ky & danh muc.' AS KetLuan;
