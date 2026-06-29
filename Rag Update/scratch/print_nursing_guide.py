import os
import json
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

path = 'processed_pdfs/دليل تمريض.pdf.json'
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
    pages = data.get('pages', [])
    for idx in [1, 2, 3]: # Page 2, 3, 4
        if idx < len(pages):
            print(f"=== PAGE {idx + 1} ===")
            print(pages[idx].get('text', ''))
