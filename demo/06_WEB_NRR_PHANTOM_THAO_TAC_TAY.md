# 6️⃣ GUIDE THAO TÁC TAY TRÊN WEB — NON-REPEATABLE READ & PHANTOM READ

> **Mục tiêu:** tái hiện 2 lỗi đọc **bằng chính thao tác tay của người dùng trên web** —
> không có trang demo riêng, không script tự động, không cần trình biên soạn DB.
> **Không có màn hình nào được thêm vào hệ thống**: mọi thứ diễn ra trên các màn hình nghiệp vụ
> đang có, với các nút đang có.

---

## 🎬 Ý TƯỞNG

Nút **“Đăng ký N lớp đã chọn”** trên trang *Đăng ký lớp học phần* chạy **MỘT giao tác** cho cả N lớp
(`SP_DangKyNhieuHocPhan`). Bản lab của thủ tục này **đọc dữ liệu HAI LẦN** trong giao tác đó
(cách nhau 8 giây) rồi **“kiểm tra lại”**: nếu hai lần đọc khác nhau thì **hủy toàn bộ giao dịch**.

```
❌ BẢN CHƯA FIX                          ✅ BẢN ĐÃ FIX
SET SESSION … READ COMMITTED              SET SESSION … REPEATABLE READ
   ├─ ĐỌC LẦN 1  (một DÒNG + một TẬP)        ├─ ĐỌC LẦN 1
   ├─ DO SLEEP(8)  ← ⏸ 8 giây                ├─ DO SLEEP(8)
   ├─ ĐỌC LẦN 2                              ├─ ĐỌC LẦN 2
   └─ khác nhau ⇒ HỦY (sinh viên bị HỦY OAN) └─ luôn giống nhau ⇒ đăng ký bình thường
       ↑ vì mỗi câu SELECT tạo snapshot MỚI       ↑ vì snapshot cố định từ lần đọc đầu
```

**Điểm mấu chốt:** với `READ COMMITTED`, một giao tác khác chỉ cần `COMMIT` một thay đổi trong 8 giây đó
là hai lần đọc lệch nhau ⇒ **sinh viên bị hủy oan dù mọi điều kiện đều hợp lệ**.

Cả hai con số của 2 lần đọc được trả về trong `ChiTiet` và **trang web hiển thị ngay** trong dải thông báo
*“Kết quả từng lớp: …”* — không cần sửa gì ở giao diện.

---

## 🔧 CONFIG SQL — TÁI HIỆN vs KHẮC PHỤC

| | File | Khác biệt |
|---|---|---|
| ❌ **TÁI HIỆN** | [`sql_config/lab__dangky_nhieu__chua_fix.sql`](sql_config/lab__dangky_nhieu__chua_fix.sql) | `SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;` |
| ✅ **KHẮC PHỤC** | [`sql_config/lab__dangky_nhieu__da_fix.sql`](sql_config/lab__dangky_nhieu__da_fix.sql) | `SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;` |
| 🔧 **BẮT BUỘC KÈM THEO** | `mysql/procedures/SP_DangKyHocPhan.sql` | Nút “Đăng ký” của trình duyệt B phải là **bản THẬT** (không `DO SLEEP`) để B commit **kịp** trong cửa sổ 8 giây |

> Hai file **giống hệt nhau**, chỉ khác **đúng một dòng** mức cô lập — nên so sánh hoàn toàn công bằng.
> Bản chính thức của hệ thống (`mysql/procedures/SP_DangKyNhieuHocPhan.sql`) **không có bước đọc lại**
> nên không bao giờ hủy oan.

```bash
cd backend

# TÁI HIỆN LỖI
node scripts/apply-sql.js ../demo/sql_config/lab__dangky_nhieu__chua_fix.sql

# KHẮC PHỤC (làm lại để chứng minh đã fix)
node scripts/apply-sql.js ../demo/sql_config/lab__dangky_nhieu__da_fix.sql

# KHÔI PHỤC BẢN CHÍNH THỨC (BẮT BUỘC sau khi demo xong)
node scripts/apply-sql.js ../mysql/procedures/SP_DangKyNhieuHocPhan.sql
```

---

## 🧰 CHUẨN BỊ

### Cách 1 — 1 CLICK trên web (khuyến nghị)

1. Mở **http://localhost:3000/chuan-bi-demo** → đăng nhập `admin` / `admin@123`.
2. Ô **“Chuẩn bị cho kịch bản”** → chọn **`② Non-repeatable Read`** (hoặc **`③ Phantom Read`** — hai kịch bản
   dùng chung một cấu hình, chỉ khác thao tác của người demo).
3. Bấm **⚙ CHUẨN BỊ DEMO**. Trang tự dựng lại dữ liệu học kỳ + nạp đúng 2 thủ tục, rồi in hướng dẫn từng bước.
4. Sau khi demo xong: quay lại trang → **✔ FIX**.

