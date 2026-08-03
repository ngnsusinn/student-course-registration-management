# QUY ƯỚC ĐẶT TÊN & CẤU TRÚC THƯ MỤC — ĐỀ TÀI 6

> **Hệ thống:** Quản lý Đăng ký học phần Sinh viên  
> **Module trung tâm:** Đăng ký học phần (TV3 — Leader)  
> **Tài liệu:** `docs/conventions.md`  
> **Áp dụng:** Toàn bộ thành viên nhóm (TV1 → TV5) khi bàn giao sản phẩm lên GitHub

---

## I. TỔNG QUAN CẤU TRÚC THƯ MỤC GIT

```
student-course-registration-management/
├── docs/                          # Tài liệu thiết kế & báo cáo phân tích
│   ├── analysis_*.md              # Đặc tả nghiệp vụ từng module
│   ├── erd_*.md                   # Sơ đồ ERD từng module (mermaid)
│   ├── normalization_*.md         # Chứng minh chuẩn hóa 3NF
│   ├── isolation_level_analysis.md # [TV3] Phân tích mức cô lập (Chương 5)
│   ├── index_benchmark.md         # [TV3] Báo cáo đo hiệu năng Index (Chương 3)
│   ├── deadlock_analysis.md       # [TV3] Phân tích Deadlock toàn hệ thống
│   └── concurrency_demo/          # Ảnh/video minh chứng test 2 session
├── sql/                           # Toàn bộ script SQL Server (T-SQL)
│   ├── init_database.sql          # [TV3] Script tổng: CREATE DB → DDL → DATA
│   ├── ddl/                       # Script tạo bảng (CREATE TABLE)
│   │   ├── 00_*.sql               # Bảng nền (danh mục)
│   │   └── 10_dangky_hocphan_ddl.sql
│   ├── data/                      # Dữ liệu mẫu (INSERT)
│   ├── queries/                   # Truy vấn & View (SELECT / CREATE VIEW)
│   ├── procedures/                # Stored Procedure & Function
│   ├── triggers/                  # Trigger
│   ├── indexes/                   # CREATE INDEX + câu lệnh đo hiệu năng
│   ├── transactions/              # BEGIN TRAN / COMMIT / ROLLBACK + test
│   ├── security/                  # GRANT / REVOKE
│   └── backup/                    # BACKUP / RESTORE
├── web/
│   ├── app/                       # Mã nguồn ứng dụng
│   │   ├── dangky_hocphan/        # [TV3] Màn hình đăng ký học phần
│   │   └── shared/                # [TV3] Template UI chung cho cả nhóm
│   ├── css/                       # Stylesheet dùng chung
│   ├── js/                        # JavaScript dùng chung
│   └── index.html                 # Trang chủ / landing
├── report/                        # Báo cáo Word tổng hợp (.docx)
├── slides/                        # Slide thuyết trình (.pptx)
└── README.md
```

---

## II. QUY ƯỚC ĐẶT TÊN (NAMING CONVENTION)

### 1. Bảng (Table)
* **Chữ HOA, không dấu, gạch chân** giữa các từ: `DANGKYHOCPHAN`, `LOPHOCPHAN`, `SINHVIEN`.
* Số nhiều tránh dùng: `KETQUAHOCTAP` thay vì `KETQUAS`.

### 2. Cột (Column)
* **PascalCase không dấu**, mô tả rõ ràng: `MaSV`, `MaLHP`, `NgayDangKy`, `TrangThaiDangKy`, `GhiChu`.
* Cột tham chiếu khóa ngoại **giữ nguyên tên** ở bảng cha lẫn bảng con (VD: `MaSV`).

### 3. Khóa chính / Khóa ngoại / Check / Default
| Loại | Quy ước | Ví dụ |
|---|---|---|
| Primary Key | `PK_<TEN_BANG>` | `PK_DANGKYHOCPHAN` |
| Foreign Key | `FK_<BANG_CON>_<BANG_CHA>` | `FK_DKHP_SINHVIEN` |
| Check | `CK_<BANG>_<Cot>` | `CK_DKHP_TrangThai` |
| Default | `DF_<BANG>_<Cot>` | `DF_DKHP_NgayDangKy` |
| Unique | `UQ_<BANG>_<Cot>` | `UQ_TAIKHOAN_TenDangNhap` |

