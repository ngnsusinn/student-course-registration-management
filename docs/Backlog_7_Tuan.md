# 📋 BACKLOG 7 TUẦN — ĐỀ TÀI 6: QUẢN LÝ SINH VIÊN ĐĂNG KÝ HỌC PHẦN TÍN CHỈ

> **Nhóm 5 thành viên** | **Leader: TV3 (Đăng ký học phần — nghiệp vụ lõi)**
>
> Mỗi tuần có 1 **Milestone** trên GitHub. Mỗi đầu việc tương ứng 1 **Issue** gán cho thành viên cụ thể.
> Label gợi ý: `priority: critical` · `priority: high` · `priority: medium` · `database` · `backend` · `frontend` · `docs` · `review` · `integration`

---

## 📌 QUY ƯỚC

| Ký hiệu | Ý nghĩa |
|---|---|
| 🔴 | Việc khó / phức tạp cao — ưu tiên giao cho Leader (TV3) |
| 🟡 | Việc trung bình |
| 🟢 | Việc cơ bản |
| ⭐ | Việc bổ sung của Leader (review, điều phối, kiến trúc) |
| 📎 | Sản phẩm bàn giao (Deliverable) |

---

## TUẦN 1 — PHÂN TÍCH NGHIỆP VỤ & THIẾT KẾ ERD

> **Milestone:** `Week 1 — Analysis & ERD`
> **Mục tiêu:** Hoàn thành phân tích nghiệp vụ toàn bộ hệ thống + ERD riêng từng module + ERD tổng thể ráp nối.

### 👤 TV1 — Danh mục hệ thống & Hồ sơ sinh viên

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 1 | 🟢 Phân tích nghiệp vụ Danh mục hệ thống & Hồ sơ sinh viên | Khảo sát quy trình quản lý Khoa/Ngành/Lớp/Hồ sơ SV; liệt kê thuộc tính, ràng buộc (SV→Lớp→Ngành→Khoa) | `database`, `docs` | `docs/analysis_danh_muc_hoso_sv.md` |
| 2 | 🟡 Thiết kế ERD Danh mục hệ thống & Hồ sơ sinh viên | Vẽ ERD cho 5 bảng: KHOA, NGANH, LOP_SINHHOAT, SINHVIEN, CHUONGTRINHDAOTAO. Xác định FK liên module | `database` | `docs/erd_danh_muc_hoso_sv.png` |

### 👤 TV2 — Học phần, Giảng viên & Mở lớp học phần

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 3 | 🟢 Phân tích nghiệp vụ Học phần, Giảng viên & Mở lớp học phần | Khảo sát quy trình mở học phần mỗi kỳ, gán môn tiên quyết, phân công GV, xếp phòng | `database`, `docs` | `docs/analysis_hocphan_giangvien.md` |
| 4 | 🟡 Thiết kế ERD Học phần, Giảng viên & Mở lớp học phần | ERD cho 7 bảng: GIANGVIEN, MONHOC, MONHOC_TIENQUYET, HOCKY, PHONGHOC, LOPHOCPHAN, LICHHOC | `database` | `docs/erd_hocphan_giangvien.png` |

### 👤 TV3 — Đăng ký học phần *(Leader)* ⭐

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 5 | 🔴 Phân tích nghiệp vụ Đăng ký học phần (nghiệp vụ lõi) | Phân tích **5 ràng buộc đăng ký** chi tiết: hạn đăng ký, sĩ số, tiên quyết, trùng lịch, min-max tín chỉ. Vẽ **lưu đồ xử lý** (flowchart) cho toàn bộ quy trình đăng ký | `database`, `docs`, `priority: critical` | `docs/analysis_dangky_hocphan.md` + `docs/flowchart_dangky.png` |
| 6 | 🔴 Thiết kế ERD Đăng ký học phần & Liên kết hệ thống | ERD bảng trung tâm DANGKYHOCPHAN. Xác định **toàn bộ FK tới** SINHVIEN, LOPHOCPHAN và các bảng phụ thuộc gián tiếp | `database`, `priority: critical` | `docs/erd_dangky_hocphan.png` |
| 7 | ⭐ Thiết kế kiến trúc tổng thể & quy ước đặt tên | Định nghĩa naming convention (bảng, cột, FK, Index, SP); cấu trúc thư mục Git; quy ước commit message; template branch | `docs`, `review` | `docs/conventions.md` + `.github/ISSUE_TEMPLATE/` |
| 8 | ⭐ Review & ráp nối ERD tổng thể | Thu thập ERD 5 module (Danh mục, Học phần, Đăng ký, Điểm, Học phí) → ráp nối thành ERD tổng 18 bảng. Rà soát tính nhất quán FK liên module. **Chủ trì họp nhóm review** | `review`, `integration`, `priority: critical` | `docs/erd_total.png` |

### 👤 TV4 — Điểm số & Kết quả học tập

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 9 | 🟢 Phân tích nghiệp vụ Điểm số & Kết quả học tập | Xác định trọng số điểm (10% CC – 30% GK – 60% CK), thang điểm chữ, quy đổi hệ 4, điều kiện cảnh báo học vụ | `database`, `docs` | `docs/analysis_diem_ketqua.md` |
| 10 | 🟡 Thiết kế ERD Điểm số & Kết quả học tập | ERD cho 2 bảng: KETQUAHOCTAP, THANGDIEMCHU. Liên kết với DANGKYHOCPHAN (thống nhất khóa với TV3) | `database` | `docs/erd_diem_ketqua.png` |

