-- ==========================================================
-- Ten file : mysql/procedures/web_procedures.sql
-- Mo ta    : bo SP phuc vu TANG WEB — backend khong con raw query
--            nao; moi duong doc/ghi deu di qua VIEW/SP/FUNCTION.
--          * Auth:      SP_DangNhap, SP_DoiMatKhau, SP_LayHoSo
--          * Dang ky:   SP_DSDangKyHieuLuc, SP_ThoiKhoaBieu_SV,
--                       SP_GanTrangThaiDK, SP_XoaDangKyChoDuyet
--          * Danh muc:  SP_DM_* (doc), SP_CapNhatHoSoSV, SP_XoaSinhVien
--          * Admin:     SP_ThongKeTongHop, SP_TKDangKyTheoKy,
--                       SP_DSLopHocPhan, SP_DSTaiKhoan,
--                       SP_GanTrangThaiTaiKhoan, SP_DSNhatKyDoiMatKhau
--          * Ket qua:   SP_DSBangDiem, SP_DSThangDiemChu,
--                       SP_DSThongKeMonHoc, SP_DSCanhBaoHocVu,
--                       SP_DSGpaTheoLop
--          * Hoc phi:   SP_DSHocPhiCuaToi, SP_DSHocPhiDanhsach,
--                       SP_ThongKeHocPhi
--          * Giang vien: SP_GV_LopCuaToi, SP_GV_KiemTraLop,
--                       SP_GV_DSSinhVienLop
-- Dung mysql2 multipleStatements khi goi SP co nhieu ket qua,
-- hoac goi tung SP roi SELECT @KetQua.
-- ==========================================================

DROP PROCEDURE IF EXISTS SP_DangNhap;
DROP PROCEDURE IF EXISTS SP_DoiMatKhau;
DROP PROCEDURE IF EXISTS SP_LayHoSo;
DROP PROCEDURE IF EXISTS SP_DSDangKyHieuLuc;
DROP PROCEDURE IF EXISTS SP_DSThoiKhoaBieu;
DROP PROCEDURE IF EXISTS SP_GanTrangThaiDK;
DROP PROCEDURE IF EXISTS SP_XoaDangKyChoDuyet;
DROP PROCEDURE IF EXISTS SP_DM_HocKy;
DROP PROCEDURE IF EXISTS SP_DM_Khoa;
DROP PROCEDURE IF EXISTS SP_DM_Nganh;
DROP PROCEDURE IF EXISTS SP_DM_Lop;
DROP PROCEDURE IF EXISTS SP_DM_MonHoc;
DROP PROCEDURE IF EXISTS SP_DM_GiangVien;
DROP PROCEDURE IF EXISTS SP_DM_PhongHoc;
DROP PROCEDURE IF EXISTS SP_DM_TienQuyet;
DROP PROCEDURE IF EXISTS SP_DM_CTDiet;
DROP PROCEDURE IF EXISTS SP_DSSinhVien;
DROP PROCEDURE IF EXISTS SP_CapNhatHoSoSV;
DROP PROCEDURE IF EXISTS SP_XoaSinhVien;
DROP PROCEDURE IF EXISTS SP_ThongKeTongHop;
DROP PROCEDURE IF EXISTS SP_TKDangKyTheoKy;
DROP PROCEDURE IF EXISTS SP_DSLopHocPhan;
DROP PROCEDURE IF EXISTS SP_DSTaiKhoan;
DROP PROCEDURE IF EXISTS SP_GanTrangThaiTaiKhoan;
DROP PROCEDURE IF EXISTS SP_DSNhatKyDoiMatKhau;
DROP PROCEDURE IF EXISTS SP_ThongBaoSapKetThuc;
DROP PROCEDURE IF EXISTS SP_DSBangDiem;
DROP PROCEDURE IF EXISTS SP_DSThangDiemChu;
DROP PROCEDURE IF EXISTS SP_DSThongKeMonHoc;
DROP PROCEDURE IF EXISTS SP_DSCanhBaoHocVu;
DROP PROCEDURE IF EXISTS SP_DSGpaTheoLop;
DROP PROCEDURE IF EXISTS SP_DSHocPhiCuaToi;
DROP PROCEDURE IF EXISTS SP_DSHocPhiDanhsach;
DROP PROCEDURE IF EXISTS SP_ThongKeHocPhi;
DROP PROCEDURE IF EXISTS SP_GV_LopCuaToi;
DROP PROCEDURE IF EXISTS SP_GV_KiemTraLop;
DROP PROCEDURE IF EXISTS SP_GV_DSSinhVienLop;
DROP PROCEDURE IF EXISTS SP_HealthCheck;

