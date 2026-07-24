# BẢNG PHÂN CÔNG NHIỆM VỤ BÀI TẬP LỚN
## Đề tài 6: Quản lý sinh viên đăng ký học phần tín chỉ
### Môn: Hệ Quản trị Cơ sở dữ liệu — Nhóm 5 thành viên

> Căn cứ xây dựng: yêu cầu tổ chức BTL + tiêu chí đánh giá trong "Danh sách đề tài BTL" và toàn bộ 6 chương giáo trình (Tổng quan CSDL, Mô hình quan hệ & SQL, Lưu trữ & Chỉ mục, Quản lý giao dịch, Điều khiển cạnh tranh, Phục hồi dữ liệu).

---

## 0. Danh sách nhóm

| STT | Họ và tên | MSSV | Module phụ trách | Vai trò |
|---|---|---|---|---|
| 1 | ..................... | ............ | Danh mục hệ thống & Hồ sơ sinh viên | Thành viên |
| 2 | ..................... | ............ | Học phần, Giảng viên & Mở lớp học phần | Thành viên |
| 3 | ..................... | ............ | Đăng ký học phần (nghiệp vụ lõi) | Thành viên |
| 4 | ..................... | ............ | Điểm số & Kết quả học tập | Thành viên |
| 5 | ..................... | ............ | Học phí, Tài khoản & Vận hành hệ thống | Thành viên |

> Nhóm nên bầu 1 người làm "đầu mối" (nộp bài, liên hệ giảng viên). Vai trò này thuần túy hành chính, **không** cộng thêm khối lượng kỹ thuật, để giữ đúng nguyên tắc công bằng.

---

## I. Nguyên tắc phân chia công việc

1. **Chia theo 5 module nghiệp vụ**, bám sát đúng vòng đời thực tế của bài toán: *Hồ sơ & danh mục nền* → *Mở lớp học phần* → *Đăng ký học phần* → *Điểm số* → *Học phí/Vận hành hệ thống*. Đây cũng là thứ tự một sinh viên thực sự trải qua trong một học kỳ, nên rất dễ trình bày logic khi bảo vệ.
2. **Mỗi module đi qua đúng 10 loại đầu việc giống nhau** (phân tích → ERD → chuẩn hóa → DDL → dữ liệu mẫu → truy vấn/View → Procedure/Function/Trigger → Index → Transaction/Concurrency → Giao diện + báo cáo). Nhờ vậy không ai chỉ "code" hoặc chỉ "làm giao diện" — mỗi người đều làm đủ mọi kỹ năng mà môn học yêu cầu.
3. Số **bảng dữ liệu** giữa các module không bằng nhau tuyệt đối (dao động 1–7 bảng), nhưng được **bù trừ bằng độ phức tạp nghiệp vụ** — xem bảng định lượng ở Mục IV để đối chiếu cụ thể (số query, procedure, trigger, màn hình đều được giữ xấp xỉ bằng nhau).
4. Mỗi module được gán thêm **một điểm nhấn chuyên sâu** ứng với 1–2 chương lý thuyết đặc thù (VD: module Đăng ký học phần chuyên sâu về Giao dịch & Điều khiển cạnh tranh vì đây là nơi xảy ra tranh chấp dữ liệu rõ nhất). Nhờ đó khi ghép 5 module lại, **toàn bộ 6 chương của giáo trình** đều được ứng dụng thực tế — xem ma trận ở Mục V.

---

## II. Tổng quan phân công theo module

| Thành viên | Module phụ trách | Bảng dữ liệu chính | Chương chuyên sâu (điểm nhấn) |
|---|---|---|---|
| 1 | Danh mục hệ thống & Hồ sơ sinh viên | KHOA, NGANH, LOP_SINHHOAT, SINHVIEN, CHUONGTRINHDAOTAO | Chương 1 – Kiến trúc HQTCSDL & Độc lập dữ liệu |
| 2 | Học phần, Giảng viên & Mở lớp học phần | GIANGVIEN, MONHOC, MONHOC_TIENQUYET, HOCKY, PHONGHOC, LOPHOCPHAN, LICHHOC | Chương 3 – Lưu trữ & Chỉ mục (Index) |
| 3 | Đăng ký học phần (nghiệp vụ lõi) | DANGKYHOCPHAN | Chương 4 + 5 – Giao dịch (ACID) & Điều khiển cạnh tranh |
| 4 | Điểm số & Kết quả học tập | KETQUAHOCTAP, THANGDIEMCHU | Chương 2 nâng cao – Trigger/Function tự động tính điểm |
| 5 | Học phí, Tài khoản & Vận hành hệ thống | HOCPHI, TAIKHOAN, VAITRO | Chương 6 – Phục hồi dữ liệu (Backup/Restore) + Bảo mật |

