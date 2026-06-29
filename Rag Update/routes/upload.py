from fastapi import APIRouter, UploadFile, File, HTTPException
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

# Initialize embeddings (Local HuggingFace fallback for stability)
from sentence_transformers import SentenceTransformer

class LocalHuggingFaceEmbeddings:
    """Local embedding wrapper to avoid API costs/limits."""
    def __init__(self, model_name="all-MiniLM-L6-v2"):
        print(f"Loading local embedding model: {model_name}...")
        try:
            # 1. Try loading purely from local cache first to avoid ANY network issues
            self.model = SentenceTransformer(model_name, local_files_only=True)
        except Exception as e:
            print(f"Model not found locally, downloading from HF Hub... ({e})")
            # 2. If not found locally, download it
            self.model = SentenceTransformer(model_name)
            
    def embed_documents(self, texts: List[str]) -> List[List[float]]:
        return self.model.encode(texts).tolist()
    def embed_query(self, text: str) -> List[float]:
        return self.model.encode([text])[0].tolist()

try:
    embeddings = LocalHuggingFaceEmbeddings()
except Exception as e:
    print(f"ERROR loading local embeddings: {e}")
    # Final fallback logic if needed, but ST should work
    raise e

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
                    (["ألسن", "السن", "لغات", "اللغة", "الترجمة", "languages", "english", "translation", "arts", "humanities", "آداب", "اداب", "فنون"], "arts"),
                    (["حقوق", "قانون", "law"], "law"),
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
