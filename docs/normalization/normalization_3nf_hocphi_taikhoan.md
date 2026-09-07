# Chuẩn hóa 3NF Học phí, Tài khoản & Vận hành

## Mục tiêu

Chuẩn hóa cơ sở dữ liệu của module Học phí, Tài khoản và Vai trò theo chuẩn Third Normal Form (3NF) nhằm giảm dư thừa dữ liệu, loại bỏ phụ thuộc bắc cầu và đảm bảo tính nhất quán của dữ liệu.

---

## 1. Bảng VAITRO

### Thuộc tính

- MaVaiTro (PK)
- TenVaiTro
- MoTa

### Phụ thuộc hàm

```
MaVaiTro → TenVaiTro, MoTa
```

### Đánh giá

- Khóa chính: MaVaiTro
- Mọi thuộc tính không khóa phụ thuộc hoàn toàn vào khóa chính.
- Không có phụ thuộc bắc cầu.

**⇒ Đạt chuẩn 3NF.**

---

## 2. Bảng TAIKHOAN

### Thuộc tính

- MaTaiKhoan (PK)
- TenDangNhap
- MatKhau
- Email
- TrangThai
- MaVaiTro (FK)
- MaSV (FK)
- MaGV (FK)

### Phụ thuộc hàm

```
MaTaiKhoan →
TenDangNhap,
MatKhau,
Email,
TrangThai,
MaVaiTro,
MaSV,
MaGV
```

### Chuẩn hóa

Ban đầu có thể lưu:

```
TenVaiTro
```

trong bảng TAIKHOAN.

Điều này gây lặp dữ liệu như:

```
Student
Student
Student
Student
Lecturer
Lecturer
AcademicOffice
```

Để loại bỏ dư thừa, thuộc tính **TenVaiTro** được tách sang bảng **VAITRO**.

TAIKHOAN chỉ lưu:

```
MaVaiTro
```

và liên kết bằng khóa ngoại.

### Đánh giá

- Không có phụ thuộc từng phần.
- Không có phụ thuộc bắc cầu.

**⇒ Đạt chuẩn 3NF.**

---

## 3. Bảng HOCPHI

### Thuộc tính

- MaHocPhi (PK)
- MaSV (FK)
- HocKy
- NamHoc
- SoTinChi
- DonGiaTinChi
- TongTien
- TrangThai

### Phụ thuộc hàm

```
MaHocPhi →
MaSV,
HocKy,
NamHoc,
SoTinChi,
DonGiaTinChi,
TongTien,
TrangThai
```

### Đánh giá

- Khóa chính xác định toàn bộ thuộc tính.
- Không tồn tại phụ thuộc từng phần.
- Không tồn tại phụ thuộc bắc cầu.

**⇒ Đạt chuẩn 3NF.**

---

## Kết quả chuẩn hóa

| Bảng | Đạt 3NF | Ghi chú |
|------|----------|----------|
| VAITRO | Có | Không có phụ thuộc bắc cầu |
| TAIKHOAN | Có | Tách VAITRO khỏi TAIKHOAN để tránh lặp dữ liệu |
| HOCPHI | Có | Các thuộc tính phụ thuộc trực tiếp vào khóa chính |

---

## Kết luận

Sau khi chuẩn hóa đến chuẩn 3NF, cơ sở dữ liệu của module Học phí, Tài khoản và Vai trò đã loại bỏ được dữ liệu dư thừa và các phụ thuộc không cần thiết. Việc tách bảng VAITRO khỏi TAIKHOAN giúp hệ thống dễ bảo trì, dễ mở rộng và đảm bảo tính nhất quán khi quản lý quyền của người dùng.