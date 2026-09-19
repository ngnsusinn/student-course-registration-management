-- ==========================================================
-- Ten file : demo/sql_config/prepare__sp.sql
-- Muc dich : ⚠️ CÔNG CỤ DEMO — 2 stored procedure phục vụ trang
--            “Chuẩn bị Demo” (2 nút 1-click: CHUẨN BỊ và FIX).
--
--   SP_Prepare_Demo(pKichBan)     → ♻️ DỰNG LẠI TOÀN BỘ dữ liệu đăng ký của
--                                   HỌC KỲ HIỆN TẠI về trạng thái xuất phát,
--                                   rồi bày sẵn đúng dữ liệu cho kịch bản
--                                   demo được chọn (idempotent — bấm bao
--                                   nhiêu lần cũng ra cùng một kết quả).
--       pKichBan = 'DEMO'     (mặc định) : Lost Update + NRR/Phantom
--       pKichBan = 'DEADLOCK'           : thêm dòng DA_HUY cho SV030
--                                         phục vụ demo deadlock
--
--       ★ PHẦN A — REFRESH DỮ LIỆU (xoá sạch mọi dấu vết của lần demo trước):
--           A1. Mở lại đợt đăng ký HK1-2025 nếu đã bị đóng/hết hạn
--           A2. Trả SiSoToiDa của 5 lớp demo về đúng giá trị gốc trong seed
--           A3. Xoá TOÀN BỘ đăng ký của học kỳ hiện tại (mọi SV, mọi lớp)
--               — điểm của các lớp đó cascade theo (FK ON DELETE CASCADE)
--           A4. Sinh lại ĐÚNG bộ đăng ký chuẩn của học kỳ hiện tại
--               (cùng quy tắc với mysql/data/dangky_hocphan_data.sql §5)
--           A5. Tính lại SiSoHienTai cho MỌI lớp học phần
--           A6. Trả mật khẩu/trạng thái của các tài khoản demo về như seed
--         ★ PHẦN B — BÀY DỮ LIỆU CHO KỊCH BẢN ĐƯỢC CHỌN:
--           - Xoá đăng ký thử của tài khoản demo trên 5 lớp demo
--           - LHP514 và LHP506 về “còn đúng 1 chỗ”
--           - (kịch bản DEADLOCK) tạo 1 dòng DA_HUY cho SV030 ở LHP514
--
--   SP_Prepare_TrangThai()        → trả về 4 result set:
--       1. Cờ trạng thái 2 thủ tục nghiệp vụ (bản thật / bản có lỗi)
--       2. Trạng thái các lớp demo
--       3. Tài khoản demo có tồn tại & đang hoạt động không
--       4. Đợt đăng ký + độ “sạch” của dữ liệu học kỳ hiện tại
--          (để trang web biết đã SẴN SÀNG SỬ DỤNG hay chưa)
--
-- Cach ap dung (1 lan):
--     cd backend
--     node scripts/apply-sql.js ../demo/sql_config/prepare__sp.sql
-- ==========================================================

DROP PROCEDURE IF EXISTS SP_Prepare_TrangThai;
DROP PROCEDURE IF EXISTS SP_Prepare_Demo;

DELIMITER $$

