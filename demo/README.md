# 🎬 DEMO 4 LỖI ĐIỀU KHIỂN CẠNH TRANH — ĐÓNG GÓI SẴN ĐỂ TRÌNH DIỄN

> **Chương 4** của báo cáo · Module **Đăng ký học phần** · HQTCSDL **MariaDB 11.8.9** (InnoDB)
> Toàn bộ số liệu trong thư mục này là **số ĐO THẬT** trên CSDL của hệ thống (xem [`05_KET_QUA_DO_THUC_TE.md`](05_KET_QUA_DO_THUC_TE.md)).

---

## ⚡ CÁCH NHANH NHẤT — 2 NÚT 1-CLICK (khuyến nghị)

Mở **http://localhost:3000/chuan-bi-demo** (menu **⚙ Chuẩn bị Demo**) → bấm **⚙ CHUẨN BỊ DEMO** là xong
mọi setting: nút này **♻ dựng lại TOÀN BỘ dữ liệu đăng ký của học kỳ hiện tại** về trạng thái xuất phát
(xoá mọi dấu vết của lần demo trước ở **mọi lớp**, mở lại đợt đăng ký nếu bị đóng, tính lại sĩ số, trả
mật khẩu demo…) **rồi** mới triển khai các thủ tục cố ý có lỗi — nên bấm xong là **dùng được ngay**.
Demo xong bấm **✔ FIX** để trả hệ thống về bản chính thức (cũng dựng lại dữ liệu). Trang tự hiển thị
**đang ở bản nào** + chip **✔ SẴN SÀNG SỬ DỤNG** nên không sợ quên.
👉 Chi tiết: [`07_CHUAN_BI_DEMO_1CLICK.md`](07_CHUAN_BI_DEMO_1CLICK.md)

---

## 📋 4 LỖI CẦN DEMO

| # | Lỗi | Kịch bản SQL (2 tab) | Kịch bản WEB (thao tác tay trên web chính) |
|---|---|---|---|
| 1 | **Mất dữ liệu cập nhật (Lost Update)** | [`01_LOST_UPDATE.md`](01_LOST_UPDATE.md) | ✅ 2 SV cùng giành suất cuối |
| 2 | **Không đọc lại được dữ liệu (Non-repeatable Read)** | [`02_NON_REPEATABLE_READ.md`](02_NON_REPEATABLE_READ.md) | ✅ 2 SV, 2 trình duyệt → [`06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md`](06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md) |
| 3 | **Bóng ma (Phantom Read)** | [`03_PHANTOM_READ.md`](03_PHANTOM_READ.md) | ✅ 1 SV, 2 cửa sổ → [`06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md`](06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md) |
| 4 | **Khóa chết (Deadlock)** | [`04_DEADLOCK.md`](04_DEADLOCK.md) | ✅ 2 SV tick lớp ngược thứ tự |

> 💡 **Về Non-repeatable Read & Phantom Read trên web:** hệ thống **không có màn hình demo nào**.
> Nút **“Đăng ký N lớp đã chọn”** (trang *Đăng ký lớp học phần*) là nút thật chạy **một giao tác cho N lớp**;
> bản lab của `SP_DangKyNhieuHocPhan` cho thủ tục này **đọc dữ liệu hai lần trong chính giao tác đó**
> (một DÒNG + một TẬP BẢN GHI) rồi “kiểm tra lại”. Với `READ COMMITTED`, hai lần đọc lệch nhau nếu có
> giao tác khác `COMMIT` ở giữa ⇒ sinh viên **bị hủy oan**; với `REPEATABLE READ` thì hai lần đọc luôn
> giống nhau ⇒ bình thường. Hai con số của 2 lần đọc hiện ngay trên **dải thông báo của trang thật**.
> 👉 Hướng dẫn thao tác tay từng bước: [`06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md`](06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md).

---

## 🗂️ CẤU TRÚC THƯ MỤC

