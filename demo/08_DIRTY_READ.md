# 8️⃣ LỖI ĐỌC DỮ LIỆU BẨN (DIRTY READ)

> **Chương 4, mục 4.2** · Ảnh cần lấy: **Hình 4**
> *"Minh chứng demo Dirty Read: phiên A đọc được sĩ số mà phiên B CHƯA COMMIT — sau khi B ROLLBACK, con số đó không hề tồn tại"*

**Bản chất:** giao tác A đọc dữ liệu do giao tác B **ghi nhưng CHƯA `COMMIT`**. Nếu B `ROLLBACK`
(hủy giao dịch) thì con số A vừa đọc **chưa từng tồn tại** ⇒ A ra quyết định trên **dữ liệu rác**.

Trong hệ thống: sinh viên A nhìn thấy sĩ số lớp đã tăng (tưởng lớp sắp đầy / tưởng có người vừa vào)
trong khi giao dịch của sinh viên B đang dở dang và **sau đó bị hủy**.

> 💡 **Vì sao InnoDB mặc định KHÔNG BAO GIỜ bị lỗi này?**
> Mặc định `REPEATABLE READ` (MVCC) chỉ cho đọc phiên bản **đã commit**.
> Muốn tái hiện phải **hạ mức cô lập xuống `READ UNCOMMITTED`** — đây là điều duy nhất bản lab làm khác.

---

## 🔧 CONFIG SQL — TÁI HIỆN vs KHẮC PHỤC

| | Phiên ĐỌC (`SP_DangKyNhieuHocPhan`) | Phiên GHI (`SP_DangKyHocPhan`) |
|---|---|---|
| ❌ **TÁI HIỆN** | [`lab__dirty_read__reader__chua_fix.sql`](sql_config/lab__dirty_read__reader__chua_fix.sql)<br>`SET SESSION … **READ UNCOMMITTED**` | [`lab__dirty_read__writer__chua_fix.sql`](sql_config/lab__dirty_read__writer__chua_fix.sql)<br>`INSERT → DO SLEEP(8) → **ROLLBACK**` |
| ✅ **KHẮC PHỤC** | [`lab__dirty_read__reader__da_fix.sql`](sql_config/lab__dirty_read__reader__da_fix.sql)<br>`SET SESSION … **REPEATABLE READ**` | *(giữ nguyên — vẫn là phiên ghi chưa commit)* |

**Hai file phiên ĐỌC giống hệt nhau, chỉ khác ĐÚNG 1 DÒNG mức cô lập** ⇒ so sánh hoàn toàn công bằng.

**Vai của từng thủ tục trong kịch bản:**

```
🪟 A — nút “Đăng ký N lớp đã chọn”  →  SP_DangKyNhieuHocPhan  = PHIÊN ĐỌC
                                        (đọc sĩ số 2 lần, cách nhau 8 giây)

🪟 B — nút “Đăng ký” (1 lớp)        →  SP_DangKyHocPhan       = PHIÊN GHI
                                        (INSERT → giữ 8 giây CHƯA commit → ROLLBACK)
```

> ⚠️ Nếu để phiên GHI `COMMIT` thì cùng lắm chỉ là *“đọc sớm”* — **không phải** đọc bẩn.
> Chính `ROLLBACK` mới chứng minh được: con số A đọc là **RÁC**.

---

## 🚀 CHUẨN BỊ (1 CLICK — khuyến nghị)

1. Mở **http://localhost:3000/chuan-bi-demo** (hoặc `:5173`), đăng nhập `admin` / `admin@123`.
2. Ô **“Chuẩn bị cho kịch bản”** → chọn **`④ Dirty Read — đọc dữ liệu CHƯA COMMIT (LHP507)`**.
3. Bấm **⚙ CHUẨN BỊ DEMO** → đọc bảng trạng thái:
   - Thẻ `SP_DangKyHocPhan` = 🟡 *Bản lab Dirty Read — GHI rồi ROLLBACK*
   - Thẻ `SP_DangKyNhieuHocPhan` = 🟡 *Bản lab ĐỌC BẨN — đọc 2 lần @ READ UNCOMMITTED*
   - Chip = **Kịch bản đang sẵn sàng: Dirty Read**