### 👤 TV5 — Học phí, Tài khoản & Vận hành hệ thống

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 11 | 🟢 Phân tích nghiệp vụ Học phí, Tài khoản & Vận hành | Đơn giá tín chỉ, quy trình đóng học phí, 3 nhóm vai trò (SV/GV/PĐT), chính sách backup | `database`, `docs` | `docs/analysis_hocphi_taikhoan.md` |
| 12 | 🟡 Thiết kế ERD Học phí, Tài khoản & Vận hành | ERD cho 3 bảng: HOCPHI, TAIKHOAN, VAITRO. Liên kết TAIKHOAN với SINHVIEN/GIANGVIEN | `database` | `docs/erd_hocphi_taikhoan.png` |

---

## TUẦN 2 — CHUẨN HÓA & DDL (CREATE TABLE)

> **Milestone:** `Week 2 — Normalization & DDL`
> **Mục tiêu:** Chuẩn hóa 3NF tất cả bảng + viết toàn bộ script DDL + dữ liệu mẫu cơ bản.

### 👤 TV1 — Danh mục hệ thống & Hồ sơ sinh viên

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 13 | 🟡 Chuẩn hóa 3NF Danh mục hệ thống & Hồ sơ sinh viên | Kiểm tra phụ thuộc hàm 5 bảng. Tách CHUONGTRINHDAOTAO thành bảng trung gian Ngành–Môn–HK nếu cần | `database` | `docs/normalization_danh_muc_hoso_sv.md` |
| 14 | 🟢 Viết DDL Danh mục hệ thống & Hồ sơ sinh viên | CREATE TABLE 5 bảng: PK, FK (ON DELETE NO ACTION cho Khoa→Ngành), CHECK (GioiTinh, TrangThai), DEFAULT | `database` | `sql/ddl/danh_muc_hoso_sv_ddl.sql` |
| 15 | 🟢 Dữ liệu mẫu Danh mục hệ thống & Hồ sơ sinh viên | ≥ 3 Khoa, 6 Ngành, 10 Lớp, 60 SV, CTĐT mẫu 1 ngành | `database` | `sql/data/danh_muc_hoso_sv_data.sql` |

### 👤 TV2 — Học phần, Giảng viên & Mở lớp học phần

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 16 | 🟡 Chuẩn hóa 3NF Học phần, Giảng viên & Mở lớp học phần | Xử lý MONHOC_TIENQUYET (nhiều-nhiều tự tham chiếu); tách LICHHOC khỏi LOPHOCPHAN (1 LHP có nhiều buổi/tiết) | `database` | `docs/normalization_hocphan_giangvien.md` |
| 17 | 🟢 Viết DDL Học phần, Giảng viên & Mở lớp học phần | 7 bảng: CHECK SoTinChi > 0, SucChua > 0; ON DELETE CASCADE cho LICHHOC khi xóa LOPHOCPHAN | `database` | `sql/ddl/hocphan_giangvien_ddl.sql` |
| 18 | 🟢 Dữ liệu mẫu Học phần, Giảng viên & Mở lớp học phần | ≥ 15 GV, 40 môn học + tiên quyết, 3 HK, 20 phòng, 80 LHP có lịch đầy đủ | `database` | `sql/data/hocphan_giangvien_data.sql` |

### 👤 TV3 — Đăng ký học phần *(Leader)* ⭐

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 19 | 🔴 Chuẩn hóa 3NF Đăng ký học phần | PK ghép (MaSV, MaLHP). **Không lưu** SoTinChi/TenMH trong bảng (tránh dư thừa) — truy xuất qua JOIN. Chứng minh đạt 3NF | `database`, `priority: critical` | `docs/normalization_dangky_hocphan.md` |
| 20 | 🔴 Viết DDL Đăng ký học phần | CREATE TABLE: PK ghép, 2 FK, CHECK TrangThai, UNIQUE(MaSV, MaLHP) chống đăng ký trùng. **Thiết kế cần tính trước cho Transaction ở tuần 5** | `database`, `priority: critical` | `sql/ddl/dangky_hocphan_ddl.sql` |
| 21 | 🟡 Dữ liệu mẫu Đăng ký học phần | Dữ liệu đăng ký cho 60 SV × ≥ 2 HK. **Tạo tình huống biên**: sát sĩ số max, sát hạn đăng ký | `database` | `sql/data/dangky_hocphan_data.sql` |
| 22 | ⭐ Review DDL toàn bộ các module hệ thống | Rà soát DDL cả nhóm: kiểm tra FK liên module nhất quán, naming convention, kiểu dữ liệu thống nhất. **Merge script tổng** | `review`, `integration`, `priority: high` | `sql/ddl/00_all_tables.sql` |
| 23 | ⭐ Thiết lập script khởi tạo DB | Viết script tổng: CREATE DATABASE → chạy DDL theo thứ tự dependency → INSERT data mẫu. Đảm bảo 1 lệnh chạy xong toàn bộ | `database`, `integration` | `sql/init_database.sql` |

