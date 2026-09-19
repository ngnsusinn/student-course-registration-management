# 🧾 SCRIPT DEMO SQL — CHẠY TRỰC TIẾP TRÊN HỆ QUẢN TRỊ CSDL

> **Mục đích:** toàn bộ kịch bản demo (4 lỗi điều khiển cạnh tranh + DEADLOCK) được viết **bằng SQL** và chạy
> **trực tiếp trên HQTCSDL** bằng 2 cửa sổ kết nối. Trong code web **không có bất kỳ màn hình/đoạn code demo nào** —
> web chỉ gọi stored procedure.
>
> **HQTCSDL:** MySQL **5.7.41-cll-lve** (hosting `free02.123host.vn`), engine InnoDB.
> **Module:** Đăng ký học phần (TV3) · **Chương 5** — Điều khiển cạnh tranh.
> **Tài liệu liên quan:** [`concurrency_anomaly_demo.md`](concurrency_anomaly_demo.md) · [`deadlock_demo.md`](deadlock_demo.md) · [`deadlock_analysis.md`](deadlock_analysis.md) · [`kich_ban_demo_thao_tac_that.md`](kich_ban_demo_thao_tac_that.md)

---

## 0. CHUẨN BỊ (làm 1 lần)

### 0.1. Mở **2 cửa sổ** kết nối DB (mỗi cửa sổ = 1 session riêng)

```bash
mysql -h free02.123host.vn -u roacqgfa_dbms -p roacqgfa_dbms
```
> Có thể thay bằng 2 tab phpMyAdmin (mỗi tab là 1 session) nếu mạng chặn port 3306.
> Quy ước dưới đây: **[CỬA SỔ 1]** và **[CỬA SỔ 2]** — gõ đúng khối vào đúng cửa sổ, theo đúng thứ tự.
> Ký hiệu **⏸ DỪNG** = cố ý dừng lại để quan sát hiện tượng.

### 0.2. Nạp các stored procedure phục vụ demo (chạy 1 lần, ở CỬA SỔ 1)

```bash
cd backend
node scripts/apply-sql.js ../mysql/transactions/demo_4_anomaly.sql        # 4 lỗi concurrency
node scripts/apply-sql.js ../mysql/transactions/demo_deadlock.sql         # deadlock
node scripts/apply-sql.js ../mysql/procedures/SP_DangKyNhieuHocPhan.sql   # SP thật (bản đã fix)
```

### 0.3. Kiểm tra môi trường

```sql
SELECT @@version AS PhienBan, @@innodb_deadlock_detect AS PhatHienDeadlock,
       @@innodb_lock_wait_timeout AS ChoKhoaToiDa, @@transaction_isolation AS MucCoLap;
-- MONG ĐỢI: 5.7.41-cll-lve | ON | 50 | REPEATABLE-READ
```

---

# PHẦN A — DEMO 4 LỖI ĐIỀU KHIỂN CẠNH TRANH

## A.0. Chuẩn bị dữ liệu

```sql
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');
SELECT MaLHP, SiSoHienTai, SiSoToiDa, (SiSoToiDa - SiSoHienTai) AS ConTrong
FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';
-- MONG ĐỢI: LHP514 = 15/16 (còn đúng 1 chỗ)
```

## A.1. LOST UPDATE (cập nhật mất) — 2 phiên cùng đọc "còn 1 chỗ", cùng ghi

**[CỬA SỔ 1]**
```sql
START TRANSACTION;
SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';   -- đọc KHÔNG khóa -> 15/16
DO SLEEP(10);                                                          -- ⏸ 10 giây cho cửa sổ 2 chạy
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
VALUES ('SV030', 'LHP514', NOW(), 'DA_DANG_KY', 'Phien A - chua fix');
COMMIT;
```

**[CỬA SỔ 2]** *(chạy trong lúc cửa sổ 1 đang SLEEP)*
```sql
START TRANSACTION;
SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';   -- CŨNG thấy 15/16
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
VALUES ('SV041', 'LHP514', NOW(), 'DA_DANG_KY', 'Phien B - chua fix');  -- chờ khóa của A rồi mới chạy
COMMIT;
```

