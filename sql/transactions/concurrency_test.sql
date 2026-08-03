-- ==========================================================
-- Tên file : sql/transactions/concurrency_test.sql
-- Module   : Đăng ký học phần (TV3 — Leader)
-- Issue    : #74 Kịch bản test 2 session đồng thời
-- Mô tả    : KỊCH BẢN KIỂM THỬ 2 PHIÊN (SESSION) ĐĂNG KÝ ĐỒNG
--            THỜI VÀO LỚP HỌC PHẦN SẮP HẾT CHỖ.
--            Chứng minh hệ thống XỬ LÝ ĐÚNG (chỉ 1 SV thắng,
--            sĩ số không vượt SiSoToiDa, không Lost Update).
--
--  ⚠️ CÁCH CHẠY (2 CỬA SỔ SSMS):
--   1. Chạy PHẦN A "Chuẩn bị" trong cửa sổ số 1.
--   2. Chạy PHẦN B "Phiên 1" trong cửa sổ số 1.
--   3. CHUYỂN NGAY sang cửa sổ số 2, chạy PHẦN C "Phiên 2"
--      trong khi Phiên 1 ĐANG CHẠY (đang giữ khóa).
--   4. Quan sát: Phiên 2 BỊ CHẶN (chờ lock) cho tới khi Phiên 1
--      commit; sau đó Phiên 2 nhận mã lỗi 105 (lớp đầy).
--   5. Chạy PHẦN D "Kiểm tra" để xác nhận sĩ số = 25/25.
--
--  📸 Minh chứng: chụp ảnh màn hình 2 cửa sổ SSMS trước/sau khi
--     commit, lưu vào docs/concurrency_demo/ (xem README ở đó).
-- ==========================================================

-- ==========================================================
-- PHẦN A — CHUẨN BỊ (chạy 1 lần)
--   Đưa LHP501 về đúng trạng thái 24/25, đảm bảo SV001 & SV002
--   chưa đăng ký LHP501 và đủ điều kiện.
-- ==========================================================
PRINT N'=== [Issue #74] PHẦN A: Chuẩn bị trạng thái test ===';

-- Đảm bảo SV001, SV002 chưa ĐK LHP501
IF EXISTS (SELECT 1 FROM DANGKYHOCPHAN WHERE MaSV IN (N'SV001', N'SV002') AND MaLHP = N'LHP501')
BEGIN
    DELETE FROM DANGKYHOCPHAN WHERE MaSV IN (N'SV001', N'SV002') AND MaLHP = N'LHP501';
    PRINT N'Đã xóa bản ghi LHP501 của SV001/SV002 (nếu có).';
END

-- Đồng bộ sĩ số LHP501 = số ĐK hiệu lực
UPDATE LHP
SET SiSoHienTai = (
    SELECT COUNT(*) FROM DANGKYHOCPHAN d
    WHERE d.MaLHP = LHP.MaLHP AND d.TrangThaiDangKy = N'DA_DANG_KY'
)
FROM LOPHOCPHAN LHP WHERE MaLHP = N'LHP501';

-- Đảm bảo SiSoToiDa = 25
UPDATE LOPHOCPHAN SET SiSoToiDa = 25 WHERE MaLHP = N'LHP501';

PRINT N'Trạng thái LHP501 sau chuẩn bị:';
SELECT MaLHP, SiSoHienTai, SiSoToiDa, SiSoToiDa - SiSoHienTai AS [Còn trống]
FROM LOPHOCPHAN WHERE MaLHP = N'LHP501';
GO

-- ==========================================================
-- PHẦN B — PHIÊN 1 (SESSION 1) — chạy trong cửa sổ SSMS #1
--   SV001 đăng ký LHP501. Mở Transaction, giữ UPDLOCK dòng,
--   chờ 10 giây để "phóng to" cửa sổ khóa cho Phiên 2 thấy.
-- ==========================================================
PRINT N'=== [Issue #74] PHẦN B: Phiên 1 — SV001 đăng ký LHP501 ===';

BEGIN TRANSACTION;

SELECT MaLHP, SiSoHienTai, SiSoToiDa
FROM LOPHOCPHAN WITH (UPDLOCK, HOLDLOCK)
WHERE MaLHP = N'LHP501';

PRINT N'Phiên 1: Đã khóa dòng LHP501 (UPDLOCK). Giữ khóa 10 giây...';

-- Chờ 10 giây để bạn chuyển sang Phiên 2
WAITFOR DELAY '00:00:10';

-- Ghi nhận đăng ký
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
VALUES (N'SV001', N'LHP501', GETDATE(), N'DA_DANG_KY', N'Phiên 1 đăng ký chỗ cuối');
-- Trigger AFTER INSERT tự +1 SiSoHienTai

COMMIT TRANSACTION;
PRINT N'Phiên 1: COMMIT thành công — SV001 đã lấy chỗ cuối.';
GO