**Tổng cộng hệ thống dự kiến: 18 bảng dữ liệu**, đủ quy mô cho một đồ án môn HQTCSDL nhưng không quá tải cho 1 học kỳ.

---

## III. Phân công chi tiết từng thành viên

### Thành viên 1 — Danh mục hệ thống & Hồ sơ sinh viên

*Bảng phụ trách: KHOA, NGANH, LOP_SINHHOAT, SINHVIEN, CHUONGTRINHDAOTAO. Đây là dữ liệu nền mà hầu hết module khác đều tham chiếu tới, nên chất lượng thiết kế của module này ảnh hưởng trực tiếp đến cả nhóm.*

| STT | Đầu việc | Mô tả chi tiết | Sản phẩm bàn giao | Chương áp dụng |
|---|---|---|---|---|
| 1 | Phân tích nghiệp vụ | Khảo sát quy trình quản lý khoa/ngành/lớp/hồ sơ sinh viên thực tế; liệt kê thuộc tính và ràng buộc (mỗi SV thuộc đúng 1 lớp, mỗi lớp thuộc đúng 1 ngành, mỗi ngành thuộc đúng 1 khoa) | Tài liệu đặc tả nghiệp vụ module | Chương 1 |
| 2 | Thiết kế ERD module | Vẽ ERD riêng cho 5 bảng; xác định rõ các khóa ngoại sẽ được module khác tham chiếu tới (VD: SINHVIEN sẽ được DANGKYHOCPHAN, KETQUAHOCTAP, HOCPHI, TAIKHOAN dùng lại) | Sơ đồ ERD module | Chương 1, 2 |
| 3 | Chuẩn hóa dữ liệu | Kiểm tra phụ thuộc hàm trên 5 bảng; tách CHUONGTRINHDAOTAO thành bảng trung gian Ngành–Môn học–Học kỳ chuẩn để tránh dư thừa | Bảng phân tích phụ thuộc hàm, minh chứng đạt 3NF | Chương 2 |
| 4 | Viết DDL | CREATE TABLE 5 bảng: PK, FK (ON DELETE NO ACTION cho Khoa còn Ngành tham chiếu), CHECK (GioiTinh, TrangThai SV), DEFAULT | Script DDL (.sql) | Chương 2 |
| 5 | Dữ liệu mẫu | Tối thiểu 3 Khoa, 6 Ngành, 10 Lớp, 60 Sinh viên, chương trình đào tạo mẫu đầy đủ cho 1 ngành | Script INSERT | Chương 2 |
| 6 | Truy vấn & View | ≥ 5 câu SELECT phức tạp (SV theo khoa/ngành/lớp kèm sĩ số, SV chưa xếp lớp, tra cứu CTĐT theo ngành–khóa); 1 View danh sách SV đang học | Script query + view | Chương 2 |
| 7 | Procedure/Function/Trigger | SP thêm SV kèm kiểm tra lớp tồn tại; SP chuyển lớp/ngành cho SV; Function đếm sĩ số lớp; Trigger chặn xóa Ngành khi còn SV thuộc ngành | Script SP/Function/Trigger | Chương 2 |
| 8 | Chỉ mục (Index) | Non-clustered Index trên HoTen (tìm kiếm SV) và MaLop; giải thích lựa chọn loại chỉ mục theo Chương 3 | Script Index + giải thích | Chương 3 |
| 9 | Transaction & Concurrency | Giao dịch "Thêm SV mới + gán lớp" đảm bảo Atomicity; phân tích tình huống 2 nhân viên cùng sửa hồ sơ 1 SV → đề xuất Chốt phù hợp (Shared/Exclusive) | Script Transaction + báo cáo phân tích | Chương 4, 5 |
| 10 | Giao diện & Báo cáo | Màn hình quản lý Khoa/Ngành/Lớp; màn hình hồ sơ SV (thêm/sửa/tra cứu/lọc); viết phần báo cáo + slide module 1; tham gia kiểm thử tích hợp | ≥ 5 màn hình chức năng + báo cáo + slide | Tiêu chí đánh giá #5 |

**Điểm nhấn riêng:** vì sở hữu bảng nền, Thành viên 1 minh họa cụ thể khái niệm **Độc lập dữ liệu vật lý/logic** (Chương 1) bằng ví dụ: đổi cấu trúc chỉ mục hoặc thêm cột cho SINHVIEN mà không làm hỏng logic của 4 module còn lại.

---

### Thành viên 2 — Học phần, Giảng viên & Mở lớp học phần

