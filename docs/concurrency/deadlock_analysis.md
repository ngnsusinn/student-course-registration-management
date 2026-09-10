# 🔒 PHÂN TÍCH DEADLOCK TOÀN HỆ THỐNG & QUYẾT ĐỊNH NGĂN NGỪA / CHẤP NHẬN

> **Hệ thống:** Quản lý Đăng ký học phần Sinh viên
> **Module:** Đăng ký học phần (TV3 — Leader)
> **Chương:** 5 — Điều khiển cạnh tranh (Deadlock · 2PL · Lock ordering)
> **HQTCSDL thực tế:** **MySQL 5.7.41-cll-lve**, engine **InnoDB** (hosting `free02.123host.vn`)
> **Tài liệu liên quan:** `docs/concurrency/deadlock_demo.md` (kịch bản demo + log thực đo) · `docs/concurrency/isolation_level_analysis.md` · `docs/concurrency/concurrency_anomaly_demo.md`

---

## I. DEADLOCK LÀ GÌ?

**Deadlock (khóa chết)** xảy ra khi từ **2 giao dịch** trở lên **giữ khóa của nhau** theo một **chu trình**, không giao dịch nào có thể tiến tiếp.

Bốn **điều kiện Coffman** — deadlock chỉ xảy ra khi **đồng thời** thỏa cả 4:

| # | Điều kiện | Trong hệ thống này |
|---|---|---|
| 1 | **Loại trừ lẫn nhau** (Mutual Exclusion) | `SELECT ... FOR UPDATE` lấy **X-lock** trên dòng `LOPHOCPHAN` / `DANGKYHOCPHAN` |
| 2 | **Giữ và chờ** (Hold and Wait) | Giao dịch khóa dòng thứ nhất **rồi mới** xin dòng thứ hai |
| 3 | **Không tiếm quyền** (No Preemption) | InnoDB **không** tự thu hồi khóa của giao dịch đang chạy |
| 4 | **Chờ vòng tròn** (Circular Wait) | A chờ khóa của B, B chờ khóa của A |

> Hệ quả thiết kế: **phá vỡ 1 trong 4 điều kiện là hết deadlock.** Cách nhóm chọn là **phá điều kiện 4** — *khóa theo thứ tự nhất quán* — vì đó là cách **rẻ nhất và triệt để nhất**.

---

## II. HQTCSDL (InnoDB) LÀM ĐƯỢC GÌ — VÀ **KHÔNG** LÀM ĐƯỢC GÌ

| Cơ chế | Phạm vi | Hành vi | Mã lỗi |
|---|---|---|---|
| `innodb_deadlock_detect = ON` (**mặc định**) | **Khóa dòng & khóa bảng của InnoDB** | Dựng **đồ thị chờ**, phát hiện chu trình ⇒ chọn **nạn nhân** ⇒ **ROLLBACK** giao dịch đó; giao dịch kia đi tiếp | **1213** `ER_LOCK_DEADLOCK` |
| `innodb_deadlock_detect = OFF` | — | Không phát hiện ⇒ các giao dịch **chờ nhau tới hết timeout** | **1205** `ER_LOCK_WAIT_TIMEOUT` |
| `innodb_lock_wait_timeout` (mặc định **50 s**) | Khóa dòng InnoDB | Cắt thời gian chờ khóa ⇒ biến “treo vô hạn” thành “treo có hạn” | **1205** |
| Bộ phát hiện deadlock của **user-level lock** | `GET_LOCK()` ↔ `GET_LOCK()` | Có phát hiện (từ MySQL 5.7) | **3058** `ER_USER_LOCK_DEADLOCK` |
| Bộ phát hiện deadlock của **MDL** | metadata lock (DDL) | Có phát hiện | **1213** |
| ⚠️ **Vòng tròn VẮT QUA hai miền** (`GET_LOCK` ↔ khóa dòng InnoDB) | **Không miền nào thấy đủ chu trình** | **KHÔNG AI BỊ ROLLBACK — TREO** tới hết timeout | **1205** (một phía) + `GET_LOCK` trả **0** |
| `SELECT ... FOR UPDATE` | Khóa dòng | **Công cụ** để ứng dụng tự kiểm soát thứ tự & thời gian giữ khóa | — |

