# extract_tables_ocr.py
"""Extract tables from the Arabic English & Translation curriculum PDF using OCR.

This script:
1. Converts each PDF page to an image (pdf2image).
2. Uses pytesseract (Arabic language) to OCR the whole page.
3. Splits the OCR text into lines and attempts to parse rows that look like "code, name, credits".
4. Saves each detected table as CSV and JSON.

Run:
    python extract_tables_ocr.py --input "path/to/لائحه برنامج اللغة الإنجليزية و الترجمة التخصصية.pdf" --output extracted_ocr_tables
"""

import argparse
import os
import json
import csv
from pathlib import Path


import pytesseract
import fitz
from PIL import Image




def ocr_page(image: Image.Image) -> str:
    """Run OCR on an image using Arabic language data.
    Returns the raw text.
    """
    # Ensure Arabic language pack is used (tesseract must have ara installed)
    return pytesseract.image_to_string(image, lang='ara')


def parse_table_lines(lines):
    """Parse lines that look like a table row.
    Expected format (comma separated): code, name, credits
    Returns list of rows.
    """
    rows = []
    for line in lines:
        # Clean whitespace and ignore empty lines
        line = line.strip()
        if not line:
            continue
        # Split by comma (Arabic comma may be used – keep simple split)
        parts = [p.strip() for p in line.split(',')]
        if len(parts) >= 3:
            code, name, credits = parts[0], parts[1], parts[2]
            rows.append([code, name, credits])
    return rows


def render_page(pdf_path, page_number, zoom=2):
    """Render a PDF page to a PIL Image using PyMuPDF.
    zoom controls scaling factor.
    """
    doc = fitz.open(pdf_path)
    page = doc.load_page(page_number)
    mat = fitz.Matrix(zoom, zoom)
    pix = page.get_pixmap(matrix=mat)
    img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
    return img


def save_table(rows, page_num, table_idx, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    csv_path = os.path.join(out_dir, f"page_{page_num:02d}_table_{table_idx:02d}.csv")
    json_path = os.path.join(out_dir, f"page_{page_num:02d}_table_{table_idx:02d}.json")
    with open(csv_path, "w", newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerows(rows)
    with open(json_path, "w", encoding='utf-8') as f:
        json.dump(rows, f, ensure_ascii=False, indent=2)
    return csv_path, json_path


def main():
    parser = argparse.ArgumentParser(description="OCR‑based table extraction for Arabic curriculum PDF.")
    parser.add_argument("--input", required=True, help="Path to the PDF file.")
    parser.add_argument("--output", default="extracted_ocr_tables", help="Directory to store extracted CSV/JSON files.")
    args = parser.parse_args()

    doc = fitz.open(args.input)
    summary = []
    for i in range(len(doc)):
        img = render_page(args.input, i)
        text = ocr_page(img)
        lines = text.split('\n')
        rows = parse_table_lines(lines)
        if rows:
            csv_path, json_path = save_table(rows, i+1, 1, args.output)
            summary.append({"page": i+1, "table_index": 1, "csv": csv_path, "json": json_path, "rows": len(rows)})
            print(f"Page {i+1}: extracted {len(rows)} rows → {csv_path}")
        else:
            print(f"Page {i+1}: no table detected.")
    # write summary
    summary_path = os.path.join(args.output, "summary.json")
    with open(summary_path, "w", encoding='utf-8') as f:
        json.dump(summary, f, ensure_ascii=False, indent=2)
    print(f"Extraction complete. Summary written to {summary_path}")

if __name__ == "__main__":
    main()