*Bảng phụ trách: GIANGVIEN, MONHOC, MONHOC_TIENQUYET, HOCKY, PHONGHOC, LOPHOCPHAN, LICHHOC.*

| STT | Đầu việc | Mô tả chi tiết | Sản phẩm bàn giao | Chương áp dụng |
|---|---|---|---|---|
| 1 | Phân tích nghiệp vụ | Khảo sát quy trình mở học phần mỗi kỳ, cách gán môn tiên quyết, phân công giảng viên, xếp phòng học | Tài liệu đặc tả nghiệp vụ module | Chương 1 |
| 2 | Thiết kế ERD module | ERD cho 7 bảng; xác định liên kết với module Đăng ký (LOPHOCPHAN) và module Điểm (LOPHOCPHAN) | Sơ đồ ERD module | Chương 1, 2 |
| 3 | Chuẩn hóa dữ liệu | Chú ý MONHOC_TIENQUYET (quan hệ nhiều-nhiều tự tham chiếu); tách LICHHOC khỏi LOPHOCPHAN vì 1 lớp học phần có thể có nhiều buổi/tiết trong tuần | Bảng phân tích phụ thuộc hàm, minh chứng đạt 3NF | Chương 2 |
| 4 | Viết DDL | 7 bảng: CHECK SoTinChi > 0, SucChua phòng > 0; ON DELETE CASCADE hợp lý cho LICHHOC khi xóa LOPHOCPHAN | Script DDL (.sql) | Chương 2 |
| 5 | Dữ liệu mẫu | ≥ 15 giảng viên, 40 môn học kèm quan hệ tiên quyết, 3 học kỳ, 20 phòng học, 80 lớp học phần có lịch học đầy đủ | Script INSERT | Chương 2 |
| 6 | Truy vấn & View | Lớp học phần theo học kỳ kèm sĩ số còn trống; tra cứu môn tiên quyết; thời khóa biểu theo GV/phòng; kiểm tra phòng trống theo khung giờ | Script query + view | Chương 2 |
| 7 | Procedure/Function/Trigger | SP mở lớp học phần (tự kiểm tra GV/phòng không trùng lịch); Function kiểm tra phòng trống theo (phòng, thứ, tiết); **Trigger chặn lưu lịch học nếu trùng phòng hoặc trùng giảng viên cùng khung giờ** — ràng buộc này không thể khai báo bằng CHECK vì phải so sánh giữa các dòng khác nhau | Script SP/Function/Trigger | Chương 2 |
| 8 | Chỉ mục (Index) | Composite Non-clustered Index trên (MaPhong, Thu, TietBatDau) và (MaGV, Thu, TietBatDau) để tăng tốc kiểm tra trùng lịch | Script Index + giải thích | Chương 3 |
| 9 | Transaction & Concurrency | Giao dịch "Mở lớp học phần + xếp lịch" (rollback nếu phát hiện trùng); demo tình huống 2 cán bộ cùng xếp 2 lớp vào 1 phòng cùng giờ → giải quyết bằng Chốt Độc quyền (X) trên khung giờ/phòng khi đang kiểm tra-ghi | Script Transaction + báo cáo phân tích + minh chứng test | Chương 4, 5 |
| 10 | Giao diện & Báo cáo | Màn hình quản lý môn học/tiên quyết/GV; màn hình mở lớp học phần + xếp lịch dạng thời khóa biểu trực quan; báo cáo + slide module 2 | ≥ 5 màn hình chức năng + báo cáo + slide | Tiêu chí đánh giá #5 |

**Điểm nhấn riêng:** module có nhiều bảng liên kết nhất và nhiều truy vấn "kiểm tra trùng" nhất → Thành viên 2 phụ trách sâu **Chương 3 (Chỉ mục B+-Tree, tổ chức file)** vì tốc độ tra cứu lịch/phòng ảnh hưởng trực tiếp đến trải nghiệm cả hệ thống.

---

### Thành viên 3 — Đăng ký học phần (nghiệp vụ lõi)

*Bảng phụ trách: DANGKYHOCPHAN — chỉ 1 bảng nhưng là bảng trung tâm, tham chiếu tới gần như mọi module khác, và là nơi diễn ra toàn bộ nghiệp vụ phức tạp nhất hệ thống.*

