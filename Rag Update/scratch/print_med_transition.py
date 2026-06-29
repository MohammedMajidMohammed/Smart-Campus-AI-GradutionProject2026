import json
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

path = 'processed_pdfs/طب وجراحه.pdf.json'
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
    pages = data.get('pages', [])
    for idx in [16, 17]:
        print(f"=== Page {idx+1} ===")
        text = pages[idx].get('text', '')
        for line in text.split('\n'):
            if any(k in line for k in ['المستوي', 'المستوى', 'انتقال', 'الانتقال', 'يجتاز', 'ساعة معتمدة']):
                print(line.strip())
