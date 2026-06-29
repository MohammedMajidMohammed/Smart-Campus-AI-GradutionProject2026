import sys
from sentence_transformers import CrossEncoder

sys.stdout.reconfigure(encoding="utf-8")

m = CrossEncoder('cross-encoder/ms-marco-MiniLM-L-6-v2', cache_folder="models")

doc24 = '( ) االنسحاب(Withdrawal: ( يس مح للطال ب باالنس حاب م ن المق رر ال دراسي خ الل ف ت ة اقص اها ثماني ة اس ابيع ويع طي الطال ب تق دير( W ي حساب المعدل الت اكمي للطالب ميسحب واليدخل هذا التقدير فز(cGPA) ( مادة20 ( ) االنسحاب االضطراريForced withdrawal: ) ( ي حال ة انس حاب الطال بمن المق رر ال دراسي بع د الف ت ة المح ددة (ثماني ة اس ابيع) يحص ل الطال ب ع يلي زفFW ي تق دير ميس حب اض طراري ويع ت الطال ب راس ب فز ي ) حس اب المع دل المق رر ال دراسي وي دخل ه ذا التق دير فز ( الت اكمي للطالبcGPA. ) ( مادة21: ) متطلبات التخرج. ان يتم الطالب بنجاح دراسة المقررات المعتمدة ( اال يقل المعدل الت اكمي العام للطالب عند التخرج عن2,00. ) ( مادة22: ): مراتب الشر ف'
doc25 = 'ral Pathology 301 DOD العالج التحفظ301 Operative Dentistry301 DRP االستعاضة الصناعية المتحركه301 Prosthodontics301 DFP 301 االستعاضة السنية المثبته301'

queries = [
    "dentistry graduation requirements degree academic program شروط تخرج ف طب اسنان",
    "شروط التخرج ف طب اسنان",
    "متطلبات التخرج لبرنامج درجة طب الأسنان.",
    "شروط التخرج في طب الأسنان",
    "graduation requirements dentistry"
]

for q in queries:
    scores = m.predict([(q, doc24), (q, doc25)])
    print(f"Query: {q}")
    print(f"  Doc 24 score: {scores[0]:.4f}")
    print(f"  Doc 25 score: {scores[1]:.4f}")
    print("-" * 50)
