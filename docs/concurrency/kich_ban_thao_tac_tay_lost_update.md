# 🖐️ KỊCH BẢN THAO TÁC TAY — LỖI MẤT DỮ LIỆU CẬP NHẬT (LOST UPDATE)

> **Chương 4 — mục 4.1** của báo cáo · **Ảnh cần lấy: Hình 3**
> *"Minh chứng demo Lost Update (bảng kết quả 2 cửa sổ: bản chưa-fix vượt sĩ số, bản fix trả mã 105)"*
>
> 📌 **Toàn bộ kịch bản dưới đây là THAO TÁC TAY** — không dùng script tự động.
> Chọn **một trong hai cách**: **PHẦN A+B** (trình biên soạn DB, 2 tab) hoặc **PHẦN C** (web thật, 2 trình duyệt).
> Khuyến nghị: **làm cả hai** — A/B cho đúng số liệu trong báo cáo (LHP514 · 17/16), C cho "góc độ người dùng".

---

## 0. THÔNG TIN MÔI TRƯỜNG & KẾT NỐI

| Thông số | Giá trị |
|---|---|
| Hệ quản trị | **MariaDB 11.8.9** (Ubuntu 24.04) · engine **InnoDB** |
| Mức cô lập mặc định | `REPEATABLE-READ` |
| Host : Port | `0.tcp.ap.ngrok.io` : **21868** (tunnel TCP của ngrok tới server CSDL) |
| User / Password | `admin` / `01656229404aA@` |
| Database | `roacqgfa_dbms` |
| Web đang chạy | **http://localhost:3000** (bản build) hoặc **http://localhost:5173** (Vite dev) |
| Tài khoản SV | `sv030` / `matkhau@123` · `sv041` / `matkhau@123` |

> ⚠️ Tunnel ngrok (bản free) **đổi host:port mỗi lần khởi động lại**. Nếu kết nối không được, hỏi lại người mở tunnel hoặc xem `backend/.env` (mục `DB_HOST`, `DB_PORT`).

**Kết nối bằng trình biên soạn DB:** MySQL Workbench / HeidiSQL / DBeaver / phpMyAdmin đều được — tạo **2 kết nối (hoặc 2 query tab)** tới đúng host:port ở trên.

**Bảng mã lỗi của thủ tục đăng ký** (dùng để đọc kết quả):

| Mã | Ý nghĩa |
|---|---|
| `0` | Đăng ký thành công |
| `100` | Ngoài thời hạn đợt đăng ký |
| `101` | Đã đăng ký lớp này rồi |
| `102` | Chưa đạt môn tiên quyết |
| `103` | Trùng lịch học |
| `104` | Vượt số tín chỉ tối đa |
| **`105`** | **Lớp đã đầy sĩ số (hết chỗ trống)** ← mã cần thấy ở bản đã fix |
| `106` | Lớp không tồn tại / không mở đăng ký |
| `1213` | Deadlock — InnoDB tự chọn nạn nhân & rollback |

**Quy ước:** `[TAB 1]` = cửa sổ của SV030 · `[TAB 2]` = cửa sổ của SV041 · **⏸ DỪNG** = cố ý dừng lại để quan sát.
**Mẹo thao tác:** trong Workbench/HeidiSQL, **bôi đen từng câu rồi chạy riêng** (Ctrl+Enter). Giao tác vẫn mở giữa các câu ⇒ **không cần `DO SLEEP`**, cứ ngồi chờ bằng tay.

---

# PHẦN A — TRÌNH BIÊN SOẠN DB: TÁI HIỆN LỖI (2 TAB)

## A.0. Chuẩn bị (làm 1 lần, ở TAB 1)

```sql
-- Kiểm tra môi trường
SELECT VERSION() AS PhienBan,
       @@tx_isolation                AS MucCoLap,
       @@innodb_deadlock_detect      AS PhatHienDeadlock,
       @@innodb_lock_wait_timeout    AS ChoKhoaToiDa;
-- MONG ĐỢI: 11.8.9-MariaDB-ubu2404 | REPEATABLE-READ | 1 | 50

-- Đưa LHP514 về trạng thái "còn ĐÚNG 1 chỗ" + xóa dòng thử của SV030/SV041
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');

-- Xem trạng thái xuất phát
SELECT MaLHP, SiSoHienTai, SiSoToiDa, (SiSoToiDa - SiSoHienTai) AS ConTrong
FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';
-- MONG ĐỢI: LHP514 | 15 | 16 | 1
```

