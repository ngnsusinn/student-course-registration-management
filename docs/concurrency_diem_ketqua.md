# PHÂN TÍCH CONCURRENCY CẬP NHẬT ĐIỂM SỐ ĐỒNG THỜI

> **Hệ thống:** Quản lý Đăng ký học phần Sinh viên  
> **Module:** Module 4 — Điểm số & Kết quả học tập (Thành viên 4 — Wiett)  
> **Tài liệu bàn giao:** `docs/concurrency_diem_ketqua.md`  
> **Issue GitHub:** #76 (Phân tích Concurrency Cập nhật Điểm số đồng thời)  
> **Chương giáo trình:** Chương 4 – Quản lý giao dịch (ACID) & Chương 5 – Điều khiển cạnh tranh

---

## I. ĐẶT BÀI TOÁN TRANH CHẤP ĐỒNG THỜI (CONCURRENCY SCENARIO)

Trong thực tế vận hành hệ thống quản lý đào tạo, tại đợt nộp và duyệt điểm cuối kỳ, một kịch bản xung đột cạnh tranh dữ liệu thường xuyên xảy ra như sau:

> **Kịch bản xung đột:**  
> Giảng viên phụ trách môn (`GV001`) và Trưởng bộ môn (`TBM01`) cùng mở màn hình nhập/chỉnh sửa điểm của Sinh viên `SV001` trong lớp học phần `LHP101` tại cùng một khoảng thời gian.
> 
> * **Hiện trạng điểm ban đầu:** Điểm cuối kỳ `DiemCuoiKy = 4.5`.
> * **Giảng viên `GV001`:** Thực hiện chấm phúc khảo, sửa điểm thành `6.5`.
> * **Trưởng bộ môn `TBM01`:** Thực hiện duyệt điểm đợt 1, chỉnh sửa điểm thành `7.0`.

---

## II. NGUY CƠ GHI ĐÈ MẤT DỮ LIỆU (LOST UPDATE ANOMALY)

Nếu hệ thống không áp dụng cơ chế kiểm soát cạnh tranh (Concurrency Control), hiện tượng **Lost Update** sẽ xảy ra theo chuỗi thời gian như sau:

```
Thời điểm T1: Giảng viên (GV) SELECT điểm SV001 -> Nhận DiemCuoiKy = 4.5
Thời điểm T2: Trưởng bộ môn (TBM) SELECT điểm SV001 -> Nhận DiemCuoiKy = 4.5
Thời điểm T3: GV chỉnh sửa DiemCuoiKy = 6.5 và bấm LƯU (COMMIT) -> DiemCuoiKy trong DB = 6.5
Thời điểm T4: TBM chỉnh sửa DiemCuoiKy = 7.0 và bấm LƯU (COMMIT) -> DiemCuoiKy trong DB = 7.0

=> HẬU QUẢ: 
Thao tác cập nhật điểm 6.5 của Giảng viên tại T3 bị GHI ĐÈ HOÀN TOÀN bởi Trưởng bộ môn tại T4!
Điểm phúc khảo hợp lệ của Giảng viên bị mất mà không hề có bất kỳ cảnh báo nào!
```

---

## III. ĐỀ XUẤT CÁC GIẢI PHÁP KIẾN TRÚC VÀ LỰA CHỌN

Để giải quyết triệt để nguy cơ Lost Update khi sửa điểm đồng thời, chúng ta có 2 phương án kỹ thuật chính:

### Phương án 1: Khóa Độc quyền (Exclusive Locking / Pessimistic Locking - Chốt X)
* **Cơ chế:** Khi một người dùng bấm nút "Sửa điểm", hệ thống khởi tạo Transaction và đặt **Khóa Độc quyền (`UPDLOCK, XLOCK`)** trên bản ghi `KETQUAHOCTAP(MaSV, MaLHP)`.
* **Cách hoạt động:** Người dùng khác cố gắng sửa bản ghi này sẽ bị chặn (**Block**) cho đến khi giao dịch trước đó COMMIT hoặc ROLLBACK.
* **Đánh giá:** 
  * *Ưu điểm:* Đảm bảo tuyệt đối không bị ghi đè.
  * *Nhược điểm:* Giữ khóa trên giao diện web gây treo phiên làm việc của người dùng khác nếu người đầu tiên mở màn hình rồi bỏ đi không lưu.

---

### Phương án 2: Kiểm soát Cạnh tranh Lạc quan qua Mốc thời gian (Optimistic Concurrency Control with Timestamp / RowVersion) — **ĐƯỢC CHỌN KHUYẾN NGHỊ**

