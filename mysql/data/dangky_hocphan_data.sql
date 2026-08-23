-- ==========================================================
-- Ten file : mysql/data/dangky_hocphan_data.sql
-- Module   : Dang ky hoc phan (TV3 — Leader)
-- Mo ta    : Sinh du lieu dang ky cho 60 SV xuyen 5 hoc ky.
--            Ban dich T-SQL (recursive CTE + CROSS APPLY) sang
--            MySQL 5.7: dung derived table CROSS JOIN va so thu
--            tu n suy truc tiep tu MaSV (SV001 -> 1, ... SV060 -> 60).
-- ==========================================================

-- ==========================================================
-- 1. HOC KY HK1-2023 (NEN TANG — TOAN BO 60 SV)
-- ==========================================================
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
SELECT s.MaSV,
       CASE
           WHEN s.MaLopSH LIKE 'CNTT%' OR s.MaLopSH LIKE 'KTMT%' THEN
               CASE v.p WHEN 1 THEN 'LHP101' WHEN 2 THEN 'LHP102' ELSE 'LHP103' END
           WHEN s.MaLopSH LIKE 'QTKD%' OR s.MaLopSH LIKE 'TCNH%' THEN
               CASE v.p WHEN 1 THEN 'LHP104' ELSE 'LHP105' END
           ELSE
               CASE v.p WHEN 1 THEN 'LHP106' ELSE 'LHP107' END
       END,
       DATE_ADD('2023-08-20', INTERVAL (s.n % 15) + 2 DAY),
       'DA_DANG_KY',
       'Đăng ký kỳ 1 - 2023'
FROM (SELECT MaSV, MaLopSH, CAST(SUBSTRING(MaSV, 3, 3) AS UNSIGNED) AS n FROM SINHVIEN) s
CROSS JOIN (SELECT 1 AS p UNION ALL SELECT 2 UNION ALL SELECT 3) v
WHERE NOT (s.MaSV IN ('SV030', 'SV041', 'SV060') AND v.p > 2)
  AND NOT ((s.MaLopSH NOT LIKE 'CNTT%' AND s.MaLopSH NOT LIKE 'KTMT%') AND v.p > 2);

-- ==========================================================
-- 2. HOC KY HK2-2023 (SV030, SV041, SV060 dung hoc -> khong DK)
-- ==========================================================
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
SELECT s.MaSV,
       CASE
           WHEN s.MaLopSH LIKE 'CNTT%' OR s.MaLopSH LIKE 'KTMT%' THEN
               CASE v.p WHEN 1 THEN 'LHP201' WHEN 2 THEN 'LHP202' ELSE 'LHP203' END
           WHEN s.MaLopSH LIKE 'QTKD%' OR s.MaLopSH LIKE 'TCNH%' THEN
               CASE v.p WHEN 1 THEN 'LHP204' ELSE 'LHP205' END
           ELSE
               CASE v.p WHEN 1 THEN 'LHP207' ELSE 'LHP208' END
       END,
       DATE_ADD('2024-02-01', INTERVAL (s.n % 15) + 2 DAY),
       'DA_DANG_KY',
       'Đăng ký kỳ 2 - 2023'
FROM (SELECT MaSV, MaLopSH, CAST(SUBSTRING(MaSV, 3, 3) AS UNSIGNED) AS n FROM SINHVIEN) s
CROSS JOIN (SELECT 1 AS p UNION ALL SELECT 2 UNION ALL SELECT 3) v
WHERE s.MaSV NOT IN ('SV030', 'SV041', 'SV060')
  AND NOT ((s.MaLopSH NOT LIKE 'CNTT%' AND s.MaLopSH NOT LIKE 'KTMT%') AND v.p > 2);

-- ==========================================================
-- 3. HOC KY HK1-2024
-- ==========================================================
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
SELECT s.MaSV,
       CASE
           WHEN s.MaLopSH LIKE 'CNTT%' OR s.MaLopSH LIKE 'KTMT%' THEN
               CASE v.p WHEN 1 THEN 'LHP301' WHEN 2 THEN 'LHP302' ELSE 'LHP303' END
           WHEN s.MaLopSH LIKE 'QTKD%' OR s.MaLopSH LIKE 'TCNH%' THEN
               CASE v.p WHEN 1 THEN 'LHP304' ELSE 'LHP305' END
           ELSE
               CASE v.p WHEN 1 THEN 'LHP306' ELSE 'LHP307' END
       END,
       DATE_ADD('2024-08-20', INTERVAL (s.n % 15) + 2 DAY),
       'DA_DANG_KY',
       'Đăng ký kỳ 1 - 2024'