> 💡 Lớp **LHP514** (môn *Kết cấu cao tầng*, HK1-2025) đang **15/16 — còn đúng 1 chỗ**, đúng như báo cáo mô tả.

## A.1. Tái hiện Lost Update — hai phiên cùng đọc "còn 1 chỗ" rồi cùng ghi

### 🪟 [TAB 1] — phiên của SV030

```sql
START TRANSACTION;

SELECT SiSoHienTai, SiSoToiDa
FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';
-- → 15, 16   (đọc KHÔNG khóa → thấy còn 1 chỗ)

INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
VALUES ('SV030', 'LHP514', NOW(), 'DA_DANG_KY', 'Phien A - chua fix');
-- → Query OK, 1 row affected
--   Trigger TRG_DANGKYHOCPHAN_AFTER_INSERT đã +1 sĩ số (15 → 16)
--   và GIỮ KHÓA dòng LOPHOCPHAN cho tới khi COMMIT

-- ⏸⏸ DỪNG TẠI ĐÂY — TUYỆT ĐỐI CHƯA COMMIT. Chuyển sang TAB 2.
```

### 🪟 [TAB 2] — phiên của SV041 *(chạy khi TAB 1 đang ⏸)*

```sql
START TRANSACTION;

SELECT SiSoHienTai, SiSoToiDa
FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';
-- → 15, 16   ← VẪN thấy "còn 1 chỗ" (snapshot REPEATABLE-READ không thấy
--              thay đổi CHƯA commit của TAB 1) ⇒ SV041 tưởng mình là người cuối cùng

INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
VALUES ('SV041', 'LHP514', NOW(), 'DA_DANG_KY', 'Phien B - chua fix');
-- → ⏳ TREO: ô kết quả hiện "Executing query..." hoặc con xoay
--   Phiên B đang CHỜ KHÓA dòng sĩ số mà TAB 1 đang giữ.
--   ⇒ 📸 CHỤP ẢNH NGAY LÚC NÀY (đây là ảnh "phiên sau bị chờ khóa").
```

### 🪟 [TAB 1] — mở khóa cho TAB 2

```sql
COMMIT;
-- → TAB 2 tự chạy tiếp ngay lập tức
```

### 🪟 [TAB 2] — hoàn tất

```sql
COMMIT;
-- → ghi nhận thành công, trigger +1 sĩ số nhưng đã bị LEAST(SiSoToiDa, …) chặn ở 16
```

## A.2. Câu kiểm tra — bằng chứng vượt sĩ số (chụp ảnh)

```sql
SELECT COUNT(*) AS SoDK_ThucTe,
       (SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514') AS BoDem_SiSo,
       (SELECT SiSoToiDa  FROM LOPHOCPHAN WHERE MaLHP='LHP514') AS SiSoToiDa
FROM DANGKYHOCPHAN
WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';
```

**KẾT QUẢ ĐÃ ĐO THỰC TẾ (kịch bản này):**

| SoDK_ThucTe | BoDem_SiSo | SiSoToiDa |
|---|---|---|
| **17** | 16 | 16 |

```
✗ 17 lượt đăng ký thật > 16 chỗ  →  VƯỢT SĨ SỐ (Lost Update)
✗ Cột SiSoHienTai kẹt ở 16 (trigger dùng LEAST) → lỗi hỏng ÂM THẦM, nhìn màn hình vẫn "hợp lệ"
✗ Điều kiện sĩ số mà phiên A kiểm tra đã bị phiên B làm MẤT HIỆU LỰC
```

> 📸 **Hình 3 (phần "bản chưa-fix vượt sĩ số")** = ảnh chụp TAB 2 đang treo + bảng kết quả `17 | 16 | 16`.

**Dọn dẹp trước khi sang phần B:**

```sql
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');   -- trả về 15/16
```

---

# PHẦN B — TRÌNH BIÊN SOẠN DB: CHỨNG MINH BẢN ĐÃ FIX (2 TAB)

## B.1. Cơ chế chặn — `SELECT … FOR UPDATE` trên **chính LHP514**

Đây là "BUOC 6" của `SP_DangKyHocPhan` (bản chính thức), chạy y hệt nhưng **có khóa**:

