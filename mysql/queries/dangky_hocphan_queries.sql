-- ==========================================================
-- Ten file : mysql/queries/dangky_hocphan_queries.sql
-- Module   : Dang ky hoc phan (TV3 — Leader)
-- Issue    : #49 Truy van & View Dang ky hoc phan
-- Mo ta    : Ban dich T-SQL -> MySQL (bo GO, N'', TOP -> LIMIT).
--            Q1..Q7 + 2 VIEW da tao o mysql/views/.
-- ==========================================================

-- ==========================================================
-- Q1. SV DA DANG KY THEO LOP HOC PHAN (kem si so hien tai)
-- ==========================================================
SELECT
    lhp.MaLHP,
    lhp.TenLHP,
    hk.MaHocKy,
    sv.MaSV,
    sv.HoTen,
    dk.NgayDangKy,
    dk.TrangThaiDangKy,
    lhp.SiSoHienTai AS `Si so hien tai`,
    lhp.SiSoToiDa    AS `Si so toi da`
FROM DANGKYHOCPHAN dk
JOIN SINHVIEN      sv  ON sv.MaSV   = dk.MaSV
JOIN LOPHOCPHAN    lhp ON lhp.MaLHP = dk.MaLHP
JOIN HOCKY         hk  ON hk.MaHocKy = lhp.MaHocKy
WHERE dk.TrangThaiDangKy = 'DA_DANG_KY'
ORDER BY lhp.MaLHP, sv.MaSV;

-- ==========================================================
-- Q2. SV CHUA DU / VUOT TIN CHI TRONG HOC KY (Min 12, Max 24)
-- ==========================================================
SELECT
    sv.MaSV,
    sv.HoTen,
    SUM(mh.SoTinChi) AS `Tong tin chi da Dk`,
    CASE
        WHEN SUM(mh.SoTinChi) < 12 THEN CONCAT('CHUA DU tin chi (thieu ', 12 - SUM(mh.SoTinChi), ' TC)')
        WHEN SUM(mh.SoTinChi) > 24 THEN CONCAT('VUOT tin chi (vuot ', SUM(mh.SoTinChi) - 24, ' TC)')
        ELSE 'Dat yeu cau'
    END AS `Danh gia`
FROM SINHVIEN sv
JOIN DANGKYHOCPHAN dk ON dk.MaSV = sv.MaSV AND dk.TrangThaiDangKy = 'DA_DANG_KY'
JOIN LOPHOCPHAN    lhp ON lhp.MaLHP = dk.MaLHP
JOIN MONHOC        mh  ON mh.MaMonHoc = lhp.MaMonHoc
WHERE lhp.MaHocKy = 'HK1-2025'
GROUP BY sv.MaSV, sv.HoTen
ORDER BY sv.MaSV;

-- ==========================================================
-- Q3. KIEM TRA TIEN QUYET BANG SUBQUERY / EXISTS
--     (su dung ham FN_KiemTraTienQuyet da tao)
-- ==========================================================
SELECT
    sv.MaSV,
    sv.HoTen,
    lhp.MaLHP,
    mh.TenMonHoc,
    mh.MaMonHoc,
    FN_KiemTraTienQuyet(sv.MaSV, mh.MaMonHoc) AS DuTienQuyet
FROM SINHVIEN sv
JOIN DANGKYHOCPHAN dk ON dk.MaSV = sv.MaSV
JOIN LOPHOCPHAN    lhp ON lhp.MaLHP = dk.MaLHP
JOIN MONHOC        mh  ON mh.MaMonHoc = lhp.MaMonHoc
WHERE dk.TrangThaiDangKy = 'DA_DANG_KY'
  AND lhp.MaHocKy = 'HK1-2025'
  AND EXISTS (SELECT 1 FROM MONHOC_TIENQUYET mtq WHERE mtq.MaMonHoc = mh.MaMonHoc)
ORDER BY sv.MaSV;

-- ==========================================================
-- Q4. THOI KHOA BIEU CA NHAN (View VW_ThoiKhoaBieuCaNhan)
-- ==========================================================
SELECT MaHocKy, Thu, TietBatDau, SoTiet, MaLHP, TenLHP, TenMonHoc, TenPhong, HoTenGV
FROM VW_ThoiKhoaBieuCaNhan
WHERE MaSV = 'SV001' AND MaHocKy = 'HK1-2025'
ORDER BY Thu, TietBatDau;

-- ==========================================================
-- Q5. THONG KE DANG KY THEO HOC KY
-- ==========================================================
SELECT
    lhp.MaHocKy,
    COUNT(DISTINCT dk.MaSV) AS SoSVDangKy,
    COUNT(DISTINCT dk.MaLHP) AS SoLHP,
    COUNT(*) AS TongBanGhi,
    SUM(CASE WHEN dk.TrangThaiDangKy = 'DA_HUY' THEN 1 ELSE 0 END) AS DaHuy
FROM DANGKYHOCPHAN dk
JOIN LOPHOCPHAN lhp ON lhp.MaLHP = dk.MaLHP
GROUP BY lhp.MaHocKy
ORDER BY lhp.MaHocKy;

-- ==========================================================
-- Q6. SV DANG KY TRUNG LICH (anomaly detection)
--     FN_KiemTraTrungLichHoc tra ve 1 neu trung lich
-- ==========================================================
SELECT
    dk.MaSV,
    sv.HoTen,
    dk.MaLHP,
    FN_KiemTraTrungLichHoc(dk.MaSV, dk.MaLHP) AS TrungLich
FROM DANGKYHOCPHAN dk
JOIN SINHVIEN sv ON sv.MaSV = dk.MaSV
WHERE dk.TrangThaiDangKy = 'DA_DANG_KY'
  AND FN_KiemTraTrungLichHoc(dk.MaSV, dk.MaLHP) = 1
ORDER BY dk.MaSV;

-- ==========================================================
-- Q7. LOP SAP HET CHO (sat si so)
-- ==========================================================
SELECT MaLHP, TenLHP, SiSoHienTai, SiSoToiDa,
       (SiSoToiDa - SiSoHienTai) AS SoChoTrong
FROM LOPHOCPHAN
WHERE TrangThaiLop = 'MO_DANG_KY'
  AND (SiSoToiDa - SiSoHienTai) <= 3
ORDER BY SoChoTrong ASC;

-- ==========================================================
-- Q8. DANH SACH DANG KY CHI TIET (View)
-- ==========================================================
SELECT MaSV, MaLHP, TenLHP, TenMonHoc, SoTinChi, MaHocKy, HoTenGV, NgayDangKy, TrangThaiDangKy
FROM VW_SinhVienDangKyChiTiet
WHERE MaSV = 'SV001'
ORDER BY MaHocKy DESC, MaLHP;
