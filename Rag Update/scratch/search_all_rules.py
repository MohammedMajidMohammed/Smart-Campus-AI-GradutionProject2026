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

search_terms = ["الاقصى", "الادنى", "الحد", "العبء", "ساعة", "GPA", "تسجيل", "معدل"]

matches = []

for idx, (doc, meta) in enumerate(zip(results["documents"], results["metadatas"])):
    fname = meta.get("fileName", "")
    page = meta.get("page", 0)
    
    if any(sf in fname for sf in search_files):
        found = []
        for term in search_terms:
            if term.lower() in doc.lower():
                found.append(term)
        if found:
            matches.append({
                "file": fname,
                "page": page,
                "found": found,
                "text": doc
            })

print(f"Total matching pages in target files: {len(matches)}")

for m in sorted(matches, key=lambda x: (x["file"], x["page"])):
    # Look for registration limits: "الحد الأقصى" or "الحد الأدنى" or limit numbers like 12, 18, 21, 9
    text_lower = m["text"].lower()
    if any(kw in text_lower for kw in ["الاقصى", "الادنى", "العبء", "تسجيل"]):
        print(f"\n==================================================")
        print(f"File: {m['file']} | Page: {m['page']} | Matches: {m['found']}")
        print(f"==================================================")
        # Find where the keyword is and print around it
        for term in ["الاقصى", "الادنى", "العبء", "تسجيل"]:
            pos = text_lower.find(term)
            if pos != -1:
                start = max(0, pos - 150)
                end = min(len(m["text"]), pos + 500)
                print(f"--- Around '{term}' ---")
                print(m["text"][start:end].strip())
