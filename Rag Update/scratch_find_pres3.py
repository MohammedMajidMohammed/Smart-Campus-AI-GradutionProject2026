import sys
import glob

sys.stdout.reconfigure(encoding='utf-8')

for txt_file in glob.glob("processed_pdfs/*.txt"):
    try:
        with open(txt_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            for i, line in enumerate(lines):
                if "رئيس" in line or "رييس" in line:
                    print(f"[{txt_file}:{i+1}] {line.strip()}")
    except Exception as e:
        pass