**[KIỂM TRA]** *(cửa sổ bất kỳ)*
```sql
SELECT COUNT(*) AS SoDK_ThucTe,
       (SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514') AS BoDem_SiSo,
       (SELECT SiSoToiDa  FROM LOPHOCPHAN WHERE MaLHP='LHP514') AS SiSoToiDa
FROM DANGKYHOCPHAN WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';
-- MONG ĐỢI (LỖI): SoDK_ThucTe = 17 > SiSoToiDa = 16, bộ đếm kẹt ở 16 (trigger dùng LEAST)
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');   -- dọn dẹp
```

## A.2. DIRTY READ (đọc bẩn) — **tắt** phòng chống bằng `READ UNCOMMITTED`

**[CỬA SỔ 2]** (phiên GHI, giữ dữ liệu chưa commit)
```sql
START TRANSACTION;
UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP = 'LHP514';
-- ⏸ CHƯA COMMIT — chuyển sang cửa sổ 1
-- (sau khi cửa sổ 1 đọc xong lần 2, quay lại đây chạy:)
ROLLBACK;
```

**[CỬA SỔ 1]** (phiên ĐỌC — **đã tắt** phòng chống)
```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;   -- ★ TẮT phòng chống
START TRANSACTION;
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';  -- đọc được giá trị CHƯA COMMIT -> ĐỌC BẨN
DO SLEEP(8);                                                -- ⏸ trong lúc này cửa sổ 2 ROLLBACK
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';  -- giá trị "biến mất"
ROLLBACK;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;    -- trả về mặc định
```
> **MONG ĐỢI:** lần 1 thấy **16** (dữ liệu chưa commit) → sau ROLLBACK chỉ còn **15**.

```sql
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');
```

## A.3. UNREPEATABLE READ (đọc không lặp lại) — **tắt** bằng `READ COMMITTED`

**[CỬA SỔ 1]** (phiên ĐỌC)
```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;     -- ★ TẮT phòng chống
START TRANSACTION;
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';  -- lần 1
DO SLEEP(8);                                                -- ⏸ cửa sổ 2 UPDATE + COMMIT
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';  -- lần 2 -> KHÁC lần 1
ROLLBACK;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
```

**[CỬA SỔ 2]** *(chạy khi cửa sổ 1 đang SLEEP)*
```sql
UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP = 'LHP514';
COMMIT;
```
> **MONG ĐỢI:** cùng 1 giao tác, đọc 15 rồi 16.

> 💡 **Đây là bản duy nhất chạy được trên phpMyAdmin** (cả giao tác nằm trong MỘT ô query, không gõ từng câu),
> **với điều kiện 2 cửa sổ nằm ở 2 TRÌNH DUYỆT khác nhau** — 2 tab cùng trình duyệt dùng chung PHP session nên
> request này phải chờ request kia (khoá session) và cửa sổ 2 không chen vào được trong lúc `DO SLEEP`.
> Bản dán sẵn + biến thể dùng `SP_Demo_DocHaiLan` (1 câu/cửa sổ):
> `demo/sql_config/nrr__tab2phien__sql.sql` · `demo/02_NON_REPEATABLE_READ.md` PHẦN A2.

```sql
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');
```

## A.4. PHANTOM READ (đọc bóng ma) — **tắt** bằng `READ COMMITTED`

**[CỬA SỔ 1]** (phiên ĐỌC)
```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;     -- ★ TẮT phòng chống
START TRANSACTION;
SELECT COUNT(*) FROM DANGKYHOCPHAN WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';  -- lần 1
DO SLEEP(8);                                                                               -- ⏸
SELECT COUNT(*) FROM DANGKYHOCPHAN WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';  -- lần 2
ROLLBACK;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
```

**[CỬA SỔ 2]** *(chạy khi cửa sổ 1 đang SLEEP)*
```sql
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
VALUES ('SV999', 'LHP514', NOW(), 'DA_DANG_KY', 'dong bong ma');
COMMIT;
```
> **MONG ĐỢI:** COUNT 15 → 16 (dòng "bóng ma" xuất hiện).

```sql
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');
```

## A.5. PHÒNG CHỐNG LẠI — chứng minh bản đã fix

**A.5.1 — `SP_DangKyHocPhan` (có `SELECT ... FOR UPDATE`): 2 phiên giành suất cuối**