**Kết luận quan trọng:**
> InnoDB **KHÔNG phòng chống deadlock** — nó **phát hiện và dọn hậu quả**, hoặc **cắt chờ bằng timeout**. Việc **phòng chống** (không để chu trình hình thành) là **trách nhiệm của người thiết kế giao dịch**.

**Minh chứng quyền trên hosting (đo thật):** `SET GLOBAL innodb_deadlock_detect = OFF` → **ERROR 1227** *(cần `SUPER`)*; `SHOW ENGINE INNODB STATUS` / `INFORMATION_SCHEMA.INNODB_TRX` → **ERROR 1227** *(cần `PROCESS`)*. ⇒ Trên hosting chia sẻ, **không tắt được** bộ phát hiện và **không đọc được báo cáo deadlock** của InnoDB; nhóm dùng **phương án thay thế** + mã lỗi + `SHOW FULL PROCESSLIST` làm bằng chứng (chi tiết: `deadlock_demo.md` mục 3.3–3.4).

---

## III. CÁC TÌNH HUỐNG DEADLOCK **THẬT** CỦA HỆ THỐNG

### Tình huống A — Đăng ký nhiều lớp với **thứ tự người dùng chọn**

```
SV030: LHP514 → LHP506              SV041: LHP506 → LHP514
T1 giữ LHP514, xin LHP506 ⏳        T1' giữ LHP506, xin LHP514 ⏳
        ⇒ chu trình ⇒ DEADLOCK 1213  (đo thực tế: phát hiện ngay, một phiên bị rollback)
```
* **Nguồn:** bản triển khai **có lỗi** của `SP_DangKyNhieuHocPhan` (`mysql/transactions/demo_deadlock_chuafix.sql`) — **con trỏ** khóa lần lượt theo thứ tự sinh viên tick chọn trên trang *Đăng ký lớp học phần*.
* **Tính chất:** *tất yếu* khi 2 người chọn ngược thứ tự và bấm cùng lúc — xác suất **tăng theo bình phương số lớp** trong một giao dịch.

### Tình huống B — ⭐ **LỖI THẬT**: đảo thứ tự khóa giữa ĐĂNG KÝ và HỦY

| | `SP_DangKyHocPhan` (nhánh **đăng ký lại** dòng `DA_HUY`) | `SP_HuyDangKy` (**bản cũ**) |
|---|---|---|
| Khóa thứ 1 | `LOPHOCPHAN` (`FOR UPDATE`, bước 6) | `DANGKYHOCPHAN` (`JOIN ... FOR UPDATE`) |
| Khóa thứ 2 | `DANGKYHOCPHAN` (`UPDATE` tái sử dụng dòng) | `LOPHOCPHAN` (**qua trigger** `TRG_DANGKYHOCPHAN_AFTER_UPDATE`) |
| Thứ tự | **LOPHOCPHAN → DANGKYHOCPHAN** | **DANGKYHOCPHAN → LOPHOCPHAN** ← *đảo nhau* |

* **Kích hoạt:** SV vừa **hủy** một lớp (còn dòng `DA_HUY`) rồi **đăng ký lại** đúng lúc một phiên khác **hủy** lớp đó.
* **Đo thực tế:** **`1213` sau ~0,58 s**, một phiên bị rollback.
* **Bản chất:** **lỗi thiết kế**, tất yếu xảy ra với tần suất cao trong mùa “đổi lớp” ⇒ **phải sửa**, không thể chỉ retry.
* **Đã sửa:** `mysql/procedures/SP_HuyDangKy.sql` nay **khóa `LOPHOCPHAN` TRƯỚC** rồi mới đọc `DANGKYHOCPHAN` — **cùng thứ tự** với `SP_DangKyHocPhan`. Bản cũ được giữ lại **chỉ để demo** dưới tên `SP_Demo_PhienGiaoDich('HUY_CHUA_FIX', …)`.

