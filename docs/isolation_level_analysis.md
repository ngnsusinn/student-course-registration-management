# PHÂN TÍCH MỨC CÔ LẬP (ISOLATION LEVEL) CHO ĐĂNG KÝ HỌC PHẦN

> **Hệ thống:** Quản lý Đăng ký học phần Sinh viên  
> **Module:** Đăng ký học phần (TV3 — Leader)  
> **Issue:** #73 Thiết kế mức cô lập (Isolation Level) cho đăng ký  
> **Tài liệu:** `docs/isolation_level_analysis.md`  
> **Chương:** 4 – Quản lý giao dịch (ACID) + 5 – Điều khiển cạnh tranh

---

## I. BÀI TOÁN

Trong thời kỳ cao điểm đăng ký học phần, **hàng nghìn sinh viên** cùng truy cập. Tình huống nguy hiểm nhất:

> Lớp học phần `LHP501` có `SiSoToiDa = 25`, hiện `SiSoHienTai = 24` (**còn đúng 1 chỗ**). Sinh viên A và sinh viên B **cùng lúc** bấm "Đăng ký".

Nếu hệ thống không kiểm soát cạnh tranh, cả hai cùng đọc `SiSoHienTai = 24`, cùng cho phép đăng ký → sĩ số thực tế vượt quá `25` → **dữ liệu hỏng**. Đây chính là **Lost Update** và **phantom anomaly** kinh điển.

---

## II. MỨC CÔ LẬP VÀ CÁC ANOMALY (TÓM TẮT LÝ THUYẾT)

| Isolation Level | Dirty Read | Non-repeatable Read | Phantom Read | Lost Update |
|---|---|---|---|---|
| `READ UNCOMMITTED` | ⚠️ Có | Có | Có | Có |
| `READ COMMITTED` (mặc định) | Không | Có | Có | **Có** |
| `REPEATABLE READ` | Không | Không | Có | Có* |
| `SERIALIZABLE` | Không | Không | Không | Không |
| `SNAPSHOT` | Không | Không | Không | Không (xung đột ghi-ghi vẫn bị chặn) |

*\*REPEATABLE READ giữ Shared Lock tới hết transaction — chống được Lost Update **thuần đọc rồi ghi**, nhưng vẫn để lọt Phantom (chèn dòng mới).*

### Vì sao bài toán đăng ký cần cao hơn `READ COMMITTED`?

`READ COMMITTED` (mức mặc định của SQL Server) chỉ giữ **Shared Lock trong lúc đọc** và thả ngay sau khi câu `SELECT` kết thúc. Do đó:

```
Phiên A: SELECT SiSoHienTai -> 24  (khóa S được thả ngay)
Phiên B: SELECT SiSoHienTai -> 24  (khóa S được thả ngay)
Phiên A: INSERT ... + UPDATE SiSoHienTai = 25
Phiên B: INSERT ... + UPDATE SiSoHienTai = 25   <-- GHI ĐÈ (Lost Update)
Kết quả: 26 SV trong khi SiSoToiDa = 25  ❌
```

→ **READ COMMITTED KHÔNG ĐỦ** vì không có cơ chế nào chặn 2 phiên cùng "kiểm tra sĩ số rồi ghi".

---

## III. GIẢI PHÁP ĐƯỢC CHỌN: TRANSACTION + `UPDLOCK, HOLDLOCK`

Thay vì nâng toàn cục lên `SERIALIZABLE` (tốn kém, dễ deadlock vì khóa phạm vi lớn), ta dùng **khóa cập nhật (Update Lock)** kết hợp **giữ khóa tới hết giao dịch** ngay trên dòng `LOPHOCPHAN`:

```sql
BEGIN TRANSACTION;

-- Khóa dòng LOPHOCPHAN bằng Update Lock, GIỮ TỚI HẾT GIAO DỊCH
SELECT SiSoHienTai, SiSoToiDa
FROM LOPHOCPHAN WITH (UPDLOCK, HOLDLOCK)
WHERE MaLHP = @MaLHP;

IF SiSoHienTai < SiSoToiDa
BEGIN
    INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, ...) VALUES (@MaSV, @MaLHP, ...);
    -- Trigger AFTER INSERT (Issue #61) tự +1 SiSoHienTai
END
ELSE
    RAISERROR('Lớp đã đầy', ...);

COMMIT TRANSACTION;
```

### Cơ chế hoạt động