```
demo/
├── README.md                        ← file này: mục lục + cách dùng + bảng kết quả
├── 00_moi_truong_va_chuan_bi.sql    ← CHẠY ĐẦU TIÊN: kiểm tra môi trường + chuẩn bị dữ liệu
├── 01_LOST_UPDATE.md                ← kịch bản demo lỗi 1 (SQL + WEB)
├── 02_NON_REPEATABLE_READ.md        ← kịch bản demo lỗi 2 (SQL)
├── 03_PHANTOM_READ.md               ← kịch bản demo lỗi 3 (SQL)
├── 04_DEADLOCK.md                   ← kịch bản demo lỗi 4 (SQL + WEB)
├── 05_KET_QUA_DO_THUC_TE.md         ← ⭐ bảng số liệu đo thật của cả 4 lỗi
├── 06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md  ← ⭐ GUIDE THAO TÁC TAY trên web: Non-repeatable Read & Phantom Read
├── 07_CHUAN_BI_DEMO_1CLICK.md       ← ⭐ Trang “Chuẩn bị Demo”: 2 nút 1-click, MỖI DEMO 1 LỰA CHỌN RIÊNG
├── 08_DIRTY_READ.md                 ← ⭐ kịch bản demo lỗi 5 (SQL + WEB): đọc dữ liệu CHƯA COMMIT
├── sql_config/                      ← ⭐ CONFIG SQL: bản CỐ Ý CÓ LỖI & bản ĐÃ FIX
│   ├── mariadb__tat_snapshot_isolation.sql  ⚠️ BẮT BUỘC TRÊN MARIADB 11.x — tắt `innodb_snapshot_isolation`
│   ├── prepare__sp.sql              (SP_Prepare_Demo + SP_Prepare_TrangThai — phục vụ trang 1-click)
│   ├── lost_update__chua_fix.sql    (SP_DangKyHocPhan  – thiếu FOR UPDATE)  → tái hiện
│   ├── lost_update__da_fix.sql      (SP_DangKyHocPhan  – có FOR UPDATE)     → fix
│   ├── lost_update__tab2phien__call_sp.sql (kịch bản 2 TAB chạy sẵn — chỉ CALL thủ tục, không gõ tay transaction)
│   ├── nrr__tab2phien__sql.sql      (kịch bản 2 cửa sổ bằng SQL — bản CHẠY ĐƯỢC TRÊN phpMyAdmin)
│   ├── lab__dirty_read__writer__chua_fix.sql (SP_DangKyHocPhan – INSERT → SLEEP 8s → ROLLBACK)      → phiên GHI
│   ├── lab__dirty_read__reader__chua_fix.sql (SP_DangKyNhieuHocPhan – đọc 2 lần @ READ UNCOMMITTED) → ĐỌC BẨN
│   ├── lab__dirty_read__reader__da_fix.sql   (y hệt nhưng @ REPEATABLE READ)                        → đối chứng
│   ├── deadlock__chua_fix.sql       (SP_DangKyNhieuHocPhan – khóa theo thứ tự tick chọn) → tái hiện
│   ├── deadlock__da_fix.sql         (SP_DangKyNhieuHocPhan – khóa theo MaLHP tăng dần)   → fix
│   ├── lab__dangky_nhieu__chua_fix.sql (SP_DangKyNhieuHocPhan đọc 2 lần @ READ COMMITTED) → tái hiện NRR/Phantom
│   └── lab__dangky_nhieu__da_fix.sql   (y hệt nhưng @ REPEATABLE READ)                     → fix NRR/Phantom
└── cong_cu_do/                      ← công cụ ĐO (tùy chọn — chỉ để tự kiểm chứng lại)
    ├── do_thuc_te.mjs               (đo 4 lỗi ở mức SQL)
    ├── do_thuc_te_web.mjs           (đo Lost Update + Deadlock qua API web)
    ├── do_web_2trinhduyet.mjs       (mô phỏng 2 trình duyệt cho NRR/Phantom)
    └── ket_qua_do_raw.md            (kết quả thô do công cụ sinh ra)
```

---

## ⚡ CHUẨN BỊ (làm 1 lần, ~2 phút)

**1. Thông số kết nối CSDL** (điền vào trình biên soạn DB):

