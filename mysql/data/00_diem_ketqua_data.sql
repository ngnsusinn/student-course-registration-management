-- ==========================================================
-- Ten file : mysql/data/00_diem_ketqua_data.sql
-- Module   : Diem so & Ket qua hoc tap (TV4)
-- Mo ta    : THANGDIEMCHU + diem cho SV da dang ky o cac hoc ky
--            HK1-2023..HK2-2024. Ban dich T-SQL (CTE) sang
--            MySQL 5.7 dung derived table.
-- ==========================================================

-- 1. THANGDIEMCHU
INSERT INTO THANGDIEMCHU (DiemChu, TuDiemHe10, DenDiemHe10, DiemHe4, XepLoai) VALUES
('A',   8.5, 10.0, 4.0, 'Xuất sắc'),
('B+',  7.8,  8.4, 3.5, 'Khá giỏi'),
('B',   7.0,  7.7, 3.0, 'Khá'),
('C+',  6.5,  6.9, 2.5, 'Trung bình khá'),
('C',   5.5,  6.4, 2.0, 'Trung bình'),
('D+',  4.8,  5.4, 1.5, 'Trung bình yếu'),
('D',   4.0,  4.7, 1.0, 'Yếu'),
('F',   0.0,  3.9, 0.0, 'Kém');

-- 2. DIEM CAC HOC KY HK1-2023..HK2-2024
INSERT INTO KETQUAHOCTAP (MaSV, MaLHP, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy, DiemTongKet, DiemHe4, DiemChu)
SELECT g.MaSV, g.MaLHP, g.cc, g.gk, g.ck, g.tongket,
       t.DiemHe4, t.DiemChu
FROM (
    SELECT b.MaSV, b.MaLHP, b.cc, b.gk, b.ck,
           ROUND(b.cc * 0.1 + b.gk * 0.3 + b.ck * 0.6, 1) AS tongket
    FROM (
        SELECT d.MaSV, d.MaLHP,
               ROUND(6.5 + (CAST(SUBSTRING(d.MaSV, 3, 3) AS UNSIGNED) % 30) * 0.1, 1) AS cc,
               ROUND(5.5 + (CAST(SUBSTRING(d.MaSV, 3, 3) AS UNSIGNED) % 35) * 0.1, 1) AS gk,
               ROUND(5.0 + (CAST(SUBSTRING(d.MaSV, 3, 3) AS UNSIGNED) % 40) * 0.1, 1) AS ck
        FROM DANGKYHOCPHAN d
        JOIN LOPHOCPHAN l ON l.MaLHP = d.MaLHP
        WHERE l.MaHocKy IN ('HK1-2023', 'HK2-2023', 'HK1-2024', 'HK2-2024')
          AND d.TrangThaiDangKy = 'DA_DANG_KY'
    ) b
) g
JOIN THANGDIEMCHU t ON g.tongket >= t.TuDiemHe10 AND g.tongket <= t.DenDiemHe10;

-- 3. TINH HUONG "KHONG DAT" (diem F) — demo rang buoc tien quyet
UPDATE KETQUAHOCTAP
SET DiemChuyenCan = 5.0, DiemGiuaKy = 3.0, DiemCuoiKy = 2.0,
    DiemTongKet = 2.9, DiemHe4 = 0.0, DiemChu = 'F'
WHERE (MaSV = 'SV060' AND MaLHP = 'LHP106')
   OR (MaSV = 'SV030' AND MaLHP = 'LHP104')
   OR (MaSV = 'SV041' AND MaLHP = 'LHP106');
