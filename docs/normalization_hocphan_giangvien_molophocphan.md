# CHUẨN HÓA 3NF — HỌC PHẦN, GIẢNG VIÊN & MỞ LỚP HỌC PHẦN
## I. BẢNG GỐC (BAN ĐẦU) — DẠNG CHƯA CHUẨN HÓA
Giả sử ban đầu toàn bộ thông tin về môn học, giảng viên, học kỳ, phòng học và lịch học được lưu chung trong một bảng duy nhất có tên LOPHOCPHAN.

| Mã LHP | Tên LHP | Mã môn học | Tên môn học | Số tín chỉ | Mã môn tiên quyết | Mã GV | Tên GV | Email | Mã học kỳ | Tên học kỳ | Năm học | Mã phòng | Tên phòng | Thứ | Tiết bắt đầu | Số tiết | Sĩ số tối đa |
| :--- | :--- | :--- | :--- | :---: | :---: | :--- | :--- | :--- | :--- | :--- | :---: | :--- | :--- | :---: | :---: | :---: | :---: |
| LHP001 | CSDL-01 | MH001 | Cơ sở dữ liệu | 3 | NULL | GV001 | Nguyễn Văn A | gv01@abc.edu | HK01 | HK1 | 2025-2026 | P101 | A101 | 2 | 1 | 3 | 60 |
| LHP002 | OOP-01 | MH002 | Lập trình HĐT | 3 | MH001 | GV002 | Trần Văn B | gv02@abc.edu | HK01 | HK1 | 2025-2026 | P102 | A102 | 3 | 4 | 3 | 60 |

Trong bảng trên, thông tin về môn học, giảng viên, học kỳ và phòng học bị lặp lại ở mỗi lớp học phần được mở. Khi số lượng lớp học phần tăng lên, dữ liệu dư thừa ngày càng lớn và dễ phát sinh các bất thường khi cập nhật, thêm hoặc xóa dữ liệu.

## II PHÁT HIỆN PHỤ THUỘC HÀM (FUNCTIONAL DEPENDENCIES)

Trong bảng dữ liệu ban đầu tồn tại các phụ thuộc hàm sau:

MaMonHoc → TenMonHoc, SoTinChi

MaGV → TenGV, Email

MaHocKy → TenHocKy, NamHoc, TuNgay, DenNgay, TrangThaiDot

MaPhong → TenPhong, SucChua

MaLHP → TenLHP, MaMonHoc, MaHocKy, MaGV, SiSoToiDa, SiSoHienTai, TrangThaiLop

MaLichHoc → MaLHP, MaPhong, Thu, TietBatDau, SoTiet

(MaMonHoc, MaMonTienQuyet) là khóa của quan hệ học phần tiên quyết.

Vấn đề

Do lưu toàn bộ thông tin trong cùng một bảng nên xuất hiện nhiều dữ liệu dư thừa:

Tên môn học và số tín chỉ bị lặp lại ở mọi lớp học phần của cùng một môn học.

Thông tin giảng viên (họ tên, email) bị lặp lại ở tất cả các lớp do giảng viên phụ trách.

Thông tin học kỳ bị lặp lại cho mọi lớp học phần mở trong cùng học kỳ.

Thông tin phòng học bị lặp lại ở mọi lịch học sử dụng phòng đó.

Ví dụ minh họa dư thừa

Nếu thay đổi số tín chỉ của môn Cơ sở dữ liệu, phải cập nhật ở tất cả các dòng có môn học này (Update Anomaly).

Không thể lưu một môn học mới nếu chưa mở lớp học phần (Insert Anomaly).

Nếu xóa lớp học phần cuối cùng của một môn học thì thông tin môn học cũng bị mất (Delete Anomaly).

## III QUÁ TRÌNH CHUẨN HÓA 

### BƯỚC 1 Đạt 1NF

Mọi thuộc tính trong bảng đều được đảm bảo là đơn trị (Atomic):

Mỗi ô chỉ chứa một giá trị.

Không tồn tại danh sách giảng viên, phòng học hoặc lịch học trong cùng một ô dữ liệu.

Không có nhóm thuộc tính lặp.

Kết quả: Bảng đạt Chuẩn 1NF.

### Bước 2 — Đạt 2NF (Loại bỏ phụ thuộc bộ phận)

Các thuộc tính chỉ phụ thuộc vào từng đối tượng riêng biệt được tách thành các bảng độc lập:

MONHOC(MaMonHoc, TenMonHoc, SoTinChi, SoTietLyThuyet, SoTietThucHanh)
GIANGVIEN(MaGV, HoTen, Email)
HOCKY(MaHocKy, TenHocKy, NamHoc, TuNgay, DenNgay, TrangThaiDot)
PHONGHOC(MaPhong, TenPhong, SucChua)
LOPHOCPHAN(MaLHP, TenLHP, MaMonHoc, MaHocKy, MaGV, SiSoToiDa, SiSoHienTai, TrangThaiLop)

