# CHUẨN HÓA 3NF — BẢNG ĐĂNG KÝ HỌC PHẦN

> **Hệ thống:** Quản lý Đăng ký học phần Sinh viên  
> **Module:** Đăng ký học phần (TV3 — Leader)  
> **Issue:** #17 Chuẩn hóa 3NF Đăng ký học phần  
> **Tài liệu:** `docs/normalization_dangky_hocphan.md`

---

## I. BẢNG GỐC (BAN ĐẦU) — DẠNG CHƯA CHUẨN HÓA

Giả định bảng đăng ký được thiết kế ngây thơ (Unnormalized) để lưu toàn bộ thông tin vào 1 bảng — gọi là `DANGKY`:

| MaSV | HoTenSV | MaLHP | TenLHP | TenMonHoc | SoTinChi | TenGV | NgayDangKy | TrangThaiDangKy | GhiChu |
|---|---|---|---|---|---|---|---|---|---|
| SV001 | Nguyễn Văn A | LHP01 | CSDL-01 | Cơ sở dữ liệu | 3 | Nguyễn Minh | 2026-01-05 | DA_DANG_KY | |
| SV001 | Nguyễn Văn A | LHP02 | OOP-01 | Lập trình HĐT | 3 | Trần Lan | 2026-01-05 | DA_DANG_KY | |
| SV002 | Trần Thị B | LHP01 | CSDL-01 | Cơ sở dữ liệu | 3 | Nguyễn Minh | 2026-01-06 | DA_DANG_KY | |

---

## II. PHÁT HIỆN PHỤ THUỘC HÀM (FUNCTIONAL DEPENDENCIES)

Trong lược đồ thô trên tồn tại các phụ thuộc hàm sau:

1. `MaSV → HoTenSV`
2. `MaLHP → TenLHP, TenMonHoc, SoTinChi, TenGV`
3. `MaMonHoc → TenMonHoc, SoTinChi` (ẩn qua `TenLHP` → `MaMonHoc`)
4. `MaGV → TenGV` (ẩn qua `TenLHP` → `MaGV`)
5. `(MaSV, MaLHP) → NgayDangKy, TrangThaiDangKy, GhiChu`

**Vấn đề:** Khóa chính hợp lý là `(MaSV, MaLHP)`, nhưng các thuộc tính `HoTenSV`, `TenLHP`, `TenMonHoc`, `SoTinChi`, `TenGV` chỉ phụ thuộc vào **một phần** khóa — gây **dư thừa dữ liệu** (redundancy) và các dị thường cập nhật (update / insert / delete anomalies).

### Ví dụ minh họa dư thừa:
* `SoTinChi` của "Cơ sở dữ liệu" bị lặp lại ở mỗi dòng đăng ký — nếu đổi số tín chỉ môn học, phải cập nhật mọi dòng.
* Nếu `SV002` xóa đăng ký `LHP01`, thông tin môn học của `LHP01` biến mất luôn (delete anomaly) — dù lớp học phần vẫn tồn tại.
* Không thể lưu 1 môn học chưa có SV đăng ký (insert anomaly).

---

## III. QUÁ TRÌNH CHUẨN HÓA

### Bước 1 — Đạt 1NF (Atomic Values)

Tách bảng thô thành các thuộc tính đơn trị; bỏ vùng lặp. Kết quả: mỗi ô chứa đúng 1 giá trị.

### Bước 2 — Đạt 2NF (Loại bỏ phụ thuộc bộ phận)

Tách các thuộc tính phụ thuộc từng phần khóa ra bảng riêng:

**Bảng chuẩn hóa 2NF:**
* `SINHVIEN(MaSV, HoTenSV)` — từ `MaSV → HoTenSV`
* `LOPHOCPHAN(MaLHP, TenLHP, MaMonHoc, MaGV)` — từ `MaLHP → TenLHP, ...`
* `MONHOC(MaMonHoc, TenMonHoc, SoTinChi)` — tách tiếp từ LOPHOCPHAN
* `GIANGVIEN(MaGV, TenGV)` — tách tiếp từ LOPHOCPHAN
* `DANGKYHOCPHAN(MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)` — giữ nguyên nhóm thuộc tính phụ thuộc đầy đủ khóa ghép

### Bước 3 — Đạt 3NF (Loại bỏ phụ thuộc bắc cầu)

Trong `LOPHOCPHAN(MaLHP, TenLHP, MaMonHoc, TenMonHoc, SoTinChi)` còn phụ thuộc bắc cầu:
* `MaLHP → MaMonHoc → TenMonHoc, SoTinChi`

Tách `TenMonHoc`, `SoTinChi` sang `MONHOC`. Kết quả cuối cùng:

```
DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)
    ├── MaSV ──► SINHVIEN
    └── MaLHP ──► LOPHOCPHAN ──► MONHOC
```

---

## IV. BẢNG TRUNG TÂM `DANGKYHOCPHAN` — ĐẠT 3NF

### Cấu trúc cuối cùng

| Tên Cột | Kiểu Dữ Liệu | Ràng Buộc | Mô Tả |
|---|---|---|---|
| `MaSV` | `VARCHAR(12)` | **PK, FK** → `SINHVIEN(MaSV)` | Mã sinh viên đăng ký |
| `MaLHP` | `VARCHAR(15)` | **PK, FK** → `LOPHOCPHAN(MaLHP)` | Mã lớp học phần |
| `NgayDangKy` | `DATETIME` | **NOT NULL**, `DEFAULT GETDATE()` | Thời điểm đăng ký |
| `TrangThaiDangKy` | `NVARCHAR(20)` | **NOT NULL**, `CHECK` 3 giá trị | Trạng thái bản ghi |
| `GhiChu` | `NVARCHAR(255)` | NULL | Ghi chú thêm |

