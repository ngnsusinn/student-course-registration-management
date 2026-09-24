# CẤU HÌNH SQL & FIX CHO TỪNG LỖI DEMO — REFERENCE

> **Mục đích:** Tài liệu tham khảo nhanh — cấu hình SQL cần thiết để demo từng lỗi, và những gì cần fix khi khắc phục.
> **Ngày tạo:** Dựa trên trạng thái repo hiện tại.
> **Status:** Tất cả thủ tục trong `mysql/procedures/` đã FIX sẵn. Các file demo trong `mysql/transactions/` và `demo/sql_config/` giữ nguyên bản lỗi để phục vụ demo.

---

## BẢNG TÓNG TẮT

| # | Lỗi Demo | Cần "TẮT"/Cấu hình để Demo | File demo (bản lỗi) | Fix ở đâu | Fix cái gì |
|---|----------|---------------------------|---------------------|-----------|------------|
| 1 | **Lost Update** | `SP_DangKyHocPhan_ChuaFix` (thiếu `FOR UPDATE`) | `mysql/transactions/demo_4_anomaly.sql` | `mysql/procedures/SP_DangKyHocPhan.sql` + `demo/sql_config/lost_update__da_fix.sql` | Thêm `SELECT ... FOR UPDATE` ở Bước 6 |
| 2 | **Dirty Read** | `SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED` | (dùng SP demo trong `demo_4_anomaly.sql`) | `SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ` (phục hồi mặc định) | Không sửa code, chỉ restore isolation level |
| 3 | **Unrepeatable Read** | `SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED` | (dùng SP demo trong `demo_4_anomaly.sql`) | `SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ` (phục hồi mặc định) | Không sửa code, chỉ restore isolation level |
| 4 | **Phantom Read** | `SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED` | (dùng SP demo trong `demo_4_anomaly.sql`) | `SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ` (phục hồi mặc định) | Không sửa code, chỉ restore isolation level |
| 5 | **Deadlock — HQTCSDL xử lý** | `innodb_deadlock_detect = ON` (mặc định) | `mysql/transactions/demo_deadlock.sql` (SP_Demo_KhoaTheoThuTu, khóa ngược thứ tự) | `SP_Demo_KhoaThuTu` với `SAP_XEP` (con trỏ sắp MaLHP tăng dần) | Thứ tự khóa nhất quán |
| 6 | **Deadlock — TREO (không phát hiện)** | `SET GLOBAL innodb_deadlock_detect = OFF` *(hosting chặn 1227 → dùng vòng tròn GET_LOCK ↔ row lock)* | (demo thay thế trong `deadlock_demo.md` mục 3.4) | `SET GLOBAL innodb_deadlock_detect = ON` *(nếu có quyền SUPER)* | Bật lại bộ phát hiện |
| 7 | **Deadlock — Lỗi thật: đảo thứ tự khóa** | `SP_HuyDangKy` bản cũ (khóa DANGKYHOCPHAN → LOPHOCPHAN, ngược với SP_DangKyHocPhan) | `mysql/transactions/demo_deadlock.sql` (SP_Demo_PhienGiaoDich, vai `HUY_CHUA_FIX`) | `mysql/procedures/SP_HuyDangKy.sql` (đã FIX) | Đảo lại: khóa LOPHOCPHAN TRƯỚC |
| 8 | **Deadlock — Góc người dùng** | Triển khai `demo_deadlock_chuafix.sql` (con trỏ khóa theo thứ tự tick chọn) | `mysql/transactions/demo_deadlock_chuafix.sql` | `mysql/procedures/SP_DangKyNhieuHocPhan.sql` (đã FIX) | `KhoaThuTu = CONCAT('A', MaLHP)` thay vì `CONCAT('B', LPAD(ThuTu,...))` |

---

## PHÂN TÍCH CHI TIẾT TỪNG LỖI

---

### 1. LOST UPDATE — "17 SV vào lớp 16 chỗ"

#### Cấu hình để Demo

| Yếu tố | Giá trị |
|---------|---------|
| **Thủ tục** | `SP_DangKyHocPhan_ChuaFix` (trong `mysql/transactions/demo_4_anomaly.sql`) |
| **Điểm khác biệt so với bản FIX** | **BUỘC 6:** Đọc sĩ số bằng `SELECT` **thường** (không khóa) thay vì `SELECT ... FOR UPDATE` |
| **Isolation level** | Mặc định `REPEATABLE-READ` (không cần đổi) |
| **Cách chạy** | 2 cửa sổ MySQL, cùng lúc bấm đăng ký suất cuối |
| **Dọn dẹp** | `CALL SP_ChuanBi_Demo_4Anomaly('LHP514');` |

