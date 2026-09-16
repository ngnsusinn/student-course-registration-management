# 📊 KẾT QUẢ ĐO THỰC TẾ — 4 LỖI ĐIỀU KHIỂN CẠNH TRANH

> Toàn bộ số liệu dưới đây là **kết quả chạy thật**, không phải mô phỏng.
> Sinh ra bởi: `demo/cong_cu_do/do_thuc_te.mjs` (17 pha ở mức SQL) và
> `demo/cong_cu_do/do_thuc_te_web.mjs` (4 pha qua đúng API mà web gọi).
> Bản thô: [`cong_cu_do/ket_qua_do_raw.md`](cong_cu_do/ket_qua_do_raw.md)

## 🌐 MÔI TRƯỜNG ĐO

| | |
|---|---|
| Hệ quản trị | **MariaDB 11.8.9-ubu2404** (`mariadb.org binary distribution`), engine **InnoDB** |
| Mức cô lập mặc định | **REPEATABLE-READ** (session và global) |
| `innodb_deadlock_detect` | **1** (ON — cơ chế mặc định) |
| `innodb_lock_wait_timeout` | **50** giây |
| Kết nối đo | `0.tcp.ap.ngrok.io:21868` / database `roacqgfa_dbms` |
| Số phiên | 2 kết nối thật, mỗi phiên một connection riêng |

**Dữ liệu demo:** `LHP514` = môn *Kết cấu cao tầng* (MH045) = **15/16** · `LHP506` = môn *Tiếng Anh chuyên ngành CNTT* (MH017) = **0/1** — cả hai **còn đúng 1 chỗ**.

---

## 🎯 BẢNG TỔNG HỢP

| # | Lỗi | Trạng thái | Kết quả đo | Kết luận |
|---|---|---|---|---|
| 1 | **Lost Update** | ❌ Chưa fix (SQL) | `COUNT(*) = 17` > `SiSoToiDa = 16`, bộ đếm kẹt ở 16, phiên B **chờ khóa 2,12s** | ✅ Tái hiện lỗi |
| 1 | **Lost Update** | ✅ Đã fix (SQL, `FOR UPDATE`) | phiên B chờ **2,12s** → đọc `16/16` → **mã 105**, `COUNT = 16` | ✅ Đã chặn |
| 1 | **Lost Update** | ❌ Chưa fix (WEB) | 2 phiên đều `ketQua = 0` (**2 toast xanh**), `COUNT = 2 > 1`, phiên B chờ 8,0s | ✅ Tái hiện lỗi |
| 1 | **Lost Update** | ✅ Đã fix (WEB) | A = **0** (toast xanh) · B = **105** (toast đỏ), `COUNT = 1` | ✅ Đã chặn |
| 2 | **Non-repeatable Read** | ❌ Chưa fix (`READ COMMITTED`) | đọc lần 1 = **15**, lần 2 = **16** | ✅ Tái hiện lỗi |
| 2 | **Non-repeatable Read** | ✅ Đã fix (`REPEATABLE READ`) | đọc lần 1 = **15**, lần 2 = **15** | ✅ Đã chặn |
| 2 | **Non-repeatable Read** | ✅ Bổ sung (`FOR UPDATE`) | phiên ghi **bị chặn 1,76s** | ✅ Đã chặn |
| 3 | **Phantom Read** | ❌ Chưa fix (`READ COMMITTED`) | `COUNT` lần 1 = **15**, lần 2 = **16** | ✅ Tái hiện lỗi |
| 3 | **Phantom Read** | ✅ Đã fix (`REPEATABLE READ`) | `COUNT` **15 → 15** (kiểm tra lại từ phiên khác = **16**) | ✅ Đã chặn |
| 3 | **Phantom Read** | ✅ Bổ sung (khóa phạm vi) | `INSERT` bị **chặn 2,63s** | ✅ Đã chặn |
| 4 | **Deadlock** | ❌ Chưa fix (SQL) | `@kq1 = 0` · `@kq2 = 1213` — phát hiện sau **~6,89s** | ✅ Tái hiện lỗi |
| 4 | **Deadlock** | ✅ Đã fix (SQL, `SAP_XEP`) | `0` và `0` — không còn 1213 | ✅ Đã chặn |
| 4 | **Deadlock** | ❌ Chưa fix (lỗi THẬT) | `@kq1 = 1213` · `@kq2 = 202` | ✅ Tái hiện lỗi |
| 4 | **Deadlock** | ✅ Đã fix (lỗi THẬT) | `0` và `0` | ✅ Đã chặn |
| 4 | **Deadlock** | ❌ Chưa fix (WEB) | A = **1213** (toast đỏ) · B = **0**, sau 2,6s | ✅ Tái hiện lỗi |
| 4 | **Deadlock** | ✅ Đã fix (WEB) | A = **0** · B = **102** — **không còn 1213** | ✅ Đã chặn |

