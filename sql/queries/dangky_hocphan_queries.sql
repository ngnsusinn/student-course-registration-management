-- ==========================================================
-- Tên file : sql/queries/dangky_hocphan_queries.sql
-- Module   : Đăng ký học phần (TV3 — Leader)
-- Issue    : #49 Truy vấn & View Đăng ký học phần
-- Mô tả    : ≥ 6 câu SELECT phức tạp + View:
--              Q1. SV đã đăng ký theo LHP (kèm sĩ số)
--              Q2. SV chưa đủ / vượt tín chỉ trong học kỳ
--              Q3. Kiểm tra tiên quyết bằng subquery/EXISTS
--              Q4. Thời khóa biểu cá nhân
--              Q5. Thống kê đăng ký theo học kỳ
--              Q6. SV đăng ký trùng lịch (anomaly detection)
--              Q7. Lớp sắp hết chỗ (sát sĩ số)
--              + 2 VIEW: VW_SinhVienDangKyChiTiet,
--                        VW_ThoiKhoaBieuCaNhan
-- ==========================================================

-- ==========================================================
-- Q1. SV ĐÃ ĐĂNG KÝ THEO LỚP HỌC PHẦN (kèm sĩ số hiện tại)
--     Hiển thị tên SV + LHP + học kỳ + trạng thái đăng ký.
-- ==========================================================
SELECT
    lhp.MaLHP,
    lhp.TenLHP,
    hk.MaHocKy,
    sv.MaSV,
    sv.HoTen,
    dk.NgayDangKy,
    dk.TrangThaiDangKy,
    lhp.SiSoHienTai AS N'Sĩ số hiện tại',
    lhp.SiSoToiDa    AS N'Sĩ số tối đa'
FROM DANGKYHOCPHAN dk
JOIN SINHVIEN      sv  ON sv.MaSV  = dk.MaSV
JOIN LOPHOCPHAN    lhp ON lhp.MaLHP = dk.MaLHP
JOIN HOCKY         hk  ON hk.MaHocKy = lhp.MaHocKy
WHERE dk.TrangThaiDangKy = N'DA_DANG_KY'
ORDER BY lhp.MaLHP, sv.MaSV;
GO

-- ==========================================================
-- Q2. SV CHƯA ĐỦ / VƯỢT TÍN CHỈ TRONG HỌC KỲ HIỆN TẠI
--     Ngưỡng quy chế: Min = 12 TC, Max = 24 TC.
--     Tính tổng tín chỉ của các LHP SV đã ĐK thành công.
-- ==========================================================
SELECT
    sv.MaSV,
    sv.HoTen,
    SUM(mh.SoTinChi) AS N'Tổng tín chỉ đã ĐK',
    CASE
        WHEN SUM(mh.SoTinChi) < 12 THEN N'CHƯA ĐỦ tín chỉ (thiếu ' +
            CAST(12 - SUM(mh.SoTinChi) AS VARCHAR(3)) + N' TC)'
        WHEN SUM(mh.SoTinChi) > 24 THEN N'VƯỢT tín chỉ (vượt ' +
            CAST(SUM(mh.SoTinChi) - 24 AS VARCHAR(3)) + N' TC)'
        ELSE N'Đạt yêu cầu'
    END AS N'Đánh giá'
FROM SINHVIEN sv
JOIN DANGKYHOCPHAN dk ON dk.MaSV = sv.MaSV AND dk.TrangThaiDangKy = N'DA_DANG_KY'
JOIN LOPHOCPHAN    lhp ON lhp.MaLHP = dk.MaLHP
JOIN MONHOC        mh  ON mh.MaMonHoc = lhp.MaMonHoc
WHERE lhp.MaHocKy = N'HK1-2025'
GROUP BY sv.MaSV, sv.HoTen
HAVING SUM(mh.SoTinChi) < 12 OR SUM(mh.SoTinChi) > 24
ORDER BY N'Tổng tín chỉ đã ĐK';
GO