DELIMITER $$

-- ==========================================================
-- 1. AUTH
-- ==========================================================

-- Dang nhap: tra ve 1 dong (MaTaiKhoan, TenDangNhap, MatKhau, TrangThai,
-- MaVaiTro, TenVaiTro, MaSV, MaGV, Email, HoTen) hoac khong dong nao.
-- Mat khau da bam SHA2(?,256) duoi DB (UTF8MB4_BIN — phan biet hoa/thuong).
CREATE PROCEDURE SP_DangNhap (
    IN  pTenDangNhap VARCHAR(50),
    IN  pMatKhauHash CHAR(64)
)
BEGIN
    SELECT tk.MaTaiKhoan, tk.TenDangNhap, tk.MatKhau, tk.TrangThai,
           tk.MaVaiTro, vt.TenVaiTro, tk.MaSV, tk.MaGV, tk.Email,
           COALESCE(sv.HoTen, gv.HoTen,
                    CASE WHEN tk.MaSV IS NULL AND tk.MaGV IS NULL
                         THEN N'Phòng Đào Tạo' END) AS HoTen
    FROM TAIKHOAN tk
    JOIN VAITRO vt ON vt.MaVaiTro = tk.MaVaiTro
    LEFT JOIN SINHVIEN sv ON sv.MaSV = tk.MaSV
    LEFT JOIN GIANGVIEN gv ON gv.MaGV = tk.MaGV
    WHERE tk.TenDangNhap = pTenDangNhap
      AND LOWER(tk.MatKhau) = LOWER(pMatKhauHash);
END$$

-- Doi mat khau: pKetQua = 0 OK; 404 khong tim thay; 401 mat khau cu sai.
-- Trigger TRG_LogDoiMatKhau tu ghi nhat ky (dung @ClientIP do backend truyen vao).
-- Luu y: MaTaiKhoan la VARCHAR ('TK0030') — KHONG dung INT de tranh ep kieu sai.
CREATE PROCEDURE SP_DoiMatKhau (
    IN  pMaTaiKhoan VARCHAR(10),
    IN  pMatKhauCuHash CHAR(64),
    IN  pMatKhauMoiHash CHAR(64),
    OUT pKetQua INT
)
BEGIN
    DECLARE vMatKhau CHAR(64);

    SELECT MatKhau INTO vMatKhau FROM TAIKHOAN WHERE MaTaiKhoan = pMaTaiKhoan;
    IF vMatKhau IS NULL THEN
        SET pKetQua = 404;
    ELSEIF LOWER(vMatKhau) <> LOWER(pMatKhauCuHash) THEN
        SET pKetQua = 401;
    ELSE
        UPDATE TAIKHOAN
        SET MatKhau = pMatKhauMoiHash
        WHERE MaTaiKhoan = pMaTaiKhoan;
        SET pKetQua = 0;
    END IF;
END$$

-- Ho so ca nhan (SV / GV) phuc vu dashboard kieu portal.
-- pMaSV/pMaGV truyen NULL khi khong dung toi.
CREATE PROCEDURE SP_LayHoSo (
    IN  pMaVaiTro CHAR(5),
    IN  pMaSV  VARCHAR(12),
    IN  pMaGV  VARCHAR(12)
)
BEGIN
    IF pMaVaiTro = 'SV' AND pMaSV IS NOT NULL THEN
        SELECT sv.MaSV, sv.HoTen, sv.NgaySinh, sv.GioiTinh, sv.Email,
               sv.SoDienThoai, sv.QueQuan, sv.TrangThaiHoc,
               l.MaLopSH, l.TenLopSH, l.NienKhoa, n.TenNganh, k.TenKhoa
        FROM SINHVIEN sv
        JOIN LOP_SINHHOAT l ON l.MaLopSH = sv.MaLopSH
        JOIN NGANH n ON n.MaNganh = l.MaNganh
        JOIN KHOA k ON k.MaKhoa = n.MaKhoa
        WHERE sv.MaSV = pMaSV;
    ELSEIF pMaVaiTro = 'GV' AND pMaGV IS NOT NULL THEN
        SELECT * FROM VW_HoSoGiangVien WHERE MaGV = pMaGV;
    END IF;