### 4. Index
* **Primary/Unique:** do hệ thống tạo — không đặt tên riêng.
* **Non-clustered Index:** `IX_<BANG>_<Cot>` hoặc `IX_<BANG>_<Cot1>_<Cot2>` (composite).
  * `IX_DKHP_MaSV` trên `DANGKYHOCPHAN(MaSV)`
  * `IX_DKHP_MaLHP` trên `DANGKYHOCPHAN(MaLHP)`

### 5. Stored Procedure
* Tiền tố `SP_` + tên hành động + đối tượng: `SP_DangKyHocPhan`, `SP_HuyDangKy`, `SP_TinhHocPhi`.

### 6. Function
* Tiền tố `FN_` hoặc `fn_`: `FN_KiemTraTienQuyet`, `FN_KiemTraTrungLichHoc`, `FN_TinhDiemTongKet`.

### 7. Trigger
* Tiền tố `TRG_` + tên bảng + thời điểm + hành động: `TRG_DANGKYHOCPHAN_AFTER_INSERT`, `TRG_DANGKYHOCPHAN_AFTER_DELETE`.

### 8. View
* Tiền tố `VW_` + mô tả: `VW_SinhVienDangHoc`, `VW_ThoiKhoaBieuCaNhan`.

---

## III. QUY ƯỚC CODE T-SQL

1. **Bắt buộc kết thúc mỗi batch bằng `GO`** (khi chạy qua SSMS / sqlcmd).
2. Mỗi đối tượng (SP / Function / Trigger) được **bọc trong `IF OBJECT_ID(...) IS NOT NULL DROP ...`** để script chạy lặp lại được (idempotent).
3. **Dùng `TRY...CATCH`** trong Transaction, `ROLLBACK` đầy đủ trong `CATCH`, không quên `COMMIT` trong `TRY`.
4. **Comment tiếng Việt không dấu hoặc có dấu** tùy màn hình, ghi rõ module + Issue number tương ứng ở header mỗi file.
5. Header file chuẩn:

```sql
-- ==========================================================
-- Tên file : <path>
-- Module   : Đăng ký học phần (TV3)
-- Issue    : #<number> <title>
-- Mô tả    : <ngắn gọn>
-- ==========================================================
```

---

## IV. QUY ƯỚC COMMIT MESSAGE & BRANCH

### 1. Commit message
```
[TV3][Module-3] Mô tả ngắn gọn thay đổi
```
* Ví dụ: `[TV3][Module-3] Add DDL for DANGKYHOCPHAN table (#18)`

### 2. Branch
```
feature/<module>-<mo_ta>
```
* Ví dụ: `feature/dang-ky-ddl` , `feature/dang-ky-sp`

### 3. Quy trình
1. Tạo branch từ `dev`.
2. Hoàn thành → tạo **Pull Request** về `dev`.
3. Mọi PR do **TV3 (Leader)** review.
4. Cuối tuần: TV3 merge `dev` → `main`.

---

## V. BẢNG ĐỐI CHIẾU ISSUE ↔ FILE BÀN GIAO (TV3)

| # | Issue | File bàn giao |
|---|---|---|
| 17 | Chuẩn hóa 3NF | `docs/normalization_dangky_hocphan.md` |
| 18 | Viết DDL | `sql/ddl/10_dangky_hocphan_ddl.sql` |
| 19 | Dữ liệu mẫu | `sql/data/dangky_hocphan_data.sql` |
| 49 | Truy vấn & View | `sql/queries/dangky_hocphan_queries.sql` |
| 50 | SP DangKyHocPhan | `sql/procedures/SP_DangKyHocPhan.sql` |
| 51 | SP HuyDangKy + Function | `sql/procedures/FN_KiemTra_DangKy.sql` + `sql/procedures/SP_HuyDangKy.sql` |
| 61 | Trigger sĩ số | `sql/triggers/TRG_DANGKYHOCPHAN_SiSo.sql` + `docs/trigger_integration_test.md` |
| 62 | Index + đo hiệu năng | `sql/indexes/dangky_hocphan_indexes.sql` + `docs/index_benchmark.md` |
| 72 | Transaction đăng ký | `sql/transactions/dangky_hocphan_tran.sql` |
| 73 | Mức cô lập | `docs/isolation_level_analysis.md` |
| 74 | Test 2 session | `sql/transactions/concurrency_test.sql` + `docs/concurrency_demo/` |
| — | Deadlock (bổ sung) | `docs/deadlock_analysis.md` |
| — | Khởi tạo DB | `sql/init_database.sql` |
| — | Giao diện (Web) | `web/` (4 màn hình + template chung) |
