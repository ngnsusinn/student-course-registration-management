# 🎤 LỜI DẪN DEMO — LOST UPDATE (bản cầm tay khi trình bày)

> **Dùng cho:** kịch bản ① Lost Update trên web — lớp **LHP506** (*TA chuyên ngành K15*, **0/1** — còn đúng 1 chỗ),
> 2 trình duyệt `sv030` (thường) + `sv041` (ẩn danh).
> **Môi trường:** MariaDB 11.8.9 · `REPEATABLE-READ` · `innodb_snapshot_isolation = OFF` (bắt buộc) ·
> `innodb_deadlock_detect = 1` · `lock_wait_timeout = 50s`.
> **Số liệu trong tài liệu này là số ĐO THẬT** (xem `demo/05_KET_QUA_DO_THUC_TE.md`).
>
> Cách đọc file: chữ trong dấu `>` = **nói nguyên văn**. Chữ `[ ]` = **việc tay đang làm** (không đọc).

---

## 0. TRƯỚC KHI NÓI 60 GIÂY — 4 việc phải xong

| # | Việc | Kiểm tra |
|---|---|---|
| 1 | Mở `http://localhost:3000/chuan-bi-demo` → đăng nhập `admin`/`admin@123` | |
| 2 | Ô **“Chuẩn bị cho kịch bản”** chọn **① Lost Update** → bấm **⚙ CHUẨN BỊ DEMO** | chip hiện **`LOST_UPDATE`** · thẻ `SP_DangKyHocPhan` = 🟡 *BẢN CHƯA FIX* · dữ liệu **✔ SẴN SÀNG SỬ DỤNG** |
| 3 | Mở sẵn **2 cửa sổ**: cửa sổ thường `sv030` + cửa sổ **Ẩn danh/InPrivate** `sv041`, cả hai vào menu **Đăng ký lớp học phần** | 2 cửa sổ phải khác phiên đăng nhập |
| 4 | Mở sẵn 1 cửa sổ SQL (Workbench/HeidiSQL/phpMyAdmin) để chiếu **bảng kiểm** | tuỳ chọn nhưng rất nên có |

**Điều tuyệt đối không làm:** **KHÔNG F5 cửa sổ B** trong lúc demo (F5 xong nút sẽ thành “Hết chỗ” và bị khoá
⇒ mất luôn cơ hội tái hiện lỗi).

---

## 1. BẢN NGẮN 60–90 GIÂY (nếu bị bấm thời gian)

> “Em xin demo lỗi **mất dữ liệu cập nhật**. Lớp TA chuyên ngành K15 đang **0 trên 1** — nghĩa là **còn đúng
> một suất**. Bây giờ em có hai sinh viên, ở hai cửa sổ độc lập, **cùng bấm Đăng ký** cách nhau khoảng một
> giây. Mời cả lớp chú ý cột sĩ số ở cả hai cửa sổ: **không cửa sổ nào thấy lớp đã hết chỗ**, vì cả hai đều
> đang đọc **cùng một dữ liệu cũ**. Kết quả… **cả hai đều thành công**. Và đây là hậu quả: **hai lượt đăng ký
> cho một chỗ** — lỗi **Lost Update**.”

---

## 2. BẢN ĐẦY ĐỦ ~3 PHÚT — chia 6 nhịp

### 🎬 NHỊP 0 · Câu dẫn nhập (10 giây) — nói trước khi chạm chuột

> “Phần lý thuyết vừa rồi nói về **đọc – kiểm tra – ghi**. Câu hỏi đặt ra là: nếu **hai giao dịch cùng đọc,
> cùng thấy điều kiện còn đúng, rồi cùng ghi** — thì chuyện gì xảy ra? Em không mô tả bằng hình vẽ nữa, em
> **làm thật** trên hệ thống đăng ký học phần của nhóm.”

*Mẹo giữ lớp: hỏi ngược một câu — “Theo các bạn, lớp còn **1 chỗ** mà **2 bạn cùng bấm** thì ai vào?” (thường
lớp trả lời “chỉ 1 bạn”; bạn giữ câu trả lời đó để “đập” ở Nhịp 4.)*

### 🎬 NHỊP 1 · Đặt vấn đề bằng con số (20 giây)

[Chuyển màn hình sang **cửa sổ A**, chỉ vào dòng `LHP506`]