### Tình huống C — Vòng tròn **hai miền khóa** (khóa dòng ↔ khóa ứng dụng)

```
A: giữ KHÓA DÒNG LHP514  →  xin GET_LOCK('…')     [thấy: A chờ user lock]
B: giữ GET_LOCK('…')     →  xin KHÓA DÒNG LHP514  [thấy: B chờ row lock]
        ⇒ KHÔNG bộ phận nào nhìn thấy đủ chu trình ⇒ KHÔNG ai bị rollback ⇒ TREO
```
* **Nguồn:** nếu ứng dụng dùng thêm **khóa tầng ứng dụng** (`GET_LOCK`) song song với khóa dòng của SP — một kỹ thuật khá phổ biến để “tuần tự hóa theo `MaSV`”.
* **Tính chất:** **nguy hiểm nhất** vì **không có cơ chế tự phục hồi**: người dùng thấy màn hình **quay mãi**, không có thông báo lỗi.
* **Trong demo:** đây là cách nhóm **tái hiện trạng thái “đã tắt bộ phát hiện”** khi không có quyền `SUPER`.

---

## IV. CÁCH “TẮT” CƠ CHẾ CỦA HQTCSDL ĐỂ DEMO — VÀ **BẬT LẠI**

```sql
-- (1) Xem HQTCSDL đang phòng chống bằng gì:
SELECT @@innodb_deadlock_detect, @@innodb_lock_wait_timeout, @@transaction_isolation;
--  -> ON | 50 | REPEATABLE-READ

-- (2) TẮT bộ phát hiện deadlock (cần quyền SUPER; chỉ nên làm trên MySQL local/root):
SET GLOBAL innodb_deadlock_detect = OFF;      -- nay deadlock sẽ TREO tới hết timeout (1205)

-- (3) ... chạy lại 2 phiên khóa ngược thứ tự để quan sát ...

-- (4) BẬT LẠI NGAY (bắt buộc — biến này ảnh hưởng TOÀN server):
SET GLOBAL innodb_deadlock_detect = ON;
```

* `innodb_deadlock_detect` là biến **GLOBAL** — `SET SESSION` sẽ báo `ER_GLOBAL_VARIABLE`; tắt là **mọi phiên** đều mất bảo vệ ⇒ **luôn bật lại trong cùng buổi demo**.
* **Trên hosting chia sẻ của nhóm:** `SET GLOBAL …` bị từ chối **1227** ⇒ dùng **phương án thay thế** (tình huống C) để vẫn chứng minh đúng hậu quả “không phát hiện ⇒ treo”, và dùng **`SET SESSION innodb_lock_wait_timeout`** (đổi được) để **bọc** thời gian treo.
* **Nếu không dùng cơ chế mặc định của HQTCSDL** thì phòng chống bằng 4 lớp ở mục VI.

---

## V. ⭐ QUYẾT ĐỊNH: **NGĂN NGỪA** HAY **CHẤP NHẬN** DEADLOCK?

### V.1. Khung ra quyết định (cost model)

