# Thiết kế ERD Học phần, Giảng viên & Mở lớp học phần
## 1. Mục tiêu
Thiết kế ERD (Entity Relationship Diagram) cho module Học phần, Giảng viên và Mở lớp học phần nhằm mô tả cấu trúc dữ liệu, các thực thể và mối quan hệ giữa chúng trong hệ thống quản lý đăng ký tín chỉ. Việc thiết kế ERD giúp xây dựng cơ sở dữ liệu thống nhất, hạn chế dư thừa dữ liệu, đảm bảo tính toàn vẹn và hỗ trợ hiệu quả cho các nghiệp vụ quản lý học phần, phân công giảng viên và mở lớp học phần.

## 2. Phân tích các thực thể
### 2.1 Thực thể CHUONGTRINHDAOTAO
Ý nghĩa
Thực thể CHUONGTRINHDAOTAO lưu thông tin về chương trình đào tạo của từng ngành. Mỗi chương trình đào tạo bao gồm danh sách các học phần mà sinh viên phải hoàn thành trong suốt quá trình học.

Thuộc tính |	Kiểu dữ liệu    |	Ràng buộc |	Ý nghĩa
MaCTDT     | 	varchar(10)	PK, |   NOT NULL  | Mã chương trình đào tạo
MaNganh    | 	varchar(10)	FK, |  NOT NULL	  | Mã ngành
NamApDung  | 	int	            |  NOT NULL	  |Năm áp dụng
MoTa       | 	nvarchar(255)   |  NULL	      |Mô tả chương trình

### 2.2 Thực thể HOCPHAN
Ý nghĩa
Thực thể HOCPHAN lưu danh mục các học phần được giảng dạy trong từng chương trình đào tạo. Đây là thực thể trung tâm của module vì tất cả các lớp học phần đều được mở dựa trên học phần.

Thuộc tính | 	Kiểu dữ liệu  | Ràng buộc    | 	Ý nghĩa
MaHP       | 	varchar(10)   | PK, NOT NULL | 	Mã học phần
TenHP      | 	nvarchar(100) | NOT NULL     | 	Tên học phần
SoTinChi   | 	tinyint       | CHECK (>0)   | 	Số tín chỉ
LyThuyet   | 	tinyint       | NOT NULL     | 	Số tiết lý thuyết
ThucHanh   | 	tinyint       | NOT NULL     | 	Số tiết thực hành
MaCTDT     | 	varchar(10)   |  FK	         |  Chương trình đào tạo

### 2.3 Thực thể HOCPHAN_TIENQUYET
Ý nghĩa
Thực thể HOCPHAN_TIENQUYET quản lý mối quan hệ tiên quyết giữa các học phần. Một học phần có thể yêu cầu nhiều học phần tiên quyết và ngược lại.

Thuộc tính         |	Kiểu dữ liệu |	Ràng buộc |	Ý nghĩa
MaHP               |	varchar(10)  |	PK, FK    |Học phần
MaHocPhanTienQuyet |	varchar(10)  |  PK, FK    |Học phần tiên quyết

### 2.4 Thực thể GIANGVIEN
Ý nghĩa
Thực thể GIANGVIEN lưu trữ thông tin giảng viên phục vụ cho việc phân công giảng dạy các lớp học phần.

Thuộc tính  |	Kiểu dữ liệu |	Ràng buộc    |	Ý nghĩa
MaGV        |	varchar(10)  |  PK, NOT NULL |  Mã giảng viên
HoTen       |	nvarchar(100)|	NOT NULL     |  Họ tên
NgaySinh    |	date         |	NULL	     |  Ngày sinh
GioiTinh    |	bit	         |  NULL	     |  Giới tính
Email       |	varchar(100) |	UNIQUE	     |  Email
SoDienThoai |	varchar(15)  |	NULL	     |  Số điện thoại
MaKhoa      |	nvarchar(100)|	NOT NULL     |  Khoa quản lý
ChucVu      |	nvarchar(50) |	NULL	     |  Chức vụ
TrangThai   |	nvarchar(30)	DEFAULT      |  Trạng thái làm việc

### 2.5 Thực thể HOCKY
Ý nghĩa
Thực thể HOCKY lưu thông tin các học kỳ được sử dụng để tổ chức mở lớp học phần theo từng năm học.

Thuộc tính |	Kiểu dữ liệu |	Ràng buộc  |	Ý nghĩa
MaHocKy    |	varchar(10)	 |  PK	       | Mã học kỳ
TenHocKy   |	nvarchar(30) |  NOT NULL   | Tên học kỳ
NamHoc     |	varchar(9)	 |  NOT NULL   | Năm học
NgayBatDau |	date	     |  NOT NULL   | Ngày bắt đầu
NgayKetThuc|	date	     |  NOT NULL   | Ngày kết thúc

### 2.6 Thực thể LOPHOCPHAN
Ý nghĩa
Thực thể LOPHOCPHAN lưu thông tin các lớp học phần được mở trong từng học kỳ. Mỗi lớp học phần gắn với một học phần, một giảng viên và một học kỳ cụ thể.

Thuộc tính | 	Kiểu dữ liệu |	Ràng buộc |	Ý nghĩa
MaLHP	   |varchar(10)      |	PK	      |Mã lớp học phần
MaHP	   |varchar(10)      |	FK	      |Học phần
MaGV	   |varchar(10)	     |  FK	      |Giảng viên
MaHocKy	   |varchar(10)	     |  FK	      |Học kỳ
PhongHoc   |nvarchar(30)	 |  NOT NULL  |Phòng học
LichHoc	   |nvarchar(100)	 |  NOT NULL  |Lịch học
SiSoToiDa  |tinyint	         |  CHECK (>0)|Sĩ số tối đa
TrangThai  |nvarchar(30)	 |  DEFAULT	  |Trạng thái lớp học phần