> “Đây là lớp **LHP506 — TA chuyên ngành K15**. Cột sĩ số ghi **0/1**: lớp còn **đúng một chỗ trống**, nút
> **Đăng ký** đang bật. Cửa sổ bên phải là **sv041** — bạn này cũng đang mở **đúng trang đó**, cũng thấy
> **còn một chỗ**, và **em cố ý không refresh** cửa sổ này. Hai bạn đang ra quyết định dựa trên **cùng một
> dữ liệu**.”

### 🎬 NHỊP 2 · Nói rõ “đã tắt gì để tái hiện được lỗi” (20 giây) — ⭐ điểm học thuật

> “Trước khi bấm, em nói rõ **em đã chuẩn bị gì**: hệ thống đang chạy **bản thủ tục chưa fix** —
> `SP_DangKyHocPhan` **thiếu `SELECT … FOR UPDATE`** ở bước kiểm tra sĩ số. Bản này giống bản chính thức
> **đúng một chỗ duy nhất**: nó **đọc sĩ số bằng `SELECT` thường, không khoá dòng**. Em làm vậy vì **đây
> chính là lỗi mà nhóm cần chứng minh**, chứ không phải em dàn dựng kết quả.”

### 🎬 NHỊP 3 · Thao tác + bình luận từng cú bấm (45 giây) — phần “ăn tiền” là lúc màn hình TREO

| Việc làm | Lời nói |
|---|---|
| [A bấm **Đăng ký** ở dòng LHP506] | “**sv030 bấm trước.** Nút chuyển thành `...` — giao dịch đang mở, **chưa commit**.” |
| [Đếm 1… 2… rồi B bấm] | “**sv041 bấm sau khoảng một giây** — vẫn trên dữ liệu cũ: còn một chỗ.” |
| [Chỉ vào cửa sổ B đang quay `...` — **📸 CHỤP ẢNH NGAY**] | “Cả lớp nhìn cửa sổ B: nó **đang chờ**. sv041 đã `INSERT` nhưng **bị chặn lại vì khoá dòng sĩ số** mà sv030 đang giữ. **Đây chính là lúc hai giao dịch tranh chấp nhau** — ảnh này là minh chứng cho báo cáo.” |
| [Sau ~8s: A hiện toast XANH] | “sv030 xong: **đăng ký thành công** — đã lấy **suất cuối cùng**.” |
| [Sau ~16s: B cũng hiện toast XANH] | “Và sv041… **cũng thành công**. **Hai sinh viên vào một lớp một chỗ.** Đó là lỗi.” |

### 🎬 NHỊP 4 · Bằng chứng dữ liệu + giải thích “hỏng âm thầm” (30 giây)

[Chạy câu kiểm tra trên cửa sổ SQL và chiếu kết quả]

```sql
SELECT COUNT(*) AS SoDK_ThucTe,
       (SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP506') AS BoDem_SiSo,
       (SELECT SiSoToiDa  FROM LOPHOCPHAN WHERE MaLHP='LHP506') AS SiSoToiDa
FROM DANGKYHOCPHAN WHERE MaLHP='LHP506' AND TrangThaiDangKy='DA_DANG_KY';
-- THỰC TẾ: 2 | 1 | 1
```

> “**Hai lượt đăng ký thật, nhưng chỉ có một chỗ.** Điểm đáng chú ý là cột `SiSoHienTai` **vẫn ghi 1/1** —
> nhìn giao diện thì **hoàn toàn hợp lệ**. Lý do: trigger cộng sĩ số của nhóm dùng
> `LEAST(SiSoToiDa, SiSoHienTai + 1)` nên **bị chặn trần ở 1**. Nghĩa là lỗi này **hỏng âm thầm**: chỉ khi
> `COUNT(*)` thật mới lộ ra **2 người trong 1 chỗ**. Đây là lý do nhóm em **không trông cậy vào trigger** mà
> phải kiểm soát ngay trong thủ tục.”

> “Về bản chất: điều kiện *‘còn chỗ’* mà sv030 kiểm tra **đã bị sv041 làm mất hiệu lực** — bản cập nhật của
> một bên **bị mất**. Đó là **Lost Update**.”

### 🎬 NHỊP 5 · Fix + demo lại (30 giây) — chuyển từ đỏ sang xanh