---

# 1️⃣ LOST UPDATE

## M1.1 · ❌ CHƯA FIX — 2 phiên cùng đọc "còn 1 chỗ" rồi cùng ghi (LHP514)

```
Xuất phát: LHP514 = 15/16 (COUNT = 15)
PHIÊN A đọc   : 15/16  →  INSERT SV030  (giữ khóa, chưa commit)
PHIÊN B đọc   : 15/16  ← VẪN thấy "còn 1 chỗ" (snapshot REPEATABLE-READ không thấy
                          thay đổi CHƯA commit của phiên A)
PHIÊN B INSERT: CHỜ KHÓA 2,12s rồi mới chạy được
PHIÊN A COMMIT → sĩ số 15 → 16
PHIÊN B COMMIT
KẾT QUẢ: COUNT(*) đăng ký thật = 17  >  SiSoToiDa = 16
          bộ đếm SiSoHienTai kẹt ở 16 (trigger dùng LEAST)
⇒ VƯỢT SĨ SỐ — TÁI HIỆN ĐƯỢC LỖI LOST UPDATE
```

**Điểm "nói dối" thú vị:** cột `SiSoHienTai` vẫn hiển thị **16/16** — trông **hoàn toàn hợp lệ**. Chỉ khi
`COUNT(*)` thật mới lộ ra **17 lượt đăng ký**. Lỗi hỏng **âm thầm**.

## M1.2 · ✅ ĐÃ FIX — khóa dòng sĩ số bằng `SELECT … FOR UPDATE` (cùng LHP514)

```
PHIÊN A: SELECT … FOR UPDATE → 15/16   (giữ X-lock) rồi INSERT SV030
PHIÊN B: SELECT … FOR UPDATE → CHỜ KHÓA 2,12s
         → sau khi A COMMIT mới đọc được: 16/16
⇒ điều kiện IF 16 >= 16 đúng ⇒ SP_DangKyHocPhan gán pKetQua = 105 "Lớp đã đầy sĩ số"
KẾT QUẢ: 16/16 — COUNT = 16, KHÔNG vượt sĩ số
```

## M1.3 · ✅ ĐÃ FIX — qua thủ tục thật `SP_DangKyHocPhan` (LHP506 còn 1 chỗ)

```
Xuất phát: LHP506 = 0/1
@kqA (SV030) = 0     → lấy được suất cuối
@kqB (SV041) = 105   → LỚP ĐÃ ĐẦY SĨ SỐ (bị từ chối đúng)
KẾT QUẢ: 1/1 — COUNT = 1  ⇒ một suất chỉ cấp cho đúng một sinh viên
```

## M1.4 · ❌ / ✅ QUA API WEB (mô phỏng 2 cú bấm nút)

```
── BẢN CHƯA FIX ──────────────────────────────────────────────
Chuẩn bị: LHP506 = 0/1 (còn 1 chỗ)
[A] sau  8,4s → HTTP 200 · ketQua = 0     (toast XANH "Đăng ký học phần thành công.")
[B] sau 16,4s → HTTP 200 · ketQua = 0     (toast XANH — B chờ khóa 8 giây)
LHP506 sau cùng: SiSo = 1/1 · COUNT(*) hiệu lực = 2
⇒ VƯỢT SĨ SỐ — 2 sinh viên vào lớp 1 chỗ

── BẢN ĐÃ FIX ───────────────────────────────────────────────
[A] sau 0,4s → HTTP 200 · ketQua = 0      (toast XANH)
[B] sau 2,3s → HTTP 400 · ketQua = 105    (toast ĐỎ "Lớp đã đầy sĩ số")
LHP506 sau cùng: SiSo = 1/1 · COUNT(*) hiệu lực = 1
⇒ KHÔNG vượt sĩ số
```

