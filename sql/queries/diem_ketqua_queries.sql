-- ==========================================================
-- Tên file : sql/queries/diem_ketqua_queries.sql
-- Module   : Module 4 — Điểm số & Kết quả học tập (TV4 — Wiett)
-- Issue    : #52 Truy vấn & View Điểm số & Kết quả học tập
-- Mô tả    : Tập hợp các câu lệnh SELECT phức tạp, View tổng hợp
--            bảng điểm cá nhân, xếp loại học lực, điểm max/min
--            và thống kê tỷ lệ Đạt/Không đạt từng môn học.
-- ==========================================================

USE [StudentCourseRegistration];
GO

-- ==========================================================
-- 1. VIEW BẢNG ĐIỂM CÁ NHÂN CHI TIẾT CỦA SINH VIÊN (V_BANGDIEM_SINHVIEN)
-- ==========================================================
IF OBJECT_ID(N'V_BANGDIEM_SINHVIEN', N'V') IS NOT NULL DROP VIEW V_BANGDIEM_SINHVIEN;
GO

CREATE VIEW V_BANGDIEM_SINHVIEN AS
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
GO

-- ==========================================================
-- 2. QUERY 1: XEM BẢNG ĐIỂM CÁ NHÂN THEO HỌC KỲ CỦA SINH VIÊN
-- (Ví dụ: Tra cứu bảng điểm của Sinh viên 'SV001' trong học kỳ 'HK1-2023')
-- ==========================================================
SELECT 
    MaSV,
    TenSinhVien,
    MaLHP,
    TenMonHoc,
    SoTinChi,
    DiemChuyenCan,
    DiemGiuaKy,
    DiemCuoiKy,
    DiemTongKet,
    DiemChu,
    DiemHe4,
    XepLoaiMonHoc
FROM V_BANGDIEM_SINHVIEN
WHERE MaSV = 'SV001' AND MaHocKy = 'HK1-2023'
ORDER BY TenMonHoc;
GO

-- ==========================================================
-- 3. QUERY 2: DANH SÁCH SINH VIÊN ĐẠT ĐIỂM CAO NHẤT / THẤP NHẤT MỖI LỚP HỌC PHẦN
-- (Sử dụng hàm xếp hạng RANK / DENSE_RANK)
-- ==========================================================
WITH RankedGrades AS (
    SELECT 
        lhp.MaLHP,
        lhp.TenLHP,
        mh.TenMonHoc,
        sv.MaSV,
        sv.HoTen,
        kq.DiemTongKet,
        kq.DiemChu,
        RANK() OVER (PARTITION BY lhp.MaLHP ORDER BY kq.DiemTongKet DESC) AS XepHangCao,
        RANK() OVER (PARTITION BY lhp.MaLHP ORDER BY kq.DiemTongKet ASC) AS XepHangThap
    FROM KETQUAHOCTAP kq
    JOIN SINHVIEN sv ON kq.MaSV = sv.MaSV
    JOIN LOPHOCPHAN lhp ON kq.MaLHP = lhp.MaLHP
    JOIN MONHOC mh ON lhp.MaMonHoc = mh.MaMonHoc
    WHERE kq.DiemTongKet IS NOT NULL
)
SELECT 
    MaLHP,
    TenLHP,
    TenMonHoc,
    MaSV,
    HoTen,
    DiemTongKet,
    DiemChu,
    CASE 
        WHEN XepHangCao = 1 THEN N'Thủ khoa LHP (Điểm cao nhất)'
        WHEN XepHangThap = 1 THEN N'Điểm thấp nhất LHP'
    END AS GhiChuXepHang
FROM RankedGrades
WHERE XepHangCao = 1 OR XepHangThap = 1
ORDER BY MaLHP, DiemTongKet DESC;
GO

-- ==========================================================
-- 4. VIEW & QUERY 3: THỐNG KÊ TỶ LỆ ĐẠT / KHÔNG ĐẠT (F) THEO LỚP HỌC PHẦN
-- (Sử dụng GROUP BY, HAVING, CASE WHEN)
-- ==========================================================
IF OBJECT_ID(N'V_THONGKE_KETQUA_MONHOC', N'V') IS NOT NULL DROP VIEW V_THONGKE_KETQUA_MONHOC;
GO

CREATE VIEW V_THONGKE_KETQUA_MONHOC AS
SELECT 
    lhp.MaLHP,
    lhp.TenLHP,
    mh.TenMonHoc,
    hk.TenHocKy,
    COUNT(kq.MaSV) AS TongSoSinhVien,
    SUM(CASE WHEN kq.DiemChu IS NOT NULL AND kq.DiemChu <> 'F' THEN 1 ELSE 0 END) AS SoSV_Dat,
    SUM(CASE WHEN kq.DiemChu = 'F' THEN 1 ELSE 0 END) AS SoSV_KiemTraF,
    SUM(CASE WHEN kq.DiemTongKet IS NULL THEN 1 ELSE 0 END) AS SoSV_ChuaCoDiem,
    CAST(ROUND(CAST(SUM(CASE WHEN kq.DiemChu IS NOT NULL AND kq.DiemChu <> 'F' THEN 1 ELSE 0 END) AS FLOAT) * 100.0 / NULLIF(COUNT(kq.MaSV), 0), 2) AS FLOAT) AS TyLeDat_Percent
FROM LOPHOCPHAN lhp
JOIN MONHOC mh ON lhp.MaMonHoc = mh.MaMonHoc
JOIN HOCKY hk ON lhp.MaHocKy = hk.MaHocKy
LEFT JOIN KETQUAHOCTAP kq ON lhp.MaLHP = kq.MaLHP
GROUP BY lhp.MaLHP, lhp.TenLHP, mh.TenMonHoc, hk.TenHocKy;
GO

-- Tra cứu thống kê các lớp học phần có sinh viên không đạt (F)
SELECT * 
FROM V_THONGKE_KETQUA_MONHOC
WHERE SoSV_KiemTraF > 0
ORDER BY SoSV_KiemTraF DESC;
GO

-- ==========================================================
-- 5. QUERY 4: PHÂN LẠI SINH VIÊN THEO MỨC XẾP LOẠI HỌC PHẦN DÙNG GROUP BY & HAVING
-- ==========================================================
SELECT 
    ISNULL(kq.DiemChu, N'Chưa có điểm') AS DiemChu,
    ISNULL(tdc.XepLoai, N'Chưa xếp loại') AS XepLoai,
    COUNT(*) AS SoLuongBietBao,
    CAST(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM KETQUAHOCTAP), 2) AS FLOAT) AS TyLePhanPercent
FROM KETQUAHOCTAP kq
LEFT JOIN THANGDIEMCHU tdc ON kq.DiemChu = tdc.DiemChu
GROUP BY kq.DiemChu, tdc.XepLoai
ORDER BY MIN(kq.DiemHe4) DESC;
GO

PRINT N'[OK] Issue #52 — Đã hoàn thành các Query và View cho Module 4.';
GO
