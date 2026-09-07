# BÁO CÁO DEMO 4 LỖI CONCURRENCY & KIỂM TRA PHÒNG CHỐNG CỦA MySQL

> **Module:** Đăng ký học phần (TV3 — Leader) | **Chương:** 5 — Điều khiển cạnh tranh
> **Tài liệu:** `docs/concurrency/concurrency_anomaly_demo.md`
> **Trạng thái:** ✅ Đã kiểm chứng **trực tiếp trên MySQL remote thật** (free02.123host.vn — MySQL 5.7.41), ngày 06/09/2026.

---

## 1. MỤC TIÊU & KẾT QUẢ KIỂM TRA

| # | Lỗi | Trước khi kiểm tra (trạng thái repo) | Sau khi hoàn thành |
|---|---|---|---|
| 1 | **Lost Update** (Cập nhật mất) | Chỉ mô tả trong `concurrency_test.sql` PHẦN E (chưa chạy được, không có thủ tục "chưa fix") | ✅ Có **thủ tục ban đầu chưa fix lỗi** `SP_DangKyHocPhan_ChuaFix` + demo chạy thật: 17 SV vào lớp 16 chỗ |
| 2 | **Dirty Read** (Đọc bẩn) | ❌ Không có kịch bản | ✅ Demo chạy thật bằng cách **tắt phòng chống**: `READ UNCOMMITTED` |
| 3 | **Unrepeatable Read** (Đọc không lặp lại) | ❌ Không có kịch bản | ✅ Demo chạy thật bằng cách **tắt phòng chống**: `READ COMMITTED` |
| 4 | **Phantom Read** (Đọc bóng ma) | ❌ Chỉ nhắc lý thuyết trong `isolation_level_analysis.md` | ✅ Demo chạy thật bằng cách **tắt phòng chống**: `READ COMMITTED` |
| 5 | Kiểm tra MySQL **đã phòng chống gì** | Chưa kiểm chứng bằng chạy thật | ✅ Chứng minh: mặc định **REPEATABLE-READ** chặn 3/4 lỗi (Dirty, Unrepeatable, Phantom); Lost Update chặn bằng `FOR UPDATE` trong SP + retry 1213 |

**Kết quả chạy tự động cuối cùng: 10/10 PASS** (`node backend/scripts/test-anomaly-live.mjs`).

---

## 2. MYSQL ĐANG PHÒNG CHỐNG GÌ? — CÁCH "TẮT" ĐỂ DEMO

### 2.1 Trạng thái mặc định của MySQL (đã kiểm tra trực tiếp)

```sql
SELECT @@session.transaction_isolation;   -- -> REPEATABLE-READ
SELECT @@global.transaction_isolation;    -- -> REPEATABLE-READ
SELECT VERSION();                         -- -> 5.7.41-cll-lve (shared hosting)
```

| Lỗi | MySQL mặc định (REPEATABLE-READ) có chặn không? | Cơ chế chặn |
|---|---|---|
| Dirty Read | ✅ **CHẶN** | MVCC snapshot: chỉ đọc dữ liệu đã commit (undo log) |
| Unrepeatable Read | ✅ **CHẶN** | Snapshot giữ nguyên trong suốt giao dịch |
| Phantom Read | ✅ **CHẶN** (với SELECT thường) | Consistent snapshot; còn **next-key/gap lock** chặn cả INSERT vào vùng đã khóa |
| Lost Update | ⚠️ **KHÔNG tự chặn** cho "đọc rồi ghi" — phải **khóa dòng** (`SELECT ... FOR UPDATE`) như trong `SP_DangKyHocPhan` | X-lock giữ tới COMMIT |

### 2.2 Cách "TẮT" phòng chống để demo (đúng phương pháp trong slide)

```sql
-- Tắt chặn Dirty Read (hạ xuống mức thấp nhất):
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

-- Tắt chặn Unrepeatable Read & Phantom:
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Lost Update: dùng thủ tục "CHƯA FIX" (thiếu SELECT ... FOR UPDATE)
-- — xem SP_DangKyHocPhan_ChuaFix (mysql/transactions/demo_4_anomaly.sql)

-- Sau demo, trả lại mặc định:
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
```

> ⚠️ `SET SESSION` chỉ ảnh hưởng **phiên hiện tại** — an toàn cho demo, không đụng cấu hình server.

### 2.3 "Thủ tục ban đầu chưa fix lỗi"

