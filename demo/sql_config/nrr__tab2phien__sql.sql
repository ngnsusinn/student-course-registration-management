-- ==========================================================
-- Ten file : demo/sql_config/nrr__tab2phien__sql.sql
-- Muc dich : KỊCH BẢN 2 CỬA SỔ BẰNG SQL — Non-repeatable Read / Phantom Read / Dirty Read
--            ⚠️ VIẾT RIÊNG CHO **phpMyAdmin** (và mọi client đóng kết nối sau mỗi câu lệnh)
--
-- ==========================================================
-- ★ VÌ SAO "GÕ TỪNG CÂU RỒI CHUYỂN TAB" KHÔNG CHẠY ĐƯỢC TRÊN phpMyAdmin?
--
--   Muốn thấy Non-repeatable Read phải giữ MỘT giao tác MỞ giữa hai lần đọc:
--        START TRANSACTION → ĐỌC lần 1 → (cửa sổ khác UPDATE + COMMIT) → ĐỌC lần 2
--
--   • Trên Workbench / DBeaver / HeidiSQL / mysql CLI: kết nối được GIỮ LIÊN TỤC
--     giữa các lần bấm "Execute" ⇒ giao tác còn nguyên ⇒ cách gõ từng câu CHẠY TỐT.
--   • Trên phpMyAdmin: mỗi lần bấm "Go" là MỘT request HTTP mới ⇒ kết nối MySQL
--     MỚI ⇒ `START TRANSACTION` của lần gửi trước **đã bị mất** ⇒ lần đọc thứ hai
--     nằm ở giao tác KHÁC ⇒ demo vô hiệu (thậm chí REPEATABLE READ cũng ra 15→16).
--   • Thêm nữa: 2 tab trong CÙNG một trình duyệt dùng chung PHP session ⇒ request
--     này phải CHỜ request kia (khoá session) ⇒ cửa sổ 2 không chen vào được
--     trong lúc cửa sổ 1 đang `DO SLEEP`.
--
-- ★ CÁCH KHẮC PHỤC (đúng 2 điều kiện):
--     1) Gói TRỌN giao tác vào MỘT câu lệnh duy nhất  → dùng SP_Demo_DocHaiLan
--        (thủ tục tự START TRANSACTION → đọc lần 1 → DO SLEEP → đọc lần 2 → ROLLBACK)
--     2) Mở 2 CỬA SỔ Ở 2 TRÌNH DUYỆT KHÁC NHAU (1 thường + 1 Ẩn danh/InPrivate),
--        KHÔNG dùng 2 tab của cùng một trình duyệt.
--
-- ==========================================================
-- KẾT QUẢ ĐÃ ĐO THẬT (máy đang chạy web — MariaDB 11.8.9):
--   CÁCH A (SP_Demo_DocHaiLan)  READ COMMITTED  → 15 → 16  ⇒ TÁI HIỆN ĐƯỢC lỗi
--                               REPEATABLE READ → 15 → 15  ⇒ ĐÃ CHẶN
--                               READ UNCOMMITTED→ 15 → 16  ⇒ ĐỌC BẨN (cửa sổ 2 không commit)
--   CÁCH C (khối nhiều câu lệnh)  READ COMMITTED → 15 → 16 · REPEATABLE READ → 15 → 15
--   (CÁCH B — gõ từng câu — CHỈ chạy trên client giữ kết nối: Workbench/DBeaver/CLI)
-- ==========================================================


-- ==========================================================
-- BƯỚC 0 — CHUẨN BỊ (chạy ở cửa sổ nào cũng được)
-- ==========================================================
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');   -- LHP514 về "còn đúng 1 chỗ"

SELECT MaLHP, SiSoHienTai, SiSoToiDa, (SiSoToiDa - SiSoHienTai) AS ConTrong
FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';
-- MONG ĐỢI: LHP514 | 15 | 16 | 1


-- ==========================================================
-- ✅ CÁCH A — KHUYÊN DÙNG CHO phpMyAdmin (mỗi cửa sổ CHỈ 1 CÂU)
-- ==========================================================

-- 🪟 CỬA SỔ 1 (TRÌNH DUYỆT THỨ NHẤT) — chạy câu này rồi CHUYỂN NGAY sang cửa sổ 2
--    Thủ tục tự mở giao tác, đọc lần 1, ngủ pDoTreGiay giây, đọc lần 2, rồi ROLLBACK.
--    Tham số: (MaLHP, mức cô lập, số giây giữa 2 lần đọc)
CALL SP_Demo_DocHaiLan('LHP514', 'READ COMMITTED', 8);

-- 🪟 CỬA SỔ 2 (TRÌNH DUYỆT THỨ HAI) — chạy TRONG 8 GIÂY đó
UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP = 'LHP514';
COMMIT;   -- ★ BẮT BUỘC: phải COMMIT thì lần đọc 2 mới thấy giá trị mới

-- ✅ CỬA SỔ 1 sẽ trả về (1 dòng, đủ cả 2 con số để chụp ảnh):
--      MaLHP  | MucCoLap       | SiSo_Lan1 | SiSo_Lan2 | KetLuan
--      LHP514 | READ COMMITTED |    15     |    16     | ĐỔI giữa 2 lần đọc ⇒ TÁI HIỆN ĐƯỢC lỗi đọc


-- ==========================================================
-- ✅ ĐỐI CHỨNG ĐÃ FIX — làm lại y hệt, chỉ đổi mức cô lập
-- ==========================================================
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');   -- dọn về 15/16 trước

