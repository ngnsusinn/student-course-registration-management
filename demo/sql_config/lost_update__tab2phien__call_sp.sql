-- ==========================================================
-- Ten file : demo/sql_config/lost_update__tab2phien__call_sp.sql
-- Muc dich : KỊCH BẢN 2 TAB — ĐỔI TỪ "GÕ TAY TRANSACTION" SANG "GỌI THỦ TỤC"
--            (đúng như hệ thống thật: mọi thao tác đăng ký đều đi qua SP)
--
--   ❌ Cách cũ (không dùng nữa):
--         START TRANSACTION;
--         SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP='LHP506';
--         INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
--         VALUES ('SV030','LHP506',NOW(),'DA_DANG_KY','Phien A - chua fix');
--         COMMIT;
--      => Người demo phải tự nhớ thứ tự START TRANSACTION / INSERT / COMMIT,
--         dễ gõ sai và KHÔNG phải là đường đi thật của ứng dụng.
--
--   ✅ Cách mới (dùng file này): gọi đúng thủ tục nghiệp vụ, cả giao tác
--      (START TRANSACTION … kiểm tra 5 bước … INSERT … COMMIT) nằm BÊN TRONG SP.
--
-- ==========================================================
-- BỐI CẢNH: LHP506 (Tiếng Anh chuyên ngành CNTT — MH017) đang 0/1, còn đúng
--           1 chỗ; SV030 và SV041 đều đủ điều kiện (không tiên quyết, không
--           trùng lịch) ⇒ cả hai cùng nhắm suất cuối cùng.
--
-- ★ VÌ SAO PHẢI CHỌN LHP506 MÀ KHÔNG PHẢI LHP514?
--     SP_DangKyHocPhan kiểm tra MÔN TIÊN QUYẾT *trước* bước kiểm tra sĩ số.
--     LHP514 (MH045) yêu cầu đạt MH033 — SV030/SV041 đều chưa đạt ⇒ nhận mã
--     102, không bao giờ tới được bước sĩ số. LHP506 không có tiên quyết.
--     (Nếu vẫn muốn demo trên LHP514 thì phải gõ tay INSERT như bản cũ.)
-- ==========================================================


-- ==========================================================
-- BƯỚC 0 — CHUẨN BỊ (chạy ở TAB 1 hoặc tab bất kỳ)
-- ==========================================================
CALL SP_ChuanBi_Demo_4Anomaly('LHP506');   -- dọn SV030/SV041 khỏi LHP506, đưa về "còn 1 chỗ"

SELECT MaLHP, SiSoHienTai, SiSoToiDa, (SiSoToiDa - SiSoHienTai) AS ConTrong
FROM LOPHOCPHAN WHERE MaLHP = 'LHP506';
-- MONG ĐỢI: LHP506 | 0 | 1 | 1


-- ==========================================================
-- BƯỚC 1 — TAB 1 — phiên của SV030  (chạy TRƯỚC)
-- ==========================================================
-- ⚠️ Chạy câu này rồi CHUYỂN NGAY sang TAB 2 (trong vòng ~8 giây).
--    Thủ tục tự mở giao tác, tự INSERT, rồi tự DO SLEEP(8) TRƯỚC KHI COMMIT
--    ⇒ trong 8 giây đó nó vẫn đang giữ khóa dòng sĩ số của LHP506.
CALL SP_DangKyHocPhan('SV030', 'LHP506', 24, 'Phien A - chua fix', @kqA);
SELECT @kqA AS KetQua_Tab1;      -- MONG ĐỢI: 0 (đăng ký thành công — lấy suất cuối)


-- ==========================================================
-- BƯỚC 2 — TAB 2 — phiên của SV041  (chạy SAU, vẫn trong lúc TAB 1 ngủ)
-- ==========================================================
-- TAB 2 sẽ TREO ở câu CALL (đang chờ khóa của TAB 1) ⇒ 📸 CHỤP ẢNH NGAY LÚC NÀY.
-- Khi TAB 1 COMMIT, TAB 2 mới chạy tiếp — và vì bản SP hiện hành THIẾU
-- "SELECT … FOR UPDATE", nó vẫn đọc snapshot CŨ "còn 1 chỗ" ⇒ đăng ký được.
CALL SP_DangKyHocPhan('SV041', 'LHP506', 24, 'Phien B - chua fix', @kqB);
SELECT @kqB AS KetQua_Tab2;      -- ❌ MONG ĐỢI (bản chưa fix): 0  → CẢ HAI ĐỀU THÀNH CÔNG = LỖI


-- ==========================================================
-- BƯỚC 3 — KIỂM TRA HẬU QUẢ (bằng chứng vượt sĩ số) 📸
-- ==========================================================
SELECT COUNT(*) AS SoDK_ThucTe,
       (SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = 'LHP506') AS BoDem_SiSo,
       (SELECT SiSoToiDa   FROM LOPHOCPHAN WHERE MaLHP = 'LHP506') AS SiSoToiDa
