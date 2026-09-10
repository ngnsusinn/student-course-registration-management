# 🔒 BÁO CÁO DEMO DEADLOCK — HQTCSDL HỖ TRỢ GÌ, CÁCH TẮT ĐỂ DEMO, VÀ CÁCH PHÒNG CHỐNG

> **Module:** Đăng ký học phần (TV3 — Leader) · **Chương 5:** Điều khiển cạnh tranh (Deadlock · 2PL · Lock ordering)
> **Tài liệu:** `docs/concurrency/deadlock_demo.md`
> **Trạng thái:** ✅ Đã kiểm chứng **trực tiếp trên MySQL remote thật** (`free02.123host.vn` — **MySQL 5.7.41-cll-lve**, InnoDB) bằng chính các script SQL trong [`script_demo_sql.md`](script_demo_sql.md).
>
> ⚠️ **Trong ứng dụng KHÔNG có màn hình demo nào.** Toàn bộ giao diện là giao diện nghiệp vụ thật
> mà sinh viên/cán bộ sử dụng hằng ngày. Lỗi được tạo ra bằng **thao tác thật của người dùng**.
>
> **Toàn bộ demo chạy bằng SQL trên DB** — script đầy đủ: [`script_demo_sql.md`](script_demo_sql.md).
>
> **Hai gốc độ demo:**
> 1. **Trực tiếp trên HQTCSDL** (bắt buộc) → **PHẦN B** của `script_demo_sql.md` (2 cửa sổ mysql client)
> 2. **Góc độ người dùng (điểm cao hơn)** → **PHẦN C**: triển khai phiên bản SP có lỗi trong DB rồi để 2 sinh viên thao tác thật trên trang **Đăng ký lớp học phần**
>
> ⚠️ Trong code web **không có màn hình, API hay module demo nào** — web chỉ gọi stored procedure.

---

## 0. TÓM TẮT 1 TRANG (dùng để trả lời miệng)

| Câu hỏi của đề bài | Trả lời của nhóm | Bằng chứng |
|---|---|---|
| Hệ thống **có** deadlock không? | **CÓ**, 3 tình huống thật (mục 2) | Mục 3 (2 cửa sổ SQL) + mục 5 (2 trình duyệt) |
| Tình huống nào xảy ra? | (a) 2 giao dịch khóa 2 dòng theo **thứ tự ngược nhau**; (b) **đảo thứ tự khóa giữa ĐĂNG KÝ và HỦY**; (c) vòng tròn **khóa dòng ↔ khóa ứng dụng** | Mục 2 |
| HQTCSDL hỗ trợ cái gì? | **Đồ thị chờ (wait-for graph)** + **tự chọn nạn nhân và rollback** (error **1213**); **bọc thời gian chờ** `innodb_lock_wait_timeout` → **1205**; công cụ `SELECT ... FOR UPDATE`, `SHOW ENGINE INNODB STATUS` | Mục 1 + `script_demo_sql.md` B.0 |
| Phòng chống bằng cách nào? | **Khóa theo thứ tự nhất quán** (consistent lock ordering) thực hiện bằng **CON TRỎ sắp xếp `MaLHP` tăng dần** trước khi `FOR UPDATE` | Pha ⑤ (0 × 1213) |
| Tắt cơ chế mặc định để demo được không? | **Trên hosting chia sẻ: KHÔNG** — `SET GLOBAL innodb_deadlock_detect = OFF` bị từ chối (**ERROR 1227, cần quyền SUPER**). Nhóm dùng **phương án thay thế** (mục 3.4) vẫn ra đúng hiện tượng **TREO — không thao tác được gì nữa** | Pha ① và ③ |
| Nếu không dùng cách mặc định của HQTCSDL thì dùng cách nào? | 3 lớp: **(1) thứ tự khóa nhất quán** · **(2) `innodb_lock_wait_timeout` ngắn + thông báo** · **(3) bắt 1213 và RETRY** | Pha ⑤, ⑥; mục 6 |
| Lựa chọn ngăn ngừa hay chấp nhận deadlock? | **Cả hai, theo tầng**: *ngăn ngừa* cho deadlock do **thiết kế sai thứ tự khóa** (đã sửa hẳn); *chấp nhận + retry* cho tranh chấp ngẫu nhiên cùng thứ tự — xem lý lẽ ở `deadlock_analysis.md` mục V | Pha ④⑤⑥ |
| Hệ thống có **lỗi demo được** không? | **CÓ** — 2 lỗi thật: (1) `SP_HuyDangKy` bản cũ đảo thứ tự khóa so với `SP_DangKyHocPhan`; (2) bản triển khai `SP_DangKyNhieuHocPhan` khóa theo thứ tự sinh viên tick chọn (`demo_deadlock_chuafix.sql`) | Pha ④ + mục 5.2 |
| Thay đổi có dùng **con trỏ (CURSOR)** không? | **CÓ** — mọi thủ tục đăng ký/khóa nhiều lớp dùng `DECLARE ... CURSOR` để duyệt & khóa lần lượt từng dòng sĩ số | `mysql/procedures/SP_DangKyNhieuHocPhan.sql`, `mysql/transactions/demo_deadlock.sql` |
| Có **hiển thị thông báo** khi bị deadlock không? | **CÓ** — web hiện `toast` lỗi *“Xung đột khóa (deadlock 1213)…”* + dòng *“Giao dịch bị hủy (mã 1213)”* ngay trên trang Đăng ký lớp học phần | Mục 5.2 |

---

## 1. HQTCSDL HỖ TRỢ GÌ? (đo thật, không suy đoán)

Chạy ở **CỬA SỔ 1**:

```sql
SELECT @@version               AS PhienBan,          -- 5.7.41-cll-lve
       @@innodb_deadlock_detect AS PhatHienDeadlock, -- ON
       @@innodb_lock_wait_timeout AS ChoKhoaToiDa,   -- 50 (giây)
       @@transaction_isolation  AS MucCoLap;         -- REPEATABLE-READ
```

| Cơ chế HQTCSDL cung cấp | Nó làm gì | Bằng chứng nhóm đã chạy |
|---|---|---|
| **Phát hiện deadlock** (`innodb_deadlock_detect = ON`) | Dựng **đồ thị chờ** giữa các giao dịch; phát hiện **chu trình** ⇒ **tự chọn 1 nạn nhân (victim) và ROLLBACK** giao dịch đó, trả về **`ER_LOCK_DEADLOCK` = 1213**. Giao dịch còn lại đi tiếp. | Pha ②: phiên B nhận **1213**; phiên A `COMMIT` thành công. Thời gian phát hiện **~0,5 s** (đo được 0,46 s ở kịch bản thô) |
| **Bọc thời gian chờ khóa** (`innodb_lock_wait_timeout`, mặc định 50 s) | Nếu không có chu trình (chỉ chờ nhau một chiều) thì không ai bị rollback; phiên chờ bị cắt sau N giây và trả **`ER_LOCK_WAIT_TIMEOUT` = 1205**. | Pha ③: phiên B nhận **1205** sau **8 s** (đã hạ timeout xuống 8 để demo nhanh) |
| **Khóa dòng tường minh** (`SELECT ... FOR UPDATE`) | Cho phép **ứng dụng tự quyết định** khóa gì, theo thứ tự nào, giữ bao lâu → đây là “nguyên liệu” để tự phòng chống deadlock. | `SP_DangKyHocPhan` bước 6, `SP_Demo_KhoaTheoThuTu`, `SP_DangKyNhieuHocPhan` |
| **Báo cáo deadlock của InnoDB** (`SHOW ENGINE INNODB STATUS` → mục `LATEST DETECTED DEADLOCK`) | In ra **đúng 2 giao dịch, đúng câu lệnh, đúng bản ghi** đã gây deadlock — công cụ chuẩn để chứng minh trước lớp. | **Cần quyền `PROCESS`**: trên hosting nhóm bị từ chối (**1227**) — xem mục 3.3 để chạy trên MySQL local/root |
| **Bảng theo dõi khóa** (`information_schema.INNODB_TRX`, `INNODB_LOCK_WAITS`, `INNODB_LOCKS`) | Xem giao dịch nào đang giữ/đợi khóa nào. | **Cũng cần quyền `PROCESS`** → trên hosting nhóm dùng `SHOW FULL PROCESSLIST` (thấy được thread của chính mình) |

> **Kết luận mục 1:** HQTCSDL **không tự phòng chống deadlock** — nó **phát hiện và dọn hậu quả** (rollback nạn nhân) hoặc **cắt chờ bằng timeout**. Việc *phòng chống* (không để deadlock sinh ra) là **trách nhiệm của người thiết kế giao dịch**, và InnoDB cho đủ công cụ (`FOR UPDATE` + thứ tự khóa) để làm việc đó.

---

## 2. BA TÌNH HUỐNG DEADLOCK CỦA HỆ THỐNG

### 2.1. Tình huống A — Đăng ký nhiều lớp, 2 sinh viên chọn **thứ tự ngược nhau**

```
SV030 chọn:  LHP514 → LHP506          SV041 chọn:  LHP506 → LHP514
─────────────────────────────────     ─────────────────────────────────
T1: FOR UPDATE LHP514  ✅ giữ         T1': FOR UPDATE LHP506  ✅ giữ
T2: FOR UPDATE LHP506  ⏳ chờ T1'     T2': FOR UPDATE LHP514  ⏳ chờ T1
        ⇒ CHU TRÌNH: T1 chờ T1', T1' chờ T1  ⇒ DEADLOCK 1213
```

* **Điều kiện Coffman:** đủ cả 4 (loại trừ lẫn nhau · giữ và chờ · không tiếm quyền · **chờ vòng tròn**).
* **Trong hệ thống:** bản triển khai **có lỗi** của `SP_DangKyNhieuHocPhan` (`mysql/transactions/demo_deadlock_chuafix.sql`) — thủ tục dùng **CON TRO** khóa từng dòng sĩ số **theo đúng thứ tự sinh viên tick chọn** trên trang *Đăng ký lớp học phần*.

### 2.2. Tình huống B — **LỖI THẬT**: đảo thứ tự khóa giữa ĐĂNG KÝ và HỦY ⭐

| | `SP_DangKyHocPhan` (khi **đăng ký lại** lớp từng hủy) | `SP_HuyDangKy` (**bản cũ**) |
|---|---|---|
| Bước 1 | khoá `LOPHOCPHAN` (bước 6, `FOR UPDATE`) | khoá `DANGKYHOCPHAN` (`JOIN ... FOR UPDATE`) |
| Bước 2 | `UPDATE DANGKYHOCPHAN` (tái sử dụng dòng `DA_HUY`) | `UPDATE ... DA_HUY` → **trigger** mới cập nhật `LOPHOCPHAN` |
| **Thứ tự khóa** | **LOPHOCPHAN → DANGKYHOCPHAN** | **DANGKYHOCPHAN → LOPHOCPHAN** ← *ngược nhau!* |

Khi SV030 vừa **đăng ký lại** lớp đã hủy, đúng lúc một phiên khác **hủy** lớp đó ⇒ **deadlock 1213** (đo thực tế: **~0,58 s**, một phiên bị rollback).