#### Fix

| Nơi | Nội dung fix |
|-----|-------------|
| **`mysql/procedures/SP_DangKyHocPhan.sql`** | Bước 6: Thêm `FOR UPDATE` vào câu `SELECT` đọc sĩ số |
| **`demo/sql_config/lost_update__da_fix.sql`** | Bản đã fix hoàn chỉnh: `FOR UPDATE` + retry 1213 + xử lý `DA_HUY` |
| **Cụ thể dòng nào** | Dòng 164-168: `SELECT SiSoHienTai, SiSoToiDa INTO ... FROM LOPHOCPHAN WHERE MaLHP = pMaLHP FOR UPDATE;` |
| **Cơ chế** | `FOR UPDATE` giữ X-lock dòng sĩ số tới COMMIT → phiên sau phải chờ → đọc giá trị mới → nhận 105 (lớp đầy) |

**Code so sánh:**

```sql
-- ❌ BẢN CHƯA FIX (demo_4_anomaly.sql, dòng 94-97):
SELECT SiSoHienTai, SiSoToiDa
INTO vSiSoHienTai, vSiSoToiDa
FROM LOPHOCPHAN
WHERE MaLHP = pMaLHP;      -- ← KHÔNG FOR UPDATE → 2 phiên đọc cùng 1 giá trị

-- ✅ BẢN ĐÃ FIX (mysql/procedures/SP_DangKyHocPhan.sql, dòng 164-168):
SELECT SiSoHienTai, SiSoToiDa
INTO vSiSoHienTai, vSiSoToiDa
FROM LOPHOCPHAN
WHERE MaLHP = pMaLHP
FOR UPDATE;                -- ← X-lock giữ tới COMMIT → phiên sau chờ, đọc giá trị mới
```

**Thêm:** Bản fix còn có vòng `REPEAT ... UNTIL` retry khi gặp `1213` (dòng 214-222) — xử lý trường hợp 2 phiên tranh khóa cùng thứ tự.

---

### 2. DIRTY READ — "Đọc dữ liệu chưa tồn tại"

#### Cấu hình để Demo

| Yếu tố | Giá trị |
|---------|---------|
| **Cách tắt phòng chống** | `SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;` |
| **Isolation level mặc định của MySQL** | `REPEATABLE-READ` (chặn Dirty Read qua MVCC snapshot) |
| **Cần đổi gì** | Hạ từ `REPEATABLE-READ` xuống `READ UNCOMMITTED` |
| **Phiên ghi** | Cập nhật nhưng **KHÔNG COMMIT** (giữ ở trạng thái chưa commit) |
| **Dọn dẹp** | `SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;` |

#### Fix

| Nơi | Nội dung |
|-----|----------|
| **Không cần sửa code** | Đây là cách demo bằng cách thay đổi session-level config |
| **Khôi phục** | `SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;` |
| **Cơ chế MySQL mặc định** | MVCC: phiên đọc chỉ thấy bản snapshot đã commit (undo log). Không đọc dữ liệu chưa commit. |

**Script demo (2 cửa sổ):**

```sql
-- CỬA SỔ A (tắt phòng chống):
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
START TRANSACTION;
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514';  -- thấy 15

-- CỬA SỔ B (ghi chưa commit):
START TRANSACTION;
UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP='LHP514';
-- (chưa COMMIT)

-- CỬA SỔ A đọc lại:
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514';  -- THẤY 16 (ĐỌC BẨN!)

-- CỬA SỔ B rollback:
ROLLBACK;

-- CỬA SỔ A đọc lại:
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514';  -- VỀ LẠI 15

-- KHỞI PHỤC:
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
```

---

### 3. UNREPEATABLE READ — "Cùng 1 giao tác, 2 kết quả khác nhau"

#### Cấu hình để Demo

| Yếu tố | Giá trị |
|---------|---------|
| **Cách tắt phòng chống** | `SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;` |
| **Isolation level mặc định** | `REPEATABLE-READ` (snapshot giữ nguyên toàn giao dịch → chặn) |
| **Cần đổi gì** | Hạ từ `REPEATABLE-READ` xuống `READ COMMITTED` |
| **Cơ chế gây lỗi** | READ COMMITTED tạo snapshot mới sau mỗi SELECT → phiên khác kịp UPDATE + COMMIT giữa 2 lần đọc |
| **Dọn dẹp** | `SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;` |

