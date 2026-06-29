import json
import os
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

path = 'processed_pdfs/هندسه.pdf.json'
if os.path.exists(path):
    print("=== Engineering Pages 12 & 13 ===")
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        pages = data.get('pages', [])
        for idx in [11, 12]:
            print(f"--- Page {idx+1} ---")
            print(pages[idx].get('text', ''))
