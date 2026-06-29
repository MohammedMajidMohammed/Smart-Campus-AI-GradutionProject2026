import sys
import io
import fitz
import pdfplumber
import pypdf
import os

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

pdf_path = r"files/طب وجراحه.pdf"
if not os.path.exists(pdf_path):
    if os.path.exists('Rag Update'):
        pdf_path = r"Rag Update/files/طب وجراحه.pdf"

print("Using PDF:", pdf_path)
page_idx = 17 # page 18

# 1. PyMuPDF (fitz)
doc = fitz.open(pdf_path)
text_fitz = doc[page_idx].get_text("text")
doc.close()

# 2. pdfplumber
with pdfplumber.open(pdf_path) as pdf:
    text_plumber = pdf.pages[page_idx].extract_text()

# 3. pypdf
reader = pypdf.PdfReader(pdf_path)
text_pypdf = reader.pages[page_idx].extract_text()

print("\n=== FITZ ===")
for line in text_fitz.split('\n'):
    if 'ساعة' in line or 'أسبوع' in line or 'اسبوع' in line:
        print(line.strip())

print("\n=== PDFPLUMBER ===")
for line in text_plumber.split('\n') if text_plumber else []:
    if 'ساعة' in line or 'أسبوع' in line or 'اسبوع' in line:
        print(line.strip())

print("\n=== PYPDF ===")
for line in text_pypdf.split('\n') if text_pypdf else []:
    if 'ساعة' in line or 'أسبوع' in line or 'اسبوع' in line:
        print(line.strip())
