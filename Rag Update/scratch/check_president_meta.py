import chromadb
import sys

sys.stdout.reconfigure(encoding='utf-8')

client = chromadb.PersistentClient('./chroma_db')
collection = client.get_collection('university_regulations')
all_data = collection.get(include=['documents', 'metadatas'])

for doc, meta in zip(all_data['documents'], all_data['metadatas']):
    if "القاصد" in doc or "رييس جامعة المنوفية" in doc:
        print(f"Meta: {meta}\nText snippet: {doc[:100]}\n---")
