# QUY ƯỚC ĐẶT TÊN & CẤU TRÚC THƯ MỤC — ĐỀ TÀI 6

> **Hệ thống:** Quản lý Đăng ký học phần Sinh viên  
> **Module trung tâm:** Đăng ký học phần (TV3 — Leader)  
> **Tài liệu:** `docs/conventions.md`  
> **Áp dụng:** Toàn bộ thành viên nhóm (TV1 → TV5) khi bàn giao sản phẩm lên GitHub

---

## I. TỔNG QUAN CẤU TRÚC THƯ MỤC GIT

> 📌 **Cập nhật (tái cấu trúc MVC):** `backend/src` được chia thành 4 lớp **routes → controllers → models (+ services)**;
> toàn bộ tài liệu `docs/` được phân loại theo chủ đề; bộ script gốc `sql/` (T-SQL SQL Server) **đã gỡ bỏ** — chỉ giữ bản
> **MySQL** trong `mysql/` (nguồn duy nhất, đang chạy trên hosting).

```
student-course-registration-management/
├── docs/                          # 📚 Tài liệu — phân loại theo chủ đề
│   ├── README.md                  #   Mục lục tài liệu
│   ├── conventions.md             #   Quy ước đặt tên & cấu trúc (file này)
│   ├── analysis/                  #   Đặc tả & phân tích nghiệp vụ 5 module (analysis_*.md)
│   ├── erd/                       #   Sơ đồ ERD từng module (mermaid) + So_Do_ERD.docx
│   ├── normalization/             #   Chứng minh chuẩn hóa 3NF từng module
│   ├── concurrency/               #   Giao tác · mức cô lập · deadlock · demo 4 lỗi
│   │   └── media/                 #   Ảnh/video minh chứng test 2 session
│   ├── performance/               #   Đo hiệu năng Index (index_benchmark.md)
│   ├── testing/                   #   Kiểm thử tích hợp (trigger_integration_test.md)
│   ├── planning/                  #   Backlog 7 tuần · bảng phân công nhóm
│   └── reference/                 #   Giáo trình & tài liệu tham khảo
│
├── mysql/                         # 🐬 Bản script MySQL (nguồn duy nhất — đang chạy)
│   ├── init_database.sql          #   Thứ tự chạy từng file (DDL → DATA → FN/SP/Trigger...)
│   ├── ddl/ · data/               #   CREATE TABLE (18 bảng) + dữ liệu mẫu
│   ├── functions/ · procedures/   #   Function & Stored Procedure
│   ├── triggers/ · views/         #   Trigger & View
│   ├── indexes/ · queries/        #   Index + truy vấn mẫu
│   ├── transactions/              #   Transaction & concurrency
│   └── security/                  #   Phân quyền 3 vai trò
│
├── backend/                       # ⚙️ Node.js + Express (MVC — REST API)
│   ├── server.js                  #   Entry: mount /api + phục vụ frontend/dist (VIEW)
│   ├── src/
│   │   ├── routes/                #   LỚP ROUTE — chỉ ánh xạ URL → controller
│   │   ├── controllers/           #   LỚP CONTROLLER — xử lý request/response, mã lỗi SP
│   │   ├── models/                #   LỚP MODEL — chỉ gọi VIEW/PROCEDURE qua db.js
│   │   ├── services/              #   Nghiệp vụ đặc thù (anomalyRunner.js — demo concurrency)
│   │   ├── middleware/auth.js     #   JWT sign/verify + requireRole
│   │   ├── db.js                  #   mysql2 pool + helper sp()/spMulti()/spOut()
│   │   └── config.js              #   Cấu hình DB pool, JWT, PORT
│   └── scripts/                   #   init-db · verify-db · test-api · e2e-test · audit…
│
└── frontend/                      # 🖥️ React 18 SPA (Vite + MUI) — VIEW của MVC
    └── src/
        ├── pages/                 #   Màn hình theo vai trò: sv/ · gv/ · pdt/
        ├── components/            #   PortalLayout, ProtectedRoute, dialog…
        ├── api/client.js          #   axios + JWT
        └── theme.js               #   Design system teal
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

## III. QUY ƯỚC CODE SQL (MySQL)

1. **Mỗi đối tượng (SP / Function / Trigger) được bọc trong `DROP ... IF EXISTS`** để script chạy lặp lại được (idempotent).
2. **Dùng `START TRANSACTION`/`COMMIT`/`ROLLBACK`** trong SP có nghiệp vụ nhiều bước; `ROLLBACK` đầy đủ trong `DECLARE EXIT HANDLER FOR SQLEXCEPTION`.
3. **Tầng web chỉ gọi View/Procedure/Function** (không raw query) — qua helper `sp()`/`spMulti()`/`spOut()` trong `backend/src/db.js`.
   Ngoại lệ có chủ đích duy nhất: `backend/src/services/anomalyRunner.js` (demo 4 lỗi concurrency phải chạy session SQL thô để "tắt phòng chống").
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

> Đường dẫn đã cập nhật theo cấu trúc mới: bản SQL Server cũ `sql/` đã thay bằng `mysql/`;
> tài liệu nằm trong các thư mục chủ đề của `docs/`.

| # | Issue | File bàn giao |
|---|---|---|
| 17 | Chuẩn hóa 3NF | `docs/normalization/normalization_dangky_hocphan.md` |
| 18 | Viết DDL | `mysql/ddl/10_dangky_hocphan_ddl.sql` |
| 19 | Dữ liệu mẫu | `mysql/data/dangky_hocphan_data.sql` |
| 49 | Truy vấn & View | `mysql/queries/dangky_hocphan_queries.sql` |
| 50 | SP DangKyHocPhan | `mysql/procedures/SP_DangKyHocPhan.sql` |
| 51 | SP HuyDangKy + Function | `mysql/functions/FN_KiemTra_DangKy.sql` + `mysql/procedures/SP_HuyDangKy.sql` |
| 61 | Trigger sĩ số | `mysql/triggers/TRG_DANGKYHOCPHAN_SiSo.sql` + `docs/testing/trigger_integration_test.md` |
| 62 | Index + đo hiệu năng | `mysql/indexes/all_indexes.sql` + `docs/performance/index_benchmark.md` |
| 72 | Transaction đăng ký | `mysql/transactions/dangky_hocphan_tran.sql` |
| 73 | Mức cô lập | `docs/concurrency/isolation_level_analysis.md` |
| 74 | Test 2 session | `mysql/transactions/concurrency_test.sql` + `docs/concurrency/media/` |
| — | Deadlock (bổ sung) | `docs/concurrency/deadlock_analysis.md` |
| — | Khởi tạo DB | `mysql/init_database.sql` |
| — | Giao diện (Web) | `frontend/` (React 18 SPA — 20 màn hình, Vite + MUI) |