#### Fix

| Nơi | Nội dung |
|-----|----------|
| **Không cần sửa code** | Demo bằng cách thay đổi isolation level |
| **Khôi phục** | `SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;` |
| **Cơ chế MySQL mặc định** | REPEATABLE-READ giữ snapshot nhất quán từ lần đọc đầu → đọc lại vẫn ra giá trị cũ |

**Script demo:**

```sql
-- CỬA SỔ A:
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514';  -- lần 1: 15

-- CỬA SỔ B:
UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP='LHP514';
COMMIT;  -- commit giữa 2 lần đọc

-- CỬA SỔ A đọc lại (cùng giao tác):
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514';  -- lần 2: 16 ❌ (KHÁC lần 1!)
COMMIT;

-- KHỞI PHỤC:
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
```

---

### 4. PHANTOM READ — "Dòng bóng ma xuất hiện"

#### Cấu hình để Demo

| Yếu tố | Giá trị |
|---------|---------|
| **Cách tắt phòng chống** | `SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;` |
| **Isolation level mặc định** | `REPEATABLE-READ` (consistent snapshot + next-key/gap lock chặn INSERT vào vùng đã khóa) |
| **Cần đổi gì** | Hạ từ `REPEATABLE-READ` xuống `READ COMMITTED` |
| **Cơ chế gây lỗi** | Snapshot đổi sau mỗi SELECT → thấy thêm dòng mới do người khác INSERT |
| **Dọn dẹp** | `CALL SP_ChuanBi_Demo_4Anomaly('LHP514');` |

#### Fix

| Nơi | Nội dung |
|-----|----------|
| **Không cần sửa code** | Demo bằng cách thay đổi isolation level |
| **Khôi phục** | `SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;` |
| **Cơ chế MySQL mặc định** | REPEATABLE-READ: consistent snapshot giữ nguyên + InnoDB next-key lock chặn INSERT vào vùng đã đọc |

**Script demo:**

```sql
-- CỬA SỔ A:
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
SELECT COUNT(*) FROM DANGKYHOCPHAN WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';  -- lần 1: 15

-- CỬA SỔ B:
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
VALUES ('SV999','LHP514',NOW(),'DA_DANG_KY','bong ma');
COMMIT;

-- CỬA SỔ A đếm lại:
SELECT COUNT(*) FROM DANGKYHOCPHAN WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';  -- lần 2: 16 ❌
COMMIT;

-- KHỞI PHỤC:
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');
```

---

### 5. DEADLOCK — HQTCSDL TỰ XỬ LÝ (InnoDB phát hiện & rollback)

#### Cấu hình để Demo

| Yếu tố | Giá trị |
|---------|---------|
| **Cơ chế** | `innodb_deadlock_detect = ON` (MẶC ĐỊNH) — KHÔNG cần tắt gì |
| **Demo bằng** | `SP_Demo_KhoaTheoThuTu('SV030','LHP514,LHP506','THEO_YEU_CAU',3,@kq1)` và `... 'SV041','LHP506,LHP514','THEO_YEU_CAU',3,@kq2)` |
| **Khóa theo** | `THEO_YEU_CAU` = theo thứ tự người dùng gửi (ngược nhau giữa 2 phiên) |
| **Kết quả mong đợi** | 1 phiên `1213` (nạn nhân), phiên kia `0` |
| **Chờ demo** | `pDoTreGiay = 3` (giữ khóa 3 giây để 2 phiên chồng thời gian) |

#### Fix

| Nơi | Nội dung |
|-----|----------|
| **Phòng chống** | Dùng `SAP_XEP` thay vì `THEO_YEU_CAU`: con trỏ tự sắp `MaLHP` tăng dần |
| **Nguyên tắc** | Mọi giao dịch khóa theo CÙNG một thứ tự → không thể có chu trình chờ → KHÔNG deadlock |
| **Code** | `CALL SP_Demo_KhoaTheoThuTu('SV030','LHP514,LHP506','SAP_XEP',3,@kq1);` → cả 2 phiên đều `0` |

**So sánh thứ tự khóa:**

