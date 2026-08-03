# 🎓 Hệ thống Quản lý Sinh viên Đăng ký Học phần Tín chỉ

> **Đề tài 6 — Môn: Hệ Quản trị Cơ sở dữ liệu** | Nhóm 5 thành viên
> Module trung tâm: **Đăng ký học phần** (TV3 — Leader)

Hệ thống quản lý đăng ký học phần tín chỉ cho sinh viên, bao gồm **18 bảng dữ liệu** thuộc 5 module nghiệp vụ. Module **Đăng ký học phần** là nghiệp vụ lõi, nơi kiểm soát **5 ràng buộc** (hạn đăng ký, tiên quyết, trùng lịch, min-max tín chỉ, sĩ số lớp) và là điểm nhấn về **Giao dịch (ACID)** và **Điều khiển cạnh tranh** (Chương 4 & 5).

---

## 📂 Cấu trúc thư mục

```
├── docs/                # Tài liệu thiết kế & phân tích
├── sql/
│   ├── init_database.sql    # ⭐ Khởi tạo toàn bộ (CREATE DB → DDL → DATA)
│   ├── ddl/                 # CREATE TABLE (5 module, 18 bảng)
│   ├── data/                # Dữ liệu mẫu (60 SV, 5 học kỳ)
│   ├── queries/             # 7 truy vấn + 2 View
│   ├── procedures/          # 4 Function + SP_DangKyHocPhan + SP_HuyDangKy
│   ├── triggers/            # 3 Trigger tự cập nhật sĩ số
│   ├── indexes/             # Non-clustered Index + đo hiệu năng
│   ├── transactions/        # Transaction + kịch bản 2 session
│   ├── security/            # (trống — dành cho TV5)
│   └── backup/              # (trống — dành cho TV5)
└── web/                     # 4 màn hình đăng ký + template UI chung
```

---

## ✅ Đã hoàn thành (11 Issues TV3)

| Issue | Nội dung | Sản phẩm |
|---|---|---|
| #17 | Chuẩn hóa 3NF | `docs/normalization_dangky_hocphan.md` |
| #18 | DDL bảng trung tâm | `sql/ddl/10_dangky_hocphan_ddl.sql` |
| #19 | Dữ liệu mẫu (60 SV × 5 kỳ, tình huống biên) | `sql/data/dangky_hocphan_data.sql` |
| #49 | Truy vấn & View (≥6 SELECT) | `sql/queries/dangky_hocphan_queries.sql` |
| #50 | SP DangKyHocPhan (5 bước kiểm tra) | `sql/procedures/SP_DangKyHocPhan.sql` |
| #51 | SP HuyDangKy + 4 Function | `sql/procedures/FN_KiemTra_DangKy.sql`, `SP_HuyDangKy.sql` |
| #61 | Trigger tự cập nhật sĩ số | `sql/triggers/TRG_DANGKYHOCPHAN_SiSo.sql` |
| #62 | Non-clustered Index + đo hiệu năng | `sql/indexes/` + `docs/index_benchmark.md` |
| #72 | Transaction đăng ký (Atomicity) | `sql/transactions/dangky_hocphan_tran.sql` |
| #73 | Mức cô lập cho đăng ký | `docs/isolation_level_analysis.md` |
| #74 | Kịch bản test 2 session đồng thời | `sql/transactions/concurrency_test.sql` + `docs/concurrency_demo/` |

**Bổ sung:** `docs/deadlock_analysis.md` (phân tích deadlock toàn hệ thống), `docs/trigger_integration_test.md` (test trigger chain), `docs/conventions.md` (quy ước & cấu trúc thư mục).

---

## 🚀 Cách chạy

### 1. Khởi tạo Database (SQL Server)

Mở `sql/init_database.sql` trong **SSMS** và chạy (hoặc `sqlcmd -S .\SQLEXPRESS -i sql/init_database.sql`).

> Script sẽ: Tạo DB `DangKyHocPhan` → Tạo 18 bảng theo thứ tự phụ thuộc → Nạp dữ liệu mẫu → Tạo Index/SP/Trigger.

### 2. Demo giao diện (Web)

```bash
cd web
python -m http.server 8080
# mở http://localhost:8080
```

### 3. Kịch bản test concurrency (Issue #74)

1. Mở `sql/transactions/concurrency_test.sql` trong **2 cửa sổ SSMS**.
2. Cửa sổ 1: chạy **PHẦN A** (chuẩn bị) rồi **PHẦN B** (Phiên 1 — SV001).
3. Trong lúc Phiên 1 giữ khóa, cửa sổ 2 chạy **PHẦN C** (Phiên 2 — SV002) → bị chặn.
4. Chạy **PHẦN D** để xác nhận kết quả (sĩ số 25/25, SV002 bị từ chối mã 105).

Xem hướng dẫn chi tiết tại `docs/concurrency_demo/README.md`.

---

## 📚 Tài liệu chính

* `docs/analysis_dangky_hocphan.md` — Đặc tả 5 ràng buộc đăng ký + lưu đồ xử lý
* `docs/erd_dangky_hocphan.md` — ERD bảng trung tâm `DANGKYHOCPHAN` & liên kết hệ thống
* `docs/isolation_level_analysis.md` — Vì sao `READ COMMITTED` không đủ, chọn `UPDLOCK+HOLDLOCK`
* `docs/deadlock_analysis.md` — Deadlock & cách phòng tránh (Chương 5)
* `docs/index_benchmark.md` — Đo hiệu năng trước/sau Index (Chương 3)
* `docs/conventions.md` — Quy ước đặt tên & cấu trúc Git