**Vùng thời gian an toàn để tái hiện trên web** (đã đo, bản chưa fix có `DO SLEEP(8)` sau `INSERT`):

| Phiên B bấm sau A | Kết quả |
|---|---|
| 0,2 giây | ✅ cả 2 thành công · COUNT = 2/1 |
| 1 giây | ✅ cả 2 thành công · COUNT = 2/1 |
| 2 giây | ✅ cả 2 thành công · COUNT = 2/1 |
| 4 giây | ✅ cả 2 thành công · COUNT = 2/1 |

---

# 2️⃣ NON-REPEATABLE READ

## M2.1 · ❌ CHƯA FIX — hạ mức cô lập xuống `READ COMMITTED`

```
PHIÊN A: SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;   ★ TẮT phòng chống
         START TRANSACTION;
PHIÊN A đọc lần 1  → 15
PHIÊN B: UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP='LHP514';
         COMMIT;                                    (15 → 16, đã commit thật)
PHIÊN A đọc lần 2  → 16      ← KHÁC lần 1
⇒ cùng MỘT giao tác mà cùng một ô dữ liệu cho HAI giá trị khác nhau
```

## M2.2 · ✅ ĐÃ FIX — giữ mức mặc định `REPEATABLE READ`

```
PHIÊN A: SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;  ★ giữ mặc định
         START TRANSACTION;
PHIÊN A đọc lần 1  → 15
PHIÊN B: UPDATE … + 1; COMMIT;                      (15 → 16 — ĐÃ COMMIT THẬT)
PHIÊN A đọc lần 2  → 15      ← GIỐNG lần 1 ⇒ ĐÃ CHẶN ĐƯỢC LỖI
⇒ MVCC snapshot được cố định từ lần đọc ĐẦU TIÊN của giao tác
```

## M2.3 · ✅ ĐÃ FIX (bổ sung) — khóa đọc `FOR UPDATE` khi cần giá trị mới nhất

```
PHIÊN A: SELECT SiSoHienTai, SiSoToiDa … FOR UPDATE → 15/16   (giữ X-lock)
PHIÊN B: START TRANSACTION; UPDATE … + 1;
         → BỊ CHẶN 1,76s cho tới khi A COMMIT rồi mới chạy
⇒ ghi của phiên B không thể chen vào giữa 2 lần đọc của A
```

---

# 3️⃣ PHANTOM READ

## M3.1 · ❌ CHƯA FIX — hạ mức cô lập xuống `READ COMMITTED`

```
PHIÊN A: SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;   ★ TẮT phòng chống
         START TRANSACTION;
PHIÊN A đếm lần 1: COUNT(*) = 15
PHIÊN B: INSERT INTO DANGKYHOCPHAN (MaSV,MaLHP,…) VALUES ('SV999','LHP514',…);
         COMMIT;                                    (dòng "bóng ma")
PHIÊN A đếm lần 2: COUNT(*) = 16   ← XUẤT HIỆN THÊM DÒNG
⇒ dòng phiên A KHÔNG hề chèn lại xuất hiện trong tập kết quả của A
```

## M3.2 · ✅ ĐÃ FIX — giữ mức mặc định `REPEATABLE READ`

```
PHIÊN A: SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;  ★ giữ mặc định
         START TRANSACTION;
PHIÊN A đếm lần 1: COUNT(*) = 15
PHIÊN B: INSERT SV999 …; COMMIT;                    (ĐÃ GHI THẬT)
PHIÊN A đếm lần 2: COUNT(*) = 15   ← KHÔNG ĐỔI ⇒ ĐÃ CHẶN ĐƯỢC LỖI
Kiểm tra lại từ phiên khác: COUNT(*) = 16  → chứng minh dòng bóng ma CÓ tồn tại thật,
                                              chỉ là A không thấy trong giao tác của mình
```

## M3.3 · ✅ ĐÃ FIX (bổ sung) — khóa PHẠM VI đang đọc

```
PHIÊN A: SELECT COUNT(*) FROM DANGKYHOCPHAN
         WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY' FOR UPDATE;   → 15
PHIÊN B: INSERT SV999 → BỊ CHẶN 2,63s (chờ tới khi A COMMIT)
PHIÊN A đếm lại (trong cùng giao tác) → 15   ← KHÔNG ĐỔI
KẾT QUẢ cuối sau khi cả hai commit: COUNT = 16
⇒ next-key/gap lock ⇒ phiên khác KHÔNG THỂ chèn vào vùng mà A đang đọc
```