> Đây là lỗi **có thật trong source**, không phải ví dụ nhân tạo → đáp ứng yêu cầu *“hệ thống phải có lỗi, demo được lỗi”*.
> **Đã sửa:** `mysql/procedures/SP_HuyDangKy.sql` nay **khóa `LOPHOCPHAN` TRƯỚC** rồi mới đọc `DANGKYHOCPHAN` → cùng thứ tự với `SP_DangKyHocPhan`. Bản **cũ** vẫn được giữ lại để demo dưới dạng `SP_Demo_PhienGiaoDich('HUY_CHUA_FIX', ...)`.

### 2.3. Tình huống C — Vòng tròn **hai miền khóa** (khóa dòng ↔ khóa ứng dụng)

Đây là tình huống **HQTCSDL không thể tự cứu** (mục 3.2) và là cách nhóm tái hiện trạng thái *“tắt cơ chế phát hiện”*:

```
Phiên A: giữ KHÓA DÒNG  LHP514  →  xin KHÓA ỨNG DỤNG 'khoa_ung_dung_deadlock'
Phiên B: giữ KHÓA ỨNG DỤNG      →  xin KHÓA DÒNG  LHP514
        ⇒ vòng tròn, nhưng KHÔNG bộ phận nào nhìn thấy đủ vòng tròn
        ⇒ KHÔNG ai bị rollback ⇒ cả 2 phiên TREO
```

---

## 3. DEMO A — TRỰC TIẾP TRÊN HQTCSDL (BẮT BUỘC) 🎯

> **Mở 2 cửa sổ mysql client** (mỗi cửa sổ = 1 session riêng):
> ```bash
> mysql -h free02.123host.vn -u roacqgfa_dbms -p roacqgfa_dbms
> ```
> Hoặc **2 tab phpMyAdmin** của hosting nếu lớp chặn port 3306.
> Toàn bộ lệnh nằm sẵn trong [`script_demo_sql.md`](script_demo_sql.md) — **PHẦN B**; dưới đây là phần cốt lõi.

### 3.1. Chuẩn bị (CỬA SỔ 1, chạy 1 lần)

```sql
SELECT @@version, @@innodb_deadlock_detect, @@innodb_lock_wait_timeout;   -- 5.7.41 | ON | 50
CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506');
-- LHP506 = 1/2 (còn 1 chỗ) · LHP514 = 15/16 (còn 1 chỗ) · SV030 có dòng DA_HUY ở LHP514
```

### 3.2. **HQTCSDL tự phát hiện deadlock** (cơ chế mặc định — không tắt gì)

| Bước | CỬA SỔ 1 | CỬA SỔ 2 |
|---|---|---|
| 1 | `SET SESSION innodb_lock_wait_timeout = 20;`<br>`CALL SP_Demo_KhoaTheoThuTu('SV030','LHP514,LHP506','THEO_YEU_CAU',3,@kq1);` | |
| 2 | *(trong 3 giây cửa sổ 1 đang ngủ và giữ khóa LHP514)* | `SET SESSION innodb_lock_wait_timeout = 20;`<br>`CALL SP_Demo_KhoaTheoThuTu('SV041','LHP506,LHP514','THEO_YEU_CAU',3,@kq2);` |
| 3 | `SELECT @kq1;` → **1213** *(hoặc 0)* | `SELECT @kq2;` → **1213** *(hoặc 0)* |

**Kết quả bắt buộc phải thấy:** **đúng một phiên nhận `1213`** (InnoDB chọn nạn nhân & rollback), **phiên còn lại `0`** (đi tiếp và COMMIT). Sĩ số **không đổi** (demo chỉ khóa, không ghi).

**Nói trước lớp:**
> “InnoDB dựng **đồ thị chờ** giữa các giao dịch. Khi đồ thị có **chu trình**, nó chọn giao dịch **rẻ nhất** làm **nạn nhân**, rollback giao dịch đó và trả lỗi **1213**; giao dịch kia được đi tiếp. Đó là lý do hệ thống **không bị treo vĩnh viễn** — nhưng **phiên bị rollback mất toàn bộ công việc**, nên tầng ứng dụng phải biết mà xử lý.”

### 3.3. **“Tắt” cơ chế phòng chống để demo** — và sự thật trên hosting chia sẻ

**Cách chính thống (khi có quyền `SUPER` / MySQL local, root):**

```sql
SET GLOBAL innodb_deadlock_detect = OFF;   -- (1) TẮT phát hiện deadlock
-- ... chạy lại đúng 2 lệnh CALL ở 3.2 ...
-- KẾT QUẢ: KHÔNG còn 1213. CẢ HAI phiên TREO tới hết innodb_lock_wait_timeout
--          (mặc định 50 giây) rồi nhận 1205 — "bị deadlock, không thao tác được gì nữa"
SET GLOBAL innodb_deadlock_detect = ON;    -- (2) BẬT LẠI NGAY
```

> `innodb_deadlock_detect` là biến **GLOBAL** (không có `SET SESSION` — MySQL trả `ER_GLOBAL_VARIABLE`), nên nếu tắt thì **mọi phiên trên server** đều bị ảnh hưởng ⇒ **bắt buộc bật lại ngay sau demo**.

**Sự thật đo được trên hosting của nhóm (`roacqgfa_dbms`):**

```sql
SET GLOBAL innodb_deadlock_detect = OFF;
-- ERROR 1227 (42000): Access denied; you need (at least one of)
--                    the SUPER privilege(s) for this operation
```