```sql
-- ❌ THEO_YEU_CAU (gây deadlock):
INSERT INTO TAM_DEMO_LHP (ThuTu, MaLHP, KhoaThuTu)
VALUES (1, 'LHP514', CONCAT('B', LPAD(1, 6, '0')));  -- B000001
INSERT INTO TAM_DEMO_LHP (ThuTu, MaLHP, KhoaThuTu)
VALUES (2, 'LHP506', CONCAT('B', LPAD(2, 6, '0')));  -- B000002
-- Con trỏ duyệt: LHP514 → LHP506 (theo thứ tự tick)

-- ✅ SAP_XEP (phòng chống):
INSERT INTO TAM_DEMO_LHP (ThuTu, MaLHP, KhoaThuTu)
VALUES (1, 'LHP514', CONCAT('A', 'LHP514'));  -- ALHP514
INSERT INTO TAM_DEMO_LHP (ThuTu, MaLHP, KhoaThuTu)
VALUES (2, 'LHP506', CONCAT('A', 'LHP506'));  -- ALHP506
-- Con trỏ duyệt: LHP506 → LHP514 (theo MaLHP tăng dần) → cùng thứ tự với cả 2 phiên
```

---

### 6. DEADLOCK — TREO (không phát hiện được)

#### Cấu hình để Demo

| Yếu tố | Giá trị |
|---------|---------|
| **Cách chính thống** | `SET GLOBAL innodb_deadlock_detect = OFF;` *(nhưng cần quyền SUPER)* |
| **Trên hosting chia sẻ** | ❌ Bị **ERROR 1227** — KHÔNG tắt được |
| **Phương án thay thế** | Tạo vòng tròn **khóa DÒNG InnoDB ↔ khóa ỨNG DỤNG `GET_LOCK`** — không bộ phận nào thấy đủ chu trình |
| **Kết quả** | Cả 2 phiên TREO (không ai rollback, không ai thông báo lỗi) |
| **Bọc timeout** | `SET SESSION innodb_lock_wait_timeout = 8;` (để không treo 50s) |
| **Khôi phục** | `SET GLOBAL innodb_deadlock_detect = ON;` *(bắt buộc nếu có quyền)* |

#### Fix

| Nơi | Nội dung |
|-----|----------|
| **Khôi phục bộ phát hiện** | `SET GLOBAL innodb_deadlock_detect = ON;` |
| **Phòng chống vĩnh viễn** | Không dùng khóa ứng dụng (`GET_LOCK`) chồng lên khóa dòng InnoDB. Nếu buộc phải dùng → đặt tên khóa theo thứ tự và timeout ngắn |

---

### 7. DEADLOCK — LỖI THẬT: Đảo thứ tự khóa ĐĂNG KÝ ↔ HỦY ⭐

#### Cấu hình để Demo

| Yếu tố | Giá trị |
|---------|---------|
| **Nguồn lỗi** | `SP_HuyDangKy` bản cũ: khóa `DANGKYHOCPHAN` trước → trigger cập nhật `LOPHOCPHAN` sau. Trong khi `SP_DangKyHocPhan` khóa `LOPHOCPHAN` trước → ghi `DANGKYHOCPHAN` sau. **HAI THỨ TỰ NGƯỢC NHAU.** |
| **Kích hoạt** | SV030 đăng ký lại lớp đã hủy (dùng `DA_HUY`) + 1 phiên khác hủy lớp đó cùng lúc |
| **Demo bằng** | `SP_Demo_PhienGiaoDich('DANG_KY_CHUA_FIX',...)` + `SP_Demo_PhienGiaoDich('HUY_CHUA_FIX',...)` (chạy đồng thời 2 cửa sổ) |
| **Kết quả** | 1 phiên `1213` (deadlock), phiên kia lỗi nghiệp vụ `202` |

#### Fix — ĐÃ ÁP DỤNG

| Nơi | Nội dung fix |
|-----|-------------|
| **File** | `mysql/procedures/SP_HuyDangKy.sql` |
| **Thay đổi** | Bước 2: Đảo ngược thứ tự — khóa `LOPHOCPHAN` TRƯỚC (`FOR UPDATE`), rồi mới đọc `DANGKYHOCPHAN` (`FOR UPDATE`) |
| **Cụ thể** | Dòng 68-71: `SELECT ... FROM LOPHOCPHAN WHERE MaLHP = pMaLHP FOR UPDATE;` **(TRƯỚC)** → Dòng 75-78: `SELECT ... FROM DANGKYHOCPHAN ... FOR UPDATE;` **(SAU)** |
| **Kết quả** | Cả 2 thủ tục cùng khóa theo thứ tự `LOPHOCPHAN → DANGKYHOCPHAN` → không chu trình → KHÔNG deadlock |
| **Bản demo cũ** | Được giữ lại trong `SP_Demo_PhienGiaoDich('HUY_CHUA_FIX',...)` để demo lỗi |