**[CỬA SỔ 1]**
```sql
CALL SP_DangKyHocPhan('SV030', 'LHP514', 24, 'Phien A - da fix', @kqA);
SELECT @kqA;      -- MONG ĐỢI: 0 (thành công)
```
**[CỬA SỔ 2]** *(chạy ngay lập tức)*
```sql
CALL SP_DangKyHocPhan('SV041', 'LHP514', 24, 'Phien B - da fix', @kqB);
SELECT @kqB;      -- MONG ĐỢI: 105 (lớp đã đầy — chờ khóa rồi kiểm tra lại sau khi A commit)
```
```sql
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');
```

**A.5.2 — Mức mặc định `REPEATABLE READ`: đọc lại COUNT không thấy "bóng ma"**

**[CỬA SỔ 1]**
```sql
START TRANSACTION;   -- KHÔNG hạ isolation — giữ mặc định REPEATABLE READ
SELECT COUNT(*) FROM DANGKYHOCPHAN WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';  -- lần 1
DO SLEEP(8);                                                                               -- ⏸
SELECT COUNT(*) FROM DANGKYHOCPHAN WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';  -- lần 2 = lần 1
ROLLBACK;
```
**[CỬA SỔ 2]** *(chạy khi cửa sổ 1 đang SLEEP)*
```sql
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
VALUES ('SV999', 'LHP514', NOW(), 'DA_DANG_KY', 'snapshot test');
COMMIT;
```
```sql
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');
```

---

# PHẦN B — DEMO DEADLOCK

## B.0. Chuẩn bị

```sql
SELECT @@version AS PhienBan, @@innodb_deadlock_detect AS PhatHienDeadlock,
       @@innodb_lock_wait_timeout AS ChoKhoaToiDa, @@transaction_isolation AS MucCoLap;

CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506');
-- MONG ĐỢI: LHP506 = 1/2, LHP514 = 15/16, SV030 có dòng DA_HUY ở LHP514
```

## B.1. HQTCSDL **tự** phát hiện deadlock (cơ chế mặc định — không tắt gì)

**[CỬA SỔ 1]**
```sql
SET SESSION innodb_lock_wait_timeout = 20;
CALL SP_Demo_KhoaTheoThuTu('SV030', 'LHP514,LHP506', 'THEO_YEU_CAU', 3, @kq1);
-- ⏸ cửa sổ 1 đang giữ khóa LHP514 và ngủ 3 giây -> CHUYỂN NGAY sang cửa sổ 2
```
**[CỬA SỔ 2]**
```sql
SET SESSION innodb_lock_wait_timeout = 20;
CALL SP_Demo_KhoaTheoThuTu('SV041', 'LHP506,LHP514', 'THEO_YEU_CAU', 3, @kq2);
```
**[CỬA SỔ 1] / [CỬA SỔ 2]**
```sql
SELECT @kq1 AS MaLoi_CuaSo1, @kq2 AS MaLoi_CuaSo2;
-- MONG ĐỢI: một phiên = 1213 (ER_LOCK_DEADLOCK — bị InnoDB chọn làm nạn nhân & rollback)
--           phiên kia     = 0    (đi tiếp và COMMIT)
SELECT MaLHP, SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP IN ('LHP514','LHP506');
-- MONG ĐỢI: sĩ số KHÔNG đổi (chỉ khóa, không ghi) -> deadlock không làm sai dữ liệu
```

## B.2. **“TẮT”** cơ chế phòng chống để demo

### B.2.1. Cách chính thống — tắt hẳn bộ phát hiện deadlock *(cần quyền `SUPER`)*

