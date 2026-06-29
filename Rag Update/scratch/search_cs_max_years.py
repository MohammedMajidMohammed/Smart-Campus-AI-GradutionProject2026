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
    for idx, p in enumerate(pages):
        text = p.get('text', '')
        if any(kw in text for kw in ['سنوات', 'سنة', 'الحد الاقصي', 'الحد الأقصى']):
            for line in text.split('\n'):
                if any(kw in line for kw in ['دراسة', 'الدراسة', 'تخرج', 'فصل']):
                    print(f"Page {idx+1}: {line.strip()}")
