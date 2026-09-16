# 2️⃣ LỖI KHÔNG ĐỌC LẠI ĐƯỢC DỮ LIỆU (NON-REPEATABLE READ)

> **Chương 4, mục 4.3** · Có **2 cách demo**: **PHẦN A/B — SQL 2 tab** và **PHẦN C — trên WEB CHÍNH**

**Bản chất:** trong **cùng MỘT giao tác**, đọc cùng một dòng dữ liệu **hai lần** nhưng giữa hai lần đọc
có giao tác khác **cập nhật + COMMIT** ⇒ hai lần đọc cho **hai kết quả khác nhau**.

Trong hệ thống: sinh viên mở danh sách lớp và đọc sĩ số LHP514 hai lần trong cùng một phiên làm việc,
giữa hai lần đó có một giao tác khác đăng ký thành công và commit (**15 → 16**).

---

## 🔧 CONFIG SQL — TÁI HIỆN vs KHẮC PHỤC

| | Config SQL | Ý nghĩa |
|---|---|---|
| ❌ **TÁI HIỆN** | `SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;` | **Hạ mức cô lập** ⇒ mỗi câu `SELECT` tạo một snapshot **MỚI** ⇒ thấy thay đổi vừa commit |
| ✅ **KHẮC PHỤC (chính)** | `SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;` | Mức **mặc định của MariaDB/InnoDB**: MVCC snapshot **cố định từ lần đọc đầu tiên** của giao tác |
| ✅ **KHẮC PHỤC (bổ sung)** | `SELECT … FOR UPDATE;` (khóa đọc) | Khi **bắt buộc** phải đọc **giá trị mới nhất**: khóa dòng, phiên khác không ghi được vào giữa 2 lần đọc |

> ⚠️ `SET SESSION` chỉ ảnh hưởng **phiên hiện tại** — an toàn cho demo, không đụng cấu hình server.
> Sau demo **bắt buộc trả về mặc định**: `SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;`

---

# PHẦN A — TÁI HIỆN LỖI (READ COMMITTED)

### A.0. Chuẩn bị (TAB 1)

```sql
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');
SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP='LHP514';   -- 15, 16
```

### A.1. Thao tác

**🪟 [TAB 1] — phiên ĐỌC (đã TẮT phòng chống)**

```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;      -- ★ TẮT phòng chống
START TRANSACTION;

SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';
-- → 15   (lần đọc 1)

-- ⏸ DỪNG tại đây, KHÔNG commit. Sang TAB 2 chạy UPDATE rồi quay lại.
```

**🪟 [TAB 2] — phiên GHI**

```sql
UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP = 'LHP514';
COMMIT;
-- → Query OK, 1 row affected   (15 → 16, đã commit thật)
```

**🪟 [TAB 1] — đọc lần 2 trong CÙNG giao tác** 📸

```sql
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';
-- → 16   ← KHÁC lần đọc 1  ⇒ TÁI HIỆN ĐƯỢC LỖI  📸 chụp ảnh

ROLLBACK;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;     -- trả về mặc định
```

**KẾT QUẢ ĐO THẬT:** lần 1 = **15**, lần 2 = **16** — cùng một giao tác, cùng một ô dữ liệu, **hai giá trị khác nhau**.

**Hệ quả thực tế:** báo cáo trong 1 giao dịch in ra số liệu lệch nhau giữa các trang; việc "kiểm tra điều kiện
rồi ghi" cũng mất tác dụng (đúng cơ chế của Lost Update).

---

# PHẦN B — CHỨNG MINH ĐÃ FIX (REPEATABLE READ)

### B.1. Giữ mức mặc định (cách khắc phục chính)

**🪟 [TAB 1]**

```sql
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;     -- ★ giữ mặc định của InnoDB
START TRANSACTION;

SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';
-- → 15   (lần đọc 1 — snapshot được cố định từ đây)

-- ⏸ DỪNG. Sang TAB 2 UPDATE + COMMIT.
```

**🪟 [TAB 2]**

```sql
UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP = 'LHP514';
COMMIT;
```

**🪟 [TAB 1] — đọc lần 2** 📸

```sql
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';
-- → 15   ← GIỐNG lần 1  ⇒ ĐÃ CHẶN ĐƯỢC LỖI  📸 chụp ảnh

ROLLBACK;
```

**KẾT QUẢ ĐO THẬT:** lần 1 = **15**, lần 2 = **15** dù phiên B **đã UPDATE và COMMIT thật**.
Cơ chế: **MVCC snapshot** — giao tác luôn làm việc trên **một ảnh chụp nhất quán** từ lần đọc đầu tiên.

### B.2. Khắc phục bổ sung — khi BẮT BUỘC cần giá trị mới nhất (`FOR UPDATE`)

**🪟 [TAB 1]**

```sql
START TRANSACTION;

SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP='LHP514' FOR UPDATE;
-- → 15, 16   ★ khóa dòng (X-lock) giữ tới COMMIT

-- ⏸ DỪNG. Sang TAB 2.
```

**🪟 [TAB 2]**

```sql
START TRANSACTION;
UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP = 'LHP514';
-- → ⏳ TREO — BỊ CHẶN, không chen được vào giữa 2 lần đọc của TAB 1   📸 chụp ảnh
COMMIT;
```

