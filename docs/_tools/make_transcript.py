"""Tao pdf_transcript.md: ban ghi duong dan theo trang, khong bi template HTML.

Day la 'retrieval store' — toi uu cho viec tim kiem theo trang hoac grep.
Noi dung giong hong pdf_raw.md nhung khong co cac dong template HTML va co
dau ```` ``` ```` hoac ```` ## ```` de dang duyet.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "docs" / "_extract" / "pdf_raw.md"
OUT = ROOT / "docs" / "reference" / "bao-cao-nhom-10-thu-vien" / "pdf_transcript.md"

text = SRC.read_text(encoding="utf-8")

# Tach theo mucl trang
pages = re.split(r"<!--\s*===== TRANG (\d+) =====\s*-->", text)
# pages[0] = phan truoc muc trang dau (rou), sau do [so_trang, noi_dung, ...]
assert pages[0].strip() == "", f"Expected empty prefix, got: {pages[0]!r}"
body_parts = [pages[i + 1].strip() for i in range(1, len(pages), 2)]
numbers = [pages[i] for i in range(1, len(pages), 2)]

lines: list[str] = []
lines.append("# Transcript verbatim — Báo cáo cuối kỳ Nhóm 10 (HQTCSDL)")
lines.append("")
lines.append("> **Nguồn:** `Nhóm 10 - HQTCSDL - Báo cáo cuối kỳ.pdf` — 78 trang.")
lines.append("> **Mô tả:** Bản ghi nguyên văn từng trang, đánh dấu theo số trang trong PDF.")
lines.append("> **Mục đích:** dùng để tra cứu/tìm kiếm nhanh; mọi ký tự đều giống PDF gốc.")
lines.append("")
lines.append("---")
lines.append("")

for num, body in zip(numbers, body_parts):
    n = int(num)
    lines.append(f"\n## Trang {n}\n")
    lines.append(body)
    lines.append("")

OUT.write_text("\n".join(lines).strip() + "\n", encoding="utf-8")
print(f"Đã ghi: {OUT}")
print(f"Số trang ghi: {len(body_parts)}")
print(f"Tổng ký tự: {sum(len(b) for b in body_parts)}")
