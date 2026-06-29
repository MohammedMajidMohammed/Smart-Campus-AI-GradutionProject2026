import json

with open(
    r"processed_pdfs\لائحه برنامج اللغة الإنجليزية و الترجمة التخصصية.pdf.json",
    "r",
    encoding="utf-8"
) as f:
    data = json.load(f)

for page in data["pages"]:
    if page["page_number"] in [15, 16, 17]:
        print("\n" + "="*60)
        print("PAGE", page["page_number"])
        print("has_tables =", page.get("has_tables"))
        print("extraction_method =", page.get("extraction_method"))
        print("="*60)
        print(page["text"][:5000])