| STT | Đầu việc | Mô tả chi tiết | Sản phẩm bàn giao | Chương áp dụng |
|---|---|---|---|---|
| 1 | Phân tích nghiệp vụ (sâu) | Liệt kê đầy đủ 5 ràng buộc đăng ký: còn hạn đăng ký, lớp học phần chưa đầy sĩ số, đã hoàn thành môn tiên quyết, không trùng lịch với các lớp đã đăng ký, tổng tín chỉ trong khoảng min–max theo quy chế; vẽ lưu đồ xử lý | Tài liệu đặc tả nghiệp vụ + lưu đồ | Chương 1 |
| 2 | Thiết kế ERD module | ERD bảng trung tâm, xác định toàn bộ khóa ngoại tới SINHVIEN, LOPHOCPHAN và các bảng phụ thuộc gián tiếp | Sơ đồ ERD module | Chương 1, 2 |
| 3 | Chuẩn hóa dữ liệu | Khóa chính ghép (MaSV, MaLHP); không lưu lại SoTinChi/TenMH trong bảng này (tránh dư thừa) mà truy xuất qua JOIN | Bảng phân tích phụ thuộc hàm, minh chứng đạt 3NF | Chương 2 |
| 4 | Viết DDL | CREATE TABLE với PK ghép, 2 FK, CHECK TrangThai, UNIQUE(MaSV, MaLHP) chống đăng ký trùng | Script DDL (.sql) | Chương 2 |
| 5 | Dữ liệu mẫu | Sinh dữ liệu đăng ký cho toàn bộ 60 SV vào các lớp học phần của ≥ 2 học kỳ, có tình huống biên (sát sĩ số tối đa, sát hạn đăng ký) | Script INSERT | Chương 2 |
| 6 | Truy vấn & View | SV đã đăng ký theo lớp học phần; SV chưa đủ/vượt tín chỉ; kiểm tra điều kiện tiên quyết bằng subquery/EXISTS; thời khóa biểu cá nhân | Script query + view | Chương 2 |
| 7 | Procedure/Function/Trigger (lõi) | SP `DangKyHocPhan` gộp đủ 5 bước kiểm tra trước khi ghi nhận; SP `HuyDangKy` kiểm tra còn hạn hủy; Function kiểm tra hoàn thành tiên quyết; **Trigger tự động +1/–1 SiSoHienTai của LOPHOCPHAN** mỗi khi có đăng ký/hủy | Script SP/Function/Trigger | Chương 2 |
| 8 | Chỉ mục (Index) | Non-clustered Index riêng trên MaSV và trên MaLHP phục vụ 2 chiều tra cứu; đo tốc độ truy vấn trước/sau khi có index (SET STATISTICS TIME/IO) | Script Index + báo cáo đo hiệu năng | Chương 3 |
| 9 | Transaction & Concurrency (điểm nhấn chính của cả nhóm) | Đóng gói giao dịch đăng ký trong 1 Transaction để việc "kiểm tra sĩ số" và "ghi nhận đăng ký" là nguyên tử, tránh 2 SV cùng đăng ký vào chỗ trống cuối cùng (Lost Update); áp dụng Chốt Độc quyền (X) hoặc mức cô lập phù hợp; **viết kịch bản test 2 phiên (session) đăng ký đồng thời và ghi lại minh chứng (ảnh/video)** | Script Transaction + báo cáo phân tích concurrency + video/ảnh demo | Chương 4, 5 (sâu nhất) |
| 10 | Giao diện & Báo cáo | Màn hình đăng ký học phần cho SV (chọn lớp, giỏ đăng ký, xác nhận); màn hình xem/hủy đăng ký với thông báo lỗi rõ theo từng ràng buộc; báo cáo + slide module 3 (phần trọng tâm khi bảo vệ) | ≥ 4 màn hình chức năng + báo cáo + slide | Tiêu chí đánh giá #5 |

**Điểm nhấn riêng:** đây là module ít bảng nhất (1 bảng) nhưng nặng nhất về nghiệp vụ, ràng buộc và giao dịch — phần bù trừ khối lượng được thể hiện rõ ở Mục IV.

---

### Thành viên 4 — Điểm số & Kết quả học tập

*Bảng phụ trách: KETQUAHOCTAP, THANGDIEMCHU (bảng tra cứu quy đổi thang điểm — tách riêng để tránh hard-code ngưỡng điểm trong code).*