`SP_DangKyHocPhan_ChuaFix` (file `mysql/transactions/demo_4_anomaly.sql`):
- **Giống hệt** `SP_DangKyHocPhan` 5 bước kiểm tra (mã lỗi 100–106)…
- **Chỉ khác đúng 1 chỗ — BUOC 6:** đọc sĩ số bằng `SELECT` **thường** thay vì `SELECT ... FOR UPDATE`.
- Hai phiên chạy song song → cùng thấy "còn 1 chỗ" → cùng được chèn → **quá sĩ số**.

---

## 3. KỊCH BẢN GÂY LỖI CHI TIẾT (đã chạy thành công)

### 3.1 LOST UPDATE — "17 sinh viên vào lớp 16 chỗ"

**Bối cảnh:** LHP514 = 15/16 (còn đúng 1 chỗ). SV030 và SV041 cùng bấm đăng ký.

| Bước | Phiên A (SV030) | Phiên B (SV041) |
|---|---|---|
| 1 | `START TRANSACTION` | |
| 2 | `SELECT SiSoHienTai` **(không khóa)** → **15** | |
| 3 | | `START TRANSACTION` |
| 4 | | `SELECT SiSoHienTai` **(không khóa)** → **15** (cùng thấy còn 1 chỗ!) |
| 5 | `INSERT` SV030 (trigger +1, **giữ khóa chưa commit**) | |
| 6 | | `INSERT` SV041 → **BỊ CHẶN** chờ khóa của A (đo thực tế: chờ đúng 4.0s đến khi A commit) |
| 7 | `COMMIT` → sĩ số 15→16 | |
| 8 | | được đi qua, trigger +1 → `COMMIT` |

**Kết quả thực đo:** số bản ghi đăng ký = **17 > SiSoToiDa = 16** → **Lost Update**: cả 2 phiên đều "thắng" vì điều kiện sĩ số được đánh giá trên **dữ liệu cũ**; kiểm tra của phiên A **mất tác dụng**.

**Điểm "nói dối" thú vị:** trigger sĩ số có `LEAST(SiSiToiDa, SiSoHienTai+1)` nên cột `SiSoHienTai` kẹt ở 16 trông có vẻ hợp lệ — **nhưng `COUNT(*)` thực tế = 17**. Dữ liệu hỏng âm thầm, chỉ phát hiện khi đối soát.

**Cơ chế:** hai giao dịch cùng đọc–cùng ghi trên một biến trạng thái mà không ai giữ khóa đọc khi kiểm tra điều kiện → ghi sau đè ghi trước.

**Phòng chống (đã có trong hệ thống):** `SP_DangKyHocPhan` BUOC 6 dùng `SELECT ... FOR UPDATE` → phiên sau chờ, đọc giá trị **mới sau commit** → nhận mã **105 (lớp đã đầy)**. Đã đo thực tế: phiên thua chờ khóa rồi nhận 105, sĩ số cuối đúng 2/2.

### 3.2 DIRTY READ — "Đọc được dữ liệu chưa tồn tại"

**Cách tắt phòng chống:** phiên đọc hạ xuống `READ UNCOMMITTED`.

| Bước | Phiên B (ghi) | Phiên A (đọc — READ UNCOMMITTED) |
|---|---|---|
| 1 | `START TRANSACTION; UPDATE ... SiSoHienTai+1` (15→16, **chưa commit**) | |
| 2 | | `SELECT SiSoHienTai` → **16** ← **ĐỌC BẨN** (dữ liệu chưa commit) |
| 3 | | *(A ra quyết định dựa trên 16)* |
| 4 | `ROLLBACK` — 16 **chưa từng tồn tại** | |
| 5 | | `SELECT` lại → **15** — quyết định trước đó đã sai |

**Kết quả thực đo:** A đọc được **16 khi B chưa commit**, sau rollback giá trị **16 → 15**: dữ liệu bẩn "biến mất", mọi quyết định dựa trên nó vô giá trị.

**Cơ chế:** READ UNCOMMITTED bỏ qua MVCC, đọc **bản ghi hiện hành trong buffer** bất kể đã commit hay chưa.

**Phòng chống:** REPEATABLE-READ (mặc định) — A chỉ thấy **bản snapshot đã commit** (thực đo: thấy 15 đúng).

### 3.3 UNREPEATABLE READ — "Cùng 1 giao tác, 2 kết quả khác nhau"

**Cách tắt phòng chống:** phiên đọc hạ xuống `READ COMMITTED` (khóa đọc chỉ tồn tại trong lúc SELECT).