**So sánh thứ tự khóa:**

```sql
-- ❌ BẢN CŨ (SP_HuyDangKy cũ):
-- Bước 1: SELECT ... FROM DANGKYHOCPHAN dk JOIN LOPHOCPHAN lhp ... FOR UPDATE;  ← DANGKYHOCPHAN TRƯỚC
-- Bước 2: UPDATE DANGKYHOCPHAN ... → trigger → UPDATE LOPHOCPHAN ...           ← LOPHOCPHAN SAU
-- Thứ tự: DANGKYHOCPHAN → LOPHOCPHAN

-- ✅ BẢN MỚI (SP_HuyDangKy hiện tại):
-- Bước 1: SELECT SiSoHienTai... FROM LOPHOCPHAN WHERE MaLHP = ? FOR UPDATE;    ← LOPHOCPHAN TRƯỚC ✅
-- Bước 2: SELECT ... FROM DANGKYHOCPHAN WHERE ... FOR UPDATE;                    ← DANGKYHOCPHAN SAU
-- Thứ tự: LOPHOCPHAN → DANGKYHOCPHAN (CÙNG thứ tự với SP_DangKyHocPhan)
```

---

### 8. DEADLOCK — Góc độ người dùng (thao tác thật trên web)

#### Cấu hình để Demo

| Yếu tố | Giá trị |
|---------|---------|
| **Triển khai bản lỗi** | `cd backend && node scripts/apply-sql.js ../mysql/transactions/demo_deadlock_chuafix.sql` |
| **Con trỏ khóa sai thứ tự** | `KhoaThuTu = CONCAT('B', LPAD(vThuTu, 6, '0'))` — theo đúng thứ tự SV tick chọn |
| **Thao tác** | 2 trình duyệt (sv030/sv041), tick 2 lớp **ngược thứ tự**, bấm "Đăng ký N lớp đã chọn" cùng lúc |
| **Kết quả** | 1 SV thành công, 1 SV nhận toast: *"Xung đột khóa (deadlock 1213)…"* + dải *"Giao dịch bị hủy (mã 1213)"* |
| **Dọn dẹp** | `CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506');` |

#### Fix — ĐÃ ÁP DỤNG

| Nơi | Nội dung fix |
|-----|-------------|
| **File** | `mysql/procedures/SP_DangKyNhieuHocPhan.sql` |
| **Thay đổi** | Dòng 95: `CONCAT('A', vItem)` thay vì `CONCAT('B', LPAD(vThuTu, 6, '0'))` |
| **Hiệu quả** | Con trỏ luôn duyệt theo `MaLHP` tăng dần → mọi giao dịch khóa cùng thứ tự → KHÔNG thể có chu trình chờ |
| **Khôi phục bản đã fix** | `cd backend && node scripts/apply-sql.js ../mysql/procedures/SP_DangKyNhieuHocPhan.sql` |
| **Giao diện** | KHÔNG đổi — chỉ thay phiên bản SP trong DB |

**So sánh thứ tự khóa trong con trỏ:**

```sql
-- ❌ BẢN CHƯA FIX (demo_deadlock_chuafix.sql, dòng 94):
INSERT IGNORE INTO TAM_DK_NHIEU (ThuTu, MaLHP, KhoaThuTu)
VALUES (vThuTu, vItem, CONCAT('B', LPAD(vThuTu, 6, '0')));
-- Con trỏ: ORDER BY KhoaThuTu = B000001, B000002... → theo thứ tự tick → GÂY DEADLOCK

-- ✅ BẢN ĐÃ FIX (mysql/procedures/SP_DangKyNhieuHocPhan.sql, dòng 95):
INSERT IGNORE INTO TAM_DK_NHIEU (ThuTu, MaLHP, KhoaThuTu)
VALUES (vThuTu, vItem, CONCAT('A', vItem));
-- Con trỏ: ORDER BY KhoaThuTu = ALHP506, ALHP514... → theo MaLHP tăng dần → KHÔNG DEADLOCK
```

---

## TÓNG TẮT CÁC FILE ĐÃ FIX vs CÒN LỖI

### ✅ ĐÃ FIX (sản phẩm thực tế — không nên sửa)

