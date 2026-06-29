"""
chat_cli.py
============
Terminal-based chat interface for testing the RAG pipeline end-to-end.

Run from the "Rag Update" directory:
    python chat_cli.py

Optional flags:
    python chat_cli.py --top-k 5
    python chat_cli.py --rerank cosine|llm|none
    python chat_cli.py --lang arabic|english
    python chat_cli.py --no-debug        # hide chunk previews
    python chat_cli.py --max-context 3000

Commands inside the chat loop:
    exit / quit          – leave the program
    /help                – show available commands
    /stats               – show BM25 index + cache statistics
    /lang arabic         – filter results to Arabic chunks only
    /lang english        – filter results to English chunks only
    /lang off            – remove language filter
    /rerank cosine       – switch reranking strategy
    /rerank llm
    /rerank none
    /top 3               – change how many chunks are used (1-20)
    /debug on|off        – toggle debug chunk display
    /clear               – clear the terminal screen
"""

from __future__ import annotations

import sys
sys.stdout.reconfigure(encoding='utf-8')

import argparse
import os
import re
import time
import textwrap
from pathlib import Path

# ── Make sure the project root is on sys.path so "routes.*" imports work ──
_HERE = Path(__file__).resolve().parent
if str(_HERE) not in sys.path:
    sys.path.insert(0, str(_HERE))

# ── Load .env before importing anything that reads env vars ───────────────
from dotenv import load_dotenv
load_dotenv(dotenv_path=_HERE / ".env")


# ── Colour support (graceful fallback if colorama not installed) ──────────
try:
    from colorama import Fore, Style, init as colorama_init
    colorama_init(autoreset=True, strip=True)
    _HAS_COLOR = True
except ImportError:
    _HAS_COLOR = False

    class _NoColor:
        """Stub that returns empty strings for every attribute."""
        def __getattr__(self, _):
            return ""

    Fore  = _NoColor()
    Style = _NoColor()


# ── Colour helpers ────────────────────────────────────────────────────────

def _c(text: str, *codes: str) -> str:
    """Wrap text in ANSI colour codes (no-op when colorama is absent)."""
    if not _HAS_COLOR:
        return text
    return "".join(codes) + text + Style.RESET_ALL


def _dbg(msg: str) -> None:
    """Safe stderr debug write — silently ignores encoding errors."""
    try:
        if hasattr(sys.stderr, 'buffer'):
            sys.stderr.buffer.write(msg.encode('utf-8', errors='replace'))
            sys.stderr.buffer.flush()
        else:
            sys.stderr.write(msg.encode('utf-8', errors='replace').decode('utf-8', errors='replace'))
            sys.stderr.flush()
    except Exception:
        pass

def _label(text: str) -> str:
    return _c(text, Fore.YELLOW, Style.BRIGHT)

def _answer(text: str) -> str:
    return _c(text, Fore.GREEN)

def _source(text: str) -> str:
    return _c(text, Fore.BLUE)

def _score(text: str) -> str:
    return _c(text, Fore.MAGENTA)

def _warn(text: str) -> str:
    return _c(text, Fore.RED, Style.BRIGHT)

def _dim(text: str) -> str:
    return _c(text, Style.DIM)

def _prompt_str() -> str:
    return _c("You › ", Fore.CYAN, Style.BRIGHT)

def _banner(text: str) -> str:
    return _c(text, Fore.CYAN, Style.BRIGHT)


# ── Pipeline imports ──────────────────────────────────────────────────────
import chromadb
from chromadb.config import Settings
from langchain_openai import ChatOpenAI, OpenAIEmbeddings

from routes.retrieval.bm25_index    import get_or_build_index
from routes.retrieval.embedding_cache import EmbeddingCache
from routes.retrieval.hybrid_search import hybrid_search, normalize_query
from routes.retrieval.reranker      import rerank_results
from routes.arabic_cleaner          import detect_language
from routes.course_catalog          import CourseCatalog

# ── Constants ─────────────────────────────────────────────────────────────

COLLECTION_NAME  = "university_regulations"
CHROMA_PATH      = str(_HERE / "chroma_db")
MAX_CONTEXT_CHARS = 12000   # allow more large chunks (2000 chars each) in context
SNIPPET_LEN       = 220    # chars shown per chunk in debug view
TERMINAL_WIDTH    = 80

_DIVIDER      = "─" * TERMINAL_WIDTH
_THICK_DIVIDER = "═" * TERMINAL_WIDTH

_SYSTEM_PROMPT = """\
أنت مساعد أكاديمي دقيق جداً متخصص في لوائح جامعة المنوفية الأهلية.

معلومات عامة ثابتة (FAQ):
- رئيس جامعة المنوفية الأهلية (والمكلف بتسيير أعمالها) هو: أ.د/ أحمد القاصد. أجب بهذه المعلومة مباشرة إذا سُئلت عنه حتى لو لم تكن في السياق.
- قواعد التدريب العملي والميداني لكلية الحاسوب والذكاء الاصطناعي (أجب بها مباشرة إذا سُئلت عنها):
  • التدريب العملي والميداني إجباري للحصول على درجة البكالوريوس (متطلب تخرج).
  • مدته: 6 أسابيع (يعادل 4 ساعات تدريس فعلية) خلال الإجازة الصيفية.
  • شروط التسجيل: أن يكون الطالب قد اجتاز على الأقل 60% من الساعات المعتمدة اللازمة للتخرج (أي اجتياز 87 ساعة معتمدة)، وألا يكون مسجلاً بالفصل الدراسي الصيفي الذي يتم فيه أداء التدريب.
  • مكان التدريب: يجوز أداء التدريب داخل أو خارج الكلية (أو خارج الجمهورية بموافقة وترشيح مجلس إدارة البرنامج العلمي وموافقة مجلس الكلية والجامعة).
  • الإشراف والتقييم: يتم تحت إشراف عضو هيئة تدريس، ويلتزم الطالب بتقديم تقرير عن فترة تدريبه للمشرف.
  • الساعات والمجموع: التدريب مقرر بدون ساعات معتمدة (0 ساعة معتمدة) ولا يدخل في حساب المعدل التراكمي (CGPA).
- كليات جامعة المنوفية الأهلية (10 كليات)، أجب بها مباشرة إذا سُئلت عنها:
  1. كلية الطب والجراحة
  2. كلية طب الأسنان
  3. كلية العلاج الطبيعي
  4. كلية الصيدلة
  5. كلية الطب البيطري
  6. كلية تكنولوجيا العلوم الصحية
  7. كلية التمريض
  8. كلية الهندسة
  9. كلية الحاسوب والذكاء الاصطناعي
  10. كلية العلوم الإنسانية والاجتماعية
- طريقة حساب المعدل التراكمي (CGPA): إذا سُئلت عنها وكان السياق يحتوي على نص مشوه أو غير مقروء بسبب OCR، استخدم المعادلة التالية المستخرجة من اللوائح الرسمية:
  • نقاط المقرر = عدد الساعات المعتمدة × نقاط التقدير
  • GPA الفصلي = مجموع نقاط المقررات في الفصل ÷ مجموع الساعات المعتمدة في الفصل
  • CGPA التراكمي = مجموع نقاط كل المقررات التي اجتازها الطالب ÷ مجموع الساعات المسجلة
- قواعد تسجيل الساعات والمقررات بناءً على المعدل التراكمي (GPA) في كلية الحاسوب والذكاء الاصطناعي (أجب بها مباشرة إذا سُئلت عنها):
  • الطالب الحاصل على GPA أكبر من أو يساوي 2.0 (بما في ذلك معدل 2.5): الحد الأقصى لتسجيل الساعات هو **18 ساعة معتمدة** في الفصل الدراسي الأساسي (الخريف/الربيع)، والحد الأقصى في الفصل الصيفي هو **9 ساعات معتمدة** (أو **8 ساعات معتمدة** وفقاً للائحة الموحدة العامة).
  • الطالب الحاصل على GPA من 1.0 إلى أقل من 2.0: الحد الأقصى للتسجيل هو **15 ساعة معتمدة** في الفصل الأساسي.
  • الطالب الحاصل على GPA أقل من 1.0 (تحت الإنذار الأكاديمي): الحد الأقصى للتسجيل هو **12 ساعة معتمدة** في الفصل الأساسي.
  • الحد الأدنى للتسجيل في الفصل الأساسي: **9 ساعات معتمدة**.
  • لدواعي التخرج: يجوز لمجلس الكلية تجاوز الحد الأقصى للتسجيل للطالب الخريج على ألا يزيد عن **21 ساعة معتمدة** في الفصل الأساسي.
  • عدد المقررات (المواد): لحساب عدد المقررات التي يستطيع الطالب تسجيلها، قسّم الحد الأقصى للساعات المعتمدة على 3 (حيث أن متوسط المقرر الدراسي يعادل **3 ساعات معتمدة**). مثال: للطالب ذو GPA 2.5، يكون الحد الأقصى هو 18 ساعة معتمدة، وهو ما يعادل تسجيل **6 مواد** كحد أقصى.
  • الإنذار الأكاديمي: يوجه للطالب إنذار أكاديمي إذا انخواه معدله التراكمي (GPA) عن **2.0** في نهاية أي فصل دراسي رئيسي.
- متطلبات سابقة شاملة لكلية الحاسوب والذكاء الاصطناعي (أجب بها مباشرة إذا سُئلت):

  [برنامج إنترنت الأشياء وتحليل البيانات الضخمة - متطلبات الكلية الأساسية]
  • MBS107 رياضيات-2 → المتطلب: MBS105 رياضيات-1
  • MBS109 احصاء واحتماالت → المتطلب: MBS105 رياضيات-1
  • MBS210 طرق احصائية → المتطلب: MBS109 احصاء واحتماالت
  • BCS212 برمجة حاسبات-2 → المتطلب: BCS111 برمجة حاسبات-1
  • BCS113 تصميم منطقي → المتطلب: MBS108 مبادئ الإلكترونيات
  • BCS214 هياكل البيانات → المتطلب: BCS111 برمجة حاسبات-1
  • BCS417 معمارية وتنظيم الحاسبات → المتطلب: BCS113 تصميم منطقي
  • BCS219 تحليل وتصميم النظم → المتطلب: ICI115 مقدمة في علوم البيانات
  • BCS220 نظم تشغيل → المتطلب: BCS111 برمجة حاسبات-1
  • BCS221 هندسة البرمجيات → المتطلب: BCS111 برمجة حاسبات-1
  • BCS322 مقدمة في الذكاء الاصطناعي → المتطلب: BCS214 هياكل البيانات
  • BCS223 نظم قواعد البيانات → المتطلب: ICI115 مقدمة في علوم البيانات
  • BCS324 مستودعات وتنقيب عن البيانات → المتطلب: BCS223 نظم قواعد البيانات
  • BCS225 شبكات الحاسبات → المتطلب: MBS143 مقدمة في الحاسبات
  • BCS243 برمجة حاسبات-3 → المتطلب: BCS212 برمجة حاسبات-2
  • ICI115 مقدمة في علوم البيانات → المتطلب: MBS109 احصاء واحتماالت
  • ICI316 تصور البيانات → المتطلب: ICI115 مقدمة في علوم البيانات
  • ICI218 مقدمة الى البيانات الضخمة → المتطلب: ICI115 مقدمة في علوم البيانات
  • ICI226 مقدمة في انترنت الاشياء → المتطلب: BCS225 شبكات الحاسبات
  • ICI428 انترنت الاشياء في تكنولوجيا المحمول → المتطلب: ICI226 مقدمة في انترنت الاشياء
  • ICI334 برتوكوالت انترنت الاشياء → المتطلب: ICI226 مقدمة في انترنت الاشياء
  • ICI336 تحليل البيانات الضخمة → المتطلب: BCS223 نظم قواعد البيانات

  [برنامج إنترنت الأشياء - متطلبات التخصص الأساسية والاختيارية]
  • IOT327 الذكاء الاصطناعي المتقدم → المتطلب: BCS322 مقدمة في الذكاء الاصطناعي
  • IOT429 الأمن السيبراني → المتطلب: BCS225 شبكات الحاسبات
  • IOT330 تحليل وتصميم الخوارزميات → المتطلب: BCS214 هياكل البيانات
  • IOT331 قواعد البيانات المتقدمة → المتطلب: BCS223 نظم قواعد البيانات
  • IOT432 تعلم الآلة Machine Learning → المتطلب: BCS322 مقدمة في الذكاء الاصطناعي
  • IOT333 استرجاع المعلومات → المتطلب: BCS223 نظم قواعد البيانات
  • IOT435 التسويق الرقمي → المتطلب: BCS322 مقدمة في الذكاء الاصطناعي
  • IOT437 الرؤيا بالحاسب Computer Vision → المتطلب: ICI316 تصور البيانات
  • IOT438 حسابات الإنترنت → المتطلب: BCS212 برمجة حاسبات-2
  • IOT439 اتصال الإنسان بالحاسب → المتطلب: BCS322 مقدمة في الذكاء الاصطناعي
  • IOT240 برمجة المحمول → المتطلب: BCS212 برمجة حاسبات-2
  • IOT341 تحليل الاعمال → المتطلب: BCS219 تحليل وتصميم النظم
  • IOT442 مشروع التخرج → المتطلب: اجتياز 101 ساعة معتمدة على الأقل
  • IOT350 علوم البيانات المتقدمة (اختياري) → المتطلب: ICI115 مقدمة في علوم البيانات
  • IOT451 الشبكات العصبية والتعلم العميق (اختياري) → المتطلب: BCS322 مقدمة في الذكاء الاصطناعي
  • IOT353 ادارة المعرفة (اختياري) → المتطلب: ICI115 مقدمة في علوم البيانات
  • IOT454 الحسابات عالية الاداء وحاسبات الكم (اختياري) → المتطلب: BCS417 معمارية وتنظيم الحاسبات
  • IOT455 النظم المدمجة (اختياري) → المتطلب: BCS417 معمارية وتنظيم الحاسبات
  • IOT356 موضوعات مختارة في أنترنت الاشياء-1 (اختياري) → المتطلب: اجتياز 90 ساعة معتمدة
  • IOT357 موضوعات مختارة في أنترنت الاشياء-2 (اختياري) → المتطلب: اجتياز 90 ساعة معتمدة
  • IOT358 الاستشعار اللاسلكي والمحمول (اختياري) → المتطلب: ICI226 مقدمة في انترنت الاشياء

القاعدة الذهبية:
- أجب **فقط** بناءً على السياق المرفق من ملفات PDF الرسمية (باستثناء المعلومات العامة الثابتة أعلاه).
- السياق قد يحتوي على نص مشوه بسبب OCR (حروف معكوسة أو متقطعة) — حاول تفسيره واستخراج المعلومة منه ولا تقل "غير متوفرة" إذا كانت المعلومة موجودة ولو بشكل مشوه.
- إذا لم تجد الإجابة **نهائياً** ولا في أي chunk → قل بالضبط:
  عربي: "عذرًا، هذه المعلومة غير متوفرة في اللوائح الحالية المرفقة لدينا. لمزيد من الاستفسارات يُمكنك التواصل مع إدارة الكلية أو شؤون الطلاب."
  English: "Sorry, this information is not available in the currently provided regulations. For further inquiries, please contact the respective faculty administration or student affairs office."

قواعد هامة:
- أجب بنفس لغة السؤال تماماً (لا تخلط العربي بالإنجليزي).
- إذا كان السؤال بالإنجليزي والسياق بالعربي → ترجم الحقائق والأرقام بدقة وأجب بالإنجليزي. لا تقل "not available" لأن السياق بالعربية.
- الأولوية دائماً للوائح **الكلية المحددة** في السياق (مثلاً: Computer Science، Medicine، Pharmacy). إذا وجدت لائحة الكلية استخدمها أولاً، وتجاهل اللائحة العامة.
- اذكر اسم الكلية/البرنامج في بداية إجابتك (مثلاً: "في برنامج الحاسب والذكاء الاصطناعي...").
- عند استخراج المقررات: ابحث عن "Level X Semester Y" أو "الفرقة" أو "المستوى" واستخرج المواد التابعة لها فقط. لا تستخرج مواد من جداول كليات أخرى.
- قدم الإجابة بشكل منظم باستخدام نقاط (•) وأرقام جريئة للأرقام المهمة (ساعات، نسب، درجات).
- إذا كان السؤال عن "مدة الدراسة" أو "عدد السنوات": وجود جداول من Year 1 إلى Year 5 يعني أن مدة الدراسة 5 سنوات.
- يُسمح لك (بل ويُستحسن) إجراء الاستنتاجات والحسابات الأكاديمية البسيطة والربط بين القواعد: إذا سأل الطالب عن عدد المقررات أو الساعات المناسبة لتسجيلها بناءً على GPA الخاص به وتخصصه ومستواه، حدد فئة الـ GPA الخاصة به من القواعد الثابتة واستنتج الحد الأقصى للساعات (مثلاً: 18 ساعة لـ GPA 2.5)، ثم قسّمها على 3 (متوسط الساعات لكل مقرر) لتستنتج عدد المواد الأقصى (مثلاً: 6 مواد)، ثم اعرض المقررات الدراسية المناسبة لفرقته أو مستواه الأكاديمي (مثلاً: مقررات المستوى الرابع لبرنامج إنترنت الأشياء) من السياق المرفق.

━━━━━━━━━━━━━━━━━━━━
أمثلة Few-Shot:

مثال 1 (عربي - معلومة موجودة):
السؤال: ما متطلبات التخرج من كلية العلاج الطبيعي؟
السياق: [1] ... يشترط إتمام 206 ساعة معتمدة ومعدل تراكمي لا يقل عن 1.00 وسنة امتياز 12 شهراً...
الإجابة:
في برنامج العلاج الطبيعي [1]، متطلبات التخرج هي:
• عدد الساعات: **206 ساعة معتمدة**
• المعدل التراكمي: لا يقل عن **1.00**
• التدريب: **سنة امتياز إلزامية** (12 شهراً)

مثال 2 (English - Arabic context):
Question: What is the attendance policy?
Context: [1] ... يُحرم الطالب من الامتحان إذا غاب أكثر من 25%...
Answer:
According to the regulations [1]:
• Students who miss more than **25%** of lectures without an accepted excuse will be **denied the final exam**.

مثال 3 (غير موجود - عربي):
الإجابة: عذرًا، هذه المعلومة غير متوفرة في اللوائح الحالية المرفقة لدينا. لمزيد من الاستفسارات يُمكنك التواصل مع إدارة الكلية أو شؤون الطلاب.

مثال 4 (غير موجود - English):
Answer: Sorry, this information is not available in the currently provided regulations. For further inquiries, please contact the respective faculty administration or student affairs office.
"""