```sql
-- [CỬA SỔ 1]
SET GLOBAL innodb_deadlock_detect = OFF;    -- (1) TẮT
CALL SP_Demo_KhoaTheoThuTu('SV030','LHP514,LHP506','THEO_YEU_CAU',3,@kq1);
-- [CỬA SỔ 2]
CALL SP_Demo_KhoaTheoThuTu('SV041','LHP506,LHP514','THEO_YEU_CAU',3,@kq2);
-- [CỬA SỔ 1]  ⚠️ BẬT LẠI NGAY (biến GLOBAL ảnh hưởng toàn server)
SET GLOBAL innodb_deadlock_detect = ON;
```
> **KHI TẮT (OFF):** không còn `1213`. Cả 2 phiên **TREO** tới hết `innodb_lock_wait_timeout`
> (mặc định **50 giây**) rồi nhận **`1205 ER_LOCK_WAIT_TIMEOUT`** — đúng hình ảnh
> **“bị deadlock, không thao tác được gì nữa”**.
>
> ❗ **Minh chứng trên hosting của nhóm** (tài khoản `roacqgfa_dbms`):
> ```
> SET GLOBAL innodb_deadlock_detect = OFF;
> ERROR 1227 (42000): Access denied; you need (at least one of) the SUPER privilege(s) for this operation
> ```
> ⇒ Không tắt được ⇒ dùng **phương án thay thế B.2.2** để vẫn demo đúng hiện tượng treo.

### B.2.2. Phương án thay thế — deadlock **ngoài tầm phát hiện** của InnoDB (khóa DÒNG ↔ khóa ỨNG DỤNG)

**[CỬA SỔ 1]**
```sql
SET SESSION innodb_lock_wait_timeout = 8;
START TRANSACTION;
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = 'LHP514' FOR UPDATE;   -- giữ KHÓA DÒNG
-- ⏸ dừng lại, sang cửa sổ 2
```
**[CỬA SỔ 2]**
```sql
SELECT GET_LOCK('khoa_ung_dung_deadlock', 0) AS DaGiuKhoaUngDung;       -- giữ KHÓA ỨNG DỤNG
START TRANSACTION;
-- ⏸ dừng lại, quay về cửa sổ 1
```
**[CỬA SỔ 1]**
```sql
SELECT GET_LOCK('khoa_ung_dung_deadlock', 8) AS KetQua;                 -- ⏳ TREO
```
**[CỬA SỔ 2]**
```sql
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = 'LHP514' FOR UPDATE;   -- ⏳ TREO
```
**[CỬA SỔ 3 — hoặc mở thêm 1 cửa sổ]** quan sát
```sql
SHOW FULL PROCESSLIST;
-- MONG ĐỢI: 1 dòng STATE = 'User lock'  (chờ GET_LOCK)
--           1 dòng STATE = 'statistics' (chờ khóa dòng InnoDB)
```
> **KẾT QUẢ SAU ~8 GIÂY:** cửa sổ 1 `GET_LOCK` trả **0**; cửa sổ 2 nhận **ERROR 1205**.
> **KHÔNG ai bị rollback tự động** — vì đồ thị chờ của InnoDB chỉ thấy một nửa vòng tròn,
> bộ phận quản lý khóa ứng dụng chỉ thấy nửa còn lại ⇒ **không detector nào cứu được**.

**[CỬA SỔ 2]** rồi **[CỬA SỔ 1]** dọn khóa
```sql
ROLLBACK;
ROLLBACK;
SELECT RELEASE_ALL_LOCKS();
```

### B.2.3. Phương án thay thế 2 — khóa mức BẢNG (`LOCK TABLES`) + DML

```sql
-- [CỬA SỔ 1]
SET SESSION lock_wait_timeout = 8;
LOCK TABLES LOPHOCPHAN WRITE;
SET SESSION innodb_lock_wait_timeout = 8;
-- [CỬA SỔ 2]
SET SESSION lock_wait_timeout = 8;
SELECT * FROM LOPHOCPHAN WHERE MaLHP='LHP514';    -- ⏳ treo: chờ metadata lock của bảng
-- [CỬA SỔ 1]
SELECT dk.TrangThaiDangKy FROM DANGKYHOCPHAN dk
 JOIN LOPHOCPHAN lhp ON lhp.MaLHP = dk.MaLHP
 WHERE dk.MaSV='SV030' AND dk.MaLHP='LHP514' FOR UPDATE;   -- ⏳ treo tiếp
-- [CỬA SỔ 1] dọn dẹp
UNLOCK TABLES;
```

## B.3. **Bật lại / dùng cách khác** để phòng chống

### B.3.1. Bật lại cơ chế mặc định (nếu đã tắt ở B.2.1)
```sql
SET GLOBAL innodb_deadlock_detect = ON;
SELECT @@innodb_deadlock_detect;     -- -> ON
```

