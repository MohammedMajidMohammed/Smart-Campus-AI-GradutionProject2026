import json
import os
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# File 1: General regulations / bylaws page 40 & 41
path1 = 'processed_pdfs/لائحه جامعة المنوفية الأهليه A-1.pdf.json'
if os.path.exists(path1):
    print("=== Bylaw A-1 Pages 40 & 41 ===")
    with open(path1, 'r', encoding='utf-8') as f:
        data = json.load(f)
        pages = data.get('pages', [])
        for idx in [39, 40]:
            print(f"--- Page {idx+1} ---")
            print(pages[idx].get('text', ''))

# File 2: Engineering page 11
path2 = 'processed_pdfs/هندسه.pdf.json'
if os.path.exists(path2):
    print("=== Engineering Page 11 ===")
    with open(path2, 'r', encoding='utf-8') as f:
        data = json.load(f)
        pages = data.get('pages', [])
        print(pages[10].get('text', ''))
