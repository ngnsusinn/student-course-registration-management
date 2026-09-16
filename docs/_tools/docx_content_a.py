# -*- coding: utf-8 -*-
"""Nội dung phần đầu: Trang bìa — đánh giá NV — cảm ơn — cam kết — nhận xét —
mục lục — hình — bảng — thuật ngữ — Chương 1, 2."""

TCB = "[Điền tên]"  # chỗ trống người dùng tự điền

FRONT = [
    # ---------------- TRANG BÌA ----------------
    ("c18b", "TRƯỜNG ĐẠI HỌC GIAO THÔNG VẬN TẢI TP. HỒ CHÍ MINH"),
    ("c16b", "VIỆN ĐÀO TẠO CHẤT LƯỢNG CAO"),
    ("c14", "———————◆———————"),
    ("sp", 1),
    ("c22b", "BÁO CÁO"),
    ("c18b", "HỆ QUẢN TRỊ CƠ SỞ DỮ LIỆU"),
    ("sp", 1),
    ("c16b", "ĐỀ TÀI:"),
    ("c16b", "HỆ THỐNG QUẢN LÝ SINH VIÊN ĐĂNG KÝ HỌC PHẦN TÍN CHỈ"),
    ("c14b", "(Đề tài 6)"),
    ("sp", 1),
    ("c14b", "Nhóm 5 thành viên"),
    ("sp", 1),
    ("c14", "Giảng viên: " + TCB),
    ("sp", 2),
    ("c14", "TP. Hồ Chí Minh, Ngày " + TCB + " Tháng " + TCB + " Năm " + TCB),
    ("sp", 1),
    ("c13", "1. " + TCB + " — " + TCB + ""),
    ("c13", "2. " + TCB),
    ("c13", "3. " + TCB),
    ("c13", "4. " + TCB),
    ("c13", "5. " + TCB),
    ("pb",),

    # ---------------- ĐÁNH GIÁ NHIỆM VỤ ----------------
    ("h", 1, "ĐÁNH GIÁ NHIỆM VỤ CỦA TỪNG THÀNH VIÊN TRONG NHÓM"),
    ("tbl", None,
     ["Họ và Tên", "Nhiệm vụ được giao", "Mức độ hoàn thành"],
     [
        [TCB + " (TV1)",
         "Làm báo cáo Word; Soạn nội dung phần Kiến trúc HQTCSDL & Độc lập dữ liệu; "
         "Phân tích – ERD – 3NF – DDL – SP/Trigger module Danh mục hệ thống & Hồ sơ sinh viên "
         "(KHOA, NGANH, LOP_SINHHOAT, SINHVIEN, CHUONGTRINHDAOTAO); làm backend; màn hình PĐT "
         "quản lý sinh viên, khoa-ngành-lớp.", "100%"],
        [TCB + " (TV2)",
         "Soạn nội dung phần Lưu trữ & Chỉ mục (Index); Phân tích – ERD – 3NF – DDL – "
         "Function/Trigger chặn trùng lịch – composite index module Học phần, Giảng viên & Mở lớp "
         "học phần (GIANGVIEN, MONHOC, MONHOC_TIENQUYET, HOCKY, PHONGHOC, LOPHOCPHAN, LICHHOC); "
         "làm backend; màn hình quản lý môn học/GV/mở LHP.", "100%"],
        [TCB + " (TV3 — nhóm trưởng)",
         "Soạn nội dung về các tính chất giao tác ACID và các trường hợp xảy ra lỗi xung đột, "
         "tranh chấp (Lost Update, Dirty Read, Non-repeatable Read, Phantom, Deadlock); Phân tích – "
         "ERD – 3NF – DDL bảng trung tâm DANGKYHOCPHAN; SP đăng ký 5 ràng buộc + Transaction + "
         "FOR UPDATE; demo 4 lỗi + deadlock trên MySQL remote; làm backend; màn hình đăng ký/hủy "
         "đăng ký cho sinh viên.", "100%"],
        [TCB + " (TV4)",
         "Soạn nội dung chức năng tổng quan hệ thống; Phân tích – ERD – 3NF – DDL module Điểm số "
         "& Kết quả học tập (KETQUAHOCTAP, THANGDIEMCHU); Trigger tự tính điểm tổng kết/chữ/hệ 4; "
         "SP GPA/CPA + cảnh báo học vụ; nhập điểm hàng loạt bằng con trỏ; màn hình bảng điểm SV, "
         "nhập điểm GV.", "100%"],
        [TCB + " (TV5)",
         "Soạn nội dung phần Phục hồi dữ liệu & Bảo mật; Phân tích – ERD – 3NF – DDL module Học "
         "phí, Tài khoản (HOCPHI, TAIKHOAN, VAITRO); SP tính/thu học phí có giao dịch; tạo tài khoản "
         "tự động; Trigger log đổi mật khẩu; phân quyền 3 vai trò; frontend React + dashboard thống "
         "kê; làm backend.", "100%"],
     ]),
    ("pb",),

    # ---------------- LỜI CẢM ƠN ----------------
    ("h", 1, "LỜI CẢM ƠN"),
    ("p", "Để hoàn thành bài báo cáo này, chúng em đã được sự hướng dẫn và hỗ trợ của Thầy/Cô "
          + TCB + ", Giảng viên Trường Đại học Giao thông Vận tải TP. Hồ Chí Minh."),
    ("p", "Chúng em gửi lời cảm ơn chân thành đến Thầy/Cô đã luôn hỗ trợ chúng em suốt quá trình "
          "làm đề tài. Trong quá trình học tập với Thầy/Cô, tuy thời gian không nhiều nhưng Thầy/Cô "
          "luôn nhiệt tình giảng dạy để chúng em biết thêm nhiều kiến thức hay, bổ ích về hệ quản trị "
          "cơ sở dữ liệu — từ thiết kế lược đồ, chuẩn hóa dữ liệu, truy vấn, lập trình cơ sở dữ liệu "
          "(View, Function, Procedure, Trigger) cho đến quản lý giao tác, điều khiển cạnh tranh và "
          "phục hồi dữ liệu. Thầy/Cô cũng giúp chúng em hiểu một hệ thống quản lý thực tế trong nhà "
          "trường vận hành như thế nào."),
    ("p", "Bài báo cáo này được chúng em chuẩn bị, nghiên cứu kỹ lưỡng và cố gắng hoàn thiện bằng "
          "tất cả năng lực của mình. Đôi khi vẫn còn nhiều thiếu sót, rất mong nhận được sự đánh giá "
          "và nhận xét quý báu của Thầy/Cô."),
    ("sp", 2),
    ("cr", "TP. Hồ Chí Minh, Ngày " + TCB + " Tháng " + TCB + " Năm " + TCB),
    ("cr", "Nhóm Sinh Viên Thực Hiện"),
    ("pb",),

    # ---------------- CAM KẾT ----------------
    ("h", 1, "TRANG CAM KẾT"),
    ("p", "Chúng em xin cam kết báo cáo này được hoàn thành dựa trên các kết quả nghiên cứu của "
          "chúng em và các kết quả nghiên cứu này chưa được dùng cho bất cứ báo cáo cùng cấp nào khác."),
    ("sp", 2),
    ("cr", "TP. Hồ Chí Minh, Ngày " + TCB + " Tháng " + TCB + " Năm " + TCB),
    ("cr", "Nhóm Sinh Viên Thực Hiện"),
    ("pb",),

    # ---------------- NHẬN XÉT GV ----------------
    ("h", 1, "NHẬN XÉT CỦA GIẢNG VIÊN"),
    ("dots", 22),
    ("sp", 2),
    ("cr", "TP. Hồ Chí Minh, Ngày " + TCB + " Tháng " + TCB + " Năm " + TCB),
    ("cr", "Chữ ký giảng viên"),
    ("pb",),

    # ---------------- THUẬT NGỮ VIẾT TẮT ----------------
    ("h", 1, "THUẬT NGỮ VIẾT TẮT"),
    ("tbl", None, ["STT", "Tiếng Anh", "Tiếng Việt", "Viết tắt"], [
        ["1", "Database Management System", "Hệ quản trị cơ sở dữ liệu", "DBMS / HQTCSDL"],
        ["2", "Database", "Cơ sở dữ liệu", "CSDL"],
        ["3", "Entity Relationship Diagram", "Sơ đồ thực thể liên kết", "ERD"],
        ["4", "Atomicity, Consistency, Isolation, Durability",
         "Tính nguyên tử, tính nhất quán, tính cô lập, tính bền vững", "ACID"],
        ["5", "Structured Query Language", "Ngôn ngữ truy vấn có cấu trúc", "SQL"],
        ["6", "Application Programming Interface", "Giao diện lập trình ứng dụng", "API"],
        ["7", "Representational State Transfer", "Kiến trúc thiết kế API theo tài nguyên", "RESTful"],
        ["8", "JavaScript Object Notation Web Token", "Mã xác thực người dùng dạng token", "JWT"],
        ["9", "Stored Procedure", "Thủ tục lưu trữ trong CSDL", "SP"],
        ["10", "User Interface / User Experience", "Giao diện / Trải nghiệm người dùng", "UI/UX"],
        ["11", "Student", "Sinh viên", "SV"],
        ["12", "Lecturer", "Giảng viên", "GV"],
        ["13", "Office of Training", "Phòng Đào tạo", "PĐT"],
        ["14", "Course Class (per semester subject group)", "Lớp học phần", "LHP"],
        ["15", "Grade Point Average (semester)", "Điểm trung bình học kỳ", "GPA"],
        ["16", "Cumulative GPA", "Điểm trung bình tích lũy", "CPA"],
        ["17", "Third Normal Form", "Dạng chuẩn hóa 3", "3NF"],
        ["18", "Timetable", "Thời khóa biểu", "TKB"],
        ["19", "Primary Key / Foreign Key", "Khóa chính / Khóa ngoại", "PK / FK"],
        ["20", "Transaction", "Giao tác (giao dịch)", "—"],
        ["21", "Deadlock", "Khóa chết (mù deadlock)", "—"],
        ["22", "Lost Update / Dirty Read / Non-repeatable Read / Phantom",
         "Mất dữ liệu cập nhật / Đọc rác / Không đọc lại được / Bóng ma", "—"],
    ]),
    ("pb",),
]

