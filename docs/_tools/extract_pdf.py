"""Trich xuat toan bo text tu file bao cao PDF -> Markdown.

Chay:  python docs/_tools/extract_pdf.py
Output:
  docs/_extract/pdf_raw.md        - text tho theo tung trang (co so)
  docs/_extract/pdf_pages.json    - du lieu tung trang (metadata + text)
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parents[2]
PDF = ROOT / "Nhóm 10 - HQTCSDL - Báo cáo cuối kỳ.pdf"
OUT = ROOT / "docs" / "_extract"
OUT.mkdir(parents=True, exist_ok=True)


def clean(text: str) -> str:
    text = text.replace("\u00a0", " ").replace("\ufeff", "")
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    # ghep tu bi cat dong: "nghiep-\np" -> "nghiep-p"
    text = re.sub(r"-\n(?=\w)", "-", text)
    lines = [ln.rstrip() for ln in text.split("\n")]
    out: list[str] = []
    blank = 0
    for ln in lines:
        if ln.strip() == "":
            blank += 1
            if blank > 1:
                continue
        else:
            blank = 0
        out.append(ln)
    return "\n".join(out).strip()


def main() -> int:
    reader = PdfReader(str(PDF))
    meta = {}
    try:
        info = reader.metadata or {}
        for k, v in info.items():
            meta[str(k)] = str(v)
    except Exception as exc:  # pragma: no cover
        meta = {"error": str(exc)}

    pages = []
    raw_parts = []
    empty = 0
    for i, page in enumerate(reader.pages, start=1):
        try:
            text = clean(page.extract_text() or "")
        except Exception as exc:
            text = f"<<LOI TRICH XUAT TRANG {i}: {exc}>>"
        if not text:
            empty += 1
        pages.append({"page": i, "chars": len(text), "text": text})
        raw_parts.append(f"\n\n<!-- ===== TRANG {i} ===== -->\n\n{text}")

    (OUT / "pdf_raw.md").write_text("".join(raw_parts).strip() + "\n", encoding="utf-8")
    (OUT / "pdf_pages.json").write_text(
        json.dumps({"metadata": meta, "page_count": len(pages), "pages": pages},
                   ensure_ascii=False, indent=1),
        encoding="utf-8",
    )

    total = sum(p["chars"] for p in pages)
    print(f"PDF           : {PDF.name}")
    print(f"So trang      : {len(pages)}")
    print(f"Tong ky tu    : {total}")
    print(f"Trang rong    : {empty}")
    print("Metadata      :")
    for k, v in meta.items():
        print(f"  {k} = {v}")
    print("\n--- 5 trang dau (300 ky tu/trang) ---")
    for p in pages[:5]:
        print(f"\n[trang {p['page']}] {p['text'][:300]!r}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