> ⚠️ **TUYỆT ĐỐI KHÔNG chuẩn bị kịch bản này bằng lựa chọn “Lost Update”.**
> Bản *Lost Update* đặt `DO SLEEP(8)` **sau `INSERT`, trước `COMMIT`** trong `SP_DangKyHocPhan`
> (nút “Đăng ký” của trình duyệt B) ⇒ B **commit muộn ~8 giây**, tức **muộn hơn “lần đọc 2” của A**
> ⇒ A đọc 2 lần **giống nhau** ⇒ **không hủy oan** ⇒ màn demo **mất tác dụng**.
> Đã đo thực tế: chuẩn bị gộp ⇒ A `ketQua = 0`; chuẩn bị riêng (bản thật, không `DO SLEEP`) ⇒ A `ketQua = 104`.

### Cách 2 — dòng lệnh

```bash
cd backend

# 1) SP_DangKyHocPhan PHẢI là BẢN THẬT (không DO SLEEP) — nếu đang là bản Lost Update thì nạp lại:
node scripts/apply-sql.js ../mysql/procedures/SP_DangKyHocPhan.sql

# 2) Bản lab đọc 2 lần cho SP_DangKyNhieuHocPhan (nút "Đăng ký N lớp đã chọn"):
node scripts/apply-sql.js ../demo/sql_config/lab__dangky_nhieu__chua_fix.sql
```

3. Xoá đăng ký thử của các tài khoản demo trên 3 lớp demo (chạy trong trình biên soạn DB):

```sql
DELETE FROM DANGKYHOCPHAN WHERE MaSV IN ('SV001','SV003','SV004')
  AND MaLHP IN ('LHP505','LHP507','LHP508');
UPDATE LOPHOCPHAN lhp SET lhp.SiSoHienTai = (
  SELECT COUNT(*) FROM DANGKYHOCPHAN d
  WHERE d.MaLHP = lhp.MaLHP AND d.TrangThaiDangKy = 'DA_DANG_KY')
WHERE lhp.MaLHP IN ('LHP505','LHP507','LHP508');

SELECT MaLHP, SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP IN ('LHP505','LHP507','LHP508');
-- MONG ĐỢI: cả 3 lớp đều còn rất nhiều chỗ (LHP507/LHP508 trong, LHP505 ~1-2 SV)
```

4. Mở web: **http://localhost:3000** (backend phải đang chạy).

**Tài khoản dùng cho demo** (mật khẩu tất cả là `matkhau@123`):

| Tài khoản | Dùng ở đâu | Vì sao chọn |
|---|---|---|
| `sv003` | Trình duyệt A (kịch bản 1) · `sv001` cho kịch bản 2 | đủ điều kiện vào LHP507 + LHP508 |
| `sv004` | Trình duyệt B (kịch bản 1) | đủ điều kiện vào LHP507 |

> ⚠️ **PHẢI dùng 2 phiên đăng nhập riêng:** 1 cửa sổ **thường** + 1 cửa sổ **Ẩn danh/InPrivate**.
> Hai tab trong cùng một cửa sổ dùng chung `localStorage` ⇒ sẽ là **cùng một tài khoản**.

---

# 🅰️ KỊCH BẢN 1 — NON-REPEATABLE READ (2 sinh viên, 2 trình duyệt)

> **Đọc gì:** `LOPHOCPHAN.SiSoHienTai` (sĩ số) của lớp đầu tiên trong phiếu đăng ký — **MỘT DÒNG**.
> **Ai làm thay đổi:** một **sinh viên khác** đăng ký đúng lớp đó ⇒ sĩ số tăng.

| Bước | 🪟 Trình duyệt A | 🪟 Trình duyệt B (ẩn danh) |
|---|---|---|
| 1 | Đăng nhập **`sv003`** → menu **Đăng ký lớp học phần** | Đăng nhập **`sv004`** → menu **Đăng ký lớp học phần** |
| 2 | Tick ☑ **LHP507 — Hệ điều hành** và ☑ **LHP508 — Lập trình ứng dụng di động** | Tìm dòng **LHP507 — Hệ điều hành**, **để nguyên trang** |
| 3 | Bấm nút **“Đăng ký 2 lớp đã chọn”** → nút chuyển thành **“Đang đăng ký…”** | — |
| 4 | *(hệ thống đang đọc lần 1 rồi ngủ 8 giây)* | **Trong vòng 8 giây đó**, bấm nút **“Đăng ký”** ở dòng **LHP507** → toast xanh ✅ thành công |
| 5 | Sau ~8 giây, A hiện **dải cảnh báo** + **toast đỏ** | — |

**A nhìn thấy gì:**

