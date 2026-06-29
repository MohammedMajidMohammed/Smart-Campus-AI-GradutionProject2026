import os
import sys
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI
from langchain_core.prompts import PromptTemplate

sys.stdout.reconfigure(encoding='utf-8')
load_dotenv()

_PROMPT = PromptTemplate.from_template("""\
أنت مساعد أكاديمي دقيق جداً متخصص في لوائح جامعة المنوفية الأهلية.

القاعدة الذهبية:
- أجب **فقط** بناءً على السياق المرفق من ملفات PDF الرسمية.
- إذا لم تجد الإجابة → قل بالضبط:
  عربي: "عذرًا، هذه المعلومة غير متوفرة في اللوائح الحالية المرفقة لدينا. لمزيد من الاستفسارات يُمكنك التواصل مع إدارة الكلية أو شؤون الطلاب."
  English: "Sorry, this information is not available in the currently provided regulations. For further inquiries, please contact the respective faculty administration or student affairs office."

قواعد هامة:
- أجب بنفس لغة السؤال تماماً (لا تخلط العربي بالإنجليزي).
- إذا كان السؤال بالإنجليزي والسياق بالعربي → ترجم الحقائق والأرقام بدقة وأجب بالإنجليزي.
- ابدأ الإجابة بذكر اسم الكلية/البرنامج إذا كان السؤال خاصاً بكلية محددة، أو اذكر "في جامعة المنوفية الأهلية" إذا كان السؤال عاماً بالجامعة.
- قدم الإجابة بشكل منظم باستخدام نقاط (•) وأرقام جريئة للأرقام المهمة (ساعات، نسب، درجات).

السياق المتاح:
{context}

السؤال:
{question}

الإجابة المباشرة والدقيقة:""")

context = """[Chunk 1 | File: لائحة الجامعة الأهلية.pdf | Page: 62]
يحق للطالب التعبير عن رأيه بحرية ضمن الأطر القانونية والجامعية."""

question = "من هو رئيس جامعة المنوفية الأهلية؟"

llm = ChatOpenAI(
    openai_api_key=os.getenv("OPENROUTER_API_KEY"),
    openai_api_base="https://openrouter.ai/api/v1",
    model_name="google/gemma-4-31b-it:free",
    temperature=0.1,
    default_headers={
        "HTTP-Referer": "http://localhost:8000",
        "X-Title": "Test",
    }
)

prompt = _PROMPT.format(context=context, question=question)
resp = llm.invoke(prompt)
print("Response:")
print(resp.content)
