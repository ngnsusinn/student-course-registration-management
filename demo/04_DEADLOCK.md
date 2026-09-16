# 4️⃣ LỖI KHÓA CHẾT (DEADLOCK)

> **Chương 4, mục 4.5** · Ảnh cần lấy: **Hình 4**
> *"Minh chứng demo Deadlock (2 cửa sổ SQL trả 1213/0 và thông báo đỏ trên giao diện web)"*

**Bản chất:** hai giao tác giữ khóa trên hai tài nguyên theo **thứ tự NGƯỢC NHAU**, rồi mỗi bên đòi tài nguyên
mà bên kia đang giữ ⇒ **chu trình chờ** (circular wait). InnoDB phát hiện, **chọn một phiên làm nạn nhân và
rollback** (mã **1213** `ER_LOCK_DEADLOCK`) để phá vỡ vòng lặp.

Trong hệ thống: sinh viên tick chọn **nhiều lớp** rồi bấm *"Đăng ký N lớp đã chọn"* → `SP_DangKyNhieuHocPhan`
khóa lần lượt từng dòng sĩ số. Nếu khóa theo **thứ tự tick chọn**, hai sinh viên tick **ngược thứ tự** sẽ deadlock.

---

## 🔧 CONFIG SQL — TÁI HIỆN vs KHẮC PHỤC

**Điểm khác biệt duy nhất nằm ở `KhoaThuTu` của con trỏ (cursor) duyệt danh sách lớp:**

```sql
-- ❌ BẢN CHƯA FIX — con trỏ khóa theo ĐÚNG thứ tự sinh viên tick chọn
DECLARE cur_dk CURSOR FOR SELECT MaLHP FROM TAM_DK_NHIEU ORDER BY KhoaThuTu;
...
INSERT IGNORE INTO TAM_DK_NHIEU (ThuTu, MaLHP, KhoaThuTu)
VALUES (vThuTu, vItem, CONCAT('B', LPAD(vThuTu, 6, '0')));   -- ❌ B + số thứ tự tick

-- ✅ BẢN ĐÃ FIX — con trỏ LUÔN khóa theo MaLHP TĂNG DẦN (thứ tự nhất quán)
INSERT IGNORE INTO TAM_DK_NHIEU (ThuTu, MaLHP, KhoaThuTu)
VALUES (vThuTu, vItem, CONCAT('A', vItem));                  -- ★ A + MaLHP ⇒ mọi phiên CÙNG thứ tự
```

| | Config | File |
|---|---|---|
| ❌ **TÁI HIỆN** | `SP_DangKyNhieuHocPhan` khóa theo thứ tự tick chọn (+ `DO SLEEP(2)` sau khóa đầu để mở rộng cửa sổ) | [`sql_config/deadlock__chua_fix.sql`](sql_config/deadlock__chua_fix.sql) |
| ✅ **KHẮC PHỤC** | `SP_DangKyNhieuHocPhan` khóa theo `MaLHP` tăng dần (+ cùng `DO SLEEP`) | [`sql_config/deadlock__da_fix.sql`](sql_config/deadlock__da_fix.sql) |
| ✅ **KHẮC PHỤC (bổ sung)** | Đặt `innodb_lock_wait_timeout` hợp lý + **retry khi gặp `1213`** | `mysql/procedures/SP_DangKyHocPhan.sql` (đã có vòng `REPEAT … UNTIL`) |

> 💡 **Vì sao `DO SLEEP(2)`?** Thủ tục thật chạy xong trong ~0,3 giây nên cửa sổ chồng lấn chỉ ~150ms —
> người thao tác tay **không thể** bấm kịp. `DO SLEEP` **ngay sau lần khóa đầu tiên** mở rộng cửa sổ lên ~2 giây
> để tái hiện được bằng tay. **Bản chất deadlock không nằm ở SLEEP** mà ở **thứ tự khóa**.
> Hai file `deadlock__chua_fix.sql` / `deadlock__da_fix.sql` có **cùng** `DO SLEEP` ⇒ so sánh hoàn toàn công bằng.

---

# PHẦN A — DEMO BẰNG SQL (2 TAB)

## A.1. TÁI HIỆN: khóa theo thứ tự yêu cầu

### A.1.0. Chuẩn bị (TAB 1)

```sql
CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506');
-- MONG ĐỢI: LHP514 = 15/16 · LHP506 = 0/1 · SV030 có dòng DA_HUY ở LHP514

SET SESSION innodb_lock_wait_timeout = 20;    -- chờ khóa tối đa 20s (thay vì 50s)
```