| | |
|---|---|
| Host : Port | `0.tcp.ap.ngrok.io` : **21868** |
| User / Password | `admin` / `01656229404aA@` |
| Database | `roacqgfa_dbms` |

> ⚠️ Tunnel ngrok bản free **đổi host:port mỗi lần khởi động lại**. Nếu không kết nối được, xem `backend/.env`.

**2. Kiểm tra môi trường + chuẩn bị dữ liệu:** mở [`00_moi_truong_va_chuan_bi.sql`](00_moi_truong_va_chuan_bi.sql) và chạy toàn bộ.

**2b. ⚠️ TẮT `innodb_snapshot_isolation` (bắt buộc trên MariaDB 11.x — làm 1 lần):**

```bash
cd backend
node scripts/apply-sql.js ../demo/sql_config/mariadb__tat_snapshot_isolation.sql
node scripts/verify-db.js     # phải thấy: innodb_snapshot_isolation = OFF ✅
```

> Vì sao: MariaDB 11.x bật mặc định `innodb_snapshot_isolation = ON` ⇒ ở `REPEATABLE READ`, nó **tự chặn**
> việc ghi đè dòng đã bị giao tác khác sửa bằng lỗi **1020** (`ER_CHECKREAD`). Khi đó kịch bản **Lost Update**
> không tái hiện được mà tab thứ hai báo *“Lỗi hệ thống khi xử lý đăng ký.”* MySQL 8.0 không có cơ chế này.
> Sau khi chạy phải **khởi động lại backend** (connection trong pool giữ giá trị cũ).
> Chi tiết: [`01_LOST_UPDATE.md`](01_LOST_UPDATE.md) mục “⚠️ BẮT BUỘC TRƯỚC KHI DEMO”.

**3. Mở 2 cửa sổ/kết nối** tới CSDL trên (mỗi tab = 1 phiên riêng) — quy ước gọi là **[TAB 1]** và **[TAB 2]**.

**4. Web (cho phần demo trên trình duyệt):**
```bash
cd backend && npm run dev          # backend ở http://localhost:3000
# (tùy chọn) cd frontend && npm run dev   # Vite ở http://localhost:5173
```

> ⚠️ **Muốn dùng địa chỉ `http://localhost:3000/...` như trong tài liệu thì phải BUILD frontend một lần:**
> ```bash
> cd frontend && npm run build      # sinh ra frontend/dist → Express (backend) phục vụ SPA ở cổng 3000
> ```
> `frontend/dist` **không được commit** (nằm trong `.gitignore`), nên máy mới clone về sẽ **404** ở
> `:3000/chuan-bi-demo` cho tới khi build. Chưa build thì dùng thẳng **http://localhost:5173/chuan-bi-demo**
> (Vite dev đã proxy `/api` sang `:3000`). **Sau khi build xong phải khởi động lại backend** (backend chỉ
> kiểm tra `frontend/dist` lúc khởi động).

Tài khoản: `sv030` / `matkhau@123` · `sv041` / `matkhau@123`
Mục 2 & 3 demo bằng thao tác tay trên web - xem `06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md`

---

## 🎯 QUY TRÌNH DEMO GỢI Ý (khoảng 12–15 phút)

