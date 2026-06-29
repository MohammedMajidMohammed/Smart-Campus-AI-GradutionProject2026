import os
import sys
from dotenv import load_dotenv

sys.path.append(r"d:/Last_Version_Final_Gradution_Project_2026/Rag Update")
sys.stdout.reconfigure(encoding="utf-8")

load_dotenv()

from routes.chat import collection

results = collection.get(include=["documents", "metadatas"])

targets = [
    ("لائحة الجامعة الأهلية.pdf", 8),
    ("لائحة الجامعة الأهلية.pdf", 9),
    ("دليل_برامج_كلية_الحاسوب_والذكاء_الاصطناعى_جامعة_المنوفية_الاهلية.pdf", 39),
    ("دليل_برامج_كلية_الحاسوب_والذكاء_الاصطناعى_جامعة_المنوفية_الاهلية.pdf", 40)
]

for doc, meta in zip(results["documents"], results["metadatas"]):
    fname = meta.get("fileName", "")
    page = meta.get("page", 0)
    
    for tf, tp in targets:
        if tf == fname and tp == page:
            print(f"\n=========================================")
            print(f"File: {fname} | Page: {page}")
            print(f"=========================================")
            print(doc.strip())
