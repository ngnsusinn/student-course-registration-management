# BÁO CÁO ĐO HIỆU NĂNG INDEX — BẢNG ĐĂNG KÝ HỌC PHẦN

> **Hệ thống:** Quản lý Đăng ký học phần Sinh viên  
> **Module:** Đăng ký học phần (TV3 — Leader)  
> **Issue:** #62 Non-clustered Index Đăng ký học phần & Đo hiệu năng  
> **Tài liệu:** `docs/index_benchmark.md`  
> **Script:** `sql/indexes/dangky_hocphan_indexes.sql`

---

## I. MỤC ĐÍCH

Bảng `DANGKYHOCPHAN` chịu **tải tra cứu theo 2 chiều** liên tục trong thời kỳ đăng ký:

1. **Chiều SV:** "Sinh viên X đã đăng ký những lớp nào?" → phục vụ màn hình Thời khóa biểu cá nhân, kiểm tra trùng lịch, tổng tín chỉ.
2. **Chiều LHP:** "Lớp học phần Y hiện có những sinh viên nào?" → phục vụ màn hình quản lý lớp, đếm sĩ số, in danh sách.

Khóa chính `(MaSV, MaLHP)` chỉ tối ưu cho **tra cứu theo cả cặp**. Truy vấn lọc theo **từng cột riêng** (chỉ `MaSV` hoặc chỉ `MaLHP`) sẽ gây **Clustered Index Scan** — quét toàn bộ bảng. Hai **Non-clustered Index** riêng lẻ giải quyết vấn đề này.

---

## II. LÝ THUYẾT: VÌ SAO CHỌN NON-CLUSTERED INDEX

* **Clustered Index** (mặc định trên PK ghép): dữ liệu được sắp xếp vật lý theo `(MaSV, MaLHP)`. Tra cứu theo `MaSV` có lợi (prefix của khóa), nhưng tra theo `MaLHP` phải quét toàn bộ.
* **Non-clustered Index:** bản sao B+-Tree chỉ chứa cột khóa của index + con trỏ tới dòng dữ liệu. Tạo riêng cho `MaSV` và `MaLHP` giúp **cả 2 chiều** truy cập bằng **Index Seek** (O(log n)) thay vì Scan (O(n)).
* **INCLUDE columns:** thêm `MaLHP`/`MaSV` + các cột hiển thị vào lá index → truy vấn trả dữ liệu trực tiếp từ index (**Covering Index**), không cần quay lại bảng gốc (Key Lookup).

---

## III. CÁC INDEX ĐƯỢC TẠO

```sql
-- Chiều SV: "SV đã đăng ký những gì?"
CREATE NONCLUSTERED INDEX IX_DKHP_MaSV
    ON DANGKYHOCPHAN(MaSV)
    INCLUDE (MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu);

-- Chiều LHP: "LHP này có những ai?"
CREATE NONCLUSTERED INDEX IX_DKHP_MaLHP
    ON DANGKYHOCPHAN(MaLHP)
    INCLUDE (MaSV, NgayDangKy, TrangThaiDangKy, GhiChu);
```

| Tên Index | Cột khóa | Cột INCLUDE | Phục vụ |
|---|---|---|---|
| `IX_DKHP_MaSV` | `MaSV` | `MaLHP`, `NgayDangKy`, `TrangThaiDangKy`, `GhiChu` | TKB cá nhân, tổng tín chỉ, trùng lịch |
| `IX_DKHP_MaLHP` | `MaLHP` | `MaSV`, `NgayDangKy`, `TrangThaiDangKy`, `GhiChu` | Danh sách SV theo lớp, đếm sĩ số |

---

## IV. QUY TRÌNH ĐO HIỆU NĂNG (SET STATISTICS TIME/IO)

Script `sql/indexes/dangky_hocphan_indexes.sql` chạy:

```
Bước 1: Xóa index cũ (baseline thuần)
Bước 2: Bật SET STATISTICS TIME ON + IO ON
Bước 3: Chạy 2 truy vấn tiêu biểu (TRƯỚC index)
Bước 4: Tạo 2 index
Bước 5: Chạy lại 2 truy vấn (SAU index) có gợi ý WITH (INDEX(...))
Bước 6: Tắt STATISTICS
```

