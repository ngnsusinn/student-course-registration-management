-- ==========================================================
-- Ten file : demo/sql_config/mariadb__tat_snapshot_isolation.sql
-- Muc dich : Tat `innodb_snapshot_isolation` tren MariaDB 11.x
--
-- ⚠️ VI SAO CAN FILE NAY?
--   MariaDB 11.x bat mac dinh `innodb_snapshot_isolation = ON`. Khi bat,
--   o muc co lap REPEATABLE READ, MariaDB KHONG cho phep ghi de len mot
--   dong da bi giao tac khac sua sau khi giao tac nay da doc no: no ném loi
--
--        ERROR 1020 (ER_CHECKREAD):
--        "Record has changed since last read in table '...'; try restarting transaction"
--
--   Trong ban `SP_DangKyHocPhan` CHUA FIX (khong FOR UPDATE), phien B doc
--   si so bang SELECT thuong roi INSERT -> trigger cap nhat LOPHOCPHAN;
--   thay vi de xay ra LOST UPDATE (2 sinh vien vao lop 1 cho nhu tai lieu
--   mo ta), MariaDB CHAN lai va tra loi 1020 => thu tuc bat vao
--   EXIT HANDLER => pKetQua = 500 => web hien
--   "Loi he thong khi xu ly dang ky."  (mot tab bao loi, khong tai hien duoc
--   kich ban Lost Update).
--
--   MySQL 8.0 khong co co che nay => tai lieu cua do an (moi bang so lieu
--   do o REPEATABLE READ) dung voi ngu nghia MySQL. Tat co nay tren MariaDB
--   dua may chu ve DUNG ngu nghia do.
--
-- ★ TAC DUNG: chi voi CAC KET NOI MOI. Cac connection dang mo trong pool
--   cua backend van giu gia tri cu => SAU KHI CHAY FILE NAY HAY KHOI DONG
--   LAI BACKEND (hoac doi pool idle ~60s) de moi ket noi nhan gia tri moi.
--
-- ★ BEN VUNG QUA RESTART: `SET GLOBAL` mat tac dung khi may chu khoi dong
--   lai. Muon giu vinh vien, them vao file cau hinh MariaDB tren may chu:
--
--       # /etc/mysql/mariadb.conf.d/99-demo-anomaly.cnf
--       [mysqld]
--       innodb_snapshot_isolation = OFF
--
--   roi:  sudo systemctl restart mariadb
--
-- Cach ap dung bang dong lenh:
--     cd backend
--     node scripts/apply-sql.js ../demo/sql_config/mariadb__tat_snapshot_isolation.sql
--     node scripts/verify-db.js        # phai thay: snapshot_isolation = OFF
--
-- ★ KHOI PHUC MAC DINH CUA MARIADB:  SET GLOBAL innodb_snapshot_isolation = ON;
-- ==========================================================

SET GLOBAL innodb_snapshot_isolation = OFF;

SELECT @@global.innodb_snapshot_isolation  AS SI_Global_Sau_Khi_Doi,
       @@session.innodb_snapshot_isolation AS SI_Phien_Dang_Chay_File_Nay,
       VERSION()                           AS PhienBan,
       'Neu SI_Global = 0 nhung SI_Phien = 1 thi ket noi nay mo TRUOC khi doi -> KHONG sao, chi can KHOI DONG LAI BACKEND.' AS GhiChu;