### 👤 TV4 — Điểm số & Kết quả học tập

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 24 | 🟡 Chuẩn hóa 3NF Điểm số & Kết quả học tập | Cân nhắc: lưu DiemChu/DiemHe4 hay tính runtime? Tách THANGDIEMCHU làm bảng tra cứu | `database` | `docs/normalization_diem_ketqua.md` |
| 25 | 🟢 Viết DDL Điểm số & Kết quả học tập | CHECK điểm ∈ [0,10]; ràng buộc NOT NULL hợp lý theo trạng thái hoàn thành | `database` | `sql/ddl/diem_ketqua_ddl.sql` |
| 26 | 🟢 Dữ liệu mẫu Điểm số & Kết quả học tập | Điểm cho SV đã đăng ký (dùng chung data TV3). Đủ case: giỏi, rớt, chưa có điểm | `database` | `sql/data/diem_ketqua_data.sql` |

### 👤 TV5 — Học phí, Tài khoản & Vận hành hệ thống

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 27 | 🟡 Chuẩn hóa 3NF Học phí, Tài khoản & Vận hành | VAITRO tách riêng khỏi TAIKHOAN (tránh lặp chuỗi). Kiểm tra phụ thuộc hàm 3 bảng | `database` | `docs/normalization_hocphi_taikhoan.md` |
| 28 | 🟢 Viết DDL Học phí, Tài khoản & Vận hành | HOCPHI: CHECK ThanhTien ≥ 0; TAIKHOAN: UNIQUE TenDangNhap, lưu mật khẩu hash, FK SV hoặc GV | `database` | `sql/ddl/hocphi_taikhoan_ddl.sql` |
| 29 | 🟢 Dữ liệu mẫu Học phí, Tài khoản & Vận hành | Đơn giá mẫu 2–3 ngành, học phí cho SV đã đăng ký, tài khoản 3 vai trò | `database` | `sql/data/hocphi_taikhoan_data.sql` |

---

## TUẦN 3 — QUERY, VIEW & STORED PROCEDURE

> **Milestone:** `Week 3 — Queries, Views & Stored Procedures`
> **Mục tiêu:** Viết truy vấn nâng cao, tạo View, viết Stored Procedure/Function cho từng module.

### 👤 TV1 — Danh mục hệ thống & Hồ sơ sinh viên

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 30 | 🟢 Truy vấn & View Danh mục hệ thống & Hồ sơ sinh viên | ≥ 5 SELECT phức tạp: SV theo Khoa/Ngành/Lớp + sĩ số, SV chưa xếp lớp, tra cứu CTĐT. 1 View danh sách SV đang học | `database` | `sql/queries/danh_muc_hoso_sv_queries.sql` |
| 31 | 🟡 Stored Procedure & Function Thêm SV, Chuyển Lớp/Ngành & Đếm Sĩ Số | SP thêm SV kiểm tra lớp tồn tại; SP chuyển lớp/ngành; Function đếm sĩ số lớp | `database` | `sql/procedures/danh_muc_hoso_sv_sp.sql` |

### 👤 TV2 — Học phần, Giảng viên & Mở lớp học phần

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 32 | 🟡 Truy vấn & View Học phần, Giảng viên & Mở lớp học phần | LHP theo HK + sĩ số còn trống; tra môn tiên quyết; TKB theo GV/phòng; kiểm tra phòng trống theo khung giờ | `database` | `sql/queries/hocphan_giangvien_queries.sql` |
| 33 | 🟡 Stored Procedure & Function Mở Lớp Học Phần & Kiểm Tra Phòng Trống | SP mở LHP (kiểm tra GV/phòng không trùng lịch); Function kiểm tra phòng trống (phòng, thứ, tiết) | `database` | `sql/procedures/hocphan_giangvien_sp.sql` |

### 👤 TV3 — Đăng ký học phần *(Leader)* ⭐

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 34 | 🔴 Truy vấn & View Đăng ký học phần (phức tạp nhất) | ≥ 6 SELECT: SV đã ĐK theo LHP, SV chưa đủ/vượt tín chỉ, **kiểm tra tiên quyết bằng subquery/EXISTS**, TKB cá nhân, thống kê ĐK theo HK | `database`, `priority: critical` | `sql/queries/dangky_hocphan_queries.sql` |
| 35 | 🔴 SP `DangKyHocPhan` — nghiệp vụ lõi | SP gộp **đủ 5 bước kiểm tra** trước khi ghi nhận đăng ký. Mỗi bước trả error message cụ thể. Thiết kế sẵn cho Transaction (tuần 5) | `database`, `priority: critical` | `sql/procedures/sp_dangky.sql` |
| 36 | 🔴 SP `HuyDangKy` + Function kiểm tra tiên quyết | SP hủy ĐK (kiểm tra còn hạn hủy); Function `fn_CheckTienQuyet(MaSV, MaMonHoc)` trả BIT | `database`, `priority: high` | `sql/procedures/sp_huydangky.sql` |
| 37 | ⭐ Review SP & Function liên kết giữa các module | Rà soát SP/Function các module: đảm bảo logic liên module nhất quán (VD: SP ĐK gọi đúng Function kiểm tra tiên quyết qua data TV2) | `review`, `integration` | Review comments trên PR |

### 👤 TV4 — Điểm số & Kết quả học tập

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 38 | 🟡 Truy vấn & View Điểm số & Kết quả học tập | Bảng điểm cá nhân theo HK; SV theo xếp loại; điểm cao/thấp nhất (RANK/TOP); tỷ lệ đạt/không đạt (GROUP BY/HAVING) | `database` | `sql/queries/diem_ketqua_queries.sql` |
| 39 | 🟡 Function tính điểm tổng kết & quy đổi thang điểm | Function tính DiemTongKet theo trọng số; Function quy đổi DiemTongKet → DiemChu → DiemHe4 (qua THANGDIEMCHU) | `database` | `sql/procedures/diem_ketqua_functions.sql` |
| 40 | 🟡 SP tính GPA học kỳ & tích lũy | SP tính GPA HK và GPA tích lũy cho từng SV. Xử lý case: môn học lại chỉ tính lần cao nhất | `database` | `sql/procedures/sp_gpa.sql` |

