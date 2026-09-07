# 📚 TÀI LIỆU — Hệ thống Quản lý Đăng ký Học phần

> **Đề tài 6 — Môn: Hệ Quản trị Cơ sở dữ liệu** · Tài liệu thiết kế, phân tích & báo cáo của dự án.
> Source code (backend MVC, frontend React) và script database (mysql/) nằm riêng ở các thư mục gốc — thư mục này chỉ chứa **tài liệu**.
> Mục lục chi tiết của toàn bộ repo: [README.md](../README.md).

## Cấu trúc tài liệu

| Thư mục | Nội dung |
|---|---|
| [`analysis/`](analysis/) | Đặc tả & phân tích nghiệp vụ từng module (5 module) — `analysis_*.md`, `Ho_So_Sinh_Vien.md`, `module5-analysis.md` |
| [`erd/`](erd/) | Thiết kế ERD từng module (mermaid) + `So_Do_ERD.docx` (sơ đồ tổng thể) |
| [`normalization/`](normalization/) | Chứng minh chuẩn hóa **3NF** cho từng module |
| [`concurrency/`](concurrency/) | Giao tác & điều khiển cạnh tranh: mức cô lập, deadlock, **demo 4 lỗi concurrency**, kịch bản demo thật; `media/` lưu ảnh/video minh chứng |
| [`performance/`](performance/) | Đo hiệu năng Index (`index_benchmark.md`) |
| [`testing/`](testing/) | Kiểm thử tích hợp Trigger toàn hệ thống |
| [`planning/`](planning/) | Kế hoạch nhóm: Backlog 7 tuần · bảng phân công nhiệm vụ |
| [`reference/`](reference/) | Giáo trình & tài liệu tham khảo |
| [`conventions.md`](conventions.md) | Quy ước đặt tên & cấu trúc thư mục áp dụng cho toàn nhóm |

## Ghi chú tái cấu trúc

- Backend đã chuyển sang **chuẩn MVC** (`backend/src/routes → controllers → models (+ services)`).
- Tài liệu được tách khỏi source code và phân loại theo chủ đề như bảng trên.
- Bộ script **T-SQL (SQL Server)** cũ ở `sql/` đã gỡ bỏ; nguồn duy nhất hiện hành là **MySQL** trong `mysql/` (một số tên file được hợp nhất, VD toàn bộ index nằm ở `mysql/indexes/all_indexes.sql`).