### B.3.2. ⭐ Cách phòng chống CHÍNH — khóa theo **thứ tự nhất quán** (`SAP_XEP`)

**[CỬA SỔ 1]**
```sql
CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506');
SET SESSION innodb_lock_wait_timeout = 20;
CALL SP_Demo_KhoaTheoThuTu('SV030', 'LHP514,LHP506', 'SAP_XEP', 3, @kq1);
```
**[CỬA SỔ 2]** *(chạy trong lúc cửa sổ 1 đang ngủ 3 giây)*
```sql
SET SESSION innodb_lock_wait_timeout = 20;
CALL SP_Demo_KhoaTheoThuTu('SV041', 'LHP506,LHP514', 'SAP_XEP', 3, @kq2);
```
**[CỬA SỔ 1] / [CỬA SỔ 2]**
```sql
SELECT @kq1 AS CuaSo1, @kq2 AS CuaSo2;
-- MONG ĐỢI: 0 và 0 — KHÔNG có 1213.
-- Vì CON TRỎ đã tự sắp MaLHP TĂNG DẦN cho mọi phiên ⇒ không thể hình thành chu trình chờ.
-- Đây chính là cách SP_DangKyNhieuHocPhan (bản đã fix) đang làm.
```

### B.3.3. Cách phòng chống bổ sung — bọc thời gian chờ khóa
```sql
SET SESSION innodb_lock_wait_timeout = 5;    -- thay vì treo 50 giây, báo 1205 sau 5 giây
SELECT @@innodb_lock_wait_timeout;
```

### B.3.4. Xử lý khi vẫn xảy ra deadlock — bắt `1213` + RETRY
`SP_DangKyHocPhan` đã có vòng `REPEAT … UNTIL` tự **thử lại tối đa 2 lần** khi `pKetQua = 1213`
(xem `mysql/procedures/SP_DangKyHocPhan.sql`, phần “VÒNG RETRY KHI DEADLOCK”).

## B.4. **LỖI THẬT** của hệ thống — đảo thứ tự khóa ĐĂNG KÝ ↔ HỦY

**[CỬA SỔ 1]**
```sql
CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506');
SET SESSION innodb_lock_wait_timeout = 20;
CALL SP_Demo_PhienGiaoDich('DANG_KY_CHUA_FIX', 'SV030', 'LHP514', 3, @kq1);
```
**[CỬA SỔ 2]**
```sql
SET SESSION innodb_lock_wait_timeout = 20;
CALL SP_Demo_PhienGiaoDich('HUY_CHUA_FIX', 'SV030', 'LHP514', 3, @kq2);
```
**[CỬA SỔ 1] / [CỬA SỔ 2]**
```sql
SELECT @kq1 AS MaLoi_DangKy, @kq2 AS MaLoi_Huy;
-- MONG ĐỢI: một phiên = 1213 (bị rollback), phiên kia = 0 hoặc 202
-- ⇒ deadlock sinh ra từ CHÍNH nghiệp vụ đăng ký/hủy của hệ thống, không phải ví dụ nhân tạo.
```

**Chạy lại với bản ĐÃ FIX (cùng thứ tự khóa):**
```sql
-- [CỬA SỔ 1]
CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506');
CALL SP_Demo_PhienGiaoDich('DANG_KY_DA_FIX', 'SV030', 'LHP514', 3, @kq1);
-- [CỬA SỔ 2]
CALL SP_Demo_PhienGiaoDich('HUY_DA_FIX', 'SV030', 'LHP514', 3, @kq2);
-- [CỬA SỔ 1]/[CỬA SỔ 2]
SELECT @kq1 AS CuaSo1_DaFix, @kq2 AS CuaSo2_DaFix;
-- MONG ĐỢI: 0 và 0 (hoặc 202 nghiệp vụ) — KHÔNG còn 1213.
-- Bản đã fix nằm ở: mysql/procedures/SP_HuyDangKy.sql (khóa LOPHOCPHAN TRƯỚC).
```

---

# PHẦN C — DEMO DEADLOCK BẰNG **THAO TÁC THẬT TRÊN WEB** (vẫn chỉ đổi ở DB)

> Ứng dụng **không có màn hình demo**. Lỗi được tạo ra bằng cách **triển khai phiên bản stored procedure
> có lỗi** rồi để sinh viên thao tác bình thường trên trang *Đăng ký lớp học phần*.