### 👤 TV5 — Học phí, Tài khoản & Vận hành hệ thống

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 41 | 🟡 Truy vấn & View Học phí & Báo cáo Thống kê Vận hành | SV nợ học phí; tổng thu theo HK/Ngành; **báo cáo thống kê tổng hợp** (liên kết data từ các module khác) | `database` | `sql/queries/hocphi_taikhoan_queries.sql` |
| 42 | 🟡 SP tính học phí + tạo tài khoản tự động | SP tính học phí khi SV ĐK thành công; SP tạo tài khoản tự động khi thêm SV/GV mới | `database` | `sql/procedures/hocphi_taikhoan_sp.sql` |

---

## TUẦN 4 — TRIGGER, INDEX & BẢO MẬT

> **Milestone:** `Week 4 — Triggers, Indexes & Security`
> **Mục tiêu:** Hoàn thành Trigger cho toàn bộ module + thiết kế Index tối ưu + phân quyền GRANT/REVOKE.

### 👤 TV1 — Danh mục hệ thống & Hồ sơ sinh viên

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 43 | 🟢 Trigger Chặn xóa Ngành đào tạo khi còn Sinh viên | Trigger chặn xóa Ngành khi còn SV thuộc ngành | `database` | `sql/triggers/danh_muc_hoso_sv_triggers.sql` |
| 44 | 🟢 Non-clustered Index Tìm kiếm Sinh viên theo Họ tên & Lớp | Non-clustered Index trên HoTen (tìm kiếm SV) và MaLop. Giải thích lựa chọn loại index | `database` | `sql/indexes/danh_muc_hoso_sv_indexes.sql` |

### 👤 TV2 — Học phần, Giảng viên & Mở lớp học phần

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 45 | 🔴 Trigger chặn trùng lịch (phức tạp) | **Trigger chặn INSERT/UPDATE LICHHOC nếu trùng phòng hoặc trùng GV cùng khung giờ** — ràng buộc liên dòng, không thể dùng CHECK | `database`, `priority: high` | `sql/triggers/hocphan_giangvien_triggers.sql` |
| 46 | 🟡 Composite Index Tối ưu kiểm tra Trùng Lịch học & Giảng viên | Composite Non-clustered Index: (MaPhong, Thu, TietBatDau) và (MaGV, Thu, TietBatDau) — tăng tốc kiểm tra trùng lịch | `database` | `sql/indexes/hocphan_giangvien_indexes.sql` |

### 👤 TV3 — Đăng ký học phần *(Leader)* ⭐

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 47 | 🔴 Trigger tự động cập nhật sĩ số LHP | **Trigger tự +1/−1 SiSoHienTai của LOPHOCPHAN** mỗi khi có INSERT/DELETE trên DANGKYHOCPHAN. Xử lý edge case: UPDATE TrangThai | `database`, `priority: critical` | `sql/triggers/dangky_hocphan_triggers.sql` |
| 48 | 🔴 Non-clustered Index Đăng ký học phần & Đo hiệu năng | Non-clustered Index riêng trên MaSV và MaLHP. **Đo tốc độ truy vấn trước/sau khi có index** (SET STATISTICS TIME/IO). Viết báo cáo | `database`, `priority: high` | `sql/indexes/dangky_hocphan_indexes.sql` + `docs/index_benchmark.md` |
| 49 | ⭐ Review Trigger toàn bộ các module hệ thống | Kiểm tra Trigger không xung đột lẫn nhau (VD: trigger TV3 cập nhật LHP → trigger TV2 có bị kích hoạt lại không?). Test tích hợp trigger chain | `review`, `integration`, `priority: high` | Review comments + `docs/trigger_integration_test.md` |

### 👤 TV4 — Điểm số & Kết quả học tập

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 50 | 🔴 Trigger tự động tính điểm tổng kết & điểm chữ | **Trigger tự tính lại DiemTongKet & DiemChu ngay khi GV cập nhật bất kỳ điểm thành phần nào** (AFTER UPDATE) | `database`, `priority: high` | `sql/triggers/diem_ketqua_triggers.sql` |
| 51 | 🟢 Non-clustered Index Tra cứu Bảng điểm Cá nhân & Theo Lớp | Non-clustered Index trên MaSV (bảng điểm cá nhân) và MaLHP (điểm theo lớp cho GV) | `database` | `sql/indexes/diem_ketqua_indexes.sql` |

### 👤 TV5 — Học phí, Tài khoản & Vận hành hệ thống

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 52 | 🟡 Trigger ghi log đổi mật khẩu tài khoản | Trigger ghi log mỗi lần thay đổi mật khẩu trên TAIKHOAN (ghi thời gian, IP nếu có) | `database` | `sql/triggers/hocphi_taikhoan_triggers.sql` |
| 53 | 🟢 Non-clustered Index Tra cứu Học phí & Mới Đăng nhập | Non-clustered Index trên MaSV (HOCPHI); Unique Index trên TenDangNhap (TAIKHOAN) | `database` | `sql/indexes/hocphi_taikhoan_indexes.sql` |
| 54 | 🔴 Thiết lập GRANT/REVOKE 3 vai trò (Sinh viên, Giảng viên, PĐT) | **Cấu hình quyền**: SV chỉ SELECT bảng điểm chính mình (qua View), GV INSERT/UPDATE điểm lớp mình, PĐT full quyền. Script GRANT/REVOKE cụ thể | `database`, `priority: high` | `sql/security/grant_revoke.sql` |