| Bước | Nội dung | File |
|---|---|---|
| 1 | **Bấm ⚙ CHUẨN BỊ DEMO** với **đúng kịch bản sắp diễn** — nút tự **♻ refresh toàn bộ dữ liệu học kỳ hiện tại** rồi mới bày thế cờ cho kịch bản (hoặc chạy `00_moi_truong_va_chuan_bi.sql` nếu thích làm tay).<br>⚠️ **Đổi kịch bản ⇒ phải bấm lại** (xem `07_CHUAN_BI_DEMO_1CLICK.md`) | `07_CHUAN_BI_DEMO_1CLICK.md` |
| 2 | **Lost Update** — SQL: hai phiên cùng giành suất cuối ⇒ lớp nhận **17/16** | `01_LOST_UPDATE.md` PHẦN A |
| 3 | **Lost Update** — chứng minh đã fix: `FOR UPDATE` ⇒ phiên sau nhận **105** | `01_LOST_UPDATE.md` PHẦN B |
| 4 | **Lost Update** — WEB: 2 trình duyệt, cả hai **toast xanh** (lỗi) → khôi phục bản fix ⇒ **1 xanh + 1 đỏ 105** | `01_LOST_UPDATE.md` PHẦN C |
| 5 | **Non-repeatable Read** — `READ COMMITTED`: đọc 2 lần ra **15 rồi 16** → `REPEATABLE READ`: **15 rồi 15** | `02_NON_REPEATABLE_READ.md` |
| 6 | **Phantom Read** — `READ COMMITTED`: COUNT **15 rồi 16** → `REPEATABLE READ`: **15 rồi 15** | `03_PHANTOM_READ.md` |
| 7 | **NRR & Phantom trên WEB (thao tác tay)** - 2 trình duyệt: A bị **hủy oan** khi 2 lần đọc lệch (sĩ số 0→1 / số lớp 3→4) → nạp bản đã fix: A **thành công** | `06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md` |
| 8 | **Dirty Read** — WEB/SQL: A đọc được sĩ số mà B **CHƯA COMMIT** (`0→1`) → B `ROLLBACK` ⇒ con số đó là **RÁC**; `REPEATABLE READ` thì **0→0** | `08_DIRTY_READ.md` |
| 9 | **Deadlock** — SQL: khóa ngược thứ tự ⇒ một phiên **1213** → khóa theo thứ tự nhất quán ⇒ **0 và 0** | `04_DEADLOCK.md` PHẦN A |
| 10 | **Deadlock** — WEB: 2 SV tick lớp **ngược thứ tự** ⇒ một SV **toast đỏ 1213** → khôi phục bản fix ⇒ hết | `04_DEADLOCK.md` PHẦN B |
| 11 | **Bấm ✔ FIX** trên trang Chuẩn bị Demo | `07_CHUAN_BI_DEMO_1CLICK.md` |

---

## 📊 BẢNG KẾT QUẢ ĐO THẬT (tóm tắt)

| # | Lỗi | BẢN CHƯA FIX (tái hiện lỗi) | BẢN ĐÃ FIX (chứng minh) |
|---|---|---|---|
| 1 | **Lost Update** | SQL: `COUNT(*) = 17 > SiSoToiDa = 16` (phiên B chờ khóa **2,14s**) · WEB: **cả 2 toast xanh**, `COUNT = 2 > 1` | SQL: phiên B chờ **2,14s** → đọc `16/16` → **mã 105** · WEB: A = **0**, B = **105** |
| 2 | **Non-repeatable Read** | `READ COMMITTED`: đọc lần 1 = **15**, lần 2 = **16** | `REPEATABLE READ`: **15 → 15** · thêm `FOR UPDATE`: phiên ghi bị chặn **1,76s** |
| 3 | **Phantom Read** | `READ COMMITTED`: `COUNT` **15 → 16** | `REPEATABLE READ`: **15 → 15** · khóa phạm vi `FOR UPDATE`: INSERT bị chặn **2,63s** |
| 4 | **Deadlock** | SQL: `@kq1 = 0`, `@kq2 = 1213` · WEB: một SV **1213** (toast đỏ) | SQL: `0` và `0` · WEB: **0** và `102` — **không còn 1213** |
| 5 | **Dirty Read** | WEB: A đọc **`sĩ số 0→1` · `số dòng 0→1`** trong khi B **CHƯA COMMIT** (`ketQua = 104`); sau khi B `ROLLBACK`: `LHP507 = 0/40 · ĐK = 0` ⇒ con số A đọc là **RÁC** | WEB: **`sĩ số 0→0` · `số dòng 0→0`** (`ketQua = 0`) — dữ liệu chưa commit không lọt vào giao tác |

### Riêng các lỗi ĐỌC — đo TRÊN WEB bằng 2 trình duyệt (xem `06_…` và `08_…`)

