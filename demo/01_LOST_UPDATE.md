# 1️⃣ LỖI MẤT DỮ LIỆU CẬP NHẬT (LOST UPDATE)

> **Chương 4, mục 4.1** · Ảnh cần lấy: **Hình 3**
> *"Minh chứng demo Lost Update (bảng kết quả 2 cửa sổ: bản chưa-fix vượt sĩ số, bản fix trả mã 105)"*

**Bản chất:** hai giao tác cùng **đọc – kiểm tra – rồi ghi** trên cùng một dữ liệu. Cả hai cùng thấy
điều kiện còn hợp lệ, cả hai cùng ghi ⇒ **kiểm tra của phiên trước mất hiệu lực**.
Trong hệ thống: hai sinh viên cùng giành **suất cuối cùng** của một lớp học phần.

---

## 🔧 CONFIG SQL — TÁI HIỆN vs KHẮC PHỤC

| | Config |
|---|---|
| ❌ **TÁI HIỆN** | Bước kiểm tra sĩ số đọc bằng **`SELECT` thường (KHÔNG khóa)** — file [`sql_config/lost_update__chua_fix.sql`](sql_config/lost_update__chua_fix.sql) |
| ✅ **KHẮC PHỤC** | Đọc sĩ số bằng **`SELECT … FOR UPDATE`** (X-lock giữ tới `COMMIT`) + **retry khi gặp `1213`** — file [`sql_config/lost_update__da_fix.sql`](sql_config/lost_update__da_fix.sql) |
| ▶️ **KỊCH BẢN 2 TAB CHẠY SẴN** | Gọi thủ tục bằng `CALL` (không gõ tay transaction) — file [`sql_config/lost_update__tab2phien__call_sp.sql`](sql_config/lost_update__tab2phien__call_sp.sql) |

**Đoạn khác biệt duy nhất giữa hai bản (bước 6 của thủ tục):**

```sql
-- ❌ BẢN CHƯA FIX — đọc không khóa
SELECT SiSoHienTai, SiSoToiDa INTO vSiSoHienTai, vSiSoToiDa
FROM LOPHOCPHAN WHERE MaLHP = pMaLHP;

-- ✅ BẢN ĐÃ FIX — khóa độc quyền dòng sĩ số, giữ tới COMMIT
SELECT SiSoHienTai, SiSoToiDa INTO vSiSoHienTai, vSiSoToiDa
FROM LOPHOCPHAN WHERE MaLHP = pMaLHP
FOR UPDATE;                                     -- ★ tương đương UPDLOCK + HOLDLOCK của SQL Server
```

---

# PHẦN A — DEMO BẰNG SQL (2 TAB) · **gọi thủ tục** trên LHP506

> 🎯 **Cách chính: mỗi tab chỉ 1 câu `CALL SP_DangKyHocPhan(...)`** — giao tác, 5 bước kiểm tra và
> `INSERT` đều nằm **bên trong thủ tục**, nên đây đúng là đường đi thật của ứng dụng (web cũng gọi SP này).
>
> **LHP506** = môn *Tiếng Anh chuyên ngành CNTT* (MH017), HK1-2025 — đang **0/1, còn đúng 1 chỗ**,
> **không có môn tiên quyết** nên SV030/SV041 đi được tới bước kiểm tra sĩ số.
> ⏱ Bản demo đang nạp có `DO SLEEP(8)` **sau `INSERT`, trước `COMMIT`** ⇒ chạy TAB 2 trong vòng ~8 giây
> sau TAB 1 là tái hiện được (không phải tự bấm `COMMIT` như cách gõ tay).
>
> 🧩 Muốn đúng con số **17/16** của báo cáo (LHP514 = *Kết cấu cao tầng*, 15/16) thì xem **A.3** —
> bản đó vẫn phải gõ tay vì thủ tục sẽ chặn ở bước tiên quyết (mã 102).

### A.0. Chuẩn bị (TAB 1)

```sql
CALL SP_ChuanBi_Demo_4Anomaly('LHP506');

SELECT MaLHP, SiSoHienTai, SiSoToiDa, (SiSoToiDa - SiSoHienTai) AS ConTrong
FROM LOPHOCPHAN WHERE MaLHP = 'LHP506';
-- MONG ĐỢI: LHP506 | 0 | 1 | 1
```

### A.1. Tái hiện lỗi — **gọi THỦ TỤC** (không gõ tay `START TRANSACTION`/`INSERT`)

