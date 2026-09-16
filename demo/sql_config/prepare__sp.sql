-- ==========================================================
-- Ten file : demo/sql_config/prepare__sp.sql
-- Muc dich : ⚠️ CÔNG CỤ DEMO — 2 stored procedure phục vụ trang
--            “Chuẩn bị Demo” (2 nút 1-click: CHUẨN BỊ và FIX).
--
--   SP_Prepare_Demo(pKichBan)     → dọn & đưa TOÀN BỘ dữ liệu demo về
--                                   trạng thái xuất phát (idempotent).
--       pKichBan = 'DEMO'     (mặc định) : Lost Update + NRR/Phantom
--       pKichBan = 'DEADLOCK'           : thêm dòng DA_HUY cho SV030
--                                         phục vụ demo deadlock
--
--   SP_Prepare_TrangThai()        → trả về 3 result set:
--       1. Cờ trạng thái 2 thủ tục nghiệp vụ (bản thật / bản có lỗi)
--       2. Trạng thái các lớp demo
--       3. Tài khoản demo có tồn tại & đang hoạt động không
--
-- Cach ap dung (1 lan):
--     cd backend
--     node scripts/apply-sql.js ../demo/sql_config/prepare__sp.sql
-- ==========================================================

DROP PROCEDURE IF EXISTS SP_Prepare_TrangThai;
DROP PROCEDURE IF EXISTS SP_Prepare_Demo;

DELIMITER $$

-- ----------------------------------------------------------
-- 1) DỌN & CHUẨN BỊ DỮ LIỆU DEMO
-- ----------------------------------------------------------
CREATE PROCEDURE SP_Prepare_Demo (IN pKichBan VARCHAR(20))
BEGIN
    DECLARE vKB VARCHAR(20);
    SET vKB = UPPER(IFNULL(pKichBan, 'DEMO'));

    -- (a) Xóa đăng ký thử của các TÀI KHOẢN DEMO trên các LỚP DEMO
    DELETE FROM DANGKYHOCPHAN
    WHERE MaSV IN ('SV001', 'SV003', 'SV004', 'SV030', 'SV041', 'SV060', 'SV999')
      AND MaLHP IN ('LHP505', 'LHP506', 'LHP507', 'LHP508', 'LHP514');

    -- (b) Tính lại sĩ số THỰC TẾ cho 3 lớp dùng cho kịch bản NRR/Phantom
    UPDATE LOPHOCPHAN lhp
    SET lhp.SiSoHienTai = (
        SELECT COUNT(*) FROM DANGKYHOCPHAN d
        WHERE d.MaLHP = lhp.MaLHP AND d.TrangThaiDangKy = 'DA_DANG_KY')
    WHERE lhp.MaLHP IN ('LHP505', 'LHP507', 'LHP508');

    -- (c) LHP514 và LHP506 về "còn đúng 1 chỗ" (đồng thời xóa dòng thử của SV030/SV041)
    CALL SP_ChuanBi_Demo_4Anomaly('LHP514');
    CALL SP_ChuanBi_Demo_4Anomaly('LHP506');

    -- (d) Kịch bản DEADLOCK cần thêm 1 dòng DA_HUY cho SV030 ở LHP514
    IF vKB = 'DEADLOCK' THEN
        CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506');
    END IF;

    -- (e) Trả về trạng thái sau khi chuẩn bị
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
-- 2) TRẠNG THÁI HIỆN TẠI (để trang web hiển thị "đang ở bản nào")
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
        WHERE ROUTINE_SCHEMA = DATABASE() AND ROUTINE_NAME = 'SP_DangKyNhieuHocPhan') AS Nhieu_CoSleep;

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
END$$

DELIMITER ;

SELECT '[OK] Da tao SP_Prepare_Demo + SP_Prepare_TrangThai (cong cu 1-click prepare/fix)' AS KetLuan;
