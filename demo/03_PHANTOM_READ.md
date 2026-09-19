# 3️⃣ LỖI ĐỌC BÓNG MA (PHANTOM READ)

> **Chương 4, mục 4.4** · Có **2 cách demo**: **PHẦN A/B — SQL 2 tab** và **PHẦN C — trên WEB CHÍNH**
>
> ⚠️ **PHẦN A/B chỉ chạy trên client GIỮ KẾT NỐI** (Workbench / DBeaver / HeidiSQL / `mysql` CLI).
> Trên **phpMyAdmin**, dùng **`SP_Demo_DocHaiLan`** (xem
> [`02_NON_REPEATABLE_READ.md`](02_NON_REPEATABLE_READ.md) **PHẦN A2** và
> [`sql_config/nrr__tab2phien__sql.sql`](sql_config/nrr__tab2phien__sql.sql)) — cửa sổ 2 thay `UPDATE` bằng
> `INSERT INTO DANGKYHOCPHAN …` rồi xem cột `SoDong_Lan1 → SoDong_Lan2`.

**Bản chất:** một giao tác đọc **một TẬP bản ghi** theo điều kiện; giao tác khác **THÊM / XÓA** bản ghi làm
**thay đổi tập kết quả** giữa hai lần đọc. Khác Non-repeatable Read (dòng cũ **bị đổi giá trị**), ở Phantom
các dòng cũ **không đổi** — mà **tập dòng xuất hiện thêm hoặc mất đi**.

Trong hệ thống: chức năng **đếm/thống kê** — đếm số sinh viên đã đăng ký một lớp, tổng hợp tín chỉ, báo cáo sĩ số…

---

## 🔧 CONFIG SQL — TÁI HIỆN vs KHẮC PHỤC

| | Config SQL | Ý nghĩa |
|---|---|---|
| ❌ **TÁI HIỆN** | `SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;` | Mỗi `SELECT` tạo snapshot mới ⇒ **thấy thêm dòng mới** |
| ✅ **KHẮC PHỤC (chính)** | `SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;` | Snapshot cố định từ lần đọc đầu (MVCC) ⇒ tập kết quả **không đổi** |
| ✅ **KHẮC PHỤC (bổ sung)** | `SELECT … FOR UPDATE;` trên **đúng tập đang đọc** | Khóa **phạm vi** (next-key/gap lock) ⇒ phiên khác **không INSERT được** vào vùng đã khóa |

---

# PHẦN A — TÁI HIỆN LỖI (READ COMMITTED)

### A.0. Chuẩn bị (TAB 1)

```sql
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');

SELECT COUNT(*) AS SoDK FROM DANGKYHOCPHAN
WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';
-- MONG ĐỢI: 15
```

### A.1. Thao tác

**🪟 [TAB 1] — phiên ĐẾM (đã TẮT phòng chống)**

```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;      -- ★ TẮT phòng chống
START TRANSACTION;

SELECT COUNT(*) AS Lan1 FROM DANGKYHOCPHAN
WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';
-- → 15   (lần đếm 1)

-- ⏸ DỪNG. Sang TAB 2 INSERT dòng "bóng ma" rồi quay lại.
```

**🪟 [TAB 2] — phiên GHI**

```sql
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
VALUES ('SV999', 'LHP514', NOW(), 'DA_DANG_KY', 'dong bong ma');
COMMIT;
-- → Query OK, 1 row affected
```

**🪟 [TAB 1] — đếm lần 2 trong CÙNG giao tác** 📸

```sql
SELECT COUNT(*) AS Lan2 FROM DANGKYHOCPHAN
WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';
-- → 16   ← XUẤT HIỆN THÊM 1 DÒNG "BÓNG MA"  ⇒ TÁI HIỆN ĐƯỢC LỖI  📸 chụp ảnh

ROLLBACK;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;     -- trả về mặc định
```

**KẾT QUẢ ĐO THẬT:** lần 1 = **15**, lần 2 = **16** — dòng `SV999` mà phiên A **không hề chèn** lại xuất hiện
trong tập kết quả của A.

---

# PHẦN B — CHỨNG MINH ĐÃ FIX

### B.1. Giữ mức mặc định `REPEATABLE READ` (cách khắc phục chính)

**🪟 [TAB 1]**

