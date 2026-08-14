# CHUẨN HÓA 3NF — BẢNG ĐIỂM SỐ & KẾT QUẢ HỌC TẬP

> **Hệ thống:** Quản lý Đăng ký học phần Sinh viên  
> **Module:** Module 4 — Điểm số & Kết quả học tập (Thành viên 4)  
> **Tài liệu:** `docs/normalization_diem_ketqua.md`  
> **Issue GitHub:** #20 (Chuẩn hóa 3NF Điểm số & Kết quả học tập)

---

## I. BẢNG GỐC (BAN ĐẦU) — DẠNG CHƯA CHUẨN HÓA (UNNORMALIZED)

Giả định ban đầu thiết kế một bảng lưu trữ kết quả học tập đơn giản chứa tất cả thông tin điểm số, sinh viên, môn học và thang quy đổi — gọi là `BANGDIEM_THO`:

| MaSV | HoTenSV | MaLHP | TenLHP | DiemCC | DiemGK | DiemCK | DiemTK | DiemChu | DiemHe4 | XepLoai | NguyCoCanhBao |
|---|---|---|---|---|---|---|---|---|---|---|---|
| SV001 | Nguyễn Văn A | LHP01 | CSDL-01 | 9.0 | 8.0 | 8.5 | 8.4 | B+ | 3.5 | Khá giỏi | Không |
| SV001 | Nguyễn Văn A | LHP02 | OOP-01 | 7.0 | 7.5 | 7.0 | 7.2 | B | 3.0 | Khá | Không |
| SV002 | Trần Thị B | LHP01 | CSDL-01 | 10.0 | 9.0 | 9.0 | 9.1 | A | 4.0 | Xuất sắc | Không |
| SV030 | Lê Văn C | LHP04 | KTVM-01 | 5.0 | 3.0 | 2.0 | 2.9 | F | 0.0 | Kém | Có (Học lại) |

---

## II. PHÁT HIỆN PHỤ THUỘC HÀM (FUNCTIONAL DEPENDENCIES - FDs)

Trong lược đồ thô `BANGDIEM_THO` tồn tại các phụ thuộc hàm sau:

1. `MaSV → HoTenSV`
2. `MaLHP → TenLHP`
3. `(MaSV, MaLHP) → DiemCC, DiemGK, DiemCK, DiemTK, DiemChu, DiemHe4`
4. `DiemTK → DiemChu, DiemHe4, XepLoai` *(Phụ thuộc bắc cầu & Phụ thuộc tra cứu quy đổi)*
5. `DiemChu → DiemHe4, XepLoai`

### Các dị thường (Anomalies) khi chưa chuẩn hóa:
* **Dư thừa dữ liệu (Data Redundancy):** Thông tin sinh viên (`HoTenSV`), tên lớp học phần (`TenLHP`), cũng như quy tắc đổi điểm (`DiemChu → DiemHe4, XepLoai`) bị lặp lại ở mọi bản ghi điểm.
* **Dị thường Cập nhật (Update Anomaly):** Nếu quy chế nhà trường thay đổi ngưỡng quy đổi từ 8.5 $\rightarrow$ 8.4 là điểm A, ta phải chạy `UPDATE` trên từng dòng trong bảng điểm (hàng trăm ngàn bản ghi).
* **Dị thường Xóa (Delete Anomaly):** Xóa bản ghi điểm học tập của sinh viên có thể làm mất thông tin tên sinh viên hoặc thông tin quy đổi điểm chữ nếu không có bảng gốc độc lập.

---

## III. QUÁ TRÌNH CHUẨN HÓA (NORMALIZATION STEPS)

### Bước 1 — Đạt 1NF (First Normal Form)
* Mọi thuộc tính đều là **đơn trị (atomic values)**. Không chứa danh sách điểm hay mảng giá trị.
* Xác định khóa chính thô: `(MaSV, MaLHP)`.

### Bước 2 — Đạt 2NF (Second Normal Form)
Loại bỏ phụ thuộc từng phần vào khóa chính:
* `MaSV → HoTenSV` $\Rightarrow$ Tách sang bảng `SINHVIEN(MaSV, HoTenSV, ...)` (Module 1).
* `MaLHP → TenLHP` $\Rightarrow$ Tách sang bảng `LOPHOCPHAN(MaLHP, TenLHP, ...)` (Module 2).
* Giữ lại nhóm thuộc tính phụ thuộc **đầy đủ** vào khóa ghép `(MaSV, MaLHP)` trong bảng `KETQUAHOCTAP`.

### Bước 3 — Đạt 3NF (Third Normal Form)
Loại bỏ các phụ thuộc bắc cầu:
* Trong `BANGDIEM_THO` có phụ thuộc bắc cầu: `(MaSV, MaLHP) → DiemTK → (DiemChu, DiemHe4, XepLoai)`.
* Nếu lưu cứng `DiemChu`, `DiemHe4`, `XepLoai` trực tiếp và hard-code ngưỡng trong bảng điểm sẽ vi phạm tính độc lập dữ liệu.
* **Giải pháp 3NF:** Tách bảng danh mục tra cứu quy đổi **`THANGDIEMCHU`** riêng biệt với khóa chính `DiemChu`.