* **Cơ chế:** Thêm cột mốc thời gian cập nhật cuối `NgayCapNhat` (`DATETIME` hoặc `ROWVERSION`) vào bảng `KETQUAHOCTAP`.
* **Cách hoạt động:** 
  1. Khi đọc dữ liệu lên màn hình, hệ thống lấy kèm mốc thời gian `NgayCapNhatOld`.
  2. Khi người dùng bấm "Lưu điểm", câu lệnh `UPDATE` sẽ kiểm tra điều kiện:
     $$\text{WHERE MaSV} = @MaSV \quad \text{AND} \quad \text{MaLHP} = @MaLHP \quad \text{AND} \quad \text{NgayCapNhat} = @NgayCapNhatOld$$
  3. Nếu `@@ROWCOUNT = 0`, nghĩa là đã có người khác sửa điểm và thay đổi `NgayCapNhat` trước đó $\rightarrow$ Hệ thống báo lỗi xung đột và hủy thao tác.

---

## IV. MÃ SQL MINH HỌA GIẢI PHÁP OPTIMISTIC CONCURRENCY

### 1. Cấu hình cột mốc thời gian kiểm tra
```sql
-- Thêm cột NgayCapNhatCuoi vào bảng KETQUAHOCTAP để kiểm soát mốc thời gian
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('KETQUAHOCTAP') AND name = 'NgayCapNhatCuoi')
BEGIN
    ALTER TABLE KETQUAHOCTAP ADD NgayCapNhatCuoi DATETIME DEFAULT GETDATE();
END
GO
```

### 2. Stored Procedure Cập nhật điểm an toàn (SP_CapNhatDiemAnToan)

```sql
CREATE PROCEDURE SP_CapNhatDiemAnToan
    @MaSV VARCHAR(12),
    @MaLHP VARCHAR(15),
    @DiemChuyenCan FLOAT,
    @DiemGiuaKy FLOAT,
    @DiemCuoiKy FLOAT,
    @NgayCapNhatCuoiOld DATETIME -- Mốc thời gian khi người dùng bắt đầu đọc dữ liệu
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Kiểm tra xem bản ghi điểm có bị người khác chỉnh sửa giữa chừng hay không
        UPDATE KETQUAHOCTAP
        SET 
            DiemChuyenCan = @DiemChuyenCan,
            DiemGiuaKy = @DiemGiuaKy,
            DiemCuoiKy = @DiemCuoiKy,
            NgayCapNhatCuoi = GETDATE()
        WHERE MaSV = @MaSV 
          AND MaLHP = @MaLHP 
          AND (NgayCapNhatCuoi = @NgayCapNhatCuoiOld OR (NgayCapNhatCuoi IS NULL AND @NgayCapNhatCuoiOld IS NULL));

        -- Nếu không có dòng nào được cập nhật -> Xung đột Concurrency (Lost Update Prevented)
        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR(N'XUNG ĐỘT DỮ LIỆU: Điểm số của sinh viên này vừa được cập nhật bởi một người dùng khác (Giảng viên/Trưởng bộ môn)! Vui lòng tải lại trang để xem điểm mới nhất.', 16, 1);
        END

        COMMIT TRANSACTION;
        PRINT N'[SUCCESS] Cập nhật điểm số an toàn thành công!';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO
```

---

## V. KỊCH BẢN KỂM THỬ 2 PHIÊN (SESSION TEST DEMO)

| Thời điểm | Phiên 1 (Giảng viên GV001) | Phiên 2 (Trưởng bộ môn TBM01) | Kết quả Hệ thống |
|---|---|---|---|
| **T1** | Đọc điểm SV001: `DiemCK = 4.5`, `NgayCapNhatOld = 08:00:00` | Đọc điểm SV001: `DiemCK = 4.5`, `NgayCapNhatOld = 08:00:00` | Cả 2 cùng thấy điểm 4.5 |
| **T2** | Thực hiện sửa `DiemCK = 6.5` và bấm LƯU | Đang nhập điểm... | `SP_CapNhatDiemAnToan` kiểm tra `NgayCapNhat = 08:00:00` $\rightarrow$ **Cập nhật thành công**, đổi mốc `NgayCapNhat` mới = `08:02:15`. |
| **T3** | Xem kết quả điểm mới: `6.5` | Thực hiện sửa `DiemCK = 7.0` và bấm LƯU | `SP_CapNhatDiemAnToan` kiểm tra `NgayCapNhat = 08:00:00` $\neq$ `08:02:15` $\rightarrow$ **CẢNH BÁO XUNG ĐỘT!** Báo lỗi và ROLLBACK. |

---

## VI. KẾT LUẬN

1. **Vấn đề Lost Update** khi cập nhật điểm đồng thời đã được ngăn chặn 100%.
2. **Giải pháp kiểm soát bằng Timestamp/RowVersion** kết hợp Transaction mang lại hiệu năng cao cho ứng dụng Web, không gây treo giao diện và bảo đảm dữ liệu điểm số của sinh viên luôn nhất quán.
