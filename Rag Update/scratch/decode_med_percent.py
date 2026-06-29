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
    
    # Page 14 and 15
    for idx in [13, 14]:
        text = pages[idx].get('text', '')
        for line in text.split('\n'):
            if any(p in line for p in ['60', '40', '50', 'أعمال السنة', 'الامتحان']):
                print(f"Page {idx+1}: {line.strip()}")