-- ==========================================================
-- Q3. KIỂM TRA TIÊN QUYẾT BẰNG SUBQUERY / EXISTS
--     Những SV nào đăng ký LHP501 (HQT CSDL, HK1-2025) — họ có đủ
--     môn tiên quyết MH001->MH002->MH003->MH004 chưa?
--     (EXISTS = SV đã ĐẠT tất cả tiên quyết của MH005)
-- ==========================================================
SELECT
    sv.MaSV,
    sv.HoTen,
    N'LHP501 - HQT CSDL' AS N'LHP đăng ký',
    CASE
        WHEN NOT EXISTS (
            SELECT 1
            FROM MONHOC_TIENQUYET mtq
            WHERE mtq.MaMonHoc = N'MH005'           -- tiên quyết của HQT CSDL
              AND NOT EXISTS (
                    SELECT 1
                    FROM KETQUAHOCTAP kq
                    JOIN LOPHOCPHAN kqL ON kqL.MaLHP = kq.MaLHP
                    WHERE kq.MaSV = sv.MaSV
                      AND kqL.MaMonHoc = mtq.MaMonTienQuyet
                      AND kq.DiemChu <> N'F'          -- đã ĐẠT
              )
        ) THEN N'ĐỦ tiên quyết'
        ELSE N'THIẾU tiên quyết'
    END AS N'Kết quả kiểm tra'
FROM SINHVIEN sv
JOIN DANGKYHOCPHAN dk ON dk.MaSV = sv.MaSV
WHERE dk.MaLHP = N'LHP501'
  AND dk.TrangThaiDangKy = N'DA_DANG_KY'
ORDER BY sv.MaSV;
GO

-- ==========================================================
-- Q4. THỜI KHÓA BIỂU CÁ NHÂN (1 SV, học kỳ hiện tại)
--     Sắp theo Thứ + Tiết bắt đầu.
-- ==========================================================
DECLARE @MaSV_Check VARCHAR(12) = N'SV001';
SELECT
    sv.MaSV,
    sv.HoTen,
    lh.Thu,
    lh.TietBatDau,
    lh.SoTiet,
    N'Tiết ' + CAST(lh.TietBatDau AS VARCHAR(2)) + N'-' +
        CAST(lh.TietBatDau + lh.SoTiet - 1 AS VARCHAR(2)) AS N'Khung giờ',
    lhp.MaLHP,
    mh.TenMonHoc,
    lhp.TenLHP,
    ph.TenPhong,
    gv.HoTen AS N'Giảng viên'
FROM DANGKYHOCPHAN dk
JOIN SINHVIEN      sv  ON sv.MaSV = dk.MaSV
JOIN LOPHOCPHAN    lhp ON lhp.MaLHP = dk.MaLHP
JOIN MONHOC        mh  ON mh.MaMonHoc = lhp.MaMonHoc
JOIN LICHHOC       lh  ON lh.MaLHP = lhp.MaLHP
JOIN PHONGHOC      ph  ON ph.MaPhong = lh.MaPhong
LEFT JOIN GIANGVIEN gv ON gv.MaGV = lhp.MaGV
WHERE dk.MaSV = @MaSV_Check
  AND dk.TrangThaiDangKy = N'DA_DANG_KY'
  AND lhp.MaHocKy = N'HK1-2025'
ORDER BY lh.Thu, lh.TietBatDau;
GO

