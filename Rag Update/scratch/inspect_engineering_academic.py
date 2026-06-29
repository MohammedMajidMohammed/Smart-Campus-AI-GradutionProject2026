import os
import json
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

path = 'processed_pdfs/هندسه.pdf.json'
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
    pages = data.get('pages', [])
    # Let's print pages 9, 10, 65, 66 (0-indexed 8, 9, 64, 65)
    for idx in [8, 9, 64, 65]:
        if idx < len(pages):
            print(f"=== Page {idx+1} ===")
            print(pages[idx].get('text', ''))