-- ----------------------------------------------------------
-- 1) DỌN & CHUẨN BỊ DỮ LIỆU DEMO (refresh toàn bộ học kỳ hiện tại)
-- ----------------------------------------------------------
CREATE PROCEDURE SP_Prepare_Demo (IN pKichBan VARCHAR(20))
BEGIN
    DECLARE vKB VARCHAR(20);
    SET vKB = UPPER(IFNULL(pKichBan, 'DEMO'));

    -- ======================================================
    -- PHẦN A — DỰNG LẠI TOÀN BỘ DỮ LIỆU ĐĂNG KÝ CỦA HỌC KỲ HIỆN TẠI
    --   HK1-2025 là học kỳ đang mở đợt đăng ký (HOCKY.TrangThaiDot = 'MO')
    --   và là học kỳ duy nhất mà mọi kịch bản demo tác động tới.
    -- ======================================================

    -- A1) Mở lại đợt đăng ký nếu đã bị đóng / hết hạn.
    --     (Nếu đợt đóng, mọi cú bấm “Đăng ký” trên web trả mã 100 và
    --      không kịch bản nào chạy được ⇒ phải bảo đảm đợt luôn mở.)
    UPDATE HOCKY
    SET TrangThaiDot = 'MO',
        DenNgay = IF(DenNgay < CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 YEAR), DenNgay)
    WHERE MaHocKy = 'HK1-2025';

    -- A2) Trả SiSoToiDa của 5 lớp demo về giá trị gốc trong
    --     mysql/data/00_hocphan_giangvien_data.sql.
    --     (SP_ChuanBi_Demo_4Anomaly có sửa SiSoToiDa = SiSoHienTai + 1,
    --      nên phải khôi phục TRƯỚC khi dựng lại dữ liệu.)
    UPDATE LOPHOCPHAN SET SiSoToiDa = 40 WHERE MaLHP IN ('LHP505', 'LHP507', 'LHP514');
    UPDATE LOPHOCPHAN SET SiSoToiDa = 30 WHERE MaLHP = 'LHP506';
    UPDATE LOPHOCPHAN SET SiSoToiDa = 35 WHERE MaLHP = 'LHP508';

    -- A3) Xoá TOÀN BỘ đăng ký của học kỳ hiện tại — mọi sinh viên, mọi lớp.
    --     Đây là bước “refresh”: đăng ký thừa, dòng DA_HUY, dòng bóng ma…
    --     đều biến mất. KETQUAHOCTAP có FK ON DELETE CASCADE tới
    --     DANGKYHOCPHAN nên điểm vừa nhập khi demo cũng bị xoá theo.
    --     ⚠️ Phải qua BẢNG TẠM: nếu DELETE … JOIN LOPHOCPHAN thì trigger
    --        TRG_DANGKYHOCPHAN_AFTER_DELETE (có UPDATE LOPHOCPHAN) sẽ bị
    --        MariaDB chặn vì LOPHOCPHAN đang được câu lệnh gọi dùng (errno 1442).
    DROP TEMPORARY TABLE IF EXISTS tmp_lhp_hk;
    CREATE TEMPORARY TABLE tmp_lhp_hk (MaLHP VARCHAR(15) PRIMARY KEY);
    INSERT INTO tmp_lhp_hk (MaLHP)
        SELECT MaLHP FROM LOPHOCPHAN WHERE MaHocKy = 'HK1-2025';
    DELETE FROM DANGKYHOCPHAN WHERE MaLHP IN (SELECT MaLHP FROM tmp_lhp_hk);
    DROP TEMPORARY TABLE tmp_lhp_hk;

    -- A4) Sinh lại ĐÚNG bộ đăng ký chuẩn của học kỳ hiện tại.
    --     (Sao chép nguyên quy tắc ở mysql/data/dangky_hocphan_data.sql §5:
    --      SV001/SV002 học LHP505 thay cho LHP501; SV030/SV041/SV060
    --      không đăng ký học kỳ này.)
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

    -- A5) Tính lại SiSoHienTai cho MỌI lớp học phần.
    --     (3 trigger của DANGKYHOCPHAN có LEAST/GREATEST — đếm lại mới bảo
    --      đảm bộ đếm khớp đúng COUNT(*) hiệu lực, kể cả các học kỳ cũ.)
    UPDATE LOPHOCPHAN lhp
    SET lhp.SiSoHienTai = (
        SELECT COUNT(*) FROM DANGKYHOCPHAN d
        WHERE d.MaLHP = lhp.MaLHP AND d.TrangThaiDangKy = 'DA_DANG_KY');

    -- A6) Trả mật khẩu + trạng thái của các tài khoản dùng trong demo về như
    --     seed (mật khẩu chung: matkhau@123 — riêng admin: admin@123).
    --     Phòng khi lần demo trước có đổi mật khẩu / khoá tài khoản.
    --     (Cố ý KHÔNG đụng sv060 — tài khoản này LOCKED từ seed.)
    UPDATE TAIKHOAN
    SET MatKhau = SHA2('matkhau@123', 256), TrangThai = 'ACTIVE'
    WHERE TenDangNhap IN ('sv001', 'sv003', 'sv004', 'sv030', 'sv041', 'gv001');

    UPDATE TAIKHOAN
    SET MatKhau = SHA2('admin@123', 256), TrangThai = 'ACTIVE'
    WHERE TenDangNhap = 'admin';

    -- ======================================================
    -- PHẦN B — BÀY ĐÚNG DỮ LIỆU CHO KỊCH BẢN ĐƯỢC CHỌN
    -- ======================================================

    -- (B1) Xóa đăng ký thử của các TÀI KHOẢN DEMO trên các LỚP DEMO
    DELETE FROM DANGKYHOCPHAN
    WHERE MaSV IN ('SV001', 'SV003', 'SV004', 'SV030', 'SV041', 'SV060', 'SV999')
      AND MaLHP IN ('LHP505', 'LHP506', 'LHP507', 'LHP508', 'LHP514');

    -- (B2) Tính lại sĩ số THỰC TẾ cho 3 lớp dùng cho kịch bản NRR/Phantom
    UPDATE LOPHOCPHAN lhp
    SET lhp.SiSoHienTai = (
        SELECT COUNT(*) FROM DANGKYHOCPHAN d
        WHERE d.MaLHP = lhp.MaLHP AND d.TrangThaiDangKy = 'DA_DANG_KY')
    WHERE lhp.MaLHP IN ('LHP505', 'LHP507', 'LHP508');

    -- (B3) LHP514 và LHP506 về "còn đúng 1 chỗ" (đồng thời xóa dòng thử của SV030/SV041)
    CALL SP_ChuanBi_Demo_4Anomaly('LHP514');
    CALL SP_ChuanBi_Demo_4Anomaly('LHP506');

    -- (B4) Kịch bản DEADLOCK cần thêm 1 dòng DA_HUY cho SV030 ở LHP514
    IF vKB = 'DEADLOCK' THEN
        CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506');
    END IF;

    -- (B5) Tổng kết refresh — để trang web ghi vào nhật ký thao tác
    SELECT
      (SELECT IF(TrangThaiDot = 'MO' AND NOW() BETWEEN TuNgay AND DenNgay, 1, 0)
         FROM HOCKY WHERE MaHocKy = 'HK1-2025')                                       AS DotDangKy_Mo,
      (SELECT COUNT(*) FROM DANGKYHOCPHAN d
         JOIN LOPHOCPHAN l ON l.MaLHP = d.MaLHP
        WHERE l.MaHocKy = 'HK1-2025')                                                 AS SoDangKy,
      (SELECT COUNT(*) FROM LOPHOCPHAN l
        WHERE l.SiSoHienTai <> (SELECT COUNT(*) FROM DANGKYHOCPHAN d
                                 WHERE d.MaLHP = l.MaLHP AND d.TrangThaiDangKy = 'DA_DANG_KY'))
                                                                                      AS SoLopLechSiSo,
      (SELECT COUNT(*) FROM DANGKYHOCPHAN d
         JOIN LOPHOCPHAN l ON l.MaLHP = d.MaLHP
        WHERE l.MaHocKy = 'HK1-2025' AND d.TrangThaiDangKy = 'DA_DANG_KY'
          AND d.MaSV IN ('SV001', 'SV003', 'SV004', 'SV030', 'SV041', 'SV060', 'SV999')
          AND d.MaLHP IN ('LHP505', 'LHP506', 'LHP507', 'LHP508', 'LHP514'))          AS SoDauVetDemo,
      (SELECT COUNT(*) FROM DANGKYHOCPHAN d
         JOIN LOPHOCPHAN l ON l.MaLHP = d.MaLHP
        WHERE l.MaHocKy = 'HK1-2025' AND d.TrangThaiDangKy <> 'DA_DANG_KY')           AS SoDongKhongHieuLuc;

    -- (B6) Trạng thái sau khi chuẩn bị
    SELECT lhp.MaLHP, mh.TenMonHoc, lhp.SiSoHienTai, lhp.SiSoToiDa,
           (lhp.SiSoToiDa - lhp.SiSoHienTai) AS ConTrong,
           (SELECT COUNT(*) FROM DANGKYHOCPHAN d
             WHERE d.MaLHP = lhp.MaLHP AND d.TrangThaiDangKy = 'DA_DANG_KY') AS SoDK_ThucTe
    FROM LOPHOCPHAN lhp
    JOIN MONHOC mh ON mh.MaMonHoc = lhp.MaMonHoc
    WHERE lhp.MaLHP IN ('LHP505', 'LHP506', 'LHP507', 'LHP508', 'LHP514')
    ORDER BY lhp.MaLHP;
