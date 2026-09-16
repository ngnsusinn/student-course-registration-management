# KẾT QUẢ ĐO THỰC TẾ (raw — do công cụ `do_thuc_te.mjs` sinh ra)

- HQTCSDL: 11.8.9-MariaDB-ubu2404 · isolation mặc định = REPEATABLE-READ · deadlock_detect = 1 · lock_wait_timeout = 50s
- Kết nối: 0.tcp.ap.ngrok.io:21868 / roacqgfa_dbms

## M1.1 · CHƯA FIX — 2 phiên cùng đọc "còn 1 chỗ" rồi cùng ghi (LHP514)

```
   Xuất phát: LHP514 = 15/16 (COUNT=15)
   PHIÊN A đọc  : 15/16  →  INSERT SV030 (giữ khóa)
   PHIÊN B đọc  : 15/16  ← VẪN thấy "còn 1 chỗ" (snapshot cũ)
   PHIÊN B INSERT: CHỜ KHÓA 2.12s rồi mới chạy được
   KẾT QUẢ: sĩ số đếm thật = 17/16 · bộ đếm SiSoHienTai = 16
   ⇒ VƯỢT SĨ SỐ — TÁI HIỆN ĐƯỢC LỖI LOST UPDATE
```

`soLieu`: `{"maLHP":"LHP514","soDK":17,"siSoToiDa":16,"boDem":16,"choKhoaMs":2124}`

## M1.2 · ĐÃ FIX — khoá dòng sĩ số bằng SELECT … FOR UPDATE (cùng LHP514)

```
   PHIÊN A: SELECT … FOR UPDATE → 15/16  (giữ X-lock) rồi INSERT SV030
   PHIÊN B: SELECT … FOR UPDATE → CHỜ KHÓA 2.12s → sau khi A commit đọc được 16/16
   ⇒ điều kiện IF 16 >= 16 đúng ⇒ SP trả mã 105 "Lớp đã đầy sĩ số"
   KẾT QUẢ: 16/16 — KHÔNG vượt sĩ số
```

`soLieu`: `{"choKhoaMs":2115,"docDuoc":"16/16","soDK":16,"siSoToiDa":16}`

## M1.3 · ĐÃ FIX — qua thủ tục thật SP_DangKyHocPhan (LHP506 còn 1 chỗ)

```
   Xuất phát: LHP506 = 0/1
   @kqA (SV030) = 0  → lấy được suất cuối
   @kqB (SV041) = 105  → LỚP ĐÃ ĐẦY SĨ SỐ (bị từ chối đúng)
   KẾT QUẢ: 1/1 — một suất chỉ cấp cho đúng một sinh viên
```

`soLieu`: `{"kqA":0,"kqB":105,"soDK":1,"siSoToiDa":1}`

## M2.1 · CHƯA FIX — PHIÊN A hạ mức cô lập xuống READ COMMITTED

```
   PHIÊN A: SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;  ★ TẮT phòng chống
   PHIÊN A đọc lần 1 → 15
   PHIÊN B    : UPDATE SiSoHienTai + 1; COMMIT;   (15 → 16)
   PHIÊN A đọc lần 2 → 16   ← KHÁC lần 1 ⇒ TÁI HIỆN ĐƯỢC LỖI
   ⇒ cùng MỘT giao tác mà cùng một ô dữ liệu cho 2 giá trị khác nhau
```

`soLieu`: `{"lan1":15,"lan2":16,"chenhLech":1}`

## M2.2 · ĐÃ FIX — giữ mức mặc định REPEATABLE READ (MVCC snapshot)

```
   PHIÊN A: SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;  ★ giữ mặc định
   PHIÊN A đọc lần 1 → 15
   PHIÊN B    : UPDATE SiSoHienTai + 1; COMMIT;   (15 → 16 — đã commit thật)
   PHIÊN A đọc lần 2 → 15   ← GIỐNG lần 1 ⇒ ĐÃ CHẶN ĐƯỢC LỖI
   ⇒ snapshot được cố định từ lần đọc ĐẦU TIÊN của giao tác
```

`soLieu`: `{"lan1":15,"lan2":15,"giongNhau":true}`

## M2.3 · ĐÃ FIX (bổ sung) — khoá đọc bằng FOR UPDATE khi BẮT BUỘC cần giá trị mới nhất

```
   PHIÊN A: SELECT SiSoHienTai, SiSoToiDa … FOR UPDATE → 15/16 (giữ X-lock)
   PHIÊN B: UPDATE SiSoHienTai + 1 → BỊ CHẶN 1.73s cho tới khi A COMMIT rồi mới chạy
   ⇒ ghi của B không thể chen vào giữa 2 lần đọc của A
```

`soLieu`: `{"choKhoaMs":1734,"sauCung":"16/16"}`

## M3.1 · CHƯA FIX — PHIÊN A hạ mức cô lập xuống READ COMMITTED