| Đặc điểm | Giải thích |
|---|---|
| **UPDLOCK** | Khóa Update (X trung gian). Chỉ **1 phiên** có thể giữ UPDLOCK trên 1 dòng tại 1 thời điểm. Phiên khác đọc được nhưng **không** cấp UPDLOCK/X được → chờ. |
| **HOLDLOCK** (SERIALIZABLE range) | Giữ khóa **tới khi COMMIT/ROLLBACK**, không thả sớm. Chặn phiên khác chèn vào phạm vi này (chống Phantom). |
| **`READ COMMITTED` có chấp nhận được không?** | Không. Nó thả khóa S ngay sau SELECT nên 2 phiên cùng đọc 24. |
| **`SERIALIZABLE` toàn cục có dùng không?** | Không. Quá rộng, khóa toàn bảng/range dễ gây deadlock và giảm thông lượng. Chỉ áp dụng khóa đúng dòng nghiệp vụ. |
| **`REPEATABLE READ` có đủ không?** | Một mình cũng **chưa đủ** cho bài toán đăng ký vì 2 phiên cùng cấp S-lock được; phải kết hợp UPDLOCK (hoặc dùng UPDATE có điều kiện nguyên tử). |

---

## IV. PHƯƠNG ÁN THAY THẾ: UPDATE CÓ ĐIỀU KIỆN NGUYÊN TỬ

Một cách khác đạt cùng mục đích mà không cần SELECT khóa dòng — câu `UPDATE` có `WHERE` tự thân **nguyên tử**:

```sql
UPDATE LOPHOCPHAN
SET SiSoHienTai = SiSoHienTai + 1
WHERE MaLHP = @MaLHP AND SiSoHienTai < SiSoToiDa;

IF @@ROWCOUNT = 0
    RAISERROR('Lớp đã đầy', ...);
ELSE
    INSERT INTO DANGKYHOCPHAN (...) VALUES (@MaSV, @MaLHP, ...);
```

* SQL Server cấp **X-lock** khi UPDATE → 2 phiên không thể cùng tăng sĩ số.
* Nếu `@@ROWCOUNT = 0`, phiên thua cuộc biết ngay **hết chỗ**.
* Tuy nhiên cần đảm bảo **INSERT nằm cùng transaction** với UPDATE để rollback đồng bộ nếu INSERT lỗi.

> Trong đồ án, SP_DangKyHocPhan (Issue #50) dùng **phương án UPDLOCK + HOLDLOCK** vì cần kiểm tra nhiều bước trước khi ghi — dễ đọc và phù hợp minh họa lý thuyết.

---

## V. SO SÁNH CÁC MỨC CÔ LẬP — KHUYẾN NGHỊ

| Tiêu chí | `READ COMMITTED` | `REPEATABLE READ` | `SERIALIZABLE` | **`UPDLOCK`+`HOLDLOCK` (được chọn)** |
|---|---|---|---|---|
| Chống Lost Update | ❌ | ⚠️ (vẫn lọt phantom) | ✅ | ✅ |
| Chống đăng ký quá sĩ số | ❌ | ❌ | ✅ | ✅ |
| Độ "khóa" rộng | Thấp | Trung bình | **Cao (toàn bảng/range)** | **Chỉ 1 dòng** |
| Nguy cơ deadlock | Thấp | Trung bình | Cao | Trung bình (kiểm soát được bằng thứ tự khóa) |
| Hiệu năng đăng ký | Tốt | Trung bình | Kém | **Tốt (khóa tối thiểu)** |
| Phù hợp bài toán | ❌ | ⚠️ | ⚠️ | ✅ **TỐI ƯU** |

---

## VI. KẾT LUẬN

1. **READ COMMITTED không đủ** cho bài toán đăng ký học phần vì không ngăn Lost Update khi 2 phiên tranh chỗ cuối.
2. **Giải pháp chọn:** Transaction + `UPDLOCK, HOLDLOCK` trên dòng `LOPHOCPHAN` — đúng tinh thần **Chốt Độc quyền (Exclusive Lock / Pessimistic Locking)** của Chương 5, chỉ khóa **1 dòng cần thiết**, giữ tới commit.
3. **Phương án bổ sung:** `UPDATE ... WHERE SiSoHienTai < SiSoToiDa` với kiểm tra `@@ROWCOUNT` — bản chất cũng là X-lock nguyên tử.
4. Việc chọn mức cô lập được thể hiện cụ thể trong:
   * `SP_DangKyHocPhan` (Issue #50)
   * Kịch bản test 2 session `concurrency_test.sql` (Issue #74)
   * Phân tích Deadlock `deadlock_analysis.md`