| File | Content |
|------|---------|
| `mysql/procedures/SP_DangKyHocPhan.sql` | FOR UPDATE ở Bước 6 + retry 1213 |
| `mysql/procedures/SP_DangKyHocPhan.sql` (trùng) | `demo/sql_config/lost_update__da_fix.sql` — bản tương đương |
| `mysql/procedures/SP_HuyDangKy.sql` | Khóa LOPHOCPHAN TRƯỚC (cùng thứ tự với DangKyHocPhan) |
| `mysql/procedures/SP_DangKyNhieuHocPhan.sql` | Con trỏ `CONCAT('A', MaLHP)` — nhất quán |

### ⚠️ CÒN LỖI (giữ nguyên để demo — KHÔNG nên fix)

| File | Content |
|------|---------|
| `mysql/transactions/demo_4_anomaly.sql` | `SP_DangKyHocPhan_ChuaFix` (thiếu FOR UPDATE) — demo Lost Update |
| `mysql/transactions/demo_deadlock_chuafix.sql` | Con trỏ `CONCAT('B',...)` — demo deadlock web |
| `mysql/transactions/demo_deadlock.sql` | Các SP demo (khóa ngược thứ tự, hủy chưa fix) |

---

## CÁC ISOLATION LEVEL — TÓNG TẮT

| Isolation Level | Dirty Read | Unrepeatable Read | Phantom Read | Lost Update | Cần đặt để demo |
|---|---|---|---|---|---|
| `READ UNCOMMITTED` | ⚠️ **Có** | Có | Có | Có | **Dirty Read** |
| `READ COMMITTED` | Không | **Có** | **Có** | Có | **Unrepeatable + Phantom** |
| `REPEATABLE READ` *(mặc định)* | Không | Không | Có* | Có* | Mặc định (chặn 3/4) |
| `SERIALIZABLE` | Không | Không | Không | Không | — |

\* MySQL 5.7 REPEATABLE-READ chặn Phantom với SELECT thường nhờ consistent snapshot + next-key lock.

**Cách đặt/tắt:**

```sql
-- Tắt cho Dirty Read:
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

-- Tắt cho Unrepeatable + Phantom:
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Khôi phục (sau mọi demo):
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Xem hiện tại:
SELECT @@session.transaction_isolation;
SELECT @@global.transaction_isolation;
```

> ⚠️ `SET SESSION` chỉ ảnh hưởng phiên hiện tại — an toàn cho demo.
> `SET GLOBAL` ảnh hưởng TOÀN SERVER — chỉ dùng khi có quyền SUPER và BẬT LẠI NGAY sau demo.

---

## THỨ TỰ FIX KHI KHẮC PHỤC

Khi hệ thống demo lỗi và cần fix, thứ tự xử lý:

1. **Lost Update** → Thêm `SELECT ... FOR UPDATE` vào bước đọc dữ liệu kiểm tra (Bước 6 trong SP_DangKyHocPhan)
2. **Dirty/Unrepeatable/Phantom** → Khôi phục `REPEATABLE-READ` (không cần sửa code)
3. **Deadlock do thứ tự khóa** → Sắp xếp con trỏ/liệt kê theo thứ tự nhất quán (`MaLHP` tăng dần)
4. **Deadlock do đảo thứ tự giữa 2 SP** → Đảm bảo cả 2 SP cùng khóa theo cùng thứ tự (LOPHOCPHAN trước)
5. **Deadlock ngoài tầm phát hiện** → Không dùng khóa ứng dụng chồng khóa dòng; nếu có thì đặt tên theo thứ tự
6. **Deadlock ngẫu nhiên** (không phòng được) → Bắt 1213 + RETRY + thông báo rõ ràng cho người dùng

---

## COMMAND REFERENCE

```bash
# Áp bản đã fix (sau khi demo xong):
cd backend
node scripts/apply-sql.js ../mysql/procedures/SP_DangKyHocPhan.sql
node scripts/apply-sql.js ../mysql/procedures/SP_HuyDangKy.sql
node scripts/apply-sql.js ../mysql/procedures/SP_DangKyNhieuHocPhan.sql

# Áp bản lỗi (để demo):
cd backend
node scripts/apply-sql.js ../mysql/transactions/demo_deadlock_chuafix.sql

# Dọn dẹp demo Lost Update:
# (trong MySQL client)
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');

# Dọn dẹp demo Deadlock:
# (trong MySQL client)
CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506');

# Khôi phục isolation level:
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

# Xem cấu hình hiện tại:
SELECT @@version, @@innodb_deadlock_detect, @@innodb_lock_wait_timeout, @@transaction_isolation;
```