| Đối tượng đọc | ❌ `READ COMMITTED` | ✅ `REPEATABLE READ` |
|---|---|---|
| MỘT DÒNG — sĩ số lớp `LHP507` | `0 → 1` ⚠️ **A bị hủy oan** | `0 → 0` ✅ A thành công |
| **MỘT DÒNG — điểm tổng kết** | **`5.4 → 9.0`** ⚠️ | `5.4 → 5.4` ✅ |
| MỘT TẬP — số lớp của SV trong kỳ | `3 → 4` ⚠️ **A bị hủy oan** | `3 → 3` ✅ A thành công |
| MỘT TẬP — số ĐK toàn học kỳ (báo cáo) | `232 → 233` ⚠️ | `232 → 232` ✅ |

**Riêng Dirty Read** (dữ liệu **CHƯA COMMIT**) — xem `08_DIRTY_READ.md`:

| Đối tượng đọc | ❌ `READ UNCOMMITTED` | ✅ `REPEATABLE READ` |
|---|---|---|
| MỘT DÒNG — sĩ số `LHP507` + MỘT TẬP — số dòng `DANGKYHOCPHAN` | `sĩ số 0→1` · `số dòng 0→1` ⚠️ **đọc phải dữ liệu RÁC** | `sĩ số 0→0` · `số dòng 0→0` ✅ |

> Chi tiết đầy đủ (câu lệnh, thời gian, số liệu từng pha): [`05_KET_QUA_DO_THUC_TE.md`](05_KET_QUA_DO_THUC_TE.md)

---

## 🔧 CONFIG SQL — TÁI HIỆN vs KHẮC PHỤC

### Bảng đối chiếu nhanh

| Lỗi | Config để **TÁI HIỆN** | Config để **KHẮC PHỤC** |
|---|---|---|
| Lost Update | SP thiếu `FOR UPDATE` (đọc sĩ số bằng `SELECT` thường) | `SELECT … FOR UPDATE` (khóa dòng sĩ số tới `COMMIT`) + retry khi `1213` |
| Non-repeatable Read | `SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;` | `SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;` (mặc định) — hoặc khóa đọc `FOR UPDATE` |
| Phantom Read | `SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;` | `REPEATABLE READ` (MVCC snapshot) — hoặc khóa **phạm vi** `SELECT … FOR UPDATE` |
| Deadlock | Khóa theo **thứ tự tùy ý** (thứ tự người dùng tick chọn) | Khóa theo **thứ tự nhất quán** (sắp `MaLHP` tăng dần) + `innodb_lock_wait_timeout` + retry `1213` |
| Dirty Read | `SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;` ở **phiên đọc** (+ phiên ghi `INSERT` nhưng **KHÔNG** `COMMIT`, sau đó `ROLLBACK`) | `SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;` (mặc định) — chỉ đọc dữ liệu **đã commit** |

### Triển khai / khôi phục bằng dòng lệnh

> 💡 **Nhanh hơn:** trang **⚙ Chuẩn bị Demo** làm hết các bước dưới đây bằng 1 click — mỗi demo một lựa chọn riêng.

```bash
cd backend

# ── TÁI HIỆN LỖI ─────────────────────────────────────────────
node scripts/apply-sql.js ../demo/sql_config/lost_update__chua_fix.sql   # Lost Update (web)
node scripts/apply-sql.js ../demo/sql_config/deadlock__chua_fix.sql      # Deadlock    (web)

# NRR / Phantom (web) — ⚠️ PHẢI nạp kèm SP_DangKyHocPhan BẢN THẬT (không DO SLEEP),
#   nếu không trình duyệt B sẽ commit muộn hơn "lần đọc 2" của A ⇒ không tái hiện được:
node scripts/apply-sql.js ../mysql/procedures/SP_DangKyHocPhan.sql
node scripts/apply-sql.js ../demo/sql_config/lab__dangky_nhieu__chua_fix.sql

# Dirty Read (web) — phiên GHI (INSERT → SLEEP → ROLLBACK) + phiên ĐỌC BẨN:
node scripts/apply-sql.js ../demo/sql_config/lab__dirty_read__writer__chua_fix.sql
node scripts/apply-sql.js ../demo/sql_config/lab__dirty_read__reader__chua_fix.sql

# ── KHẮC PHỤC (BẮT BUỘC chạy lại sau khi demo) ───────────────
node scripts/apply-sql.js ../demo/sql_config/lost_update__da_fix.sql     # = SP_DangKyHocPhan thật
node scripts/apply-sql.js ../demo/sql_config/deadlock__da_fix.sql        # = SP_DangKyNhieuHocPhan thật

# ── Hoặc khôi phục trực tiếp từ nguồn chính thức ─────────────
node scripts/apply-sql.js ../mysql/procedures/SP_DangKyHocPhan.sql
node scripts/apply-sql.js ../mysql/procedures/SP_DangKyNhieuHocPhan.sql

# ── Kiểm tra xem đang ở bản nào ──────────────────────────────
node scripts/verify-db.js
```