> ✅ **Dùng lớp LHP506 cho phần này** (0/1 — còn đúng 1 chỗ, **không có môn tiên quyết**).
> Vì sao không dùng LHP514: `SP_DangKyHocPhan` kiểm tra **môn tiên quyết TRƯỚC** bước sĩ số —
> LHP514 (MH045) yêu cầu đạt MH033, SV030/SV041 đều **chưa đạt** ⇒ cả hai nhận **102**, không bao giờ
> tới được bước sĩ số. (Xem thêm PHẦN B.2.)
>
> 🎯 **Cả giao tác nằm BÊN TRONG thủ tục**: `START TRANSACTION` → 5 bước kiểm tra → `INSERT` → `COMMIT`.
> Người demo chỉ còn **1 câu `CALL`** cho mỗi tab — đúng đường đi thật của ứng dụng.
> ⏱ Cửa sổ tranh chấp do chính SP mở ra: bản demo đặt `DO SLEEP(8)` **sau `INSERT`, trước `COMMIT`**
> (xem [`sql_config/lost_update__chua_fix.sql`](sql_config/lost_update__chua_fix.sql)) ⇒ **chạy TAB 2 trong vòng ~8 giây**
> sau khi bấm chạy TAB 1. Câu lệnh đầy đủ: [`sql_config/lost_update__tab2phien__call_sp.sql`](sql_config/lost_update__tab2phien__call_sp.sql)

**🪟 [TAB 1] — phiên của SV030** (chạy TRƯỚC, rồi chuyển ngay sang TAB 2)

```sql
CALL SP_DangKyHocPhan('SV030', 'LHP506', 24, 'Phien A - chua fix', @kqA);
SELECT @kqA AS KetQua_Tab1;      -- → 0 : đăng ký thành công, đã lấy suất cuối
```

**🪟 [TAB 2] — phiên của SV041** (chạy SAU, vẫn trong lúc TAB 1 đang ngủ)

```sql
CALL SP_DangKyHocPhan('SV041', 'LHP506', 24, 'Phien B - chua fix', @kqB);
-- → ⏳ TREO: "Executing query..." — ĐANG CHỜ KHÓA dòng sĩ số của TAB 1
--   📸 CHỤP ẢNH NGAY LÚC NÀY
SELECT @kqB AS KetQua_Tab2;      -- → 0 : ❌ CŨNG thành công  =  LỖI (bản chưa fix)
```

> 💡 Hai tab **bắt buộc là 2 kết nối riêng** (2 Query tab của Workbench / 2 cửa sổ client).
> Dùng chung một kết nối thì câu thứ hai chỉ được gửi sau khi câu thứ nhất chạy xong ⇒ không bao giờ tái hiện được.

### A.2. Câu kiểm tra — bằng chứng vượt sĩ số 📸

```sql
SELECT COUNT(*) AS SoDK_ThucTe,
       (SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP506') AS BoDem_SiSo,
       (SELECT SiSoToiDa  FROM LOPHOCPHAN WHERE MaLHP='LHP506') AS SiSoToiDa
FROM DANGKYHOCPHAN
WHERE MaLHP='LHP506' AND TrangThaiDangKy='DA_DANG_KY';
```

**KẾT QUẢ ĐO THẬT (2 phiên `CALL`, lệch nhau 1 giây — đo trên máy đang chạy web):**

| Phiên | Thời điểm xong | `pKetQua` |
|---|---|---|
| TAB 1 — SV030 | ~16,4 s | **0** (thành công) |
| TAB 2 — SV041 | ~16,4 s | **0** (thành công — đã chờ khóa 15,4 s) |

| SoDK_ThucTe | BoDem_SiSo | SiSoToiDa |
|---|---|---|
| **2** | 1 | 1 |

```
✗ 2 lượt đăng ký thật > 1 chỗ  →  VƯỢT SĨ SỐ
✗ Bộ đếm SiSoHienTai kẹt ở 1 vì trigger dùng LEAST(SiSoToiDa, SiSo+1)
  → lỗi hỏng ÂM THẦM: nhìn cột sĩ số vẫn "hợp lệ", phải COUNT(*) mới lộ ra
✗ Điều kiện sĩ số mà phiên A kiểm tra đã bị phiên B làm MẤT HIỆU LỰC
```

### A.3. (tuỳ chọn) Bản gõ tay — bằng chứng **17/16** trên LHP514