END$$

-- ----------------------------------------------------------
-- 2) TRẠNG THÁI HIỆN TẠI (để trang web hiển thị "đang ở bản nào"
--    + dữ liệu đã SẴN SÀNG SỬ DỤNG hay chưa)
-- ----------------------------------------------------------
CREATE PROCEDURE SP_Prepare_TrangThai ()
BEGIN
    -- (1) Hai thủ tục nghiệp vụ đang là bản nào?
    SELECT
      -- SP_DangKyHocPhan: có FOR UPDATE = bản thật; không = bản Lost Update
      (SELECT IF(ROUTINE_DEFINITION LIKE '%FOR UPDATE%', 1, 0)
         FROM information_schema.ROUTINES
        WHERE ROUTINE_SCHEMA = DATABASE() AND ROUTINE_NAME = 'SP_DangKyHocPhan')      AS DonKy_CoForUpdate,
      -- SP_DangKyNhieuHocPhan: có vSiSo1 = bản lab đọc 2 lần (NRR/Phantom)
      (SELECT IF(ROUTINE_DEFINITION LIKE '%vSiSo1%', 1, 0)
         FROM information_schema.ROUTINES
        WHERE ROUTINE_SCHEMA = DATABASE() AND ROUTINE_NAME = 'SP_DangKyNhieuHocPhan') AS Nhieu_DocHaiLan,
      -- SP_DangKyNhieuHocPhan: có LPAD(vThuTu = bản khóa theo thứ tự tick (Deadlock)
      (SELECT IF(ROUTINE_DEFINITION LIKE '%LPAD(vThuTu%', 1, 0)
         FROM information_schema.ROUTINES
        WHERE ROUTINE_SCHEMA = DATABASE() AND ROUTINE_NAME = 'SP_DangKyNhieuHocPhan') AS Nhieu_KhoaTheoThuTuChon,
      -- SP_DangKyNhieuHocPhan: có DO SLEEP = bản lab (có mở rộng cửa sổ)
      (SELECT IF(ROUTINE_DEFINITION LIKE '%DO SLEEP%', 1, 0)
         FROM information_schema.ROUTINES
        WHERE ROUTINE_SCHEMA = DATABASE() AND ROUTINE_NAME = 'SP_DangKyNhieuHocPhan') AS Nhieu_CoSleep,
      -- SP_DangKyHocPhan: nhãn proc_dirty_writer = bản lab "GHI mà KHÔNG commit" (kịch bản Dirty Read)
      (SELECT IF(ROUTINE_DEFINITION LIKE '%proc_dirty_writer%', 1, 0)
         FROM information_schema.ROUTINES
        WHERE ROUTINE_SCHEMA = DATABASE() AND ROUTINE_NAME = 'SP_DangKyHocPhan')      AS DonKy_LaWriterLab,
      -- SP_DangKyNhieuHocPhan: nhãn proc_dirty_read_ru = bản lab ĐỌC BẨN (@ READ UNCOMMITTED)
      (SELECT IF(ROUTINE_DEFINITION LIKE '%proc_dirty_read_ru%', 1, 0)
         FROM information_schema.ROUTINES
        WHERE ROUTINE_SCHEMA = DATABASE() AND ROUTINE_NAME = 'SP_DangKyNhieuHocPhan') AS Nhieu_LaDocBan,
      -- SP_DangKyNhieuHocPhan: nhãn proc_dirty_read_rr = bản lab ĐỐI CHỨNG (@ REPEATABLE READ)
      (SELECT IF(ROUTINE_DEFINITION LIKE '%proc_dirty_read_rr%', 1, 0)
         FROM information_schema.ROUTINES
        WHERE ROUTINE_SCHEMA = DATABASE() AND ROUTINE_NAME = 'SP_DangKyNhieuHocPhan') AS Nhieu_LaDocBanDaFix;

    -- (2) Trạng thái các lớp demo
    SELECT lhp.MaLHP, mh.TenMonHoc, lhp.SiSoHienTai, lhp.SiSoToiDa,
           (lhp.SiSoToiDa - lhp.SiSoHienTai) AS ConTrong,
           (SELECT COUNT(*) FROM DANGKYHOCPHAN d
             WHERE d.MaLHP = lhp.MaLHP AND d.TrangThaiDangKy = 'DA_DANG_KY') AS SoDK_ThucTe
    FROM LOPHOCPHAN lhp
    JOIN MONHOC mh ON mh.MaMonHoc = lhp.MaMonHoc
    WHERE lhp.MaLHP IN ('LHP505', 'LHP506', 'LHP507', 'LHP508', 'LHP514')
    ORDER BY lhp.MaLHP;

    -- (3) Tài khoản demo
    SELECT tk.TenDangNhap, tk.MaVaiTro, tk.TrangThai, tk.MaSV, tk.MaGV
    FROM TAIKHOAN tk
    WHERE tk.TenDangNhap IN ('sv001','sv003','sv004','sv030','sv041','gv001','admin')
    ORDER BY tk.TenDangNhap;

    -- (4) Đợt đăng ký + độ "sạch" của dữ liệu học kỳ hiện tại
    SELECT hk.MaHocKy, hk.TenHocKy, hk.TrangThaiDot, hk.TuNgay, hk.DenNgay,
           IF(hk.TrangThaiDot = 'MO' AND NOW() BETWEEN hk.TuNgay AND hk.DenNgay, 1, 0) AS DangMoDangKy,
           (SELECT COUNT(*) FROM DANGKYHOCPHAN d
              JOIN LOPHOCPHAN l ON l.MaLHP = d.MaLHP
             WHERE l.MaHocKy = hk.MaHocKy)                                            AS SoDangKy,
           (SELECT COUNT(*) FROM LOPHOCPHAN l
             WHERE l.SiSoHienTai <> (SELECT COUNT(*) FROM DANGKYHOCPHAN d
                                      WHERE d.MaLHP = l.MaLHP AND d.TrangThaiDangKy = 'DA_DANG_KY'))
                                                                                      AS SoLopLechSiSo,
           (SELECT COUNT(*) FROM DANGKYHOCPHAN d
              JOIN LOPHOCPHAN l ON l.MaLHP = d.MaLHP
             WHERE l.MaHocKy = hk.MaHocKy AND d.TrangThaiDangKy = 'DA_DANG_KY'
               AND d.MaSV IN ('SV001','SV003','SV004','SV030','SV041','SV060','SV999')
               AND d.MaLHP IN ('LHP505','LHP506','LHP507','LHP508','LHP514'))         AS SoDauVetDemo,
           (SELECT COUNT(*) FROM DANGKYHOCPHAN d
              JOIN LOPHOCPHAN l ON l.MaLHP = d.MaLHP
             WHERE l.MaHocKy = hk.MaHocKy AND d.TrangThaiDangKy <> 'DA_DANG_KY')      AS SoDongKhongHieuLuc,
           -- SAN SANG = đợt đang mở + không lớp nào lệch sĩ số + không còn
           -- đăng ký hiệu lực của tài khoản demo trên lớp demo
           IF(hk.TrangThaiDot = 'MO' AND NOW() BETWEEN hk.TuNgay AND hk.DenNgay
              AND (SELECT COUNT(*) FROM LOPHOCPHAN l
                    WHERE l.SiSoHienTai <> (SELECT COUNT(*) FROM DANGKYHOCPHAN d
                                             WHERE d.MaLHP = l.MaLHP AND d.TrangThaiDangKy = 'DA_DANG_KY')) = 0
              AND (SELECT COUNT(*) FROM DANGKYHOCPHAN d
                     JOIN LOPHOCPHAN l ON l.MaLHP = d.MaLHP
                    WHERE l.MaHocKy = hk.MaHocKy AND d.TrangThaiDangKy = 'DA_DANG_KY'
                      AND d.MaSV IN ('SV001','SV003','SV004','SV030','SV041','SV060','SV999')
                      AND d.MaLHP IN ('LHP505','LHP506','LHP507','LHP508','LHP514')) = 0
             , 1, 0)                                                                  AS SanSang
    FROM HOCKY hk
    WHERE hk.MaHocKy = 'HK1-2025';
END$$

DELIMITER ;

SELECT '[OK] Da tao SP_Prepare_Demo (refresh toan bo du lieu HK hien tai) + SP_Prepare_TrangThai (4 result set)' AS KetLuan;
