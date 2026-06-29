import os

for root, dirs, files in os.walk("routes"):
    for file in files:
        if file.endswith(".py"):
            path = os.path.join(root, file)
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
                if "translate" in content.lower():
                    print(f"Found in {path}")
                    for line_no, line in enumerate(content.splitlines(), 1):
                        if "translate" in line.lower() or "llm.invoke" in line.lower():
                            print(f"  {line_no}: {line.strip()}")
