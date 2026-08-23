# 🎓 Hệ thống Quản lý Sinh viên Đăng ký Học phần Tín chỉ

> **Đề tài 6 — Môn: Hệ Quản trị Cơ sở dữ liệu** | Nhóm 5 thành viên
> Module trung tâm: **Đăng ký học phần** (TV3 — Leader)

Hệ thống quản lý đăng ký học phần tín chỉ cho sinh viên, bao gồm **18 bảng dữ liệu** thuộc 5 module nghiệp vụ. Module **Đăng ký học phần** là nghiệp vụ lõi, nơi kiểm soát **5 ràng buộc** (hạn đăng ký, tiên quyết, trùng lịch, min-max tín chỉ, sĩ số lớp) và là điểm nhấn về **Giao dịch (ACID)** và **Điều khiển cạnh tranh** (Chương 4 & 5).

> ✅ **Đã chuyển toàn bộ T-SQL → MySQL** (thư mục `mysql/`) và triển khai lên
> **MySQL remote** `free02.123host.vn` (DB `roacqgfa_dbms`).
> Backend **Node.js/Express** + Frontend **HTML/JS thuần** đã kết nối DB thật.

---

## 📂 Cấu trúc thư mục

```
├── docs/                    # Tài liệu thiết kế & phân tích (toàn bộ 5 module)
├── sql/                     # Bản gốc T-SQL (SQL Server)
│   ├── init_database.sql    # Khởi tạo toàn bộ (CREATE DB → DDL → DATA)
│   ├── ddl/ · data/ · queries/ · procedures/ · triggers/ · indexes/ · transactions/ · security/
│   └── ban_thao/            # Bản thảo T-SQL ban đầu (lưu trữ, không dùng chạy)
├── mysql/                   # ⭐ Bản dịch MySQL (chạy được trên hosting)
│   ├── init_database.sql    # Hướng dẫn khởi tạo (thứ tự chạy từng file)
│   ├── ddl/                 # CREATE TABLE (18 bảng)
│   ├── data/                # Dữ liệu mẫu (60 SV, 5 học kỳ, 794 lượt ĐK)
│   ├── functions/           # 8 Function (tiên quyết, trùng lịch, tín chỉ, điểm…)
│   ├── procedures/          # 12 Stored Procedure (ĐK, hủy, điểm, GPA, học phí…)
│   ├── triggers/            # 8 Trigger (sĩ số, điểm, trùng lịch, log, chặn xóa)
│   ├── views/               # 10 View báo cáo
│   ├── indexes/             # Index tối ưu tra cứu
│   ├── transactions/        # Transaction & concurrency (bản MySQL)
│   ├── queries/             # Truy vấn mẫu từng module (bản MySQL)
│   └── security/            # Phân quyền 3 vai trò (mẫu)
├── backend/                 # Node.js + Express + mysql2 (API REST + JWT)
│   ├── server.js            # Entry point (phục vụ cả web/)
│   ├── src/routes/          # auth, danhmuc, dangky, ketqua, hocphi, giangvien, admin
│   └── scripts/             # init-db, verify-db, test-api, e2e-test…
└── web/                     # Frontend (HTML/JS thuần, kết nối API thật)
    ├── login.html           # Đăng nhập (SV / GV / PĐT)
    ├── index.html           # Dashboard theo vai trò
    ├── app/dangky_hocphan/  # Đăng ký, TKB, danh sách ĐK, hủy ĐK (SV)
    ├── app/diem/            # Bảng điểm & GPA (SV)
    ├── app/hocphi/          # Học phí của tôi (SV)
    ├── app/giangvien/       # Lớp của tôi, nhập điểm, TKB (GV)
    ├── app/danhmuc/         # Quản lý SV, Khoa·Ngành·Lớp, CTĐT (PĐT)
    ├── app/hocphan/         # Môn học·GV·Phòng, Mở LHP (PĐT)
    └── app/admin/           # Dashboard, Tài khoản (PĐT)
```

---

## 🚀 Cách chạy (đã kết nối MySQL remote)