| Bước | Phiên A (đọc — READ COMMITTED) | Phiên B (ghi) |
|---|---|---|
| 1 | `START TRANSACTION; SELECT SiSoHienTai` → **15** | |
| 2 | | `UPDATE SiSoHienTai+1; COMMIT;` |
| 3 | `SELECT SiSoHienTai` (cùng giao tác) → **16** | |

**Kết quả thực đo:** 15 → **16** trong cùng 1 giao tác → không lặp lại được lần đọc đầu.

**Hệ quả thực tế:** báo cáo trong 1 giao dịch in ra số liệu lệch nhau giữa các trang; kiểm tra "điều kiện rồi ghi" cũng mất tác dụng.

**Cơ chế:** READ COMMITTED tạo **snapshot mới sau mỗi câu SELECT** → giữa 2 SELECT người khác kịp sửa + commit.

**Phòng chống:** REPEATABLE-READ — snapshot giữ nguyên từ lần đọc đầu (thực đo: đọc lại vẫn 15).

### 3.4 PHANTOM READ — "Dòng bóng ma xuất hiện"

**Cách tắt phòng chống:** phiên đọc hạ xuống `READ COMMITTED`.

| Bước | Phiên A (đọc — READ COMMITTED) | Phiên B (ghi) |
|---|---|---|
| 1 | `START TRANSACTION; SELECT COUNT(*)` số SV đã ĐK LHP514 → **15** | |
| 2 | | `INSERT` SV999 vào LHP514; `COMMIT;` |
| 3 | `SELECT COUNT(*)` lại (cùng giao tác) → **16** — xuất hiện **1 dòng bóng ma** | |

**Kết quả thực đo:** COUNT 15 → **16** do dòng SV999 A không hề chèn.

**Cơ chế:** cùng như 3.3 — snapshot đổi sau mỗi SELECT nên "thấy" thêm dòng mới.

**Phòng chống:**
- REPEATABLE-READ: 2 lần COUNT **bằng nhau** (thực đo) nhờ snapshot + InnoDB next-key lock chặn INSERT vào vùng đã khóa.
- Ngoài ra `SP_DangKyHocPhan_NangCao` minh họa khóa range (`FOR UPDATE`) giữ tới commit — phiên khác không chèn được vào phạm vi.

---

## 4. KẾT QUẢ CHẠY TỰ ĐỘNG THỰC TẾ (trích log `test-anomaly-live.mjs`)

```
MySQL 5.7.41-cll-lve — Isolation mặc định: REPEATABLE-READ

PHA 1 — MySQL (RR) ĐANG PHÒNG CHỐNG:
  [1a] Dirty read bị chặn ............ A đọc 15 (giá trị cũ), KHÔNG thấy 16 chưa commit  ✅
  [1b] Unrepeatable read bị chặn ..... đọc lại vẫn 15 dù B đã UPDATE+COMMIT              ✅
  [1c] Phantom bị chặn ............... COUNT không đổi dù B đã INSERT                     ✅

PHA 2 — LOST UPDATE (SP_ChuaFix, không khóa):
  Cả 2 phiên đọc SiSo = 15/15 → cùng được phép đăng ký
  Phiên B bị chặn khóa của A ... chờ 4.0s
  Sau 2 COMMIT: 17 bản ghi ĐK > SiSoToiDa 16 (bộ đếm kẹt 16 vì LEAST clamp)              ✅

PHA 3 — DIRTY READ (READ UNCOMMITTED):
  A đọc = 16 (B chưa commit); B ROLLBACK → giá trị thật 15                                ✅

PHA 4 — UNREPEATABLE READ (READ COMMITTED):
  A đọc lần 1 = 15 → B UPDATE+COMMIT → A đọc lại = 16                                     ✅

PHA 5 — PHANTOM READ (READ COMMITTED):
  A COUNT 15 → B INSERT SV999 + COMMIT → A COUNT lại 16                                   ✅

PHA 6 — SP ĐÃ FIX (FOR UPDATE): 2 phiên giành chỗ cuối
  A = 105 (lớp đầy), B = 0 (thắng), sĩ số cuối = 2/2, không vượt                          ✅

TỔNG KẾT: 10/10 PASS
```

---

## 5. HƯỚNG DẪN DEMO

### 5.1 Chuẩn bị (chạy 1 lần)
```bash
cd backend
node scripts/apply-demo-anomaly.js          # tạo 3 SP demo lên DB remote
node scripts/test-anomaly-live.mjs          # chạy demo tự động toàn bộ (khuyến nghị khi thuyết trình)
```