Ví dụ:

MaMonHoc
    → TenMonHoc

    → SoTinChi

được tách sang bảng MONHOC.

MaGV
    → HoTen

    → Email

được tách sang bảng GIANGVIEN.

Sau khi tách, mọi thuộc tính đều phụ thuộc đầy đủ vào khóa chính của từng bảng, không còn phụ thuộc bộ phận.

Kết quả: Các bảng đạt Chuẩn 2NF.

### Bước 3 — Đạt 3NF (Loại bỏ phụ thuộc bắc cầu)

#### 3.1 Loại bỏ phụ thuộc bắc cầu trong LOPHOCPHAN

Trong bảng ban đầu tồn tại phụ thuộc:

MaLHP
    → MaMonHoc

    → TenMonHoc

    → SoTinChi

Đây là phụ thuộc bắc cầu vì:

MaLHP

    → MaMonHoc

MaMonHoc

    → TenMonHoc, SoTinChi

Do đó, thông tin TenMonHoc và SoTinChi được tách sang bảng MONHOC.

Tương tự:

MaLHP
    → MaGV

    → HoTen

    → Email

Thông tin giảng viên được tách sang bảng GIANGVIEN.

Nhờ vậy, bảng LOPHOCPHAN chỉ còn lưu khóa ngoại tham chiếu đến các bảng liên quan.

#### 3.2 Chuẩn hóa quan hệ MONHOC_TIENQUYET

Quan hệ giữa các môn học tiên quyết là quan hệ nhiều – nhiều tự tham chiếu (Recursive Many-to-Many Relationship).

Nếu lưu:

MaMonHoc	MonTienQuyet
MH002	MH001, MH003

thì:

Một ô chứa nhiều giá trị.
Vi phạm chuẩn 1NF.
Khó truy vấn và cập nhật.

Do đó tạo bảng trung gian:

MONHOC_TIENQUYET
MaMonHoc	MaMonTienQuyet
MH002	MH001
MH002	MH003

Khóa chính:

(MaMonHoc, MaMonTienQuyet)

Quan hệ nhiều–nhiều được chuẩn hóa, loại bỏ dữ liệu lặp và đảm bảo tính toàn vẹn tham chiếu.

#### 3.3 Tách LICHHOC khỏi LOPHOCPHAN

Ban đầu nếu lưu trực tiếp:

MaLHP
TenLHP
Thu
TietBatDau
SoTiet
MaPhong

thì một lớp học phần học nhiều buổi sẽ phải lặp toàn bộ thông tin lớp học.

Ví dụ:

LHP001
CSDL-01
Thứ 2
Tiết 1

LHP001
CSDL-01
Thứ 5
Tiết 4

Các thông tin:

MaGV
MaMonHoc
MaHocKy
TenLHP
SiSoToiDa

đều bị lặp lại.

Điều này gây:

Update Anomaly: sửa thông tin lớp học phải cập nhật nhiều dòng.
Insert Anomaly: không thể thêm lớp học nếu chưa có lịch học.
Delete Anomaly: xóa lịch học cuối cùng có thể làm mất thông tin lớp học.

Do đó tách thành:

LOPHOCPHAN

MaLHP
TenLHP
MaMonHoc
MaHocKy
MaGV
SiSoToiDa
SiSoHienTai
TrangThaiLop

LICHHOC

MaLichHoc
MaLHP
MaPhong
Thu
TietBatDau
SoTiet

Quan hệ:

LOPHOCPHAN (1)
        │
        └──────────< LICHHOC (N)

Một lớp học phần có thể có nhiều lịch học, nhưng mỗi lịch học chỉ thuộc về một lớp học phần.

## IV. CÁC BẢNG SAU KHI CHUẨN HÓA

| Bảng | Vai trò |
| :--- | :--- |
| **MONHOC** | Quản lý thông tin môn học |
| **MONHOC_TIENQUYET** | Quản lý quan hệ tiên quyết giữa các môn học |
| **GIANGVIEN** | Quản lý thông tin giảng viên |
| **HOCKY** | Quản lý thông tin học kỳ |
| **PHONGHOC** | Quản lý thông tin phòng học |
| **LOPHOCPHAN** | Quản lý lớp học phần |
| **LICHHOC** | Quản lý lịch học của lớp học phần |