### A.1.1. Thao tác

**🪟 [TAB 1] — phiên A khóa theo thứ tự LHP514 → LHP506**

```sql
CALL SP_Demo_KhoaTheoThuTu('SV030', 'LHP514,LHP506', 'THEO_YEU_CAU', 3, @kq1);
-- ⏸ Sau khi câu này bắt đầu chạy, nó sẽ GIỮ KHÓA LHP514 và NGỦ 3 GIÂY
--    → CHUYỂN NGAY sang TAB 2
```

**🪟 [TAB 2] — phiên B khóa NGƯỢC LẠI LHP506 → LHP514** *(chạy trong lúc TAB 1 đang ngủ)*

```sql
SET SESSION innodb_lock_wait_timeout = 20;
CALL SP_Demo_KhoaTheoThuTu('SV041', 'LHP506,LHP514', 'THEO_YEU_CAU', 3, @kq2);
-- → ⏳ TREO (chu trình chờ hình thành) rồi InnoDB phá vỡ: một phiên bị rollback
```

**🪟 [TAB 1] / [TAB 2] — đọc kết quả** 📸

```sql
SELECT @kq1 AS MaLoi_CuaSo1, @kq2 AS MaLoi_CuaSo2;

SELECT MaLHP, SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP IN ('LHP514','LHP506');
```

**KẾT QUẢ ĐO THẬT:**

| @kq1 (phiên A) | @kq2 (phiên B) | Thời điểm phát hiện | Sĩ số sau deadlock |
|---|---|---|---|
| **0** | **1213** | ~**6,89 giây** sau khi bắt đầu (gồm 2 lần giữ khóa 3s) | **KHÔNG đổi** (chỉ khóa, không ghi) |

```
⇒ Một phiên nhận 1213 (ER_LOCK_DEADLOCK) — InnoDB tự chọn nạn nhân & rollback
⇒ Deadlock KHÔNG làm sai dữ liệu — nó chỉ phá khả năng xử lý
```

## A.2. ĐÃ FIX: khóa theo thứ tự NHẤT QUÁN (SAP_XEP)

**🪟 [TAB 1]**

```sql
CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506');

CALL SP_Demo_KhoaTheoThuTu('SV030', 'LHP514,LHP506', 'SAP_XEP', 3, @kq1);
-- ⏸ CHUYỂN NGAY sang TAB 2
```

**🪟 [TAB 2]**

```sql
CALL SP_Demo_KhoaTheoThuTu('SV041', 'LHP506,LHP514', 'SAP_XEP', 3, @kq2);
-- ★ Dù người dùng gửi NGƯỢC thứ tự, CON TRỎ tự sắp lại theo MaLHP TĂNG DẦN
--   ⇒ mọi phiên khóa cùng một thứ tự ⇒ KHÔNG THỂ hình thành chu trình chờ
```

**🪟 [TAB 1] / [TAB 2]**

```sql
SELECT @kq1 AS CuaSo1, @kq2 AS CuaSo2;
```

**KẾT QUẢ ĐO THẬT:** `@kq1 = 0` · `@kq2 = 0` — **KHÔNG còn 1213**.

## A.3. LỖI THẬT CỦA HỆ THỐNG: đảo thứ tự khóa giữa ĐĂNG KÝ và HỦY ĐĂNG KÝ

Trong `SP_DangKyHocPhan` (bản cũ): khóa **LOPHOCPHAN** trước → rồi ghi **DANGKYHOCPHAN**.
Trong `SP_HuyDangKy` (bản cũ): khóa **DANGKYHOCPHAN** trước → trigger mới cập nhật **LOPHOCPHAN**.
⇒ **HAI THỨ TỰ NGƯỢC NHAU** — deadlock sinh ra từ **chính nghiệp vụ**, không phải ví dụ nhân tạo.

**🪟 [TAB 1]** — bản **CHƯA FIX**

```sql
SET SESSION innodb_lock_wait_timeout = 20;
CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506');
CALL SP_Demo_PhienGiaoDich('DANG_KY_CHUA_FIX', 'SV030', 'LHP514', 3, @kq1);
-- ⏸ CHUYỂN NGAY sang TAB 2
```

**🪟 [TAB 2]**

