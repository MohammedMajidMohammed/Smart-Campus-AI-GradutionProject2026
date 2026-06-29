import sys
import os
import time
from pathlib import Path
from dotenv import load_dotenv

sys.path.append(str(Path(__file__).parent.parent))
load_dotenv()

import chromadb
from chromadb.config import Settings
from routes.course_catalog import CourseCatalog

print("Connecting to ChromaDB...")
chroma = chromadb.PersistentClient(
    path="./chroma_db",
    settings=Settings(anonymized_telemetry=False)
)
collection = chroma.get_collection("university_regulations")
print(f"Total collection count: {collection.count()} chunks")

print("Initializing CourseCatalog...")
catalog = CourseCatalog(collection)

t0 = time.time()
print("Building catalog...")
n = catalog.build()
t1 = time.time()

print(f"Done in {t1-t0:.2f} seconds!")
print(f"Total courses: {n}")
print("Summary statistics:")
print(catalog.summary())