**🪟 [TAB 1]**

```sql
COMMIT;    -- → TAB 2 được chạy tiếp
```

**KẾT QUẢ ĐO THẬT:** ghi của phiên B **bị chặn 1,76 giây** cho tới khi A COMMIT rồi mới chạy.

---

## 📸 CHECKLIST ẢNH

- [ ] Lần đọc 1 = **15** và lần đọc 2 = **16** trong cùng giao tác (PHẦN A) — có cả câu `SET … READ COMMITTED`
- [ ] Lần đọc 1 = **15** và lần đọc 2 = **15** (PHẦN B.1) — có cả câu `SET … REPEATABLE READ`
- [ ] TAB 2 hiện trạng thái **treo / chờ khóa** ở B.2
- [ ] (tùy chọn) `SELECT @@session.transaction_isolation;` phải là `REPEATABLE-READ` ở cuối buổi

---

## 🧹 DỌN DẸP

```sql
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');                  -- trả sĩ số về 15/16
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;  -- BẮT BUỘC: trả về mặc định
SELECT @@session.transaction_isolation;                   -- kiểm tra: REPEATABLE-READ
```

---

## 📌 GHI CHÚ KỸ THUẬT

1. **Vì sao dùng `READ COMMITTED` để tái hiện:** mức mặc định `REPEATABLE READ` của MariaDB/InnoDB
   **đã chặn sẵn** lỗi này, nên phải **chủ động hạ mức cô lập** mới nhìn thấy được. Đây chính là
   phương pháp "tắt cơ chế phòng chống để quan sát" trong bài giảng.

---

# PHẦN C — DEMO TRÊN **WEB CHÍNH** BẰNG THAO TÁC TAY (2 trình duyệt)

> Hệ thống **không có màn hình demo nào**. Nút **“Đăng ký N lớp đã chọn”** trên trang
> *Đăng ký lớp học phần* là nút THẬT, chạy **một giao tác** cho cả N lớp.
> Bản lab của `SP_DangKyNhieuHocPhan` cho thủ tục đó **đọc sĩ số lớp HAI LẦN** trong chính giao tác
> (cách nhau 8 giây) rồi “kiểm tra lại”: hai lần đọc lệch nhau ⇒ **hủy giao dịch**.

### C.1. Chuẩn bị

```bash
cd backend
node scripts/apply-sql.js ../demo/sql_config/lab__dangky_nhieu__chua_fix.sql
```

```sql
-- dọn đăng ký thử của tài khoản demo
DELETE FROM DANGKYHOCPHAN WHERE MaSV IN ('SV001','SV003','SV004') AND MaLHP IN ('LHP505','LHP507','LHP508');
UPDATE LOPHOCPHAN lhp SET lhp.SiSoHienTai = (
  SELECT COUNT(*) FROM DANGKYHOCPHAN d WHERE d.MaLHP=lhp.MaLHP AND d.TrangThaiDangKy='DA_DANG_KY')
WHERE lhp.MaLHP IN ('LHP505','LHP507','LHP508');
```

### C.2. Thao tác (2 trình duyệt — 1 thường + 1 ẩn danh)

| Bước | 🪟 Trình duyệt A — `sv003` | 🪟 Trình duyệt B (ẩn danh) — `sv004` |
|---|---|---|
| 1 | **Đăng ký lớp học phần** | **Đăng ký lớp học phần** |
| 2 | Tick ☑ **LHP507 — Hệ điều hành** và ☑ **LHP508 — Lập trình ứng dụng di động** | Tìm dòng **LHP507**, để nguyên trang |
| 3 | Bấm **“Đăng ký 2 lớp đã chọn”** → “Đang đăng ký…” | — |
| 4 | *(đang đọc lần 1 rồi ngủ 8 giây)* | **Trong vòng 8 giây đó**, bấm **“Đăng ký”** ở dòng **LHP507** → toast xanh ✅ |
| 5 | Sau ~8 giây: **toast đỏ** + dải cảnh báo | — |

```
⚠️ Giao dịch bị hủy (mã 104)
   Không thể đăng ký! Tổng số tín chỉ vượt quá giới hạn tối đa cho phép.
   Kết quả từng lớp: HỦY OAN — Đối chứng cô lập [LHP507] · sĩ số 0→1 · số lớp của SV trong kỳ 4→4
```

⇒ Cùng MỘT giao tác, cùng một câu `SELECT` trên cùng một dòng: **lần 1 = 0, lần 2 = 1** ⇒ **Non-repeatable Read**;
sinh viên A **bị hủy oan**. 📸 chụp dải cảnh báo này.

### C.3. Chứng minh đã fix

```bash
node scripts/apply-sql.js ../demo/sql_config/lab__dangky_nhieu__da_fix.sql
```

Làm lại y hệt C.2 → A nhận **toast XANH**, dòng đối chứng ghi `sĩ số 0→0` ⇒ **hai lần đọc giống nhau**.

**KẾT QUẢ ĐO THẬT:** `READ COMMITTED` → `sĩ số 0→1` ⇒ **HỦY OAN (mã 104)** · `REPEATABLE READ` → `sĩ số 0→0` ⇒ **thành công (mã 0)**.

> 📖 Guide đầy đủ (kèm kịch bản Phantom Read cùng nút này): [`06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md`](06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md)