-- ==========================================================
-- PHẦN C — PHIÊN 2 (SESSION 2) — chạy trong cửa sổ SSMS #2
--   ⚡ CHẠY PHẦN NÀY TRONG KHI PHIÊN 1 ĐANG GIỮ KHÓA (10 giây)
--   SV002 cũng cố đăng ký LHP501. Phiên 2 sẽ BỊ CHẶN tới khi
--   Phiên 1 commit; sau đó nhận mã lỗi 105 (lớp đã đầy).
-- ==========================================================
PRINT N'=== [Issue #74] PHẦN C: Phiên 2 — SV002 cố đăng ký LHP501 ===';
PRINT N'(Bạn phải chạy PHẦN B và PHẦN C ở 2 cửa sổ SSMS khác nhau)';

DECLARE @rc INT;
EXEC dbo.SP_DangKyHocPhan
    @MaSV = N'SV002',
    @MaLHP = N'LHP501',
    @GhiChu = N'Phiên 2 cố lấy chỗ cuối',
    @KetQua = @rc OUTPUT;

PRINT N'Kết quả Phiên 2: mã = ' + CAST(@rc AS VARCHAR(10));
IF @rc = 105
    PRINT N'✅ ĐÚNG: Lớp đã đầy — Lost Update được ngăn chặn, SV002 bị từ chối.';
ELSE
    PRINT N'⚠️ Không như kỳ vọng (mã khác 105), kiểm tra lại trạng thái dữ liệu.';
GO

-- ==========================================================
-- PHẦN D — KIỂM TRA KẾT QUẢ (chạy sau khi cả 2 phiên xong)
--   Sĩ số LHP501 phải = 25 (không vượt SiSoToiDa).
--   SV001 có bản ghi, SV002 không có.
-- ==========================================================
PRINT N'=== [Issue #74] PHẦN D: Kiểm tra kết quả ===';

SELECT MaLHP, SiSoHienTai, SiSoToiDa,
       CASE WHEN SiSoHienTai <= SiSoToiDa THEN N'✅ Hợp lệ' ELSE N'❌ Vượt sĩ số!' END AS [Trạng thái]
FROM LOPHOCPHAN WHERE MaLHP = N'LHP501';

SELECT MaSV, MaLHP, TrangThaiDangKy, NgayDangKy
FROM DANGKYHOCPHAN
WHERE MaLHP = N'LHP501' AND MaSV IN (N'SV001', N'SV002')
ORDER BY MaSV;
GO

-- ==========================================================
-- PHẦN E (TÙY CHỌN) — DEMO LOST UPDATE NẾU KHÔNG DÙNG KHÓA
--   ⚠️ KHÔNG CHẠY TRONG SẢN PHẨM — chỉ minh họa lỗi.
--   Để chứng minh vì sao phải dùng Transaction + UPDLOCK:
--   (Không tự chạy kịch bản này ở đây; tham khảo mô tả dưới đây)
-- ==========================================================
PRINT N'=== [Issue #74] PHẦN E: Mô tả demo Lost Update (không dùng khóa) ===';
PRINT N'Bước 1: Tạm thời TẮT trigger + dùng 2 query thuần (không lock):';
PRINT N'  S1: SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP=''LHP501'';  -> 24';
PRINT N'  S2: SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP=''LHP501'';  -> 24';
PRINT N'Bước 2: S1 INSERT + UPDATE SiSoHienTai=25; S2 INSERT + UPDATE =25';
PRINT N'Kết quả: 26 SV / SiSoToiDa 25 (HỎNG DỮ LIỆU — Lost Update).';
PRINT N'Giải pháp đã áp dụng trong SP: UPDLOCK+HOLDLOCK.';
GO

-- ==========================================================
-- PHẦN F (TÙY CHỌN) — DEMO DEADLOCK + PHÒNG TRÁNH
--   Mở 2 cửa sổ SSMS, chạy 2 batch sau ĐỒNG THỜI:
--     Phiên 1: đăng ký LHP501 rồi LHP502
--     Phiên 2: đăng ký LHP502 rồi LHP501  (ngược thứ tự -> deadlock)
--   SQL Server chọn 1 nạn nhân (lỗi 1205), phiên kia thành công.
--   Xem chi tiết docs/deadlock_analysis.md.
-- ==========================================================
PRINT N'=== [Issue #74] PHẦN F: Deadlock demo (tham khảo deadlock_analysis.md) ===';

-- Phiên 1 (cửa sổ 1):
-- BEGIN TRAN;
--   SELECT ... FROM LOPHOCPHAN WITH (UPDLOCK,HOLDLOCK) WHERE MaLHP='LHP501';
--   WAITFOR DELAY '00:00:05';
--   SELECT ... FROM LOPHOCPHAN WITH (UPDLOCK,HOLDLOCK) WHERE MaLHP='LHP502';
-- COMMIT;
-- Phiên 2 (cửa sổ 2):
-- BEGIN TRAN;
--   SELECT ... FROM LOPHOCPHAN WITH (UPDLOCK,HOLDLOCK) WHERE MaLHP='LHP502';
--   WAITFOR DELAY '00:00:05';
--   SELECT ... FROM LOPHOCPHAN WITH (UPDLOCK,HOLDLOCK) WHERE MaLHP='LHP501';
-- COMMIT;
GO

PRINT N'[OK] Issue #74 — Kịch bản test 2 session đồng thời hoàn tất.';
GO
