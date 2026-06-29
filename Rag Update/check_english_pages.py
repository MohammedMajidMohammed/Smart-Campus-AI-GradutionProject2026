import json

with open(
    r"processed_pdfs\لائحه برنامج اللغة الإنجليزية و الترجمة التخصصية.pdf.json",
    "r",
    encoding="utf-8"
) as f:
    data = json.load(f)

print("Total pages =", len(data["pages"]))

for p in data["pages"]:
    print(p.get("page_num"))