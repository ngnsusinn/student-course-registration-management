# 🎞️ KỊCH BẢN SLIDE DEMO — LỖI ĐIỀU KHIỂN CẠNH TRANH & DEADLOCK

> **Mục đích:** tài liệu này là **kịch bản để dựng PPT** (mỗi mục = 1 slide: nội dung đưa lên slide + lời thoại + lệnh demo + kết quả mong đợi + ảnh cần chèn).
> **Chương 5 — Điều khiển cạnh tranh** · Module **Đăng ký học phần (TV3)** · MySQL **5.7.41-cll-lve** (remote `free02.123host.vn`, InnoDB).
> **Trục trình bày xuyên suốt — 5 câu hỏi cho MỖI lỗi:**
> **①** Lỗi được đề ra là gì? → **②** Đã **config/tắt gì** để tái hiện được lỗi? → **③** Kết quả nhìn thấy là gì? → **④** Khắc phục (fix) thế nào? → **⑤** **Demo lại sau khi fix** ra sao?
>
> **Tài liệu nguồn:** [`script_demo_sql.md`](script_demo_sql.md) · [`concurrency_anomaly_demo.md`](concurrency_anomaly_demo.md) · [`deadlock_demo.md`](deadlock_demo.md) · [`deadlock_analysis.md`](deadlock_analysis.md) · [`kich_ban_demo_thao_tac_that.md`](kich_ban_demo_thao_tac_that.md)

---

## 0. THÔNG TIN DÀN DỰNG (đọc trước khi làm slide)

| Hạng mục | Giá trị |
|---|---|
| Số slide đề xuất | **30 slide** — trình bày **20–25 phút** + 5 phút Q&A |
| Tỉ lệ slide | 16:9 · nền sáng · màu nhấn teal `#008689` (nhận diện UTH) · lỗi = đỏ `#C0392B`, fix = xanh `#1E8E5A` |
| Vai trò khi demo | 1 người thuyết trình + 1 người phụ "CỬA SỔ B" (hoặc tự làm với 2 màn hình) |
| Cửa sổ cần mở sẵn | **Browser A** (`sv030/matkhau@123`), **Browser B** (`sv041/matkhau@123`), **CỬA SỔ A + CỬA SỔ B** (mysql client / 2 tab phpMyAdmin) |
| Quy ước ký hiệu trên slide | ⏸ = cố ý dừng để quan sát · 🎬 = điểm chuyển sang demo trực tiếp · ⚙️ = thao tác "tắt phòng chống" · ✅ = kết quả sau fix |
| Cấu trúc mỗi phần lỗi | **4 slide**: (1) Lỗi & cơ chế → (2) Tắt gì để tái hiện + kết quả → (3) Fix → (4) Demo lại sau fix |
| Ảnh minh chứng | `docs/concurrency/media/` — tên file gợi ý ghi ở từng slide (`D1..D7`, `01..06`); nếu chưa chụp thì để khung "ẢNH SẼ CHÈN" |

### Bảng "ĐÃ CONFIG/TẮT NHỮNG GÌ" — in ra để dán cạnh máy khi demo ⭐

| # | Lỗi cần tái hiện | **Đã tắt/cấu hình gì** | Bằng lệnh nào | Phạm vi ảnh hưởng | **Khôi phục** |
|---|---|---|---|---|---|
| 1 | **Lost Update** | Dùng **bản thủ tục chưa fix** (thiếu `SELECT ... FOR UPDATE`) | `SP_DangKyHocPhan_ChuaFix` *(hoặc gõ tay `INSERT` 2 phiên)* | Chỉ SP demo, không đụng cấu hình server | Chạy lại `SP_DangKyHocPhan` (bản đã fix) — hoặc không cần, vì demo chỉ gọi bản `_ChuaFix` |
| 2 | **Dirty Read** | Hạ mức cô lập **của riêng phiên đọc** xuống mức thấp nhất | `SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;` | **Chỉ phiên hiện tại** (`SET SESSION`) | `SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;` |
| 3 | **Unrepeatable Read** | Hạ mức cô lập phiên đọc (snapshot đổi sau mỗi `SELECT`) | `SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;` | Chỉ phiên hiện tại | `SET SESSION ... REPEATABLE READ;` |
| 4 | **Phantom Read** | Hạ mức cô lập phiên đọc (như trên) | `SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;` | Chỉ phiên hiện tại | `SET SESSION ... REPEATABLE READ;` |
| 5 | **Deadlock — không cho HQTCSDL tự phát hiện** | **Tắt bộ phát hiện deadlock** | `SET GLOBAL innodb_deadlock_detect = OFF;` | ⚠️ **TOÀN SERVER** (biến GLOBAL, không có `SET SESSION`) | **BẬT LẠI NGAY**: `SET GLOBAL innodb_deadlock_detect = ON;` |
| 5b | *Thực tế trên hosting nhóm* | **KHÔNG tắt được** → dùng phương án thay thế: vòng tròn **khóa dòng ↔ `GET_LOCK`** | `GET_LOCK('khoa_ung_dung_deadlock', 8)` + `... FOR UPDATE` | 2 phiên demo | `ROLLBACK;` → `SELECT RELEASE_ALL_LOCKS();` |
| 6 | **Deadlock — bản triển khai có lỗi** | Triển khai **bản SP khóa theo thứ tự tick chọn** | `node scripts/apply-sql.js ../mysql/transactions/demo_deadlock_chuafix.sql` | Chỉ SP `SP_DangKyNhieuHocPhan` | Khôi phục bản fix: `node scripts/apply-sql.js ../mysql/procedures/SP_DangKyNhieuHocPhan.sql` |
| 7 | **Rút ngắn thời gian treo** (không bắt buộc) | Hạ timeout chờ khóa để demo nhanh | `SET SESSION innodb_lock_wait_timeout = 8;` | Chỉ phiên hiện tại | `SET SESSION innodb_lock_wait_timeout = 50;` |

> 🔴 **Quy tắc an toàn bắt buộc nói trên slide:** *"Chỉ có `innodb_deadlock_detect` là biến GLOBAL — tắt là ảnh hưởng mọi phiên, nên bật lại ngay. Mọi thứ còn lại chỉ là `SET SESSION` hoặc đổi phiên bản stored procedure."*

---

# PHẦN I — MỞ ĐẦU (Slide 1–5)

## Slide 01 — Trang bìa

**Trên slide:**
- **CHƯƠNG 5 — ĐIỀU KHIỂN CẠNH TRANH**
- *Lỗi · Cách tái hiện · Cách khắc phục · Demo lại sau khi fix*
- Module Đăng ký học phần — MySQL 5.7.41 (remote) · Node.js/Express · React 18
- Đề tài 6 — Hệ Quản trị Cơ sở dữ liệu · Nhóm … · GVHD …

**Lời thoại:**
> "Nhóm em không demo bằng màn hình giả lập nào. Toàn bộ lỗi được tạo ra **bằng thao tác thật** của sinh viên trên web, hoặc **bằng SQL chạy trực tiếp trên HQTCSDL**. Slide hôm nay đi theo 1 trục: lỗi gì → tắt gì để tái hiện → thấy gì → fix thế nào → **demo lại sau fix**."

