-- ==========================================================
-- Ten file : mysql/queries/danh_muc_hoso_sv_queries.sql
-- Module   : Danh muc he thong & Ho so sinh vien (TV1)
-- Mo ta    : Ban dich T-SQL -> MySQL.
--            Q1..Q5: SV theo Khoa/Nganh/Lop + si so, SV chua xep
--            lop, tra cuu CTDT, danh sach SV dang hoc (View).
-- ==========================================================

-- ==========================================================
-- Q1. DANH SACH SINH VIEN THEO KHOA / NGANH / LOP + SI SO
-- ==========================================================
SELECT
    k.MaKhoa, k.TenKhoa,
    n.MaNganh, n.TenNganh,
    l.MaLopSH, l.TenLopSH, l.NienKhoa,
    COUNT(sv.MaSV) AS SiSo
FROM KHOA k
JOIN NGANH n ON n.MaKhoa = k.MaKhoa
JOIN LOP_SINHHOAT l ON l.MaNganh = n.MaNganh
LEFT JOIN SINHVIEN sv ON sv.MaLopSH = l.MaLopSH AND sv.TrangThaiHoc = 1
GROUP BY k.MaKhoa, k.TenKhoa, n.MaNganh, n.TenNganh, l.MaLopSH, l.TenLopSH, l.NienKhoa
ORDER BY k.MaKhoa, n.MaNganh, l.MaLopSH;

-- ==========================================================
-- Q2. SINH VIEN CHUA XEP LOP (khong thuoc lop sinh hoat nao)
-- ==========================================================
SELECT sv.MaSV, sv.HoTen, sv.Email, sv.TrangThaiHoc
FROM SINHVIEN sv
LEFT JOIN LOP_SINHHOAT l ON sv.MaLopSH = l.MaLopSH
WHERE l.MaLopSH IS NULL
ORDER BY sv.MaSV;

-- ==========================================================
-- Q3. TRA CUU CHUONG TRINH DAO TAO THEO NGANH - KHOAHOC
--     (Nganh CNTT - cac mon du kien theo hoc ky)
-- ==========================================================
SELECT
    n.MaNganh, n.TenNganh,
    ctdt.HocKyDuKien,
    mh.MaMonHoc, mh.TenMonHoc, mh.SoTinChi,
    IF(ctdt.BatBuoc = 1, 'Bat buoc', 'Tu chon') AS LoaiMon
FROM CHUONGTRINHDAOTAO ctdt
JOIN NGANH n ON ctdt.MaNganh = n.MaNganh
JOIN MONHOC mh ON ctdt.MaMonHoc = mh.MaMonHoc
WHERE n.MaNganh = 'CNTT'
ORDER BY ctdt.HocKyDuKien, mh.MaMonHoc;

-- ==========================================================
-- Q4. DANH SACH SINH VIEN DANG HOC (View VW_SinhVienDangHoc
--     duoc tao o mysql/views/danh_muc_hoso_sv_views.sql)
-- ==========================================================
SELECT * FROM VW_SinhVienDangHoc ORDER BY MaSV;

-- ==========================================================
-- Q5. TRA CUU SINH VIEN THEO HO TEN / LOP (su dung Index
--     idx_sinhvien_hoten_malop trong mysql/indexes/all_indexes.sql)
-- ==========================================================
SELECT sv.MaSV, sv.HoTen, sv.Email, sv.SoDienThoai, l.TenLopSH
FROM SINHVIEN sv
JOIN LOP_SINHHOAT l ON sv.MaLopSH = l.MaLopSH
WHERE sv.HoTen LIKE '%Nguyen%' OR sv.MaLopSH = 'CNTT01'
ORDER BY sv.MaSV;

-- ==========================================================
-- Q6. DEM SI SO LOP (dung Function FN_DemSiSoLop da tao)
-- ==========================================================
SELECT l.MaLopSH, l.TenLopSH, FN_DemSiSoLop(l.MaLopSH) AS SiSo
FROM LOP_SINHHOAT l
ORDER BY l.MaLopSH;
