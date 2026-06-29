import os
import sys

sys.stdout.reconfigure(encoding="utf-8")

with open(r"d:/Last_Version_Final_Gradution_Project_2026/Rag Update/scratch/target_pages_content.txt", "r", encoding="utf-16") as f:
    text = f.read()

print("File size:", len(text))
# Let's split by the separator we wrote
blocks = text.split("==================================================")
print("Number of blocks:", len(blocks))

for b in blocks:
    if "File:" in b:
        # print first 1000 characters of each block
        lines = b.strip().splitlines()
        print("\n" + "="*50)
        print(lines[0]) # File & Page info
        print("="*50)
        print("\n".join(lines[1:35])) # First 34 lines of the page
        print("...")
