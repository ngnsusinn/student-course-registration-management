# 7️⃣ TRANG “CHUẨN BỊ DEMO” — 2 NÚT 1-CLICK

> **Mục tiêu:** chuẩn bị **mọi setting** cho buổi demo/lab bằng **1 cú click**, và trả hệ thống về
> bản chính thức cũng bằng **1 cú click** — không cần mở terminal, không cần trình biên soạn DB.
> **Đặc biệt:** nút CHUẨN BỊ DEMO **tự động refresh toàn bộ dữ liệu đăng ký của học kỳ hiện tại** về
> trạng thái xuất phát ⇒ bấm xong là **dùng được ngay**, không phải dọn tay bất cứ thứ gì.

| | |
|---|---|
| **URL** | **http://localhost:3000/chuan-bi-demo** *(hoặc http://localhost:5173/chuan-bi-demo)* |
| **Menu** | **⚙ Chuẩn bị Demo** — hiện cho **cả 3 vai trò** SV · GV · PĐT |
| **Đăng nhập** | Bất kỳ tài khoản (khuyến nghị `admin` / `admin@123`) |
| **API** | `GET /api/prepare/trang-thai` · `POST /api/prepare/chuan-bi` · `POST /api/prepare/fix` |

---

## 🎛️ HAI NÚT

| Nút | Việc nó làm | Kết quả |
|---|---|---|
| **⚙ CHUẨN BỊ DEMO** | ① Triển khai **đúng bộ thủ tục của kịch bản đang chọn** (xem bảng dưới)<br>② **♻ DỰNG LẠI TOÀN BỘ dữ liệu đăng ký của học kỳ hiện tại** rồi bày đúng dữ liệu cho kịch bản | Sẵn sàng demo **đúng 1 kịch bản** đã chọn |
| **✔ FIX** | ① Khôi phục `SP_DangKyHocPhan` — **bản thật** (có `FOR UPDATE` + retry `1213`)<br>② Khôi phục `SP_DangKyNhieuHocPhan` — **bản thật** (khóa theo `MaLHP` tăng dần)<br>③ **♻ DỰNG LẠI TOÀN BỘ dữ liệu** học kỳ hiện tại | Hệ thống trở về **bản chính thức**, không còn thủ tục có lỗi, dữ liệu sạch |

### Ô chọn kịch bản — **MỖI DEMO MỘT LỰA CHỌN RIÊNG** (không gộp)

| # | Kịch bản | `SP_DangKyHocPhan` | `SP_DangKyNhieuHocPhan` | Tài liệu |
|---|---|---|---|---|
| ① | **Lost Update** | `lost_update__chua_fix`<br>*(thiếu `FOR UPDATE` + `DO SLEEP 8s`)* | **bản thật** *(không dùng)* | `01_LOST_UPDATE.md` |
| ② | **Non-repeatable Read** | **bản thật** *(không `DO SLEEP`)* | `lab__dangky_nhieu__chua_fix`<br>*(đọc 2 lần @ `READ COMMITTED`)* | `06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md` KB1 |
| ③ | **Phantom Read** | **bản thật** *(không `DO SLEEP`)* | `lab__dangky_nhieu__chua_fix`<br>*(đọc 2 lần @ `READ COMMITTED`)* | `06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md` KB2 |
| ④ | **Dirty Read** | `lab__dirty_read__writer__chua_fix`<br>*(`INSERT → SLEEP → ROLLBACK`)* | `lab__dirty_read__reader__chua_fix`<br>*(đọc 2 lần @ `READ UNCOMMITTED`)* | `08_DIRTY_READ.md` |
| ⑤ | **Deadlock** | **bản thật** *(không dùng)* | `deadlock__chua_fix`<br>*(khóa theo **thứ tự tick chọn**)* | `04_DEADLOCK.md` PHẦN B |

📌 Kịch bản ② và ③ **dùng chung một bộ thủ tục** (chỉ khác thao tác của người demo: B đăng ký **cùng lớp**
với A ⇒ Non-repeatable Read; B đăng ký **lớp khác** ⇒ Phantom Read), nên chọn cái nào cũng như nhau về
mặt cấu hình.

