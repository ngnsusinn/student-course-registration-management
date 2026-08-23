-- ==========================================================
-- Ten file : mysql/views/dangky_hocphan_views.sql
-- Module   : Dang ky hoc phan (TV3)
-- Mo ta    : Ban dich T-SQL -> MySQL:
--            VW_SinhVienDangKyChiTiet, VW_ThoiKhoaBieuCaNhan.
-- ==========================================================

CREATE OR REPLACE VIEW VW_SinhVienDangKyChiTiet AS
SELECT
    dk.MaSV,
    sv.HoTen       AS HoTenSV,
    sv.MaLopSH,
    dk.MaLHP,
    lhp.TenLHP,
    mh.TenMonHoc,
    mh.SoTinChi,
    lhp.MaHocKy,
    hk.TenHocKy,
    hk.NamHoc,
    lhp.MaGV,
    gv.HoTen       AS HoTenGV,
    dk.NgayDangKy,
    dk.TrangThaiDangKy,
    dk.GhiChu
FROM DANGKYHOCPHAN dk
JOIN SINHVIEN      sv  ON sv.MaSV  = dk.MaSV
JOIN LOPHOCPHAN    lhp ON lhp.MaLHP = dk.MaLHP
JOIN MONHOC        mh  ON mh.MaMonHoc = lhp.MaMonHoc
JOIN HOCKY         hk  ON hk.MaHocKy = lhp.MaHocKy
LEFT JOIN GIANGVIEN gv ON gv.MaGV = lhp.MaGV;

CREATE OR REPLACE VIEW VW_ThoiKhoaBieuCaNhan AS
SELECT
    dk.MaSV,
    sv.HoTen AS HoTenSV,
    lhp.MaHocKy,
    lh.Thu,
    lh.TietBatDau,
    lh.SoTiet,
    lhp.MaLHP,
    lhp.TenLHP,
    mh.TenMonHoc,
    ph.TenPhong,
    gv.HoTen AS HoTenGV
FROM DANGKYHOCPHAN dk
JOIN SINHVIEN      sv  ON sv.MaSV = dk.MaSV
JOIN LOPHOCPHAN    lhp ON lhp.MaLHP = dk.MaLHP
JOIN MONHOC        mh  ON mh.MaMonHoc = lhp.MaMonHoc
JOIN LICHHOC       lh  ON lh.MaLHP = lhp.MaLHP
JOIN PHONGHOC      ph  ON ph.MaPhong = lh.MaPhong
LEFT JOIN GIANGVIEN gv ON gv.MaGV = lhp.MaGV
WHERE dk.TrangThaiDangKy = 'DA_DANG_KY';