END$$

-- ==========================================================
-- 2. DANG KY HOC PHAN
-- ==========================================================

-- Danh sach dang ky hieu luc cua 1 SV (co loc hoc ky — tham so NULL = tat ca)
CREATE PROCEDURE SP_DSDangKyHieuLuc (
    IN pMaSV    VARCHAR(12),
    IN pMaHocKy VARCHAR(15)
)
BEGIN
    SELECT * FROM VW_SinhVienDangKyChiTiet
    WHERE MaSV = pMaSV
      AND TrangThaiDangKy = 'DA_DANG_KY'
      AND (pMaHocKy IS NULL OR MaHocKy = pMaHocKy)
    ORDER BY MaHocKy, MaLHP;
END$$

-- Thoi khoa bieu ca nhan cua 1 SV (view VW_ThoiKhoaBieuCaNhan, loc hoc ky)
CREATE PROCEDURE SP_DSThoiKhoaBieu (
    IN pMaSV    VARCHAR(12),
    IN pMaHocKy VARCHAR(15)
)
BEGIN
    SELECT * FROM VW_ThoiKhoaBieuCaNhan
    WHERE MaSV = pMaSV
      AND (pMaHocKy IS NULL OR MaHocKy = pMaHocKy)
    ORDER BY MaHocKy, Thu, TietBatDau;
END$$

-- PĐT: gan trang thai 1 dang ky (DUYET / TU_CHOI / DA_HUY / DA_DANG_KY)
CREATE PROCEDURE SP_GanTrangThaiDK (
    IN pMaSV VARCHAR(12),
    IN pMaLHP VARCHAR(15),
    IN pTrangThai VARCHAR(20),
    OUT pKetQua INT
)
BEGIN
    UPDATE DANGKYHOCPHAN
    SET TrangThaiDangKy = pTrangThai
    WHERE MaSV = pMaSV AND MaLHP = pMaLHP;
    SET pKetQua = ROW_COUNT();
END$$

-- PĐT: xoa 1 dang ky dang cho duyet
CREATE PROCEDURE SP_XoaDangKyChoDuyet (
    IN pMaSV VARCHAR(12),
    IN pMaLHP VARCHAR(15),
    OUT pKetQua INT
)
BEGIN
    DELETE FROM DANGKYHOCPHAN
    WHERE MaSV = pMaSV AND MaLHP = pMaLHP AND TrangThaiDangKy = 'CHO_DUYET';
    SET pKetQua = ROW_COUNT();
END$$

-- ==========================================================
-- 3. DANH MUC (doc)
-- ==========================================================

CREATE PROCEDURE SP_DM_HocKy ()
BEGIN
    SELECT hk.*,
           CASE WHEN hk.TrangThaiDot = 'MO' AND NOW() BETWEEN hk.TuNgay AND hk.DenNgay
                THEN 1 ELSE 0 END AS DangMoDangKy
    FROM HOCKY hk
    ORDER BY hk.TuNgay DESC;
END$$

CREATE PROCEDURE SP_DM_Khoa ()
BEGIN
    SELECT * FROM KHOA ORDER BY MaKhoa;
END$$

CREATE PROCEDURE SP_DM_Nganh ()
BEGIN
    SELECT n.*, k.TenKhoa
    FROM NGANH n JOIN KHOA k ON k.MaKhoa = n.MaKhoa
    ORDER BY n.MaNganh;
END$$

CREATE PROCEDURE SP_DM_Lop ()
BEGIN
    SELECT l.*, n.TenNganh, FN_DemSiSoLop(l.MaLopSH) AS SiSo
    FROM LOP_SINHHOAT l
    JOIN NGANH n ON n.MaNganh = l.MaNganh
    ORDER BY l.MaLopSH;
END$$

CREATE PROCEDURE SP_DM_MonHoc (
    IN pMaKhoa VARCHAR(10)
)
BEGIN
    SELECT mh.*, k.TenKhoa
    FROM MONHOC mh JOIN KHOA k ON k.MaKhoa = mh.MaKhoa
    WHERE pMaKhoa IS NULL OR mh.MaKhoa = pMaKhoa
    ORDER BY mh.MaMonHoc;
END$$