> “Cách sửa **không thêm bảng, không thêm cột, không sửa giao diện**. Nhóm em đổi **đúng một câu `SELECT`**
> ở bước kiểm tra sĩ số thành **`SELECT … FOR UPDATE`** — tức **khoá độc quyền (X-lock) dòng sĩ số** và
> **giữ khoá tới lúc `COMMIT`** (tương đương `UPDLOCK + HOLDLOCK` của SQL Server). Vì nằm trong stored
> procedure nên **mọi client đều được bảo vệ**, kể cả người gọi API trực tiếp.”

[Bấm **✔ FIX** trên trang Chuẩn bị Demo (hoặc nạp `mysql/procedures/SP_DangKyHocPhan.sql`), rồi lặp lại y hệt:
chọn lại kịch bản ① → **⚙ CHUẨN BỊ DEMO** → A bấm → B bấm]

> “Làm lại **y hệt**, giao diện **không đổi một dòng**:
> sv030 → **thành công** (nhanh, dưới 1 giây);
> sv041 bấm sau → **toast ĐỎ: *‘Lớp học phần đã đầy sĩ số (hết chỗ trống)’* — mã `105`**.
> Kiểm tra lại: **`1 | 1 | 1`** — **một suất chỉ cấp cho đúng một sinh viên**.”

### 🎬 NHỊP 6 · Câu chốt + chuyển tiếp (15 giây)

> “Ba điều em muốn chốt: **một** — Lost Update là lỗi **thật của hệ thống**, không phải ví dụ nhân tạo, và nó
> **hỏng âm thầm** vì bộ đếm vẫn trông hợp lệ. **Hai** — cách chữa nằm **trọn trong database**: khoá dòng
> đúng lúc, giữ tới `COMMIT`. **Ba** — nhất quán với phần lý thuyết: **MVCC không bảo vệ logic nghiệp vụ**;
> muốn an toàn cho kiểu *đọc – kiểm tra – ghi* thì phải **khoá lưu quan**.”

[Chuyển tiếp] → *“Và khi hai giao dịch khoá **ngược thứ tự nhau**, chúng ta không còn Lost Update nữa mà
sang một lỗi khác: **deadlock** — em xin demo ở phần tiếp theo.”*

---

## 3. NẾU BỊ HỎI — 7 câu giảng viên hay hỏi (trả lời ngắn, đúng)

| Câu hỏi | Trả lời |
|---|---|
| **Vì sao bộ đếm vẫn 1/1 mà có 2 người?** | Trigger dùng `LEAST(SiSoToiDa, SiSoHienTai+1)` ⇒ bị chặn trần; **bản ghi đăng ký vẫn chèn thật** ⇒ `COUNT(*) = 2`. Lỗi hỏng âm thầm ⇒ phải phòng chống ở thủ tục. |
| **`FOR UPDATE` đặt ở đâu, giữ bao lâu?** | Bước 6 của `SP_DangKyHocPhan`: `SELECT SiSoHienTai, SiSoToiDa … FOR UPDATE` **trong** `START TRANSACTION … COMMIT` ⇒ X-lock giữ **tới lúc COMMIT**. |
| **Vậy HQTSCSDL không tự chặn lỗi này à?** | Ở mức `REPEATABLE-READ`, **MVCC chỉ bảo vệ việc *đọc*, không bảo vệ logic *đọc-rồi-ghi* của ứng dụng** ⇒ vẫn phải khoá lưu quan. *(Xem thêm mục 4 bên dưới — có một chi tiết riêng của MariaDB 11.x.)* |
| **`DO SLEEP(8)` có phải nguyên nhân gây lỗi không?** | **Không.** SLEEP chỉ **mở rộng cửa sổ tranh chấp** để người thao tác tay kịp bấm ở cửa sổ kia. Bản đã fix **giữ nguyên cách kiểm tra** mà lỗi biến mất ⇒ bản chất lỗi nằm ở **thiếu `FOR UPDATE`**. |
| **Vì sao B không bị deadlock mà lại chờ?** | `DANGKYHOCPHAN` có **khoá ngoại** tới `LOPHOCPHAN`: mỗi `INSERT` **đã lấy khoá chia sẻ (S)** trên dòng lớp để kiểm tra FK, rồi **trigger** đòi nâng lên **khoá độc quyền (X)** trên cùng dòng. Nếu hai `INSERT` **chồng lên nhau** thì cả hai cùng giữ S và cùng đòi X ⇒ **deadlock 1213**. Vì vậy thủ tục demo đặt `DO SLEEP` **sau `INSERT`, trước `COMMIT`** ⇒ phiên B **chờ khoá** (hình ảnh cần chụp) rồi mới đi tiếp ⇒ ra đúng **Lost Update**. |
| **Sao không dùng `CHECK`/ràng buộc để chặn vượt sĩ số?** | Chặn được *trạng thái* nhưng không chặn được *quyết định* đã ra trên dữ liệu cũ, và làm mất thông báo nghiệp vụ rõ ràng (mã 105). Cách của nhóm: **khoá dòng + trả mã lỗi nghiệp vụ** để giao diện báo đúng cho sinh viên. |
| **Vì sao phải là 2 cửa sổ ẩn danh?** | 2 tab trong **cùng một cửa sổ** dùng chung `localStorage` ⇒ **cùng một phiên đăng nhập**, không tạo được 2 phiên độc lập. |
| ⭐ **“Vậy Lost Update chỗ nào? Có thấy lệnh nào bị đè đâu?”** | Xem **mục 3B** ngay dưới — trả lời theo **3 tầng**: (1) **điều kiện đã kiểm tra** bị mất hiệu lực; (2) bộ đếm **cũng mất một phép `+1`** nhưng bị `LEAST` + ràng buộc `CHECK` **che đi**; (3) chỗ lỗi **hiện rõ**: `COUNT = 2 > SiSoToiDa = 1`. |