<details>
<summary>Cách chuẩn bị bằng dòng lệnh (nếu không dùng trang web)</summary>

```bash
cd backend
node scripts/apply-sql.js ../demo/sql_config/lab__dirty_read__writer__chua_fix.sql
node scripts/apply-sql.js ../demo/sql_config/lab__dirty_read__reader__chua_fix.sql
```

Kiểm tra nhanh dữ liệu: `LHP507 = 0/40`, `LHP508 = 0/35` và **không** có dòng đăng ký nào của
`SV003`/`SV004` trên 2 lớp này.
</details>

**Tài khoản demo** (mật khẩu `matkhau@123`) — **PHẢI dùng 2 phiên đăng nhập riêng**
(1 cửa sổ thường + 1 cửa sổ **Ẩn danh/InPrivate**):

| Tài khoản | Vai | Vì sao chọn |
|---|---|---|
| `sv003` | 🪟 A — PHIÊN ĐỌC | đủ điều kiện vào LHP507 |
| `sv004` | 🪟 B — PHIÊN GHI (chưa commit) | đủ điều kiện vào LHP507 |

---

# 🅰️ KỊCH BẢN 1 — DEMO TRÊN WEB (2 TRÌNH DUYỆT)

| Bước | 🪟 Trình duyệt A — `sv003` (PHIÊN ĐỌC) | 🪟 Trình duyệt B — `sv004` (PHIÊN GHI) |
|---|---|---|
| 1 | Đăng nhập → menu **Đăng ký lớp học phần** | Đăng nhập → menu **Đăng ký lớp học phần** |
| 2 | Tick ☑ **LHP507 — Hệ điều hành** *(chỉ cần 1 lớp; lab chỉ đọc lớp đầu tiên)* | Tìm dòng **LHP507**, **để nguyên trang** |
| 3 | Bấm **“Đăng ký 1 lớp đã chọn”** → nút chuyển **“Đang đăng ký…”**<br>*(hệ thống đọc lần 1: sĩ số = 0)* | — |
| 4 | ⏸ *(đang ngủ 8 giây)* | **Trong vòng 8 giây đó**, bấm **“Đăng ký”** ở dòng LHP507 → toast XANH ✅<br>*⇒ đã `INSERT` nhưng **CHƯA `COMMIT`** (giữ nguyên 8 giây)* |
| 5 | Sau ~8 giây: A đọc **lần 2** → **dải ĐỎ + toast đỏ** 📸 | *(sau ~10 giây nữa: giao dịch của B tự **ROLLBACK** — dữ liệu biến mất)* |

**A nhìn thấy gì (đây là ảnh cần chụp):**

```
⚠️ Giao dịch bị hủy (mã 104)
   Kết quả từng lớp: ĐỌC BẨN — Đối chứng cô lập [LHP507] · sĩ số 0→1 ·
                     số dòng DANGKYHOCPHAN 0→1
                     ⇒ ĐÃ đọc dữ liệu CHƯA COMMIT của phiên khác
                       (phiên đó ROLLBACK ⇒ con số này là RÁC)
```

⇒ **Cùng một giao tác**, cùng một câu `SELECT` trên cùng một dòng: **lần 1 = 0, lần 2 = 1**.
Con số `1` đó **chưa được commit** ở bất kỳ thời điểm nào — đó là **DIRTY READ**.

### 🧾 Bằng chứng thứ hai — con số đó KHÔNG hề tồn tại

Ngay sau khi cả 2 phiên xong, chạy (hoặc xem bảng “Lớp demo” trên trang Chuẩn bị Demo):

```sql
SELECT lhp.MaLHP, lhp.SiSoHienTai, lhp.SiSoToiDa,
       (SELECT COUNT(*) FROM DANGKYHOCPHAN d
         WHERE d.MaLHP = lhp.MaLHP AND d.TrangThaiDangKy = 'DA_DANG_KY') AS SoDK_ThucTe
FROM LOPHOCPHAN lhp WHERE lhp.MaLHP = 'LHP507';
-- ✅ MONG ĐỢI: LHP507 | 0 | 40 | 0     ← sĩ số về 0, KHÔNG có dòng đăng ký nào
```