> Chỉ dùng khi cần đúng con số **17 | 16 | 16** của báo cáo (LHP514 = *Kết cấu cao tầng*, 15/16).
> Cách này **gõ tay từng câu** thay vì gọi SP — vì SP sẽ chặn ở bước tiên quyết (mã 102).
> Thao tác tay không cần `DO SLEEP`: mỗi câu gửi riêng, giao tác **vẫn đang mở** giữa hai câu.

```sql
-- TAB 1: chuẩn bị
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');
SELECT MaLHP, SiSoHienTai, SiSoToiDa, (SiSoToiDa - SiSoHienTai) AS ConTrong
FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';          -- MONG ĐỢI: 15 | 16 | 1
```

**🪟 [TAB 1] — phiên của SV030**

```sql
START TRANSACTION;

SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';
-- → 15, 16   (đọc KHÔNG khóa → thấy còn 1 chỗ)

INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
VALUES ('SV030', 'LHP514', NOW(), 'DA_DANG_KY', 'Phien A - chua fix');
-- → Query OK. Trigger đã +1 sĩ số (15→16) và GIỮ KHÓA dòng LOPHOCPHAN.

-- ⏸⏸ DỪNG — TUYỆT ĐỐI CHƯA COMMIT. Sang TAB 2.
```

**🪟 [TAB 2] — phiên của SV041**

```sql
START TRANSACTION;

SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';
-- → 15, 16   ← VẪN thấy "còn 1 chỗ" (snapshot REPEATABLE-READ không thấy
--              thay đổi CHƯA commit của TAB 1) ⇒ SV041 tưởng mình là người cuối cùng

INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
VALUES ('SV041', 'LHP514', NOW(), 'DA_DANG_KY', 'Phien B - chua fix');
-- → ⏳ TREO: "Executing query..."  —  ĐANG CHỜ KHÓA của TAB 1
--   📸 CHỤP ẢNH NGAY LÚC NÀY  (đo được: chờ 2,14 giây)
```

**🪟 [TAB 1] — mở khóa**

```sql
COMMIT;    -- → TAB 2 tự chạy tiếp ngay
```

**🪟 [TAB 2] — hoàn tất**

```sql
COMMIT;
```

**KẾT QUẢ ĐO THẬT (bản gõ tay trên LHP514):**

```sql
SELECT COUNT(*) AS SoDK_ThucTe,
       (SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514') AS BoDem_SiSo,
       (SELECT SiSoToiDa  FROM LOPHOCPHAN WHERE MaLHP='LHP514') AS SiSoToiDa
FROM DANGKYHOCPHAN
WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';
```

| SoDK_ThucTe | BoDem_SiSo | SiSoToiDa |
|---|---|---|
| **17** | 16 | 16 |

---

# PHẦN B — CHỨNG MINH ĐÃ FIX (2 TAB)

> ▶️ **Chuẩn bị trước khi làm phần này:** khôi phục bản thủ tục thật (có `FOR UPDATE`) rồi dọn dữ liệu LHP506:
> ```bash
> cd backend
> node scripts/apply-sql.js ../mysql/procedures/SP_DangKyHocPhan.sql
> node scripts/verify-db.js        # phải thấy "✅ ĐÃ FIX (có FOR UPDATE)"
> ```
> ```sql
> CALL SP_ChuanBi_Demo_4Anomaly('LHP506');   -- về 0/1
> ```
> **Hai câu `CALL` giống hệt PHẦN A** — chỉ khác bản thủ tục đang nạp ⇒ đối chứng rất rõ khi trình bày.

### B.1. Cơ chế `SELECT … FOR UPDATE` trên **chính LHP514**

**🪟 [TAB 1]**

```sql
START TRANSACTION;

SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP = 'LHP514' FOR UPDATE;
-- → 15, 16   ★ khóa ĐỘC QUYỀN (X-lock) dòng sĩ số, giữ tới COMMIT

INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
VALUES ('SV030', 'LHP514', NOW(), 'DA_DANG_KY', 'Phien A - da fix');

-- ⏸ DỪNG — chưa COMMIT. Sang TAB 2.
```

**🪟 [TAB 2]**

```sql
START TRANSACTION;

SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP = 'LHP514' FOR UPDATE;
-- → ⏳ TREO — PHẢI CHỜ  📸 chụp ảnh
--   Sau khi TAB 1 COMMIT, câu này mới trả về:
-- → 16, 16   ← đọc SAU khi phiên A đã ghi ⇒ LỚP ĐÃ ĐẦY
--   ⇒ đây chính là lúc SP_DangKyHocPhan gán pKetQua = 105
ROLLBACK;
```

**🪟 [TAB 1]**