---

## IV. BÀI TOÁN KIẾN TRÚC: LƯU TÍNH TOÁN (STORED) VS TÍNH RUNTIME

Trong thiết kế CSDL thực tế cho Module Điểm, có một quyết định thiết kế quan trọng:

> **Câu hỏi:** Nên lưu `DiemTongKet`, `DiemChu`, `DiemHe4` trực tiếp trong bảng `KETQUAHOCTAP` hay tính toán động (runtime) qua VIEW / SELECT query mỗi khi cần?

### Phân tích Đánh đổi (Trade-off Analysis):

| Phương Án | Ưu Điểm | Nhược Điểm | Giải Pháp Tối Ưu Được Chọn |
|---|---|---|---|
| **Phương án A: Tính Runtime hoàn toàn** *(Không lưu DiemTK, DiemChu)* | - Chuẩn hóa triệt để.<br>- Không bao giờ lo sai lệch điểm tổng kết khi sửa điểm thành phần. | - **Hiệu năng kém (Slow query):** Khi báo cáo GPA toàn trường cho 20.000 SV, phải tính toán lại hàng triệu dòng.<br>- Không tạo được Non-clustered Index trên `DiemChu` hoặc `DiemHe4` để lọc danh sách SV học lại / giỏi. | ❌ Không phù hợp cho CSDL lớn. |
| **Phương án B: Lưu trữ sẵn + Dùng Trigger tự động (Cơ chế Denormalization có kiểm soát)** | - **Tốc độ truy vấn cực nhanh (Fast READ):** Xem bảng điểm, GPA, lọc SV bị cảnh báo học vụ diễn ra tức thì (`O(1)`).<br>- Tạo được Index hỗ trợ báo cáo thống kê. | - Phải bảo đảm tính nhất quán khi điểm thành phần thay đổi. | ✅ **ĐƯỢC CHỌN:** Lưu sẵn các cột `DiemTongKet`, `DiemChu`, `DiemHe4` và **dùng `AFTER UPDATE/INSERT` Trigger tự động tính toán lại**. |

---

## V. CẤU TRÚC LƯỢC ĐỒ CHUẨN HÓA 3NF CUỐI CÙNG

Sau khi chuẩn hóa 3NF và áp dụng giải pháp lưu trữ có kiểm soát, Module 4 gồm 2 bảng:

### 1. Bảng `THANGDIEMCHU` (Danh mục tra cứu độc lập)

```sql
THANGDIEMCHU (DiemChu, TuDiemHe10, DenDiemHe10, DiemHe4, XepLoai)
  └── PK: DiemChu
```

* **Kiểm tra 3NF:**
  * 1NF: Mọi thuộc tính đơn trị.
  * 2NF: Khóa đơn `DiemChu`, không có phụ thuộc một phần.
  * 3NF: Mọi thuộc tính không khóa (`TuDiemHe10`, `DenDiemHe10`, `DiemHe4`, `XepLoai`) chỉ phụ thuộc trực tiếp vào `DiemChu`. ✅

### 2. Bảng `KETQUAHOCTAP` (Lưu kết quả học tập)

```sql
KETQUAHOCTAP (MaSV, MaLHP, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy, DiemTongKet, DiemHe4, DiemChu)
  ├── Composite PK: (MaSV, MaLHP)
  ├── Composite FK: (MaSV, MaLHP) REFERENCES DANGKYHOCPHAN(MaSV, MaLHP)
  └── FK: DiemChu REFERENCES THANGDIEMCHU(DiemChu)
```

* **Kiểm tra 3NF:**
  * 1NF: Đạt.
  * 2NF: Khóa chính ghép `(MaSV, MaLHP)`. Các điểm thành phần `DiemChuyenCan`, `DiemGiuaKy`, `DiemCuoiKy` phụ thuộc đầy đủ vào toàn bộ khóa ghép (điểm của 1 SV trong 1 LHP cụ thể).
  * 3NF: Thuộc tính quy đổi `DiemChu` được liên kết bằng Khóa ngoại (FK) tới bảng danh mục `THANGDIEMCHU`, đảm bảo không vi phạm phụ thuộc bắc cầu trong dữ liệu tĩnh. ✅

---

## VI. KẾT LUẬN & ĐÁNH GIÁ TÍNH CHUẨN HÓA

* Bảng `KETQUAHOCTAP` và `THANGDIEMCHU` đạt chuẩn **3NF**.
* Bảo đảm tính toàn vẹn dữ liệu thông qua ràng buộc **Composite FK** tham chiếu tới `DANGKYHOCPHAN(MaSV, MaLHP)` (Module 3).
* Kết hợp cơ chế **Trigger tự động** (thực hiện ở Tuần 4 - Issue #50) để tự động cập nhật `DiemTongKet` và quy đổi `DiemChu`/`DiemHe4` ngay khi giảng viên nhập hoặc chỉnh sửa điểm thành phần.
