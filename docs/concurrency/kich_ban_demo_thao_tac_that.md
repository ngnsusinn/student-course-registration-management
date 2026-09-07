# 🎬 KỊCH BẢN DEMO THAO TÁC THẬT — 4 LỖI ĐIỀU KHIỂN CẠNH TRANH

> **Demo bằng tay trước lớp**: 2 trình duyệt (2 sinh viên đăng ký cùng lúc trên web thật)
> + 2 cửa sổ MySQL (gõ lệnh thật từng bước). **Không dùng trang Concurrency Lab tự động.**
>
> Thời lượng: ~15–20 phút · Số người: 1 thuyết trình + 1 phụ "cửa sổ B" (hoặc tự làm một mình 2 màn hình)

---

## 0. CHUẨN BỊ TRƯỚC KHI THUYẾT TRÌNH (làm tại nhà, 5 phút)

### 0.1. Mở sẵn các cửa sổ

| # | Cửa sổ | Nội dung | Dùng cho |
|---|--------|----------|----------|
| 1 | **Browser A** (VD: Chrome thường) | Đăng nhập web `http://localhost:3000` bằng `sv030 / matkhau@123` | Màn 1 |
| 2 | **Browser B** (VD: Edge, hoặc Chrome ẩn danh) | Đăng nhập web bằng `sv041 / matkhau@123` | Màn 1 |
| 3 | **CỬA SỔ A** — MySQL client (Workbench / HeidiSQL / CMD) | Kết nối `free02.123host.vn`, DB `roacqgfa_dbms` | Màn 2→5 |
| 4 | **CỬA SỔ B** — MySQL client (thứ 2) | Cùng kết nối | Màn 2→5 |

```bash
# Lệnh kết nối mysql client (2 cửa sổ giống nhau):
mysql -h free02.123host.vn -u roacqgfa_dbms -p roacqgfa_dbms
```

> 💡 Mẹo trình chiếu: phóng to chữ SQL (Ctrl+滚轮 trong Workbench) và chữ web (Ctrl+Shift+=)
> để cả lớp đọc được. Cửa sổ A đặt bên trái màn hình, cửa sổ B bên phải.

### 0.2. Đưa dữ liệu về trạng thái demo (chạy 1 lần, ở CỬA SỔ A)

```sql
-- Đưa LHP514 "Kết cấu cao tầng K15" về 15/16 (còn đúng 1 chỗ)
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');

-- Kiểm tra 2 lớp dùng cho demo:
SELECT MaLHP, TenLHP, SiSoHienTai, SiSoToiDa, TrangThaiLop
FROM LOPHOCPHAN WHERE MaLHP IN ('LHP514','LHP506');
-- Kết quả mong đợi:
--   LHP514 (Kết cấu cao tầng) 15/16  MO_DANG_KY   ← dùng Màn 2,3,4,5
--   LHP506 (TA chuyên ngành)   1/2   MO_DANG_KY   ← dùng Màn 1 (web)
```

Nếu LHP506 đã bị đăng ký kín (2/2), dọn về 1/2:

```sql
DELETE FROM DANGKYHOCPHAN WHERE MaLHP='LHP506' AND MaSV IN ('SV030','SV041');
-- Trigger tự trừ sĩ số → quay về 1/2
```

---

# MÀN 1 — LOST UPDATE **BỊ CHẶN** NHỜ THỦ TỤC ĐÃ FIX (thao tác WEB thật) ⭐

> **Câu chuyện:** 2 sinh viên cùng giành **suất cuối cùng** của lớp TA chuyên ngành (1/2 chỗ).

**Thao tác:**

1. Chiếu **Browser A** (sv030) và **Browser B** (sv041) cạnh nhau, cùng trang **Đăng ký học phần**.
2. Cả 2 cùng tìm lớp **LHP506 — TA chuyên ngành K15** (hiển thị *còn 1 chỗ*).
3. Thuyết trình hô **"3 — 2 — 1 — ĐĂNG KÝ!"**, cả hai bấm nút **Đăng ký** gần như cùng lúc.
4. **Kết quả xuất hiện:**
   - Một trình duyệt: ✅ *"Đăng ký học phần thành công."*
   - Trình duyệt kia: ❌ *"Đăng ký thất bại! Lớp học phần đã đầy sĩ số (hết chỗ trống)"* — **mã 105**.

**Chứng minh bằng SQL (CỬA SỔ A):**

```sql
SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP='LHP506';   -- 2/2 — không vượt
SELECT MaSV FROM DANGKYHOCPHAN
WHERE MaLHP='LHP506' AND TrangThaiDangKy='DA_DANG_KY';                -- đúng 2 dòng
```