> ⚠️ **VÌ SAO KHÔNG ĐƯỢC GỘP CÁC KỊCH BẢN LẠI?** Hai lý do — cả hai đều là **xung đột thật**, không phải
> cho gọn:
>
> 1. **② ③ cần `SP_DangKyHocPhan` là BẢN THẬT (không `DO SLEEP`).** Bản *Lost Update* có
>    `DO SLEEP(8)` **sau `INSERT`, trước `COMMIT`** ⇒ giao dịch của trình duyệt B **commit muộn ~8 giây**,
>    tức **muộn hơn “lần đọc 2”** của A trong thủ tục lab ⇒ A đọc 2 lần **giống nhau** ⇒ **không hủy oan**
>    ⇒ kịch bản NRR/Phantom **không tái hiện được**. (Đã đo: chuẩn bị gộp ⇒ A `ketQua = 0`; chuẩn bị
>    riêng với bản thật ⇒ A `ketQua = 104` + dòng `HỦY OAN — … sĩ số 0→1`.)
> 2. **④ cần `SP_DangKyHocPhan` là bản `INSERT → SLEEP → ROLLBACK`** (phiên ghi **không** commit) —
>    khác hẳn bản *Lost Update* (`INSERT → SLEEP → **COMMIT**`).
>
> Vì tất cả kịch bản **chia nhau đúng 2 thủ tục nghiệp vụ**, mỗi lần đổi kịch bản phải bấm
> **⚙ CHUẨN BỊ DEMO** lại. Trang web hiển thị rõ **“Kịch bản đang sẵn sàng”** để không bấm nhầm.

---

## ♻ MỖI LẦN BẤM LÀ MỘT LẦN “REFRESH TOÀN BỘ DỮ LIỆU”

Cả 2 nút đều gọi **`SP_Prepare_Demo(pKichBan)`**. Thủ tục này chạy **PHẦN A — dựng lại dữ liệu học kỳ
hiện tại (HK1-2025)** trước, rồi mới **PHẦN B — bày dữ liệu cho kịch bản**:

| Bước | Việc làm | Vì sao cần |
|---|---|---|
| **A1** | Mở lại **đợt đăng ký** HK1-2025 nếu đã bị đóng / hết hạn (`HOCKY.TrangThaiDot='MO'`, gia hạn `DenNgay` nếu đã qua) | Đợt đóng ⇒ mọi cú bấm “Đăng ký” trả mã **100**, không kịch bản nào chạy được |
| **A2** | Trả `SiSoToiDa` của **5 lớp demo** về giá trị gốc trong seed (`LHP505=40 · LHP506=30 · LHP507=40 · LHP508=35 · LHP514=40`) | `SP_ChuanBi_Demo_4Anomaly` có sửa `SiSoToiDa = SiSoHienTai + 1` |
| **A3** | **Xoá TOÀN BỘ đăng ký của học kỳ hiện tại** — mọi sinh viên, **mọi lớp** (điểm của các lớp đó tự cascade theo) | Xoá sạch mọi dấu vết: đăng ký thừa khi thao tác tay, dòng `DA_HUY`, dòng “bóng ma”, điểm vừa nhập khi demo |
| **A4** | **Sinh lại đúng bộ đăng ký chuẩn** của học kỳ hiện tại (cùng quy tắc với `mysql/data/dangky_hocphan_data.sql` §5) | Dữ liệu về **đúng** trạng thái xuất phát, kể cả khi lần demo trước đã làm sai lệch |
| **A5** | **Tính lại `SiSoHienTai` cho MỌI lớp học phần** | 3 trigger dùng `LEAST/GREATEST` nên đếm lại mới bảo đảm bộ đếm khớp `COUNT(*)` hiệu lực |
| **A6** | Trả **mật khẩu + trạng thái** của tài khoản demo về như seed (`matkhau@123`, riêng `admin` là `admin@123`) | Phòng khi lần demo trước có đổi mật khẩu / khoá tài khoản |
| **B1–B4** | Xoá đăng ký thử của tài khoản demo trên **5 lớp demo**, đưa `LHP514`/`LHP506` về *“còn đúng 1 chỗ”*, (kịch bản Deadlock) tạo dòng `DA_HUY` cho `SV030` | Bày đúng thế cờ cho kịch bản được chọn |

**Hệ quả:** thao tác này **idempotent** — bấm bao nhiêu lần cũng ra đúng một trạng thái. Muốn diễn lại
từ đầu, đổi kịch bản, hay lỡ tay đăng ký linh tinh ở bất kỳ lớp nào ⇒ **chỉ cần bấm lại nút**.

**Không bị đụng tới:** các học kỳ cũ (`HK1-2023` → `HK2-2024`) và các bảng danh mục
(`SINHVIEN`, `LOPHOCPHAN`, `MONHOC`, `GIANGVIEN`, `HOCKY`, `TAIKHOAN`…) — trừ việc **mở lại đợt** (A1)
và **trả mật khẩu demo** (A6) như nói trên.