CH1_2 = [
    # =================== 1. GIỚI THIỆU ĐỀ TÀI ===================
    ("h", 1, "1. Giới thiệu đề tài"),
    ("p", "Trong bối cảnh các trường đại học chuyển sang đào tạo theo hệ thống tín chỉ, công tác "
          "quản lý đăng ký học phần của sinh viên phải xử lý khối lượng lớn thao tác đồng thời vào "
          "đầu mỗi học kỳ: hàng nghìn lượt sinh viên cùng tranh nhau suất trong các lớp học phần, "
          "trong khi hệ thống phải kiểm tra đồng thời nhiều ràng buộc nghiệp vụ (thời hạn đăng ký, "
          "môn tiên quyết, trùng lịch học, giới hạn tín chỉ, sĩ số lớp). Các phương pháp quản lý thủ "
          "công bằng sổ sách hoặc spreadsheet không còn đáp ứng được yêu cầu về tính chính xác, tốc "
          "độ xử lý cũng như khả năng mở rộng khi số lượng sinh viên, môn học và lớp học phần ngày "
          "càng tăng."),
    ("p", "Xuất phát từ nhu cầu thực tế đó, nhóm đã phát triển đề tài “Xây dựng hệ thống quản lý "
          "sinh viên đăng ký học phần tín chỉ”, nhằm tự động hóa toàn bộ vòng đời đào tạo tín chỉ: "
          "quản lý hồ sơ sinh viên và danh mục hệ thống (khoa, ngành, lớp sinh hoạt, chương trình "
          "đào tạo), quản lý môn học và mở lớp học phần kèm xếp lịch, nghiệp vụ đăng ký – hủy đăng "
          "ký học phần có kiểm tra ràng buộc, nhập điểm và tính GPA/CPA, quản lý học phí và vận hành "
          "tài khoản người dùng. Hệ thống giúp giảm thiểu sai sót trong khâu đăng ký, loại bỏ tính "
          "điểm thủ công, minh bạch học phí và cải thiện trải nghiệm cho cả sinh viên, giảng viên "
          "lẫn cán bộ đào tạo."),
    ("p", "Về mặt kỹ thuật, hệ thống được tổ chức thành các nhóm chức năng rõ ràng, tương ứng 5 "
          "module nghiệp vụ:"),
    ("ul", [
        "Module danh mục hệ thống & hồ sơ sinh viên — dữ liệu nền cho toàn hệ thống",
        "Module học phần, giảng viên & mở lớp học phần — môn học, tiên quyết, phòng học, kỳ học, "
        "xếp lịch",
        "Module đăng ký học phần (nghiệp vụ trung tâm) — 5 ràng buộc đăng ký + giao tác",
        "Module điểm số & kết quả học tập — nhập điểm, tự tính điểm tổng kết, GPA/CPA, cảnh báo học vụ",
        "Module học phí, tài khoản & vận hành — tính/thu học phí, tài khoản 3 vai trò, bảo mật",
    ]),
    ("p", "Kiến trúc hệ thống ba tầng theo chuẩn MVC: frontend là ứng dụng React 18 một trang "
          "(Vite, Material UI, Redux Toolkit) cùng công nghệ với portal đào tạo thật của trường; "
          "backend Node.js + Express cung cấp REST API với xác thực JWT, cấu trúc routes → "
          "controllers → models; toàn bộ truy vấn dữ liệu và MỌI GIAO TÁC được đóng gói trong tầng "
          "cơ sở dữ liệu MySQL — lớp ứng dụng chỉ gọi thủ tục lưu trữ, không viết SQL trực tiếp. "
          "Cách tổ chức “nghiệp vụ đặt trong database” giúp hệ thống đảm bảo tính nhất quán, dễ kiểm "
          "soát và phù hợp với các hệ thống backend hiện đại. Việc sử dụng View, Function, Stored "
          "Procedure, Trigger và Index giúp tối ưu hiệu năng, giữ dữ liệu đồng bộ và tự động hóa các "
          "nghiệp vụ quan trọng."),
    ("p", "Thông qua đề tài, nhóm không chỉ củng cố kiến thức về thiết kế hệ thống và cơ sở dữ "
          "liệu — phân tích nghiệp vụ, ERD, chuẩn hóa 3NF, lập trình SQL trên MySQL — mà còn trực "
          "tiếp triển khai và kiểm chứng các nội dung lý thuyết trọng tâm của môn học: tính chất "
          "ACID của giao tác, các anomaly khi nhiều người dùng thao tác đồng thời (lost update, "
          "dirty read, non-repeatable read, phantom), deadlock của hệ quản trị CSDL và các kỹ thuật "
          "phòng chống. Đây là nền tảng quan trọng để phát triển các hệ thống quản lý quy mô lớn hơn "
          "trong tương lai."),
    ("pb",),

    # =================== 2. CÁC CHỨC NĂNG CHÍNH ===================
    ("h", 1, "2. Các chức năng chính của hệ thống"),
    ("h", 2, "2.1. Use Case"),
    ("h", 3, "2.1.1. Sơ đồ Use Case tổng quát"),
    ("img", "Sơ đồ Use Case tổng quát"),
    ("h", 3, "2.1.2. Danh sách tác nhân"),
    ("p", "Use Case trên gồm 3 tác nhân chính là: Sinh viên, Giảng viên và Phòng Đào tạo."),
    ("tbl", "Các tác nhân của Use Case", ["Tác nhân", "Mô tả"], [
        ["Sinh viên (SV)",
         "Người dùng cuối của hệ thống: tra cứu các lớp học phần đang mở, đăng ký và hủy đăng ký "
         "học phần, xem thời khóa biểu, danh sách đăng ký, bảng điểm cá nhân, GPA/CPA và học phí."],
        ["Giảng viên (GV)",
         "Người phụ trách lớp học phần: xem danh sách lớp được phân công, xem thời khóa biểu và "
         "danh sách sinh viên trong lớp, nhập điểm (từng sinh viên hoặc hàng loạt), xem thống kê "
         "kết quả môn học."],
        ["Phòng Đào tạo (PĐT)",
         "Người quản trị hệ thống về mặt nghiệp vụ: quản lý hồ sơ sinh viên và toàn bộ danh mục "
         "(khoa, ngành, lớp, môn học, tiên quyết, giảng viên, phòng học, học kỳ, chương trình đào "
         "tạo), mở lớp học phần và xếp lịch, mở/đóng đợt đăng ký, quản lý học phí, quản lý tài khoản "
         "và xem thống kê – báo cáo toàn hệ thống."],
    ]),
    ("h", 3, "2.1.3. Danh sách Use Case"),
    ("tbl", "Các Use Case chính", ["STT", "Use Case", "Tác nhân chính", "Mô tả ngắn"], [
        ["1", "Đăng nhập / Đổi mật khẩu", "SV, GV, PĐT",
         "Người dùng đăng nhập bằng tài khoản và mật khẩu để sử dụng các chức năng được phân quyền; "
         "đổi mật khẩu có ghi nhật ký."],
        ["2", "Quản lý hồ sơ sinh viên", "PĐT",
         "Thêm, sửa, xóa sinh viên; chuyển lớp; tra cứu theo lớp, tên."],
        ["3", "Quản lý danh mục & chương trình đào tạo", "PĐT",
         "CRUD khoa, ngành, lớp sinh hoạt, môn học, môn tiên quyết, giảng viên, phòng học, học kỳ, "
         "chương trình đào tạo; mở/đóng đợt đăng ký."],
        ["4", "Mở lớp học phần & xếp lịch", "PĐT",
         "Tạo lớp học phần cho môn học trong kỳ, phân công giảng viên, xếp lịch phòng – thứ – tiết."],
        ["5", "Đăng ký học phần", "SV",
         "Đăng ký một hoặc nhiều lớp học phần đang mở; hệ thống kiểm tra 5 ràng buộc trong một giao "
         "tác và trả mã lỗi cụ thể nếu vi phạm."],
        ["6", "Hủy đăng ký", "SV",
         "Hủy lớp đã đăng ký trong thời hạn; cập nhật lại sĩ số."],
        ["7", "Tra cứu thời khóa biểu & danh sách đăng ký", "SV",
         "Xem thời khóa biểu cá nhân theo học kỳ, danh sách lớp đã đăng ký, tổng tín chỉ."],
        ["8", "Xem kết quả học tập", "SV",
         "Xem bảng điểm chi tiết, GPA học kỳ, CPA tích lũy, xếp loại và cảnh báo học vụ."],
        ["9", "Nhập điểm", "GV",
         "Nhập điểm chuyên cần, giữa kỳ, cuối kỳ cho từng sinh viên hoặc hàng loạt; điểm tổng kết, "
         "điểm chữ, điểm hệ 4 tự tính bằng Trigger."],
        ["10", "Theo dõi lớp phụ trách", "GV",
         "Xem danh sách lớp học phần được phân công, sinh viên trong lớp, thống kê kết quả môn học."],
        ["11", "Quản lý học phí", "PĐT, SV",
         "PĐT tính học phí theo tín chỉ, thu tiền (giao dịch kiểm tra số còn nợ), báo cáo thu theo "
         "kỳ/ngành; SV xem học phí của mình."],
        ["12", "Quản lý tài khoản & phân quyền", "PĐT",
         "Tạo tài khoản SV/GV tự động, khóa/mở khóa tài khoản, xử lý yêu cầu đặt lại mật khẩu, xem "
         "nhật ký đổi mật khẩu."],
        ["13", "Thống kê & báo cáo", "PĐT",
         "Dashboard tổng hợp toàn hệ thống: số SV, GV, môn học, lớp học phần, lượt đăng ký, báo cáo "
         "học phí, danh sách cảnh báo học vụ."],
    ]),
    ("h", 3, "2.1.4. Đặc tả Use Case"),
]