## V. PHỤ THUỘC HÀM ĐẦY ĐỦ — BẢNG MINH CHỨNG
| Khóa / Phụ thuộc | Loại | Đạt / Không đạt |
| :--- | :--- | :---: |
| MaMonHoc → TenMonHoc, SoTinChi | Full dependency | 2NF ✅ |
| MaGV → HoTen, Email | Full dependency | 2NF ✅ |
| MaHocKy → TenHocKy, NamHoc, TuNgay, DenNgay, TrangThaiDot | Full dependency | 2NF ✅ |
| MaPhong → TenPhong, SucChua | Full dependency | 2NF ✅ |
| MaLHP → MaMonHoc, MaHocKy, MaGV, SiSoToiDa, SiSoHienTai, TrangThaiLop | Full dependency | 2NF ✅ |
| MaLichHoc → MaLHP, MaPhong, Thu, TietBatDau, SoTiet | Full dependency | 2NF ✅ |
| (MaMonHoc, MaMonTienQuyet) là khóa của bảng MONHOC_TIENQUYET | Khóa ghép | 2NF ✅ |
| Không tồn tại phụ thuộc bắc cầu giữa các thuộc tính không khóa | | 3NF ✅ |

Kết luận: Các bảng MONHOC, MONHOC_TIENQUYET, GIANGVIEN, HOCKY, PHONGHOC, LOPHOCPHAN và LICHHOC đều đạt chuẩn 3NF; đồng 

thời phần lớn các bảng cũng thỏa mãn BCNF do mọi phụ thuộc hàm đều có vế trái là khóa hoặc siêu khóa.

## VI. ĐỐI CHIẾU VỚI THIẾT KẾ DDL

Script DDL chính thức của module đã hiện thực đúng mô hình chuẩn hóa 3NF thông qua việc xây dựng các bảng MONHOC,

MONHOC_TIENQUYET, GIANGVIEN, HOCKY, PHONGHOC, LOPHOCPHAN và LICHHOC, cùng các khóa chính, khóa ngoại và ràng buộc toàn 

vẹn tương ứng. Thiết kế này đảm bảo loại bỏ dữ liệu dư thừa, duy trì tính nhất quán và hỗ trợ hiệu quả cho việc quản lý 

học phần, phân công giảng viên, bố trí lịch học và mở lớp học phần.

# Viết DDL Học phần, Giảng viên & Mở lớp học phần

/*==========================================================

DATABASE

==========================================================*/ 
if db_id('DangKyHocPhan') is not null begin

alter database DangKyHocPhan

set single_user with rollback immediate;

drop database DangKyHocPhan;
end

create database DangKyHocPhan;

use DangKyHocPhan;

/*==========================================================

MONHOC

==========================================================*/

create table MonHoc

( MaMonHoc varchar(10) not null,

TenMonHoc nvarchar(100) not null,

SoTinChi int not null,

SoTietLyThuyet int not null,

SoTietThucHanh int not null,

constraint PK_MonHoc

    primary key (MaMonHoc),

constraint UQ_MonHoc

    unique (TenMonHoc),

constraint CK_MH_TinChi

    check (SoTinChi > 0),

constraint CK_MH_LT

    check (SoTietLyThuyet >= 0),

constraint CK_MH_TH

    check (SoTietThucHanh >= 0)
);

/*==========================================================

MONHOC_TIENQUYET

==========================================================*/

create table MonHoc_TienQuyet

( MaMonHoc varchar(10) not null,

MaMonTienQuyet varchar(10) not null,

constraint PK_MonHoc_TienQuyet

    primary key (MaMonHoc, MaMonTienQuyet),

constraint FK_MHTQ_MonHoc

    foreign key (MaMonHoc)

    references MonHoc(MaMonHoc),

constraint FK_MHTQ_MonTienQuyet

    foreign key (MaMonTienQuyet)

    references MonHoc(MaMonHoc),

constraint CK_MHTQ

    check (MaMonHoc <> MaMonTienQuyet)
);

/*==========================================================

HOCKY

==========================================================*/

create table HocKy

( MaHocKy varchar(10) not null,

TenHocKy nvarchar(30) not null,

NamHoc varchar(20) not null,

TuNgay date not null,

DenNgay date not null,

TrangThaiDot nvarchar(30) not null,

constraint PK_HocKy
    primary key (MaHocKy),

constraint CK_HocKy_Ngay

    check (TuNgay < DenNgay),

constraint CK_HocKy_TrangThai

    check (TrangThaiDot in
    (
        N'Chưa mở',

        N'Đang mở',

        N'Đã kết thúc'

    ))
);

/*==========================================================

GIANGVIEN

==========================================================*/

 create table GiangVien

( MaGV varchar(10) not null,

HoTen nvarchar(100) not null,

Email varchar(100) not null,

constraint PK_GiangVien

    primary key (MaGV),

constraint UQ_GiangVien_Email

    unique (Email),

constraint CK_GiangVien_Email

    check (Email like '%@%.%')
);

/*==========================================================

PHONGHOC

==========================================================*/

create table PhongHoc

( MaPhong varchar(10) not null,

TenPhong nvarchar(30) not null,

SucChua int not null,

constraint PK_PhongHoc

    primary key (MaPhong),

constraint UQ_PhongHoc

    unique (TenPhong),

constraint CK_PhongHoc

    check (SucChua > 0)
);

