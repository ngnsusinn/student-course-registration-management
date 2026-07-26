### I. LƯỢC ĐỒ QUAN HỆ (RELATIONAL SCHEMA)
*(Quy ước: Khóa chính được đánh dấu **[PK]**, Khóa ngoại đánh dấu **[FK]*)*

* **KHOA** (MaKhoa **[PK]**, TenKhoa, DienThoaiKhoa, EmailKhoa)
* **NGANH** (MaNganh **[PK]**, TenNganh, ThoiGianDaoTao, MaKhoa **[FK]**)
* **LOP** (MaLop **[PK]**, TenLop, NienKhoa, MaNganh **[FK]**)
* **SINH_VIEN** (MaSV **[PK]**, HoTen, NgaySinh, GioiTinh, Email, SoDienThoai, QueQuan, TrangThaiHoc, MaLop **[FK]**)
* **CHUONGTRINHDAOTAO** (MaCTDT **[PK]**, TenCTDT, NamApDung, TongSoTinChi, MaNganh **[FK]**)



### II. TỪ ĐIỂN DỮ LIỆU 
Đặc tả chi tiết về kiểu dữ liệu (Đề xuất áp dụng cho hệ quản trị SQL Server / MySQL):

**1. Bảng KHOA**
| Tên Cột | Kiểu dữ liệu | Ràng buộc / Khóa |
| :--- | :--- | :--- |
| MaKhoa | VARCHAR(10) | **PRIMARY KEY** |
| TenKhoa | NVARCHAR(100) | UNIQUE, NOT NULL |
| DienThoaiKhoa | VARCHAR(15) | |
| EmailKhoa | VARCHAR(100) | UNIQUE, NOT NULL |

**2. Bảng NGANH**
| Tên Cột | Kiểu dữ liệu | Ràng buộc / Khóa |
| :--- | :--- | :--- |
| MaNganh | VARCHAR(10) | **PRIMARY KEY** |
| TenNganh | NVARCHAR(100) | UNIQUE, NOT NULL |
| ThoiGianDaoTao | DECIMAL(3,1) | Số năm (VD: 4.0) |
| MaKhoa | VARCHAR(10) | **FOREIGN KEY** REFERENCES KHOA(MaKhoa) |

**3. Bảng LOP**
| Tên Cột | Kiểu dữ liệu | Ràng buộc / Khóa |
| :--- | :--- | :--- |
| MaLop | VARCHAR(15) | **PRIMARY KEY** |
| TenLop | NVARCHAR(100) | NOT NULL |
| NienKhoa | INT | Khóa nhập học (VD: 2023) |
| MaNganh | VARCHAR(10) | **FOREIGN KEY** REFERENCES NGANH(MaNganh) |

**4. Bảng CHUONGTRINHDAOTAO**
| Tên Cột | Kiểu dữ liệu | Ràng buộc / Khóa |
| :--- | :--- | :--- |
| MaCTDT | VARCHAR(10) | **PRIMARY KEY** |
| TenCTDT | NVARCHAR(100) | NOT NULL |
| NamApDung | INT | NOT NULL |
| TongSoTinChi | INT | NOT NULL |
| MaNganh | VARCHAR(10) | **FOREIGN KEY** REFERENCES NGANH(MaNganh) |

**5. Bảng SINH_VIEN**
| Tên Cột | Kiểu dữ liệu | Ràng buộc / Khóa |
| :--- | :--- | :--- |
| MaSV | VARCHAR(12) | **PRIMARY KEY** |
| HoTen | NVARCHAR(100) | NOT NULL |
| NgaySinh | DATE | NOT NULL |
| GioiTinh | TINYINT | 1: Nam, 0: Nữ |
| TrangThaiHoc | TINYINT | 1: Đang học, 2: Bảo lưu, 3: Thôi học |
| Email | VARCHAR(100) | UNIQUE, NOT NULL |
| SoDienThoai | VARCHAR(15) | NOT NULL |
| QueQuan | NVARCHAR(100) | |
| MaLop | VARCHAR(15) | **FOREIGN KEY** REFERENCES LOP(MaLop) |



### III. ĐẶC TẢ RÀNG BUỘC TOÀN VẸN 

#### 1. Ràng buộc toàn vẹn thực thể
Khóa chính của cả 5 bảng (`MaKhoa`, `MaNganh`, `MaLop`, `MaSV`, `MaCTDT`) đều được thiết lập ràng buộc `PRIMARY KEY`. Hệ quản trị CSDL sẽ tự động đảm bảo khóa chính không được để trống (`NOT NULL`) và không được trùng lặp.

#### 2. Ràng buộc toàn vẹn tham chiếu 
Áp dụng ràng buộc `FOREIGN KEY` với cơ chế hành vi khi xóa/sửa dữ liệu như sau:
* **Hành vi `ON DELETE RESTRICT` (Ngăn chặn):** Nếu người quản trị thực hiện lệnh `DELETE FROM KHOA WHERE MaKhoa = 'CNTT'`, hệ thống sẽ kiểm tra. Nếu trong bảng `NGANH` vẫn còn bản ghi tham chiếu đến mã khoa này, giao dịch sẽ bị Hủy (Rollback) để chống mất mát dữ liệu dây chuyền.
* **Quy tắc này áp dụng cho các quan hệ:**
  * KHOA $\rightarrow$ NGANH
  * NGANH $\rightarrow$ CHUONGTRINHDAOTAO
  * NGANH $\rightarrow$ LOP
  * LOP $\rightarrow$ SINH_VIEN

#### 3. Ràng buộc miền giá trị 
* **UNIQUE:** Các cột `TenKhoa`, `TenNganh`, `Email` (trong bảng sinh viên) phải mang giá trị duy nhất.
* **CHECK:**
  * Bảng **SINH_VIEN**: `CHECK (GioiTinh IN (0, 1))` và `CHECK (TrangThaiHoc IN (1, 2, 3))`.
  * Bảng **LOP**: `CHECK (NienKhoa BETWEEN 2000 AND 2030)`.
  * Bảng **NGANH**: `CHECK (ThoiGianDaoTao > 0)`.
  * Bảng **CHUONGTRINHDAOTAO**: `CHECK (NamApDung >= 2000)` và `CHECK (TongSoTinChi > 0)`.
