-- ==========================================================
-- Tên file : sql/indexes/hocphan_giangvien_lophocphan_indexes.sql
-- Module   : Học phần, Giảng viên & Mở lớp học phần (TV2)
-- Issue    : Non-clustered Index Học phần, Giảng viên & Lớp học phần
-- Mô tả    : Tạo Non-clustered Index phục vụ các truy vấn thường dùng:
--              - IX_LHP_MaMonHoc  : Tra cứu các LHP theo môn học
--              - IX_LHP_MaGV      : Tra cứu các LHP theo giảng viên
--              - IX_LHP_MaHocKy   : Tra cứu các LHP theo học kỳ
--              - IX_LH_MaPhong    : Tra cứu lịch học theo phòng
--              - IX_LH_MaLHP      : Tra cứu lịch học theo lớp học phần
--            Kèm câu lệnh đo hiệu năng (SET STATISTICS TIME/IO)
--            để so sánh trước/sau khi tạo index.
-- ==========================================================

/*==========================================================
    COMPOSITE INDEX TỐI ƯU KIỂM TRA TRÙNG LỊCH
==========================================================*/

/* 1. Index kiểm tra lịch theo phòng */
CREATE NONCLUSTERED INDEX IX_LichHoc_MaPhong_Thu_Tiet
ON LichHoc (MaPhong, Thu, TietBatDau);



/* 2. Index kiểm tra lịch theo giảng viên */
CREATE NONCLUSTERED INDEX IX_LopHocPhan_MaGV_HocKy
ON LopHocPhan (MaGV, MaHocKy);

/*==========================================================
    COMPOSITE INDEX TỐI ƯU KIỂM TRA TRÙNG LỊCH
==========================================================*/

/* 1. Index kiểm tra lịch theo phòng */
CREATE NONCLUSTERED INDEX IX_LichHoc_MaPhong_Thu_Tiet
ON LichHoc (MaPhong, Thu, TietBatDau);



/* 2. Index kiểm tra lịch theo giảng viên */
CREATE NONCLUSTERED INDEX IX_LopHocPhan_MaGV_HocKy
ON LopHocPhan (MaGV, MaHocKy);

/*==========================================================
    COMPOSITE INDEX TỐI ƯU KIỂM TRA TRÙNG LỊCH
==========================================================*/

/* 1. Index kiểm tra lịch theo phòng */
CREATE NONCLUSTERED INDEX IX_LichHoc_MaPhong_Thu_Tiet
ON LichHoc (MaPhong, Thu, TietBatDau);



/* 2. Index kiểm tra lịch theo giảng viên */
CREATE NONCLUSTERED INDEX IX_LopHocPhan_MaGV_HocKy
ON LopHocPhan (MaGV, MaHocKy);
