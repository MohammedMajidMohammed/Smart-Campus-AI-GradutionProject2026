import os
import sys
from dotenv import load_dotenv

sys.path.append(r"d:/Last_Version_Final_Gradution_Project_2026/Rag Update")
sys.stdout.reconfigure(encoding="utf-8")
load_dotenv()

from routes.chat import collection

results = collection.get(include=["documents", "metadatas"])
for doc, meta in zip(results["documents"], results["metadatas"]):
    fname = meta.get("fileName", "")
    page = meta.get("page", 0)
    
    if "اسنان" in fname or "أسنان" in fname:
        doc_lower = doc.lower()
        if any(term in doc_lower for term in ["ساعة", "تخرج", "بكالوريوس", "درجة"]):
            print(f"=== File: {fname} | Page: {page} ===")
            print(doc.strip())
            print("-" * 80)
