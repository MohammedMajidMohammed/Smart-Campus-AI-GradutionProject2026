import os
import sys
from dotenv import load_dotenv

sys.path.append(r"d:/Last_Version_Final_Gradution_Project_2026/Rag Update")
sys.stdout.reconfigure(encoding="utf-8")

load_dotenv()

from routes.chat import collection

# Get all documents in the collection
results = collection.get(include=["documents", "metadatas"])

print(f"Total documents: {len(results['documents'])}")

search_terms = ["العبء", "الحد الأقصى", "الحد الأدنى", "ساعة معتمدة", "gpa", "تسجيل"]

for doc, meta in zip(results["documents"], results["metadatas"]):
    fname = meta.get("fileName", "")
    page = meta.get("page", 0)
    
    # We want Computers and AI guide or general guides:
    if "دليل_برامج_كلية_الحاسوب" in fname or "لائحة الجامعة" in fname or "لائحه جامعة" in fname:
        doc_lower = doc.lower()
        # Look for pages describing "تسجيل" or "العبء الدراسي" or registration limits
        if any(term in doc_lower for term in ["العبء", "الاقصى", "الادنى", "تسجيل", "gpa"]):
            print(f"\n=========================================")
            print(f"File: {fname} | Page: {page}")
            print(f"=========================================")
            
            # Print lines that look like registration limits
            lines = doc.splitlines()
            for line in lines:
                line_lower = line.lower()
                # Check for keywords and typical limit numbers
                if any(k in line_lower for k in ["الاقصى", "الادنى", "العبء", "تسجيل", "gpa", "ساعة", "ساعات"]) and any(n in line for n in ["12", "18", "21", "20", "14", "15", "9", "2.", "2,"]):
                    print("  ", line.strip())
