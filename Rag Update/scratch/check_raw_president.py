import os
import pypdf

pdf_dir = '.'
pdfs = [f for f in os.listdir(pdf_dir) if f.endswith('.pdf')]

found = []
for pdf in pdfs:
    try:
        reader = pypdf.PdfReader(pdf)
        for i, page in enumerate(reader.pages):
            text = page.extract_text()
            if text and ("رئيس" in text or "أ.د" in text or "ا.د" in text):
                lines = [line for line in text.split('\n') if "رئيس" in line or "أ.د" in line or "ا.د" in line]
                found.append(f"[{pdf}] Page {i+1}: {lines}")
    except Exception as e:
        pass

with open('scratch/president_raw_search.txt', 'w', encoding='utf-8') as f:
    for item in found:
        f.write(item + '\n')
print(f"Found {len(found)} matches in raw PDFs.")