```
⚠️ Giao dịch bị hủy (mã 104)
   Không thể đăng ký! Tổng số tín chỉ vượt quá giới hạn tối đa cho phép.
   Kết quả từng lớp: HỦY OAN — Đối chứng cô lập [LHP507] · sĩ số 0→1 · số lớp của SV trong kỳ 4→4
```

⇒ **Cùng MỘT giao tác**, cùng một câu `SELECT` trên cùng một dòng mà **lần 1 = 0, lần 2 = 1**
⇒ **Non-repeatable Read**. Sinh viên A bị **hủy oan** — phiếu đăng ký hoàn toàn hợp lệ vẫn bị hủy.
📸 **Chụp ảnh ngay dải cảnh báo này** (nó chứa cả hai con số `0→1`).

> ⚠️ Chú ý: chỉ số `số lớp của SV trong kỳ` báo `4→4` (không đổi) — nghĩa là **chỉ có phép đọc MỘT DÒNG**
> bị lệch. Đây là điều phân biệt rõ **Non-repeatable Read** với **Phantom Read**.

**Chứng minh đã fix:** nạp bản đã fix rồi **làm lại y hệt**:

```bash
cd backend && node scripts/apply-sql.js ../demo/sql_config/lab__dangky_nhieu__da_fix.sql
```

```
✅ Giao dịch đã hoàn tất.  —  toast XANH: “Đăng ký học phần thành công.”
   Kết quả từng lớp: LHP507:OK; LHP508:OK · Đối chứng cô lập [LHP507] · sĩ số 0→0 · số lớp của SV trong kỳ 4→4
```

⇒ hai lần đọc **giống nhau** (`0→0`) ⇒ **không hủy oan**, A đăng ký thành công cả 2 lớp.

---

# 🅱️ KỊCH BẢN 2 — PHANTOM READ (cùng một sinh viên, 2 cửa sổ)

> **Đọc gì:** `COUNT(*)` số lớp mà **chính sinh viên đó** đã đăng ký trong học kỳ — **MỘT TẬP BẢN GHI**.
> **Ai làm thay đổi:** chính sinh viên đó đăng ký thêm **một lớp KHÁC** ở cửa sổ thứ hai
> ⇒ **một dòng MỚI** xuất hiện trong tập đang đếm.

| Bước | 🪟 Cửa sổ A (thường) | 🪟 Cửa sổ B (ẩn danh) |
|---|---|---|
| 1 | Đăng nhập **`sv001`** → **Đăng ký lớp học phần** | Đăng nhập **`sv001`** (cùng tài khoản) → **Đăng ký lớp học phần** |
| 2 | Tick ☑ **LHP507** và ☑ **LHP508** | Tìm dòng **LHP505 — An toàn thông tin**, **để nguyên trang** |
| 3 | Bấm **“Đăng ký 2 lớp đã chọn”** → **“Đang đăng ký…”** | — |
| 4 | *(đang đọc lần 1 rồi ngủ 8 giây)* | **Trong vòng 8 giây đó**, bấm **“Đăng ký”** ở dòng **LHP505** → toast xanh ✅ thành công |
| 5 | Sau ~8 giây, A hiện **dải cảnh báo** + **toast đỏ** | — |

**A nhìn thấy gì:**

```
⚠️ Giao dịch bị hủy (mã 104)
   Không thể đăng ký! Tổng số tín chỉ vượt quá giới hạn tối đa cho phép.
   Kết quả từng lớp: HỦY OAN — Đối chứng cô lập [LHP507] · sĩ số 0→0 · số lớp của SV trong kỳ 3→4
```

⇒ **Cùng MỘT giao tác**, cùng một câu `COUNT(*)` mà **lần 1 = 3, lần 2 = 4** — tập kết quả **xuất hiện thêm
một DÒNG BÓNG MA** (dòng `SV001 → LHP505` do cửa sổ B vừa chèn) ⇒ **Phantom Read**.

> ⚠️ Chú ý: lần này `sĩ số` báo `0→0` (không đổi) vì cửa sổ B đăng ký một **lớp KHÁC** —
> đúng bản chất **Bóng ma: các dòng CŨ không đổi, chỉ có DÒNG MỚI xuất hiện**.

**Chứng minh đã fix:** nạp bản đã fix và làm lại → `số lớp của SV trong kỳ 3→3` ⇒ A **đăng ký thành công**.

---

## 📊 KẾT QUẢ ĐO THẬT (mô phỏng đúng 2 cú bấm qua API của web)