-- 🪟 CỬA SỔ 1
CALL SP_Demo_DocHaiLan('LHP514', 'REPEATABLE READ', 8);
-- 🪟 CỬA SỔ 2 (trong 8 giây đó)
UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP = 'LHP514';
COMMIT;
-- ✅ CỬA SỔ 1: SiSo_Lan1 = 15 · SiSo_Lan2 = 15 ⇒ 'KHÔNG đổi ⇒ mức cô lập đã CHẶN'
--    (dù cửa sổ 2 ĐÃ UPDATE và COMMIT thật — MVCC giữ nguyên ảnh chụp)


-- ==========================================================
-- ✅ BIẾN THỂ — DIRTY READ (cửa sổ 2 GHI nhưng KHÔNG COMMIT)
-- ==========================================================
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');

-- 🪟 CỬA SỔ 1
CALL SP_Demo_DocHaiLan('LHP514', 'READ UNCOMMITTED', 8);
-- 🪟 CỬA SỔ 2 (trong 8 giây đó): ghi nhưng ĐỪNG commit
--     START TRANSACTION;
--     UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP = 'LHP514';
--     ROLLBACK;   -- ★ rollback: con số mà cửa sổ 1 vừa đọc KHÔNG hề tồn tại
-- ✅ CỬA SỔ 1: SiSo_Lan2 = 16 ⇒ ĐÃ đọc dữ liệu CHƯA COMMIT (đọc bẩn)
--    Đổi 'READ UNCOMMITTED' → 'REPEATABLE READ' ⇒ SiSo_Lan2 = 15 ⇒ đã chặn


-- ==========================================================
-- CÁCH B — CLIENT GIỮ KẾT NỐI (Workbench / DBeaver / HeidiSQL / mysql CLI)
--           Không dùng cho phpMyAdmin.
-- ==========================================================
-- 🪟 CỬA SỔ 1
--     SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;   -- ★ TẮT phòng chống
--     START TRANSACTION;
--     SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';   -- lần 1 → 15
--     -- ⏸ DỪNG, KHÔNG commit. Sang cửa sổ 2.
--     SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';   -- lần 2 → 16  📸
--     ROLLBACK;
--     SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;     -- trả về mặc định
--
-- 🪟 CỬA SỔ 2 (chạy giữa 2 lần đọc)
--     UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP = 'LHP514';
--     COMMIT;


-- ==========================================================
-- CÁCH C — phpMyAdmin CÓ bật nhiều câu lệnh trong 1 ô (dán TRỌN khối vào 1 ô rồi Go)
--           Nếu phpMyAdmin báo lỗi cú pháp ⇒ dùng CÁCH A.
-- ==========================================================
-- 🪟 CỬA SỔ 1 — dán TẤT CẢ các dòng sau vào MỘT ô query rồi bấm Go:
--     SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
--     START TRANSACTION;
--     SELECT SiSoHienTai AS Lan1 FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';
--     DO SLEEP(8);
--     SELECT SiSoHienTai AS Lan2 FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';
--     ROLLBACK;
--     SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
--
-- 🪟 CỬA SỔ 2 — trong 8 giây đó:
--     UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP = 'LHP514';
--     COMMIT;


-- ==========================================================
-- BƯỚC CUỐI — DỌN DẸP (BẮT BUỘC)
-- ==========================================================
-- CALL SP_ChuanBi_Demo_4Anomaly('LHP514');                   -- trả LHP514 về 15/16
-- SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;   -- trả mức cô lập mặc định
-- SELECT @@session.transaction_isolation;                    -- kiểm tra: REPEATABLE-READ
--
-- Lưu ý: cách demo này chỉ sửa CỘT ĐẾM SiSoHienTai (không tạo dòng đăng ký nào),
--        nên sau demo chỉ cần CALL SP_ChuanBi_Demo_4Anomaly('LHP514') là bộ đếm
--        khớp lại COUNT(*) hiệu lực.


-- ==========================================================
-- GHI CHÚ
-- ==========================================================
-- 1) SP_Demo_DocHaiLan tự trả mức cô lập về REPEATABLE READ trước khi kết thúc ⇒
--    an toàn cả khi backend dùng connection pool.
-- 2) Mức cô lập nhận 1 trong 4 giá trị:
--      'READ UNCOMMITTED' | 'READ COMMITTED' | 'REPEATABLE READ' | 'SERIALIZABLE'
--    (giá trị khác ⇒ tự chuẩn hoá về 'READ COMMITTED')
-- 3) pDoTreGiay = 0 ⇒ đọc liền 2 lần (không cần cửa sổ 2), dùng để kiểm tra nhanh.
-- 4) Đổi LHP514 thành LHP506 cũng chạy được, nhưng phải CALL SP_ChuanBi_Demo_4Anomaly('LHP506')
--    trước — và nhớ LHP506 chỉ có 1 chỗ (0/1).
-- 5) Muốn demo Phantom Read: cửa sổ 2 thay UPDATE bằng
--      INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
--      VALUES ('SV999', 'LHP514', NOW(), 'DA_DANG_KY', 'dong bong ma');
--      COMMIT;
--    rồi xem cột SoDong_Lan1 → SoDong_Lan2 (15 → 16).

SELECT '[OK] Kich ban 2 cua so bang SQL — xem huong dan trong file nay (CACH A cho phpMyAdmin)' AS KetLuan;