---

## TUẦN 5 — TRANSACTION & CONCURRENCY CONTROL

> **Milestone:** `Week 5 — Transactions & Concurrency`
> **Mục tiêu:** Đóng gói giao dịch cho tất cả module + phân tích/demo tình huống cạnh tranh. **Đây là tuần trọng tâm của Leader (TV3).**

### 👤 TV1 — Danh mục hệ thống & Hồ sơ sinh viên

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 55 | 🟡 Transaction Thêm Sinh viên mới & Gán Lớp sinh hoạt | Giao dịch "Thêm SV mới + gán lớp" đảm bảo Atomicity (rollback nếu lớp không tồn tại) | `database` | `sql/transactions/danh_muc_hoso_sv_tran.sql` |
| 56 | 🟡 Phân tích Concurrency Cập nhật Hồ sơ Sinh viên đồng thời | Phân tích: 2 nhân viên cùng sửa hồ sơ 1 SV → đề xuất Chốt phù hợp (Shared/Exclusive) | `database`, `docs` | `docs/concurrency_danh_muc_hoso_sv.md` |

### 👤 TV2 — Học phần, Giảng viên & Mở lớp học phần

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 57 | 🟡 Transaction "Mở LHP + xếp lịch" | Đóng gói trong 1 Transaction, rollback nếu phát hiện trùng lịch | `database` | `sql/transactions/hocphan_giangvien_tran.sql` |
| 58 | 🟡 Demo concurrency trùng phòng học | Demo 2 cán bộ cùng xếp 2 lớp vào 1 phòng cùng giờ → giải quyết bằng Chốt X trên khung giờ/phòng | `database`, `docs` | `docs/concurrency_hocphan_giangvien.md` + ảnh minh chứng |

### 👤 TV3 — Đăng ký học phần *(Leader)* ⭐

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 59 | 🔴 Transaction đăng ký học phần (Atomicity) | Đóng gói toàn bộ SP `DangKyHocPhan` trong Transaction. Đảm bảo "kiểm tra sĩ số" + "ghi nhận đăng ký" là **nguyên tử** — tránh Lost Update khi 2 SV cùng ĐK chỗ cuối cùng | `database`, `priority: critical` | `sql/transactions/dangky_hocphan_tran.sql` |
| 60 | 🔴 Thiết kế mức cô lập (Isolation Level) cho đăng ký | Chọn mức cô lập phù hợp (SERIALIZABLE / REPEATABLE READ). Áp dụng Chốt Độc quyền (X) hoặc UPDLOCK, HOLDLOCK. **Giải thích tại sao** READ COMMITTED không đủ | `database`, `priority: critical`, `docs` | `docs/isolation_level_analysis.md` |
| 61 | 🔴 Kịch bản test 2 session đồng thời | **Viết kịch bản test** 2 phiên (session) đăng ký đồng thời vào LHP sắp hết chỗ. Ghi lại minh chứng (ảnh/video). Chứng minh hệ thống xử lý đúng | `database`, `priority: critical` | `sql/transactions/concurrency_test.sql` + `docs/concurrency_demo/` (ảnh/video) |
| 62 | ⭐ Phân tích Deadlock toàn hệ thống | Giả lập tình huống deadlock (VD: SV1 ĐK môn A rồi B, SV2 ĐK môn B rồi A). Đề xuất cách phòng tránh (consistent ordering). **Viết báo cáo cho cả nhóm** | `database`, `docs`, `priority: high` | `docs/deadlock_analysis.md` |
| 63 | ⭐ Review Transaction toàn bộ các module hệ thống | Kiểm tra tất cả Transaction: đúng TRY-CATCH, đúng ROLLBACK, không quên COMMIT, mức cô lập phù hợp | `review`, `integration` | Review comments trên PR |

### 👤 TV4 — Điểm số & Kết quả học tập

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 64 | 🟡 Transaction nhập điểm hàng loạt | Rollback toàn bộ nếu 1 dòng lỗi (tránh nhập dở dang). TRY-CATCH | `database` | `sql/transactions/diem_ketqua_tran.sql` |
| 65 | 🟡 Phân tích Concurrency Cập nhật Điểm số đồng thời | GV và Trưởng bộ môn cùng sửa điểm 1 SV → dùng Chốt X hoặc timestamp kiểm tra | `database`, `docs` | `docs/concurrency_diem_ketqua.md` |

### 👤 TV5 — Học phí, Tài khoản & Vận hành hệ thống

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 66 | 🟡 Transaction thu học phí sinh viên | Giao dịch thu học phí: cập nhật trạng thái + ghi nhận thanh toán. Phân tích đụng độ 2 tiến trình cùng cập nhật | `database` | `sql/transactions/hocphi_taikhoan_tran.sql` |
| 67 | 🟡 Phân tích Concurrency Cập nhật Thanh toán Học phí | 2 tiến trình cùng cập nhật trạng thái đóng học phí → giải quyết | `database`, `docs` | `docs/concurrency_hocphi_taikhoan.md` |

---

## TUẦN 6 — BACKUP/RESTORE, GIAO DIỆN & TÍCH HỢP