---

## 3B. ❓ NẾU BỊ HỎI: “VẬY LOST UPDATE CHỖ NÀO?” ⭐ (câu hỏi khó nhất — trả lời được là điểm cộng lớn)

Trên màn hình, sau demo bạn thấy `COUNT = 2` nhưng bộ đếm **vẫn `1/1`** — nên câu hỏi rất tự nhiên là:
*“Thế cái gì bị **mất**? Có thấy lệnh `UPDATE` nào bị đè đâu?”* Trả lời **theo 3 tầng**, từ đúng bản chất
đến chỗ nhìn thấy được:

### Tầng 1 — Cái bị mất là **điều kiện đã kiểm tra** (đúng đường đi của demo web)

```
Phiên A: đọc 0/1 → “còn chỗ” ✔ → INSERT SV030
Phiên B: đọc 0/1 → “còn chỗ” ✔ → INSERT SV041        ← B đọc CÙNG bản đọc cũ của A
⇒ Kết luận “còn chỗ” của A bị B LÀM MẤT HIỆU LỰC
⇒ 2 bản ghi cho 1 chỗ  (COUNT = 2 > SiSoToiDa = 1)   ← chỗ lỗi hiện rõ
```

> “Cái mất không phải một dòng dữ liệu, mà là **giá trị của phép đọc**: cả hai phiên cùng đọc *‘còn chỗ’*,
> cả hai cùng ghi, nên **điều kiện mà phiên A đã kiểm tra không còn đúng nữa**. Đây đúng là mẫu
> **read → check → write** bị mất tính nguyên tử.”

### Tầng 2 — Bộ đếm `SiSoHienTai` **cũng mất một phép `+1`**, nhưng bị **che mất**

Trigger cộng sĩ số dùng `LEAST(SiSoToiDa, SiSoHienTai + 1)` và bảng còn có ràng buộc
`CONSTRAINT CK_LOPHOCPHAN_SiSo CHECK (SiSoHienTai <= SiSoToiDa)` (`mysql/ddl/00_hocphan_giangvien_ddl.sql`).
Vì vậy phép `+1` thứ hai **không đổi dòng nào** — đo được thật:

```
UPDATE LOPHOCPHAN SET SiSoHienTai = LEAST(SiSoToiDa, SiSoHienTai + 1) WHERE MaLHP='LHP506';
→ Rows matched: 1  ·  Rows CHANGED: 0     ← phép +1 của phiên B bị NUỐT MẤT
```

> “Nếu **không** có `LEAST` và ràng buộc `CHECK`, cột sĩ số sẽ là **`2/1`** — tức lỗi lộ ra ngay ở cột sĩ số.
> Chính hai lớp chặn đó làm lỗi **hỏng âm thầm**: cột vẫn `1/1` trông hợp lệ, phải `COUNT(*)` mới thấy.”

