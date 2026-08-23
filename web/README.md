# 🖥️ ỨNG DỤNG WEB — HỆ THỐNG ĐĂNG KÝ HỌC PHẦN TÍN CHỈ

> **Module:** Đăng ký học phần (TV3 — Leader) + toàn bộ 5 module nghiệp vụ
> **Trạng thái:** ✅ Đã kết nối **MySQL remote** qua backend Node.js/Express (không còn mock data)

## Cấu trúc

```
web/
├── login.html                   # Đăng nhập (SV / GV / PĐT — JWT)
├── index.html                   # Dashboard theo vai trò
├── css/shared.css               # 🎨 TEMPLATE UI CHUNG (design system)
├── js/
│   ├── api.js                   # API client (fetch + JWT + localStorage)
│   ├── shared.js                # Hàm chung: toast, format, esc, auth guard, menu theo vai trò
│   └── dangky.js                # Logic đăng ký học phần (gọi API thật)
└── app/
    ├── dangky_hocphan/          # SV: đăng ký, TKB, danh sách ĐK, hủy ĐK
    ├── diem/                    # SV: bảng điểm & GPA/CPA
    ├── hocphi/                  # SV: học phí của tôi — PĐT: quản lý học phí
    ├── giangvien/               # GV: lớp của tôi, nhập điểm, TKB
    ├── danhmuc/                 # PĐT: quản lý SV, Khoa·Ngành·Lớp, CTĐT
    ├── hocphan/                 # PĐT: môn học·GV·phòng, mở LHP
    └── admin/                   # PĐT: dashboard, tài khoản
```

## Cách chạy

```bash
cd backend
npm install
npm start
# mở trình duyệt: http://localhost:3000  (backend phục vụ luôn thư mục web/)
```

> Backend Express tự động phục vụ `web/` (xem `backend/server.js`), nên chỉ cần chạy `npm start` là đủ.

## Tài khoản demo

| Vai trò | Tên đăng nhập | Mật khẩu |
|---|---|---|
| Sinh viên | `sv001` | `matkhau@123` |
| Giảng viên | `gv001` | `matkhau@123` |
| Phòng Đào Tạo | `admin` | `admin@123` |

## Liên kết UI ↔ Database (MySQL)

| Chức năng UI | API/SP/View |
|---|---|
| Danh sách LHP đang mở | `GET /api/dangky/lopmo` → `LOPHOCPHAN WHERE TrangThaiLop='MO_DANG_KY'` |
| Đăng ký | `POST /api/dangky` → `SP_DangKyHocPhan` (mã lỗi 0/100..106) |
| Hủy đăng ký | `POST /api/dangky/huy` → `SP_HuyDangKy` (mã lỗi 0/200..202) |
| Thời khóa biểu | `GET /api/dangky/thoikhoabieu` → `VW_ThoiKhoaBieuCaNhan` |
| Danh sách đăng ký | `GET /api/dangky/danhsach` → `VW_SinhVienDangKyChiTiet` |
| Kiểm tra tiên quyết | `FN_KiemTraTienQuyet(MaSV, MaMonHoc)` |
| Kiểm tra trùng lịch | `FN_KiemTraTrungLichHoc(MaSV, MaLHP)` |
| Tổng tín chỉ | `FN_TinhTongTinChi(MaSV, MaHocKy)` |
| Bảng điểm | `GET /api/ketqua/bangdiem` → `V_BANGDIEM_SINHVIEN` |
| GPA/CPA | `SP_TinhGPA_HocKy`, `SP_TinhCPA_TichLuy` |
| Học phí | `GET /api/hocphi/cua-toi` · `POST /api/hocphi/thu` → `SP_ThuHocPhi` |
| Nhập điểm GV | `POST /api/giangvien/nhapdiem` → `SP_GV_NHAP_DIEM` |
| Mở LHP | `POST /api/admin/molophocphan` → `SP_MoLopHocPhan` |
| Thêm SV | `POST /api/admin/themsinhvien` → `SP_ThemSinhVien_Moi` |
| Chuyển lớp | `POST /api/danhmuc/sinhvien/chuyenlop` → `SP_ChuyenLop_Nganh` |

## Mã lỗi giao diện ↔ SP

| UI hiển thị | Mã SP | Ràng buộc |
|---|---|---|
| ⏰ Hết hạn đăng ký | `100` | Hạn đăng ký |
| 🔁 Đã đăng ký rồi | `101` | Trùng LHP |
| 📚 Thiếu tiên quyết | `102` | Môn tiên quyết |
| 📅 Trùng lịch | `103` | Trùng lịch học |
| 📊 Vượt tín chỉ | `104` | Min-Max tín chỉ |
| 👥 Lớp đầy | `105` | Sĩ số |
| ❓ Không tồn tại LHP | `106` | Xác thực LHP |
