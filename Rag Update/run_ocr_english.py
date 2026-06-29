"""
run_ocr_english.py
==================
Wrapper to reprocess the English/Translation PDF with force-OCR.
Usage:
    venv/Scripts/python.exe run_ocr_english.py
    venv/Scripts/python.exe run_ocr_english.py --dry-run
"""
import sys
import os
# Ensure UTF-8 output for Arabic characters
sys.stdout.reconfigure(encoding='utf-8')
# أضف المجلد الحالي للـ path
sys.path.insert(0, os.path.dirname(__file__))

# اسم الملف المستهدف
TARGET_PDF = "لائحه برنامج اللغة الإنجليزية و الترجمة التخصصية.pdf"

# حقن الـ arguments
dry_run = "--dry-run" in sys.argv
sys.argv = [sys.argv[0], TARGET_PDF]
if dry_run:
    sys.argv.append("--dry-run")

# شغّل السكريبت
import reprocess_single_pdf
reprocess_single_pdf.main()