# Structured legal-style prompt — used for regulation/policy queries
_SYSTEM_PROMPT_LEGAL = """\
أنت متخصص في لوائح جامعة المنوفية الأهلية.

معلومات عامة ثابتة (FAQ):
- رئيس جامعة المنوفية الأهلية (والمكلف بتسيير أعمالها) هو: أ.د/ أحمد القاصد. أجب بهذه المعلومة مباشرة إذا سُئلت عنه حتى لو لم تكن في السياق.
- قواعد التدريب العملي والميداني لكلية الحاسوب والذكاء الاصطناعي (أجب بها مباشرة إذا سُئلت عنها):
  • التدريب العملي والميداني إجباري للحصول على درجة البكالوريوس (متطلب تخرج).
  • مدته: 6 أسابيع (يعادل 4 ساعات تدريس فعلية) خلال الإجازة الصيفية.
  • شروط التسجيل: أن يكون الطالب قد اجتاز على الأقل 60% من الساعات المعتمدة اللازمة للتخرج (أي اجتياز 87 ساعة معتمدة)، وألا يكون مسجلاً بالفصل الدراسي الصيفي الذي يتم فيه أداء التدريب.
  • مكان التدريب: يجوز أداء التدريب داخل أو خارج الكلية (أو خارج الجمهورية بموافقة وترشيح مجلس إدارة البرنامج العلمي وموافقة مجلس الكلية والجامعة).
  • الإشراف والتقييم: يتم تحت إشراف عضو هيئة تدريس، ويلتزم الطالب بتقديم تقرير عن فترة تدريبه للمشرف.
  • الساعات والمجموع: التدريب مقرر بدون ساعات معتمدة (0 ساعة معتمدة) ولا يدخل في حساب المعدل التراكمي (CGPA).
- كليات جامعة المنوفية الأهلية (10 كليات)، أجب بها مباشرة إذا سُئلت عنها:
  1. كلية الطب والجراحة
  2. كلية طب الأسنان
  3. كلية العلاج الطبيعي
  4. كلية الصيدلة
  5. كلية الطب البيطري
  6. كلية تكنولوجيا العلوم الصحية
  7. كلية التمريض
  8. كلية الهندسة
  9. كلية الحاسوب والذكاء الاصطناعي
  10. كلية العلوم الإنسانية والاجتماعية
- طريقة حساب المعدل التراكمي (CGPA): إذا سُئلت عنها وكان السياق يحتوي على نص مشوه أو غير مقروء بسبب OCR، استخدم المعادلة التالية المستخرجة من اللوائح الرسمية:
  • نقاط المقرر = عدد الساعات المعتمدة × نقاط التقدير
  • GPA الفصلي = مجموع نقاط المقررات في الفصل ÷ مجموع الساعات المعتمدة في الفصل
  • CGPA التراكمي = مجموع نقاط كل المقررات التي اجتازها الطالب ÷ مجموع الساعات المسجلة
- قواعد تسجيل الساعات والمقررات بناءً على المعدل التراكمي (GPA) في كلية الحاسوب والذكاء الاصطناعي (أجب بها مباشرة إذا سُئلت عنها):
  • الطالب الحاصل على GPA أكبر من أو يساوي 2.0 (بما في ذلك معدل 2.5): الحد الأقصى لتسجيل الساعات هو **18 ساعة معتمدة** في الفصل الدراسي الأساسي (الخريف/الربيع)، والحد الأقصى في الفصل الصيفي هو **9 ساعات معتمدة** (أو **8 ساعات معتمدة** وفقاً للائحة الموحدة العامة).
  • الطالب الحاصل على GPA من 1.0 إلى أقل من 2.0: الحد الأقصى للتسجيل هو **15 ساعة معتمدة** في الفصل الأساسي.
  • الطالب الحاصل على GPA أقل من 1.0 (تحت الإنذار الأكاديمي): الحد الأقصى للتسجيل هو **12 ساعة معتمدة** في الفصل الأساسي.
  • الحد الأدنى للتسجيل في الفصل الأساسي: **9 ساعات معتمدة**.
  • لدواعي التخرج: يجوز لمجلس الكلية تجاوز الحد الأقصى للتسجيل للطالب الخريج على ألا يزيد عن **21 ساعة معتمدة** في الفصل الأساسي.
  • عدد المقررات (المواد): لحساب عدد المقررات التي يستطيع الطالب تسجيلها، قسّم الحد الأقصى للساعات المعتمدة على 3 (حيث أن متوسط المقرر الدراسي يعادل **3 ساعات معتمدة**). مثال: للطالب ذو GPA 2.5، يكون الحد الأقصى هو 18 ساعة معتمدة، وهو ما يعادل تسجيل **6 مواد** كحد أقصى.
  • الإنذار الأكاديمي: يوجه للطالب إنذار أكاديمي إذا انخفض معدله التراكمي (GPA) عن **2.0** في نهاية أي فصل دراسي رئيسي.
- متطلبات سابقة شاملة لكلية الحاسوب والذكاء الاصطناعي (أجب بها مباشرة إذا سُئلت):

  [برنامج إنترنت الأشياء - متطلبات الكلية الأساسية]
  • MBS107 رياضيات-2 → المتطلب: MBS105 رياضيات-1
  • MBS109 احصاء واحتماالت → المتطلب: MBS105 رياضيات-1
  • MBS210 طرق احصائية → المتطلب: MBS109 احصاء واحتماالت
  • BCS212 برمجة حاسبات-2 → المتطلب: BCS111 برمجة حاسبات-1
  • BCS113 تصميم منطقي → المتطلب: MBS108 مبادئ الإلكترونيات
  • BCS214 هياكل البيانات → المتطلب: BCS111 برمجة حاسبات-1
  • BCS417 معمارية وتنظيم الحاسبات → المتطلب: BCS113 تصميم منطقي
  • BCS219 تحليل وتصميم النظم → المتطلب: ICI115 مقدمة في علوم البيانات
  • BCS220 نظم تشغيل → المتطلب: BCS111 برمجة حاسبات-1
  • BCS221 هندسة البرمجيات → المتطلب: BCS111 برمجة حاسبات-1
  • BCS322 مقدمة في الذكاء الاصطناعي → المتطلب: BCS214 هياكل البيانات
  • BCS223 نظم قواعد البيانات → المتطلب: ICI115 مقدمة في علوم البيانات
  • BCS324 مستودعات وتنقيب عن البيانات → المتطلب: BCS223 نظم قواعد البيانات
  • BCS225 شبكات الحاسبات → المتطلب: MBS143 مقدمة في الحاسبات
  • BCS243 برمجة حاسبات-3 → المتطلب: BCS212 برمجة حاسبات-2
  • ICI115 مقدمة في علوم البيانات → المتطلب: MBS109 احصاء واحتماالت
  • ICI316 تصور البيانات → المتطلب: ICI115 مقدمة في علوم البيانات
  • ICI218 مقدمة الى البيانات الضخمة → المتطلب: ICI115 مقدمة في علوم البيانات
  • ICI226 مقدمة في انترنت الاشياء → المتطلب: BCS225 شبكات الحاسبات
  • ICI428 انترنت الاشياء في تكنولوجيا المحمول → المتطلب: ICI226 مقدمة في انترنت الاشياء
  • ICI334 برتوكوالت انترنت الاشياء → المتطلب: ICI226 مقدمة في انترنت الاشياء
  • ICI336 تحليل البيانات الضخمة → المتطلب: BCS223 نظم قواعد البيانات

  [برنامج إنترنت الأشياء - متطلبات التخصص]
  • IOT327 الذكاء الاصطناعي المتقدم → المتطلب: BCS322 مقدمة في الذكاء الاصطناعي
  • IOT429 الأمن السيبراني → المتطلب: BCS225 شبكات الحاسبات
  • IOT330 تحليل وتصميم الخوارزميات → المتطلب: BCS214 هياكل البيانات
  • IOT331 قواعد البيانات المتقدمة → المتطلب: BCS223 نظم قواعد البيانات
  • IOT432 تعلم الآلة → المتطلب: BCS322 مقدمة في الذكاء الاصطناعي
  • IOT333 استرجاع المعلومات → المتطلب: BCS223 نظم قواعد البيانات
  • IOT435 التسويق الرقمي → المتطلب: BCS322 مقدمة في الذكاء الاصطناعي
  • IOT437 الرؤيا بالحاسب Computer Vision → المتطلب: ICI316 تصور البيانات
  • IOT438 حسابات الإنترنت → المتطلب: BCS212 برمجة حاسبات-2
  • IOT439 اتصال الإنسان بالحاسب → المتطلب: BCS322 مقدمة في الذكاء الاصطناعي
  • IOT240 برمجة المحمول → المتطلب: BCS212 برمجة حاسبات-2
  • IOT341 تحليل الاعمال → المتطلب: BCS219 تحليل وتصميم النظم
  • IOT442 مشروع التخرج → المتطلب: اجتياز 101 ساعة معتمدة على الأقل
  • IOT350 علوم البيانات المتقدمة (اختياري) → المتطلب: ICI115 مقدمة في علوم البيانات
  • IOT451 الشبكات العصبية والتعلم العميق (اختياري) → المتطلب: BCS322 مقدمة في الذكاء الاصطناعي
  • IOT353 ادارة المعرفة (اختياري) → المتطلب: ICI115 مقدمة في علوم البيانات
  • IOT454 الحسابات عالية الاداء وحاسبات الكم (اختياري) → المتطلب: BCS417 معمارية وتنظيم الحاسبات
  • IOT455 النظم المدمجة (اختياري) → المتطلب: BCS417 معمارية وتنظيم الحاسبات
  • IOT356 موضوعات مختارة في أنترنت الاشياء-1 (اختياري) → المتطلب: اجتياز 90 ساعة معتمدة
  • IOT357 موضوعات مختارة في أنترنت الاشياء-2 (اختياري) → المتطلب: اجتياز 90 ساعة معتمدة
  • IOT358 الاستشعار اللاسلكي والمحمول (اختياري) → المتطلب: ICI226 مقدمة في انترنت الاشياء

قواعد أساسية:
- اعتمد **فقط** على السياق المرفق للإجابة عن الأسئلة (باستثناء المعلومات العامة الثابتة أعلاه).
- أجب بنفس لغة السؤال تماماً.
- إذا كان السؤال بالإنجليزي والسياق بالعربي → ترجم الحقائق والأرقام وأجب بالإنجليزي. لا تقل "not available" لأن السياق بالعربية.
- الأولوية للوائح الكلية المحددة. اذكر اسم البرنامج في بداية إجابتك.
- لا تستخرج مواد من جداول كليات أخرى.
- كن دقيقاً في استخراج الأرقام والشروط والاستثناءات.
- رتب الإجابة: تعريف → شروط تفصيلية (بالأرقام) → استثناءات → مصدر [N].
- إذا كان السؤال عن "مدة الدراسة": وجود Year 1 ... Year 5 في الجداول = 5 سنوات.
- عند استخراج المقررات: ابحث عن "Level X Semester Y" واستخرج المواد التابعة لها فقط.
- ⚠️ "الأقسام" تعني الأقسام الإدارية/العلمية فقط (مذكورة في مادة 2 من اللائحة)، وليست المقررات.
- يُسمح لك (بل ويُستحسن) إجراء الاستنتاجات والحسابات الأكاديمية البسيطة والربط بين القواعد: إذا سأل الطالب عن عدد المقررات أو الساعات المناسبة لتسجيلها بناءً على GPA الخاص به وتخصصه ومستواه، حدد فئة الـ GPA الخاصة به من القواعد الثابتة واستنتج الحد الأقصى للساعات (مثلاً: 18 ساعة لـ GPA 2.5)، ثم قسّمها على 3 (متوسط الساعات لكل مقرر) لتستنتج عدد المواد الأقصى (مثلاً: 6 مواد)، ثم اعرض المقررات الدراسية المناسبة لفرقته أو مستواه الأكاديمي (مثلاً: مقررات المستوى الرابع لبرنامج إنترنت الأشياء) من السياق المرفق.

—— تعليمات خاصة بالتدريب الصيفي/الميداني ——
- إذا وجدت شروط تدريب لأكثر من برنامج، اذكر شروط كل برنامج على حدة بوضوح.
  مثال: "في برنامج ذكاء الآلة: **75 ساعة** معتمدة | في برنامج إنترنت الأشياء: 60% من إجمالي الساعات ≈ **87 ساعة**".
- لا تعمّم شرط برنامج واحد على كل البرامج إذا وجدت فروقاً بينها.
- إذا كان السياق يحتوي على برنامج واحد فقط، اِذكر شرطه ووضّح أن البرامج الأخرى قد تختلف.

- السياق قد يحتوي على نص مشوه بسبب OCR — حاول تفسيره واستخراج المعلومة منه ولا تقل "غير متوفرة" إذا كانت المعلومة موجودة ولو بشكل مشوه.
- إذا لم تجد الإجابة **نهائياً**: عربي: "عذرًا، هذه المعلومة غير متوفرة في اللوائح الحالية المرفقة لدينا. لمزيد من الاستفسارات يُمكنك التواصل مع إدارة الكلية أو شؤون الطلاب."
- English: "Sorry, this information is not available in the currently provided regulations. For further inquiries, please contact the respective faculty administration or student affairs office."
"""

