-- ==========================================================
-- Tên file : sql/data/00_diem_ketqua_data.sql
-- Module   : Điểm số & Kết quả học tập (TV4)
-- Mô tả    : THANGDIEMCHU + điểm cho SV đã đăng ký ở các học kỳ
--            HK1-2023..HK2-2024 (lịch sử để kiểm tra tiên quyết).
--            - Gần như toàn bộ SV ĐẠT môn tiên quyết (điểm >= 4.0).
--            - Một vài SV (SV060 bảo lưu, SV030/SV041) bị F một môn
--              để minh hoạ FN_KiemTraTienQuyet trả FALSE.
-- ==========================================================

-- ==========================================================
-- 1. THANGDIEMCHU (bảng tra cứu quy đổi — theo docs/analysis_diem_ketqua.md)
-- ==========================================================
INSERT INTO THANGDIEMCHU (DiemChu, TuDiemHe10, DenDiemHe10, DiemHe4, XepLoai) VALUES
(N'A',   8.5, 10.0, 4.0, N'Xuất sắc'),
(N'B+',  7.8,  8.4, 3.5, N'Khá giỏi'),
(N'B',   7.0,  7.7, 3.0, N'Khá'),
(N'C+',  6.5,  6.9, 2.5, N'Trung bình khá'),
(N'C',   5.5,  6.4, 2.0, N'Trung bình'),
(N'D+',  4.8,  5.4, 1.5, N'Trung bình yếu'),
(N'D',   4.0,  4.7, 1.0, N'Yếu'),
(N'F',   0.0,  3.9, 0.0, N'Kém');
GO

-- ==========================================================
-- 2. ĐIỂM CÁC HỌC KỲ HK1-2023..HK2-2024
--    Sinh điểm cho TẤT CẢ bản ghi DANGKYHOCPHAN thuộc các học kỳ
--    ĐÓNG (mọi LHP bắt đầu bằng LHP1xx, LHP2xx, LHP3xx, LHP4xx).
--    DiemTongKet = 0.1*CC + 0.3*GK + 0.6*CK, làm tròn 1 chữ số.
--    Điểm chữ quy đổi qua THANGDIEMCHU.
-- ==========================================================
;WITH Base AS (
    SELECT d.MaSV, d.MaLHP,
           -- điểm thành phần ngẫu nhiên có kiểm soát (theo mã SV)
           CAST(ROUND(6.5 + (CAST(SUBSTRING(d.MaSV, 3, 3) AS INT) % 30) * 0.1, 1) AS FLOAT) AS cc,
           CAST(ROUND(5.5 + (CAST(SUBSTRING(d.MaSV, 3, 3) AS INT) % 35) * 0.1, 1) AS FLOAT) AS gk,
           CAST(ROUND(5.0 + (CAST(SUBSTRING(d.MaSV, 3, 3) AS INT) % 40) * 0.1, 1) AS FLOAT) AS ck
    FROM DANGKYHOCPHAN d
    JOIN LOPHOCPHAN l ON l.MaLHP = d.MaLHP
    WHERE l.MaHocKy IN (N'HK1-2023', N'HK2-2023', N'HK1-2024', N'HK2-2024')
      AND d.TrangThaiDangKy = N'DA_DANG_KY'
),
Graded AS (
    SELECT b.MaSV, b.MaLHP,
           b.cc, b.gk, b.ck,
           -- điểm tổng kết hệ 10
           CAST(ROUND(b.cc*0.1 + b.gk*0.3 + b.ck*0.6, 1) AS FLOAT) AS tongket
    FROM Base b
)
INSERT INTO KETQUAHOCTAP (MaSV, MaLHP, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy, DiemTongKet, DiemHe4, DiemChu)
SELECT g.MaSV, g.MaLHP, g.cc, g.gk, g.ck, g.tongket,
       t.DiemHe4, t.DiemChu
FROM Graded g
JOIN THANGDIEMCHU t ON g.tongket >= t.TuDiemHe10 AND g.tongket <= t.DenDiemHe10;
GO

-- ==========================================================
-- 3. TÌNH HUỐNG "KHÔNG ĐẠT" (điểm F) — để demo ràng buộc tiên quyết
--    SV030 (QTKD), SV041 (XD), SV060 (XD, bảo lưu) bị rớt môn nền ở HK1-2023.
--    => Không đủ điều kiện đăng ký môn nối tiếp ở các học kỳ sau:
--      SV060: F LHP106 (Cơ học)  -> chưa đạt, không ĐK được LHP306 (BTCT)
--      SV030: F LHP104 (Kinh tế vi mô) -> chưa đạt
--      SV041: F LHP106 (Cơ học)  -> chưa đạt
-- ==========================================================
UPDATE KQ
SET DiemChuyenCan = 5.0, DiemGiuaKy = 3.0, DiemCuoiKy = 2.0,
    DiemTongKet = 2.9, DiemHe4 = 0.0, DiemChu = N'F'
FROM KETQUAHOCTAP KQ
WHERE (KQ.MaSV = N'SV060' AND KQ.MaLHP = N'LHP106')
   OR (KQ.MaSV = N'SV030' AND KQ.MaLHP = N'LHP104')
   OR (KQ.MaSV = N'SV041' AND KQ.MaLHP = N'LHP106');
GO

-- ==========================================================
-- 4. KIỂM TRA NHANH
-- ==========================================================
PRINT N'--- [Module 4] Số bản ghi điểm đã tạo ---';
SELECT COUNT(*) AS [Tổng bản ghi điểm] FROM KETQUAHOCTAP;
PRINT N'--- Phân bố điểm chữ ---';
SELECT DiemChu, COUNT(*) AS [Số bản ghi] FROM KETQUAHOCTAP GROUP BY DiemChu ORDER BY DiemChu;
GO