### 1. Kiểm tra 1NF
* Mọi thuộc tính đều **đơn trị** — không chứa danh sách, không có vùng lặp. ✅

### 2. Kiểm tra 2NF
* Khóa chính là khóa **ghép** `(MaSV, MaLHP)`.
* 3 thuộc tính không khóa `NgayDangKy`, `TrangThaiDangKy`, `GhiChu` đều phụ thuộc **đầy đủ** vào toàn bộ khóa:
  * `(MaSV, MaLHP) → NgayDangKy`
  * `(MaSV, MaLHP) → TrangThaiDangKy`
  * `(MaSV, MaLHP) → GhiChu`
* Không tồn tại thuộc tính phụ thuộc vào chỉ `MaSV` hoặc chỉ `MaLHP`. ✅

### 3. Kiểm tra 3NF
* Không tồn tại phụ thuộc bắc cầu giữa các thuộc tính không khóa.
* `NgayDangKy`, `TrangThaiDangKy`, `GhiChu` không phụ thuộc lẫn nhau và chỉ phụ thuộc trực tiếp vào khóa `(MaSV, MaLHP)`. ✅

### 4. Điểm mấu chốt: **KHÔNG** lưu dữ liệu dư thừa

| Trường KHÔNG lưu | Lý do | Cách lấy khi cần |
|---|---|---|
| `TenSV`, `HoTenSV` | Phụ thuộc `MaSV` đơn lẻ (vi phạm 2NF) | `JOIN SINHVIEN` |
| `TenLHP`, `TenMonHoc` | Phụ thuộc `MaLHP`/`MaMonHoc` | `JOIN LOPHOCPHAN/MONHOC` |
| `SoTinChi` | Phụ thuộc `MaMonHoc` | `JOIN MONHOC` |
| `TenGV` | Phụ thuộc `MaGV` | `JOIN GIANGVIEN` |

> **Nguyên tắc:** `DANGKYHOCPHAN` chỉ lưu **cặp khóa + thuộc tính của chính giao dịch đăng ký**. Mọi thông tin miêu tả SV / LHP / Môn học / GV đều truy xuất qua `JOIN`. Nhờ vậy thay đổi tên môn, số tín chỉ, tên giảng viên... chỉ cần sửa **1 chỗ**, không ảnh hưởng dữ liệu đăng ký lịch sử.

---

## V. PHỤ THUỘC HÀM ĐẦY ĐỦ — BẢNG MINH CHỨNG

| Khoá / Phụ thuộc | Loại | Đạt / Không đạt |
|---|---|---|
| `(MaSV, MaLHP) → NgayDangKy` | Full dependency trên khóa ghép | 2NF ✅ |
| `(MaSV, MaLHP) → TrangThaiDangKy` | Full dependency trên khóa ghép | 2NF ✅ |
| `(MaSV, MaLHP) → GhiChu` | Full dependency trên khóa ghép | 2NF ✅ |
| Không có `A → B` trong đó `A` là tập con thực sự của khóa | Không phụ thuộc bộ phận | 2NF ✅ |
| Không có `X → Y` bắc cầu qua thuộc tính không khóa | Không phụ thuộc bắc cầu | 3NF ✅ |

**Kết luận: Bảng `DANGKYHOCPHAN` đạt chuẩn 3NF** — và thực tế cũng đạt **BCNF** vì mọi phụ thuộc hàm đều có vế trái chứa khóa.

---

## VI. ĐỐI CHIẾU VỚI THIẾT KẾ DDL

Script DDL chính thức (Issue #18 — `sql/ddl/10_dangky_hocphan_ddl.sql`) thực thi đúng thiết kế 3NF trên:

```sql
CREATE TABLE DANGKYHOCPHAN (
    MaSV                VARCHAR(12)     NOT NULL,
    MaLHP               VARCHAR(15)     NOT NULL,
    NgayDangKy          DATETIME        NOT NULL DEFAULT GETDATE(),
    TrangThaiDangKy     NVARCHAR(20)    NOT NULL DEFAULT N'DA_DANG_KY',
    GhiChu              NVARCHAR(255)   NULL,
    CONSTRAINT PK_DANGKYHOCPHAN PRIMARY KEY (MaSV, MaLHP),
    CONSTRAINT FK_DKHP_SINHVIEN FOREIGN KEY (MaSV) REFERENCES SINHVIEN(MaSV),
    CONSTRAINT FK_DKHP_LOPHOCPHAN FOREIGN KEY (MaLHP) REFERENCES LOPHOCPHAN(MaLHP),
    CONSTRAINT CK_DKHP_TrangThaiDangKy CHECK (
        TrangThaiDangKy IN (N'DA_DANG_KY', N'DA_HUY', N'CHO_XAC_NHAN'))
);
```

---

## VII. KẾT LUẬN

1. Quá trình chuẩn hóa đã **loại bỏ hoàn toàn dư thừa** dữ liệu khỏi bảng trung tâm.
2. Bảng `DANGKYHOCPHAN` đạt **1NF, 2NF, 3NF** (và BCNF), là nền tảng vững chắc cho:
   * Các SP/Function kiểm tra 5 ràng buộc đăng ký (Issue #50, #51).
   * Transaction đảm bảo ACID (Issue #72).
   * Trigger tự động cập nhật sĩ số (Issue #61).
3. Thiết kế 1 bảng trung tâm "mỏng" nhưng kết nối rộng đúng như vai trò **cầu nối nhiều–nhiều** giữa `SINHVIEN` và `LOPHOCPHAN` đã được phê duyệt ở Issue #6.