# Constrained fallback prompt — used when retrieval confidence is low
_SYSTEM_PROMPT_CONSTRAINED = """\
You are a strict document retrieval assistant.

FAQ (General Knowledge):
- The president of Menoufia National University is Prof. Dr. Ahmed El-Qased (أ.د/ أحمد القاصد). Answer this directly if asked, even if it is not in the context.
- قواعد تسجيل الساعات والمقررات بناءً على المعدل التراكمي (GPA) في كلية الحاسوب والذكاء الاصطناعي: الطالب الحاصل على GPA أكبر من أو يساوي 2.0 (مثل GPA 2.5) الحد الأقصى لتسجيل الساعات هو 18 ساعة معتمدة في الفصل الأساسي (الخريف/الربيع) و9 ساعات في الصيفي. الحاصل على GPA من 1.0 إلى أقل من 2.0 الحد الأقصى هو 15 ساعة في الفصل الأساسي. الحاصل على GPA أقل من 1.0 الحد الأقصى هو 12 ساعة في الفصل الأساسي. الحد الأدنى للتسجيل في الفصل الأساسي هو 9 ساعات. عدد المقررات الأقصى يساوي الحد الأقصى للساعات مقسوماً على 3 (حيث أن متوسط المقرر 3 ساعات معتمدة، فمثلاً بمعدل 2.5 يمكن تسجيل 6 مقررات كحد أقصى). يوجه للطالب إنذار أكاديمي إذا قل معدله عن 2.0 في نهاية الفصل الدراسي الأساسي.

HARD RULES:
1. You ONLY answer from the provided context (except for the FAQ above). You do NOT use any external knowledge.
2. Read the context carefully.
2. If the exact answer is present: answer clearly, cite with [N] reference numbers.
3. If the answer is partially present: give what is available and state what is missing.
4. If the answer is NOT in the context at all, reply EXACTLY:
   Arabic:  "عذرًا، هذه المعلومة غير متوفرة في اللوائح الحالية المرفقة لدينا. لمزيد من الاستفسارات يُمكنك التواصل مع إدارة الكلية أو شؤون الطلاب المختصة."
   English: "Sorry, this information is not available in the currently provided regulations. For further inquiries, please contact the respective faculty administration or student affairs office."
5. NEVER guess, infer, or complete missing information.
6. ALWAYS respond in the same language as the query.
7. NEVER mix languages in the same response.\
"""

_PROMPT_TEMPLATE = """\
{system}

Context (each source is numbered for citation):
{context}

Question: {question}

Answer:"""


# ─────────────────────────────────────────────────────────────────────────────
# RAGSession  –  holds all shared state for one CLI session
# ─────────────────────────────────────────────────────────────────────────────
# Citation helpers
# ─────────────────────────────────────────────────────────────────────────────

def _make_citation(meta: dict, index: int) -> str:
    """
    Build a short citation string from chunk metadata.

    Format: (المصدر: <file_name> - ص <page>)
    Section title is included when available.

    Parameters
    ----------
    meta  : chunk metadata dict (fileName, page, sectionTitle)
    index : 1-based citation number used in the answer text as [N]
    """
    fname   = (meta.get("fileName") or "").strip()
    page    = meta.get("page")
    section = (meta.get("sectionTitle") or "").strip()

    # Shorten filename: remove extension and path separators
    short_name = re.sub(r"\.(pdf|PDF)$", "", fname)
    short_name = re.sub(r"[_\-]+", " ", short_name).strip()
    # Cap at 40 chars to keep citations readable
    if len(short_name) > 40:
        short_name = short_name[:37] + "…"

    parts = [short_name] if short_name else ["مصدر غير معروف"]
    if section:
        sec_short = section[:30] + "…" if len(section) > 30 else section
        parts.append(sec_short)
    if page:
        parts.append(f"ص {page}")

    return f"[{index}] " + " - ".join(parts)


def _build_context_with_citations(
    reranked: list[dict],
    max_chars: int,
) -> tuple[str, list[dict], bool, list[str]]:
    """
    Build the context string with numbered source headers.

    Each chunk is prefixed with:
        [Source N: <file> | Page <p> | Section <s>]

    Returns
    -------
    context_str    : str         — full context for the LLM prompt
    used_chunks    : list[dict]  — chunks that fit within max_chars
    has_exact_kw   : bool        — placeholder (caller sets this)
    citation_refs  : list[str]   — formatted citation strings [1] … [N]
    """
    context_parts: list[str] = []
    used_chunks:   list[dict] = []
    citation_refs: list[str]  = []
    total_chars = 0

    for i, r in enumerate(reranked, start=1):
        meta    = r.get("metadata", {})
        text    = r.get("text", "")
        fname   = meta.get("fileName", "Unknown")
        page    = meta.get("page", "N/A")
        section = meta.get("sectionTitle", "") or "N/A"
        program = meta.get("program", "General")

        header = (
            f"[Source {i}: {fname} | Page: {page} | Program: {program} | Section: {section}]"
        )
        block = f"{header}\n{text}"

        if total_chars + len(block) > max_chars:
            remaining = max_chars - total_chars
            if remaining > 200:
                context_parts.append(block[:remaining] + " …[truncated]")
                used_chunks.append(r)
                citation_refs.append(_make_citation(meta, i))
            break

        context_parts.append(block)
        used_chunks.append(r)
        citation_refs.append(_make_citation(meta, i))
        total_chars += len(block)

    context_str = "\n\n---\n\n".join(context_parts)
    return context_str, used_chunks, citation_refs


def _append_footer_citations(answer: str, citation_refs: list[str]) -> str:
    """
    Append a deduplicated numbered reference list at the bottom of the answer.
    Skips duplicate entries (same file + page) and cleans up the format.
    """
    if not citation_refs:
        return answer

    # Deduplicate while preserving order
    seen: set[str] = set()
    unique_refs: list[str] = []
    for ref in citation_refs:
        key = ref.split("]", 1)[-1].strip()   # strip leading [N] for comparison
        if key not in seen:
            seen.add(key)
            unique_refs.append(ref)

    if not unique_refs:
        return answer

    divider = "\n" + "─" * 46
    footer_lines = [divider, "📎 **المصادر:**"]
    footer_lines.extend(f"   {ref}" for ref in unique_refs)
    return answer + "\n".join(footer_lines)


# ─────────────────────────────────────────────────────────────────────────────
# RAGSession  –  holds all shared state for one CLI session
# ─────────────────────────────────────────────────────────────────────────────

