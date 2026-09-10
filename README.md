# 🎓 Hệ thống Quản lý Sinh viên Đăng ký Học phần Tín chỉ

> **Đề tài 6 — Môn: Hệ Quản trị Cơ sở dữ liệu** | Nhóm 5 thành viên
> **Nền tảng:** MySQL (remote hosting) · Node.js/Express · **React 18 + Vite + MUI (Material Design)** — cùng công nghệ với portal.ut.edu.vn

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
- [8. Frontend — React SPA, 19 màn hình](#8-frontend--react-spa-19-màn-hình)
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
│  FRONTEND (frontend/) — VIEW của MVC · React 18 SPA              │
│  (giống stack portal thật): Vite · MUI 5 · Redux Toolkit ·       │
│  React Router v6 · axios · react-toastify · teal #008689         │
│  19 màn hình theo 3 vai trò · Đăng nhập JWT · localStorage       │
└───────────────────────────────┬─────────────────────────────────┘
                                │  REST API (JSON) + Bearer Token
┌───────────────────────────────▼─────────────────────────────────┐
│  BACKEND (backend/) — Node.js + Express + mysql2 (MVC)           │
│  server.js (entry) → routes/ (URL) → controllers/ (request/      │
│  response, mã lỗi SP) → models/ (CHỈ `CALL SP` qua db.js:        │
│  sp/spMulti/spOut/spOutFull — không raw query, không connection  │
│  thô; MỌI GIAO TÁC nằm trong Stored Procedure)                   │
│  7 nhóm route: auth · danhmuc · dangky · ketqua · hocphi ·       │
│  giangvien · admin (~70 endpoint, phân quyền 3 vai trò)          │
│  + phục vụ bản build frontend/dist (SPA fallback)                │
└───────────────────────────────┬─────────────────────────────────┘
                                │  mysql2 (utf8mb4)
┌───────────────────────────────▼─────────────────────────────────┐
│  DATABASE (mysql/) — MODEL dữ liệu · MySQL 5.7/8.0 (remote)      │
│  18 bảng · SP/Function/Trigger/View · Index · Transaction/SP     │
│  (bản SQL Server cũ sql/ đã được loại bỏ khỏi repo)              │
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
├── docs/                          # 📚 TÀI LIỆU — tách riêng khỏi source code
│   ├── README.md                  #   Mục lục tài liệu
│   ├── conventions.md             #   Quy ước đặt tên & cấu trúc thư mục
│   ├── analysis/                  #   Đặc tả & phân tích nghiệp vụ 5 module
│   ├── erd/                       #   ERD từng module (mermaid) + So_Do_ERD.docx
│   ├── normalization/             #   Chứng minh chuẩn hóa 3NF từng module
│   ├── concurrency/               #   Cô lập · deadlock (phân tích + demo) ·
│   │                               #   demo 4 lỗi · kịch bản thao tác thật
│   │   └── media/                 #   Ảnh/video minh chứng test 2 session
│   ├── performance/               #   Đo hiệu năng Index
│   ├── testing/                   #   Kiểm thử tích hợp Trigger
│   ├── planning/                  #   Backlog 7 tuần · phân công nhóm
│   └── reference/                 #   Giáo trình tham khảo
│
├── mysql/                         # 🐬 Bản script MySQL — nguồn duy nhất (đang chạy)
│   ├── init_database.sql          #   Hướng dẫn thứ tự chạy từng file
│   ├── ddl/                       #   18 bảng (5 file, theo thứ tự phụ thuộc)
│   ├── data/                      #   Dữ liệu mẫu (60 SV, 5 học kỳ, 794 lượt ĐK)
│   ├── functions/                 #   9 Function
│   ├── procedures/                #   Stored Procedure (gồm 2 SP giao tác hàng loạt)
│   ├── triggers/                  #   9 Trigger
│   ├── views/                     #   10 View
│   ├── indexes/                   #   Index tối ưu
│   ├── transactions/              #   SP demo 4 lỗi + DEADLOCK (script demo ở docs/)
│   ├── queries/                   #   Truy vấn mẫu từng module
│   └── security/                  #   Phân quyền 3 vai trò
│
├── backend/                       # ⚙️ API Node.js + Express — cấu trúc MVC
│   ├── server.js                  #   Entry: mount /api + phục vụ frontend/dist
│   ├── .env                       #   Cấu hình DB (không commit lên Git)
│   ├── package.json
│   └── src/
│       ├── config.js              #   Cấu hình DB pool, JWT, PORT
│       ├── db.js                  #   mysql2 pool NỘI BỘ (không export) + 4 helper
│       │                          #   sp/spMulti/spOut/spOutFull (chỉ CALL SP)
│       ├── middleware/auth.js     #   JWT sign/verify + requireRole
│       ├── routes/                #   🅡 ROUTE — chỉ ánh xạ URL → controller
│       │   ├── index.js           #     gom 7 nhóm route + /api/health
│       │   └── auth · danhmuc · dangky · ketqua · hocphi ·
│       │       giangvien · admin
│       ├── controllers/           #   🅒 CONTROLLER — request/response + mã lỗi SP
│       │   └── *.controller.js (8 file, 1/nhóm route + system)
│       └── models/                #   🅜 MODEL — chỉ `CALL SP` qua db.js
│           └── *.model.js (8 file, theo module nghiệp vụ)
│                                  #   ⚠️ KHÔNG có services/demo: mọi giao tác nằm trong DB
│   └── scripts/
│       ├── init-db.js             #   Khởi tạo toàn bộ DB từ mysql/
│       ├── verify-db.js           #   Kiểm tra nhanh DB
│       ├── test-api.js            #   Test API cơ bản
│       ├── e2e-test.js            #   25 test E2E (3 vai trò)
│       ├── apply-sql.js           #   Áp 1 file .sql (SP/DDL) lên DB — hỗ trợ DELIMITER
│       └── audit-no-raw-query.mjs #   Audit: không raw query + giao tác chỉ ở DB
│
└── frontend/                      # 🖥️ VIEW của MVC — React 18 SPA (Vite + MUI)
    ├── vite.config.js             #   Dev proxy /api → :3000
    ├── index.html                 #   Google Fonts (Montserrat/Roboto) + favicon
    ├── public/images/             #   Logo trường, nền đăng nhập (asset thật UTH)
    └── src/
        ├── main.jsx               #   Provider + Router + ThemeProvider + Toast
        ├── App.jsx                #   19 route + ProtectedRoute theo vai trò
        ├── theme.js               #   Design system teal #008689 (MUI createTheme)
        ├── api/client.js          #   axios + Bearer JWT + interceptor 401
        ├── store/authSlice.js     #   Redux Toolkit: phiên đăng nhập
        ├── config/menu.jsx        #   Menu + breadcrumb 3 vai trò
        ├── utils/format.js        #   Tiền VND, thứ, trạng thái, mã lỗi SP
        ├── components/            #   PortalLayout, ProtectedRoute, SectionCard,
        │                          #   StatusBadges, ConfirmDialog, ChangePasswordDialog
        └── pages/
            ├── Login.jsx          #   Đăng nhập 1 bước (tài khoản + mật khẩu)
            ├── Dashboard.jsx      #   Theo vai trò (SV/GV/PĐT) + trigger sinh nhật
            ├── sv/                #   Đăng ký (từng lớp + nhiều lớp) · TKB · Danh sách ·
            │                      #   Hủy · Bảng điểm · Học phí
            ├── gv/                #   Lớp của tôi · Nhập điểm · TKB
            └── pdt/               #   SV · Khoa/Ngành/Lớp · Môn học · Mở LHP ·
                                   #   Cảnh báo · Học phí · Tài khoản
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
> Toàn bộ DDL hiện hành: `mysql/ddl/` (MySQL — bản T-SQL SQL Server cũ đã gỡ bỏ).

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
- **`demo_4_anomaly.sql`** — ⭐ 3 SP phục vụ demo **4 lỗi concurrency** (Chương 5): `SP_DangKyHocPhan_ChuaFix` (thủ tục ban đầu **chưa fix lỗi** — thiếu `FOR UPDATE`), `SP_ChuanBi_Demo_4Anomaly`, `SP_DangKyHocPhan_NangCao`
- **`demo_deadlock.sql`** — ⭐ 3 SP demo **DEADLOCK** dùng **CON TRỎ (CURSOR)** để duyệt & khóa lần lượt từng dòng sĩ số: `SP_Demo_KhoaTheoThuTu` (chỉ khóa, an toàn) · `SP_Demo_PhienGiaoDich` (tái hiện **lỗi thật** đảo thứ tự khóa ĐĂNG KÝ ↔ HỦY, bản chưa fix & đã fix) · `SP_ChuanBi_Demo_Deadlock`
- **`demo_deadlock_chuafix.sql`** — ⚠️ **bản triển khai CÓ LỖI** của `SP_DangKyNhieuHocPhan` (con trỏ khóa theo đúng thứ tự sinh viên tick chọn). Áp file này rồi dùng **2 trình duyệt tick lớp ngược thứ tự** trên trang *Đăng ký lớp học phần* ⇒ **deadlock 1213 hiện thẳng trên giao diện**; chạy lại `procedures/SP_DangKyNhieuHocPhan.sql` để khôi phục
- `danh_muc_hoso_sv_concurrency.sql` — cập nhật hồ sơ SV chống xung đột
- `diem_ketqua_tran.sql` — nhập điểm hàng loạt (rollback nếu 1 dòng lỗi)
- `hocphan_giangvien_molophocphan_transactions.sql` — mở LHP + xếp lịch
- `thu_hoc_phi_transaction.sql`, `phan_tich_concurrency_hoc_phi.sql` — thu/đóng học phí an toàn
- `them_sv_gan_lop_tran.sql` — thêm SV + gán lớp (Atomicity)

> 📜 **TOÀN BỘ SCRIPT DEMO SQL (copy-paste vào 2 cửa sổ):** [`docs/concurrency/script_demo_sql.md`](docs/concurrency/script_demo_sql.md) — **PHẦN A** 4 lỗi concurrency · **PHẦN B** deadlock (tự phát hiện `1213` → tắt phòng chống → **TREO** → bật lại/ngăn ngừa → lỗi thật) · **PHẦN C** demo bằng thao tác thật trên web. **Demo chạy hoàn toàn trên DB — trong code web không có màn hình/API/module demo nào.**
>
> 🔒 **Phân tích & lựa chọn:** [`deadlock_analysis.md`](docs/concurrency/deadlock_analysis.md) (ngăn ngừa vs chấp nhận) · [`deadlock_demo.md`](docs/concurrency/deadlock_demo.md) (cơ chế HQTCSDL) · [`concurrency_anomaly_demo.md`](docs/concurrency/concurrency_anomaly_demo.md) (4 lỗi concurrency).

---

## 6. Các đối tượng Database

> Toàn bộ nằm trong `mysql/` (đã triển khai lên MySQL remote).

### 6.1 Stored Procedure

| SP | Module | Chức năng |
|---|---|---|
| `SP_DangKyHocPhan` | TV3 ⭐ | Đăng ký học phần — 5 bước kiểm tra + ghi nhận (Transaction + FOR UPDATE; **tự retry khi gặp deadlock 1213** → phiên thua luôn nhận mã 105 rõ ràng) |
| `SP_DangKyHocPhan_ChuaFix` | TV3 ⭐ demo | **Bản gốc chưa fix lỗi** (thiếu `FOR UPDATE`) — dùng để demo Lost Update; xem `mysql/transactions/demo_4_anomaly.sql` |
| `SP_HuyDangKy` | TV3 | Hủy đăng ký trong hạn (mã 200–202). **Đã fix deadlock:** khóa `LOPHOCPHAN` **trước** rồi mới đọc `DANGKYHOCPHAN` — cùng thứ tự khóa với `SP_DangKyHocPhan` (xem `docs/concurrency/deadlock_analysis.md`) |
| `SP_DangKyNhieuHocPhan` | TV3 ⭐ | Đăng ký **nhiều học phần trong 1 giao dịch** (tính năng thật trên trang *Đăng ký lớp học phần*: tick chọn nhiều lớp → “Đăng ký N lớp đã chọn”). Dùng **CON TRO** khóa lần lượt từng dòng sĩ số **theo `MaLHP` tăng dần** (khóa theo thứ tự nhất quán ⇒ không thể deadlock). Xem `mysql/procedures/SP_DangKyNhieuHocPhan.sql` |
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
| `SP_ThemMonHocVaTienQuyet` | TV1 | Thêm môn học **+ các môn tiên quyết trong CÙNG 1 GIAO TÁC** (giao tác nằm trong SP; lỗi bất kỳ ⇒ ROLLBACK). `mysql/procedures/web_procedures_3.sql` |
| `SP_GV_NhapDiemHangLoat` | TV4 | Nhập điểm **cả lớp trong 1 GIAO TÁC** bằng **CON TRỎ**; 1 dòng sai ⇒ ROLLBACK cả lô (nguyên tử thật sự). `mysql/procedures/web_procedures_3.sql` |

**SP demo DEADLOCK** (`mysql/transactions/demo_deadlock.sql` — dùng **CON TRO / CURSOR**):

| SP | Chức năng |
|---|---|
| `SP_Demo_KhoaTheoThuTu` | Con trỏ duyệt danh sách `MaLHP`, `SELECT ... FOR UPDATE` lần lượt từng dòng sĩ số rồi `COMMIT`. Tham số `pKieuKhoa`: `'THEO_YEU_CAU'` (khóa theo thứ tự người dùng chọn → **gây deadlock**) hoặc `'SAP_XEP'` (khóa theo `MaLHP` tăng dần → **phòng chống deadlock**). **Chỉ khóa, không ghi dữ liệu** → an toàn để chạy lại nhiều lần. Dùng cho demo **trực tiếp trên HQTCSDL** (2 cửa sổ) |
| `SP_Demo_PhienGiaoDich` | Tái hiện **lỗi thật** đảo thứ tự khóa giữa ĐĂNG KÝ và HỦY: `'DANG_KY_CHUA_FIX'` / `'HUY_CHUA_FIX'` (bản lỗi → `1213`) và `'DANG_KY_DA_FIX'` / `'HUY_DA_FIX'` (cùng thứ tự khóa → không deadlock) |
| `SP_ChuanBi_Demo_Deadlock` | Đưa 2 lớp demo về trạng thái an toàn: xóa đăng ký thử nghiệm của `SV030/SV041`, **tính lại sĩ số thực tế**, tạo 1 dòng `DA_HUY` để kích hoạt nhánh gây deadlock |

**Bản triển khai CÓ LỖI để demo deadlock bằng thao tác thật trên web:** `mysql/transactions/demo_deadlock_chuafix.sql` — định nghĩa lại `SP_DangKyNhieuHocPhan` sao cho **con trỏ khóa theo đúng thứ tự sinh viên tick chọn**. Áp file này → 2 sinh viên tick 2 lớp ngược thứ tự trên trang *Đăng ký lớp học phần* ⇒ **deadlock 1213 hiện thẳng lên giao diện**. Sau khi demo, chạy lại `mysql/procedures/SP_DangKyNhieuHocPhan.sql` để khôi phục.

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

Composite index cho kiểm tra trùng lịch `(MaPhong, Thu, TietBatDau)`, `(MaGV, Thu, TietBatDau)`; non-clustered trên `MaSV`/`MaLHP` (đăng ký), `HoTen`+`MaLopSH` (tra SV), `MaSV` (điểm, học phí), unique `TenDangNhap` (đăng nhập). Xem `mysql/indexes/all_indexes.sql` + `docs/performance/index_benchmark.md`.

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

> **Mã lỗi kinh doanh** (trả kèm HTTP 400): Đăng ký `100–106`, Hủy `200–202`, Thu học phí `301–304`, Thêm SV `401–402`, Chuyển lớp `403–405`.
> **Mã lỗi KHÓA của HQTCSDL** (Chương 5, trả kèm HTTP 409 ở `/dangky/nhieu`): `1213` `ER_LOCK_DEADLOCK` (deadlock — nạn nhân bị rollback), `1205` `ER_LOCK_WAIT_TIMEOUT` (chờ khóa quá lâu).

---

## 8. Frontend — React SPA, 19 màn hình

> 🎨 **Cùng công nghệ với portal.ut.edu.vn**: React 18 + Vite + Material UI (MUI 5) + Redux Toolkit +
> React Router v6 + axios + react-toastify. Nhận diện thương hiệu **Portal UTH — Trường ĐH Giao thông vận tải TP. HCM**
> (logo, teal `#008689`, font Montserrat/Roboto) — topbar + header trắng + thanh menu teal + breadcrumb +
> footer 3 cột, dựng trong `components/PortalLayout.jsx` cho toàn bộ 19 màn hình.
>
> 🔎 **Thuật ngữ & bố cục được đối chiếu từ chính JS bundle công khai của portal thật** (trích ~1.000 chuỗi
> tiếng Việt): "Đăng ký lớp học phần", "Lớp HP đã đăng ký", "Kết quả học tập", "Tiến độ học tập",
> "GV dự kiến", "SS tối đa", "Xếp lịch", "Điểm quá trình/cuối kỳ", "Hệ 4", "Xuất Excel"…

| Nhóm | Route React | Vai trò |
|---|---|---|
| Chung | `/login` (đăng nhập) · `/` (dashboard theo vai trò) | Tất cả |
| Cá nhân | `/thong-tin-ca-nhan` (hồ sơ SV + cập nhật liên hệ) | SV |
| Đăng ký | `/dang-ky` (đăng ký **từng lớp** hoặc **tick chọn nhiều lớp → “Đăng ký N lớp đã chọn”**) · `/thoi-khoa-bieu` · `/dang-ky-cua-toi` · `/huy-dang-ky` | SV |
| Điểm & Học phí | `/bang-diem` · `/hoc-phi` | SV |
| GV | `/lop-cua-toi` · `/nhap-diem` · `/thoi-khoa-bieu-gv` | GV |
| PĐT | `/quan-ly/sinh-vien` · `/quan-ly/khoa-nganh-lop` · `/quan-ly/mon-hoc` · `/quan-ly/mo-lhp` · `/quan-ly/diem-canh-bao` · `/quan-ly/hoc-phi` · `/quan-ly/tai-khoan` | PĐT |

**Cơ chế chung:** `api/client.js` (axios + Bearer JWT, interceptor tự đá về `/login` khi 401) ·
`store/authSlice.js` (Redux Toolkit) · `ProtectedRoute` theo `MaVaiTro` · `theme.js` (design system teal) ·
`react-toastify` cho thông báo · `ConfirmDialog` thay `window.confirm` · modal **Đổi mật khẩu** toàn cục ·
`utils/export.js` — nút **Xuất Excel** (CSV BOM UTF-8) trên các bảng lớn, giống portal thật.

**Đăng nhập (1 bước):**
- `POST /api/auth/login` — tài khoản + mật khẩu (SHA-256) → cấp JWT `{token, user}`; lưu `localStorage`, `ProtectedRoute` giữ phiên.
- `GET /api/auth/hoso` — hồ sơ cá nhân (SV: họ tên, MSSV, ngày sinh, ngành, lớp SH, khoa…) phục vụ dashboard; trigger sinh nhật 🎂 trên dashboard theo `NgaySinh` thật.
- _Ghi chú:_ portal thật dùng OTP 2 bước cho GV/PĐT (qua email trường + reCAPTCHA); bản demo này **tạm bỏ OTP**, đăng nhập trực tiếp bằng mật khẩu.

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

**Cách 1 — Production (1 lệnh, giống deploy thật):**

```bash
cd frontend && npm install && npm run build     # build React → frontend/dist
cd ../backend && npm install && npm start       # Express phục vụ API + frontend/dist
```

Mở trình duyệt: **http://localhost:3000** → SPA React (mọi route không phải `/api` tự fallback `index.html`).

**Cách 2 — Development (hot reload React):**

```bash
cd backend  && npm run dev        # terminal 1 — API :3000
cd frontend && npm run dev        # terminal 2 — Vite :5173 (proxy /api → :3000)
```

Truy cập **http://localhost:5173** để sửa UI nóng; :3000 vẫn chạy bản build gần nhất.

### Tài khoản demo

| Vai trò | Tên đăng nhập | Mật khẩu | Quyền |
|---|---|---|---|
| Sinh viên | `sv001` | `matkhau@123` | Đăng ký, TKB, điểm, học phí |
| Giảng viên | `gv001` | `matkhau@123` | Lớp của tôi, nhập điểm |
| Phòng Đào Tạo | `admin` | `admin@123` | Toàn quyền quản trị |

> 60 tài khoản SV (`sv001`–`sv060`), 15 tài khoản GV (`gv001`–`gv015`) đều dùng mật khẩu `matkhau@123` (SV060 bị khóa để minh họa).
> Đăng nhập 1 bước qua `POST /api/auth/login` (tài khoản + mật khẩu → JWT). OTP 2 bước của portal thật hiện đã tạm bỏ.

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

### Sinh viên (`sv001`…) — nơi diễn ra các demo lỗi
1. **Đăng ký lớp học phần** → tick chọn **một hoặc nhiều lớp** rồi bấm **“Đăng ký N lớp đã chọn”** (1 giao dịch) hoặc **“Đăng ký”** từng lớp.
   * **Lost Update**: 2 trình duyệt cùng bấm giành **suất cuối** (với bản SP chưa fix) → sĩ số vượt.
   * **Deadlock 1213**: 2 trình duyệt tick **2 lớp như nhau nhưng ngược thứ tự** rồi bấm gần như cùng lúc (với bản triển khai `demo_deadlock_chuafix.sql`) → một bạn nhận ngay thông báo *“Xung đột khóa (deadlock 1213)…”* trên giao diện.
2. **Hủy đăng ký HP** → hủy một lớp vừa đăng ký ⇒ dùng cho lỗi thật **đảo thứ tự khóa ĐĂNG KÝ ↔ HỦY**.

> ⚠️ **Trong ứng dụng KHÔNG có màn hình/API/module demo nào.** Mọi kịch bản lỗi được tạo ra hoặc bằng **thao tác thật** của người dùng trên các màn hình nghiệp vụ trên, hoặc bằng **script SQL chạy trực tiếp trên DB**: [`docs/concurrency/script_demo_sql.md`](docs/concurrency/script_demo_sql.md).

---

## 11. Kiểm thử

| Công cụ | Nội dung | Kết quả |
|---|---|---|
| `backend/scripts/test-api.js` | Luồng SV: login → LHP mở → tín chỉ → TKB → điểm → GPA → học phí | ✅ |
| `backend/scripts/e2e-test.js` | **25 test E2E** qua 3 vai trò (auth, đăng ký, điểm, học phí, GV, admin, danh mục) | ✅ 25/25 PASS |
| `backend/scripts/verify-db.js` | Kiểm tra nhanh đối tượng DB (sĩ số, điểm F, học phí, tài khoản, function, view) | ✅ |
| **`backend/scripts/audit-no-raw-query.mjs`** | **Audit v3 — 3 lớp**: (1) quét tĩnh toàn bộ `backend/src`: mọi SQL phải là `CALL SP`/`SET @`/`SELECT @`; (2) đối chiếu SP được gọi với `SHOW PROCEDURE STATUS` trên DB thật; (3) **kiểm tra giao tác** — `backend/src` không được chứa `beginTransaction`/`COMMIT`/`ROLLBACK` | ✅ **100% sạch, KHÔNG còn ngoại lệ** · mọi SP được gọi đều tồn tại · mọi giao tác nằm trong DB |
| Đăng nhập 1 bước | `POST /auth/login` (sai mật khẩu → 401; tài khoản khóa → 403; đúng → cấp JWT) | ✅ |
| `npm run build` (frontend) | Vite build React SPA — 19 route, không lỗi biên dịch | ✅ |
| Trigger | Tự +1/−1 sĩ số khi đăng ký/hủy · tự tính điểm · chặn trùng lịch · chặn xóa ngành | ✅ đã kiểm thử |
| Concurrency | `mysql/transactions/concurrency_test.sql` — 2 session tranh chỗ cuối (kịch bản 2 cửa sổ mysql client) | theo docs |
| Demo SQL (4 lỗi + deadlock) | [`docs/concurrency/script_demo_sql.md`](docs/concurrency/script_demo_sql.md) — chạy trực tiếp trên DB bằng 2 cửa sổ (PHẦN A · B · C) | theo docs |

---

## 12. Tài liệu thiết kế

| Tài liệu | Nội dung |
|---|---|
| `docs/analysis/analysis_dangky_hocphan.md` | Đặc tả 5 ràng buộc + lưu đồ xử lý đăng ký |
| `docs/erd/erd_dangky_hocphan.md` | ERD bảng trung tâm `DANGKYHOCPHAN` |
| `docs/erd/erd_diem_ketqua.md` · `docs/erd/erd_hocphi_taikhoan.md` · `docs/erd/erd_hocphan_giangvien_molophocphan.md` | ERD các module |
| `docs/normalization/` (5 file `normalization_*.md`) | Chứng minh chuẩn hóa 3NF từng module |
| `docs/analysis/Ho_So_Sinh_Vien.md` | Đặc tả dữ liệu module danh mục & hồ sơ SV |
| **`docs/concurrency/script_demo_sql.md`** | ⭐ **TOÀN BỘ SCRIPT DEMO SQL** (chạy trực tiếp trên HQTCSDL bằng 2 cửa sổ): PHẦN A — 4 lỗi concurrency + cách "tắt" phòng chống · PHẦN B — deadlock (tự phát hiện `1213`, tắt `innodb_deadlock_detect`, **TREO**, ngăn ngừa bằng thứ tự khóa, lỗi thật) · PHẦN C — demo bằng thao tác thật trên web · PHẦN D — dọn dẹp |
| `docs/concurrency/isolation_level_analysis.md` | Vì sao READ COMMITTED chưa đủ → chọn khóa phù hợp |
| **`docs/concurrency/concurrency_anomaly_demo.md`** | ⭐ **Báo cáo demo 4 lỗi concurrency**: trạng thái phòng chống của MySQL, cách "tắt" để gây lỗi, cơ chế từng lỗi, kịch bản slide |
| **`docs/concurrency/kich_ban_demo_thao_tac_that.md`** | ⭐ **Kịch bản demo THAO TÁC THẬT trước lớp** (KHÔNG dùng màn hình demo): 2 trình duyệt đăng ký/ hủy cùng lúc + 2 cửa sổ MySQL gõ lệnh tay từng bước — **Màn 1–5**: 4 lỗi concurrency · **Màn 6**: DEADLOCK; kèm bảng dàn bài 1 trang, xử lý sự cố, câu hỏi GV hay hỏi |
| `docs/concurrency/deadlock_analysis.md` | 🔒 **Phân tích DEADLOCK toàn hệ thống** (MySQL-correct): 4 điều kiện Coffman · HQTCSDL hỗ trợ gì & **điểm mù** · 3 tình huống deadlock thật (gồm **lỗi đảo thứ tự khóa** trong source) · **quyết định NGĂN NGỪA hay CHẤP NHẬN** kèm bảng chi phí & lý lẽ · 4 lớp phòng chống |
| **`docs/concurrency/deadlock_demo.md`** | ⭐ **Báo cáo demo DEADLOCK**: HQTCSDL hỗ trợ gì · cách **tắt** cơ chế để demo (và vì sao hosting chặn `SET GLOBAL`) · **phương án thay thế** để thấy TREO · demo **trực tiếp trên HQTCSDL** (2 cửa sổ) · demo **góc độ người dùng bằng thao tác thật trên web** (triển khai bản SP có lỗi → 2 SV tick lớp ngược thứ tự → `1213` → khôi phục bản đã fix) · log thực đo · câu hỏi GV hay hỏi |
| `docs/performance/index_benchmark.md` | Đo hiệu năng trước/sau Index (Chương 3) |
| `docs/testing/trigger_integration_test.md` | Test chuỗi trigger toàn hệ thống |
| `docs/concurrency/concurrency_diem_ketqua.md` | Phân tích concurrency nhập điểm |
| `docs/planning/Backlog_7_Tuan.md` · `docs/planning/Phan_Cong_Nhiem_Vu_De_Tai_6.md` | Kế hoạch & phân công nhóm |
| `docs/erd/So_Do_ERD.docx` | Sơ đồ ERD tổng thể (Word) |
| `docs/reference/Giao_Trinh_He_Quan_Tri_Co_So_Du_Lieu_Full.txt` | Giáo trình tham khảo |

---

## 13. Trạng thái hoàn thiện

- [x] Phân tích nghiệp vụ + ERD + chuẩn hóa 3NF cho cả 5 module (docs)
- [x] DDL 18 bảng + dữ liệu mẫu (60 SV, 15 GV, 48 môn, 46 LHP, 794 lượt đăng ký)
- [x] Chuyển **toàn bộ T-SQL → MySQL** (DDL, data, 9 FN, 12+66 SP, 9 Trigger, 12 View, Index, Transaction, Query, Security)
- [x] Triển khai & chạy trên **MySQL remote** (`free02.123host.vn`)
- [x] Backend **Node.js/Express theo chuẩn MVC** — REST + JWT, **7 nhóm route** (~70 endpoint) qua `routes → controllers → models`, phân quyền 3 vai trò; **không có module/màn hình demo nào trong code web**
- [x] Dọn dẹp & sắp xếp repo: **backend chia 3 lớp MVC** (`routes/` · `controllers/` · `models/`) — **không còn `services/` vì không còn code demo**; **tài liệu tách riêng** trong `docs/` theo chủ đề (analysis/erd/normalization/concurrency/performance/testing/planning/reference); gỡ bộ script T-SQL cũ `sql/` — chỉ giữ bản MySQL `mysql/`
- [x] **Viết lại frontend bằng React 18 + Vite + MUI + Redux Toolkit** — cùng công nghệ portal.ut.edu.vn, 19 màn hình, kết nối DB thật (không mock data)
- [x] Đăng nhập **1 bước** (tài khoản + mật khẩu → JWT) + hồ sơ cá nhân `/auth/hoso` (OTP 2 bước portal thật tạm bỏ)
- [x] Express phục vụ bản build `frontend/dist` (SPA fallback) — 1 tiến trình duy nhất
- [x] SP đăng ký kiểm tra **5 ràng buộc** (mã 100–106) + Transaction chống Lost Update — đã kiểm thử
- [x] **Demo 4 lỗi concurrency (Lost Update · Dirty Read · Unrepeatable Read · Phantom Read) — đã chạy thật trên MySQL remote, 10/10 PASS**; MySQL mặc định (REPEATABLE-READ) chặn 3/4, Lost Update chặn bằng `FOR UPDATE`; có thủ tục "chưa fix lỗi" + kịch bản 2 cửa sổ; **demo trước lớp bằng thao tác thật trên web** (2 trình duyệt đăng ký cùng lúc) và 2 cửa sổ SQL — **không có màn hình demo nào trong ứng dụng**
- [x] **Demo DEADLOCK (Chương 5) — đã chạy thật, 6/6 + 13/13 PASS**: HQTCSDL hỗ trợ gì (đồ thị chờ, tự chọn nạn nhân `1213`, bọc timeout `1205`) · **cách tắt cơ chế để demo** (hosting chặn `SET GLOBAL` vì thiếu `SUPER` → dùng phương án thay thế **khóa dòng ↔ `GET_LOCK`** để thấy **TREO, không thao tác được gì**) · **tìm & sửa lỗi thật**: `SP_HuyDangKy` đảo thứ tự khóa so với `SP_DangKyHocPhan` → deadlock `1213` · **ngăn ngừa** bằng khóa theo thứ tự nhất quán (CON TRO `ORDER BY MaLHP`) · **chấp nhận + retry** `1213`; demo ở **cả góc độ HQTCSDL (2 cửa sổ) và góc độ người dùng (2 trình duyệt tick chọn lớp ngược thứ tự trên trang Đăng ký lớp học phần)**
- [x] Trigger tự tính điểm / cập nhật sĩ số / chặn trùng lịch / chặn xóa ngành / log mật khẩu — đã kiểm thử
- [x] **Tầng web 100% View/Procedure/Function — KHÔNG raw query, KHÔNG tự mở giao tác**: routes/controllers/models chỉ gọi `CALL SP_*` qua `db.js` (helper `sp/spOut/spMulti/spOutFull`); `pool`/`getConnection` **không được export** nên tầng web không có cách nào lấy connection thô. **Mọi giao tác nằm trong Stored Procedure** (kể cả 2 nghiệp vụ hàng loạt `SP_ThemMonHocVaTienQuyet`, `SP_GV_NhapDiemHangLoat`). Kiểm chứng: `node scripts/audit-no-raw-query.mjs` → **PASS, không còn ngoại lệ**
- [x] E2E: 25/25 PASS, sĩ số nhất quán sau đăng ký–hủy

---

## 📜 Ghi chú triển khai

- **Charset:** database đặt `utf8mb4_unicode_ci` (đã đổi từ mặc định latin1 của hosting) để lưu đúng tiếng Việt trong SP/Trigger/View.
- **T-SQL → MySQL:** `UPDLOCK+HOLDLOCK` → `SELECT ... FOR UPDATE`; `GETDATE()` → `NOW()`; `GO` → tách statement (script runner `init-db.js` tự xử lý DELIMITER); `NVARCHAR` → `VARCHAR` (utf8mb4).
- **Phân quyền:** trên MySQL 5.7 shared hosting không có `CREATE ROLE`, nên GRANT mẫu đi kèm và quyền thực thi nằm ở middleware JWT của backend.
- **Tầng web chỉ gọi SP:** mọi route đi qua 4 helper trong `backend/src/db.js` — `sp()` (1 result set), `spMulti()` (nhiều result set), `spOut()`/`spOutFull()` (SP có tham số OUT `@KetQua`, tự thêm `SELECT @KetQua` và chạy cùng connection). `db.js` **không export pool/getConnection** ⇒ không thể raw query hay tự mở giao tác. Định nghĩa SP: `mysql/procedures/web_procedures.sql` + `web_procedures_2.sql` + `web_procedures_3.sql` (2 SP giao tác); view: `mysql/views/web_views.sql`. **Mọi demo nằm ở tầng DB** — xem `docs/concurrency/script_demo_sql.md`.