**Nói gì trước lớp:**

> "Cả 2 request đều chạy đúng **một** thủ tục `SP_DangKyHocPhan`. Bước cuối của thủ tục đọc sĩ số
> bằng `SELECT ... FOR UPDATE` — **khóa lưu quan dòng sĩ số**: ai đến trước giữ khóa, người sau
> phải **chờ**; khi được phép đọc lại thì chỗ đã hết → thủ tục tự trả mã 105. Không ai ghi đè ai,
> sĩ số không bao giờ vượt 2. Đó là cách phòng chống **Lost Update** bằng khóa."

*(Lý do chọn LHP506 cho màn này: môn TA không có môn tiên quyết nên 2 SV này đăng ký qua web hợp lệ.)*

**Dọn dẹp (nếu muốn chạy lại):** xem lệnh xóa ở mục 0.2.

---

# MÀN 2 — LOST UPDATE **XẢY RA** VỚI THỦ TỤC BAN ĐẦU CHƯA FIX (2 cửa sổ SQL) ⭐

> **Câu chuyện:** cùng tình huống 1 chỗ cuối — nhưng đây là **thủ tục ban đầu chưa fix**
> (`SP_DangKyHocPhan_ChuaFix`, thiếu `FOR UPDATE`) hoặc gõ tay như 2 lập trình viên sơ xuất.

**Chuẩn bị lại chỗ trống (CỬA SỔ A):**

```sql
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');   -- LHP514 về 15/16
```

### Bước 2.1 — CỬA SỔ A (gõ rồi chạy từng khối, **chưa commit**):

```sql
SET autocommit=0;
START TRANSACTION;

INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
VALUES ('SV030','LHP514',NOW(),'DA_DANG_KY','Demo Lost Update - phien A');

SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514';   -- A thấy 15
-- ⟵ DỪNG Ở ĐÂY. Chuyển sang cửa sổ B.
```

*(Trigger `TRG_DANGKYHOCPHAN_SiSo` vừa UPDATE dòng LOPHOCPHAN → **A đang giữ khóa ghi dòng này, chưa commit**.)*

### Bước 2.2 — CỬA SỔ B (chạy):

```sql
SET autocommit=0;
START TRANSACTION;

INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
VALUES ('SV041','LHP514',NOW(),'DA_DANG_KY','Demo Lost Update - phien B');
-- ⟵ CỬA SỔ B TREO! Con trỏ quay quay, không trả kết quả.
```

> 👉 Chỉ vào cửa sổ B: **"B đang bị chờ khóa của A — đây chính là hiện tượng tranh chấp khóa."**
> *(Chờ ~10 giây cho lớp thấy, đừng để quá 50s kẻo `Lock wait timeout`.)*

### Bước 2.3 — Quay lại CỬA SỔ A:

```sql
COMMIT;
-- ⟵ Cửa sổ B rung lên, INSERT hoàn tất. B chạy:
```

### Bước 2.4 — CỬA SỔ B:

```sql
COMMIT;
```

### Bước 2.5 — Bằng chứng hỏng dữ liệu (CỬA SỔ A):

```sql
SELECT COUNT(*) AS SoDangKyThucTe, MAX(lhp.SiSoToiDa) AS ChoToiDa
FROM DANGKYHOCPHAN dk JOIN LOPHOCPHAN lhp ON lhp.MaLHP=dk.MaLHP
WHERE dk.MaLHP='LHP514' AND dk.TrangThaiDangKy='DA_DANG_KY';
-- ⟵ SoDangKyThucTe = 17  >  ChoToiDa = 16  → CHỖ BỊ BÁN QUÁ!

SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514';   -- vẫn báo 16 — "bộ đếm nói dối"
-- (trigger dùng LEAST(SiSoToiDa, ...) nên bộ đếm kẹt, hỏng âm thầm)
```

**Nói gì:**

> "**17 lượt đăng ký thực tế cho 16 chỗ** — 2 giao tác cùng đọc 'còn 1 chỗ', cùng quyết định
> bán, và bản cập nhật của một bên bị **mất**. Bộ đếm sĩ số còn 'nói dối' vì bị chặn trần.
> Đây là Lost Update — điều mà ở Màn 1, thủ tục đã fix đã ngăn thành công."

**Dọn dẹp:**

```sql
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');   -- xóa SV030/041/060/999, tự tính lại sĩ số
```

---

# MÀN 3 — DIRTY READ (2 cửa sổ SQL)

> **Câu chuyện:** SV030 hỏi "lớp còn chỗ không?" đúng lúc giao tác khác đang sửa nửa chừng.