### 🪟 [TAB 1] — phiên của SV030

```sql
START TRANSACTION;

SELECT SiSoHienTai, SiSoToiDa
FROM LOPHOCPHAN
WHERE MaLHP = 'LHP514'
FOR UPDATE;
-- → 15, 16   ★ khóa ĐỘC QUYỀN (X-lock) dòng sĩ số, giữ tới COMMIT

INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
VALUES ('SV030', 'LHP514', NOW(), 'DA_DANG_KY', 'Phien A - da fix');

-- ⏸ DỪNG — chưa COMMIT. Chuyển sang TAB 2.
```

### 🪟 [TAB 2] — phiên của SV041

```sql
START TRANSACTION;

SELECT SiSoHienTai, SiSoToiDa
FROM LOPHOCPHAN
WHERE MaLHP = 'LHP514'
FOR UPDATE;
-- → ⏳ TREO — phiên B PHẢI CHỜ. 📸 chụp ảnh.
--   Sau khi TAB 1 COMMIT, câu này mới trả về:
-- → 16, 16   ← đọc SAU khi phiên A đã ghi: LỚP ĐÃ ĐẦY
--   ⇒ đây chính là lúc SP_DangKyHocPhan gán pKetQua = 105

ROLLBACK;   -- không ghi gì
```

### 🪟 [TAB 1]

```sql
COMMIT;
```

**KẾT QUẢ ĐÃ ĐO THỰC TẾ:** TAB 2 chờ **2,6 giây**, đọc được `16/16`, kết thúc `LHP514 = 16/16`, `COUNT(*) = 16` → **KHÔNG vượt sĩ số**.

## B.2. Kết quả nghiệp vụ **mã 105** qua thủ tục thật (đúng caption Hình 3)

> ⚠️ **Vì sao không dùng LHP514 cho phần này?** `SP_DangKyHocPhan` kiểm tra **môn tiên quyết trước** bước sĩ số. LHP514 (môn `MH045`) yêu cầu đạt `MH033` — mà **SV030 và SV041 đều chưa đạt** ⇒ cả hai sẽ nhận **`102`**, không bao giờ tới được bước sĩ số.
> Lớp **LHP506** (môn `MH017`, HK1-2025) **không có tiên quyết** và đang **0/1 — còn đúng 1 chỗ** ⇒ dùng lớp này để lấy **mã 105**.

### 🪟 [TAB 1] — chuẩn bị

```sql
CALL SP_ChuanBi_Demo_4Anomaly('LHP506');

SELECT MaLHP, SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP='LHP506';
-- MONG ĐỢI: LHP506 | 0 | 1  (còn đúng 1 chỗ)
```

### 🪟 [TAB 1] — phiên của SV030

```sql
CALL SP_DangKyHocPhan('SV030', 'LHP506', 24, 'Phien A - da fix', @kqA);
SELECT @kqA AS KetQua_CuaSo1;
-- MONG ĐỢI: 0   → đăng ký thành công, lấy được suất cuối
```

### 🪟 [TAB 2] — phiên của SV041 *(chạy ngay sau đó)*

```sql
CALL SP_DangKyHocPhan('SV041', 'LHP506', 24, 'Phien B - da fix', @kqB);
SELECT @kqB AS KetQua_CuaSo2;
-- MONG ĐỢI: 105 → "Lớp đã đầy sĩ số": phiên B chờ khóa của A,
--                  đọc lại SAU commit, thấy 1/1 nên bị từ chối
```

### 🪟 Kiểm tra kết quả (tab bất kỳ)

```sql
SELECT MaLHP, SiSoHienTai, SiSoToiDa,
       (SELECT COUNT(*) FROM DANGKYHOCPHAN d
         WHERE d.MaLHP='LHP506' AND d.TrangThaiDangKy='DA_DANG_KY') AS SoDK_ThucTe
FROM LOPHOCPHAN WHERE MaLHP='LHP506';
```

**KẾT QUẢ ĐÃ ĐO THỰC TẾ:** `@kqA = 0` · `@kqB = 105` · `1/1` · `COUNT(*) = 1` → **một suất chỉ cấp cho đúng một sinh viên**.

