import json
import sys

# Fix Windows console encoding
sys.stdout.reconfigure(encoding='utf-8')

with open('processed_pdfs/لائحه برنامج اللغة الإنجليزية و الترجمة التخصصية.pdf.json', encoding='utf-8') as f:
    doc = json.load(f)

# اعرض الصفحات التي تحتوي على جداول المقررات (ص 9-14)
for p in doc['pages']:
    if p['page_number'] in [9, 10, 11, 12, 13, 14]:
        print(f"=== Page {p['page_number']} | has_tables={p.get('has_tables')} ===")
        print(p['text'][:1000])
        print()