```sql
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;     -- ★ giữ mặc định
START TRANSACTION;

SELECT COUNT(*) AS Lan1 FROM DANGKYHOCPHAN
WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';
-- → 15

-- ⏸ DỪNG. Sang TAB 2 INSERT + COMMIT.
```

**🪟 [TAB 2]**

```sql
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
VALUES ('SV999', 'LHP514', NOW(), 'DA_DANG_KY', 'snapshot test');
COMMIT;
```

**🪟 [TAB 1] — đếm lần 2** 📸

```sql
SELECT COUNT(*) AS Lan2 FROM DANGKYHOCPHAN
WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';
-- → 15   ← KHÔNG ĐỔI  ⇒ ĐÃ CHẶN ĐƯỢC LỖI  📸 chụp ảnh

ROLLBACK;

-- Kiểm tra dòng bóng ma ĐÃ được ghi thật vào CSDL:
SELECT COUNT(*) AS SoDK_ThucTe FROM DANGKYHOCPHAN
WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';
-- → 16
```

**KẾT QUẢ ĐO THẬT:** A đếm **15 → 15** dù phiên B **đã ghi thật** (kiểm tra lại từ phiên khác thấy **16**).
Cơ chế: snapshot + **next-key lock** của InnoDB giữ cho tập kết quả ổn định trong suốt giao tác.

### B.2. Khắc phục bổ sung — khóa **PHẠM VI** đang đọc (`FOR UPDATE`) 📸

Đây chính là cơ chế mà `SP_DangKyHocPhan_NangCao` minh họa: khóa **range** giữ tới `COMMIT`, phiên khác
**không thể chèn** vào phạm vi đang đọc.

**🪟 [TAB 1]**

```sql
START TRANSACTION;

SELECT COUNT(*) AS Lan1 FROM DANGKYHOCPHAN
WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY'
FOR UPDATE;                          -- ★ khóa PHẠM VI (các dòng + khoảng trống)
-- → 15

-- ⏸ DỪNG. Sang TAB 2 thử INSERT.
```

**🪟 [TAB 2]**

```sql
START TRANSACTION;
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
VALUES ('SV999', 'LHP514', NOW(), 'DA_DANG_KY', 'thu chen vao pham vi da khoa');
-- → ⏳ TREO — BỊ CHẶN bởi khóa phạm vi (next-key/gap lock)   📸 chụp ảnh
COMMIT;
```

**🪟 [TAB 1]**

```sql
SELECT COUNT(*) AS Lan2 FROM DANGKYHOCPHAN
WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY' FOR UPDATE;
-- → 15   ← KHÔNG ĐỔI (phiên B chưa chen được)

COMMIT;    -- → TAB 2 được chạy tiếp
```

**KẾT QUẢ ĐO THẬT:** INSERT của phiên B **bị chặn 2,63 giây**; A đếm lại vẫn **15**; sau khi cả hai commit,
`COUNT = 16`.

---

## 📸 CHECKLIST ẢNH

- [ ] Lần đếm 1 = **15**, lần đếm 2 = **16** (PHẦN A) — có cả câu `SET … READ COMMITTED`
- [ ] Lần đếm 1 = **15**, lần đếm 2 = **15** (PHẦN B.1) — và ảnh kiểm tra lại thấy **16**
- [ ] TAB 2 hiện trạng thái **treo / chờ khóa** ở B.2 (khóa phạm vi chặn INSERT)

---

## 🧹 DỌN DẸP

```sql
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');                  -- xóa SV999 + trả sĩ số về 15/16
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;  -- BẮT BUỘC
SELECT @@session.transaction_isolation;                   -- REPEATABLE-READ
```

---

## 📌 GHI CHÚ KỸ THUẬT

1. **Phân biệt rõ với Non-repeatable Read:**
   - Non-repeatable Read: **dòng CŨ bị đổi giá trị** (15 → 16 trên cùng một dòng).
   - Phantom Read: **tập dòng thay đổi** — xuất hiện **dòng MỚI** (`SV999`) mà dòng cũ không đổi.