### 1. Khởi tạo Database (MySQL)

> Database `roacqgfa_dbms` trên `free02.123host.vn` đã có sẵn toàn bộ đối tượng.
> Nếu cần tạo lại từ đầu, chạy:

```bash
cd backend
node scripts/init-db.js     # đọc cấu hình trong backend/.env
```

Hoặc chạy lần lượt các file trong `mysql/` theo thứ tự ghi ở `mysql/init_database.sql`.

### 2. Chạy Backend + Frontend

```bash
cd backend
npm install
npm start                   # Backend: http://localhost:3000 (phục vụ luôn web/)
# Mở trình duyệt: http://localhost:3000  → tự động vào trang đăng nhập
```

### 3. Tài khoản demo

| Vai trò | Tên đăng nhập | Mật khẩu |
|---|---|---|
| Sinh viên | `sv001` | `matkhau@123` |
| Giảng viên | `gv001` | `matkhau@123` |
| Phòng Đào Tạo | `admin` | `admin@123` |

---

## 🔌 API chính (backend)

| Nhóm | Endpoint | Vai trò |
|---|---|---|
| Auth | `POST /api/auth/login` · `GET /api/auth/me` · `POST /api/auth/doimatkhau` | Tất cả |
| Đăng ký | `GET /api/dangky/lopmo` · `POST /api/dangky` · `POST /api/dangky/huy` | SV |
| Đăng ký | `GET /api/dangky/danhsach` · `thoikhoabieu` · `tongtinchi` | SV |
| Điểm | `GET /api/ketqua/bangdiem` · `gpa` · `cpa` · `canhbao-hocvu` | SV/PĐT |
| Học phí | `GET /api/hocphi/cua-toi` · `danhsach` · `baocao` · `POST thu/tinh` | SV/PĐT |
| Giảng viên | `GET /api/giangvien/lopcuatoi` · `sinhvien/:MaLHP` · `POST nhapdiem(-hangloat)` | GV |
| Danh mục | `GET/POST/PUT/DELETE /api/danhmuc/{khoa,nganh,lop,monhoc,giangvien,phonghoc,hocky,ctdt}` | PĐT |
| Admin | `GET /api/admin/thongke` · `lophocphan` · `taikhoan` · `POST themsinhvien/molophocphan` | PĐT |

Chi tiết test: `backend/scripts/test-api.js`, `test-crud.js`.

---

## 📚 Tài liệu chính

* `docs/analysis_dangky_hocphan.md` — Đặc tả 5 ràng buộc đăng ký + lưu đồ xử lý
* `docs/erd_dangky_hocphan.md` — ERD bảng trung tâm `DANGKYHOCPHAN`
* `docs/isolation_level_analysis.md` — Mức cô lập & khóa (UPDLOCK/HOLDLOCK → `FOR UPDATE`)
* `docs/deadlock_analysis.md` — Deadlock & cách phòng tránh (Chương 5)
* `docs/index_benchmark.md` — Đo hiệu năng trước/sau Index (Chương 3)
* `mysql/transactions/concurrency_test.sql` — Kịch bản test 2 session đồng thời (MySQL)
* `docs/conventions.md` — Quy ước đặt tên & cấu trúc Git

---

## ✅ Trạng thái hoàn thiện

- [x] Toàn bộ docs phân tích/ERD/chuẩn hóa 5 module
- [x] Chuyển toàn bộ T-SQL → MySQL (DDL, data, function, SP, trigger, view, index, transaction, query, security)
- [x] Khởi tạo & chạy trên MySQL remote (`free02.123host.vn`)
- [x] Backend Node.js/Express (REST + JWT, 7 nhóm route)
- [x] Frontend kết nối API thật (đăng nhập, đăng ký, điểm, học phí, GV, quản trị)
- [x] Trigger tự tính điểm / cập nhật sĩ số / chặn xóa ngành — đã kiểm thử
- [x] SP đăng ký kiểm tra 5 ràng buộc (mã lỗi 100–106) — đã kiểm thử
