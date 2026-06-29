import json
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

path = 'processed_pdfs/هندسه.pdf.json'
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
    pages = data.get('pages', [])
    print(pages[11].get('text', '')) # Index 11 is Page 12
