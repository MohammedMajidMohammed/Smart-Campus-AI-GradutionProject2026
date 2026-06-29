import os
import sys
from dotenv import load_dotenv

sys.path.append(r"d:/Last_Version_Final_Gradution_Project_2026/Rag Update")
sys.stdout.reconfigure(encoding="utf-8")

load_dotenv()

from routes.chat import collection
import re

results = collection.get(include=["documents", "metadatas"])

for doc, meta in zip(results["documents"], results["metadatas"]):
    fname = meta.get("fileName", "")
    page = meta.get("page", 0)
    
    if "الحاسوب" in fname:
        doc_lower = doc.lower()
        # Look for level 4 / year 4 / المستوي الرابع and "انترنت الاشياء" or "تحليل البيانات"
        if any(lv in doc_lower for lv in ["level 4", "المستوي الرابع", "المستوى الرابع", "الفرقة الرابعة"]) and any(prog in doc_lower for prog in ["internet", "اشياء", "الاشياء", "البيانات"]):
            print(f"\n=========================================")
            print(f"File: {fname} | Page: {page}")
            print(f"=========================================")
            print(doc.strip()[:1500])
