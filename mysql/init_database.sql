-- ==========================================================
-- Ten file : mysql/init_database.sql
-- Mo ta    : Kich ban khoi tao TOAN BO he thong tren MySQL
--            (ban thay the sql/init_database.sql cua SQL Server).
--            Database roacqgfa_dbms da ton tai tren hosting
--            (khong duoc quyen CREATE/DROP DATABASE).
-- Cach chay :
--   (1) Dung Node.js runner (khuyen dung, xu ly DELIMITER):
--         cd backend && node scripts/init-db.js
--   (2) Dung mysql client (tu mysql/):
--         mysql -h free02.123host.vn -u roacqgfa_dbms -p roacqgfa_dbms
--         sau do chay lan luot: source <tung file theo thu tu duoi>
-- Thu tu  :
--   1. ddl/00_danh_muc_hoso_sv_ddl.sql
--   2. ddl/00_hocphan_giangvien_ddl.sql
--   3. ddl/10_dangky_hocphan_ddl.sql
--   4. ddl/00_diem_ketqua_ddl.sql
--   5. ddl/00_hocphi_taikhoan_ddl.sql
--   6. data/00_danh_muc_hoso_sv_data.sql
--   7. data/00_hocphan_giangvien_data.sql
--   8. data/dangky_hocphan_data.sql
--   9. data/00_diem_ketqua_data.sql
--  10. data/00_hocphi_taikhoan_data.sql
--  11. functions/FN_KiemTra_DangKy.sql
--  12. procedures/SP_DangKyHocPhan.sql
--  13. procedures/SP_HuyDangKy.sql
--  14. procedures/hocphi_taikhoan_procedures.sql
--  15. procedures/sp_gpa.sql
--  16. procedures/hocphan_giangvien_procedures.sql
--  17. procedures/ThemSV_Chuyen_Lop.sql
--  18. triggers/TRG_DANGKYHOCPHAN_SiSo.sql
--  19. triggers/TRG_KETQUAHOCTAP_TinhDiem.sql
--  20. triggers/TRG_LICHHOC_KiemTraTrungLich.sql
--  21. triggers/TRG_LogDoiMatKhau.sql
--  22. triggers/Xoa_Nganh_Trigger.sql
--  23. views/dangky_hocphan_views.sql
--  24. views/diem_ketqua_views.sql
--  25. views/hocphi_views.sql
--  26. views/danh_muc_hoso_sv_views.sql
--  27. indexes/all_indexes.sql
--  28. security/phan_quyen_3_vai_tro.sql (tuy chon)
-- ==========================================================

USE roacqgfa_dbms;

SELECT COUNT(*) AS SoBang FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'roacqgfa_dbms';