**Ảnh:** logo UTH + ảnh chụp trang *Đăng ký lớp học phần* mờ phía sau.

---

## Slide 02 — Bài toán mở màn: "Còn đúng 1 chỗ, 2 sinh viên cùng bấm"

**Trên slide:**
- Lớp **LHP514 — Kết cấu cao tầng K15**: `SiSoHienTai = 15 / SiSoToiDa = 16` → **còn 1 chỗ**
- Lớp **LHP506 — TA chuyên ngành K15**: `1 / 2`
- SV030 và SV041 bấm **Đăng ký** cùng lúc (cách nhau vài trăm ms)
- ❓ Câu hỏi: *điều gì xảy ra nếu tầng ứng dụng/DB không kiểm soát cạnh tranh?*

**Lời thoại:**
> "Đây là câu hỏi mở đầu của Chương 5. Nếu làm sai, hậu quả là **bán quá số chỗ**, hoặc **đọc phải dữ liệu chưa tồn tại**, hoặc **hệ thống treo vì deadlock**."

---

## Slide 03 — Kiến trúc: web chỉ gọi Stored Procedure

**Trên slide (sơ đồ 3 lớp):**
- **React SPA** (19 màn hình) → REST/JWT → **Node.js MVC** (`routes → controllers → models`) → **MySQL 5.7 remote**
- `backend/src/db.js` chỉ có 4 helper: `sp / spMulti / spOut / spOutFull` — **chỉ `CALL SP`**, `pool`/`getConnection` **không được export**
- ⚠️ **Mọi giao tác nằm trong DB** — trong code web **không có màn hình/API/module demo nào**
- Kiểm chứng: `node scripts/audit-no-raw-query.mjs` → sạch 100%

**Lời thoại:**
> "Điểm quan trọng để hiểu cách demo: web **không tự mở transaction**, cũng không có raw query. Vì vậy lỗi concurrency **không thể giấu ở tầng ứng dụng** — nó nằm ở DB, và cách sửa cũng nằm ở DB (stored procedure)."

**Ảnh:** sơ đồ kiến trúc (lấy từ README mục 2).

---

## Slide 04 — Bản đồ 5 lỗi & **MySQL mặc định đã phòng chống gì**

**Trên slide — bảng:**

| Lỗi | MySQL mặc định (`REPEATABLE-READ`) | Cơ chế |
|---|---|---|
| Dirty Read | ✅ **CHẶN** | MVCC snapshot: chỉ đọc dữ liệu **đã commit** |
| Unrepeatable Read | ✅ **CHẶN** | Snapshot giữ nguyên suốt giao dịch |
| Phantom Read | ✅ **CHẶN** (với `SELECT` thường) | Consistent snapshot + next-key/gap lock |
| **Lost Update** | ⚠️ **KHÔNG chặn** với kiểu "đọc → kiểm tra → ghi" | Phải **khóa dòng** `SELECT ... FOR UPDATE` như trong `SP_DangKyHocPhan` |
| **Deadlock** | ⚠️ **Không phòng chống** — chỉ **phát hiện & dọn hậu quả** | Đồ thị chờ → chọn nạn nhân → rollback (**1213**) · cắt chờ → **1205** |

**Lời thoại:**
> "Đây là slide 'chốt' của cả bài: **MySQL đã chặn sẵn 3/4 lỗi concurrency**. Nghĩa là muốn demo 3 lỗi đó, nhóm em **buộc phải chủ động tắt phòng chống**. Riêng Lost Update thì MySQL **không** tự chặn — và deadlock thì HQTCSDL chỉ phát hiện chứ **không phòng chống**."

---

## Slide 05 — Đã config/tắt những gì để demo được lỗi ⭐ (slide quan trọng nhất)

**Trên slide:** (rút gọn bảng ở mục 0 — chỉ để 4 dòng)

| Lỗi | **Tắt gì** | Lệnh | Phạm vi |
|---|---|---|---|
| Dirty Read | Hạ mức cô lập | `SET SESSION ... READ UNCOMMITTED;` | chỉ phiên |
| Unrepeatable + Phantom | Hạ mức cô lập | `SET SESSION ... READ COMMITTED;` | chỉ phiên |
| Lost Update | Dùng **SP chưa fix** (thiếu `FOR UPDATE`) | `SP_DangKyHocPhan_ChuaFix` | chỉ SP demo |
| Deadlock | **Tắt bộ phát hiện** *(bị hosting chặn `1227`)* → thay bằng vòng tròn `GET_LOCK` ↔ khóa dòng; và triển khai **SP khóa theo thứ tự tick chọn** | `SET GLOBAL innodb_deadlock_detect = OFF;` · `demo_deadlock_chuafix.sql` | ⚠️ GLOBAL vs chỉ 1 SP |

**Lời thoại:**
> "Nhóm em nói rõ ngay từ đầu: **demo lỗi thì phải tắt phòng chống**, nhưng tắt có 3 mức độ nguy hiểm khác nhau. An toàn nhất là `SET SESSION` — chỉ ảnh hưởng phiên đang demo. Nguy hiểm nhất là `SET GLOBAL innodb_deadlock_detect = OFF` — ảnh hưởng **toàn server**, nên nếu tắt thì **bật lại ngay**. Trên hosting dùng chung nhóm em **không có quyền `SUPER`**, nên đã chuẩn bị sẵn phương án thay thế."

**Ảnh:** `D3_khong_tat_duoc.png` (lỗi `1227` khi `SET GLOBAL`).

---
---

# PHẦN II — LỖI 1: LOST UPDATE (Slide 6–9)

> 🎤 **Lời dẫn chi tiết để nói khi demo (bản cầm tay, có Q&A dự phòng):**
> [`loi_dan_demo_lost_update.md`](loi_dan_demo_lost_update.md) — khớp với kịch bản **web LHP506 (0/1)** hiện hành.

## Slide 06 — Lost Update: lỗi là gì & vì sao MySQL không tự chặn

**Trên slide:**
- **Định nghĩa:** 2 giao dịch cùng **đọc → kiểm tra → ghi** trên cùng dữ liệu ⇒ bản ghi sau **đè** bản ghi trước ⇒ **một cập nhật bị mất**
- Trong hệ thống: bước 6 của `SP_DangKyHocPhan` kiểm tra `SiSoHienTai < SiSoToiDa`
- Nếu đọc **không khóa**: cả 2 phiên đều thấy *"còn 1 chỗ"* → **cả 2 đều được chèn**
- MySQL **không tự chặn** kiểu này vì đây là "read-then-write" của ứng dụng, MVCC không bảo vệ logic nghiệp vụ

**Lời thoại:**
> "Điểm tinh tế: trigger sĩ số của nhóm có `LEAST(SiSoToiDa, SiSoHienTai+1)` nên cột sĩ số **kẹt ở 16, trông vẫn hợp lệ** — nhưng dữ liệu đã hỏng âm thầm. Đây là lý do phải phòng chống ở **thủ tục**, không trông cậy vào trigger."

---

## Slide 07 — 🎬 DEMO Lost Update (1): **TẮT gì** + kết quả lỗi