| Tiêu chí | **Ngăn ngừa** (khóa theo thứ tự nhất quán) | **Chấp nhận** (để HQTCSDL rollback nạn nhân + retry) |
|---|---|---|
| Chi phí **một lần** | Sửa code/thủ tục, ràng buộc thiết kế (phải có **thứ tự toàn cục** cho tài nguyên) | Gần như **0** — chỉ cần bắt mã 1213 |
| Chi phí **mỗi lần chạy** | **0** (chỉ sắp xếp danh sách trước khi khóa — con trỏ `ORDER BY MaLHP`) | **1 lần rollback + N lần gọi lại**; độ trễ tăng; có thể **retry storm** khi tải cao |
| Ảnh hưởng **người dùng** | Không | Một số request **bị chậm/hủy**; nếu không bắt lỗi thì hiện **lỗi hệ thống 500** |
| **Bảo đảm** | Deadlock **không thể sinh ra** (triệt tiêu điều kiện 4) | Deadlock **vẫn sinh ra**, chỉ được **che** |
| **Giới hạn** | Cần thứ tự toàn cục **và** kiểm soát được **tất cả** giao dịch chạm cùng tài nguyên | Vô dụng với deadlock **ngoài tầm phát hiện** (tình huống C) và với deadlock có **tần suất cao, tất yếu** (tình huống B) |
| Ảnh hưởng **thông lượng** | Thấp (vẫn khóa theo dòng, song song theo dòng khác nhau) | Thấp, nhưng **giảm khi tải cao** do rollback lặp |

### V.2. Quyết định cho **từng** tình huống (có lý lẽ)

| Tình huống | Quyết định | **Vì sao thuyết phục** |
|---|---|---|
| **A** — đăng ký nhiều lớp, thứ tự người dùng chọn | ✅ **NGĂN NGỪA** (khóa theo `MaLHP` tăng dần) | (1) Chi phí phòng chống **bằng 0 lúc chạy** — chỉ `ORDER BY MaLHP` trong con trỏ. (2) Nó **triệt tiêu** deadlock chứ không che. (3) Deadlock ở đây là **tất yếu theo thiết kế** (xác suất tăng theo số lớp), nên “chấp nhận + retry” sẽ **lặp lại thường xuyên** ⇒ tốn kém và dễ retry storm. (4) Quy tắc “mọi giao dịch khóa tài nguyên theo cùng một thứ tự” là **quy ước dễ kiểm tra, dễ dạy lại cho cả nhóm**. |
| **B** — đảo thứ tự khóa ĐĂNG KÝ ↔ HỦY | ✅ **NGĂN NGỪA — bắt buộc, đã sửa** | Đây là **bug**, không phải “rủi ro ngẫu nhiên”: hai thủ tục lõi (**đăng ký**, **hủy**) mâu thuẫn thứ tự khóa. Nếu chỉ retry: (1) mỗi lần SV đổi lớp là một lần hủy giao dịch ⇒ **chậm, mất công**, (2) bug vẫn còn trong hệ thống ⇒ **không thể bảo vệ** trước lớp, (3) **sửa chỉ 1 chỗ** (`SP_HuyDangKy` khóa `LOPHOCPHAN` trước) mà **hết vĩnh viễn**. Tỉ lệ *chi phí sửa / lợi ích* là tốt nhất trong cả ba tình huống. |
| **C** — vòng tròn hai miền khóa (`GET_LOCK` ↔ khóa dòng) | ✅ **NGĂN NGỪA** (không dùng khóa ứng dụng chồng lên khóa dòng; nếu buộc phải dùng thì **đặt tên khóa theo thứ tự** và **timeout ngắn**) | **Chấp nhận là vô nghĩa** ở đây vì **không có bộ phát hiện nào cứu được**: cả 2 phiên treo tới timeout, người dùng **không nhận được thông báo** nào. Đây là tình huống duy nhất mà “để HQTCSDL lo” **thất bại hoàn toàn**. |
| **D** — tranh chấp **cùng thứ tự** (chờ nhau một chiều), deadlock do **gap lock** khi `INSERT`/`DELETE` đồng thời, deadlock phát sinh khi index/schema đổi | ✅ **CHẤP NHẬN + RETRY** | (1) **Không thể** triệt tiêu bằng thứ tự khóa (không có chu trình cố định; gap lock phụ thuộc kế hoạch thực thi và dữ liệu). (2) Tần suất **thấp và ngẫu nhiên**. (3) Chi phí retry **rất nhỏ** so với việc hạ thông lượng bằng khóa thô (`LOCK TABLES`, `SERIALIZABLE` toàn cục). (4) Đây là **pattern chuẩn** của mọi hệ giao dịch thực tế (ngân hàng, thương mại điện tử). |

