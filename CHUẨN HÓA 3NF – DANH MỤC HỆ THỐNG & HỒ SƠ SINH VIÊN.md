CHUẨN HÓA 3NF – DANH MỤC HỆ THỐNG VÀ HỒ SƠ SINH VIÊN 

I. CÁC BẢNG BAN ĐẦU 

Các bảng được kiểm tra gồm: 

KHOA 
NGANH 
LOP 
SINH_VIEN 
CHUONGTRINHDAOTAO 

II. PHÂN TÍCH PHỤ THUỘC HÀM 

1. Bảng KHOA 

Lược đồ 

KHOA(MaKhoa, TenKhoa, DienThoaiKhoa, EmailKhoa) 
 

Phụ thuộc hàm 

MaKhoa → TenKhoa, DienThoaiKhoa, EmailKhoa 
 

Trong đó MaKhoa là khóa chính và xác định duy nhất các thông tin của khoa. 

Kết luận 

Bảng KHOA đạt 3NF. 

 

2. Bảng NGANH 

Lược đồ 

NGANH(MaNganh, TenNganh, ThoiGianDaoTao, MaKhoa) 
 

Phụ thuộc hàm 

MaNganh → TenNganh, ThoiGianDaoTao, MaKhoa 
 

MaNganh xác định duy nhất tên ngành, thời gian đào tạo và khoa quản lý ngành. 

Kết luận 

Bảng NGANH đạt 3NF. 

3. Bảng LOP 

Lược đồ 

LOP(MaLop, TenLop, NienKhoa, MaNganh) 

Phụ thuộc hàm 

MaLop → TenLop, NienKhoa, MaNganh 

MaLop xác định duy nhất tên lớp, niên khóa và ngành của lớp. 

Kết luận 

Bảng LOP đạt 3NF. 

4. Bảng SINH_VIEN 

Lược đồ 

SINH_VIEN( 
   MaSV, 
   HoTen, 
   NgaySinh, 
   GioiTinh, 
   Email, 
   SoDienThoai, 
   QueQuan, 
   TrangThaiHoc, 
   MaLop 
) 
 

Phụ thuộc hàm 

MaSV → HoTen, NgaySinh, GioiTinh, Email, 
      SoDienThoai, QueQuan, TrangThaiHoc, MaLop 
 

MaSV xác định duy nhất toàn bộ thông tin của một sinh viên. 

Kết luận 

Bảng SINH_VIEN đạt 3NF. 

III. PHÂN TÍCH BẢNG CHUONGTRINHDAOTAO 

1. Cấu trúc dữ liệu 

Chương trình đào tạo thể hiện các môn học mà một ngành phải học và môn học đó được bố trí ở học kỳ nào. 

Có thể biểu diễn: 

CHUONGTRINHDAOTAO(MaNganh, MaMH, MaHocKy) 

Trong đó: 

MaNganh: Mã ngành đào tạo. 

MaMH: Mã môn học. 

MaHocKy: Học kỳ dự kiến học môn. 

2. Phụ thuộc hàm 

Khóa của quan hệ là: 

(MaNganh, MaMH) 
 

Phụ thuộc hàm: 

(MaNganh, MaMH) → MaHocKy 
 

Một môn học trong một ngành được xác định học ở một học kỳ nhất định. 

 

IV. KIỂM TRA CHUẨN HÓA 

1. Dạng chuẩn 1NF 

Các bảng đều có thuộc tính mang giá trị nguyên tử, không có nhóm thuộc tính lặp. 

Do đó: 

KHOA 
NGANH 
LOP 
SINH_VIEN 
CHUONGTRINHDAOTAO 

đều đạt 1NF. 

2. Dạng chuẩn 2NF 

Các bảng có khóa đơn 

Các bảng: 

KHOA 
NGANH 
LOP 
SINH_VIEN 

đều sử dụng khóa chính đơn: 

MaKhoa 
MaNganh 
MaLop 

MaSV 

Các thuộc tính không khóa phụ thuộc đầy đủ vào khóa chính. 

→ Không có phụ thuộc bộ phận. 

CHUONGTRINHDAOTAO 

Khóa ghép: 

(MaNganh, MaMH) 

Phụ thuộc: 

(MaNganh, MaMH) → MaHocKy 
 

MaHocKy phụ thuộc vào toàn bộ khóa ghép. 

→ Không có phụ thuộc bộ phận. 

Kết luận 

Các bảng đạt 2NF. 