---

## 📊 BẢNG TRẠNG THÁI (trang tự đọc lại sau mỗi lần bấm)

### 1) Hai thẻ thủ tục

| Thẻ trạng thái | Ý nghĩa |
|---|---|
| 🟡 **SẴN SÀNG DEMO** | thủ tục đang là **bản cố ý có lỗi** — có thể demo ngay |
| 🟢 **BẢN CHÍNH THỨC** | thủ tục đang là **bản thật** — hãy bấm *CHUẨN BỊ DEMO* nếu muốn demo |

### 2) Khối “Dữ liệu học kỳ hiện tại” — biết ngay đã sẵn sàng chưa

Kèm 1 chip **✔ SẴN SÀNG SỬ DỤNG** / **✖ CHƯA SẴN SÀNG** và bảng đối chiếu:

| Hạng mục | Mong đợi |
|---|---|
| Đợt đăng ký | `MO` · còn hạn |
| Đăng ký trong học kỳ | đúng bộ dữ liệu chuẩn (**231** bản ghi với bộ dữ liệu hiện tại) |
| Lớp lệch sĩ số | **0** |
| Đăng ký demo còn sót | **0** |
| Dòng không hiệu lực (`DA_HUY`…) | **0** (riêng kịch bản Deadlock: **1**) |

Ngoài ra trang vẫn hiển thị **bảng lớp demo** (sĩ số / còn chỗ / `COUNT(*)` hiệu lực) và **bảng tài
khoản demo** (kèm ghi chú tài khoản nào dùng cho kịch bản nào).

---

## 🚶 QUY TRÌNH CHUẨN CHO BUỔI DEMO

```
1. Mở http://localhost:3000 → đăng nhập admin / admin@123
2. Menu ⚙ Chuẩn bị Demo
3. Chọn ĐÚNG kịch bản sắp diễn → bấm [⚙ CHUẨN BỊ DEMO]              ← 1 CLICK
4. Kiểm tra ngay trên trang:
     • chip “Kịch bản đang sẵn sàng” = đúng kịch bản vừa chọn
     • 2 thẻ thủ tục = 🟡 SẴN SÀNG DEMO  ·  chip dữ liệu = ✔ SẴN SÀNG SỬ DỤNG
5. Làm theo hướng dẫn từng bước in ngay dưới trang (mục “Kịch bản đang chọn”)
   — nhớ F5 các tab đang mở để thấy dữ liệu mới
6. Demo xong → quay lại trang này → bấm [✔ FIX]                       ← 1 CLICK
7. Kiểm tra: chip “Kịch bản đang sẵn sàng” biến mất + cả 2 thẻ 🟢 BẢN CHÍNH THỨC ⇒ an toàn
```

> 💡 **Muốn demo kịch bản khác?** Quay lại bước 3, chọn kịch bản mới rồi bấm **⚙ CHUẨN BỊ DEMO** một lần nữa.
> Bắt buộc phải bấm lại vì các kịch bản **chia nhau 2 thủ tục** — xem mục ⚠️ ở trên.
> Thao tác này **idempotent**, bấm bao nhiêu lần cũng ra đúng một trạng thái.

---

## 🔍 CHUYỆN GÌ XẢY RA BÊN TRONG?

Hai nút chỉ **áp các file SQL đã có sẵn trong repo** rồi gọi **1 stored procedure** dọn & dựng lại dữ
liệu — **không có logic lạ**:

| Nút / kịch bản | File SQL được áp | Nguồn |
|---|---|---|
| CHUẨN BỊ ① Lost Update | `demo/sql_config/lost_update__chua_fix.sql`<br>`mysql/procedures/SP_DangKyNhieuHocPhan.sql` | bản cố ý có lỗi + bản chính thức |
| CHUẨN BỊ ② ③ NRR / Phantom | `mysql/procedures/SP_DangKyHocPhan.sql`<br>`demo/sql_config/lab__dangky_nhieu__chua_fix.sql` | bản chính thức + bản lab đọc 2 lần |
| CHUẨN BỊ ④ Dirty Read | `demo/sql_config/lab__dirty_read__writer__chua_fix.sql`<br>`demo/sql_config/lab__dirty_read__reader__chua_fix.sql` | bộ lab “ghi không commit” + “đọc bẩn” |
| CHUẨN BỊ ⑤ Deadlock | `mysql/procedures/SP_DangKyHocPhan.sql`<br>`demo/sql_config/deadlock__chua_fix.sql` | bản chính thức + bản khóa theo thứ tự tick |
| **FIX** | `mysql/procedures/SP_DangKyHocPhan.sql`<br>`mysql/procedures/SP_DangKyNhieuHocPhan.sql` | **bản chính thức của hệ thống** |