```sql
COMMIT;
```

**KẾT QUẢ ĐO THẬT:** TAB 2 chờ **2,14 giây**, đọc được **16/16** ⇒ mã **105** · sĩ số cuối **16/16, COUNT = 16 — KHÔNG vượt**.

### B.2. Kết quả nghiệp vụ **mã 105** qua thủ tục thật (đúng caption Hình 3)

> ⚠️ **Vì sao không dùng LHP514 cho phần này?** `SP_DangKyHocPhan` kiểm tra **môn tiên quyết TRƯỚC** bước sĩ số.
> LHP514 (MH045) yêu cầu đạt **MH033** — SV030 và SV041 **đều chưa đạt** ⇒ cả hai nhận **102**.
> **LHP506** (MH017) **không có tiên quyết** và đang **0/1 — còn đúng 1 chỗ** ⇒ dùng để lấy mã 105.

```sql
-- TAB 1: chuẩn bị
CALL SP_ChuanBi_Demo_4Anomaly('LHP506');
SELECT MaLHP, SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP='LHP506';
-- MONG ĐỢI: LHP506 | 0 | 1
```

```sql
-- TAB 1: phiên SV030
CALL SP_DangKyHocPhan('SV030', 'LHP506', 24, 'Phien A - da fix', @kqA);
SELECT @kqA AS KetQua_CuaSo1;      -- MONG ĐỢI: 0   (lấy được suất cuối)
```

```sql
-- TAB 2: phiên SV041 (chạy ngay sau đó)
CALL SP_DangKyHocPhan('SV041', 'LHP506', 24, 'Phien B - da fix', @kqB);
SELECT @kqB AS KetQua_CuaSo2;      -- MONG ĐỢI: 105 (Lớp đã đầy sĩ số)
```

> 💡 Bản **đã fix** không phụ thuộc thời điểm: chạy TAB 2 **sau** khi TAB 1 xong thì nó đọc thẳng `1/1`
> ⇒ **105**; còn chạy TAB 2 **trong lúc** TAB 1 đang xử lý thì nó **chờ khóa** rồi mới đọc ⇒ vẫn **105**.
> Đó chính là điều bản **chưa fix** ở PHẦN A không làm được (chờ khóa xong vẫn đọc snapshot cũ ⇒ **0**).

```sql
-- Kiểm tra
SELECT MaLHP, SiSoHienTai, SiSoToiDa,
       (SELECT COUNT(*) FROM DANGKYHOCPHAN d
         WHERE d.MaLHP='LHP506' AND d.TrangThaiDangKy='DA_DANG_KY') AS SoDK_ThucTe
FROM LOPHOCPHAN WHERE MaLHP='LHP506';
-- MONG ĐỢI: LHP506 | 1 | 1 | 1
```

**KẾT QUẢ ĐO THẬT:** `@kqA = 0` · `@kqB = 105` · sĩ số **1/1**, `COUNT = 1` — một suất chỉ cấp cho đúng một sinh viên.

> 📸 **Hình 3** nên là ảnh ghép: **nửa trên** = 2 tab **PHẦN A** — cùng gọi `CALL SP_DangKyHocPhan`, cả hai
> trả **`0`** và bảng kiểm tra **`2 | 1 | 1`**; **nửa dưới** = 2 tab **PHẦN B** — cùng câu `CALL` đó nhưng
> trên bản thủ tục **đã fix**, cho **`0`** và **`105`** với bảng kiểm tra **`1 | 1 | 1`**.
> (Nếu làm thêm **A.3** bằng cách gõ tay trên LHP514 thì chèn thêm ảnh bảng **`17 | 16 | 16`**.)

---

# PHẦN C — DEMO BẰNG THAO TÁC WEB (2 TRÌNH DUYỆT)

### C.0. Nguyên tắc bắt buộc

1. **2 phiên đăng nhập riêng:** 1 cửa sổ **thường** (sv030) + 1 cửa sổ **Ẩn danh/InPrivate** (sv041).
   *(Hai tab trong cùng một cửa sổ dùng chung `localStorage` ⇒ sẽ là cùng một tài khoản.)*
2. **KHÔNG được F5/refresh trình duyệt B** sau khi A đăng ký xong — nếu refresh, nút sẽ thành **"Hết chỗ"**
   và bị **disable**. Việc B ra quyết định dựa trên dữ liệu **cũ** chính là bản chất của Lost Update.

### C.1. Triển khai "bản thủ tục chưa fix"

