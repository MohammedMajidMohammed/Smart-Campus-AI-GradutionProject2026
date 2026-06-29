import os
import json
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

path = 'processed_pdfs/دليل_برامج_كلية_الحاسوب_والذكاء_الاصطناعى_جامعة_المنوفية_الاهلية.pdf.json'
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
    pages = data.get('pages', [])
    for p_idx in [3, 4, 5, 6, 7]: # Pages 4 to 8 (0-indexed 3 to 7)
        if p_idx < len(pages):
            print(f"=== PAGE {p_idx + 1} ===")
            print(pages[p_idx].get('text', ''))