# --------- Đặc tả UC: mỗi UC một bảng 7 dòng như PDF ---------
def uc(title, tac_nhan, muc_tieu, tien, hau, luong, ngoai):
    return ("tbl", "Use Case " + title,
            ["Mục", "Nội dung"],
            [["Tên Use Case", title],
             ["Tác nhân", tac_nhan],
             ["Mục tiêu", muc_tieu],
             ["Tiền điều kiện", tien],
             ["Hậu điều kiện", hau],
             ["Luồng sự kiện chính", luong],
             ["Luồng ngoại lệ", ngoai]])

CH_UC = [
    ("p", "a. Đặc tả Use Case Đăng nhập / Đổi mật khẩu"),
    uc("Đăng nhập", "Sinh viên, Giảng viên, PĐT",
       "Cho phép người dùng đăng nhập vào hệ thống để sử dụng các chức năng theo quyền hạn của vai "
       "trò (MaVaiTro).",
       "Người dùng đã được PĐT tạo tài khoản trong bảng TAIKHOAN và tài khoản ở trạng thái ACTIVE.",
       "Người dùng đăng nhập thành công, nhận token JWT (hạn 12 giờ) và được chuyển đến dashboard "
       "theo vai trò.",
       "1. Người dùng mở màn hình đăng nhập.\n"
       "2. Người dùng nhập tên đăng nhập và mật khẩu.\n"
       "3. Hệ thống băm mật khẩu bằng SHA-256 và đối chiếu với bảng TAIKHOAN.\n"
       "4. Nếu hợp lệ và tài khoản đang mở, hệ thống cấp token JWT, lưu phiên đăng nhập và chuyển "
       "vào giao diện chính của vai trò đó.",
       "Nếu sai tài khoản hoặc mật khẩu, hệ thống trả lỗi 401 và yêu cầu nhập lại. Nếu tài khoản đã "
       "bị khóa (TrangThai = LOCKED), hệ thống trả lỗi 403. Chức năng “Quên mật khẩu?” tạo một yêu "
       "cầu đặt lại mật khẩu (bảng YEUCAU_DATLAI_MATKHAU, trạng thái CHO_XU_LY) để PĐT xử lý; không "
       "tiết lộ tài khoản có tồn tại hay không. Mọi lần đổi mật khẩu đều được Trigger ghi vào nhật "
       "ký đổi mật khẩu."),
    ("p", "b. Đặc tả Use Case Quản lý hồ sơ sinh viên"),
    uc("Quản lý hồ sơ sinh viên", "PĐT",
       "Cho phép PĐT quản lý thông tin sinh viên: thêm mới, cập nhật, xóa và chuyển lớp.",
       "PĐT đã đăng nhập. Lớp sinh hoạt và ngành của sinh viên đã tồn tại trong hệ thống.",
       "Thông tin sinh viên được cập nhật trong bảng SINHVIEN; sinh viên mới được tự động tạo tài "
       "khoản đăng nhập.",
       "1. PĐT chọn chức năng quản lý sinh viên.\n"
       "2. Hệ thống hiển thị danh sách sinh viên, cho lọc theo lớp và tìm theo tên.\n"
       "3. PĐT chọn thêm, sửa, xóa hoặc chuyển lớp.\n"
       "4. Hệ thống gọi thủ tục (SP_ThemSinhVien_Moi, SP_ChuyenLop_Nganh) kiểm tra dữ liệu.\n"
       "5. Hệ thống lưu thay đổi; khi thêm mới, tài khoản đăng nhập của sinh viên được tạo tự động.",
       "Nếu lớp sinh hoạt không tồn tại hoặc trùng mã sinh viên, hệ thống báo lỗi (mã 401–402). Nếu "
       "chuyển lớp sang lớp không tồn tại hoặc sinh viên không hợp lệ, hệ thống báo lỗi (mã 403–405) "
       "và không thực hiện thay đổi."),
    ("p", "c. Đặc tả Use Case Quản lý danh mục & chương trình đào tạo"),
    uc("Quản lý danh mục & chương trình đào tạo", "PĐT",
       "Cho phép PĐT thêm, sửa, xóa và xem các danh mục nền: khoa, ngành, lớp sinh hoạt, môn học, "
       "quan hệ tiên quyết, giảng viên, phòng học, học kỳ và chương trình đào tạo của ngành.",
       "PĐT đã đăng nhập.",
       "Dữ liệu danh mục được cập nhật; đợt đăng ký của học kỳ có thể được mở hoặc đóng.",
       "1. PĐT chọn chức năng danh mục tương ứng.\n"
       "2. Hệ thống hiển thị danh sách bản ghi.\n"
       "3. PĐT thực hiện thêm, sửa, xóa hoặc thay đổi trạng thái đợt đăng ký (TrangThaiDot MO/DONG).\n"
       "4. Hệ thống kiểm tra ràng buộc dữ liệu.\n"
       "5. Hệ thống lưu thay đổi vào CSDL.",
       "Nếu dữ liệu vi phạm ràng buộc (trùng tên khoa/ngành, trùng email, năm học ngoài khoảng cho "
       "phép…), hệ thống báo lỗi. Khi xóa ngành còn sinh viên theo học, Trigger "
       "TRG_XoaNganh_ChanKhiConSinhVien chặn thao tác và báo lỗi. Khi thêm môn học kèm danh sách môn "
       "tiên quyết, toàn bộ được ghi trong CÙNG MỘT GIAO TÁC — lỗi ở bất kỳ bước nào thì hủy hết."),
    ("p", "d. Đặc tả Use Case Mở lớp học phần & xếp lịch"),
    uc("Mở lớp học phần & xếp lịch", "PĐT",
       "Cho phép PĐT tạo lớp học phần của một môn học trong học kỳ, phân công giảng viên và xếp lịch "
       "học (phòng, thứ, tiết).",
       "PĐT đã đăng nhập. Môn học, học kỳ, giảng viên, phòng học đã tồn tại.",
       "Lớp học phần được tạo với trạng thái MO_DANG_KY kèm các dòng lịch học.",
       "1. PĐT chọn chức năng mở lớp học phần.\n"
       "2. PĐT chọn môn học, học kỳ, giảng viên, sĩ số tối đa.\n"
       "3. PĐT nhập các buổi học (phòng, thứ, tiết bắt đầu, số tiết).\n"
       "4. Hệ thống gọi SP_MoLopHocPhan kiểm tra giảng viên và phòng học không trùng lịch với lớp "
       "khác trong cùng khung giờ.\n"
       "5. Nếu hợp lệ, hệ thống tạo lớp và lưu lịch học.",
       "Nếu giảng viên hoặc phòng học đã có lịch trùng trong khung giờ, hệ thống báo lỗi và không "
       "tạo lớp. Mọi thao tác thêm lịch đều đi qua Trigger TRG_LICHHOC_BEFORE_INSERT/UPDATE chặn "
       "trùng phòng và trùng giảng viên cùng khung giờ ngay tại CSDL."),
    ("p", "e. Đặc tả Use Case Đăng ký học phần"),
    uc("Đăng ký học phần", "Sinh viên",
       "Cho phép sinh viên đăng ký một hoặc nhiều lớp học phần đang mở trong đợt đăng ký, với đầy đủ "
       "kiểm tra ràng buộc nghiệp vụ.",
       "Sinh viên đã đăng nhập. Học kỳ đang mở đợt đăng ký (TrangThaiDot = MO và thời điểm hiện tại "
       "trong khoảng [TuNgay, DenNgay]).",
       "Bản ghi đăng ký được tạo trong DANGKYHOCPHAN; sĩ số hiện tại của lớp tăng đúng 1 (Trigger tự "
       "cập nhật).",
       "1. Sinh viên xem danh sách lớp học phần đang mở (kèm sĩ số, lịch học, giảng viên, số tín "
       "chi đã đăng ký).\n"
       "2. Sinh viên chọn một lớp (hoặc tick nhiều lớp) rồi nhấn Đăng ký.\n"
       "3. Hệ thống chạy SP_DangKyHocPhan trong MỘT GIAO TÁC: kiểm tra đợt đăng ký, kiểm tra chưa "
       "đăng ký trùng lớp, kiểm tra môn tiên quyết (FN_KiemTraTienQuyet), kiểm tra trùng lịch học "
       "(FN_KiemTraTrungLichHoc), kiểm tra tổng tín chỉ không vượt giới hạn (FN_TinhTongTinChi), "
       "khóa dòng sĩ số bằng SELECT … FOR UPDATE và kiểm tra còn chỗ.\n"
       "4. Nếu qua hết 5 bước kiểm tra, hệ thống INSERT vào DANGKYHOCPHAN, Trigger cộng sĩ số, "
       "giao tác COMMIT.\n"
       "5. Hệ thống báo đăng ký thành công và cập nhật lại danh sách lớp.",
       "Tùy bước kiểm tra thất bại, hệ thống trả mã lỗi tương ứng: 100 ngoài thời hạn đăng ký; 101 "
       "đã đăng ký lớp này; 102 chưa hoàn thành môn tiên quyết; 103 trùng lịch học với lớp đã đăng "
       "ký; 104 vượt quá tín chỉ tối đa; 105 lớp đã đầy sĩ số; 106 lớp không tồn tại hoặc không mở "
       "đăng ký. Khi đăng ký nhiều lớp trong một giao dịch bằng con trỏ, nếu bất kỳ lớp nào lỗi thì "
       "TOÀN BỘ các lớp đã ghi trước đó được ROLLBACK — không tồn tại trạng thái đăng ký một phần."),
    ("p", "f. Đặc tả Use Case Hủy đăng ký"),
    uc("Hủy đăng ký", "Sinh viên",
       "Cho phép sinh viên hủy lớp học phần đã đăng ký trong thời hạn cho phép.",
       "Sinh viên đã đăng nhập và có bản ghi đăng ký trạng thái DA_DANG_KY.",
       "Bản ghi chuyển trạng thái DA_HUY; sĩ số hiện tại của lớp giảm 1 do Trigger tự cập nhật.",
       "1. Sinh viên mở màn hình hủy đăng ký.\n"
       "2. Hệ thống hiển thị danh sách lớp đang học.\n"
       "3. Sinh viên chọn lớp cần hủy và xác nhận.\n"
       "4. Hệ thống gọi SP_HuyDangKy kiểm tra điều kiện trong một giao tác.\n"
       "5. Hệ thống cập nhật trạng thái DA_HUY; Trigger trừ sĩ số.",
       "Nếu hủy ngoài thời hạn, hệ thống báo lỗi mã 200. Nếu không tìm thấy bản ghi đăng ký, báo lỗi "
       "mã 201. Nếu bản ghi không ở trạng thái ĐÃ ĐĂNG KÝ, báo lỗi mã 202."),
    ("p", "g. Đặc tả Use Case Tra cứu thời khóa biểu & danh sách đăng ký"),
    uc("Tra cứu thời khóa biểu & danh sách đăng ký", "Sinh viên",
       "Cho phép sinh viên xem thời khóa biểu cá nhân, danh sách lớp đã đăng ký và tổng tín chỉ theo "
       "học kỳ.",
       "Sinh viên đã đăng nhập.",
       "Hệ thống hiển thị kết quả tra cứu từ các view (VW_ThoiKhoaBieuCaNhan, "
       "VW_SinhVienDangKyChiTiet).",
       "1. Sinh viên chọn chức năng thời khóa biểu hoặc danh sách đăng ký.\n"
       "2. Sinh viên chọn học kỳ.\n"
       "3. Hệ thống truy vấn dữ liệu liên quan qua view.\n"
       "4. Hệ thống hiển thị lịch học theo thứ/tiết/phòng, giảng viên và tổng tín chỉ.",
       "Nếu học kỳ chưa có lớp nào đăng ký, hệ thống hiển thị thông báo không có dữ liệu."),
    ("p", "h. Đặc tả Use Case Xem kết quả học tập"),
    uc("Xem kết quả học tập", "Sinh viên",
       "Cho phép sinh viên xem bảng điểm chi tiết theo học kỳ, GPA học kỳ, CPA tích lũy, xếp loại và "
       "thông tin cảnh báo học vụ.",
       "Sinh viên đã đăng nhập; giảng viên đã nhập điểm (nếu chưa nhập, điểm hiển thị trống).",
       "Hệ thống hiển thị bảng điểm, GPA/CPA và xếp loại.",
       "1. Sinh viên mở màn hình bảng điểm, chọn học kỳ.\n"
       "2. Hệ thống hiển thị điểm chuyên cần, giữa kỳ, cuối kỳ, điểm tổng kết, điểm chữ, điểm hệ 4 "
       "của từng môn (view V_BANGDIEM_SINHVIEN).\n"
       "3. Hệ thống tính GPA học kỳ (SP_TinhGPA_HocKy) và CPA tích lũy (SP_TinhCPA_TichLuy — môn học "
       "lại lấy điểm cao nhất).\n"
       "4. Nếu CPA thấp dưới ngưỡng, hệ thống đánh dấu cảnh báo học vụ.",
       "Nếu không có điểm trong kỳ, hệ thống hiển thị thông báo phù hợp."),
    ("p", "i. Đặc tả Use Case Nhập điểm"),
    uc("Nhập điểm", "Giảng viên",
       "Cho phép giảng viên nhập điểm quá trình (chuyên cần), giữa kỳ và cuối kỳ cho sinh viên lớp "
       "mình phụ trách, từng sinh viên hoặc hàng loạt.",
       "Giảng viên đã đăng nhập và được phân công phụ trách lớp học phần.",
       "Điểm được lưu vào KETQUAHOCTAP; điểm tổng kết, điểm chữ và điểm hệ 4 được Trigger tự động "
       "tính theo công thức 10% chuyên cần + 30% giữa kỳ + 60% cuối kỳ.",
       "1. Giảng viên chọn lớp phụ trách.\n"
       "2. Hệ thống hiển thị danh sách sinh viên của lớp.\n"
       "3. Giảng viên nhập điểm cho từng em hoặc điền bảng hàng loạt rồi nhấn Lưu tất cả.\n"
       "4. Hệ thống kiểm tra giảng viên có quyền nhập điểm lớp đó (SP_GV_NHAP_DIEM).\n"
       "5. Hệ thống lưu điểm; Trigger TRG_KETQUAHOCTAP_BEFORE_INSERT/UPDATE tự tính điểm tổng kết, "
       "quy đổi điểm chữ và điểm hệ 4 theo bảng THANGDIEMCHU.",
       "Nếu cố nhập điểm cho lớp mình không phụ trách, hệ thống từ chối. Khi nhập hàng loạt bằng con "
       "trỏ (SP_GV_NhapDiemHangLoat), toàn bộ lớp được ghi trong MỘT GIAO TÁC: chỉ cần một dòng sai "
       "thì cả lô bị ROLLBACK, không có trạng thái nhập dở dang."),
    ("p", "j. Đặc tả Use Case Theo dõi lớp phụ trách"),
    uc("Theo dõi lớp phụ trách", "Giảng viên",
       "Cho phép giảng viên xem danh sách lớp học phần được phân công kèm thời khóa biểu, sĩ số và "
       "thống kê kết quả môn học.",
       "Giảng viên đã đăng nhập.",
       "Hệ thống hiển thị danh sách lớp và thống kê.",
       "1. Giảng viên mở chức năng Lớp của tôi, chọn học kỳ.\n"
       "2. Hệ thống hiển thị các lớp phụ trách kèm sĩ số và lịch học.\n"
       "3. Giảng viên chọn một lớp để xem danh sách sinh viên và bảng điểm.\n"
       "4. Hệ thống hiển thị thống kê kết quả môn học (view V_THONGKE_KETQUA_MONHOC).",
       "Nếu chưa được phân công lớp nào trong kỳ, hệ thống hiển thị thông báo trống."),
    ("p", "k. Đặc tả Use Case Quản lý học phí"),
    uc("Quản lý học phí", "PĐT (thu/tính) — Sinh viên (xem)",
       "Cho phép PĐT tính học phí theo số tín chỉ đã đăng ký, thu tiền và xem báo cáo thu; sinh viên "
       "xem học phí của mình.",
       "Sinh viên đã đăng ký học phần trong kỳ. PĐT đã đăng nhập để tính/thu.",
       "Bản ghi HOCPHI được tạo/cập nhật: Tổng tiền, Đã nộp, trạng thái.",
       "1. PĐT chạy tính học phí cho sinh viên theo kỳ: hệ thống lấy tổng tín chỉ đã đăng ký nhân "
       "đơn giá (SP_TinhHocPhi).\n"
       "2. Khi sinh viên nộp tiền, PĐT nhập số tiền thu; SP_ThuHocPhi chạy trong một giao dịch, "
       "kiểm tra còn nợ rồi cập nhật DaNop và trạng thái.\n"
       "3. PĐT xem báo cáo tổng thu theo học kỳ, theo ngành và danh sách nợ (các view "
       "VW_TongThuTheoHocKy, VW_TongThuTheoNganh, VW_SinhVienNoHocPhi).\n"
       "4. Sinh viên xem bảng học phí của mình: tổng tiền, đã nộp, còn nợ.",
       "Nếu thu vượt số còn nợ hoặc bản ghi không tồn tại, hệ thống báo lỗi mã 301–304."),
    ("p", "l. Đặc tả Use Case Quản lý tài khoản & phân quyền"),
    uc("Quản lý tài khoản & phân quyền", "PĐT",
       "Cho phép PĐT tạo tài khoản cho sinh viên/giảng viên, khóa hoặc mở khóa tài khoản, xử lý yêu "
       "cầu đặt lại mật khẩu và xem nhật ký đổi mật khẩu.",
       "PĐT đã đăng nhập.",
       "Tài khoản được tạo/chuyển trạng thái; lịch sử thay đổi được ghi nhận.",
       "1. PĐT mở màn hình quản lý tài khoản.\n"
       "2. PĐT chọn tạo tài khoản SV/GV (SP_TaoTaiKhoanSinhVien / SP_TaoTaiKhoanGiangVien — tự sinh "
       "tên đăng nhập, đặt mật khẩu mặc định đã băm).\n"
       "3. PĐT có thể khóa/mở khóa tài khoản (TrangThai ACTIVE/LOCKED).\n"
       "4. PĐT xem nhật ký đổi mật khẩu do Trigger ghi tự động và xử lý các yêu cầu đặt lại mật khẩu.",
       "Nếu trùng tên đăng nhập (ràng buộc UNIQUE trên TAIKHOAN.TenDangNhap), hệ thống báo lỗi và "
       "không tạo. Tài khoản bị khóa khi đăng nhập sẽ nhận thông báo từ chối."),
    ("p", "m. Đặc tả Use Case Thống kê & báo cáo"),
    uc("Thống kê & báo cáo", "PĐT",
       "Cho phép PĐT xem dashboard tổng hợp toàn hệ thống và các báo cáo nghiệp vụ.",
       "PĐT đã đăng nhập.",
       "Hệ thống hiển thị kết quả thống kê.",
       "1. PĐT mở dashboard.\n"
       "2. Hệ thống tổng hợp số lượng sinh viên, giảng viên, môn học, lớp học phần, lượt đăng ký "
       "theo kỳ, số thu học phí.\n"
       "3. PĐT chọn các báo cáo chi tiết: kết quả học tập theo môn, học phí theo kỳ/ngành, danh sách "
       "cảnh báo học vụ.\n"
       "4. Hệ thống hiển thị và cho phép xuất bảng dữ liệu sang Excel (CSV).",
       "Nếu không có dữ liệu thống kê, hệ thống hiển thị thông báo phù hợp."),
    ("pb",),

    # =================== 2.2 → 2.8 MODULE / API ===================
    ("h", 2, "2.2. Module Xác thực (Authentication)"),
    ("p", "Tách riêng khỏi hồ sơ người dùng, chuyên lo việc định danh và cấp quyền. Mật khẩu lưu ở "
          "dạng băm SHA-256; phiên làm việc dùng JWT hết hạn 12 giờ."),
    ("tbl", "Xác thực tài khoản", ["Chức năng", "HTTP Method", "Endpoint", "Body / Query"], [
        ["Đăng nhập hệ thống", "POST", "/auth/login", "{tenDangNhap, matKhau} → trả {token, user}"],
        ["Lấy thông tin tài khoản đang đăng nhập", "GET", "/auth/me", "JWT token trong Header"],
        ["Lấy hồ sơ cá nhân theo vai trò", "GET", "/auth/hoso", "JWT token trong Header"],
        ["Đổi mật khẩu", "POST", "/auth/doimatkhau", "{matKhauCu, matKhauMoi} — Trigger ghi nhật ký"],
    ]),
    ("h", 2, "2.3. Module Đăng ký học phần (/dangky) — Sinh viên"),
    ("p", "Đây là module trung tâm của hệ thống. Các endpoint đọc dùng View; endpoint ghi gọi thẳng "
          "các thủ tục chứa giao tác trong CSDL."),
    ("tbl", "Quản lý đăng ký học phần",
     ["Chức năng", "HTTP Method", "Endpoint", "Giải thích"], [
        ["Lấy học kỳ & đợt đăng ký hiện tại", "GET", "/dangky/hocky-hientai", "Đợt đang mở (MO)"],
        ["Danh sách lớp học phần đang mở", "GET", "/dangky/lopmo",
         "Kèm sĩ số còn trống, lịch học, giảng viên, thông tin tiên quyết, đã đăng ký hay chưa"],
        ["Đăng ký 1 học phần", "POST", "/dangky",
         "{MaLHP, MaxTinChi} → SP_DangKyHocPhan, trả mã lỗi 0/100–106"],
        ["Đăng ký nhiều học phần (1 giao dịch)", "POST", "/dangky/nhieu",
         "[MaLHP…] → SP_DangKyNhieuHocPhan dùng con trỏ khóa theo MaLHP tăng dần; lỗi bất kỳ ⇒ "
         "ROLLBACK cả lô; gặp deadlock 1213 được HQTCSDL phát hiện, SP tự retry"],
        ["Hủy đăng ký", "POST", "/dangky/huy", "{MaLHP} → SP_HuyDangKy, trả mã 0/200–202"],
        ["Danh sách đăng ký theo kỳ", "GET", "/dangky/danhsach?MaHocKy=", "View chi tiết đăng ký"],
        ["Thời khóa biểu cá nhân", "GET", "/dangky/thoikhoabieu?MaHocKy=", "View TKB"],
        ["Tổng tín chỉ đã đăng ký", "GET", "/dangky/tongtinchi?MaHocKy=", "Phục vụ kiểm tra giới hạn "
         "tín chỉ ngay trên màn hình"],
     ]),
    ("h", 2, "2.4. Module Điểm & Kết quả học tập (/ketqua)"),
    ("tbl", "Quản lý điểm và kết quả",
     ["Chức năng", "HTTP Method", "Endpoint", "Vai trò"], [
        ["Bảng điểm cá nhân theo kỳ", "GET", "/ketqua/bangdiem?MaHocKy=", "SV"],
        ["GPA học kỳ", "GET", "/ketqua/gpa?MaHocKy=", "SV"],
        ["CPA tích lũy + cảnh báo học vụ", "GET", "/ketqua/cpa", "SV"],
        ["Bảng thang điểm chữ (tra cứu)", "GET", "/ketqua/thangdiemchu", "Tất cả"],
        ["Thống kê kết quả môn học", "GET", "/ketqua/thongke-monhoc?MaLHP=", "GV / PĐT"],
        ["Danh sách sinh viên cảnh báo học vụ", "GET", "/ketqua/canhbao-hocvu", "PĐT"],
        ["GPA sinh viên trong lớp", "GET", "/ketqua/gpa-theo-lop/:MaLHP", "GV / PĐT"],
     ]),
    ("h", 2, "2.5. Module Học phí (/hocphi)"),
    ("tbl", "Quản lý học phí",
     ["Chức năng", "HTTP Method", "Endpoint", "Vai trò / Giải thích"], [
        ["Học phí của tôi", "GET", "/hocphi/cua-toi", "SV"],
        ["Danh sách học phí", "GET", "/hocphi/danhsach?TrangThai=&MaHocKy=", "PĐT"],
        ["Báo cáo tổng thu theo kỳ/ngành, nợ", "GET", "/hocphi/baocao", "PĐT — dùng view báo cáo"],
        ["Thu học phí", "POST", "/hocphi/thu",
         "PĐT — {MaHocPhi, SoTien} → SP_ThuHocPhi (giao dịch, mã 301–304)"],
        ["Tính học phí", "POST", "/hocphi/tinh",
         "PĐT — {MaSV, MaHocKy, DonGiaTinChi} → SP_TinhHocPhi"],
     ]),
    ("h", 2, "2.6. Module Giảng viên (/giangvien)"),
    ("tbl", "Chức năng dành cho giảng viên",
     ["Chức năng", "HTTP Method", "Endpoint", "Giải thích"], [
        ["Lớp tôi phụ trách theo kỳ", "GET", "/giangvien/lopcuatoi?MaHocKy=", "Kèm lịch học, sĩ số"],
        ["Danh sách sinh viên trong lớp", "GET", "/giangvien/sinhvien/:MaLHP", "Kèm điểm hiện có"],
        ["Nhập điểm 1 sinh viên", "POST", "/giangvien/nhapdiem", "→ SP_GV_NHAP_DIEM"],
        ["Nhập điểm hàng loạt cả lớp", "POST", "/giangvien/nhapdiem-hangloat",
         "{MaLHP, DanhSachDiem} → SP_GV_NhapDiemHangLoat — một giao dịch bằng con trỏ"],
     ]),
    ("h", 2, "2.7. Module Quản lý danh mục (/danhmuc)"),
    ("p", "PĐT quản lý (đọc/ghi); các vai trò khác chỉ đọc phục vụ tra cứu."),
    ("tbl", "Quản lý danh mục",
     ["Chức năng", "HTTP Method", "Endpoint", "Giải thích"], [
        ["Danh sách khoa / ngành / lớp / môn học / giảng viên / phòng / học kỳ / tiên quyết",
         "GET", "/danhmuc/{khoa, nganh, lop, monhoc, giangvien, phonghoc, hocky, tienquyet}", "Đọc"],
        ["CRUD từng danh mục", "POST / PUT / DELETE", "/danhmuc/{khoa, nganh, lop, monhoc, "
         "giangvien, phonghoc, hocky}", "Chỉ PĐT"],
        ["Chương trình đào tạo theo ngành", "GET / POST / DELETE", "/danhmuc/ctdt", "Chỉ PĐT"],
        ["Tra cứu sinh viên", "GET", "/danhmuc/sinhvien?MaLopSH=&tim=", "Chỉ PĐT"],
        ["Chuyển lớp sinh viên", "POST", "/danhmuc/sinhvien/chuyenlop", "→ SP_ChuyenLop_Nganh"],
        ["Cập nhật / xóa hồ sơ sinh viên", "PUT / DELETE", "/danhmuc/sinhvien/:MaSV", "Chỉ PĐT"],
        ["Thêm môn học kèm tiên quyết", "POST", "/danhmuc/monhoc-kem-tienquyet",
         "→ SP_ThemMonHocVaTienQuyet — một giao dịch cho môn + toàn bộ quan hệ tiên quyết"],
     ]),
    ("h", 2, "2.8. Module Quản trị hệ thống (/admin)"),
    ("tbl", "Chức năng quản trị (PĐT)",
     ["Chức năng", "HTTP Method", "Endpoint", "Giải thích"], [
        ["Dashboard thống kê tổng hợp", "GET", "/admin/thongke", "SV/GV/môn/LHP/lượt đăng ký"],
        ["Danh sách tất cả lớp học phần", "GET", "/admin/lophocphan?MaHocKy=&TrangThaiLop=", ""],
        ["Danh sách tài khoản", "GET", "/admin/taikhoan", ""],
        ["Khóa / mở khóa tài khoản", "PUT", "/admin/taikhoan/khoa", ""],
        ["Tạo tài khoản SV / GV", "POST", "/admin/taikhoan/sinhvien · /giangvien", "Tự động"],
        ["Nhật ký đổi mật khẩu", "GET", "/admin/nhatky-doimatkhau", "Do Trigger ghi tự động"],
        ["Mở lớp học phần + xếp lịch", "POST", "/admin/molophocphan", "→ SP_MoLopHocPhan"],
     ]),
    ("p", "Mã lỗi kinh doanh của hệ thống (trả kèm HTTP 400): đăng ký 100–106 · hủy đăng ký 200–202 "
          "· thu học phí 301–304 · thêm sinh viên 401–402 · chuyển lớp 403–405. Mã lỗi khóa của hệ "
          "quản trị CSDL (trả kèm HTTP 409 ở endpoint đăng ký nhiều lớp): 1213 ER_LOCK_DEADLOCK "
          "(deadlock — nạn nhân bị rollback) và 1205 ER_LOCK_WAIT_TIMEOUT (chờ khóa quá lâu)."),
    ("pb",),
]
