import json
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

path = 'processed_pdfs/دليل_الطالب_نهائي_علاج_طبيعي_2025_2026.pdf.json'
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
    pages = data.get('pages', [])
    for idx, p in enumerate(pages):
        text = p.get('text', '')
        if 'أعذار' in text or 'اعذار' in text or 'الأعذار' in text or 'الاعذار' in text or 'عذر' in text:
            print(f"Page {idx+1}:")
            for line in text.split('\n'):
                if any(kw in line for kw in ['أعذار', 'اعذار', 'الأعذار', 'الاعذار', 'عذر', 'مرض']):
                    print(f"  {line.strip()}")