> **Milestone:** `Week 6 — Recovery, UI & Integration`
> **Mục tiêu:** Demo Backup/Restore (Chương 6) + xây dựng giao diện kết nối DB + kiểm thử tích hợp lần 1.

### 👤 TV1 — Danh mục hệ thống & Hồ sơ sinh viên

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 68 | 🟡 Giao diện Quản lý Khoa, Ngành, Lớp & Hồ sơ Sinh viên | Màn hình quản lý Khoa/Ngành/Lớp (CRUD); màn hình hồ sơ SV (thêm/sửa/tra cứu/lọc) | `frontend` | `app/danh_muc_hoso_sv/` — ≥ 5 màn hình |
| 69 | 🟢 Minh họa độc lập dữ liệu (Data Independence Demo) | Demo: đổi cấu trúc index hoặc thêm cột cho SINHVIEN mà không làm hỏng logic các module khác (Chương 1) | `database`, `docs` | `docs/data_independence_demo.md` |

### 👤 TV2 — Học phần, Giảng viên & Mở lớp học phần

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 70 | 🟡 Giao diện Quản lý Môn học, Giảng viên & Mở Lớp học phần | Màn hình quản lý môn học/tiên quyết/GV; màn hình mở LHP + xếp lịch dạng thời khóa biểu trực quan | `frontend` | `app/hocphan_giangvien/` — ≥ 5 màn hình |

### 👤 TV3 — Đăng ký học phần *(Leader)* ⭐

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 71 | 🔴 Giao diện Đăng ký học phần (UX phức tạp nhất) | Màn hình chọn LHP (giỏ đăng ký, kiểm tra ràng buộc realtime); màn hình xem/hủy ĐK với **thông báo lỗi cụ thể theo từng ràng buộc** (5 loại) | `frontend`, `priority: critical` | `app/dangky_hocphan/` — ≥ 4 màn hình |
| 72 | ⭐ Thiết kế template UI chung | Tạo layout chung, navigation, color scheme, error handling pattern cho toàn bộ app. **Các TV khác dùng template này** | `frontend`, `integration` | `app/shared/` — template + components |
| 73 | ⭐ Điều phối kiểm thử tích hợp lần 1 | Tổ chức test chéo vòng: TV1→TV2→TV3→TV4→TV5→TV1. Lập checklist test, thu thập bug report, assign lại bug cho owner | `integration`, `priority: high` | `docs/integration_test_1.md` + GitHub Issues cho bugs |

### 👤 TV4 — Điểm số & Kết quả học tập

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 74 | 🟡 Giao diện Nhập điểm, Xem bảng điểm & Cảnh báo học vụ | Màn hình GV nhập điểm theo LHP (bảng nhập nhanh); màn hình SV xem bảng điểm/GPA; màn hình cảnh báo học vụ | `frontend` | `app/diem_ketqua/` — ≥ 4 màn hình |

### 👤 TV5 — Học phí, Tài khoản & Vận hành hệ thống

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 75 | 🟡 Giao diện Quản lý Học phí, Tài khoản & Dashboard Thống kê | Màn hình quản lý học phí; màn hình tài khoản/phân quyền (đăng nhập, đổi MK); Dashboard thống kê tổng hợp | `frontend` | `app/hocphi_taikhoan/` — ≥ 5 màn hình |
| 76 | 🔴 Kế hoạch Backup/Restore (Chương 6) | Xây dựng kế hoạch sao lưu: Full backup + Transaction Log backup. Demo `BACKUP DATABASE` / `RESTORE DATABASE`. Giả lập sự cố → phục hồi thành công. Giải thích WAL/Checkpoint | `database`, `priority: critical`, `docs` | `sql/backup/backup_plan.sql` + `docs/recovery_plan.md` + video demo |

---

## TUẦN 7 — BÁO CÁO, SLIDE, LUYỆN TẬP BẢO VỆ & HOÀN THIỆN

> **Milestone:** `Week 7 — Documentation, Presentation & Final Polish`
> **Mục tiêu:** Hoàn thiện toàn bộ tài liệu, slide, kiểm thử tích hợp cuối cùng, luyện bảo vệ.

### 👤 TV1 — Danh mục hệ thống & Hồ sơ sinh viên

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 77 | 🟢 Viết báo cáo phần Danh mục hệ thống & Hồ sơ sinh viên | Phần đặc tả, ERD, DDL, query, SP, trigger, index, transaction của module Danh mục & Hồ sơ SV | `docs` | Phần tương ứng trong `report/BaoCao_DeTai6.docx` |
| 78 | 🟢 Làm slide Danh mục hệ thống & Hồ sơ sinh viên | Slide theo template nhóm, trình bày module Danh mục & Hồ sơ SV + điểm nhấn Chương 1 (độc lập dữ liệu) | `docs` | `slides/danh_muc_hoso_sv_slides.pptx` |

### 👤 TV2 — Học phần, Giảng viên & Mở lớp học phần

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 79 | 🟢 Viết báo cáo phần Học phần, Giảng viên & Mở lớp học phần | Đặc tả + ERD + DDL + query + SP + trigger + index + transaction của module Học phần & Mở LHP | `docs` | Phần tương ứng trong báo cáo |
| 80 | 🟢 Làm slide Học phần, Giảng viên & Mở lớp học phần | Slide module Học phần & Mở LHP + điểm nhấn Chương 3 (Index B+-Tree) | `docs` | `slides/hocphan_giangvien_slides.pptx` |

