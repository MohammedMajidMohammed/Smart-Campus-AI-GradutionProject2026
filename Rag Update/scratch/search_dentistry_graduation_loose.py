import os
import sys
from dotenv import load_dotenv

sys.path.append(r"d:/Last_Version_Final_Gradution_Project_2026/Rag Update")
sys.stdout.reconfigure(encoding="utf-8")
load_dotenv()

from routes.chat import collection
results = collection.get(include=["documents", "metadatas"])

search_terms = ["تخرج", "تخر", "بكالوريوس", "درجة", "متطلبات", "امتياز"]

for doc, meta in zip(results["documents"], results["metadatas"]):
    fname = meta.get("fileName", "")
    page = meta.get("page", 0)
    
    if "اسنان" in fname or "أسنان" in fname or "dentistry" in fname.lower() or "teeth" in fname.lower():
        doc_lower = doc.lower()
        found = [term for term in search_terms if term in doc_lower]
        if found:
            print(f"File: {fname} | Page: {page} | Found: {found}")
            lines = doc.splitlines()
            for line in lines:
                if any(k in line for k in search_terms):
                    print("  ", line.strip())
            print("-" * 50)