### Bước 3.0 — **TẮT PHÒNG CHỐNG** ở CỬA SỔ A (đúng kỹ thuật trong slide):

```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
START TRANSACTION;
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514';   -- A thấy 15
```

### Bước 3.1 — CỬA SỔ B: sửa dữ liệu nhưng **CHƯA commit**:

```sql
SET autocommit=0;
START TRANSACTION;
UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP='LHP514';
-- Query OK (chưa chốt sổ!)
```

### Bước 3.2 — CỬA SỔ A đọc lại:

```sql
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514';   -- ⟵ A THẤY 16!
-- "Ôi lớp vừa đầy rồi, chắc hết suất!"  → ra quyết định dựa trên dữ liệu CHƯA COMMIT
```

### Bước 3.3 — CỬA SỔ B **lăn lăn quay ngược**:

```sql
ROLLBACK;
```

### Bước 3.4 — CỬA SỔ A đọc lại lần nữa:

```sql
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514';   -- ⟵ 16 biến thành 15!
```

**Nói gì:**

> "A đọc được số **16** mà B chưa bao giờ commit — đó là **Đọc bẩn**. Quyết định dựa trên số
> đó trở nên vô nghĩa khi B rollback. MySQL mặc định **REPEATABLE-READ chặn sẵn lỗi này** —
> vì vậy chúng ta phải chủ động hạ xuống READ UNCOMMITTED (bước 3.0) mới tái hiện được,
> đúng như thuyết trình về isolation level."

---

# MÀN 4 — UNREPEATABLE READ (2 cửa sổ SQL)

### Bước 4.0 — CỬA SỔ A: **tắt phòng chống** ở mức khác:

```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514';   -- lần 1: 15
```

### Bước 4.1 — CỬA SỔ B: sửa và **CÓ commit**:

```sql
UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP='LHP514';
COMMIT;
```

### Bước 4.2 — CỬA SỔ A đọc lần 2 **trong cùng giao tác**:

```sql
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514';   -- lần 2: 16 — KHÁC lần 1!
COMMIT;   -- kết thúc giao tác của A
```

**Nói gì:**

> "Cùng một giao tác, đọc cùng một ô dữ liệu **2 lần ra 2 kết quả** (15 rồi 16) — báo cáo
> trong 1 lần chấm điểm sẽ mâu thuẫn chính nó. Đây là **Đọc không lặp lại**.
> Lưu ý: với mức mặc định REPEATABLE-READ, lần 2 vẫn ra 15 — MySQL chặn sẵn."

---

# MÀN 5 — PHANTOM READ (2 cửa sổ SQL)

### Bước 5.0 — CỬA SỔ A:

```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
SELECT COUNT(*) AS SoDK
FROM DANGKYHOCPHAN
WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';   -- lần 1: 15
```

### Bước 5.1 — CỬA SỔ B: **chèn dòng mới** + commit:

```sql
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
VALUES ('SV999','LHP514',NOW(),'DA_DANG_KY','bong ma');
COMMIT;
```

### Bước 5.2 — CỬA SỔ A đếm lại:

```sql
SELECT COUNT(*) AS SoDK
FROM DANGKYHOCPHAN
WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';   -- lần 2: 16 — dòng "bóng ma"!
COMMIT;
```

**Nói gì:**

> "A không tự ghi gì cả, nhưng giữa 2 lần đếm **tự nhiên xuất hiện thêm 1 dòng** (15 → 16):
> dòng 'bóng ma' do ai đó chèn. Khác Màn 4 ở chỗ: dữ liệu **cũ** không đổi, mà **tập dòng**
> thay đổi. Ở MySQL, READ COMMITTED để hở lỗi này; REPEATABLE-READ (mặc định) chặn được
> với SELECT thường nhờ consistent snapshot."

**Dọn dẹp cuối buổi:**

```sql
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');   -- xóa SV999 + chuẩn hóa lại LHP514 = 15/16
DELETE FROM DANGKYHOCPHAN WHERE MaLHP='LHP506' AND MaSV IN ('SV030','SV041');
SELECT MaLHP, SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP IN ('LHP514','LHP506');
```

---

# 📌 TÓM TẮT DÀN BÀN (in 1 trang mang theo)

