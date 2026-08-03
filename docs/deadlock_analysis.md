# PHÂN TÍCH DEADLOCK TOÀN HỆ THỐNG & CÁCH PHÒNG TRÁNH

> **Hệ thống:** Quản lý Đăng ký học phần Sinh viên  
> **Module:** Đăng ký học phần (TV3 — Leader)  
> **Issue:** #62 Phân tích Deadlock toàn hệ thống  
> **Tài liệu:** `docs/deadlock_analysis.md`  
> **Chương:** 5 – Điều khiển cạnh tranh (Deadlock, 2PL)

---

## I. DEADLOCK LÀ GÌ?

**Deadlock (khóa kẹt / khóa chết)** xảy ra khi 2 (hoặc nhiều) giao dịch **giữ khóa lẫn nhau chờ đợi** một cách vòng tròn, không tiến trình nào hoàn thành.

Điều kiện **4 điều kiện tiên quyết (Coffman conditions):**
1. **Loại trừ lẫn nhau (Mutual Exclusion):** tài nguyên không dùng chung được.
2. **Giữ và chờ (Hold and Wait):** giữ 1 khóa rồi chờ khóa khác.
3. **Không tiếm quyền (No Preemption):** khóa không bị thu hồi cưỡng bức.
4. **Chờ vòng tròn (Circular Wait):** A chờ B, B chờ A.

---

## II. TÌNH HUỐNG DEADLOCK TRONG ĐĂNG KÝ HỌC PHẦN

### Kịch bản 2 phiên đăng ký ngược thứ tự (Dirty Read → Deadlock)

```
Phiên A (SV001): Đăng ký LHP501 rồi LHP502
Phiên B (SV002): Đăng ký LHP502 rồi LHP501

                Phiên A                     Phiên B
                --------                    --------
    T1:    LOCK S (UPDLOCK) LHP501 ✅
    T1':                                 LOCK S (UPDLOCK) LHP502 ✅
    T2:    ĐK LHP501 -> chờ LOCK LHP502  ⏳
    T2':                                 ĐK LHP502 -> chờ LOCK LHP501  ⏳
            => DEADLOCK: A chờ B, B chờ A
```

### Phân tích theo 4 điều kiện

| Điều kiện | Có thỏa? | Diễn giải |
|---|---|---|
| 1. Mutual Exclusion | ✅ | Khóa UPDLOCK/X là độc quyền |
| 2. Hold and Wait | ✅ | A giữ LHP501 chờ LHP502 |
| 3. No Preemption | ✅ | Khóa không tự nhường |
| 4. Circular Wait | ✅ | A→LHP502, B→LHP501 |

**→ Deadlock xảy ra. SQL Server phát hiện trong ~5 giây, chọn 1 phiên làm "nạn nhân" (victim) và ROLLBACK phiên đó (lỗi 1205).**

---

## III. CÁCH PHÒNG TRÁNH DEADLOCK

### 1. KHÓA THEO THỨ TỰ NHẤT QUÁN (Consistent Lock Ordering) ⭐ QUAN TRỌNG NHẤT

**Luật:** Mọi giao dịch phải khóa các LHP theo **cùng một thứ tự** (VD: `MaSV ASC`, `MaLHP ASC`).

```
ĐÚNG (cùng thứ tự MaLHP):
  A: khóa LHP501 -> khóa LHP502
  B: khóa LHP501 -> khóa LHP502   (cùng thứ tự nên không kẹt)

SAI (khác thứ tự -> deadlock):
  A: LHP501 -> LHP502
  B: LHP502 -> LHP501
```

**Áp dụng:** Trong `SP_DangKyHocPhan`, nếu SV đăng ký nhiều LHP cùng lúc, sắp xếp `@DanhSachLHP` theo `MaLHP ASC` trước khi duyệt.

### 2. GIẢM THỜI GIAN GIỮ KHÓA (Hold Locks Short)

* Chỉ khóa dòng thật sự cần thiết (dùng `UPDLOCK` trên **đúng dòng** `LOPHOCPHAN` — không dùng `SERIALIZABLE` toàn bảng).
* Tách các bước không cần khóa (kiểm tra tiên quyết, trùng lịch) ra **ngoài** Transaction; chỉ giữ Transaction cho phần ghi.

### 3. DÙNG MỨC CÔ LẬP PHÙ HỢP

* Không nâng `SERIALIZABLE` toàn cục — khóa range rộng làm tăng xác suất deadlock.
* Xem `docs/isolation_level_analysis.md` (Issue #73) để hiểu vì sao `UPDLOCK+HOLDLOCK` trên 1 dòng là tối ưu.

### 4. BẮT LỖI DEADLOCK (ERROR 1205) TRONG ỨNG DỤNG

```sql
-- Trong SP: bắt lỗi 1205 và chạy lại giao dịch
IF ERROR_NUMBER() = 1205
BEGIN
    PRINT N'Deadlock xảy ra, thử lại...';
    -- (Ở tầng ứng dụng: retry transaction tối đa N lần)
END
```

### 5. ĐẶT TIMEOUT KHÓA (LOCK_TIMEOUT)

```sql
SET LOCK_TIMEOUT 5000;  -- chờ tối đa 5 giây rồi báo lỗi thay vì kẹt mãi
```

---

## IV. CÁCH DEMO & KIỂM TRA

Script `sql/transactions/concurrency_test.sql` (Issue #74) có phần:
* **Test 2 session đăng ký đồng thời** — chứng minh không Lost Update.
* **Deadlock demo tùy chọn** — mở 2 cửa sổ SSMS, chạy 2 batch đăng ký ngược thứ tự LHP501/LHP502, quan sát lỗi `1205` ở 1 phiên và phiên kia thành công sau retry.

**Cách kiểm tra bằng DMV (trong khi xảy ra deadlock):**
```sql
SELECT * FROM sys.dm_tran_locks WHERE resource_type = N'OBJECT' OR resource_type = N'KEY';
SELECT * FROM sys.dm_exec_requests WHERE blocking_session_id > 0;
```

---

## V. KẾT LUẬN

1. Deadlock là **rủi ro thực tế** của bài toán đăng ký khi nhiều SV cùng ghi.
2. **Phòng tránh chủ đạo:** khóa theo **thứ tự nhất quán** + giữ khóa **ngắn** + chỉ khóa **dòng cần thiết**.
3. **Ứng phó:** bắt lỗi `1205` và **thử lại (retry)** giao dịch — đây là pattern chuẩn của các hệ thống giao dịch thực tế.
4. Điều này hoàn thiện bức tranh **Chương 5** cho module Đăng ký học phần (điểm nhấn của cả nhóm).