/*==========================================================

LOPHOCPHAN

==========================================================*/

create table LopHocPhan

( MaLHP varchar(10) not null,

TenLHP nvarchar(100) not null,

SiSoToiDa int not null,

SiSoHienTai int not null default 0,

TrangThaiLop nvarchar(30) not null default N'Mở đăng ký',


MaMonHoc varchar(10) not null,

MaHocKy varchar(10) not null,

MaGV varchar(10) not null,

constraint PK_LopHocPhan

    primary key (MaLHP),

constraint FK_LHP_MonHoc

    foreign key (MaMonHoc)

    references MonHoc(MaMonHoc),

constraint FK_LHP_HocKy

    foreign key (MaHocKy)

    references HocKy(MaHocKy),

constraint FK_LHP_GiangVien

    foreign key (MaGV)

    references GiangVien(MaGV),

constraint CK_LHP_SiSo

    check (SiSoToiDa > 0),

constraint CK_LHP_HienTai

    check (SiSoHienTai between 0 and SiSoToiDa),

constraint CK_LHP_TrangThai

    check (TrangThaiLop in

    (

        N'Mở đăng ký',

        N'Đã đóng',

        N'Đã hủy'

    ))
);

/*==========================================================

LICHHOC

==========================================================*/

create table LichHoc

(

MaLichHoc varchar(10) not null,

MaLHP varchar(10) not null,

MaPhong varchar(10) not null,

Thu tinyint not null,

TietBatDau tinyint not null,

SoTiet tinyint not null,

constraint PK_LichHoc

    primary key (MaLichHoc),

constraint FK_LH_LopHocPhan

    foreign key (MaLHP)

    references LopHocPhan(MaLHP)
    
    on delete cascade,

constraint FK_LH_PhongHoc

    foreign key (MaPhong)

    references PhongHoc(MaPhong),

constraint CK_LH_Thu

    check (Thu between 2 and 8),

constraint CK_LH_TietBatDau

    check (TietBatDau > 0),

constraint CK_LH_SoTiet

    check (SoTiet > 0),

constraint UQ_LichPhong

    unique (MaPhong, Thu, TietBatDau)
);

/*==========================================================

INDEX
==========================================================*/

create index IDX_LHP_MonHoc

on LopHocPhan(MaMonHoc);

create index IDX_LHP_GiangVien

on LopHocPhan(MaGV);

create index IDX_LHP_HocKy

on LopHocPhan(MaHocKy);

create index IDX_LH_Phong

on LichHoc(MaPhong);

create index IDX_LH_LopHocPhan

on LichHoc(MaLHP);

# Dữ liệu mẫu Học phần, Giảng viên & Mở lớp học phần

/*==========================================================
    DỮ LIỆU MẪU - HOCKY
==========================================================*/
INSERT INTO HocKy VALUES
('HK01', N'Học kỳ 1', '2026-2027', '2026-09-01', '2027-01-15', N'Đã kết thúc'),
('HK02', N'Học kỳ 2', '2026-2027', '2027-02-01', '2027-06-15', N'Đang mở'),
('HK03', N'Học kỳ hè', '2026-2027', '2027-07-01', '2027-08-15', N'Chưa mở');

/*==========================================================
    DỮ LIỆU MẪU - PHONGHOC
==========================================================*/
INSERT INTO PhongHoc VALUES
('P001',N'A101',40), ('P002',N'A102',40), ('P003',N'A103',45), ('P004',N'A104',45), ('P005',N'A105',50),
('P006',N'B101',40), ('P007',N'B102',40), ('P008',N'B103',45), ('P009',N'B104',45), ('P010',N'B105',50),
('P011',N'C101',40), ('P012',N'C102',40), ('P013',N'C103',45), ('P014',N'C104',45), ('P015',N'C105',50),
('P016',N'D101',40), ('P017',N'D102',40), ('P018',N'D103',45), ('P019',N'D104',45), ('P020',N'D105',60);

/*==========================================================
    DỮ LIỆU MẪU - GIANGVIEN
==========================================================*/
INSERT INTO GiangVien VALUES
('GV001',N'Nguyễn Văn An','an@uth.edu.vn'),
('GV002',N'Trần Thị Bình','binh@uth.edu.vn'),
('GV003',N'Lê Văn Cường','cuong@uth.edu.vn'),
('GV004',N'Phạm Minh Đức','duc@uth.edu.vn'),
('GV005',N'Hoàng Quốc Dũng','dung@uth.edu.vn'),
('GV006',N'Đỗ Thị Hạnh','hanh@uth.edu.vn'),
('GV007',N'Bùi Văn Hải','hai@uth.edu.vn'),
('GV008',N'Nguyễn Thị Hoa','hoa@uth.edu.vn'),
('GV009',N'Phan Văn Khánh','khanh@uth.edu.vn'),
('GV010',N'Lý Minh Long','long@uth.edu.vn'),
('GV011',N'Võ Thanh Nam','nam@uth.edu.vn'),
('GV012',N'Đặng Thị Ngọc','ngoc@uth.edu.vn'),
('GV013',N'Trịnh Văn Phúc','phuc@uth.edu.vn'),
('GV014',N'Huỳnh Minh Quân','quan@uth.edu.vn'),
('GV015',N'Nguyễn Thanh Tùng','tung@uth.edu.vn');