> 📸 **Hình 3 (phần "bản fix trả mã 105")** = ảnh chụp 2 tab với `@kqA = 0` và `@kqB = 105`.
> 👉 **Bố cục ảnh gợi ý:** nửa trên là 2 tab ở PHẦN A (`17 | 16 | 16`), nửa dưới là 2 tab ở PHẦN B (`0` và `105`).

**Dọn dẹp:**

```sql
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');
CALL SP_ChuanBi_Demo_4Anomaly('LHP506');
```

---

# PHẦN C — TRÊN WEB THẬT (2 TRÌNH DUYỆT)

> Mục đích: chứng minh **từ góc độ người dùng** — hai sinh viên cùng bấm nút *Đăng ký* và **cả hai đều nhận thông báo thành công**, dù lớp chỉ còn 1 chỗ.
> ⚠️ Web đang chạy bản thủ tục **ĐÃ FIX**, nên phải **tạm thời triển khai bản chưa-fix** rồi khôi phục sau khi demo.

## C.0. Nguyên tắc bắt buộc

1. Phải là **2 phiên đăng nhập riêng biệt**: 1 cửa sổ thường (sv030) + 1 cửa sổ **Ẩn danh/InPrivate** (sv041). *(Hai tab trong cùng một cửa sổ dùng chung `localStorage` ⇒ sẽ là cùng một tài khoản.)*
2. **KHÔNG được F5/refresh trình duyệt B** sau khi A đăng ký xong — nếu refresh, nút sẽ chuyển thành **"Hết chỗ"** và bị **disable**, mất cơ hội tái hiện lỗi. (Đây chính là bản chất Lost Update trên giao diện: B đang ra quyết định dựa trên dữ liệu **cũ**.)

## C.1. Triển khai "bản thủ tục ban đầu chưa fix" (Terminal, làm 1 lần)

```bash
cd backend
node scripts/apply-sql.js ../mysql/transactions/demo_lostupdate_chuafix.sql
```

> File này ghi đè `SP_DangKyHocPhan` bằng **đúng bản cũ**: giống hệt bản chính thức, **chỉ thiếu `FOR UPDATE`** ở bước kiểm tra sĩ số (kèm `DO SLEEP(8)` đặt **sau INSERT, trước COMMIT** để mở rộng cửa sổ quan sát — xem Phụ lục).

## C.2. Chuẩn bị dữ liệu (trình biên soạn DB hoặc TAB 1)

```sql
CALL SP_ChuanBi_Demo_4Anomaly('LHP506');
SELECT MaLHP, SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP='LHP506';
-- MONG ĐỢI: LHP506 | 0 | 1   → trên web hiển thị "TA chuyên ngành K15 — còn 1 chỗ"
```

## C.3. Thao tác trên web

| Bước | Trình duyệt A (cửa sổ thường) | Trình duyệt B (cửa sổ ẩn danh) |
|---|---|---|
| 1 | Mở **http://localhost:3000** → đăng nhập `sv030` / `matkhau@123` | Mở **http://localhost:3000** → đăng nhập `sv041` / `matkhau@123` |
| 2 | Menu **Đăng ký lớp học phần** | Menu **Đăng ký lớp học phần** |
| 3 | Tìm dòng **`LHP506` – TA chuyên ngành K15**, cột sĩ số ghi **còn chỗ**, nút **Đăng ký** đang bật | Làm y hệt — **để nguyên trang, KHÔNG refresh** |
| 4 | **Bấm nút `Đăng ký`** của LHP506 | — |
| 5 | Nút chuyển thành **`...`** (đang xử lý) — chờ | **Đếm 1… 2… rồi bấm nút `Đăng ký`** của LHP506 (chậm hơn A khoảng **2 giây**) |
| 6 | Sau ~8 giây: toast xanh **"✅ Đăng ký học phần thành công. — LHP506 (Đăng ký mới)"** | Nút cũng hiện **`...`**; chờ thêm ~8 giây → toast xanh **"✅ Đăng ký học phần thành công. — LHP506 (Đăng ký mới)"** ⚠️ **CẢ HAI ĐỀU THÀNH CÔNG — ĐÓ LÀ LỖI** |

📸 **Chụp ảnh:** cả 2 trình duyệt cạnh nhau, mỗi bên có toast xanh thành công cho cùng lớp LHP506.

