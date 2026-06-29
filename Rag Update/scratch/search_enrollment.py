import os
import json
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

keywords = ['إيقاف القيد', 'إلغاء القيد', 'إعادة قيد', 'اعادة قيد', 'إيقاف قيد', 'ايقاف قيد', 'إلغاء قيد', 'الغاء قيد']

print("Searching inside processed_pdfs...")
for fname in os.listdir('processed_pdfs'):
    if not fname.endswith('.json'):
        continue
    path = os.path.join('processed_pdfs', fname)
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        pages = data.get('pages', [])
        for i, p in enumerate(pages):
            text = p.get('text', '')
            lines = text.split('\n')
            for line in lines:
                if any(k in line for k in keywords):
                    print(f"[{fname} (Page {i+1})]: {line.strip()}")