| Lệnh | Kết quả trên hosting | Ý nghĩa |
|---|---|---|
| `SET GLOBAL innodb_deadlock_detect = OFF` | ❌ **1227** — cần `SUPER` | **Không tắt được** ⇒ phải có phương án thay thế |
| `SET SESSION innodb_deadlock_detect = OFF` | ❌ `ER_GLOBAL_VARIABLE` | Biến chỉ có ở mức GLOBAL |
| `SET SESSION innodb_lock_wait_timeout = 5` | ✅ **được** | **Bọc** thời gian treo — dùng để demo nhanh |
| `SHOW ENGINE INNODB STATUS` / `INNODB_TRX` | ❌ **1227** — cần `PROCESS` | Trên hosting không xem được báo cáo deadlock của InnoDB |
| `SHOW FULL PROCESSLIST` | ✅ (thấy thread của chính mình) | Dùng thay thế để **chỉ vào 2 dòng đang treo** |
| `GET_LOCK()/RELEASE_LOCK()` | ✅ | Dùng cho phương án thay thế ở 3.4 |

### 3.4. **PHƯƠNG ÁN THAY THẾ** — vẫn ra đúng hiện tượng “TREO, không thao tác được gì nữa”

Không tắt được bộ phát hiện ⇒ tạo **vòng tròn khóa mà bộ phát hiện KHÔNG nhìn thấy**: **khóa dòng InnoDB ↔ khóa ứng dụng `GET_LOCK`**. Hai bộ phận chỉ nhìn thấy **một nửa vòng tròn** nên **không bên nào phát hiện ra deadlock**.

| Bước | CỬA SỔ 1 | CỬA SỔ 2 |
|---|---|---|
| 1 | `SET SESSION innodb_lock_wait_timeout = 8;`<br>`START TRANSACTION;`<br>`SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514' FOR UPDATE;` | |
| 2 | | `SELECT GET_LOCK('khoa_ung_dung_deadlock', 0);`<br>`START TRANSACTION;` |
| 3 | `SELECT GET_LOCK('khoa_ung_dung_deadlock', 8);`<br>⏳ **quay, không trả kết quả** | `SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514' FOR UPDATE;`<br>⏳ **quay, không trả kết quả** |
| 4 | *(cửa sổ thứ 3)* `SHOW FULL PROCESSLIST;` → thấy `STATE = User lock` và `STATE = statistics` | |
| 5 | sau ~8 s: `GET_LOCK` trả **0** (không lấy được khóa) | sau ~8 s: **ERROR 1205** Lock wait timeout exceeded |

**Nói trước lớp:**
> “Đây là **deadlock mà HQTCSDL không thể tự phát hiện**: InnoDB chỉ dựng đồ thị chờ cho **khóa dòng/bảng của nó**, còn `GET_LOCK` là **khóa do ứng dụng đặt tên** — không nằm trong đồ thị đó. Kết quả: **không ai bị chọn làm nạn nhân**, cả hai phiên **treo**, người dùng **không thao tác được gì nữa**. Nếu để mặc định (`innodb_lock_wait_timeout = 50`, `GET_LOCK(..., -1)`) thì treo **50 giây hoặc vĩnh viễn**. ⇒ Đây là lý do **không thể trông cậy hoàn toàn vào HQTCSDL**, mà phải phòng chống từ thiết kế.”

> 🧠 **Ghi chú kỹ thuật đã kiểm chứng:** MySQL 5.7 **có** phát hiện deadlock **giữa các `GET_LOCK` với nhau** (trả `ER_USER_LOCK_DEADLOCK = 3058`) — nhưng **không** phát hiện vòng tròn **vắt qua hai miền** (`GET_LOCK` ↔ khóa dòng InnoDB). Nhóm đã đo cả hai để nói chính xác.

### 3.5. **Lỗi thật của hệ thống** — đảo thứ tự khóa (tình huống 2.2)

```sql
-- CỬA SỔ 1 (chạy 1 lần để chuẩn bị)
CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506');
```
| CỬA SỔ 1 | CỬA SỔ 2 |
|---|---|
| `CALL SP_Demo_PhienGiaoDich('DANG_KY_CHUA_FIX','SV030','LHP514',3,@kq1);` | `CALL SP_Demo_PhienGiaoDich('HUY_CHUA_FIX','SV030','LHP514',3,@kq2);` |
| `SELECT @kq1;` | `SELECT @kq2;` |

→ **một phiên `1213`**, phiên kia `202` (nghiệp vụ) — **deadlock sinh ra từ chính nghiệp vụ đăng ký/hủy**.

Chạy lại với **bản đã fix** (`..._DA_FIX`) → **không còn `1213`**.

### 3.6. **Bật lại / dùng cách khác để phòng chống** (mục 6)

```sql
SET GLOBAL innodb_deadlock_detect = ON;      -- nếu đã tắt ở 3.3
SET SESSION innodb_lock_wait_timeout = 5;    -- biến treo 50 s thành có hạn
CALL SP_Demo_KhoaTheoThuTu('SV030','LHP514,LHP506','SAP_XEP',3,@kq1);   -- CON TRO tự sắp xếp
CALL SP_Demo_KhoaTheoThuTu('SV041','LHP506,LHP514','SAP_XEP',3,@kq2);
SELECT @kq1, @kq2;                           -- KẾT QUẢ MONG ĐỢI: 0 và 0 — KHÔNG có 1213
```

---

## 4. CƠ CHẾ “TỰ SẮP XẾP” NẰM Ở ĐÂU? (CON TRO — CURSOR)

Thủ tục **thật** phục vụ trang *Đăng ký lớp học phần* là `SP_DangKyNhieuHocPhan`
(`mysql/procedures/SP_DangKyNhieuHocPhan.sql`) — dùng **con trỏ** và **luôn khóa theo `MaLHP` tăng dần**:

```sql
-- 1) Tách danh sách 'LHP514,LHP506' -> bảng tạm, TÍNH SẴN KHÓA SẮP XẾP:
INSERT INTO TAM_DK_NHIEU (ThuTu, MaLHP, KhoaThuTu)
VALUES (vThuTu, vItem, CONCAT('A', vItem));      -- ★ 'A' + MaLHP  ⇒ tăng dần, KHÔNG theo thứ tự tick

-- 2) CON TRO duyệt & KHÓA lần lượt từng dòng sĩ số, giữ khóa tới COMMIT:
DECLARE cur_dk CURSOR FOR
    SELECT MaLHP FROM TAM_DK_NHIEU ORDER BY KhoaThuTu;   -- ★ THỨ TỰ KHÓA = thứ tự con trỏ

OPEN cur_dk;
dk_loop: LOOP
    FETCH cur_dk INTO vMaLHP;
    ...
    SELECT lhp.SiSoHienTai, lhp.SiSoToiDa, ... INTO ...
    FROM LOPHOCPHAN lhp JOIN MONHOC mh ...
    WHERE lhp.MaLHP = vMaLHP
    FOR UPDATE;                                          -- ★ X-lock giữ tới COMMIT
    ...
END LOOP;
CLOSE cur_dk;
COMMIT;                                                  -- ★ nhả toàn bộ khóa
```

> **Bản demo “có lỗi”** `mysql/transactions/demo_deadlock_chuafix.sql` chỉ khác **đúng 1 dòng**:
> `CONCAT('B', LPAD(vThuTu, 6, '0'))` — khóa theo **đúng thứ tự sinh viên tick chọn** ⇒ gây deadlock.
> Đây chính là cách nhóm tạo ra lỗi **bằng thao tác thật trên web**, không cần bất kỳ màn hình demo nào.

| Thủ tục / file | Vai trò | Có ghi dữ liệu? |
|---|---|---|
| `SP_DangKyNhieuHocPhan` (`mysql/procedures/`) | **Đăng ký thật** nhiều lớp trong 1 giao dịch — dùng bởi nút **“Đăng ký N lớp đã chọn”**. Luôn sắp `MaLHP` tăng dần | Có |
| `SP_DangKyNhieuHocPhan` bản **có lỗi** (`mysql/transactions/demo_deadlock_chuafix.sql`) | Bản triển khai lỗi (khóa theo thứ tự tick chọn) — **nguồn gây deadlock thật trên web** | Có |
| `SP_Demo_KhoaTheoThuTu` (`mysql/transactions/demo_deadlock.sql`) | **Chỉ khóa** rồi COMMIT — an toàn tuyệt đối, dùng cho demo **trên HQTCSDL** | Không |
| `SP_Demo_PhienGiaoDich` | Tái hiện **bản chưa fix / đã fix** của ĐĂNG KÝ ↔ HỦY | Có |
| `SP_ChuanBi_Demo_Deadlock` | Đưa dữ liệu demo về trạng thái an toàn (xóa ĐK thử nghiệm, tính lại sĩ số, tạo dòng `DA_HUY`) | Có (dọn dẹp) |

---

## 5. DEMO B — GÓC ĐỘ NGƯỜI DÙNG (ĐIỂM CAO HƠN) 🎯

> **Nguyên tắc:** dùng **đúng giao diện nghiệp vụ thật** — trang *Đăng ký lớp học phần* (SV).
> Không có nút/màn hình demo nào. Lỗi xuất hiện vì **phiên bản thủ tục đang triển khai có lỗi**.

### 5.1. Chuẩn bị
| # | Cửa sổ | Nội dung |
|---|---|---|
| 1 | **Browser A** | Đăng nhập `sv030 / matkhau@123` → menu **Đăng ký lớp học phần** |
| 2 | **Browser B** | Đăng nhập `sv041 / matkhau@123` → cùng trang |
| 3 | **Cửa sổ SQL** | Dùng để chuẩn bị dữ liệu + chứng minh kết quả |

```sql
-- (3) Chuẩn bị dữ liệu + TRIỂN KHAI BẢN CÓ LỖI (mô phỏng "lập trình viên quên sắp xếp thứ tự khóa"):
CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506');
```
```bash
cd backend
node scripts/apply-sql.js ../mysql/transactions/demo_deadlock_chuafix.sql
```

### 5.2. Màn 1 — DEADLOCK **XẢY RA** (bản triển khai khóa theo thứ tự tick chọn)

1. Cả hai trình duyệt mở trang **Đăng ký lớp học phần**, ở bảng *“Học phần đang chờ đăng ký”*.
2. **Browser A (sv030)**: tick **LHP514** rồi **LHP506** *(thứ tự tick: 514 → 506)*.
3. **Browser B (sv041)**: tick **LHP506** rồi **LHP514** *(cố ý ngược)*.
4. Hô **“3 – 2 – 1 – ĐĂNG KÝ!”**, cả hai bấm **“Đăng ký 2 lớp đã chọn”** gần như cùng lúc.
5. **Kết quả:**
   * Một trình duyệt: ✅ *“Đăng ký học phần thành công.”*
   * Trình duyệt kia: ❌ **toast đỏ** *“Xung đột khóa (deadlock 1213): giao dịch đăng ký của bạn bị hệ quản trị CSDL hủy để giải phóng deadlock. Vui lòng bấm đăng ký lại.”* — đồng thời hiện dải **“Giao dịch bị hủy (mã 1213)”** phía trên bảng.

**Nói trước lớp:**
> “Hai sinh viên bấm cùng lúc, mỗi người khóa 2 dòng sĩ số nhưng **theo thứ tự ngược nhau**. Thủ tục dùng **con trỏ** khóa lần lượt từng dòng và **giữ khóa tới lúc COMMIT**. Vì thứ tự ngược nhau nên hình thành **chu trình chờ**. InnoDB **phát hiện và chọn một giao dịch làm nạn nhân**, rollback nó, và **thông báo 1213** hiện thẳng lên màn hình người dùng. Giao dịch kia hoàn tất bình thường.”

