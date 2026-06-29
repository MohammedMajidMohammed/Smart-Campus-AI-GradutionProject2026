
import chromadb
from sentence_transformers import SentenceTransformer
import os
import json

model = SentenceTransformer("all-MiniLM-L6-v2")
client = chromadb.PersistentClient(path="chroma_db")
collection = client.get_collection("university_regulations")

query = "Basic and Clinical Dental Sciences Oral Biology Oral Pathology Oral Medicine and Diagnosis Oral and Maxilofacial Radiology Periodontology Oral and Maxillofacial Surgery"
query_vec = model.encode(query).tolist()

results = collection.query(
    query_embeddings=[query_vec],
    n_results=10,
    where={"program": "dentistry"}
)

with open("scratch/chroma_results.txt", "w", encoding="utf-8") as f:
    for i in range(len(results["ids"][0])):
        f.write(f"ID: {results['ids'][0][i]}\n")
        metadata = results['metadatas'][0][i]
        f.write(f"Page: {metadata.get('page')}, File: {metadata.get('fileName')}\n")
        f.write(f"Snippet: {results['documents'][0][i][:500]}\n")
        f.write("-" * 50 + "\n")
