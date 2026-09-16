-- ==========================================================
-- Ten file : mysql/transactions/demo_lostupdate_chuafix.sql
-- Module   : Dang ky hoc phan (TV3) — Chuong 4, muc 4.1 LOST UPDATE
--
-- ⚠️⚠️ ĐÂY LÀ BẢN CỐ Ý CÓ LỖI — CHỈ DÙNG ĐỂ DEMO TRƯỚC LỚP ⚠️⚠️
--
-- Muc dich: ghi đè thủ tục THẬT `SP_DangKyHocPhan` bằng "bản ban đầu chưa
--           fix lỗi" — GIỐNG HỆT bản chính thức, CHỈ KHÁC ĐÚNG 1 CHỖ:
--           bước kiểm tra sĩ số đọc bằng SELECT thường
--           (KHÔNG có FOR UPDATE) => hai phiên cùng đọc "còn 1 chỗ",
--           cùng ghi => LOST UPDATE, lớp nhận quá sĩ số.
--
-- Vi sao phải có DO SLEEP?  Bản chất lỗi KHÔNG nằm ở SLEEP. SLEEP chỉ để
--   MỞ RỘNG CỬA SỔ TRANH CHẤP, vì thao tác tay trên web (2 người bấm nút)
--   không thể đồng thời trong vài chục mili-giây như khi chạy script.
--   => 2 sinh viên chỉ cần bấm "Đăng ký" cách nhau ~2 giây là tái hiện được.
--   (Trên trình biên soạn DB thì KHÔNG cần SLEEP: tự ngồi chờ cũng được,
--    xem docs/concurrency/kich_ban_thao_tac_tay_lost_update.md PHẦN A.)
--
--   Vị trí SLEEP: đặt SAU INSERT và TRƯỚC COMMIT (xem giải thích ở dưới,
--   ngay tại lệnh DO SLEEP) — nếu đặt trước INSERT sẽ bị deadlock 1213.
--
-- Cach ap dung (máy đang chạy web):
--     cd backend
--     node scripts/apply-sql.js ../mysql/transactions/demo_lostupdate_chuafix.sql
--
-- ★ KHÔI PHỤC BẢN ĐÃ FIX (bắt buộc sau khi demo xong):
--     node scripts/apply-sql.js ../mysql/procedures/SP_DangKyHocPhan.sql
--
-- Ma loi pKetQua: 0=OK, 100=Het han, 101=Trung LHP, 102=Thieu tien quyet,
--                 103=Trung lich, 104=Vuot tin chi, 105=Lop day, 500=Loi he thong
-- ==========================================================

DROP PROCEDURE IF EXISTS SP_DangKyHocPhan;

DELIMITER $$