/*==========================================================
    DỮ LIỆU MẪU - MONHOC
==========================================================*/
INSERT INTO MonHoc VALUES
('MH001',N'Nhập môn Công nghệ thông tin',3,30,30),
('MH002',N'Lập trình C',3,30,30),
('MH003',N'Lập trình hướng đối tượng',3,30,30),
('MH004',N'Cấu trúc dữ liệu và giải thuật',4,45,30),
('MH005',N'Cơ sở dữ liệu',3,30,30),
('MH006',N'Hệ quản trị cơ sở dữ liệu',3,30,30),
('MH007',N'Kiến trúc máy tính',3,45,15),
('MH008',N'Hệ điều hành',3,30,30),
('MH009',N'Mạng máy tính',3,30,30),
('MH010',N'Lập trình Web',3,30,30),
('MH011',N'Phân tích và thiết kế hệ thống',3,30,30),
('MH012',N'Công nghệ phần mềm',3,30,30),
('MH013',N'Lập trình Java',3,30,30),
('MH014',N'Lập trình .NET',3,30,30),
('MH015',N'Lập trình Python',3,30,30),
('MH016',N'An toàn thông tin',3,30,30),
('MH017',N'Trí tuệ nhân tạo',3,30,30),
('MH018',N'Khai phá dữ liệu',3,30,30),
('MH019',N'Học máy',3,30,30),
('MH020',N'Điện toán đám mây',3,30,30),
('MH021',N'Internet vạn vật',3,30,30),
('MH022',N'Lập trình thiết bị di động',3,30,30),
('MH023',N'Phát triển ứng dụng Web',3,30,30),
('MH024',N'Đồ họa máy tính',3,30,30),
('MH025',N'Xử lý ảnh',3,30,30),
('MH026',N'Xử lý ngôn ngữ tự nhiên',3,30,30),
('MH027',N'Kiểm thử phần mềm',3,30,30),
('MH028',N'Quản lý dự án CNTT',3,30,30),
('MH029',N'Thương mại điện tử',3,30,30),
('MH030',N'Blockchain',3,30,30),
('MH031',N'Big Data',3,30,30),
('MH032',N'Phân tích dữ liệu',3,30,30),
('MH033',N'Thiết kế UI/UX',3,30,30),
('MH034',N'Đồ án cơ sở',2,15,30),
('MH035',N'Đồ án chuyên ngành',3,15,45),
('MH036',N'Thực tập doanh nghiệp',4,0,120),
('MH037',N'Đồ án tốt nghiệp',6,0,180),
('MH038',N'Chuyên đề CNTT',2,15,30),
('MH039',N'Kỹ năng nghề nghiệp',2,30,0),
('MH040',N'Khởi nghiệp và đổi mới sáng tạo',2,30,0);

/*==========================================================
    DỮ LIỆU MẪU - MONHOC_TIENQUYET
==========================================================*/
INSERT INTO MonHoc_TienQuyet VALUES
('MH003','MH002'), ('MH004','MH003'), ('MH005','MH002'), ('MH006','MH005'),
('MH008','MH007'), ('MH009','MH007'), ('MH010','MH003'), ('MH011','MH005'),
('MH012','MH011'), ('MH013','MH003'), ('MH014','MH013'), ('MH016','MH009'),
('MH017','MH004'), ('MH018','MH005'), ('MH019','MH017'), ('MH020','MH009'),
('MH021','MH009'), ('MH022','MH013'), ('MH023','MH010'), ('MH024','MH003'),
('MH025','MH024'), ('MH026','MH017'), ('MH027','MH012'), ('MH028','MH012'),
('MH029','MH010'), ('MH030','MH020'), ('MH031','MH018'), ('MH032','MH018'),
('MH034','MH012'), ('MH035','MH034'), ('MH036','MH035'), ('MH037','MH036'),
('MH038','MH012');

