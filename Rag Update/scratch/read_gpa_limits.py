import os
import sys
from dotenv import load_dotenv

sys.path.append(r"d:/Last_Version_Final_Gradution_Project_2026/Rag Update")
sys.stdout.reconfigure(encoding="utf-8")

load_dotenv()

from routes.chat import collection

results = collection.get(include=["documents", "metadatas"])

print(f"Total documents: {len(results['documents'])}")

# Let's search for registration hour limits or GPA rules in all files:
keywords = ["تسجيل", "ساعة معتمدة", "الحد الأقصى", "الحد الأدنى", "العبء الدراسي", "gpa"]

for doc, meta in zip(results["documents"], results["metadatas"]):
    fname = meta.get("fileName", "")
    page = meta.get("page", 0)
    
    # We are interested in Computers Faculty or General university regulations:
    if "الحاسوب" in fname or "جامعة" in fname or "اللائحة" in fname:
        doc_lower = doc.lower()
        if any(kw in doc_lower for kw in ["الاقصى", "الادنى", "العبء", "gpa", "تسجيل"]):
            # Check if this page mentions GPA constraints for registration, e.g. "أقل من", "منذر", "12", "18", "15"
            if any(num in doc for num in ["12", "18", "15", "14", "20", "2.0", "3.0"]):
                print(f"\n=========================================")
                print(f"File: {fname} | Page: {page}")
                print(f"=========================================")
                print(doc.strip()[:1000]) # print first 1000 chars of the page