---

# 4️⃣ DEADLOCK

## M4.1 · ❌ CHƯA FIX — 2 phiên khóa 2 lớp theo thứ tự NGƯỢC NHAU

```
PHIÊN A: CALL SP_Demo_KhoaTheoThuTu('SV030','LHP514,LHP506','THEO_YEU_CAU',3,@kq1);
PHIÊN B: CALL SP_Demo_KhoaTheoThuTu('SV041','LHP506,LHP514','THEO_YEU_CAU',3,@kq2);
@kq1 = 0  ·  @kq2 = 1213
Thời điểm phát hiện: ~6,89 giây sau khi bắt đầu (gồm 2 lần giữ khóa 3 giây)
⇒ MỘT PHIÊN NHẬN 1213 (ER_LOCK_DEADLOCK) — InnoDB tự chọn nạn nhân & rollback
⇒ Sĩ số KHÔNG đổi (thủ tục demo chỉ khóa, không ghi)
```

**Trích thông báo của InnoDB (`SHOW ENGINE INNODB STATUS`) khi đo được deadlock thật trên bảng `LOPHOCPHAN`:**

```
------------------------
LATEST DETECTED DEADLOCK
------------------------
*** (1) TRANSACTION:
TRANSACTION 3607, ACTIVE 5 sec starting index read
LOCK WAIT ... query id 24964 ... Updating
UPDATE LOPHOCPHAN
        SET SiSoHienTai = LEAST(SiSoToiDa, SiSoHienTai + 1)
        WHERE MaLHP = NEW.MaLHP                      ← trigger cộng sĩ số
*** WAITING FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS ... table `roacqgfa_dbms`.`LOPHOCPHAN` ... lock_mode X locks rec but not gap waiting
*** CONFLICTING WITH:
RECORD LOCKS ... table `roacqgfa_dbms`.`LOPHOCPHAN` ... lock mode S locks rec but not gap
```

> 📌 Đây là **bằng chứng gốc** cho thấy: khóa ngoại `DANGKYHOCPHAN → LOPHOCPHAN` khiến mỗi `INSERT` **đã lấy
> khóa S** trên dòng lớp, rồi trigger đòi nâng lên **khóa X** cùng dòng → hai phiên chồng nhau là deadlock.

## M4.2 · ✅ ĐÃ FIX — khóa theo thứ tự NHẤT QUÁN (`SAP_XEP`)

```
PHIÊN A: … 'SAP_XEP' …   (người dùng vẫn gửi LHP514→LHP506, nhưng CON TRỎ tự sắp lại)
PHIÊN B: … 'SAP_XEP' …   (gửi LHP506→LHP514)
@kq1 = 0  ·  @kq2 = 0
⇒ CẢ HAI = 0 — KHÔNG còn deadlock (không thể hình thành chu trình chờ)
```

## M4.3 · ❌ LỖI THẬT CỦA HỆ THỐNG — đảo thứ tự khóa ĐĂNG KÝ ↔ HỦY ĐĂNG KÝ

```
PHIÊN A: SP_Demo_PhienGiaoDich('DANG_KY_CHUA_FIX','SV030','LHP514',3,@kq1)
         [LOPHOCPHAN → DANGKYHOCPHAN]
PHIÊN B: SP_Demo_PhienGiaoDich('HUY_CHUA_FIX','SV030','LHP514',3,@kq2)
         [DANGKYHOCPHAN → LOPHOCPHAN]
@kq1 = 1213  ·  @kq2 = 202
⇒ DEADLOCK sinh ra từ CHÍNH nghiệp vụ đăng ký/hủy của hệ thống, không phải ví dụ nhân tạo
```

## M4.4 · ✅ ĐÃ FIX — `SP_HuyDangKy` khóa `LOPHOCPHAN` TRƯỚC (cùng thứ tự)

```
PHIÊN A: 'DANG_KY_DA_FIX'  ·  PHIÊN B: 'HUY_DA_FIX'
@kq1 = 0  ·  @kq2 = 0
⇒ KHÔNG còn 1213 — hai phiên nối tiếp nhau an toàn
```

## M4.5 · ❌ / ✅ QUA API WEB (2 sinh viên tick lớp ngược thứ tự)

