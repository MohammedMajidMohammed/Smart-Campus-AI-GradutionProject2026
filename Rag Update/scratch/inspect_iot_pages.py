import os
import sys
from dotenv import load_dotenv

sys.path.append(r"d:/Last_Version_Final_Gradution_Project_2026/Rag Update")
sys.stdout.reconfigure(encoding="utf-8")

load_dotenv()

from routes.chat import collection

results = collection.get(include=["documents", "metadatas"])
print(f"Total documents: {len(results['documents'])}")

matched = 0
for doc, meta in zip(results["documents"], results["metadatas"]):
    fname = meta.get("fileName", "")
    page = meta.get("page", 0)
    # convert page to int if it is string
    try:
        page_num = int(page)
    except:
        page_num = 0
        
    if "الحاسوب" in fname and 33 <= page_num <= 42:
        print(f"\n=========================================")
        print(f"File: {fname} | Page: {page_num}")
        print(f"=========================================")
        print(doc.strip()[:1500])
        matched += 1

print(f"Matched {matched} pages.")