> ⚠️ **Bắt buộc khôi phục bản đã fix sau khi demo xong** — nếu không, web sẽ chạy bằng thủ tục cố ý có lỗi.

---

## 🧰 CÔNG CỤ ĐO (tùy chọn — để tự kiểm chứng lại số liệu)

```bash
# Đo cả 4 lỗi ở mức SQL (13 pha, ~90 giây) — tự dọn dẹp sau khi đo
node demo/cong_cu_do/do_thuc_te.mjs

# Đo 2 lỗi qua đúng API mà web gọi (backend phải đang chạy)
node demo/cong_cu_do/do_thuc_te_web.mjs lost-update
node demo/cong_cu_do/do_thuc_te_web.mjs deadlock

# Mô phỏng đúng thao tác 2 trình duyệt cho các lỗi ĐỌC
#   (nạp bản lab tương ứng trước — hoặc để nút ⚙ CHUẨN BỊ DEMO làm hộ)
node demo/cong_cu_do/do_web_2trinhduyet.mjs nrr
node demo/cong_cu_do/do_web_2trinhduyet.mjs phantom
node demo/cong_cu_do/do_web_2trinhduyet.mjs dirty

# Kiểm chứng trang “Chuẩn bị Demo”: cả 5 kịch bản + nút FIX (tự trả về bản chính thức)
node demo/cong_cu_do/do_prepare_1click.mjs
```

Công cụ chỉ **ĐỌC và IN số liệu** — mọi thao tác tay vẫn làm theo các file `01_…` → `04_…`.

---

## ✅ CHECKLIST TRƯỚC KHI TRÌNH DIỄN

- [ ] Đã bấm **⚙ CHUẨN BỊ DEMO** ở http://localhost:3000/chuan-bi-demo **với đúng kịch bản sắp diễn** →
      chip **“Kịch bản đang sẵn sàng”** = kịch bản đó, 2 thẻ trạng thái = 🟡 SẴN SÀNG DEMO
      và khối “Dữ liệu học kỳ hiện tại” = **✔ SẴN SÀNG SỬ DỤNG** (lệch sĩ số 0 · dấu vết demo 0)
- [ ] Đã mở sẵn **2 tab kết nối CSDL**
- [ ] Backend đang chạy ở `http://localhost:3000`
- [ ] Đã mở sẵn 2 cửa sổ cho mục 2 & 3 (1 thường + 1 **ẩn danh**), tài khoản `sv003` / `sv004` / `sv001`
- [ ] Đã mở sẵn **2 trình duyệt** (1 thường + 1 **ẩn danh**) — 2 tab cùng cửa sổ sẽ dùng chung phiên đăng nhập
- [ ] Đã chạy `node scripts/verify-db.js` → `SP_DangKyHocPhan: ✅ ĐÃ FIX`
- [ ] Đã chạy `node scripts/verify-db.js` → **`innodb_snapshot_isolation = OFF ✅`** (nếu thấy `ON`: chạy
      `node scripts/apply-sql.js ../demo/sql_config/mariadb__tat_snapshot_isolation.sql` rồi **khởi động lại backend**)
- [ ] Sau buổi demo: bấm **✔ FIX** trên trang Chuẩn bị Demo → 2 thẻ trạng thái = 🟢 BẢN CHÍNH THỨC
