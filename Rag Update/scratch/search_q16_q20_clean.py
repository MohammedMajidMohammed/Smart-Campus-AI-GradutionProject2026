import os
import json
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# Search files
files = ['هندسه.pdf.json', 'لائحة الجامعة الأهلية.pdf.json', 'دليل_برامج_كلية_الحاسوب_والذكاء_الاصطناعى_جامعة_المنوفية_الاهلية.pdf.json']
keywords = ['تخرج', 'التخرج', 'إنذار', 'انذار', 'معدل تراكمي', 'المعدل التراكمي', 'مراقبة', 'المراقبة', 'تكرار', 'الاعادة', 'الإعادة', 'صيفي', 'الصيفي']

for fname in files:
    path = os.path.join('processed_pdfs', fname)
    if not os.path.exists(path):
        continue
    print(f"=== File: {fname} ===")
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        pages = data.get('pages', [])
        for i, p in enumerate(pages):
            text = p.get('text', '')
            for line in text.split('\n'):
                if any(k in line for k in keywords):
                    # Print only if it matches some combinations
                    if any(c in line for c in ['تخرج', 'انذار', 'إنذار', 'تراكمي', 'معدل', 'مراقبة', 'صيفي', 'تكرار', 'إعادة']):
                        print(f"  Page {i+1}: {line.strip()}")