Mọi lần bấm **⚙ CHUẨN BỊ DEMO** đều kết thúc bằng **`CALL SP_Prepare_Demo('DEMO' | 'DEADLOCK')`** — thủ tục
này **dựng lại toàn bộ dữ liệu học kỳ hiện tại** rồi bày dữ liệu cho kịch bản (xem mục ♻ ở trên).
*(Tham số hồ sơ dữ liệu là `DEMO` cho ①→④ và `DEADLOCK` cho ⑤ — vì ⑤ cần thêm 1 dòng `DA_HUY`.)*

Mỗi lần bấm, trang ghi **4 dòng nhật ký**:
`1 dòng triển khai thủ tục` → `1 dòng triển khai thủ tục` → `1 dòng ♻ dựng lại dữ liệu` → `1 dòng tổng kết`
(ví dụ: *“↳ Học kỳ hiện tại: 231 đăng ký · lệch sĩ số 0 lớp · dấu vết demo còn lại 0 · đợt đăng ký ĐANG MỞ
⇒ SẴN SÀNG SỬ DỤNG”*).

> ✅ Vì mọi thứ đi qua **stored procedure** và **file SQL có sẵn**, không cần khởi động lại backend —
> bấm là có hiệu lực **ngay**.

---

## 🔒 GHI CHÚ AN TOÀN & CÁCH GỠ

- Đây là **công cụ demo**, không phải nghiệp vụ. API yêu cầu **đăng nhập** nhưng **không giới hạn vai trò**
  (để tiện cho lab). **Không nên giữ trong bản production.**
- Chỉ được áp các file trong **whitelist** (`backend/src/prepare/sqlRunner.js`) — không nhận đường dẫn
  từ client ⇒ không có rủi ro path traversal.
- **Cách gỡ hoàn toàn:**
  1. `backend/src/routes/index.js` — bỏ dòng `router.use('/prepare', prepareRoutes);`
  2. `frontend/src/App.jsx` — bỏ route `/chuan-bi-demo`
  3. `frontend/src/config/menu.jsx` — bỏ 3 mục menu + 1 nhãn breadcrumb
  4. Xoá `backend/src/routes/prepare.js`, `backend/src/controllers/prepare.controller.js`,
     `backend/src/models/prepare.model.js`, `backend/src/prepare/`
  5. `cd frontend && node node_modules/vite/bin/vite.js build`
  - *(Không cần xoá `SP_Prepare_Demo` / `SP_Prepare_TrangThai` — chúng vô hại.)*

---

## 📊 KẾT QUẢ ĐO THẬT (chạy `demo/cong_cu_do/do_prepare_1click.mjs`)

| Lần bấm | `SP_DangKyHocPhan` | `SP_DangKyNhieuHocPhan` | Dữ liệu HK1-2025 | Nhật ký |
|---|---|---|---|---|
| *(trạng thái đầu)* | 🟡 bản lỗi (Lost Update) | 🟡 bản lab đọc 2 lần | 231 ĐK · lệch 0 · sót 0 ⇒ ✔ sẵn sàng | — |
| **⚙ ① LOST_UPDATE** | 🟡 `sleep=1, FOR UPDATE=0` | 🟢 bản thật | 231 ĐK · lệch 0 · sót 0 | **4/4 ✔** |
| **⚙ ② NRR** | 🟢 bản thật `sleep=0` | 🟡 lab `vSiSo1=1`, `READ COMMITTED` | 231 ĐK · lệch 0 · sót 0 | **4/4 ✔** |
| **⚙ ③ PHANTOM** | 🟢 bản thật `sleep=0` | 🟡 lab `vSiSo1=1`, `READ COMMITTED` | 231 ĐK · lệch 0 · sót 0 | **4/4 ✔** |
| **⚙ ④ DIRTY_READ** | 🟡 lab `proc_dirty_writer`<br>*(INSERT → SLEEP → ROLLBACK)* | 🟡 lab `proc_dirty_read_ru`<br>*(`READ UNCOMMITTED`)* | 231 ĐK · lệch 0 · sót 0 | **4/4 ✔** |
| **⚙ ⑤ DEADLOCK** | 🟢 bản thật | 🟡 khóa theo thứ tự tick (`LPAD = 1`) + `SV030` có dòng `DA_HUY` ở `LHP514` | 232 ĐK · lệch 0 · sót 0 · không hiệu lực 1 | **4/4 ✔** |
| **✔ FIX** | 🟢 bản thật (`FOR UPDATE=1`, `DO SLEEP=0`) | 🟢 bản thật (`vSiSo1=0`, `LPAD=0`) | 231 ĐK · lệch 0 · sót 0 ⇒ ✔ sẵn sàng | **4/4 ✔** |

