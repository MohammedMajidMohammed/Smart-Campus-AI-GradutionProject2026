# شرح ملف `Rag Update/routes/chat.py` بالتفصيل

هذا الملف هو نقطة النهاية (Endpoint) للدردشة (Chat) في نظام RAG (Retrieval-Augmented Generation) للجامعة.

---

## 1. الاستيرادات (Imports)

```
python
from fastapi import APIRouter, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import List, Optional
import os
import chromadb
from chromadb.config import Settings
from langchain_openai import OpenAIEmbeddings, ChatOpenAI
from langchain_core.prompts import PromptTemplate
from dotenv import load_dotenv
```

| الاستيراد | الغرض |
|-----------|--------|
| `FastAPI`, `APIRouter`, `HTTPException` | إنشاء نقاط النهاية API |
| `pydantic.BaseModel` | نمذجة البيانات (Data Modeling) |
| `chromadb` | قاعدة بيانات المتجهات (Vector Database) |
| `OpenAIEmbeddings`, `ChatOpenAI` | نماذج الذكاء الاصطناعي للـ Embeddings والدردشة |
| `PromptTemplate` | قوالب الأسئلة (Prompts) |
| `load_dotenv` | تحميل المتغيرات من ملف .env |

---

## 2. إعداد الراوتر (Router Setup)

```
python
load_dotenv()
router = APIRouter()

# Initialize ChromaDB
chroma_client = chromadb.PersistentClient(
    path="./chroma_db",
    settings=Settings(anonymized_telemetry=False)
)

# Get collection
try:
    collection = chroma_client.get_collection(name="university_regulations")
except:
    collection = None
```

- **`load_dotenv()`**: تحميل مفاتيح API من ملف `.env`
- **`chroma_client`**: عميل ChromaDB (قاعدة بيانات متجهات تخزن في `./chroma_db`)
- **`collection`**: محاولة الحصول على مجموعة `university_regulations` (مجموعة الوثائق المفهرسة)

---

## 3. إعداد نموذج Embeddings

```
python
openai_key = os.getenv("OPENAI_API_KEY")
openrouter_key = os.getenv("OPENROUTER_API_KEY")

if openai_key and openai_key.strip() and openai_key != "your_openai_api_key_here":
    print("Using OpenAI API for embeddings")
    embeddings = OpenAIEmbeddings(
        openai_api_key=openai_key,
        model="text-embedding-ada-002"
    )
elif openrouter_key and openrouter_key.strip() and openrouter_key != "your_openrouter_api_key_here":
    print("Using OpenRouter API for embeddings")
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
    print("WARNING: No valid embeddings API key found!")
    embeddings = None
```

**هدف Embeddings**: تحويل النصوص إلى متجهات عددية (Vectors) للبحث عن التشابه.

- **الأولوية الأولى**: OpenAI API
- **الاحتياطي**: OpenRouter (مجاني أكثر)
- **النموذج**: `text-embedding-ada-002`

---

## 4. إعداد نموذج اللغة (LLM)

```
python
llm = ChatOpenAI(
    openai_api_key=os.getenv("OPENROUTER_API_KEY"),
    openai_api_base="https://openrouter.ai/api/v1",
    model_name=os.getenv("OPENROUTER_MODEL", "openai/gpt-4o-mini"),
    temperature=0.1,
    default_headers={
        "HTTP-Referer": os.getenv("OPENROUTER_REFERRER", "http://localhost:8000"),
        "X-Title": "Smart Campus RAG",
    }
)
```

- **النموذج**: `openai/gpt-4o-mini` (صغير وسريع)
- **temperature=0.1**: إجابات أكثر deterministic (أقل إبداعاً)

---

## 5. قالب السؤال (Prompt Template)

```
python
prompt_template = PromptTemplate.from_template("""
You are a helpful assistant that answers questions about university regulations based ONLY on the provided context from PDF documents.

IMPORTANT RULES:
- Answer ONLY using the information provided in the context below
- If the information is not found in the context, respond with: "المعلومات غير موجودة في اللائحة" (for Arabic) or "Information not found in the regulations" (for English)
- Do not make up or assume any information
- Cite the source file name when providing answers
- Provide accurate, clear answers based on the context

Context from university regulations PDFs:
{context}

Question: {question}

Answer (respond in the same language as the question):
""")
```

هذا القالب يحدد:
- الإجابة **فقط** من السياق المقدم
- عدم اختلاق معلومات
- إذا لم تُوجد الإجابة → رسالة محددة (بالعربية أو الإنجليزية)
- ذكر اسم الملف المصدر

---

## 6. نماذج البيانات (Data Models)

