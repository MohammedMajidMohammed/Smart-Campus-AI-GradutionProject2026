import os
import sys

sys.stdout.reconfigure(encoding="utf-8")

with open(r"d:/Last_Version_Final_Gradution_Project_2026/Rag Update/scratch/gpa_limits.txt", "r", encoding="utf-16") as f:
    text = f.read()

# Let's find pages that have Computers Faculty in header:
blocks = text.split("=========================================")
print(f"Total blocks: {len(blocks)}")

for b in blocks:
    if "دليل_برامج_كلية_الحاسوب" in b or "لائحة الجامعة" in b or "لائحه جامعة" in b:
        # Check if the text contains numbers like 12, 14, 18, 21 or words like "العبء" or "الحد الأقصى"
        text_lower = b.lower()
        if any(w in text_lower for w in ["الاقصى", "الادنى", "العبء", "gpa", "تسجيل", "انذار", "منذر"]):
            print("\n" + "="*50)
            # print block header (first 2 lines)
            lines = b.strip().splitlines()
            print("\n".join(lines[:2]))
            print("="*50)
            
            # Print sentences that contain keywords or numbers
            for line in lines[2:]:
                line_lower = line.lower()
                if any(k in line_lower for k in ["الاقصى", "الادنى", "العبء", "تسجيل", "gpa", "ساعة", "12", "18", "21", "2.0"]):
                    print(line.strip())