/*==========================================================
    DỮ LIỆU MẪU - LOPHOCPHAN 
==========================================================*/
INSERT INTO LopHocPhan VALUES
('LHP001',N'Nhập môn CNTT - 01',60,0,N'Mở đăng ký','MH001','HK02','GV001'),
('LHP002',N'Nhập môn CNTT - 02',60,0,N'Mở đăng ký','MH001','HK02','GV002'),
('LHP003',N'Lập trình C - 01',60,0,N'Mở đăng ký','MH002','HK02','GV003'),
('LHP004',N'Lập trình C - 02',60,0,N'Mở đăng ký','MH002','HK02','GV004'),
('LHP005',N'Lập trình HĐT - 01',55,0,N'Mở đăng ký','MH003','HK02','GV005'),
('LHP006',N'Lập trình HĐT - 02',55,0,N'Mở đăng ký','MH003','HK02','GV006'),
('LHP007',N'CTDL & GT - 01',50,0,N'Mở đăng ký','MH004','HK02','GV007'),
('LHP008',N'CTDL & GT - 02',50,0,N'Mở đăng ký','MH004','HK02','GV008'),
('LHP009',N'Cơ sở dữ liệu - 01',60,0,N'Mở đăng ký','MH005','HK02','GV009'),
('LHP010',N'Cơ sở dữ liệu - 02',60,0,N'Mở đăng ký','MH005','HK02','GV010'),
('LHP011',N'Hệ QTCSDL - 01',50,0,N'Mở đăng ký','MH006','HK02','GV011'),
('LHP012',N'Hệ QTCSDL - 02',50,0,N'Mở đăng ký','MH006','HK02','GV012'),
('LHP013',N'Kiến trúc máy tính - 01',55,0,N'Mở đăng ký','MH007','HK02','GV013'),
('LHP014',N'Kiến trúc máy tính - 02',55,0,N'Mở đăng ký','MH007','HK02','GV014'),
('LHP015',N'Hệ điều hành - 01',55,0,N'Mở đăng ký','MH008','HK02','GV015'),
('LHP016',N'Hệ điều hành - 02',55,0,N'Mở đăng ký','MH008','HK02','GV001'),
('LHP017',N'Mạng máy tính - 01',60,0,N'Mở đăng ký','MH009','HK02','GV002'),
('LHP018',N'Mạng máy tính - 02',60,0,N'Mở đăng ký','MH009','HK02','GV003'),
('LHP019',N'Lập trình Web - 01',60,0,N'Mở đăng ký','MH010','HK02','GV004'),
('LHP020',N'Lập trình Web - 02',60,0,N'Mở đăng ký','MH010','HK02','GV005'),
('LHP021',N'Phân tích và thiết kế HT - 01',60,0,N'Mở đăng ký','MH011','HK02','GV006'),
('LHP022',N'Phân tích và thiết kế HT - 02',60,0,N'Mở đăng ký','MH011','HK02','GV007'),
('LHP023',N'Công nghệ phần mềm - 01',60,0,N'Mở đăng ký','MH012','HK02','GV008'),
('LHP024',N'Công nghệ phần mềm - 02',60,0,N'Mở đăng ký','MH012','HK02','GV009'),
('LHP025',N'Lập trình Java - 01',55,0,N'Mở đăng ký','MH013','HK02','GV010'),
('LHP026',N'Lập trình Java - 02',55,0,N'Mở đăng ký','MH013','HK02','GV011'),
('LHP027',N'Lập trình .NET - 01',55,0,N'Mở đăng ký','MH014','HK02','GV012'),
('LHP028',N'Lập trình .NET - 02',55,0,N'Mở đăng ký','MH014','HK02','GV013'),
('LHP029',N'Lập trình Python - 01',60,0,N'Mở đăng ký','MH015','HK02','GV014'),
('LHP030',N'Lập trình Python - 02',60,0,N'Mở đăng ký','MH015','HK02','GV015'),
('LHP031',N'An toàn thông tin - 01',50,0,N'Mở đăng ký','MH016','HK02','GV001'),
('LHP032',N'An toàn thông tin - 02',50,0,N'Mở đăng ký','MH016','HK02','GV002'),
('LHP033',N'Trí tuệ nhân tạo - 01',50,0,N'Mở đăng ký','MH017','HK02','GV003'),
('LHP034',N'Trí tuệ nhân tạo - 02',50,0,N'Mở đăng ký','MH017','HK02','GV004'),
('LHP035',N'Khai phá dữ liệu - 01',50,0,N'Mở đăng ký','MH018','HK02','GV005'),
('LHP036',N'Khai phá dữ liệu - 02',50,0,N'Mở đăng ký','MH018','HK02','GV006'),
('LHP037',N'Học máy - 01',45,0,N'Mở đăng ký','MH019','HK02','GV007'),
('LHP038',N'Học máy - 02',45,0,N'Mở đăng ký','MH019','HK02','GV008'),
('LHP039',N'Điện toán đám mây - 01',60,0,N'Mở đăng ký','MH020','HK02','GV009'),
('LHP040',N'Điện toán đám mây - 02',60,0,N'Mở đăng ký','MH020','HK02','GV010'),
('LHP041',N'Internet vạn vật - 01',50,0,N'Mở đăng ký','MH021','HK02','GV011'),
('LHP042',N'Internet vạn vật - 02',50,0,N'Mở đăng ký','MH021','HK02','GV012'),
('LHP043',N'Lập trình Mobile - 01',55,0,N'Mở đăng ký','MH022','HK02','GV013'),
('LHP044',N'Lập trình Mobile - 02',55,0,N'Mở đăng ký','MH022','HK02','GV014'),
('LHP045',N'Phát triển ứng dụng Web - 01',60,0,N'Mở đăng ký','MH023','HK02','GV015'),
('LHP046',N'Phát triển ứng dụng Web - 02',60,0,N'Mở đăng ký','MH023','HK02','GV001'),
('LHP047',N'Đồ họa máy tính - 01',50,0,N'Mở đăng ký','MH024','HK02','GV002'),
('LHP048',N'Đồ họa máy tính - 02',50,0,N'Mở đăng ký','MH024','HK02','GV003'),
('LHP049',N'Xử lý ảnh - 01',45,0,N'Mở đăng ký','MH025','HK02','GV004'),
('LHP050',N'Xử lý ảnh - 02',45,0,N'Mở đăng ký','MH025','HK02','GV005'),
('LHP051',N'Xử lý ngôn ngữ TN - 01',45,0,N'Mở đăng ký','MH026','HK02','GV006'),
('LHP052',N'Xử lý ngôn ngữ TN - 02',45,0,N'Mở đăng ký','MH026','HK02','GV007'),
('LHP053',N'Kiểm thử phần mềm - 01',55,0,N'Mở đăng ký','MH027','HK02','GV008'),
('LHP054',N'Kiểm thử phần mềm - 02',55,0,N'Mở đăng ký','MH027','HK02','GV009'),
('LHP055',N'Quản lý dự án CNTT - 01',60,0,N'Mở đăng ký','MH028','HK02','GV010'),
('LHP056',N'Quản lý dự án CNTT - 02',60,0,N'Mở đăng ký','MH028','HK02','GV011'),
('LHP057',N'Thương mại điện tử - 01',60,0,N'Mở đăng ký','MH029','HK02','GV012'),
('LHP058',N'Thương mại điện tử - 02',60,0,N'Mở đăng ký','MH029','HK02','GV013'),
('LHP059',N'Blockchain - 01',50,0,N'Mở đăng ký','MH030','HK02','GV014'),
('LHP060',N'Blockchain - 02',50,0,N'Mở đăng ký','MH030','HK02','GV015'),
('LHP061',N'Big Data - 01',50,0,N'Mở đăng ký','MH031','HK02','GV001'),
('LHP062',N'Big Data - 02',50,0,N'Mở đăng ký','MH031','HK02','GV002'),
('LHP063',N'Phân tích dữ liệu - 01',55,0,N'Mở đăng ký','MH032','HK02','GV003'),
('LHP064',N'Phân tích dữ liệu - 02',55,0,N'Mở đăng ký','MH032','HK02','GV004'),
('LHP065',N'Thiết kế UI/UX - 01',60,0,N'Mở đăng ký','MH033','HK02','GV005'),
('LHP066',N'Thiết kế UI/UX - 02',60,0,N'Mở đăng ký','MH033','HK02','GV006'),
('LHP067',N'Đồ án cơ sở - 01',40,0,N'Mở đăng ký','MH034','HK02','GV007'),
('LHP068',N'Đồ án cơ sở - 02',40,0,N'Mở đăng ký','MH034','HK02','GV008'),
('LHP069',N'Đồ án chuyên ngành - 01',35,0,N'Mở đăng ký','MH035','HK02','GV009'),
('LHP070',N'Đồ án chuyên ngành - 02',35,0,N'Mở đăng ký','MH035','HK02','GV010'),
('LHP071',N'Thực tập doanh nghiệp - 01',30,0,N'Mở đăng ký','MH036','HK02','GV011'),
('LHP072',N'Thực tập doanh nghiệp - 02',30,0,N'Mở đăng ký','MH036','HK02','GV012'),
('LHP073',N'Đồ án tốt nghiệp - 01',25,0,N'Mở đăng ký','MH037','HK02','GV013'),
('LHP074',N'Đồ án tốt nghiệp - 02',25,0,N'Mở đăng ký','MH037','HK02','GV014'),
('LHP075',N'Chuyên đề CNTT - 01',45,0,N'Mở đăng ký','MH038','HK02','GV015'),
('LHP076',N'Chuyên đề CNTT - 02',45,0,N'Mở đăng ký','MH038','HK02','GV001'),
('LHP077',N'Kỹ năng nghề nghiệp - 01',60,0,N'Mở đăng ký','MH039','HK02','GV002'),
('LHP078',N'Kỹ năng nghề nghiệp - 02',60,0,N'Mở đăng ký','MH039','HK02','GV003'),
('LHP079',N'Khởi nghiệp và đổi mới sáng tạo - 01',60,0,N'Mở đăng ký','MH040','HK02','GV004'),
('LHP080',N'Khởi nghiệp và đổi mới sáng tạo - 02',60,0,N'Mở đăng ký','MH040','HK02','GV005');