> 💡 Khoảng cách 2 giây chỉ để thao tác rõ ràng — đã đo thực tế: lệch **0,2s / 1s / 2s / 4s đều cho kết quả đúng**. Chỉ cần **đừng bấm đồng thời trong cùng một phần mười giây**.

## C.4. Kiểm tra hậu quả trong DB (chụp ảnh kèm)

```sql
SELECT COUNT(*) AS SoDK_ThucTe,
       (SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP506') AS BoDem_SiSo,
       (SELECT SiSoToiDa  FROM LOPHOCPHAN WHERE MaLHP='LHP506') AS SiSoToiDa
FROM DANGKYHOCPHAN WHERE MaLHP='LHP506' AND TrangThaiDangKy='DA_DANG_KY';
-- MONG ĐỢI: 2 | 1 | 1   → 2 sinh viên vào lớp 1 chỗ
```

## C.5. Khôi phục bản ĐÃ FIX rồi làm lại để thấy khác biệt

```bash
cd backend
node scripts/apply-sql.js ../mysql/procedures/SP_DangKyHocPhan.sql

# và dọn dữ liệu về "còn 1 chỗ"
#   CALL SP_ChuanBi_Demo_4Anomaly('LHP506');
```

Làm lại y hệt C.3 (giao diện không đổi gì):
- **A** bấm *Đăng ký* → toast xanh **thành công**.
- **B** (vẫn **không refresh**) bấm *Đăng ký* → toast đỏ
  **"Đăng ký thất bại! Lớp học phần đã đầy sĩ số (hết chỗ trống)."** (mã **105**) ⇒ phiên đến sau **đã bị chặn đúng**.

📸 Ảnh cặp đôi này rất giá trị: **trước fix = 2 toast xanh · sau fix = 1 xanh + 1 đỏ 105**.

---

# PHẦN D — DỌN DẸP & CHECKLIST ẢNH

## D.1. Dọn dẹp cuối buổi

```sql
-- Trả dữ liệu demo về trạng thái ban đầu
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');   -- → 15/16
CALL SP_ChuanBi_Demo_4Anomaly('LHP506');   -- → 0/1
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
```

```bash
# BẮT BUỘC: khôi phục thủ tục thật nếu đã làm PHẦN C
cd backend
node scripts/apply-sql.js ../mysql/procedures/SP_DangKyHocPhan.sql

# Kiểm tra đã khôi phục đúng (phải thấy CoForUpdate = 1)
#   SELECT ROUTINE_DEFINITION LIKE '%FOR UPDATE%' FROM information_schema.ROUTINES
#   WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_NAME='SP_DangKyHocPhan';
```

## D.2. Checklist ảnh cho Hình 3

- [ ] Ảnh TAB 2 **đang treo / chờ khóa** trong khi TAB 1 chưa COMMIT (PHẦN A)
- [ ] Ảnh bảng kiểm tra **`17 | 16 | 16`** → vượt sĩ số (PHẦN A)
- [ ] Ảnh `SELECT … FOR UPDATE` của TAB 2 trả về **`16, 16`** sau khi chờ (PHẦN B.1)
- [ ] Ảnh 2 tab với **`@kqA = 0`** và **`@kqB = 105`** (PHẦN B.2)
- [ ] (Cộng điểm) Ảnh 2 trình duyệt **cùng toast xanh thành công** (PHẦN C.3)
- [ ] (Cộng điểm) Ảnh bảng DB **`2 | 1 | 1`** (PHẦN C.4)
- [ ] (Cộng điểm) Ảnh đối chứng sau khi khôi phục bản fix: **1 xanh + 1 đỏ 105** (PHẦN C.5)

---

# PHỤ LỤC — HAI ĐIỀU ĐÃ ĐO ĐƯỢC KHI CHẠY THẬT

### 1. Vì sao kịch bản DB (PHẦN A/B) **không cần `DO SLEEP`**

Trong báo cáo, script mẫu dùng `DO SLEEP(10)` để "giữ phiên" cho cửa sổ kia chạy xen vào. Khi **thao tác tay**, bạn **không cần** làm vậy: mỗi câu lệnh gửi riêng, mà giao tác **vẫn đang mở** giữa hai câu ⇒ cứ để nguyên đó và chuyển tab. Cách này còn **chính xác hơn** script, vì **thứ tự thực thi do bạn quyết định**, không phụ thuộc vào đồng hồ.

