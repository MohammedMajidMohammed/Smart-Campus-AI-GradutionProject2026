import sys
import io
import fitz
import pytesseract
from PIL import Image
import os

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# Ensure Tesseract is configured
tesseract_cmd = r"C:\Program Files\Tesseract-OCR\tesseract.exe"
if os.path.exists(tesseract_cmd):
    pytesseract.pytesseract.tesseract_cmd = tesseract_cmd

pdf_path = r"files/طب وجراحه.pdf"
if not os.path.exists(pdf_path):
    # Try finding in root or check files directory
    print("Files in workspace directory:")
    print(os.listdir('.'))
    if os.path.exists('Rag Update'):
        pdf_path = r"Rag Update/files/طب وجراحه.pdf"

print("Using PDF path:", pdf_path)

doc = fitz.open(pdf_path)
page_num = 11  # Let's check page 11 (0-indexed is 10)
page = doc[page_num - 1]

# 1. Native text
native_text = page.get_text("text")
print("\n=== NATIVE TEXT ===")
print(native_text[:1000])

# 2. OCR text
zoom = 300 / 72
mat = fitz.Matrix(zoom, zoom)
pix = page.get_pixmap(matrix=mat, alpha=False)
img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
ocr_text = pytesseract.image_to_string(img, lang="ara+eng")

print("\n=== OCR TEXT ===")
print(ocr_text[:1000])

doc.close()