### 5.3. Màn 2 — **ĐÃ PHÒNG CHỐNG** (bản đã fix: con trỏ tự sắp `MaLHP` tăng dần)

```bash
# Khôi phục BẢN ĐÃ FIX (thao tác trên web y như cũ, KHÔNG đổi gì trên giao diện):
node scripts/apply-sql.js ../mysql/procedures/SP_DangKyNhieuHocPhan.sql
```
1. Vẫn **2 trình duyệt đó**, vẫn tick **ngược thứ tự nhau**, vẫn bấm **cùng lúc**.
2. **Kết quả:** **không còn toast 1213**. Các thông báo còn lại (nếu có) là **lỗi nghiệp vụ bình thường** — ví dụ *“Bạn chưa hoàn thành môn tiên quyết…”* (mã 102) — chứng tỏ giao dịch **đi được qua bước khóa** mà không bị hủy.

**Nói trước lớp:**
> “Giao diện **không đổi một dòng nào**. Chỉ **thay phiên bản thủ tục trong database**: con trỏ sắp `MaLHP` tăng dần nên mọi giao dịch khóa **cùng một thứ tự** ⇒ **deadlock biến mất**. Đây là cách phòng chống **rẻ nhất, không cần HQTCSDL rollback ai**, và nằm trong database nên **mọi client đều được bảo vệ**.”

### 5.4. (Tùy chọn) Màn 3 — chứng minh bằng SQL

```sql
-- Số đăng ký thực tế không bao giờ vượt sĩ số tối đa, dù xảy ra deadlock:
SELECT lhp.MaLHP, lhp.SiSoHienTai, lhp.SiSoToiDa,
       (SELECT COUNT(*) FROM DANGKYHOCPHAN d
         WHERE d.MaLHP = lhp.MaLHP AND d.TrangThaiDangKy='DA_DANG_KY') AS SoDKThucTe
FROM LOPHOCPHAN lhp WHERE lhp.MaLHP IN ('LHP514','LHP506');
```
→ Deadlock chỉ làm **một giao dịch bị hủy**, **không** làm sai dữ liệu (khác hẳn *Lost Update* — xem `concurrency_anomaly_demo.md`).

**Dọn dẹp:** `CALL SP_ChuanBi_Demo_Deadlock('LHP514,LHP506');` (và chắc chắn đã chạy lại `procedures/SP_DangKyNhieuHocPhan.sql`)

---

## 6. BỐN LỚP PHÒNG CHỐNG / XỬ LÝ DEADLOCK ĐANG CÓ TRONG HỆ THỐNG

| # | Cách | Cài ở đâu | Khi nào dùng | Bằng chứng |
|---|---|---|---|---|
| **1** | **Khóa theo thứ tự nhất quán** (consistent lock ordering) — *ngăn ngừa* | `SP_DangKyNhieuHocPhan` (`mysql/procedures/` — **con trỏ** luôn sắp `MaLHP` tăng dần) + `SP_Demo_KhoaTheoThuTu` (`pKieuKhoa='SAP_XEP'`); `SP_HuyDangKy` đã sửa để khoá `LOPHOCPHAN` trước | Mọi giao dịch khóa **nhiều** tài nguyên. **Đây là cách chính.** | Pha ⑤: 0 × `1213` |
| **2** | **Giữ khóa ngắn** — chỉ khóa **đúng dòng cần**, tách các bước chỉ-đọc ra ngoài giao dịch | `SP_DangKyHocPhan` chỉ `FOR UPDATE` **1 dòng** `LOPHOCPHAN` (không `SERIALIZABLE` toàn bảng) | Mọi giao dịch | `isolation_level_analysis.md` |
| **3** | **Bọc thời gian chờ khóa** — `SET SESSION innodb_lock_wait_timeout` (≤ 10 s cho thao tác người dùng) | Tầng kết nối DB; trên web xử lý mã **1205** | Khi **không** kiểm soát hết được thứ tự khóa (deadlock ngoài tầm phát hiện) | Pha ③: 1205 sau 8 s thay vì treo 50 s |
| **4** | **Chấp nhận deadlock + bắt 1213 và RETRY** — *xử lý* | `SP_DangKyHocPhan` có vòng `REPEAT WHILE` retry tối đa 2 lần khi `pKetQua = 1213`; web hiện thông báo 1213 rõ ràng cho người dùng | Tranh chấp **ngẫu nhiên** trên cùng thứ tự khóa (không thể triệt tiêu bằng thiết kế) | Pha ⑥ |

**Bổ sung (khuyến nghị trình bày):**

* `SET SESSION innodb_lock_wait_timeout` **chỉ ảnh hưởng phiên hiện tại** → an toàn, không đụng cấu hình server (khác `SET GLOBAL`).
* Trên hosting luôn dùng **`SET SESSION`**; chỉ dùng **`SET GLOBAL`** khi có quyền và **bật lại ngay**.

---

## 7. BẰNG CHỨNG CHẠY TỰ ĐỘNG (trích log thực tế)

### 7.1. Kết quả đo ở góc độ HQTCSDL (2 cửa sổ SQL)

