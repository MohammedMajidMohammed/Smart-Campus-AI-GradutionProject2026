import os
import json
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# Search for BF, success marks, repeat rules, grading in medicine and student guide
files = ['طب وجراحه.pdf.json', 'student guide 25-26-2.pdf.json', 'لائحة الجامعة الأهلية.pdf.json']
keywords = ['BF', 'اعمال السنة', 'الامتحان النهائي', 'النجاح', 'الدرجة المطلوبة للنجاح', 'التقديرات', 'أعلى تقدير', 'اعادة المقرر', 'إعادة مقرر']

for fname in files:
    path = os.path.join('processed_pdfs', fname)
    if not os.path.exists(path):
        continue
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        pages = data.get('pages', [])
        for i, p in enumerate(pages):
            text = p.get('text', '')
            for line in text.split('\n'):
                if any(k.lower() in line.lower() for k in keywords):
                    print(f"[{fname} Page {i+1}]: {line.strip()}")
