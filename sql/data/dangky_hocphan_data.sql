-- ==========================================================
-- Tên file : sql/data/dangky_hocphan_data.sql
-- Module   : Đăng ký học phần (TV3 — Leader)
-- Issue    : #19 Dữ liệu mẫu Đăng ký học phần
-- Mô tả    : Sinh dữ liệu đăng ký cho 60 SV xuyên 5 học kỳ
--            (HK1-2023 → HK2-2023 → HK1-2024 → HK2-2024 → HK1-2025).
--            - Mỗi SV ĐK từ 2-4 LHP/học kỳ (đủ điều kiện ≥ 2 học kỳ).
--            - LỊCH SỬ TIÊN QUYẾT NHẤT QUÁN: SV chỉ ĐK môn ở HK sau
--              khi ĐẠT môn tiên quyết ở HK trước.
--            - SV030, SV041, SV060 bị điểm F môn nền → DỪNG ĐK từ
--              HK2-2023 (chứng minh FN_KiemTraTienQuyet = FALSE).
--            - TÌNH HUỐNG BIÊN:
--                (a) SÁT SĨ SỐ: LHP501 = 24/25 (còn 1 chỗ) — SV001,
--                    SV002 chưa ĐK để tranh chỗ cuối (Issue #74).
--                (b) SÁT HẠN: SV chẵn đăng ký 23h30 ngày 14/01/2027.
-- ==========================================================

-- ==========================================================
-- 1. ĐĂNG KÝ HỌC KỲ HK1-2023 (NỀN TẢNG — TOÀN BỘ 60 SV)
--      CNTT/KTMT: LHP101 (Nhập môn) + LHP102 (Giải tích) + LHP103 (Đại số)
--      QTKD/TCNH: LHP104 (Kinh tế vi mô) + LHP105 (Thống kê KT)
--      XD        : LHP106 (Cơ học) + LHP107 (Trắc địa)
-- ==========================================================
;WITH Nums AS (SELECT 1 AS n UNION ALL SELECT n+1 FROM Nums WHERE n < 60)
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
SELECT s.MaSV,
       CASE
           WHEN s.MaLopSH LIKE 'CNTT%' OR s.MaLopSH LIKE 'KTMT%' THEN
               CASE p WHEN 1 THEN N'LHP101' WHEN 2 THEN N'LHP102' ELSE N'LHP103' END
           WHEN s.MaLopSH LIKE 'QTKD%' OR s.MaLopSH LIKE 'TCNH%' THEN
               CASE p WHEN 1 THEN N'LHP104' ELSE N'LHP105' END
           ELSE
               CASE p WHEN 1 THEN N'LHP106' ELSE N'LHP107' END
       END,
       DATEADD(DAY, (n % 15) + 2, '2023-08-20') AS NgayDangKy,
       N'DA_DANG_KY',
       N'Đăng ký kỳ 1 - 2023'
FROM Nums n
CROSS APPLY (VALUES (1),(2),(3)) AS v(p)
JOIN (SELECT MaSV, MaLopSH, ROW_NUMBER() OVER (ORDER BY MaSV) rn FROM SINHVIEN) s ON s.rn = n.n
WHERE NOT (s.MaSV IN (N'SV030', N'SV041', N'SV060') AND p > 2)
  -- SV khối CNTT/KTMT đăng ký 3 môn; khối khác chỉ 2 môn (tránh trùng LHP)
  AND NOT ((s.MaLopSH NOT LIKE 'CNTT%' AND s.MaLopSH NOT LIKE 'KTMT%') AND p > 2);
GO

-- ==========================================================
-- 2. ĐĂNG KÝ HỌC KỲ HK2-2023
--      CNTT/KTMT: LHP201 (C/C++) + LHP202 (Toán rời rạc) + LHP203 (XSTK)
--      QTKD/TCNH: LHP204 (Kinh tế vĩ mô) + LHP205 (Quản trị học)
--      XD        : LHP207 (Sức bền) + LHP208 (Vật liệu XD)
--    (SV030, SV041, SV060 bị F môn nền → KHÔNG ĐK học kỳ này)
-- ==========================================================
;WITH Nums AS (SELECT 1 AS n UNION ALL SELECT n+1 FROM Nums WHERE n < 60)
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
SELECT s.MaSV,
       CASE
           WHEN s.MaLopSH LIKE 'CNTT%' OR s.MaLopSH LIKE 'KTMT%' THEN
               CASE p WHEN 1 THEN N'LHP201' WHEN 2 THEN N'LHP202' ELSE N'LHP203' END
           WHEN s.MaLopSH LIKE 'QTKD%' OR s.MaLopSH LIKE 'TCNH%' THEN
               CASE p WHEN 1 THEN N'LHP204' ELSE N'LHP205' END
           ELSE
               CASE p WHEN 1 THEN N'LHP207' ELSE N'LHP208' END
       END,
       DATEADD(DAY, (n % 15) + 2, '2024-02-01') AS NgayDangKy,
       N'DA_DANG_KY',
       N'Đăng ký kỳ 2 - 2023'
FROM Nums n
CROSS APPLY (VALUES (1),(2),(3)) AS v(p)
JOIN (SELECT MaSV, MaLopSH, ROW_NUMBER() OVER (ORDER BY MaSV) rn FROM SINHVIEN) s ON s.rn = n.n
WHERE s.MaSV NOT IN (N'SV030', N'SV041', N'SV060')
  -- SV khối CNTT/KTMT đăng ký 3 môn; khối khác chỉ 2 môn (tránh trùng LHP)
  AND NOT ((s.MaLopSH NOT LIKE 'CNTT%' AND s.MaLopSH NOT LIKE 'KTMT%') AND p > 2);
GO

-- ==========================================================
-- 3. ĐĂNG KÝ HỌC KỲ HK1-2024
--      CNTT/KTMT: LHP301 (CTDL&GT) + LHP302 (OOP) + LHP303 (Kiến trúc MT)
--      QTKD/TCNH: LHP304 (Nguyên lý kế toán) + LHP305 (Quản trị nhân lực)
--      XD        : LHP306 (BTCT) + LHP307 (Kết cấu thép)
-- ==========================================================
;WITH Nums AS (SELECT 1 AS n UNION ALL SELECT n+1 FROM Nums WHERE n < 60)
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
SELECT s.MaSV,
       CASE
           WHEN s.MaLopSH LIKE 'CNTT%' OR s.MaLopSH LIKE 'KTMT%' THEN
               CASE p WHEN 1 THEN N'LHP301' WHEN 2 THEN N'LHP302' ELSE N'LHP303' END
           WHEN s.MaLopSH LIKE 'QTKD%' OR s.MaLopSH LIKE 'TCNH%' THEN
               CASE p WHEN 1 THEN N'LHP304' ELSE N'LHP305' END
           ELSE
               CASE p WHEN 1 THEN N'LHP306' ELSE N'LHP307' END
       END,
       DATEADD(DAY, (n % 15) + 2, '2024-08-20') AS NgayDangKy,
       N'DA_DANG_KY',
       N'Đăng ký kỳ 1 - 2024'
FROM Nums n
CROSS APPLY (VALUES (1),(2),(3)) AS v(p)
JOIN (SELECT MaSV, MaLopSH, ROW_NUMBER() OVER (ORDER BY MaSV) rn FROM SINHVIEN) s ON s.rn = n.n
WHERE s.MaSV NOT IN (N'SV030', N'SV041', N'SV060')
  -- SV khối CNTT/KTMT đăng ký 3 môn; khối khác chỉ 2 môn (tránh trùng LHP)
  AND NOT ((s.MaLopSH NOT LIKE 'CNTT%' AND s.MaLopSH NOT LIKE 'KTMT%') AND p > 2);
GO

-- ==========================================================
-- 4. ĐĂNG KÝ HỌC KỲ HK2-2024
--      CNTT/KTMT: LHP401 (CSDL) + LHP402 (Web) + LHP403 (Mạng)
--      QTKD/TCNH: LHP404 (Tài chính DN) + LHP405 (Ngân hàng TM)
--      XD        : LHP406 (Nền móng) + LHP407 (Thủy lực)
-- ==========================================================
;WITH Nums AS (SELECT 1 AS n UNION ALL SELECT n+1 FROM Nums WHERE n < 60)
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
SELECT s.MaSV,
       CASE
           WHEN s.MaLopSH LIKE 'CNTT%' OR s.MaLopSH LIKE 'KTMT%' THEN
               CASE p WHEN 1 THEN N'LHP401' WHEN 2 THEN N'LHP402' ELSE N'LHP403' END
           WHEN s.MaLopSH LIKE 'QTKD%' OR s.MaLopSH LIKE 'TCNH%' THEN
               CASE p WHEN 1 THEN N'LHP404' ELSE N'LHP405' END
           ELSE
               CASE p WHEN 1 THEN N'LHP406' ELSE N'LHP407' END
       END,
       DATEADD(DAY, (n % 15) + 2, '2025-02-01') AS NgayDangKy,
       N'DA_DANG_KY',
       N'Đăng ký kỳ 2 - 2024'
FROM Nums n
CROSS APPLY (VALUES (1),(2),(3)) AS v(p)
JOIN (SELECT MaSV, MaLopSH, ROW_NUMBER() OVER (ORDER BY MaSV) rn FROM SINHVIEN) s ON s.rn = n.n
WHERE s.MaSV NOT IN (N'SV030', N'SV041', N'SV060')
  -- SV khối CNTT/KTMT đăng ký 3 môn; khối khác chỉ 2 môn (tránh trùng LHP)
  AND NOT ((s.MaLopSH NOT LIKE 'CNTT%' AND s.MaLopSH NOT LIKE 'KTMT%') AND p > 2);
GO

-- ==========================================================
-- 5. ĐĂNG KÝ HỌC KỲ HK1-2025 (HIỆN TẠI — ĐỢT ĐANG MỞ)
--    Mỗi SV ĐK 4 LHP (~12 tín chỉ), môn tiên quyết đã ĐẠT trước đó:
--      CNTT/KTMT: LHP501 (HQT CSDL) + LHP502 (CNPM) + LHP503 (PTTKHT)
--                 + LHP504 (AI)
--                 * SV001, SV002 KHÔNG ĐK LHP501 (chuyển sang LHP505
--                   An toàn TT) → LHP501 chỉ còn 1 chỗ trống (24/25).
--      QTKD/TCNH: LHP509 (Chứng khoán) + LHP510 (Kế toán quản trị)
--                 + LHP511 (Đầu tư TCQT) + LHP512 (Phân tích BCTC)
--      XD        : LHP513 (Quy hoạch) + LHP514 (Kết cấu cao tầng)
--                 + LHP515 (Thẩm định) + LHP516 (Công nghệ thi công)
--    SV030, SV041, SV060 (F môn nền) KHÔNG ĐK kỳ này.
--    TÌNH HUỐNG BIÊN (b): SV chẵn đăng ký 23h30 ngày 14/01/2027
--    (SÁT HẠN ĐÓNG ĐỢT 15/01/2027).
-- ==========================================================
;WITH Nums AS (SELECT 1 AS n UNION ALL SELECT n+1 FROM Nums WHERE n < 60)
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
SELECT s.MaSV,
       CASE
           WHEN s.MaLopSH LIKE 'CNTT%' OR s.MaLopSH LIKE 'KTMT%' THEN
               CASE
                   WHEN p = 1 AND s.MaSV IN (N'SV001', N'SV002') THEN N'LHP505'  -- thay HQT CSDL bằng ATTT
                   WHEN p = 1 THEN N'LHP501'
                   WHEN p = 2 THEN N'LHP502'
                   WHEN p = 3 THEN N'LHP503'
                   ELSE N'LHP504'
               END
           WHEN s.MaLopSH LIKE 'QTKD%' OR s.MaLopSH LIKE 'TCNH%' THEN
               CASE p WHEN 1 THEN N'LHP509' WHEN 2 THEN N'LHP510' WHEN 3 THEN N'LHP511' ELSE N'LHP512' END
           ELSE
               CASE p WHEN 1 THEN N'LHP513' WHEN 2 THEN N'LHP514' WHEN 3 THEN N'LHP515' ELSE N'LHP516' END
       END,
       CASE
           WHEN s.MaSV IN (N'SV001', N'SV002') THEN '2025-09-05 08:00:00'  -- SV tranh chỗ cuối
           WHEN (CAST(SUBSTRING(s.MaSV,3,3) AS INT) % 2) = 0 THEN '2027-01-14 23:30:00'  -- SÁT HẠN
           ELSE DATEADD(DAY, (n % 40) + 5, '2025-09-10')
       END AS NgayDangKy,
       N'DA_DANG_KY',
       CASE
           WHEN s.MaSV IN (N'SV001', N'SV002') THEN N'SV tranh chỗ cuối LHP501'
           WHEN (CAST(SUBSTRING(s.MaSV,3,3) AS INT) % 2) = 0 THEN N'Đăng ký sát hạn đợt HK1-2025'
           ELSE NULL
       END
FROM Nums n
CROSS APPLY (VALUES (1),(2),(3),(4)) AS v(p)
JOIN (SELECT MaSV, MaLopSH, ROW_NUMBER() OVER (ORDER BY MaSV) rn FROM SINHVIEN) s ON s.rn = n.n
WHERE s.MaSV NOT IN (N'SV030', N'SV041', N'SV060');
GO

-- ==========================================================
-- 6. ĐỒNG BỘ SiSoHienTai = số bản ghi ĐK ĐANG HIỆU LỰC
--    (Từ đây về sau, Trigger Issue #61 sẽ tự duy trì con số này.)
-- ==========================================================
UPDATE LHP
SET SiSoHienTai = (
    SELECT COUNT(*)
    FROM DANGKYHOCPHAN d
    WHERE d.MaLHP = LHP.MaLHP
      AND d.TrangThaiDangKy = N'DA_DANG_KY'
)
FROM LOPHOCPHAN LHP;
GO

-- ==========================================================
-- 7. KIỂM TRA NHANH DỮ LIỆU VỪA SINH
-- ==========================================================
PRINT N'--- [Issue #19] Tổng quan dữ liệu đăng ký ---';
SELECT
    (SELECT COUNT(*) FROM DANGKYHOCPHAN) AS [Tổng bản ghi ĐK],
    (SELECT COUNT(DISTINCT MaSV) FROM DANGKYHOCPHAN) AS [Số SV đã ĐK],
    (SELECT COUNT(DISTINCT MaLHP) FROM DANGKYHOCPHAN) AS [Số LHP có ĐK];

PRINT N'--- LOPHOCPHAN còn 1 chỗ trống (sát sĩ số) ---';
SELECT MaLHP, SiSoHienTai, SiSoToiDa, SiSoToiDa - SiSoHienTai AS [Còn trống]
FROM LOPHOCPHAN
WHERE SiSoHienTai = SiSoToiDa - 1;

PRINT N'--- SV đăng ký sát hạn (>= 14/01/2027) ---';
SELECT TOP 10 MaSV, MaLHP, NgayDangKy, GhiChu
FROM DANGKYHOCPHAN
WHERE NgayDangKy >= '2027-01-14'
ORDER BY NgayDangKy DESC;

PRINT N'--- SV001 / SV002 (tranh chỗ cuối LHP501) ---';
SELECT MaSV, MaLHP, NgayDangKy, GhiChu
FROM DANGKYHOCPHAN
WHERE MaSV IN (N'SV001', N'SV002') AND MaLHP IN (N'LHP501', N'LHP505');
GO