### 👤 TV3 — Đăng ký học phần *(Leader)* ⭐

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 81 | 🔴 Viết báo cáo phần Đăng ký học phần (trọng tâm bảo vệ) | Đặc tả nghiệp vụ lõi + ERD + DDL + **5 ràng buộc đăng ký** + SP + trigger + **Transaction/Concurrency analysis chi tiết** + kết quả demo 2 session | `docs`, `priority: critical` | Phần trọng tâm trong báo cáo |
| 82 | 🔴 Làm slide Đăng ký học phần + phần Transaction/Concurrency | Slide module Đăng ký HP + **phần trình bày chính khi bảo vệ**: Chương 4 (ACID), Chương 5 (Concurrency, Deadlock) với demo live | `docs`, `priority: critical` | `slides/dangky_hocphan_slides.pptx` |
| 83 | ⭐ Biên tập & tổng hợp báo cáo cuối cùng | Thu thập báo cáo từ 5 module nghiệp vụ → ghép, thống nhất format, mục lục, trang bìa, danh sách hình/bảng. Kiểm tra chính tả, nhất quán thuật ngữ | `docs`, `integration`, `priority: high` | `report/BaoCao_DeTai6.docx` (bản final) |
| 84 | ⭐ Tổng hợp slide thuyết trình | Ghép 5 phần slide module, thêm slide mở đầu (giới thiệu nhóm, tổng quan hệ thống) + slide kết luận | `docs`, `integration` | `slides/Slide_DeTai6.pptx` (bản final) |
| 85 | ⭐ Điều phối kiểm thử tích hợp cuối cùng | Test toàn luồng: tạo SV → mở LHP → đăng ký → nhập điểm → tính GPA → học phí. Fix bug nếu còn. **Sign-off** | `integration`, `priority: critical` | `docs/final_integration_test.md` |
| 86 | ⭐ Tổ chức luyện tập bảo vệ chéo | Chuẩn bị bộ câu hỏi phản biện. Tổ chức 1–2 buổi hỏi chéo nội bộ. Đảm bảo mỗi TV nắm được toàn bộ hệ thống | `docs`, `review` | `docs/mock_defense_questions.md` |
| 87 | ⭐ Điền bảng đánh giá mức độ hoàn thành | Thu thập tự chấm + chấm chéo từ cả nhóm. Tổng hợp bảng đánh giá Mục VII | `docs` | Bảng đánh giá trong báo cáo |

### 👤 TV4 — Điểm số & Kết quả học tập

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 88 | 🟢 Viết báo cáo phần Điểm số & Kết quả học tập | Đặc tả + ERD + DDL + query + Function/Trigger tính điểm + SP GPA + transaction của module Điểm số | `docs` | Phần tương ứng trong báo cáo |
| 89 | 🟢 Làm slide Điểm số & Kết quả học tập | Slide module Điểm số + điểm nhấn Chương 2 nâng cao (Trigger/Function) | `docs` | `slides/diem_ketqua_slides.pptx` |

### 👤 TV5 — Học phí, Tài khoản & Vận hành hệ thống

| # | Issue Title | Mô tả | Label | 📎 Deliverable |
|---|---|---|---|---|
| 90 | 🟢 Viết báo cáo phần Học phí, Tài khoản & Vận hành | Đặc tả + ERD + DDL + query + SP + GRANT/REVOKE + **Backup/Restore + WAL/Checkpoint** | `docs` | Phần tương ứng trong báo cáo |
| 91 | 🟢 Làm slide Học phí, Tài khoản & Vận hành | Slide module Học phí & Vận hành + điểm nhấn Chương 6 (Phục hồi dữ liệu) | `docs` | `slides/hocphi_taikhoan_slides.pptx` |

---

## 📊 TỔNG HỢP KHỐI LƯỢNG THEO THÀNH VIÊN

| Thành viên | Module phụ trách | Tổng Issues | 🔴 Khó | 🟡 TB | 🟢 Cơ bản | ⭐ Leader extra | Vai trò đặc biệt |
|---|---|---|---|---|---|---|---|
| **TV1** | Danh mục hệ thống & Hồ sơ sinh viên | 12 | 0 | 4 | 8 | 0 | — |
| **TV2** | Học phần, Giảng viên & Mở lớp học phần | 12 | 1 | 7 | 4 | 0 | — |
| **TV3 (Leader)** ⭐ | Đăng ký học phần (nghiệp vụ lõi) | **25** | **10** | **2** | **0** | **13** | Review code, điều phối tích hợp, thiết kế kiến trúc, biên tập báo cáo, tổ chức luyện bảo vệ |
| **TV4** | Điểm số & Kết quả học tập | 12 | 1 | 6 | 5 | 0 | — |
| **TV5** | Học phí, Tài khoản & Vận hành hệ thống | 12 | 2 | 5 | 5 | 0 | — |
| **Tổng** | | **73** | **14** | **24** | **22** | **13** | |

> **Nhận xét:** TV3 (Leader) gánh **25/73 issues** (34%), trong đó **10 issues khó** (71% tổng issues khó) + **13 issues leader extra** (review, tích hợp, điều phối). Các TV khác chia đều 12 issues/người. Đây phản ánh vai trò leader chịu trách nhiệm phần khó nhất + quản lý chất lượng tổng thể.

---

## 🏷️ HƯỚNG DẪN TẠO GITHUB ISSUES & PROJECTS

### 1. Tạo Labels

Chạy các lệnh sau trong repository (hoặc tạo thủ công trên GitHub):