> 🔎 **Lưu ý kỹ thuật cho báo cáo:** trong script mẫu ở mục 4.1.3, `DO SLEEP(10)` được đặt **trước** lệnh `INSERT` của phiên A. Ở thời điểm đó **phiên A chưa giữ khóa nào**, nên `INSERT` của phiên B **không hề bị chặn** — bảng mô tả "INSERT của B bị chặn chờ khóa của A" chỉ đúng khi **A INSERT trước rồi mới tạm dừng** (đúng như kịch bản A.1 ở trên). Kết quả cuối (`17/16`) thì giống nhau ở cả hai cách.

### 2. ⚠️ Vì sao `DO SLEEP` trong bản SP chưa-fix **phải nằm SAU `INSERT`, TRƯỚC `COMMIT`**

Khi thử đặt `DO SLEEP` **trước** `INSERT` (cách làm đầu tiên), phiên B **không** nhận Lost Update mà nhận **lỗi 1213 — Deadlock**:

```
TRANSACTION 3607 (SV041)  LOCK WAIT
  UPDATE LOPHOCPHAN SET SiSoHienTai = LEAST(SiSoToiDa, SiSoHienTai + 1)
  WHERE MaLHP = NEW.MaLHP                       ← trigger cộng sĩ số
*** WAITING FOR THIS LOCK TO BE GRANTED:
  RECORD LOCKS ... LOPHOCPHAN ... lock_mode X locks rec but not gap waiting
*** CONFLICTING WITH:
  RECORD LOCKS ... LOPHOCPHAN ... lock mode S locks rec but not gap   ← của phiên kia
```

**Nguyên nhân:** `DANGKYHOCPHAN` có khóa ngoại tới `LOPHOCPHAN`, nên mỗi `INSERT` **đã lấy khóa chia sẻ (S)** trên dòng lớp để kiểm tra FK; sau đó **trigger** lại đòi nâng lên **khóa độc quyền (X)** trên **cùng dòng đó**. Hai phiên cùng giữ S và cùng đòi X ⇒ **chu trình chờ** ⇒ InnoDB chọn một phiên làm nạn nhân và rollback (`1213`) ⇒ **màn demo Lost Update bị hỏng** (đã đo: hai lệnh INSERT chồng nhau trong khoảng ~1 giây là dính).

**Cách sửa:** đặt `DO SLEEP` **sau `INSERT`, trước `COMMIT`**:
- Phiên A: `INSERT` (giữ khóa) → ngủ 8 giây → `COMMIT`
- Phiên B: đọc sĩ số bằng `SELECT` thường (**vẫn thấy giá trị cũ "còn chỗ"**) → `INSERT` **bị chờ khóa** → A commit → B đi tiếp ⇒ **cùng ghi** ⇒ **Lost Update**, **không deadlock**, và **nhìn thấy rõ phiên B chờ khóa**.

**Vùng thời gian đã đo thực tế (phiên B bấm sau phiên A):**

| Lệch | Kết quả |
|---|---|
| 0,2 giây | ✅ cả 2 thành công · SoDK = **2/1** (Lost Update) |
| 1 giây | ✅ cả 2 thành công · SoDK = **2/1** |
| 2 giây | ✅ cả 2 thành công · SoDK = **2/1** |
| 4 giây | ✅ cả 2 thành công · SoDK = **2/1** |

⇒ **Rất an toàn**: chỉ cần hai người **không bấm trúng cùng một phần mười giây**.

---

## 📁 FILE LIÊN QUAN

| File | Vai trò |
|---|---|
| `mysql/transactions/demo_lostupdate_chuafix.sql` | Bản SP **cố ý chưa fix** (ghi đè `SP_DangKyHocPhan`) — dùng cho PHẦN C |
| `mysql/procedures/SP_DangKyHocPhan.sql` | Bản **đã fix** (`SELECT … FOR UPDATE`) — **khôi phục sau demo** |
| `mysql/transactions/demo_4_anomaly.sql` | `SP_ChuanBi_Demo_4Anomaly` (chuẩn bị dữ liệu) + bản `ChuaFix` tên riêng |
| `docs/concurrency/script_demo_sql.md` | Script SQL tham khảo cho cả 4 lỗi + deadlock |
| `docs/concurrency/concurrency_anomaly_demo.md` | Báo cáo đo thực tế 4 lỗi concurrency |