-- ==========================================================
-- Q5. THỐNG KÊ ĐĂNG KÝ THEO HỌC KỲ
--     Số SV đăng ký, số lớp, số bản ghi, tỷ lệ hủy.
-- ==========================================================
SELECT
    lhp.MaHocKy,
    COUNT(DISTINCT dk.MaSV)                          AS N'Số SV đã ĐK',
    COUNT(DISTINCT dk.MaLHP)                         AS N'Số LHP',
    COUNT(*)                                         AS N'Tổng bản ghi',
    SUM(CASE WHEN dk.TrangThaiDangKy = N'DA_HUY' THEN 1 ELSE 0 END) AS N'Đã hủy',
    CAST(
        100.0 * SUM(CASE WHEN dk.TrangThaiDangKy = N'DA_HUY' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0) AS DECIMAL(5,1)
    ) AS N'Tỷ lệ hủy (%)'
FROM DANGKYHOCPHAN dk
JOIN LOPHOCPHAN lhp ON lhp.MaLHP = dk.MaLHP
GROUP BY lhp.MaHocKy
ORDER BY lhp.MaHocKy;
GO

-- ==========================================================
-- Q6. PHÁT HIỆN SV ĐĂNG KÝ TRÙNG LỊCH (ANOMALY DETECTION)
--     Tìm các cặp LHP cùng Thứ + khung tiết GIAO NHAU trong cùng
--     học kỳ mà 1 SV đã ĐK thành công — nếu tồn tại là dữ liệu LỖI.
--     (SP_DangKyHocPhan đã chặn trùng lịch, truy vấn này để rà soát.)
--     Điều kiện trùng: max(TietBD1, TietBD2) <= min(TietKT1, TietKT2)
-- ==========================================================
SELECT DISTINCT
    dk.MaSV,
    sv.HoTen,
    lhp1.MaLHP AS N'LHP thứ 1',
    lhp2.MaLHP AS N'LHP thứ 2',
    lh1.Thu,
    N'Tiết ' + CAST(lh1.TietBatDau AS VARCHAR(2)) + N'-' +
        CAST(lh1.TietBatDau + lh1.SoTiet - 1 AS VARCHAR(2)) AS N'Khung 1',
    N'Tiết ' + CAST(lh2.TietBatDau AS VARCHAR(2)) + N'-' +
        CAST(lh2.TietBatDau + lh2.SoTiet - 1 AS VARCHAR(2)) AS N'Khung 2'
FROM DANGKYHOCPHAN dk
JOIN SINHVIEN sv   ON sv.MaSV = dk.MaSV
JOIN LOPHOCPHAN lhp1 ON lhp1.MaLHP = dk.MaLHP
JOIN LICHHOC lh1   ON lh1.MaLHP = lhp1.MaLHP
-- Chỉ xét 2 LHP KHÁC NHAU mà CÙNG SV đã đăng ký thành công
JOIN DANGKYHOCPHAN dk2 ON dk2.MaSV = dk.MaSV
                      AND dk2.TrangThaiDangKy = N'DA_DANG_KY'
                      AND dk2.MaLHP <> dk.MaLHP
JOIN LOPHOCPHAN lhp2 ON lhp2.MaLHP = dk2.MaLHP
JOIN LICHHOC lh2   ON lh2.MaLHP = lhp2.MaLHP
                   AND lh2.Thu = lh1.Thu
                   AND lh2.TietBatDau <= lh1.TietBatDau + lh1.SoTiet - 1
                   AND lh2.TietBatDau + lh2.SoTiet - 1 >= lh1.TietBatDau
WHERE dk.TrangThaiDangKy = N'DA_DANG_KY'
  AND lhp1.MaHocKy = N'HK1-2025'
  AND lhp2.MaHocKy = lhp1.MaHocKy
  AND lhp1.MaLHP < lhp2.MaLHP   -- tránh trùng cặp (A,B)/(B,A)
ORDER BY dk.MaSV;
GO