```
── BẢN CHƯA FIX ──────────────────────────────────────────────
A (sv030): tick LHP514 → LHP506        B (sv041): tick LHP506 → LHP514
[A] sau 2,6s → HTTP 409 · ketQua = 1213
     "Xung đột khóa (deadlock 1213): giao dịch đăng ký của bạn bị hệ quản trị CSDL
      hủy để giải phóng deadlock. Vui lòng bấm đăng ký lại."
[B] sau 2,6s → HTTP 200 · ketQua = 0    "Đăng ký học phần thành công."
Sĩ số sau cùng: LHP514 = 15/16 · LHP506 = 1/1   ⇒ deadlock KHÔNG làm sai dữ liệu
⇒ TÁI HIỆN ĐƯỢC LỖI DEADLOCK TRÊN WEB (toast đỏ 1213)

── BẢN ĐÃ FIX (giữ nguyên DO SLEEP để so sánh công bằng) ─────
[A] sau 2,3s → HTTP 200 · ketQua = 0     "Đăng ký học phần thành công."
[B] sau 4,3s → HTTP 409 · ketQua = 102   "Bạn chưa hoàn thành môn tiên quyết…"
                                          (B CHỜ KHÓA ~2 giây rồi mới chạy — nối tiếp an toàn)
⇒ KHÔNG còn 1213

── BẢN THẬT (không SLEEP) ────────────────────────────────────
[A] sau 0,3s → ketQua = 0   ·   [B] sau 0,6s → ketQua = 102
⇒ KHÔNG còn 1213, chỉ còn lỗi nghiệp vụ bình thường
```

---

# 5️⃣ NRR & PHANTOM TRÊN WEB — 2 PHA (thao tác tay, 2 trình duyệt)

> Đo qua **đúng API mà giao diện thật gọi**: `POST /api/dangky/nhieu` (nút **“Đăng ký N lớp đã chọn”**)
> và `POST /api/dangky` (nút **“Đăng ký”** ở cột Thao tác). Bản lab của `SP_DangKyNhieuHocPhan`
> **đọc hai lần trong cùng một giao tác** (cách nhau `DO SLEEP(8)`) rồi “kiểm tra lại”.
> Guide: [`06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md`](06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md) ·
> công cụ: `demo/cong_cu_do/do_web_2trinhduyet.mjs`

| # | Kịch bản | Phép đọc bị lệch | ❌ `READ COMMITTED` | ✅ `REPEATABLE READ` |
|---|---|---|---|---|
| 1 | **Non-repeatable Read** — `sv003` ở cửa sổ A, `sv004` ở cửa sổ B | **MỘT DÒNG**: `LHP507.SiSoHienTai` | `0 → 1` ⇒ **HỦY OAN** (`ketQua = 104`, toast đỏ) | `0 → 0` ⇒ **thành công** (`ketQua = 0`, toast xanh) |
| 2 | **Phantom Read** — `sv001` ở **cả hai** cửa sổ | **MỘT TẬP**: `COUNT(*)` số lớp của SV trong kỳ | `3 → 4` ⇒ **HỦY OAN** (`ketQua = 104`, toast đỏ) | `3 → 3` ⇒ **thành công** (`ketQua = 0`, toast xanh) |

**Chi tiết (đúng phần hiển thị trên giao diện):**

