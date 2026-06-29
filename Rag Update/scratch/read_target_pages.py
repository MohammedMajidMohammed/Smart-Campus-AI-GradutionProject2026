import os
import sys
from dotenv import load_dotenv

sys.path.append(r"d:/Last_Version_Final_Gradution_Project_2026/Rag Update")
sys.stdout.reconfigure(encoding="utf-8")

load_dotenv()

from routes.chat import collection

# Get all documents in the collection
results = collection.get(include=["documents", "metadatas"])

search_files = [
    "دليل_برامج_كلية_الحاسوب_والذكاء_الاصطناعى_جامعة_المنوفية_الاهلية.pdf",
    "لائحة الجامعة الأهلية.pdf",
    "لائحه جامعة المنوفية الأهليه a-1.pdf"
]

print("Scanning targeted pages...")

pages_to_print = [
    ("دليل_برامج_كلية_الحاسوب_والذكاء_الاصطناعى_جامعة_المنوفية_الاهلية.pdf", 12),
    ("دليل_برامج_كلية_الحاسوب_والذكاء_الاصطناعى_جامعة_المنوفية_الاهلية.pdf", 13),
    ("دليل_برامج_كلية_الحاسوب_والذكاء_الاصطناعى_جامعة_المنوفية_الاهلية.pdf", 40),
    ("دليل_برامج_كلية_الحاسوب_والذكاء_الاصطناعى_جامعة_المنوفية_الاهلية.pdf", 41),
    ("دليل_برامج_كلية_الحاسوب_والذكاء_الاصطناعى_جامعة_المنوفية_الاهلية.pdf", 42),
    ("دليل_برامج_كلية_الحاسوب_والذكاء_الاصطناعى_جامعة_المنوفية_الاهلية.pdf", 63),
    ("لائحة الجامعة الأهلية.pdf", 9),
    ("لائحة الجامعة الأهلية.pdf", 10),
    ("لائحه جامعة المنوفية الأهليه a-1.pdf", 12)
]

for doc, meta in zip(results["documents"], results["metadatas"]):
    fname = meta.get("fileName", "")
    page = meta.get("page", 0)
    
    for target_file, target_page in pages_to_print:
        if target_file == fname and target_page == page:
            print(f"\n==================================================")
            print(f"File: {fname} | Page: {page}")
            print(f"==================================================")
            print(doc.strip())
