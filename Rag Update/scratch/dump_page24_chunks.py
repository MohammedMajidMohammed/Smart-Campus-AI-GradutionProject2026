import os
import sys
from dotenv import load_dotenv

sys.path.append(r"d:/Last_Version_Final_Gradution_Project_2026/Rag Update")
sys.stdout.reconfigure(encoding="utf-8")
load_dotenv()

from routes.chat import collection

# Get all chunks matching this file and page
results = collection.get(
    where={
        "$and": [
            {"fileName": "لائحه الفم والاسنان جامعة المنوفية الأهليه A-1.pdf"},
            {"page": 24}
        ]
    },
    include=["documents", "metadatas"]
)

print(f"Total chunks found on Page 24: {len(results['documents'])}")
for i, (doc, meta) in enumerate(zip(results["documents"], results["metadatas"])):
    print(f"\nChunk {i+1}:")
    print(f"Metadata: {meta}")
    print(f"Content:\n{doc}")
    print("-" * 60)