### Tầng 3 — Muốn thấy “mất một phép `+1`” bằng con số: làm trên lớp **còn nhiều chỗ**

Vì LHP506 chỉ có `SiSoToiDa = 1` nên bộ đếm không thể vượt 1 (bị `LEAST` + `CHECK` chặn). Chọn lớp còn
nhiều chỗ — ví dụ **LHP508 = 0/35** — rồi làm đúng 2 câu ghi mù (giá trị do **ứng dụng** tính):

```sql
-- [TAB 1] và [TAB 2] — MỖI PHIÊN tự đọc rồi tự tính giá trị mới
START TRANSACTION;
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP508';   -- cả 2 phiên đều đọc = 0
-- ứng dụng tự tính: 0 + 1 = 1  ⇒  mỗi phiên ghi 1
UPDATE LOPHOCPHAN SET SiSoHienTai = 1 WHERE MaLHP='LHP508';
COMMIT;
```

**KẾT QUẢ ĐO THẬT:**

| | Bộ đếm sau 2 lần `+1` | Kết luận |
|---|---|---|
| Không khoá (đọc thường) | **1/35** | ❌ **mất hẳn 1 phép `+1`** (đáng lẽ `2/35`) |
| Đọc bằng `SELECT … FOR UPDATE` | **2/35** | ✅ phiên B **bị chặn 1,5s** → đọc lại `1` → ghi `2` — **không mất gì** |

> “Đây chính là **Lost Update cổ điển (P4)**: hai giao dịch cùng `+1` trên một dòng, lệnh ghi của phiên B
> **ghi đè** lệnh ghi của phiên A bằng **cùng một giá trị** (vì cùng gốc đọc cũ) ⇒ **một phép cộng biến mất**.
> Thêm `FOR UPDATE` là phiên B buộc phải chờ và **đọc lại giá trị mới** ⇒ không mất.”

### Nếu bị hỏi sâu: “Đây là Lost Update hay Write Skew?”

> “Ở mức **bộ đếm sĩ số**: đúng là **Lost Update (P4)** — hai lần `+1` trên **cùng một dòng**, một lần bị mất.
> Ở mức **bản ghi đăng ký**: hệ quả là **vi phạm bất biến** `COUNT(*) ≤ SiSoToiDa` — mặt này giống
> **write skew** (hai giao tác cùng thoả điều kiện rồi cùng ghi, hợp lệ riêng lẻ nhưng sai khi kết hợp).
> Cả hai cách gọi đều **chữa bằng cùng một giải pháp**: **khoá dòng sĩ số bằng `SELECT … FOR UPDATE`
> và giữ tới `COMMIT`** — biến *đọc – kiểm tra – ghi* thành một chuỗi **tuần tự hoá**.”

---

## 4. ⭐ CHI TIẾT RIÊNG CỦA MÔI TRƯỜNG (nên chủ động nói, rất được điểm)

Máy chủ của nhóm là **MariaDB 11.8**, và từ nhánh 11.x MariaDB **bật mặc định
`innodb_snapshot_isolation = ON`**. Khi bật, ở `REPEATABLE-READ` MariaDB **tự chặn** việc ghi đè dòng đã bị
giao tác khác sửa — nhưng nó chặn bằng một **lỗi hệ thống**:

```
ERROR 1020 (ER_CHECKREAD):
Record has changed since last read in table '...'; try restarting transaction
```

Lúc đó kịch bản Lost Update **không tái hiện được**: phiên thứ hai không nhận “thành công” mà nhận
**`pKetQua = 500`** ⇒ giao diện hiện *“Lỗi hệ thống khi xử lý đăng ký.”*

> **Câu nói gợi ý nếu bị hỏi:** “Máy chủ nhóm em là MariaDB 11.8, mặc định nó có cơ chế **snapshot isolation**
> và **chặn** kiểu ghi đè này bằng lỗi **1020**. Nhưng báo cáo của nhóm viết theo ngữ nghĩa **MySQL 8.0**
> (`REPEATABLE-READ` — không có cơ chế đó), nên nhóm em **tắt `innodb_snapshot_isolation`** cho đúng môi
> trường mô tả trong báo cáo. Đây cũng là một phát hiện khi triển khai thật: **cùng một mức cô lập nhưng hai
> HQTSCSDL xử lý khác nhau**.”