### V.3. Kết luận — chọn **CẢ HAI**, theo tầng (đây là câu trả lời cuối cùng)

> **Nhóm chọn “NGĂN NGỪA” làm tuyến chính và “CHẤP NHẬN + RETRY” làm lưới an toàn.**
>
> 1. **Ngăn ngừa ở tầng thiết kế** cho mọi deadlock **do thứ tự khóa** (tình huống A, B, C) — vì đây là loại **tất yếu, lặp lại, đoán trước được**, và cách sửa **rẻ như không** (sắp xếp `MaLHP` tăng dần trong con trỏ; sửa `SP_HuyDangKy`). Ngăn ngừa **triệt tiêu** vấn đề thay vì che nó, và **không tốn gì lúc chạy**.
> 2. **Chấp nhận + retry ở tầng vận hành** cho phần deadlock **còn sót lại** (tình huống D) — vì loại này **ngẫu nhiên, tần suất thấp**, và **không thể** loại bỏ hoàn toàn nếu không hy sinh thông lượng. `SP_DangKyHocPhan` đã có **vòng retry khi `pKetQua = 1213`**; web hiển thị thông báo **1213/1205** rõ ràng cho người dùng.
> 3. **Bọc thời gian** bằng `innodb_lock_wait_timeout` ngắn (thay vì 50 s mặc định) để người dùng **nhận phản hồi trong vài giây** thay vì màn hình quay mãi.
>
> **Vì sao KHÔNG chọn “chỉ chấp nhận”?** Vì nó **không sửa được bug thiết kế** (tình huống B), **không cứu được deadlock ngoài tầm phát hiện** (tình huống C), và biến một lỗi *có thể triệt tiêu miễn phí* thành **chi phí vận hành lặp lại mãi mãi**.
>
> **Vì sao KHÔNG chọn “ngăn ngừa bằng mọi giá”?** Vì các biện pháp thô (`SERIALIZABLE` toàn cục, `LOCK TABLES`, khóa 1 khóa lớn cho cả hệ thống) sẽ **giết thông lượng** — trong khi InnoDB đã có sẵn cơ chế phát hiện + rollback **rất rẻ** cho phần tranh chấp ngẫu nhiên còn lại.

### V.4. Bảng “ai làm gì” trong source

| Tầng | Cơ chế | Vị trí |
|---|---|---|
| Thiết kế giao dịch | **Khóa theo thứ tự nhất quán** (con trỏ `ORDER BY`) | `SP_DangKyNhieuHocPhan`, `SP_Demo_KhoaTheoThuTu`; `SP_HuyDangKy` (đã sửa) |
| Thiết kế giao dịch | **Giữ khóa ngắn** — chỉ `FOR UPDATE` đúng dòng sĩ số, tách bước chỉ-đọc ra ngoài | `SP_DangKyHocPhan` bước 6 |
| Vận hành | **Bọc timeout** `innodb_lock_wait_timeout` | tầng kết nối DB + xử lý mã 1205 ở web |
| Vận hành | **Chấp nhận + retry 1213** | `SP_DangKyHocPhan` (vòng `REPEAT … UNTIL vXong = 1`) |
| Trình bày | **Thông báo rõ ràng** mã 1213/1205 cho người dùng | `frontend/src/utils/format.js` (`KHOA_ERRORS`), `DangKyHocPhan.jsx` |

---

## VI. BỐN LỚP PHÒNG CHỐNG (TÓM TẮT ĐỂ TRÌNH BÀY)

