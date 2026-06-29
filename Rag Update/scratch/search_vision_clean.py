import os
import json
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

for fname in os.listdir('processed_pdfs'):
    if not fname.endswith('.json'):
        continue
    path = os.path.join('processed_pdfs', fname)
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        pages = data.get('pages', [])
        for i, p in enumerate(pages):
            text = p.get('text', '')
            if 'رؤية الجامعة' in text or 'رسالة الجامعة' in text:
                print(f"File: {fname}, Page: {i+1}")
                # Print lines containing vision/mission
                for line in text.split('\n'):
                    if any(k in line for k in ['رؤية', 'الرؤية', 'رسالة', 'الرسالة']):
                        print(f"  {line.strip()}")