V. TÁCH CHUONGTRINHDAOTAO THÀNH BẢNG TRUNG GIAN 

Để thể hiện rõ quan hệ giữa Ngành – Môn học – Học kỳ, bảng CHUONGTRINHDAOTAO được tách thành bảng trung gian: 

NGANH_MON_HOC 

Lược đồ 

NGANH_MON_HOC( 
   MaNganh [PK, FK], 
   MaMH [PK, FK], 
   MaHocKy [FK] 
) 
 

Phụ thuộc hàm 

(MaNganh, MaMH) → MaHocKy 

Khóa chính 

PRIMARY KEY (MaNganh, MaMH) 

Khóa ngoại 

MaNganh REFERENCES NGANH(MaNganh) 
MaMH REFERENCES MON_HOC(MaMH) 
MaHocKy REFERENCES HOC_KY(MaHocKy) 
Bảng NGANH_MON_HOC dùng để lưu mối quan hệ giữa ngành, môn học và học kỳ. 

VI. KIỂM TRA 3NF 

Sau khi tách bảng: 

KHOA 

MaKhoa → TenKhoa, DienThoaiKhoa, EmailKhoa 

→ Đạt 3NF. 

NGANH 

MaNganh → TenNganh, ThoiGianDaoTao, MaKhoa 

→ Đạt 3NF. 

LOP 

MaLop → TenLop, NienKhoa, MaNganh 

→ Đạt 3NF. 

SINH_VIEN 

MaSV → HoTen, NgaySinh, GioiTinh, Email, 
      SoDienThoai, QueQuan, TrangThaiHoc, MaLop 

→ Đạt 3NF. 

NGANH_MON_HOC 

(MaNganh, MaMH) → MaHocKy 

→ MaHocKy phụ thuộc đầy đủ vào khóa (MaNganh, MaMH) và không có phụ thuộc bắc cầu. 

→ Đạt 3NF. 

VII. LƯỢC ĐỒ QUAN HỆ SAU KHI CHUẨN HÓA 

KHOA ( 
   MaKhoa [PK], 
   TenKhoa, 
   DienThoaiKhoa, 
   EmailKhoa 
) 
 
NGANH ( 
   MaNganh [PK], 
   TenNganh, 
   ThoiGianDaoTao, 
   MaKhoa [FK] 
) 
 
LOP ( 
   MaLop [PK], 
   TenLop, 
   NienKhoa, 
   MaNganh [FK] 
) 
 
SINH_VIEN ( 
   MaSV [PK], 
   HoTen, 
   NgaySinh, 
   GioiTinh, 
   Email, 
   SoDienThoai, 
   QueQuan, 
   TrangThaiHoc, 
   MaLop [FK] 
) 
 
NGANH_MON_HOC ( 
   MaNganh [PK, FK], 
   MaMH [PK, FK], 
   MaHocKy [FK] 
) 
VIII. MỐI QUAN HỆ GIỮA CÁC BẢNG 

KHOA 
 │ 
 │ 1 - N 
 ▼ 
NGANH 
 │ 
 ├──────── 1 - N ────────► LOP 
 │                           │ 
 │                           │ 1 - N 
 │                           ▼ 
 │                       SINH_VIEN 
 │ 
 │ 1 - N 
 ▼ 
NGANH_MON_HOC 
 │ 
 ├──────── N - 1 ────────► MON_HOC 
 │ 
 └──────── N - 1 ────────► HOC_KY 
 

 

X. KẾT QUẢ CHUẨN HÓA 
 
| Bảng          | Khóa chính    | Phụ thuộc hàm                                                                      | Kết quả |
| ------------- | ------------- | ---------------------------------------------------------------------------------- | ------- |
| KHOA          | MaKhoa        | MaKhoa → TenKhoa, DienThoaiKhoa, EmailKhoa                                         | 3NF     |
| NGANH         | MaNganh       | MaNganh → TenNganh, ThoiGianDaoTao, MaKhoa                                         | 3NF     |
| LOP           | MaLop         | MaLop → TenLop, NienKhoa, MaNganh                                                  | 3NF     |
| SINH_VIEN     | MaSV          | MaSV → HoTen, NgaySinh, GioiTinh, Email, SoDienThoai, QueQuan, TrangThaiHoc, MaLop | 3NF     |
| NGANH_MON_HOC | MaNganh, MaMH | (MaNganh, MaMH) → MaHocKy                                                          | 3NF     |

 