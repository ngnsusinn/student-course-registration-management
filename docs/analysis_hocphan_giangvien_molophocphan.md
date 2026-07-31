# Phân tích nghiệp vụ Học phần, Giảng viên & Mở lớp học phần
## 1. Giới thiệu nghiệp vụ
### 1.1 Mô tả nghiệp vụ
Module Học phần, Giảng viên và Mở lớp học phần là một trong những nghiệp vụ cốt lõi của hệ thống quản lý đăng ký tín chỉ. Module này hỗ trợ Phòng Đào tạo quản lý danh mục học phần, thông tin giảng viên và tổ chức mở các lớp học phần theo từng học kỳ.
Sau khi các lớp học phần được tạo thành công, dữ liệu sẽ được công bố để sinh viên thực hiện đăng ký học phần. Do đó, tính chính xác của dữ liệu trong module này ảnh hưởng trực tiếp đến toàn bộ quá trình đăng ký học của sinh viên.

### 1.2 Mục tiêu nghiệp vụ
•	Quản lý danh mục học phần của nhà trường. 
•	Quản lý thông tin giảng viên. 
•	Quản lý việc mở lớp học phần theo từng học kỳ. 
•	Phân công giảng viên giảng dạy. 
•	Xây dựng lịch học và phòng học. 
•	Chuẩn bị dữ liệu phục vụ sinh viên đăng ký học phần. 
## 2. Tác nhân
Tác nhân	Vai trò
Phòng Đào tạo	Quản lý học phần, giảng viên và mở lớp học phần
Giảng viên	Được phân công giảng dạy các lớp học phần
Sinh viên	Xem danh sách lớp học phần để đăng ký

## 3. Use Case
STT	Use Case	Tác nhân	Mô tả
1	Quản lý học phần	Phòng Đào tạo	Thêm, sửa, xóa và tra cứu thông tin học phần.
2	Quản lý giảng viên	Phòng Đào tạo	Thêm, sửa, xóa và cập nhật thông tin giảng viên.
3	Chọn học kỳ	Phòng Đào tạo	Chọn học kỳ để thực hiện mở lớp học phần.
4	Mở lớp học phần	Phòng Đào tạo	Tạo lớp học phần cho học phần đã chọn.
5	Phân công giảng viên	Phòng Đào tạo	Phân công giảng viên phụ trách giảng dạy lớp học phần.
6	Xếp lịch học	Phòng Đào tạo	Thiết lập lịch học, phòng học và sĩ số tối đa cho lớp học phần.
7	Xem lớp học phần được phân công	Giảng viên	Xem danh sách các lớp học phần được phân công giảng dạy.
8	Xem danh sách lớp học phần	Sinh viên	Xem danh sách lớp học phần đã được mở để đăng ký.

## 4.Phân tích nghiệp vụ
### 4.1. Phân tích nghiệp vụ quản lý học phần
Mô tả
Phòng Đào tạo chịu trách nhiệm xây dựng và quản lý danh mục học phần của trường. Mỗi học phần được xác định bằng một mã học phần duy nhất và chứa đầy đủ thông tin như tên học phần, số tín chỉ, số tiết lý thuyết, số tiết thực hành và điều kiện tiên quyết (nếu có).
Danh mục học phần là cơ sở để xây dựng chương trình đào tạo và mở lớp học phần trong từng học kỳ.
Dữ liệu đầu vào
•	Mã học phần 
•	Tên học phần 
•	Số tín chỉ 
•	Số tiết lý thuyết 
•	Số tiết thực hành 
•	Điều kiện tiên quyết 
Dữ liệu đầu ra
•	Danh sách học phần 
•	Thông tin học phần đã được lưu 
Quy tắc nghiệp vụ
•	Mã học phần phải duy nhất. 
•	Tên học phần không được để trống. 
•	Số tín chỉ phải lớn hơn 0. 
•	Không được xóa học phần đang được mở lớp. 

### 4.2. Phân tích nghiệp vụ quản lý giảng viên
Mô tả
Phòng Đào tạo quản lý hồ sơ giảng viên nhằm phục vụ việc phân công giảng dạy. Mỗi giảng viên có mã định danh riêng cùng các thông tin như họ tên, email, số điện thoại, khoa và chức vụ.
Thông tin giảng viên được sử dụng khi mở lớp học phần và phân công giảng dạy.
Dữ liệu đầu vào
•	Mã giảng viên 
•	Họ tên 
•	Email 
•	Số điện thoại 
•	Mã Khoa 
•	Chức vụ 
Dữ liệu đầu ra
•	Danh sách giảng viên 
•	Hồ sơ giảng viên 
Quy tắc nghiệp vụ
•	Mã giảng viên không được trùng. 
•	Email phải đúng định dạng. 
•	Không được xóa giảng viên đang giảng dạy. 

### 4.3. Phân tích nghiệp vụ mở lớp học phần
Mô tả
Sau khi danh mục học phần và danh sách giảng viên đã được thiết lập, Phòng Đào tạo tiến hành mở các lớp học phần theo từng học kỳ.
Mỗi lớp học phần sẽ được gắn với một học phần cụ thể, một giảng viên phụ trách, phòng học, lịch học và sĩ số tối đa. Sau khi hoàn tất kiểm tra các điều kiện, lớp học phần sẽ được lưu vào hệ thống để sinh viên đăng ký.
Dữ liệu đầu vào
•	Học phần 
•	Học kỳ 
•	Giảng viên 
•	Phòng học 
•	Lịch học 
•	Sĩ số tối đa 
Dữ liệu đầu ra
•	Danh sách lớp học phần 
•	Lịch học 
•	Danh sách phân công giảng viên 
Quy tắc nghiệp vụ
•	Học phần phải tồn tại. 
•	Giảng viên phải tồn tại. 
•	Không được trùng lịch giảng viên. 
•	Không được trùng phòng học. 
•	Sĩ số tối đa phải lớn hơn 0. 
•	Khi đủ sĩ số phải đóng đăng ký. 
•	Học phần có thể có hoặc không có học phần tiên quyết.
•	Nếu có học phần tiên quyết thì học phần tiên quyết phải tồn tại trong hệ thống.

## 5. Luồng xử lý nghiệp vụ

                Phòng Đào tạo
                       │
                       ▼
            Quản lý học phần
                       │
                       ▼
           Quản lý giảng viên
                       │
                       ▼
               Chọn học kỳ
                       │
                       ▼
         Phân công giảng viên
                       │
                       ▼
               Xếp lịch học
                       │
                       ▼
          Kiểm tra ràng buộc
     (Giảng viên, phòng học,
       học phần, sĩ số,...)
                       │
         ┌─────────────┴─────────────┐
         │                           │
         ▼                         	 ▼
     Không hợp lệ              	  Hợp lệ
         │                           │
         ▼                           ▼
   Thông báo lỗi               	Lưu dữ liệu
                                    │
                                    ▼
             				Mở lớp học phần
                                  	 │
                                     ▼
                        Sinh viên đăng ký học phần

## 6. Phân tích dữ liệu
Module sử dụng các thực thể chính:
•	HOCPHAN: lưu thông tin học phần. 
•	GIANGVIEN: lưu thông tin giảng viên. 
•	HOCKY: lưu thông tin học kỳ. 
•	LOPHOCPHAN: lưu thông tin lớp học phần được mở. 
•	HOCPHAN_TIENQUYET: quản lý quan hệ tiên quyết giữa các học phần. 
•	CHUONGTRINHDAOTAO (nếu phạm vi hệ thống có quản lý CTĐT): quản lý chương trình đào tạo của từng ngành.