1. **Khóa theo thứ tự nhất quán** — *phá điều kiện “chờ vòng tròn”*. ⭐ Quan trọng nhất.
2. **Giữ khóa ngắn & khóa đúng dòng cần thiết** — giảm xác suất chồng lấn.
3. **Bọc thời gian chờ khóa** (`innodb_lock_wait_timeout` ngắn) — biến “treo vô hạn” thành “treo có hạn + có thông báo”.
4. **Bắt lỗi 1213 và RETRY ở tầng ứng dụng** — lưới an toàn cho phần tranh chấp còn lại.

---

## VII. KIỂM CHỨNG THỰC TẾ (đã chạy, không phải lý thuyết)

| Kịch bản | Kết quả đo được |
|---|---|
| Khóa 2 dòng theo thứ tự ngược nhau (InnoDB detector ON) | **1213** ở một phiên, phiên kia `COMMIT` — phát hiện trong **~0,5 s** |
| `SET GLOBAL innodb_deadlock_detect = OFF` trên hosting | **ERROR 1227** (cần `SUPER`) → phải dùng phương án thay thế |
| Vòng tròn **hai miền khóa** (`GET_LOCK` ↔ khóa dòng) | **Không ai bị rollback**: một phiên `1205` sau 8 s, phiên kia `GET_LOCK` trả `0`; `PROCESSLIST` hiện `User lock` / `statistics` |
| Lỗi thật: `SP_DangKyHocPhan` ↔ `SP_HuyDangKy` bản cũ | **1213** sau **~0,58 s** |
| Sau khi sửa `SP_HuyDangKy` (khóa `LOPHOCPHAN` trước) | **Không còn 1213** |
| Bản **đã fix** (`mysql/procedures/SP_DangKyNhieuHocPhan.sql` — con trỏ luôn sắp `MaLHP` tăng dần) cho cùng tình huống tranh chấp | **0 × 1213** — deadlock bị triệt tiêu |
| Góc độ người dùng (API thật `POST /dangky/nhieu`): 2 SV tick 2 lớp ngược thứ tự | Bản SP có lỗi ⇒ một SV nhận **1213**; khôi phục bản đã fix ⇒ **không còn 1213** |

**Chạy lại toàn bộ:**
```bash
cd backend
node scripts/apply-sql.js ../mysql/transactions/demo_deadlock.sql    # tạo/cập nhật 3 SP demo deadlock
node scripts/apply-sql.js ../mysql/procedures/SP_DangKyNhieuHocPhan.sql  # SP thật (bản đã fix)
```
**Demo thủ công 2 cửa sổ:** [`docs/concurrency/script_demo_sql.md`](script_demo_sql.md) — **PHẦN B** (deadlock) và **PHẦN C** (thao tác thật trên web).

---

## VIII. KẾT LUẬN

1. Deadlock là **rủi ro thực tế và có thật** của bài toán đăng ký: nhóm đã **tái hiện được lỗi trong chính source** (`SP_HuyDangKy` bản cũ), không chỉ mô tả lý thuyết.
2. **HQTCSDL chỉ phát hiện & dọn hậu quả** (1213 / 1205), **không phòng chống**, và **có điểm mù** (vòng tròn vắt qua hai miền khóa) → **không thể trông cậy hoàn toàn**.
3. Nhóm chọn **NGĂN NGỪA là tuyến chính** (khóa theo thứ tự nhất quán bằng **con trỏ**) + **CHẤP NHẬN & RETRY là lưới an toàn**, kèm **bọc timeout** và **thông báo rõ ràng** cho người dùng — lựa chọn này **rẻ lúc chạy, triệt để với lỗi thiết kế, và vẫn chịu được tranh chấp ngẫu nhiên**.
4. Toàn bộ cơ chế nằm **trong database (thủ tục)** ⇒ mọi client (web, script, công cụ) đều được bảo vệ như nhau.