**Trên slide — "tắt phòng chống bằng cách dùng bản chưa fix":**
- Đã nạp: `mysql/transactions/demo_4_anomaly.sql` → `SP_DangKyHocPhan_ChuaFix`
- Khác bản thật **đúng 1 chỗ**: bước 6 đọc `SELECT` **thường** thay vì `SELECT ... FOR UPDATE`

**Lệnh demo (2 cửa sổ SQL):**

`[CỬA SỔ A]`
```sql
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');   -- LHP514 = 15/16 (còn đúng 1 chỗ)
-- Hoặc gõ tay như 2 lập trình viên sơ xuất:
SET autocommit=0; START TRANSACTION;
INSERT INTO DANGKYHOCPHAN (MaSV,MaLHP,NgayDangKy,TrangThaiDangKy,GhiChu)
VALUES ('SV030','LHP514',NOW(),'DA_DANG_KY','Demo Lost Update - phien A');
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514';   -- A thấy 15
-- ⏸ DỪNG: A đang giữ khóa ghi dòng LOPHOCPHAN, chưa commit
```

`[CỬA SỔ B]` *(chạy trong lúc A đang dừng)*
```sql
SET autocommit=0; START TRANSACTION;
INSERT INTO DANGKYHOCPHAN (MaSV,MaLHP,NgayDangKy,TrangThaiDangKy,GhiChu)
VALUES ('SV041','LHP514',NOW(),'DA_DANG_KY','Demo Lost Update - phien B');
-- ⏳ TREO — B đang chờ khóa của A  → chỉ tay vào màn hình: "đây là tranh chấp khóa"
```

`[CỬA SỔ A]` → `COMMIT;` · `[CỬA SỔ B]` → `COMMIT;`

**Bằng chứng hỏng dữ liệu:**
```sql
SELECT COUNT(*) AS SoDK_ThucTe,
       (SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514') AS BoDem_SiSo,
       (SELECT SiSoToiDa    FROM LOPHOCPHAN WHERE MaLHP='LHP514') AS SiSoToiDa
FROM DANGKYHOCPHAN WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';
```

**Kết quả mong đợi (LỖI):** `SoDK_ThucTe = 17 > SiSoToiDa = 16`, **bộ đếm vẫn báo 16**.

**Lời thoại:**
> "**17 lượt đăng ký cho 16 chỗ.** Hai giao dịch cùng đọc 'còn 1 chỗ', cùng quyết định cho vào, và bản cập nhật của một bên **bị mất**. Bộ đếm còn 'nói dối' vì bị chặn trần."

**Ảnh:** `07_lost_update_demo.png`.

**Dọn:** `CALL SP_ChuanBi_Demo_4Anomaly('LHP514');`

---

## Slide 08 — Fix Lost Update: khóa dòng `SELECT ... FOR UPDATE`

**Trên slide — code bước 6 (bản đã fix):**
```sql
START TRANSACTION;
  -- ... 5 bước kiểm tra nghiệp vụ (mã 100–104) ...
  SELECT SiSoHienTai, SiSoToiDa
  INTO   vSiSo, vToiDa
  FROM   LOPHOCPHAN
  WHERE  MaLHP = pMaLHP
  FOR UPDATE;              -- ★ X-lock giữ tới COMMIT  (≈ UPDLOCK+HOLDLOCK của SQL Server)
  IF vSiSo >= vToiDa THEN SET pKetQua = 105; ROLLBACK;   -- "Lớp đã đầy sĩ số"
  ELSE INSERT INTO DANGKYHOCPHAN ...; COMMIT; END IF;
```
- Vì sao hiệu quả: phiên sau **phải chờ**, khi được đọc lại thì chỗ **đã hết** → tự trả **mã 105**
- Thêm lớp bảo hiểm: `SP_DangKyHocPhan` có vòng **retry khi gặp deadlock 1213** (tối đa 2 lần)

**Lời thoại:**
> "Fix không phải thêm bảng hay thêm cột — chỉ **đổi 1 câu SELECT thành `FOR UPDATE`**, tức khóa lưu quan đúng dòng sĩ số và **giữ tới lúc COMMIT**. Toàn bộ nằm trong stored procedure nên **mọi client đều được bảo vệ**, kể cả người gọi API trực tiếp."

---

## Slide 09 — ✅ DEMO LẠI SAU FIX (Lost Update)

**Trên slide — "giao diện KHÔNG đổi, chỉ thủ tục trong DB đổi":**

`[CỬA SỔ A]` / `[CỬA SỔ B]` chạy gần như cùng lúc:
```sql
CALL SP_DangKyHocPhan('SV030','LHP514',24,'Phien A - da fix',@kqA);  SELECT @kqA;  -- 0   (thắng)
CALL SP_DangKyHocPhan('SV041','LHP514',24,'Phien B - da fix',@kqB);  SELECT @kqB;  -- 105 (lớp đã đầy)
```

**Và bằng chứng trên WEB THẬT (2 trình duyệt, lớp LHP506 — 1/2 chỗ):**
- Cả 2 bấm **Đăng ký** cùng lúc → 1 bạn ✅ *"Đăng ký học phần thành công."*, bạn kia ❌ **mã 105** *"Lớp học phần đã đầy sĩ số"*
- Kiểm tra: `LHP506 = 2/2`, đúng **2 dòng** `DA_DANG_KY` → **không bao giờ vượt sĩ số**

**Lời thoại:**
> "Đây là **demo lại sau fix**: cùng một thao tác, cùng thời điểm, nhưng lần này **đúng 1 phiên thắng** và phiên thua nhận thông báo nghiệp vụ rõ ràng. Sĩ số cuối = 2/2."

**Ảnh:** `02_phien_1_dang_khoa.png` → `03_phien_2_bi_cho.png` → `05_phien_2_bi_tu_choi.png` (mã 105).

---
---

# PHẦN III — LỖI 2: DIRTY READ (Slide 10–11)

## Slide 10 — Dirty Read: **tắt gì** + kết quả

**Trên slide:**
- **Định nghĩa:** đọc dữ liệu **chưa commit** của giao dịch khác (dữ liệu đó có thể **bị rollback → chưa từng tồn tại**)
- **MySQL mặc định đã chặn** (REPEATABLE-READ + MVCC) ⇒ **phải tắt** mới thấy lỗi
- ⚙️ **Đã tắt:** `SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;` *(chỉ phiên đọc — an toàn)*

**Lệnh demo:**
```sql
-- [CỬA SỔ B] phiên GHI: sửa nhưng CHƯA commit
SET autocommit=0; START TRANSACTION;
UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP='LHP514';   -- 15 → 16, chưa chốt

-- [CỬA SỔ A] phiên ĐỌC — ĐÃ TẮT phòng chống
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;   -- ★ TẮT
START TRANSACTION;
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514';    -- ★ ĐỌC BẨN = 16
DO SLEEP(8);                                                -- ⏸ trong lúc này B ROLLBACK
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514';    -- 15 — giá trị "biến mất"
ROLLBACK;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;    -- ⬅ TRẢ VỀ MẶC ĐỊNH
```

**Kết quả mong đợi (LỖI):** lần 1 thấy **16** (chưa commit) → sau `ROLLBACK` còn **15**.

