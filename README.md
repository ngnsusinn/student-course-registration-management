# 🎓 Hệ thống Quản lý Sinh viên Đăng ký Học phần Tín chỉ

> **Đề tài 6 — Môn: Hệ Quản trị Cơ sở dữ liệu** | Nhóm 5 thành viên
> **Nền tảng:** MySQL (remote hosting) · Node.js/Express · HTML/CSS/JavaScript thuần

Hệ thống quản lý toàn bộ vòng đời đào tạo tín chỉ: **hồ sơ sinh viên → mở lớp học phần → đăng ký → nhập điểm → tính GPA → học phí**, được xây dựng theo đúng quy trình môn học (phân tích → ERD → chuẩn hóa 3NF → DDL → truy vấn/View → Stored Procedure/Function/Trigger → Index → Transaction/Concurrency → giao diện).

📌 **Module trung tâm — Đăng ký học phần (TV3 – Leader):** nghiệp vụ lõi kiểm soát **5 ràng buộc đăng ký** (hạn đăng ký, môn tiên quyết, trùng lịch, min–max tín chỉ, sĩ số lớp) và là điểm nhấn về **Giao dịch (ACID)** + **Điều khiển cạnh tranh (Concurrency Control)**.

✅ **Đã chuyển toàn bộ T-SQL → MySQL** và triển khai lên **MySQL remote** (`free02.123host.vn` / DB `roacqgfa_dbms`). Backend + Frontend đã kết nối **DB thật** (không dùng mock data).

---

## 🧭 Mục lục

