# KIỂM THỬ TÍCH HỢP TRIGGER TOÀN HỆ THỐNG

> **Hệ thống:** Quản lý Đăng ký học phần Sinh viên  
> **Module:** Đăng ký học phần (TV3 — Leader)  
> **Issue:** #49 Review Trigger toàn bộ các module hệ thống  
> **Tài liệu:** `docs/trigger_integration_test.md`

---

## I. MỤC ĐÍCH

Khi module Đăng ký (TV3) thao tác trên bảng `DANGKYHOCPHAN`, trigger của TV3 sẽ **tự động cập nhật `LOPHOCPHAN.SiSoHienTai`**. Cần kiểm tra trigger này **không xung đột** với trigger của các module khác (TV2 — chặn trùng lịch LICHHOC, TV4 — tự tính điểm, TV5 — ghi log). Tài liệu này ghi lại **kịch bản test tích hợp trigger chain**.

---

## II. DANH SÁCH TRIGGER LIÊN QUAN

| # | Trigger | Bảng | Sự kiện | Tác động |
|---|---|---|---|---|
| 1 | `TRG_DANGKYHOCPHAN_AFTER_INSERT` (TV3) | DANGKYHOCPHAN | INSERT | `LOPHOCPHAN.SiSoHienTai +1` |
| 2 | `TRG_DANGKYHOCPHAN_AFTER_DELETE` (TV3) | DANGKYHOCPHAN | DELETE | `LOPHOCPHAN.SiSoHienTai -1` |
| 3 | `TRG_DANGKYHOCPHAN_AFTER_UPDATE` (TV3) | DANGKYHOCPHAN | UPDATE | Cộng/trừ theo chuyển trạng thái |
| 4 | Trigger chặn trùng lịch (TV2) | LICHHOC | INSERT/UPDATE | Chặn trùng phòng/GV |
| 5 | Trigger tự tính điểm (TV4) | KETQUAHOCTAP | INSERT/UPDATE | Tính DiemTongKet/DiemChu |
| 6 | Trigger ghi log đổi MK (TV5) | TAIKHOAN | UPDATE | Ghi log |

---

## III. KỊCH BẢN TEST TRIGGER CHAIN (TV3)

### Kịch bản 1: INSERT đăng ký → Sĩ số tăng

```sql
-- Xem sĩ số trước
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = N'LHP502';

-- Đăng ký (thành công)
EXEC SP_DangKyHocPhan @MaSV = N'SV001', @MaLHP = N'LHP502', @KetQua = ...;

-- Xem sĩ số sau → phải TĂNG 1
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = N'LHP502';
```

**Kỳ vọng:** `SiSoHienTai` tăng đúng 1; không trigger TV2 nào bị kích hoạt (không chạm LICHHOC).

### Kịch bản 2: Hủy đăng ký → Sĩ số giảm

```sql
EXEC SP_HuyDangKy @MaSV = N'SV001', @MaLHP = N'LHP502', @KetQua = ...;
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = N'LHP502';
```

**Kỳ vọng:** `SiSoHienTai` giảm đúng 1 (trigger AFTER UPDATE xử lý `DA_DANG_KY → DA_HUY`).

### Kịch bản 3: Chuyển trạng thái mở lại

```sql
UPDATE DANGKYHOCPHAN SET TrangThaiDangKy = N'DA_DANG_KY'
WHERE MaSV = N'SV001' AND MaLHP = N'LHP502';
SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = N'LHP502';
```

**Kỳ vọng:** `SiSoHienTai` tăng lại 1 (trigger AFTER UPDATE xử lý `DA_HUY → DA_DANG_KY`).

### Kịch bản 4: Kiểm tra không xung đột với trigger TV2

* Trigger TV3 chỉ chạm bảng `LOPHOCPHAN`; trigger TV2 chỉ chạm `LICHHOC` → **không kích hoạt chéo**.
* Xác nhận bằng:
```sql
-- Bật theo dõi sự kiện trigger
DBCC TRACEON(3604);
-- Sau đó chạy INSERT đăng ký và quan sát message từ trigger
```

### Kịch bản 5: Đăng ký trùng bị PK chặn (không kích trigger)

```sql
-- INSERT trùng PK -> lỗi 2627, trigger KHÔNG chạy
INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP) VALUES (N'SV001', N'LHP502');
```

**Kỳ vọng:** Lỗi violation, sĩ số KHÔNG đổi (trigger không chạy khi INSERT thất bại).

---

## IV. BẢNG KẾT QUẢ KIỂM THỬ (điền sau khi chạy thực tế)

| Kịch bản | Hành động | Sĩ số trước | Sĩ số sau | Kết quả | Ghi chú |
|---|---|---|---|---|---|
| 1 | INSERT ĐK | | | ✅/❌ | |
| 2 | Hủy ĐK | | | ✅/❌ | |
| 3 | Mở lại ĐK | | | ✅/❌ | |
| 4 | Xung đột TV2 | | | ✅/❌ | |
| 5 | INSERT trùng PK | | | ✅/❌ | |

---

## V. KẾT LUẬN

1. Trigger TV3 tự duy trì `SiSoHienTai` **không cần lập trình thủ công** — đúng yêu cầu Issue #61.
2. Không có **trigger chain xung đột**: các trigger chạm các bảng khác nhau, không kích hoạt lẫn nhau.
3. Trigger chỉ chạy khi **INSERT/UPDATE/DELETE thành công** — trường hợp lỗi (PK, FK, CHECK) không gây thay đổi sĩ số.
4. Kịch bản test này là cơ sở cho kiểm thử tích hợp lần 1 (Issue #73).