> 💡 **1 CLICK:** mở **http://localhost:3000/chuan-bi-demo** → chọn kịch bản **`① Lost Update`** →
> bấm **⚙ CHUẨN BỊ DEMO** (trang tự nạp thủ tục + dựng lại dữ liệu). Hoặc làm bằng dòng lệnh như dưới.

```bash
cd backend
node scripts/apply-sql.js ../demo/sql_config/lost_update__chua_fix.sql

# kiểm tra: phải thấy "BẢN CHƯA FIX"
node scripts/verify-db.js
```

### C.2. Chuẩn bị dữ liệu

```sql
CALL SP_ChuanBi_Demo_4Anomaly('LHP506');
SELECT MaLHP, SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP='LHP506';   -- 0/1
```

### C.3. Thao tác

| Bước | Trình duyệt A (cửa sổ thường) | Trình duyệt B (cửa sổ ẩn danh) |
|---|---|---|
| 1 | Mở **http://localhost:3000** → đăng nhập `sv030` / `matkhau@123` | Mở **http://localhost:3000** → đăng nhập `sv041` / `matkhau@123` |
| 2 | Menu **Đăng ký lớp học phần** | Menu **Đăng ký lớp học phần** |
| 3 | Tìm dòng **`LHP506` – TA chuyên ngành K15** → cột sĩ số ghi **còn chỗ**, nút **Đăng ký** đang bật | Y hệt — **để nguyên trang, KHÔNG refresh** |
| 4 | **Bấm `Đăng ký`** | — |
| 5 | Nút chuyển thành **`...`** (đang xử lý) | **Đếm 1… 2…** rồi **bấm `Đăng ký`** (chậm hơn A ~2 giây) |
| 6 | Sau ~8 giây: toast xanh **"✅ Đăng ký học phần thành công. — LHP506 (Đăng ký mới)"** | Chờ thêm ~8 giây → toast xanh **"✅ Đăng ký học phần thành công."** ⚠️ **CẢ HAI ĐỀU THÀNH CÔNG — ĐÓ LÀ LỖI** |

📸 **Chụp:** cả 2 trình duyệt cạnh nhau, mỗi bên có **toast xanh thành công cho cùng lớp LHP506**.

> 💡 Khoảng cách 2 giây chỉ để thao tác rõ ràng — **đã đo: lệch 0,2s / 1s / 2s / 4s đều cho kết quả đúng**.
> Chỉ cần **đừng bấm đồng thời trong cùng một phần mười giây**.

### C.4. Kiểm tra hậu quả trong DB 📸

```sql
SELECT COUNT(*) AS SoDK_ThucTe,
       (SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP506') AS BoDem_SiSo,
       (SELECT SiSoToiDa  FROM LOPHOCPHAN WHERE MaLHP='LHP506') AS SiSoToiDa
FROM DANGKYHOCPHAN WHERE MaLHP='LHP506' AND TrangThaiDangKy='DA_DANG_KY';
-- MONG ĐỢI: 2 | 1 | 1   → 2 sinh viên vào lớp 1 chỗ
```

**KẾT QUẢ ĐO THẬT QUA API WEB** (mô phỏng đúng 2 cú bấm):

```
[A] sau 8.4s  → HTTP 200 · ketQua = 0    (toast XANH)
[B] sau 16.4s → HTTP 200 · ketQua = 0    (toast XANH — B chờ khóa 8 giây)
LHP506 sau cùng: SiSo = 1/1 · COUNT(*) hiệu lực = 2   ⇒ VƯỢT SĨ SỐ
```

### C.5. Khôi phục bản ĐÃ FIX rồi làm lại để thấy khác biệt

```bash
cd backend
node scripts/apply-sql.js ../demo/sql_config/lost_update__da_fix.sql   # = SP_DangKyHocPhan thật
node scripts/verify-db.js                                              # phải thấy "✅ ĐÃ FIX"
```

```sql
CALL SP_ChuanBi_Demo_4Anomaly('LHP506');    -- dọn về 0/1
```

Làm lại y hệt C.3 (giao diện **không đổi gì**):

- **A** bấm *Đăng ký* → toast **xanh thành công**.
- **B** (vẫn **không refresh**) bấm *Đăng ký* → toast **đỏ**
  **"Đăng ký thất bại! Lớp học phần đã đầy sĩ số (hết chỗ trống)."** (mã **105**).

**KẾT QUẢ ĐO THẬT QUA API WEB (bản đã fix):**

