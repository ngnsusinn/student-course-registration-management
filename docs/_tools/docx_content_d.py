# -*- coding: utf-8 -*-
"""Chương 5 — Giao diện; Chương 6 — Kết luận; Tài liệu tham khảo."""

TCB = "[Điền tên]"
MK = "[mật khẩu demo — điền mật khẩu hiện hành]"

CH5 = [
    ("h", 1, "5. Giao diện hệ thống"),
    ("p", "Link web để chạy hệ thống quản lý đăng ký học phần: " + TCB + " (địa chỉ triển khai thực "
          "tế của nhóm — backend Express phục vụ luôn bản build React SPA trên cùng tiến trình)."),
    ("p", "Hệ thống gồm 3 nhóm tài khoản theo đúng 3 vai trò. Dùng tên tài khoản và mật khẩu dưới "
          "đây để đăng nhập vào hệ thống:"),
    ("ul", [
        "Phòng Đào Tạo (Quản trị hệ thống): tên tài khoản: admin — Password: " + MK +
        " (toàn quyền quản trị)",
        "Giảng viên: tên tài khoản: gv001 — Password: " + MK + " (nhập điểm, theo dõi lớp phụ trách)",
        "Sinh viên: tên tài khoản: sv001 — Password: " + MK + " (đăng ký học phần, tra cứu, điểm, "
        "học phí)",
    ]),
    ("p", "Môi trường dữ liệu thật đã kiểm thử: ngoài 3 tài khoản trên còn có bộ dữ liệu mẫu 60 sinh "
          "viên (sv001–sv060), 15 giảng viên (gv001–gv015), 48 môn học, 46 lớp học phần, 794 lượt "
          "đăng ký trên 5 học kỳ. Tài khoản sv060 được khóa (LOCKED) để minh họa luồng từ chối đăng "
          "nhập."),
    ("note", "Toàn bộ ảnh dưới đây chụp từ giao diện thật của hệ thống; các mục [CHÈN ẢNH] để trống "
             "để nhóm chèn ảnh minh họa vào bản hoàn chỉnh."),
    ("h", 2, "5.1. Phòng Đào tạo (quản trị hệ thống)"),
    ("h", 3, "5.1.1. Giao diện đăng nhập"),
    ("p", "Màn hình đăng nhập một bước: tên đăng nhập + mật khẩu; nhận diện thương hiệu Portal UTH "
          "(logo trường, nền, màu teal). Sai thông tin hiển thị thông báo lỗi; tài khoản bị khóa nhận "
          "thông báo từ chối riêng."),
    ("img", "Giao diện đăng nhập"),
    ("h", 3, "5.1.2. Dashboard quản trị"),
    ("p", "Dashboard tổng hợp toàn hệ thống theo vai trò PĐT: thẻ số liệu sinh viên / giảng viên / "
          "môn học / lớp học phần / lượt đăng ký theo kỳ, biểu đồ thu học phí, hộp thoại đổi mật khẩu "
          "toàn cục."),
    ("img", "Dashboard Phòng Đào tạo"),
    ("h", 3, "5.1.3. Quản lý sinh viên"),
    ("p", "Danh sách sinh viên kèm lọc theo lớp sinh hoạt và tìm kiếm theo tên; chức năng thêm (tự tạo "
          "tài khoản kèm hồ sơ), sửa, xóa và CHUYỂN LỚP. Thử thêm sinh viên vào lớp không tồn tại để "
          "thấy mã lỗi 401–405 hiển thị đúng nguyên nhân."),
    ("img", "Quản lý sinh viên — danh sách và tìm kiếm"),
    ("img", "Thêm / cập nhật hồ sơ sinh viên"),
    ("h", 3, "5.1.4. Quản lý Khoa — Ngành — Lớp sinh hoạt"),
    ("p", "CRUD ba danh mục tổ chức và chương trình đào tạo của ngành (môn – học kỳ dự kiến – bắt "
          "buộc). Thử xóa ngành còn sinh viên: hệ thống từ chối với thông báo lỗi phát từ Trigger."),
    ("img", "Quản lý Khoa – Ngành – Lớp – Chương trình đào tạo"),
    ("h", 3, "5.1.5. Quản lý Môn học & tiên quyết"),
    ("p", "CRUD môn học (số tín chỉ, lý thuyết, thực hành, khoa phụ trách) và bảng quan hệ tiên quyết "
          "giữa các môn. Thêm môn học kèm danh sách tiên quyết được ghi bằng MỘT giao dịch — nếu một "
          "quan hệ tiên quyết lỗi thì toàn bộ bị hủy."),
    ("img", "Quản lý môn học và danh sách môn tiên quyết"),
    ("h", 3, "5.1.6. Quản lý Giảng viên — Phòng học — Học kỳ"),
    ("p", "CRUD giảng viên (tự tạo tài khoản), phòng học (sức chứa) và học kỳ kèm đợt đăng ký: mở "
          "(MO) / đóng (DONG) đợt chính là công tắc bật/tắt nghiệp vụ đăng ký của toàn trường."),
    ("img", "Quản lý giảng viên / phòng học / học kỳ và đợt đăng ký"),
    ("h", 3, "5.1.7. Mở lớp học phần & xếp lịch"),
    ("p", "Tạo lớp học phần cho môn trong kỳ, gán giảng viên, nhập các buổi học (phòng, thứ, tiết). "
          "Giao diện dạng thời khóa biểu; SP_MoLopHocPhan tự kiểm tra và báo lỗi nếu giảng viên hoặc "
          "phòng trùng lịch."),
    ("img", "Mở lớp học phần và xếp lịch dạng thời khóa biểu"),
    ("h", 3, "5.1.8. Điểm & cảnh báo học vụ"),
    ("p", "Danh sách sinh viên bị cảnh báo học vụ (CPA dưới ngưỡng), thống kê kết quả từng môn học, "
          "GPA sinh viên theo lớp."),
    ("img", "Danh sách cảnh báo học vụ và thống kê kết quả môn học"),
    ("h", 3, "5.1.9. Quản lý học phí"),
    ("p", "Tính học phí theo tín chỉ, danh sách hóa đơn lọc theo trạng thái (chưa thanh toán / nợ / đã "
          "nộp), form thu tiền chạy trong giao dịch, báo cáo tổng thu theo kỳ và theo ngành; nút Xuất "
          "Excel (CSV) cho bảng lớn."),
    ("img", "Quản lý học phí — danh sách, thu tiền và báo cáo"),
    ("h", 3, "5.1.10. Quản lý tài khoản & nhật ký bảo mật"),
    ("p", "Danh sách tài khoản, tạo tài khoản SV/GV tự động, khóa/mở khóa; danh sách yêu cầu “Quên mật "
          "khẩu?” chờ xử lý; bảng nhật ký đổi mật khẩu do trigger ghi tự động."),
    ("img", "Quản lý tài khoản, khóa/mở khóa và nhật ký đổi mật khẩu"),
    ("h", 2, "5.2. Sinh viên"),
    ("h", 3, "5.2.1. Trang chủ sinh viên"),
    ("p", "Dashboard theo vai trò SV: tổng tín chỉ đã đăng ký trong kỳ, số lớp đã đăng ký, hạn chót "
          "đăng ký."),
    ("img", "Trang chủ sinh viên"),
    ("h", 3, "5.2.2. Đăng ký lớp học phần"),
    ("p", "Danh sách lớp đang mở kèm sĩ số còn trống, lịch học, giảng viên và trạng thái “đã đăng ký”. "
          "Sinh viên bấm đăng ký từng lớp hoặc TICK CHỌN NHIỀU LỚP rồi bấm “Đăng ký N lớp đã chọn” — "
          "một giao dịch duy nhất. Mọi vi phạm hiển thị đúng mã lỗi (100–106) bằng thông báo đỏ; hai "
          "sinh viên giành suất cuối thì một người nhận thông báo “Lớp đã đầy sĩ số”."),
    ("img", "Đăng ký lớp học phần — đăng ký nhiều lớp một lần"),
    ("img", "Thông báo mã lỗi nghiệp vụ khi đăng ký (hết đợt / thiếu tiên quyết / trùng lịch / đầy sĩ số)"),
    ("h", 3, "5.2.3. Thời khóa biểu"),
    ("p", "Thời khóa biểu cá nhân theo học kỳ, hiển thị theo thứ/tiết/phòng/giảng viên (view "
          "VW_ThoiKhoaBieuCaNhan)."),
    ("img", "Thời khóa biểu cá nhân"),
    ("h", 3, "5.2.4. Danh sách đăng ký & hủy đăng ký"),
    ("p", "Tổng hợp các lớp đã đăng ký kèm tổng tín chỉ theo kỳ; màn hủy đăng ký chỉ liệt kê lớp còn "
          "trong hạn hủy, xác nhận hai bước trước khi ghi."),
    ("img", "Danh sách đăng ký và hủy đăng ký học phần"),
    ("h", 3, "5.2.5. Bảng điểm — GPA / CPA"),
    ("p", "Bảng điểm chi tiết theo học kỳ (điểm thành phần, tổng kết, chữ, hệ 4), GPA học kỳ, CPA tích "
          "lũy, xếp loại và thông tin cảnh báo học vụ; bảng quy đổi thang điểm chữ tra cứu mọi lúc."),
    ("img", "Bảng điểm, GPA/CPA và xếp loại học lực"),
    ("h", 3, "5.2.6. Học phí của tôi"),
    ("p", "Hóa đơn học phí theo kỳ: tổng tiền, đã nộp, còn nợ, trạng thái."),
    ("img", "Học phí cá nhân"),
    ("h", 3, "5.2.7. Thông tin cá nhân"),
    ("p", "Hồ sơ sinh viên (họ tên, MSSV, ngày sinh, lớp, ngành, khoa…) và cập nhật thông tin liên hệ; "
          "nút Đổi mật khẩu toàn cục kèm ghi nhật ký."),
    ("img", "Thông tin cá nhân sinh viên"),
    ("h", 2, "5.3. Giảng viên"),
    ("h", 3, "5.3.1. Lớp của tôi"),
    ("p", "Danh sách lớp học phần được phân công theo học kỳ kèm sĩ số và lịch giảng dạy."),
    ("img", "Danh sách lớp học phần của giảng viên"),
    ("h", 3, "5.3.2. Nhập điểm"),
    ("p", "Chọn lớp → bảng nhập điểm chuyên cần / giữa kỳ / cuối kỳ cho toàn lớp; nhập từng sinh viên "
          "hoặc điền hàng loạt rồi “Lưu tất cả” (một giao dịch bằng con trỏ). Điểm tổng kết, điểm chữ "
          "và điểm hệ 4 hiển thị ngay do trigger tự tính."),
    ("img", "Màn hình nhập điểm hàng loạt của giảng viên"),
    ("h", 3, "5.3.3. Thời khóa biểu giảng viên & thống kê"),
    ("p", "TKB giảng dạy cá nhân; thống kê phân bố điểm và GPA sinh viên trong lớp phụ trách."),
    ("img", "Thời khóa biểu giảng viên và thống kê kết quả lớp"),
    ("h", 2, "5.4. Tổng kết các chức năng trên giao diện hệ thống"),
    ("tbl", "Các chức năng trên giao diện hệ thống",
     ["Chức năng", "Phòng Đào tạo", "Giảng viên", "Sinh viên"], [
        ["Xem dashboard", "Có", "Có", "Có"],
        ["Đăng ký / hủy học phần", "Không", "Không", "Có"],
        ["Tra cứu thời khóa biểu", "Có", "Có (lớp của mình)", "Có (của mình)"],
        ["Nhập điểm", "Không", "Có", "Không"],
        ["Xem bảng điểm", "Có (mọi SV)", "Có (lớp phụ trách)", "Có (của mình)"],
        ["Xem / quản lý học phí", "Có (tính, thu, báo cáo)", "Không", "Có (xem của mình)"],
        ["Quản lý sinh viên", "Có", "Không", "Không"],
        ["Quản lý danh mục & CTĐT", "Có", "Không", "Không"],
        ["Mở lớp học phần & xếp lịch", "Có", "Không", "Không"],
        ["Cảnh báo học vụ", "Có", "Không", "Có (của mình)"],
        ["Quản lý tài khoản", "Có", "Không", "Không"],
    ]),
    ("p", "Quyền truy cập được thực thi ở lớp ứng dụng (JWT + middleware requireRole theo MaVaiTro) "
          "kết hợp phân quyền GRANT của CSDL; sinh viên chỉ đọc được dữ liệu của mình qua View."),
    ("pb",),

    # =================== 6. KẾT LUẬN ===================
    ("h", 1, "6. Kết luận"),
    ("p", "Hệ thống quản lý sinh viên đăng ký học phần tín chỉ đã được xây dựng nhằm hỗ trợ nhà "
          "trường quản lý hiệu quả toàn bộ vòng đời đào tạo theo tín chỉ: quản lý hồ sơ sinh viên và "
          "danh mục đào tạo, mở lớp học phần và xếp lịch, đăng ký – hủy đăng ký, nhập điểm và tính "
          "GPA/CPA, quản lý học phí và vận hành tài khoản. Thay vì quản lý thủ công bằng sổ sách và "
          "bảng tính, hệ thống lưu trữ dữ liệu tập trung, giảm sai sót trong khâu đăng ký vốn nhiều "
          "xung đột nhất, và hỗ trợ sinh viên — giảng viên — cán bộ đào tạo thao tác nhanh chóng, "
          "minh bạch hơn."),
    ("p", "Về mặt chức năng, hệ thống được chia thành các nhóm chính gồm: quản lý danh mục & hồ sơ, "
          "quản lý đào tạo (môn học, tiên quyết, mở lớp, xếp lịch), nghiệp vụ trung tâm đăng ký học "
          "phần với năm ràng buộc kiểm tra, quản lý điểm số & kết quả học tập tự động, và quản lý tài "
          "chính học phí — tài khoản. Sinh viên là người dùng cuối thực hiện đăng ký, tra cứu và xem "
          "kết quả của chính mình; giảng viên nhập điểm và theo dõi lớp được phân công; Phòng Đào tạo "
          "nắm toàn quyền quản trị danh mục, học vụ, tài chính và hệ thống."),
    ("p", "Về cơ sở dữ liệu, hệ thống được thiết kế theo mô hình quan hệ với 18 bảng nghiệp vụ tổ chức "
          "theo 5 module, cộng 2 bảng bổ trợ phục vụ vận hành. Các bảng liên kết với nhau qua khóa "
          "chính và khóa ngoại — trong đó nổi bật là các KHÓA CHÍNH GHÉP của bảng trung tâm "
          "DANGKYHOCPHAN (MaSV, MaLHP) và KHÓA NGOẠI GHỐI từ KETQUAHOCTAP trỏ xuống đúng cặp khóa "
          "này — giúp ràng buộc nghiệp vụ “chỉ có điểm khi đã đăng ký” được chính CSDL bảo đảm. Việc "
          "tách MÔN HỌC khỏi LỚP HỌC PHẦN, và LỊCH HỌC khỏi LỚP, cho phép quản lý đúng bản chất “một "
          "môn nhiều lớp, một lớp nhiều buổi” của đào tạo tín chỉ. Toàn bộ thiết kế được chứng minh "
          "đạt dạng chuẩn 3NF."),
    ("p", "Ngoài các bảng dữ liệu, hệ thống sử dụng 10 View, 9 Function, hơn hai chục Stored Procedure "
          "và 9 Trigger. View phục vụ tra cứu, thống kê và hạn chế tầm nhìn dữ liệu theo vai trò. "
          "Function hiện thực các phép kiểm tra phức tạp (đợt đăng ký, môn tiên quyết, trùng lịch học, "
          "quy đổi điểm). Procedure gom toàn bộ quy trình nghiệp vụ nhiều bước vào một điểm thực thi "
          "duy nhất — trong đó SP_DangKyHocPhan là thủ tục trung tâm. Trigger tự động cập nhật sĩ số, "
          "tự động tính điểm tổng kết, chặn trùng lịch và chặn xóa dữ liệu còn tham chiếu."),
    ("p", "Hệ thống đặc biệt chú trọng an toàn dữ liệu trong môi trường nhiều người dùng thông qua "
          "giao tác và các tính chất ACID: mọi nghiệp vụ nhiều bước (đăng ký, đăng ký nhiều lớp, hủy, "
          "nhập điểm hàng loạt, thu học phí, thêm sinh viên kèm tạo tài khoản…) chạy trong một giao "
          "tác nằm TRỌNG TÂM ở tầng CSDL — ứng dụng không viết SQL trực tiếp và không tự mở giao dịch. "
          "Nhờ đó dữ liệu không bao giờ rơi vào trạng thái nửa đúng nửa sai."),
    ("p", "Báo cáo đã phân tích và TÁI HIỆN BẰNG THỰC NGHIỆM năm lớp lỗi và xung đột kinh điển của "
          "hệ quản trị CSDL trên chính dữ liệu của hệ thống: Lost Update (hai sinh viên giành suất "
          "cuối — lớp nhận 17/16 khi bản chưa khóa), Dirty Read, Non-repeatable Read, Phantom Read "
          "(chủ động hạ mức cô lập để nhìn thấy lỗi, rồi chứng minh mức mặc định REPEATABLE-READ + "
          "MVCC chặn lại), và Deadlock — bao gồm cả lỗi ĐẢO THỨ TỰ KHÓA có thật trong thủ tục hủy, "
          "được phát hiện, sửa bằng quy ước khóa thống nhất, và phòng chống tận gốc bằng khóa theo thứ "
          "tự nhất quán trong thủ tục đăng ký nhiều lớp. Kết quả kiểm chứng: 10/10 pha demo anomaly "
          "PASS, 6/6 pha deadlock + 13/13 test E2E PASS; lỗi 1213 được HQTCSDL phát hiện, hệ thống "
          "tự thử lại và báo rõ cho người dùng qua HTTP 409 kèm thông báo trên giao diện."),
    ("p", "Về giao diện, hệ thống hướng tới sự đơn giản, đúng quy trình và quen thuộc với người dùng "
          "trường đại học: 19 màn hình theo ba vai trò dựng bằng React 18 + Material UI theo nhận diện "
          "Portal của trường, thông báo bằng đúng mã lỗi nghiệp vụ, xuất bảng dữ liệu sang Excel. Mọi "
          "kịch bản demo lỗi đều chạy bằng THAO TÁC THẬT của người dùng hoặc script SQL trực tiếp trên "
          "CSDL — trong ứng dụng không tồn tại màn hình hay API demo nào."),
    ("p", "Tóm lại, hệ thống đã đáp ứng được các yêu cầu cơ bản về quản lý dữ liệu, xử lý nghiệp vụ "
          "và đảm bảo tính nhất quán của cơ sở dữ liệu, đồng thời vận hành thật trên MySQL remote với "
          "dữ liệu mẫu lớn. Trong tương lai, hệ thống có thể tiếp tục mở rộng: khôi phục đăng nhập "
          "OTP hai bước cho giảng viên và cán bộ như portal thật, gửi email nhắc lịch học – lịch nộp "
          "học phí – kết quả điểm, danh sách chờ (waiting list) tự động bù chỗ khi có sinh viên hủy "
          "lớp, xuất báo cáo học vụ tự động, và tối ưu cho kỳ cao điểm bằng hàng đợi đăng ký."),
    ("pb",),

    # =================== TÀI LIỆU THAM KHẢO ===================
    ("h", 1, "TÀI LIỆU THAM KHẢO"),
    ("num", [
        "Giáo trình Hệ quản trị cơ sở dữ liệu — Trường Đại học Giao thông Vận tải TP. Hồ Chí Minh "
        "(bản đầy đủ lưu tại docs/reference/Giao_Trinh_He_Quan_Tri_Co_So_Du_Lieu).",
        "Mã nguồn hệ thống (GitHub): " + TCB,
        "Ứng dụng triển khai: " + TCB,
        "Tài liệu kỹ thuật MySQL 5.7 / 8.0 — InnoDB Locking and Transaction Model (dev.mysql.com).",
    ]),
]