📸 **Chụp ảnh ghép:** dải đỏ `sĩ số 0→1` **+** bảng kiểm tra `0/40 · ĐK = 0` ⇒ “A đã đọc một con số
chưa từng tồn tại”.

> 💡 B vẫn thấy toast **XANH “Đăng ký học phần thành công”** — đúng như một giao dịch đang chờ commit.
> Bấm **F5** ở cửa sổ B sau đó: lớp đó **không** nằm trong “Lớp HP đã đăng ký” (vì đã `ROLLBACK`).

---

# 🅱️ KỊCH BẢN 2 — ĐỐI CHỨNG ĐÃ FIX (dải XANH)

Nạp bản phiên ĐỌC ở `REPEATABLE READ` rồi **làm lại y hệt** bước 1→5 ở trên:

```bash
cd backend && node scripts/apply-sql.js ../demo/sql_config/lab__dirty_read__reader__da_fix.sql
```

**A nhìn thấy gì:**

```
✅ Giao dịch đã hoàn tất. — Đăng ký học phần thành công.
   Kết quả từng lớp: KHÔNG ĐỌC BẨN — Đối chứng cô lập [LHP507] · sĩ số 0→0 ·
                     số dòng DANGKYHOCPHAN 0→0
                     ⇒ REPEATABLE READ đã CHẶN dữ liệu chưa commit
```

⇒ hai lần đọc **giống nhau** (`0→0`) — dữ liệu chưa commit **không lọt** vào giao tác của A.
Nạp lại bản chưa fix để diễn lại từ đầu:

```bash
node scripts/apply-sql.js ../demo/sql_config/lab__dirty_read__reader__chua_fix.sql
```

---

# 🅲 KỊCH BẢN 3 (tuỳ chọn) — 2 TAB BẰNG TRÌNH BIÊN SOẠN DB

Không cần web, chỉ cần 2 tab SQL của Workbench/HeidiSQL/DBeaver (mỗi tab là một kết nối riêng).

**🪟 [TAB 2] — PHIÊN GHI: ghi nhưng TUYỆT ĐỐI CHƯA COMMIT**

```sql
SET SESSION innodb_lock_wait_timeout = 20;
START TRANSACTION;

INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
VALUES ('SV004', 'LHP507', NOW(), 'DA_DANG_KY', 'Phien GHI - chua commit');

-- ⏸ DỪNG Ở ĐÂY. Sang TAB 1. (Chưa COMMIT!)
```

**🪟 [TAB 1] — PHIÊN ĐỌC: hạ mức cô lập rồi đọc**

```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;   -- ❌ cho phép đọc dữ liệu chưa commit

SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP = 'LHP507';
-- ❌ → 1, 40   ← ĐỌC BẨN: con số 1 này CHƯA được commit!
```

**🪟 [TAB 2] — hủy giao dịch**

```sql
ROLLBACK;   -- dữ liệu "bẩn" biến mất
```

**🪟 [TAB 1] — đối chứng: mức cô lập mặc định thì KHÔNG đọc được**

```sql
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- Làm lại: TAB 2 INSERT (chưa commit) → TAB 1 SELECT
-- ✅ → 0, 40   ← REPEATABLE READ đã chặn
```

> 📌 TAB 2 nhớ `ROLLBACK` trước khi kết thúc, nếu không dòng `SV004 → LHP507` sẽ nằm lại trong CSDL
> (khi đó bấm **⚙ CHUẨN BỊ DEMO** một lần là sạch).

---

## 📊 KẾT QUẢ ĐO THẬT

Mô phỏng đúng 2 cú bấm qua **API của web** (A bấm trước, B bấm sau 1,5 giây):

