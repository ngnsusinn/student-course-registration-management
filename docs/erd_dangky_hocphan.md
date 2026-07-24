# THIẾT KẾ ERD MODULE ĐĂNG KÝ HỌC PHẦN & LIÊN KẾT HỆ THỐNG

> **Hệ thống:** Quản lý Đăng ký học phần Sinh viên  
> **Module:** Đăng ký học phần (Nghiệp vụ lõi - Thành viên 3)  
> **Bảng trung tâm:** `DANGKYHOCPHAN`  
> **Tài liệu bàn giao:** `docs/erd_dangky_hocphan.md`  

---

## I. TỔNG QUAN VỀ THIẾT KẾ ERD BẢNG TRUNG TÂM

Bảng `DANGKYHOCPHAN` đóng vai trò là **cầu nối trung tâm (Junction/Bridge Table)** duy nhất kết nối quan hệ **Nhiều - Nhiều ($N:M$)** giữa hai thực thể cốt lõi của hệ thống quản lý đào tạo: **`SINHVIEN`** (Thực thể đăng ký) và **`LOPHOCPHAN`** (Thực thể được đăng ký).

Mặc dù Module 3 chỉ phụ trách trực tiếp 1 bảng dữ liệu, nhưng bảng này có các liên kết trực tiếp và gián tiếp tới toàn bộ **17 bảng còn lại** thuộc 4 module của hệ thống.

```
                  ┌─────────────────┐
                  │    SINHVIEN     │ (Module 1: Hồ sơ SV)
                  └────────┬────────┘
                           │ (1:N)
                           ▼
┌────────────────────────────────────────────────────────┐
│                    DANGKYHOCPHAN                       │ (Bảng trung tâm Module 3)
│  - PK ghép: (MaSV, MaLHP)                              │
│  - FK: MaSV ──► SINHVIEN(MaSV)                         │
│  - FK: MaLHP ──► LOPHOCPHAN(MaLHP)                     │
└──────────────────────────┬─────────────────────────────┘
                           ▲
                           │ (1:N)
                  ┌────────┴────────┐
                  │   LOPHOCPHAN    │ (Module 2: Học phần & Mở lớp)
                  └─────────────────┘
```

---

## II. SƠ ĐỒ ERD CHI TIẾT KẾT NỐI TOÀN HỆ THỐNG (MERMAID ER DIAGRAM)

Sơ đồ ERD dưới đây thể hiện vị trí trung tâm của bảng `DANGKYHOCPHAN` cùng toàn bộ khóa ngoại (FK) trực tiếp và các bảng phụ thuộc gián tiếp thuộc 5 module nghiệp vụ:

```mermaid
erDiagram
    %% ==========================================
    %% MODULE 1: DANH MỤC HỆ THỐNG & HỒ SƠ SV
    %% ==========================================
    KHOA {
        string MaKhoa PK
        string TenKhoa
    }

    NGANH {
        string MaNganh PK
        string TenNganh
        string MaKhoa FK
    }

    LOP_SINHHOAT {
        string MaLopSH PK
        string TenLopSH
        string MaNganh FK
    }

    SINHVIEN {
        string MaSV PK
        string HoTen
        date NgaySinh
        string GioiTinh
        string Email
        string SoDienThoai
        string TrangThaiHoc
        string MaLopSH FK
    }

    CHUONGTRINHDAOTAO {
        string MaNganh PK, FK
        string MaMonHoc PK, FK
        int HocKyDuKien
        boolean BatBuoc
    }

    %% ==========================================
    %% MODULE 2: HỌC PHẦN & MỞ LỚP HỌC PHẦN
    %% ==========================================
    MONHOC {
        string MaMonHoc PK
        string TenMonHoc
        int SoTinChi
        int SoTietLyThuyet
        int SoTietThucHanh
        string MaKhoa FK
    }

    MONHOC_TIENQUYET {
        string MaMonHoc PK, FK
        string MaMonTienQuyet PK, FK
    }

    HOCKY {
        string MaHocKy PK
        string TenHocKy
        string NamHoc
        date TuNgay
        date DenNgay
        string TrangThaiDot
    }

    GIANGVIEN {
        string MaGV PK
        string HoTen
        string Email
        string MaKhoa FK
    }

    PHONGHOC {
        string MaPhong PK
        string TenPhong
        int SucChua
    }

    LOPHOCPHAN {
        string MaLHP PK
        string TenLHP
        int SiSoToiDa
        int SiSoHienTai
        string TrangThaiLop
        string MaMonHoc FK
        string MaHocKy FK
        string MaGV FK
    }

    LICHHOC {
        string MaLichHoc PK
        string MaLHP FK
        string MaPhong FK
        int Thu
        int TietBatDau
        int SoTiet
    }

    %% ==========================================
    %% MODULE 3: ĐĂNG KÝ HỌC PHẦN (CENTER)
    %% ==========================================
    DANGKYHOCPHAN {
        string MaSV PK, FK
        string MaLHP PK, FK
        datetime NgayDangKy
        string TrangThaiDangKy
        string GhiChu
    }

    %% ==========================================
    %% MODULE 4: ĐIỂM SỐ & KẾT QUẢ HỌC TẬP
    %% ==========================================
    KETQUAHOCTAP {
        string MaSV PK, FK
        string MaLHP PK, FK
        float DiemChuyenCan
        float DiemGiuaKy
        float DiemCuoiKy
        float DiemTongKet
        float DiemHe4
        string DiemChu
    }

    THANGDIEMCHU {
        string DiemChu PK
        float TuDiemHe10
        float DenDiemHe10
        float DiemHe4
        string XepLoai
    }

    %% ==========================================
    %% MODULE 5: HỌC PHÍ & TÀI KHOẢN
    %% ==========================================
    HOCPHI {
        string MaHocPhi PK
        string MaSV FK
        string MaHocKy FK
        decimal TongTien
        decimal DaNop
        string TrangThaiHocPhi
    }

    VAITRO {
        string MaVaiTro PK
        string TenVaiTro
    }

    TAIKHOAN {
        string TenDangNhap PK
        string MatKhau
        string MaSV FK
        string MaGV FK
        string MaVaiTro FK
    }

    %% ==========================================
    %% RELATIONSHIPS
    %% ==========================================
    %% Module 1 internal
    KHOA ||--o{ NGANH : "thuoc"
    NGANH ||--o{ LOP_SINHHOAT : "co"
    LOP_SINHHOAT ||--o{ SINHVIEN : "chua"
    NGANH ||--o{ CHUONGTRINHDAOTAO : "quy_dinh"
    MONHOC ||--o{ CHUONGTRINHDAOTAO : "thuoc_ctdt"

    %% Module 2 internal
    KHOA ||--o{ MONHOC : "quan_ly_mon"
    KHOA ||--o{ GIANGVIEN : "quan_ly_gv"
    MONHOC ||--o{ MONHOC_TIENQUYET : "la_mon_chinh"
    MONHOC ||--o{ MONHOC_TIENQUYET : "la_mon_tien_quyet"
    MONHOC ||--o{ LOPHOCPHAN : "mo_thanh"
    HOCKY ||--o{ LOPHOCPHAN : "dien_ra_trong"
    GIANGVIEN ||--o{ LOPHOCPHAN : "phang_cong_giang_day"
    LOPHOCPHAN ||--o{ LICHHOC : "co_lich_hoc"
    PHONGHOC ||--o{ LICHHOC : "xep_tai"

    %% Module 3 DIRECT CONNECTIONS (Center Bridge)
    SINHVIEN ||--o{ DANGKYHOCPHAN : "thuc_hien_dang_ky"
    LOPHOCPHAN ||--o{ DANGKYHOCPHAN : "duoc_dang_ky"

    %% Module 4 DOWNSTREAM CONNECTION
    DANGKYHOCPHAN ||--o| KETQUAHOCTAP : "sinh_ra_ket_qua"
    THANGDIEMCHU ..o{ KETQUAHOCTAP : "quy_doi"

    %% Module 5 SYSTEM CONNECTIONS
    SINHVIEN ||--o{ HOCPHI : "phai_nong"
    HOCKY ||--o{ HOCPHI : "thuoc_ky"
    SINHVIEN ||--o| TAIKHOAN : "so_huu"
    GIANGVIEN ||--o| TAIKHOAN : "so_huu"
    VAITRO ||--o{ TAIKHOAN : "duoc_gan"
```

---