**Lời thoại:**
> "Sinh viên A ra quyết định dựa trên con số **16 chưa từng tồn tại**. Đây là lý do MySQL mặc định không cho đọc bẩn. Lưu ý nhóm em chỉ `SET SESSION` — **chỉ phiên demo bị hạ mức cô lập**, không đụng cấu hình server."

---

## Slide 11 — ✅ Fix & demo lại: trả về `REPEATABLE-READ`

**Trên slide:**
- **Khắc phục:** *không cần viết gì thêm* — giữ mức mặc định **REPEATABLE-READ**; MVCC chỉ cho đọc **dữ liệu đã commit**
- **Demo lại:** chạy đúng kịch bản trên nhưng **KHÔNG** hạ isolation → A đọc **15** (giá trị cũ hợp lệ), hoàn toàn **không thấy 16** chưa commit

```sql
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;   -- trả về mặc định
START TRANSACTION;
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514';   -- 15 ✅ (B vẫn chưa commit)
ROLLBACK;
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');                   -- dọn về 15/16
```

**Kết quả đo thật:** `[1a] Dirty read bị chặn ........ A đọc 15, KHÔNG thấy 16 chưa commit ✅`

---
---

# PHẦN IV — LỖI 3: UNREPEATABLE READ (Slide 12–13)

## Slide 12 — Unrepeatable Read: **tắt gì** + kết quả

**Trên slide:**
- **Định nghĩa:** trong **cùng 1 giao tác**, đọc cùng một ô dữ liệu **2 lần ra 2 kết quả khác nhau**
- Hệ quả nghiệp vụ: báo cáo/học phí in ra số liệu **mâu thuẫn chính nó**; kiểm tra "điều kiện rồi ghi" mất tác dụng
- ⚙️ **Đã tắt:** `SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;` → snapshot **mới sau mỗi câu `SELECT`**

**Lệnh demo:**
```sql
-- [CỬA SỔ A] phiên ĐỌC — ĐÃ TẮT
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;   -- ★ TẮT
START TRANSACTION;
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514';  -- lần 1: 15
DO SLEEP(8);                                              -- ⏸ B UPDATE + COMMIT
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514';  -- lần 2: 16  ← KHÁC lần 1
ROLLBACK;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
```
```sql
-- [CỬA SỔ B] chạy khi A đang SLEEP
UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP='LHP514';
COMMIT;
```

**Kết quả mong đợi (LỖI):** cùng 1 giao tác đọc **15 rồi 16**.

---

## Slide 13 — ✅ Fix & demo lại: `REPEATABLE-READ` giữ snapshot

**Trên slide:**
- **Khắc phục:** giữ mặc định **REPEATABLE-READ** — snapshot được giữ **từ lần đọc đầu tiên** trong suốt giao dịch
- **Demo lại (không hạ isolation):** A đọc lần 1 = 15 → B `UPDATE + COMMIT` → A đọc lần 2 **vẫn 15** ✅
- Kết quả đo thật: `[1b] Unrepeatable read bị chặn ..... đọc lại vẫn 15 dù B đã UPDATE+COMMIT ✅`

**Lời thoại:**
> "Cùng một kịch bản, chỉ khác **một dòng `SET SESSION`**: khi không tắt phòng chống thì lần đọc thứ hai vẫn là 15 — báo cáo trong cùng giao tác luôn nhất quán."

---
---

# PHẦN V — LỖI 4: PHANTOM READ (Slide 14–15)

## Slide 14 — Phantom Read: **tắt gì** + kết quả

**Trên slide:**
- **Định nghĩa:** giữa 2 lần đọc trong cùng 1 giao tác, **tập kết quả tự nhiên thêm/bớt dòng** ("dòng bóng ma") mà phiên đọc **không hề ghi gì**
- Khác Unrepeatable Read: dữ liệu **cũ không đổi**, mà **số dòng** thay đổi
- ⚙️ **Đã tắt:** `SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;`

**Lệnh demo:**
```sql
-- [CỬA SỔ A] phiên ĐỌC — ĐÃ TẮT
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;   -- ★ TẮT
START TRANSACTION;
SELECT COUNT(*) FROM DANGKYHOCPHAN
 WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';    -- lần 1: 15
DO SLEEP(8);                                               -- ⏸
SELECT COUNT(*) FROM DANGKYHOCPHAN
 WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';    -- lần 2: 16 ← dòng bóng ma
ROLLBACK;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
```
```sql
-- [CỬA SỔ B]
INSERT INTO DANGKYHOCPHAN (MaSV,MaLHP,NgayDangKy,TrangThaiDangKy,GhiChu)
VALUES ('SV999','LHP514',NOW(),'DA_DANG_KY','dong bong ma');
COMMIT;
```

**Kết quả mong đợi (LỖI):** `COUNT` **15 → 16**.

---

## Slide 15 — ✅ Fix & demo lại: snapshot + next-key lock

**Trên slide:**
- **Khắc phục:** mặc định **REPEATABLE-READ** → 2 lần `COUNT` **bằng nhau** nhờ consistent snapshot; InnoDB còn dùng **next-key/gap lock** để chặn `INSERT` vào vùng đã khóa
- Minh họa nâng cao: `SP_DangKyHocPhan_NangCao` khóa **range** bằng `FOR UPDATE` giữ tới `COMMIT` ⇒ phiên khác **không chèn được** vào phạm vi đó
- Kết quả đo thật: `[1c] Phantom bị chặn ............... COUNT không đổi dù B đã INSERT ✅`

**Lời thoại:**
> "Fix ở đây là **không hạ mức cô lập** + thiết kế khóa đúng phạm vi. Đây là lý do nhóm em chọn giữ REPEATABLE-READ cho toàn hệ thống."

---

## Slide 16 — Tổng hợp 4 lỗi concurrency: **tắt gì → trước fix → sau fix**

**Trên slide — bảng chốt (rất nên in ra giấy):**

| # | Lỗi | **Đã tắt gì để demo** | Trước fix (thấy gì) | Sau fix (thấy gì) |
|---|---|---|---|---|
| 1 | **Lost Update** | Dùng `SP_DangKyHocPhan_ChuaFix` (thiếu `FOR UPDATE`) | **17 ĐK > 16 chỗ**, bộ đếm kẹt 16 | 1 phiên **0**, 1 phiên **105**, sĩ số **2/2** |
| 2 | **Dirty Read** | `SET SESSION ... READ UNCOMMITTED` | đọc **16** khi chưa commit → sau rollback còn **15** | chỉ đọc **15** (dữ liệu đã commit) |
| 3 | **Unrepeatable Read** | `SET SESSION ... READ COMMITTED` | cùng giao tác: **15 rồi 16** | cùng giao tác: **15 và 15** |
| 4 | **Phantom Read** | `SET SESSION ... READ COMMITTED` | `COUNT` **15 rồi 16** | `COUNT` **15 và 15** |
| — | **Tổng kết đo thật** | — | — | **10/10 PASS** |

**Lời thoại:**
> "Cột thứ ba là điểm nhấn của phần này: **3 lỗi đầu MySQL đã chặn sẵn — nhóm em phải tắt phòng chống mới demo được**. Lỗi Lost Update thì MySQL **không** chặn, và nhóm em đã vá bằng `SELECT ... FOR UPDATE`."

