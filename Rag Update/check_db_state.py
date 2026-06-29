import os
import sys
from pathlib import Path
from dotenv import load_dotenv

sys.path.append(str(Path(__file__).parent))
sys.stdout.reconfigure(encoding='utf-8')
load_dotenv()

from routes.upload import collection

# The filename as it appears in the JSON and should be in metadata
target_file = "لائحه برنامج اللغة الإنجليزية و الترجمة التخصصية.pdf"

try:
    # Query ChromaDB for all chunks belonging to this file
    res = collection.get(where={"fileName": target_file})
    ids = res.get("ids", [])
    metas = res.get("metadatas", [])
    
    print(f"Total chunks for '{target_file}': {len(ids)}")
    
    if len(ids) > 0:
        # Check the program tag of the first chunk
        prog = metas[0].get("program", "None")
        print(f"Program tag: {prog}")
        
        # Print a snippet of the first few chunks to see if they contain OCR text
        docs = res.get("documents", [])
        for i in range(min(3, len(docs))):
            print(f"\n--- Chunk {i} snippet ---")
            print(docs[i][:200])
except Exception as e:
    print(f"Error: {e}")
