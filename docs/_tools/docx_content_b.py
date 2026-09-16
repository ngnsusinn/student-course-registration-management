# -*- coding: utf-8 -*-
"""Chương 3 — Database: thiết kế, ERD, 20 bảng, khóa, ràng buộc,
View/Function/Procedure/Trigger/Index, ACID."""

def bang(ten, mo_ta, rows, them=None):
    """rows: list [thuoc_tinh, y_nghia]"""
    out = [("p", mo_ta),
           ("tbl", "Bảng " + ten, ["Thuộc tính", "Ý nghĩa"], rows)]
    if them:
        out.append(("p", them))
    return out

CH3 = [
    ("h", 1, "3. Database"),
    ("p", "Cơ sở dữ liệu (Database) là thành phần quan trọng của hệ thống quản lý đăng ký học phần, "
          "dùng để lưu trữ toàn bộ thông tin về danh mục đào tạo (khoa, ngành, lớp sinh hoạt, môn "
          "học, tiên quyết, giảng viên, phòng học, học kỳ, chương trình đào tạo), hồ sơ sinh viên, "
          "lớp học phần, lịch học, đăng ký học phần, kết quả học tập, học phí, tài khoản và nhật ký "
          "vận hành. Việc thiết kế cơ sở dữ liệu hợp lý giúp hệ thống quản lý dữ liệu chính xác, hạn "
          "chế trùng lặp và đảm bảo các nghiệp vụ đăng ký — hủy đăng ký — nhập điểm — thu học phí "
          "được thực hiện nhất quán."),
    ("p", "Trong hệ thống này, cơ sở dữ liệu được thiết kế theo mô hình quan hệ, triển khai trên "
          "MySQL (InnoDB, utf8mb4) đặt ở máy chủ remote. Các bảng được liên kết với nhau thông qua "
          "khóa chính và khóa ngoại. Ngoài các bảng dữ liệu chính, hệ thống còn sử dụng View, "
          "Function, Procedure, Trigger và Index để hỗ trợ tra cứu, thống kê, tối ưu hiệu năng và tự "
          "động xử lý một số nghiệp vụ quan trọng."),
    ("h", 2, "3.1. Thiết kế cơ sở dữ liệu"),
    ("p", "Cơ sở dữ liệu của hệ thống gồm 18 bảng nghiệp vụ chia theo 5 module, cùng 2 bảng bổ trợ "
          "về vận hành tài khoản (nhật ký đổi mật khẩu, yêu cầu đặt lại mật khẩu), được xây dựng "
          "đúng theo dòng chảy nghiệp vụ của một học kỳ tín chỉ: danh mục & hồ sơ nền → mở lớp học "
          "phần → đăng ký → điểm số → học phí & tài khoản."),
    ("p", "Hệ thống tách thông tin giảng dạy thành hai mức: MÔN HỌC và LỚP HỌC PHẦN. Bảng MONHOC "
          "lưu thông tin chung của một môn học (tên, số tín chỉ, số tiết lý thuyết/thực hành, khoa "
          "phụ trách). Bảng LOPHOCPHAN lưu từng lớp học phần cụ thể được mở trong một học kỳ với "
          "giảng viên phụ trách, sĩ số tối đa và sĩ số hiện tại. Cách thiết kế này — tương tự như "
          "tách đầu sách khỏi cuốn sách vật lý — giúp hệ thống quản lý chính xác từng lớp phát sinh "
          "của cùng một môn học: một môn học mỗi kỳ có thể mở nhiều lớp, mỗi lớp có mã riêng, lịch "
          "riêng và trạng thái đăng ký riêng."),
    ("p", "Đối với nghiệp vụ đăng ký, quan hệ giữa sinh viên và lớp học phần là nhiều-nhiều: một "
          "sinh viên đăng ký nhiều lớp, một lớp có nhiều sinh viên. Hệ thống xử lý bằng bảng trung "
          "tâm DANGKYHOCPHAN với khóa chính ghép (MaSV, MaLHP) — vừa đảm bảo một sinh viên không "
          "thể đăng ký trùng một lớp, vừa là điểm neo cho các bảng phía sau: KETQUAHOCTAP tham chiếu "
          "khóa ngoại GHỐI (MaSV, MaLHP) để điểm chỉ tồn tại cho những đăng ký hợp lệ, còn HOCPHI "
          "tổng hợp theo (MaSV, MaHocKy)."),
    ("p", "Lịch học được tách khỏi lớp học phần thành bảng LICHHOC vì một lớp học phần có thể có "
          "nhiều buổi trong tuần (nhiều dòng lịch với phòng, thứ, tiết khác nhau); nhờ đó ràng buộc "
          "trùng lịch được phát hiện bằng cách so sánh giữa các lớp với nhau."),
    ("p", "Đối với nghiệp vụ xử lý vi phạm và vận hành, các ràng buộc như sĩ số, tín chỉ tối đa, "
          "đợt đăng ký… được đóng gói trong thủ tục lưu trữ và trigger — nơi duy nhất được phép thay "
          "đổi dữ liệu — để ứng dụng không thể ghi tắt. Bảng giữ vai trò công nợ tương tự phiếu phạt "
          "trong các hệ thống quản lý khác chính là HOCPHI, với trạng thái (CHUA_THANH_TOAN / "
          "QUA_HAN / DANG_XU_LY / DA_THANH_TOAN) kiểm soát bằng thủ tục có giao dịch."),
    ("p", "Khi thiết kế cơ sở dữ liệu bằng cách tách riêng thành nhiều bảng theo module như vậy, hệ "
          "thống dễ mở rộng, dễ bảo trì và đảm bảo tính toàn vẹn dữ liệu: mỗi quy trình nghiệp vụ đi "
          "qua đúng một số bảng xác định, và mọi bảng dùng chung đều có chủ sở hữu rõ ràng."),
    ("h", 2, "3.2. Mô hình ERD"),
    ("p", "Quan hệ tổng thể giữa các bảng:"),
    ("num", [
        "KHOA 1—n NGANH 1—n LOP_SINHHOAT 1—n SINHVIEN (mỗi sinh viên thuộc đúng một lớp sinh hoạt)",
        "NGANH n—m MONHOC thông qua bảng CHUONGTRINHDAOTAO (chương trình đào tạo: ngành – môn học – "
        "học kỳ dự kiến – bắt buộc/tự chọn)",
        "MONHOC n—m MONHOC (quan hệ tự tham chiếu tiên quyết) thông qua bảng MONHOC_TIENQUYET",
        "MONHOC 1—n LOPHOCPHAN; HOCKY 1—n LOPHOCPHAN; GIANGVIEN 1—n LOPHOCPHAN",
        "LOPHOCPHAN 1—n LICHHOC; PHONGHOC 1—n LICHHOC",
        "SINHVIEN n—m LOPHOCPHAN thông qua bảng trung tâm DANGKYHOCPHAN ⭐",
        "DANGKYHOCPHAN 1—0..1 KETQUAHOCTAP (điểm theo cặp SV–lớp) ; DANGKYHOCPHAN → HOCPHI (theo SV–kỳ)",
        "SINHVIEN / GIANGVIEN 1—0..1 TAIKHOAN n—1 VAITRO (ba vai trò SV / GV / PĐT)",
    ]),
    ("img", "Mô hình ERD tổng thể"),
    ("h", 2, "3.3. Danh sách bảng dữ liệu"),
    ("p", "Cơ sở dữ liệu của hệ thống gồm các bảng chính sau, trình bày theo 5 module."),

    # ---------- Module 1 ----------
    ("h", 3, "3.3.1. Bảng KHOA"),
    *bang("KHOA", "Bảng KHOA dùng để lưu thông tin các khoa trong trường, là cấp tổ chức cao nhất "
          "quản lý ngành đào tạo, môn học và giảng viên.", [
        ["MaKhoa", "Mã khoa, khóa chính"],
        ["TenKhoa", "Tên khoa, không được trùng"],
        ["DienThoaiKhoa", "Điện thoại liên hệ của khoa"],
        ["EmailKhoa", "Email khoa, không được trùng"],
    ]),
    ("h", 3, "3.3.2. Bảng NGANH"),
    *bang("NGANH", "Bảng NGANH lưu các ngành đào tạo thuộc một khoa.", [
        ["MaNganh", "Mã ngành, khóa chính"],
        ["TenNganh", "Tên ngành, không được trùng"],
        ["ThoiGianDaoTao", "Thời gian đào tạo (năm), phải lớn hơn 0"],
        ["MaKhoa", "Mã khoa, khóa ngoại tham chiếu đến KHOA"],
    ], "Ràng buộc FK_NGANH_KHOA với ON UPDATE CASCADE: đổi mã khoa sẽ tự cập nhật toàn bộ ngành "
        "con; ON DELETE NO ACTION: không thể xóa khoa còn ngành (và Trigger sẽ chặn xóa ngành còn "
        "sinh viên — xem mục Trigger)."),
    ("h", 3, "3.3.3. Bảng LOP_SINHHOAT"),
    *bang("LOP_SINHHOAT", "Bảng LOP_SINHHOAT lưu các lớp sinh hoạt (lớp hành chính) của một ngành "
          "theo khóa học.", [
        ["MaLopSH", "Mã lớp sinh hoạt, khóa chính"],
        ["TenLopSH", "Tên lớp sinh hoạt"],
        ["NienKhoa", "Niên khóa, giá trị hợp lệ trong khoảng 2000–2030"],
        ["MaNganh", "Mã ngành, khóa ngoại tham chiếu đến NGANH"],
    ]),
    ("h", 3, "3.3.4. Bảng SINHVIEN"),
    *bang("SINHVIEN", "Bảng SINHVIEN lưu hồ sơ sinh viên — thực thể trung tâm của nhóm bảng danh "
          "mục và là bảng được nhiều module tham chiếu nhất (đăng ký, điểm, học phí, tài khoản).", [
        ["MaSV", "Mã sinh viên, khóa chính"],
        ["HoTen", "Họ tên sinh viên"],
        ["NgaySinh", "Ngày sinh"],
        ["GioiTinh", "Giới tính: 1 — Nam, 0 — Nữ"],
        ["Email", "Email sinh viên, không được trùng"],
        ["SoDienThoai", "Số điện thoại"],
        ["QueQuan", "Quê quán"],
        ["TrangThaiHoc", "Trạng thái học tập: 1 — Đang học, 2 — Bảo lưu, 3 — Thôi học"],
        ["MaLopSH", "Mã lớp sinh hoạt, khóa ngoại tham chiếu đến LOP_SINHHOAT"],
    ], "Mỗi sinh viên thuộc đúng một lớp sinh hoạt; mỗi lớp thuộc đúng một ngành; mỗi ngành thuộc "
       "đúng một khoa — chuỗi tham chiếu này bảo đảm mọi thống kê theo khoa/đều tính đúng."),
    ("h", 3, "3.3.5. Bảng CHUONGTRINHDAOTAO"),
    *bang("CHUONGTRINHDAOTAO", "Bảng trung gian chương trình đào tạo, xác định một ngành học những "
          "môn học nào, dự kiến học kỳ nào, bắt buộc hay tự chọn. Đây là kết quả chuẩn hóa: nếu để "
          "danh sách môn nằm trong bảng NGANH sẽ vi phạm dạng chuẩn 1NF (lặp nhóm lặp cột).", [
        ["MaNganh", "Mã ngành, bộ phận khóa chính, khóa ngoại đến NGANH"],
        ["MaMonHoc", "Mã môn học, bộ phận khóa chính, khóa ngoại đến MONHOC"],
        ["HocKyDuKien", "Học kỳ dự kiến trong kế hoạch đào tạo, phải lớn hơn 0"],
        ["BatBuoc", "Cờ bắt buộc (1) hay tự chọn (0)"],
    ], "Khóa chính ghép (MaNganh, MaMonHoc): một môn chỉ xuất hiện một lần trong chương trình của "
       "một ngành."),

    # ---------- Module 2 ----------
    ("h", 3, "3.3.6. Bảng MONHOC"),
    *bang("MONHOC", "Bảng MONHOC lưu thông tin chung của mỗi môn học.", [
        ["MaMonHoc", "Mã môn học, khóa chính"],
        ["TenMonHoc", "Tên môn học"],
        ["SoTinChi", "Số tín chỉ, phải lớn hơn 0"],
        ["SoTietLyThuyet", "Số tiết lý thuyết"],
        ["SoTietThucHanh", "Số tiết thực hành"],
        ["MaKhoa", "Mã khoa phụ trách môn học, khóa ngoại đến KHOA"],
    ]),
    ("h", 3, "3.3.7. Bảng MONHOC_TIENQUYET"),
    *bang("MONHOC_TIENQUYET", "Quan hệ nhiều-nhiều TỰ THAM CHIẾU giữa các môn học: môn này là tiên "
          "quyết của môn kia. Đây cũng là bảng hiện thực hóa ràng buộc nghiệp vụ “sinh viên phải đạt "
          "môn tiên quyết mới được đăng ký môn sau”.", [
        ["MaMonHoc", "Mã môn học (môn sau), bộ phận khóa chính, khóa ngoại đến MONHOC"],
        ["MaMonTienQuyet", "Mã môn tiên quyết (môn trước), bộ phận khóa chính, khóa ngoại đến MONHOC"],
    ], "CHECK (MaMonHoc <> MaMonTienQuyet) chống một môn làm tiên quyết của chính nó. ON DELETE "
       "CASCADE: xóa môn học sẽ tự xóa các quan hệ tiên quyết liên quan."),
    ("h", 3, "3.3.8. Bảng GIANGVIEN"),
    *bang("GIANGVIEN", "Bảng GIANGVIEN lưu giảng viên phụ trách lớp học phần.", [
        ["MaGV", "Mã giảng viên, khóa chính"],
        ["HoTen", "Họ tên giảng viên"],
        ["Email", "Email giảng viên, không được trùng"],
        ["MaKhoa", "Mã khoa quản lý giảng viên, khóa ngoại đến KHOA"],
    ]),
    ("h", 3, "3.3.9. Bảng HOCKY"),
    *bang("HOCKY", "Bảng HOCKY lưu các học kỳ cùng ĐỢT ĐĂNG KÝ tương ứng (thời hạn đăng ký của sinh "
          "viên).", [
        ["MaHocKy", "Mã học kỳ, khóa chính"],
        ["TenHocKy", "Tên học kỳ"],
        ["NamHoc", "Năm học"],
        ["TuNgay", "Ngày bắt đầu đợt đăng ký"],
        ["DenNgay", "Ngày kết thúc đợt đăng ký"],
        ["TrangThaiDot", "Trạng thái đợt: MO hoặc DONG"],
    ], "Điều kiện đợt mở hợp lệ: TrangThaiDot = 'MO' VÀ NOW() BETWEEN TuNgay AND DenNgay — được kiểm "
       "tra bằng FN_KiemTraDotDangKy ngay trong thủ tục đăng ký (mã lỗi 100)."),
    ("h", 3, "3.3.10. Bảng PHONGHOC"),
    *bang("PHONGHOC", "Bảng PHONGHOC lưu danh mục phòng học phục vụ xếp lịch.", [
        ["MaPhong", "Mã phòng, khóa chính"],
        ["TenPhong", "Tên phòng"],
        ["SucChua", "Sức chứa, phải lớn hơn 0"],
    ]),
    ("h", 3, "3.3.11. Bảng LOPHOCPHAN"),
    *bang("LOPHOCPHAN", "Bảng LOPHOCPHAN lưu từng lớp học phần được mở trong một học kỳ — đối tượng "
          "mà sinh viên đăng ký.", [
        ["MaLHP", "Mã lớp học phần, khóa chính"],
        ["TenLHP", "Tên lớp học phần"],
        ["SiSoToiDa", "Sĩ số tối đa, phải lớn hơn 0"],
        ["SiSoHienTai", "Sĩ số hiện tại — Trigger tự cộng/trừ khi có đăng ký/hủy"],
        ["TrangThaiLop", "MO_DANG_KY / DONG_DANG_KY / DA_KET_THUC"],
        ["MaMonHoc", "Mã môn học, khóa ngoại đến MONHOC"],
        ["MaHocKy", "Mã học kỳ, khóa ngoại đến HOCKY"],
        ["MaGV", "Mã giảng viên phụ trách, khóa ngoại đến GIANGVIEN (được phép NULL khi chưa xếp GV)"],
    ], "CHECK SiSoHienTai <= SiSoToiDa bảo vệ bất biến sĩ số ở tầng khai báo; trên thực thi, giá trị "
       "này được bảo vệ bằng khóa dòng (SELECT … FOR UPDATE) trong thủ tục đăng ký để hai sinh viên "
       "không cùng giành một suất (Lost Update)."),
    ("h", 3, "3.3.12. Bảng LICHHOC"),
    *bang("LICHHOC", "Bảng LICHHOC lưu các buổi học của một lớp học phần (một lớp có thể có nhiều "
          "buổi trong tuần).", [
        ["MaLichHoc", "Mã lịch học, khóa chính"],
        ["MaLHP", "Mã lớp học phần, khóa ngoại đến LOPHOCPHAN, ON DELETE CASCADE"],
        ["MaPhong", "Mã phòng, khóa ngoại đến PHONGHOC"],
        ["Thu", "Thứ trong tuần (2–8: thứ Hai đến Chủ nhật)"],
        ["TietBatDau", "Tiết bắt đầu (1–15)"],
        ["SoTiet", "Số tiết liên tiếp (1–6)"],
    ], "Ràng buộc “phòng không trùng, giảng viên không trùng trong cùng khung giờ” không thể khai "
       "báo bằng CHECK (vì phải SO SÁNH GIỮA CÁC DÒNG khác nhau) nên được hiện thực bằng Function "
       "FN_KiemTraPhongTrong, Function FN_KiemTraTrungLichHoc và Trigger TRG_LICHHOC."),

    # ---------- Module 3 ----------
    ("h", 3, "3.3.13. Bảng DANGKYHOCPHAN ⭐ (bảng trung tâm)"),
    *bang("DANGKYHOCPHAN", "Bảng trung tâm của toàn hệ thống, ghi nhận việc một sinh viên đăng ký "
          "một lớp học phần.", [
        ["MaSV", "Mã sinh viên, bộ phận khóa chính, khóa ngoại đến SINHVIEN"],
        ["MaLHP", "Mã lớp học phần, bộ phận khóa chính, khóa ngoại đến LOPHOCPHAN"],
        ["NgayDangKy", "Thời điểm đăng ký, mặc định CURRENT_TIMESTAMP"],
        ["TrangThaiDangKy", "DA_DANG_KY / DA_HUY / CHO_XAC_NHAN"],
        ["GhiChu", "Ghi chú nghiệp vụ"],
    ], "Khóa chính ghép (MaSV, MaLHP) giúp một lớp không bị một sinh viên ghi trùng hai lượt; trạng "
       "thái DA_HUY được GIỮ LẠI (soft delete) để phục vụ tra cứu lịch sử và để bảng KETQUAHOCTAP giữ "
       "nguyên quan hệ tham chiếu. Trigger TRG_DANGKYHOCPHAN_AFTER_INSERT/UPDATE/DELETE tự động cộng "
       "trừ SiSoHienTai."),

    # ---------- Module 4 ----------
    ("h", 3, "3.3.14. Bảng THANGDIEMCHU"),
    *bang("THANGDIEMCHU", "Bảng tra cứu quy đổi điểm: khoảng điểm hệ 10 → chữ → hệ 4 → xếp loại.", [
        ["DiemChu", "Điểm chữ (A, B+, B…), khóa chính"],
        ["TuDiemHe10", "Cận dưới của khoảng điểm hệ 10"],
        ["DenDiemHe10", "Cận trên của khoảng điểm hệ 10 (phải lớn hơn cận dưới)"],
        ["DiemHe4", "Điểm tương ứng hệ 4 (0–4)"],
        ["XepLoai", "Mô tả xếp loại (Xuất sắc, Giỏi, Khá, Trung bình, Yếu…)"],
    ]),
    ("h", 3, "3.3.15. Bảng KETQUAHOCTAP"),
    *bang("KETQUAHOCTAP", "Bảng KETQUAHOCTAP lưu điểm của một sinh viên trong một lớp học phần mà "
          "sinh viên đó đã đăng ký.", [
        ["MaSV", "Mã sinh viên, bộ phận khóa chính"],
        ["MaLHP", "Mã lớp học phần, bộ phận khóa chính"],
        ["DiemChuyenCan", "Điểm chuyên cần (0–10)"],
        ["DiemGiuaKy", "Điểm giữa kỳ (0–10)"],
        ["DiemCuoiKy", "Điểm cuối kỳ (0–10)"],
        ["DiemTongKet", "Điểm tổng kết — DO TRIGGER tự tính: 10% CC + 30% GK + 60% CK"],
        ["DiemHe4", "Điểm hệ 4 — do Trigger quy đổi qua bảng THANGDIEMCHU"],
        ["DiemChu", "Điểm chữ — do Trigger quy đổi; là khóa ngoại đến THANGDIEMCHU"],
    ], "Khóa ngoại GHỐI (MaSV, MaLHP) tham chiếu thẳng xuống DANGKYHOCPHAN — nghĩa là không thể tồn "
       "tại bảng điểm của một sinh viên chưa từng đăng ký lớp đó. Đây là ví dụ điển hình của ràng "
       "buộc toàn vẹn tham chiếu nhiều cột."),

    # ---------- Module 5 ----------
    ("h", 3, "3.3.16. Bảng VAITRO"),
    *bang("VAITRO", "Bảng VAITRO định nghĩa ba vai trò sử dụng hệ thống.", [
        ["MaVaiTro", "Mã vai trò, khóa chính"],
        ["TenVaiTro", "Tên vai trò (Sinh viên / Giảng viên / Phòng Đào tạo), không được trùng"],
        ["MoTa", "Mô tả quyền hạn"],
    ]),
    ("h", 3, "3.3.17. Bảng TAIKHOAN"),
    *bang("TAIKHOAN", "Bảng TAIKHOAN lưu tài khoản đăng nhập; một tài khoản gắn với đúng một hồ sơ "
          "sử dụng (sinh viên HOẶC giảng viên, hoặc để trống nếu là cán bộ PĐT).", [
        ["MaTaiKhoan", "Mã tài khoản, khóa chính"],
        ["TenDangNhap", "Tên đăng nhập, không được trùng"],
        ["MatKhau", "Mật khẩu lưu dạng băm SHA-256 (không bao giờ lưu plaintext)"],
        ["Email", "Email liên hệ"],
        ["TrangThai", "ACTIVE hoặc LOCKED — tài khoản khóa không thể đăng nhập"],
        ["MaVaiTro", "Mã vai trò, khóa ngoại đến VAITRO"],
        ["MaSV", "Mã sinh viên, khóa ngoại đến SINHVIEN (NULL nếu không phải SV)"],
        ["MaGV", "Mã giảng viên, khóa ngoại đến GIANGVIEN (NULL nếu không phải GV)"],
    ], "CHECK (MaSV, MaGV không đồng thời có giá trị) bảo đảm một tài khoản chỉ thuộc về một hồ sơ."),
    ("h", 3, "3.3.18. Bảng HOCPHI"),
    *bang("HOCPHI", "Bảng HOCPHI lưu hóa đơn học phí của một sinh viên trong một học kỳ.", [
        ["MaHocPhi", "Mã học phí, khóa chính"],
        ["MaSV", "Mã sinh viên, khóa ngoại đến SINHVIEN"],
        ["MaHocKy", "Mã học kỳ, khóa ngoại đến HOCKY"],
        ["SoTinChi", "Tổng số tín chỉ đã đăng ký trong kỳ (> 0)"],
        ["DonGiaTinChi", "Đơn giá mỗi tín chỉ (> 0)"],
        ["TongTien", "Tổng học phí = SoTinChi × DonGiaTinChi"],
        ["DaNop", "Đã nộp, bắt buộc không vượt quá TongTien"],
        ["TrangThai", "CHUA_THANH_TOAN / DANG_XU_LY / DA_THANH_TOAN / QUA_HAN"],
    ], "UNIQUE (MaSV, MaHocKy): mỗi sinh viên chỉ có MỘT hóa đơn học phí duy nhất cho mỗi học kỳ — "
       "ràng buộc nghiệp vụ tương đương “một phiếu mượn chỉ có tối đa một phiếu phạt”."),
    ("h", 3, "3.3.19. Bảng NHATKY_DOIMATKHAU (bổ trợ)"),
    *bang("NHATKY_DOIMATKHAU", "Bảng nhật ký ghi nhận MỖI LẦN đổi mật khẩu, do Trigger "
          "TRG_LogDoiMatKhau trên bảng TAIKHOAN tự động ghi — phục vụ truy vết an toàn.", [
        ["MaNhatKy", "Mã nhật ký, khóa chính, tự tăng"],
        ["MaTaiKhoan", "Mã tài khoản thay đổi mật khẩu, khóa ngoại đến TAIKHOAN"],
        ["TenDangNhap", "Tên đăng nhập (bản sao để đọc nhanh)"],
        ["ThoiGianThayDoi", "Thời điểm thay đổi"],
        ["DiaChiIP", "Địa chỉ IP phát sinh thao tác"],
        ["GhiChu", "Ghi chú"],
    ]),
    ("h", 3, "3.3.20. Bảng YEUCAU_DATLAI_MATKHAU (bổ trợ)"),
    *bang("YEUCAU_DATLAI_MATKHAU", "Bảng tiếp nhận yêu cầu “Quên mật khẩu?” từ màn hình đăng nhập; "
          "PĐT duyệt từng yêu cầu (đặt lại về mật khẩu mặc định hoặc từ chối).", [
        ["MaYeuCau", "Mã yêu cầu, khóa chính, tự tăng"],
        ["TenDangNhap", "Tên đăng nhập cần đặt lại, khóa ngoại đến TAIKHOAN"],
        ["Email", "Email khai báo để xác minh"],
        ["LyDo", "Lý do yêu cầu"],
        ["TrangThai", "CHO_XU_LY / DA_XU_LY / TU_CHOI"],
        ["NgayGui", "Thời điểm gửi yêu cầu"],
        ["NgayXuLy", "Thời điểm PĐT xử lý"],
        ["NguoiXuLy", "Mã tài khoản PĐT xử lý"],
        ["GhiChu", "Ghi chú"],
    ], "Toàn bộ dòng trạng thái chờ được đặt chỉ số (TrangThai, NgayGui) để màn hình duyệt yêu cầu "
       "luôn nhanh."),
    ("pb",),

    # ---------- 3.4 keys ----------
    ("h", 2, "3.4. Khóa chính, khóa ngoại và ràng buộc"),
    ("p", "Trong cơ sở dữ liệu của hệ thống, khóa chính, khóa ngoại và các ràng buộc CHECK/UNIQUE "
          "được sử dụng nhằm đảm bảo tính toàn vẹn và tính nhất quán dữ liệu, giúp tránh trùng mã, "
          "nhập dữ liệu tham chiếu không tồn tại, hoặc lưu trạng thái trái quy định."),
    ("h", 3, "3.4.1. Khóa chính"),
    ("p", "Mỗi bảng có một khóa chính; trong đó ba bảng dùng KHÓA CHÍNH GHÉP — đều là các bảng thể "
          "hiện quan hệ nhiều-nhiều hoặc quan hệ phụ thuộc ngữ cảnh: DANGKYHOCPHAN (MaSV, MaLHP), "
          "KETQUAHOCTAP (MaSV, MaLHP), MONHOC_TIENQUYET (MaMonHoc, MaMonTienQuyet) và "
          "CHUONGTRINHDAOTAO (MaNganh, MaMonHoc)."),
    ("tbl", "Khóa chính của hệ thống", ["Bảng", "Khóa chính", "Ý nghĩa"], [
        ["KHOA", "MaKhoa", "Định danh duy nhất mỗi khoa"],
        ["NGANH", "MaNganh", "Định danh duy nhất mỗi ngành"],
        ["LOP_SINHHOAT", "MaLopSH", "Định danh duy nhất mỗi lớp sinh hoạt"],
        ["SINHVIEN", "MaSV", "Định danh duy nhất mỗi sinh viên (MSSV)"],
        ["CHUONGTRINHDAOTAO", "MaNganh + MaMonHoc", "Khóa chính ghép: một môn chỉ xuất hiện một lần "
         "trong chương trình của một ngành"],
        ["MONHOC", "MaMonHoc", "Định danh duy nhất mỗi môn học"],
        ["MONHOC_TIENQUYET", "MaMonHoc + MaMonTienQuyet", "Khóa chính ghép của quan hệ tự tham chiếu "
         "tiên quyết"],
        ["GIANGVIEN", "MaGV", "Định danh duy nhất mỗi giảng viên"],
        ["HOCKY", "MaHocKy", "Định danh duy nhất mỗi học kỳ"],
        ["PHONGHOC", "MaPhong", "Định danh duy nhất mỗi phòng học"],
        ["LOPHOCPHAN", "MaLHP", "Định danh duy nhất mỗi lớp học phần"],
        ["LICHHOC", "MaLichHoc", "Định danh duy nhất mỗi buổi học"],
        ["DANGKYHOCPHAN ⭐", "MaSV + MaLHP", "Khóa chính ghép: một sinh viên không thể đăng ký trùng "
         "một lớp"],
        ["THANGDIEMCHU", "DiemChu", "Định danh mỗi khoảng điểm chữ"],
        ["KETQUAHOCTAP", "MaSV + MaLHP", "Khóa chính ghép: mỗi sinh viên có đúng một bảng điểm cho "
         "một lớp"],
        ["VAITRO", "MaVaiTro", "Định danh mỗi vai trò"],
        ["TAIKHOAN", "MaTaiKhoan", "Định danh mỗi tài khoản"],
        ["HOCPHI", "MaHocPhi", "Định danh mỗi hóa đơn học phí"],
        ["NHATKY_DOIMATKHAU", "MaNhatKy (AUTO_INCREMENT)", "Định danh mỗi dòng nhật ký"],
        ["YEUCAU_DATLAI_MATKHAU", "MaYeuCau (AUTO_INCREMENT)", "Định danh mỗi yêu cầu"],
    ]),
    ("h", 3, "3.4.2. Khóa ngoại"),
    ("tbl", "Khóa ngoại của hệ thống",
     ["Bảng chứa FK", "Khóa ngoại", "Tham chiếu đến", "Ý nghĩa / ON DELETE"], [
        ["NGANH", "MaKhoa", "KHOA.MaKhoa", "Mỗi ngành thuộc một khoa — NO ACTION"],
        ["LOP_SINHHOAT", "MaNganh", "NGANH.MaNganh", "Mỗi lớp thuộc một ngành — NO ACTION"],
        ["SINHVIEN", "MaLopSH", "LOP_SINHHOAT.MaLopSH", "Mỗi SV thuộc một lớp sinh hoạt — NO ACTION"],
        ["CHUONGTRINHDAOTAO", "MaNganh", "NGANH.MaNganh", "CTĐT theo ngành — NO ACTION"],
        ["CHUONGTRINHDAOTAO", "MaMonHoc", "MONHOC.MaMonHoc", "Môn của CTĐT — NO ACTION"],
        ["MONHOC", "MaKhoa", "KHOA.MaKhoa", "Khoa phụ trách môn — NO ACTION"],
        ["MONHOC_TIENQUYET", "MaMonHoc / MaMonTienQuyet", "MONHOC.MaMonHoc",
         "Cả hai phía đều CASCADE: xóa môn tự xóa quan hệ tiên quyết"],
        ["GIANGVIEN", "MaKhoa", "KHOA.MaKhoa", "Khoa quản lý GV — NO ACTION"],
        ["LOPHOCPHAN", "MaMonHoc", "MONHOC.MaMonHoc", "Lớp của môn nào — NO ACTION"],
        ["LOPHOCPHAN", "MaHocKy", "HOCKY.MaHocKy", "Lớp mở kỳ nào — NO ACTION"],
        ["LOPHOCPHAN", "MaGV", "GIANGVIEN.MaGV", "GV phụ trách (NULL được phép) — NO ACTION"],
        ["LICHHOC", "MaLHP", "LOPHOCPHAN.MaLHP", "Lịch của lớp — CASCADE (xóa lớp xóa lịch)"],
        ["LICHHOC", "MaPhong", "PHONGHOC.MaPhong", "Học phòng nào — NO ACTION"],
        ["DANGKYHOCPHAN ⭐", "MaSV", "SINHVIEN.MaSV", "Ai đăng ký — NO ACTION"],
        ["DANGKYHOCPHAN ⭐", "MaLHP", "LOPHOCPHAN.MaLHP", "Đăng ký lớp nào — NO ACTION"],
        ["KETQUAHOCTAP", "(MaSV, MaLHP) — FK GHỐI", "DANGKYHOCPHAN(MaSV, MaLHP)",
         "Điểm chỉ tồn tại nếu ĐÃ ĐĂNG KÝ lớp đó — CASCADE"],
        ["KETQUAHOCTAP", "DiemChu", "THANGDIEMCHU.DiemChu", "Điểm chữ hợp lệ theo thang — NO ACTION"],
        ["TAIKHOAN", "MaVaiTro", "VAITRO.MaVaiTro", "Phân quyền — NO ACTION"],
        ["TAIKHOAN", "MaSV", "SINHVIEN.MaSV", "Tài khoản thuộc SV nào (nullable) — NO ACTION"],
        ["TAIKHOAN", "MaGV", "GIANGVIEN.MaGV", "Tài khoản thuộc GV nào (nullable) — NO ACTION"],
        ["HOCPHI", "MaSV", "SINHVIEN.MaSV", "Hóa đơn của SV — NO ACTION"],
        ["HOCPHI", "MaHocKy", "HOCKY.MaHocKy", "Hóa đơn kỳ nào — NO ACTION"],
        ["NHATKY_DOIMATKHAU", "MaTaiKhoan", "TAIKHOAN.MaTaiKhoan", "Nhật ký theo tài khoản — CASCADE"],
        ["YEUCAU_DATLAI_MATKHAU", "TenDangNhap", "TAIKHOAN.TenDangNhap", "Yêu cầu theo tài khoản — "
         "CASCADE"],
    ]),
    ("p", "Điểm đặc biệt: KETQUAHOCTAP tham chiếu bằng KHÓA NGOẠI GHỐI xuống đúng khóa chính ghép "
          "của DANGKYHOCPHAN. Khóa ngoại thông thường (MaSV trỏ SINHVIEN, MaLHP trỏ LOPHOCPHAN) "
          "không thể hiện được ràng buộc này, vì điểm chỉ hợp lệ khi CẶP (SV, LỚP) THỰC SỰ ĐÃ ĐĂNG "
          "KÝ — một minh chứng cụ thể của toàn vẹn tham chiếu nhiều cột."),
    ("h", 3, "3.4.3. Ràng buộc"),
    ("p", "a. Ràng buộc UNIQUE"),
    ("tbl", "Ràng buộc UNIQUE", ["Bảng", "Thuộc tính", "Ý nghĩa"], [
        ["KHOA", "TenKhoa, EmailKhoa", "Không hai khoa trùng tên hoặc trùng email"],
        ["NGANH", "TenNganh", "Không hai ngành trùng tên"],
        ["SINHVIEN", "Email", "Mỗi email chỉ thuộc về một sinh viên"],
        ["GIANGVIEN", "Email", "Mỗi email chỉ thuộc về một giảng viên"],
        ["TAIKHOAN", "TenDangNhap", "Mỗi tên đăng nhập chỉ có một tài khoản — nền tảng cho luồng "
         "đăng nhập"],
        ["HOCPHI", "(MaSV, MaHocKy)", "Mỗi sinh viên chỉ có MỘT hóa đơn học phí mỗi học kỳ — tránh "
         "tạo trùng bill"],
    ]),
    ("p", "b. Ràng buộc kiểm tra dữ liệu (CHECK) — khai báo ngay trong DDL"),
    ("ul", [
        "Kiểu số đếm được: SoTinChi > 0; SiSoToiDa > 0; SucChua > 0; ThoiGianDaoTao > 0; "
        "HocKyDuKien > 0; DonGiaTinChi > 0; TongTien >= 0.",
        "Bất biến sĩ số: 0 <= SiSoHienTai <= SiSoToiDa (khóa dòng FOR UPDATE bảo vệ ở tầng thực thi).",
        "Miền giá trị: GioiTinh ∈ {0,1}; TrangThaiHoc ∈ {1,2,3}; Thu ∈ [2..8]; TietBatDau ∈ [1..15]; "
        "SoTiet ∈ [1..6]; TuNgay < DenNgay; điểm hệ 10 trong [0..10], điểm hệ 4 trong [0..4]; "
        "DaNop <= TongTien.",
        "Logic liên cột: MONHOC_TIENQUYET.MaMonHoc <> MaMonTienQuyet (không tự tiên quyết); "
        "TAIKHOAN không đồng thời mang cả MaSV và MaGV; THANGDIEMCHU.TuDiemHe10 < DenDiemHe10.",
        "Lưu ý triển khai: MySQL 5.7 chỉ PARSE còn MySQL 8.0.16+ mới ENFORCE ràng buộc CHECK, nên "
        "các ràng buộc quan trọng đều được kiểm tra LẠI bằng thủ tục/trigger trong CSDL.",
    ]),
    ("p", "c. Ràng buộc trạng thái nghiệp vụ"),
    ("tbl", "Ràng buộc trạng thái nghiệp vụ", ["Bảng", "Thuộc tính", "Dữ liệu phù hợp"], [
        ["HOCKY", "TrangThaiDot", "MO / DONG (đợt đăng ký mở hay đóng)"],
        ["LOPHOCPHAN", "TrangThaiLop", "MO_DANG_KY / DONG_DANG_KY / DA_KET_THUC"],
        ["DANGKYHOCPHAN", "TrangThaiDangKy", "DA_DANG_KY / DA_HUY / CHO_XAC_NHAN"],
        ["TAIKHOAN", "TrangThai", "ACTIVE / LOCKED"],
        ["HOCPHI", "TrangThai", "CHUA_THANH_TOAN / DANG_XU_LY / DA_THANH_TOAN / QUA_HAN"],
        ["YEUCAU_DATLAI_MATKHAU", "TrangThai", "CHO_XU_LY / DA_XU_LY / TU_CHOI"],
    ]),
    ("p", "Các ràng buộc toàn vẹn dữ liệu suy ra: Không thể thêm sinh viên nếu lớp sinh hoạt không "
          "tồn tại; không thể mở lớp học phần nếu môn học, học kỳ (hoặc giảng viên khi đã gán) không "
          "tồn tại; không thể đăng ký nếu sinh viên hoặc lớp học phần không tồn tại; không thể có "
          "bảng điểm nếu chưa đăng ký lớp đó (FK ghép); không thể có hóa đơn học phí nếu sinh viên/"
          "học kỳ không tồn tại; không thể có hai hóa đơn của cùng một sinh viên trong một học kỳ; "
          "không thể xóa ngành khi còn sinh viên (Trigger); không thể lưu lịch học gây trùng phòng/"
          "trùng giảng viên (Trigger)."),
    ("pb",),

    # ---------- 3.5 ----------
    ("h", 2, "3.5. View, Function, Procedure, Trigger, Index"),
    ("h", 3, "3.5.1. View"),
    ("p", "View được sử dụng để tạo các bảng ảo phục vụ tra cứu, thống kê và hiển thị dữ liệu; ứng "
          "dụng đọc danh sách qua View thay vì viết lại nhiều câu truy vấn phức tạp, đồng thời View "
          "còn là lớp bảo mật — sinh viên chỉ xem được dữ liệu của chính mình."),
    ("tbl", "View", ["View", "Chức năng"], [
        ["VW_SinhVienDangKyChiTiet", "Chi tiết đăng ký kèm tên SV, tên lớp HP, môn học, sĩ số"],
        ["VW_ThoiKhoaBieuCaNhan", "Thời khóa biểu cá nhân: thứ, tiết, phòng, giảng viên theo SV"],
        ["V_BANGDIEM_SINHVIEN", "Bảng điểm đầy đủ một sinh viên (điểm thành phần, tổng kết, chữ, hệ 4)"],
        ["V_THONGKE_KETQUA_MONHOC", "Thống kê kết quả một lớp học phần: phân bố điểm, tỷ lệ đạt"],
        ["VW_SinhVienDangHoc", "Danh sách sinh viên đang học (phục vụ lọc nhanh)"],
        ["VW_SinhVienNoHocPhi", "Sinh viên còn nợ học phí theo kỳ"],
        ["VW_SinhVienDaThanhToan", "Sinh viên đã thanh toán xong học phí"],
        ["VW_TongThuTheoHocKy", "Tổng thu học phí nhóm theo học kỳ"],
        ["VW_TongThuTheoNganh", "Tổng thu học phí nhóm theo ngành"],
        ["VW_BaoCaoHocPhi", "Báo cáo học phí tổng hợp phục vụ dashboard PĐT"],
    ]),
    ("h", 3, "3.5.2. Function"),
    ("p", "Function được sử dụng như một hàm trả về giá trị phục vụ kiểm tra điều kiện và tính toán "
          "nghiệp vụ. Hệ thống có 9 Function, chia thành ba nhóm: kiểm tra điều kiện đăng ký, kiểm "
          "tra xếp lịch và tính điểm."),
    ("tbl", "Function", ["Function", "Chức năng"], [
        ["FN_KiemTraDotDangKy", "Kiểm tra học kỳ đang mở đợt đăng ký và thời điểm hiện tại nằm "
         "trong [TuNgay, DenNgay]"],
        ["FN_KiemTraTienQuyet", "Kiểm tra sinh viên đã đạt TOÀN BỘ môn tiên quyết của môn đăng ký "
         "(phép truy vấn lồng: với mỗi môn TQ, phải tồn tại KETQUAHOCTAP điểm đạt)"],
        ["FN_KiemTraTrungLichHoc", "Kiểm tra lớp định đăng ký có buổi học (thứ, tiết) chồng lấn với "
         "lịch các lớp sinh viên đã đăng ký trong kỳ"],
        ["FN_KiemTraPhongTrong", "Kiểm tra phòng học trống trong khung giờ định xếp lịch (phục vụ "
         "mở lớp)"],
        ["FN_TinhTongTinChi", "Đếm tổng tín chỉ các lớp sinh viên đang đăng ký trong kỳ — dùng cho "
         "ràng buộc MaxTinChi"],
        ["FN_TinhDiemTongKet", "Tính điểm tổng kết theo trọng số 10% CC + 30% GK + 60% CK"],
        ["FN_QuyDoiDiemChu", "Quy đổi điểm hệ 10 → điểm chữ nhờ bảng THANGDIEMCHU"],
        ["FN_QuyDoiDiemHe4", "Quy đổi điểm hệ 10 → điểm hệ 4"],
        ["FN_DemSiSoLop", "Đếm sĩ số thực tế từ bảng đăng ký — dùng đối chiếu, hiệu chỉnh "
         "SiSoHienTai"],
    ]),
    ("h", 3, "3.5.3. Stored Procedure"),
    ("p", "Procedure được dùng để đóng gói các thao tác nghiệp vụ phức tạp. Toàn bộ ghi-đọc của ứng "
          "dụng đều đi qua Procedure; tầng backend KHÔNG viết SQL trực tiếp và KHÔNG tự mở giao tác "
          "— mọi TRANSACTION nằm bên trong Procedure. Đây là điểm khác biệt quan trọng so với cách "
          "để logic nghiệp vụ phân tán ở ứng dụng: bảo đảm tính nhất quán và chỉ một điểm thực thi "
          "duy nhất cho mỗi nghiệp vụ."),
    ("tbl", "Procedure", ["Procedure", "Chức năng"], [
        ["SP_DangKyHocPhan ⭐", "Đăng ký một lớp học phần: 5 bước kiểm tra + ghi nhận trong MỘT giao "
         "tác (đợt mở → trùng lớp → tiên quyết → trùng lịch → tín chỉ → FOR UPDATE khóa dòng lớp "
         "kiểm tra sĩ số → INSERT); trả mã 0–106; tự RETRY khi gặp deadlock 1213"],
        ["SP_DangKyNhieuHocPhan ⭐", "Đăng ký NHIỀU lớp trong MỘT giao dịch bằng CON TRỎ: mở cursor "
         "duyệt danh sách MaLHP ĐÃ SẮP XẾP TĂNG DẦN, khóa lần lượt từng dòng sĩ số — thứ tự khóa "
         "nhất quán ⇒ triệt tiêu deadlock; một lớp lỗi ⇒ ROLLBACK cả lô"],
        ["SP_HuyDangKy", "Hủy đăng ký trong hạn; sau khi được sửa lỗi thứ tự khóa: KHÓA LOPHOCPHAN "
         "TRƯỚC rồi mới đọc DANGKYHOCPHAN — cùng thứ tự khóa với SP_DangKyHocPhan"],
        ["SP_DangKyHocPhan_ChuaFix", "Bản gốc CHƯA fix (thiếu FOR UPDATE) — chỉ dùng để TÁI HIỆN lỗi "
         "Lost Update khi trình diễn"],
        ["SP_ThemSinhVien_Moi", "Thêm sinh viên: kiểm tra lớp tồn tại, chống trùng mã, và TỰ TẠO TÀI "
         "KHOAN trong cùng thủ tục"],
        ["SP_ChuyenLop_Nganh", "Chuyển lớp sinh viên (mã lỗi 403–405)"],
        ["SP_MoLopHocPhan", "Mở lớp học phần + xếp lịch: kiểm tra giảng viên và phòng không trùng "
         "lịch (FN_KiemTraPhongTrong)"],
        ["SP_GV_NHAP_DIEM", "Giảng viên nhập điểm cho một sinh viên (kiểm tra quyền phụ trách lớp)"],
        ["SP_GV_NhapDiemHangLoat", "Nhập điểm CẢ LỚP trong MỘT GIAO TÁC bằng CON TRỎ; một dòng sai ⇒ "
         "ROLLBACK cả lô"],
        ["SP_TinhGPA_HocKy", "Tính GPA học kỳ + xếp loại"],
        ["SP_TinhCPA_TichLuy", "Tính CPA tích lũy (môn học lại tính điểm cao nhất) + đặt cảnh báo "
         "học vụ"],
        ["SP_TinhHocPhi", "Tính học phí = tổng tín chỉ × đơn giá, tôn trọng UNIQUE (MaSV, MaHocKy)"],
        ["SP_ThuHocPhi", "Thu tiền trong TRANSACTION: kiểm tra còn nợ, cập nhật DaNop/trạng thái "
         "(mã lỗi 301–304)"],
        ["SP_TaoTaiKhoanSinhVien / SP_TaoTaiKhoanGiangVien", "Tạo tài khoản tự động với tên đăng "
         "nhập và mật khẩu mặc định đã băm"],
        ["SP_ThemMonHocVaTienQuyet", "Thêm môn học + danh sách môn tiên quyết trong CÙNG MỘT GIAO "
         "TÁC (nghiệp vụ nằm trọn trong DB)"],
        ["SP_TaoYeuCauDatLaiMatKhau / SP_XuLyYeuCauDatLaiMatKhau / SP_TuChoiYeuCauDatLaiMatKhau",
         "Luồng “Quên mật khẩu?”: ghi nhận yêu cầu và PĐT duyệt/từ chối"],
    ]),
    ("p", "Trong đó, SP_DangKyHocPhan là Procedure quan trọng nhất vì xử lý nghiệp vụ trung tâm. "
          "Khi sinh viên đăng ký, hệ thống phải lần lượt kiểm tra năm điều kiện rồi mới ghi bản ghi "
          "đăng ký; toàn bộ được đặt trong một giao tác để nếu bất kỳ bước nào lỗi, hệ thống hủy bỏ "
          "toàn bộ và dữ liệu không bị sai lệch. Bước kiểm tra sĩ số dùng SELECT … FOR UPDATE khóa "
          "dòng của lớp học phần cho đến khi COMMIT — tương đương UPDLOCK + HOLDLOCK của SQL Server "
          "— để hai sinh viên cùng giành suất cuối không thể cùng thấy “còn chỗ”. Procedure "
          "SP_DangKyNhieuHocPhan mở rộng tinh thần đó cho việc đăng ký nhiều lớp một lần: con trỏ "
          "duyệt theo MaLHP TĂNG DẦN để mọi giao dịch cùng chiều khóa, tránh deadlock. Procedure "
          "SP_ThuHocPhi cũng dùng giao tác và kiểm tra trạng thái hóa đơn để tránh hai giao dịch thu "
          "tiền chồng lấn lên cùng một phiếu."),
    ("h", 3, "3.5.4. Trigger"),
    ("p", "Trigger được sử dụng để tự động thực hiện một thao tác khi có sự kiện thêm, sửa hoặc xóa "
          "dữ liệu xảy ra trên bảng. Hệ thống có 9 trigger (tính theo từng bảng × thời điểm)."),
    ("tbl", "Trigger", ["Trigger", "Bảng tác động", "Thời điểm", "Chức năng chính"], [
        ["TRG_DANGKYHOCPHAN_AFTER_INSERT", "DANGKYHOCPHAN", "AFTER INSERT",
         "Vừa có đăng ký mới → tự động CỘNG 1 SiSoHienTai của lớp học phần"],
        ["TRG_DANGKYHOCPHAN_AFTER_UPDATE", "DANGKYHOCPHAN", "AFTER UPDATE",
         "Đổi trạng thái (DA_DANG_KY ↔ DA_HUY) → điều chỉnh ±1 sĩ số cho đúng"],
        ["TRG_DANGKYHOCPHAN_AFTER_DELETE", "DANGKYHOCPHAN", "AFTER DELETE",
         "Xóa bản ghi đăng ký → tự động TRỪ 1 sĩ số"],
        ["TRG_KETQUAHOCTAP_BEFORE_INSERT", "KETQUAHOCTAP", "BEFORE INSERT",
         "Khi nhập điểm lần đầu: tự tính DiemTongKet, DiemChu, DiemHe4 trước khi ghi"],
        ["TRG_KETQUAHOCTAP_BEFORE_UPDATE", "KETQUAHOCTAP", "BEFORE UPDATE",
         "Khi sửa điểm thành phần: tính LẠI điểm tổng kết/chữ/hệ 4"],
        ["TRG_LICHHOC_BEFORE_INSERT", "LICHHOC", "BEFORE INSERT",
         "CHẶN lưu buổi học mới nếu phòng hoặc giảng viên đã có lịch trùng khung giờ"],
        ["TRG_LICHHOC_BEFORE_UPDATE", "LICHHOC", "BEFORE UPDATE",
         "Tương tự khi sửa lịch"],
        ["TRG_LogDoiMatKhau", "TAIKHOAN", "AFTER UPDATE",
         "Khi MatKhau thay đổi → ghi một dòng vào NHATKY_DOIMATKHAU"],
        ["TRG_XoaNganh_ChanKhiConSinhVien", "NGANH", "BEFORE DELETE",
         "CHẶN xóa ngành khi còn sinh viên thuộc các lớp của ngành đó"],
    ]),
    ("p", "Ba trigger đặc trưng nhất: (1) Nhóm trigger sĩ số biến một cột ĐỘ DẪN (SiSoHienTai) thành "
          "bất biến được duy trì tự động — mọi đường ghi (kể cả script tay) đều đi qua nó nên ứng "
          "dụng không thể quên cập nhật; (2) nhóm trigger điểm hiện thực công thức tính tổng kết ngay "
          "trước khi ghi, bảo đảm không bao giờ có dòng điểm chưa quy đổi; (3) nhóm trigger lịch học "
          "hiện thực ràng buộc KHÔNG THỂ DIỄN ĐẠT bằng CHECK (phải so sánh giữa các dòng khác nhau). "
          "Nhờ trigger, dữ liệu giữa DANGKYHOCPHAN ↔ LOPHOCPHAN ↔ KETQUAHOCTAP ↔ LICHHOC luôn đồng "
          "bộ và giảm thao tác xử lý thủ công ở tầng ứng dụng."),
    ("h", 3, "3.5.5. Index"),
    ("p", "Hệ thống được tối ưu chỉ mục theo đúng các truy vấn nóng nhất của nghiệp vụ:"),
    ("ul", [
        "Composite index (MaPhong, Thu, TietBatDau) và (MaGV, Thu, TietBatDau) trên LICHHOC — tăng "
        "tốc kiểm tra trùng phòng / trùng giảng viên mỗi lần mở lớp hoặc đăng ký.",
        "Index trên MaSV và MaLHP của DANGKYHOCPHAN — tra danh sách đăng ký và kiểm tra trùng lớp.",
        "Index trên (HoTen, MaLopSH) — tìm kiếm sinh viên theo tên và lớp ở màn danh mục.",
        "Index trên MaSV của KETQUAHOCTAP và HOCPHI — tra bảng điểm, học phí theo sinh viên.",
        "UNIQUE index trên TenDangNhap — đăng nhập O(log n) và chống trùng tài khoản.",
        "Chỉ mục (TrangThai, NgayGui) trên YEUCAU_DATLAI_MATKHAU — màn duyệt yêu cầu đặt lại mật khẩu.",
    ]),
    ("p", "Hiệu năng trước/sau khi tạo index được đo và ghi trong tài liệu docs/performance/"
          "index_benchmark.md."),
    ("pb",),

    # ---------- 3.6 ACID ----------
    ("h", 2, "3.6. Giao tác và tính chất ACID"),
    ("p", "Một giao tác cần đảm bảo bốn tính chất ACID gồm: Atomicity, Consistency, Isolation và "
          "Durability. Trong hệ thống này, mọi giao tác đều nằm bên trong Stored Procedure — ứng "
          "dụng không tự mở giao dịch, nhờ đó không tồn tại đường ghi nào vòng qua kiểm soát."),
    ("h", 3, "3.6.1. Tính nguyên tử (Atomicity)"),
    ("p", "Ý nghĩa: Giao tác được xem là một khối xử lý không thể chia nhỏ. Hoặc thực hiện toàn bộ "
          "các thao tác → COMMIT; hoặc nếu có lỗi thì hủy toàn bộ → ROLLBACK."),
    ("p", "Ví dụ trong hệ thống đăng ký học phần, khi sinh viên đăng ký nhiều lớp bằng "
          "SP_DangKyNhieuHocPhan, hệ thống phải thực hiện nhiều bước:"),
    ("num", [
        "Khởi tạo giao tác (START TRANSACTION).",
        "Mở con trỏ danh sách MaLHP đã sắp xếp tăng dần; với từng lớp: kiểm tra đợt mở, ràng buộc "
        "nghiệp vụ, KHÓA dòng sĩ số bằng SELECT … FOR UPDATE.",
        "INSERT bản ghi DANGKYHOCPHAN; Trigger tự động cộng 1 SiSoHienTai.",
        "Toàn bộ hợp lệ → COMMIT.",
    ]),
    ("p", "Nếu sinh viên đăng ký 3 lớp nhưng đến lớp thứ 2 bị lỗi, ví dụ lớp đó đã đầy hoặc trùng "
          "lịch, thì hệ thống KHÔNG ĐƯỢC lưu nửa chừng. Trường hợp lỗi: đã tạo bản ghi của lớp thứ "
          "nhất, lớp thứ hai vi phạm ràng buộc. Nếu không có Atomicity, hệ thống sẽ rơi vào trạng "
          "thái phiếu đăng ký một phần: lớp thứ nhất chiếm sĩ số, lớp thứ hai mất — dữ liệu sai lệch "
          "khó lần ra. Cách xử lý đúng: nếu có BẤT KỲ lớp nào lỗi → ROLLBACK toàn bộ giao tác; sinh "
          "viên nhận đúng một thông báo lỗi của lớp vi phạm và danh sách lớp không thay đổi dòng nào."),
    ("h", 3, "3.6.2. Tính nhất quán (Consistency)"),
    ("p", "Ý nghĩa: Sau khi giao tác kết thúc, CSDL phải ở trạng thái hợp lệ và tuân thủ đầy đủ các "
          "ràng buộc. Ràng buộc của hệ thống gồm: khóa chính, khóa ngoại (kể cả khóa ngoại GHỐI), "
          "NOT NULL, UNIQUE, CHECK / giá trị trạng thái hợp lệ, và ràng buộc nghiệp vụ đăng ký — "
          "điểm số."),
    ("p", "Ví dụ: không thể tồn tại bảng điểm của một sinh viên chưa đăng ký lớp. Với ràng buộc "
          "FK_KQHT_DANGKY (FK ghép xuống DANGKYHOCPHAN):"),
    ("sql", "INSERT INTO KETQUAHOCTAP (MaSV, MaLHP, DiemChuyenCan, DiemGiuaKy, DiemCuoiKy)\n"
            "VALUES ('SV999', 'LHP999', 8, 7, 9);\n"
            "-- Cặp ('SV999','LHP999') không tồn tại trong DANGKYHOCPHAN → vi phạm khóa ngoại."),
    ("p", "Kết quả đúng: hệ thống không cho thêm dữ liệu, giao tác bị hủy, CSDL giữ nguyên trạng "
          "thái nhất quán. Ví dụ nhất quán khác: khi có bản ghi DA_DANG_KY mới, SiSoHienTai phải "
          "tăng đúng 1 (trigger); khi bản ghi chuyển DA_HUY, SiSoHienTai phải giảm đúng 1. Nếu bảng "
          "đăng ký ghi DA_DANG_KY mà SiSoHienTai vẫn giữ nguyên thì dữ liệu mất nhất quán."),
    ("h", 3, "3.6.3. Tính cô lập (Isolation)"),
    ("p", "Ý nghĩa: các giao tác chạy đồng thời không được làm ảnh hưởng sai lệch lẫn nhau — mỗi "
          "giao tác phải cho kết quả như thể nó chạy một mình, dù trên thực tế hàng trăm sinh viên "
          "cùng đăng ký trong một khung giờ."),
    ("p", "Nếu không có Isolation trong hệ thống sẽ gây ra các lỗi: mất dữ liệu cập nhật (Lost "
          "Update), đọc dữ liệu rác (Dirty Read), không đọc lại được dữ liệu (Non-repeatable Read), "
          "bóng ma (Phantom) và khóa chết (Deadlock)."),
    ("p", "Ví dụ trong hệ thống đăng ký: hai sinh viên cùng lúc giành suất CUỐI CÙNG của lớp "
          "LHP01 (SiSoToiDa = 50, SiSoHienTai = 49):"),
    ("num", [
        "T1 đọc SiSoHienTai = 49 → thấy còn chỗ",
        "T2 đọc SiSoHienTai = 49 → cũng thấy còn chỗ",
        "T1 INSERT đăng ký; T2 cũng INSERT",
        "Nếu không cô lập: lớp nhận 51/50 — vi phạm ràng buộc sĩ số",
    ]),
    ("p", "Cách xử lý đúng: trong SP_DangKyHocPhan, bước kiểm tra sĩ số dùng SELECT … FOR UPDATE "
          "khóa dòng LOPHOCPHAN đến khi COMMIT; T2 phải CHỜ T1 kết thúc rồi đọc lại, thấy 50/50 và "
          "báo mã lỗi 105 “Lớp đã đầy sĩ số”. Nhờ đó một chỗ ngồi chỉ được cấp cho đúng một sinh "
          "viên."),
    ("h", 3, "3.6.4. Tính bền vững (Durability)"),
    ("p", "Ý nghĩa: Khi giao tác đã COMMIT, dữ liệu phải được lưu bền vững, không mất khi hệ thống "
          "gặp sự cố. Cách thực hiện: InnoDB ghi redo log (WAL) và chỉ ghi xuống bộ nhớ ổn định theo "
          "cơ chế checkpoint; có cơ chế khôi phục từ log khi crash."),
    ("p", "Ví dụ: nhân viên PĐT thu học phí thành công cho một sinh viên; sau COMMIT, hệ thống đã "
          "lưu bản ghi cập nhật DaNop, trạng thái DA_THANH_TOAN trong HOCPHI. Nếu server mất điện "
          "ngay sau đó, dữ liệu đã commit vẫn phải được giữ lại: hóa đơn đã nộp đúng số tiền, không "
          "thụt lui."),
    ("pb",),
]