---
---

# PHẦN VI — DEADLOCK (Slide 17–25)

## Slide 17 — Deadlock: 3 tình huống thật của hệ thống

**Trên slide (3 khối):**
- **(A) Đăng ký nhiều lớp, 2 SV chọn thứ tự ngược nhau**
  `SV030: LHP514 → LHP506` vs `SV041: LHP506 → LHP514` ⇒ chu trình chờ ⇒ **1213**
- **(B) ⭐ LỖI THẬT trong source: đảo thứ tự khóa ĐĂNG KÝ ↔ HỦY**

  | | `SP_DangKyHocPhan` | `SP_HuyDangKy` (bản CŨ) |
  |---|---|---|
  | Khóa 1 | `LOPHOCPHAN` (`FOR UPDATE`) | `DANGKYHOCPHAN` (`JOIN ... FOR UPDATE`) |
  | Khóa 2 | `DANGKYHOCPHAN` | `LOPHOCPHAN` (qua trigger) |
  | Thứ tự | **LOPHOCPHAN → DANGKYHOCPHAN** | **DANGKYHOCPHAN → LOPHOCPHAN** ← *ngược nhau!* |

- **(C) Vòng tròn hai miền khóa:** khóa dòng InnoDB ↔ khóa ứng dụng `GET_LOCK` — **HQTCSDL không thể tự cứu**
- Đủ **4 điều kiện Coffman** (loại trừ lẫn nhau · giữ và chờ · không tiếm quyền · **chờ vòng tròn**)

---

## Slide 18 — HQTCSDL hỗ trợ gì? (đo thật, không suy đoán)

**Trên slide — bảng:**

| Cơ chế InnoDB | Nó làm gì | Bằng chứng nhóm đã chạy |
|---|---|---|
| `innodb_deadlock_detect = ON` | Dựng **đồ thị chờ**, thấy **chu trình** ⇒ tự chọn **nạn nhân** & **ROLLBACK**, trả **`ER_LOCK_DEADLOCK = 1213`** | Phiên B nhận **1213** (phát hiện ~**0,5 s**), phiên A `COMMIT` thành công |
| `innodb_lock_wait_timeout` (mặc định **50 s**) | Không có chu trình (chờ một chiều) ⇒ cắt chờ, trả **`ER_LOCK_WAIT_TIMEOUT = 1205`** | Phiên B nhận **1205** sau **8 s** (đã hạ timeout để demo nhanh) |
| `SELECT ... FOR UPDATE` | Cho ứng dụng **tự quyết định** khóa gì, theo thứ tự nào, giữ bao lâu → nguyên liệu để **tự phòng chống** | `SP_DangKyHocPhan` bước 6 · `SP_Demo_KhoaTheoThuTu` |
| `SHOW ENGINE INNODB STATUS` (`LATEST DETECTED DEADLOCK`) | In ra **đúng 2 giao dịch, đúng câu lệnh** gây deadlock | ⚠️ Cần quyền `PROCESS` — hosting **chặn 1227** |

**Lời thoại (câu chốt):**
> "HQTCSDL **không tự phòng chống deadlock** — nó **phát hiện và dọn hậu quả** (rollback nạn nhân 1213) hoặc **cắt chờ** (1205). Việc *phòng chống* là **trách nhiệm của người thiết kế giao dịch**."

---

## Slide 19 — 🎬 DEMO Deadlock (mặc định): HQTCSDL **tự** phát hiện — **không tắt gì**

**Lệnh demo:**
```sql
-- [CỬA SỔ A] chạy trước
CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506');   -- LHP506 = 1/2 · LHP514 = 15/16 · SV030 có dòng DA_HUY
SET SESSION innodb_lock_wait_timeout = 20;
CALL SP_Demo_KhoaTheoThuTu('SV030','LHP514,LHP506','THEO_YEU_CAU',3,@kq1);   -- ⏸ ngủ 3s, đang giữ LHP514

-- [CỬA SỔ B] chạy trong 3 giây đó
SET SESSION innodb_lock_wait_timeout = 20;
CALL SP_Demo_KhoaTheoThuTu('SV041','LHP506,LHP514','THEO_YEU_CAU',3,@kq2);   -- cố ý NGƯỢC thứ tự

-- [cả 2 cửa sổ]
SELECT @kq1, @kq2;
```

**Kết quả mong đợi:** **đúng 1 phiên = `1213`** (bị chọn làm nạn nhân & rollback), phiên kia = **0**; **sĩ số KHÔNG đổi** (demo chỉ khóa, không ghi).

**Lời thoại:**
> "InnoDB không để hệ thống treo vĩnh viễn — nhưng **phiên thua mất toàn bộ công việc**, nên tầng ứng dụng phải biết mà xử lý."

---

## Slide 20 — ⚙️ **ĐÃ TẮT GÌ** để demo hậu quả "không phát hiện deadlock" ⭐

**Trên slide — 2 nhánh:**

**Nhánh 1 — cách chính thống (khi có quyền `SUPER` / MySQL local):**
```sql
SET GLOBAL innodb_deadlock_detect = OFF;   -- ★ TẮT phát hiện deadlock
-- ... chạy lại đúng 2 lệnh CALL ở slide 19 ...
-- KẾT QUẢ: KHÔNG còn 1213 — CẢ HAI phiên TREO tới hết timeout rồi nhận 1205
SET GLOBAL innodb_deadlock_detect = ON;    -- ⚠️ BẬT LẠI NGAY
```
- `innodb_deadlock_detect` là biến **GLOBAL** — **không có `SET SESSION`** (MySQL trả `ER_GLOBAL_VARIABLE`)
- ⇒ Tắt là **ảnh hưởng mọi phiên trên server** ⇒ **bắt buộc bật lại ngay**

**Nhánh 2 — sự thật đo trên hosting của nhóm (`roacqgfa_dbms`):**
```sql
SET GLOBAL innodb_deadlock_detect = OFF;
-- ERROR 1227 (42000): Access denied; you need (at least one of) the SUPER privilege(s)
```

| Lệnh | Trên hosting nhóm | Ý nghĩa |
|---|---|---|
| `SET GLOBAL innodb_deadlock_detect = OFF` | ❌ **1227** (cần `SUPER`) | **Không tắt được** ⇒ phải có phương án thay thế |
| `SET SESSION innodb_deadlock_detect = OFF` | ❌ `ER_GLOBAL_VARIABLE` | Biến chỉ có ở mức GLOBAL |
| `SET SESSION innodb_lock_wait_timeout = 5` | ✅ được | Bọc thời gian treo — dùng để demo nhanh |
| `SHOW ENGINE INNODB STATUS` / `INNODB_TRX` | ❌ **1227** (cần `PROCESS`) | Không xem được báo cáo deadlock của InnoDB |
| `SHOW FULL PROCESSLIST` | ✅ (thấy thread của mình) | Dùng để **chỉ vào 2 dòng đang treo** |
| `GET_LOCK() / RELEASE_LOCK()` | ✅ | Dùng cho **phương án thay thế** |

