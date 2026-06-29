
import os
for root, dirs, files in os.walk("."):
    if "venv" in root or ".git" in root or ".gemini" in root:
        continue
    for file in files:
        if file.endswith(".py"):
            path = os.path.join(root, file)
            with open(path, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
            if "DEBUG ISOLATION" in content:
                print(f"Found in {path}")
                for i, line in enumerate(content.split('\n')):
                    if "DEBUG ISOLATION" in line:
                        print(f"  Line {i+1}: {line.strip()}")
