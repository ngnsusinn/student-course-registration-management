-- ==========================================================
-- Ten file : mysql/views/diem_ketqua_views.sql
-- Module   : Diem so & Ket qua hoc tap (TV4)
-- Mo ta    : Ban dich T-SQL -> MySQL:
--            V_BANGDIEM_SINHVIEN, V_THONGKE_KETQUA_MONHOC.
--            (VW_DIEM_CUA_TOI voi SESSION_CONTEXT khong ton tai
--             trong MySQL -> loc theo MaSV o lop ung dung/API.)
-- ==========================================================

CREATE OR REPLACE VIEW V_BANGDIEM_SINHVIEN AS
SELECT
    sv.MaSV,
    sv.HoTen AS TenSinhVien,
    lsh.MaLopSH,
    hk.MaHocKy,
    hk.TenHocKy,
    lhp.MaLHP,
    mh.MaMonHoc,
    mh.TenMonHoc,
    mh.SoTinChi,
    kq.DiemChuyenCan,
    kq.DiemGiuaKy,
    kq.DiemCuoiKy,
    kq.DiemTongKet,
    kq.DiemChu,
    kq.DiemHe4,
    tdc.XepLoai AS XepLoaiMonHoc
FROM KETQUAHOCTAP kq
JOIN SINHVIEN sv ON kq.MaSV = sv.MaSV
JOIN LOP_SINHHOAT lsh ON sv.MaLopSH = lsh.MaLopSH
JOIN LOPHOCPHAN lhp ON kq.MaLHP = lhp.MaLHP
JOIN MONHOC mh ON lhp.MaMonHoc = mh.MaMonHoc
JOIN HOCKY hk ON lhp.MaHocKy = hk.MaHocKy
LEFT JOIN THANGDIEMCHU tdc ON kq.DiemChu = tdc.DiemChu;

CREATE OR REPLACE VIEW V_THONGKE_KETQUA_MONHOC AS
SELECT
    lhp.MaLHP,
    lhp.TenLHP,
    mh.TenMonHoc,
    hk.TenHocKy,
    COUNT(kq.MaSV) AS TongSoSinhVien,
    SUM(CASE WHEN kq.DiemChu IS NOT NULL AND kq.DiemChu <> 'F' THEN 1 ELSE 0 END) AS SoSV_Dat,
    SUM(CASE WHEN kq.DiemChu = 'F' THEN 1 ELSE 0 END) AS SoSV_KiemTraF,
    SUM(CASE WHEN kq.DiemTongKet IS NULL THEN 1 ELSE 0 END) AS SoSV_ChuaCoDiem,
    ROUND(
        SUM(CASE WHEN kq.DiemChu IS NOT NULL AND kq.DiemChu <> 'F' THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(kq.MaSV), 0), 2
    ) AS TyLeDat_Percent
FROM LOPHOCPHAN lhp
JOIN MONHOC mh ON lhp.MaMonHoc = mh.MaMonHoc
JOIN HOCKY hk ON lhp.MaHocKy = hk.MaHocKy
LEFT JOIN KETQUAHOCTAP kq ON lhp.MaLHP = kq.MaLHP
GROUP BY lhp.MaLHP, lhp.TenLHP, mh.TenMonHoc, hk.TenHocKy;