**Lời thoại:**
> "Đây là phần **đặc biệt** của bài: nhóm em **không tắt được** cơ chế phòng chống của HQTCSDL vì hosting chia sẻ không cấp quyền `SUPER`. Thay vì bỏ qua, nhóm em **dựng một vòng tròn khóa mà bộ phát hiện không nhìn thấy**."

**Ảnh:** `D3_khong_tat_duoc.png` (màn hình lỗi `1227`).

---

## Slide 21 — 🎬 Phương án thay thế: **khóa DÒNG ↔ khóa ỨNG DỤNG** ⇒ TREO, không ai cứu

**Trên slide (bảng 2 cửa sổ):**

| Bước | CỬA SỔ A | CỬA SỔ B |
|---|---|---|
| 1 | `SET SESSION innodb_lock_wait_timeout = 8;`<br>`START TRANSACTION;`<br>`SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514' FOR UPDATE;` | |
| 2 | | `SELECT GET_LOCK('khoa_ung_dung_deadlock', 0);`<br>`START TRANSACTION;` |
| 3 | `SELECT GET_LOCK('khoa_ung_dung_deadlock', 8);` ⏳ **TREO** | `SELECT SiSoHienTai ... FOR UPDATE;` ⏳ **TREO** |
| 4 | *(cửa sổ thứ 3)* `SHOW FULL PROCESSLIST;` → 1 dòng `User lock` · 1 dòng `statistics` | |
| 5 | sau ~8 s: `GET_LOCK` trả **0** | sau ~8 s: **ERROR 1205** |
| 6 | Dọn: `ROLLBACK;` → `SELECT RELEASE_ALL_LOCKS();` | |

**Lời thoại:**
> "InnoDB chỉ dựng đồ thị chờ cho **khóa dòng/bảng của nó**; `GET_LOCK` là khóa do **ứng dụng đặt tên** — không nằm trong đồ thị đó. Kết quả: **không ai bị chọn làm nạn nhân**, cả 2 phiên treo, người dùng **không thao tác được gì nữa**. Đây đúng là hậu quả của việc 'không có bộ phát hiện'."

**Ghi chú kỹ thuật để ghi điểm:** MySQL 5.7 **có** phát hiện deadlock **giữa các `GET_LOCK` với nhau** (`ER_USER_LOCK_DEADLOCK = 3058`) — nhưng **không** phát hiện vòng tròn **vắt qua hai miền** (`GET_LOCK` ↔ khóa dòng).

**Ảnh:** `D4_treo_khong_thao_tac.png` ⭐ (bắt buộc có).

---

## Slide 22 — Khắc phục (1): thứ tự khóa nhất quán bằng **CON TRỎ**

**Trên slide — code `SP_DangKyNhieuHocPhan` (bản đã fix):**
```sql
-- Bảng tạm: TÍNH SẴN KHÓA SẮP XẾP (không theo thứ tự tick)
INSERT INTO TAM_DK_NHIEU (ThuTu, MaLHP, KhoaThuTu)
VALUES (vThuTu, vItem, CONCAT('A', vItem));          -- ★ 'A' + MaLHP ⇒ tăng dần

DECLARE cur_dk CURSOR FOR
    SELECT MaLHP FROM TAM_DK_NHIEU ORDER BY KhoaThuTu;   -- ★ THỨ TỰ KHÓA = thứ tự con trỏ
OPEN cur_dk;
dk_loop: LOOP
    FETCH cur_dk INTO vMaLHP;
    SELECT lhp.SiSoHienTai, lhp.SiSoToiDa ... FROM LOPHOCPHAN lhp ... 
     WHERE lhp.MaLHP = vMaLHP FOR UPDATE;                 -- ★ X-lock giữ tới COMMIT
END LOOP;
CLOSE cur_dk;
COMMIT;                                                   -- ★ nhả toàn bộ khóa
```

**Bản demo CÓ LỖI khác đúng 1 dòng:**
```sql
-- demo_deadlock_chuafix.sql
KhoaThuTu = CONCAT('B', LPAD(vThuTu, 6, '0'))   -- ★ khóa theo ĐÚNG thứ tự sinh viên tick chọn ⇒ deadlock
```

> **Câu chốt:** *"Thứ tự khóa do **con trỏ** quyết định. Sửa 1 dòng trong `ORDER BY` = hết deadlock, không cần HQTCSDL rollback ai."*

---

## Slide 23 — Khắc phục (2): sửa **lỗi thật** đảo thứ tự khóa + 4 lớp phòng chống

**Trên slide:**
- **Fix lỗi thật:** `SP_HuyDangKy` nay **khóa `LOPHOCPHAN` TRƯỚC** rồi mới đọc `DANGKYHOCPHAN` ⇒ **cùng thứ tự** với `SP_DangKyHocPhan` (bản cũ vẫn giữ để demo qua `SP_Demo_PhienGiaoDich('HUY_CHUA_FIX', ...)`)
- **4 lớp phòng chống/xử lý đang có trong hệ thống:**

| # | Cách | Cài ở đâu | Loại |
|---|---|---|---|
| 1 | **Khóa theo thứ tự nhất quán** (con trỏ tự sắp `MaLHP`) | `SP_DangKyNhieuHocPhan`, `SP_HuyDangKy` (đã sửa), `SP_Demo_KhoaTheoThuTu` (`SAP_XEP`) | **Ngăn ngừa** (chính) |
| 2 | **Giữ khóa ngắn** — chỉ `FOR UPDATE` đúng dòng sĩ số | `SP_DangKyHocPhan` | Ngăn ngừa |
| 3 | **Bọc thời gian chờ** — timeout ngắn + thông báo 1205 | `SET SESSION innodb_lock_wait_timeout` | Giảm thiệt hại |
| 4 | **Chấp nhận + bắt 1213 để RETRY** | `SP_DangKyHocPhan` (retry tối đa 2 lần) | Xử lý |

**Lời thoại:**
> "Nhóm em chọn **cả hai**: **ngăn ngừa** cho deadlock do thiết kế sai thứ tự khóa (sửa 1 lần, hết vĩnh viễn, chi phí lúc chạy bằng 0) và **chấp nhận + retry** cho tranh chấp ngẫu nhiên cùng thứ tự — retry là lưới an toàn chuẩn của mọi hệ giao dịch."

---

## Slide 24 — ✅ DEMO LẠI SAU FIX (góc độ HQTCSDL): `0` và `0`, không còn `1213`

**Lệnh demo:**
```sql
-- [CỬA SỔ A]
CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506');
CALL SP_Demo_KhoaTheoThuTu('SV030','LHP514,LHP506','SAP_XEP',3,@kq1);   -- ★ đổi THEO_YEU_CAU -> SAP_XEP
-- [CỬA SỔ B] chạy trong lúc A ngủ 3s
CALL SP_Demo_KhoaTheoThuTu('SV041','LHP506,LHP514','SAP_XEP',3,@kq2);   -- vẫn tick ngược, nhưng...
-- [cả 2]
SELECT @kq1 AS CuaSo1, @kq2 AS CuaSo2;    -- ✅ 0 và 0 — KHÔNG có 1213
```

**Vì sao:** con trỏ **tự sắp `MaLHP` tăng dần cho mọi phiên** ⇒ không thể hình thành chu trình chờ.

