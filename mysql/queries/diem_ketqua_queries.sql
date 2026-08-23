-- ==========================================================
-- Ten file : mysql/queries/diem_ketqua_queries.sql
-- Module   : Diem so & Ket qua hoc tap (TV4)
-- Issue    : #52 Truy van & View Diem so & Ket qua hoc tap
-- Mo ta    : Ban dich T-SQL -> MySQL (CTE -> derived table,
--            RANK/DENSE_RANK giu nguyen, bo GO / N'').
--            View V_BANGDIEM_SINHVIEN da tao o mysql/views/.
-- ==========================================================

-- ==========================================================
-- Q1. BANG DIEM CA NHAN THEO HOC KY
-- ==========================================================
SELECT MaSV, TenSinhVien, MaLHP, TenMonHoc, SoTinChi,
       DiemChuyenCan, DiemGiuaKy, DiemCuoiKy, DiemTongKet, DiemChu, DiemHe4, XepLoaiMonHoc
FROM V_BANGDIEM_SINHVIEN
WHERE MaSV = 'SV001' AND MaHocKy = 'HK1-2023'
ORDER BY TenMonHoc;

-- ==========================================================
-- Q2. SV DIEM CAO NHAT / THAP NHAT MOI LOP HOC PHAN
--     (RANK / DENSE_RANK — MySQL 8.0)
-- ==========================================================
SELECT MaLHP, TenLHP, TenMonHoc, MaSV, HoTen, DiemTongKet, DiemChu, XepHang
FROM (
    SELECT
        lhp.MaLHP, lhp.TenLHP, mh.TenMonHoc, sv.MaSV, sv.HoTen,
        kq.DiemTongKet, kq.DiemChu,
        RANK() OVER (PARTITION BY lhp.MaLHP ORDER BY kq.DiemTongKet DESC) AS XepHang
    FROM KETQUAHOCTAP kq
    JOIN LOPHOCPHAN lhp ON kq.MaLHP = lhp.MaLHP
    JOIN MONHOC     mh  ON lhp.MaMonHoc = mh.MaMonHoc
    JOIN SINHVIEN   sv  ON sv.MaSV = kq.MaSV
    WHERE kq.DiemTongKet IS NOT NULL
) ranked
WHERE XepHang = 1
ORDER BY MaLHP;

-- ==========================================================
-- Q3. DANH SACH SV THEO XEP LOAI HOC LUC
-- ==========================================================
SELECT
    sv.MaSV, sv.HoTen,
    ROUND(AVG(kq.DiemHe4 * mh.SoTinChi) / AVG(mh.SoTinChi), 2) AS DiemTBL,
    CASE
        WHEN AVG(kq.DiemHe4 * mh.SoTinChi) / AVG(mh.SoTinChi) >= 3.60 THEN 'Xuat sac'
        WHEN AVG(kq.DiemHe4 * mh.SoTinChi) / AVG(mh.SoTinChi) >= 3.20 THEN 'Gioi'
        WHEN AVG(kq.DiemHe4 * mh.SoTinChi) / AVG(mh.SoTinChi) >= 2.50 THEN 'Kha'
        WHEN AVG(kq.DiemHe4 * mh.SoTinChi) / AVG(mh.SoTinChi) >= 2.00 THEN 'Trung binh'
        ELSE 'Yeu/Kem'
    END AS XepLoai
FROM SINHVIEN sv
JOIN KETQUAHOCTAP kq ON kq.MaSV = sv.MaSV AND kq.DiemHe4 IS NOT NULL
JOIN LOPHOCPHAN  lhp ON lhp.MaLHP = kq.MaLHP
JOIN MONHOC      mh  ON mh.MaMonHoc = lhp.MaMonHoc
GROUP BY sv.MaSV, sv.HoTen
ORDER BY DiemTBL DESC;

-- ==========================================================
-- Q4. TY LE DAT / KHONG DAT MOI MON (GROUP BY / HAVING)
-- ==========================================================
SELECT
    mh.MaMonHoc,
    mh.TenMonHoc,
    COUNT(*) AS TongSV,
    SUM(CASE WHEN kq.DiemHe4 >= 1.0 THEN 1 ELSE 0 END) AS Dat,
    SUM(CASE WHEN kq.DiemHe4 < 1.0 THEN 1 ELSE 0 END)  AS KhongDat,
    ROUND(SUM(CASE WHEN kq.DiemHe4 >= 1.0 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS TyLeDat
FROM KETQUAHOCTAP kq
JOIN LOPHOCPHAN lhp ON lhp.MaLHP = kq.MaLHP
JOIN MONHOC     mh  ON mh.MaMonHoc = lhp.MaMonHoc
GROUP BY mh.MaMonHoc, mh.TenMonHoc
HAVING COUNT(*) > 0
ORDER BY TyLeDat DESC;

-- ==========================================================
-- Q5. THONG KE KET QUA MON HOC (View V_THONGKE_KETQUA_MONHOC)
-- ==========================================================
SELECT * FROM V_THONGKE_KETQUA_MONHOC ORDER BY MaLHP;

-- ==========================================================
-- Q6. CANH BAO HOC VU (SV co CPA < 1.60 — goi SP_TinhCPA_TichLuy)
-- ==========================================================
CALL SP_TinhCPA_TichLuy('SV001');

-- ==========================================================
-- Q7. GV XEM DIEM LOP MINH DAY (nhap diem / cham diem)
-- ==========================================================
SELECT
    sv.MaSV, sv.HoTen, sv.MaLopSH, dk.NgayDangKy, dk.TrangThaiDangKy,
    kq.DiemChuyenCan, kq.DiemGiuaKy, kq.DiemCuoiKy, kq.DiemTongKet, kq.DiemChu, kq.DiemHe4
FROM DANGKYHOCPHAN dk
JOIN SINHVIEN sv ON sv.MaSV = dk.MaSV
LEFT JOIN KETQUAHOCTAP kq ON kq.MaSV = dk.MaSV AND kq.MaLHP = dk.MaLHP
WHERE dk.MaLHP = 'LHP101' AND dk.TrangThaiDangKy = 'DA_DANG_KY'
ORDER BY sv.MaSV;