```
── KỊCH BẢN 1 · READ COMMITTED ───────────────────────────────────────────────
[Trình duyệt B] sv004 bấm “Đăng ký” LHP507        → HTTP 200 · ketQua = 0  (THÀNH CÔNG, đã COMMIT)
[Trình duyệt A] sv003 bấm “Đăng ký 2 lớp đã chọn” → HTTP 409 · ketQua = 104
   toast ĐỎ: “Không thể đăng ký! Tổng số tín chỉ vượt quá giới hạn tối đa cho phép.”
   Kết quả từng lớp: HỦY OAN — Đối chứng cô lập [LHP507] · sĩ số 0→1 · số lớp của SV trong kỳ 4→4
   ⇒ chỉ phép đọc MỘT DÒNG lệch (0→1) ⇒ NON-REPEATABLE READ; A bị HỦY OAN

── KỊCH BẢN 1 · REPEATABLE READ ──────────────────────────────────────────────
[Trình duyệt A] sv003 → HTTP 200 · ketQua = 0  (toast XANH)
   LHP507:OK; LHP508:OK · Đối chứng cô lập [LHP507] · sĩ số 0→0 · số lớp của SV trong kỳ 4→4
   ⇒ hai lần đọc giống nhau ⇒ KHÔNG hủy oan

── KỊCH BẢN 2 · READ COMMITTED ───────────────────────────────────────────────
[Trình duyệt B] sv001 (cửa sổ ẩn danh) bấm “Đăng ký” LHP505 → HTTP 200 · ketQua = 0
[Trình duyệt A] sv001 bấm “Đăng ký 2 lớp đã chọn”             → HTTP 409 · ketQua = 104
   Kết quả từng lớp: HỦY OAN — Đối chứng cô lập [LHP507] · sĩ số 0→0 · số lớp của SV trong kỳ 3→4
   ⇒ chỉ phép đọc MỘT TẬP lệch (3→4) ⇒ PHANTOM READ; A bị HỦY OAN

── KỊCH BẢN 2 · REPEATABLE READ ──────────────────────────────────────────────
[Trình duyệt A] sv001 → HTTP 200 · ketQua = 0  (toast XANH)
   LHP507:OK; LHP508:OK · Đối chứng cô lập [LHP507] · sĩ số 0→0 · số lớp của SV trong kỳ 3→3
   ⇒ hai lần đọc giống nhau ⇒ KHÔNG hủy oan
```

> 📌 Điểm mạnh của phép đo này: **mỗi kịch bản chỉ làm lệch ĐÚNG MỘT trong hai phép đọc**
> (`sĩ số` cho Non-repeatable Read, `số lớp` cho Phantom Read) — nên hai lỗi **không lẫn vào nhau**.

---

## 🔬 CÁCH TỰ KIỂM CHỨNG LẠI

```bash
# 1) Đo cả 4 lỗi ở mức SQL (17 pha, ~90 giây) — tự dọn dẹp sau khi đo
node demo/cong_cu_do/do_thuc_te.mjs

# 2) Đo Lost Update + Deadlock qua đúng API mà web gọi (backend phải đang chạy ở :3000)
node demo/cong_cu_do/do_thuc_te_web.mjs lost-update
node demo/cong_cu_do/do_thuc_te_web.mjs deadlock

# 3) Mô phỏng đúng thao tác 2 trình duyệt cho Non-repeatable Read / Phantom Read
#    (nhớ nạp bản lab tương ứng trước: lab__dangky_nhieu__chua_fix.sql / __da_fix.sql)
node demo/cong_cu_do/do_web_2trinhduyet.mjs nrr
node demo/cong_cu_do/do_web_2trinhduyet.mjs phantom

# 4) Kết quả thô được ghi tự động vào
#    demo/cong_cu_do/ket_qua_do_raw.md
```

---

## ✅ KẾT LUẬN

| Nhận định | Bằng chứng đo được |
|---|---|
| MySQL/MariaDB **đã chặn sẵn** 2 lỗi bằng mức mặc định `REPEATABLE-READ` + MVCC | Non-repeatable Read: **15 → 15** · Phantom: **15 → 15** (dù phiên kia đã commit thật) |
| **Và chặn được cả trên web** | 2 trình duyệt: `sĩ số 0→0` · `số lớp 3→3` — sinh viên đăng ký bình thường (không bị hủy oan) |
| **Lost Update thì mặc định KHÔNG chặn** — phải khóa dòng | Chưa fix: **17/16** · Đã fix `FOR UPDATE`: **105**, sĩ số `16/16` |
| **Deadlock mặc định ĐƯỢC phát hiện** và rollback an toàn | `1213` xuất hiện, sĩ số **không đổi** ⇒ rollback-retry là chiến lược tự nhiên |
| Chặn deadlock **triệt để** bằng **thứ tự khóa nhất quán** | `THEO_YEU_CAU`: **0 / 1213** → `SAP_XEP`: **0 / 0** |
| Lỗi deadlock của hệ thống là **THẬT**, không nhân tạo | Đảo thứ tự ĐĂNG KÝ ↔ HỦY: **1213 / 202** → sau fix: **0 / 0** |
| Khóa còn giúp chống **cả 3 lỗi đọc/ghi** | `FOR UPDATE`: chặn ghi **1,76–2,63s** · khóa phạm vi: chặn INSERT **2,63s** |
