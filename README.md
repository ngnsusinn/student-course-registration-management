erDiagram
    KHOA ||--|{ NGANH : "quan_ly"
    NGANH ||--|{ CHUONGTRINHDAOTAO : "ban_hanh"
    NGANH ||--|{ LOP_SINHHOAT : "mo_lop"
    LOP_SINHHOAT ||--|{ SINHVIEN : "bao_gom"

    KHOA {
        VARCHAR_10 MaKhoa PK
        NVARCHAR_100 TenKhoa
        VARCHAR_15 DienThoai
        VARCHAR_100 EmailKhoa
    }

    NGANH {
        VARCHAR_10 MaNganh PK
        NVARCHAR_100 TenNganh
        DECIMAL ThoiGianDaoTao
        VARCHAR_10 MaKhoa FK
    }

    CHUONGTRINHDAOTAO {
        VARCHAR_10 MaCTDT PK
        NVARCHAR_100 TenCTDT
        INT NamApDung
        INT TongSoTinChi
        VARCHAR_10 MaNganh FK
    }

    LOP_SINHHOAT {
        VARCHAR_15 MaLop PK
        NVARCHAR_100 TenLop
        INT NienKhoa
        VARCHAR_10 MaNganh FK
    }

    SINHVIEN {
        VARCHAR_12 MaSV PK
        NVARCHAR_100 HoTen
        DATE NgaySinh
        TINYINT GioiTinh
        VARCHAR_100 Email
        VARCHAR_15 SoDienThoai
        TINYINT TrangThaiHoc
        VARCHAR_15 MaLop FK
