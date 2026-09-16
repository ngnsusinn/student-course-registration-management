# -*- coding: utf-8 -*-
"""Chương 4 — Các trường hợp lỗi hệ thống, xung đột, tranh chấp và cách xử lý.
Toàn bộ tình huống, số liệu và SQL lấy từ demo THẬT chạy trên MySQL remote
(docs/concurrency/, mysql/transactions/)."""

CH4 = [
    ("h", 1, "4. Các trường hợp lỗi hệ thống, xung đột, tranh chấp và cách hệ thống xử lý lỗi"),
    ("p", "Trong hệ thống quản lý đăng ký học phần, hàng trăm sinh viên có thể thao tác cùng lúc "
          "trên cùng một dữ liệu — đặc biệt vào đầu mỗi học kỳ: nhiều sinh viên cùng giành suất "
          "trong một lớp học phần, giảng viên nhập điểm trong khi sinh viên xem bảng điểm, nhiều "
          "giao dịch thu học phí cùng cập nhật một hóa đơn… Nếu hệ thống không kiểm soát tốt giao "
          "tác thì dữ liệu có thể bị sai lệch hoặc không nhất quán, dẫn đến các lỗi: mất dữ liệu cập "
          "nhật (Lost Update), đọc dữ liệu rác (Dirty Read), không đọc lại được dữ liệu "
          "(Non-repeatable Read), bóng ma (Phantom) và khóa chết (Deadlock). Các lỗi này ảnh hưởng "
          "trực tiếp đến sĩ số lớp, trạng thái đăng ký, kết quả học tập và học phí."),
    ("p", "Toàn bộ tình huống dưới đây được TÁI HIỆN VÀ ĐO THỰC TẾ trên cơ sở dữ liệu MySQL remote "
          "của hệ thống (MySQL 5.7.41, InnoDB) bằng hai cửa sổ SQL chạy song song, cộng với kịch bản "
          "hai trình duyệt thao tác thật trên giao diện. Mức cô lập mặc định của môi trường là "
          "REPEATABLE-READ; để nhìn thấy từng lỗi, ta chủ động “tắt” cơ chế phòng chống bằng mức cô "
          "lập thấp hơn hoặc bằng thủ tục chưa-fix."),
    ("note", "Ghi chú trình bày: các khối SQL hai cửa sổ dưới đây mô phỏng lịch giao tác T1/T2 đúng "
             "như thí nghiệm đã chạy. [CỬA SỔ 1] và [CỬA SỔ 2] được thực thi đồng thời, câu lệnh "
             "chạy theo thứ tự từ trên xuống."),

    # ---------------- 4.1 LOST UPDATE ----------------
    ("h", 2, "4.1. Lỗi mất dữ liệu cập nhật (Lost Update)"),
    ("h", 3, "4.1.1. Khái niệm"),
    ("p", "Mất dữ liệu cập nhật (Lost Update) xảy ra khi hai giao tác cùng đọc và cập nhật một dữ "
          "liệu, nhưng kết quả của giao tác này bị giao tác khác ghi đè hoặc làm mất. Dạng nguy hiểm "
          "nhất là “đọc–kiểm tra–rồi ghi”: cả hai cùng đọc, cùng thấy điều kiện còn hợp lệ, cùng ghi "
          "— kiểm tra của phiên trước mất tác dụng."),
    ("p", "Trong hệ thống quản lý đăng ký học phần, lỗi này xảy ra khi hai sinh viên cùng lúc giành "
          "nhau suất cuối cùng của một lớp học phần."),
    ("h", 3, "4.1.2. Tình huống xảy ra lỗi"),
    ("p", "Lớp học phần LHP514 (môn Kết cấu cao tầng, nhóm demo) đang có sĩ số 15/16 — còn đúng MỘT "
          "chỗ. Hai sinh viên SV030 và SV041 cùng bấm Đăng ký lớp này tại hai trình duyệt khác nhau, "
          "trong khi hệ thống đang chạy bản thủ tục chưa kiểm soát khóa — SP_DangKyHocPhan_ChuaFix "
          "(giữ nguyên 5 bước kiểm tra tiên quyết/lịch/tín chỉ, nhưng thiếu lệnh khóa dòng FOR "
          "UPDATE ở bước kiểm tra sĩ số)."),
    ("h", 3, "4.1.3. Trình bày lỗi trên hệ thống"),
    ("p", "[CỬA SỔ 1] — phiên của SV030:"),
    ("sql", "START TRANSACTION;\n"
            "SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';\n"
            "-- đọc KHÔNG khóa → thấy 15/16 (còn chỗ)\n"
            "DO SLEEP(10);   -- ⏸ giữ phiên 10 giây cho cửa sổ 2 chạy xen vào\n"
            "INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)\n"
            "VALUES ('SV030', 'LHP514', NOW(), 'DA_DANG_KY', 'Phien A - chua fix');\n"
            "COMMIT;"),
    ("p", "[CỬA SỔ 2] — phiên của SV041 (chạy trong lúc cửa sổ 1 đang SLEEP):"),
    ("sql", "START TRANSACTION;\n"
            "SELECT SiSoHienTai, SiSoToiDa FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';\n"
            "-- CŨNG thấy 15/16 → tưởng mình là người cuối cùng được nhận\n"
            "INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)\n"
            "VALUES ('SV041', 'LHP514', NOW(), 'DA_DANG_KY', 'Phien B - chua fix');\n"
            "COMMIT;"),
    ("p", "Lịch giao tác của hai phiên:"),
    ("tbl", "Lịch giao tác (Lỗi mất dữ liệu cập nhật)", ["T1 — Phiên A (SV030)", "T2 — Phiên B (SV041)"], [
        ["START TRANSACTION", ""],
        ["SELECT SiSoHienTai (không khóa) → 15", ""],
        ["", "START TRANSACTION"],
        ["", "SELECT SiSoHienTai (không khóa) → 15"],
        ["INSERT đăng ký SV030 (chưa COMMIT)", ""],
        ["", "INSERT đăng ký SV041 → bị chặn chờ khóa, đợi phiên A"],
        ["COMMIT → sĩ số 15 → 16", ""],
        ["", "được tiếp tục → trigger +1 → COMMIT"],
    ]),
    ("p", "Câu kiểm tra sau thí nghiệm:"),
    ("sql", "SELECT COUNT(*) AS SoDK_ThucTe,\n"
            "       (SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514') AS BoDem_SiSo,\n"
            "       (SELECT SiSoToiDa  FROM LOPHOCPHAN WHERE MaLHP='LHP514') AS SiSoToiDa\n"
            "FROM DANGKYHOCPHAN WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';\n"
            "-- KẾT QUẢ SAI (ghi nhận khi chạy demo): 17 lượt đăng ký thật > 16 chỗ; "
            "bộ đếm SiSoHienTai kẹt ở 16."),
    ("h", 3, "4.1.4. Kết quả"),
    ("p", "Kết quả sai khi xảy ra lỗi:"),
    ("ul", [
        "Lớp chỉ còn MỘT chỗ mà hai sinh viên cùng đăng ký thành công — lớp vượt sĩ số (17/16).",
        "Nghiêm trọng hơn, lỗi hỏng ÂM THẦM: vì trigger sĩ số dùng LEAST(SiSoToiDa, SiSoHienTai + 1) "
        "nên cột SiSoHienTai chỉ hiển thị đến 16 và “trông vẫn hợp lệ” — không ai phát hiện nếu chỉ "
        "nhìn màn hình, phải đối soát COUNT(*) thực tế mới thấy.",
        "Kết quả kiểm tra sĩ số của phiên A đã bị phiên B làm MẤT HIỆU LỰC — đúng bản chất Lost "
        "Update.",
    ]),
    ("p", "Kết quả đúng mong muốn (và là cách hệ thống bản chính thức đang hoạt động): thủ tục "
          "SP_DangKyHocPhan ở bước kiểm tra sĩ số khóa đúng dòng lớp học phần bằng SELECT … FOR "
          "UPDATE — tương đương UPDLOCK + HOLDLOCK trên SQL Server — giữ khóa tới khi COMMIT:"),
    ("sql", "-- BUOC 6 trong SP_DangKyHocPhan (bản chính thức):\n"
            "SELECT SiSoHienTai, SiSoToiDa INTO vSiSoHienTai, vSiSoToiDa\n"
            "FROM LOPHOCPHAN\n"
            "WHERE MaLHP = pMaLHP\n"
            "FOR UPDATE;              -- ★ khóa độc quyền dòng sĩ số tới khi COMMIT\n"
            "IF vSiSoHienTai >= vSiSoToiDa THEN\n"
            "    SET pKetQua = 105;   -- 'Lớp đã đầy sĩ số'\n"
            "END IF;"),
    ("p", "Khi đó phiên đến sau phải CHỜ phiên đang ghi hoàn tất, đọc lại giá trị SAU COMMIT, thấy "
          "lớp đã đầy và nhận mã lỗi 105 “Lớp đã đầy sĩ số”. Kịch bản hai cửa sổ đã kiểm chứng: "
          "SV001 và SV002 cùng giành chỗ cuối của LHP501 (24/25) — phiên gọi SP_DangKyHocPhan nhận "
          "@KetQua = 105, sĩ số cuối đúng 25/25, không vượt."),
    ("img", "Minh chứng demo Lost Update (bảng kết quả 2 cửa sổ: bản chưa-fix vượt sĩ số, bản fix "
            "trả mã 105)"),
    ("p", "Một biến thể Lost Update khác trên dữ liệu điểm số cũng được phân tích: giảng viên A mở "
          "phiếu điểm, đọc điểm cuối kỳ 4.5 của một sinh viên; cùng lúc chủ nhiệm B đọc 4.5 rồi lưu "
          "thành 5.0; khi A lưu 6.5 theo nhận xét của mình, kết quả của B bị ghi đè im lặng. Tài "
          "liệu thiết kế đề xuất giải pháp optimistic (kiểm tra phiên bản dòng trước khi ghi); bản "
          "hiện hành xử lý bằng cách đưa toàn bộ việc nhập điểm vào thủ tục có giao tác."),

    # ---------------- 4.2 DIRTY READ ----------------
    ("h", 2, "4.2. Lỗi đọc dữ liệu rác (Dirty Read)"),
    ("h", 3, "4.2.1. Khái niệm"),
    ("p", "Đọc dữ liệu rác (Dirty Read) xảy ra khi một giao tác đọc dữ liệu CHƯA ĐƯỢC XÁC NHẬN "
          "COMMIT từ giao tác khác. Nếu giao tác kia sau đó bị ROLLBACK, dữ liệu đã đọc trở thành dữ "
          "liệu không hợp lệ — giao tác đọc đã quyết định dựa trên một giá trị chưa từng tồn tại "
          "chính thức."),
    ("p", "Trong hệ thống, lỗi này có thể xảy ra khi một giao tác đăng ký/hủy đang cập nhật sĩ số "
          "nhưng chưa commit, trong khi sinh viên khác mở màn hình xem lớp (đọc SiSoHienTai để quyết "
          "định còn chỗ hay không)."),
    ("h", 3, "4.2.2. Tình huống xảy ra lỗi"),
    ("p", "Phiên B cập nhật sĩ số LHP514 từ 15 lên 16 trong một giao tác nhưng CHƯA COMMIT. Đúng lúc "
          "đó, phiên A — đặt ở mức cô lập READ UNCOMMITTED để tái hiện — đọc sĩ số của cùng lớp và "
          "nhìn thấy giá trị 16 “ma”. Sau đó phiên B gặp lỗi nghiệp vụ và ROLLBACK."),
    ("h", 3, "4.2.3. Trình bày lỗi trên hệ thống"),
    ("p", "[CỬA SỔ 1] — phiên ĐỌC (tắt phòng chống bằng mức cô lập thấp):"),
    ("sql", "SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;   -- ★ TẮT phòng chống\n"
            "START TRANSACTION;\n"
            "SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';\n"
            "-- → ĐỌC BẨN: thấy 16 (giá trị CHƯA COMMIT của phiên B)\n"
            "DO SLEEP(8);   -- ⏸ trong lúc này phiên B ROLLBACK\n"
            "SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';\n"
            "-- → 15: giá trị 'ma' biến mất\n"
            "ROLLBACK;\n"
            "SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;   -- trả về mặc định"),
    ("p", "[CỬA SỔ 2] — phiên GHI:"),
    ("sql", "START TRANSACTION;\n"
            "UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP = 'LHP514';\n"
            "-- ⏸ CHƯA COMMIT để cửa sổ 1 đọc…\n"
            "ROLLBACK;   -- giá trị 16 chưa từng tồn tại trong CSDL hợp lệ"),
    ("p", "Lịch giao tác:"),
    ("tbl", "Lịch giao tác (Lỗi đọc dữ liệu rác)", ["T1 — Phiên B (ghi)", "T2 — Phiên A (đọc, READ UNCOMMITTED)"], [
        ["UPDATE SiSoHienTai 15 → 16, chưa COMMIT", ""],
        ["", "SELECT SiSoHienTai → 16 ← ĐỌC BẨN"],
        ["", "(A quyết định 'lớp đã đầy' dựa trên 16)"],
        ["ROLLBACK — 16 chưa từng tồn tại", ""],
        ["", "SELECT lại → 15"],
    ]),
    ("h", 3, "4.2.4. Kết quả"),
    ("p", "Kết quả sai: phiên A từ chối cho sinh viên đăng ký vì tưởng lớp đã đầy — dựa trên một con "
          "số không bao giờ được commit. Mọi quyết định đưa ra từ dữ liệu rác đều vô giá trị khi "
          "giao tác nguồn rollback."),
    ("p", "Kết quả đúng mong muốn: ở mức cô lập mặc định REPEATABLE-READ của InnoDB, bản READ sử "
          "dụng MVCC snapshot — chỉ thấy các thay đổi ĐÃ COMMIT. Đo thực nghiệm: khi phiên B chưa "
          "commit thì phiên A đọc lại thấy đúng giá trị cũ 15; sau ROLLBACK giá trị vẫn là 15 — dữ "
          "liệu rác không thể lọt tới người đọc. Kiểm chứng nhanh môi trường: "
          "SELECT @@session.transaction_isolation → REPEATABLE-READ."),

    # ---------------- 4.3 NON-REPEATABLE READ ----------------
    ("h", 2, "4.3. Lỗi không đọc lại được dữ liệu (Non-repeatable Read)"),
    ("h", 3, "4.3.1. Khái niệm"),
    ("p", "Non-repeatable Read xảy ra khi một giao tác đọc cùng một dòng dữ liệu hai lần nhưng giữa "
          "hai lần đọc có giao tác khác cập nhật và COMMIT dữ liệu đó — hai lần đọc cho hai kết quả "
          "khác nhau trong cùng một giao tác."),
    ("p", "Trong hệ thống, lỗi này xảy ra khi một sinh viên mở màn hình danh sách lớp và đọc sĩ số "
          "LHP514 hai lần trong cùng một phiên làm việc, còn giữa hai lần đọc đó một giao tác khác "
          "đăng ký thành công và commit (sĩ số 15 → 16)."),
    ("h", 3, "4.3.2. Tình huống xảy ra lỗi"),
    ("p", "Phiên A (đọc) đặt mức READ COMMITTED — mức mà mỗi câu SELECT tạo một snapshot MỚI — rồi "
          "đọc sĩ số LHP514 hai lần trong cùng một giao tác. Phiên B cập nhật +1 và COMMIT giữa hai "
          "lần đọc."),
    ("h", 3, "4.3.3. Trình bày lỗi trên hệ thống"),
    ("p", "[CỬA SỔ 1] — phiên ĐỌC:"),
    ("sql", "SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;   -- ★ TẮT phòng chống\n"
            "START TRANSACTION;\n"
            "SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';  -- lần 1 → 15\n"
            "DO SLEEP(8);   -- ⏸ cửa sổ 2 UPDATE + COMMIT ngay lúc này\n"
            "SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP = 'LHP514';  -- lần 2 → 16 ≠ 15\n"
            "ROLLBACK;\n"
            "SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;"),
    ("p", "[CỬA SỔ 2] — phiên GHI:"),
    ("sql", "UPDATE LOPHOCPHAN SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLHP = 'LHP514';\n"
            "COMMIT;"),
    ("p", "Lịch giao tác:"),
    ("tbl", "Lịch giao tác (Lỗi không đọc lại được dữ liệu)", ["T1 — Phiên A (đọc, READ COMMITTED)", "T2 — Phiên B (ghi)"], [
        ["SELECT SiSoHienTai → 15", ""],
        ["", "UPDATE SiSoHienTai + 1; COMMIT"],
        ["SELECT SiSoHienTai → 16 (khác lần 1)", ""],
    ]),
    ("h", 3, "4.3.4. Kết quả"),
    ("p", "Kết quả sai: trong cùng một giao tác, cùng một ô dữ liệu cho hai giá trị khác nhau (15 rồi "
          "16). Nếu ứng dụng đọc sĩ số ở đầu rồi tính “còn bao nhiêu chỗ” ở cuối, hai con số không "
          "nhau sẽ làm quyết định sai — người dùng thấy báo cáo số liệu lệch nhau giữa hai lần đọc."),
    ("p", "Kết quả đúng mong muốn: ở mức REPEATABLE-READ mặc định, snapshot của MVCC được cố định từ "
          "lần đọc ĐẦU TIÊN của giao tác — đo thực nghiệm cho thấy phiên A đọc lần hai vẫn ra 15 dù "
          "phiên B đã UPDATE và COMMIT. Giao tác luôn làm việc với một ảnh chụp nhất quán."),

    # ---------------- 4.4 PHANTOM ----------------
    ("h", 2, "4.4. Bóng ma (Phantom Read)"),
    ("h", 3, "4.4.1. Khái niệm"),
    ("p", "Phantom xảy ra khi một giao tác đọc một TẬP BẢN GHI theo điều kiện nào đó, nhưng giao tác "
          "khác THÊM hoặc XÓA bản ghi làm thay đổi tập kết quả giữa hai lần đọc. Khác "
          "non-repeatable read (dữ liệu CŨ bị đổi giá trị), ở phantom các dòng cũ không đổi — mà tập "
          "dòng XUẤT HIỆN THÊM hoặc MẤT ĐI."),
    ("p", "Trong hệ thống, lỗi này thường xuất hiện ở các chức năng đếm/ thống kê: đếm số sinh viên "
          "đã đăng ký một lớp, tổng hợp tín chỉ, báo cáo sĩ số…"),
    ("h", 3, "4.4.2. Tình huống xảy ra lỗi"),
    ("p", "Phiên A (mức READ COMMITTED để tái hiện) đếm số lượt đăng ký đang hiệu lực của lớp LHP514 "
          "hai lần trong cùng một giao tác. Giữa hai lần đếm, phiên B chèn mới một bản ghi đăng ký "
          "của SV999 vào chính lớp đó và COMMIT. Lần đếm thứ hai của A nhảy thêm một “bóng ma”."),
    ("h", 3, "4.4.3. Trình bày lỗi trên hệ thống"),
    ("p", "[CỬA SỔ 1] — phiên ĐẾM:"),
    ("sql", "SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;   -- ★ TẮT phòng chống\n"
            "START TRANSACTION;\n"
            "SELECT COUNT(*) FROM DANGKYHOCPHAN\n"
            "WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';   -- lần 1 → 15\n"
            "DO SLEEP(8);                                             -- ⏸ phiên B INSERT + COMMIT\n"
            "SELECT COUNT(*) FROM DANGKYHOCPHAN\n"
            "WHERE MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';   -- lần 2 → 16\n"
            "ROLLBACK;\n"
            "SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;"),
    ("p", "[CỬA SỔ 2] — phiên GHI:"),
    ("sql", "INSERT INTO DANGKYHOCPHAN (MaSV, MaLHP, NgayDangKy, TrangThaiDangKy, GhiChu)\n"
            "VALUES ('SV999', 'LHP514', NOW(), 'DA_DANG_KY', 'dong bong ma');\n"
            "COMMIT;"),
    ("p", "Lịch giao tác:"),
    ("tbl", "Lịch giao tác (Lỗi bóng ma)", ["T1 — Phiên A (đọc, READ COMMITTED)", "T2 — Phiên B (ghi)"], [
        ["SELECT COUNT(*) → 15", ""],
        ["", "INSERT SV999 vào LHP514; COMMIT"],
        ["SELECT COUNT(*) → 16 (thêm 1 dòng bóng ma)", ""],
    ]),
    ("h", 3, "4.4.4. Kết quả"),
    ("p", "Kết quả sai: cùng một điều kiện đếm, cùng một giao tác, cho hai kết quả (15 rồi 16) chỉ "
          "vì người khác chèn dòng — số liệu “còn bao nhiêu chỗ trống” trong một phiên làm việc "
          "không ổn định."),
    ("p", "Kết quả đúng mong muốn — hệ thống có hai lớp phòng chống:"),
    ("ul", [
        "Mặc định REPEATABLE-READ: consistent snapshot giữ tập dòng cố định từ lần đọc đầu; đo thực "
        "nghiệm chạy lại đúng kịch bản nhưng giữ nguyên mức mặc định thì hai lần COUNT bằng nhau — "
        "dòng INSERT của phiên B vô hình với A trong suốt giao tác.",
        "Với thao tác ghi quyết định theo tập dòng (đăng ký giành chỗ): thủ tục dùng khóa dòng FOR "
        "UPDATE trên LOPHOCPHAN kết hợp INnoDB next-key/gap lock trên phạm vi liên quan — phiên khác "
        "không chèn thêm được vào phạm vi đang khóa cho tới khi phiên đang ghi COMMIT.",
    ]),

    # ---------------- 4.5 DEADLOCK ----------------
    ("h", 2, "4.5. Khóa chết (Deadlock)"),
    ("h", 3, "4.5.1. Khái niệm"),
    ("p", "Khóa chết (Deadlock) xảy ra khi từ hai giao tác trở lên GIỮ TÀI NGUYÊN mà giao tác khác "
          "cần và đồng thời CHỜ tài nguyên do giao tác còn lại giữ, tạo thành CHU TRÌNH chờ; không "
          "giao tác nào có thể tiếp tục. Deadlock chỉ xảy ra khi hội đủ đồng thời bốn điều kiện "
          "Coffman: loại trừ lẫn nhau, giữ-và-chờ, không tiếm quyền, và chờ vòng tròn."),
    ("p", "Trong hệ thống quản lý đăng ký học phần, deadlock có thể xảy ra khi hai sinh viên cùng lúc "
          "đăng ký NHIỀU lớp học phần nhưng thứ tự KHÓA các lớp không giống nhau — giao tác này đang "
          "giữ lớp kia chờ, giao tác kia đang giữ lớp này chờ."),
    ("h", 3, "4.5.2. Tình huống xảy ra lỗi"),
    ("p", "Tình huống 1 — đăng ký nhiều lớp ngược thứ tự: SV030 tick chọn hai lớp theo thứ tự LHP514 "
          "rồi LHP506; SV041 cũng tick đúng hai lớp đó nhưng NGƯỢC thứ tự (LHP506 trước, LHP514 sau), "
          "rồi cả hai bấm “Đăng ký N lớp đã chọn” gần như cùng lúc (LHP514 = 15/16, LHP506 = 1/2). "
          "Nếu thủ tục khóa các lớp THEO THỨ TỰ NGƯỜI DÙNG CHỌN, hai giao tác sẽ tạo vòng chờ "
          "khóa — đúng như lịch giao tác sau:"),
    ("tbl", "Lịch giao tác (Lỗi khóa chết)", ["T1 — Phiên SV030", "T2 — Phiên SV041"], [
        ["FOR UPDATE LHP514 ✅ giữ khóa", ""],
        ["", "FOR UPDATE LHP506 ✅ giữ khóa"],
        ["FOR UPDATE LHP506 → ⏳ chờ T2 nhả", ""],
        ["", "FOR UPDATE LHP514 → ⏳ chờ T1 nhả"],
        ["→ CHU TRÌNH chờ — DEADLOCK", ""],
    ]),
    ("p", "Tình huống 2 — LỖI THẬT được tìm thấy trong chính source của nhóm: đảo thứ tự khóa giữa "
          "ĐĂNG KÝ và HỦY. Thủ tục đăng ký (khi đăng ký lại một dòng từng hủy) khóa LOPHOCPHAN trước "
          "rồi mới đụng DANGKYHOCPHAN; trong khi thủ tục HỦY bản cũ khóa DANGKYHOCPHAN trước (SELECT "
          "… JOIN … FOR UPDATE) rồi mới cập nhật lớp (trigger chạm vào LOPHOCPHAN). Hai thao tác "
          "ngược chiều trên cùng cặp bản ghi tạo deadlock đúng nghĩa."),
    ("p", "Tình huống 3 — vòng tròn hai miền khóa: một giao tác giữ khóa dòng InnoDB, giao tác khác "
          "giữ khóa ứng dụng GET_LOCK; mỗi bên lại cần khóa của bên kia ở MIỀN KHÁC. Trường hợp này "
          "nguy hiểm nhất vì bộ phát hiện deadlock của InnoDB chỉ thấy đồ thị khóa trong miền của nó "
          "— điểm mù không thể tự phát hiện, chỉ còn timeout cắt."),
    ("h", 3, "4.5.3. Trình bày lỗi trên hệ thống"),
    ("p", "Thí nghiệm 1 — để HQTCSDL tự phát hiện (mặc định, chạy bằng thủ tục demo chuyên khóa theo "
          "thứ tự yêu cầu — chỉ khóa, không ghi dữ liệu):"),
    ("sql", "-- [CỬA SỔ 1]\n"
            "SET SESSION innodb_lock_wait_timeout = 20;\n"
            "CALL SP_Demo_KhoaTheoThuTu('SV030', 'LHP514,LHP506', 'THEO_YEU_CAU', 3, @kq1);\n"
            "-- [CỬA SỔ 2]\n"
            "SET SESSION innodb_lock_wait_timeout = 20;\n"
            "CALL SP_Demo_KhoaTheoThuTu('SV041', 'LHP506,LHP514', 'THEO_YEU_CAU', 3, @kq2);\n"
            "SELECT @kq1 AS MaLoi_CuaSo1, @kq2 AS MaLoi_CuaSo2;\n"
            "-- KẾT QUẢ: một phiên nhận 1213 (ER_LOCK_DEADLOCK — InnoDB chọn làm nạn nhân,\n"
            "--           tự ROLLBACK), phiên kia nhận 0 và hoàn tất."),
    ("p", "Thí nghiệm 2 — tái hiện deadlock THẬT từ cặp thủ tục đăng ký/hủy chưa thống nhất thứ tự "
          "khóa:"),
    ("sql", "CALL SP_Demo_PhienGiaoDich('DANG_KY_CHUA_FIX', 'SV030', 'LHP514', 3, @kq1);  -- cửa sổ 1\n"
            "CALL SP_Demo_PhienGiaoDich('HUY_CHUA_FIX',     'SV030', 'LHP514', 3, @kq2);  -- cửa sổ 2\n"
            "-- MỘT PHIÊN nhận 1213; phiên kia về 0/202.\n"
            "-- Chạy lại đúng kịch bản với tham số 'DANG_KY_DA_FIX' / 'HUY_DA_FIX' → KHÔNG CÒN 1213\n"
            "-- (bản fix: SP_HuyDangKy đã đổi sang khóa LOPHOCPHAN TRƯỚC khi chạm DANGKYHOCPHAN)."),
    ("p", "Thí nghiệm 3 — trên GIAO DIỆN WEB thật: hai trình duyệt của SV030 và SV041 cùng mở trang "
          "Đăng ký lớp học phần với bản thủ tục cố ý khóa theo thứ tự tick chọn "
          "(demo_deadlock_chuafix.sql); hai bạn tick cùng hai lớp NHƯNG NGƯỢC THỨ TỰ rồi bấm đăng ký "
          "gần đồng thời → một bạn nhận ngay thông báo đỏ trên màn hình: “Xung đột khóa (DEADLOCK "
          "1213): hệ quản trị CSDL đã hủy giao dịch của bạn để giải phóng deadlock. Vui lòng bấm đăng "
          "ký lại.”, bạn kia đăng ký thành công."),
    ("p", "Thí nghiệm 4 — khi KHÔNG có bộ phát hiện (tình huống hai miền khóa, mà ta cũng không thể "
          "tắt innodb_deadlock_detect trên hosting vì lệnh cần quyền SUPER bị từ chối bằng ERROR "
          "1227): hai phiên treo chờ lẫn nhau, PROCESSLIST hiển thị hai trạng thái chờ “User lock”/"
          "“statistics”, cả hai chỉ được giải thoát khi hết innodb_lock_wait_timeout — trải nghiệm "
          "thực tế là “màn hình quay mãi không xong, không thao tác được gì”."),
    ("h", 3, "4.5.4. Kết quả"),
    ("p", "Kết quả sai:"),
    ("ul", [
        "Không có cơ chế nào: hai giao tác chờ lẫn nhau VĨNH VIỄN (hoặc tới hết timeout mặc định "
        "50 giây) — toàn bộ nghiệp vụ trên các bản ghi đó bị tê liệt.",
        "Có bộ phát hiện (InnoDB mặc định): một giao tác bị chọn làm NẠN NHÂN và ROLLBACK — mất "
        "toàn bộ công việc đã làm của phiên đó; nếu ứng dụng không xử lý, người dùng nhận lỗi khó hiểu.",
    ]),
    ("p", "Cách hệ thống xử lý — kết hợp NGĂN NGỪA (chính) và CHẤP NHẬN + THỬ LẠI (lưới an toàn), "
          "bốn lớp:"),
    ("num", [
        "Phá điều kiện “chờ vòng tròn” bằng THỨ TỰ KHÓA NHẤT QUÁN: SP_DangKyNhieuHocPhan dùng con "
        "trỏ duyệt danh sách MaLHP đã sắp xếp TĂNG DẦN rồi khóa lần lượt từng dòng sĩ số; mọi giao "
        "tác đăng ký nhiều lớp đều khóa cùng một chiều → đồ thị chờ không thể thành vòng. SP_HuyDangKy "
        "được sửa để khóa LOPHOCPHAN TRƯỚC khi đọc DANGKYHOCPHAN — thống nhất thứ tự với thủ tục đăng "
        "ký. Đo thực nghiệm: hai phiên cùng tick ngược thứ tự nhưng chạy bản sửa → trả về 0 và 0, "
        "không phát sinh 1213.",
        "Giữ KHÓA NGẮN NHẤT CÓ THỂ: chỉ FOR UPDATE đúng một dòng sĩ số cần thiết, không nâng cả "
        "giao tác lên SERIALIZABLE — vừa đủ chống Lost Update vừa giảm vùng tranh chấp.",
        "Bọc TIMEOUT: innodb_lock_wait_timeout được đặt ngắn (≤ 10 giây trong demo) để nếu kẹt thì "
        "người dùng nhận mã 1205 rõ ràng thay vì treo vô hạn.",
        "BẮT LỖI 1213 VÀ THỬ LẠI: SP_DangKyHocPhan có vòng retry (REPEAT … UNTIL) tự chạy lại tối đa "
        "2 lần khi InnoDB báo deadlock; nếu vẫn thất bại, trả mã khóa 1213 cho ứng dụng; controller "
        "trả HTTP 409 kèm mã, frontend format.js dịch thành thông báo thân thiện hướng dẫn người dùng "
        "bấm đăng ký lại.",
    ]),
    ("p", "Kết quả đo thực tế của toàn bộ kịch bản deadlock: lỗi được phát hiện sau khoảng 0,5 giây; "
          "phiên nạn nhân rollback sau ~2.050 ms; trên web, phiên thua nhận HTTP 409 ketQua=1213 chỉ "
          "sau 48 ms, phiên thắng nhận ketQua=0. Chạy bộ kiểm thử E2E deadlock: 6/6 pha đúng kịch bản "
          "và 13/13 test PASS. Sĩ số các lớp KHÔNG thay đổi sau deadlock (các thủ tục demo chỉ khóa "
          "không ghi) — khác với Lost Update, deadlock không làm hỏng dữ liệu, chỉ phá khả năng xử "
          "lý — nên chiến lược rollback-retry hoàn toàn tự nhiên."),
    ("img", "Minh chứng demo Deadlock (2 cửa sổ SQL trả 1213/0 và thông báo đỏ trên giao diện web)"),
    ("note", "Kết luận lý thuyết rút ra từ tài liệu phân tích: InnoDB KHÔNG PHÒNG CHỐNG deadlock mà "
             "chỉ PHÁT HIỆN & DỌN HẬU QUẢ (chọn nạn nhân 1213) hoặc CẮT CHỜ (1205) — và có ĐIỂM MÙ "
             "với chu trình lồng hai miền khóa. Vì vậy ngăn ngừa bằng thứ tự khóa nhất quán phải là "
             "tuyến phòng thủ chính, chấp nhận + retry chỉ là lưới an toàn."),

    # ---------------- 4.6 CÁCH XỬ LÝ ----------------
    ("h", 2, "4.6. Cách hệ thống xử lý bằng transaction, trigger và rollback"),
    ("h", 3, "4.6.1. Xử lý bằng transaction"),
    ("p", "Transaction được dùng cho các nghiệp vụ gồm nhiều bước liên quan đến nhiều bảng. Nguyên "
          "tắc kiến trúc của hệ thống: MỌI GIAO TÁC ĐỀU NẰM BÊN TRONG STORED PROCEDURE — tầng backend "
          "chỉ CALL thủ tục, không raw query và không tự mở giao dịch (được kiểm chứng bằng script "
          "audit riêng). Các nghiệp vụ đang chạy trong một transaction:"),
    ("tbl", "Các nghiệp vụ được đóng gói trong một transaction", ["Nghiệp vụ", "Thủ tục", "Điểm giao tác"], [
        ["Đăng ký một lớp học phần", "SP_DangKyHocPhan", "5 bước kiểm tra + FOR UPDATE + ghi nhận, "
         "trả mã 0/100–106"],
        ["Đăng ký nhiều lớp một lần", "SP_DangKyNhieuHocPhan", "Con trỏ khóa MaLHP tăng dần; một lớp "
         "lỗi ⇒ ROLLBACK cả lô"],
        ["Hủy đăng ký", "SP_HuyDangKy", "Khóa lớp trước, cập nhật trạng thái; trigger tự −1 sĩ số; "
         "mã 200–202"],
        ["Nhập điểm cả lớp hàng loạt", "SP_GV_NhapDiemHangLoat", "Con trỏ từng dòng; một dòng sai ⇒ "
         "ROLLBACK cả lô"],
        ["Thu học phí", "SP_ThuHocPhi", "FOR UPDATE dòng hóa đơn, kiểm tra còn nợ trước khi ghi; mã "
         "301–304"],
        ["Thêm sinh viên + gán lớp + tạo tài khoản", "SP_ThemSinhVien_Moi", "Ba thao tác một giao "
         "tác; mã 401–402"],
        ["Thêm môn học + danh sách tiên quyết", "SP_ThemMonHocVaTienQuyet", "Môn và toàn bộ quan hệ "
         "tiên quyết cùng commit hoặc cùng rollback"],
        ["Mở lớp học phần + xếp lịch", "SP_MoLopHocPhan", "Tạo lớp + nhiều dòng lịch học; kiểm tra "
         "trùng GV/phòng"],
        ["Chuyển lớp sinh viên", "SP_ChuyenLop_Nganh", "Kiểm tra lớp đến hợp lệ rồi mới cập nhật; mã "
         "403–405"],
        ["Cập nhật hồ sơ SV chống xung đột", "SP_CapNhatHoSoSinhVien_Concurrency", "SELECT … FOR "
         "UPDATE đúng dòng SINHVIEN"],
    ]),
    ("p", "Ví dụ chuẩn — khi đăng ký một học phần, hệ thống thực hiện theo tuần tự:"),
    ("num", [
        "START TRANSACTION.",
        "Kiểm tra đợt đăng ký đang mở và đúng hạn (mã 100 nếu sai).",
        "Kiểm tra sinh viên chưa đăng ký lớp này (mã 101).",
        "Kiểm tra môn tiên quyết qua FN_KiemTraTienQuyet (mã 102).",
        "Kiểm tra trùng lịch học qua FN_KiemTraTrungLichHoc (mã 103).",
        "Kiểm tra tổng tín chỉ không vượt giới hạn qua FN_TinhTongTinChi (mã 104).",
        "SELECT … FOR UPDATE khóa dòng sĩ số; nếu đầy → mã 105.",
        "INSERT DANGKYHOCPHAN — Trigger tự động +1 sĩ số.",
        "Tất cả thành công → COMMIT; bất kỳ lỗi nào → ROLLBACK toàn bộ.",
    ]),
    ("p", "Về chọn mức cô lập: nhóm phân tích cả ba phương án — READ COMMITTED không đủ vì hai phiên "
          "có thể cùng đọc “còn chỗ”; SERIALIZABLE toàn cục quá rộng, tăng nguy cơ deadlock và giảm "
          "thông lượng; giải pháp chọn là giữ mức mặc định REPEATABLE-READ và TĂNG CƯỜNG ĐÚNG ĐIỂM "
          "NHẠY CẢM bằng khóa độc quyền một dòng (FOR UPDATE giữ tới COMMIT)."),
    ("h", 3, "4.6.2. Xử lý bằng trigger"),
    ("p", "Hệ thống sử dụng trigger để tự động kiểm tra và cập nhật dữ liệu trong các nghiệp vụ quan "
          "trọng, để mọi đường ghi — kể cả script tay — đều phải đi qua cùng một luật."),
    ("tbl", "Hệ thống xử lý bằng trigger", ["Trigger", "Vai trò xử lý"], [
        ["TRG_DANGKYHOCPHAN_AFTER_INSERT / _UPDATE / _DELETE",
         "Tự động ±1 SiSoHienTai của lớp học phần mỗi khi có đăng ký mới, đổi trạng thái hoặc xóa bản "
         "ghi — sĩ số luôn khớp tập đăng ký mà ứng dụng không cần (và không được phép) tự cộng"],
        ["TRG_KETQUAHOCTAP_BEFORE_INSERT / _UPDATE",
         "Tự động tính DiemTongKet = 10% chuyên cần + 30% giữa kỳ + 60% cuối kỳ, quy đổi điểm chữ và "
         "điểm hệ 4 theo THANGDIEMCHU; điểm cuối kỳ < 3.0 ⇒ F"],
        ["TRG_LICHHOC_BEFORE_INSERT / _UPDATE",
         "CHẶN lưu lịch học nếu phòng hoặc giảng viên đã có lớp khác trong cùng khung giờ — hiện thực "
         "hóa ràng buộc không thể khai báo bằng CHECK"],
        ["TRG_XoaNganh_ChanKhiConSinhVien",
         "CHẶN xóa ngành khi còn sinh viên thuộc ngành, kèm thông báo lỗi nghiệp vụ rõ ràng"],
        ["TRG_LogDoiMatKhau",
         "Mỗi lần MatKhau trong TAIKHOAN thay đổi, tự ghi một dòng vào NHATKY_DOIMATKHAU — truy vết "
         "an toàn mà ứng dụng không thể quên"],
    ]),
    ("p", "Lưu ý sư phạm rút ra từ chính demo: trigger sĩ số dùng LEAST(SiSoToiDa, SiSoHienTai + 1) "
          "nên nó chỉ chặn TRẦN hiển thị của bộ đếm, KHÔNG thể thay cho kiểm tra trong giao tác — "
          "minh chứng là bộ đếm “kẹt ở 16” trong khi thực tế đã 17 lượt đăng ký (mục 4.1.4). Trigger "
          "đảm bảo ĐỒNG BỘ dữ liệu phái sinh, còn ĐÚNG NGHIỆP VỤ dưới tranh chấp phải do khóa và "
          "giao tác bảo đảm."),
    ("h", 3, "4.6.3. Xử lý bằng rollback"),
    ("p", "Rollback được sử dụng khi một thao tác trong giao tác xảy ra lỗi; toàn bộ thay đổi chưa "
          "commit bị hủy. Ví dụ đã kiểm chứng thật trên hệ thống:"),
    ("sql", "-- SV060 đăng ký LHP514 nhưng chưa đạt môn tiên quyết:\n"
            "CALL SP_DangKyHocPhan('SV060', 'LHP514', 24, 'Test rollback', @rc3);\n"
            "SELECT @rc3;                       -- → 102 (chưa hoàn thành môn tiên quyết)\n"
            "SELECT COUNT(*) FROM DANGKYHOCPHAN\n"
            "WHERE MaSV='SV060' AND MaLHP='LHP514' AND TrangThaiDangKy='DA_DANG_KY';   -- → 0\n"
            "SELECT SiSoHienTai FROM LOPHOCPHAN WHERE MaLHP='LHP514';  -- sĩ số KHÔNG đổi"),
    ("p", "Kết quả: bản ghi đăng ký không được tạo, sĩ số không bị cộng, dữ liệu không rơi vào trạng "
          "thái nửa đúng nửa sai. Với SP_DangKyNhieuHocPhan, nếu một trong N lớp lỗi, biến tổng hợp "
          "chi tiết (dạng 'LHP514:OK; LHP506:105') cho biết lớp nào làm hỏng lô — và vì ROLLBACK, "
          "lớp 'OK' kia cũng KHÔNG được ghi. Với SP_GV_NhapDiemHangLoat, một dòng điểm ngoài [0,10] "
          "kích SIGNAL lỗi → EXIT HANDLER ROLLBACK rồi RESIGNAL — cả lớp không nhận phải một nửa số "
          "điểm."),
    ("h", 3, "4.6.4. Kiểm tra trạng thái trước khi cho phép đăng ký"),
    ("p", "Trong hệ thống hiện tại, một lượt đăng ký chỉ được ghi khi thỏa mãn ĐỒNG THỜI toàn bộ các "
          "điều kiện sau — được kiểm tra theo đúng thứ tự trong một giao tác, mỗi điều kiện gắn một "
          "mã lỗi để giao diện báo đúng nguyên nhân:"),
    ("tbl", "Bảng kiểm tra trạng thái trước khi đăng ký", ["#", "Điều kiện", "Cơ chế kiểm tra", "Mã lỗi", "Thông báo trên giao diện"], [
        ["1", "Lớp học phần tồn tại và đang mở đăng ký", "ĐỌC LOPHOCPHAN.TrangThaiLop = MO_DANG_KY",
         "106", "Lớp học phần không tồn tại hoặc không ở trạng thái mở đăng ký"],
        ["2", "Đợt đăng ký còn hiệu lực", "FN_KiemTraDotDangKy + HOCKY.TrangThaiDot='MO' và NOW() "
         "trong [TuNgay, DenNgay]", "100", "Rất tiếc! Hiện tại ngoài thời hạn đăng ký học phần của "
         "học kỳ này"],
        ["3", "Chưa đăng ký lớp này", "Kiểm tra không có bản ghi DA_DANG_KY của (MaSV, MaLHP)", "101",
         "Bạn đã đăng ký lớp học phần này rồi"],
        ["4", "Đã hoàn thành môn tiên quyết", "FN_KiemTraTienQuyet — mọi môn tiên quyết phải có điểm "
         "chữ khác F", "102", "Không thể đăng ký! Bạn chưa hoàn thành môn tiên quyết của môn học này"],
        ["5", "Không trùng lịch học", "FN_KiemTraTrungLichHoc — so thứ + khoảng tiết với các lớp đã "
         "đăng ký trong kỳ", "103", "Đăng ký thất bại! Lớp học phần bị trùng lịch học với lớp bạn đã "
         "đăng ký"],
        ["6", "Tổng tín chỉ trong giới hạn", "FN_TinhTongTinChi + số tín chỉ lớp ≤ MaxTinChi (mặc "
         "định 24)", "104", "Không thể đăng ký! Tổng số tín chỉ vượt quá giới hạn tối đa cho phép"],
        ["7", "Còn chỗ trong lớp (sau khi KHÓA dòng)", "SELECT … FOR UPDATE trên LOPHOCPHAN; "
         "SiSoHienTai < SiSoToiDa", "105", "Đăng ký thất bại! Lớp học phần đã đầy sĩ số (hết chỗ trống)"],
    ]),
    ("p", "Điều kiện hủy đăng ký cũng được kiểm tra tương ứng: còn trong hạn hủy (mã 200), bản ghi "
          "tồn tại (mã 201), đang ở trạng thái DA_DANG_KY (mã 202)."),
    ("h", 3, "4.6.5. Kiểm tra điều kiện sinh viên trước khi lập giao dịch"),
    ("p", "Trước khi ghi bất kỳ dữ liệu nào, thủ tục đăng ký còn chuẩn bị trạng thái an toàn cho sinh "
          "viên: nếu trước đó sinh viên từng ĐĂNG KÝ RỒI HỦY lớp này (dòng DA_HUY còn giữ lại vì khóa "
          "chính ghép không cho xóa–thêm trùng), hệ thống TÁI SỬ DỤNG dòng cũ bằng UPDATE đổi trạng "
          "thái về DA_DANG_KY thay vì INSERT — tránh vi phạm khóa chính (lỗi 1062) ngay trên luồng "
          "nghiệp vụ hợp lệ. Với đăng ký nhiều lớp, danh sách MaLHP được sắp tăng dần và loại bỏ "
          "trùng lặp trước khi mở con trỏ — chuẩn bị thứ tự khóa nhất quán."),
    ("h", 3, "4.6.6. Cập nhật tự động khi dữ liệu thay đổi"),
    ("p", "Khi một bản ghi đăng ký được thêm vào, đổi trạng thái hoặc xóa đi, trigger sẽ tự động xử "
          "lý dây chuyền:"),
    ("ul", [
        "Bản ghi DA_DANG_KY mới → SiSoHienTai của lớp +1.",
        "DA_DANG_KY chuyển thành DA_HUY → SiSoHienTai −1 (học phần được “giữ chỗ” tự động nhả ra).",
        "DA_HUY đăng ký lại (DA_DANG_KY) → SiSoHienTai +1.",
        "Điểm thành phần thay đổi → DiemTongKet, DiemChu, DiemHe4 được tính lại NGAY TRƯỚC khi ghi, "
        "không thể có bản điểm lệch công thức.",
        "Mật khẩu tài khoản đổi → một dòng nhật ký xuất hiện trong NHATKY_DOIMATKHAU.",
    ]),
    ("p", "Nhờ đó, sĩ số lớp, trạng thái đăng ký và điểm số luôn đồng bộ sau mọi thao tác; toàn bộ "
          "chuỗi trigger được kiểm thử tích hợp liên module (đăng ký → hủy → đăng ký lại → xóa; "
          "điểm → lịch học → ngành) với kết quả nhất quán."),
    ("pb",),
]
