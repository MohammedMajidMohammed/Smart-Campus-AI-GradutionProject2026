import os
import sys
from dotenv import load_dotenv

sys.path.append(r"d:/Last_Version_Final_Gradution_Project_2026/Rag Update")
sys.stdout.reconfigure(encoding="utf-8")

load_dotenv()

import chromadb
from chromadb.config import Settings
from routes.chat import collection, embeddings, llm, _get_bm25_index, _translate_query_to_arabic
from routes.retrieval.query_understanding import understand_query
from routes.retrieval.hybrid_search import hybrid_search
from routes.retrieval.reranker import rerank_results
from routes.chat import _build_context, _PROMPT, _PROMPT_LEGAL

question = "دلوقتي أنا ال gpa بتاعي 2.5 و أنا فرقه رابعه اسجل كام ماده و ايه الحد الاقصي لعد الساعات اللي ممكن اسجلها و ايه المواد اللي اسجلها في كلية الحاسبات والذكاء الاصطناعي قسم برنامج إنترنت الأشياء وتحليل البيانات الضخمة"

print("--- Query Understanding ---")
query_intent = understand_query(question, llm=llm)
print(f"Intent: {query_intent.intent}")
print(f"Program: {query_intent.program}")
print(f"Year: {query_intent.year}")
print(f"Semester: {query_intent.semester}")
print(f"Clean query: {query_intent.clean_query}")

print("\n--- Retrieval ---")
bm25_idx = _get_bm25_index()
retrieval_query = _translate_query_to_arabic(query_intent.clean_query, "arabic")

retrieval_output = hybrid_search(
    query                  = retrieval_query,
    collection             = collection,
    embeddings             = embeddings,
    bm25_index             = bm25_idx,
    top_k                  = 15,
    dense_candidates       = 100,
    sparse_candidates      = 100,
    use_rrf                = True,
    use_query_understanding = True,
    use_multi_query        = True,
    use_section_boost      = True,
    query_intent           = query_intent,
    llm                    = llm,
)

candidates = retrieval_output["results"]
print(f"Retrieved {len(candidates)} candidates.")

print("\n--- Reranking ---")
reranked = rerank_results(
    query          = query_intent.clean_query,
    candidates     = candidates,
    embeddings     = embeddings,
    top_n          = 8,
    original_query = question,
)

print(f"Reranked top candidates:")
for idx, r in enumerate(reranked):
    meta = r.get("metadata", {})
    score = r.get("rerank_score", 0.0)
    print(f"{idx+1}. File: {meta.get('fileName')}, Page: {meta.get('page')}, Score: {score:.4f}")
    print(f"   Snippet (150 chars): {r.get('text')[:150].strip()}")

print("\n--- Context Building ---")
context_str = _build_context(reranked)
print(f"Context length: {len(context_str)} characters")

print("\n--- LLM Generation ---")
_template = _PROMPT_LEGAL # since advising contains warning/GPA
prompt = _template.format(context=context_str, question=question)
response = llm.invoke(prompt)
answer = response.content if hasattr(response, "content") else str(response)
print("Answer:")
print(answer)
