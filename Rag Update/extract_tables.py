# extract_tables.py
"""Extract tabular data from the English & Translation curriculum PDF.

The script processes each page, detects tables with OpenCV, runs OCR on each cell,
assembles rows, and saves the result as CSV and JSON files under `extracted_tables/`.
It can be run as:
    python extract_tables.py --input "path/to/لائحه برنامج اللغة الإنجليزية و الترجمة التخصصية.pdf" --output extracted_tables/

Dependencies: pdf2image, opencv-python, pandas, pytesseract, numpy.
"""

# extract_tables.py
"""Extract tabular data from the English & Translation curriculum PDF using pdfplumber.

The script processes each page, extracts tables with pdfplumber, and saves them as CSV and JSON
files under `extracted_tables/`. It can be run as:
    python extract_tables.py --input "path/to/لائحه برنامج اللغة الإنجليزية و الترجمة التخصصية.pdf" --output extracted_tables/
"""

import argparse
import os
import json
import pandas as pd
import pdfplumber


def extract_tables_from_page(page):
    """Return a list of tables from a pdfplumber page.
    Each table is a list of rows, where each row is a list of cell strings.
    """
    tables = page.extract_tables()
    return tables if tables else []


def save_table(table, page_num, table_idx, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    csv_path = os.path.join(out_dir, f"page_{page_num:02d}_table_{table_idx:02d}.csv")
    json_path = os.path.join(out_dir, f"page_{page_num:02d}_table_{table_idx:02d}.json")
    df = pd.DataFrame(table)
    df.to_csv(csv_path, index=False, header=False)
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(table, f, ensure_ascii=False, indent=2)
    return csv_path, json_path


def main():
    parser = argparse.ArgumentParser(description="Extract tables from curriculum PDF.")
    parser.add_argument("--input", required=True, help="Path to the PDF file.")
    parser.add_argument("--output", default="extracted_tables", help="Directory to store CSV/JSON files.")
    args = parser.parse_args()

    summary = []
    with pdfplumber.open(args.input) as pdf:
        for i, page in enumerate(pdf.pages, start=1):
            tables = extract_tables_from_page(page)
            if not tables:
                print(f"Page {i}: no table detected.")
                continue
            for idx, table in enumerate(tables, start=1):
                csv_path, json_path = save_table(table, i, idx, args.output)
                summary.append({"page": i, "table_index": idx, "csv": csv_path, "json": json_path, "rows": len(table)})
                print(f"Page {i} Table {idx}: extracted {len(table)} rows -> {csv_path}")
    # Write a summary file
    summary_path = os.path.join(args.output, "summary.json")
    with open(summary_path, "w", encoding="utf-8") as f:
        json.dump(summary, f, ensure_ascii=False, indent=2)
    print(f"Extraction complete. Summary written to {summary_path}")

if __name__ == "__main__":
    main()