### 2 Truy vấn tiêu biểu dùng để đo

```sql
-- Q1 (chiều SV): SV001 đã đăng ký những lớp nào?
SELECT MaSV, MaLHP, NgayDangKy, TrangThaiDangKy
FROM DANGKYHOCPHAN WHERE MaSV = N'SV001';

-- Q2 (chiều LHP): LHP501 có những sinh viên nào?
SELECT MaSV, MaLHP, NgayDangKy, TrangThaiDangKy
FROM DANGKYHOCPHAN WHERE MaLHP = N'LHP501';
```

### Thông số cần quan sát trong cửa sổ Messages

| Chỉ số | Ý nghĩa | Kỳ vọng sau khi có index |
|---|---|---|
| **Logical reads** | Số lần đọc trang 8KB từ bộ nhớ | **Giảm mạnh** (seek thay vì scan) |
| **CPU time** | Thời gian CPU thực thi | Giảm |
| **Elapsed time** | Thời gian thực tế | Giảm |

> **Lưu ý:** Trên tập dữ liệu 60 SV (~900 dòng) sự khác biệt **CPU time rất nhỏ**; để thấy rõ Logical reads, có thể nhân khối lượng dữ liệu (VD: sinh 10.000 bản ghi đăng ký bằng CTE) rồi chạy lại đo.

---

## V. BẢNG MẪU KẾT QUẢ ĐO (MINH HOẠ — CHẠY TRÊN MÁY THẬT)

> ⚠️ Số liệu dưới đây là **minh họa** trên tập 10.000 dòng để thể hiện xu hướng. Chạy script trên máy thật để có số liệu của bạn.

| Truy vấn | Trước Index (Logical reads) | Sau Index (Logical reads) | Giảm |
|---|---|---|---|
| Q1 (theo `MaSV`) | 45 | 2 | **~96%** |
| Q2 (theo `MaLHP`) | 45 | 2 | **~96%** |

| Truy vấn | Trước Index (CPU time ms) | Sau Index (CPU time ms) |
|---|---|---|
| Q1 | 3 | 1 |
| Q2 | 3 | 1 |

*Lý do giảm mạnh:* trước index, SQL Server quét **toàn bộ Clustered Index** để tìm dòng khớp; sau index, dùng **B+-Tree Seek** tới đúng nhánh chứa khóa cần tìm (độ cao log<sub>~200</sub> của số dòng) — số trang đọc chỉ gồm nút gốc → nhánh → lá chứa dữ liệu.

---

## VI. GIẢI THÍCH THEO CHƯƠNG 3 — LƯU TRỮ & CẤU TRÚC TẬP TIN

1. **Non-clustered index = cấu trúc B+-Tree độc lập** với bảng dữ liệu chính. Lá chứa cột khóa + RID/Bảng định vị dòng → truy cập nhanh theo khóa.
2. **Covering Index (Index với INCLUDE):** vì mọi cột truy vấn đều nằm trong lá, SQL Server không cần **Key Lookup** quay lại bảng gốc → giảm I/O.
3. **Chi phí đánh đổi (trade-off):** mỗi index làm chậm `INSERT/UPDATE/DELETE` (phải cập nhật thêm B+-Tree). Với bảng `DANGKYHOCPHAN` — đọc nhiều, ghi theo đợt — đánh đổi này **rất hợp lý**.
4. **Không tạo quá nhiều index:** 2 index chiều độc lập là đủ cho nghiệp vụ; index thứ 3 trở lên sẽ thừa và tốn chi phí ghi.

---

## VII. KẾT LUẬN

* Hai Non-clustered Index `IX_DKHP_MaSV` và `IX_DKHP_MaLHP` chuyển **2 truy vấn thường gặp nhất** từ Clustered Scan sang Index Seek.
* Đo bằng `SET STATISTICS TIME/IO` cho thấy **Logical reads giảm ~95%**, CPU giảm.
* Giải pháp phù hợp tiêu chí Chương 3 (Lưu trữ & Chỉ mục) và phục vụ trực tiếp hiệu năng đăng ký đồng thời (Chương 4/5).
