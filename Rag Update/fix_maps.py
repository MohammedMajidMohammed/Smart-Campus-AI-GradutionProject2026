import re

def fix_broken_map(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # The map starts with _FNAME_PROG_MAP = [
    # And we want to replace everything from there until the end of that list structure.
    # Since it's broken, let's look for the start and then the next big assignment or function.
    
    start_marker = '_FNAME_PROG_MAP = ['
    idx1 = content.find(start_marker)
    if idx1 == -1: return
    
    # Find the next # ── or def or something that marks the end of the global variables section
    idx_end = content.find('# Chunks from these files', idx1)
    if idx_end == -1:
        idx_end = content.find('def detect_program', idx1)
        
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
]

'''
    new_content = content[:idx1] + new_map + content[idx_end:]
    
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(new_content)

fix_broken_map('retag_chunks.py')
fix_broken_map('routes/upload.py')
print("Fixed maps")