2. **Lưu ý về `SELECT COUNT(*) … FOR UPDATE`:** MariaDB/InnoDB cho phép và nó khóa các dòng **cùng khoảng
   trống** đã quét (next-key lock) — đã đo thực tế: **chặn được INSERT** trong 2,63 giây. Đây là bằng chứng
   mạnh cho phần "phòng chống phantom bằng khóa phạm vi".

---

# PHẦN C — DEMO TRÊN **WEB CHÍNH** BẰNG THAO TÁC TAY (1 SV, 2 cửa sổ)

> Hệ thống **không có màn hình demo nào**. Nút **“Đăng ký N lớp đã chọn”** trên trang
> *Đăng ký lớp học phần* là nút THẬT, chạy **một giao tác** cho cả N lớp.
> Bản lab của `SP_DangKyNhieuHocPhan` cho thủ tục đó **đếm số lớp của sinh viên trong học kỳ HAI LẦN**
> trong chính giao tác (cách nhau 8 giây) rồi “kiểm tra lại”: hai lần đếm lệch nhau ⇒ **hủy giao dịch**.

### C.1. Chuẩn bị

```bash
cd backend
node scripts/apply-sql.js ../demo/sql_config/lab__dangky_nhieu__chua_fix.sql
```

```sql
DELETE FROM DANGKYHOCPHAN WHERE MaSV IN ('SV001','SV003','SV004') AND MaLHP IN ('LHP505','LHP507','LHP508');
UPDATE LOPHOCPHAN lhp SET lhp.SiSoHienTai = (
  SELECT COUNT(*) FROM DANGKYHOCPHAN d WHERE d.MaLHP=lhp.MaLHP AND d.TrangThaiDangKy='DA_DANG_KY')
WHERE lhp.MaLHP IN ('LHP505','LHP507','LHP508');
```

### C.2. Thao tác (2 cửa sổ — **cùng một tài khoản** `sv001`)

| Bước | 🪟 Cửa sổ A (thường) | 🪟 Cửa sổ B (ẩn danh) |
|---|---|---|
| 1 | Đăng nhập **`sv001`** → **Đăng ký lớp học phần** | Đăng nhập **`sv001`** → **Đăng ký lớp học phần** |
| 2 | Tick ☑ **LHP507** và ☑ **LHP508** | Tìm dòng **LHP505 — An toàn thông tin**, để nguyên trang |
| 3 | Bấm **“Đăng ký 2 lớp đã chọn”** → “Đang đăng ký…” | — |
| 4 | *(đang đọc lần 1 rồi ngủ 8 giây)* | **Trong vòng 8 giây đó**, bấm **“Đăng ký”** ở dòng **LHP505** → toast xanh ✅ |
| 5 | Sau ~8 giây: **toast đỏ** + dải cảnh báo | — |

```
⚠️ Giao dịch bị hủy (mã 104)
   Không thể đăng ký! Tổng số tín chỉ vượt quá giới hạn tối đa cho phép.
   Kết quả từng lớp: HỦY OAN — Đối chứng cô lập [LHP507] · sĩ số 0→0 · số lớp của SV trong kỳ 3→4
```

⇒ Cùng MỘT giao tác, cùng một câu `COUNT(*)` mà **lần 1 = 3, lần 2 = 4** — tập kết quả **xuất hiện thêm
một DÒNG BÓNG MA** (dòng `SV001 → LHP505` do cửa sổ B vừa chèn) ⇒ **Phantom Read**. 📸 chụp dải cảnh báo.

> 💡 Lưu ý `sĩ số 0→0` (không đổi) vì cửa sổ B đăng ký một **lớp KHÁC** — đúng bản chất Phantom:
> **dòng CŨ không đổi, chỉ có DÒNG MỚI xuất hiện**.

### C.3. Chứng minh đã fix

```bash
node scripts/apply-sql.js ../demo/sql_config/lab__dangky_nhieu__da_fix.sql
```

Làm lại y hệt C.2 → A nhận **toast XANH**, dòng đối chứng ghi `số lớp của SV trong kỳ 3→3`.

**KẾT QUẢ ĐO THẬT:** `READ COMMITTED` → `3 → 4` ⇒ **HỦY OAN (mã 104)** · `REPEATABLE READ` → `3 → 3` ⇒ **thành công (mã 0)**.

> 📖 Guide đầy đủ (kèm kịch bản Non-repeatable Read cùng nút này): [`06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md`](06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md)
