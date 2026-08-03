# 🖥️ ỨNG DỤNG WEB — MODULE ĐĂNG KÝ HỌC PHẦN

> **Module:** Đăng ký học phần (TV3 — Leader)  
> **Issue:** #71 Giao diện Đăng ký học phần (UX phức tạp nhất) + #72 Template UI chung

## Cấu trúc

```
web/
├── index.html                     # Trang chủ / Dashboard
├── css/shared.css                 # 🎨 TEMPLATE UI CHUNG (cả nhóm dùng)
├── js/
│   ├── shared.js                  # Hàm dùng chung (toast, format, escape)
│   ├── mock-data.js               # Dữ liệu mẫu (khớp sql/data/)
│   └── dangky.js                  # Logic đăng ký (5 ràng buộc + mã lỗi SP)
└── app/dangky_hocphan/            # 4 màn hình chức năng TV3
    ├── dang-ky.html               # Màn 1: Chọn LHP + Giỏ đăng ký
    ├── thoi-khoa-bieu.html        # Màn 2: Thời khóa biểu cá nhân
    ├── danh-sach-dang-ky.html     # Màn 3: Danh sách + tóm tắt tín chỉ
    └── huy-dang-ky.html           # Màn 4: Xem/Hủy đăng ký + mã lỗi
```

## Cách chạy (demo front-end)

```bash
cd web
python -m http.server 8080
# mở trình duyệt: http://localhost:8080
```

Hoặc chỉ cần mở `web/index.html` trực tiếp bằng trình duyệt (không cần server vì dữ liệu là JS mock).

## Liên kết với Database (gợi ý tích hợp)

Hiện giao diện dùng **mock data** (`js/mock-data.js`) để demo. Khi nối DB thật, thay các hàm trong `js/dangky.js` bằng `fetch` tới API:

| Chức năng UI | SP/View tương ứng trong SQL |
|---|---|
| Danh sách LHP đang mở | `SELECT ... FROM LOPHOCPHAN WHERE TrangThaiLop = 'MO_DANG_KY'` |
| Đăng ký | `SP_DangKyHocPhan` (mã lỗi 0/100..106) |
| Hủy đăng ký | `SP_HuyDangKy` (mã lỗi 0/200..202) |
| Thời khóa biểu | `VW_ThoiKhoaBieuCaNhan` |
| Danh sách đăng ký | `VW_SinhVienDangKyChiTiet` |
| Kiểm tra tiên quyết | `FN_KiemTraTienQuyet(MaSV, MaMonHoc)` |
| Kiểm tra trùng lịch | `FN_KiemTraTrungLichHoc(MaSV, MaLHP)` |
| Tổng tín chỉ | `FN_TinhTongTinChi(MaSV, MaHocKy)` |

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