Cách kiểm tra / bật lại:

```bash
cd backend
node scripts/verify-db.js      # phải thấy: innodb_snapshot_isolation = OFF ✅
# nếu đang ON:
node scripts/apply-sql.js ../demo/sql_config/mariadb__tat_snapshot_isolation.sql
# rồi KHỞI ĐỘNG LẠI backend (connection trong pool giữ giá trị cũ)
```

Chi tiết đầy đủ: [`../../demo/01_LOST_UPDATE.md`](../../demo/01_LOST_UPDATE.md) mục “⚠️ BẮT BUỘC TRƯỚC KHI DEMO”.

---

## 5. PHƯƠNG ÁN DỰ PHÒNG (nếu web/mạng có sự cố)

### 5A. Demo bằng **2 tab SQL** (không cần web) — đúng số liệu báo cáo

> Lời dẫn: *“Nếu mạng chậm, em xin demo trực tiếp trên HQTSCSDL bằng hai phiên — bản chất hoàn toàn giống
> nhau, vì web cũng chỉ gọi đúng thủ tục này.”*

```sql
-- TAB 1 (sv030) rồi sang TAB 2 (sv041) trong vòng ~8 giây:
CALL SP_DangKyHocPhan('SV030', 'LHP506', 24, 'Phien A - chua fix', @kqA);
CALL SP_DangKyHocPhan('SV041', 'LHP506', 24, 'Phien B - chua fix', @kqB);
SELECT @kqA, @kqB;          -- THỰC TẾ: 0 và 0  ⇒ CẢ HAI THÀNH CÔNG (lỗi)
-- Bảng kiểm:                                  2 | 1 | 1
```

Và **bản gõ tay đúng số của báo cáo (LHP514 = 15/16 ⇒ 17/16)** — xem
[`kich_ban_thao_tac_tay_lost_update.md`](kich_ban_thao_tac_tay_lost_update.md) PHẦN A.

### 5B. Nếu bị hỏi “chạy trên web hay SQL?” 

> “Cả hai đều là **cùng một thủ tục** `SP_DangKyHocPhan`: web chỉ gọi `CALL SP_DangKyHocPhan(...)`. Em demo
> trên web để thấy **góc độ người dùng**, và trên SQL để thấy **góc độ dữ liệu**.”

---

## 6. NHỮNG CÂU **KHÔNG NÊN NÓI** (dễ bị bắt lỗi)

| ❌ Đừng nói | ✅ Nên nói |
|---|---|
| “MySQL không bao giờ chặn được lỗi này.” | “Ở `REPEATABLE-READ`, MVCC **không bảo vệ** kiểu *đọc-rồi-ghi* của ứng dụng — phải **khoá lưu quan**.” |
| “Trigger cộng sĩ số nên không thể vượt sĩ số.” | “Trigger **chặn trần bộ đếm**, nhưng **bản ghi vẫn chèn thật** ⇒ `COUNT = 2`.” |
| “Lỗi do `DO SLEEP`.” | “SLEEP chỉ **mở rộng cửa sổ tranh chấp**; lỗi do **thiếu `FOR UPDATE`**.” |
| “Em tắt bảo vệ của database cho dễ demo.” *(nghe như ăn gian)* | “Em đang chạy **bản thủ tục chưa fix** — **đúng cái lỗi cần chứng minh**; bản chính thức có `FOR UPDATE`.” |
| “Phiên B bị chặn nên không đăng ký được.” | “Phiên B **chờ khoá ~8 giây rồi vẫn vào được** — vì nó đã đọc sĩ số **trước khi** phiên A commit.” |

---

## 7. SAU KHI DEMO XONG (bắt buộc)

1. Vào `http://localhost:3000/chuan-bi-demo` → bấm **✔ FIX** (trả 2 thủ tục về bản chính thức + dựng lại dữ liệu).
2. Xác nhận: chip **“Kịch bản đang sẵn sàng”** biến mất · 2 thẻ = 🟢 **BẢN CHÍNH THỨC** · dữ liệu **✔ SẴN SÀNG SỬ DỤNG**.
3. Muốn kiểm chứng lại toàn bộ bằng dòng lệnh: `node demo/cong_cu_do/do_prepare_1click.mjs`
   (tự chạy cả 5 kịch bản + nút FIX, kết thúc bằng việc trả hệ thống về bản chính thức).
