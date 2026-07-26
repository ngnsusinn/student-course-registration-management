erDiagram
    %% Định nghĩa các mối quan hệ (Relationships)
    KHOA ||--o{ NGANH : "quản lý"
    NGANH ||--o{ CHUONGTRINHDAOTAO : "ban hành"
    NGANH ||--o{ LOP_SINHHOAT : "bao gồm"
    LOP_SINHHOAT ||--o{ SINHVIEN : "tập hợp"

    %% Định nghĩa các thực thể và thuộc tính
    KHOA {
        VARCHAR MaKhoa PK 
        NVARCHAR TenKhoa
        VARCHAR DienThoaiKhoa
        VARCHAR EmailKhoa
    }

    NGANH {
        VARCHAR MaNganh PK 
        NVARCHAR TenNganh
        DECIMAL ThoiGianDaoTao
        VARCHAR MaKhoa FK 
    }

    CHUONGTRINHDAOTAO {
        VARCHAR MaCTDT PK 
        NVARCHAR TenCTDT
        INT NamApDung
        INT TongSoTinChi
        VARCHAR MaNganh FK 
    }

    LOP_SINHHOAT {
        VARCHAR MaLop PK 
        NVARCHAR TenLop
        INT NienKhoa
        VARCHAR MaNganh FK 
    }

    SINHVIEN {
        VARCHAR MaSV PK 
        NVARCHAR HoTen
        DATE NgaySinh
        TINYINT GioiTinh
        TINYINT TrangThaiHoc
        VARCHAR Email
        VARCHAR SoDienThoai
        NVARCHAR QueQuan
        VARCHAR MaLop FK 
    }