**Và kiểm chứng lỗi thật đã fix:**
```sql
CALL SP_Demo_PhienGiaoDich('DANG_KY_CHUA_FIX','SV030','LHP514',3,@kq1);
CALL SP_Demo_PhienGiaoDich('HUY_CHUA_FIX','SV030','LHP514',3,@kq2);
SELECT @kq1, @kq2;   -- ⚠️ một phiên = 1213  ⇒ BUG THẬT (trước fix)
-- chạy lại với '..._DA_FIX'  ⇒ ✅ không còn 1213
```

---

## Slide 25 — ✅ DEMO LẠI SAU FIX (góc độ NGƯỜI DÙNG — điểm cao hơn)

**Trên slide — bảng log thật 2 lần chạy:**

| | Triển khai bản **CÓ LỖI** (`demo_deadlock_chuafix.sql`) | Sau khi **khôi phục bản đã fix** (`SP_DangKyNhieuHocPhan.sql`) |
|---|---|---|
| Thao tác | A tick **LHP514 → LHP506** · B tick **LHP506 → LHP514**, cùng bấm **“Đăng ký 2 lớp đã chọn”** | **Y hệt, giao diện không đổi 1 dòng** |
| SV030 | **HTTP 409 · ketQua = 1213** — toast đỏ *"Xung đột khóa (deadlock 1213)…"* | HTTP 409 · ketQua = **102** (*“chưa hoàn thành môn tiên quyết”*) — **lỗi nghiệp vụ, không phải deadlock** |
| SV041 | HTTP 200 · ketQua = 0 — *"Đăng ký học phần thành công."* | HTTP 200 · ketQua = 0 |
| Kết luận | ❌ Deadlock **1213** (phát hiện sau ~48 ms) | ✅ **Không còn deadlock** |

**Lệnh chuyển bản:**
```bash
# TRIỂN KHAI bản có lỗi
cd backend && node scripts/apply-sql.js ../mysql/transactions/demo_deadlock_chuafix.sql
# KHÔI PHỤC bản đã fix
node scripts/apply-sql.js ../mysql/procedures/SP_DangKyNhieuHocPhan.sql
```

**Lời thoại:**
> "Đây là điểm mạnh nhất: **ứng dụng không có màn hình demo nào**. Lỗi xuất hiện bằng **thao tác thật của 2 sinh viên** trên trang *Đăng ký lớp học phần*; và sau khi khôi phục bản thủ tục đã fix thì **giao diện không đổi gì mà deadlock biến mất** — chứng minh phòng chống nằm gọn trong database."

**Ảnh:** `D6_web_deadlock.png` ⭐ → `D7_web_da_phong_chong.png`.

---
---

# PHẦN VII — CHỐT (Slide 26–30)

## Slide 26 — Bảng "ĐÃ TẮT GÌ → KHÔI PHỤC THẾ NÀO" (slide an toàn, nên có)

**Trên slide:** dán lại bảng ở **mục 0** (7 dòng) + 3 gạch đầu dòng:
- `SET SESSION ...` → chỉ phiên demo, tự hết khi đóng phiên; vẫn nên `SET SESSION ... REPEATABLE READ;` cho sạch
- Đổi **phiên bản stored procedure** → khôi phục bằng `apply-sql.js` bản đã fix (**bắt buộc** trước khi kết thúc)
- `SET GLOBAL innodb_deadlock_detect = OFF` → **ảnh hưởng toàn server** ⇒ **bật `ON` ngay**; nếu bị `1227` thì dùng phương án `GET_LOCK` và dọn bằng `RELEASE_ALL_LOCKS()`

**Script dọn dẹp cuối buổi (PHẦN D):**
```sql
CALL SP_ChuanBi_Demo_4Anomaly('LHP514');
CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506');
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET SESSION innodb_lock_wait_timeout = 50;
SELECT RELEASE_ALL_LOCKS();
SELECT MaLHP, SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP IN ('LHP514','LHP506');
```

---

## Slide 27 — Kết quả đo thật (log dán lên slide)

**Trên slide — khối log:**
```
MySQL 5.7.41-cll-lve · innodb_deadlock_detect = ON · lock_wait = 50s · REPEATABLE-READ

4 LỖI CONCURRENCY (10/10 PASS)
  [1a] Dirty read bị chặn ............ A đọc 15, KHÔNG thấy 16 chưa commit      ✅
  [1b] Unrepeatable read bị chặn ..... đọc lại vẫn 15 dù B đã UPDATE+COMMIT      ✅
  [1c] Phantom bị chặn ............... COUNT không đổi dù B đã INSERT            ✅
  [P2] LOST UPDATE (SP_ChuaFix) ...... 17 bản ghi ĐK > SiSoToiDa 16 (kẹt 16)     ✅
  [P3] DIRTY READ (READ UNCOMMITTED) . A đọc 16 khi B chưa commit                ✅
  [P4] UNREPEATABLE (READ COMMITTED) . 15 rồi 16                                 ✅
  [P5] PHANTOM (READ COMMITTED) ...... COUNT 15 rồi 16                           ✅
  [P6] SP ĐÃ FIX (FOR UPDATE) ........ A = 105, B = 0, sĩ số cuối 2/2            ✅

DEADLOCK (6/6 + 13/13 PASS)
  co-che            ✅ không có SUPER → không tắt được innodb_deadlock_detect (1227)
  detector-bat      ✅ 1213 sau ~2050ms, phiên kia hoàn tất
  treo-khong-cuu    ✅ cả 2 treo 9.0s · PROCESSLIST: "User lock" / "statistics" · 1205
  loi-he-thong      ✅ tái hiện deadlock 1213 từ nghiệp vụ đăng ký/hủy
  ngan-ngua-thu-tu  ✅ cùng tình huống, KHÔNG có 1213
  retry-1213        ✅ lần 1 dính 1213 → lần 2 thành công
  API E2E deadlock  ✅ 13 PASS / 0 FAIL (2 trình duyệt thật)
```

---

## Slide 28 — Câu hỏi giảng viên hay hỏi (chuẩn bị sẵn)

**Trên slide — 5 câu + đáp án ngắn:**

1. **Vì sao bộ đếm sĩ số kẹt ở 16 dù 17 người đăng ký?** → Trigger dùng `LEAST(SiSoToiDa, SiSoHienTai+1)` nên bị chặn trần; bản ghi thật vẫn chèn ⇒ **hỏng âm thầm** ⇒ phải phòng chống ở thủ tục, không trông cậy trigger.
2. **`FOR UPDATE` đặt ở đâu?** → Bước 6 `SP_DangKyHocPhan`: `SELECT SiSoHienTai ... FOR UPDATE` **bên trong** `START TRANSACTION ... COMMIT`.
3. **Vì sao `SET GLOBAL` mà không `SET SESSION` cho `innodb_deadlock_detect`?** → Là biến **GLOBAL**; `SET SESSION` báo `ER_GLOBAL_VARIABLE`. Hệ quả: tắt là ảnh hưởng mọi phiên ⇒ phải bật lại ngay; hosting không có `SUPER` nên **không tắt được** → dùng phương án `GET_LOCK` ↔ khóa dòng.
4. **Không tắt được thì làm sao chứng minh hậu quả của việc không phát hiện?** → Tạo vòng tròn **vắt qua hai miền khóa** ⇒ không bộ phận nào thấy đủ chu trình ⇒ **không ai bị rollback**, cả 2 phiên treo tới timeout (PROCESSLIST: `User lock` / `statistics`).
5. **Deadlock có làm hỏng dữ liệu như Lost Update không?** → **Không.** InnoDB rollback **toàn bộ** giao dịch nạn nhân (ACID); cái mất là **công việc của phiên bị hủy**. Khác hẳn Lost Update (17 SV vào lớp 16 chỗ).

