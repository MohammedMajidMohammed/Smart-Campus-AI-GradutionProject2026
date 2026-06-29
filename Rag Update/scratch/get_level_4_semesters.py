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
    
    if "الحاسوب" in fname:
        doc_lower = doc.lower()
        if any(w in doc_lower for w in ["level 4", "المستوى الرابع", "المستوي الرابع", "الفرقة الرابعة"]):
            # Check if this is program "انترنت الاشياء" or "تحليل البيانات"
            if "الاشياء" in doc or "internet" in doc_lower:
                print(f"\n=========================================")
                print(f"File: {fname} | Page: {page}")
                print(f"=========================================")
                print(doc.strip())