```sql
SET SESSION innodb_lock_wait_timeout = 20;
CALL SP_Demo_PhienGiaoDich('HUY_CHUA_FIX', 'SV030', 'LHP514', 3, @kq2);
```

**🪟 [TAB 1] / [TAB 2]** 📸

```sql
SELECT @kq1 AS MaLoi_DangKy, @kq2 AS MaLoi_Huy;
```

**KẾT QUẢ ĐO THẬT:** `@kq1 = 1213` · `@kq2 = 202` (202 = mã nghiệp vụ "không ở trạng thái đăng ký").
⇒ **DEADLOCK sinh ra từ chính nghiệp vụ đăng ký/hủy của hệ thống.**

**Chạy lại với bản ĐÃ FIX** (cùng thứ tự khóa — `SP_HuyDangKy` khóa `LOPHOCPHAN` **trước**):

```sql
-- [TAB 1]
CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506');
CALL SP_Demo_PhienGiaoDich('DANG_KY_DA_FIX', 'SV030', 'LHP514', 3, @kq1);
-- [TAB 2]
CALL SP_Demo_PhienGiaoDich('HUY_DA_FIX', 'SV030', 'LHP514', 3, @kq2);
-- [TAB 1]/[TAB 2]
SELECT @kq1 AS CuaSo1_DaFix, @kq2 AS CuaSo2_DaFix;
```

**KẾT QUẢ ĐO THẬT:** `0` và `0` — **KHÔNG còn 1213**. Hai phiên nối tiếp nhau an toàn.

---

# PHẦN B — DEMO BẰNG THAO TÁC WEB (2 TRÌNH DUYỆT)

### B.0. Nguyên tắc

- 2 phiên đăng nhập riêng: 1 cửa sổ **thường** (sv030) + 1 cửa sổ **Ẩn danh** (sv041).
- Cả hai phải **tick CÙNG 2 lớp** nhưng theo **thứ tự NGƯỢC NHAU**:
  - **A (sv030):** tick **`LHP514`** rồi **`LHP506`**
  - **B (sv041):** tick **`LHP506`** rồi **`LHP514`**
- Rồi bấm **"Đăng ký 2 lớp đã chọn"** gần như cùng lúc (cách nhau ~0,3 giây).

### B.1. Triển khai bản CỐ Ý CÓ LỖI

```bash
cd backend
node scripts/apply-sql.js ../demo/sql_config/deadlock__chua_fix.sql
# → in ra: "[!] DA TRIEN KHAI BAN CO LOI (khoa theo thu tu tick chon)"
```

```sql
CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506');
```

### B.2. Thao tác

| Bước | Trình duyệt A (sv030) | Trình duyệt B (sv041, ẩn danh) |
|---|---|---|
| 1 | Đăng nhập → **Đăng ký lớp học phần** | Đăng nhập → **Đăng ký lớp học phần** |
| 2 | Tick ☑ **LHP514** trước, rồi tick ☑ **LHP506** | Tick ☑ **LHP506** trước, rồi tick ☑ **LHP514** *(cố ý NGƯỢC)* |
| 3 | Hô **"3 – 2 – 1 – ĐĂNG KÝ"** | — |
| 4 | Bấm **"Đăng ký 2 lớp đã chọn"** | Bấm **"Đăng ký 2 lớp đã chọn"** (cách A ~0,3 giây) |
| 5 | ⚠️ Một trong hai nhận **toast ĐỎ**: *"Xung đột khóa (deadlock 1213): giao dịch đăng ký của bạn bị hệ quản trị CSDL hủy để giải phóng deadlock. Vui lòng bấm đăng ký lại."* + dải *"Giao dịch bị hủy (mã 1213)"* | — |

**KẾT QUẢ ĐO THẬT QUA API WEB (bản chưa fix):**

```
[A] sau 2.6s → HTTP 409 · ketQua = 1213 · "Xung đột khóa (deadlock 1213): giao dịch đăng ký của bạn bị
                                            hệ quản trị CSDL hủy để giải phóng deadlock..."
[B] sau 2.6s → HTTP 200 · ketQua = 0    · "Đăng ký học phần thành công."
Sĩ số sau cùng: LHP514 = 15/16 · LHP506 = 1/1   ⇒ deadlock KHÔNG làm sai dữ liệu
```

📸 **Chụp:** màn hình có **toast đỏ 1213** + dải thông báo giao dịch bị hủy.

### B.3. Khôi phục bản ĐÃ FIX rồi làm lại y hệt (giao diện không đổi)

