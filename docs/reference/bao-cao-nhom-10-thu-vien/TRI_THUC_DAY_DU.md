# TRI THỨC ĐẦY ĐỦ — Báo cáo cuối kỳ Nhóm 10 (HQTCSDL): Hệ thống Quản lý Thư viện

> **Nguồn duy nhất:** `Nhóm 10 - HQTCSDL - Báo cáo cuối kỳ.pdf` — 78 trang, 89.511 ký tự, trích xuất 100% (0 trang rỗng, 0 trang lỗi).
> **Transcript nguyên văn theo từng trang:** [`pdf_transcript.md`](pdf_transcript.md) · dữ liệu thô dạng JSON: [`../../_extract/pdf_pages.json`](../../_extract/pdf_pages.json)
> **Ngày tài liệu ghi trên bìa:** TP. Hồ Chí Minh, Ngày 20 Tháng 4 Năm 2026 · Metadata PDF: `Microsoft® Word 2019`, tạo `2026-05-02 16:11:58 +07:00`, Author `Nguyễn Lê Huy Tâm`.
> **Mọi con số trong tài liệu này đều lấy trực tiếp từ PDF.** Các chỗ PDF tự mâu thuẫn hoặc thiếu được ghi rõ trong [§10](#10-điểm-bất-nhất--lỗi-trong-chính-báo-cáo) — không tự suy diễn, không tự bổ sung.

---

## Mục lục

| § | Nội dung | Trang PDF |
|---|---|---|
| [0](#0-tóm-tắt-một-trang) | Tóm tắt một trang | — |
| [1](#1-thông-tin-hành-chính) | Thông tin hành chính, thành viên, phân công | 1–5 |
| [2](#2-giới-thiệu-đề-tài) | Giới thiệu đề tài | 16 (tr.11) |
| [3](#3-use-case) | Use Case: tác nhân, danh sách, đặc tả 13 UC | 17–26 (tr.12–21) |
| [4](#4-các-module-chức-năng--api-endpoints) | 8 module chức năng & API endpoints | 27–31 (tr.22–26) |
| [5](#5-database) | Database: thiết kế, ERD, 8 bảng, khóa, ràng buộc | 31–40 (tr.26–35) |
| [6](#6-view--function--procedure--trigger) | View, Function, Procedure, Trigger | 40–43 (tr.35–38) |
| [7](#7-giao-tác-và-tính-chất-acid) | Giao tác và 4 tính chất ACID | 43–47 (tr.38–42) |
| [8](#8-các-lỗi-xung-đột-tranh-chấp-và-cách-xử-lý) | 5 lỗi xung đột + cách xử lý | 47–58 (tr.42–53) |
| [9](#9-giao-diện-hệ-thống) | Giao diện, tài khoản demo, phân quyền | 58–75 (tr.53–70) |
| [10](#10-điểm-bất-nhất--lỗi-trong-chính-báo-cáo) | Điểm bất nhất / lỗi trong chính báo cáo | — |
| [11](#11-kết-luận-và-hướng-phát-triển) | Kết luận & hướng phát triển | 76–77 (tr.71–72) |
| [12](#12-phụ-lục-và-tài-liệu-tham-khảo) | Phụ lục: viết tắt, hình, bảng, tham khảo | 11–15, 78 |

---

## 0. Tóm tắt một trang

**Đề tài:** “Xây dựng hệ thống quản lý thư viện” — môn **Hệ Quản trị Cơ sở dữ liệu (HQTCSDL)**, lớp/Nhóm 10, Viện Đào tạo Chất lượng cao, Trường Đại học Giao thông Vận tải TP. Hồ Chí Minh. Giảng viên: **Trần Anh Quân**. 5 thành viên, tất cả hoàn thành 100%.

**Mục tiêu:** thay thế quản lý thủ công bằng sổ sách / hệ thống rời rạc, tự động hóa nghiệp vụ thư viện: quản lý độc giả, nhân sự, sách & kho sách, mượn–trả, xử lý tiền phạt.

**Công nghệ:** CSDL quan hệ **MySQL**; backend RESTful API (JWT cho xác thực); frontend web; ứng dụng dùng **View, Function, Stored Procedure, Trigger** để tối ưu truy vấn và đảm bảo nhất quán dữ liệu. Bản chạy thật: <https://full-stack-project-library-manageme-amber.vercel.app/> · mã nguồn: <https://github.com/ThaiDevv/FullStack-Project-library-management.git>

**Hai tác nhân:** **Thủ thư (Nhân viên)** và **Quản lý**. Trên giao diện có 2 tài khoản: Quản trị viên `NV04`/`123456` và Nhân viên `NV01`/`123456`.

**13 Use Case chính:** Đăng nhập · Quản lý thể loại · Quản lý sách · Quản lý độc giả · Quản lý nhân viên · Quản lý phiếu mượn · Quản lý chi tiết phiếu mượn · Quản lý mượn/trả sách · Tìm kiếm · Tra cứu · Thống kê · Quản lý phiếu phạt · Thanh toán phiếu phạt.

**Mô hình dữ liệu:** 8 bảng — `THELOAI`, `DAUSACH`, `CUONSACH`, `DOCGIA`, `NHANVIEN`, `PHIEUMUON`, `CT_PHIEUMUON`, `PHIEUPHAT`. Điểm thiết kế cốt lõi: **tách “đầu sách” (DAUSACH) khỏi “cuốn sách vật lý” (CUONSACH)** để theo dõi chính xác từng bản sách khi mượn/trả. Quan hệ phiếu mượn ↔ sách là **n–n qua bảng chi tiết** `CT_PHIEUMUON` (khóa chính ghép `MaPM` + `MaCuonSach`).

**7 View** (`v_quanlysach`, `v_phieumuonchitiet`, `v_lichsumuon`, `v_sachdangmuon_docgia`, `quanlyphieuquahan`, `thongkesachdangmuon`, `thongkesachtheotheloai`) · **2 Function** (`fn_DemSoSachDangMuon`, `fn_TinhTienPhat`) · **~20 Procedure** · **4 Trigger** (`trg_MuonSach_CapNhatTrangThai`, `trg_TraSach_XuLyTuDong`, `trg_KiemTraDocGiaQuaHan`, `trg_XoaPhieuMuon_HoanTonKho`).

**Quy tắc nghiệp vụ then chốt:** sách chỉ cho mượn khi `TrangThai='Sẵn sàng'` **và** `TinhTrang='Bình Thường'`; độc giả bị chặn nếu còn phiếu quá hạn **hoặc** đã mượn đủ **5 cuốn**; mỗi phiếu mượn phát sinh **tối đa 1 phiếu phạt** (UNIQUE trên `PHIEUPHAT.MaPM`); số điện thoại độc giả là duy nhất.

**Phần học thuật trọng tâm của báo cáo:** chứng minh 4 tính chất **ACID** bằng ví dụ thư viện, và phân tích **5 lỗi tranh chấp** — Lost Update, Dirty Read, Non-repeatable Read, Phantom, **Deadlock** — kèm lịch giao tác (schedule), câu lệnh SQL tái hiện lỗi, kết quả sai, và cách khắc phục (transaction + trigger + rollback + khóa `FOR UPDATE`).

---

## 1. Thông tin hành chính

### 1.1 Trang bìa (trang 1)

| Trường | Nội dung |
|---|---|
| Đơn vị | TRƯỜNG ĐẠI HỌC GIAO THÔNG VẠI TẢI TP. HỒ CHÍ MINH — VIỆN ĐÀO TẠO CHẤT LƯỢNG CAO |
| Loại tài liệu | BÁO CÁO — HỆ QUẢN TRỊ CƠ SƠ DỮ LIỆU *(PDF ghi đúng như vậy: “CƠ SƠ”)* |
| Đề tài | **HỆ THỐNG QUẢN LÝ THƯ VIỆN** |
| Nhóm | Nhóm 10 |
| Giảng viên | Trần Anh Quân |
| Thời gian | TP. Hồ Chí Minh, Ngày 20 Tháng 4 Năm 2026 |

**Danh sách thành viên (nguyên văn trang 1):**

| # | Họ và tên | MSSV |
|---|---|---|
| 1 | Nguyễn Lê Huy Tâm | 056206011188 |
| 2 | Phạm Bá Trí Tâm | 079206013039 |
| 3 | Trần Văn Ngọc Thắng | 04620600164 |
| 4 | Trần Văn Thái | 051206002315 |
| 5 | Nguyễn Ngọc Gia Bảo | 079206008279 |

> Lưu ý: MSSV của Trần Văn Ngọc Thắng chỉ có **11 chữ số** (04620600164), các MSSV khác có 12 chữ số. Giữ nguyên theo PDF.

### 1.2 Đánh giá nhiệm vụ từng thành viên (trang 2 — Bảng ở mục lục ký hiệu “i”)

| Họ và tên | Nhiệm vụ được giao | Mức độ hoàn thành |
|---|---|---|
| Nguyễn Lê Huy Tâm | Làm báo cáo words; Làm canva; Làm backend; Soạn nội dung về các tính chất giao tác và các trường hợp xảy ra lỗi xung đột | 100% |
| Phạm Bá Trí Tâm | Làm canva; Làm backend; Soạn nội dung các chức năng tổng quan của hệ thống | 100% |
| Trần Văn Ngọc Thắng | Làm canva; Làm database + backend; Soạn nội dung về chức năng hệ thống (view, proceduce) | 100% |
| Trần Văn Thái | Làm canva; Làm database + backend + frontend (fullstack); Làm và soạn nội dung các chức năng tổng quan của hệ thống | 100% |
| Nguyễn Ngọc Gia Bảo | Làm canva; Làm backend; Soạn nội dung về chức năng hệ thống (function, trigger), vẽ Use Case, sơ đồ ERD | 100% |

> PDF gõ “proceduce” (đúng: *procedure*) — giữ nguyên.
> **Suy ra từ bảng:** 4/5 thành viên làm **backend**; 2 người làm **database** (Thắng, Thái); chỉ **1 người làm frontend** (Thái); **1 người làm báo cáo Word** (Huy Tâm); cả 5 người làm **Canva**. Nguyễn Ngọc Gia Bảo chịu trách nhiệm **Use Case + ERD**; Nguyễn Lê Huy Tâm chịu trách nhiệm **giao tác/ACID + lỗi xung đột** — đúng hai phần dài nhất của báo cáo (§7 và §8 dưới đây).

### 1.3 Lời cảm ơn (trang 3 — “ii”)

Cảm ơn Thầy **Trần Anh Quân**, giảng viên Trường Đại học Giao thông Vận tải TP.HCM, đã hỗ trợ suốt quá trình làm đề tài; nhóm ghi nhận thầy dạy về cách một doanh nghiệp hoạt động và một chủ doanh nghiệp cần những gì. Nhóm tự nhận bài báo cáo được chuẩn bị kỹ lưỡng nhưng “đôi khi vẫn còn nhiều thứ sai sót”, mong nhận đánh giá của thầy. Ký ngày 20/4/2026 bởi cả 5 thành viên.

### 1.4 Trang cam kết (trang 4 — “iii”)

Cam kết báo cáo hoàn thành dựa trên kết quả nghiên cứu của nhóm và **chưa được dùng cho bất cứ báo cáo cùng cấp nào khác**. Ký ngày 20/4/2026 bởi cả 5 thành viên.

### 1.5 Nhận xét của giảng viên (trang 5 — “iv”)

Trang để trống dạng biểu mẫu: 30 dòng chấm (`...........`) dành cho nhận xét, kết thúc bằng “TP. Hồ Chí Minh, Ngày 20 Tháng 4 Năm 2026” và “Chữ ký giảng viên”. **Không có nội dung nhận xét nào được điền trong PDF.**

### 1.6 Bảng thuật ngữ viết tắt (trang 11 — “6”)

| STT | Tiếng Anh | Tiếng Việt | Viết tắt |
|---|---|---|---|
| 1 | Database Management System | Hệ quản trị cơ sở dữ liệu | DBMS / HQTCSDL |
| 2 | Database | Cơ sở dữ liệu | CSDL |
| 3 | Entity Relationship Diagram | Sơ đồ thực thể liên kết | ERD |
| 4 | Atomicity, Consistency, Isolation, Durability | Tính nguyên tử, tính nhất quán, tính cô lập, tính bền vững | ACID |
| 5 | Structured Query Language | Ngôn ngữ truy vấn có cấu trúc | SQL |
| 6 | Application Programming Interface | Giao diện lập trình ứng dụng | API |
| 7 | Representational State Transfer | Kiến trúc thiết kế API theo tài nguyên | RESTful |
| 8 | HyperText Transfer Protocol | Giao thức truyền tải siêu văn bản | HTTP |
| 9 | JavaScript Object Notation Web Token | Mã xác thực người dùng dạng token | JWT |
| 10 | User Interface / User Experience | Giao diện người dùng / Trải nghiệm người dùng | UI/UX |

---

## 2. Giới thiệu đề tài

*(Trang 16 — đánh số trang in là 11)*

**Bối cảnh:** chuyển đổi số diễn ra mạnh mẽ, áp dụng CNTT vào quản lý là xu hướng tất yếu, trong đó có lĩnh vực thư viện. Quản lý truyền thống bằng sổ sách hoặc các hệ thống rời rạc **không còn đáp ứng** yêu cầu về tính chính xác, tốc độ xử lý và khả năng mở rộng khi số lượng sách và người dùng ngày càng tăng.

**Đề tài:** “Xây dựng hệ thống quản lý thư viện”, hỗ trợ tự động hóa các nghiệp vụ: quản lý độc giả, quản lý nhân sự, quản lý sách và kho sách, hoạt động mượn–trả, và xử lý tiền phạt. Lợi ích nêu ra: **giảm thiểu sai sót, nâng cao hiệu quả làm việc, cải thiện trải nghiệm người sử dụng**.

**Phân chia module (nguyên văn 6 gạch đầu dòng):**

- Module xác thực để quản lý đăng nhập và phân quyền người dùng
- Module quản lý nhân sự và độc giả
- Module quản lý thể loại và kho sách
- Module nghiệp vụ mượn và trả
- Module quản lý tiền phạt
- Module báo cáo và thống kê

**Lập luận kỹ thuật:** cách tổ chức module rõ ràng giúp hệ thống **đảm bảo tính mở rộng, bảo trì dễ dàng** và phù hợp với các hệ thống backend hiện đại. Ngoài ra, sử dụng **view, stored procedure, function và trigger** trong CSDL giúp **tối ưu hiệu năng** và **đảm bảo tính nhất quán dữ liệu**.

**Giá trị học thuật:** củng cố kiến thức về thiết kế hệ thống, cơ sở dữ liệu và lập trình **thông qua ngôn ngữ MySQL**, đồng thời tiếp cận bài toán thực tế trong quản lý thư viện — nền tảng để phát triển các hệ thống quản lý lớn hơn.

---

## 3. Use Case

*(Trang 17–26 — in là 12–21)*

### 3.1 Sơ đồ Use Case tổng quát

**Hình 1 — Sơ đồ Use Case tổng quát** (trang 17, in tr.12). ⚠️ Sơ đồ là **hình ảnh nhúng trong PDF**, không phải văn bản — bản trích xuất này **không chứa được nội dung hình**. Muốn xem phải mở trực tiếp trang 17 của PDF gốc. *(Đây là giới hạn duy nhất về nội dung: xem [§10.10](#1010-những-gì-bản-trích-xuất-này-không-chứa-được).)*

### 3.2 Danh sách tác nhân — Bảng 1

Use Case gồm **2 tác nhân chính: Thủ thư và Quản lý**.

| Tác nhân | Mô tả (nguyên văn) |
|---|---|
| **Thủ thư** (Nhân viên) | Người trực tiếp sử dụng hệ thống để quản lý sách, độc giả, phiếu mượn, xử lý mượn – trả sách, tìm kiếm và tra cứu thông tin. |
| **Quản lý** | Người có quyền quản lý nhân viên, theo dõi hoạt động hệ thống và xem thống kê, báo cáo. |

### 3.3 Danh sách Use Case — Bảng 2

| STT | Use Case | Tác nhân chính | Mô tả ngắn |
|---|---|---|---|
| 1 | Đăng nhập | Thủ thư, Quản lý | Người dùng đăng nhập vào hệ thống để sử dụng các chức năng được phân quyền. |
| 2 | Quản lý thể loại | Thủ thư | Thêm, sửa, xóa và xem danh sách thể loại sách. |
| 3 | Quản lý sách | Thủ thư | Quản lý thông tin đầu sách và các cuốn sách trong thư viện. |
| 4 | Quản lý độc giả | Thủ thư | Thêm, sửa, xóa và tra cứu thông tin độc giả. |
| 5 | Quản lý nhân viên | Quản lý | Quản lý thông tin nhân viên trong hệ thống. |
| 6 | Quản lý phiếu mượn | Thủ thư | Lập, cập nhật, tra cứu phiếu mượn sách. |
| 7 | Quản lý chi tiết phiếu mượn | Thủ thư | Quản lý danh sách các cuốn sách trong từng phiếu mượn. |
| 8 | Quản lý mượn / trả sách | Thủ thư | Xử lý nghiệp vụ cho mượn sách và nhận trả sách. |
| 9 | Tìm kiếm | Thủ thư | Tìm kiếm sách, độc giả hoặc phiếu mượn. |
| 10 | Tra cứu | Thủ thư | Tra cứu lịch sử mượn sách, sách đang mượn hoặc phiếu quá hạn. |
| 11 | Thống kê | Quản lý | Xem thống kê về sách, phiếu mượn, sách đang mượn và tình trạng hoạt động thư viện. |
| 12 | Quản lý phiếu phạt | Thủ thư | Lập và quản lý phiếu phạt khi độc giả trả sách trễ hạn hoặc vi phạm quy định. |
| 13 | Thanh toán phiếu phạt | Thủ thư | Cập nhật trạng thái thanh toán của phiếu phạt. |

### 3.4 Đặc tả Use Case (13 bảng)

#### a. Đăng nhập — Bảng 3 (tr.14)

| Mục | Nội dung |
|---|---|
| Tên Use Case | Đăng nhập |
| Tác nhân | Thủ thư, Quản lý |
| Mục tiêu | Cho phép người dùng đăng nhập vào hệ thống để sử dụng các chức năng theo quyền hạn. |
| Tiền điều kiện | Người dùng đã có tài khoản trong hệ thống. |
| Hậu điều kiện | Người dùng đăng nhập thành công và được chuyển đến giao diện chính. |
| Luồng sự kiện chính | 1. Người dùng mở màn hình đăng nhập.<br>2. Người dùng nhập thông tin tài khoản và mật khẩu.<br>3. Hệ thống kiểm tra thông tin đăng nhập.<br>4. Nếu hợp lệ, hệ thống cho phép người dùng truy cập vào hệ thống. |
| Luồng ngoại lệ | Nếu tài khoản hoặc mật khẩu sai, hệ thống hiển thị thông báo lỗi và yêu cầu nhập lại. |

#### b. Quản lý thể loại — Bảng 4 (tr.14–15) ⚠️

> **Lỗi trong PDF:** bảng mang tiêu đề “Use Case Quản lý thể loại” nhưng **toàn bộ nội dung bị sao chép y nguyên của Use Case Đăng nhập** — kể cả ô “Tên Use Case” cũng ghi *Đăng nhập*. Đặc tả riêng cho Quản lý thể loại **không tồn tại** trong báo cáo. Nguyên văn:

| Mục | Nội dung |
|---|---|
| Tên Use Case | Đăng nhập *(ghi vậy — lỗi sao chép)* |
| Tác nhân | Thủ thư, Quản lý |
| Mục tiêu | Cho phép người dùng đăng nhập vào hệ thống để sử dụng các chức năng theo quyền hạn. |
| Tiền điều kiện | Người dùng đã có tài khoản trong hệ thống. |
| Hậu điều kiện | Người dùng đăng nhập thành công và được chuyển đến giao diện chính. |
| Luồng sự kiện chính | 1. Mở màn hình đăng nhập. 2. Nhập tài khoản/mật khẩu. 3. Hệ thống kiểm tra. 4. Hợp lệ → cho truy cập. |
| Luồng ngoại lệ | Sai tài khoản/mật khẩu → thông báo lỗi, yêu cầu nhập lại. |

#### c. Quản lý sách — Bảng 5 (tr.15)

| Mục | Nội dung |
|---|---|
| Tên Use Case | Quản lý sách |
| Tác nhân | Thủ thư |
| Mục tiêu | Cho phép thủ thư quản lý thông tin đầu sách và các cuốn sách vật lý trong thư viện. |
| Tiền điều kiện | Thủ thư đã đăng nhập vào hệ thống. |
| Hậu điều kiện | Thông tin sách được thêm mới, cập nhật hoặc xóa khỏi hệ thống. |
| Luồng sự kiện chính | 1. Thủ thư chọn chức năng quản lý sách.<br>2. Hệ thống hiển thị danh sách sách.<br>3. Thủ thư thực hiện thêm, sửa, xóa hoặc tìm kiếm sách.<br>4. Hệ thống kiểm tra dữ liệu nhập vào.<br>5. Hệ thống lưu thông tin sách vào cơ sở dữ liệu. |
| Luồng ngoại lệ | Nếu mã đầu sách hoặc mã cuốn sách bị trùng, hệ thống thông báo lỗi. Nếu sách đang được mượn, hệ thống không cho phép xóa. |

#### d. Quản lý độc giả — Bảng 6 (tr.16)

| Mục | Nội dung |
|---|---|
| Tên Use Case | Quản lý độc giả |
| Tác nhân | Thủ thư |
| Mục tiêu | Cho phép thủ thư quản lý thông tin độc giả của thư viện. |
| Tiền điều kiện | Thủ thư đã đăng nhập vào hệ thống. |
| Hậu điều kiện | Thông tin độc giả được cập nhật trong cơ sở dữ liệu. |
| Luồng sự kiện chính | 1. Chọn chức năng quản lý độc giả.<br>2. Hệ thống hiển thị danh sách độc giả.<br>3. Thủ thư chọn thêm, sửa, xóa hoặc tìm kiếm độc giả.<br>4. Thủ thư nhập thông tin độc giả.<br>5. Hệ thống kiểm tra dữ liệu và lưu thông tin. |
| Luồng ngoại lệ | Nếu số điện thoại bị trùng hoặc thông tin bắt buộc bị bỏ trống, hệ thống hiển thị thông báo lỗi. |

#### e. Quản lý nhân viên — Bảng 7 (tr.16–17)

| Mục | Nội dung |
|---|---|
| Tên Use Case | Quản lý nhân viên |
| Tác nhân | Quản lý |
| Mục tiêu | Cho phép quản lý thêm, sửa, xóa và xem thông tin nhân viên. |
| Tiền điều kiện | Quản lý đã đăng nhập vào hệ thống. |
| Hậu điều kiện | Thông tin nhân viên được cập nhật trong hệ thống. |
| Luồng sự kiện chính | 1. Chọn chức năng quản lý nhân viên.<br>2. Hệ thống hiển thị danh sách nhân viên.<br>3. Quản lý thực hiện thêm, sửa hoặc xóa nhân viên.<br>4. Hệ thống kiểm tra dữ liệu.<br>5. Hệ thống lưu thay đổi. |
| Luồng ngoại lệ | Nếu mã nhân viên bị trùng hoặc nhân viên đang liên quan đến phiếu mượn, hệ thống thông báo lỗi và không cho phép xóa. |

#### f. Quản lý phiếu mượn — Bảng 8 (tr.17)

| Mục | Nội dung |
|---|---|
| Tên Use Case | Quản lý phiếu mượn |
| Tác nhân | Thủ thư |
| Mục tiêu | Cho phép thủ thư lập, cập nhật và tra cứu phiếu mượn sách. |
| Tiền điều kiện | Thủ thư đã đăng nhập. Độc giả và sách đã tồn tại trong hệ thống. |
| Hậu điều kiện | Phiếu mượn được tạo hoặc cập nhật trong cơ sở dữ liệu. |
| Luồng sự kiện chính | 1. Chọn chức năng quản lý phiếu mượn.<br>2. Hệ thống hiển thị danh sách phiếu mượn.<br>3. Chọn lập phiếu mượn mới.<br>4. Chọn độc giả, nhân viên xử lý, ngày mượn và ngày trả dự kiến.<br>5. Hệ thống tạo phiếu mượn. |
| Luồng ngoại lệ | Nếu độc giả không tồn tại hoặc thông tin phiếu mượn không hợp lệ, hệ thống hiển thị thông báo lỗi. |

#### g. Quản lý chi tiết phiếu mượn — Bảng 9 (tr.17–18)

| Mục | Nội dung |
|---|---|
| Tên Use Case | Quản lý chi tiết phiếu mượn |
| Tác nhân | Thủ thư |
| Mục tiêu | Cho phép thủ thư thêm các cuốn sách cụ thể vào phiếu mượn. |
| Tiền điều kiện | Phiếu mượn đã được tạo. Cuốn sách tồn tại trong hệ thống. |
| Hậu điều kiện | Chi tiết phiếu mượn được lưu và trạng thái sách được cập nhật. |
| Luồng sự kiện chính | 1. Mở phiếu mượn cần xử lý.<br>2. Chọn cuốn sách cần cho mượn.<br>3. Hệ thống kiểm tra tình trạng cuốn sách.<br>4. Nếu sách đang “Sẵn sàng”, hệ thống thêm sách vào chi tiết phiếu mượn.<br>5. Hệ thống cập nhật trạng thái sách thành “Đang mượn”. |
| Luồng ngoại lệ | Nếu sách không ở trạng thái “Sẵn sàng”, hệ thống không cho mượn và hiển thị thông báo lỗi. |

#### h. Quản lý mượn / trả sách — Bảng 10 (tr.18)

| Mục | Nội dung |
|---|---|
| Tên Use Case | Quản lý mượn / trả sách |
| Tác nhân | Thủ thư |
| Mục tiêu | Xử lý nghiệp vụ cho mượn sách và nhận trả sách từ độc giả. |
| Tiền điều kiện | Thủ thư đã đăng nhập. Phiếu mượn và chi tiết phiếu mượn đã tồn tại. |
| Hậu điều kiện | Trạng thái mượn/trả của sách được cập nhật chính xác. |
| Luồng sự kiện chính | 1. Chọn chức năng mượn / trả sách.<br>2. Hệ thống hiển thị thông tin phiếu mượn.<br>3. Khi cho mượn, hệ thống kiểm tra sách còn sẵn sàng hay không.<br>4. Khi trả sách, thủ thư nhập ngày trả thực tế.<br>5. Hệ thống cập nhật trạng thái chi tiết phiếu mượn và tình trạng cuốn sách. |
| Luồng ngoại lệ | Nếu sách đã được mượn bởi người khác, hệ thống không cho mượn. Nếu trả sách trễ hạn, hệ thống có thể phát sinh phiếu phạt. |

#### i. Tìm kiếm — Bảng 11 (tr.19)

| Mục | Nội dung |
|---|---|
| Tên Use Case | Tìm kiếm |
| Tác nhân | Thủ thư |
| Mục tiêu | Cho phép thủ thư tìm kiếm sách, độc giả hoặc phiếu mượn trong hệ thống. |
| Tiền điều kiện | Thủ thư đã đăng nhập vào hệ thống. |
| Hậu điều kiện | Hệ thống hiển thị danh sách kết quả phù hợp với từ khóa tìm kiếm. |
| Luồng sự kiện chính | 1. Chọn chức năng tìm kiếm.<br>2. Nhập từ khóa cần tìm.<br>3. Hệ thống xử lý từ khóa.<br>4. Hệ thống hiển thị kết quả tìm kiếm. |
| Luồng ngoại lệ | Nếu không có dữ liệu phù hợp, hệ thống hiển thị thông báo không tìm thấy kết quả. |

#### j. Tra cứu — Bảng 12 (tr.19–20)

| Mục | Nội dung |
|---|---|
| Tên Use Case | Tra cứu |
| Tác nhân | Thủ thư |
| Mục tiêu | Cho phép thủ thư tra cứu thông tin lịch sử mượn, sách đang mượn hoặc phiếu mượn quá hạn. |
| Tiền điều kiện | Thủ thư đã đăng nhập vào hệ thống. |
| Hậu điều kiện | Hệ thống hiển thị thông tin tra cứu theo yêu cầu. |
| Luồng sự kiện chính | 1. Chọn chức năng tra cứu.<br>2. Chọn loại thông tin cần tra cứu.<br>3. Hệ thống truy vấn dữ liệu liên quan.<br>4. Hệ thống hiển thị kết quả tra cứu. |
| Luồng ngoại lệ | Nếu dữ liệu không tồn tại, hệ thống hiển thị thông báo không có kết quả phù hợp. |

#### k. Thống kê — Bảng 13 (tr.20)

| Mục | Nội dung |
|---|---|
| Tên Use Case | Thống kê |
| Tác nhân | Quản lý |
| Mục tiêu | Cho phép quản lý xem các thống kê về sách, độc giả, phiếu mượn và tình trạng hoạt động thư viện. |
| Tiền điều kiện | Quản lý đã đăng nhập vào hệ thống. |
| Hậu điều kiện | Hệ thống hiển thị kết quả thống kê. |
| Luồng sự kiện chính | 1. Chọn chức năng thống kê.<br>2. Hệ thống hiển thị các loại thống kê có sẵn.<br>3. Chọn loại thống kê cần xem.<br>4. Hệ thống tổng hợp dữ liệu (khối “4. Hệ thống tổng hợp dữ liệu.” nằm ở đầu trang 21 do ngắt trang).<br>5. Hệ thống hiển thị kết quả thống kê. |
| Luồng ngoại lệ | Nếu không có dữ liệu thống kê, hệ thống hiển thị thông báo phù hợp. |

#### l. Quản lý phiếu phạt — Bảng 14 (tr.20–21)

| Mục | Nội dung |
|---|---|
| Tên Use Case | Quản lý phiếu phạt |
| Tác nhân | Thủ thư |
| Mục tiêu | Cho phép thủ thư lập và quản lý phiếu phạt khi độc giả vi phạm quy định mượn – trả sách. |
| Tiền điều kiện | Thủ thư đã đăng nhập. Độc giả và phiếu mượn liên quan đã tồn tại. |
| Hậu điều kiện | Phiếu phạt được tạo hoặc cập nhật trong hệ thống. |
| Luồng sự kiện chính | 1. Chọn chức năng quản lý phiếu phạt.<br>2. Hệ thống hiển thị danh sách phiếu phạt.<br>3. Chọn lập phiếu phạt mới.<br>4. Nhập mã độc giả, mã phiếu mượn, lý do phạt và số tiền phạt.<br>5. Hệ thống lưu thông tin phiếu phạt. |
| Luồng ngoại lệ | Nếu phiếu mượn không tồn tại hoặc dữ liệu nhập không hợp lệ, hệ thống hiển thị thông báo lỗi. |

#### m. Thanh toán phiếu phạt — Bảng 15 (tr.21)

| Mục | Nội dung |
|---|---|
| Tên Use Case | Thanh toán phiếu phạt |
| Tác nhân | Thủ thư |
| Mục tiêu | Cập nhật trạng thái thanh toán của phiếu phạt khi độc giả đã nộp tiền phạt. |
| Tiền điều kiện | Phiếu phạt đã tồn tại và đang ở trạng thái chưa thanh toán. |
| Hậu điều kiện | Phiếu phạt được cập nhật thành đã thanh toán và lưu ngày thanh toán. |
| Luồng sự kiện chính | 1. Tìm kiếm phiếu phạt cần thanh toán.<br>2. Hệ thống hiển thị thông tin phiếu phạt.<br>3. Xác nhận độc giả đã thanh toán.<br>4. Hệ thống cập nhật trạng thái phiếu phạt thành “Đã thanh toán”.<br>5. Hệ thống lưu ngày thanh toán. |
| Luồng ngoại lệ | Nếu phiếu phạt đã được thanh toán trước đó, hệ thống thông báo không thể thanh toán lại. |

---

## 4. Các module chức năng & API endpoints

*(Trang 27–31 — in là 22–26)*

Báo cáo thiết kế API theo chuẩn **RESTful**: dùng đúng HTTP method theo ngữ nghĩa (`GET` đọc, `POST` tạo/hành động, `PATCH` cập nhật một phần, `DELETE` xóa), tài nguyên số nhiều, và có ghi chú lý do chọn method ở từng dòng.

### 4.1 Module Xác thực (Authentication) — Bảng 16

Tách riêng khỏi User, **chuyên lo việc cấp quyền và định danh**.

| Chức năng | HTTP Method | Endpoint chuẩn | Body / Query |
|---|---|---|---|
| Đăng nhập hệ thống | POST | `/auth/login` | `{MaNV, password}` |
| Lấy thông tin tài khoản đang đăng nhập | GET | `/auth/me` | Dùng **JWT Token trong Header** |

### 4.2 Module Quản lý nhân sự (`/staffs`) — Bảng 17

Tách nhân viên ra khỏi Độc giả. **Chỉ Admin mới có quyền truy cập module này.**

| Chức năng | Method | Endpoint | Giải thích RESTful |
|---|---|---|---|
| Lấy danh sách nhân viên | GET | `/staffs` | Có thể truyền thêm `?keyword=...` để tìm kiếm |
| Xem chi tiết 1 nhân viên | GET | `/staffs/:id` | Lấy data của nhân viên có mã `:id` |
| Tạo nhân viên (kèm tài khoản) | POST | `/staffs` | POST vào tập hợp để sinh ra 1 đối tượng mới |
| Cập nhật thông tin nhân viên | PATCH | `/staffs/:id` | PATCH dùng để cập nhật một phần dữ liệu |
| Xóa nhân viên | DELETE | `/staffs/:id` | DELETE đối tượng `:id` khỏi tập hợp |

### 4.3 Module Quản lý độc giả (`/readers`) — Bảng 18

| Chức năng | Method | Endpoint | Ghi chú |
|---|---|---|---|
| Danh sách / Tìm kiếm độc giả | GET | `/readers` | Query: `?keyword=Nguyễn Văn A` |
| Xem chi tiết 1 độc giả | GET | `/readers/:id` | Hiển thị thông tin cá nhân |
| Thêm độc giả mới | POST | `/readers` | |
| Cập nhật thông tin độc giả | PATCH | `/readers/:id` | |
| Khóa/Xóa thẻ độc giả | DELETE | `/readers/:id` | **Gọi Procedure `KhoaTheDocGia`** |
| Mở khóa thẻ (Hành động phụ) | POST | `/readers/:id/unlock` | Dùng POST cho các hành động đặc thù không phải CRUD chuẩn |

### 4.4 Module Quản lý thể loại (`/categories`) — Bảng 19

| Chức năng | Method | Endpoint |
|---|---|---|
| Lấy danh sách thể loại | GET | `/categories` |
| Thêm thể loại mới | POST | `/categories` |
| Cập nhật thể loại | PATCH | `/categories/:id` |
| Xóa thể loại | DELETE | `/categories/:id` |

### 4.5 Module Quản lý kho sách (`/books`) — Bảng 20

> Định vị module (nguyên văn): “Module này cần bao quát cả việc nhập kho sách vật lý (`cuonsach`) thuộc về đầu sách (`dausach`).”

| Chức năng | Method | Endpoint | Giải thích |
|---|---|---|---|
| Lấy danh sách Đầu sách | GET | `/books` | **Gọi View `v_quanlysach`** để hiển thị kèm số lượng tồn kho |
| Xem chi tiết 1 Đầu sách | GET | `/books/:id` | |
| Thêm Đầu sách mới | POST | `/books` | **Gọi Procedure `ThemDauSach`** |
| Cập nhật Đầu sách | PATCH | `/books/:id` | |
| Xóa Đầu sách | DELETE | `/books/:id` | |
| Lấy danh sách các Cuốn sách vật lý | GET | `/books/:id/instances` | Xem các cuốn `C001`, `C002`… thuộc đầu sách này |
| Nhập kho (Thêm sách vật lý) | POST | `/books/:id/instances` | **Gọi Procedure `NhapKhoCuonSach`** |

### 4.6 Module Nghiệp vụ Mượn–Trả (`/borrow-tickets`) — Bảng 21

> Định vị module (nguyên văn): “Đây là **module phức tạp nhất**, các endpoint cần thể hiện rõ tính **cha-con** (Phiếu mượn ▸ Sách trong phiếu).”

| Chức năng | Method | Endpoint | Giải thích / Body cần truyền |
|---|---|---|---|
| Lấy danh sách Phiếu mượn | GET | `/borrow-tickets` | **Gọi View `v_lichsumuon`** |
| Xem chi tiết 1 Phiếu mượn | GET | `/borrow-tickets/:id` | **Gọi View `v_phieumuonchitiet`** |
| Lập phiếu mượn (Nhiều sách) | POST | `/borrow-tickets` | Chạy `ThucHienMuonNhieuSach` (truyền danh sách sách vào Body) |
| Xóa/Hủy phiếu mượn | DELETE | `/borrow-tickets/:id` | |
| Gia hạn phiếu mượn | PATCH | `/borrow-tickets/:id/deadline` | Body: `{soNgayThem: 7}` |
| Thêm sách vào phiếu đang có | POST | `/borrow-tickets/:id/books` | Body: `[MaCuonSach...]` |
| Trả sách (Xóa khỏi phiếu) | DELETE | `/borrow-tickets/:id/books/:bookId` | Xóa chính xác cuốn `:bookId` khỏi phiếu `:id` |
| Thực hiện trả nhiều sách | POST | `/borrow-tickets/:id/return` | Body: `[MaCuonSach...]` |

### 4.7 Module Quản lý Tiền phạt (`/fines`) — Bảng 22

> Lý do tồn tại module (nguyên văn): “**Bổ sung bắt buộc** vì cơ sở dữ liệu có bảng `phieuphat` và nghiệp vụ thanh toán phạt.”

| Chức năng | Method | Endpoint | Giải thích |
|---|---|---|---|
| Danh sách phiếu phạt | GET | `/fines` | |
| Thanh toán tiền phạt | PATCH | `/fines/:id/pay` | **Chạy Procedure `sp_ThanhToanTienPhat`** |

### 4.8 Module Báo cáo & Thống kê (`/reports`) — Bảng 23

> Endpoint dành riêng cho việc **xuất số liệu Dashboard**.

| Chức năng | Method | Endpoint | Giải thích |
|---|---|---|---|
| Thống kê sách theo thể loại | GET | `/reports/books-by-category` | Trả về tổng sách từng danh mục |
| Thống kê sách đang mượn | GET | `/reports/currently-borrowed` | Trả về các cuốn đang ra khỏi kho |
| Thống kê mượn trả theo thời gian | GET | `/reports/borrow-stats` | Query: `?startDate=...&endDate=...` |
| Báo cáo phiếu quá hạn | GET | `/reports/overdue-tickets` | **Gọi `sp_ThongKePhieuQuaHan_TheoThoiGian`** |

---

## 5. Database

*(Trang 31–40 — in là 26–35)*

### 5.1 Thiết kế cơ sở dữ liệu

**Định vị (nguyên văn):** CSDL là thành phần quan trọng của hệ thống quản lý thư viện, dùng để lưu trữ toàn bộ thông tin về thể loại sách, đầu sách, cuốn sách, độc giả, nhân viên, phiếu mượn, chi tiết phiếu mượn và phiếu phạt. Thiết kế hợp lý giúp **quản lý dữ liệu chính xác, hạn chế trùng lặp** và đảm bảo nghiệp vụ mượn–trả được thực hiện **nhất quán**.

**Mô hình:** quan hệ. Các bảng liên kết qua **khóa chính và khóa ngoại**. Ngoài bảng dữ liệu chính, hệ thống dùng **View, Function, Procedure, Trigger** để hỗ trợ tra cứu, thống kê và tự động xử lý nghiệp vụ quan trọng.

**Cơ sở phân nhóm:** CSDL được xây dựng dựa trên các nhóm chức năng chính — quản lý danh mục sách, quản lý độc giả, quản lý nhân viên, quản lý mượn–trả sách, quản lý phiếu phạt.

**Quyết định thiết kế quan trọng nhất — tách hai mức thông tin sách:**

- Bảng **`DAUSACH`** lưu thông tin **chung** của một đầu sách: tên sách, tác giả, năm xuất bản, thể loại.
- Bảng **`CUONSACH`** lưu **từng cuốn sách vật lý cụ thể** trong thư viện.

> Lập luận nguyên văn: “Cách thiết kế này giúp hệ thống quản lý chính xác từng bản sách khi thực hiện nghiệp vụ mượn và trả. Ví dụ, **một đầu sách có thể có nhiều cuốn sách khác nhau** trong thư viện. Mỗi cuốn sách có **một mã riêng và một tình trạng riêng**. Khi độc giả mượn sách, hệ thống **không chỉ ghi nhận tên sách mà còn ghi nhận chính xác mã cuốn sách được mượn**. Điều này giúp tránh nhầm lẫn trong quá trình quản lý và kiểm soát trạng thái từng cuốn sách.”

**Nghiệp vụ mượn sách:**

- **`PHIEUMUON`** lưu thông tin **chung** của phiếu: độc giả mượn sách, nhân viên lập phiếu, ngày mượn, ngày trả dự kiến, trạng thái tổng thể.
- **`CT_PHIEUMUON`** lưu **chi tiết các cuốn sách** trong từng phiếu. Nhờ đó **một phiếu mượn có thể chứa nhiều cuốn sách khác nhau**.

**Nghiệp vụ xử lý vi phạm:** **`PHIEUPHAT`** lưu phiếu phạt phát sinh từ quá trình mượn–trả. Phiếu phạt có thể phát sinh khi độc giả **trả sách trễ hạn, làm hư hỏng sách hoặc vi phạm quy định** của thư viện.

**Kết luận thiết kế (nguyên văn):** “Khi thiết kế cơ sở dữ liệu bằng cách tách riêng ra nhiều bảng như này sẽ giúp hệ thống **dễ mở rộng, dễ bảo trì và đảm bảo tính toàn vẹn dữ liệu**.”

### 5.2 Mô hình ERD

**Hình 2 — Mô hình ERD** (trang 32, in tr.27). ⚠️ Là **hình ảnh nhúng**, không trích xuất được thành văn bản. Người vẽ: **Nguyễn Ngọc Gia Bảo** (theo bảng phân công nhiệm vụ). Muốn xem chi tiết phải mở trang 32 của PDF gốc.

### 5.3 Danh sách bảng dữ liệu (8 bảng)

Cấu trúc quan hệ suy ra từ các bảng dưới đây:

```
THELOAI ──1──n──> DAUSACH ──1──n──> CUONSACH ──1──n──> CT_PHIEUMUON <──n──1── PHIEUMUON
                                                              │                    │
DOCGIA ──1──────────────n─────────────────────────────────────┼────────────────────┤
                                                              │                    │
NHANVIEN ──1────────────n─────────────────────────────────────┴────────────────────┤
                                                                                   │
PHIEUPHAT ──(MaDocGia)──> DOCGIA ; ──(MaNV)──> NHANVIEN ; ──(MaPM)──> PHIEUMUON ────┘
```

#### 5.3.1 Bảng THELOAI — Bảng 24 (tr.27–28)

Dùng để lưu thông tin các **thể loại sách** trong thư viện; là bảng **phục vụ cho chức năng phân loại đầu sách**.

| Thuộc tính | Ý nghĩa |
|---|---|
| `MaTheLoai` | Mã thể loại, **khóa chính** |
| `TenTheLoai` | Tên thể loại |
| `MoTa` | Mô tả thể loại |

> Giúp hệ thống **phân nhóm sách theo từng loại nội dung**, hỗ trợ việc tìm kiếm và quản lý sách dễ dàng hơn.

#### 5.3.2 Bảng DAUSACH — Bảng 25 (tr.28)

Dùng để lưu **thông tin chung của một đầu sách**.

| Thuộc tính | Ý nghĩa |
|---|---|
| `MaDauSach` | Mã đầu sách, **khóa chính** |
| `TenSach` | Tên sách |
| `TacGia` | Tác giả |
| `NamXuatBan` | Năm xuất bản |
| `MaTheLoai` | Mã thể loại, **khóa ngoại** tham chiếu đến `THELOAI` |

> Bảng này **không đại diện cho từng cuốn sách vật lý cụ thể** mà đại diện cho thông tin chung của một đầu sách.

#### 5.3.3 Bảng CUONSACH — Bảng 26 (tr.28)

Dùng để **quản lý từng cuốn sách vật lý** trong thư viện.

| Thuộc tính | Ý nghĩa |
|---|---|
| `MaCuonSach` | Mã cuốn sách, **khóa chính** |
| `MaDauSach` | Mã đầu sách, **khóa ngoại** tham chiếu đến `DAUSACH` |
| `TinhTrang` | Tình trạng của cuốn sách |

> Tình trạng cuốn sách có thể là **“Sẵn sàng” hoặc “Đang mượn”**. *(Câu này trong PDF nói về `TinhTrang` nhưng giá trị liệt kê lại đúng của `TrangThai` — xem [§10.6](#106-mơ-hồ-giữa-tinhtrang-và-trangthai-của-cuonsach).)* Đây là **bảng rất quan trọng** trong nghiệp vụ mượn–trả vì hệ thống cần biết chính xác **cuốn nào còn trong kho và cuốn nào đang được mượn**.

#### 5.3.4 Bảng DOCGIA — Bảng 27 (tr.29)

Dùng để lưu **thông tin độc giả** của thư viện.

| Thuộc tính | Ý nghĩa |
|---|---|
| `MaDocGia` | Mã độc giả, **khóa chính** |
| `HoTen` | Họ tên độc giả |
| `NgaySinh` | Ngày sinh |
| `DiaChi` | Địa chỉ |
| `DienThoai` | Số điện thoại, **không được trùng** |

> Hỗ trợ các chức năng quản lý độc giả, lập phiếu mượn, tra cứu lịch sử mượn sách và xử lý phiếu phạt.

#### 5.3.5 Bảng NHANVIEN — Bảng 28 (tr.29)

Dùng để lưu **thông tin nhân viên thư viện**.

| Thuộc tính | Ý nghĩa |
|---|---|
| `MaNV` | Mã nhân viên, **khóa chính** |
| `HoTen` | Họ tên nhân viên |
| `DienThoai` | Số điện thoại nhân viên |

> Nhân viên là người **thực hiện các nghiệp vụ** như lập phiếu mượn, xử lý trả sách và lập phiếu phạt.

#### 5.3.6 Bảng PHIEUMUON — Bảng 29 (tr.29–30)

Dùng để lưu **thông tin chung của một lần mượn sách**.

| Thuộc tính | Ý nghĩa |
|---|---|
| `MaPM` | Mã phiếu mượn, **khóa chính** |
| `MaDocGia` | Mã độc giả, **khóa ngoại** tham chiếu đến `DOCGIA` |
| `MaNV` | Mã nhân viên, **khóa ngoại** tham chiếu đến `NHANVIEN` |
| `NgayMuon` | Ngày mượn sách |
| `NgayTraDuKien` | Ngày trả dự kiến |
| `TrangThaiTongThe` | Trạng thái tổng thể của phiếu mượn |

> Cho biết **độc giả nào mượn sách, nhân viên nào lập phiếu, ngày mượn và hạn trả sách**.

#### 5.3.7 Bảng CT_PHIEUMUON — Bảng 30 (tr.30)

Dùng để lưu **chi tiết các cuốn sách trong từng phiếu mượn**.

| Thuộc tính | Ý nghĩa |
|---|---|
| `MaPM` | Mã phiếu mượn, **khóa chính đồng thời là khóa ngoại** |
| `MaCuonSach` | Mã cuốn sách, **khóa chính đồng thời là khóa ngoại** |
| `NgayTraThucTe` | Ngày trả thực tế |
| `TrangThai` | Trạng thái của cuốn sách trong phiếu mượn |

> **Khóa chính của bảng này là cặp `MaPM` và `MaCuonSach`.** Cách thiết kế này giúp **một phiếu mượn có thể chứa nhiều cuốn sách**, đồng thời **tránh việc một cuốn sách bị ghi trùng trong cùng một phiếu mượn**.

#### 5.3.8 Bảng PHIEUPHAT — Bảng 31 (tr.30–31)

Dùng để lưu **các khoản phạt phát sinh trong quá trình mượn–trả sách**.

| Thuộc tính | Ý nghĩa |
|---|---|
| `MaPhieuPhat` | Mã phiếu phạt, **khóa chính** |
| `MaDocGia` | Mã độc giả bị phạt, **khóa ngoại** → `DOCGIA` |
| `MaNV` | Mã nhân viên lập phiếu phạt, **khóa ngoại** → `NHANVIEN` |
| `MaPM` | Mã phiếu mượn liên quan, **khóa ngoại** → `PHIEUMUON` |
| `SoTien` | Số tiền phạt |
| `LyDo` | Lý do phạt |
| `TrangThai` | Trạng thái phiếu phạt |
| `NgayTao` | Ngày tạo phiếu phạt |
| `NgayThanhToan` | Ngày thanh toán tiền phạt |

> Giúp hệ thống quản lý các trường hợp **trả sách trễ hạn, mất sách, hư hỏng sách** hoặc các vi phạm khác.

### 5.4 Khóa chính, khóa ngoại và ràng buộc

**Định vị (nguyên văn):** khóa chính, khóa ngoại và các ràng buộc được sử dụng nhằm **đảm bảo tính toàn vẹn và tính nhất quán** của dữ liệu; giúp hệ thống **tránh các lỗi như trùng mã dữ liệu, nhập dữ liệu không tồn tại, hoặc tạo các bản ghi không hợp lệ**.

#### 5.4.1 Khóa chính — Bảng 32 (tr.31–32)

Khóa chính là loại khóa được **thiết lập duy nhất ở mỗi bản ghi** trong bảng. Các bảng `THELOAI`, `DAUSACH`, `CUONSACH`, `DOCGIA`, `NHANVIEN`, `PHIEUMUON`, `PHIEUPHAT` đều phải có khóa chính riêng. Ở một số trường hợp, một bảng cũng có thể có **nhiều hơn 1 khóa chính — gọi là khóa chính ghép**. Ví dụ, `CT_PHIEUMUON` dùng khóa chính ghép gồm `MaPM` và `MaCuonSach`. Điều này phù hợp với đặc điểm của bảng chi tiết, vì **một phiếu mượn có thể có nhiều cuốn sách** và mỗi dòng chi tiết tương ứng với một cuốn sách cụ thể trong phiếu mượn đó.

| Bảng | Khóa chính | Ý nghĩa |
|---|---|---|
| `THELOAI` | `MaTheLoai` | Định danh duy nhất — mỗi mã thể loại sẽ đều có một mã riêng |
| `DAUSACH` | `MaDauSach` | Định danh duy nhất — mỗi mã đầu sách sẽ đều có một mã riêng |
| `CUONSACH` | `MaCuonSach` | Định danh duy nhất — mỗi mã cuốn sách vật lý sẽ đều có một mã riêng |
| `DOCGIA` | `MaDocGia` | Định danh duy nhất — mỗi độc giả sẽ đều có một mã riêng |
| `NHANVIEN` | `MaNV` | Định danh duy nhất — mỗi nhân viên sẽ đều có một mã riêng |
| `PHIEUMUON` | `MaPM` | Định danh duy nhất — mỗi phiếu mượn sẽ đều có một mã riêng |
| `PHIEUPHAT` | `MaPhieuPhat` | Định danh duy nhất — mỗi phiếu phạt sẽ đều có một mã riêng |
| `CT_PHIEUMUON` | `MaPM, MaCuonSach` | **Khóa chính ghép.** Tác dụng xác định duy nhất **một cuốn sách trong một phiếu mượn** |

#### 5.4.2 Khóa ngoại — Bảng 33 (tr.32–33)

Khóa ngoại dùng để **liên kết dữ liệu giữa các bảng**, đảm bảo **dữ liệu ở bảng con phải tồn tại tương ứng ở bảng cha**. Nhờ đó hệ thống tránh được tình trạng **dữ liệu mồ côi** hoặc dữ liệu không hợp lệ.

| Bảng chứa khóa ngoại | Khóa ngoại | Tham chiếu đến | Ý nghĩa |
|---|---|---|---|
| `DAUSACH` | `MaTheLoai` | `THELOAI.MaTheLoai` | Mỗi đầu sách thuộc một thể loại |
| `CUONSACH` | `MaDauSach` | `DAUSACH.MaDauSach` | Mỗi cuốn sách thuộc một đầu sách |
| `PHIEUMUON` | `MaDocGia` | `DOCGIA.MaDocGia` | Mỗi phiếu mượn thuộc một độc giả |
| `PHIEUMUON` | `MaNV` | `NHANVIEN.MaNV` | Mỗi phiếu mượn do một nhân viên lập |
| `CT_PHIEUMUON` | `MaPM` | `PHIEUMUON.MaPM` | Chi tiết phiếu mượn thuộc một phiếu mượn |
| `CT_PHIEUMUON` | `MaCuonSach` | `CUONSACH.MaCuonSach` | Chi tiết phiếu mượn ghi nhận một cuốn sách cụ thể |
| `PHIEUPHAT` | `MaDocGia` | `DOCGIA.MaDocGia` | Phiếu phạt thuộc về một độc giả |
| `PHIEUPHAT` | `MaNV` | `NHANVIEN.MaNV` | Phiếu phạt do một nhân viên lập |
| `PHIEUPHAT` | `MaPM` | `PHIEUMUON.MaPM` | Phiếu phạt phát sinh từ một phiếu mượn |

**Giải thích của báo cáo (nguyên văn):** `DAUSACH.MaTheLoai` → `THELOAI.MaTheLoai` giúp xác định mỗi đầu sách thuộc thể loại nào; tương tự `CUONSACH.MaDauSach` → `DAUSACH.MaDauSach`. Trong nghiệp vụ mượn sách, `PHIEUMUON.MaDocGia` → `DOCGIA.MaDocGia` và `PHIEUMUON.MaNV` → `NHANVIEN.MaNV`, nhờ đó **mỗi phiếu mượn luôn gắn với một độc giả và một nhân viên cụ thể**. `CT_PHIEUMUON` có hai khóa ngoại quan trọng giúp biết **mỗi dòng chi tiết thuộc phiếu mượn nào và cuốn sách nào đang được mượn**. `PHIEUPHAT` có các khóa ngoại `MaDocGia`, `MaNV`, `MaPM` giúp xác định **phiếu phạt thuộc về độc giả nào, do nhân viên nào lập và phát sinh từ phiếu mượn nào**.

#### 5.4.3 Ràng buộc

##### a. Ràng buộc UNIQUE — Bảng 34 (tr.34)

| Bảng | Thuộc tính | Ý nghĩa |
|---|---|---|
| `DOCGIA` | `DienThoai` | Mỗi số điện thoại chỉ thuộc về một độc giả |
| `PHIEUPHAT` | `MaPM` | Mỗi phiếu mượn chỉ phát sinh tối đa một phiếu phạt |

> UNIQUE trên `DOCGIA.DienThoai` **tránh trường hợp nhiều độc giả khác nhau dùng cùng một số điện thoại**. UNIQUE trên `PHIEUPHAT.MaPM` **tránh tạo nhiều phiếu phạt trùng nhau**, thể hiện quy tắc nghiệp vụ: **một phiếu mượn chỉ phát sinh tối đa một phiếu phạt**. Ví dụ, nếu phiếu mượn `PM001` đã có phiếu phạt, hệ thống **sẽ không cho phép tạo thêm một phiếu phạt khác cũng gắn với PM001**.

##### b. Ràng buộc toàn vẹn dữ liệu (tr.34)

Các ràng buộc giúp đảm bảo **dữ liệu luôn hợp lệ trong quá trình thêm, sửa hoặc xóa dữ liệu**:

- Không thể thêm **đầu sách** nếu **thể loại** không tồn tại.
- Không thể thêm **cuốn sách** nếu **đầu sách** không tồn tại.
- Không thể lập **phiếu mượn** nếu **độc giả hoặc nhân viên** không tồn tại.
- Không thể thêm **chi tiết phiếu mượn** nếu **phiếu mượn hoặc cuốn sách** không tồn tại.
- Không thể lập **phiếu phạt** nếu **độc giả, nhân viên hoặc phiếu mượn** liên quan không tồn tại.
- **Không thể tạo nhiều phiếu phạt cho cùng một phiếu mượn.**

##### c. Ràng buộc trạng thái nghiệp vụ — Bảng 35 (tr.34–35)

| Bảng | Thuộc tính | Dữ liệu phù hợp |
|---|---|---|
| `CUONSACH` | `TinhTrang` | Sẵn sàng / Đang mượn |
| `CT_PHIEUMUON` | `TrangThai` | Đang mượn / Đã trả |
| `PHIEUMUON` | `TrangThaiTongThe` | Trạng thái tổng thể của phiếu mượn (Đang mượn / Đã trả) |
| `PHIEUPHAT` | `TrangThai` | Chưa thanh toán / Đã thanh toán |

> ⚠️ Bảng này ghi `CUONSACH.TinhTrang` nhận giá trị “Sẵn sàng / Đang mượn”, trong khi câu văn §5.3.3 cũng gán các giá trị đó cho `TinhTrang`. Nhưng theo §6.4 thì `TinhTrang` phải là **“Bình Thường”**, còn **“Sẵn sàng / Đang mượn” là giá trị của `TrangThai`**. Xem [§10.6](#106-mơ-hồ-giữa-tinhtrang-và-trangthai-của-cuonsach).

---

## 6. View, Function, Procedure, Trigger

*(Trang 40–43 — in là 35–38)*

### 6.1 View — Bảng 36 (tr.35)

**Mục đích:** tạo các **bảng ảo** phục vụ tra cứu, thống kê và hiển thị dữ liệu. Thay vì phải viết lại nhiều câu lệnh truy vấn phức tạp, hệ thống có thể dùng View để lấy **dữ liệu đã được tổng hợp sẵn từ nhiều bảng**.

| View | Chức năng |
|---|---|
| `v_quanlysach` | Hiển thị thông tin đầu sách, thể loại, **tổng số cuốn** và **số cuốn còn sẵn sàng** |
| `v_phieumuonchitiet` | Hiển thị **chi tiết phiếu mượn** gồm độc giả, nhân viên, sách, ngày mượn, ngày trả |
| `v_lichsumuon` | Hiển thị **lịch sử mượn sách** của độc giả |
| `v_sachdangmuon_docgia` | Thống kê **số sách đang mượn theo từng độc giả** |
| `quanlyphieuquahan` | Hiển thị danh sách **phiếu mượn quá hạn** |
| `thongkesachdangmuon` | Thống kê **số lượng sách đang được mượn** |
| `thongkesachtheotheloai` | Thống kê **tổng số sách theo từng thể loại** |

### 6.2 Function — Bảng 37 (tr.36)

**Mục đích:** dùng như một **hàm** để thực hiện các phép tính hoặc **trả về một giá trị** phục vụ nghiệp vụ. Hệ thống có **hai Function quan trọng**:

| Function | Chức năng |
|---|---|
| `fn_DemSoSachDangMuon` | **Đếm số sách đang mượn của một độc giả.** Có thể dùng để **kiểm tra điều kiện trước khi cho mượn sách**, tránh trường hợp một độc giả mượn quá số lượng cho phép |
| `fn_TinhTienPhat` | **Tính tiền phạt dựa trên số ngày trả trễ** (số ngày trả trễ dựa vào **ngày trả dự kiến** và **ngày trả thực tế**) |

### 6.3 Procedure — Bảng 38 (tr.36–37)

**Mục đích:** **đóng gói các thao tác xử lý nghiệp vụ phức tạp**. Thay vì để chương trình thực hiện từng câu lệnh SQL riêng lẻ, hệ thống gom các bước xử lý vào Procedure để đảm bảo **tính nhất quán và dễ bảo trì**.

| Procedure | Chức năng |
|---|---|
| `ThemTheLoai`, `CapNhatTheLoai`, `XoaTheLoai` | Thêm, cập nhật, xóa thể loại |
| `ThemDauSach`, `CapNhatDauSach`, `TimKiemDauSach` | Quản lý thông tin đầu sách |
| `NhapKhoCuonSach` | Thêm cuốn sách vật lý vào kho |
| `ThemDocGia`, `CapNhatDocGia`, `TimDocGia`, `sp_TimKiemDocGia` | Quản lý và tìm kiếm độc giả |
| `ThemNhanVien`, `CapNhatNhanVien` | Quản lý nhân viên |
| `ThucHienMuonNhieuSach` | Thực hiện mượn nhiều cuốn sách trong một phiếu mượn |
| `ThucHienTraSach` | Xử lý trả nhiều cuốn sách |
| `GiaHanSach` | Gia hạn thời gian trả sách |
| `sp_TraCuuPhieuMuon` | Tra cứu phiếu mượn |
| `sp_ThanhToanTienPhat` | Xử lý thanh toán tiền phạt |

**Phân tích ba Procedure quan trọng (nguyên văn):**

- **`ThucHienMuonNhieuSach`** — *Procedure quan trọng nhất* vì xử lý nghiệp vụ mượn sách. Khi độc giả mượn nhiều cuốn, hệ thống **tạo phiếu mượn mới trong bảng `PhieuMuon`**, sau đó **thêm từng cuốn sách vào bảng `CT_PhieuMuon`**. Quá trình này được **đặt trong một giao tác** để đảm bảo **nếu có lỗi xảy ra trong quá trình thêm sách, hệ thống có thể hủy bỏ thao tác và tránh dữ liệu bị sai lệch**.
- **`ThucHienTraSach`** — cập nhật **ngày trả thực tế** và **trạng thái** của các cuốn sách được trả. Khi trạng thái trong `CT_PhieuMuon` được cập nhật thành **“Đã trả”**, **Trigger sẽ tự động cập nhật lại tình trạng cuốn sách trong bảng `CuonSach` thành “Sẵn sàng”**.
- **`sp_ThanhToanTienPhat`** — xử lý nghiệp vụ thanh toán tiền phạt. Procedure này **có sử dụng giao tác, kiểm tra trạng thái phiếu phạt và khóa dòng dữ liệu cần xử lý** để **tránh trường hợp nhiều nhân viên cùng thanh toán một phiếu phạt**.

**Procedure khác xuất hiện trong luồng API nhưng không có trong Bảng 38:** `KhoaTheDocGia` (khóa thẻ độc giả — §4.3) và `sp_ThongKePhieuQuaHan_TheoThoiGian` (báo cáo quá hạn — §4.8).

### 6.4 Trigger — Bảng 39 (tr.37–38)

**Mục đích:** **tự động thực hiện một thao tác khi có sự kiện thêm, sửa hoặc xóa dữ liệu** xảy ra trên bảng.

| Trigger | Bảng tác động | Thời điểm | Chức năng chính |
|---|---|---|---|
| `trg_MuonSach_CapNhatTrangThai` | `CT_PHIEUMUON` | **BEFORE INSERT** | Kiểm tra cuốn sách có **đủ điều kiện cho mượn** không. Nếu hợp lệ thì cập nhật **trạng thái sách thành “Đang mượn”** |
| `trg_TraSach_XuLyTuDong` | `CT_PHIEUMUON` | **AFTER UPDATE** | Khi sách được trả, **tự động hoàn lại trạng thái sách, tính tiền phạt nếu trả trễ, sinh phiếu phạt và cập nhật trạng thái phiếu mượn** |
| `trg_KiemTraDocGiaQuaHan` | `PHIEUMUON` | **BEFORE INSERT** | Kiểm tra độc giả có **phiếu mượn quá hạn** hoặc **đã mượn đủ số lượng sách cho phép** hay chưa |
| `trg_XoaPhieuMuon_HoanTonKho` | `PHIEUMUON` | **BEFORE DELETE** | Khi xóa phiếu mượn, **tự động hoàn lại trạng thái các cuốn sách đang mượn về “Sẵn sàng”** |

**Diễn giải chi tiết (nguyên văn):** Trigger được dùng để tự động xử lý các nghiệp vụ quan trọng liên quan đến **mượn sách, trả sách, kiểm tra điều kiện mượn và cập nhật trạng thái sách**.

- Khi thủ thư thêm một cuốn sách vào chi tiết phiếu mượn, `trg_MuonSach_CapNhatTrangThai` kiểm tra cuốn sách có đang ở trạng thái **“Sẵn sàng”** và có tình trạng **“Bình Thường”** hay không. **Nếu không hợp lệ, hệ thống báo lỗi và không cho mượn. Nếu hợp lệ, hệ thống tự động chuyển trạng thái cuốn sách sang “Đang mượn”.**
- Khi độc giả trả sách, `trg_TraSach_XuLyTuDong` tự động: cập nhật trạng thái cuốn sách về **“Sẵn sàng”**, **tính tiền phạt nếu trả trễ hạn**, **sinh phiếu phạt nếu có phát sinh tiền phạt**, và **cập nhật trạng thái phiếu mượn thành “Hoàn tất” nếu tất cả sách trong phiếu đã được trả**.
- `trg_KiemTraDocGiaQuaHan` kiểm tra độc giả **trước khi lập phiếu mượn mới**, nhằm **ngăn trường hợp độc giả còn sách quá hạn hoặc đã mượn đủ số lượng sách cho phép**.
- `trg_XoaPhieuMuon_HoanTonKho` hoàn lại trạng thái sách về **“Sẵn sàng”** khi phiếu mượn bị xóa.

> **Kết luận (nguyên văn):** “Nhờ các Trigger này, hệ thống **giảm bớt thao tác xử lý thủ công**, đảm bảo dữ liệu giữa các bảng `PHIEUMUON`, `CT_PHIEUMUON`, `CUONSACH` và `PHIEUPHAT` **luôn được cập nhật đồng bộ** và phù hợp với nghiệp vụ thực tế.”

---

## 7. Giao tác và tính chất ACID

*(Trang 43–47 — in là 38–42)*

**Định vị:** “Một giao tác cần đảm bảo bốn tính chất ACID gồm: **Atomicity, Consistency, Isolation và Durability**.”

### 7.1 Tính nguyên tử (Atomicity)

**Ý nghĩa:** giao tác được xem là **một khối xử lý không thể chia nhỏ**.

**Hoạt động:**
- Hoặc thực hiện **toàn bộ** các thao tác → **COMMIT**
- Hoặc nếu có lỗi thì **hủy toàn bộ** → **ROLLBACK**

**Ví dụ thư viện:** khi độc giả mượn nhiều cuốn sách, hệ thống phải thực hiện nhiều bước:
1. Tạo phiếu mượn trong bảng `PhieuMuon`
2. Thêm từng cuốn sách vào bảng `CT_PhieuMuon`
3. Cập nhật tình trạng sách trong bảng `CuonSach` thành **“Đang mượn”**

Nếu độc giả mượn **3 cuốn** nhưng đến **cuốn thứ 2 bị lỗi** (ví dụ cuốn đó đã được người khác mượn trước), thì hệ thống **không được lưu nửa chừng**.

**Trường hợp lỗi:**
- Đã tạo `PhieuMuon`
- Đã thêm được cuốn `C001` vào `CT_PhieuMuon`
- Nhưng cuốn `C002` không còn “Sẵn sàng”

Nếu **không có Atomicity**, hệ thống có thể bị **sai dữ liệu**: phiếu mượn đã được tạo nhưng **danh sách sách mượn không đầy đủ**.

**Cách xử lý đúng:**
- Nếu **tất cả** cuốn sách đều hợp lệ → **COMMIT**
- Nếu có **bất kỳ** cuốn nào lỗi → **ROLLBACK toàn bộ giao tác**

### 7.2 Tính nhất quán (Consistency)

**Ý nghĩa:** sau khi giao tác kết thúc, CSDL phải ở **trạng thái hợp lệ** và **tuân thủ đầy đủ các ràng buộc**.

**Ràng buộc trong hệ thống gồm:**
- Khóa chính
- Khóa ngoại
- `NOT NULL`
- `UNIQUE`
- `ENUM` / trạng thái hợp lệ
- Ràng buộc nghiệp vụ mượn–trả sách

**Ví dụ 1:** Không thể thêm chi tiết phiếu mượn nếu mã phiếu mượn hoặc mã cuốn sách không tồn tại.

```sql
INSERT INTO CT_PhieuMuon(MaPM, MaCuonSach, TrangThai)
VALUES ('PM999', 'C001', 'Đang mượn');
```

Nếu `PM999` không tồn tại trong bảng `PhieuMuon`, thao tác này **vi phạm khóa ngoại**.

**Kết quả đúng:**
- Hệ thống **không cho thêm dữ liệu**
- Giao tác **bị hủy**
- CSDL **vẫn giữ trạng thái nhất quán**

**Ví dụ 2 — chuyển trạng thái phải đồng bộ:**
- Khi một cuốn sách được mượn, trạng thái trong `CuonSach` phải chuyển **“Sẵn sàng” → “Đang mượn”**
- Khi sách được trả, trạng thái phải chuyển lại **“Đang mượn” → “Sẵn sàng”**

Nếu `CT_PhieuMuon` ghi rằng sách đang mượn nhưng `CuonSach` vẫn ghi “Sẵn sàng”, **dữ liệu bị mất nhất quán**.

### 7.3 Tính cô lập (Isolation)

**Ý nghĩa:** các giao tác chạy đồng thời **không được làm ảnh hưởng sai lệch lẫn nhau**. Tức là **mỗi giao tác cần phải cho kết quả như thể nó đang chạy một mình**, dù trên thực tế có nhiều nhân viên cùng thao tác hệ thống.

**Nếu không có Isolation, sẽ gây ra các lỗi:**
- Lỗi mất dữ liệu cập nhật (**Lost Update**)
- Lỗi đọc dữ liệu rác (**Dirty Read**)
- Lỗi không đọc lại được dữ liệu (**Non-repeatable Read**)
- **Bóng ma (Phantom)**

**Ví dụ thư viện:** hai nhân viên cùng lúc cho mượn cùng một cuốn sách `C001`.
- `NV01` kiểm tra `C001` → thấy **“Sẵn sàng”**
- `NV02` cũng kiểm tra `C001` → cũng thấy **“Sẵn sàng”**
- `NV01` lập phiếu mượn `C001`
- `NV02` cũng lập phiếu mượn `C001`

Nếu không có cơ chế cô lập giao tác, **cùng một cuốn sách vật lý có thể bị ghi vào hai phiếu mượn khác nhau**.

**Kết quả sai:**
- `C001` xuất hiện trong **2 phiếu mượn**
- Cả hai độc giả đều được ghi nhận là **đã mượn C001**
- Trạng thái sách **bị sai về mặt nghiệp vụ**

**Cách xử lý đúng:**
- Khi một nhân viên đang xử lý mượn `C001`, **giao tác khác phải chờ**
- Sau khi giao tác đầu tiên hoàn tất, hệ thống **kiểm tra lại trạng thái sách**
- Nếu `C001` đã “Đang mượn” thì **không cho nhân viên thứ hai mượn nữa**

> “Điều này giúp đảm bảo **một cuốn sách chỉ có thể được mượn bởi một độc giả tại một thời điểm**.”

### 7.4 Tính bền vững (Durability)

**Ý nghĩa:** khi giao tác đã **COMMIT**, dữ liệu phải được **lưu lại bền vững**, không bị mất ngay cả khi hệ thống gặp sự cố.

**Cách thực hiện:**
- Hệ quản trị CSDL **ghi log**
- Lưu dữ liệu xuống **bộ nhớ ổn định**
- Có **cơ chế khôi phục** khi xảy ra lỗi

**Ví dụ thư viện:** nhân viên thực hiện mượn sách thành công cho độc giả. Sau khi giao tác đã COMMIT, hệ thống đã lưu:
- Thông tin phiếu mượn trong bảng `PhieuMuon`
- Danh sách sách mượn trong bảng `CT_PhieuMuon`
- Trạng thái sách trong bảng `CuonSach` là **“Đang mượn”**

Nếu **server bị sập ngay sau đó**, dữ liệu đã commit **vẫn phải được giữ lại**.

**Kết quả đúng:**
- Phiếu mượn vẫn tồn tại
- Chi tiết phiếu mượn vẫn tồn tại
- Trạng thái sách vẫn là **“Đang mượn”**

---

## 8. Các lỗi xung đột, tranh chấp và cách xử lý

*(Trang 47–58 — in là 42–53)*

**Định vị chương (nguyên văn):** trong hệ thống quản lý thư viện, **nhiều nhân viên có thể thao tác cùng lúc trên cùng một dữ liệu**, đặc biệt trong các nghiệp vụ mượn sách, trả sách, cập nhật trạng thái sách, thống kê… Nếu hệ thống **không kiểm soát tốt giao tác** thì dữ liệu có thể bị sai lệch hoặc không nhất quán, dẫn đến các lỗi: **lost update, dirty read, non-repeatable read, phantom**. Các lỗi này ảnh hưởng trực tiếp đến **trạng thái sách, phiếu mượn, phiếu phạt và kết quả thống kê** của hệ thống.

### 8.1 Lỗi mất dữ liệu cập nhật (Lost Update)

#### Khái niệm
Xảy ra khi **hai giao tác cùng đọc và cập nhật một dữ liệu**, nhưng **kết quả cập nhật của giao tác này bị giao tác khác ghi đè hoặc làm mất**. Trong hệ thống thư viện, lỗi này có thể xảy ra khi **hai nhân viên cùng lúc xử lý cho mượn cùng một cuốn sách vật lý**.

#### Tình huống
Cuốn sách `C006` đang có:
- `TrangThai = 'Sẵn sàng'`
- `TinhTrang = 'Bình Thường'`

Hai nhân viên cùng lúc lập phiếu mượn cho cùng cuốn `C006`:
- `NV01` lập phiếu mượn cho độc giả `DG01`, chọn cuốn `C006`
- Cùng lúc đó, `NV02` lập phiếu mượn cho độc giả `DG02`, cũng chọn cuốn `C006`

#### Trình bày lỗi trên hệ thống
```sql
-- Giao tác T1: NV01
SELECT TrangThai, TinhTrang
FROM CuonSach
WHERE MaCuonSach = 'C006';
-- Kết quả: TrangThai = 'Sẵn sàng', TinhTrang = 'Bình Thường'

-- Giao tác T2: NV02 đọc gần như cùng lúc
SELECT TrangThai, TinhTrang
FROM CuonSach
WHERE MaCuonSach = 'C006';
-- Kết quả: TrangThai = 'Sẵn sàng', TinhTrang = 'Bình Thường'

-- T1 thêm sách vào chi tiết phiếu mượn
INSERT INTO CT_PhieuMuon(MaPM, MaCuonSach, TrangThai)
VALUES ('PM_A', 'C006', 'Đang mượn');

-- T2 cũng thêm sách vào chi tiết phiếu mượn
INSERT INTO CT_PhieuMuon(MaPM, MaCuonSach, TrangThai)
VALUES ('PM_B', 'C006', 'Đang mượn');
```

#### Kết quả
**Kết quả sai:**
- `C006` xuất hiện trong **hai phiếu mượn khác nhau** (một cuốn sách vật lý bị cho **hai độc giả** mượn)
- Trạng thái cuối của sách là “Đang mượn” nhưng **dữ liệu không xác định phiếu nào là hợp lệ**
- → **Hệ thống mất tính nhất quán**

**Kết quả đúng mong muốn:**
- Đầu tiên, `NV01` xử lý trước: hệ thống **cho lập phiếu mượn thành công**
- Sau đó, `NV02` xử lý sau: hệ thống **báo lỗi: “Cuốn sách này không có sẵn trong kho để cho mượn!”**

### 8.2 Lỗi đọc dữ liệu rác (Dirty Read)

#### Khái niệm
Xảy ra khi **một giao tác đọc dữ liệu chưa được xác nhận COMMIT từ giao tác khác**. Nếu giao tác kia sau đó bị **ROLLBACK**, dữ liệu đã đọc trở thành **dữ liệu không hợp lệ**. Trong hệ thống thư viện, lỗi này có thể xảy ra khi **một nhân viên đang xử lý mượn sách nhưng chưa commit, trong khi nhân viên khác lại đọc trạng thái sách đó**.

#### Tình huống
`NV01` đang xử lý mượn cuốn `C007`, nhưng **giao tác chưa hoàn tất**. `NV02` **kiểm tra tình trạng cuốn sách trong lúc đó**.

**Bảng 40 — Lịch giao tác (Lỗi đọc dữ liệu rác):**

| NV01 (T1) | NV02 (T2) |
|---|---|
| Cập nhật cuốn `C007` thành `Đang mượn`, nhưng **chưa commit** | |
| | Kiểm tra trạng thái cuốn `C007` |
| Giao tác **bị lỗi và rollback** | |

> `NV02` đã đọc một **trạng thái chưa được xác nhận**. Trạng thái đó sau đó bị hủy nên **không tồn tại thật trong cơ sở dữ liệu**.

#### Trình bày lỗi trên hệ thống
```sql
-- Giao tác T1: NV01
START TRANSACTION;

UPDATE CuonSach
SET TrangThai = 'Đang mượn'
WHERE MaCuonSach = 'C007';
-- Chưa COMMIT

-- Giao tác T2: NV02
SELECT TrangThai
FROM CuonSach
WHERE MaCuonSach = 'C007';
-- Nếu đọc được dữ liệu chưa commit: TrangThai = 'Đang mượn'

-- T1 xảy ra lỗi
ROLLBACK;
```

#### Kết quả
**Kết quả sai:**
- `NV02` kiểm tra sách và thấy `C007` đang ở trạng thái **“Đang mượn”**
- Sau khi T1 rollback thì `C007` thực tế **vẫn đang ở trạng thái “Sẵn sàng”**

**Kết quả đúng mong muốn:**
- Khi `NV02` kiểm tra sách mà **dữ liệu chưa được commit** thì **giao tác sẽ không thể đọc được**
- Sau khi T1 rollback thì `C007` ở trạng thái **“Sẵn sàng”**, nhưng trước kia `NV02` **không thấy được dữ liệu rác** như trường hợp sai ở trên

### 8.3 Lỗi không đọc lại được dữ liệu (Non-repeatable Read)

#### Khái niệm
Xảy ra khi **một giao tác đọc cùng một dòng dữ liệu hai lần**, nhưng **giữa hai lần đọc có giao tác khác cập nhật và commit dữ liệu đó**. Kết quả là **hai lần đọc cho ra hai giá trị khác nhau**. Trong hệ thống thư viện, lỗi này có thể xảy ra khi **một nhân viên đang xem thông tin một cuốn sách, trong khi nhân viên khác cập nhật trạng thái của cuốn sách đó**.

#### Tình huống
`NV01` đang xem thông tin cuốn `C009`. Ban đầu, cuốn sách đang **Sẵn sàng**. Trong lúc đó, `NV02` **lập phiếu mượn cho cuốn này và commit**.

**Bảng 41 — Lịch giao tác (Lỗi không đọc lại được dữ liệu):**

| NV01 (T1) | NV02 (T2) |
|---|---|
| Mở màn hình chi tiết cuốn `C009` | |
| | Lập phiếu mượn cuốn `C009` và **commit** |
| Kiểm tra lại thông tin cuốn `C009` | |
| Thấy sách `C009` vẫn còn | |

> Trong cùng một lịch giao tác, sẽ xảy ra trường hợp **nhân viên đọc cùng một cuốn sách nhưng nhận hai kết quả khác nhau**. Nếu `NV01` đang chuẩn bị lập phiếu mượn, **dữ liệu ban đầu có thể làm nhân viên hiểu nhầm rằng sách vẫn còn**.

#### Trình bày lỗi trên hệ thống
```sql
-- Giao tác T1: NV01
START TRANSACTION;

SELECT TrangThai
FROM CuonSach
WHERE MaCuonSach = 'C009';
-- Lần 1: TrangThai = 'Sẵn sàng'

-- Giao tác T2: NV02
START TRANSACTION;

UPDATE CuonSach
SET TrangThai = 'Đang mượn'
WHERE MaCuonSach = 'C009';

COMMIT;

-- T1 - NV01 đọc lại
SELECT TrangThai
FROM CuonSach
WHERE MaCuonSach = 'C009';
-- Lần 2: TrangThai = 'Đang mượn'
```

#### Kết quả
**Kết quả sai:**
- Đọc **lần 1**: thấy sách chưa có ai mượn (trạng thái **“Sẵn sàng”**)
- Đọc **lần 2**: thấy sách đã được mượn (trạng thái **“Đang mượn”**)

**Các cách để có kết quả đúng mong muốn:**
- Nên **kiểm tra lại trạng thái sách ngay trước khi thêm vào phiếu mượn**
- Nếu sách đã được mượn thì hệ thống **ngay lập tức báo lỗi và không cho mượn**

### 8.4 Bóng ma (Phantom)

#### Khái niệm
Xảy ra khi **một giao tác đọc một tập bản ghi theo điều kiện nào đó**, nhưng **giao tác khác thêm, xóa hoặc cập nhật bản ghi làm thay đổi tập kết quả**. Khi giao tác đầu tiên truy vấn lại, **kết quả xuất hiện thêm hoặc mất đi các dòng dữ liệu**. Trong hệ thống thư viện, lỗi này **thường xuất hiện trong các chức năng tìm kiếm, tra cứu hoặc thống kê**.

#### Tình huống
`NV01` đang **thống kê số cuốn sách thuộc thể loại `TL01`**. Sau khi `NV01` thống kê là có **5 cuốn sách** thuộc thể loại `TL01`. Trong lúc đó, `NV02` **nhập thêm một cuốn sách mới** thuộc một đầu sách của thể loại `TL01`. Như vậy, `NV02` khi xuất kết quả thống kê ra thì sẽ thấy **6 cuốn sách** thuộc thể loại `TL01`.

**Bảng 42 — Lịch giao tác (Lỗi bóng ma):**

| NV01 (T1) | NV02 (T2) |
|---|---|
| Thống kê **15** cuốn sách thuộc thể loại `TL01` | |
| | Thêm một cuốn sách mới (`C006`) thuộc thể loại `TL01` |
| Xuất thống kê<br>Thấy **6** cuốn sách nhưng thực tế lúc nãy chỉ thống kê được **5** cuốn sách | |
| | Xuất thống kê |
| | Thấy **6** cuốn sách như đã thống kê |

> Trong cùng một giao tác thống kê, **tập dữ liệu bị thay đổi do giao tác khác thêm bản ghi mới**. Cuốn sách mới xuất hiện đó **giống như một “bóng ma”** trong kết quả truy vấn.

#### Trình bày lỗi trên hệ thống
```sql
-- Giao tác T1: NV01
START TRANSACTION;

SELECT cs.MaCuonSach, ds.TenSach, ds.MaTheLoai
FROM CuonSach cs
JOIN DauSach ds ON cs.MaDauSach = ds.MaDauSach
WHERE ds.MaTheLoai = 'TL01';
-- Kết quả lần 1: 5 dòng

-- Giao tác T2: NV02
START TRANSACTION;

INSERT INTO CuonSach(MaCuonSach, MaDauSach, TrangThai, TinhTrang)
VALUES ('C015', 'DS01', 'Sẵn sàng', 'Bình Thường');

COMMIT;

-- T1 - NV01 truy vấn lại
SELECT cs.MaCuonSach, ds.TenSach, ds.MaTheLoai
FROM CuonSach cs
JOIN DauSach ds ON cs.MaDauSach = ds.MaDauSach
WHERE ds.MaTheLoai = 'TL01';
-- Kết quả lần 2: 6 dòng
```

#### Kết quả
**Kết quả sai:**
- `NV01` thống kê **lần 1**: **5** cuốn sách thuộc thể loại `TL01`
- `NV01` thống kê **lần 2**: **6** cuốn sách thuộc thể loại `TL01` (xuất hiện **dữ liệu bóng ma**)
- Lí do (nguyên văn): “Cuốn sách `C006` xuất hiện thêm trong kết quả sau khi `NV02` nhập vào trước khi `NV01` thống kê lần 1”

**Các cách để có kết quả đúng mong muốn:**
- Khi báo cáo/thống kê thì **kết quả phải giữ nguyên trong suốt giao tác**
- Nên **báo cáo theo thời gian thực**
- Dùng **mức cô lập cao hơn như *seriablizable*** *(PDF viết vậy; đúng chính tả: **serializable**)* hoặc **khóa phạm vi dữ liệu**

### 8.5 Khóa chết (Deadlock)

#### Khái niệm
Xảy ra khi **hai hoặc nhiều giao tác giữ tài nguyên mà giao tác khác cần, đồng thời mỗi giao tác lại chờ tài nguyên do giao tác còn lại đang giữ**. Khi đó, các giao tác rơi vào **trạng thái chờ lẫn nhau** và **không giao tác nào có thể tiếp tục thực hiện**. Trong hệ thống quản lý thư viện, deadlock có thể xảy ra khi **hai nhân viên cùng lúc xử lý mượn nhiều cuốn sách, nhưng thứ tự khóa các cuốn sách không giống nhau**.

#### Tình huống
Hai nhân viên cùng xử lý mượn hai cuốn sách `C001` và `C002`.

**Bảng 43 — Lịch giao tác (Lỗi khóa chết):**

| NV01 (T1) | NV02 (T2) |
|---|---|
| Lập phiếu mượn `C001` | |
| | Lập phiếu mượn `C002` |
| Lập phiếu mượn `C002` | |
| | Lập phiếu mượn `C001` |
| Commit sau khi đã lập phiếu mượn `C001` | |
| | Commit sau khi đã lập phiếu mượn `C002` |

> **Giải thích nguyên văn:** “Trong thực tế, nếu thực hiện theo lịch giao tác này thì sẽ xảy ra lỗi deadlock ngay vì giao tác T1 đang giữ khóa `C001` và chờ khóa `C002` của T2 nhưng giao tác T2 lại đang chờ khóa `C001` của T1 mà cũng vừa giữ khóa `C002`. Điều này khiến cho hai giao tác T1 và T2 **chờ lẫn nhau** và xảy ra trường hợp khóa chết.”

#### Trình bày lỗi trên hệ thống
```sql
-- Giao tác T1: NV01
START TRANSACTION;

SELECT *
FROM CuonSach
WHERE MaCuonSach = 'C001'
FOR UPDATE;
-- T1 khóa C001

-- Giao tác T2: NV02
START TRANSACTION;

SELECT *
FROM CuonSach
WHERE MaCuonSach = 'C002'
FOR UPDATE;
-- T2 khóa C002

-- T1 muốn khóa tiếp C002
SELECT *
FROM CuonSach
WHERE MaCuonSach = 'C002'
FOR UPDATE;
-- T1 phải chờ T2 nhả khóa C002

-- T2 muốn khóa tiếp C001
SELECT *
FROM CuonSach
WHERE MaCuonSach = 'C001'
FOR UPDATE;
-- T2 phải chờ T1 nhả khóa C001
```

#### Kết quả
**Kết quả sai:**
- `NV01` **đang giữ khóa `C001`** và **chờ khóa `C002`**
- `NV02` **đang giữ khóa `C002`** và **chờ khóa `C001`**
- → Hai giao tác **chờ lẫn nhau**, gây ra **deadlock**

> Khi xảy ra deadlock, hệ thống **có thể bị treo tại nghiệp vụ đang xử lý nếu không có cơ chế phát hiện và xử lý**. Trong thực tế, **hệ quản trị cơ sở dữ liệu thường phát hiện deadlock và chọn một giao tác để rollback, giao tác còn lại tiếp tục thực hiện**.

**Bảng 44 — Lịch giao tác (Khắc phục lỗi khóa chết):**

| NV01 (T1) | NV02 (T2) | Hệ thống (T3) |
|---|---|---|
| Lập phiếu mượn `C001` | | |
| | Lập phiếu mượn `C002` | |
| Lập phiếu mượn `C002` | | Chờ xử lý, không hoàn tất được giao tác lập phiếu mượn |
| | Lập phiếu mượn `C001` | Chờ xử lý, không hoàn tất được giao tác lập phiếu mượn |
| | | **Phát hiện deadlock, cần rollback một giao tác** → Thông báo lỗi và **rollback T2** |
| Lập phiếu mượn `C002` | | |
| Commit sau khi đã lập phiếu mượn `C001` | | |
| | Commit sau khi đã lập phiếu mượn `C002` | |
| | Lập phiếu mượn `C002` | |
| | Lập phiếu mượn `C001` | |
| | Commit sau khi đã lập phiếu mượn `C002` | |
| | Commit sau khi đã lập phiếu mượn `C001` | |

> **Kết luận nguyên văn (tr.55):** “Nếu làm theo cách này thì sẽ có thể **hạn chế được các tình trạng xảy ra khóa chết** trong hệ thống.”
> *(⚠️ Bảng 44 trong PDF có các ô bị lệch/dồn cột — đây là cách tái dựng trung thực nhất theo thứ tự dòng đọc được; xem [§10.8](#108-bảng-44-lịch-giao-tác-bị-vỡ-cột).)*

**Kết quả đúng mong muốn:**
- **Một giao tác được ưu tiên xử lý** và **giao tác còn lại bị rollback**
- Người dùng bị rollback: **nhận thông báo và có thể thực hiện lại thao tác**
- Giao tác được ưu tiên xử lý xong thì **giao tác còn lại có thể xử lý sau đó**

### 8.6 Cách hệ thống xử lý bằng transaction, trigger và rollback

#### 8.6.1 Xử lý bằng transaction

Transaction được dùng cho các nghiệp vụ **gồm nhiều bước liên quan đến nhiều bảng**. Trong hệ thống thư viện, các nghiệp vụ cần transaction gồm:
- Lập phiếu mượn
- Thêm nhiều sách vào phiếu mượn
- Trả sách
- Tính và sinh phiếu phạt
- Thanh toán phiếu phạt
- Xóa phiếu mượn

**Ví dụ — khi lập phiếu mượn, hệ thống cần thực hiện nhiều bước:**
1. Tạo phiếu mượn trong bảng `PHIEUMUON`
2. Thêm từng cuốn sách vào bảng `CT_PHIEUMUON`
3. Cập nhật trạng thái sách trong bảng `CUONSACH`
4. Nếu **tất cả thành công** thì **COMMIT**
5. Nếu **có lỗi** thì **ROLLBACK toàn bộ**

> Nhờ transaction, hệ thống **tránh được tình trạng chỉ lưu một phần dữ liệu**. Ví dụ, nếu đã tạo phiếu mượn nhưng đến bước thêm sách bị lỗi, **toàn bộ giao tác sẽ bị hủy** để tránh **phiếu mượn thiếu chi tiết**.

#### 8.6.2 Xử lý bằng trigger — Bảng 45

Hệ thống dùng trigger để **tự động kiểm tra và cập nhật dữ liệu** trong các nghiệp vụ quan trọng.

| Trigger | Vai trò xử lý |
|---|---|
| `trg_MuonSach_CapNhatTrangThai` | Kiểm tra sách trước khi cho mượn; nếu sách hợp lệ thì cập nhật `TrangThai = 'Đang mượn'` |
| `trg_TraSach_XuLyTuDong` | Khi sách được trả, cập nhật sách về **Sẵn sàng**, **tính tiền phạt**, **sinh phiếu phạt** và **đóng phiếu mượn nếu đã trả hết** |
| `trg_KiemTraDocGiaQuaHan` | **Chặn lập phiếu mượn mới** nếu độc giả còn sách quá hạn **hoặc đã mượn đủ 5 cuốn** |
| `trg_XoaPhieuMuon_HoanTonKho` | Khi xóa phiếu mượn, **hoàn lại các cuốn sách đang mượn về trạng thái Sẵn sàng** |

> Nhờ trigger, hệ thống **giảm bớt xử lý thủ công ở tầng ứng dụng** và đảm bảo **dữ liệu giữa các bảng luôn đồng bộ**.

#### 8.6.3 Xử lý bằng rollback

Rollback được sử dụng khi **một thao tác trong giao tác xảy ra lỗi**. Khi rollback, **toàn bộ thay đổi chưa commit sẽ bị hủy**.

**Ví dụ trong nghiệp vụ mượn sách:**
1. Hệ thống tạo phiếu mượn.
2. Hệ thống thêm cuốn `C001` vào chi tiết phiếu mượn.
3. Khi thêm cuốn `C002`, **trigger phát hiện sách không còn sẵn sàng**.
4. Hệ thống **báo lỗi**.
5. **Transaction rollback toàn bộ.**

> **Kết quả:** phiếu mượn **không được tạo**, chi tiết phiếu mượn **không được lưu**, trạng thái sách **không bị cập nhật sai**. → “Rollback giúp đảm bảo dữ liệu **không bị rơi vào trạng thái nửa đúng nửa sai**.”

#### 8.6.4 Kiểm tra trạng thái sách trước khi cho mượn

Trong hệ thống hiện tại, **một cuốn sách chỉ được cho mượn khi thỏa mãn đồng thời**:

> **`TrangThai = 'Sẵn sàng'` VÀ `TinhTrang = 'Bình Thường'`**

Nếu một trong hai điều kiện **không thỏa mãn**, trigger `trg_MuonSach_CapNhatTrangThai` sẽ **báo lỗi và không cho thêm sách vào chi tiết phiếu mượn**.

Điều này giúp hệ thống tránh các lỗi như:
- Cho mượn **sách đang được mượn**
- Cho mượn **sách bị hư hỏng**
- Cho mượn **sách không còn khả dụng**
- **Một cuốn sách xuất hiện trong nhiều phiếu mượn cùng lúc**

#### 8.6.5 Kiểm tra điều kiện độc giả trước khi lập phiếu mượn

Trước khi tạo phiếu mượn mới, trigger `trg_KiemTraDocGiaQuaHan` kiểm tra:
- Độc giả **có phiếu mượn quá hạn chưa trả** hay không
- Độc giả **đã mượn đủ 5 cuốn sách** hay chưa

Nếu độc giả **vi phạm một trong hai điều kiện** trên, hệ thống **sẽ không cho phép lập phiếu mượn mới**. Điều này đảm bảo **quy định mượn sách của thư viện được thực hiện đúng** và tránh trường hợp độc giả **mượn quá số lượng cho phép** hoặc **còn sách quá hạn nhưng vẫn tiếp tục mượn thêm**.

#### 8.6.6 Cập nhật tự động khi trả sách

Khi một dòng trong `CT_PHIEUMUON` được cập nhật sang trạng thái **Đã trả**, trigger `trg_TraSach_XuLyTuDong` sẽ **tự động xử lý**:
- Cập nhật `CUONSACH.TrangThai = 'Sẵn sàng'`
- **Tính tiền phạt nếu trả trễ**
- **Tạo phiếu phạt nếu phát sinh tiền phạt**
- Kiểm tra **nếu tất cả sách trong phiếu đã trả** thì cập nhật
- `PHIEUMUON.TrangThaiTongThe = 'Hoàn tất'`

> Nhờ đó, **trạng thái sách, trạng thái phiếu mượn và phiếu phạt được cập nhật đồng bộ** sau thao tác trả sách.

---

## 9. Giao diện hệ thống

*(Trang 58–75 — in là 53–70)*

### 9.1 Link chạy hệ thống & tài khoản demo (tr.58, in tr.53)

- **Link web chạy hệ thống:** <https://full-stack-project-library-manageme-amber.vercel.app/>
- Hệ thống gồm **2 tài khoản chính: Quản trị viên (Admin)** và **Nhân viên**.

| Vai trò | Quyền | Tên tài khoản | Password |
|---|---|---|---|
| **Quản trị viên** | Quản lý nhân viên và thư viện | `NV04` | `123456` |
| **Nhân viên** | Quản lý thư viện | `NV01` | `123456` |

> ⚠️ **Cảnh báo bảo mật:** đây là **thông tin đăng nhập thật của bản demo công khai trên Internet**, in trong báo cáo. Không tái sử dụng mật khẩu này cho bất kỳ hệ thống thật nào. Ngoài ra tài khoản admin có mã `NV04` — tức **admin cũng nằm trong bảng `NHANVIEN`**, khớp với thiết kế §4.1 (`/auth/login` nhận `MaNV`).

### 9.2 Giao diện Quản trị viên (5.1) — 29 màn hình

Mỗi mục dưới đây tương ứng **một hình ảnh nhúng** trong PDF (Hình 3–32). Bản trích xuất văn bản giữ được **tiêu đề** của từng hình; nội dung hình ảnh không trích xuất được.

| # | Mục | Tiêu đề màn hình | Hình | Trang PDF |
|---|---|---|---|---|
| 5.1.1 | Đăng nhập | Giao diện đăng nhập | Hình 3 | 59 |
| 5.1.2 | Dashboard | Dashboard | Hình 4 | 60 |
| 5.1.3 | Quản lý kho sách | Quản lý kho sách – **Đầu sách** | Hình 5 | 60 |
| 5.1.4 | Tìm kiếm | Tìm kiếm theo **tên sách** | Hình 6 | 61 |
| 5.1.5 | Tìm kiếm | Tìm kiếm theo **tên tác giả** | Hình 7 | 61 |
| 5.1.6 | Tìm kiếm | Tìm kiếm theo **thể loại** | Hình 8 | 62 |
| 5.1.7 | Kho sách | **Thêm đầu sách mới** | Hình 9 | 62 |
| 5.1.8 | Quản lý kho sách | Quản lý kho sách – **Thể loại** | Hình 10 | 63 |
| 5.1.9 | Thể loại | **Sửa** thể loại sách | Hình 11 | 63 |
| 5.1.10 | Thể loại | **Xóa** thể loại sách | Hình 12 | 64 |
| 5.1.11 | Thể loại | **Thêm** thể loại sách mới | Hình 13 | 64 |
| 5.1.12 | Độc giả | Quản lý độc giả | Hình 14 | 65 |
| 5.1.13 | Độc giả | Tìm kiếm theo **tên độc giả** | Hình 15 | 65 |
| 5.1.14 | Độc giả | Tìm kiếm độc giả theo **số điện thoại** | Hình 16 | 66 |
| 5.1.15 | Độc giả | **Cập nhật/Sửa** thông tin độc giả | Hình 17 | 66 |
| 5.1.16 | Độc giả | **Khóa thẻ** độc giả | Hình 18 | 67 |
| 5.1.17 | Độc giả | **Thêm** độc giả | Hình 19 | 67 |
| 5.1.18 | Mượn/trả | Quản lý **mượn và trả sách** | Hình 20 | 68 |
| 5.1.19 | Phiếu mượn | **Tìm kiếm** phiếu mượn | Hình 21 | 68 |
| 5.1.20 | Phiếu mượn | **Lọc mã phiếu theo ngày** | Hình 22 | 69 |
| 5.1.21 | Phiếu mượn | **Tạo phiếu mượn mới** | Hình 23 | 69 |
| 5.1.22 | Phiếu phạt | Quản lý **phiếu phạt** | Hình 24 | 70 |
| 5.1.23 | Phiếu phạt | Tìm kiếm phiếu phạt theo **mã độc giả** | Hình 25 | 70 |
| 5.1.24 | Phiếu phạt | **Thanh toán** phiếu phạt | Hình 26 | 71 |
| 5.1.25 | Báo cáo | Giao diện **báo cáo và thống kê** | Hình 27 | 71 |
| 5.1.25 | Báo cáo | **Tổng thể** báo cáo và thống kê | Hình 28 | 72 |
| 5.1.26 | Nhân viên | Quản lý nhân viên | Hình 29 | 73 |
| 5.1.27 | Nhân viên | **Cập nhật/Sửa** thông tin nhân viên | Hình 30 | 73 |
| 5.1.28 | Nhân viên | **Xóa** nhân viên | Hình 31 | 74 |
| 5.1.29 | Nhân viên | **Thêm** nhân viên | Hình 32 | 74 |

### 9.3 Giao diện Nhân viên (5.2)

**Nguyên văn:** “Các giao diện của nhân viên **cũng giống như quản trị viên** (vì **những gì nhân viên làm được thì quản trị viên cũng làm được**). Ngoại trừ việc **nhân viên không thể tự quản lý nhân viên** nên trong giao diện của nhân viên **sẽ không có phần chức năng quản lý nhân viên** giống như quản trị viên.” — **Hình 33: Giao diện nhân viên** (trang 75).

> Suy ra quan hệ quyền: **Admin ⊃ Nhân viên** (admin có mọi quyền của nhân viên, cộng thêm quyền quản lý nhân viên). Điều này khớp với §4.2: “Chỉ Admin mới có quyền truy cập module `/staffs`”.

### 9.4 Tổng kết chức năng trên giao diện — Bảng 46 (tr.75, in tr.70)

| Chức năng | Quản trị viên | Nhân viên (Thủ thư) |
|---|---|---|
| Xem dashboard | **Có** | **Có** |
| Quản lý sách | **Có** | **Có** |
| Quản lý thể loại | **Có** | **Có** |
| Quản lý độc giả | **Có** | **Có** |
| Quản lý mượn trả | **Có** | **Có** |
| Quản lý tiền phạt | **Có** | **Có** |
| Thống kê và báo cáo | **Có** | **Có** |
| Quản lý nhân viên | **Có** | **Không** |

---

## 10. Điểm bất nhất / lỗi trong chính báo cáo

Ghi lại trung thực để người đọc sau không bị nhầm. **Không sửa** trong bản trích xuất; chỉ nêu ở đây.

### 10.1 Use Case “Quản lý thể loại” bị sao chép nhầm (tr.14–15)
Bảng 4 mang tiêu đề “Use Case Quản lý thể loại” nhưng nội dung là **bản sao nguyên xi của Use Case Đăng nhập**, kể cả ô “Tên Use Case” cũng ghi *Đăng nhập*. → **Thiếu hoàn toàn đặc tả Use Case Quản lý thể loại** trong báo cáo.

### 10.2 Số lượng bảng đặc tả Use Case không khớp danh sách
Phần mục lục (§2.1.4) ghi đặc tả Use Case trải từ **trang 14 đến 21**; danh mục Bảng liệt kê **Bảng 3→15 = 13 bảng**; nhưng danh sách Use Case (Bảng 2) cũng có **13 Use Case**. Khớp về số lượng, nhưng vì §10.1 nên **thực chất chỉ có 12 đặc tả đúng nội dung**.

### 10.3 Procedure không nhất quán quy ước đặt tên
Trong Bảng 38 tồn tại **đồng thời hai quy ước**: CamelCase không tiền tố (`ThemTheLoai`, `NhapKhoCuonSach`, `ThucHienTraSach`, `GiaHanSach`) và có tiền tố `sp_` (`sp_TimKiemDocGia`, `sp_TraCuuPhieuMuon`, `sp_ThanhToanTienPhat`). Ngoài ra dòng “`ThemDocGia`, `CapNhatDocGia`, `TimDocGia`, `sp_TimKiemDocGia`” gộp **hai procedure tìm kiếm độc giả song song** (`TimDocGia` và `sp_TimKiemDocGia`) mà không giải thích khác biệt. Trigger cũng dùng tiền tố `trg_`.

### 10.4 Procedure dùng trong API nhưng thiếu trong Bảng 38
- `KhoaTheDocGia` (§4.3, dùng ở `DELETE /readers/:id`) **không có** trong Bảng 38.
- `sp_ThongKePhieuQuaHan_TheoThoiGian` (§4.8, dùng ở `GET /reports/overdue-tickets`) **không có** trong Bảng 38.

### 10.5 API `/fines` thiếu endpoint tạo phiếu phạt
Use Case 12 (Quản lý phiếu phạt) yêu cầu **lập phiếu phạt mới**, nhưng Bảng 22 chỉ có `GET /fines` và `PATCH /fines/:id/pay` — **thiếu `POST /fines`**. (Trên thực tế phiếu phạt được sinh tự động bởi `trg_TraSach_XuLyTuDong`, nhưng báo cáo không nói rõ điều này ở phần API.)

### 10.6 Mơ hồ giữa `TinhTrang` và `TrangThai` của `CUONSACH`
- Bảng 26 (§5.3.3) chỉ định nghĩa **một** thuộc tính trạng thái là `TinhTrang`; câu giải thích gán cho nó giá trị **“Sẵn sàng” / “Đang mượn”**.
- Bảng 35 (§5.4.3c) cũng ghi `CUONSACH.TinhTrang` ⊃ “Sẵn sàng / Đang mượn”.
- **Nhưng** §8.6.4 khẳng định điều kiện cho mượn là `TrangThai = 'Sẵn sàng'` **VÀ** `TinhTrang = 'Bình Thường'`.
- Trigger `trg_MuonSach_CapNhatTrangThai` (§6.4) cũng kiểm tra **cả hai**: `TrangThai` = “Sẵn sàng” và `TinhTrang` = “Bình Thường”.
- Và câu SQL mẫu ở §8.4 lại `INSERT INTO CuonSach(MaCuonSach, MaDauSach, TrangThai, TinhTrang) VALUES ('C015','DS01','Sẵn sàng','Bình Thường')` — tức **có cả hai cột**.

→ **Kết luận:** `CUONSACH` thực tế có **hai cột**: `TrangThai` ∈ {Sẵn sàng, Đang mượn} và `TinhTrang` ∈ {Bình Thường, hư hỏng…}. Bảng 26 và Bảng 35 trong báo cáo **thiếu cột `TrangThai` và mô tả sai `TinhTrang`**. Đây là **lỗi tài liệu**, không phải lỗi thiết kế.

### 10.7 Tiền phạt chưa có đơn giá / công thức cụ thể
`fn_TinhTienPhat` được mô tả là “tính tiền phạt dựa trên số ngày trả trễ (dựa vào ngày trả dự kiến và ngày trả thực tế)”, và `PHIEUPHAT.SoTien` là số tiền phạt. Nhưng báo cáo **không nêu đơn giá mỗi ngày trễ** hay công thức quy đổi. Cũng **không nêu** mức phạt cho **mất sách / hư hỏng sách** dù `LyDo` và phần mô tả PHIEUPHAT có nhắc tới các trường hợp này.

### 10.8 Bảng 44 (lịch giao tác khắc phục deadlock) bị vỡ cột
Bảng 44 (tr.55) có **13 dòng dữ liệu** nhưng nội dung bị dồn/lệch cột rõ rệt: dòng cuối nhắc lại “Lập phiếu mượn C002 / Lập phiếu mượn C001 / Commit…” trong khi phần trên đã kết thúc ở “rollback T2”. Cách đọc hợp lý: bảng là **hai lịch giao tác ghép liền nhau** (lịch gây deadlock, rồi lịch khắc phục), bị Word nối bảng không ngắt. Bản trích xuất giữ nguyên thứ tự dòng.

### 10.9 Số liệu “15 cuốn” trong ví dụ Phantom
Bảng 42 (tr.46) ghi `NV01` **“Thống kê 15 cuốn sách thuộc thể loại TL01”**, nhưng ngay dòng dưới và phần kết quả đều dùng con số **5 → 6**. Chữ “15” là **lỗi đánh máy** (hoặc tàn dư của bản nháp). Ngoài ra bảng 42 nói `NV02` thêm cuốn **`C006`**, còn SQL mẫu lại `INSERT ... VALUES ('C015', 'DS01', ...)` — **hai mã cuốn khác nhau cho cùng một sự kiện**.

### 10.10 Những gì bản trích xuất này không chứa được
- **Hình 1 (Sơ đồ Use Case tổng quát)**, **Hình 2 (Mô hình ERD)**, và **Hình 3–33** (31 ảnh giao diện) là **hình ảnh nhúng**, không có lớp văn bản → **không thể trích xuất thành chữ**. Toàn bộ *tiêu đề* và *vị trí trang* của chúng đã được ghi lại đầy đủ ở §3.1, §5.2 và §9.2 để có thể tra cứu ngược về PDF.
- Không có **script SQL/DDL đầy đủ** trong báo cáo: chỉ có các **đoạn SQL minh họa lỗi** ở chương 4 (§8) và mô tả bằng lời. Báo cáo **không in** phần `CREATE TABLE`, `CREATE VIEW`, `CREATE PROCEDURE`, `CREATE TRIGGER` hoàn chỉnh.
- Trang 5 (“Nhận xét của giảng viên”) chỉ có dòng chấm, **không có nội dung**.

### 10.11 Đề tài trong PDF khác đề tài của repo này
Báo cáo này là **“Hệ thống quản lý thư viện”**, trong khi thư mục làm việc hiện tại (`student-course-registration-management`) là **“Hệ thống quản lý đăng ký học phần”** — một đề tài khác (xem `docs/README.md` của repo: các module `dangky_hocphan`, `diem_ketqua`, `hocphi_taikhoan`…). **Hai bộ tài liệu KHÔNG liên quan nội dung với nhau.** Nếu mục đích là áp dụng tri thức này cho repo hiện tại thì cần chuyển thể: ánh xạ tương ứng gần đúng là `DAUSACH/CUONSACH` ↔ `học phần/lớp học phần`, `PHIEUMUON/CT_PHIEUMUON` ↔ `đăng ký học phần`, `PHIEUPHAT` ↔ `học phí công nợ`. **Không tự động trộn hai bộ tài liệu này lại.**

### 10.12 Lỗi chính tả/đánh máy đáng chú ý
| Nơi | PDF ghi | Đúng |
|---|---|---|
| Trang bìa, tiêu đề | HỆ QUẢN TRỊ CƠ **SƠ** DỮ LIỆU | CƠ **SỞ** DỮ LIỆU |
| Trang bìa | TRƯỜNG ĐẠI HỌC GIAO THÔNG **VẠI** TẢI | GIAO THÔNG **VẬN** TẢI |
| Lời cảm ơn | “cảm ơn **quý báo** của Thầy” | quý **báu** |
| Bảng phân công | “Soạn nội dung về chức năng hệ thống (view, **proceduce**)” | **procedure** |
| §2.1.3 | “danh sách thủ thư” / “ki ếm sách” / “mư ợn” | lỗi khoảng trắng do ngắt dòng của Word |
| §8.4 | “**seriablizable**” | **serializable** |
| Trang bìa | “Nguyễn Lê Huy Tâm” và “Phạm Bá Trí Tâm” **cùng họ Tâm**, dễ nhầm | — |

> Nhiều lỗi khoảng trắng giữa chữ và dấu (kiểu “đư ợc”, “nghi ệp”) là **do Word tách dấu tiếng Việt khi ngắt dòng**, không phải lỗi chính tả của tác giả.

---

## 11. Kết luận và hướng phát triển

*(Trang 76–77 — in là 71–72)*

### 11.1 Kết luận (6 đoạn, tóm nguyên văn)

1. **Mục đích:** Hệ thống quản lý thư viện được xây dựng nhằm hỗ trợ thư viện quản lý hiệu quả các nghiệp vụ cơ bản: quản lý thể loại, quản lý sách, quản lý độc giả, quản lý nhân viên, lập phiếu mượn, xử lý trả sách, quản lý phiếu phạt, tìm kiếm, tra cứu và thống kê. Thay vì quản lý thủ công, hệ thống giúp **lưu trữ dữ liệu tập trung, giảm sai sót trong quá trình xử lý** và **hỗ trợ nhân viên thao tác nhanh chóng hơn**.
2. **Chức năng:** chia thành các nhóm chính gồm **quản lý danh mục, quản lý người dùng, nghiệp vụ mượn–trả sách, hỗ trợ tra cứu & thống kê**. **Thủ thư** là người trực tiếp thực hiện nghiệp vụ hằng ngày (quản lý sách, độc giả, lập phiếu mượn, nhận trả sách). **Quản lý** có quyền **theo dõi thống kê, quản lý nhân viên và giám sát hoạt động chung**.
3. **Cơ sở dữ liệu:** thiết kế theo mô hình quan hệ với các bảng chính `THELOAI`, `DAUSACH`, `CUONSACH`, `DOCGIA`, `NHANVIEN`, `PHIEUMUON`, `CT_PHIEUMUON`, `PHIEUPHAT`. Các bảng liên kết qua khóa chính/khóa ngoại, đảm bảo **tính toàn vẹn dữ liệu**. Đặc biệt, **việc tách `DAUSACH` và `CUONSACH`** giúp hệ thống **quản lý rõ ràng giữa thông tin đầu sách và từng cuốn sách vật lý**.
4. **View/Function/Procedure/Trigger:** View giúp **tra cứu và thống kê nhanh hơn**. Function hỗ trợ **tính toán** như đếm số sách đang mượn hoặc tính tiền phạt. Procedure giúp **gom các thao tác nghiệp vụ phức tạp thành một quy trình xử lý rõ ràng**. Trigger giúp **tự động kiểm tra điều kiện mượn sách, cập nhật trạng thái sách, sinh phiếu phạt khi trả trễ và hoàn tất phiếu mượn khi độc giả đã trả đủ sách**.
5. **An toàn dữ liệu:** hệ thống chú trọng đảm bảo an toàn dữ liệu thông qua **giao tác và các tính chất ACID**. Các nghiệp vụ quan trọng như mượn sách, trả sách, thanh toán phiếu phạt cần được **xử lý theo transaction** để đảm bảo **hoặc toàn bộ thao tác thành công, hoặc khi có lỗi thì rollback toàn bộ**. Nhờ đó **dữ liệu không bị rơi vào trạng thái nửa đúng nửa sai**.
6. **Lỗi và xung đột:** báo cáo đã phân tích các trường hợp lỗi/xung đột có thể xảy ra trong **môi trường nhiều người dùng**: **Lost Update, Dirty Read, Non-repeatable Read, Phantom và Deadlock**. Đây là các vấn đề quan trọng trong hệ thống CSDL khi nhiều nhân viên cùng thao tác đồng thời. Việc sử dụng **transaction, trigger, kiểm tra trạng thái, khóa dữ liệu và rollback** giúp hệ thống **hạn chế sai lệch dữ liệu**, đảm bảo **trạng thái sách, phiếu mượn và phiếu phạt luôn chính xác**.
7. **Giao diện (tr.72):** hướng đến **sự đơn giản, dễ sử dụng** và phù hợp với **quy trình làm việc của thư viện**. Các chức năng được **tổ chức theo từng nhóm nghiệp vụ**, giúp thủ thư và quản lý dễ dàng thao tác, tìm kiếm thông tin và theo dõi tình hình hoạt động của thư viện.

### 11.2 Tự đánh giá chung (nguyên văn tr.72)
> “Tóm lại, hệ thống quản lý thư viện **đã đáp ứng được các yêu cầu cơ bản** về quản lý dữ liệu, xử lý nghiệp vụ và đảm bảo tính nhất quán của cơ sở dữ liệu. Hệ thống không chỉ hỗ trợ thư viện trong việc quản lý sách và độc giả mà còn giúp kiểm soát quá trình mượn–trả, xử lý phiếu phạt và thống kê thông tin một cách hiệu quả.”

### 11.3 Hướng phát triển tương lai (nguyên văn tr.72)
Hệ thống **có thể tiếp tục được mở rộng** thêm các chức năng:
- **Phân quyền chi tiết hơn**
- **Gửi thông báo nhắc trả sách**
- **Quản lý đặt trước sách**
- **Xuất báo cáo tự động**

…để **nâng cao hiệu quả sử dụng**.

---

## 12. Phụ lục và tài liệu tham khảo

### 12.1 Danh mục hình ảnh (trang 12–13 — in là 7–8) — 33 hình

| Hình | Tên | Trang in |
|---|---|---|
| 1 | Sơ đồ Use Case tổng quát | 12 |
| 2 | Mô hình ERD | 27 |
| 3 | Giao diện đăng nhập | 54 |
| 4 | Dashboard | 55 |
| 5 | Quản lý kho sách – Đầu sách | 55 |
| 6 | Tìm kiếm theo tên sách | 56 |
| 7 | Tìm kiếm theo tên tác giả | 56 |
| 8 | Tìm kiếm theo thể loại | 57 |
| 9 | Thêm đầu sách mới | 57 |
| 10 | Quản lý kho sách – Thể loại | 58 |
| 11 | Sửa thể loại sách | 58 |
| 12 | Xóa thể loại sách | 59 |
| 13 | Thêm thể loại sách mới | 59 |
| 14 | Quản lý độc giả | 60 |
| 15 | Tìm kiếm theo tên độc giả | 60 |
| 16 | Tìm kiếm theo độc giả theo số điện thoại | 61 |
| 17 | Cập nhật/Sửa thông tin độc giả | 61 |
| 18 | Khóa thẻ độc giả | 62 |
| 19 | Thêm độc giả | 62 |
| 20 | Quản lý mượn và trả sách | 63 |
| 21 | Tìm kiếm phiếu mượn | 63 |
| 22 | Lọc mã phiếu theo ngày | 64 |
| 23 | Tạo phiếu mượn mới | 64 |
| 24 | Quản lý phiếu phạt | 65 |
| 25 | Tìm kiếm phiếu phạt theo mã độc giả | 65 |
| 26 | Thanh toán phiếu phạt | 66 |
| 27 | Giao diện báo cáo và thống kê | 66 |
| 28 | Tổng thể báo cáo và thống kê | 67 |
| 29 | Quản lý nhân viên | 68 |
| 30 | Cập nhật/Sửa thông tin nhân viên | 68 |
| 31 | Xóa nhân viên | 69 |
| 32 | Thêm nhân viên | 69 |
| 33 | Giao diện nhân viên | 70 |

### 12.2 Danh mục bảng biểu (trang 14–15 — in là 9–10) — 46 bảng

| Bảng | Tên | Trang in |
|---|---|---|
| 1 | Các tác nhân của Use Case | 12 |
| 2 | Các Use Case chính | 13 |
| 3 | Use Case Đăng nhập | 14 |
| 4 | Use Case Quản lý thể loại | 14 |
| 5 | Use Case Quản lý sách | 15 |
| 6 | Use Case Quản lý độc giả | 16 |
| 7 | Use Case Quản lý nhân viên | 16 |
| 8 | Use Case Quản lý phiếu mượn | 17 |
| 9 | Use Case Quản lý chi tiết phiếu mượn | 17 |
| 10 | Use Case Quản lý mượn / trả sách | 18 |
| 11 | Use Case Tìm kiếm | 19 |
| 12 | Use Case Tra cứu | 19 |
| 13 | Use Case Thống kê | 20 |
| 14 | Use Case Quản lý phiếu phạt | 20 |
| 15 | Use Case Thanh toán phiếu phạt | 21 |
| 16 | Xác thực tài khoản | 22 |
| 17 | Quản lý nhân sự | 22 |
| 18 | Quản lý độc giả | 22 |
| 19 | Quản lý thể loại | 23 |
| 20 | Quản lý kho sách | 23 |
| 21 | Quản lý mượn và trả | 24 |
| 22 | Quản lý tiền phạt | 25 |
| 23 | Quản lý báo cáo và thống kê | 25 |
| 24 | Bảng THELOAI | 27 |
| 25 | Bảng DAUSACH | 28 |
| 26 | Bảng CUONSACH | 28 |
| 27 | Bảng DOCGIA | 29 |
| 28 | Bảng NHANVIEN | 29 |
| 29 | Bảng PHIEUMUON | 29 |
| 30 | Bảng CT_PHIEUMUON | 30 |
| 31 | Bảng PHIEUPHAT | 30 |
| 32 | Khóa chính của hệ thống | 32 |
| 33 | Khóa ngoại của hệ thống | 32 |
| 34 | Ràng buộc UNIQUE | 34 |
| 35 | Ràng buộc trạng thái nghiệp vụ | 35 |
| 36 | View | 35 |
| 37 | Function | 36 |
| 38 | Procedure | 36 |
| 39 | Trigger | 37 |
| 40 | Lịch giao tác (Lỗi đọc dữ liệu rác) | 44 |
| 41 | Lịch giao tác (Lỗi không đọc lại được dữ liệu) | 45 |
| 42 | Lịch giao tác (Lỗi bóng ma) | 46 |
| 43 | Lịch giao tác (Lỗi khóa chết) | 48 |
| 44 | Lịch giao tác (Khắc phục lỗi khóa chết) | 50 |
| 45 | Hệ thống xử lý bằng trigger | 51 |
| 46 | Các chức năng trên giao diện hệ thống | 70 |

### 12.3 Tài liệu tham khảo (trang 78 — in là 73)

| # | Nội dung |
|---|---|
| [1] | Link github đồ án của nhóm: <https://github.com/ThaiDevv/FullStack-Project-library-management.git> |
| [2] | Web chạy chương trình: <https://full-stack-project-library-manageme-amber.vercel.app/> |

> Báo cáo **chỉ có 2 tài liệu tham khảo, cả hai đều là sản phẩm của chính nhóm** — **không có** giáo trình, sách, bài báo hay tài liệu kỹ thuật nào được trích dẫn.

### 12.4 Bản đồ trang PDF → mục nội dung

Dùng để tra ngược nhanh về file PDF gốc.

| Trang PDF | Số trang in | Nội dung |
|---|---|---|
| 1 | — | Bìa |
| 2 | i | Đánh giá nhiệm vụ từng thành viên |
| 3 | ii | Lời cảm ơn |
| 4 | iii | Trang cam kết |
| 5 | iv | Nhận xét của giảng viên (trống) |
| 6–10 | 1–5 | Mục lục (tr.6–10 và tiếp ở tr.11–15) |
| 11 | 6 | Thuật ngữ viết tắt |
| 12–13 | 7–8 | Danh mục hình ảnh (33 hình) |
| 14–15 | 9–10 | Danh mục bảng biểu (46 bảng) |
| 16 | 11 | **1. Giới thiệu đề tài** |
| 17 | 12 | 2. Chức năng hệ thống · 2.1 Use Case · Hình 1 · Bảng 1 (tác nhân) |
| 18 | 13 | Bảng 2 — 13 Use Case chính |
| 19–26 | 14–21 | 2.1.4 Đặc tả 13 Use Case (Bảng 3–15) |
| 27 | 22 | 2.2 Xác thực · 2.3 Nhân sự · 2.4 Độc giả (Bảng 16–18) |
| 28 | 23 | 2.5 Thể loại · 2.6 Kho sách (Bảng 19–20) |
| 29 | 24 | 2.7 Mượn–Trả (Bảng 21) |
| 30 | 25 | 2.8 Tiền phạt · 2.9 Báo cáo (Bảng 22–23) |
| 31 | 26 | **3. Database** · 3.1 Thiết kế |
| 32 | 27 | 3.2 ERD (Hình 2) · 3.3.1 THELOAI (Bảng 24) |
| 33 | 28 | 3.3.2 DAUSACH · 3.3.3 CUONSACH (Bảng 25–26) |
| 34 | 29 | 3.3.4 DOCGIA · 3.3.5 NHANVIEN · 3.3.6 PHIEUMUON (Bảng 27–29) |
| 35 | 30 | 3.3.7 CT_PHIEUMUON · 3.3.8 PHIEUPHAT (Bảng 30–31) |
| 36 | 31 | 3.4 Khóa · 3.4.1 Khóa chính (Bảng 32) |
| 37 | 32 | Bảng 32 (tiếp) · 3.4.2 Khóa ngoại (Bảng 33) |
| 38 | 33 | Bảng 33 (tiếp) + giải thích khóa ngoại |
| 39 | 34 | 3.4.3 Ràng buộc: UNIQUE (Bảng 34) · toàn vẹn dữ liệu |
| 40 | 35 | Bảng 35 trạng thái · 3.5 View, Function, Procedure, Trigger · 3.5.1 View (Bảng 36) |
| 41 | 36 | 3.5.2 Function (Bảng 37) · 3.5.3 Procedure (Bảng 38) |
| 42 | 37 | Bảng 38 (tiếp) · phân tích procedure · 3.5.4 Trigger (Bảng 39) |
| 43 | 38 | Bảng 39 (tiếp) · diễn giải trigger · 3.6 ACID |
| 44 | 39 | 3.6.1 Atomicity · 3.6.2 Consistency |
| 45 | 40 | 3.6.2 (tiếp) · 3.6.3 Isolation |
| 46 | 41 | 3.6.3 (tiếp) · 3.6.4 Durability |
| 47 | 42 | **4. Các trường hợp lỗi...** · 4.1 Lost Update |
| 48 | 43 | 4.1.3–4.1.4 SQL + kết quả · 4.2 Dirty Read |
| 49 | 44 | Bảng 40 · 4.2.3–4.2.4 |
| 50 | 45 | 4.3 Non-repeatable Read · Bảng 41 · 4.3.3 |
| 51 | 46 | 4.3.4 · 4.4 Phantom · Bảng 42 |
| 52 | 47 | Bảng 42 (tiếp) · 4.4.3 SQL |
| 53 | 48 | 4.4.4 · 4.5 Deadlock · Bảng 43 |
| 54 | 49 | 4.5.3 SQL `FOR UPDATE` |
| 55 | 50 | Bảng 44 (khắc phục deadlock) |
| 56 | 51 | 4.5.4 kết quả · 4.6 transaction/trigger/rollback |
| 57 | 52 | Bảng 45 · 4.6.3 rollback · 4.6.4 kiểm tra trạng thái sách |
| 58 | 53 | 4.6.5–4.6.6 · **5. Giao diện** (link + tài khoản) |
| 59 | 54 | 5.1.1 Đăng nhập (Hình 3) |
| 60–74 | 55–69 | 5.1.2–5.1.29 (Hình 4–32) |
| 75 | 70 | 5.2 Nhân viên (Hình 33) · 5.3 Bảng 46 tổng kết chức năng |
| 76 | 71 | **6. Kết luận** |
| 77 | 72 | Kết luận (tiếp) |
| 78 | 73 | TÀI LIỆU THAM KHẢO |

---

## Phụ lục A — Trích xuất lại tri thức này

| Việc cần làm | Lệnh |
|---|---|
| Trích xuất lại toàn bộ PDF | `python docs\_tools\extract_pdf.py` |
| Xem text thô kèm mốc trang | [`pdf_transcript.md`](pdf_transcript.md) |
| Đọc dữ liệu có cấu trúc (metadata + từng trang) | [`../../_extract/pdf_pages.json`](../../_extract/pdf_pages.json) |
| Đếm/kiểm tra độ phủ | `pdf_pages.json` → `page_count: 78`, mọi trang có `chars > 0` |

Script dùng **`pypdf`** (cài bằng `python -m pip install pypdf`). Trên Windows, đặt `$env:PYTHONIOENCODING='utf-8'` trước khi chạy để tránh `UnicodeEncodeError` khi in tiếng Việt ra console.

**Kết quả kiểm chứng độ phủ:** 78/78 trang trích xuất thành công · 0 trang rỗng · 0 trang lỗi · tổng **89.511 ký tự** · 100% nội dung văn bản của PDF đã được đọc và phản ánh vào tài liệu này. Phần duy nhất không thể chuyển thành văn bản là **35 hình ảnh nhúng** (33 hình giao diện + Use Case + ERD), đã được lập danh mục đầy đủ ở §3.1, §5.2, §9.2 và §12.1 với số trang tra cứu.
