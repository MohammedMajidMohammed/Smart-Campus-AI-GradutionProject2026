import os
import sys
from dotenv import load_dotenv

sys.path.append(r"d:/Last_Version_Final_Gradution_Project_2026/Rag Update")
sys.stdout.reconfigure(encoding="utf-8")
load_dotenv()

from routes.chat import collection
results = collection.get(include=["documents", "metadatas"])

search_terms = ["تخرج", "متطلبات", "بكالوريوس", "درجة", "الساعات", "التخرج"]
dentistry_files = ["لائحه الفم والاسنان", "لائحه جامعة المنوفية", "لائحة الجامعة"]

for doc, meta in zip(results["documents"], results["metadatas"]):
    fname = meta.get("fileName", "")
    page = meta.get("page", 0)
    
    if any(df in fname for df in dentistry_files):
        doc_lower = doc.lower()
        matches = [term for term in search_terms if term in doc_lower]
        if len(matches) >= 2:
            print(f"File: {fname} | Page: {page} | Matches: {matches}")
            # print a snippet of text containing 'تخرج' or 'التخرج' or 'درجة'
            lines = doc.splitlines()
            for line in lines:
                if any(k in line for k in ["تخرج", "درجة", "بكالوريوس", "الساعات"]):
                    print("  ", line.strip())
            print("-" * 50)
