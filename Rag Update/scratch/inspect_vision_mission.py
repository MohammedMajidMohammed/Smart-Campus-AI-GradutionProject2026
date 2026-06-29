import os
import json
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# Let's search inside 'لائحة الجامعة الأهلية.pdf.json' and 'student guide 25-26-2.pdf.json'
files_to_check = ['لائحة الجامعة الأهلية.pdf.json', 'student guide 25-26-2.pdf.json', 'دليل_برامج_كلية_الحاسوب_والذكاء_الاصطناعى_جامعة_المنوفية_الاهلية.pdf.json']

for fname in files_to_check:
    path = os.path.join('processed_pdfs', fname)
    if not os.path.exists(path):
        continue
    print("=" * 80)
    print(f"File: {fname}")
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        pages = data.get('pages', [])
        for i, page in enumerate(pages):
            text = page.get('text', '')
            if 'رؤية' in text or 'الرؤية' in text or 'الرسالة' in text or 'رسالة' in text:
                # print the page and check if it contains the official university vision/mission
                lines = text.split('\n')
                # If there are phrases like "رؤية الجامعة" or "رسالة الجامعة" or "الرؤية والرسالة"
                if any(any(k in line for k in ['رؤية الجامعة', 'رسالة الجامعة', 'الرؤية:', 'الرسالة:']) for line in lines):
                    print(f"--- Page {i+1} ---")
                    for line in lines:
                        if any(k in line for k in ['رؤية', 'الرؤية', 'الرسالة', 'رسالة', 'رؤية الجامعة', 'رسالة الجامعة']):
                            print(line.strip())
