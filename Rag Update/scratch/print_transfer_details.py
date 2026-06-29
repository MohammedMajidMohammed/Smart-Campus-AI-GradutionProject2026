import json
import os
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# Print Page 4 of Bylaw A-1
path1 = 'processed_pdfs/لائحه جامعة المنوفية الأهليه A-1.pdf.json'
if os.path.exists(path1):
    print("=== Bylaw A-1 Page 4 ===")
    with open(path1, 'r', encoding='utf-8') as f:
        data = json.load(f)
        pages = data.get('pages', [])
        print(pages[3].get('text', ''))

# Print Page 9 of Medicine
path2 = 'processed_pdfs/طب وجراحه.pdf.json'
if os.path.exists(path2):
    print("=== Medicine Page 9 ===")
    with open(path2, 'r', encoding='utf-8') as f:
        data = json.load(f)
        pages = data.get('pages', [])
        print(pages[8].get('text', ''))
