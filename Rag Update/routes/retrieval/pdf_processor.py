# pdf_processor.py
"""
Utility module for extracting textual content from PDF files.
It first attempts to extract searchable text using pdfplumber. If a page
contains little or no text (common with scanned Arabic documents), the
module falls back to OCR via pytesseract.

The function `extract_text_from_pdf` returns a single string that
concatenates the extracted text for all pages.

Dependencies (add to requirements.txt if missing):
- pdfplumber
- pytesseract
- pdf2image
- pillow
- poppler (system dependency for pdf2image)
"""

import os
from typing import List

import pdfplumber
from pdf2image import convert_from_path
from PIL import Image
import pytesseract

# Ensure Tesseract is found (the path is already known from logs)
# If Tesseract is not in PATH, you can set it manually:
# pytesseract.pytesseract.tesseract_cmd = r"C:\Program Files\Tesseract-OCR\tesseract.exe"


def _ocr_page(image: Image.Image) -> str:
    """Run OCR on a single PIL image and return the extracted Arabic text.
    The function forces Arabic language ("ara").
    """
    try:
        text = pytesseract.image_to_string(image, lang="ara")
        return text.strip()
    except Exception as e:
        # In case OCR fails, return an empty string so the caller can decide.
        print(f"[pdf_processor] OCR error: {e}")
        return ""


def _extract_text_pdfplumber(page) -> str:
    """Extract plain text from a pdfplumber page.
    Returns an empty string if no text is found.
    """
    try:
        txt = page.extract_text()
        return txt.strip() if txt else ""
    except Exception as e:
        print(f"[pdf_processor] pdfplumber error: {e}")
        return ""


def extract_text_from_pdf(pdf_path: str, min_char_threshold: int = 30) -> str:
    """Extract text from a PDF file.

    Parameters
    ----------
    pdf_path: str
        Absolute path to the PDF document.
    min_char_threshold: int, optional
        Minimum number of characters considered as "meaningful" text on a page.
        Pages with fewer characters trigger OCR.

    Returns
    -------
    str
        Concatenated text for the whole PDF.
    """
    if not os.path.isfile(pdf_path):
        raise FileNotFoundError(f"PDF not found: {pdf_path}")

    all_text: List[str] = []
    # First pass: try pdfplumber for all pages
    with pdfplumber.open(pdf_path) as pdf:
        for i, page in enumerate(pdf.pages, start=1):
            raw = _extract_text_pdfplumber(page)
            if raw and len(raw) >= min_char_threshold:
                all_text.append(raw)
            else:
                # Fallback to OCR for this page
                # Convert the specific page to an image using pdf2image
                try:
                    images = convert_from_path(pdf_path, first_page=i, last_page=i, fmt="png")
                    if images:
                        ocr_text = _ocr_page(images[0])
                        if ocr_text:
                            all_text.append(ocr_text)
                except Exception as e:
                    print(f"[pdf_processor] PDF to image conversion error on page {i}: {e}")

    # Join with double newlines for readability
    return "\n\n".join(all_text)


if __name__ == "__main__":
    import sys
    if len(sys.argv) != 2:
        print("Usage: python pdf_processor.py <path-to-pdf>")
        sys.exit(1)
    txt = extract_text_from_pdf(sys.argv[1])
    print(txt)
