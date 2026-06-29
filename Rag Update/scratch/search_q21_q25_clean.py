import os
import json
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# Search words
keywords = ['غش', 'الغش', 'عقوبة الغش', 'عذر مقبول', 'الامتحان النهائي', 'الامتحان النهائى', 'الأعذار الطبية', 'الاعذار الطبية', 'اللجنة الطبية', 'مرتبة الشرف', 'التحصيل الدراسي المتعثر', 'المتعثرين', 'متعثر']

for fname in os.listdir('processed_pdfs'):
    if not fname.endswith('.json'):
        continue
    path = os.path.join('processed_pdfs', fname)
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        pages = data.get('pages', [])
        for i, p in enumerate(pages):
            text = p.get('text', '')
            for line in text.split('\n'):
                if any(k in line for k in keywords):
                    print(f"[{fname} Page {i+1}]: {line.strip()}")
