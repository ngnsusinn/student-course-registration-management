# 📸 THƯ MỤC MINH CHỨNG CONCURRENCY — Issue #74

> Thư mục này lưu **ảnh/video** chứng minh kịch bản test 2 session đăng ký đồng thời vào lớp học phần sắp hết chỗ.

> 📌 **Cập nhật repo (tái cấu trúc MVC):** bộ script gốc `sql/` (SQL Server) đã được gỡ bỏ — toàn bộ kịch bản demo hiện hành chạy trên **MySQL**:
> kịch bản 2 cửa sổ `mysql/transactions/concurrency_test.sql`, 4 lỗi concurrency `mysql/transactions/demo_4_anomaly_2cua_so.sql`,
> demo tự động `backend/scripts/test-anomaly-live.mjs` + Concurrency Lab trên web. Tài liệu: `docs/concurrency/`.

## Nội dung cần minh chứng (bắt buộc)

| STT | Màn hình | Nội dung chứng minh |
|---|---|---|
| 1 | `01_trang_thai_truoc.png` | LHP501 = 24/25 (còn 1 chỗ), SV001 & SV002 chưa ĐK LHP501 |
| 2 | `02_phien_1_dang_khoa.png` | Phiên 1 (SV001) mở Transaction + UPDLOCK, đang giữ khóa dòng LHP501 |
| 3 | `03_phien_2_bi_cho.png` | Phiên 2 (SV002) đang **chờ lock** (dấu `...`) trong khi Phiên 1 chưa commit |
| 4 | `04_phien_1_commit.png` | Phiên 1 COMMIT thành công — SV001 lấy được chỗ cuối |
| 5 | `05_phien_2_bi_tu_choi.png` | Phiên 2 nhận mã lỗi **105** (lớp đã đầy) |
| 6 | `06_siso_cuoi.png` | Kiểm tra cuối: LHP501 = **25/25**, không vượt SiSoToiDa, SV002 không có bản ghi |
| 7 | `07_lost_update_demo.png` *(tùy chọn)* | Nếu chạy PHẦN E, chụp ảnh cho thấy sĩ số vượt 25 khi không dùng khóa |

## Hướng dẫn chụp minh chứng (2 cửa sổ mysql client / Workbench)

1. **Chuẩn bị:** Mở database trong **2 cửa sổ** kết nối (mysql client / MySQL Workbench).

2. **Cửa sổ 1 — chạy phần chuẩn bị (PHẦN A của `mysql/transactions/concurrency_test.sql`):**
   ```sql
   -- mở file mysql/transactions/concurrency_test.sql rồi chạy lần lượt từng PHẦN
   -- (bản gốc SQL Server với EXEC/:r đã gỡ khỏi repo khi tái cấu trúc)
   ```
   > Bôi đen từng PHẦN (A→F) rồi chạy: PHẦN A trước, sau đó PHẦN B → F.

3. **Cửa sổ 1:** bôi đen **PHẦN B** (Phiên 1 — SV001) → chạy. Bạn có **10 giây** để chuyển sang cửa sổ 2.

4. **Cửa sổ 2 (trong lúc Phiên 1 đang giữ khóa):** bôi đen **PHẦN C** (Phiên 2 — SV002) → chạy. Quan sát trạng thái **chờ lock** (ô phía dưới hiện "Executing query..."), chụp ảnh **màn hình 03**.

5. **Khi Phiên 1 commit xong**, Phiên 2 tự chạy tiếp và nhận mã **105**. Chụp ảnh **màn hình 04, 05**.

6. **Cửa sổ 1:** chạy **PHẦN D** → chụp ảnh **màn hình 06**.

7. Lưu tất cả ảnh vào thư mục này, đặt tên theo bảng trên.

## Gợi ý quay video (tùy chọn, cộng điểm)

* Dùng Windows Game Bar: `Win + G` → Record để quay toàn bộ thao tác 2 cửa sổ.
* Đặt tên `concurrency_demo.mp4` trong thư mục này (đã thêm vào `.gitignore` do dung lượng lớn).

## Checklist hoàn thành

- [ ] Ảnh `01..06` đã lưu đủ
- [ ] Trạng thái cuối `SiSoHienTai = SiSoToiDa = 25`
- [ ] Mã lỗi Phiên 2 = 105 (không phải 0)
- [ ] (Tùy chọn) Ảnh/ video demo Lost Update + Deadlock