CREATE PROCEDURE SP_DM_GiangVien ()
BEGIN
    SELECT gv.*, k.TenKhoa
    FROM GIANGVIEN gv JOIN KHOA k ON k.MaKhoa = gv.MaKhoa
    ORDER BY gv.MaGV;
END$$

CREATE PROCEDURE SP_DM_PhongHoc ()
BEGIN
    SELECT * FROM PHONGHOC ORDER BY MaPhong;
END$$

CREATE PROCEDURE SP_DM_TienQuyet ()
BEGIN
    SELECT mtq.MaMonHoc, mh1.TenMonHoc, mtq.MaMonTienQuyet,
           mh2.TenMonHoc AS TenMonTienQuyet
    FROM MONHOC_TIENQUYET mtq
    JOIN MONHOC mh1 ON mh1.MaMonHoc = mtq.MaMonHoc
    JOIN MONHOC mh2 ON mh2.MaMonHoc = mtq.MaMonTienQuyet
    ORDER BY mtq.MaMonHoc;
END$$

CREATE PROCEDURE SP_DM_CTDiet (
    IN pMaNganh VARCHAR(10)
)
BEGIN
    SELECT ctdt.MaNganh, n.TenNganh, ctdt.MaMonHoc, mh.TenMonHoc, mh.SoTinChi,
           ctdt.HocKyDuKien, ctdt.BatBuoc
    FROM CHUONGTRINHDAOTAO ctdt
    JOIN NGANH n ON n.MaNganh = ctdt.MaNganh
    JOIN MONHOC mh ON mh.MaMonHoc = ctdt.MaMonHoc
    WHERE pMaNganh IS NULL OR ctdt.MaNganh = pMaNganh
    ORDER BY ctdt.MaNganh, ctdt.HocKyDuKien, ctdt.MaMonHoc;
END$$

-- Danh sach sinh vien (tim hoac lay toan bo — view VW_SinhVienDangHoc
-- chi chua SV dang hoc; SV nghi hoc van duoc tra ve qua truy van truc tiep
-- bang SINHVIEN trong SP nay).
CREATE PROCEDURE SP_DSSinhVien (
    IN pTim    VARCHAR(120),
    IN pMaLopSH VARCHAR(15)
)
BEGIN
    IF pTim IS NULL OR pTim = '' THEN
        SELECT * FROM VW_SinhVienDangHoc
        WHERE pMaLopSH IS NULL OR pMaLopSH = '' OR MaLopSH = pMaLopSH
        ORDER BY MaSV;
    ELSE
        SELECT * FROM VW_SinhVienDangHoc
        WHERE (pMaLopSH IS NULL OR pMaLopSH = '' OR MaLopSH = pMaLopSH)
          AND (HoTen LIKE CONCAT('%', pTim, '%') OR MaSV LIKE CONCAT('%', pTim, '%'))
        ORDER BY MaSV;
    END IF;
END$$

-- ==========================================================
-- 4. DANH MUC (ghi) — ho so sinh vien
-- ==========================================================

-- Cap nhat ho so SV: chi cap nhat truong truyen len (NULL = bo qua).
-- GUI tu frontend: MaLopSH, QueQuan, TrangThaiHoc la so dang chuoi —
-- ep ve so/deep de khong sai kieu (MySQL tu ep, nhung lam ro o day).
CREATE PROCEDURE SP_CapNhatHoSoSV (
    IN pMaSV VARCHAR(12),
    IN pHoTen VARCHAR(100),
    IN pNgaySinh DATE,
    IN pGioiTinh TINYINT,
    IN pEmail VARCHAR(100),
    IN pSoDienThoai VARCHAR(15),
    IN pQueQuan VARCHAR(200),
    IN pMaLopSH VARCHAR(15),
    IN pTrangThaiHoc TINYINT
)
BEGIN
    UPDATE SINHVIEN SET
        HoTen        = COALESCE(pHoTen, HoTen),
        NgaySinh     = COALESCE(pNgaySinh, NgaySinh),
        GioiTinh     = COALESCE(pGioiTinh, GioiTinh),
        Email        = COALESCE(pEmail, Email),
        SoDienThoai  = COALESCE(pSoDienThoai, SoDienThoai),
        QueQuan      = COALESCE(pQueQuan, QueQuan),
        MaLopSH      = COALESCE(pMaLopSH, MaLopSH),
        TrangThaiHoc = COALESCE(pTrangThaiHoc, TrangThaiHoc)
    WHERE MaSV = pMaSV;
    SELECT ROW_COUNT() AS SoDongCapNhat;