## 3. Phân tích mối quan hệ giữa các thực thể
Quan hệ	Kiểu quan hệ	Giải thích
CHUONGTRINHDAOTAO – HOCPHAN	1 – N	Một chương trình đào tạo bao gồm nhiều học phần, mỗi học phần chỉ thuộc một chương trình đào tạo.
HOCPHAN – LOPHOCPHAN	1 – N	Một học phần có thể được mở thành nhiều lớp học phần ở các học kỳ khác nhau, nhưng mỗi lớp học phần chỉ thuộc một học phần.
GIANGVIEN – LOPHOCPHAN	1 – N	Một giảng viên có thể giảng dạy nhiều lớp học phần, nhưng mỗi lớp học phần chỉ do một giảng viên phụ trách.
HOCKY – LOPHOCPHAN	1 – N	Một học kỳ có thể mở nhiều lớp học phần, nhưng mỗi lớp học phần chỉ thuộc một học kỳ.
HOCPHAN – HOCPHAN_TIENQUYET	N – N	Một học phần có thể có nhiều học phần tiên quyết và đồng thời cũng có thể là học phần tiên quyết của nhiều học phần khác. Quan hệ này được cài đặt thông qua bảng trung gian HOCPHAN_TIENQUYET.

### 3.1 Ràng buộc toàn vẹn
####  3.1.1 Ràng buộc thực thể
•	Mỗi bảng phải có khóa chính (Primary Key) duy nhất. 
•	Khóa chính không được để trống (NOT NULL). 
#### 3.1.2 Ràng buộc tham chiếu
•	MaCTDT trong bảng HOCPHAN phải tồn tại trong bảng CHUONGTRINHDAOTAO. 
•	MaHP, MaGV và MaHocKy trong bảng LOPHOCPHAN phải tồn tại trong các bảng tương ứng. 
•	MaHP và MaHocPhanTienQuyet trong bảng HOCPHAN_TIENQUYET phải tham chiếu đến bảng HOCPHAN. 
3.1.3 Ràng buộc miền giá trị
•	Số tín chỉ phải lớn hơn 0. 
•	Số tiết lý thuyết và thực hành không được âm. 
•	Sĩ số tối đa phải lớn hơn 0. 
•	Ngày bắt đầu học kỳ phải nhỏ hơn ngày kết thúc. 
#### 3.1.4 Ràng buộc nghiệp vụ
•	Không được mở lớp học phần khi học phần chưa tồn tại. 
•	Không được phân công một giảng viên giảng dạy hai lớp học phần trùng thời gian. 
•	Không được sử dụng cùng một phòng học cho hai lớp học phần tại cùng một thời điểm. 
•	Không được xóa học phần hoặc giảng viên khi vẫn còn được tham chiếu trong bảng LOPHOCPHAN. 
•	Khi số lượng sinh viên đăng ký đạt sĩ số tối đa, hệ thống sẽ ngừng tiếp nhận đăng ký mới cho lớp học phần
•	Học phần có thể có hoặc không có học phần tiên quyết. Nếu có thì học phần tiên quyết phải tồn tại trong hệ thống.
•	
CHUONGTRINHDAOTAO
        │1
        │
        │N
    HOCPHAN
        │
        ├───────────────┐
        │               │
        │               │
        ▼               ▼
HOCPHAN_TIENQUYET   LOPHOCPHAN
                        ▲
            ┌───────────┴───────────┐
            │                      	│
            │                       │
       GIANGVIEN              	   HOCKY.




```mermaid
erDiagram
    Khoa {
        varchar MaKhoa PK
        nvarchar TenKhoa
    }

    Nganh {
        varchar MaNganh PK
        nvarchar TenNganh
        varchar MaKhoa FK
    }

    ChuongTrinhDaoTao {
        varchar MaCTDT PK
        varchar MaNganh FK
        int NamApDung
        nvarchar MoTa
    }

    HocPhan {
        varchar MaHP PK
        nvarchar TenHP
        tinyint SoTinChi
        tinyint SoTietLyThuyet
        tinyint SoTietThucHanh
        varchar MaCTDT FK
    }

    HocPhan_TienQuyet {
        varchar MaHP PK, FK
        varchar MaHocPhanTienQuyet PK, FK
    }

    GiangVien {
        varchar MaGV PK
        nvarchar HoTen
        date NgaySinh
        bit GioiTinh
        varchar Email
        varchar SoDienThoai
        varchar MaKhoa FK
        nvarchar ChucVu
        nvarchar TrangThai
    }

    HocKy {
        varchar MaHocKy PK
        nvarchar TenHocKy
        varchar NamHoc
        date NgayBatDau
        date NgayKetThuc
    }

    LopHocPhan {
        varchar MaLHP PK
        varchar MaHP FK
        varchar MaGV FK
        varchar MaHocKy FK
        nvarchar PhongHoc
        nvarchar LichHoc
        tinyint SiSoToiDa
        nvarchar TrangThai
    }

    %% Quan hệ giữa các bảng (Relationships)
    Khoa ||--o{ Nganh : "có"
    Khoa ||--o{ GiangVien : "thuộc"
    Nganh ||--o{ ChuongTrinhDaoTao : "có"
    ChuongTrinhDaoTao ||--o{ HocPhan : "chứa"
    HocPhan ||--o{ HocPhan_TienQuyet : "yêu cầu"
    HocPhan ||--o{ LopHocPhan : "mở"
    GiangVien ||--o{ LopHocPhan : "phân công"
    HocKy ||--o{ LopHocPhan : "thuộc"
```
