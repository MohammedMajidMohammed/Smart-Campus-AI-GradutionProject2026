import chromadb
import sys

sys.stdout.reconfigure(encoding='utf-8')

client = chromadb.PersistentClient('./chroma_db')
collection = client.get_collection('university_regulations')
all_data = collection.get()

matches = []
for doc in all_data['documents']:
    if doc and ("قاصد" in doc or "رئيس" in doc or "رييس" in doc or "عميد" in doc or "احمد" in doc or "أحمد" in doc):
        matches.append(doc)

with open('scratch/president_raw_chunks.txt', 'w', encoding='utf-8') as f:
    for m in matches:
        f.write(m + "\n\n---\n\n")

print(f"Found {len(matches)} chunks containing potential names.")