END$$

-- Xoa SV (FK se tu choi neu con du lieu lien quan)
CREATE PROCEDURE SP_XoaSinhVien (
    IN pMaSV VARCHAR(12),
    OUT pKetQua INT
)
BEGIN
    DELETE FROM SINHVIEN WHERE MaSV = pMaSV;
    SET pKetQua = ROW_COUNT();
END$$

-- ==========================================================
-- 5. ADMIN (doc + ghi)
-- ==========================================================

CREATE PROCEDURE SP_ThongKeTongHop ()
BEGIN
    SELECT
        (SELECT COUNT(*) FROM SINHVIEN) AS TongSinhVien,
        (SELECT COUNT(*) FROM SINHVIEN WHERE TrangThaiHoc = 1) AS SvDangHoc,
        (SELECT COUNT(*) FROM GIANGVIEN) AS TongGiangVien,
        (SELECT COUNT(*) FROM MONHOC) AS TongMonHoc,
        (SELECT COUNT(*) FROM LOPHOCPHAN) AS TongLopHocPhan,
        (SELECT COUNT(*) FROM LOPHOCPHAN WHERE TrangThaiLop = 'MO_DANG_KY') AS LopDangMo,
        (SELECT COUNT(*) FROM DANGKYHOCPHAN WHERE TrangThaiDangKy = 'DA_DANG_KY') AS TongDangKyHieuLuc,
        (SELECT COUNT(*) FROM TAIKHOAN) AS TongTaiKhoan;
END$$

CREATE PROCEDURE SP_TKDangKyTheoKy ()
BEGIN
    SELECT lhp.MaHocKy,
           COUNT(DISTINCT dk.MaSV) AS SoSVDangKy,
           COUNT(DISTINCT dk.MaLHP) AS SoLHP,
           COUNT(*) AS TongBanGhi,
           SUM(CASE WHEN dk.TrangThaiDangKy = 'DA_HUY' THEN 1 ELSE 0 END) AS DaHuy
    FROM DANGKYHOCPHAN dk
    JOIN LOPHOCPHAN lhp ON lhp.MaLHP = dk.MaLHP
    GROUP BY lhp.MaHocKy
    ORDER BY lhp.MaHocKy;
END$$

-- Danh sach LHP (loc hoc ky / trang thai — tham so NULL = khong loc)
CREATE PROCEDURE SP_DSLopHocPhan (
    IN pMaHocKy VARCHAR(15),
    IN pTrangThaiLop VARCHAR(30)
)
BEGIN
    SELECT lhp.*, mh.TenMonHoc, mh.SoTinChi, hk.TenHocKy, hk.NamHoc,
           gv.HoTen AS TenGV,
           (SELECT GROUP_CONCAT(CONCAT(lh.Thu, ':', lh.TietBatDau, '-',
                                       lh.TietBatDau + lh.SoTiet - 1, '@', ph.TenPhong)
                                SEPARATOR '; ')
              FROM LICHHOC lh JOIN PHONGHOC ph ON ph.MaPhong = lh.MaPhong
             WHERE lh.MaLHP = lhp.MaLHP) AS LichHoc
    FROM LOPHOCPHAN lhp
    JOIN MONHOC mh ON mh.MaMonHoc = lhp.MaMonHoc
    JOIN HOCKY hk ON hk.MaHocKy = lhp.MaHocKy
    LEFT JOIN GIANGVIEN gv ON gv.MaGV = lhp.MaGV
    WHERE (pMaHocKy IS NULL OR lhp.MaHocKy = pMaHocKy)
      AND (pTrangThaiLop IS NULL OR lhp.TrangThaiLop = pTrangThaiLop)
    ORDER BY lhp.MaHocKy DESC, lhp.MaLHP
    LIMIT 500;
END$$

CREATE PROCEDURE SP_DSTaiKhoan ()
BEGIN
    SELECT * FROM VW_TaiKhoanVaiTro ORDER BY MaTaiKhoan;
END$$

CREATE PROCEDURE SP_GanTrangThaiTaiKhoan (
    IN pMaTaiKhoan VARCHAR(10),
    IN pTrangThai VARCHAR(10)
)
BEGIN
    UPDATE TAIKHOAN SET TrangThai = pTrangThai WHERE MaTaiKhoan = pMaTaiKhoan;
END$$

