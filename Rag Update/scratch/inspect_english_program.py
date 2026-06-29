import json
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

path = 'processed_pdfs/لائحه برنامج اللغة الإنجليزية و الترجمة التخصصية.pdf.json'
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
    print("Total pages:", len(data.get('pages', [])))
    # print first 5 pages text
    for i in range(min(5, len(data.get('pages', [])))):
        print(f"--- Page {i+1} ---")
        print(data['pages'][i].get('text', '')[:1000])
