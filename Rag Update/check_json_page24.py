import json
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

json_path = Path("processed_pdfs/Guide to the programs of the Faculty of Computer Science and Artificial Intelligence, Menoufia National University.pdf.json")
with open(json_path, "r", encoding="utf-8") as f:
    data = json.load(f)

pages = data.get("pages", [])
for p in pages:
    if p.get("page_number") == 24:
        print("Page 24 text:")
        print(p.get("text"))
        print("Raw text:")
        print(p.get("raw_text"))