```
   PHIÊN A: SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;  ★ TẮT phòng chống
   PHIÊN A đếm lần 1: COUNT(*) = 15
   PHIÊN B: INSERT SV999 vào LHP514; COMMIT;   (dòng "bóng ma")
   PHIÊN A đếm lần 2: COUNT(*) = 16   ← XUẤT HIỆN THÊM DÒNG ⇒ TÁI HIỆN ĐƯỢC LỖI
   ⇒ dòng A KHÔNG hề chèn lại xuất hiện trong tập kết quả của A
```

`soLieu`: `{"lan1":15,"lan2":16,"themDong":1}`

## M3.2 · ĐÃ FIX — giữ mức mặc định REPEATABLE READ (snapshot + next-key lock)

```
   PHIÊN A: SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;  ★ giữ mặc định
   PHIÊN A đếm lần 1: COUNT(*) = 15
   PHIÊN B: INSERT SV999 vào LHP514; COMMIT;   (đã ghi thật — kiểm tra lại thấy COUNT=16)
   PHIÊN A đếm lần 2: COUNT(*) = 15   ← KHÔNG ĐỔI ⇒ ĐÃ CHẶN ĐƯỢC LỖI
   ⇒ A vẫn làm việc trên một ảnh chụp nhất quán
```

`soLieu`: `{"lan1":15,"lan2":15,"khongDoi":true,"countThatSauCung":16}`

## M3.3 · ĐÃ FIX (bổ sung) — khoá PHẠM VI bằng SELECT … FOR UPDATE trên đúng tập đang đếm

```
   PHIÊN A: SELECT COUNT(*) … FROM DANGKYHOCPHAN WHERE MaLHP='LHP514' … FOR UPDATE  → COUNT = 15
   PHIÊN B: INSERT SV999 → BỊ CHẶN 2.63s (chờ tới khi A COMMIT)
   PHIÊN A đếm lại (trong cùng giao tác) → 15  ← KHÔNG ĐỔI
   KẾT QUẢ cuối sau khi cả hai commit: COUNT = 16
   ⇒ phiên khác KHÔNG THỂ chèn vào phạm vi mà A đang đọc (next-key/gap lock)
```

`soLieu`: `{"countA":15,"countA2":15,"insertChoMs":2626,"countCuoi":16}`

## M4.1 · CHƯA FIX — 2 phiên khoá 2 lớp theo thứ tự NGƯỢC NHAU (khoá theo yêu cầu)

```
   PHIÊN A: CALL SP_Demo_KhoaTheoThuTu('SV030','LHP514,LHP506','THEO_YEU_CAU',3,@kq1)
   PHIÊN B: CALL SP_Demo_KhoaTheoThuTu('SV041','LHP506,LHP514','THEO_YEU_CAU',3,@kq2)
   @kq1 = 0 · @kq2 = 1213
   ⇒ MỘT PHIÊN NHẬN 1213 (ER_LOCK_DEADLOCK) — InnoDB tự chọn nạn nhân & rollback
   Thời điểm phát hiện: ~6.89s sau khi bắt đầu
```

`soLieu`: `{"kq1":0,"kq2":1213,"phatHienMs":6889}`

## M4.2 · ĐÃ FIX — khoá theo thứ tự NHẤT QUÁN (con trỏ sắp MaLHP TĂNG DẦN)

```
   PHIÊN A: … 'SAP_XEP' … (A cũng khoá LHP506→LHP514 theo yêu cầu, nhưng con trỏ tự sắp lại)
   PHIÊN B: … 'SAP_XEP' …
   @kq1 = 0 · @kq2 = 0
   ⇒ CẢ HAI = 0 — KHÔNG còn deadlock (không thể hình thành chu trình chờ)
```

`soLieu`: `{"kq1":0,"kq2":0}`

## M4.3 · LỖI THẬT CỦA HỆ THỐNG — đảo thứ tự khoá giữa ĐĂNG KÝ và HỦY ĐĂNG KÝ

```
   PHIÊN A: SP_Demo_PhienGiaoDich('DANG_KY_CHUA_FIX','SV030','LHP514',3,@kq1)   [LOPHOCPHAN → DANGKYHOCPHAN]
   PHIÊN B: SP_Demo_PhienGiaoDich('HUY_CHUA_FIX','SV030','LHP514',3,@kq2)       [DANGKYHOCPHAN → LOPHOCPHAN]
   @kq1 = 1213 · @kq2 = 202   (1213 = deadlock, 202 = nghiệp vụ)
   ⇒ DEADLOCK sinh ra từ CHÍNH nghiệp vụ đăng ký/hủy của hệ thống
```

`soLieu`: `{"kq1":1213,"kq2":202}`

## M4.4 · ĐÃ FIX — SP_HuyDangKy khoá LOPHOCPHAN TRƯỚC (cùng thứ tự với SP_DangKyHocPhan)

```
   PHIÊN A: 'DANG_KY_DA_FIX' · PHIÊN B: 'HUY_DA_FIX'
   @kq1 = 0 · @kq2 = 0
   ⇒ KHÔNG còn 1213 — hai phiên nối tiếp nhau an toàn
```

`soLieu`: `{"kq1":0,"kq2":0}`

## Dọn dẹp

```
{"LHP514_DK":15,"LHP514_SiSo":15,"LHP514_ToiDa":16,"LHP506_DK":0,"LHP506_SiSo":0}
```
