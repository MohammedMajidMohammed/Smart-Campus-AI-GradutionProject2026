import sys
import io
import fitz
import os

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

pdf_path = r"files/طب وجراحه.pdf"
if not os.path.exists(pdf_path):
    if os.path.exists('Rag Update'):
        pdf_path = r"Rag Update/files/طب وجراحه.pdf"

doc = fitz.open(pdf_path)
page = doc[17] # Page 18

print("=== WITHOUT SORT ===")
print(page.get_text("text")[:1000])

print("\n=== WITH SORT ===")
print(page.get_text("text", sort=True)[:1000])

doc.close()
