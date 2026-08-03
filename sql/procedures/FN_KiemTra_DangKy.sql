-- ==========================================================
-- Tên file : sql/procedures/FN_KiemTra_DangKy.sql
-- Module   : Đăng ký học phần (TV3 — Leader)
-- Issue    : #51 SP HuyDangKy + Function kiểm tra tiên quyết
-- Mô tả    : Bộ 4 FUNCTION hỗ trợ quy trình đăng ký/hủy:
--              1. FN_KiemTraTienQuyet(MaSV, MaMonHoc)  -> BIT
--              2. FN_KiemTraTrungLichHoc(MaSV, MaLHP)  -> BIT
--              3. FN_TinhTongTinChi(MaSV, MaHocKy)     -> INT
--              4. FN_KiemTraDotDangKy()                -> BIT
--            Các function thuần đọc (NO SQL side effect), được
--            gọi lại trong SP_DangKyHocPhan (Issue #50),
--            SP_HuyDangKy và Transaction (Issue #72).
-- ==========================================================

-- ==========================================================
-- 1. FN_KiemTraTienQuyet
--    Kiểm tra SV đã ĐẠT (DiemChu <> 'F') tất cả môn tiên quyết
--    của môn học muốn đăng ký chưa.
--    Trả về: 1 = Đủ điều kiện, 0 = Thiếu tiên quyết
-- ==========================================================
IF OBJECT_ID(N'dbo.FN_KiemTraTienQuyet', N'FN') IS NOT NULL DROP FUNCTION dbo.FN_KiemTraTienQuyet;
GO
CREATE FUNCTION dbo.FN_KiemTraTienQuyet (
    @MaSV      VARCHAR(12),
    @MaMonHoc  VARCHAR(10)
)
RETURNS BIT
AS
BEGIN
    DECLARE @KetQua BIT = 1;

    -- Nếu môn không có tiên quyết -> luôn hợp lệ
    IF NOT EXISTS (SELECT 1 FROM MONHOC_TIENQUYET WHERE MaMonHoc = @MaMonHoc)
        RETURN @KetQua;

    -- Tồn tại ít nhất 1 môn tiên quyết mà SV CHƯA ĐẠT -> trả 0
    IF EXISTS (
        SELECT 1
        FROM MONHOC_TIENQUYET mtq
        WHERE mtq.MaMonHoc = @MaMonHoc
          AND NOT EXISTS (
                SELECT 1
                FROM KETQUAHOCTAP kq
                JOIN LOPHOCPHAN kqL ON kqL.MaLHP = kq.MaLHP
                WHERE kq.MaSV = @MaSV
                  AND kqL.MaMonHoc = mtq.MaMonTienQuyet
                  AND kq.DiemChu <> N'F'     -- đã ĐẠT (DiemChu khác F)
          )
    )
        SET @KetQua = 0;

    RETURN @KetQua;
END;
GO

-- ==========================================================
-- 2. FN_KiemTraTrungLichHoc
--    Kiểm tra LHP mới có TRÙNG LỊCH với các LHP SV đã ĐK thành
--    công trong CÙNG HỌC KỲ không.
--    Điều kiện trùng: cùng Thu VÀ khung tiết giao nhau.
--    Trả về: 1 = Bị trùng lịch, 0 = Không trùng
-- ==========================================================
IF OBJECT_ID(N'dbo.FN_KiemTraTrungLichHoc', N'FN') IS NOT NULL DROP FUNCTION dbo.FN_KiemTraTrungLichHoc;
GO
CREATE FUNCTION dbo.FN_KiemTraTrungLichHoc (
    @MaSV   VARCHAR(12),
    @MaLHP  VARCHAR(15)
)
RETURNS BIT
AS
BEGIN
    DECLARE @KetQua BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM LICHHOC lhMoi
        JOIN LOPHOCPHAN lhpMoi ON lhpMoi.MaLHP = lhMoi.MaLHP
        WHERE lhMoi.MaLHP = @MaLHP
          AND EXISTS (
                SELECT 1
                FROM DANGKYHOCPHAN dkCu
                JOIN LOPHOCPHAN lhpCu ON lhpCu.MaLHP = dkCu.MaLHP
                JOIN LICHHOC lhCu    ON lhCu.MaLHP = lhpCu.MaLHP
                WHERE dkCu.MaSV = @MaSV
                  AND dkCu.TrangThaiDangKy = N'DA_DANG_KY'
                  AND lhpCu.MaHocKy = lhpMoi.MaHocKy   -- cùng học kỳ
                  AND lhCu.Thu = lhMoi.Thu             -- cùng Thứ
                  -- Khung tiết giao nhau:
                  AND lhCu.TietBatDau <= lhMoi.TietBatDau + lhMoi.SoTiet - 1
                  AND lhCu.TietBatDau + lhCu.SoTiet - 1 >= lhMoi.TietBatDau
          )
    )
        SET @KetQua = 1;

    RETURN @KetQua;
END;
GO

-- ==========================================================
-- 3. FN_TinhTongTinChi
--    Tính tổng số tín chỉ SV đã ĐK thành công trong 1 học kỳ.
-- ==========================================================
IF OBJECT_ID(N'dbo.FN_TinhTongTinChi', N'FN') IS NOT NULL DROP FUNCTION dbo.FN_TinhTongTinChi;
GO
CREATE FUNCTION dbo.FN_TinhTongTinChi (
    @MaSV    VARCHAR(12),
    @MaHocKy VARCHAR(10)
)
RETURNS INT
AS
BEGIN
    DECLARE @Tong INT;

    SELECT @Tong = ISNULL(SUM(mh.SoTinChi), 0)
    FROM DANGKYHOCPHAN dk
    JOIN LOPHOCPHAN lhp ON lhp.MaLHP = dk.MaLHP
    JOIN MONHOC     mh  ON mh.MaMonHoc = lhp.MaMonHoc
    WHERE dk.MaSV = @MaSV
      AND dk.TrangThaiDangKy = N'DA_DANG_KY'
      AND lhp.MaHocKy = @MaHocKy;

    RETURN @Tong;
END;
GO

-- ==========================================================
-- 4. FN_KiemTraDotDangKy
--    Kiểm tra đợt đăng ký HIỆN TẠI còn mở hay không.
--    Điều kiện hợp lệ: GETDATE() BETWEEN TuNgay AND DenNgay
--                      AND TrangThaiDot = N'MO'
--    Trả về: 1 = Đang mở, 0 = Đã đóng
--    (Lưu ý: nếu có NHIỀU học kỳ cùng mở, hàm ưu tiên kỳ có
--     TuNgay gần nhất — đơn giản hoá: lấy học kỳ MO có DenNgay
--     lớn nhất.)
-- ==========================================================
IF OBJECT_ID(N'dbo.FN_KiemTraDotDangKy', N'FN') IS NOT NULL DROP FUNCTION dbo.FN_KiemTraDotDangKy;
GO
CREATE FUNCTION dbo.FN_KiemTraDotDangKy ()
RETURNS BIT
AS
BEGIN
    DECLARE @KetQua BIT = 0;

    IF EXISTS (
        SELECT 1
        FROM HOCKY
        WHERE TrangThaiDot = N'MO'
          AND GETDATE() BETWEEN TuNgay AND DenNgay
    )
        SET @KetQua = 1;

    RETURN @KetQua;
END;
GO

PRINT N'[OK] Issue #51 — Đã tạo 4 FUNCTION hỗ trợ đăng ký/hủy.';
GO