> Mã kịch bản cũ `DEMO` (gộp 3 demo) **đã bị bỏ**: gọi `{ kichBan: "DEMO" }` nay trả **HTTP 400**
> với thông báo `kichBan phải là một trong: LOST_UPDATE, NRR, PHANTOM, DIRTY_READ, DEADLOCK.`

### Kiểm chứng khả năng “refresh sạch” (làm bẩn dữ liệu rồi bấm 1 nút)

| Loại “rác” được cố ý tạo ra | Sau khi bấm **⚙ CHUẨN BỊ DEMO** |
|---|---|
| `SV005` đăng ký thêm **lớp demo** `LHP507` | ✅ bị xoá |
| `SV006` đăng ký **lớp KHÔNG thuộc demo** `LHP509` | ✅ bị xoá (xoá theo **cả học kỳ**, không chỉ 5 lớp demo) |
| Điểm `KETQUAHOCTAP` của `SV005`/`LHP507` | ✅ bị xoá theo (FK `ON DELETE CASCADE`) |
| Dòng `DA_HUY` sót của `SV030` ở `LHP514` | ✅ bị xoá |
| Đợt đăng ký bị **ĐÓNG** (`HOCKY.TrangThaiDot='DONG'`) | ✅ tự **MỞ lại** (còn hạn) |
| `sv030` + `admin` bị **khoá + đổi mật khẩu** | ✅ về `ACTIVE` + đúng mật khẩu seed |
| `SiSoToiDa` của `LHP506` bị sửa thành `99` | ✅ về `30` rồi bày lại thành `1` (0/1) |
| `SiSoHienTai` của `LHP508` bị sửa thành `7` | ✅ tính lại **đúng** `0` (khớp `COUNT(*)`) |

Trước khi refresh: `HK1-2025 = 234` bản ghi · **1 lớp lệch sĩ số** · 1 dòng không hiệu lực.
Sau khi refresh: `HK1-2025 = 231` bản ghi · **0 lớp lệch sĩ số** · 0 dòng không hiệu lực · **0 rác**.

⇒ Cả 3 thao tác đều **HTTP 200**, mỗi thao tác gồm **3 bước + 1 dòng tổng kết**, tất cả đều ✔.

> Công cụ kiểm chứng (không bắt buộc): `node demo/cong_cu_do/do_prepare_1click.mjs`
> (backend phải đang chạy ở `http://localhost:3000`).

---

## 🧩 GHI CHÚ KỸ THUẬT

1. **Vì sao phải qua bảng tạm khi xoá đăng ký?** Trigger `TRG_DANGKYHOCPHAN_AFTER_DELETE` có `UPDATE
   LOPHOCPHAN`; nếu câu xoá là `DELETE … JOIN LOPHOCPHAN` thì MariaDB chặn với lỗi **1442**
   (`Can't update table 'LOPHOCPHAN' … already used by statement`). Vì vậy danh sách lớp của học kỳ
   được nạp vào **bảng tạm** `tmp_lhp_hk` rồi mới xoá.
2. **Vì sao trang phải dò dòng tổng kết theo tên cột?** `SP_Prepare_Demo` có gọi 2 SP con
   (`SP_ChuanBi_Demo_4Anomaly`, `SP_ChuanBi_Demo_Deadlock`), nên result set của SP con **bị chèn lên
   trước** dòng tổng kết — backend dò theo cột `DotDangKy_Mo` thay vì tin vào thứ tự result set.
3. **Vì sao phải trả `SiSoToiDa` trước khi dựng lại dữ liệu?** Trigger `AFTER INSERT` dùng
   `LEAST(SiSoToiDa, SiSoHienTai + 1)` — nếu để `SiSoToiDa` bị sửa (ví dụ `99`), bộ đếm sẽ sai cho tới
   khi bước A5 tính lại.