| Kịch bản | Phép đọc bị lệch | ❌ `READ COMMITTED` | ✅ `REPEATABLE READ` |
|---|---|---|---|
| 1 — Non-repeatable Read | **MỘT DÒNG**: sĩ số LHP507 | `0 → 1` ⇒ **HỦY OAN** (`ketQua = 104`, toast đỏ) | `0 → 0` ⇒ **thành công** (`ketQua = 0`, toast xanh) |
| 2 — Phantom Read | **MỘT TẬP**: số lớp của SV trong kỳ | `3 → 4` ⇒ **HỦY OAN** (`ketQua = 104`, toast đỏ) | `3 → 3` ⇒ **thành công** (`ketQua = 0`, toast xanh) |

Trong cả hai kịch bản, **trình duyệt B đều thành công thật** (`ketQua = 0`) — dữ liệu đã đổi và `COMMIT`;
chỉ có trình duyệt A là bị hủy oan.

> Công cụ mô phỏng để tự kiểm chứng (không thay thế thao tác tay):
> ```bash
> node demo/cong_cu_do/do_web_2trinhduyet.mjs nrr
> node demo/cong_cu_do/do_web_2trinhduyet.mjs phantom
> ```

---

## 📸 CHECKLIST ẢNH

- [ ] **Kịch bản 1**: dải cảnh báo mã **104** + dòng `HỦY OAN — … sĩ số 0→1 …` (dải đỏ/cam rất dễ thấy)
- [ ] **Kịch bản 1 (đã fix)**: dải xanh + dòng `sĩ số 0→0 …` và **2 dòng LHP507/LHP508 đã vào “Lớp HP đã đăng ký”**
- [ ] **Kịch bản 2**: dải cảnh báo + dòng `số lớp của SV trong kỳ 3→4`
- [ ] **Kịch bản 2 (đã fix)**: dòng `số lớp của SV trong kỳ 3→3`
- [ ] Ảnh **2 trình duyệt cạnh nhau** ở bước 4 (A đang “Đang đăng ký…”, B vừa báo thành công)
- [ ] (tùy chọn) Trang **Lớp HP đã đăng ký** của A **trống** ở lần chưa fix — chứng minh phiếu bị hủy oan

---

## 🧹 DỌN DẸP (làm sau khi demo xong)

Trên trang **Chuẩn bị Demo** bấm **✔ FIX** (khôi phục cả 2 thủ tục + dựng lại dữ liệu), hoặc bằng dòng lệnh:

```bash
cd backend
node scripts/apply-sql.js ../mysql/procedures/SP_DangKyNhieuHocPhan.sql   # BẮT BUỘC
node scripts/apply-sql.js ../mysql/procedures/SP_DangKyHocPhan.sql        # (đang là bản thật — nạp lại cho chắc)
```

```sql
-- Xoá đăng ký thử của các tài khoản demo
DELETE FROM DANGKYHOCPHAN WHERE MaSV IN ('SV001','SV003','SV004')
  AND MaLHP IN ('LHP505','LHP507','LHP508');
UPDATE LOPHOCPHAN lhp SET lhp.SiSoHienTai = (
  SELECT COUNT(*) FROM DANGKYHOCPHAN d
  WHERE d.MaLHP = lhp.MaLHP AND d.TrangThaiDangKy = 'DA_DANG_KY')
WHERE lhp.MaLHP IN ('LHP505','LHP507','LHP508');
```

---

## 📌 GHI CHÚ KỸ THUẬT (nên nói khi trình bày)

1. **Vì sao phải có `DO SLEEP(8)`?** Thủ tục thật chạy xong trong vài trăm mili-giây, người thao tác tay
   **không thể** bấm kịp ở cửa sổ kia. `DO SLEEP` chỉ **mở rộng cửa sổ thời gian** — **bản chất lỗi không
   nằm ở SLEEP** mà ở **mức cô lập** `READ COMMITTED`.
2. **Vì sao đọc lần 2 đặt TRƯỚC khi giao tác ghi?** Để chênh lệch **chỉ có thể đến từ giao tác khác**,
   không phải do chính nó vừa ghi ⇒ bằng chứng sạch, không thể ngụy biện.
3. **Phân biệt 2 lỗi qua chính dải thông báo:**
   - `sĩ số 0→1` mà `số lớp 4→4` ⇒ **Non-repeatable Read** (một DÒNG bị đổi giá trị).
   - `sĩ số 0→0` mà `số lớp 3→4` ⇒ **Phantom Read** (một DÒNG MỚI xuất hiện trong tập kết quả).
4. **Vì sao `REPEATABLE READ` chặn được:** MVCC giữ **một ảnh chụp (snapshot) cố định từ lần đọc đầu tiên**
   của giao tác, nên mọi lần đọc sau đều thấy đúng ảnh chụp đó — dù giao tác khác đã `COMMIT`.
5. **Muốn tắt phần lab:** chỉ cần nạp lại bản chính thức
   (`mysql/procedures/SP_DangKyNhieuHocPhan.sql`) — **không có gì phải sửa trong code web**.
