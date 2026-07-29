# ĐẶC TẢ NGHIỆP VỤ ĐIỂM SỐ & KẾT QUẢ HỌC TẬP

> **Hệ thống:** Quản lý Đăng ký học phần Sinh viên  
> **Module:** Module 4 — Điểm số & Kết quả học tập (Thành viên 4)  
> **Tài liệu bàn giao:** `docs/analysis_diem_ketqua.md`  
> **Issue GitHub:** #7 (Phân tích nghiệp vụ Điểm số & Kết quả học tập)

---

## I. TỔNG QUAN VỀ NGHIỆP VỤ ĐIỂM SỐ & KẾT QUẢ HỌC TẬP

Module **Điểm số & Kết quả học tập** đóng vai trò ghi nhận, tính toán, và đánh giá toàn bộ quá trình học tập của sinh viên sau khi đã đăng ký học phần thành công ở Module 3.

Dữ liệu điểm số không chỉ phản ánh kết quả cá nhân của sinh viên trong từng lớp học phần mà còn là cơ sở dữ liệu đầu vào quan trọng để:
1. Tính điểm trung bình học kỳ (**GPA**) và điểm trung bình tích lũy (**CPA**).
2. Xếp loại học lực theo từng học kỳ và xếp loại tốt nghiệp toàn khóa.
3. Xét điều kiện **cảnh báo học vụ**, buộc thôi học hoặc hạ mức học lực.
4. Kiểm tra điều kiện môn học tiên quyết cho các đợt đăng ký học phần tiếp theo.
5. Làm căn cứ xét học bổng khuyến khích học tập hoặc miễn giảm học phí (liên kết Module 5).

---

## II. QUY ĐỊNH TRỌNG SỐ ĐIỂM THÀNH PHẦN

Mỗi lớp học phần đánh giá kết quả của sinh viên dựa trên **3 cột điểm thành phần** bắt buộc (thang điểm 10, tính chính xác đến 1 chữ số thập phân):

| Cột Điểm | Tên Viết Tắt | Trọng Số | Mô Tả |
|---|---|---|---|
| Điểm Chuyên Cần | `DiemChuyenCan` | **10%** ($0.10$) | Đánh giá mức độ tham gia lớp học, bài tập trên lớp |
| Điểm Giữa Kỳ | `DiemGiuaKy` | **30%** ($0.30$) | Kiểm tra giữa học kỳ hoặc bài tập lớn / tiểu luận |
| Điểm Cuối Kỳ | `DiemCuoiKy` | **60%** ($0.60$) | Thi kết thúc học phần (bắt buộc) |

### 1. Công thức tính Điểm Tổng Kết (Thang điểm 10)
$$\text{DiemTongKet} = (\text{DiemChuyenCan} \times 0.10) + (\text{DiemGiuaKy} \times 0.30) + (\text{DiemCuoiKy} \times 0.60)$$

* **Quy tắc làm tròn:** `DiemTongKet` được làm tròn đến **1 chữ số thập phân** (ví dụ: $7.84 \rightarrow 7.8$; $7.85 \rightarrow 7.9$).
* **Điều kiện bị điểm F cố định (Điểm liệt):** Nếu `DiemCuoiKy < 3.0` (hoặc bỏ thi cuối kỳ `DiemCuoiKy = 0`), sinh viên nhận điểm F học phần bất kể điểm chuyên cần và giữa kỳ cao đến đâu.

---

## III. QUY ĐỔI THANG ĐIỂM CHỮ VÀ HỆ 4 (THANG ĐIỂM CHUẨN)

Sau khi có `DiemTongKet` (thang 10), hệ thống tự động tra cứu bảng `THANGDIEMCHU` để quy đổi sang **Điểm chữ** và **Điểm hệ 4**.

Bảng quy đổi chuẩn áp dụng toàn hệ thống:

| Thang Điểm 10 (`DiemTongKet`) | Điểm Chữ (`DiemChu`) | Điểm Hệ 4 (`DiemHe4`) | Xếp Loại Học Phần | Đánh Giá Hợp Lệ |
|---|---|---|---|---|
| $8.5 \le \text{Điểm} \le 10.0$ | **A** | **4.0** | Xuất sắc | Đạt (Passed) |
| $7.8 \le \text{Điểm} \le 8.4$ | **B+** | **3.5** | Khá giỏi | Đạt (Passed) |
| $7.0 \le \text{Điểm} \le 7.7$ | **B** | **3.0** | Khá | Đạt (Passed) |
| $6.5 \le \text{Điểm} \le 6.9$ | **C+** | **2.5** | Trung bình khá | Đạt (Passed) |
| $5.5 \le \text{Điểm} \le 6.4$ | **C** | **2.0** | Trung bình | Đạt (Passed) |
| $4.8 \le \text{Điểm} \le 5.4$ | **D+** | **1.5** | Trung bình yếu | Đạt (Passed) |
| $4.0 \le \text{Điểm} \le 4.7$ | **D** | **1.0** | Yếu | Đạt (Passed) |
| $< 4.0$ | **F** | **0.0** | Kém | **Không đạt (Failing - Phải học lại)** |