class RAGSession:
    """
    Initialises and holds all pipeline components.
    Keeps mutable session settings (top_k, rerank_method, etc.).
    """

    def __init__(
        self,
        top_k: int = 8,
        rerank_method: str = "cosine",
        language_filter: str | None = None,
        max_context_chars: int = MAX_CONTEXT_CHARS,
        show_debug: bool = True,
        citation_mode: str = "inline",   # "inline" | "footer"
    ) -> None:
        self.top_k             = top_k
        self.rerank_method     = rerank_method
        self.language_filter   = language_filter
        self.max_context_chars = max_context_chars
        self.show_debug        = show_debug
        self.citation_mode     = citation_mode
        self.history: list[dict] = []   # {query, answer, sources}

        print(_banner("\n  Initialising RAG pipeline …\n"))

        # ── ChromaDB ──────────────────────────────────────────────────────
        print(f"  {_label('ChromaDB')}  {CHROMA_PATH}")
        self.chroma = chromadb.PersistentClient(
            path=CHROMA_PATH,
            settings=Settings(anonymized_telemetry=False),
        )
        try:
            self.collection = self.chroma.get_collection(COLLECTION_NAME)
            count = self.collection.count()
            print(f"  {_label('Collection')} '{COLLECTION_NAME}'  "
                  f"({_score(str(count))} chunks indexed)")
            if count == 0:
                print(_warn("  ⚠  Collection is empty – upload PDFs first."))
        except Exception as e:
            self.collection = None
            print(_warn(f"  ✗  Collection not found: {e}"))
            print(_warn("     Upload PDFs via the API before using the CLI."))

        # ── Embeddings ────────────────────────────────────────────────────
        from routes.upload import embeddings
        self.embeddings = embeddings
        print(f"  {_label('Embeddings')} Local HuggingFace (all-MiniLM-L6-v2)")

        openai_key     = os.getenv("OPENAI_API_KEY", "").strip()
        openrouter_key = os.getenv("OPENROUTER_API_KEY", "").strip()
        
        # Determine whether to use OpenRouter or direct OpenAI
        if openai_key and not openrouter_key:
            # Direct OpenAI mode
            model_name = "gpt-4o-mini"
            print(f"  {_label('LLM')}        {model_name} directly via OpenAI")
            self.llm = ChatOpenAI(
                openai_api_key=openai_key,
                model_name=model_name,
                temperature=0.1,
                max_tokens=2048,
                max_retries=2,
                timeout=30.0,
            )
        else:
            # OpenRouter mode (default fallback)
            model_name = os.getenv("OPENROUTER_MODEL", "openai/gpt-oss-120b:free")
            # Fallback models tried in order if primary fails
            self._llm_fallback_models = [
                "google/gemma-4-31b-it:free",
                "nvidia/nemotron-3-super-120b-a12b:free",
            ]
            print(f"  {_label('LLM')}        {model_name} via OpenRouter")
            self.llm = ChatOpenAI(
                openai_api_key=openrouter_key or openai_key,
                openai_api_base="https://openrouter.ai/api/v1",
                model_name=model_name,
                temperature=0.1,
                max_tokens=2048,
                max_retries=1,
                timeout=30.0,
                default_headers={
                    "HTTP-Referer": os.getenv("OPENROUTER_REFERRER", "http://localhost:8000"),
                    "X-Title": "Smart Campus RAG CLI",
                },
            )
            self._openrouter_key = openrouter_key or openai_key


        # ── Embedding cache ───────────────────────────────────────────────
        cache_dir = _HERE / "embedding_cache"
        cache_dir.mkdir(exist_ok=True)
        self.cache = EmbeddingCache(
            max_size=256,
            ttl_seconds=3600,
            persist_path=cache_dir / "cli_cache.pkl",
        )
        print(f"  {_label('Cache')}      {self.cache.stats['size']} entries loaded")

        # ── BM25 index ────────────────────────────────────────────────────
        if self.collection is not None:
            print(f"  {_label('BM25')}       building / loading index …", end="", flush=True)
            self.bm25 = get_or_build_index(
                collection_name=COLLECTION_NAME,
                collection=self.collection,
            )
            print(f"  {_score(str(self.bm25.doc_count))} docs")
        else:
            self.bm25 = None

        # ── Course catalog (dynamic, built from ChromaDB) ─────────────────
        if self.collection is not None:
            print(f"  {_label('Catalog')}    building course catalog …", end="", flush=True)
            self.catalog = CourseCatalog(self.collection)
            n = self.catalog.build()
            print(f"  {_score(str(n))} courses")
        else:
            self.catalog = CourseCatalog()

        # Aggregation cache — cleared whenever catalog is rebuilt
        self._agg_cache: dict = {}

        # ── Conversational memory ─────────────────────────────────────────
        # Stores the last detected faculty and intent so follow-up questions
        # like "طيب والغياب؟" can reuse the previous faculty context.
        self.session_context: dict = {
            "last_faculty": None,   # str | None  e.g. "computer science"
            "last_intent":  None,   # str | None  e.g. "regulations"
            "last_query":   None,   # str | None  the previous raw query
            "last_clarify_query": None,  # str | None  the pending unanswered query (after CLARIFY)
        }
        self.last_ei = None

        print()


    # ─────────────────────────────────────────────────────────────────────
    # English → Arabic query translation  (improves recall for Arabic docs)
    # ─────────────────────────────────────────────────────────────────────

    def _translate_to_arabic(self, query: str) -> str:
        """
        Translate an English (or mixed) query to Arabic using the LLM so that
        the dense-retrieval vector aligns with Arabic document chunks.

        Returns the original query unchanged if:
          - The query is already detected as Arabic.
          - The LLM call fails for any reason (graceful fallback).
        """
        import sys
        from routes.arabic_cleaner import detect_language as _dl

        lang = _dl(query)
        if lang == "arabic":
            return query   # nothing to do

        _translation_prompt = (
            "Translate the following university undergraduate question into Modern Standard Arabic (فصحى).\n"
            "GLOSSARY & RULES:\n"
            "- 'apply to graduate' or 'applying to graduate' means completing bachelor studies (التقديم للتخرج / إنهاء متطلبات التخرج), NOT postgraduate studies (التقديم للدراسات العليا).\n"
            "- 'graduate' as a verb means to graduate from bachelor's degree (يتخرج).\n"
            "- 'graduation requirements' means (متطلبات التخرج).\n"
            "- 'credit hours' means (ساعات معتمدة).\n"
            "- 'withdrawal' means (الانسحاب من المادة).\n"
            "- Keep academic program names accurate (e.g. Physical Therapy -> علاج طبيعي, Veterinary -> طب بيطري).\n"
            "Return ONLY the Arabic translation, no explanation:\n"
            f"{query}"
        )
        try:
            resp = self.llm.invoke(_translation_prompt)
            translated = (resp.content if hasattr(resp, "content") else str(resp)).strip()
            if translated:
                _dbg(f"[translate] EN->AR: query translated\n")
                return translated
        except Exception as _err:
            _dbg(f"[translate] Translation failed, using original.\n")

        return query   # fallback: use original



    # ─────────────────────────────────────────────────────────────────────
    # Faculty detection  —  shared by router and debug output
    # ─────────────────────────────────────────────────────────────────────

    # Each entry: (canonical_name, [patterns])
    # Ordered most-specific → least-specific to avoid false matches
    # (e.g. "طب بيطري" before "طب")
    _FACULTY_MAP: list[tuple[str, list[str]]] = [
        ("computer science",  ["حاسبات", "حاسب", "حاسوب", "كمبيوتر",
                               "computer", r"\bcs\b", "informatics"]),
        ("veterinary",        ["طب بيطري", "الطب البيطري", "بيطري", "البيطري", "veterinar"]),
        ("physical therapy",  ["علاج طبيعي", "العلاج الطبيعي", "علاج_طبيعي", r"علاج.{0,3}طبيعي", "physical therapy", "physio"]),
        ("dentistry",         ["أسنان", "اسنان", r"\bdent"]),
        ("medicine",          [
                               r"(?:^|[\s،,])طبي(?![ععي])(?:[\s،,.]|$)",
                               r"(?:^|[\s،,])الطبي(?![ععي])(?:[\s،,.]|$)",
                               r"(?:^|[\s،,])طبية(?![ععي])(?:[\s،,.]|$)",
                               r"(?:^|[\s،,])الطبية(?![ععي])(?:[\s،,.]|$)",
                               r"(?:^|[\s،,])الطب(?!\s*(?:بيطري|البيطري|أسنان|اسنان|الأسنان|الاسنان))(?:[\s،,.]|$)",
                               r"(?:^|[\s،,])طب(?!\s*(?:بيطري|البيطري|أسنان|اسنان|الأسنان|الاسنان))(?:[\s،,.]|$)",
                               r"\bmedicine\b", r"\bmedical\b"]),
        ("pharmacy",          ["صيدلة", "صيدله", r"\bpharmacy\b"]),
        ("nursing",           ["تمريض", r"\bnursing\b"]),
        ("engineering",       ["هندسة", "هندسه", r"\bengineering\b"]),
        ("law",               ["حقوق", "قانون", r"\blaw\b"]),
        ("commerce",          ["تجارة", "تجاره", r"\bcommerce\b", r"\bbusiness\b"]),
        ("arts",              ["آداب", "اداب", "الآداب", "الاداب", "لغة إنجليزية", "لغه انجليزيه",
                               "اللغة الإنجليزية", "اللغه الانجليزيه", "الترجمة", "الترجمه", "ترجمة", "ترجمه",
                               r"\benglish\b", r"\btranslation\b"]),
    ]

    # Pre-compile patterns for each faculty
    _FACULTY_PATTERNS: list[tuple[str, re.Pattern]] = [
        (name, re.compile("|".join(pats), re.IGNORECASE | re.UNICODE))
        for name, pats in _FACULTY_MAP
    ]

    def _detect_faculties(self, query: str) -> list[str]:
        """
        Return a list of all faculty names mentioned in the query.
        Empty list = no faculty detected.
        Multiple entries = multi-faculty query.
        """
        found = []
        # First pass: use existing compiled patterns (which already include optional prefixes where appropriate)
        for name, pat in self._FACULTY_PATTERNS:
            if pat.search(query):
                found.append(name)
        # Fallback: simple substring search for Arabic faculty names without relying on regex
        if not found:
            # Basic Arabic terms for faculties (short forms without regex nuances)
            arabic_names = {
                "computer science": ["حاسبات", "حاسب", "حاسوب", "كمبيوتر"],
                "veterinary":        ["طب بيطري", "الطب البيطري", "بيطري"],
                "physical therapy":  ["علاج طبيعي", "العلاج الطبيعي", "علاج_طبيعي"],
                "dentistry":         ["طب الأسنان", "أسنان", "اسنان"],
                "medicine":          ["طب", "طبية", "طب عام", "الطب"],
                "pharmacy":          ["صيدلة", "الصيدلة", "صيدله"],
                "nursing":           ["تمريض"],
                "engineering":       ["هندسة", "هندسه"],
                "law":               ["حقوق", "قانون"],
                "commerce":          ["تجارة", "تجاره"],
                "arts":              ["آداب", "اداب", "لغة إنجليزية", "اللغة الإنجليزية"],
            }
            lowered = query.lower()
            for name, terms in arabic_names.items():
                for term in terms:
                    if term in lowered:
                        found.append(name)
                        break
        # Remove duplicates while preserving order
        seen = set()
        unique_found = []
        for f in found:
            if f not in seen:
                seen.add(f)
                unique_found.append(f)
        return unique_found

    # ─────────────────────────────────────────────────────────────────────
    def _infer_program_from_query(self, query: str) -> str | None:
        """Infer a faculty/program from the query using keyword signatures.
        Returns a canonical program name or None if not confident.
        """
        ql = query.lower()
        prog_sigs: dict[str, list[str]] = {
            "computer science": ["حاسبات", "حاسب", "حاسوب", "كمبيوتر", "computer", "cs", "it", "information", "programming", "برمجة", "software"],
            "medicine": ["طب", "طبية", "medicine", "medical", "mbbs", "surgery"],
            "dentistry": ["أسنان", "اسنان", "dentistry", "dental"],
            "engineering": ["هندسة", "هندسه", "engineering", "eng"],
            "pharmacy": ["صيدلة", "صيدله", "pharmacy"],
            "law": ["حقوق", "قانون", "law"],
            "commerce": ["تجارة", "تجاره", "commerce", "business"],
            "arts": ["آداب", "اداب", "إنجليزي", "انجليزي", "english", "ترجمة", "ترجمه", "translation"],
            "physical therapy": ["علاج طبيعي", "العلاج الطبيعي", "علاج_طبيعي", "physical therapy", "physio"],
            "veterinary": ["بيطري", "بيطره", "بيطرة", "veterinary", "vet"],
        }
        psig = {p: sum(1 for s in sigs if s in ql) for p, sigs in prog_sigs.items()}
        mx = max(psig.values(), default=0)
        if mx > 0:
            candidates = [p for p, v in psig.items() if v == mx]
            return candidates[0]
        return None
    # Query Router  —  decides which pipeline handles each query
    # Query Router  —  decides which pipeline handles each query
    # ─────────────────────────────────────────────────────────────────────

    def _route_query(self, query: str) -> tuple[str, dict]:
        """
        Classify the query and return (route, metadata).

        Routes:
          "CATALOG"  — structured course/curriculum question
          "RAG"      — regulation/policy question scoped to one faculty
          "HYBRID"   — course list + explanation in same query
          "CLARIFY"  — no faculty detected, or ambiguous (multi-faculty)
          "COMPARE"  — multiple faculties detected (reserved for future use)

        metadata keys:
          detected_faculties : list[str]   — all faculties found in query
          clarify_reason     : str | None  — "no_faculty" | "multi_faculty"

        Decision is deterministic (regex-based), no LLM call needed.
        """
        q = query.strip()

        # ── Detect faculties ──────────────────────────────────────────────
        detected_faculties = self._detect_faculties(q)
        has_faculty = len(detected_faculties) >= 1
        multi_faculty = len(detected_faculties) >= 2
        # ── Vague faculty words check ─────────────────────────────────────
        # If query contains "الكلية/الكليه" without a specific faculty name,
        # do NOT infer — treat as no faculty so CLARIFY fires.
        _VAGUE_FACULTY_WORDS = re.compile(
            r"\b(الكلية|الكليه|كليتي|كليتك|في\s*الكلية|في\s*الكليه)\b",
            re.IGNORECASE | re.UNICODE,
        )
        _has_vague_faculty = bool(_VAGUE_FACULTY_WORDS.search(q))

        # Fallback inference when no explicit faculty found
        # Skip inference if query has vague "الكلية" — force CLARIFY instead
        if not has_faculty and not _has_vague_faculty:
            inferred = self._infer_program_from_query(q)
            if inferred:
                detected_faculties = [inferred]
                has_faculty = True
                multi_faculty = False

        # ── Signal patterns ───────────────────────────────────────────────
        _CATALOG_SIGNALS = re.compile(
            r"\b(مواد|مقررات|خطة|منهج|جدول|مادة|مقرر)\b"
            r"|\b(اعرض|اظهر|اجلب|وريني|اريني|اعطيني)\b"
            r"|\bكل\b.{0,30}\b(مواد|مقررات|برامج|كليات|الخطة|المنهج)\b"
            r"|\b(الفرق[هة]|فرق[هة]|السنة|المستوى|الترم|الفصل)\b"
            r"|\b(سنة|فرقة|ترم|فصل)\s*(اول[هى]?|تاني[هة]?|تالت[هة]?|رابع[هة]?|[1-4])\b"
            r"|\b(courses?|subjects?|curriculum|schedule|plan|catalog)\b"
            r"|\b(year|semester|level)\s*[1-4]\b"
            r"|\blist\b.{0,20}\b(courses?|subjects?)\b"
            r"|\bshow\b.{0,20}\b(courses?|subjects?|curriculum)\b",
            re.IGNORECASE | re.UNICODE,
        )
        _RAG_SIGNALS = re.compile(
            r"\b(شرح|اشرح|تعريف|عرّف|ما\s*هو|ما\s*هي|ماذا|كيف|لماذا|متى|أين)\b"
            r"|\b(لائحة|نظام|قانون|قاعدة|سياسة|شرط|متطلب|اشتراط)\b"
            r"|\b(يعني|معنى|مفهوم|فكرة|هدف|أهداف|وصف)\b"
            r"|\b(كم\s*ساعة|الساعات|الاعتمادية|الدرجة|التقدير)\b"
            r"|\b(الغياب|الرسوب|النجاح|الاعتراض|التظلم|الانتساب)\b"
            r"|\b(explain|define|what\s+is|what\s+are|how|why|when|where)\b"
            r"|\b(regulation|policy|rule|requirement|condition|prerequisite)\b"
            r"|\b(credit\s*hours?|grading|attendance|absence|fail|pass)\b"
            r"|\b(description|objective|goal|overview|about)\b",
            re.IGNORECASE | re.UNICODE,
        )
        _AGG_SIGNALS = re.compile(
            r"\bكل\b.{0,20}\b(لائح[هة]|مواد|مقررات|برامج|كليات|المنهج|الخطة)\b"
            r"|\b(اعرض|اظهر|اطبع|اجلب|اعطيني|وريني|اريني)\b.{0,10}\bكل\b"
            r"|\b(كل|جميع)\s+(الكليات|البرامج|المواد|المقررات|الفرق|الترمات)\b"
            r"|\blist\s+all\b|\bshow\s+all\b|\ball\s+(courses?|subjects?)\b"
            r"|\bfull\s+(curriculum|catalog|list|plan)\b"
            r"|\bcomplete\s+(curriculum|structure|list|catalog)\b",
            re.IGNORECASE | re.UNICODE,
        )

        has_catalog = bool(_CATALOG_SIGNALS.search(q))
        has_rag     = bool(_RAG_SIGNALS.search(q))
        has_agg     = bool(_AGG_SIGNALS.search(q))

        # ── General university questions (no faculty needed) ──────────────
        # ── General university questions (no faculty needed) ──────────────
        # Simple keyword check — avoids complex regex backtracking
        _GENERAL_UNIV_KEYWORDS = [
            "الجامعة", "جامعة المنوفية", "جامعة منوفية", "الجامعه", "جامعه المنوفيه", "جامعه منوفيه",
            "تأسست", "أُنشئت", "انشئت", "تاسست", "إنشاء", "تأسيس",
            "قرار جمهوري", "قرار وزاري", "مرسوم",
            "رؤية الجامعة", "رسالة الجامعة", "أهداف الجامعة",
            "رؤيه الجامعه", "رساله الجامعه", "رؤيه جامعه", "رساله جامعه",
            "الرؤية الرسمية", "الرسالة الرسمية",
            "موقع الجامعة", "عنوان الجامعة", "موقع الجامعه", "عنوان الجامعه", "طريق القاهرة",
            "كم كلية", "عدد الكليات", "كم برنامج", "عدد البرامج", "كم كليه",
            "الكليات المتاحة", "البرامج المتاحة", "الكليات المتاحه", "البرامج المتاحه",
            "الرسوم الدراسية", "مصروفات الجامعة", "الرسوم", "المصروفات", "مصروفات الجامعه",
            "شروط القبول", "متطلبات القبول",
            "منحة دراسية", "منح دراسية", "منحه دراسيه", "منح دراسيه", "المنح", "scholarship", "grant", "financial aid",
            "حقوق الطالب", "واجبات الطالب", "student rights", "student responsibilities",
            "رئيس الجامعة", "رئيس الجامعه", "رئيس جامعة", "رئيس جامعه", "university president", "president",
            # الانسحاب نُقل إلى _SPECIFY_FACULTY_KEYWORDS عشان يطلب تحديد الكلية أولاً
            "النجاح", "الرسوب", "درجات", "تقديرات", "passing", "pass", "fail", "grading", "gpa", "معدل", "نقاط",
            "التسجيل", "قيد", "سجل", "تسجيل", "registration", "enrollment",
            "أعذار", "اعذار", "عذر", "excuses", "excuse",
            "غش", "الغش", "عقوبات", "cheating", "penalties",
            "اللائحة العامة", "لائحة الجامعة", "student guide", "دليل الطالب",
            "التحويل", "تحويل", "transfer",
            "الإنذار الأكاديمي", "انذار اكاديمي", "academic warning", "warning",
            "التخرج", "تخرج", "graduate", "graduation",
            "tuition", "tuition fees", "fees",
            "complaint", "شكوى", "تظلم",
            # Training / internship — new
            "تدريب", "تدريب صيفي", "تدريب ميداني", "تدريب عملي",
            "التدريب", "التدريب الصيفي", "التدريب الميداني", "التدريب العملي",
            "internship", "field training", "summer training", "practical training",
        ]
        q_lower = q.lower()
        has_general_univ = any(kw in q_lower for kw in _GENERAL_UNIV_KEYWORDS)

        meta = {
            "detected_faculties": detected_faculties,
            "clarify_reason":     None,
        }

        # ── Study / Tutoring redirect (before all other routes) ─────────────
        # Questions about understanding academic material, solving exercises,
        # or requesting tutoring belong in the Study Chat, not here.
        _STUDY_SIGNALS = re.compile(
            # Arabic study intent
            r"\b(اشرحلي|وضحلي|فسرلي|علمني|ساعدني\s+ف[يه]?\s+ال?مذاكرة)\b"
            r"|\b(ازاي|كيفية)\s+.{0,20}\b(اذاكر|اتعلم|احل|افهم|اراجع)\b"
            r"|\b(مذاكرة|مراجع[ةه]|ملخص\s+مادة|ملخص\s+ل[لا])\b"
            r"|\b(حل\s*(مسأل[ةه]|تمرين|مسائل|واجب|تدريب))\b"
            r"|\b(واجب|homework|assignment|quiz\s*solution)\b"
            r"|\b(اشرح\s+(?!نظام|لائحة|قانون|غياب|تسجيل|درجات|رسوم|متطلبات)[\u0600-\u06FF]{3,})\b"
            # English study intent
            r"|\b(tutor(ing)?|study\s+help|help\s+(me\s+)?study|explain\s+(?!regulation|policy|rule|absence|grade)[a-z]{3,})\b"
            r"|\b(solve\s+(this|the|a)\s+(problem|exercise|question))\b"
            r"|\b(summarize\s+(the\s+)?(chapter|topic|lecture|material))\b"
            r"|\b(i\s+don.?t\s+understand\s+[a-z]{3,})\b",
            re.IGNORECASE | re.UNICODE,
        )
        # Academic subject keywords that confirm it's a content question
        _STUDY_SUBJECT_KW = [
            "فيزياء", "كيمياء", "رياضيات", "حساب", "جبر", "تفاضل", "تكامل",
            "احياء", "احصاء", "برمجة", "خوارزميات", "قواعد بيانات",
            "تشريح", "فسيولوجيا", "صيدلانيات", "ميكروبيولوجيا",
            "physics", "chemistry", "math", "calculus", "algebra",
            "biology", "anatomy", "programming", "algorithms", "statistics",
        ]
        _has_study_subject = any(kw in q_lower for kw in _STUDY_SUBJECT_KW)
        _has_study_signal  = bool(_STUDY_SIGNALS.search(q))

        # ── استثناءات مهمة: أسئلة عن اللوائح تبدو دراسية بس هي مش كده ──
        _REGULATION_EXCEPTIONS = re.compile(
            r"\b(احسب|حساب|بيتحسب|بتحسب|يتحسب|كيفية\s+حساب)\b.{0,30}\b(معدل|gpa|تراكمي|الدرجة|النتيجة)\b"
            r"|\b(معدل|gpa|تراكمي).{0,30}\b(احسب|حساب|بيتحسب|ازاي|كيف)\b"
            r"|\b(ازاي|كيف|كيفية).{0,20}\b(المعدل|gpa|التراكمي|الدرجات|النجاح|الرسوب)\b"
            r"|\b(نظام|قواعد|شروط|لوائح|لائحة)\b",
            re.IGNORECASE | re.UNICODE,
        )
        _is_regulation_question = bool(_REGULATION_EXCEPTIONS.search(q))

        # Trigger redirect if: strong study signal, OR study action + academic subject
        # لكن مش لو السؤال عن لوائح أو حساب معدل
        if (_has_study_signal or (_has_study_subject and not has_rag)) and not _is_regulation_question:
            meta["study_redirect"] = True
            return "STUDY_REDIRECT", meta

        # Aggregation always wins → CATALOG (regardless of faculty count)
        if has_agg:
            return "CATALOG", meta

        # Certain keywords MUST specify a faculty first
        _SPECIFY_FACULTY_KEYWORDS = [
            "ساعة", "ساعات", "مواد", "مقررات", "منهج", "خطة",
            "غياب", "حرمان", "تخرج", "الخريج",
            "نجاح", "رسوب", "درجات", "تقدير", "تقديرات",
            "تحويل", "عذر", "أعذار", "اعذار",
            "courses", "subjects", "hours", "graduation",
            "passing", "grading", "transfer", "excuses",
            "انسحاب", "الانسحاب", "withdrawal", "withdraw", "drop course",
             "انسحب", "اسحب", "يسحب", "سحب"
            # ملاحظة: تم حذف "gpa", "attendance", "absence" عشان أسئلة عامة عن
            # حساب المعدل أو الغياب تروح على RAG مباشرة من غير ما تطلب تحديد كلية
        ]
        requires_faculty = any(kw in q_lower for kw in _SPECIFY_FACULTY_KEYWORDS)
        if requires_faculty and not has_faculty:
            meta["clarify_reason"] = "no_faculty"
            return "CLARIFY", meta

        # General university question (no faculty needed) → RAG with general program
        if has_general_univ and not has_faculty:
            meta["general_university"] = True
            return "RAG", meta

        # Multi-faculty detected → Route to RAG with comparison/multi-program capability
        if multi_faculty:
            meta["multi_faculty_compare"] = True
            return "RAG", meta

        # Pure catalog (with or without faculty) → CATALOG
        if has_catalog and not has_rag:
            return "CATALOG", meta

        # Both catalog + RAG signals → HYBRID
        # Refinement: Only route to HYBRID if there's a strong "explanation/detail" intent.
        # Simple "What are the courses?" should stay in CATALOG.
        _STRICT_RAG_SIGNALS = re.compile(r"\b(اشرح|وضح|فسر|مميزات|طبيعة|صعوبة|نظام)\b", re.IGNORECASE | re.UNICODE)
        has_strict_rag = bool(_STRICT_RAG_SIGNALS.search(q))

        if has_catalog and has_strict_rag:
            return "HYBRID", meta

        # RAG query WITH exactly one faculty → scoped answer
        if has_rag and has_faculty:
            return "RAG", meta

        # RAG query WITHOUT faculty → ask which faculty
        if has_rag and not has_faculty:
            meta["clarify_reason"] = "no_faculty"
            return "CLARIFY", meta

        # Default: if faculty detected → RAG, else → ask which faculty first
        # (prevents "not available" for ambiguous queries that need a faculty scope)
        if has_faculty:
            return "RAG", meta

        meta["clarify_reason"] = "no_faculty"
        return "CLARIFY", meta

    # ─────────────────────────────────────────────────────────────────────
    # Structured catalog pipeline (aggregation queries)
    # ─────────────────────────────────────────────────────────────────────

    def _structured_catalog_response(self, query: str, query_lang: str) -> dict:
        """
        Handle aggregation queries by iterating the catalog directly.
        Does NOT use RAG / vector search / LLM.
        Pattern: iterate → organize → format

        Supports partial aggregation:
          "اعرض كل مواد الفرقة الأولى حاسبات"
          → structured output filtered to CS year 1
        """
        import time as _time
        from collections import defaultdict
        import hashlib
        t0 = _time.perf_counter()

        # ── Safety guard 1: catalog not built ────────────────────────────
        if not self.catalog.is_built:
            return {
                "answer": "⚠️ الكاتالوج لم يُبنَ بعد — يرجى إعادة تشغيل النظام.",
                "query_language": query_lang,
                "reranked": [],
                "retrieval_stats": {"method": "catalog_aggregation"},
                "elapsed_ms": 0.0,
            }

        # ── Safety guard 2: catalog empty ────────────────────────────────
        if not self.catalog.courses:
            return {
                "answer": (
                    "⚠️ البيانات غير مكتملة في الكاتالوج.\n"
                    "السبب المحتمل: الملفات لم تُرفع بعد أو لم يتم استخراج المقررات منها.\n"
                    "الحل: ارفع الملفات عبر /api/upload ثم أعد تشغيل النظام."
                ),
                "query_language": query_lang,
                "reranked": [],
                "retrieval_stats": {"method": "catalog_aggregation", "hits": 0},
                "elapsed_ms": 0.0,
            }

        # ── Detect requested scope (partial aggregation support) ──────────
        _PROG_HINTS = [
            ("computer science", ["حاسبات","حاسب","حاسوب","كمبيوتر","computer","cs","it",
                                  "information","برمجة","software"]),
            ("dentistry",        ["أسنان","اسنان","dentistry","dental"]),
            ("medicine",         ["طب","طبية","medicine","medical","mbbs"]),
            ("engineering",      ["هندسة","هندسه","engineering","eng"]),
            ("pharmacy",         ["صيدلة","صيدله","pharmacy"]),
            ("law",              ["حقوق","قانون","law"]),
            ("commerce",         ["تجارة","تجاره","commerce","business"]),
        ]
        _ql = query.lower()
        _want_program = next(
            (p for p, hints in _PROG_HINTS if any(h in _ql for h in hints)),
            None
        )

        _want_year = None
        for _yr, _pat in [
            (1, r"فرق[هة]\s*اول[هى]?|level\s*1|year\s*1|first\s*year|\باوله?\b"),
            (2, r"فرق[هة]\s*تاني[هة]?|level\s*2|year\s*2|second\s*year"),
            (3, r"فرق[هة]\s*تالت[هة]?|level\s*3|year\s*3|third\s*year"),
            (4, r"فرق[هة]\s*رابع[هة]?|level\s*4|year\s*4|fourth\s*year"),
        ]:
            if re.search(_pat, query, re.IGNORECASE | re.UNICODE):
                _want_year = _yr
                break

        _want_sem = None
        if re.search(r"ترم\s*اول|الترم\s*الاول|semester\s*1|first\s*semester",
                     query, re.IGNORECASE | re.UNICODE):
            _want_sem = 1
        elif re.search(r"ترم\s*تاني|الترم\s*التاني|semester\s*2|second\s*semester",
                       query, re.IGNORECASE | re.UNICODE):
            _want_sem = 2

        # ── Performance: cache key ────────────────────────────────────────
        _cache_key = hashlib.md5(
            f"{_want_program}|{_want_year}|{_want_sem}".encode()
        ).hexdigest()
        if hasattr(self, "_agg_cache") and _cache_key in self._agg_cache:
            cached = self._agg_cache[_cache_key]
            cached["elapsed_ms"] = (_time.perf_counter() - t0) * 1000
            cached["retrieval_stats"]["cache_hit"] = True
            return cached

        # ── Query the catalog ─────────────────────────────────────────────
        courses = self.catalog.query(
            program=_want_program,
            year=_want_year,
            semester=_want_sem,
        )

        # ── Safety guard 3: no matching data ─────────────────────────────
        # Apply result limit (Issue: catalog failing to filter by year)
        # If catalog returns > 20 items, it's likely a broad dump.
        # Fail gracefully so RAG can take over.
        if len(courses) > 20:
            return {
                "answer": "",
                "query_language": query_lang,
                "reranked": [],
                "retrieval_stats": {"method": "catalog_aggregation", "hits": 0},
                "elapsed_ms": (_time.perf_counter() - t0) * 1000,
            }

        if not courses:
            _scope = []
            if _want_program:
                _scope.append(_want_program)
            if _want_year:
                _scope.append(f"السنة {_want_year}")
            if _want_sem:
                _scope.append(f"الترم {_want_sem}")
            _scope_str = " / ".join(_scope) if _scope else "النطاق المطلوب"
            return {
                "answer": (
                    f"⚠️ لا توجد بيانات في الكاتالوج لـ: {_scope_str}\n"
                    "تأكد من رفع الملفات الصحيحة وإعادة بناء الكاتالوج."
                ),
                "query_language": query_lang,
                "reranked": [],
                "retrieval_stats": {
                    "method": "catalog_aggregation", "hits": 0,
                    "program_filter": _want_program,
                    "year_filter": _want_year,
                    "semester_filter": _want_sem,
                },
                "elapsed_ms": (_time.perf_counter() - t0) * 1000,
            }

        # ── Organize: group by program → year → semester ──────────────────
        tree: dict = defaultdict(lambda: defaultdict(lambda: defaultdict(list)))
        for c in courses:
            prog = c.get("program") or "غير محدد"
            yr   = c.get("year")    or 0
            sem  = c.get("semester") or 0
            tree[prog][yr][sem].append(c)

        # ── Format: hierarchical output ───────────────────────────────────
        _PROG_AR = {
            "computer science": "كلية الحاسبات والذكاء الاصطناعي",
            "medicine":         "كلية الطب",
            "dentistry":        "كلية طب الأسنان",
            "engineering":      "كلية الهندسة",
            "pharmacy":         "كلية الصيدلة",
            "law":              "كلية الحقوق",
            "commerce":         "كلية التجارة",
            "arts":             "كلية العلوم الإنسانية والاجتماعية",
        }
        _YR_AR  = {1:"الأولى", 2:"الثانية", 3:"الثالثة", 4:"الرابعة", 0:"غير محدد"}
        _SEM_AR = {1:"الأول",  2:"الثاني",  0:"غير محدد"}

        lines: list[str] = []
        total = 0

        for prog in sorted(tree.keys()):
            prog_label = _PROG_AR.get(prog, prog)
            lines.append(f"\n{'━'*52}")
            lines.append(f"📚 {prog_label}")
            lines.append(f"{'━'*52}")

            for yr in sorted(tree[prog].keys()):
                yr_label = _YR_AR.get(yr, str(yr))
                yr_count = sum(len(v) for v in tree[prog][yr].values())
                lines.append(f"\n  🎓 الفرقة {yr_label}  ({yr_count} مقرر)")
                lines.append(f"  {'─'*46}")

                for sem in sorted(tree[prog][yr].keys()):
                    sem_label   = _SEM_AR.get(sem, str(sem))
                    sem_courses = tree[prog][yr][sem]
                    lines.append(f"\n    📖 الترم {sem_label}  ({len(sem_courses)} مقرر):")

                    for c in sem_courses:
                        title   = c.get("title_ar") or c.get("title_en") or c["code"]
                        code    = c["code"]
                        credits = c.get("credit_hours")
                        prereq  = c.get("prerequisite")
                        extras  = []
                        if credits:
                            extras.append(f"{credits} ساعة")
                        if prereq:
                            extras.append(f"متطلب: {prereq}")
                        extra_str = f"  [{', '.join(extras)}]" if extras else ""
                        lines.append(f"      • {title} ({code}){extra_str}")
                        total += 1

        lines.append(f"\n{'━'*52}")
        lines.append(f"📊 إجمالي المقررات: {total}")
        if _want_program or _want_year or _want_sem:
            _applied = []
            if _want_program:
                _applied.append(_PROG_AR.get(_want_program, _want_program))
            if _want_year:
                _applied.append(f"الفرقة {_YR_AR.get(_want_year, str(_want_year))}")
            if _want_sem:
                _applied.append(f"الترم {_SEM_AR.get(_want_sem, str(_want_sem))}")
            lines.append(f"🔍 فلتر مطبق: {' | '.join(_applied)}")

        result = {
            "answer":          "\n".join(lines),
            "query_language":  query_lang,
            "reranked":        [],
            "chunks_used":     0,
            "retrieval_stats": {
                "method":          "catalog_aggregation",
                "hits":            total,
                "program_filter":  _want_program,
                "year_filter":     _want_year,
                "semester_filter": _want_sem,
                "cache_hit":       False,
            },
            "elapsed_ms": (_time.perf_counter() - t0) * 1000,
        }

        # ── Cache the result ──────────────────────────────────────────────
        if not hasattr(self, "_agg_cache"):
            self._agg_cache: dict = {}
        self._agg_cache[_cache_key] = result
        return result

    # ─────────────────────────────────────────────────────────────────────
    # Core RAG pipeline
    # ─────────────────────────────────────────────────────────────────────

    def get_rag_response(self, query: str) -> dict:
        """
        Dispatcher — routes every query through the Query Router first,
        applies conversational memory (last_faculty fallback), then calls
        the appropriate pipeline.

          CATALOG → _structured_catalog_response()
          RAG     → _rag_pipeline()
          HYBRID  → _hybrid_pipeline()
          CLARIFY → clarification message
        """
        t0 = time.perf_counter()

        query_norm = normalize_query(query)
        query_lang = detect_language(query_norm)

        route, route_meta = self._route_query(query)
        _detected_faculties = route_meta.get("detected_faculties", [])
        _clarify_reason     = route_meta.get("clarify_reason")

        # ── Conversational memory: faculty fallback ───────────────────────
        # Case A: previous turn CLARIFY — student just answered with a faculty name
        # e.g. last clarify_query="ما نظام الغياب" + current query="الحاسبات"
        # → rebuild as "ما نظام الغياب في الحاسبات" and re-route.
        _memory_used = False
        _memory_faculty = self.session_context.get("last_faculty")
        _pending_clarify = self.session_context.get("last_clarify_query")

        if _pending_clarify and _detected_faculties and route in ("CLARIFY", "RAG", "CATALOG"):
            # Student replied with a faculty — rebuild the original question
            _combined = f"{_pending_clarify} في كلية {_detected_faculties[0]}"
            _new_route, _new_meta = self._route_query(_combined)
            if _new_route in ("RAG", "HYBRID", "CATALOG"):
                query              = _combined
                query_norm         = normalize_query(_combined)   # ← must update!
                query_lang         = detect_language(query_norm)  # ← and language
                route              = _new_route
                route_meta         = _new_meta
                _detected_faculties = _new_meta.get("detected_faculties", _detected_faculties)
                _clarify_reason    = None
                _memory_used       = True
                self.session_context["last_clarify_query"] = None  # clear pending

        # Case B: follow-up with no faculty — use last_faculty from memory
        elif (
            _clarify_reason == "no_faculty"
            and _memory_faculty
            and not _detected_faculties
        ):
            # Re-route with the remembered faculty injected
            _augmented_query = f"{query} في {_memory_faculty}"
            _new_route, _new_meta = self._route_query(_augmented_query)

            # Only accept the re-route if it resolved to RAG/HYBRID
            # (don't silently override a legitimate CLARIFY for other reasons)
            if _new_route in ("RAG", "HYBRID", "CATALOG"):
                route              = _new_route
                route_meta         = _new_meta
                _detected_faculties = [_memory_faculty]
                _clarify_reason    = None
                _memory_used       = True
                # Use the augmented query for retrieval so the faculty
                # context is embedded in the search
                query_norm = normalize_query(_augmented_query)

        # ── Update session context after routing ──────────────────────────
        # Always update last_query; update faculty/intent only when detected
        self.session_context["last_query"] = query
        if _detected_faculties and not _memory_used:
            self.session_context["last_faculty"] = _detected_faculties[0]
        elif _memory_used:
            pass  # keep last_faculty unchanged — it was already correct

        if route == "STUDY_REDIRECT":
            if query_lang == "arabic":
                _study_ans = (
                    "📚 يبدو أن سؤالك متعلق بالمحتوى الدراسي أو المذاكرة.\n\n"
                    "هذا الشات مخصص للوائح والأنظمة الجامعية فقط ✅\n\n"
                    "للمساعدة في المذاكرة وشرح المواد، توجّه إلى:\n"
                    "🎓 **شات الدراسة (Study Chat)**\n\n"
                    "هل تريد الاستفسار عن شيء في اللوائح الجامعية؟ 😊"
                )
            else:
                _study_ans = (
                    "📚 It looks like your question is about studying or academic content.\n\n"
                    "This chat is dedicated to university regulations and policies only ✅\n\n"
                    "For study help and subject explanations, please go to:\n"
                    "🎓 **Study Chat**\n\n"
                    "Can I help you with something about university regulations? 😊"
                )
            return {
                "answer":             _study_ans,
                "query_language":     query_lang,
                "reranked":           [],
                "retrieval_stats":    {"method": "study_redirect"},
                "detected_faculties": _detected_faculties,
                "elapsed_ms":         (time.perf_counter() - t0) * 1000,
                "route":              "STUDY_REDIRECT",
            }

        if route == "CATALOG":
            result = self._structured_catalog_response(query, query_lang)
            if not result.get("answer") or result.get("answer").strip() == "":
                # Fallback to HYBRID if catalog fails to provide a concise answer
                route = "HYBRID"
            else:
                result["route"]              = "CATALOG"
                result["detected_faculties"] = _detected_faculties
                result["memory_used"]        = _memory_used
                return result

        if route == "HYBRID":
            result = self._hybrid_pipeline(query, query_norm, query_lang, t0, fallback_program=(_detected_faculties[0] if _detected_faculties else None))
            result["route"]              = "HYBRID"
            result["detected_faculties"] = _detected_faculties
            result["memory_used"]        = _memory_used
            return result

        if route == "CLARIFY":
            _AVAILABLE = (
                "• كلية الحاسبات والذكاء الاصطناعي\n"
                "• كلية الصيدلة\n"
                "• كلية التمريض\n"
                "• كلية طب بيطري\n"
                "• كلية علاج طبيعي\n"
                "• كلية العلوم الإنسانية والاجتماعية (برنامج اللغة الإنجليزية والترجمة التخصصية)\n"
                "• لائحة الجامعة العامة"
            )

            # Different message depending on WHY we're clarifying
            if _clarify_reason == "multi_faculty":
                # Multiple faculties detected → ask compare or specific
                _fac_ar = {
                    "computer science": "الحاسبات",
                    "pharmacy":         "الصيدلة",
                    "nursing":          "التمريض",
                    "veterinary":       "طب بيطري",
                    "physical therapy": "علاج طبيعي",
                    "medicine":         "الطب",
                    "engineering":      "الهندسة",
                    "dentistry":        "طب الأسنان",
                    "law":              "الحقوق",
                    "commerce":         "التجارة",
                    "arts":             "الآداب",
                }
                _fac_list = " و ".join(
                    _fac_ar.get(f, f) for f in _detected_faculties
                )
                if query_lang == "arabic":
                    _ans = (
                        f"🔀 تم اكتشاف أكثر من كلية في سؤالك: **{_fac_list}**\n\n"
                        "هل تقصد مقارنة بين الكليات أم تريد كلية محددة؟\n\n"
                        "• للمقارنة: قل \"قارن بين نظام الغياب في الحاسبات والصيدلة\"\n"
                        "• لكلية واحدة: حدد الكلية مثل \"ما هو نظام الغياب في الحاسبات؟\""
                    )
                else:
                    _fac_list_en = " and ".join(_detected_faculties)
                    _ans = (
                        f"🔀 Multiple faculties detected: **{_fac_list_en}**\n\n"
                        "Are you asking to compare faculties, or do you want a specific one?\n\n"
                        "• To compare: say \"Compare attendance policy in CS and Pharmacy\"\n"
                        "• For one faculty: specify it, e.g. \"Attendance policy in CS?\""
                    )
            else:
                # No faculty detected → ask which one
                if query_lang == "arabic":
                    _ans = (
                        "📌 سؤالك يحتاج تحديد الكلية أو البرنامج.\n\n"
                        "الكليات المتاحة:\n"
                        f"{_AVAILABLE}\n\n"
                        "مثال: \"ما هو نظام الغياب في كلية الحاسبات؟\""
                    )
                else:
                    _ans = (
                        "📌 Please specify which faculty or program you're asking about.\n\n"
                        "Available faculties:\n"
                        "• Computer Science & AI\n"
                        "• Pharmacy\n"
                        "• Nursing\n"
                        "• Veterinary Medicine\n"
                        "• Physical Therapy\n"
                        "• Humanities and Social Sciences (English Language & Translation)\n"
                        "• General University Regulations\n\n"
                        "Example: \"What is the attendance policy in Computer Science?\""
                    )

            # 💾 Save the original query so next turn can rebuild it with the faculty
            self.session_context["last_clarify_query"] = query
            self.session_context["last_query"] = query

            return {
                "answer":             _ans,
                "query_language":     query_lang,
                "reranked":           [],
                "retrieval_stats":    {
                    "method":           "clarify",
                    "clarify_reason":   _clarify_reason,
                },
                "detected_faculties": _detected_faculties,
                "elapsed_ms":         (time.perf_counter() - t0) * 1000,
                "route":              "CLARIFY",
            }

        # Default: RAG
        _force_prog = "general" if route_meta.get("general_university") else None
        if route_meta.get("multi_faculty_compare"):
            _force_prog = _detected_faculties
        result = self._rag_pipeline(query, query_norm, query_lang, t0, force_program=_force_prog)
        result["route"]              = "RAG"
        result["detected_faculties"] = _detected_faculties
        result["memory_used"]        = _memory_used

        # Update last_intent from the RAG pipeline's query understanding
        _rag_intent = (
            result.get("retrieval_stats", {})
                  .get("query_understanding", {})
                  .get("intent")
        )
        if _rag_intent:
            self.session_context["last_intent"] = _rag_intent

        return result

    # ─────────────────────────────────────────────────────────────────────
    # HYBRID pipeline  —  catalog list + RAG explanation merged
    # ─────────────────────────────────────────────────────────────────────

    def _hybrid_pipeline(
        self, query: str, query_norm: str, query_lang: str, t0: float,
        fallback_program: str | None = None,
    ) -> dict:
        """
        For mixed queries like "اشرح مواد الفرقة الأولى حاسبات":
          1. Detect program from query (same logic as catalog + RAG)
          2. Get structured course list from catalog (program-filtered)
          3. Get RAG explanation chunks (program-isolated via hybrid_search)
          4. Merge: catalog list first, then LLM explanation below

        Fix 3: both catalog and RAG parts are now program-scoped.
        The RAG part passes the detected program to hybrid_search so the
        program isolation layer in hybrid_search filters out other faculties.
        """
        from routes.retrieval.query_understanding import understand_query as _uq

        # ── Detect program once — shared by both sub-pipelines ────────────
        _intent = _uq(query)
        _prog   = _intent.program or fallback_program  # e.g. "computer science" or None

        # ── Step 1: catalog part (already program-filtered via catalog.query) ─
        cat_result     = self._structured_catalog_response(query, query_lang)
        catalog_answer = cat_result.get("answer", "")

        # ── Step 2: RAG part — pass detected program intent to hybrid_search ─
        # hybrid_search will apply _apply_program_isolation for this program.
        rag_result = self._rag_pipeline(
            query, query_norm, query_lang, t0,
            force_program=_prog,   # ← new param: override program detection
        )
        rag_answer = rag_result.get("answer", "")

        # ── Step 3: decision logic ──
        # If catalog has specific results and the user didn't ask for "explanation",
        # we skip the RAG/LLM part to avoid duplication and "hallucination" risk.
        _STRICT_RAG_SIGNALS = re.compile(r"\b(اشرح|وضح|فسر|مميزات|طبيعة|صعوبة|نظام)\b", re.IGNORECASE | re.UNICODE)
        wants_explanation = bool(_STRICT_RAG_SIGNALS.search(query))

        # Check if catalog answer is specific (not a full list of everything)
        # 148 courses usually means it failed to filter by year/program.
        is_generic_list = "إجمالي المقررات: 148" in catalog_answer or "إجمالي المقررات: 149" in catalog_answer

        if catalog_answer and not wants_explanation and not is_generic_list:
            # Catalog gave a good filtered list, and user didn't ask for "why/how"
            return cat_result

        # ── Step 4: merge — only include RAG answer if it adds real info ──
        _no_info_markers = [
            "المعلومات غير موجودة",
            "Information not found",
            "not found in the regulations",
        ]
        rag_has_info = rag_answer and not any(
            m.lower() in rag_answer.lower() for m in _no_info_markers
        )

        if catalog_answer and rag_has_info:
            merged = (
                catalog_answer
                + "\n\n" + "─" * 52
                + "\n📝 معلومات إضافية من اللائحة:\n"
                + rag_answer
            )
        elif catalog_answer:
            merged = catalog_answer
        else:
            merged = rag_answer

        return {
            "answer":          merged,
            "query_language":  query_lang,
            "reranked":        rag_result.get("reranked", []),
            "chunks_used":     rag_result.get("chunks_used", 0),
            "retrieval_stats": rag_result.get("retrieval_stats", {}),
            "elapsed_ms":      (time.perf_counter() - t0) * 1000,
        }

    # ─────────────────────────────────────────────────────────────────────
    # RAG-only pipeline  (was the old get_rag_response body)
    # ─────────────────────────────────────────────────────────────────────

    def _rag_pipeline(
        self, query: str, query_norm: str, query_lang: str, t0: float,
        force_program: str | None = None,
    ) -> dict:
        # Detect intent at the start so we can adjust top_k
        import sys
        from routes.retrieval.query_understanding import understand_query as _uq_rag
        _ei = _uq_rag(query)
        _dbg(f"DEBUG CLI: Intent={_ei.intent} Program={_ei.program}\n")
        if force_program:
            _ei.program = force_program
        self.last_ei = _ei
        
        # Guard: _ei.program may be a list (multi-faculty) or str or None
        if isinstance(_ei.program, list):
            _dom_prog = _ei.program[0].lower() if _ei.program else "general"
        else:
            _dom_prog = _ei.program.lower() if _ei.program else "general"

        if self.collection is None or self.collection.count() == 0:
            return {
                "answer": _warn("No documents indexed. Upload PDFs first."),
                "query_language": query_lang,
                "reranked": [],
                "retrieval_stats": {},
                "elapsed_ms": 0.0,
            }

        if self.embeddings is None:
            return {
                "answer": _warn("Embeddings not configured. Check .env file."),
                "query_language": query_lang,
                "reranked": [],
                "retrieval_stats": {},
                "elapsed_ms": 0.0,
            }

        # ── 2. Embed with cache ───────────────────────────────────────────
        try:
            self.cache.embed_query_cached(query_norm, self.embeddings)
        except Exception as e:
            return {
                "answer": _warn(f"Embedding failed: {e}"),
                "query_language": query_lang,
                "reranked": [],
                "retrieval_stats": {},
                "elapsed_ms": (time.perf_counter() - t0) * 1000,
            }

        # ── 3. Hybrid retrieval ───────────────────────────────────────────
        # Optimization: Use more chunks for course queries to ensure full coverage
        # (Course lists in OCR PDFs are often spread across many sparse chunks).
        _is_subj = (self.last_ei.intent == "subjects list") if self.last_ei else False
        # Detect if query is about training (summer/field/practical)
        _is_training = False
        if self.last_ei:
            _training_kws = ["تدريب", "training", "internship", "صيفي", "ميداني", "عملي"]
            _q_lower = query.lower()
            _is_training = (
                self.last_ei.intent == "regulations"
                and any(kw in _q_lower or kw in query for kw in _training_kws)
            )
        # Increase search depth for subjects list to find sparse OCR tables.
        # Also increase for training queries to cover all programs.
        if _is_subj:
            target_top_k = 20
            candidates_k = 200
        elif _is_training:
            target_top_k = 15   # need more chunks to cover all CS programs
            candidates_k = 120
        else:
            target_top_k = 8
            candidates_k = 80
        
        try:
            # Build _qi_override from _ei — always pass it so hybrid_search
            # uses the same intent we detected (including force_program override)
            _qi_override = _ei

            # ── EN→AR translation for better Arabic-doc retrieval ─────────
            _retrieval_query = query_norm
            if query_lang != "arabic":
                _ar_query = self._translate_to_arabic(query_norm)
                if _ar_query and _ar_query != query_norm:
                    _retrieval_query = _ar_query
                    _dbg(f"[retrieval] Using translated query\n")

            _dbg(f"DEBUG CLI: Calling hybrid_search with target_top_k={target_top_k} candidates_k={candidates_k}\n")
            retrieval = hybrid_search(
                query             = _retrieval_query,
                collection        = self.collection,
                embeddings        = self.embeddings,
                bm25_index        = self.bm25,
                top_k             = target_top_k,
                dense_candidates  = candidates_k,
                sparse_candidates = candidates_k,
                use_rrf           = True,
                language_filter   = self.language_filter,
                query_intent      = _qi_override,
            )

        except Exception as e:
            import traceback, io
            tb_buf = io.StringIO()
            traceback.print_exc(file=tb_buf)
            return {
                "answer": f"ERROR: {type(e).__name__}: {repr(str(e))}\n\nFULL TRACEBACK:\n{tb_buf.getvalue()}",
                "query_language": query_lang,
                "reranked": [],
                "retrieval_stats": {},
                "elapsed_ms": (time.perf_counter() - t0) * 1000,
            }

        candidates      = retrieval["results"]
        retrieval_stats = retrieval["retrieval_stats"]

        # ── Confidence gating ─────────────────────────────────────────────
        # If retrieval confidence is too low, ask for clarification instead
        # of returning a potentially wrong answer from unrelated documents.
        if retrieval_stats.get("low_retrieval_confidence"):
            _max_score = retrieval_stats.get("max_retrieval_score", 0.0)
            _tier      = retrieval_stats.get("query_understanding", {}).get(
                "classifier_tier", "rule_based"
            )
            if query_lang == "arabic":
                _clarify = (
                    "⚠️ لم أتمكن من العثور على معلومات كافية للإجابة بدقة.\n"
                    "هل يمكنك توضيح سؤالك؟ مثلاً:\n"
                    "• ما الكلية أو التخصص المقصود؟\n"
                    "• هل السؤال عن لائحة معينة أو مادة بعينها؟"
                )
            else:
                _clarify = (
                    "⚠️ I couldn't find enough relevant information to answer accurately.\n"
                    "Could you clarify your question? For example:\n"
                    "• Which faculty or program are you asking about?\n"
                    "• Are you asking about a specific regulation or course?"
                )
            return {
                "answer":          _clarify,
                "query_language":  query_lang,
                "reranked":        candidates,
                "retrieval_stats": retrieval_stats,
                "elapsed_ms":      (time.perf_counter() - t0) * 1000,
            }

        if not candidates:
            no_info = (
                "عذرًا، هذه المعلومة غير متوفرة في اللوائح الحالية المرفقة لدينا. "
                "لمزيد من الاستفسارات يُمكنك التواصل مع إدارة الكلية أو شؤون الطلاب المختصة."
                if query_lang == "arabic"
                else "Sorry, this information is not available in the currently provided regulations. "
                     "For further inquiries, please contact the respective faculty administration "
                     "or student affairs office."
            )
            return {
                "answer": no_info,
                "query_language": query_lang,
                "reranked": [],
                "retrieval_stats": retrieval_stats,
                "elapsed_ms": (time.perf_counter() - t0) * 1000,
            }

        # ── 4. Rerank ─────────────────────────────────────────────────────
        method = self.rerank_method.lower()
        
        # Dynamic top_k for lists: tables need more chunks to be complete
        _final_top_k = self.top_k
        _intent = retrieval_stats.get("query_understanding", {}).get("intent")
        if _intent in ("subjects list", "curriculum"):
            _final_top_k = 20
        elif _intent == "departments":
            # Very tight limit for departments to avoid noisy subject tables (p.25)
            # formal lists (p.11) are always in top 1-2.
            _final_top_k = 3
            
        if method == "none":
            reranked = candidates[:_final_top_k]
            for i, c in enumerate(reranked):
                c["rerank_score"]  = c.get("rrf_score", 1.0 - i * 0.01)
                c["rerank_method"] = "passthrough"
        elif method == "llm":
            reranked = rerank_results(
                query      = query_norm,
                candidates = candidates,
                llm        = self.llm,
                top_n      = _final_top_k,
            )
        elif method == "bm25":
            reranked = rerank_results(
                query      = query_norm,
                candidates = candidates,
                embeddings = "bm25",
                top_n      = _final_top_k,
            )
        else:  # cosine (default)
            reranked = rerank_results(
                query      = query_norm,
                candidates = candidates,
                embeddings = self.embeddings,
                top_n      = _final_top_k,
            )

        # ── 4c. Emergency Program Boost ──────────────────────────────────
        # If a chunk has high program_score but low rerank_score (common for
        # English tables in Arabic queries), boost it to ensure it's used.
        for r in reranked:
            if r.get("rerank_score", 0.0) < 0.1 and r.get("program_score", 0.0) >= 0.7:
                r["rerank_score"] = 0.5   # give it a mid-tier score to survive
                r["emergency_boost"] = True

        # Re-sort after emergency boost
        reranked.sort(key=lambda x: x.get("rerank_score", 0.0), reverse=True)

        if not reranked:
            no_info = (
                "عذرًا، هذه المعلومة غير متوفرة في اللوائح الحالية المرفقة لدينا. "
                "لمزيد من الاستفسارات يُمكنك التواصل مع إدارة الكلية أو شؤون الطلاب المختصة."
                if query_lang == "arabic"
                else "Sorry, this information is not available in the currently provided regulations. "
                     "For further inquiries, please contact the respective faculty administration "
                     "or student affairs office."
            )
            return {
                "answer": no_info,
                "query_language": query_lang,
                "reranked": [],
                "retrieval_stats": retrieval_stats,
                "elapsed_ms": (time.perf_counter() - t0) * 1000,
            }

        # ── 4b. HARD ENFORCEMENT LAYER ───────────────────────────────────
        # retrieve → filter → validate → THEN LLM
        # This runs BEFORE context building and BEFORE the LLM.
        # It enforces single-program lock: the LLM only sees chunks
        # from the dominant program. Cross-domain leakage is impossible.

        # ── Step A: Detect dominant program from query ────────────────────
        from routes.retrieval.query_understanding import understand_query as _uq_enforce
        _ei = _uq_enforce(query)

        _PROG_SIGS: dict[str, list[str]] = {
            "computer science": ["حاسبات","حاسب","حاسوب","كمبيوتر","computer","cs",
                                  "it","information","programming","برمجة","software"],
            "medicine":         ["طب","طبية","medicine","medical","mbbs","surgery"],
            "dentistry":        ["أسنان","اسنان","dentistry","dental","dbm","أسنان"],
            "engineering":      ["هندسة","هندسه","engineering","eng"],
            "pharmacy":         ["صيدلة","صيدله","pharmacy"],
            "law":              ["حقوق","قانون","law"],
            "commerce":         ["تجارة","تجاره","commerce","business"],
            "arts":             ["آداب","اداب","إنجليزي","انجليزي","english","ترجمة","ترجمه","translation"],
            "physical therapy":  ["علاج طبيعي", "علاج_طبيعي", "physical therapy", "physio"],
            "veterinary":        ["بيطري", "بيطره", "بيطرة", "veterinary", "vet"],
        }
        _ql = query.lower()
        _psig = {p: sum(1 for s in sigs if s in _ql) for p, sigs in _PROG_SIGS.items()}
        _dom_prog = _ei.program or ""
        _mx = max(_psig.values(), default=0)
        if _mx > 0:
            _cands = [p for p, s in _psig.items() if s == _mx]
            _dom_prog = (_cands[0] if len(_cands) == 1
                         else _ei.program if _ei.program in _cands
                         else _cands[0])

        # ── Step B: Program-prefix map ────────────────────────────────────
        # Maps each program to the course-code prefixes that belong to it.
        # A chunk is "in-program" if it contains at least one matching prefix.
        _PROG_PREFIXES: dict[str, set[str]] = {
            "computer science": {"GEN","BAS","BCS","MBS","ICI","CS","IT",
                                  "SWE","CIS","CSC","INF","BIS","AIS"},
            "medicine":         {"MED","GEN","BAS"},
            "dentistry":        {"DBM","MGP","GEN","BAS","ARE","DOP","DOD","DRP","DFP","DOS","DPP","DDE","DD"},
            "engineering":      {"ARE","GEN","BAS","ENG","CIV","MEC","ELE"},
            "pharmacy":         {"PHR","GEN","BAS"},
            "law":              {"LAW","GEN"},
            "commerce":         {"ACC","ECO","MGT","GEN","BAS"},
            "physical therapy":  {"GEN","BAS","PT","PHT"},
            "veterinary":        {"GEN","BAS","VET","VMP"},
            "arts":             {"ART","ENG","TRS","GEN","BAS"},
        }
        # Prefixes that NEVER belong to CS (hard exclusion)
        _NON_CS_PREFIXES = {"MED","NUR","PHR","DEN","VET","OPH","ENT",
                             "DBM","MGP","ARE","LAW","ACC","ECO"}

        _detect_re_enf = re.compile(r"\b([A-Z]{2,4})\s*(\d{3,4})\b", re.IGNORECASE)

        def _chunk_in_program(chunk_text: str, prog) -> bool:
            """Return True if chunk contains at least one prefix for prog or NO prefixes at all.
            prog can be a str or list[str] for multi-faculty queries.
            """
            if not prog:
                return True

            progs = [prog] if isinstance(prog, str) else list(prog)

            codes = _detect_re_enf.findall(chunk_text)
            if not codes:
                return True  # Allow chunks with no course codes (intro text, regulations)

            for _p in progs:
                allowed = _PROG_PREFIXES.get(_p, set())
                for p, _ in codes:
                    if p.upper() in allowed:
                        return True
            return False

        def _chunk_has_foreign_codes(chunk_text: str, prog) -> bool:
            """Return True if chunk contains codes from a DIFFERENT program.
            Only strictly enforced for single-CS queries (not multi-faculty).
            """
            # For list-based (multi-faculty) programs, skip strict exclusion
            if isinstance(prog, list):
                return False
            if prog != "computer science":
                return False   # only enforce strict exclusion for CS queries
            for p, _ in _detect_re_enf.findall(chunk_text):
                if p.upper() in _NON_CS_PREFIXES:
                    return True
            return False

        # ── Step C: Filter reranked list ──────────────────────────────────
        if _dom_prog:
            _filtered = [
                r for r in reranked
                if _chunk_in_program(r.get("text",""), _dom_prog)
                and not _chunk_has_foreign_codes(r.get("text",""), _dom_prog)
            ]
            # Fallback: if filtering removed everything, keep original list
            # (better to answer with mixed data than to say "not found" wrongly)
            if _filtered:
                reranked = _filtered
            # else: keep original reranked — guardrail will handle it

            # ── Step C2: For training/regulations queries, boost program-specific file chunks ──
            # Problem: general regulation chunks (no course codes) pass the filter above
            # but they contain the WRONG training conditions (different hours threshold).
            # Fix: When the query is about training + specific program, sort chunks
            # so that chunks from the program's own PDF file appear FIRST.
            _is_training_query = any(
                kw in query or kw in query.lower()
                for kw in ["تدريب", "training", "internship", "صيفي", "ميداني"]
            )
            if _is_training_query and _dom_prog and _dom_prog != "general":
                # Keywords that identify program-specific files
                _prog_file_hints: dict[str, list[str]] = {
                    "computer science":  ["حاسبات", "حاسب", "حاسوب", "computer", "cs", "ذكاء", "أشياء"],
                    "medicine":          ["طب", "طبية", "medicine", "medical"],
                    "dentistry":         ["أسنان", "اسنان", "dentistry", "dental"],
                    "engineering":       ["هندسة", "هندسه", "engineering"],
                    "pharmacy":          ["صيدلة", "صيدله", "pharmacy"],
                    "law":               ["حقوق", "قانون", "law"],
                    "commerce":          ["تجارة", "تجاره", "commerce", "business"],
                    "nursing":           ["تمريض", "nursing"],
                    "physical therapy":  ["علاج طبيعي", "physical therapy"],
                    "veterinary":        ["بيطري", "بيطره", "veterinary"],
                }
                _hints = _prog_file_hints.get(_dom_prog, [])

                def _prog_chunk_priority(r):
                    fname = (r.get("metadata", {}).get("fileName") or "").lower()
                    # Priority 0 = program-specific file, Priority 1 = everything else
                    return 0 if any(h in fname for h in _hints) else 1

                reranked = sorted(reranked, key=_prog_chunk_priority)

        # ── Step D: Detect year/semester from query ───────────────────────
        _q_year = _ei.year
        if _q_year is None:
            for _yr, _pat in [
                (1, r"فرق[هة]\s*اول[هى]?|الفرق[هة]\s*الاول[هى]?|level\s*1|year\s*1|"
                    r"first\s*year|السنة\s*الأولى|المستوى\s*الأول|\باوله?\b"),
                (2, r"فرق[هة]\s*تاني[هة]?|level\s*2|year\s*2|second\s*year"),
                (3, r"فرق[هة]\s*تالت[هة]?|level\s*3|year\s*3|third\s*year"),
                (4, r"فرق[هة]\s*رابع[هة]?|level\s*4|year\s*4|fourth\s*year"),
            ]:
                if re.search(_pat, query, re.IGNORECASE | re.UNICODE):
                    _q_year = _yr
                    break

        _q_sem = _ei.semester
        if _q_sem is None:
            if re.search(r"ترم\s*اول|الترم\s*الاول|semester\s*1|first\s*semester",
                         query, re.IGNORECASE | re.UNICODE):
                _q_sem = 1
            elif re.search(r"ترم\s*تاني|الترم\s*التاني|semester\s*2|second\s*semester",
                           query, re.IGNORECASE | re.UNICODE):
                _q_sem = 2

        # ── 5. Guaranteed course extraction (bypasses LLM for course queries) ──
        # GUARD: only run for "subjects list" intent.
        # For regulation/policy queries (غياب، درجات، لائحة), skip entirely
        # and let the LLM answer from context in step 7.
        _detect_re = _detect_re_enf
        _MEDICINE_PREFIXES = _NON_CS_PREFIXES
        _is_cs_query = (_dom_prog == "computer science")
        _is_course_query = (_ei.intent == "subjects list")

        # Level/semester patterns to search inside chunk text
        _LEVEL_PATS = {
            1: re.compile(r"\b(level\s*1|year\s*1|first\s*year|الفرق[هة]\s*الأول[هى]?|فرق[هة]\s*اول[هى]?|السنة\s*الأولى|المستوى\s*الأول)\b",
                          re.IGNORECASE | re.UNICODE),
            2: re.compile(r"\b(level\s*2|year\s*2|second\s*year|الفرق[هة]\s*الثاني[هة]?|فرق[هة]\s*تاني[هة]?|السنة\s*الثانية|المستوى\s*الثاني)\b",
                          re.IGNORECASE | re.UNICODE),
            3: re.compile(r"\b(level\s*3|year\s*3|third\s*year|الفرق[هة]\s*الثالث[هة]?|فرق[هة]\s*تالت[هة]?|السنة\s*الثالثة|المستوى\s*الثالث)\b",
                          re.IGNORECASE | re.UNICODE),
            4: re.compile(r"\b(level\s*4|year\s*4|fourth\s*year|الفرق[هة]\s*الرابع[هة]?|فرق[هة]\s*رابع[هة]?|السنة\s*الرابعة|المستوى\s*الرابع)\b",
                          re.IGNORECASE | re.UNICODE),
        }
        _SEM_PATS = {
            1: re.compile(r"\b(semester\s*1|fall|الترم\s*الأول|الفصل\s*الأول|ترم\s*اول)\b",
                          re.IGNORECASE | re.UNICODE),
            2: re.compile(r"\b(semester\s*2|spring|الترم\s*الثاني|الفصل\s*الثاني|ترم\s*تاني)\b",
                          re.IGNORECASE | re.UNICODE),
        }

        # ── Score every chunk ─────────────────────────────────────────────
        # Only run course extraction for "subjects list" intent.
        # Regulation/policy queries (غياب، درجات، لائحة) skip to step 6/7.
        _best_chunk = None
        _best_score = -9999

        if _is_course_query:
          for _r in reranked:
            _raw   = _r.get("text", "")
            _meta  = _r.get("metadata", {})
            _fname = (_meta.get("fileName") or "").lower()
            _s     = 0

            # Count non-medicine codes
            _all_m = _detect_re.findall(_raw)
            _cs_m  = [(_p, _n) for _p, _n in _all_m
                      if _p.upper() not in _MEDICINE_PREFIXES]
            _s += len(_cs_m) * 3

            # ── Year match (CRITICAL) ─────────────────────────────────────
            if _q_year is not None:
                _pat = _LEVEL_PATS.get(_q_year)
                if _pat and _pat.search(_raw):
                    _s += 50
                elif _cs_m:
                    _s -= 30

            # ── Semester match ────────────────────────────────────────────
            if _q_sem is not None:
                _spat = _SEM_PATS.get(_q_sem)
                if _spat and _spat.search(_raw):
                    _s += 20

            if _is_cs_query and any(w in _fname for w in ["حاسب", "computer", "حاسوب"]):
                _s += 5

            if _is_cs_query and _all_m and not _cs_m:
                _s -= 200

            if _s > _best_score:
                _best_score = _s
                _best_chunk = _r

        # ── Fix 2: Dynamic confidence threshold ──────────────────────────
        # Instead of a fixed threshold of 3, compute it from the score
        # distribution of all chunks. Use mean - 0.5*stdev so the threshold
        # adapts to both small datasets (few chunks, low scores) and large
        # ones (many chunks, higher scores).
        _all_scores = [
            sum([
                len([(_p, _n) for _p, _n in _detect_re.findall(_r.get("text", ""))
                     if _p.upper() not in _MEDICINE_PREFIXES]) * 3,
            ])
            for _r in reranked if _r.get("text", "")
        ]
        if _all_scores and len(_all_scores) > 1:
            import statistics as _stats
            _score_mean = _stats.mean(_all_scores)
            _score_std  = _stats.stdev(_all_scores)
            _MIN_CONFIDENCE = max(1, _score_mean - 0.5 * _score_std)
        else:
            _MIN_CONFIDENCE = 1   # single chunk or empty → very permissive

        if _best_score < _MIN_CONFIDENCE:
            _best_chunk = None

        # ── Step 5: (Disabled) Guaranteed course extraction ───────────────
        # Now that chunks are large (2000+ chars) and context is wide (12000 chars),
        # the LLM is much better at filtering the correct subjects from the 
        # full tables than a rigid regex. We'll let the LLM handle it in Step 7.
        pass

        # ── 6. Build context + detect exact match ────────────────────────
        # Final Priority Sort: Ensure faculty chunks appear FIRST in the context string
        # so the LLM sees them as the primary source of truth.
        # Detect if this is a training query so we can prioritize program files
        _training_kws_ctx = ["تدريب", "training", "internship", "صيفي", "ميداني"]
        _is_training_ctx  = any(kw in query for kw in _training_kws_ctx)
        _prog_hints_ctx   = {
            "computer science":  ["حاسبات", "حاسب", "حاسوب", "computer", "cs", "ذكاء", "أشياء", "iot"],
            "medicine":          ["طب", "طبية", "medicine", "medical"],
            "dentistry":         ["أسنان", "اسنان", "dentistry"],
            "engineering":       ["هندسة", "engineering"],
            "pharmacy":          ["صيدلة", "pharmacy"],
            "law":               ["حقوق", "law"],
            "commerce":          ["تجارة", "commerce"],
            "nursing":           ["تمريض", "nursing"],
            "physical therapy":  ["علاج طبيعي", "physical"],
            "veterinary":        ["بيطري", "veterinary"],
        }

        def _get_chunk_priority(c):
            prog  = c.get("metadata", {}).get("program", "").lower()
            fname = (c.get("metadata", {}).get("fileName") or "").lower()

            # For training queries + specific program: use filename-based priority
            # so program-specific PDFs appear BEFORE the general university regulation.
            if _is_training_ctx and _dom_prog and _dom_prog != "general":
                _hints = _prog_hints_ctx.get(
                    _dom_prog if isinstance(_dom_prog, str) else (_dom_prog[0] if _dom_prog else ""),
                    []
                )
                if _hints and any(h in fname for h in _hints):
                    return 0   # program-specific file — highest priority
                if prog == "general":
                    return 1   # general regulation — secondary
                return 2       # other programs — lowest

            # Default metadata-based priority
            # Support both single string and list for _dom_prog
            if isinstance(_dom_prog, list):
                if prog in _dom_prog: return 0
            else:
                if prog == _dom_prog: return 0
            if prog == "general": return 1
            return 2

        reranked.sort(key=_get_chunk_priority)

        context_str, used_chunks, citation_refs = _build_context_with_citations(
            reranked, self.max_context_chars
        )
        chunks_used = len(used_chunks)

        # has_exact_match: True if any used chunk contains core query keywords
        _query_keywords = [
            w for w in re.findall(r"[\u0600-\u06FF]{3,}|[a-zA-Z]{4,}", query)
            if w.lower() not in {
                "في", "من", "على", "عن", "هو", "هي", "ما", "كيف", "لماذا",
                "the", "what", "how", "why", "when", "where", "that", "this",
            }
        ]
        has_exact_match = False
        for r in used_chunks:
            if not has_exact_match and _query_keywords:
                text_lower = r.get("text", "").lower()
                matched = sum(1 for kw in _query_keywords if kw.lower() in text_lower)
                if matched >= max(1, len(_query_keywords) // 2):
                    has_exact_match = True

        retrieval_stats["has_exact_match"] = has_exact_match

        # ── 7. Choose prompt based on intent + confidence + exact match ───
        # Three prompt tiers:
        #   LEGAL      — regulation/policy query + good retrieval
        #                → structured 4-section format, extractive when possible
        #   STANDARD   — general query or course query with good retrieval
        #                → standard answer with citation
        #   CONSTRAINED — low retrieval confidence
        #                → strict "not found" fallback, no guessing
        _is_regulation_query = (_ei.intent in {
            "regulations", "grades", "graduation", "fees",
            "registration", "exam schedule", "general", "departments",
        })
        _good_retrieval = True

        if not _good_retrieval:
            _active_system = _SYSTEM_PROMPT_CONSTRAINED
            _answer_mode   = "constrained"
        elif _is_regulation_query:
            # Legal structured format — extractive if exact match found
            _active_system = _SYSTEM_PROMPT_LEGAL
            _answer_mode   = "legal_extractive" if has_exact_match else "legal_summarized"
        else:
            _active_system = _SYSTEM_PROMPT
            _answer_mode   = "standard"

        # ── 8. Generate answer ────────────────────────────────────────────
        prompt = _PROMPT_TEMPLATE.format(
            system   = _active_system,
            context  = context_str,
            question = query,
        )
        # Build list of models to try: primary first, then fallbacks
        _models_to_try = [self.llm]
        _fallbacks = getattr(self, "_llm_fallback_models", [])
        _or_key    = getattr(self, "_openrouter_key", None)
        for _fb_model in _fallbacks:
            if _or_key:
                _models_to_try.append(ChatOpenAI(
                    openai_api_key=_or_key,
                    openai_api_base="https://openrouter.ai/api/v1",
                    model_name=_fb_model,
                    temperature=0.1,
                    max_tokens=2048,
                    max_retries=1,
                    timeout=30.0,
                    default_headers={
                        "HTTP-Referer": os.getenv("OPENROUTER_REFERRER", "http://localhost:8000"),
                        "X-Title": "Smart Campus RAG CLI",
                    },
                ))

        answer = None
        for _try_idx, _try_llm in enumerate(_models_to_try):
            try:
                _model_label = getattr(_try_llm, "model_name", "?")
                if _try_idx > 0:
                    _dbg(f"[LLM] Primary failed, trying fallback: {_model_label}\n")
                response = _try_llm.invoke(prompt)
                answer   = response.content if hasattr(response, "content") else str(response)
                break  # success — stop trying
            except Exception as _llm_err:
                _dbg(f"[LLM] Model {_model_label} failed: {_llm_err}\n")
                continue  # try next

        if answer is None:
            _dbg("[LLM] All models failed, returning raw chunk text.\n")
            if query_lang == "arabic":
                answer = "⚠️ عذراً، تعذر الاتصال بنموذج الذكاء الاصطناعي لتلخيص الإجابة (تجاوز حد الاستخدام لليوم). ولكن تم استخراج النصوص التالية مباشرة من لائحة البرنامج كمصادر للإجابة:\n\n"
            else:
                answer = "⚠️ Sorry, the AI model could not be reached to summarize the answer (rate limit exceeded). However, the following text segments were extracted directly from the regulation documents as sources:\n\n"

            for idx, chunk in enumerate(reranked[:3], 1):
                fname = chunk.get("metadata", {}).get("fileName", "Document")
                page  = chunk.get("metadata", {}).get("page", "?")
                text  = chunk.get("text", "").strip()
                answer += f"📄 **المصدر [{idx}]: {fname} - صفحة {page}**\n{text}\n\n"


        # ── 9. Apply citation formatting ──────────────────────────────────
        # Always append a clean deduplicated source footer so the user can
        # see exactly which documents were used — regardless of citation_mode.
        if citation_refs:
            answer = _append_footer_citations(answer, citation_refs)

        elapsed_ms = (time.perf_counter() - t0) * 1000

        # ── Save to history ───────────────────────────────────────────────
        self.history.append({
            "query":        query,
            "answer":       answer,
            "sources":      [r.get("metadata", {}) for r in reranked],
            "citation_refs": citation_refs,
        })

        return {
            "answer":          answer,
            "query_language":  query_lang,
            "reranked":        reranked,
            "chunks_used":     chunks_used,
            "retrieval_stats": retrieval_stats,
            "answer_mode":     _answer_mode,
            "has_exact_match": has_exact_match,
            "citation_refs":   citation_refs,
            "citation_mode":   self.citation_mode,
            "elapsed_ms":      elapsed_ms,
        }


    # ─────────────────────────────────────────────────────────────────────
    # Display helpers
    # ─────────────────────────────────────────────────────────────────────

    def print_debug_chunks(self, reranked: list[dict]) -> None:
        """Print a compact debug view of retrieved chunks."""
        if not reranked:
            return
        print()
        print(_label(f"  Retrieved chunks ({len(reranked)})"))
        print(_dim("  " + _DIVIDER))

        for i, r in enumerate(reranked, start=1):
            meta    = r.get("metadata", {})
            fname   = meta.get("fileName", "Unknown")
            page    = meta.get("page", "?")
            section = meta.get("sectionTitle", "") or "—"
            lang    = meta.get("language", "?")
            kw      = meta.get("keywords", "")
            rscore  = r.get("rerank_score", 0.0)
            rmethod = r.get("rerank_method", "?")
            rrf     = r.get("rrf_score", 0.0)

            # Truncate snippet
            snippet = r.get("text", "").replace("\n", " ").strip()
            if len(snippet) > SNIPPET_LEN:
                snippet = snippet[:SNIPPET_LEN] + " …"

            _full_text = r.get("text", "")
            _len = len(_full_text)
            print(
                f"  {_score(f'[{i}]')} "
                f"{_label(fname)}  "
                f"p.{_score(str(page))}  "
                f"len={_dim(str(_len))}  "
                f"lang={_dim(lang)}  "
                f"rerank={_score(f'{rscore:.3f}')} ({_dim(rmethod)})  "
                f"rrf={_dim(f'{rrf:.4f}')}"
                f"  prog_score={_dim(str(r.get('program_score', '?')))}"
            )
            print(f"      {_dim('Section:')} {section}")
            if kw:
                print(f"      {_dim('Keywords:')} {kw[:80]}")
            print(f"      {_dim(snippet)}")
            print()

    def print_sources(self, reranked: list[dict], answer: str = "") -> None:
        """Print a grouped source reference list (only cited ones if answer provided)."""
        # ── 1. Detect cited indices ──────────────────────────────────────
        cited_indices = set()
        if answer:
            # Matches [1], [1,2], [المصدر 1], [المصدر 1, 2]
            patterns = [
                r"\[\s*(\d+(?:\s*,\s*\d+)*)\s*\]",
                r"المصدر\s*(\d+(?:\s*,\s*\d+)*)",
                r"source\s*(\d+(?:\s*,\s*\d+)*)"
            ]
            for pat in patterns:
                for match in re.finditer(pat, answer, re.IGNORECASE):
                    nums = re.findall(r"\d+", match.group(1))
                    cited_indices.update(int(n) for n in nums)

        # ── 2. Group chunk indices by (fileName, page) ───────────────────
        groups: dict[tuple[str, int], list[int]] = {}
        meta_map: dict[tuple[str, int], dict] = {}
        
        for i, r in enumerate(reranked, start=1):
            # Skip if we have citations and this chunk wasn't cited
            if cited_indices and i not in cited_indices:
                continue
                
            meta = r.get("metadata", {})
            key  = (meta.get("fileName", "Unknown"), meta.get("page", "?"))
            if key not in groups:
                groups[key] = []
                meta_map[key] = meta
            groups[key].append(i)

        if not groups:
            return

        print(_label("  Sources"))
        for key, indices in groups.items():
            meta = meta_map[key]
            fname   = meta.get("fileName", "Unknown")
            page    = meta.get("page", "?")
            section = meta.get("sectionTitle", "") or "—"
            
            # Format indices as [1, 2, 3]
            idx_str = f"[{', '.join(map(str, indices))}]"
            
            print(
                f"  {_score(idx_str):<12} "
                f"{_source(fname)}  "
                f"— page {_score(str(page))}  "
                f"| {_dim(section)}"
            )

    def print_stats(self, stats: dict, elapsed_ms: float) -> None:
        """Print a one-line timing summary."""
        timing   = stats.get("timing_ms", {})
        method   = stats.get("fusion_method", "?")
        prog_f   = stats.get("program_filter") or "none"
        prog_b   = stats.get("program_boosted", 0)
        exact    = stats.get("has_exact_match")
        exact_str = f"  exact={'✓' if exact else '✗'}" if exact is not None else ""
        print(
            _dim(
                f"  ⏱  dense={timing.get('dense', 0):.0f}ms  "
                f"sparse={timing.get('sparse', 0):.0f}ms  "
                f"fusion={timing.get('fusion', 0):.0f}ms  "
                f"total={elapsed_ms:.0f}ms  "
                f"method={method}  "
                f"prog_filter={prog_f}  "
                f"prog_boosted={prog_b}"
                f"{exact_str}  "
                f"cache={self.cache.stats['hit_rate']:.0%} hit"
            )
        )

    def print_session_stats(self) -> None:
        """Print BM25 index and cache statistics."""
        print()
        print(_banner("  Session statistics"))
        print(_dim("  " + _DIVIDER))

        cs = self.cache.stats
        print(
            f"  {_label('Embedding cache')}  "
            f"size={cs['size']}/{cs['max_size']}  "
            f"hits={cs['hits']}  misses={cs['misses']}  "
            f"hit_rate={cs['hit_rate']:.0%}"
        )

        if self.bm25:
            print(
                f"  {_label('BM25 index')}      "
                f"docs={self.bm25.doc_count}  "
                f"built={self.bm25.is_built}"
            )

        if self.collection:
            print(
                f"  {_label('ChromaDB')}        "
                f"collection='{COLLECTION_NAME}'  "
                f"chunks={self.collection.count()}"
            )

        print(
            f"  {_label('Settings')}         "
            f"top_k={self.top_k}  "
            f"rerank={self.rerank_method}  "
            f"lang_filter={self.language_filter or 'off'}  "
            f"max_ctx={self.max_context_chars}"
        )
        print(f"  {_label('History')}          {len(self.history)} queries this session")
        print()


# ─────────────────────────────────────────────────────────────────────────────
# Command parser  –  handles /commands typed inside the chat loop
# ─────────────────────────────────────────────────────────────────────────────

def _handle_command(raw: str, session: RAGSession) -> bool:
    """
    Parse and execute a /command.

    Returns True if the command was handled (caller should skip RAG),
    False if the input is not a command.
    """
    raw = raw.strip()
    if not raw.startswith("/"):
        return False

    parts = raw.split()
    cmd   = parts[0].lower()

    # ── /help ─────────────────────────────────────────────────────────────
    if cmd == "/help":
        print()
        print(_banner("  Available commands"))
        print(_dim("  " + _DIVIDER))
        rows = [
            ("/help",              "Show this help message"),
            ("/stats",             "Show index, cache, and session statistics"),
            ("/lang arabic",       "Filter results to Arabic chunks only"),
            ("/lang english",      "Filter results to English chunks only"),
            ("/lang off",          "Remove language filter"),
            ("/rerank cosine",     "Use cosine similarity reranking (default)"),
            ("/rerank llm",        "Use LLM-based reranking (slower, higher quality)"),
            ("/rerank none",       "Disable reranking (use raw retrieval order)"),
            ("/top N",             "Set number of chunks to use (e.g. /top 3)"),
            ("/debug on|off",      "Toggle debug chunk display"),
            ("/clear",             "Clear the terminal screen"),
            ("exit / quit",        "Exit the program"),
        ]
        for cmd_str, desc in rows:
            print(f"  {_label(cmd_str):<28} {desc}")
        print()
        return True

    # ── /stats ────────────────────────────────────────────────────────────
    if cmd == "/stats":
        session.print_session_stats()
        return True

    # ── /lang ─────────────────────────────────────────────────────────────
    if cmd == "/lang":
        if len(parts) < 2:
            print(_warn("  Usage: /lang arabic | english | off"))
            return True
        val = parts[1].lower()
        if val == "off":
            session.language_filter = None
            print(_dim("  Language filter removed."))
        elif val in ("arabic", "english", "mixed"):
            session.language_filter = val
            print(_dim(f"  Language filter set to '{val}'."))
        else:
            print(_warn(f"  Unknown language '{val}'. Use: arabic | english | mixed | off"))
        return True

    # ── /rerank ───────────────────────────────────────────────────────────
    if cmd == "/rerank":
        if len(parts) < 2:
            print(_warn("  Usage: /rerank cosine | llm | none"))
            return True
        val = parts[1].lower()
        if val in ("cosine", "llm", "none"):
            session.rerank_method = val
            print(_dim(f"  Reranking strategy set to '{val}'."))
        else:
            print(_warn(f"  Unknown strategy '{val}'. Use: cosine | llm | none"))
        return True

    # ── /top ──────────────────────────────────────────────────────────────
    if cmd == "/top":
        if len(parts) < 2 or not parts[1].isdigit():
            print(_warn("  Usage: /top N  (e.g. /top 5)"))
            return True
        n = int(parts[1])
        if 1 <= n <= 20:
            session.top_k = n
            print(_dim(f"  top_k set to {n}."))
        else:
            print(_warn("  top_k must be between 1 and 20."))
        return True

    # ── /debug ────────────────────────────────────────────────────────────
    if cmd == "/debug":
        if len(parts) < 2:
            session.show_debug = not session.show_debug
        else:
            session.show_debug = parts[1].lower() in ("on", "1", "true", "yes")
        state = "on" if session.show_debug else "off"
        print(_dim(f"  Debug display {state}."))
        return True

    # ── /clear ────────────────────────────────────────────────────────────
    if cmd == "/clear":
        os.system("cls" if os.name == "nt" else "clear")
        return True

    print(_warn(f"  Unknown command '{cmd}'. Type /help for a list."))
    return True


# ─────────────────────────────────────────────────────────────────────────────
# Startup banner
# ─────────────────────────────────────────────────────────────────────────────

def _print_welcome(session: RAGSession) -> None:
    os.system("cls" if os.name == "nt" else "clear")
    print()
    print(_banner("  " + _THICK_DIVIDER))
    print(_banner("   Smart Campus RAG  –  CLI Test Interface"))
    print(_banner("  " + _THICK_DIVIDER))
    print()
    print(f"  {_label('top_k')}        {session.top_k} chunks")
    print(f"  {_label('rerank')}       {session.rerank_method}")
    print(f"  {_label('lang filter')}  {session.language_filter or 'off'}")
    print(f"  {_label('debug')}        {'on' if session.show_debug else 'off'}")
    print(f"  {_label('max context')}  {session.max_context_chars} chars")
    print(f"  {_label('citations')}    {session.citation_mode}")
    print()
    print(_dim("  Type your question in Arabic or English."))
    print(_dim("  Type /help for commands  |  exit to quit."))
    print()
    print(_dim("  " + _DIVIDER))
    print()


# ─────────────────────────────────────────────────────────────────────────────
# Main chat loop
# ─────────────────────────────────────────────────────────────────────────────

def chat_loop(session: RAGSession) -> None:
    """
    Interactive chat loop.
    Reads queries from stdin, runs the RAG pipeline, prints results.
    Exits when the user types 'exit', 'quit', or sends EOF (Ctrl-D / Ctrl-Z).
    """
    _print_welcome(session)

    while True:
        # ── Read input ────────────────────────────────────────────────────
        try:
            raw = input(_prompt_str()).strip()
        except (EOFError, KeyboardInterrupt):
            print()
            print(_dim("\n  Goodbye!\n"))
            break

        if not raw:
            continue

        # ── Exit ──────────────────────────────────────────────────────────
        if raw.lower() in ("exit", "quit", "q", ":q"):
            print(_dim("\n  Goodbye!\n"))
            break

        # ── /commands ─────────────────────────────────────────────────────
        if _handle_command(raw, session):
            continue

        # ── RAG pipeline ──────────────────────────────────────────────────
        print()
        print(_dim(f"  Thinking …"))

        result = session.get_rag_response(raw)

        answer         = result["answer"]
        query_lang     = result["query_language"]
        reranked       = result["reranked"]
        stats          = result["retrieval_stats"]
        elapsed_ms     = result["elapsed_ms"]
        chunks_used    = result.get("chunks_used", len(reranked))
        route          = result.get("route", "RAG")
        answer_mode    = result.get("answer_mode", "")
        has_exact      = result.get("has_exact_match", None)
        det_faculties  = result.get("detected_faculties", [])

        # ── Route label ───────────────────────────────────────────────────
        _route_colors = {
            "CATALOG": Fore.CYAN,
            "RAG":     Fore.MAGENTA,
            "HYBRID":  Fore.YELLOW,
            "CLARIFY": Fore.RED,
            "COMPARE": Fore.BLUE,
        }
        _fac_str   = f"  faculties={det_faculties}" if det_faculties else ""
        _mode_str  = f"  [{answer_mode}]" if answer_mode else ""
        _exact_str = f"  exact={has_exact}" if has_exact is not None else ""
        _mem_str   = f"  🧠memory" if result.get("memory_used") else ""
        _route_label = _c(
            f"  ⇒ Route: {route}{_mode_str}{_exact_str}{_fac_str}{_mem_str}",
            _route_colors.get(route, Fore.WHITE), Style.DIM
        )
        print(_route_label)

        # ── Debug: chunk previews ─────────────────────────────────────────
        if session.show_debug and reranked:
            session.print_debug_chunks(reranked)
            print(_dim("  " + _DIVIDER))

        # ── Answer ────────────────────────────────────────────────────────
        print()
        print(_label("  Answer") + _dim(f"  (lang={query_lang})"))
        print(_dim("  " + _DIVIDER))
        # Word-wrap the answer for readability
        for line in answer.splitlines():
            wrapped = textwrap.fill(
                line,
                width=TERMINAL_WIDTH - 4,
                initial_indent="  ",
                subsequent_indent="  ",
                break_long_words=False,
                break_on_hyphens=False,
            )
            print(_answer(wrapped) if wrapped.strip() else "")

        # ── Sources ───────────────────────────────────────────────────────
        _is_not_found = "المعلومات غير موجودة" in answer or "not found" in answer.lower()
        if reranked and not _is_not_found:
            print()
            session.print_sources(reranked, answer)

        # ── Timing ───────────────────────────────────────────────────────
        if stats:
            print()
            session.print_stats(stats, elapsed_ms)

        print()
        print(_dim("  " + _DIVIDER))
        print()

    # Persist embedding cache on exit
    session.cache.save()


# ─────────────────────────────────────────────────────────────────────────────
# Entry point
# ─────────────────────────────────────────────────────────────────────────────

def _parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Smart Campus RAG – CLI test interface",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=textwrap.dedent("""\
            Examples:
              python chat_cli.py
              python chat_cli.py --top-k 3 --rerank llm
              python chat_cli.py --lang arabic --no-debug
        """),
    )
    p.add_argument("--top-k",      type=int,   default=8,
                   help="Number of chunks to use in context (default: 8)")
    p.add_argument("--rerank",     type=str,   default="none",
                   choices=["cosine", "llm", "bm25", "none"],
                   help="Reranking strategy (default: cosine)")
    p.add_argument("--lang",       type=str,   default=None,
                   choices=["arabic", "english", "mixed"],
                   help="Language filter for retrieval (default: off)")
    p.add_argument("--no-debug",   action="store_true",
                   help="Hide debug chunk previews")
    p.add_argument("--citation-mode", type=str, default="inline",
                   choices=["inline", "footer"],
                   help="Citation style: inline [N] markers or footer list (default: inline)")
    p.add_argument("--max-context", type=int, default=MAX_CONTEXT_CHARS,
                   help="Max characters sent to LLM context (default: 4000)")
    return p.parse_args()


if __name__ == "__main__":
    args = _parse_args()

    session = RAGSession(
        top_k             = args.top_k,
        rerank_method     = args.rerank,
        language_filter   = args.lang,
        max_context_chars = args.max_context,
        show_debug        = not args.no_debug,
        citation_mode     = args.citation_mode,
    )

    chat_loop(session)