## III. ĐẶC TẢ CHI TIẾT BẢNG TRUNG TÂM `DANGKYHOCPHAN`

### 1. Structure & Attributes Specification

| Tên Cột | Kiểu Dữ Liệu | Ràng Buộc (Constraints) | Mô Tả Nghiệp Vụ |
|---|---|---|---|
| `MaSV` | `VARCHAR(10)` | **PK, FK** $\rightarrow$ `SINHVIEN(MaSV)` | Mã sinh viên thực hiện đăng ký |
| `MaLHP` | `VARCHAR(15)` | **PK, FK** $\rightarrow$ `LOPHOCPHAN(MaLHP)` | Mã lớp học phần được đăng ký |
| `NgayDangKy` | `DATETIME` | **NOT NULL**, `DEFAULT GETDATE()` | Thời điểm chính xác sinh viên nhấn xác nhận ĐK |
| `TrangThaiDangKy` | `NVARCHAR(20)` | **NOT NULL**, `CHECK IN ('DA_DANG_KY', 'DA_HUY', 'CHO_XAC_NHAN')` | Trạng thái của bản ghi đăng ký |
| `GhiChu` | `NVARCHAR(255)` | **NULL** | Ghi chú thêm (VD: "Đăng ký bổ sung", "Miễn giảm") |

* **Khóa chính (Primary Key):** Composite PK `(MaSV, MaLHP)`. Đảm bảo một sinh viên không thể tạo 2 bản ghi đăng ký cho cùng một lớp học phần.
* **Khóa ngoại 1 (FK 1):** `FK_DANGKYHOCPHAN_SINHVIEN` tham chiếu `SINHVIEN(MaSV)`.
* **Khóa ngoại 2 (FK 2):** `FK_DANGKYHOCPHAN_LOPHOCPHAN` tham chiếu `LOPHOCPHAN(MaLHP)`.

---

## IV. MA TRẬN KHÓA NGOẠI (FOREIGN KEY MAP) VÀ CHUỖI PHỤ THUỘC GIÁN TIẾP

Bảng `DANGKYHOCPHAN` kết nối trực tiếp với 2 thực thể cha, và thông qua 2 thực thể cha này để liên kết tới toàn bộ các bảng trong CSDL:

```
[KHOA] ◄─── [NGANH] ◄─── [LOP_SINHHOAT] ◄─── [SINHVIEN] ──┐
                                                           ├─► [DANGKYHOCPHAN] ──► [KETQUAHOCTAP]
[MONHOC] ◄─── [MONHOC_TIENQUYET]                           │
   ▲                                                       │
   ├─── [LOPHOCPHAN] ──────────────────────────────────────┘
   │       ▲             ▲
   │       │             │
[HOCKY] ───┘        [GIANGVIEN]
```

### 1. Liên kết Khóa ngoại Trực tiếp (Direct Foreign Keys)

| Tên Khóa Ngoại | Bảng Con (Child) | Cột Khóa Ngoại | Bảng Cha (Parent) | Cột Tham Chiếu | Quy Tắc Cascade (`ON DELETE / UPDATE`) |
|---|---|---|---|---|---|
| `FK_DKHP_SV` | `DANGKYHOCPHAN` | `MaSV` | `SINHVIEN` | `MaSV` | `ON DELETE NO ACTION`, `ON UPDATE CASCADE` |
| `FK_DKHP_LHP` | `DANGKYHOCPHAN` | `MaLHP` | `LOPHOCPHAN` | `MaLHP` | `ON DELETE NO ACTION`, `ON UPDATE CASCADE` |

* **Lý do dùng `ON DELETE NO ACTION` / `RESTRICT`:** Không cho phép xóa một Sinh viên hoặc xóa một Lớp học phần nếu đã phát sinh dữ liệu đăng ký học phần trong CSDL (bảo toàn lịch sử đào tạo).

---

### 2. Chuỗi Phụ thuộc Gián tiếp (Indirect Dependencies Map)

#### A. Chuỗi phụ thuộc từ hướng `SINHVIEN` (Upstream Parent Chain 1)

1. **`SINHVIEN` $\rightarrow$ `LOP_SINHHOAT`:**
   * Cột liên kết: `SINHVIEN.MaLopSH` $\rightarrow$ `LOP_SINHHOAT.MaLopSH`.
   * Ý nghĩa: Xác định lớp sinh hoạt chính quy của sinh viên.