```
[A] sau 0.4s → HTTP 200 · ketQua = 0      (toast XANH)
[B] sau 2.3s → HTTP 400 · ketQua = 105    (toast ĐỎ "Lớp đã đầy sĩ số")
LHP506 sau cùng: SiSo = 1/1 · COUNT(*) hiệu lực = 1   ⇒ KHÔNG vượt sĩ số
```

📸 Ảnh cặp đôi rất giá trị: **trước fix = 2 toast xanh · sau fix = 1 xanh + 1 đỏ 105**.

---

## 📸 CHECKLIST ẢNH

- [ ] TAB 2 **đang treo / chờ khóa** trong khi TAB 1 chưa xong (đúng lúc này thì `SELECT @kqB` chưa trả về)
- [ ] Bảng kiểm tra **`2 | 1 | 1`** + 2 tab đều `@kq = 0`  (PHẦN A — bản chưa fix)
- [ ] (nếu làm A.3) Bảng kiểm tra **`17 | 16 | 16`** trên LHP514
- [ ] `SELECT … FOR UPDATE` của TAB 2 trả về **`16, 16`** sau khi chờ  (PHẦN B.1)
- [ ] 2 tab với **`@kqA = 0`** và **`@kqB = 105`**  (PHẦN B.2 — bản đã fix)
- [ ] (cộng điểm) 2 trình duyệt **cùng toast xanh thành công**  (PHẦN C.3)
- [ ] (cộng điểm) Bảng DB **`2 | 1 | 1`**  (PHẦN C.4)
- [ ] (cộng điểm) Đối chứng sau khi khôi phục: **1 xanh + 1 đỏ 105**  (PHẦN C.5)

---

## 🧹 DỌN DẸP

```sql
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');   -- → 15/16
CALL SP_ChuanBi_Demo_4Anomaly('LHP506');   -- → 0/1
```

```bash
cd backend
node scripts/apply-sql.js ../mysql/procedures/SP_DangKyHocPhan.sql   # BẮT BUỘC sau PHẦN A / PHẦN C
node scripts/verify-db.js
```

---

## 📌 GHI CHÚ KỸ THUẬT (nên nói khi trình bày)

1. **`DO SLEEP` trong file `lost_update__chua_fix.sql` nằm SAU `INSERT`, TRƯỚC `COMMIT`.**
   Vị trí này rất quan trọng: `DANGKYHOCPHAN` có **khóa ngoại** tới `LOPHOCPHAN`, nên mỗi `INSERT` **đã lấy
   khóa chia sẻ (S)** trên dòng lớp để kiểm tra FK; sau đó **trigger** lại đòi nâng lên **khóa độc quyền (X)**
   trên **cùng dòng đó**. Nếu hai lệnh `INSERT` chồng lên nhau, cả hai cùng giữ S và cùng đòi X ⇒
   **chu trình chờ ⇒ deadlock 1213**, làm hỏng màn demo (đã đo: đặt SLEEP *trước* INSERT thì lệch 1 giây là dính 1213).
   Đặt SLEEP **sau INSERT** thì: phiên A giữ khóa → phiên B **chờ khóa** (đúng hình ảnh cần chụp) → A commit →
   B đi tiếp ⇒ **Lost Update, không deadlock**.
2. **SLEEP không phải nguyên nhân lỗi** — nó chỉ **mở rộng cửa sổ tranh chấp** để người thao tác tay
   kịp tái hiện. Bản chất lỗi nằm ở việc **thiếu `FOR UPDATE`**.
3. **Vì sao phải chọn đúng lớp:** LHP514 dùng cho kịch bản gõ tay (đúng số 17/16 như báo cáo), LHP506 dùng cho
   kịch bản **gọi thủ tục** và kịch bản web vì **không có môn tiên quyết** nên đi được tới bước kiểm tra sĩ số.
4. **Vì sao kịch bản 2 tab nên `CALL` thủ tục thay vì gõ tay `START TRANSACTION` … `INSERT` … `COMMIT`:**
   giao tác nằm **trọn trong thủ tục** nên người demo không thể quên `COMMIT`/`ROLLBACK`, không gõ sai tên cột,
   và đúng **đường đi thật của ứng dụng** (web cũng gọi chính SP này qua `backend/src/models/dangky.model.js`).
   Bản `_ChuaFix`/bản demo tự mở cửa sổ tranh chấp bằng `DO SLEEP(8)` ở cuối giao tác, nên chỉ cần chạy TAB 2
   trong vòng ~8 giây — vẫn thấy đúng cảnh **TAB 2 treo chờ khóa** để chụp ảnh.