FROM DANGKYHOCPHAN
WHERE MaLHP = 'LHP506' AND TrangThaiDangKy = 'DA_DANG_KY';
-- ❌ MONG ĐỢI (bản chưa fix): 2 | 1 | 1  → 2 sinh viên vào lớp 1 chỗ
--    Bộ đếm kẹt ở 1 vì trigger dùng LEAST(SiSoToiDa, SiSoHienTai + 1)
--    ⇒ lỗi hỏng ÂM THẦM, phải COUNT(*) mới lộ ra.

SELECT d.MaSV, d.MaLHP, d.NgayDangKy, d.GhiChu
FROM DANGKYHOCPHAN d
WHERE d.MaLHP = 'LHP506' AND d.TrangThaiDangKy = 'DA_DANG_KY'
ORDER BY d.MaSV;
-- MONG ĐỢI: SV030 (Phien A - chua fix) + SV041 (Phien B - chua fix)


-- ==========================================================
-- BƯỚC 4 — CHỨNG MINH ĐÃ FIX: khôi phục bản thật rồi làm lại
-- ==========================================================
--   1) Khôi phục thủ tục thật (có FOR UPDATE + retry 1213):
--        cd backend
--        node scripts/apply-sql.js ../mysql/procedures/SP_DangKyHocPhan.sql
--        node scripts/verify-db.js        -- phải thấy "✅ ĐÃ FIX (có FOR UPDATE)"
--   2) Xoá bài của 2 tab vừa rồi về "còn 1 chỗ":
--        CALL SP_ChuanBi_Demo_4Anomaly('LHP506');
--   3) Chạy lại y hệt BƯỚC 1 và BƯỚC 2 (không đổi một chữ nào):
--
--        -- TAB 1
--        CALL SP_DangKyHocPhan('SV030','LHP506',24,'Phien A - da fix',@kqA);
--        SELECT @kqA;     -- 0   = lấy được suất cuối
--
--        -- TAB 2 (trong lúc TAB 1 chưa COMMIT)
--        CALL SP_DangKyHocPhan('SV041','LHP506',24,'Phien B - da fix',@kqB);
--        SELECT @kqB;     -- 105 = LỚP ĐÃ ĐẦY SĨ SỐ  ← bị chặn đúng
--
--   4) Kiểm tra lại:
--        SELECT COUNT(*) AS SoDK_ThucTe,
--               (SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP506') AS BoDem_SiSo,
--               (SELECT SiSoToiDa   FROM LOPHOCPHAN WHERE MaLHP='LHP506') AS SiSoToiDa
--        FROM DANGKYHOCPHAN
--        WHERE MaLHP='LHP506' AND TrangThaiDangKy='DA_DANG_KY';
--      ✅ MONG ĐỢI: 1 | 1 | 1  → KHÔNG vượt sĩ số, một suất chỉ cấp cho 1 SV


-- ==========================================================
-- BƯỚC 5 — DỌN DẸP (bắt buộc sau khi demo)
-- ==========================================================
-- CALL SP_ChuanBi_Demo_4Anomaly('LHP506');   -- → 0/1
-- CALL SP_ChuanBi_Demo_4Anomaly('LHP514');   -- → 15/16
-- cd backend
-- node scripts/apply-sql.js ../mysql/procedures/SP_DangKyHocPhan.sql
-- node scripts/verify-db.js


-- ==========================================================
-- GHI CHÚ KỸ THUẬT
-- ==========================================================
-- 1) Cả 2 tab PHẢI là 2 KẾT NỐI RIÊNG (2 Query tab trong Workbench, hoặc 2
--    cửa sổ client). Dùng chung 1 kết nối thì lệnh thứ hai chỉ được gửi sau
--    khi lệnh thứ nhất xong ⇒ KHÔNG bao giờ tái hiện được.
-- 2) Cửa sổ tranh chấp do chính SP mở ra: file
--    demo/sql_config/lost_update__chua_fix.sql đặt
--        DECLARE vDoTreGiay INT DEFAULT 8;
--    và  DO SLEEP(vDoTreGiay);   -- SAU INSERT, TRƯỚC COMMIT
--    ⇒ muốn rộng rãi hơn cho người thao tác tay thì sửa 8 → 15 rồi nạp lại file đó.
--    ⚠️ Đặt SLEEP *TRƯỚC* INSERT sẽ sinh deadlock 1213 (xem demo/01_LOST_UPDATE.md,
--       mục "GHI CHÚ KỸ THUẬT"), làm hỏng màn demo.
-- 3) Bản chất lỗi KHÔNG nằm ở SLEEP: SLEEP chỉ kéo dài cửa sổ tranh chấp.
--    Lỗi nằm ở bước kiểm tra sĩ số đọc bằng SELECT thường (thiếu FOR UPDATE).
-- 4) Mã kết quả pKetQua: 0=OK · 100=Hết hạn · 101=Trùng LHP · 102=Thiếu tiên quyết
--    · 103=Trùng lịch · 104=Vượt tín chỉ · 105=Lớp đầy · 106=LHP không mở · 500=Lỗi hệ thống
-- ==========================================================

SELECT '[OK] Kich ban 2 tab bang CALL thu tuc — xem huong dan trong file nay' AS KetLuan;