| STT | Đầu việc | Mô tả chi tiết | Sản phẩm bàn giao | Chương áp dụng |
|---|---|---|---|---|
| 1 | Phân tích nghiệp vụ | Xác định trọng số điểm thành phần (VD 10% chuyên cần – 30% giữa kỳ – 60% cuối kỳ), thang điểm chữ và quy đổi hệ 4, tiêu chí xếp loại học lực, điều kiện cảnh báo học vụ | Tài liệu đặc tả nghiệp vụ | Chương 1 |
| 2 | Thiết kế ERD module | ERD 2 bảng; liên kết KETQUAHOCTAP với DANGKYHOCPHAN (thống nhất với Thành viên 3 về khóa dùng chung) | Sơ đồ ERD module | Chương 1, 2 |
| 3 | Chuẩn hóa dữ liệu | Cân nhắc lưu vs. tính runtime cho DiemChu/DiemHe4 (đánh đổi giữa chuẩn hóa và hiệu năng truy vấn); tách THANGDIEMCHU làm bảng tra cứu độc lập | Bảng phân tích phụ thuộc hàm, minh chứng đạt 3NF | Chương 2 |
| 4 | Viết DDL | CHECK các cột điểm trong khoảng [0,10]; ràng buộc NOT NULL hợp lý theo trạng thái hoàn thành | Script DDL (.sql) | Chương 2 |
| 5 | Dữ liệu mẫu | Nhập điểm cho toàn bộ SV đã đăng ký (dùng chung dữ liệu với Thành viên 3), đủ tình huống: SV giỏi, SV rớt môn, SV chưa có điểm | Script INSERT | Chương 2 |
| 6 | Truy vấn & View | Bảng điểm cá nhân theo học kỳ; danh sách SV theo mức xếp loại; SV điểm cao/thấp nhất mỗi lớp (RANK/TOP); tỷ lệ đạt/không đạt mỗi môn (GROUP BY/HAVING) | Script query + view | Chương 2 |
| 7 | Procedure/Function/Trigger (nâng cao) | Function tính DiemTongKet theo trọng số; Function quy đổi DiemTongKet → DiemChu → DiemHe4 (qua THANGDIEMCHU); SP tính GPA học kỳ/tích lũy; **Trigger tự động tính lại DiemTongKet & DiemChu ngay khi GV cập nhật bất kỳ điểm thành phần nào** | Script SP/Function/Trigger | Chương 2 (điểm nhấn) |
| 8 | Chỉ mục (Index) | Non-clustered Index trên MaSV (tra bảng điểm cá nhân) và MaLHP (tra điểm theo lớp cho GV) | Script Index + giải thích | Chương 3 |
| 9 | Transaction & Concurrency | Giao dịch nhập điểm hàng loạt (rollback toàn bộ nếu 1 dòng lỗi, tránh dở dang); phân tích tình huống GV và Trưởng bộ môn cùng sửa điểm 1 SV → dùng Chốt X hoặc kiểm tra mốc thời gian cập nhật cuối | Script Transaction + báo cáo phân tích | Chương 4, 5 |
| 10 | Giao diện & Báo cáo | Màn hình GV nhập điểm theo lớp học phần (bảng nhập nhanh); màn hình SV xem bảng điểm/GPA; màn hình cảnh báo học vụ; báo cáo + slide module 4 | ≥ 4 màn hình chức năng + báo cáo + slide | Tiêu chí đánh giá #5 |

**Điểm nhấn riêng:** module có logic tính toán và trigger tự động nhiều nhất → Thành viên 4 phụ trách sâu phần **SQL nâng cao (Function/Trigger)** của Chương 2.

---

### Thành viên 5 — Học phí, Tài khoản-Phân quyền & Vận hành hệ thống

*Bảng phụ trách: HOCPHI, TAIKHOAN, VAITRO. Module này ít bảng nhất trong 5 module dữ liệu nghiệp vụ nhưng kiêm thêm vai trò "vận hành": bảo mật toàn hệ thống, sao lưu/phục hồi, và điều phối kiểm thử tích hợp cuối kỳ — đây chính là phần bù khối lượng.*

