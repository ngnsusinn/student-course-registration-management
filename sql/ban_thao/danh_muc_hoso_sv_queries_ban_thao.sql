-- SELECT 1: SV THEO KHOA/NGÀNH/LỚP + SĨ SỐ TỪNG LỚP
SELECT 
    K.TenKhoa,
    N.TenNganh,
    L.TenLop,
    SV.MaSV,
    SV.HoTen,
    SV.NgaySinh,
    Phai = CASE SV.GioiTinh 
        WHEN 1 THEN N'Nam' 
        ELSE N'Nữ' 
    END,
    SV.Email,
    (SELECT COUNT(*) FROM SINH_VIEN WHERE MaLop = L.MaLop) AS SiSoLop
FROM SINH_VIEN SV
JOIN LOP L ON SV.MaLop = L.MaLop
JOIN NGANH N ON L.MaNganh = N.MaNganh
JOIN KHOA K ON N.MaKhoa = K.MaKhoa
ORDER BY K.TenKhoa, N.TenNganh, L.TenLop, SV.MaSV;
GO
-- SELECT 2: THỐNG KÊ SĨ SỐ THỰC TẾ THEO LỚP, NGÀNH VÀ KHOA
SELECT 
    K.MaKhoa,
    K.TenKhoa,
    N.MaNganh,
    N.TenNganh,
    L.MaLop,
    L.TenLop,
    COUNT(SV.MaSV) AS SiSoThucTe
FROM LOP L
JOIN NGANH N ON L.MaNganh = N.MaNganh
JOIN KHOA K ON N.MaKhoa = K.MaKhoa
LEFT JOIN SINH_VIEN SV ON L.MaLop = SV.MaLop
GROUP BY K.MaKhoa, K.TenKhoa, N.MaNganh, N.TenNganh, L.MaLop, L.TenLop
ORDER BY K.TenKhoa, N.TenNganh, L.TenLop;
GO
-- SELECT 3: TRA CỨU SINH VIÊN CHƯA XẾP LỚP
IF EXISTS(SELECT * FROM SINH_VIEN WHERE MaLop IS NULL OR MaLop NOT IN (SELECT MaLop FROM LOP))
BEGIN
    SELECT 
        SV.MaSV,
        SV.HoTen,
        SV.NgaySinh,
        CASE SV.GioiTinh WHEN 1 THEN N'Nam' ELSE N'Nữ' END AS GioiTinhText,
        SV.Email,
        SV.SoDienThoai,
        N'Chưa xếp lớp' AS TrangThaiXepLop
    FROM SINH_VIEN SV
    WHERE SV.MaLop IS NULL OR SV.MaLop NOT IN (SELECT MaLop FROM LOP);
END
ELSE
BEGIN
    PRINT N'Không có sinh viên chưa xếp lớp';
END
GO
-- SELECT 4: TRA CỨU CHƯƠNG TRÌNH ĐÀO TẠO THEO MÃ NGÀNH
DECLARE @MaNganhTraCuu CHAR(10);
SET @MaNganhTraCuu = 'AUT'; -- Đổi mã ngành cần tra cứu tại đây

SELECT 
    CTDT.MaCTDT,
    CTDT.TenCTDT,
    N.TenNganh,
    HK.TenHocKy,
    MH.MaMH,
    MH.TenMon,
    MH.SoTinChi
FROM CHUONGTRINHDAOTAO CTDT
JOIN NGANH N ON CTDT.MaNganh = N.MaNganh
JOIN CHI_TIET_CTDT CT ON CTDT.MaCTDT = CT.MaCTDT
JOIN MON_HOC MH ON CT.MaMH = MH.MaMH
JOIN HOC_KY HK ON CT.MaHocKy = HK.MaHocKy
WHERE N.MaNganh = @MaNganhTraCuu
ORDER BY HK.MaHocKy, MH.MaMH;
GO
-- SELECT 5: THỐNG KÊ PHÂN LOẠI TRẠNG THÁI SINH VIÊN THEO KHOA
SELECT 
    K.MaKhoa,
    K.TenKhoa,
    COUNT(SV.MaSV) AS TongSoSV,
    COUNT(CASE WHEN SV.TrangThaiHoc = 1 THEN 1 END) AS SoSV_DangHoc,
    COUNT(CASE WHEN SV.TrangThaiHoc = 2 THEN 1 END) AS SoSV_BaoLuu,
    COUNT(CASE WHEN SV.TrangThaiHoc = 3 THEN 1 END) AS SoSV_ThoiHoc
FROM KHOA K
JOIN NGANH N ON K.MaKhoa = N.MaKhoa
JOIN LOP L ON N.MaNganh = L.MaNganh
LEFT JOIN SINH_VIEN SV ON L.MaLop = SV.MaLop
GROUP BY K.MaKhoa, K.TenKhoa
ORDER BY K.TenKhoa;
GO
-- 1 VIEW: XEM DANH SÁCH SINH VIÊN ĐANG HỌC
IF OBJECT_ID('vw_DanhSachSinhVienDangHoc', 'V') IS NOT NULL
    DROP VIEW vw_DanhSachSinhVienDangHoc;
GO

CREATE VIEW vw_DanhSachSinhVienDangHoc AS
SELECT 
    SV.MaSV,
    SV.HoTen,
    SV.NgaySinh,
    CASE SV.GioiTinh WHEN 1 THEN N'Nam' ELSE N'Nữ' END AS GioiTinh,
    SV.Email,
    SV.SoDienThoai,
    L.TenLop,
    N.TenNganh,
    K.TenKhoa,
    N'Đang học' AS TrangThaiHocText
FROM SINH_VIEN SV
JOIN LOP L ON SV.MaLop = L.MaLop
JOIN NGANH N ON L.MaNganh = N.MaNganh
JOIN KHOA K ON N.MaKhoa = K.MaKhoa
WHERE SV.TrangThaiHoc = 1;
GO