*(Thêm: "READ COMMITTED tốt hơn sao còn phải đổi?" → Đổi là để **tái hiện lỗi** cho mục đích giảng dạy; hệ thống thật giữ REPEATABLE-READ + khóa lưu quan.)*

---

## Slide 29 — Kết luận: 3 thông điệp

**Trên slide:**
1. **MySQL 5.7 (REPEATABLE-READ) đã chặn sẵn 3/4 lỗi concurrency** — muốn demo phải **chủ động tắt** (`SET SESSION` isolation) ⇒ tắt an toàn, chỉ ảnh hưởng phiên.
2. **Lost Update là lỗi thật của hệ thống** nếu thiếu khóa lưu quan → đã vá bằng **`SELECT ... FOR UPDATE`** trong `SP_DangKyHocPhan`; kết quả sau fix: **đúng 1 phiên thắng, sĩ số không bao giờ vượt**.
3. **Deadlock: HQTCSDL phát hiện & dọn hậu quả (1213/1205) nhưng KHÔNG phòng chống, và có "điểm mù"** (khóa dòng ↔ `GET_LOCK`). Nhóm **phòng chống bằng khóa theo thứ tự nhất quán (CON TRỎ)** + **chấp nhận & retry 1213**.
   👉 **Toàn bộ phòng chống nằm trong database** — web chỉ gọi stored procedure.

**Lời thoại kết:**
> "Điểm nhóm em muốn nhấn: **sửa lỗi không đụng vào giao diện**. Cùng một cú bấm của sinh viên — trước fix là deadlock 1213 hoặc 17 SV vào lớp 16 chỗ; sau fix là thông báo nghiệp vụ sạch. Đó là sức mạnh của việc đưa toàn bộ giao tác vào stored procedure."

---

## Slide 30 — Phụ lục: file & minh chứng cần chèn

**Trên slide — bảng file:**

| File | Vai trò |
|---|---|
| `mysql/transactions/demo_4_anomaly.sql` | 3 SP: `SP_DangKyHocPhan_ChuaFix` (**bản chưa fix**) · `SP_ChuanBi_Demo_4Anomaly` · `SP_DangKyHocPhan_NangCao` |
| `mysql/procedures/SP_DangKyHocPhan.sql` | Bản **đã fix**: `FOR UPDATE` + retry `1213` |
| `mysql/procedures/SP_HuyDangKy.sql` | **Đã sửa lỗi đảo thứ tự khóa** (khóa `LOPHOCPHAN` trước) |
| `mysql/procedures/SP_DangKyNhieuHocPhan.sql` | Bản fix: **CON TRỎ** sắp `MaLHP` tăng dần |
| `mysql/transactions/demo_deadlock_chuafix.sql` | ⚠️ Bản **có lỗi** (khóa theo thứ tự tick) — nguồn deadlock trên web |
| `mysql/transactions/demo_deadlock.sql` | `SP_Demo_KhoaTheoThuTu` · `SP_Demo_PhienGiaoDich` · `SP_ChuanBi_Demo_Deadlock` |
| [`docs/concurrency/script_demo_sql.md`](script_demo_sql.md) | ⭐ Toàn bộ script SQL (PHẦN A/B/C/D) |

**Ảnh cần chụp/chèn (đặt trong `docs/concurrency/media/`):** `D1_bien_he_thong.png` · `D2_loi_1213.png` · `D3_khong_tat_duoc.png` (1227) · `D4_treo_khong_thao_tac.png` ⭐ · `D5_da_fix_thu_tu_khoa.png` · `D6_web_deadlock.png` ⭐ · `D7_web_da_phong_chong.png` · `01..06` (2 phiên tranh chỗ cuối) · `07_lost_update_demo.png`

---

# 📋 DÀN BÀI 1 TRANG (in mang theo khi lên lớp)

| Slide | Nội dung | Việc phải làm trên lớp |
|---|---|---|
| 1–5 | Mở đầu · bài toán · kiến trúc · **bản đồ phòng chống** · **bảng đã tắt gì** | nói, chưa demo |
| 6 | Lost Update: lỗi & cơ chế | nói |
| 7 | 🎬 Lost Update **xảy ra** | 2 cửa sổ SQL: `SP_ChuanBi_Demo_4Anomaly` → INSERT 2 phiên → `COUNT = 17 > 16` |
| 8 | Fix `FOR UPDATE` (+ retry 1213) | chiếu code |
| 9 | ✅ Demo lại sau fix | 2 cửa sổ `CALL SP_DangKyHocPhan` → `0` / `105`; **2 trình duyệt LHP506** → 1 thành công, 1 mã 105 |
| 10–11 | Dirty Read: tắt `READ UNCOMMITTED` → 16 rồi 15 → fix RR | 2 cửa sổ SQL, `DO SLEEP(8)` |
| 12–13 | Unrepeatable Read: tắt `READ COMMITTED` → 15 rồi 16 → fix RR | 2 cửa sổ SQL |
| 14–15 | Phantom Read: tắt `READ COMMITTED` → 15 rồi 16 → fix RR + next-key | 2 cửa sổ SQL |
| 16 | Bảng tổng hợp 4 lỗi (tắt gì / trước / sau) | nói |
| 17–18 | Deadlock: 3 tình huống · HQTCSDL hỗ trợ gì | nói |
| 19 | 🎬 Deadlock mặc định `THEO_YEU_CAU` → **1213 / 0** | 2 cửa sổ SQL |
| 20 | ⚙️ **Đã tắt gì**: `SET GLOBAL ... OFF` → **1227** trên hosting | chiếu ảnh `D3` |
| 21 | 🎬 Thay thế: `GET_LOCK` ↔ khóa dòng → **TREO** + PROCESSLIST | 3 cửa sổ SQL, timeout 8s |
| 22–23 | Fix: con trỏ sắp `MaLHP` · sửa `SP_HuyDangKy` · 4 lớp phòng chống | chiếu code |
| 24 | ✅ Demo lại (HQTCSDL): `SAP_XEP` → **0 và 0** | 2 cửa sổ SQL |
| 25 | ✅ Demo lại (web): trước fix **1213** → sau fix **102** | 2 trình duyệt, đổi bản SP bằng `apply-sql.js` |
| 26–27 | Bảng khôi phục + log kết quả | nói + dọn dẹp |
| 28–30 | Q&A · kết luận · phụ lục | nói |

> ⏱ **Phân bổ thời gian gợi ý:** mở đầu 3' · 4 lỗi concurrency 8' · deadlock 9' · kết luận + Q&A 5' = **~25 phút**.