| STT | Đầu việc | Mô tả chi tiết | Sản phẩm bàn giao | Chương áp dụng |
|---|---|---|---|---|
| 1 | Phân tích nghiệp vụ | Đơn giá tín chỉ theo ngành/hệ đào tạo, quy trình đóng học phí, 3 nhóm vai trò người dùng (SV/GV/Phòng đào tạo) và quyền hạn tương ứng, danh mục báo cáo thống kê cần có, chính sách sao lưu định kỳ | Tài liệu đặc tả nghiệp vụ | Chương 1 |
| 2 | Thiết kế ERD module | ERD 3 bảng; xác định liên kết TAIKHOAN với SINHVIEN/GIANGVIEN | Sơ đồ ERD module | Chương 1, 2 |
| 3 | Chuẩn hóa dữ liệu | VAITRO tách riêng khỏi TAIKHOAN (tránh lặp lại tên vai trò dạng chuỗi); kiểm tra phụ thuộc hàm 3 bảng | Bảng phân tích phụ thuộc hàm, minh chứng đạt 3NF | Chương 2 |
| 4 | Viết DDL | HOCPHI: CHECK ThanhTien ≥ 0; TAIKHOAN: UNIQUE TenDangNhap, lưu mật khẩu đã băm (hash), FK đúng 1 trong 2 (SV hoặc GV) | Script DDL (.sql) | Chương 2 |
| 5 | Dữ liệu mẫu | Đơn giá tín chỉ mẫu theo 2–3 ngành; học phí tính sẵn cho các SV đã đăng ký ở module 3; tài khoản mẫu cho cả 3 vai trò | Script INSERT | Chương 2 |
| 6 | Truy vấn & View | Danh sách SV nợ học phí; tổng thu học phí theo học kỳ/ngành; **báo cáo thống kê tổng hợp toàn hệ thống** (sĩ số lớp học phần, tỷ lệ cảnh báo học vụ — liên kết dữ liệu từ các module khác) | Script query + view | Chương 2 |
| 7 | Procedure/Function/Trigger + Bảo mật | SP tự động tính học phí ngay sau khi SV đăng ký thành công; SP tạo tài khoản tự động khi thêm SV/GV mới; Trigger ghi log mỗi lần đổi mật khẩu; **thiết lập GRANT/REVOKE cụ thể cho 3 vai trò** (VD: SV chỉ SELECT được bảng điểm của chính mình qua View, không được UPDATE) | Script SP/Function/Trigger/GRANT | Chương 2 (bảo mật) |
| 8 | Chỉ mục (Index) | Non-clustered Index trên MaSV (bảng HOCPHI); Unique Index trên TenDangNhap (bảng TAIKHOAN, dùng khi đăng nhập) | Script Index + giải thích | Chương 3 |
| 9 | Transaction, Concurrency & Phục hồi (điểm nhấn Chương 6) | Giao dịch thu học phí; phân tích khả năng đụng độ khi 2 tiến trình cùng cập nhật trạng thái đóng học phí; **xây dựng kế hoạch sao lưu** (Full backup định kỳ + Transaction Log backup), demo `BACKUP DATABASE`/`RESTORE DATABASE`, giả lập sự cố mất dữ liệu và phục hồi thành công, giải thích cơ chế WAL/Checkpoint của SQL Server áp dụng trong hệ thống | Script Transaction + kế hoạch backup + video demo restore | Chương 4, 5, 6 |
| 10 | Giao diện & Vận hành | Màn hình quản lý học phí; màn hình quản lý tài khoản/phân quyền (đăng nhập, đổi mật khẩu); Dashboard thống kê tổng hợp; báo cáo + slide module 5; **điều phối lịch kiểm thử tích hợp chéo** giữa các thành viên (không làm một mình) | ≥ 5 màn hình chức năng + báo cáo + slide | Tiêu chí đánh giá #5 |

**Điểm nhấn riêng:** duy nhất trong nhóm đảm nhiệm trọn vẹn **Chương 6 (Phục hồi dữ liệu)** — lý do khối lượng module này gồm cả trách nhiệm "vận hành hệ thống" để bù cho số bảng nghiệp vụ ít hơn các module khác.

---

## IV. Bảng định lượng khối lượng công việc (đối chiếu công bằng)

| Thành viên | Số bảng CSDL | Query/View (tối thiểu) | Procedure/Function (tối thiểu) | Trigger (tối thiểu) | Màn hình giao diện (tối thiểu) | Vì sao vẫn công bằng |
|---|---|---|---|---|---|---|
| 1 | 5 | 5 | 3 | 1 | 5 | Nhiều bảng nhưng là dữ liệu nền, logic chủ yếu là CRUD đơn giản |
| 2 | 7 | 5 | 3 | 2 | 5 | Nhiều bảng liên kết nhất hệ thống, logic xếp lịch phức tạp |
| 3 | 1 | 6 | 4 | 2 | 4 | Ít bảng nhất nhưng nghiệp vụ + ràng buộc + giao dịch phức tạp nhất toàn hệ thống |
| 4 | 2 | 5 | 4 | 2 | 4 | Nhiều công thức tính toán và trigger tự động |
| 5 | 3 | 5 | 3 | 1 | 5 | Kiêm bảo mật (GRANT/REVOKE), sao lưu/phục hồi (Chương 6) và điều phối kiểm thử cuối kỳ |
| **Tổng** | **18** | **26** | **17** | **8** | **23** | |

Nhận xét: cột "Số bảng" chênh lệch (1–7) nhưng 4 cột còn lại — vốn phản ánh sát hơn khối lượng công sức thực tế — đều nằm trong khoảng hẹp (query 5–6, procedure 3–4, trigger 1–2, màn hình 4–5). Đây là căn cứ định lượng cho việc chia đều công việc, có thể trình bày trực tiếp với giảng viên nếu được hỏi.