```
python
class ChatRequest(BaseModel):
    question: str

class ChatResponse(BaseModel):
    success: bool
    answer: str
    sources: List[dict]
```

| الفئة | الوصف |
|-------|-------|
| `ChatRequest` | سؤال المستخدم |
| `ChatResponse` | إجابة النظام + المصادر |

---

## 7. نقطة النهاية الرئيسية (Main Endpoint)

```
python
@router.post("/", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """Chat endpoint with RAG"""
```

### الخطوة 1: التحقق من السؤال

```
python
if not request.question or not request.question.strip():
    raise HTTPException(status_code=400, detail="Question is required")
```

### الخطوة 2: التحقق من وجود وثائق مفهرسة

```
python
if not collection:
    raise HTTPException(
        status_code=400,
        detail="No PDFs have been indexed yet. Please upload PDFs first."
    )

count = collection.count()
if count == 0:
    raise HTTPException(
        status_code=400,
        detail="No PDFs have been indexed yet. Please upload PDFs first."
    )
```

### الخطوة 3: تحويل السؤال إلى متجه (Embed Question)

```
python
question_embedding = embeddings.embed_query(request.question)
```

- تحويل السؤال إلى متجه عددي يمثل semantic meaning

### الخطوة 4: البحث في ChromaDB

```
python
results = collection.query(
    query_embeddings=[question_embedding],
    n_results=5,
    include=["documents", "metadatas", "distances"]
)
```

- البحث عن **أقرب 5 أجزاء** (chunks) - Similarity Search
- إرجاع: الوثائق، البيانات الوصفية، المسافات (كلما اقل المسافة = أكثر تشابه)

### الخطوة 5: تصفية النتائج ذات الصلة

```
python
relevant_chunks = []
for i in range(len(context_chunks)):
    if context_distances[i] < 1.5:  # Threshold for relevance
        relevant_chunks.append({
            "text": context_chunks[i],
            "metadata": context_metadatas[i],
            "distance": context_distances[i]
        })
```

- تصفية chunks ذات المسافة > 1.5 (غير ذات صلة)

### الخطوة 6: بناء السياق

```python
context_string = "\n\n---\n\n".join([
    f"[Source: {chunk['metadata'].get('fileName', 'Unknown')}, Page: {chunk['metadata'].get('page', 'N/A')}]\n{chunk['text']}"
    for chunk in relevant_chunks
])
```

---

## 8. توليد الإجابة (Generate Answer)

```
python
prompt = prompt_template.format(
    context=context_string,
    question=request.question
)

response = llm.invoke(prompt)
answer = response.content if hasattr(response, 'content') else str(response)
```

1. **بناء السؤال** باستخدام القالب + السياق + السؤال
2. **إرسال لـ LLM** للحصول على الإجابة
3. استخراج الإجابة من response

---

## 9. تجهيز المصادر (Prepare Sources)

```
python
sources = []
seen = set()
for chunk in relevant_chunks:
    file_name = chunk['metadata'].get('fileName', 'Unknown')
    page = chunk['metadata'].get('page', 'N/A')
    key = f"{file_name}-{page}"
    if key not in seen:
        seen.add(key)
        sources.append({
            "file": file_name,
            "page": page,
            "textSnippet": chunk['text'][:300] + ("..." if len(chunk['text']) > 300 else "")
        })
```

- استخراج المصادر الفريدة (بدون تكرار)
- إرجاع: اسم الملف، رقم الصفحة، مقتطف من النص

---

## 10. إرجاع النتيجة

```
python
return ChatResponse(
    success=True,
    answer=answer,
    sources=sources
)
```

---

## ملخص تدفق النظام (System Flow)

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│  المستخدم   │───▶│  FastAPI     │───▶│_embeddings_ │
│ (السؤال)     │    │  Endpoint    │    │ (تحويل لنص) │
└─────────────┘    └──────────────┘    └──────┬──────┘
                                              │
                                              ▼
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│المستخدم     │◀───│   LLM        │◀───│ ChromaDB    │
│(الإجابة)     │    │ (GPT-4)      │    │ (بحث متجه)  │
└─────────────┘    └──────────────┘    └─────────────┘
```

---

## مثال على الطلب/الاستجابة

### الطلب:
```
json
{
  "question": "ما هي شروط التخرج من الجامعة؟"
}
```

### الاستجابة:
```
json
{
  "success": true,
  "answer": "شروط التخرج تشمل:\n1. إتمام جميع المواد المطلوبة\n2. المعدل التراكمي لا يقل عن 2.0\n3. إكمال مشروع التخرج",
  "sources": [
    {
      "file": "university_regulations_2024.pdf",
      "page": 45,
      "textSnippet": "شروط التخرج يجب أن يكون..."
    }
  ]
}