| | Phiên ĐỌC A (`sv003`) | Phiên GHI B (`sv004`) | Sau cùng |
|---|---|---|---|
| ❌ **READ UNCOMMITTED** | t = 8,29 s · `ketQua = 104`<br>`ĐỌC BẨN — sĩ số 0→1 · số dòng 0→1` | t = 9,77 s · `ketQua = 0` | **LHP507 = 0/40 · ĐK = 0** ⇒ con số A đọc là RÁC |
| ✅ **REPEATABLE READ** | t = 8,27 s · `ketQua = 0`<br>`KHÔNG ĐỌC BẨN — sĩ số 0→0 · số dòng 0→0` | t = 9,77 s · `ketQua = 0` | LHP507 = 0/40 · ĐK = 0 |

Trong cả hai lần, **phiên GHI đều không để lại dữ liệu** (đã `ROLLBACK`) — nên chỉ có phiên ĐỌC là
khác nhau, đúng bản chất lỗi.

---

## 📸 CHECKLIST ẢNH

- [ ] **Chưa fix**: dải ĐỎ có dòng `ĐỌC BẨN — … sĩ số 0→1 · số dòng DANGKYHOCPHAN 0→1`
- [ ] **Bằng chứng rác**: bảng kiểm tra `LHP507 | 0/40 | ĐK = 0` ngay sau đó
- [ ] Ảnh **2 trình duyệt cạnh nhau** ở bước 4 (A đang “Đang đăng ký…”, B vừa toast xanh)
- [ ] **Đã fix**: dải XANH có dòng `KHÔNG ĐỌC BẨN — … sĩ số 0→0`
- [ ] (tuỳ chọn) 2 tab trình biên soạn DB: TAB 1 đọc ra `1, 40` trong khi TAB 2 chưa `COMMIT`

---

## 🧹 DỌN DẸP (BẮT BUỘC sau khi demo)

Trên trang **Chuẩn bị Demo** bấm **✔ FIX**, hoặc bằng dòng lệnh:

```bash
cd backend
node scripts/apply-sql.js ../mysql/procedures/SP_DangKyHocPhan.sql
node scripts/apply-sql.js ../mysql/procedures/SP_DangKyNhieuHocPhan.sql
node scripts/verify-db.js
```

---

## 📌 GHI CHÚ KỸ THUẬT (nên nói khi trình bày)

1. **Lỗi nằm ở MỨC CÔ LẬP, không nằm ở `DO SLEEP`.** `DO SLEEP(8)` chỉ **mở rộng cửa sổ** để người thao
   tác tay kịp bấm ở cửa sổ kia (thủ tục thật chạy xong trong vài chục ms).
   Bằng chứng: bản đã fix **giữ nguyên `DO SLEEP(8)`** mà lỗi biến mất.
2. **Vì sao phiên GHI phải `ROLLBACK`?** Để chứng minh dứt khoát dữ liệu A đọc là **rác**. Nếu `COMMIT`
   thì con số đó thành thật ⇒ không còn là dirty read.
3. **Vì sao dải đỏ ghi mã `104`?** Đây là **dấu hiệu của phòng lab** (giống bản lab NRR/Phantom dùng `104`
   để báo *HỦY OAN*), không phải lỗi nghiệp vụ. Nội dung thật nằm ở dòng `ChiTiet`:
   `ĐỌC BẨN — …` hoặc `KHÔNG ĐỌC BẨN — …`.
4. **Hai lần đọc nằm TRƯỚC mọi thao tác ghi** của chính giao tác A ⇒ độ lệch **chỉ có thể** đến từ
   giao tác khác (không thể ngụy biện là “do A vừa ghi”).
5. **Thủ tục lab tự trả mức cô lập về `REPEATABLE READ`** trước khi kết thúc — vì backend dùng
   **connection pool**, để mức cô lập không “rò” sang các request sau.
6. **Vì sao mỗi kịch bản phải chuẩn bị riêng?** `SP_DangKyHocPhan` của kịch bản Dirty Read
   (`lab__dirty_read__writer__chua_fix.sql`) là bản **GHI rồi ROLLBACK**, khác hẳn bản *Lost Update*
   (`INSERT → SLEEP → COMMIT`). Bật lẫn nhau là hỏng cả hai màn demo.