### 5.2 Demo thủ công 2 cửa sổ (đúng phương pháp slide)
- File: `mysql/transactions/demo_4_anomaly_2cua_so.sql` — mở 2 cửa sổ kết nối, làm theo từng PHẦN A→E; mỗi phần có khối lệnh cho **CỬA SỐ 1** và **CỬA SỐ 2**, dùng `DO SLEEP(n)` để "phóng to" cửa sổ khóa cho bên kia chạy.

### 5.3 Demo qua giao diện web (cộng điểm)
- Đăng nhập **admin** (PĐT) → menu **Concurrency Lab** (trang `/quan-ly/concurrency`).
- API tương ứng: `GET /api/concurrency/trangthai`, `POST /api/concurrency/chuanbi`, `POST /api/concurrency/demo/:ten` (xem `backend/src/routes/concurrency.js`) — chạy **cùng các pha** như script tự động và trả về **dòng thời gian từng bước của 2 phiên** để trình chiếu.

---

## 6. NỘI DUNG GỢI Ý CHO SLIDE

**Slide 1 — Bài toán:** LHP514 còn đúng **1 chỗ**, 2 SV bấm Đăng ký cùng lúc. Điều gì xảy ra?

**Slide 2 — 4 lỗi & khi nào gặp:**
- **Lost Update**: 2 giao dịch cùng *đọc → kiểm tra → ghi* trên cùng dữ liệu → ghi sau đè ghi trước.
- **Dirty Read**: đọc dữ liệu **chưa commit** của giao dịch khác (có thể bị rollback).
- **Unrepeatable Read**: trong 1 giao dịch, đọc **2 lần khác kết quả**.
- **Phantom Read**: tập kết quả **thêm/bớt dòng** giữa 2 lần đọc trong 1 giao dịch.

**Slide 3 — MySQL mặc định phòng được gì?** REPEATABLE-READ + MVCC: chặn Dirty/Unrepeatable/Phantom (SELECT thường). **Lost Update thì KHÔNG** — cần khóa dòng.

**Slide 4 — Làm sao gây được lỗi trên MySQL?** (đã làm trong demo)
1. `SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED` → Dirty Read.
2. `SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED` → Unrepeatable + Phantom.
3. Dùng **thủ tục ban đầu chưa fix** (`SP_DangKyHocPhan_ChuaFix` — không `FOR UPDATE`) → Lost Update.

**Slide 5 — Cơ chế fix của hệ thống:**
- `SP_DangKyHocPhan`: `START TRANSACTION` + `SELECT ... FOR UPDATE` (khóa dòng sĩ số tới COMMIT) = `UPDLOCK+HOLDLOCK` của SQL Server.
- Trigger sĩ số tự ±1; SP **tự retry** khi gặp deadlock 1213 (InnoDB chọn nạn nhân → rollback an toàn → thử lại → nhận 105 rõ ràng).
- Kết quả: 2 phiên giành chỗ cuối → **đúng 1 phiên thắng**, sĩ số không bao giờ vượt.

**Slide 6 — Số liệu thực đo:** bảng PASS/FAIL (mục 4) + ảnh chụp web demo.

---

## 7. CÁC FILE CỦA PHẦN DEMO NÀY

| File | Vai trò |
|---|---|
| `mysql/transactions/demo_4_anomaly.sql` | 3 SP: **ChuaFix** (thủ tục ban đầu lỗi), **ChuanBi**, **NangCao** |
| `mysql/transactions/demo_4_anomaly_2cua_so.sql` | Kịch bản thủ công 2 cửa sổ cho từng lỗi |
| `backend/scripts/apply-demo-anomaly.js` | Áp SP demo (hoặc file SQL bất kỳ) lên DB |
| `backend/scripts/test-anomaly-live.mjs` | Demo tự động 6 pha, in từng bước + PASS/FAIL |
| `backend/src/routes/concurrency.js` + `frontend/src/pages/pdt/ConcurrencyDemo.jsx` | Demo qua web (cộng điểm) |

## 8. GHI CHÚ VỀ DỮ LIỆU

- Toàn bộ demo chỉ tác động `LHP514` (lớp demo) và tối đa 4 SV thử nghiệm (SV030/SV041/SV060/SV999) — kết thúc luôn gọi `SP_ChuanBi_Demo_4Anomaly('LHP514')` để trả về trạng thái "còn 1 chỗ", không làm hỏng dữ liệu gốc.
- SP `SP_DangKyHocPhan` được nâng cấp thêm **retry deadlock (1213)** — hành vi API không đổi (mã 0/100–106), chỉ cải thiện trường hợp 2 phiên tranh khóa.