* **Đăng ký học lại:** Những môn có `DiemChu = 'F'` không được tính chỉ số tích lũy đạt tín chỉ và sinh viên bắt buộc phải đăng ký học lại ở các học kỳ sau.

---

## IV. QUY TẮC TÍNH ĐIỂM TRUNG BÌNH (GPA & CPA) VÀ XẾP LOẠI HỌC LỰC

### 1. Công thức tính Điểm trung bình học kỳ (GPA - Grade Point Average)
GPA của một học kỳ được tính theo công thức trung bình trọng số tín chỉ:

$$\text{GPA} = \frac{\sum_{i=1}^{n} (\text{DiemHe4}_i \times \text{SoTinChi}_i)}{\sum_{i=1}^{n} \text{SoTinChi}_i}$$

*Trong đó:*
* $\text{DiemHe4}_i$: Điểm hệ 4 của môn học thứ $i$ trong học kỳ.
* $\text{SoTinChi}_i$: Số tín chỉ của môn học thứ $i$.
* $n$: Tổng số môn học sinh viên đăng ký học trong học kỳ đó.

### 2. Công thức tính Điểm trung bình tích lũy (CPA - Cumulative Point Average)
CPA được tính tương tự GPA nhưng tính trên **toàn bộ các môn học** sinh viên đã học từ đầu khóa đến thời điểm hiện tại (nếu học lại môn F thì lấy điểm mới nhất thay thế điểm cũ).

### 3. Quy chuẩn Xếp loại Học lực Sinh viên

| Thang Điểm GPA / CPA (Hệ 4) | Xếp Loại Học Lực |
|---|---|
| $3.60 \le \text{GPA/CPA} \le 4.00$ | **Xuất sắc** |
| $3.20 \le \text{GPA/CPA} < 3.60$ | **Giỏi** |
| $2.50 \le \text{GPA/CPA} < 3.20$ | **Khá** |
| $2.00 \le \text{GPA/CPA} < 2.50$ | **Trung bình** |
| $1.00 \le \text{GPA/CPA} < 2.00$ | **Yếu** |
| $< 1.00$ | **Kém** |

---

## V. QUY ĐỊNH VỀ CẢNH BÁO HỌC VỤ (ACADEMIC WARNING)

Cảnh báo học vụ được xử lý tự động cuối mỗi học kỳ nhằm phát hiện các sinh viên có kết quả học tập yếu kém để nhắc nhở hoặc đưa ra hình thức xử lý kỷ luật.

### 1. Điều kiện vi phạm Cảnh báo học vụ
Sinh viên bị **Cảnh báo học vụ cấp 1** hoặc **cấp 2** nếu vi phạm một trong các điều kiện sau:

1. **Theo điểm GPA học kỳ:**
   * Sinh viên năm thứ 1: $\text{GPA} < 1.00$
   * Sinh viên năm thứ 2: $\text{GPA} < 1.10$
   * Sinh viên năm thứ 3: $\text{GPA} < 1.20$
   * Sinh viên năm thứ 4 trở đi: $\text{GPA} < 1.30$
2. **Theo số tín chỉ nợ (Điểm F):**
   * Tổng số tín chỉ bị điểm F trong học kỳ $> 50\%$ tổng số tín chỉ đã đăng ký trong kỳ đó.
3. **Theo điểm tích lũy CPA:**
   * $\text{CPA} < 1.20$ đối với SV năm 1.
   * $\text{CPA} < 1.40$ đối với SV năm 2.
   * $\text{CPA} < 1.60$ đối với SV năm 3 trở đi.

### 2. Mức độ xử lý Cảnh báo học vụ
* **Cảnh báo lần 1 (Mức 1):** Gửi thông báo cảnh báo tới Sinh viên & Cố vấn học tập; giới hạn số tín chỉ đăng ký tối đa học kỳ sau ($\le 14$ tín chỉ).
* **Cảnh báo lần 2 liên tiếp (Mức 2):** Buộc giảm tải chương trình học, giới hạn đăng ký $\le 12$ tín chỉ.
* **Cảnh báo 3 lần liên tiếp (hoặc 2 lần liên tiếp ở mức nặng):** **Buộc thôi học (Tước quyền học tập)**.

---

## VI. RÀNG BUỘC NGHIỆP VỤ & KIỂM SOÁT TÍNH TOÀN VẸN DỮ LIỆU

1. **Ràng buộc Miền giá trị (Domain Constraint):**
   * Các cột `DiemChuyenCan`, `DiemGiuaKy`, `DiemCuoiKy`, `DiemTongKet` phải nằm trong đoạn $[0.0, 10.0]$.
2. **Ràng buộc Tham chiếu Đăng ký (FK Constraint):**
   * Chỉ được nhập điểm cho bộ `(MaSV, MaLHP)` đã tồn tại trong bảng `DANGKYHOCPHAN` với trạng thái `TrangThaiDangKy = 'DA_DANG_KY'`.
3. **Ràng buộc Quyền hạn & Thời gian (Access Control & Deadline):**
   * Giảng viên chỉ có quyền nhập/sửa điểm cho lớp học phần mình phụ trách (`GIANGVIEN.MaGV = LOPHOCPHAN.MaGV`).
   * Không được phép sửa điểm sau khi phòng Đào tạo đã thực hiện **Khóa sổ điểm học kỳ**.
