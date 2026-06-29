import sys
from chat_cli import RAGSession

session = RAGSession()
res = session.collection.get(include=["documents", "metadatas"])
docs = res.get("documents", [])
metas = res.get("metadatas", [])

count = 0
for idx, (doc, meta) in enumerate(zip(docs, metas)):
    doc_lower = doc.lower()
    # Search for passing requirements indicators
    if ("60" in doc_lower and ("pass" in doc_lower or "نجاح" in doc_lower or "درج" in doc_lower or "تخرج" in doc_lower or "متطلب" in doc_lower or "حد" in doc_lower)):
        print(f"Match {count}: File: {meta.get('fileName')}, Page: {meta.get('page')}, Section: {meta.get('sectionTitle')}")
        print(doc[:300] + "...")
        print("-" * 60)
        count += 1