**[CỬA SỔ 1]** chuẩn bị dữ liệu
```sql
CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506');
```
**Triển khai bản CÓ LỖI** (khóa theo đúng thứ tự sinh viên tick chọn):
```bash
cd backend && node scripts/apply-sql.js ../mysql/transactions/demo_deadlock_chuafix.sql
```
**Thao tác trên web (2 trình duyệt):**
1. Browser A: `sv030 / matkhau@123` → **Đăng ký lớp học phần**; Browser B: `sv041 / matkhau@123` → cùng trang.
2. A tick **LHP514 rồi LHP506**; B tick **LHP506 rồi LHP514** *(cố ý ngược)*.
3. Hô “3 – 2 – 1 – ĐĂNG KÝ”, cả hai bấm **“Đăng ký 2 lớp đã chọn”** gần như cùng lúc.
4. **MONG ĐỢI:** một SV nhận toast đỏ **“Xung đột khóa (deadlock 1213)…”** + dải *“Giao dịch bị hủy (mã 1213)”*.

**Khôi phục bản ĐÃ FIX** rồi làm lại y hệt (giao diện không đổi gì):
```bash
node scripts/apply-sql.js ../mysql/procedures/SP_DangKyNhieuHocPhan.sql
```
> **MONG ĐỢI:** không còn `1213`; chỉ còn lỗi nghiệp vụ bình thường (ví dụ `102` — chưa hoàn thành môn tiên quyết).

---

# PHẦN D — DỌN DẸP CUỐI BUỔI

```sql
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');
CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506');
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT RELEASE_ALL_LOCKS();
SELECT MaLHP, SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP IN ('LHP514','LHP506');
```
```bash
# Đảm bảo đã khôi phục bản đã fix (nếu vừa chạy PHẦN C)
cd backend && node scripts/apply-sql.js ../mysql/procedures/SP_DangKyNhieuHocPhan.sql
```

---

## PHỤ LỤC — BẢNG TÓM TẮT (in 1 trang mang theo)

| # | Lỗi | Cách "tắt phòng chống" | Kết quả phải thấy |
|---|---|---|---|
| A.1 | Lost Update | dùng `SP_DangKyHocPhan_ChuaFix` (không `FOR UPDATE`) | số ĐK **17 > 16**, bộ đếm kẹt 16 |
| A.2 | Dirty Read | `SET SESSION … READ UNCOMMITTED` | đọc **16** khi chưa commit, sau rollback còn **15** |
| A.3 | Unrepeatable Read | `SET SESSION … READ COMMITTED` | cùng giao tác: **15 rồi 16** |
| A.4 | Phantom Read | `SET SESSION … READ COMMITTED` | COUNT **15 rồi 16** |
| A.5 | Phòng chống | *(không tắt)* | 1 phiên **0**, 1 phiên **105**; sĩ số không vượt |
| B.1 | Deadlock (mặc định) | *(không tắt)* | 1 phiên **1213**, phiên kia **0** |
| B.2.1 | Deadlock **TREO** | `SET GLOBAL innodb_deadlock_detect = OFF` *(hosting chặn 1227)* | cả 2 treo → **1205** sau timeout |
| B.2.2 | Deadlock **TREO** (thay thế) | vòng tròn **khóa dòng ↔ `GET_LOCK`** | cả 2 treo; PROCESSLIST: `User lock` / `statistics` |
| B.3.2 | Ngăn ngừa | `SAP_XEP` (con trỏ sắp `MaLHP` tăng dần) | **0 và 0** — không có 1213 |
| B.3.3 | Ngăn ngừa bổ sung | `SET SESSION innodb_lock_wait_timeout = 5` | treo có hạn, báo 1205 sau 5 giây |
| B.3.4 | Xử lý | bắt `1213` + RETRY | giao dịch thành công sau khi thử lại |
| B.4 | **Lỗi thật** | `DANG_KY_CHUA_FIX` vs `HUY_CHUA_FIX` | một phiên **1213** |
| C | Góc độ người dùng | triển khai `demo_deadlock_chuafix.sql` | 2 SV tick ngược thứ tự ⇒ **toast deadlock 1213**; khôi phục bản fix ⇒ hết |
