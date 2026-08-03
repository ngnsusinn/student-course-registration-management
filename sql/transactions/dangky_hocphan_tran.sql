-- ==========================================================
-- Tên file : sql/transactions/dangky_hocphan_tran.sql
-- Module   : Đăng ký học phần (TV3 — Leader)
-- Issue    : #72 Transaction đăng ký học phần (Atomicity)
-- Mô tả    : Đóng gói toàn bộ SP_DangKyHocPhan trong Transaction
--            để "kiểm tra sĩ số" + "ghi nhận đăng ký" là NGUYÊN TỬ
--            — tránh Lost Update khi 2 SV cùng đăng ký chỗ cuối.
--            Script này:
--              1. Minh họa Transaction tường minh với UPDLOCK.
--              2. Demo Lost Update nếu KHÔNG dùng khóa (phiên bản
--                 có lỗi để so sánh).
--              3. Demo đúng cách: 1 chỗ trống, chỉ 1 SV thành công.
--              4. Demo rollback khi có lỗi giữa chừng.
--              5. Deadlock demo + cách phòng tránh.
--    Kịch bản 2 SESSION THẬT nằm ở sql/transactions/concurrency_test.sql
--    (Issue #74).
-- ==========================================================

-- ==========================================================
-- 0. BỐI CẢNH: LHP501 (HQT CSDL) = 24/25, CÒN ĐÚNG 1 CHỖ TRỐNG.
--    SV001, SV002 là 2 SV CÓ ĐỦ TIÊN QUYẾT nhưng CHƯA ĐK LHP501
--    (trong dữ liệu mẫu họ ĐK LHP505 thay thế) -> dùng để tranh
--    chỗ cuối. (Xem data/dangky_hocphan_data.sql)
-- ==========================================================

-- 0.1 RESET TRẠNG THÁI (để script chạy LẠI được nhiều lần)
--     Xóa bản ghi LHP501 của SV001/SV002 + đồng bộ sĩ số về 24.
IF EXISTS (SELECT 1 FROM DANGKYHOCPHAN WHERE MaSV IN (N'SV001', N'SV002') AND MaLHP = N'LHP501')
BEGIN
    DELETE FROM DANGKYHOCPHAN WHERE MaSV IN (N'SV001', N'SV002') AND MaLHP = N'LHP501';
    PRINT N'[reset] Đã xóa LHP501 của SV001/SV002 (chạy lại lần đầu sẽ bỏ qua).';
END

UPDATE LHP
SET SiSoHienTai = (
    SELECT COUNT(*) FROM DANGKYHOCPHAN d
    WHERE d.MaLHP = LHP.MaLHP AND d.TrangThaiDangKy = N'DA_DANG_KY'
)
FROM LOPHOCPHAN LHP WHERE MaLHP = N'LHP501';
GO

PRINT N'--- [Issue #72] Trạng thái LHP501 trước khi test ---';
SELECT MaLHP, SiSoHienTai, SiSoToiDa, SiSoToiDa - SiSoHienTai AS [Còn trống]
FROM LOPHOCPHAN WHERE MaLHP = N'LHP501';
GO

-- Kiểm tra SV001/SV002 chưa ĐK LHP501
PRINT N'--- Kiểm tra SV001/SV002 chưa ĐK LHP501 ---';
SELECT MaSV, MaLHP, TrangThaiDangKy
FROM DANGKYHOCPHAN
WHERE MaSV IN (N'SV001', N'SV002') AND MaLHP = N'LHP501';
GO

-- ==========================================================
-- 1. DEMO LOST UPDATE (CÁCH SAI — KHÔNG DÙNG LOCK)
--    Đây là code minh họa lỗi, KHÔNG chạy trong sản phẩm.
--    Nếu 2 phiên cùng đọc SiSoHienTai = 24 rồi cùng INSERT,
--    sĩ số thực tế sẽ bị vượt quá SiSoToiDa (25).
--    --> Kịch bản 2 session thật ở Issue #74 chứng minh điều này.
-- ==========================================================
PRINT N'';
PRINT N'--- [Issue #72] MINH HỌA LOST UPDATE (KHÔNG NÊN DÙNG) ---';
PRINT N'Phiên 1 & 2 cùng thực hiện:';
PRINT N'  SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = ''LHP501''  (không khóa)';
PRINT N'  Cả 2 đều đọc được 24 (< 25) -> cùng cho phép đăng ký.';
PRINT N'  Phiên 1: INSERT + UPDATE SiSoHienTai = 25';
PRINT N'  Phiên 2: INSERT + UPDATE SiSoHienTai = 25  (Ghi ĐÈ lên 25)';
PRINT N'Kết quả SAI: 26 SV trong khi SiSoToiDa = 25 (dữ liệu hỏng).';
PRINT N'Giải pháp: Transaction + UPDLOCK/HOLDLOCK (SP_DangKyHocPhan).';
GO

-- ==========================================================
-- 2. DEMO ĐÚNG CÁCH — GIAO DỊCH NGUYÊN TỬ + UPDLOCK
--    SV001 đăng ký LHP501: thành công (chỉ còn 1 chỗ nên thắng).
-- ==========================================================
PRINT N'';
PRINT N'--- [Issue #72] SV001 đăng ký LHP501 (chỗ cuối) ---';
DECLARE @rc INT;
EXEC dbo.SP_DangKyHocPhan
    @MaSV = N'SV001',
    @MaLHP = N'LHP501',
    @GhiChu = N'Đăng ký qua Transaction test',
    @KetQua = @rc OUTPUT;
SELECT @rc AS [MaKetQua];   -- Kỳ vọng 0 = thành công
GO

-- Kiểm tra sĩ số sau khi SV001 đăng ký -> phải là 25/25 (hết chỗ)
PRINT N'--- [Issue #72] Sau khi SV001 đăng ký, LHP501 = ? ---';
SELECT MaLHP, SiSoHienTai, SiSoToiDa, SiSoToiDa - SiSoHienTai AS [Còn trống]
FROM LOPHOCPHAN WHERE MaLHP = N'LHP501';
GO

-- ==========================================================
-- 3. DEMO CHẶN ĐĂNG KÝ KHI HẾT CHỖ
--    SV002 thử đăng ký -> phải BỊ CHẶN (mã 105 = lớp đầy).
--    Sĩ số KHÔNG vượt quá SiSoToiDa nhờ khóa dòng + kiểm tra
--    trước khi INSERT (Atomicity đảm bảo).
-- ==========================================================
PRINT N'--- [Issue #72] SV002 thử đăng ký LHP501 (đã đầy) ---';
DECLARE @rc2 INT;
EXEC dbo.SP_DangKyHocPhan
    @MaSV = N'SV002',
    @MaLHP = N'LHP501',
    @GhiChu = NULL,
    @KetQua = @rc2 OUTPUT;
SELECT @rc2 AS [MaKetQua];   -- Kỳ vọng 105 = lớp đầy
GO

-- Kiểm tra: SV002 KHÔNG có bản ghi, sĩ số vẫn 25
PRINT N'--- Kiểm tra SV002 không được ghi nhận ---';
SELECT COUNT(*) AS [So ban ghi SV002-LHP501]
FROM DANGKYHOCPHAN WHERE MaSV = N'SV002' AND MaLHP = N'LHP501';
SELECT MaLHP, SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP = N'LHP501';
GO

-- ==========================================================
-- 4. DEMO ROLLBACK KHI CÓ LỖI GIỮA CHỪNG
--    Nếu bất kỳ bước kiểm tra nào thất bại, toàn bộ Transaction
--    bị rollback: không có bản ghi DANGKYHOCPHAN, không có sự
--    thay đổi sĩ số nào.
-- ==========================================================
PRINT N'--- [Issue #72] Demo rollback: đăng ký thiếu tiên quyết ---';
DECLARE @rc3 INT;
-- SV060 (bảo lưu, F môn nền Cơ học) thử đăng ký LHP514 (Kết cấu cao tầng)
-- -> thiếu tiên quyết (LHP306 BTCT chưa đạt)
EXEC dbo.SP_DangKyHocPhan
    @MaSV = N'SV060',
    @MaLHP = N'LHP514',
    @GhiChu = N'Test rollback',
    @KetQua = @rc3 OUTPUT;
SELECT @rc3 AS [MaKetQua];   -- Kỳ vọng 102 (thiếu tiên quyết)

-- Kiểm tra rollback: không có bản ghi SV060-LHP514, sĩ số LHP514 không đổi
PRINT N'--- Kiểm tra rollback ---';
SELECT COUNT(*) AS [So ban ghi SV060-LHP514]
FROM DANGKYHOCPHAN WHERE MaSV = N'SV060' AND MaLHP = N'LHP514';
SELECT MaLHP, SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP = N'LHP514';
GO

-- ==========================================================
-- 5. DEADLOCK DEMO & CÁCH PHÒNG TRÁNH (Chương 5)
--    Tình huống:
--      Phiên A: khóa LHP501 rồi cần LHP502
--      Phiên B: khóa LHP502 rồi cần LHP501
--    -> deadlock. SQL Server tự chọn 1 phiên làm nạn nhân (rollback).
--    Script 2 session nằm ở concurrency_test.sql;
--    phân tích chi tiết ở docs/deadlock_analysis.md.
-- ==========================================================
PRINT N'--- [Issue #72] Deadlock: chạy concurrency_test.sql để demo 2 session ---';
PRINT N'Phòng tránh: luôn khóa các LHP theo THỨ TỰ CỐ ĐỊNH (VD: MaLHP tăng dần).';
GO

PRINT N'[OK] Issue #72 — Đã có Transaction đăng ký học phần nguyên tử + demo.';
GO
