import os
import json
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

keywords = ['الجمهور', 'أنشئت', 'قرار رئيس', 'قرار الجمهوري', 'قرار رقم', 'تأسس', 'تأسيس']

print("Searching inside processed_pdfs...")
found = False
for f in os.listdir('processed_pdfs'):
    if not f.endswith('.json'):
        continue
    filepath = os.path.join('processed_pdfs', f)
    with open(filepath, 'r', encoding='utf-8') as file:
        try:
            data = json.load(file)
            # Support both format versions
            pages = data.get('pages', []) if isinstance(data, dict) else []
            for page in pages:
                page_num = page.get('page', '?')
                text = page.get('text', '')
                for line in text.split('\n'):
                    if any(k in line for k in keywords):
                        print(f"[{f} (Page {page_num})]: {line.strip()}")
                        found = True
        except Exception as e:
            print(f"Error reading {f}: {e}")

if not found:
    print("No matching lines found.")
