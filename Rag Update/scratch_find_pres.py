import sys
import os
import glob
sys.stdout.reconfigure(encoding='utf-8')

# Search for "رئيس" in the text files
for txt_file in glob.glob("*.txt") + glob.glob("files/*.txt"):
    try:
        with open(txt_file, 'r', encoding='utf-8') as f:
            for i, line in enumerate(f):
                if "رئيس" in line and ("جامع" in line or "المنوفي" in line):
                    print(f"[{txt_file}:{i+1}] {line.strip()}")
    except Exception as e:
        pass
