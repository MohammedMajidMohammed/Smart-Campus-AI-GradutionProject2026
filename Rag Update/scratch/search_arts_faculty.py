import os
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

keywords = ["arts", "humanities", "ترجمة", "إنجليزي", "انجليزي", "translation", "english"]
for root, dirs, files in os.walk('.'):
    if 'venv' in root or '.git' in root or '__pycache__' in root or 'scratch' in root:
        continue
    for f in files:
        if f.endswith('.py'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8', errors='ignore') as file:
                for line_no, line in enumerate(file, 1):
                    for kw in keywords:
                        if kw in line.lower():
                            print(f"[{path}:{line_no}]: {line.strip()}")
                            break
