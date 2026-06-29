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
    for idx, page in enumerate(pages):
        text = page.get('text', '')
        if any(k in text for k in ['المعدل التراكمي', 'الإنذار الأكاديمي', 'انذار', 'إنذار', 'العبء الدراسي', 'صيفي', 'الصيفي', 'التخرج']):
            print(f"Page {idx+1} contains matching keywords. Snippets:")
            for line in text.split('\n'):
                if any(k in line for k in ['انذار', 'إنذار', 'تراكمي', 'معدل', 'صيفي', 'تكرار', 'تخرج', 'العبء']):
                    print(f"  {line.strip()}")
