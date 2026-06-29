import os

def restore_upload():
    content = r'''from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from typing import List
import os
import io
import json
import pandas as pd
from pathlib import Path
import chromadb
from chromadb.config import Settings
from langchain_openai import OpenAIEmbeddings
from dotenv import load_dotenv

# OCR-enhanced PDF processor (replaces raw pypdf extraction)
from routes.pdf_processor import extract_and_structure_pdf, structured_doc_to_chunks

# Invalidate BM25 index after new documents are added
from routes.retrieval.bm25_index import invalidate_index

load_dotenv()

router = APIRouter()

# Initialize ChromaDB
chroma_client = chromadb.PersistentClient(
    path="./chroma_db",
    settings=Settings(anonymized_telemetry=False)
)

# Get or create collection
collection = chroma_client.get_or_create_collection(
    name="university_regulations",
    metadata={"description": "University regulations PDFs and CSV Q&A"}
)

# Initialize embeddings
# Try OpenAI first (more reliable for embeddings), fallback to OpenRouter
openai_key = os.getenv("OPENAI_API_KEY")
openrouter_key = os.getenv("OPENROUTER_API_KEY")

if openai_key and openai_key.strip() and openai_key != "your_openai_api_key_here":
    # Use OpenAI directly for embeddings (more reliable)
    print("Using OpenAI API for embeddings")
    embeddings = OpenAIEmbeddings(
        openai_api_key=openai_key,
        model="text-embedding-ada-002"
    )
elif openrouter_key and openrouter_key.strip() and openrouter_key != "your_openrouter_api_key_here":
    # Use OpenRouter for embeddings
    print("Using OpenRouter API for embeddings")
    if not openrouter_key.startswith("sk-or-v1-"):
        print("WARNING: API key doesn't start with 'sk-or-v1-'. Make sure it's a valid OpenRouter API key.")
    
    embeddings = OpenAIEmbeddings(
        openai_api_key=openrouter_key,
        openai_api_base="https://openrouter.ai/api/v1",
        model="text-embedding-ada-002",
        default_headers={
            "HTTP-Referer": os.getenv("OPENROUTER_REFERRER", "http://localhost:8000"),
            "X-Title": "Smart Campus RAG",
        }
    )
else:
    error_msg = (
        "ERROR: No valid API key found for embeddings!\n"
        "Please set one of the following in .env:\n"
        "  Option 1 (Recommended): OPENAI_API_KEY=sk-your-openai-key\n"
        "  Option 2: OPENROUTER_API_KEY=sk-or-v1-your-openrouter-key\n"
        "\n"
        "Get OpenAI key: https://platform.openai.com/api-keys\n"
        "Get OpenRouter key: https://openrouter.ai/keys"
    )
    print(error_msg)
    raise ValueError("No valid embeddings API key found. Please set OPENAI_API_KEY or OPENROUTER_API_KEY in .env file")

@router.get("/pdfs")
async def get_indexed_pdfs():
    """Get list of indexed PDFs and CSV files"""
    try:
        results = collection.get()
        unique_files = list(set([
            meta.get("fileName") 
            for meta in results.get("metadatas", []) 
            if meta.get("fileName")
        ]))
        
        pdfs = []
        for filename in unique_files:
            count = sum(1 for meta in results.get("metadatas", []) 
                       if meta.get("fileName") == filename)
            file_type = "CSV" if any(
                meta.get("type") == "qa_pair" 
                for meta in results.get("metadatas", []) 
                if meta.get("fileName") == filename
            ) else "PDF"
            pdfs.append({"name": filename, "chunks": count, "type": file_type})
        
        return JSONResponse({"success": True, "pdfs": pdfs})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/")
async def upload_pdfs(files: List[UploadFile] = File(...)):
    if not files:
        raise HTTPException(status_code=400, detail="No files uploaded")
    
    results = []
    try:
        for file in files:
            file_ext = file.filename.lower().split('.')[-1] if '.' in file.filename else ''
            
            if file_ext == 'csv':
                try:
                    contents = await file.read()
                    try:
                        csv_content = contents.decode('utf-8-sig')
                    except:
                        csv_content = contents.decode('utf-8')
                    
                    csv_file = io.StringIO(csv_content)
                    df = pd.read_csv(csv_file)
                    
                    if 'question' not in df.columns or 'answer' not in df.columns:
                        results.append({"fileName": file.filename, "success": False, "error": "CSV columns missing"})
                        continue
                    
                    documents, metadatas, ids = [], [], []
                    for idx, row in df.iterrows():
                        question = str(row['question']).strip()
                        answer = str(row['answer']).strip()
                        if not question or not answer: continue
                        documents.append(f"Q: {question}\nA: {answer}")
                        metadatas.append({"fileName": file.filename, "type": "qa_pair"})
                        ids.append(f"{file.filename}-qa-{idx}")
                    
                    if documents:
                        embeddings_list = embeddings.embed_documents(documents)
                        collection.add(embeddings=embeddings_list, documents=documents, metadatas=metadatas, ids=ids)
                        results.append({"fileName": file.filename, "success": True, "chunks": len(documents), "type": "CSV"})
                        invalidate_index("university_regulations")
                    continue
                except Exception as e:
                    results.append({"fileName": file.filename, "success": False, "error": str(e)})
                    continue

            if file_ext != 'pdf':
                results.append({"fileName": file.filename, "success": False, "error": "Only PDF/CSV allowed"})
                continue
            
            try:
                contents = await file.read()
                structured_doc = extract_and_structure_pdf(pdf_bytes=contents, filename=file.filename)
                
                if not structured_doc["full_text"].strip():
                    results.append({"fileName": file.filename, "success": False, "error": "Empty PDF"})
                    continue

                chunks, metadatas = structured_doc_to_chunks(structured_doc, chunk_size=1000, chunk_overlap=200)
                
                _FNAME_PROG_MAP = [
                    (["علاج طبيعي", "علاج_طبيعي", "physical therapy", "physio"], "physical therapy"),
                    (["طب بيطري", "بيطري", "veterinary", "veterinar", "bitar"], "veterinary"),
                    (["طب أسنان", "أسنان", "اسنان", "dentistry", "dent"], "dentistry"),
                    (["طب وجراحه", "طب_وجراحه", "وجراحه"], "medicine"),
                    (["طب", "medicine", "medical", "mbbs"], "medicine"),
                    (["صيدلة", "صيدله", "pharmacy", "pharm"], "pharmacy"),
                    (["تمريض", "nursing", "nurse"], "nursing"),
                    (["هندسة", "هندسه", "engineering", "eng"], "engineering"),
                    (["حاسبات", "حاسبات ومعلومات", "computer", "cs", "it", "fci", "bcs"], "computer science"),
                    (["إدارة", "ادارة", "أعمال", "business", "management", "bba", "mgt"], "business"),
                    (["ألسن", "السن", "لغات", "languages", "al-alsun", "alsun"], "languages"),
                    (["حقوق", "قانون", "law"], "law"),
                    (["فنون", "فنون تطبيقية", "فنون جميلة", "arts", "applied arts", "fine arts"], "arts"),
                    (["آداب", "اداب", "arts and humanities", "humanities"], "humanities"),
                    (["علوم", "science", "sci"], "science"),
                    (["زراعة", "زراعه", "agriculture", "agri"], "agriculture"),
                    (["تربية", "تربيه", "education", "edu"], "education"),
                    (["اقتصاد", "اقتصاد وعلوم سياسية", "economics", "political science", "eco"], "economics"),
                    (["إعلام", "اعلام", "mass communication", "media"], "mass communication"),
                    (["سياحة", "سياحه", "فنادق", "tourism", "hotels"], "tourism"),
                    (["آثار", "اثار", "archaeology", "antiquities"], "archaeology"),
                    (["فني", "معهد فني", "technical", "tech"], "technical"),
                ]
                
                _fname_lower = file.filename.lower()
                _doc_program = None
                for _keywords, _prog in _FNAME_PROG_MAP:
                    if any(kw in _fname_lower for kw in _keywords):
                        _doc_program = _prog
                        break

                if _doc_program:
                    for m in metadatas: m["program"] = _doc_program
                
                ids = [meta.get("chunkId") or f"{file.filename}-{i}" for i, meta in enumerate(metadatas)]
                embeddings_list = embeddings.embed_documents(chunks)
                
                batch_size = 500
                for i in range(0, len(chunks), batch_size):
                    end = min(i + batch_size, len(chunks))
                    collection.upsert(
                        embeddings=embeddings_list[i:end],
                        documents=chunks[i:end],
                        metadatas=metadatas[i:end],
                        ids=ids[i:end]
                    )
                
                results.append({"fileName": file.filename, "success": True, "chunks": len(chunks), "type": "PDF"})
                invalidate_index("university_regulations")
            except Exception as e:
                results.append({"fileName": file.filename, "success": False, "error": str(e)})
        
        return JSONResponse({"success": True, "results": results})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
'''
    with open('routes/upload.py', 'w', encoding='utf-8') as f:
        f.write(content)

restore_upload()
print("Restored upload.py")
