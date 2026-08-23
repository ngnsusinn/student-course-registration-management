-- ==========================================================
-- Ten file : mysql/queries/hocphan_giangvien_molophocphan_queries.sql
-- Module   : Hoc phan, Giang vien & Mo lop hoc phan (TV2)
-- Mo ta    : Ban dich T-SQL -> MySQL.
--            Q1..Q7: LHP theo HK + si so, tra tien quyet, TKB theo
--            GV/phong, kiem tra phong trong, LHP theo mon, thong ke.
-- ==========================================================

-- ==========================================================
-- Q1. LHP THEO HOC KY + SI SO CON TRONG
-- ==========================================================
SELECT
    lhp.MaLHP,
    lhp.TenLHP,
    mh.TenMonHoc,
    hk.TenHocKy,
    hk.NamHoc,
    lhp.SiSoToiDa,
    lhp.SiSoHienTai,
    (lhp.SiSoToiDa - lhp.SiSoHienTai) AS SoChoConTrong,
    lhp.TrangThaiLop
FROM LOPHOCPHAN lhp
JOIN MONHOC mh ON lhp.MaMonHoc = mh.MaMonHoc
JOIN HOCKY  hk ON lhp.MaHocKy  = hk.MaHocKy
WHERE hk.MaHocKy = 'HK1-2025'
ORDER BY lhp.MaLHP;

-- ==========================================================
-- Q2. TRA MON TIEN QUYET
-- ==========================================================
SELECT
    mh.MaMonHoc,
    mh.TenMonHoc,
    mtq.MaMonTienQuyet,
    mhTQ.TenMonHoc AS TenMonTienQuyet
FROM MONHOC mh
JOIN MONHOC_TIENQUYET mtq ON mtq.MaMonHoc = mh.MaMonHoc
JOIN MONHOC mhTQ ON mhTQ.MaMonHoc = mtq.MaMonTienQuyet
ORDER BY mh.MaMonHoc;

-- ==========================================================
-- Q3. THOI KHOA BIEU THEO GIANG VIEN
-- ==========================================================
SELECT
    gv.MaGV, gv.HoTen, hk.MaHocKy,
    lh.Thu, lh.TietBatDau, lh.SoTiet,
    lhp.MaLHP, lhp.TenLHP, mh.TenMonHoc, ph.TenPhong
FROM LICHHOC lh
JOIN LOPHOCPHAN lhp ON lh.MaLHP = lhp.MaLHP
JOIN MONHOC mh ON lhp.MaMonHoc = mh.MaMonHoc
JOIN PHONGHOC ph ON lh.MaPhong = ph.MaPhong
JOIN GIANGVIEN gv ON lhp.MaGV = gv.MaGV
JOIN HOCKY hk ON lhp.MaHocKy = hk.MaHocKy
WHERE gv.MaGV = 'GV001' AND hk.MaHocKy = 'HK1-2025'
ORDER BY lh.Thu, lh.TietBatDau;

-- ==========================================================
-- Q4. THOI KHOA BIEU THEO PHONG
-- ==========================================================
SELECT
    ph.MaPhong, ph.TenPhong, hk.MaHocKy,
    lh.Thu, lh.TietBatDau, lh.SoTiet,
    lhp.MaLHP, lhp.TenLHP, mh.TenMonHoc, gv.HoTen AS TenGV
FROM LICHHOC lh
JOIN PHONGHOC ph ON lh.MaPhong = ph.MaPhong
JOIN LOPHOCPHAN lhp ON lh.MaLHP = lhp.MaLHP
JOIN MONHOC mh ON lhp.MaMonHoc = mh.MaMonHoc
LEFT JOIN GIANGVIEN gv ON lhp.MaGV = gv.MaGV
JOIN HOCKY hk ON lhp.MaHocKy = hk.MaHocKy
WHERE ph.MaPhong = 'P001' AND hk.MaHocKy = 'HK1-2025'
ORDER BY lh.Thu, lh.TietBatDau;

-- ==========================================================
-- Q5. KIEM TRA PHONG TRONG THEO KHUNG GIO
--     (dung Function FN_KiemTraPhongTrong da tao)
-- ==========================================================
SELECT ph.MaPhong, ph.TenPhong, ph.SucChua,
       FN_KiemTraPhongTrong(ph.MaPhong, 2, 1, 3) AS TrongKhungGio
FROM PHONGHOC ph
WHERE ph.SucChua >= 40
ORDER BY ph.MaPhong;

-- ==========================================================
-- Q6. DANH SACH LHP THEO MON HOC
-- ==========================================================
SELECT mh.MaMonHoc, mh.TenMonHoc,
       lhp.MaLHP, lhp.TenLHP, lhp.SiSoHienTai, lhp.SiSoToiDa,
       lhp.TrangThaiLop
FROM MONHOC mh
JOIN LOPHOCPHAN lhp ON lhp.MaMonHoc = mh.MaMonHoc
WHERE mh.MaMonHoc = 'MH001'
ORDER BY lhp.MaLHP;

-- ==========================================================
-- Q7. THONG KE SO LHP THEO GIANG VIEN
-- ==========================================================
SELECT
    gv.MaGV, gv.HoTen,
    COUNT(DISTINCT lhp.MaLHP) AS SoLHPPhuTrach,
    SUM(lhp.SiSoHienTai) AS TongSinhVien
FROM GIANGVIEN gv
LEFT JOIN LOPHOCPHAN lhp ON lhp.MaGV = gv.MaGV
GROUP BY gv.MaGV, gv.HoTen
ORDER BY SoLHPPhuTrach DESC;