```
MySQL 5.7.41-cll-lve | innodb_deadlock_detect = ON | innodb_lock_wait_timeout = 50s | REPEATABLE-READ

PHA co-che            ✅ Không có quyền SUPER → không tắt được innodb_deadlock_detect (1227)
PHA detector-bat      ✅ DEADLOCK ĐÃ XẢY RA và được HQTCSDL tự xử lý:
                         phiên B nhận ER_LOCK_DEADLOCK (1213) và bị rollback sau 2050ms; phiên A hoàn tất
PHA treo-khong-cuu    ✅ DEADLOCK KHÔNG ĐƯỢC PHÁT HIỆN: cả 2 phiên treo tới hết timeout (9.0s)
                         · PROCESSLIST: A = "User lock" (chờ 1s) · B = "statistics" (chờ 1s)
                         · A: GET_LOCK trả 0 · B: LỖI 1205 ER_LOCK_WAIT_TIMEOUT
PHA loi-he-thong      ✅ ĐÃ TÁI HIỆN LỖI THẬT: deadlock 1213 từ nghiệp vụ đăng ký/hủy
PHA ngan-ngua-thu-tu  ✅ PHÒNG CHỐNG THÀNH CÔNG: cùng tình huống nhưng KHÔNG có 1213
PHA retry-1213        ✅ CHẤP NHẬN + RETRY THÀNH CÔNG: lần 1 dính 1213 → lần 2 thành công

TỔNG KẾT: 6/6 pha đúng kịch bản ✅
```

### 7.2. Kết quả đo ở góc độ NGƯỜI DÙNG (2 trình duyệt thật)

```
[2] MySQL 5.7.41-cll-lve · detect=ON · lock_wait=50s · iso=REPEATABLE-READ
[3] PASS ✅ co-che · detector-bat · treo-khong-cuu · loi-he-thong · ngan-ngua-thu-tu · retry-1213
[4] GÓC ĐỘ NGƯỜI DÙNG (bản triển khai CÓ LỖI — khóa theo thứ tự tick chọn)
    Triển khai: demo_deadlock_chuafix.sql
      SV030: HTTP 409 · ketQua=1213 · "Xung đột khóa (deadlock 1213)…"
      SV041: HTTP 200 · ketQua=0    · "Đăng ký học phần thành công."
    → PASS: thao tác thật của 2 sinh viên ⇒ DEADLOCK 1213 (sau 48ms)
[5] GÓC ĐỘ NGƯỜI DÙNG (bản ĐÃ FIX — con trỏ tự sắp MaLHP tăng dần)
    Triển khai: SP_DangKyNhieuHocPhan.sql
      SV030: HTTP 409 · ketQua=102  · "…chưa hoàn thành môn tiên quyết…"  ← lỗi nghiệp vụ, KHÔNG phải deadlock
      SV041: HTTP 200 · ketQua=0    · "Đăng ký học phần thành công."
    → PASS: cùng thao tác thật ⇒ KHÔNG còn deadlock
=== API E2E DEADLOCK: 13 PASS / 0 FAIL ===
```

> Hai sinh viên thao tác trên **đúng giao diện thật** (nút **“Đăng ký N lớp đã chọn”**).
> Kịch bản: triển khai **bản SP có lỗi** (`demo_deadlock_chuafix.sql`) → deadlock hiện trên giao diện →
> khôi phục **bản đã fix** (`SP_DangKyNhieuHocPhan.sql`) → hết deadlock. Chi tiết: `script_demo_sql.md` **PHẦN C**.

---

## 8. CÂU HỎI GIẢNG VIÊN HAY HỎI

1. **“HQTCSDL có tự phòng chống deadlock không?”** — **Không.** InnoDB chỉ **phát hiện** (đồ thị chờ) và **dọn hậu quả** (rollback nạn nhân, lỗi 1213), hoặc **cắt chờ** bằng `innodb_lock_wait_timeout` (lỗi 1205). *Phòng chống* là việc của người thiết kế giao dịch.
2. **“Vì sao tắt `innodb_deadlock_detect` lại phải dùng `SET GLOBAL`?”** — Vì nó là biến **toàn cục**; `SET SESSION` báo `ER_GLOBAL_VARIABLE`. Hệ quả: tắt là **ảnh hưởng mọi phiên** ⇒ phải bật lại ngay. Trên hosting nhóm **không có quyền `SUPER`** nên không tắt được — đã có phương án thay thế (mục 3.4).
3. **“Không tắt được thì làm sao chứng minh được hậu quả của việc không phát hiện?”** — Tạo vòng tròn **vắt qua hai miền khóa** (`GET_LOCK` ↔ khóa dòng): không bộ phận nào thấy đủ chu trình ⇒ **không ai bị rollback** ⇒ cả 2 treo tới `innodb_lock_wait_timeout`. Đây đúng là hậu quả của “không có bộ phát hiện”, và nhóm đã **đo thật** (PROCESSLIST: `User lock` / `statistics`).
4. **“Vì sao chọn **ngăn ngừa** mà không chỉ **chấp nhận** deadlock?”** — Vì lỗi của hệ thống là **sai thứ tự khóa trong thiết kế** (tình huống 2.2): nó **tất yếu** xảy ra với tần suất cao khi SV đổi lớp, và mỗi lần xảy ra là **một giao dịch bị hủy** + retry. Sửa thứ tự khóa là **sửa 1 lần, hết vĩnh viễn, chi phí bằng 0 lúc chạy**. Xem phân tích chi phí đầy đủ ở `deadlock_analysis.md` mục V.
5. **“Vậy sao vẫn giữ retry 1213?”** — Vì **không phải mọi deadlock đều phòng được**: vẫn còn tranh chấp **cùng thứ tự** (chờ nhau một chiều), deadlock do **gap lock** khi chèn/xóa đồng thời, hoặc deadlock phát sinh khi schema/index thay đổi. Retry là **lưới an toàn** chuẩn của mọi hệ giao dịch (kể cả ngân hàng), chi phí rất thấp.
6. **“Deadlock có làm hỏng dữ liệu như Lost Update không?”** — **Không.** InnoDB rollback **toàn bộ** giao dịch nạn nhân (ACID), nên dữ liệu vẫn đúng; cái mất là **công việc của phiên bị hủy**. Khác hẳn Lost Update (17 SV vào lớp 16 chỗ) — xem `concurrency_anomaly_demo.md`.
7. **“Con trỏ (CURSOR) để làm gì trong bài này?”** — Con trỏ quyết định **THỨ TỰ KHÓA**: ở `SP_DangKyNhieuHocPhan` bản đã fix, `ORDER BY KhoaThuTu` với `KhoaThuTu = CONCAT('A', MaLHP)` ⇒ duyệt theo `MaLHP` **tăng dần** ⇒ mọi phiên khóa cùng thứ tự ⇒ không thể có chu trình. Ở bản có lỗi, `KhoaThuTu = CONCAT('B', LPAD(ThuTu,…))` ⇒ duyệt theo **thứ tự tick chọn** ⇒ sinh ra chu trình. Nhờ con trỏ mà việc “khóa nhiều dòng” trở thành **một giao dịch nguyên tử** và **thứ tự kiểm soát được**.
8. **“Nếu để mặc định thì hệ thống treo bao lâu?”** — `innodb_lock_wait_timeout = 50 s`. Quá lâu với người dùng web ⇒ nhóm đặt **ngắn hơn và có thông báo** (mục 6, lớp 3).
10. **“Làm sao chứng minh deadlock xảy ra từ chính thao tác người dùng, không phải từ màn hình demo?”** — Ứng dụng **không có màn hình demo nào** (cũng không có API demo). Kịch bản ở mục 5 dùng đúng trang *Đăng ký lớp học phần*: 2 sinh viên tick 2 lớp ngược thứ tự rồi bấm nút **“Đăng ký N lớp đã chọn”**; phía DB triển khai phiên bản SP có lỗi — đúng cách demo Lost Update bằng `SP_DangKyHocPhan_ChuaFix`.
9. **“Làm sao chứng minh InnoDB thật sự chọn nạn nhân theo đồ thị chờ?”** — `SHOW ENGINE INNODB STATUS` mục `LATEST DETECTED DEADLOCK` in ra **đúng 2 giao dịch và đúng câu lệnh** (cần quyền `PROCESS`; trên hosting bị chặn nên nhóm dùng **mã lỗi 1213 + PROCESSLIST** làm bằng chứng).

