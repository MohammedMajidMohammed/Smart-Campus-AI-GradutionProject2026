import os
import json
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# File 1: general regulations page 9
path1 = 'processed_pdfs/لائحة الجامعة الأهلية.pdf.json'
if os.path.exists(path1):
    print("=== General Regulations Page 9 ===")
    with open(path1, 'r', encoding='utf-8') as f:
        data = json.load(f)
        pages = data.get('pages', [])
        if len(pages) >= 9:
            print(pages[8].get('text', ''))

# File 2: computer science guide page 16
path2 = 'processed_pdfs/دليل_برامج_كلية_الحاسوب_والذكاء_الاصطناعى_جامعة_المنوفية_الاهلية.pdf.json'
if os.path.exists(path2):
    print("=== Computer Science Guide Page 16 ===")
    with open(path2, 'r', encoding='utf-8') as f:
        data = json.load(f)
        pages = data.get('pages', [])
        if len(pages) >= 16:
            print(pages[15].get('text', ''))