CREATE PROCEDURE SP_DSNhatKyDoiMatKhau ()
BEGIN
    SELECT * FROM NHATKY_DOIMATKHAU ORDER BY ThoiGianThayDoi DESC LIMIT 200;
END$$

-- Thong bao sap ket thuc (dashboard SV/GV/PĐT — trang DangKyHocPhan goi)
CREATE PROCEDURE SP_ThongBaoSapKetThuc ()
BEGIN
    SELECT * FROM VW_ThongBaoSapKetThuc;
END$$

-- ==========================================================
-- 6. KET QUA HOC TAP
-- ==========================================================

CREATE PROCEDURE SP_DSBangDiem (
    IN pMaSV    VARCHAR(12),
    IN pMaHocKy VARCHAR(15)
)
BEGIN
    SELECT * FROM V_BANGDIEM_SINHVIEN
    WHERE MaSV = pMaSV
      AND (pMaHocKy IS NULL OR MaHocKy = pMaHocKy)
    ORDER BY MaHocKy, TenMonHoc;
END$$

CREATE PROCEDURE SP_DSThangDiemChu ()
BEGIN
    SELECT * FROM THANGDIEMCHU ORDER BY TuDiemHe10 DESC;
END$$

CREATE PROCEDURE SP_DSThongKeMonHoc (
    IN pMaLHP VARCHAR(15)
)
BEGIN
    SELECT * FROM V_THONGKE_KETQUA_MONHOC
    WHERE pMaLHP IS NULL OR MaLHP = pMaLHP
    ORDER BY MaLHP;
END$$

-- Danh sach SV canh bao hoc vu (SPA tinh CPA tung SV — do backend goi lai SP)
CREATE PROCEDURE SP_DSCanhBaoHocVu ()
BEGIN
    SELECT MaSV, HoTen, MaLopSH FROM SINHVIEN
    WHERE TrangThaiHoc = 1
    ORDER BY MaSV;
END$$

CREATE PROCEDURE SP_DSGpaTheoLop (
    IN pMaLHP VARCHAR(15)
)
BEGIN
    SELECT sv.MaSV, sv.HoTen, kq.DiemTongKet, kq.DiemChu, kq.DiemHe4,
           mh.SoTinChi, lhp.MaHocKy
    FROM DANGKYHOCPHAN dk
    JOIN SINHVIEN sv ON sv.MaSV = dk.MaSV
    JOIN LOPHOCPHAN lhp ON lhp.MaLHP = dk.MaLHP
    JOIN MONHOC mh ON mh.MaMonHoc = lhp.MaMonHoc
    LEFT JOIN KETQUAHOCTAP kq ON kq.MaSV = dk.MaSV AND kq.MaLHP = dk.MaLHP
    WHERE dk.MaLHP = pMaLHP AND dk.TrangThaiDangKy = 'DA_DANG_KY'
    ORDER BY sv.MaSV;
END$$

-- ==========================================================
-- 7. HOC PHI
-- ==========================================================

CREATE PROCEDURE SP_DSHocPhiCuaToi (
    IN pMaSV VARCHAR(12)
)
BEGIN
    SELECT hp.*, hk.TenHocKy, hk.NamHoc, (hp.TongTien - hp.DaNop) AS ConNo
    FROM HOCPHI hp JOIN HOCKY hk ON hk.MaHocKy = hp.MaHocKy
    WHERE hp.MaSV = pMaSV
    ORDER BY hp.MaHocKy DESC;
END$$

-- PĐT: danh sach hoc phi (loc trang thai / hoc ky — NULL = khong loc)
CREATE PROCEDURE SP_DSHocPhiDanhsach (
    IN pTrangThai VARCHAR(30),
    IN pMaHocKy   VARCHAR(15)
)
BEGIN
    SELECT hp.*, sv.HoTen, l.TenLopSH, n.TenNganh,
           (hp.TongTien - hp.DaNop) AS ConNo
    FROM HOCPHI hp
    JOIN SINHVIEN sv ON sv.MaSV = hp.MaSV
    JOIN LOP_SINHHOAT l ON l.MaLopSH = sv.MaLopSH
    JOIN NGANH n ON n.MaNganh = l.MaNganh
    WHERE (pTrangThai IS NULL OR hp.TrangThai = pTrangThai)
      AND (pMaHocKy IS NULL OR hp.MaHocKy = pMaHocKy)
    ORDER BY hp.MaHocKy DESC, sv.MaSV
    LIMIT 500;
