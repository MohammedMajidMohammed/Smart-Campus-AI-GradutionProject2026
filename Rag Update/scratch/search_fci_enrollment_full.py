import os
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
    # Let's search for lines containing 'انقطاع', 'إيقاف', 'إلغاء', 'فصل' on page 17 (index 16)
    page_text = pages[16].get('text', '')
    print("Page 17:")
    for line in page_text.split('\n'):
        if any(k in line for k in ['انقطع', 'انقطاع', 'إيقاف', 'إلغاء', 'قيد', 'فصل']):
            print("  ", line.strip())
            
    print("Page 18:")
    page_text_18 = pages[17].get('text', '')
    for line in page_text_18.split('\n'):
        if any(k in line for k in ['انقطع', 'انقطاع', 'إيقاف', 'إلغاء', 'قيد', 'فصل', 'إعادة']):
            print("  ", line.strip())
