import re

print("Patching chat_cli.py...")
with open('chat_cli.py', 'r', encoding='utf-8') as f:
    cli = f.read()

# 1. max-context
if '--max-context' not in cli:
    cli = cli.replace(
        'p.add_argument("--lang",       type=str,   default=None,',
        'p.add_argument("--max-context", type=int, default=4000,\n                   help="Max context chars sent to LLM (default: 4000)")\n    p.add_argument("--lang",       type=str,   default=None,'
    )

# 2. max_tokens
cli = cli.replace('max_tokens=1024', 'max_tokens=2048')

# 3. Unify Prompt (import from routes.chat)
# In chat_cli.py, we can just import _PROMPT and use it.
# Or better, just hard-replace the prompt strings. Let's hard-replace _SYSTEM_PROMPT_LEGAL since it's the main one.
new_prompt = '''_SYSTEM_PROMPT_LEGAL = """أنت مساعد أكاديمي دقيق جداً متخصص في لوائح الجامعات والمقررات الدراسية.
السياق المرفق مستخرج مباشرةً من ملفات PDF رسمية للجامعة — اعتمد عليه كمصدر وحيد.
القاعدة الذهبية: أجب فقط بناءً على المعلومات الموجودة في السياق (Context) المرفق. يمنع منعاً باتاً اختراع أي معلومات من خارج السياق.

━━━━━━━━━━━━━━━━━━━━
📋 إذا كان السؤال عن المقررات/المواد:
━━━━━━━━━━━━━━━━━━━━
- استخرج كل المقررات المذكورة مع أكوادها (مثل GEN 001, CS 201).
- اعرضها كقائمة نقطية منظمة.
- اذكر الفرقة الدراسية والترم إذا تم ذكرهم.
- لا تقل "لا يوجد" إذا رأيت أكواداً في النص.

━━━━━━━━━━━━━━━━━━━━
📜 إذا كان السؤال عن اللوائح والقوانين:
━━━━━━━━━━━━━━━━━━━━
- قدم الإجابة بشكل واضح ودقيق في نقاط.
- اذكر رقم المادة أو القرار أو الصفحة إن وجد.
- تجنب إضافة أي استنتاجات شخصية.

━━━━━━━━━━━━━━━━━━━━
🌐 قواعد عامة:
━━━━━━━━━━━━━━━━━━━━
- أجب بنفس لغة السؤال. (إذا كان السؤال بالعربية، أجب بالعربية بدقة).
- إذا لم تكن هناك معلومات كافية في السياق للإجابة عن السؤال، قل صراحة وبشكل مباشر: "المعلومات غير متوفرة في السياق الحالي". لا تحاول التخمين.

━━━━━━━━━━━━━━━━━━━━
السياق المتاح لك:
{context}

السؤال:
{question}

الإجابة المباشرة والدقيقة:"""'''

cli = re.sub(r'_SYSTEM_PROMPT_LEGAL\s*=\s*""".*?"""', new_prompt, cli, flags=re.DOTALL)

with open('chat_cli.py', 'w', encoding='utf-8') as f:
    f.write(cli)


print("Patching routes/chat.py...")
with open('routes/chat.py', 'r', encoding='utf-8') as f:
    chat = f.read()

# 4. pass llm to understand_query
chat = chat.replace(
    'query_intent = understand_query(request.question)',
    'query_intent = understand_query(request.question, llm=llm)'
)

with open('routes/chat.py', 'w', encoding='utf-8') as f:
    f.write(chat)


print("Patching retag_chunks.py...")
with open('retag_chunks.py', 'r', encoding='utf-8') as f:
    retag = f.read()

# 5. Fix _FNAME_PROG_MAP
def replace_map(content):
    idx1 = content.find('_FNAME_PROG_MAP = [')
    if idx1 == -1: return content
    idx2 = content.find(']', idx1)
    
    new_map = '''_FNAME_PROG_MAP = [
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
]'''
    return content[:idx1] + new_map + content[idx2+1:]

retag = replace_map(retag)
retag = retag.replace('return None', 'return "general"')

with open('retag_chunks.py', 'w', encoding='utf-8') as f:
    f.write(retag)


print("Patching routes/upload.py...")
with open('routes/upload.py', 'r', encoding='utf-8') as f:
    up = f.read()

up = replace_map(up)
up = up.replace('return None', 'return "general"')

with open('routes/upload.py', 'w', encoding='utf-8') as f:
    f.write(up)

print("Done")