FROM (SELECT MaSV, MaLopSH, CAST(SUBSTRING(MaSV, 3, 3) AS UNSIGNED) AS n FROM SINHVIEN) s
CROSS JOIN (SELECT 1 AS p UNION ALL SELECT 2 UNION ALL SELECT 3) v
WHERE s.MaSV NOT IN ('SV030', 'SV041', 'SV060')
  AND NOT ((s.MaLopSH NOT LIKE 'CNTT%' AND s.MaLopSH NOT LIKE 'KTMT%') AND v.p > 2);

-- ==========================================================
-- 4. HOC KY HK2-2024
-- ==========================================================
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
SELECT s.MaSV,
       CASE
           WHEN s.MaLopSH LIKE 'CNTT%' OR s.MaLopSH LIKE 'KTMT%' THEN
               CASE v.p WHEN 1 THEN 'LHP401' WHEN 2 THEN 'LHP402' ELSE 'LHP403' END
           WHEN s.MaLopSH LIKE 'QTKD%' OR s.MaLopSH LIKE 'TCNH%' THEN
               CASE v.p WHEN 1 THEN 'LHP404' ELSE 'LHP405' END
           ELSE
               CASE v.p WHEN 1 THEN 'LHP406' ELSE 'LHP407' END
       END,
       DATE_ADD('2025-02-01', INTERVAL (s.n % 15) + 2 DAY),
       'DA_DANG_KY',
       'Đăng ký kỳ 2 - 2024'
FROM (SELECT MaSV, MaLopSH, CAST(SUBSTRING(MaSV, 3, 3) AS UNSIGNED) AS n FROM SINHVIEN) s
CROSS JOIN (SELECT 1 AS p UNION ALL SELECT 2 UNION ALL SELECT 3) v
WHERE s.MaSV NOT IN ('SV030', 'SV041', 'SV060')
  AND NOT ((s.MaLopSH NOT LIKE 'CNTT%' AND s.MaLopSH NOT LIKE 'KTMT%') AND v.p > 2);

-- ==========================================================
-- 5. HOC KY HK1-2025 (HIEN TAI — DOT DANG MO)
--    SV001/SV002 khong DK LHP501 (chuyen sang LHP505) de tao
--    tinh huong sat si so 24/25.
-- ==========================================================
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
SELECT s.MaSV,
       CASE
           WHEN s.MaLopSH LIKE 'CNTT%' OR s.MaLopSH LIKE 'KTMT%' THEN
               CASE
                   WHEN v.p = 1 AND s.MaSV IN ('SV001', 'SV002') THEN 'LHP505'
                   WHEN v.p = 1 THEN 'LHP501'
                   WHEN v.p = 2 THEN 'LHP502'
                   WHEN v.p = 3 THEN 'LHP503'
                   ELSE 'LHP504'
               END
           WHEN s.MaLopSH LIKE 'QTKD%' OR s.MaLopSH LIKE 'TCNH%' THEN
               CASE v.p WHEN 1 THEN 'LHP509' WHEN 2 THEN 'LHP510' WHEN 3 THEN 'LHP511' ELSE 'LHP512' END
           ELSE
               CASE v.p WHEN 1 THEN 'LHP513' WHEN 2 THEN 'LHP514' WHEN 3 THEN 'LHP515' ELSE 'LHP516' END
       END,
       CASE
           WHEN s.MaSV IN ('SV001', 'SV002') THEN '2025-09-05 08:00:00'
           WHEN (s.n % 2) = 0 THEN '2027-01-14 23:30:00'
           ELSE DATE_ADD('2025-09-10', INTERVAL (s.n % 40) + 5 DAY)
       END,
       'DA_DANG_KY',
       CASE
           WHEN s.MaSV IN ('SV001', 'SV002') THEN 'SV tranh cho cuoi LHP501'
           WHEN (s.n % 2) = 0 THEN 'Đăng ký sát hạn đợt HK1-2025'
           ELSE NULL
       END
FROM (SELECT MaSV, MaLopSH, CAST(SUBSTRING(MaSV, 3, 3) AS UNSIGNED) AS n FROM SINHVIEN) s
CROSS JOIN (SELECT 1 AS p UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4) v
WHERE s.MaSV NOT IN ('SV030', 'SV041', 'SV060');

-- ==========================================================
-- 6. DONG BO SiSoHienTai = so ban ghi DK DANG HIEU LUC
-- ==========================================================
UPDATE LOPHOCPHAN LHP
SET SiSoHienTai = (
    SELECT COUNT(*)
    FROM DANGKYHOCPHAN d
    WHERE d.MaLHP = LHP.MaLHP
      AND d.TrangThaiDangKy = 'DA_DANG_KY'
);