CREATE PROCEDURE SP_DangKyHocPhan (
    IN  pMaSV      VARCHAR(12),
    IN  pMaLHP     VARCHAR(15),
    IN  pMaxTinChi INT,
    IN  pGhiChu    VARCHAR(255),
    OUT pKetQua    INT
)
proc_dangky_chuafix: BEGIN
    DECLARE vMaHocKy      VARCHAR(10);
    DECLARE vMaMonHoc     VARCHAR(10);
    DECLARE vSoTinChiMH   INT;
    DECLARE vTrangThaiLop VARCHAR(30);
    DECLARE vSiSoHienTai  INT;
    DECLARE vSiSoToiDa    INT;
    DECLARE vTongTinChiDa INT;
    DECLARE vNotFound     INT DEFAULT 0;
    DECLARE vDoTreGiay    INT DEFAULT 8;   -- ⏸ 8 giây: mở rộng cửa sổ cho người thao tác tay

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET vNotFound = 1;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET pKetQua = 500;
    END;

    IF pMaxTinChi IS NULL THEN SET pMaxTinChi = 24; END IF;
    SET pKetQua = 500;

    START TRANSACTION;

    SELECT lhp.MaHocKy, lhp.MaMonHoc, mh.SoTinChi, lhp.TrangThaiLop
    INTO vMaHocKy, vMaMonHoc, vSoTinChiMH, vTrangThaiLop
    FROM LOPHOCPHAN lhp JOIN MONHOC mh ON mh.MaMonHoc = lhp.MaMonHoc
    WHERE lhp.MaLHP = pMaLHP;

    IF vNotFound = 1 THEN SET pKetQua = 106; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;
    IF vTrangThaiLop <> 'MO_DANG_KY' THEN SET pKetQua = 106; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;

    IF FN_KiemTraDotDangKy() = 0 THEN SET pKetQua = 100; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;

    IF NOT EXISTS (SELECT 1 FROM HOCKY
                   WHERE MaHocKy = vMaHocKy AND TrangThaiDot = 'MO'
                     AND NOW() BETWEEN TuNgay AND DenNgay)
    THEN SET pKetQua = 100; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;

    IF EXISTS (SELECT 1 FROM DANGKYHOCPHAN WHERE MaSV = pMaSV AND MaLHP = pMaLHP
                 AND TrangThaiDangKy IN ('DA_DANG_KY','CHO_DUYET'))
    THEN SET pKetQua = 101; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;

    IF FN_KiemTraTienQuyet(pMaSV, vMaMonHoc) = 0 THEN SET pKetQua = 102; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;

    IF FN_KiemTraTrungLichHoc(pMaSV, pMaLHP) = 1 THEN SET pKetQua = 103; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;

    SET vTongTinChiDa = FN_TinhTongTinChi(pMaSV, vMaHocKy);
    IF (vTongTinChiDa + vSoTinChiMH) > pMaxTinChi THEN SET pKetQua = 104; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;

    -- ============================================================
    -- ★ ĐIỂM KHÁC BIỆT DUY NHẤT SO VỚI BẢN ĐÃ FIX: KHÔNG CÓ FOR UPDATE
    --   Bản đã fix:  SELECT ... FROM LOPHOCPHAN WHERE MaLHP = pMaLHP FOR UPDATE;
    --   Bản này   :  SELECT thường  -> KHÔNG khóa dòng sĩ số
    -- ============================================================
    SELECT SiSoHienTai, SiSoToiDa
    INTO vSiSoHienTai, vSiSoToiDa
    FROM LOPHOCPHAN
    WHERE MaLHP = pMaLHP;

    IF vSiSoHienTai >= vSiSoToiDa THEN SET pKetQua = 105; ROLLBACK; LEAVE proc_dangky_chuafix; END IF;

    -- ⏸ Giữ nguyên quyết định "còn chỗ" vừa đọc trong 5 giây để phiên kia
    --    kịp đọc cùng giá trị cũ => cả hai cùng thấy hợp lệ (Lost Update).
    INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
    VALUES (pMaSV, pMaLHP, NOW(), 'DA_DANG_KY', pGhiChu);

    -- ⏸ ⚠️ VỊ TRÍ CỦA SLEEP RẤT QUAN TRỌNG — ĐẶT *SAU* INSERT, *TRƯỚC* COMMIT:
    --   • Phiên A: INSERT xong (giữ khóa dòng LOPHOCPHAN) → ngủ → COMMIT
    --   • Phiên B: đọc sĩ số bằng SELECT thường (MVCC) vẫn thấy giá trị CŨ
    --     "còn chỗ" → INSERT bị CHỜ KHÓA của A → A commit → B đi tiếp → cùng ghi
    --   => quan sát được đúng "phiên sau bị chờ khóa" mà KHÔNG sinh deadlock.
    --
    --   Nếu đặt SLEEP *TRƯỚC* INSERT (cách làm ban đầu) thì hai lệnh INSERT của
    --   A và B chồng lên nhau: cả hai cùng giữ khóa S (do kiểm tra FK tới
    --   LOPHOCPHAN) rồi cùng đòi nâng lên khóa X (do trigger cộng sĩ số)
    --   => InnoDB phát hiện DEADLOCK 1213 và rollback một phiên, làm hỏng
    --      màn demo Lost Update (đã đo thực tế: lệch 1 giây là dính 1213).
    DO SLEEP(vDoTreGiay);

    SET pKetQua = 0;
    COMMIT;
END$$
DELIMITER ;

SELECT '[CANH BAO] Da ghi de SP_DangKyHocPhan bang BAN CHUA FIX (khong FOR UPDATE, sleep 8s sau INSERT). Khoi phuc bang: node scripts/apply-sql.js ../mysql/procedures/SP_DangKyHocPhan.sql' AS KetLuan;