| Màn | Lỗi | Thao tác thật | Lệnh "tắt phòng chống" | Kết quả phải thấy |
|---|-----|---------------|------------------------|-------------------|
| 1 | Lost Update **bị chặn** | 2 trình duyệt bấm Đăng ký cùng lúc (LHP506) | *(không cần — SP đã fix)* | 1 × "thành công", 1 × **mã 105**, sĩ số 2/2 |
| 2 | Lost Update **xảy ra** | 2 cửa sổ INSERT chưa commit (LHP514) | thủ tục **chưa fix** (thiếu `FOR UPDATE`) | **17 đăng ký > 16 chỗ**, bộ đếm kẹt 16 |
| 3 | Dirty Read | B UPDATE chưa commit, A đọc | `SET SESSION ... READ UNCOMMITTED` | A thấy 16 → sau rollback còn 15 |
| 4 | Unrepeatable Read | B UPDATE có commit giữa 2 lần đọc của A | `SET SESSION ... READ COMMITTED` | cùng giao tác: 15 rồi 16 |
| 5 | Phantom Read | B INSERT có commit giữa 2 lần đếm của A | `SET SESSION ... READ COMMITTED` | COUNT 15 rồi 16 |

**Thông điệp kết:** *"MySQL 5.7 mặc định (REPEATABLE-READ) đã chặn sẵn Màn 3, 4, 5. Màn 2 bị hở vì
thiếu khóa lưu quan — và Màn 1 chứng minh thủ tục `SP_DangKyHocPhan` của nhóm đã vá bằng
`SELECT ... FOR UPDATE`, kết hợp transaction trong thủ tục. Web chỉ gọi thủ tục — mọi phòng
chống nằm gọn trong database."*

---

# 🛠 XỬ LÝ SỰ CỐ TRƯỚC LỚP (cheat sheet)

| Triệu chứng | Nguyên nhân | Xử lý |
|---|---|---|
| Màn 2: cửa sổ B **không** bị treo | A quên `START TRANSACTION` hoặc `autocommit=1` | chạy lại từ Bước 2.1, chắc chắn `SET autocommit=0;` |
| Màn 2: B báo `Lock wait timeout (1205)` | chờ quá 50 giây | chạy nhanh bước 2.3 (COMMIT của A) trong vòng ~40s |
| Màn 1: cả 2 trình duyệt đều thành công | LHP506 còn ≥ 2 chỗ | chạy lệnh dọn ở mục 0.2 rồi thử lại |
| Màn 1: báo lỗi "chưa hoàn thành môn tiên quyết" | nhầm sang LHP khác | **chỉ dùng LHP506** cho demo web |
| Web báo "ngoài thời hạn đăng ký" | học kỳ demo chưa mở | kiểm tra: `SELECT * FROM HOCKY WHERE TrangThaiDot='MO';` (HK1-2025 đang mở đến 2027) |
| Sai mật khẩu sv030/sv041 | — | mật khẩu chung SV: `matkhau@123` |
| Chưa kết nối được MySQL | hosting chặn IP lạ | kết nối thử từ nhà **trước** buổi demo; nếu lớp chặn port 3306, dùng 2 tab phpMyAdmin của hosting thay 2 cửa sổ mysql client (mỗi tab = 1 session) |

# ❓ CÂU HỎI GIẢNG VIÊN HAY HỎI

1. **"Vì sao bộ đếm sĩ số kẹt ở 16 dù 17 người đăng ký?"** — Trigger cập nhật sĩ số viết
   `LEAST(SiSoToiDa, SiSoHienTai+1)` nên bị chặn trần; bản ghi thật vẫn chèn thêm → hỏng âm thầm.
   Đây là lý do phải phòng chống ngay từ thủ tục, không trông cậy vào trigger.
2. **"FOR UPDATE đặt ở đâu trong thủ tục?"** — Bước 6 đọc sĩ số:
   `SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = ... FOR UPDATE` bên trong
   `START TRANSACTION ... COMMIT` của `SP_DangKyHocPhan`.
3. **"2 giao tác ở 2 lớp khác nhau có chặn nhau không?"** — Không: khóa theo **dòng**,
   LHP khác = dòng khác. Màn 2 chặn nhau vì cùng UPDATE một dòng LOPHOCPHAN của LHP514.
4. **"Nếu A giữ khóa quá lâu thì sao?"** — B chờ đến `innodb_lock_wait_timeout` (50s) rồi nhận
   lỗi 1205; thủ tục đăng ký của nhóm còn có **retry khi gặp deadlock 1213** để phiên thua
   nhận mã nghiệp vụ sạch (105) thay vì lỗi hệ thống.
5. **"READ COMMITTED 'tốt hơn' REPEATABLE-READ sao còn phải đổi?"** — Đổi là để **tái hiện lỗi**
   cho mục đích giảng dạy; hệ thống thật giữ REPEATABLE-READ + khóa lưu quan như Màn 1.
