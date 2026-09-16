# 7️⃣ TRANG “CHUẨN BỊ DEMO” — 2 NÚT 1-CLICK

> **Mục tiêu:** chuẩn bị **mọi setting** cho buổi demo/lab bằng **1 cú click**, và trả hệ thống về
> bản chính thức cũng bằng **1 cú click** — không cần mở terminal, không cần trình biên soạn DB.

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
| **⚙ CHUẨN BỊ DEMO** | ① Triển khai `SP_DangKyHocPhan` — **bản CHƯA FIX** (thiếu `FOR UPDATE`)<br>② Triển khai `SP_DangKyNhieuHocPhan` — **bản lab** (đọc 2 lần @ `READ COMMITTED`)<br>③ Dọn & chuẩn bị dữ liệu demo | Sẵn sàng demo **Lost Update · Non-repeatable Read · Phantom Read** |
| **✔ FIX** | ① Khôi phục `SP_DangKyHocPhan` — **bản thật** (có `FOR UPDATE` + retry `1213`)<br>② Khôi phục `SP_DangKyNhieuHocPhan` — **bản thật** (khóa theo `MaLHP` tăng dần)<br>③ Dọn dữ liệu về trạng thái xuất phát | Hệ thống trở về **bản chính thức**, không còn thủ tục có lỗi |

### Ô chọn kịch bản (chỉ ảnh hưởng nút CHUẨN BỊ)

| Kịch bản | Triển khai | Dùng cho |
|---|---|---|
| **Demo chính** *(mặc định)* | bản Lost Update + bản lab đọc 2 lần | `01_LOST_UPDATE.md` · `06_WEB_NRR_PHANTOM_THAO_TAC_TAY.md` |
| **Deadlock** | bản Lost Update + bản **khóa theo thứ tự tick chọn** + tạo dòng `DA_HUY` cho SV030 | `04_DEADLOCK.md` PHẦN B |

> ⚠️ **Vì sao Deadlock phải chuẩn bị riêng?** Kịch bản Deadlock và kịch bản NRR/Phantom **dùng chung
> một thủ tục** `SP_DangKyNhieuHocPhan` (nút *“Đăng ký N lớp đã chọn”*), nên **không thể** bật cả hai
> cùng lúc. Ô chọn kịch bản giải quyết việc này — vẫn chỉ **1 click**.

---

## 📊 BẢNG TRẠNG THÁI (trang tự đọc lại sau mỗi lần bấm)

Trang hiển thị ngay **đang ở bản nào**, nên bạn luôn biết mình đã chuẩn bị hay chưa:

| Thẻ trạng thái | Ý nghĩa |
|---|---|
| 🟡 **SẴN SÀNG DEMO** | thủ tục đang là **bản cố ý có lỗi** — có thể demo ngay |
| 🟢 **BẢN CHÍNH THỨC** | thủ tục đang là **bản thật** — hãy bấm *CHUẨN BỊ DEMO* nếu muốn demo |

Kèm theo: **bảng lớp demo** (sĩ số / còn chỗ / `COUNT(*)` hiệu lực) và **bảng tài khoản demo** (kèm
ghi chú tài khoản nào dùng cho kịch bản nào).

---

## 🚶 QUY TRÌNH CHUẨN CHO BUỔI DEMO

```
1. Mở http://localhost:3000 → đăng nhập admin / admin@123
2. Menu ⚙ Chuẩn bị Demo
3. Chọn kịch bản (mặc định: Demo chính) → bấm [⚙ CHUẨN BỊ DEMO]     ← 1 CLICK
4. Đọc bảng trạng thái: cả 2 thẻ phải là 🟡 SẴN SÀNG DEMO
5. Mở 2 trình duyệt và làm theo guide (xem bảng “Sau khi bấm CHUẨN BỊ DEMO” ngay trên trang)
6. Demo xong → quay lại trang này → bấm [✔ FIX]                      ← 1 CLICK
7. Kiểm tra: cả 2 thẻ chuyển 🟢 BẢN CHÍNH THỨC  ⇒ hệ thống đã an toàn
```

> 💡 Nếu cần demo **Deadlock**: quay lại bước 3, đổi ô chọn sang *Deadlock*, bấm CHUẨN BỊ DEMO
> (bấm lại lần nữa cũng được — thao tác này **idempotent**, không làm hỏng dữ liệu).

---

## 🔍 CHUYỆN GÌ XẢY RA BÊN TRONG?

Hai nút chỉ **áp các file SQL đã có sẵn trong repo** rồi gọi SP dọn dữ liệu — **không có logic lạ**:

| Nút | File SQL được áp | Nguồn |
|---|---|---|
| CHUẨN BỊ (Demo chính) | `demo/sql_config/lost_update__chua_fix.sql`<br>`demo/sql_config/lab__dangky_nhieu__chua_fix.sql` | bản cố ý có lỗi của 2 thủ tục |
| CHUẨN BỊ (Deadlock) | `demo/sql_config/lost_update__chua_fix.sql`<br>`demo/sql_config/deadlock__chua_fix.sql` | bản cố ý có lỗi của 2 thủ tục |
| FIX | `mysql/procedures/SP_DangKyHocPhan.sql`<br>`mysql/procedures/SP_DangKyNhieuHocPhan.sql` | **bản chính thức của hệ thống** |

Dữ liệu được dọn bằng **1 stored procedure**: `CALL SP_Prepare_Demo('DEMO' | 'DEADLOCK')` →
xóa đăng ký thử của các tài khoản demo trên các lớp demo, tính lại sĩ số thực tế, đưa `LHP514` và
`LHP506` về *“còn đúng 1 chỗ”*.

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

| Lần bấm | `SP_DangKyHocPhan` | `SP_DangKyNhieuHocPhan` | Dữ liệu |
|---|---|---|---|
| *(trạng thái đầu)* | 🟢 bản thật | 🟡 bản **deadlock** (còn sót từ lần trước — trang phát hiện đúng) | — |
| **⚙ CHUẨN BỊ DEMO** | 🟡 **CHƯA FIX** (`FOR UPDATE = 0`) | 🟡 **bản lab đọc 2 lần** (`vSiSo1 = 1`) | `LHP506 = 0/1`, `LHP514 = 15/16` |
| **✔ FIX** | 🟢 bản thật (`FOR UPDATE = 1`, `DO SLEEP = 0`) | 🟢 bản thật (`vSiSo1 = 0`, `LPAD = 0`) | về trạng thái xuất phát |
| **⚙ CHUẨN BỊ (Deadlock)** | 🟡 CHƯA FIX | 🟡 **khóa theo thứ tự tick** (`LPAD = 1`) + `SV030` có dòng `DA_HUY` ở `LHP514` | `LHP506 = 0/1` |
| **✔ FIX** (lần cuối) | 🟢 bản thật | 🟢 bản thật | về trạng thái xuất phát |

⇒ Cả 3 thao tác đều **HTTP 200**, mỗi thao tác gồm **3 bước** và đều ✔.

> Công cụ kiểm chứng (không bắt buộc): `node demo/cong_cu_do/do_prepare_1click.mjs`