END$$

-- PĐT: bao cao hoc phi (dong 1) + 3 view tong hop
CREATE PROCEDURE SP_ThongKeHocPhi ()
BEGIN
    SELECT COUNT(*) AS TongPhieu, COUNT(DISTINCT MaSV) AS TongSinhVien,
           SUM(TongTien) AS TongHocPhi, SUM(DaNop) AS TongDaThu,
           SUM(TongTien - DaNop) AS TongConNo,
           SUM(CASE WHEN TrangThai = 'DA_THANH_TOAN' THEN 1 ELSE 0 END) AS DaThanhToan,
           SUM(CASE WHEN TrangThai <> 'DA_THANH_TOAN' THEN 1 ELSE 0 END) AS ChuaThanhToan
    FROM HOCPHI;
    SELECT * FROM VW_TongThuTheoHocKy ORDER BY MaHocKy;
    SELECT * FROM VW_TongThuTheoNganh;
    SELECT * FROM VW_SinhVienNoHocPhi ORDER BY SoTienConNo DESC LIMIT 50;
END$$

-- ==========================================================
-- 8. GIANG VIEN
-- ==========================================================

-- Lop cua toi (loc hoc ky — NULL = tat ca)
CREATE PROCEDURE SP_GV_LopCuaToi (
    IN pMaGV    VARCHAR(12),
    IN pMaHocKy VARCHAR(15)
)
BEGIN
    SELECT lhp.*, mh.TenMonHoc, mh.SoTinChi, hk.TenHocKy, hk.NamHoc,
           (SELECT GROUP_CONCAT(CONCAT(lh.Thu, ':', lh.TietBatDau, '-',
                                       lh.TietBatDau + lh.SoTiet - 1)
                                SEPARATOR '; ')
              FROM LICHHOC lh WHERE lh.MaLHP = lhp.MaLHP) AS LichHoc
    FROM LOPHOCPHAN lhp
    JOIN MONHOC mh ON mh.MaMonHoc = lhp.MaMonHoc
    JOIN HOCKY hk ON hk.MaHocKy = lhp.MaHocKy
    WHERE lhp.MaGV = pMaGV
      AND (pMaHocKy IS NULL OR lhp.MaHocKy = pMaHocKy)
    ORDER BY lhp.MaHocKy DESC, lhp.MaLHP;
END$$

-- Kiem tra GV co phu trach LHP: 1 dong = OK; 0 dong = LHP khong ton tai;
-- ket qua 2 (GuV khac) = khong phu trach.
CREATE PROCEDURE SP_GV_KiemTraLop (
    IN pMaGV VARCHAR(12),
    IN pMaLHP VARCHAR(15)
)
BEGIN
    SELECT CASE
             WHEN NOT EXISTS (SELECT 1 FROM LOPHOCPHAN WHERE MaLHP = pMaLHP) THEN 0
             WHEN (SELECT MaGV FROM LOPHOCPHAN WHERE MaLHP = pMaLHP) = pMaGV THEN 1
             ELSE 2
           END AS KetQua;
END$$

CREATE PROCEDURE SP_GV_DSSinhVienLop (
    IN pMaLHP VARCHAR(15)
)
BEGIN
    SELECT sv.MaSV, sv.HoTen, sv.MaLopSH, dk.NgayDangKy, dk.TrangThaiDangKy,
           kq.DiemChuyenCan, kq.DiemGiuaKy, kq.DiemCuoiKy,
           kq.DiemTongKet, kq.DiemChu, kq.DiemHe4
    FROM DANGKYHOCPHAN dk
    JOIN SINHVIEN sv ON sv.MaSV = dk.MaSV
    LEFT JOIN KETQUAHOCTAP kq ON kq.MaSV = dk.MaSV AND kq.MaLHP = dk.MaLHP
    WHERE dk.MaLHP = pMaLHP AND dk.TrangThaiDangKy = 'DA_DANG_KY'
    ORDER BY sv.MaSV;
END$$

-- Health check cho server.js (thay 'SELECT 1' — giu quy tac khong raw query)
CREATE PROCEDURE SP_HealthCheck ()
BEGIN
    SELECT 1 AS ok;
END$$

DELIMITER ;

SELECT '[OK] web_procedures.sql — da tao 39 SP phuc vu tang web.' AS KetLuan;
