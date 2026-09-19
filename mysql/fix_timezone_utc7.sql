-- ==========================================================
-- fix_timezone_utc7.sql
-- Chuyển toàn bộ dữ liệu DATETIME từ UTC sang UTC+7
--
-- Cách chạy:
--   1. Đảm bảo backend đã restart với timezone: '+07:00' trong config
--   2. Chạy file này trên MySQL:
--      mysql -h [host] -u [user] -p [database] < mysql/fix_timezone_utc7.sql
--   3. Hoặc chạy script Node.js:
--      cd backend && node scripts/fix-timezone-utc7.js
--
-- Lưu ý: Chỉ cần chạy MỘT LẦN. Sau đó dữ liệu mới sẽ tự động dùng UTC+7.
-- ==========================================================

SET time_zone = '+07:00';

-- 1. DANGKYHOCPHAN — NgayDangKy (thời gian đăng ký học phần)
UPDATE DANGKYHOCPHAN
SET NgayDangKy = NgayDangKy + INTERVAL 7 HOUR;

-- 2. NHATKY_DOIMATKHAU — ThoiGianThayDoi (thời gian đổi mật khẩu)
UPDATE NHATKY_DOIMATKHAU
SET ThoiGianThayDoi = ThoiGianThayDoi + INTERVAL 7 HOUR;

-- 3. YEUCAU_DATLAI_MATKHAU — NgayGui (thời gian gửi yêu cầu)
UPDATE YEUCAU_DATLAI_MATKHAU
SET NgayGui = NgayGui + INTERVAL 7 HOUR;

-- 3b. YEUCAU_DATLAI_MATKHAU — NgayXuLy (thời gian xử lý, có thể NULL)
UPDATE YEUCAU_DATLAI_MATKHAU
SET NgayXuLy = NgayXuLy + INTERVAL 7 HOUR
WHERE NgayXuLy IS NOT NULL;

-- Kiểm tra kết quả
SELECT '=== KẾT QUẢ ===' AS ThongBao;
SELECT 'DANGKYHOCPHAN' AS Bang, COUNT(*) AS SoDong, MIN(NgayDangKy) AS MinNgay, MAX(NgayDangKy) AS MaxNgay FROM DANGKYHOCPHAN
UNION ALL
SELECT 'NHATKY_DOIMATKHAU', COUNT(*), MIN(ThoiGianThayDoi), MAX(ThoiGianThayDoi) FROM NHATKY_DOIMATKHAU
UNION ALL
SELECT 'YEUCAU_DATLAI_MATKHAU', COUNT(*), MIN(NgayGui), MAX(NgayGui) FROM YEUCAU_DATLAI_MATKHAU;