-- ==========================================================
-- Q7. LỚP SẮP HẾT CHỖ (SÁT SĨ SỐ) — phục vụ cảnh báo UI
-- ==========================================================
SELECT
    lhp.MaLHP,
    mh.TenMonHoc,
    lhp.SiSoHienTai,
    lhp.SiSoToiDa,
    lhp.SiSoToiDa - lhp.SiSoHienTai AS N'Còn trống',
    CASE
        WHEN lhp.SiSoToiDa - lhp.SiSoHienTai <= 1 THEN N'⚠️ SẮP ĐẦY'
        WHEN lhp.SiSoToiDa - lhp.SiSoHienTai <= 3 THEN N'⚠️ Còn ít'
        ELSE N'Còn nhiều'
    END AS N'Trạng thái chỗ'
FROM LOPHOCPHAN lhp
JOIN MONHOC mh ON mh.MaMonHoc = lhp.MaMonHoc
WHERE lhp.MaHocKy = N'HK1-2025'
ORDER BY lhp.SiSoToiDa - lhp.SiSoHienTai;
GO

-- ==========================================================
-- VIEW 1: VW_SinhVienDangKyChiTiet
--     Danh sách đăng ký chi tiết (SV - LHP - Môn - GV - học kỳ)
--     Dùng chung cho màn hình "Xem danh sách đăng ký".
-- ==========================================================
IF OBJECT_ID(N'VW_SinhVienDangKyChiTiet', N'V') IS NOT NULL DROP VIEW VW_SinhVienDangKyChiTiet;
GO
CREATE VIEW VW_SinhVienDangKyChiTiet AS
SELECT
    dk.MaSV,
    sv.HoTen       AS N'HoTenSV',
    sv.MaLopSH,
    dk.MaLHP,
    lhp.TenLHP,
    mh.TenMonHoc,
    mh.SoTinChi,
    lhp.MaHocKy,
    hk.TenHocKy,
    hk.NamHoc,
    lhp.MaGV,
    gv.HoTen       AS N'HoTenGV',
    dk.NgayDangKy,
    dk.TrangThaiDangKy,
    dk.GhiChu
FROM DANGKYHOCPHAN dk
JOIN SINHVIEN      sv  ON sv.MaSV  = dk.MaSV
JOIN LOPHOCPHAN    lhp ON lhp.MaLHP = dk.MaLHP
JOIN MONHOC        mh  ON mh.MaMonHoc = lhp.MaMonHoc
JOIN HOCKY         hk  ON hk.MaHocKy = lhp.MaHocKy
LEFT JOIN GIANGVIEN gv ON gv.MaGV = lhp.MaGV;
GO

-- ==========================================================
-- VIEW 2: VW_ThoiKhoaBieuCaNhan
--     TKB chi tiết theo từng SV — tiện cho màn hình TKB.
-- ==========================================================
IF OBJECT_ID(N'VW_ThoiKhoaBieuCaNhan', N'V') IS NOT NULL DROP VIEW VW_ThoiKhoaBieuCaNhan;
GO
CREATE VIEW VW_ThoiKhoaBieuCaNhan AS
SELECT
    dk.MaSV,
    sv.HoTen AS N'HoTenSV',
    lhp.MaHocKy,
    lh.Thu,
    lh.TietBatDau,
    lh.SoTiet,
    lhp.MaLHP,
    lhp.TenLHP,
    mh.TenMonHoc,
    ph.TenPhong,
    gv.HoTen AS N'HoTenGV'
FROM DANGKYHOCPHAN dk
JOIN SINHVIEN      sv  ON sv.MaSV = dk.MaSV
JOIN LOPHOCPHAN    lhp ON lhp.MaLHP = dk.MaLHP
JOIN MONHOC        mh  ON mh.MaMonHoc = lhp.MaMonHoc
JOIN LICHHOC       lh  ON lh.MaLHP = lhp.MaLHP
JOIN PHONGHOC      ph  ON ph.MaPhong = lh.MaPhong
LEFT JOIN GIANGVIEN gv ON gv.MaGV = lhp.MaGV
WHERE dk.TrangThaiDangKy = N'DA_DANG_KY';
GO

PRINT N'[OK] Issue #49 — Đã tạo 7 truy vấn + 2 View.';
GO