---

## 9. CÁC FILE CỦA PHẦN DEMO NÀY

| File | Vai trò |
|---|---|
| `mysql/procedures/SP_DangKyNhieuHocPhan.sql` | ⭐ Thủ tục **THẬT** đăng ký nhiều lớp trong 1 giao dịch (**CON TRO** khóa theo `MaLHP` tăng dần — đã phòng chống deadlock) |
| `mysql/transactions/demo_deadlock_chuafix.sql` | ⚠️ **Bản triển khai CÓ LỖI** của cùng thủ tục (khóa theo thứ tự tick chọn) — nguồn gây **deadlock 1213** bằng thao tác thật trên web |
| `mysql/transactions/demo_deadlock.sql` | ⭐ 3 thủ tục dùng CON TRỎ cho demo **trên HQTCSDL**: `SP_Demo_KhoaTheoThuTu`, `SP_Demo_PhienGiaoDich`, `SP_ChuanBi_Demo_Deadlock` |
| [`docs/concurrency/script_demo_sql.md`](script_demo_sql.md) | ⭐ **TOÀN BỘ SCRIPT SQL DEMO** — PHẦN B: deadlock (2 cửa sổ) · PHẦN C: thao tác thật trên web |
| `mysql/procedures/SP_HuyDangKy.sql` | **Đã sửa lỗi đảo thứ tự khóa** (khoá `LOPHOCPHAN` trước) — bản fix của tình huống 2.2 |

| `frontend/src/pages/sv/DangKyHocPhan.jsx` | Trang **Đăng ký lớp học phần** (giao diện THẬT): tick chọn nhiều lớp → **“Đăng ký N lớp đã chọn”** — nơi deadlock hiện ra bằng thao tác thật |
| `frontend/src/pages/sv/HuyDangKy.jsx` | Trang **Hủy đăng ký HP** (giao diện THẬT) — dùng cho lỗi đảo thứ tự khóa ĐĂNG KÝ ↔ HỦY |
| `backend/scripts/audit-no-raw-query.mjs` | Kiểm chứng tầng web: **không raw query** + **mọi giao tác nằm trong Stored Procedure** |
| `docs/concurrency/deadlock_analysis.md` | Phân tích & **quyết định ngăn ngừa vs chấp nhận** deadlock |

## 10. GHI CHÚ VỀ DỮ LIỆU & AN TOÀN

* Mọi thao tác demo chỉ tác động **2 lớp `LHP514` / `LHP506`** và **2 sinh viên `SV030` / `SV041`**.
* `SP_ChuanBi_Demo_Deadlock` **luôn** xóa đăng ký thử nghiệm, **tính lại sĩ số thực tế**, và chỉ tạo **1 dòng `DA_HUY`** — **không** đụng dữ liệu gốc.
* Mỗi kịch bản đều kết thúc bằng `COMMIT`/`ROLLBACK` + `RELEASE_ALL_LOCKS()` + `SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;` + `SET SESSION innodb_lock_wait_timeout = 50;` (xem PHẦN D của `script_demo_sql.md`).
* **Tuyệt đối không** để `SET GLOBAL innodb_deadlock_detect = OFF` ở trạng thái tắt: kịch bản 3.3 luôn có bước `(2) BẬT LẠI NGAY`.
