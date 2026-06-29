import json
from pprint import pprint

with open(
    r"processed_pdfs\لائحه برنامج اللغة الإنجليزية و الترجمة التخصصية.pdf.json",
    "r",
    encoding="utf-8"
) as f:
    data = json.load(f)

print("TOP KEYS:")
print(data.keys())

print("\nFIRST PAGE:")
pprint(data["pages"][0])