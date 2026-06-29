import sys
import io
import os
import json

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from chat_cli import RAGSession

# Force stdout/stderr to UTF-8
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# The 30 questions
questions = [
    # الفئة 1
    "متى أُنشئت جامعة المنوفية الأهلية؟ وما هو رقم القرار الجمهوري؟",
    "كم كلية وكم برنامج دراسي في الجامعة حالياً؟ (اذكر مثالين على كليات).",
    "ما هي الرؤية الرسمية للجامعة؟",
    "ما هي الرسالة الرسمية للجامعة؟",
    "أين تقع الجامعة جغرافياً (الطريق)؟",
    
    # الفئة 2
    "الدراسة في الجامعة بنظام إيه؟ (ساعات معتمدة ولا سنوي؟)",
    "ما هو أقصى عدد ساعات يمكن للطالب تسجيلها في الفصل الدراسي العادي (خريف/ربيع) في كلية الحاسبات مثلاً؟",
    "ما الفرق بين إيقاف القيد وإلغاء القيد؟ وما هي الشروط الأساسية لكل منهما؟",
    "متى يُسمح للطالب بتقديم طلب إعادة قيد بعد إلغائه؟",
    "ما هي قواعد الحذف والإضافة للمقررات؟",
    
    # الفئة 3
    "ما هي نسبة أعمال السنة والامتحان النهائي في معظم المقررات في برنامج الطب والجراحة؟",
    "ما هي الدرجة المطلوبة للنجاح في مقرر عادي في برنامج الطب (النسبة المئوية)؟",
    "ما معنى التقدير BF في نظام التقييم؟",
    "لو طالب رسب في مقرر، ما هو أعلى تقدير يمكنه الحصول عليه عند إعادة المقرر؟",
    "ما هي شروط الانتقال من مستوى دراسي لآخر في برنامج الطب؟",
    
    # الفئة 4
    "ما هي شروط القبول في برنامج إنترنت الأشياء وتحليل البيانات الضخمة بكلية الحاسبات؟",
    "كم سنة (أو مستوى) مدة دراسة البكالوريوس في برنامج الطب والجراحة؟ وكم ساعة معتمدة تقريباً؟",
    "ما هي المسارات المتاحة في برنامج علوم التمريض؟",
    "في برنامج الصيدلة الإكلينيكية، هل هناك سنة امتياز؟",
    "ما متطلبات التخرج في برنامج العلاج الطبيعي؟",
    
    # الفئة 5
    "طالب في الطب غاب عن الامتحان النهائي بعذر مقبول → ما التقدير الذي يحصل عليه وماذا يحدث بعد كده؟",
    "طالب رسب في 3 مقررارت في مستوى واحد في كلية الهندسة أو الحاسبات → هل يُفصل أم يُنذر أكاديمياً؟",
    "لو طالب يريد تحويل من جامعة أخرى إلى المنوفية الأهلية، ما الإجراءات؟",
    "ما هي حقوق الطالب الأكاديمية والشخصية حسب الميثاق الأخلاقي؟",
    "طالب يريد إيقاف قيد لمدة سنة بسبب ظروف شخصية → ما الخطوات الصحيحة التي يجب اتباعها؟",
    
    # Bonus
    "ما الفرق بين W و FW في نظام التقييم؟",
    "هل درجات المقررات الاختيارية أو متطلبات الجامعة تدخل في المجموع التراكمي (GPA)؟",
    "من المسؤول عن الإرشاد الأكاديمي للطالب؟",
    "ما هي عقوبات المخالفات التأديبية (مثال واحد على الأقل)؟",
    "أين يمكن للطالب الرجوع لخريطة الحرم الجامعي؟"
]

class MockLLMResponse:
    def __init__(self, content):
        self.content = content

class MockLLM:
    def __init__(self):
        self.invocations = []
    def invoke(self, prompt):
        self.invocations.append(prompt)
        # We return the prompt itself so it's captured in get_rag_response's answer field
        return MockLLMResponse(prompt)

def main():
    print("Initializing RAG Session for Extraction...")
    session = RAGSession(top_k=8, rerank_method="cosine", show_debug=False, citation_mode="footer")
    
    # Replace session's LLM with our MockLLM
    mock_llm = MockLLM()
    session.llm = mock_llm
    
    extracted_data = []
    
    for i, q in enumerate(questions):
        print(f"[{i+1}/{len(questions)}] Extracting context for: {q}")
        res = session.get_rag_response(q)
        
        # The answer contains the prompt (which contains the context_str and system prompt)
        full_prompt = res.get("answer", "")
        sources = res.get("reranked", [])
        source_names = list(set([doc.get("metadata", {}).get("fileName", "") for doc in sources]))
        
        extracted_data.append({
            "index": i + 1,
            "question": q,
            "prompt": full_prompt,
            "sources": sources,
            "source_names": source_names
        })
        
    output_path = "scratch/extracted_contexts.json"
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(extracted_data, f, ensure_ascii=False, indent=2)
        
    print(f"Extraction completed successfully! Saved to {output_path}")

if __name__ == "__main__":
    main()