```bash
# Priority labels
gh label create "priority: critical" --color "D73A4A" --description "Việc quan trọng nhất, ảnh hưởng tiến độ cả nhóm"
gh label create "priority: high" --color "E99695" --description "Việc quan trọng, cần hoàn thành đúng hạn"
gh label create "priority: medium" --color "FEF2C0" --description "Việc bình thường"

# Type labels
gh label create "database" --color "0075CA" --description "Liên quan đến SQL, DDL, DML, SP, Trigger"
gh label create "backend" --color "5319E7" --description "Logic xử lý phía server"
gh label create "frontend" --color "7057FF" --description "Giao diện người dùng"
gh label create "docs" --color "0E8A16" --description "Tài liệu, báo cáo, slide"
gh label create "review" --color "FBCA04" --description "Cần review từ leader hoặc thành viên khác"
gh label create "integration" --color "006B75" --description "Liên quan tích hợp liên module"
```

### 2. Tạo Milestones

```bash
gh api repos/:owner/:repo/milestones --method POST -f title="Week 1 — Analysis & ERD" -f due_on="YYYY-MM-DDT23:59:59Z"
gh api repos/:owner/:repo/milestones --method POST -f title="Week 2 — Normalization & DDL" -f due_on="YYYY-MM-DDT23:59:59Z"
gh api repos/:owner/:repo/milestones --method POST -f title="Week 3 — Queries, Views & Stored Procedures" -f due_on="YYYY-MM-DDT23:59:59Z"
gh api repos/:owner/:repo/milestones --method POST -f title="Week 4 — Triggers, Indexes & Security" -f due_on="YYYY-MM-DDT23:59:59Z"
gh api repos/:owner/:repo/milestones --method POST -f title="Week 5 — Transactions & Concurrency" -f due_on="YYYY-MM-DDT23:59:59Z"
gh api repos/:owner/:repo/milestones --method POST -f title="Week 6 — Recovery, UI & Integration" -f due_on="YYYY-MM-DDT23:59:59Z"
gh api repos/:owner/:repo/milestones --method POST -f title="Week 7 — Documentation & Final Polish" -f due_on="YYYY-MM-DDT23:59:59Z"
```

### 3. Tạo Issues mẫu (ví dụ cho Issue #59)

```bash
gh issue create \
  --title "🔴 Transaction đăng ký học phần (Atomicity)" \
  --body "## Mô tả
Đóng gói toàn bộ SP DangKyHocPhan trong Transaction. Đảm bảo 'kiểm tra sĩ số' + 'ghi nhận đăng ký' là **nguyên tử** — tránh Lost Update khi 2 SV cùng ĐK chỗ cuối cùng.

## Checklist
- [ ] Wrap SP trong BEGIN TRAN / COMMIT / ROLLBACK
- [ ] Sử dụng TRY-CATCH
- [ ] Chọn mức cô lập phù hợp
- [ ] Test với 2 session đồng thời
- [ ] Viết minh chứng test

## Deliverable
\`sql/transactions/dangky_hocphan_tran.sql\`

## Liên quan
- Chương 4: ACID
- Chương 5: Concurrency Control" \
  --label "database,priority: critical" \
  --assignee "TV3_github_username" \
  --milestone "Week 5 — Transactions & Concurrency"
```

### 4. Tạo GitHub Project Board

1. Vào repo → **Projects** → **New Project** → chọn **Board**
2. Tạo các cột: `Backlog` | `To Do This Week` | `In Progress` | `In Review` | `Done`
3. Drag issues vào cột phù hợp mỗi tuần
4. Dùng **View** filter theo Milestone để xem công việc từng tuần
5. Dùng **View** filter theo Assignee để xem công việc từng người

### 5. Quy trình làm việc Git

```
main (protected)
  ├── dev (nhánh tích hợp)
  │   ├── feature/danh-muc-hoso-ddl   (TV1)
  │   ├── feature/hoc-phan-ddl        (TV2)
  │   ├── feature/dang-ky-sp          (TV3)
  │   ├── feature/diem-so-trigger     (TV4)
  │   └── feature/hoc-phi-backup      (TV5)
  └── docs (tài liệu)
```

- Mỗi TV tạo branch từ `dev` theo format: `feature/<ten-module>-<task>`
- Tạo **Pull Request** khi hoàn thành → assign **TV3 (Leader)** review
- Sau review → merge vào `dev`
- Cuối mỗi tuần: TV3 merge `dev` → `main`

---

## 📅 TIMELINE TỔNG QUAN

```
Tuần 1  ████████░░░░░░░░░░░░░░░░░░░░░░  Phân tích & ERD
Tuần 2  ░░░░░░░░████████░░░░░░░░░░░░░░  Chuẩn hóa & DDL
Tuần 3  ░░░░░░░░░░░░░░░░████████░░░░░░  Query/View/SP
Tuần 4  ░░░░░░░░░░░░░░░░░░░░░░░░██████  Trigger/Index/Security
Tuần 5  ██████████████████░░░░░░░░░░░░  Transaction & Concurrency ⭐ Leader peak
Tuần 6  ░░░░░░░░░░████████████████░░░░  Backup + UI + Tích hợp
Tuần 7  ░░░░░░░░░░░░░░░░░░████████████  Báo cáo + Slide + Bảo vệ
```

> **⚠️ Lưu ý:** Tuần 5 là tuần **nặng nhất** cho Leader (TV3) với 5 issues khó về Transaction/Concurrency. Nên chuẩn bị trước từ cuối tuần 4.
