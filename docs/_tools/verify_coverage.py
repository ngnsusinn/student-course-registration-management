"""Kiem tra do phu: so trang, ky tu, trang rong, bien dem."""
import json
from pathlib import Path
from pypdf import PdfReader

ROOT = Path(__file__).resolve().parents[2]
PDF = ROOT / "Nhóm 10 - HQTCSDL - Báo cáo cuối kỳ.pdf"
TR = ROOT / "docs/reference/bao-cao-nhom-10-thu-vien/pdf_transcript.md"
JN = ROOT / "docs/_extract/pdf_pages.json"
RAW = ROOT / "docs/_extract/pdf_raw.md"
META = ROOT / "docs/reference/bao-cao-nhom-10-thu-vien/TRI_THUC_DAY_DU.md"

reader = PdfReader(str(PDF))
n_pages = len(reader.pages)
d = json.loads(JN.read_text(encoding="utf-8"))
page_count = d["page_count"]
pages = d["pages"]

# 1. So trang PDF vs JSON
assert n_pages == page_count == 78, (n_pages, page_count)

# 2. Dem ky tu tu PDF va tu transcript
pdf_chars = sum(len((p.extract_text() or "")) for p in reader.pages)
tr_chars = TR.stat().st_size
raw_chars = RAW.stat().st_size
meta_chars = META.stat().st_size
json_chars = sum(p["chars"] for p in pages)

# 3. Khong trang rong
empty = [p["page"] for p in pages if p["chars"] == 0]

# 4. Transcript co nhieu trang != 0
tr_text = TR.read_text(encoding="utf-8")
section_count = tr_text.count("## Trang ")

# 5. Metadata tri thuc co xuat day tat ca 8 bang
meta_text = META.read_text(encoding="utf-8")
tables_8 = ["THELOAI", "DAUSACH", "CUONSACH", "DOCGIA", "NHANVIEN",
            "PHIEUMUON", "CT_PHIEUMUON", "PHIEUPHAT"]
found_tables = sum(1 for t in tables_8 if t in meta_text)

print(f"{'='*60}")
print(f"KIEM TRA DO PHU")
print(f"{'='*60}")
print(f"So trang PDF            : {n_pages}")
print(f"So trang JSON           : {page_count}")
print(f"So trang transcript    : {section_count} (muc '## Trang')")
print(f"So trang rong (PDF)     : {len(empty)} {empty if empty else ''}")
print(f"Ky tu tu PDF            : {pdf_chars}")
print(f"Ky tu JSON total        : {json_chars}")
print(f"Ky tu raw.md            : {raw_chars}")
print(f"Ky tu transcript.md     : {tr_chars}")
print(f"Ky tu TRI_THUC_DAY_DU   : {meta_chars}")
print(f"8 bang DB duoc ghi      : {found_tables}/8")
print(f"{'='*60}")

# 6. Kiem tra moi trang truyen thuy van ban (bo khoang trang)
missing = []
tr_norm = tr_text.replace(" ", "")
for p in pages:
    n = p["page"]
    snippet = (p["text"] or "").strip()[:40].replace(" ", "")
    if snippet and snippet not in tr_norm:
        missing.append((n, snippet))
print(f"Trang khong tim thay trong transcript: {len(missing)}")
for m in missing[:5]:
    print(f"   trang {m[0]}: {m[1]!r}")

# 7. Cac chu de in PDF co xuat hien trong tri thuc khong
sections = ["Giới thiệu đề tài", "Use Case", "Module Xác thực",
            "Module Quản lý nhân sự", "Module Quản lý độc giả",
            "Module Quản lý thể loại", "Module Quản lý kho sách",
            "Module Nghiệp vụ", "Module Quản lý Tiền phạt",
            "Module Báo cáo", "Database", "Mô hình ERD",
            "Khóa chính", "Khóa ngoại", "Ràng buộc",
            "View", "Function", "Procedure", "Trigger",
            "Atomicity", "Consistency", "Isolation", "Durability",
            "Lost Update", "Dirty Read", "Non-repeatable Read",
            "Phantom", "Deadlock", "Giao diện hệ thống",
            "Kết luận", "TÀI LIỆU THAM KHẢO"]
print(f"\nCac chu de in PDF trong tri thuc:")
all_found = True
for s in sections:
    ok = s in meta_text
    if not ok: all_found = False
    print(f"  {'✓' if ok else '✗'} {s}")
print(f"\nTat ca chu de đều xuất hiện: {all_found}")

# 8. De xuat ky tu moi trang (max 20 chu) de xem dac
print(f"\nDem ky tu moi trang (min/max):")
char_counts = [p["chars"] for p in pages]
print(f"  min: {min(char_counts)} (trang {char_counts.index(min(char_counts))+1})")
print(f"  max: {max(char_counts)} (trang {char_counts.index(max(char_counts))+1})")