```bash
cd backend
node scripts/apply-sql.js ../demo/sql_config/deadlock__da_fix.sql
```

**KẾT QUẢ ĐO THẬT QUA API WEB (bản đã fix, VẪN giữ `DO SLEEP` để so sánh công bằng):**

```
[A] sau 2.3s → HTTP 200 · ketQua = 0     · "Đăng ký học phần thành công."
[B] sau 4.3s → HTTP 409 · ketQua = 102   · "Không thể đăng ký! Bạn chưa hoàn thành môn tiên quyết..."
                                            (B CHỜ KHÓA ~2 giây rồi mới chạy — nối tiếp an toàn)
Sĩ số sau cùng: LHP514 = 15/16 · LHP506 = 1/1
```

⇒ **KHÔNG còn 1213.** Với bản thật (không SLEEP) cũng vậy: `A = 0` (0,3s) · `B = 102` (0,6s) — chỉ còn lỗi
nghiệp vụ bình thường.

📸 Ảnh đối chứng: **trước fix = toast đỏ 1213 · sau fix = không còn 1213** (chỉ còn thông báo nghiệp vụ 102).

---

## 📸 CHECKLIST ẢNH

- [ ] `SELECT @@innodb_deadlock_detect, @@innodb_lock_wait_timeout, @@tx_isolation;` → `1 · 50 · REPEATABLE-READ`
- [ ] Hai cửa sổ SQL: **`@kq1 = 0` · `@kq2 = 1213`** (PHẦN A.1)
- [ ] Hai cửa sổ SQL: **`@kq1 = 0` · `@kq2 = 0`** sau khi dùng `SAP_XEP` (PHẦN A.2)
- [ ] Lỗi thật: **`@kq1 = 1213` · `@kq2 = 202`** rồi sau fix **`0` · `0`** (PHẦN A.3)
- [ ] Sĩ số **không đổi** sau deadlock (chứng minh deadlock không làm hỏng dữ liệu)
- [ ] **Góc độ người dùng:** toast đỏ **1213** trên web (PHẦN B.2)
- [ ] Đối chứng sau khi khôi phục bản fix: **không còn toast 1213** (PHẦN B.3)

---

## 🧹 DỌN DẸP

```sql
CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506');
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');
CALL SP_ChuanBi_Demo_4Anomaly('LHP506');
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT RELEASE_ALL_LOCKS();
SELECT MaLHP, SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP IN ('LHP514','LHP506');
```

```bash
cd backend
node scripts/apply-sql.js ../mysql/procedures/SP_DangKyNhieuHocPhan.sql   # BẮT BUỘC
node scripts/verify-db.js
```

---

## 📌 GHI CHÚ KỸ THUẬT (nên nói khi trình bày)

1. **Khóa theo thứ tự nhất quán** (*consistent lock ordering*) là cách phòng chống deadlock **triệt để nhất**:
   nếu **mọi** giao tác luôn khóa tài nguyên theo **cùng một thứ tự**, thì **không thể** hình thành chu trình chờ
   ⇒ deadlock bị loại bỏ **từ thiết kế**, không cần retry. Đây là điều `SP_DangKyNhieuHocPhan` đang làm
   (con trỏ sắp `MaLHP` tăng dần bằng `CONCAT('A', vItem)`).
2. **Deadlock không làm hỏng dữ liệu** — các thủ tục demo chỉ **khóa**, không ghi; và khi deadlock xảy ra,
   InnoDB **rollback toàn bộ** giao tác nạn nhân. Vì thế chiến lược **rollback + retry** là hoàn toàn tự nhiên
   (`SP_DangKyHocPhan` đã có vòng `REPEAT … UNTIL` thử lại tối đa 2 lần khi `pKetQua = 1213`).
3. **`innodb_lock_wait_timeout`**: mặc định 50 giây. Nếu **tắt** bộ phát hiện deadlock
   (`SET GLOBAL innodb_deadlock_detect = OFF` — cần quyền `SUPER`, hosting của nhóm **chặn** với lỗi 1227),
   hai phiên sẽ **treo** tới hết timeout rồi nhận **1205 ER_LOCK_WAIT_TIMEOUT**. Có thể demo "treo"
   bằng phương án thay thế: vòng tròn **khóa dòng ↔ `GET_LOCK`** (khóa ứng dụng) — xem
   `docs/concurrency/script_demo_sql.md` PHẦN B.2.2.
