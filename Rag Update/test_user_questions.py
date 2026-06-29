import sys
import io
import time
import json
from chat_cli import RAGSession
import chat_cli

class DummyCatalog:
    is_built = True
    courses = []
    def __init__(self, *args, **kwargs): pass
    def build(self): return 0
    def query(self, **kwargs): return []
chat_cli.CourseCatalog = DummyCatalog

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

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
    "طالب رسب في 3 مقررات في مستوى واحد في كلية الهندسة أو الحاسبات → هل يُفصل أم يُنذر أكاديمياً؟",
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

def main():
    print("Initializing RAG Session...")
    session = RAGSession(top_k=8, rerank_method="cosine", show_debug=False, citation_mode="footer")
    
    results = []
    
    # Generate markdown string directly
    md_output = "# نتائج اختبار الأسئلة الشاملة\n\n"
    
    for i, q in enumerate(questions):
        print(f"[{i+1}/{len(questions)}] Testing: {q}")
        try:
            res = session.get_rag_response(q)
            ans = res.get('answer', 'ERROR/EMPTY')
            sources = res.get("reranked", [])
            source_names = list(set([r.get("metadata", {}).get("fileName", "") for r in sources]))
            
            md_output += f"### سؤال {i+1}:\n**{q}**\n\n"
            md_output += f"**الإجابة:**\n{ans}\n\n"
            md_output += f"**المصادر المستخرجة:** {', '.join(source_names)}\n"
            md_output += "---\n\n"
            
            # Save progress incrementally to avoid data loss on crash
            with open("C:/Users/Right Click/.gemini/antigravity/brain/cf0ea8bc-79f2-4638-b749-b5e8c92f36dd/comprehensive_test_results.md", "w", encoding="utf-8") as f:
                f.write(md_output)
                
            if i < len(questions) - 1:
                time.sleep(15)  # Respect API rate limits (15s to be safe)
                
        except Exception as e:
            print(f"Error on question {i+1}: {e}")
            
    print("Done! Results saved to artifact.")

if __name__ == "__main__":
    main()
