import os
import json
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

path = 'processed_pdfs/لائحة الجامعة الأهلية.pdf.json'
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
    pages = data.get('pages', [])
    for idx, p in enumerate(pages):
        text = p.get('text', '')
        if any(kw in text for kw in ['التحويل', 'تحويل', 'تحويل الطالب', 'جامعة اخرى', 'جامعة أخرى', 'الرغبات']):
            print(f"Page {idx+1}:")
            for line in text.split('\n'):
                if any(kw in line for kw in ['تحويل', 'التحويل', 'جامعة', 'رغبة', 'رغبات', 'شروط']):
                    print(f"  {line.strip()}")
