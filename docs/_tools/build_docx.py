# -*- coding: utf-8 -*-
"""Ghép toàn bộ nội dung -> file DOCX theo bố cục báo cáo PDF mẫu.

Chay:  python docs/_tools/build_docx.py
Output: <repo>/Đề tài 6 - HQTCSDL - Báo cáo cuối kỳ.docx
"""
from __future__ import annotations

import sys
from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.shared import Pt, Inches, RGBColor

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))

from docx_content_a import FRONT, CH1_2, CH_UC          # noqa: E402
from docx_content_b import CH3                          # noqa: E402
from docx_content_c import CH4                          # noqa: E402
from docx_content_d import CH5                          # noqa: E402

# ---------- tách FRONT: trước / sau trang THUẬT NGỮ ----------
idx = next(i for i, e in enumerate(FRONT)
           if e[0] == "h" and e[2].startswith("THUẬT NGỮ"))
FRONT_A, FRONT_B = FRONT[:idx], FRONT[idx:]

CONTENT = [("h", 1, "NỘI DUNG")] + CH1_2 + CH_UC + CH3 + CH4 + CH5
ALL_AFTER_TOC = FRONT_B + CONTENT   # phần thân sau các trang mục lục

# ---------- pass 1: đếm Hình / Bảng / mục lục ----------
hinh_list, bang_list, toc_entries = [], [], []
fig = bang = 0
for el in ALL_AFTER_TOC:
    if el[0] == "img":
        fig += 1
        hinh_list.append((fig, el[1]))
    elif el[0] == "tbl" and el[1]:
        bang += 1
        bang_list.append((bang, el[1]))
    elif el[0] == "h" and el[1] in (1, 2, 3):
        toc_entries.append((el[1], el[2]))
TOTAL_IMG, TOTAL_TBL = fig, bang

# ---------- builder ----------
doc = Document()
styles = doc.styles
normal = styles["Normal"]
normal.font.name = "Times New Roman"
normal.font.size = Pt(12)

def center(text, size, bold=False, italic=False):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run(text)
    r.bold = bold
    r.italic = italic
    r.font.size = Pt(size)
    return p

def fill_cell(cell, text, bold=False):
    lines = str(text).split("\n")
    cell.text = lines[0]
    for ln in lines[1:]:
        cell.add_paragraph(ln)
    for para in cell.paragraphs:
        for r in para.runs:
            r.bold = bold
            r.font.size = Pt(10.5)

def add_table(header, rows):
    t = doc.add_table(rows=1 + len(rows), cols=len(header))
    t.style = "Table Grid"
    for j, h in enumerate(header):
        fill_cell(t.rows[0].cells[j], h, bold=True)
    for i, row in enumerate(rows, start=1):
        for j, v in enumerate(row):
            fill_cell(t.rows[i].cells[j], v)
    doc.add_paragraph()

def render(el):
    k = el[0]
    if k in ("c13", "c14", "c16", "c18", "c22"):
        center(el[1], int(k[1:]) if False else {"c13": 13, "c14": 14, "c16": 16, "c18": 18, "c22": 22}[k])
    elif k in ("c13b", "c14b", "c16b", "c18b", "c22b"):
        center(el[1], {"c13b": 13, "c14b": 14, "c16b": 16, "c18b": 18, "c22b": 22}[k], bold=True)
    elif k == "cr":
        center(el[1], 12)
    elif k == "sp":
        for _ in range(el[1]):
            doc.add_paragraph()
    elif k == "pb":
        doc.add_page_break()
    elif k == "h":
        doc.add_heading(el[2], level=el[1])
    elif k == "p":
        doc.add_paragraph(el[1])
    elif k == "note":
        p = doc.add_paragraph()
        r = p.add_run(el[1])
        r.italic = True
        r.font.color.rgb = RGBColor(0x66, 0x66, 0x66)
    elif k == "dots":
        for _ in range(el[1]):
            p = doc.add_paragraph()
            p.add_run("." * 95)
    elif k == "img":
        global_fig[0] += 1
        p = center("[ CHÈN ẢNH VÀO ĐÂY ]", 12, bold=True, italic=True)
        center(f"Hình {global_fig[0]} – {el[1]}", 11, bold=False)
        doc.add_paragraph()
    elif k == "tbl":
        caption, header, rows = el[1], el[2], el[3]
        if caption:
            global_bang[0] += 1
            center(f"Bảng {global_bang[0]} – {caption}", 11)
        add_table(header, rows)
    elif k == "ul":
        for item in el[1]:
            doc.add_paragraph(item, style="List Bullet")
    elif k == "num":
        for i, item in enumerate(el[1], start=1):
            p = doc.add_paragraph(f"{i}. {item}")
            p.paragraph_format.left_indent = Inches(0.3)
    elif k == "sql":
        p = doc.add_paragraph()
        p.paragraph_format.left_indent = Inches(0.25)
        lines = el[1].split("\n")
        for i, ln in enumerate(lines):
            r = p.add_run(ln)
            r.font.name = "Consolas"
            r.font.size = Pt(10)
            if i < len(lines) - 1:
                r.add_break()
    else:
        raise ValueError("loai phan tu khong biet: " + repr(el[:2]))

global_fig = [0]
global_bang = [0]

# --- A) trang bìa + các trang đầu ---
for el in FRONT_A:
    render(el)

# --- B) MỤC LỤC + DANH MỤC HÌNH + DANH MỤC BẢNG ---
# ---------- lưu ----------
doc.add_heading("MỤC LỤC", level=1)  # khong dem vao danh sach hinh/bang
for lvl, title in toc_entries:
    prefix = {1: "", 2: "    ", 3: "        "}[lvl]
    p = doc.add_paragraph(prefix + title)
    p.paragraph_format.space_after = Pt(0)
p = doc.add_paragraph()
r = p.add_run("(Số trang của mục lục sẽ tự cập nhật chính xác khi bạn chèn "
              "References → Table of Contents trong bản Word hoàn chỉnh.)")
r.italic = True
doc.add_page_break()

center("DANH MỤC HÌNH ẢNH", 14, bold=True)
doc.add_paragraph()
for n, cap in hinh_list:
    p = doc.add_paragraph(f"Hình {n} - {cap}")
    p.paragraph_format.space_after = Pt(2)
doc.add_page_break()

center("DANH MỤC BẢNG BIỂU", 14, bold=True)
doc.add_paragraph()
for n, cap in bang_list:
    p = doc.add_paragraph(f"Bảng {n} - {cap}")
    p.paragraph_format.space_after = Pt(2)
doc.add_page_break()

# --- C) THUẬT NGỮ + NỘI DUNG + các chương ---
for el in ALL_AFTER_TOC:
    render(el)

# ---------- lưu ----------
OUT = ROOT / "Đề tài 6 - HQTCSDL - Báo cáo cuối kỳ.docx"
doc.save(str(OUT))
print("Đã tạo:", OUT)
print(f"Số hình placeholder : {TOTAL_IMG}")
print(f"Số bảng đánh số     : {TOTAL_TBL}")
print(f"Số mục mục lục      : {len(toc_entries)}")
print(f"Kích thước file     : {OUT.stat().st_size:,} bytes")

# kiem tra mo lai duoc
d2 = Document(str(OUT))
print(f"Mở lại OK — paragraphs={len(d2.paragraphs)}, tables={len(d2.tables)}")