- [1. Tính năng chính](#1-tính-năng-chính)
- [2. Kiến trúc hệ thống](#2-kiến-trúc-hệ-thống)
- [3. Cấu trúc thư mục](#3-cấu-trúc-thư-mục)
- [4. Mô hình dữ liệu — 18 bảng / 5 module](#4-mô-hình-dữ-liệu--18-bảng--5-module)
- [5. Nghiệp vụ Đăng ký học phần & 5 ràng buộc](#5-nghiệp-vụ-đăng-ký-học-phần--5-ràng-buộc)
- [6. Các đối tượng Database](#6-các-đối-tượng-database)
- [7. Backend API](#7-backend-api)
- [8. Frontend — 19 màn hình](#8-frontend--19-màn-hình)
- [9. Yêu cầu môi trường & Cài đặt](#9-yêu-cầu-môi-trường--cài-đặt)
- [10. Hướng dẫn sử dụng theo vai trò](#10-hướng-dẫn-sử-dụng-theo-vai-trò)
- [11. Kiểm thử](#11-kiểm-thử)
- [12. Tài liệu thiết kế](#12-tài-liệu-thiết-kế)
- [13. Trạng thái hoàn thiện](#13-trạng-thái-hoàn-thiện)

---

## 1. Tính năng chính

### 👨‍🎓 Sinh viên
- Đăng nhập / đổi mật khẩu (JWT, mật khẩu mã hóa SHA-256, log đổi mật khẩu)
- Xem danh sách **lớp học phần đang mở** + sĩ số + lịch học + giảng viên
- **Đăng ký học phần** với kiểm tra đầy đủ 5 ràng buộc ngay tại SP (mã lỗi 100–106)
- **Hủy đăng ký** trong thời hạn (mã lỗi 200–202)
- Thời khóa biểu cá nhân, danh sách đăng ký, tổng tín chỉ theo học kỳ
- Bảng điểm chi tiết, **GPA học kỳ**, **CPA tích lũy**, xếp loại, cảnh báo học vụ
- Xem học phí từng kỳ (tổng tiền / đã nộp / còn nợ)

### 👨‍🏫 Giảng viên
- Xem danh sách lớp mình phụ trách + thời khóa biểu
- Xem danh sách sinh viên trong lớp
- **Nhập điểm** (từng SV hoặc hàng loạt) — điểm tổng kết/điểm chữ/hệ 4 **tự động tính bằng Trigger**
- Xem thống kê kết quả môn học, GPA sinh viên theo lớp

### 🏢 Phòng Đào Tạo (PĐT)
- **Quản lý sinh viên**: thêm/sửa/xóa, chuyển lớp (SP), tra cứu theo lớp/tên
- **Quản lý Khoa · Ngành · Lớp · Chương trình đào tạo** (CRUD đầy đủ)
- **Quản lý Môn học · Giảng viên · Phòng học · Học kỳ** (CRUD + mở/đóng đợt đăng ký)
- **Mở lớp học phần** + xếp lịch (SP kiểm tra GV/phòng trùng lịch)
- **Quản lý học phí**: tính học phí, thu tiền (SP transaction), báo cáo thu theo kỳ/ngành
- **Quản lý tài khoản**: tạo tài khoản SV/GV tự động, khóa/mở khóa, nhật ký đổi mật khẩu
- **Dashboard thống kê** toàn hệ thống + danh sách **cảnh báo học vụ**

---

## 2. Kiến trúc hệ thống

```
┌─────────────────────────────────────────────────────────────────┐
│  FRONTEND (web/) — HTML + CSS + JavaScript thuần                │
│  Đăng nhập · Dashboard · 19 màn hình theo 3 vai trò (SV/GV/PĐT) │
│  js/api.js: API client (fetch + JWT + localStorage)             │
└───────────────────────────────┬─────────────────────────────────┘
                                │  REST API (JSON) + Bearer Token
┌───────────────────────────────▼─────────────────────────────────┐
│  BACKEND (backend/) — Node.js + Express + mysql2                │
│  server.js · src/config.js · src/db.js (pool) · middleware/auth │
│  Routes: auth · danhmuc · dangky · ketqua · hocphi · giangvien ·│
│          admin  (70+ endpoint, phân quyền theo MaVaiTro)        │
└───────────────────────────────┬─────────────────────────────────┘
                                │  mysql2 (utf8mb4)
┌───────────────────────────────▼─────────────────────────────────┐
│  DATABASE — MySQL 5.7/8.0 (free02.123host.vn)                   │
│  18 bảng · 12 SP · 9 Function · 9 Trigger · 10 View · Index     │
│  Bảng nguồn: mysql/ (bản dịch từ sql/ T-SQL)                    │
└─────────────────────────────────────────────────────────────────┘
```

**Luồng nghiệp vụ chính** (đăng ký học phần):
```
SV chọn LHP ──▶ SP_DangKyHocPhan (START TRANSACTION)
                 ├─ 1. Kiểm tra đợt mở đăng ký (hạn)          → mã 100
                 ├─ 2. Kiểm tra chưa đăng ký trùng LHP         → mã 101
                 ├─ 3. FN_KiemTraTienQuyet                     → mã 102
                 ├─ 4. FN_KiemTraTrungLichHoc                  → mã 103
                 ├─ 5. FN_TinhTongTinChi + MaxTinChi           → mã 104
                 └─ 6. SELECT ... FOR UPDATE (khóa dòng sĩ số) → mã 105
                        └─ INSERT DANGKYHOCPHAN → Trigger tự +1 SiSoHienTai
                 ──▶ COMMIT (nguyên tử, chống Lost Update)
```

---

## 3. Cấu trúc thư mục

```
student-course-registration-management/
│
├── docs/                          # 📚 Tài liệu thiết kế & phân tích (5 module)
│   ├── analysis_*.md              #   Đặc tả nghiệp vụ từng module
│   ├── erd_*.md                   #   ERD từng module (mermaid)
│   ├── normalization_*.md         #   Chứng minh chuẩn hóa 3NF
│   ├── isolation_level_analysis.md#   Mức cô lập & khóa (Chương 5)
│   ├── deadlock_analysis.md       #   Phân tích deadlock (Chương 5)
│   ├── index_benchmark.md         #   Đo hiệu năng Index (Chương 3)
│   ├── concurrency_demo/          #   Kịch bản test 2 session
│   ├── Backlog_7_Tuan.md          #   Backlog theo tuần
│   ├── Phan_Cong_Nhiem_Vu_De_Tai_6.md
│   └── Giao_Trinh_He_Quan_Tri_*.txt  # Giáo trình tham khảo
│
├── sql/                           # 🐘 Bản gốc T-SQL (SQL Server)
│   ├── init_database.sql          #   Script tổng: CREATE DB → DDL → DATA
│   ├── ddl/ · data/               #   CREATE TABLE (18 bảng) + dữ liệu mẫu
│   ├── queries/                   #   Truy vấn & View
│   ├── procedures/ · functions/   #   SP & Function
│   ├── triggers/ · indexes/       #   Trigger & Index + đo hiệu năng
│   ├── transactions/              #   Transaction & concurrency
│   ├── security/                  #   GRANT/REVOKE 3 vai trò
│   └── ban_thao/                  #   Bản thảo ban đầu (lưu trữ, không chạy)
│
├── mysql/                         # ⭐ Bản dịch MySQL (chạy được trên hosting)
│   ├── init_database.sql          #   Hướng dẫn thứ tự chạy từng file
│   ├── ddl/                       #   18 bảng (5 file, theo thứ tự phụ thuộc)
│   ├── data/                      #   Dữ liệu mẫu (60 SV, 5 học kỳ, 794 lượt ĐK)
│   ├── functions/                 #   9 Function
│   ├── procedures/                #   12 Stored Procedure
│   ├── triggers/                  #   9 Trigger
│   ├── views/                     #   10 View
│   ├── indexes/                   #   Index tối ưu
│   ├── transactions/              #   Transaction & concurrency (FOR UPDATE)
│   ├── queries/                   #   Truy vấn mẫu từng module
│   └── security/                  #   Phân quyền 3 vai trò
│
├── backend/                       # ⚙️ Node.js + Express + mysql2
│   ├── server.js                  #   Entry point (API + phục vụ luôn web/)
│   ├── .env                       #   Cấu hình DB (không commit lên Git)
│   ├── package.json
│   ├── src/
│   │   ├── config.js              #   Cấu hình DB pool, JWT, PORT
│   │   ├── db.js                  #   mysql2 pool + query helper
│   │   ├── middleware/auth.js     #   JWT sign/verify + requireRole
│   │   └── routes/                #   auth · danhmuc · dangky · ketqua ·
│   │                              #   hocphi · giangvien · admin
│   └── scripts/
│       ├── init-db.js             #   Khởi tạo toàn bộ DB từ mysql/
│       ├── verify-db.js           #   Kiểm tra nhanh DB
│       ├── test-api.js            #   Test API cơ bản
│       ├── e2e-test.js            #   25 test E2E (3 vai trò)
│       └── check-pages.mjs        #   Rà soát asset HTML
│
└── web/                           # 🖥️ Frontend (HTML/JS thuần)
    ├── login.html                 #   Đăng nhập
    ├── index.html                 #   Dashboard theo vai trò
    ├── css/shared.css             #   Design system chung
    ├── js/api.js                  #   API client (fetch + JWT)
    ├── js/shared.js               #   Hàm chung + menu theo vai trò
    ├── js/dangky.js               #   Logic đăng ký (SV)
    └── app/
        ├── dangky_hocphan/        #   SV: đăng ký, TKB, danh sách, hủy
        ├── diem/                  #   SV: bảng điểm · PĐT: điểm & cảnh báo
        ├── hocphi/                #   SV: học phí · PĐT: quản lý học phí
        ├── giangvien/             #   GV: lớp, nhập điểm, TKB
        ├── danhmuc/               #   PĐT: SV, Khoa·Ngành·Lớp, CTĐT
        ├── hocphan/               #   PĐT: Môn học·GV·Phòng, Mở LHP
        └── admin/                 #   PĐT: Dashboard, Tài khoản
```

---

## 4. Mô hình dữ liệu — 18 bảng / 5 module

| Module | Thành viên | Bảng | Mô tả |
|---|---|---|---|
| **1. Danh mục & Hồ sơ SV** | TV1 | `KHOA`, `NGANH`, `LOP_SINHHOAT`, `SINHVIEN`, `CHUONGTRINHDAOTAO` | Dữ liệu nền: khoa → ngành → lớp → SV, CTĐT (ngành–môn–học kỳ) |
| **2. Học phần, GV & Mở LHP** | TV2 | `GIANGVIEN`, `MONHOC`, `MONHOC_TIENQUYET`, `HOCKY`, `PHONGHOC`, `LOPHOCPHAN`, `LICHHOC` | Môn học + tiên quyết, mở lớp học phần mỗi kỳ, xếp lịch phòng/GV |
| **3. Đăng ký học phần** ⭐ | TV3 | `DANGKYHOCPHAN` | Bảng trung tâm (PK ghép `MaSV`+`MaLHP`), 5 ràng buộc + Transaction |
| **4. Điểm số & Kết quả** | TV4 | `KETQUAHOCTAP`, `THANGDIEMCHU` | Điểm CC/GK/CK, tự tính điểm tổng kết–chữ–hệ 4, thang điểm tra cứu |
| **5. Học phí, Tài khoản** | TV5 | `HOCPHI`, `TAIKHOAN`, `VAITRO` | Tính/thu học phí, tài khoản đăng nhập 3 vai trò |

> Bảng `NHATKY_DOIMATKHAU` được bổ sung để Trigger log đổi mật khẩu ghi nhận lịch sử.
> Toàn bộ DDL: `mysql/ddl/` (MySQL) · `sql/ddl/` (T-SQL gốc).

**Quan hệ khóa ngoại chính:**

```
KHOA 1──n NGANH 1──n LOP_SINHHOAT 1──n SINHVIEN
                                     │
                     NGANH n──m MONHOC (qua CHUONGTRINHDAOTAO)
                     MONHOC 1──n LOPHOCPHAN 1──n LICHHOC
                     GIANGVIEN 1──n LOPHOCPHAN · PHONGHOC 1──n LICHHOC
                     SINHVIEN n──m LOPHOCPHAN (qua DANGKYHOCPHAN) ⭐
                     DANGKYHOCPHAN 1──n KETQUAHOCTAP · HOCPHI
                     SINHVIEN/GIANGVIEN 1──0..1 TAIKHOAN n──1 VAITRO
```

---

## 5. Nghiệp vụ Đăng ký học phần & 5 ràng buộc

SP `SP_DangKyHocPhan` đóng gói **toàn bộ 5 bước kiểm tra + ghi nhận** trong **một Transaction** (`START TRANSACTION ... COMMIT/ROLLBACK`), dùng `SELECT ... FOR UPDATE` để khóa dòng LOPHOCPHAN — tương đương `UPDLOCK+HOLDLOCK` của SQL Server — ngăn **Lost Update** khi 2 SV tranh chỗ cuối cùng.

| # | Ràng buộc | Điều kiện hợp lệ | Mã lỗi | Thông báo UI |
|---|---|---|---|---|
| 1 | Hạn đăng ký | Đợt `MO` và `NOW() BETWEEN TuNgay AND DenNgay` | `100` | Ngoài thời hạn đăng ký học phần |
| 2 | Trùng LHP | Chưa có bản ghi `(MaSV, MaLHP)` | `101` | Bạn đã đăng ký lớp học phần này rồi |
| 3 | Môn tiên quyết | `FN_KiemTraTienQuyet` = đạt hết | `102` | Chưa hoàn thành môn tiên quyết |
| 4 | Trùng lịch học | `FN_KiemTraTrungLichHoc` = không trùng | `103` | Trùng lịch học với lớp đã đăng ký |
| 5 | Giới hạn tín chỉ | `Tổng TC + TC mới ≤ MaxTinChi` | `104` | Vượt quá tín chỉ tối đa |
| 6 | Sĩ số lớp | `SiSoHienTai < SiSoToiDa` (khóa dòng) | `105` | Lớp đã đầy sĩ số |
| — | LHP không hợp lệ | LHP tồn tại & đang `MO_DANG_KY` | `106` | LHP không tồn tại / không mở |
| — | Lỗi hệ thống | — | `500` | Lỗi hệ thống |

**Hủy đăng ký** (`SP_HuyDangKy`): mã `200` (ngoài hạn hủy) · `201` (không tìm thấy) · `202` (không ở trạng thái ĐÃ ĐĂNG KÝ).

**Transaction / Concurrency** (`mysql/transactions/`):
- `dangky_hocphan_tran.sql` — demo Atomicity + chống Lost Update + rollback
- `concurrency_test.sql` — kịch bản **2 session** đăng ký đồng thời chỗ cuối
- `danh_muc_hoso_sv_concurrency.sql` — cập nhật hồ sơ SV chống xung đột
- `diem_ketqua_tran.sql` — nhập điểm hàng loạt (rollback nếu 1 dòng lỗi)
- `hocphan_giangvien_molophocphan_transactions.sql` — mở LHP + xếp lịch
- `thu_hoc_phi_transaction.sql`, `phan_tich_concurrency_hoc_phi.sql` — thu/đóng học phí an toàn
- `them_sv_gan_lop_tran.sql` — thêm SV + gán lớp (Atomicity)

---

## 6. Các đối tượng Database

> Toàn bộ nằm trong `mysql/` (đã triển khai lên MySQL remote).

### 6.1 Stored Procedure (12)

| SP | Module | Chức năng |
|---|---|---|
| `SP_DangKyHocPhan` | TV3 ⭐ | Đăng ký học phần — 5 bước kiểm tra + ghi nhận (Transaction + FOR UPDATE) |
| `SP_HuyDangKy` | TV3 | Hủy đăng ký trong hạn (mã 200–202) |
| `SP_ThemSinhVien_Moi` | TV1 | Thêm SV + kiểm tra lớp/trùng mã + **tự tạo tài khoản** |
| `SP_ChuyenLop_Nganh` | TV1 | Chuyển lớp cho SV (mã 403/404/405) |
| `SP_MoLopHocPhan` | TV2 | Mở LHP + xếp lịch, kiểm tra GV/phòng trùng lịch |
| `SP_GV_NHAP_DIEM` | TV4 | GV nhập điểm (kiểm tra lớp phụ trách) |
| `SP_TinhGPA_HocKy` | TV4 | GPA học kỳ + xếp loại |
| `SP_TinhCPA_TichLuy` | TV4 | CPA tích lũy (môn học lại tính điểm cao nhất) + cảnh báo học vụ |
| `SP_TinhHocPhi` | TV5 | Tự tính học phí = tổng TC × đơn giá |
| `SP_ThuHocPhi` | TV5 | Thu tiền (kiểm tra còn nợ, Transaction) |
| `SP_TaoTaiKhoanSinhVien` | TV5 | Tạo tài khoản SV tự động |
| `SP_TaoTaiKhoanGiangVien` | TV5 | Tạo tài khoản GV tự động |

### 6.2 Function (9)

`FN_KiemTraDotDangKy` · `FN_KiemTraTienQuyet` · `FN_KiemTraTrungLichHoc` · `FN_KiemTraPhongTrong` · `FN_TinhTongTinChi` · `FN_TinhDiemTongKet` · `FN_QuyDoiDiemChu` · `FN_QuyDoiDiemHe4` · `FN_DemSiSoLop`

### 6.3 Trigger (9)

| Trigger | Bảng | Tác động |
|---|---|---|
| `TRG_DANGKYHOCPHAN_AFTER_INSERT/UPDATE/DELETE` | `DANGKYHOCPHAN` | **Tự động ±1 `SiSoHienTai`** của LHP khi đăng ký/hủy/đổi trạng thái |
| `TRG_KETQUAHOCTAP_BEFORE_INSERT/UPDATE` | `KETQUAHOCTAP` | **Tự tính** `DiemTongKet` (10% CC + 30% GK + 60% CK) → `DiemChu` → `DiemHe4` |
| `TRG_LICHHOC_BEFORE_INSERT/UPDATE` | `LICHHOC` | **Chặn trùng lịch** phòng / GV cùng khung giờ |
| `TRG_LogDoiMatKhau` | `TAIKHOAN` | Ghi nhật ký mỗi lần đổi mật khẩu |
| `TRG_XoaNganh_ChanKhiConSinhVien` | `NGANH` | **Chặn xóa ngành** khi còn SV thuộc ngành |

### 6.4 View (10)

`VW_SinhVienDangKyChiTiet` · `VW_ThoiKhoaBieuCaNhan` · `V_BANGDIEM_SINHVIEN` · `V_THONGKE_KETQUA_MONHOC` · `VW_SinhVienDangHoc` · `VW_SinhVienNoHocPhi` · `VW_SinhVienDaThanhToan` · `VW_TongThuTheoHocKy` · `VW_TongThuTheoNganh` · `VW_BaoCaoHocPhi`

### 6.5 Index

Composite index cho kiểm tra trùng lịch `(MaPhong, Thu, TietBatDau)`, `(MaGV, Thu, TietBatDau)`; non-clustered trên `MaSV`/`MaLHP` (đăng ký), `HoTen`+`MaLopSH` (tra SV), `MaSV` (điểm, học phí), unique `TenDangNhap` (đăng nhập). Xem `mysql/indexes/all_indexes.sql` + `docs/index_benchmark.md`.

### 6.6 Phân quyền

`mysql/security/phan_quyen_3_vai_tro.sql` — SV chỉ SELECT view điểm của mình; GV chỉ EXECUTE SP nhập điểm; PĐT toàn quyền. Trên shared hosting MySQL 5.7 không có `CREATE ROLE` nên phân quyền được thực thi ở **lớp ứng dụng** (middleware JWT + `requireRole`).

---

## 7. Backend API

> Base URL: `http://localhost:3000/api` — Xác thực: `Authorization: Bearer <token>` (JWT, hết hạn 12h).

### 7.1 Auth

| Method | Endpoint | Vai trò | Mô tả |
|---|---|---|---|
| POST | `/auth/login` | Tất cả | Đăng nhập → trả `{token, user}` |
| GET | `/auth/me` | Tất cả | Thông tin người dùng hiện tại |
| POST | `/auth/doimatkhau` | Tất cả | Đổi mật khẩu (ghi log qua Trigger) |

### 7.2 Đăng ký học phần (SV)

| Method | Endpoint | Mô tả |
|---|---|---|
| GET | `/dangky/hocky-hientai` | Đợt đăng ký đang mở |
| GET | `/dangky/lopmo` | Danh sách LHP đang mở (kèm sĩ số, lịch, tiên quyết, đã ĐK chưa) |
| POST | `/dangky` | `{MaLHP, MaxTinChi}` → `SP_DangKyHocPhan` (mã 0/100–106) |
| POST | `/dangky/huy` | `{MaLHP}` → `SP_HuyDangKy` (mã 0/200–202) |
| GET | `/dangky/danhsach?MaHocKy=` | Danh sách đăng ký (View chi tiết) |
| GET | `/dangky/thoikhoabieu?MaHocKy=` | Thời khóa biểu cá nhân |
| GET | `/dangky/tongtinchi?MaHocKy=` | Tổng tín chỉ đã đăng ký |

### 7.3 Điểm & Kết quả (SV/GV/PĐT)

| Method | Endpoint | Vai trò | Mô tả |
|---|---|---|---|
| GET | `/ketqua/bangdiem?MaHocKy=` | SV | Bảng điểm cá nhân |
| GET | `/ketqua/gpa?MaHocKy=` | SV | GPA học kỳ |
| GET | `/ketqua/cpa` | SV | CPA tích lũy + cảnh báo học vụ |
| GET | `/ketqua/thangdiemchu` | Tất cả | Bảng thang điểm chữ |
| GET | `/ketqua/thongke-monhoc?MaLHP=` | GV/PĐT | Thống kê kết quả môn học |
| GET | `/ketqua/canhbao-hocvu` | PĐT | Danh sách SV bị cảnh báo học vụ |
| GET | `/ketqua/gpa-theo-lop/:MaLHP` | GV/PĐT | GPA sinh viên trong lớp |

### 7.4 Học phí

| Method | Endpoint | Vai trò | Mô tả |
|---|---|---|---|
| GET | `/hocphi/cua-toi` | SV | Học phí của tôi |
| GET | `/hocphi/danhsach?TrangThai=&MaHocKy=` | PĐT | Danh sách học phí |
| GET | `/hocphi/baocao` | PĐT | Báo cáo tổng thu theo kỳ/ngành, nợ |
| POST | `/hocphi/thu` | PĐT | `{MaHocPhi, SoTien}` → `SP_ThuHocPhi` (mã 301–304) |
| POST | `/hocphi/tinh` | PĐT | `{MaSV, MaHocKy, DonGiaTinChi}` → `SP_TinhHocPhi` |

### 7.5 Giảng viên

| Method | Endpoint | Mô tả |
|---|---|---|
| GET | `/giangvien/lopcuatoi?MaHocKy=` | Lớp GV phụ trách (kèm lịch học) |
| GET | `/giangvien/sinhvien/:MaLHP` | Danh sách SV + điểm trong lớp |
| POST | `/giangvien/nhapdiem` | Nhập điểm 1 SV → `SP_GV_NHAP_DIEM` |
| POST | `/giangvien/nhapdiem-hangloat` | Nhập điểm hàng loạt `{MaLHP, DanhSachDiem}` |

### 7.6 Danh mục (PĐT quản lý, mọi vai trò xem)

| Endpoint | Mô tả |
|---|---|
| `GET /danhmuc/{khoa,nganh,lop,monhoc,giangvien,phonghoc,hocky,tienquyet}` | Danh sách (đọc) |
| `POST/PUT/DELETE /danhmuc/{khoa,nganh,lop,monhoc,giangvien,phonghoc,hocky}` | CRUD (PĐT) |
| `GET/POST/DELETE /danhmuc/ctdt` | Chương trình đào tạo (PĐT) |
| `GET /danhmuc/sinhvien?MaLopSH=&tim=` | Tra cứu SV (PĐT) |
| `POST /danhmuc/sinhvien/chuyenlop` | Chuyển lớp → `SP_ChuyenLop_Nganh` |
| `PUT/DELETE /danhmuc/sinhvien/:MaSV` | Cập nhật / xóa hồ sơ SV |

### 7.7 Admin (PĐT)

| Method | Endpoint | Mô tả |
|---|---|---|
| GET | `/admin/thongke` | Dashboard tổng hợp |
| GET | `/admin/lophocphan?MaHocKy=&TrangThaiLop=` | Danh sách tất cả LHP |
| GET | `/admin/taikhoan` | Danh sách tài khoản |
| PUT | `/admin/taikhoan/khoa` | Khóa / mở khóa tài khoản |
| POST | `/admin/taikhoan/sinhvien` · `/giangvien` | Tạo tài khoản tự động |
| GET | `/admin/nhatky-doimatkhau` | Nhật ký đổi mật khẩu |
| POST | `/admin/molophocphan` | Mở LHP + xếp lịch → `SP_MoLopHocPhan` |
| POST | `/admin/themsinhvien` | Thêm SV + tự tạo tài khoản → `SP_ThemSinhVien_Moi` |

> **Mã lỗi kinh doanh** (trả kèm HTTP 400): Đăng ký `100–106`, Hủy `200–202`, Thu học phí `301–304`, Thêm SV `401–402`, Chuyển lớp `403–405`.

---

## 8. Frontend — 19 màn hình

> 🎨 **Giao diện định hướng theo Portal UTH thật** (`portal.ut.edu.vn`): nhận diện thương
> hiệu Trường ĐH Giao thông vận tải TP.HCM (logo, màu teal `#008689`, font Montserrat/Roboto),
> topbar + header trắng + thanh menu teal + breadcrumb + footer 3 cột — dựng tập trung trong
> `js/shared.js` + `css/shared.css` cho toàn bộ 19 màn hình.

| Nhóm | Trang | Vai trò |
|---|---|---|
| Chung | `login.html` (đăng nhập 2 bước + OTP) · `index.html` (dashboard) | Tất cả |
| Đăng ký | `app/dangky_hocphan/dang-ky.html` · `thoi-khoa-bieu.html` · `danh-sach-dang-ky.html` · `huy-dang-ky.html` | SV |
| Điểm | `app/diem/bang-diem.html` · `app/diem/nhap-diem-pdt.html` | SV · PĐT |
| Học phí | `app/hocphi/hoc-phi-cua-toi.html` · `app/hocphi/quan-ly-hoc-phi.html` | SV · PĐT |
| GV | `app/giangvien/lop-cua-toi.html` · `nhap-diem.html` · `thoi-khoa-bieu-gv.html` | GV |
| Danh mục | `app/danhmuc/sinh-vien.html` · `khoa-nganh-lop.html` | PĐT |
| Học phần | `app/hocphan/mon-hoc-giang-vien.html` · `mo-lop-hoc-phan.html` | PĐT |
| Admin | `app/admin/dashboard.html` · `app/admin/tai-khoan.html` | PĐT |

**Cơ chế chung:** `js/api.js` (fetch + JWT, tự chuyển về login khi token hết hạn — đường dẫn tuyệt đối) · `js/shared.js` (layout portal, đồng hồ thời gian thực, toast, esc chống XSS, format tiền, menu + auth guard theo vai trò, **modal Đổi mật khẩu**) · `css/shared.css` (design system teal).

**Đăng nhập kiểu portal (2 bước):**
1. `POST /api/auth/otp/gui` — kiểm tra tài khoản/mật khẩu → sinh OTP 6 số (hạn 120s).
   Portal thật gửi OTP về email trường + reCAPTCHA; bản demo hiển thị mã ngay trên UI (`otpDemo`).
2. `POST /api/auth/otp/xacthuc` — nhập đúng OTP → cấp JWT `{token, user}`.
- `POST /api/auth/login` giữ nguyên cho test tự động/E2E.
- `GET /api/auth/hoso` — hồ sơ cá nhân (SV: họ tên, MSSV, ngày sinh, ngành, lớp SH, khoa…) phục vụ dashboard; trigger sinh nhật 🎂 trên dashboard theo `NgaySinh` thật.

---

## 9. Yêu cầu môi trường & Cài đặt

### Yêu cầu
- **Node.js ≥ 18** (khuyến nghị 20+)
- **MySQL 5.7 / 8.0** (đã có sẵn remote `free02.123host.vn`)
- Trình duyệt hiện đại (Chrome/Edge/Firefox)

### Bước 1 — Cấu hình kết nối DB

Tạo file `backend/.env` (mẫu đã có trong repo, không commit):

```env
DB_HOST=free02.123host.vn
DB_USER=roacqgfa_dbms
DB_PASSWORD=roacqgfa_dbms1
DB_NAME=roacqgfa_dbms
PORT=3000
JWT_SECRET=dangkyhocphan_secret_2026
```

> Database `roacqgfa_dbms` trên hosting **đã chứa sẵn toàn bộ đối tượng và dữ liệu mẫu**. Chỉ chạy bước 2 nếu cần tạo lại từ đầu.

### Bước 2 — (Tùy chọn) Khởi tạo lại Database

```bash
cd backend
npm install
node scripts/init-db.js        # DDL → Data → Function/SP/Trigger/View/Index
```

Hoặc chạy lần lượt các file trong `mysql/` theo thứ tự ghi trong `mysql/init_database.sql`.

### Bước 3 — Chạy ứng dụng

```bash
cd backend
npm start                      # hoặc: npm run dev (tự động reload)
```

Mở trình duyệt: **http://localhost:3000** → tự động vào trang đăng nhập.
(Backend Express phục vụ luôn cả frontend `web/` nên chỉ cần 1 lệnh.)

### Tài khoản demo

| Vai trò | Tên đăng nhập | Mật khẩu | Quyền |
|---|---|---|---|
| Sinh viên | `sv001` | `matkhau@123` | Đăng ký, TKB, điểm, học phí |
| Giảng viên | `gv001` | `matkhau@123` | Lớp của tôi, nhập điểm |
| Phòng Đào Tạo | `admin` | `admin@123` | Toàn quyền quản trị |

> 60 tài khoản SV (`sv001`–`sv060`), 15 tài khoản GV (`gv001`–`gv015`) đều dùng mật khẩu `matkhau@123` (SV060 bị khóa để minh họa).
> Đăng nhập trên giao diện gồm 2 bước (mật khẩu → OTP) như portal thật; mã OTP demo hiển thị ngay trên màn hình.
> Nếu chỉ cần vào nhanh, backend vẫn giữ `POST /api/auth/login` một bước cho script test.

---

## 10. Hướng dẫn sử dụng theo vai trò

### Sinh viên (`sv001`)
1. Đăng nhập → **Trang chủ** hiển thị tổng tín chỉ, số lớp đã ĐK, hạn đăng ký.
2. **Đăng ký học phần** → chọn lớp đang mở → nhấn **Đăng ký**; hệ thống kiểm tra 5 ràng buộc và báo lỗi cụ thể (100–106) nếu vi phạm.
3. **Thời khóa biểu** → xem lịch học đã sắp xếp theo thứ/tiết/phòng.
4. **Danh sách đăng ký** → tổng hợp tín chỉ theo học kỳ.
5. **Hủy đăng ký** → hủy trong hạn (mã lỗi 200–202 nếu không hợp lệ).
6. **Bảng điểm** → chọn học kỳ xem GPA, CPA tích lũy, thang điểm chữ.
7. **Học phí** → xem tổng tiền/đã nộp/còn nợ.

### Giảng viên (`gv001`)
1. **Lớp của tôi** → danh sách lớp phụ trách kèm sĩ số, lịch.
2. **Nhập điểm** → chọn lớp → điền điểm CC/GK/CK → **Lưu tất cả**; điểm TK/chữ/hệ 4 tự tính bằng Trigger (10% + 30% + 60%).

### Phòng Đào Tạo (`admin`)
1. **Dashboard** → thống kê SV/GV/môn/LHP/lượt đăng ký + báo cáo học phí.
2. **Quản lý SV** → thêm/sửa/xóa, **chuyển lớp**, tra cứu theo lớp/tên.
3. **Khoa · Ngành · Lớp** → CRUD + quản lý **chương trình đào tạo** (thử xóa ngành còn SV để thấy Trigger chặn).
4. **Môn học · GV · Phòng** → CRUD + mở/đóng **đợt đăng ký**.
5. **Mở LHP** → tạo LHP + xếp lịch (SP tự kiểm tra trùng lịch GV/phòng).
6. **Điểm & Cảnh báo** → danh sách SV cảnh báo học vụ, thống kê môn.
7. **Học phí** → tính học phí, thu tiền, báo cáo.
8. **Tài khoản** → tạo tài khoản SV/GV, khóa/mở khóa, nhật ký đổi mật khẩu.

---

## 11. Kiểm thử

| Công cụ | Nội dung | Kết quả |
|---|---|---|
| `backend/scripts/test-api.js` | Luồng SV: login → LHP mở → tín chỉ → TKB → điểm → GPA → học phí | ✅ |
| `backend/scripts/e2e-test.js` | **25 test E2E** qua 3 vai trò (auth, đăng ký, điểm, học phí, GV, admin, danh mục) | ✅ 25/25 PASS |
| `backend/scripts/verify-db.js` | Kiểm tra nhanh đối tượng DB (sĩ số, điểm F, học phí, tài khoản, function, view) | ✅ |
| `backend/scripts/check-pages.mjs` | Rà soát 20 file HTML: asset đủ, không còn tham chiếu mock | ✅ 0 lỗi |
| Trigger | Tự +1/−1 sĩ số khi đăng ký/hủy · tự tính điểm · chặn trùng lịch · chặn xóa ngành | ✅ đã kiểm thử |
| Concurrency | `mysql/transactions/concurrency_test.sql` — 2 session tranh chỗ cuối (kịch bản 2 cửa sổ mysql client) | theo docs |

---

## 12. Tài liệu thiết kế

| Tài liệu | Nội dung |
|---|---|
| `docs/analysis_dangky_hocphan.md` | Đặc tả 5 ràng buộc + lưu đồ xử lý đăng ký |
| `docs/erd_dangky_hocphan.md` | ERD bảng trung tâm `DANGKYHOCPHAN` |
| `docs/erd_diem_ketqua.md` · `erd_hocphi_taikhoan.md` · `erd_hocphan_giangvien_molophocphan.md` | ERD các module |
| `docs/normalization_*.md` (5 file) | Chứng minh chuẩn hóa 3NF từng module |
| `docs/Ho_So_Sinh_Vien.md` | Đặc tả dữ liệu module danh mục & hồ sơ SV |
| `docs/isolation_level_analysis.md` | Vì sao READ COMMITTED chưa đủ → chọn khóa phù hợp |
| `docs/deadlock_analysis.md` | Deadlock & phòng tránh (Chương 5) |
| `docs/index_benchmark.md` | Đo hiệu năng trước/sau Index (Chương 3) |
| `docs/trigger_integration_test.md` | Test chuỗi trigger toàn hệ thống |
| `docs/concurrency_diem_ketqua.md` | Phân tích concurrency nhập điểm |
| `docs/Backlog_7_Tuan.md` · `Phan_Cong_Nhiem_Vu_De_Tai_6.md` | Kế hoạch & phân công nhóm |
| `docs/So_Do_ERD.docx` | Sơ đồ ERD tổng thể (Word) |
| `docs/Giao_Trinh_He_Quan_Tri_Co_So_Du_Lieu_Full.txt` | Giáo trình tham khảo |

---

## 13. Trạng thái hoàn thiện

- [x] Phân tích nghiệp vụ + ERD + chuẩn hóa 3NF cho cả 5 module (docs)
- [x] DDL 18 bảng + dữ liệu mẫu (60 SV, 15 GV, 48 môn, 46 LHP, 794 lượt đăng ký)
- [x] Chuyển **toàn bộ T-SQL → MySQL** (DDL, data, 9 FN, 12 SP, 9 Trigger, 10 View, Index, Transaction, Query, Security)
- [x] Triển khai & chạy trên **MySQL remote** (`free02.123host.vn`)
- [x] Backend **Node.js/Express** — REST + JWT, 7 nhóm route (~70 endpoint), phân quyền 3 vai trò
- [x] Frontend kết nối **DB thật** — 19 màn hình, không mock data
- [x] SP đăng ký kiểm tra **5 ràng buộc** (mã 100–106) + Transaction chống Lost Update — đã kiểm thử
- [x] Trigger tự tính điểm / cập nhật sĩ số / chặn trùng lịch / chặn xóa ngành / log mật khẩu — đã kiểm thử
- [x] E2E: 25/25 PASS, 19 màn hình + template, sĩ số nhất quán sau đăng ký–hủy

---

## 📜 Ghi chú triển khai

- **Charset:** database đặt `utf8mb4_unicode_ci` (đã đổi từ mặc định latin1 của hosting) để lưu đúng tiếng Việt trong SP/Trigger/View.
- **T-SQL → MySQL:** `UPDLOCK+HOLDLOCK` → `SELECT ... FOR UPDATE`; `GETDATE()` → `NOW()`; `GO` → tách statement (script runner `init-db.js` tự xử lý DELIMITER); `NVARCHAR` → `VARCHAR` (utf8mb4).
- **Phân quyền:** trên MySQL 5.7 shared hosting không có `CREATE ROLE`, nên GRANT mẫu đi kèm và quyền thực thi nằm ở middleware JWT của backend.
