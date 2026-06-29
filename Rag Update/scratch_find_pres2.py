import sys
import glob

sys.stdout.reconfigure(encoding='utf-8')

# Search for "رئيس" in the text files and print 1 line before and after
for txt_file in glob.glob("*.txt") + glob.glob("files/*.txt") + glob.glob("processed_pdfs/*.txt"):
    try:
        with open(txt_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            for i, line in enumerate(lines):
                if "رئيس" in line and ("جامع" in line or "الاهلي" in line):
                    print(f"[{txt_file}:{i+1}] {line.strip()}")
    except Exception as e:
        pass