---

## V. Ma trận ứng dụng toàn bộ 6 chương giáo trình

| Chương | Nội dung trọng tâm | Ứng dụng cụ thể trong đồ án | Áp dụng sâu nhất | Toàn nhóm áp dụng cơ bản |
|---|---|---|---|---|
| 1 – Tổng quan CSDL & HQTCSDL | 3 mức trừu tượng dữ liệu, độc lập dữ liệu, vai trò DBA | Phần mở đầu báo cáo mô tả bài toán theo 3 mức; module Danh mục minh họa độc lập dữ liệu vật lý/logic; mỗi người đóng vai "DBA" khi định nghĩa sơ đồ & cấp quyền cho module mình | Thành viên 1 | Cả 5 thành viên |
| 2 – Mô hình quan hệ & SQL | DDL, DML, View, Stored Procedure, Function, Trigger, GRANT/REVOKE | Toàn bộ 18 bảng, 26 câu truy vấn, 17 procedure/function, 8 trigger, phân quyền GRANT/REVOKE | Thành viên 4 (Trigger/Function nâng cao) và Thành viên 5 (GRANT/REVOKE) | Cả 5 thành viên (bắt buộc ở mọi module) |
| 3 – Lưu trữ & Cấu trúc tập tin | RAID, tổ chức file, Chỉ mục B+-Tree, Băm | Thiết kế Non-clustered Index cho toàn bộ cột tra cứu tần suất cao; Composite Index chống trùng lịch; đo hiệu năng trước/sau khi có index | Thành viên 2 | Cả 5 thành viên (mỗi bảng có ≥ 1 chỉ mục hợp lý) |
| 4 – Quản lý giao dịch | ACID, Lịch trình, Khả tuần tự | Đóng gói Transaction (BEGIN TRAN/COMMIT/ROLLBACK) cho: đăng ký học phần, mở lớp, nhập điểm, thu học phí | Thành viên 3 | Cả 5 thành viên (mỗi module ≥ 1 giao dịch minh họa ACID) |
| 5 – Điều khiển cạnh tranh | Chốt (Lock), Giao thức 2PL, Deadlock | Demo tranh chấp "chỗ đăng ký cuối cùng", "trùng lịch phòng"; giải quyết bằng Chốt Độc quyền (X) + mức cô lập phù hợp; giả lập và xử lý deadlock | Thành viên 3 (chính), Thành viên 2 (phụ) | Cả 5 thành viên (mỗi module ≥ 1 tình huống concurrency được phân tích) |
| 6 – Hệ thống phục hồi dữ liệu | Log, WAL, Checkpoint, Shadow Paging | Kế hoạch sao lưu định kỳ; demo `BACKUP`/`RESTORE DATABASE`; giả lập sự cố mất dữ liệu và phục hồi; giải thích cơ chế Log/Checkpoint của SQL Server | Thành viên 5 | Cả nhóm cùng dự buổi demo, trình bày chung trong báo cáo |

---

## VI. Nhiệm vụ chung của cả nhóm (chia đều, không tách riêng cho ai)

| STT | Nhiệm vụ chung | Cách chia đều |
|---|---|---|
| 1 | Họp ráp nối 5 ERD module thành ERD tổng thể, rà soát tính nhất quán khóa ngoại liên module | Cả 5 người cùng tham dự; mỗi người trình bày và bảo vệ ERD module của mình |
| 2 | Kiểm thử tích hợp (Integration Testing) toàn hệ thống | Kiểm thử chéo: mỗi người test module của người kế tiếp (TV1→TV2→TV3→TV4→TV5→TV1) để phát hiện lỗi khách quan hơn tự kiểm tra |
| 3 | Biên soạn báo cáo Word tổng hợp | Mỗi người viết đúng phần module mình (số trang tương đương); vai trò tổng hợp định dạng cuối luân phiên theo từng đợt nộp |
| 4 | Làm slide thuyết trình | Mỗi người làm slide phần module mình theo 1 template thống nhất cả nhóm chọn trước |
| 5 | Luyện tập bảo vệ đồ án | Mỗi người phải nắm được toàn bộ hệ thống (không chỉ phần mình) để trả lời phản biện; tổ chức 1–2 buổi hỏi chéo nội bộ trước khi bảo vệ chính thức |
| 6 | Đánh giá chéo mức độ hoàn thành | Dùng bảng ở Mục VII: cả 5 người tự chấm + chấm chéo, thống nhất công khai trước khi nộp |

---

## VII. Bảng đánh giá mức độ hoàn thành thành viên