/*==========================================================
    DỮ LIỆU MẪU CHUẨN HÓA - LICHHOC 
    Khung giờ 5 ca (mỗi ca 3 tiết):
    - Ca 1: Tiết 1-3   (TietBatDau = 1,  SoTiet = 3)
    - Ca 2: Tiết 4-6   (TietBatDau = 4,  SoTiet = 3)
    - Ca 3: Tiết 7-9   (TietBatDau = 7,  SoTiet = 3)
    - Ca 4: Tiết 10-12 (TietBatDau = 10, SoTiet = 3)
    - Ca 5: Tiết 13-15 (TietBatDau = 13, SoTiet = 3)
==========================================================*/
INSERT INTO LichHoc VALUES
('LH001','LHP001','P001',2,1,3),  ('LH002','LHP002','P002',2,4,3),
('LH003','LHP003','P003',3,1,3),  ('LH004','LHP004','P004',3,4,3),
('LH005','LHP005','P005',4,1,3),  ('LH006','LHP006','P006',4,4,3),
('LH007','LHP007','P007',5,1,3),  ('LH008','LHP008','P008',5,4,3),
('LH009','LHP009','P009',6,1,3),  ('LH010','LHP010','P010',6,4,3),
('LH011','LHP011','P011',7,1,3),  ('LH012','LHP012','P012',7,4,3),
('LH013','LHP013','P013',2,7,3),  ('LH014','LHP014','P014',3,7,3),
('LH015','LHP015','P015',4,7,3),  ('LH016','LHP016','P016',5,7,3),
('LH017','LHP017','P017',6,7,3),  ('LH018','LHP018','P018',7,7,3),
('LH019','LHP019','P019',2,10,3), ('LH020','LHP020','P020',3,10,3),
('LH021','LHP021','P001',4,10,3), ('LH022','LHP022','P002',5,10,3),
('LH023','LHP023','P003',6,10,3), ('LH024','LHP024','P004',7,10,3),
('LH025','LHP025','P005',2,13,3), ('LH026','LHP026','P006',3,13,3),
('LH027','LHP027','P007',4,13,3), ('LH028','LHP028','P008',5,13,3),
('LH029','LHP029','P009',6,13,3), ('LH030','LHP030','P010',7,13,3),
('LH031','LHP031','P011',2,1,3),  ('LH032','LHP032','P012',3,1,3),
('LH033','LHP033','P013',4,1,3),  ('LH034','LHP034','P014',5,1,3),
('LH035','LHP035','P015',6,1,3),  ('LH036','LHP036','P016',7,1,3),
('LH037','LHP037','P017',2,4,3),  ('LH038','LHP038','P018',3,4,3),
('LH039','LHP039','P019',4,4,3),  ('LH040','LHP040','P020',5,4,3),
('LH041','LHP041','P001',6,4,3),  ('LH042','LHP042','P002',6,7,3),
('LH043','LHP043','P003',7,4,3),  ('LH044','LHP044','P004',7,7,3),
('LH045','LHP045','P005',2,7,3),  ('LH046','LHP046','P006',3,7,3),
('LH047','LHP047','P007',4,7,3),  ('LH048','LHP048','P008',5,7,3),
('LH049','LHP049','P009',6,7,3),  ('LH050','LHP050','P010',7,7,3),
('LH051','LHP051','P011',2,10,3), ('LH052','LHP052','P012',3,10,3),
('LH053','LHP053','P013',4,10,3), ('LH054','LHP054','P014',5,10,3),
('LH055','LHP055','P015',6,10,3), ('LH056','LHP056','P016',7,10,3),
('LH057','LHP057','P017',2,10,3), ('LH058','LHP058','P018',3,10,3),
('LH059','LHP059','P019',4,10,3), ('LH060','LHP060','P020',5,10,3),
('LH061','LHP061','P001',2,13,3), ('LH062','LHP062','P002',3,13,3),
('LH063','LHP063','P003',4,13,3), ('LH064','LHP064','P004',5,13,3),
('LH065','LHP065','P005',6,13,3), ('LH066','LHP066','P006',7,13,3),
('LH067','LHP067','P007',2,4,3),  ('LH068','LHP068','P008',3,4,3),
('LH069','LHP069','P009',4,4,3),  ('LH070','LHP070','P010',5,4,3),
('LH071','LHP071','P011',6,4,3),  ('LH072','LHP072','P012',7,4,3),
('LH073','LHP073','P013',2,7,3),  ('LH074','LHP074','P014',3,7,3),
('LH075','LHP075','P015',4,7,3),  ('LH076','LHP076','P016',5,7,3),
('LH077','LHP077','P017',6,7,3),  ('LH078','LHP078','P018',7,7,3),
('LH079','LHP079','P019',2,13,3), ('LH080','LHP080','P020',3,13,3);