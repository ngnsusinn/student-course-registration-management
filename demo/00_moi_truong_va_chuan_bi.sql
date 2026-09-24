-- ==========================================================
-- demo/00_moi_truong_va_chuan_bi.sql
-- CHẠY ĐẦU TIÊN — kiểm tra môi trường + chuẩn bị dữ liệu cho cả 4 kịch bản demo
--
-- 💡 CÁCH NHANH HƠN (khuyến nghị): mở web → menu “⚙ Chuẩn bị Demo”
--    (http://localhost:3000/chuan-bi-demo) → bấm [⚙ CHUẨN BỊ DEMO] là xong
--    mọi thứ (triển khai thủ tục cố ý có lỗi + dọn dữ liệu).
--    File này dành cho ai muốn KIỂM TRA MÔI TRƯỜNG và CHUẨN BỊ BẰNG TAY.
--    Xem: demo/07_CHUAN_BI_DEMO_1CLICK.md
--
-- Cách chạy: mở trình biên soạn DB (MySQL Workbench / HeidiSQL / DBeaver /
--            phpMyAdmin) → kết nối theo thông số ở mục 0.1 → dán & chạy file này.
-- ==========================================================

-- ----------------------------------------------------------
-- 0.1. THÔNG SỐ KẾT NGHIỆM (điền vào form kết nối của trình biên soạn DB)
-- ----------------------------------------------------------
--   Host      : 0.tcp.ap.ngrok.io
--   Port      : 21868
--   User      : admin
--   Password  : 01656229404aA@
--   Database  : roacqgfa_dbms
--   ⚠️ Tunnel ngrok (bản free) ĐỔI host:port mỗi lần khởi động lại tunnel.
--      Nếu không kết nối được: xem backend/.env (DB_HOST, DB_PORT) hoặc hỏi
--      người đang mở tunnel.

-- ----------------------------------------------------------
-- 0.2. KIỂM TRA MÔI TRƯỜNG
-- ----------------------------------------------------------
SELECT VERSION()                      AS PhienBanHQTCSDL,
       @@tx_isolation                 AS MucCoLapMacDinh,
       @@innodb_deadlock_detect       AS PhatHienDeadlock,
       @@innodb_lock_wait_timeout     AS ChoKhoaToiDa_Giay,
       @@autocommit                   AS Autocommit;
-- MONG ĐỢI: 11.8.9-MariaDB-ubu2404 | REPEATABLE-READ | 1 | 50 | 1

-- Đối tượng phục vụ demo đã nạp chưa?
SELECT ROUTINE_NAME
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = DATABASE()
  AND ROUTINE_NAME IN ('SP_ChuanBi_Demo_4Anomaly','SP_ChuanBi_Demo_Deadlock',
                       'SP_DangKyHocPhan','SP_DangKyHocPhan_ChuaFix','SP_DangKyHocPhan_NangCao',
                       'SP_Demo_KhoaTheoThuTu','SP_Demo_PhienGiaoDich','SP_Demo_DocHaiLan',
                       'SP_DangKyNhieuHocPhan')
ORDER BY ROUTINE_NAME;
-- MONG ĐỢI: đủ 9 dòng. Nếu thiếu, nạp lại bằng:
--   cd backend
--   node scripts/apply-sql.js ../mysql/transactions/demo_4_anomaly.sql
--   node scripts/apply-sql.js ../mysql/transactions/demo_deadlock.sql
--   node scripts/apply-sql.js ../mysql/procedures/SP_DangKyHocPhan.sql
--   node scripts/apply-sql.js ../mysql/procedures/SP_DangKyNhieuHocPhan.sql

-- ----------------------------------------------------------
-- 0.3. CHUẨN BỊ DỮ LIỆU — 2 lớp "demo"
-- ----------------------------------------------------------
--   LHP514 = môn Kết cấu cao tầng (MH045)  → dùng cho kịch bản SQL (15/16, còn 1 chỗ)
--   LHP506 = môn TA chuyên ngành (MH017)   → dùng cho kịch bản WEB  (0/1,  còn 1 chỗ)
--
--   ⚠️ Vì sao web phải dùng LHP506? SP_DangKyHocPhan kiểm tra MÔN TIÊN QUYẾT trước
--      bước kiểm tra sĩ số. LHP514 yêu cầu đạt MH033 — SV030 và SV041 đều CHƯA đạt
--      nên sẽ nhận mã 102, không bao giờ tới được bước sĩ số. LHP506 không có
--      tiên quyết nên đi được tới bước sĩ số và trả mã 105.

CALL SP_ChuanBi_Demo_4Anomaly('LHP514');    -- trả LHP514 về "còn đúng 1 chỗ"
CALL SP_ChuanBi_Demo_4Anomaly('LHP506');    -- trả LHP506 về "còn đúng 1 chỗ"

SELECT lhp.MaLHP,
       mh.TenMonHoc,
       lhp.SiSoHienTai,
       lhp.SiSoToiDa,
       (lhp.SiSoToiDa - lhp.SiSoHienTai) AS ConTrong,
       (SELECT COUNT(*) FROM DANGKYHOCPHAN d
         WHERE d.MaLHP = lhp.MaLHP AND d.TrangThaiDangKy = 'DA_DANG_KY') AS SoDK_ThucTe
FROM LOPHOCPHAN lhp
JOIN MONHOC mh ON mh.MaMonHoc = lhp.MaMonHoc
WHERE lhp.MaLHP IN ('LHP514','LHP506');
-- MONG ĐỢI:
--   LHP514 | Kết cấu cao tầng          | 15 | 16 | 1 | 15
--   LHP506 | Tiếng Anh chuyên ngành CNTT |  0 |  1 | 1 |  0

-- ----------------------------------------------------------
-- 0.4. KIỂM TRA 2 SINH VIÊN DEMO
-- ----------------------------------------------------------
SELECT sv.MaSV, sv.HoTen, tk.TenDangNhap, tk.TrangThai,
       FN_KiemTraTienQuyet(sv.MaSV,'MH017')  AS TienQuyet_LHP506,
       FN_KiemTraTrungLichHoc(sv.MaSV,'LHP506') AS TrungLich_LHP506,
       FN_TinhTongTinChi(sv.MaSV,'HK1-2025') AS TongTinChi_HK1_2025
FROM SINHVIEN sv
LEFT JOIN TAIKHOAN tk ON tk.MaSV = sv.MaSV
WHERE sv.MaSV IN ('SV030','SV041');
-- MONG ĐỢI: cả 2 đều TienQuyet_LHP506 = 1 và TrungLich_LHP506 = 0
--           (đủ điều kiện đăng ký LHP506) · mật khẩu web: matkhau@123

-- ----------------------------------------------------------
-- 0.5. MÃ LỖI CỦA THỦ TỤC ĐĂNG KÝ (để đọc kết quả)
-- ----------------------------------------------------------
--   0    = Thành công
--   100  = Ngoài thời hạn đợt đăng ký
--   101  = Đã đăng ký lớp này rồi
--   102  = Chưa hoàn thành môn tiên quyết
--   103  = Trùng lịch học
--   104  = Vượt số tín chỉ tối đa
--   105  = LỚP ĐÃ ĐẦY SĨ SỐ          ← mã cần thấy ở bản ĐÃ FIX
--   106  = Lớp không tồn tại / không mở đăng ký
--   1213 = DEADLOCK (ER_LOCK_DEADLOCK) — InnoDB tự chọn nạn nhân & rollback
--   1205 = Hết thời gian chờ khóa (ER_LOCK_WAIT_TIMEOUT)