*Bảng này trực tiếp đáp ứng yêu cầu "phải có bản tổng kết và đánh giá mức độ hoàn thành của từng thành viên" của đề bài. Dùng lại bảng này ở giữa và cuối kỳ.*

Tiêu chí xây dựng từ đúng 5 tiêu chí đánh giá của môn học + 1 tiêu chí tinh thần làm việc nhóm:

| Tiêu chí | Trọng số | TV1 (%) | TV2 (%) | TV3 (%) | TV4 (%) | TV5 (%) | Minh chứng cần lưu |
|---|---|---|---|---|---|---|---|
| 1. Phân tích bài toán & mô hình ERD/quan hệ phù hợp | 20% | | | | | | Tài liệu đặc tả + sơ đồ ERD module |
| 2. Chuẩn hóa dữ liệu đạt 3NF/BCNF | 15% | | | | | | Bảng phân tích phụ thuộc hàm |
| 3. Ràng buộc toàn vẹn đầy đủ (PK/FK/CHECK/DEFAULT) | 15% | | | | | | Script DDL có đủ ràng buộc |
| 4. Procedure/Function/Trigger xử lý nghiệp vụ tự động | 20% | | | | | | Script SP/Function/Trigger + kết quả chạy thử |
| 5. Giao diện kết nối CSDL, chạy ổn định | 20% | | | | | | Ảnh/video demo màn hình chức năng |
| 6. Đúng tiến độ, minh chứng rõ ràng, hợp tác tốt | 10% | | | | | | Lịch sử commit/log trao đổi nhóm |
| **Tổng** | **100%** | | | | | | |

---

## VIII. Lộ trình thực hiện theo tiến độ học từng chương

*Vì đề bài ghi rõ "sẽ cập nhật theo từng chương trong quá trình học", nhóm nên triển khai đồ án song song với tiến độ giảng dạy thay vì dồn vào cuối kỳ.*

| Giai đoạn | Song song chương | Công việc chính | Mốc hoàn thành gợi ý |
|---|---|---|---|
| 1 | Chương 1–2 (đầu kỳ) | Phân tích nghiệp vụ, vẽ ERD từng module + họp ráp nối tổng, chuẩn hóa 3NF, viết DDL + dữ liệu mẫu | Tuần 3–4 |
| 2 | Chương 2 (nâng cao) | Viết Query/View/Stored Procedure/Function/Trigger/GRANT-REVOKE cho từng module | Tuần 5–7 |
| 3 | Chương 3 | Thiết kế & tạo Index, đo hiệu năng truy vấn trước/sau khi có index | Tuần 8 |
| 4 | Chương 4–5 | Đóng gói Transaction, phân tích và test tình huống concurrency/deadlock | Tuần 9–11 |
| 5 | Chương 6 | Thiết lập kế hoạch backup, demo restore, viết cơ chế phục hồi | Tuần 12 |
| 6 | Cuối kỳ | Hoàn thiện giao diện, kiểm thử tích hợp chéo, viết báo cáo, làm slide, luyện tập bảo vệ | Tuần 13–15 |

*(Số tuần chỉ mang tính gợi ý — điều chỉnh theo lịch giảng dạy thực tế của lớp.)*

---

## IX. Lưu ý quan trọng

- **Lưu minh chứng cá nhân**: mỗi người nên giữ lại script SQL có ghi tên mình trong comment, ảnh/video demo chức năng (đặc biệt màn hình test concurrency với 2 phiên chạy đồng thời) — đúng yêu cầu "mỗi thành viên phải chứng minh được mình làm và mình làm đúng".
- **Nên dùng Git/GitHub** để quản lý mã nguồn chung: mỗi người code trên nhánh riêng rồi merge — vừa dễ phân định công sức khi cần đối chiếu, vừa là điểm cộng khi bảo vệ.
- **Ai cũng có thể bị hỏi về bất kỳ phần nào**: giảng viên hoàn toàn có thể hỏi một thành viên về module của người khác, nên bước "luyện tập bảo vệ chéo" ở Mục VI không nên bỏ qua.
- Đây là đề xuất phân công dựa trên khảo sát toàn bộ 6 chương giáo trình đã cung cấp. Nhóm có thể đổi tên bảng/thêm bớt vài cột cho sát với hệ đào tạo tín chỉ của trường mình (VD thêm bảng Học bổng, Miễn giảm học phí…), miễn giữ nguyên tắc chia đều 10 loại đầu việc như trên.
- **Bước tiếp theo gợi ý**: khi nhóm sẵn sàng, có thể nhờ dựng chi tiết ERD đầy đủ (kèm hình vẽ) và script DDL hoàn chỉnh cho cả 18 bảng dựa trên bảng phân công này.