2. **`LOP_SINHHOAT` $\rightarrow$ `NGANH`:**
   * Cột liên kết: `LOP_SINHHOAT.MaNganh` $\rightarrow$ `NGANH.MaNganh`.
   * Ý nghĩa: Xác định ngành học của lớp, phục vụ kiểm tra Chương trình đào tạo và Min-Max tín chỉ theo ngành.
3. **`NGANH` $\rightarrow$ `KHOA`:**
   * Cột liên kết: `NGANH.MaKhoa` $\rightarrow$ `KHOA.MaKhoa`.
   * Ý nghĩa: Quản lý cấp Khoa chuyên môn sở hữu ngành.

#### B. Chuỗi phụ thuộc từ hướng `LOPHOCPHAN` (Upstream Parent Chain 2)

1. **`LOPHOCPHAN` $\rightarrow$ `MONHOC`:**
   * Cột liên kết: `LOPHOCPHAN.MaMonHoc` $\rightarrow$ `MONHOC.MaMonHoc`.
   * Ý nghĩa: Lấy thông tin Tên môn học, Số tín chỉ (`SoTinChi`), Số tiết lý thuyết/thực hành để kiểm tra giới hạn tín chỉ.
2. **`MONHOC` $\rightarrow$ `MONHOC_TIENQUYET`:**
   * Cột liên kết: `MONHOC.MaMonHoc` $\rightarrow$ `MONHOC_TIENQUYET.MaMonHoc`.
   * Ý nghĩa: Truy xuất danh sách môn tiên quyết để kiểm tra Ràng buộc 3 (Môn tiên quyết).
3. **`LOPHOCPHAN` $\rightarrow$ `HOCKY`:**
   * Cột liên kết: `LOPHOCPHAN.MaHocKy` $\rightarrow$ `HOCKY.MaHocKy`.
   * Ý nghĩa: Xác định học kỳ diễn ra lớp học phần và khoảng thời gian mở đợt đăng ký (Ràng buộc 1).
4. **`LOPHOCPHAN` $\rightarrow$ `GIANGVIEN`:**
   * Cột liên kết: `LOPHOCPHAN.MaGV` $\rightarrow$ `GIANGVIEN.MaGV`.
   * Ý nghĩa: Phân công giảng viên giảng dạy lớp học phần.
5. **`LOPHOCPHAN` $\rightarrow$ `LICHHOC` $\rightarrow$ `PHONGHOC`:**
   * Cột liên kết: `LICHHOC.MaLHP` $\rightarrow$ `LOPHOCPHAN.MaLHP` và `LICHHOC.MaPhong` $\rightarrow$ `PHONGHOC.MaPhong`.
   * Ý nghĩa: Truy xuất Thời khóa biểu (Thứ, Tiết, Phòng) để kiểm tra Ràng buộc 4 (Trùng lịch học).

#### C. Chuỗi phụ thuộc Xuôi dòng (Downstream Dependent Tables)

1. **`DANGKYHOCPHAN` $\rightarrow$ `KETQUAHOCTAP`:**
   * Khóa ngoại ghép: `KETQUAHOCTAP.(MaSV, MaLHP)` $\rightarrow$ `DANGKYHOCPHAN.(MaSV, MaLHP)`.
   * Quy tắc Cascade: `ON DELETE CASCADE` (Nếu hủy bản ghi đăng ký thì tự động hủy dòng kết quả học tập tương ứng chưa nhập điểm).
2. **`DANGKYHOCPHAN` $\rightarrow$ `HOCPHI`:**
   * Liên kết logic qua `(MaSV, MaHocKy)`: Tổng số tín chỉ sinh viên đăng ký thành công trong `DANGKYHOCPHAN` của học kỳ sẽ là căn cứ để Procedure tính tiền tự động ghi nhận vào bảng `HOCPHI`.

---

## V. PHÂN TÍCH CHUẨN HÓA DỮ LIỆU BẢNG `DANGKYHOCPHAN` (3NF PROOF)

Để chứng minh thiết kế bảng `DANGKYHOCPHAN` đạt Chuẩn 3 (3NF) và không dư thừa dữ liệu:

### 1. Đạt chuẩn 1NF (First Normal Form)
* Mỗi thuộc tính trong bảng (`MaSV`, `MaLHP`, `NgayDangKy`, `TrangThaiDangKy`, `GhiChu`) đều chứa các giá trị đơn (Atomic Values), không chứa danh sách hay mảng lặp lại.

### 2. Đạt chuẩn 2NF (Second Normal Form)
* Khóa chính của bảng là khóa ghép $(MaSV, MaLHP)$.
* Tất cả các thuộc tính không phải khóa (`NgayDangKy`, `TrangThaiDangKy`, `GhiChu`) đều **phụ thuộc đầy đủ** vào toàn bộ khóa ghép $(MaSV, MaLHP)$, không phụ thuộc vào một phần khóa chính.
* **Thiết kế tối ưu (Không dư thừa):** Tuyệt đối **không lưu** các cột như `TenSV`, `TenLHP`, `SoTinChi`, `TenMonHoc` trong bảng `DANGKYHOCPHAN`. Các thông tin này chỉ phụ thuộc vào `MaSV` hoặc `MaLHP` riêng lẻ, nếu lưu lại sẽ vi phạm 2NF. Khi cần hiển thị, hệ thống sẽ dùng câu lệnh `JOIN`.

### 3. Đạt chuẩn 3NF (Third Normal Form)
* Không tồn tại phụ thuộc bắc cầu (Transitive Dependency) giữa các thuộc tính không phải khóa.
* Mọi thuộc tính không phải khóa đều phụ thuộc trực tiếp và duy nhất vào khóa chính $(MaSV, MaLHP)$.

---

## VI. SCRIPT DDL TẠO BẢNG TRUNG TÂM `DANGKYHOCPHAN`

```sql
-- ========================================================
-- DDL SCRIPT: CREATING TABLE DANGKYHOCPHAN
-- Module: Đăng ký học phần (Nghiệp vụ lõi)
-- ========================================================

CREATE TABLE DANGKYHOCPHAN (
    MaSV              VARCHAR(10)     NOT NULL,
    MaLHP             VARCHAR(15)     NOT NULL,
    NgayDangKy        DATETIME        NOT NULL DEFAULT GETDATE(),
    TrangThaiDangKy   NVARCHAR(20)    NOT NULL DEFAULT N'DA_DANG_KY',
    GhiChu            NVARCHAR(255)   NULL,

    -- Primary Key Constraint (Composite PK)
    CONSTRAINT PK_DANGKYHOCPHAN PRIMARY KEY (MaSV, MaLHP),

    -- Foreign Key Constraints
    CONSTRAINT FK_DKHP_SINHVIEN FOREIGN KEY (MaSV) 
        REFERENCES SINHVIEN(MaSV)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,

    CONSTRAINT FK_DKHP_LOPHOCPHAN FOREIGN KEY (MaLHP) 
        REFERENCES LOPHOCPHAN(MaLHP)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,

    -- Check Constraint for Registration Status
    CONSTRAINT CK_DKHP_TrangThai CHECK (TrangThaiDangKy IN (N'DA_DANG_KY', N'DA_HUY', N'CHO_XAC_NHAN'))
);
GO

-- Non-Clustered Indexes for High-Speed Querying (Requirement for Module 3 & 8)
CREATE NONCLUSTERED INDEX IX_DKHP_MaSV ON DANGKYHOCPHAN(MaSV);
CREATE NONCLUSTERED INDEX IX_DKHP_MaLHP ON DANGKYHOCPHAN(MaLHP);
GO
```

---

## VII. KẾT LUẬN

Sơ đồ ERD và đặc tả bảng `DANGKYHOCPHAN` trên đây khẳng định:
1. Vị trí trung tâm kết nối toàn bộ hệ thống quản lý đào tạo tín chỉ.
2. Thiết kế đạt chuẩn **3NF**, hoàn toàn không dư thừa dữ liệu.
3. Ma trận khóa ngoại thể hiện rõ mối liên kết từ bảng trung tâm đến cả **17 bảng còn lại**, phục vụ trực tiếp cho việc kiểm tra 5 ràng buộc đăng ký và viết Stored Procedure / Trigger giao dịch ở các bước tiếp theo.
